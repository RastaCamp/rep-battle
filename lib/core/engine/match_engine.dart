import 'dart:math';

import '../config/game_mode_config.dart';
import '../models/game_card.dart';
import '../models/match_house_rules.dart';
import '../models/match_state.dart';
import '../models/player_state.dart';
import '../models/ability_modifier.dart';
import 'ability_modifier_engine.dart';
import '../services/shuffle_service.dart';
import '../config/deck_art_style.dart';
import '../data/deck_factory.dart';
import '../../services/custom_card_service.dart';

class MatchEngineResult {
  final MatchState state;
  final String? message;
  final bool armorBroken;
  final bool comboIncreased;
  final bool comboBroken;
  final bool playerEliminated;
  final bool matchEnded;
  final bool groupTurnContinues;

  const MatchEngineResult({
    required this.state,
    this.message,
    this.armorBroken = false,
    this.comboIncreased = false,
    this.comboBroken = false,
    this.playerEliminated = false,
    this.matchEnded = false,
    this.groupTurnContinues = false,
  });
}

class MatchEngine {
  final RulesConfig rules;
  final GameModeConfig mode;
  final Random _random = Random();

  MatchEngine({required this.rules, required this.mode});

  Future<MatchState> createMatch({
    required List<PlayerState> players,
    int? shuffleSeed,
    String deckId = 'default_rep_battle',
    CustomCardService? customCards,
    DeckArtStyle deckArtStyle = DeckArtStyle.defaultArt,
    bool lightDeck = false,
    MatchHouseRules houseRules = const MatchHouseRules(),
  }) async {
    var deck = await DeckFactory.buildStandardDeck(
      artStyle: deckArtStyle,
      customCards: customCards,
    );
    if (lightDeck) {
      deck = DeckFactory.trimToLightDeck(deck);
    }
    final errors = DeckFactory.validateDeck(deck, minCards: lightDeck ? 26 : 52);
    if (errors.isNotEmpty) {
      throw StateError('Invalid deck: ${errors.join(', ')}');
    }
    deck = ShuffleService.fisherYates(deck, seed: shuffleSeed);

    for (final p in players) {
      p.lives = mode.lives;
      p.armor = mode.startingArmor;
      p.skips = mode.startingSkips;
      AbilityModifierEngine.applyStartingStats(
        p,
        AbilityModifiers.get(p.abilityModifierId),
        mode.lives,
      );
      if (mode.teamMode) {
        p.teamId = _teamForSuit(p);
      }
    }

    return MatchState(
      matchId: DateTime.now().millisecondsSinceEpoch.toString(),
      modeId: mode.id,
      deckId: deckId,
      activeDeck: deck,
      startingDeckSize: deck.length,
      discardPile: [],
      players: players,
      shuffleSeed: shuffleSeed,
      reshuffleEnabled: mode.reshuffleOnEmpty,
      timerSecondsRemaining: mode.timerEnabled ? mode.timerSeconds : 0,
      phase: MatchPhase.intro,
      houseRules: houseRules,
    );
  }

  String? _teamForSuit(PlayerState p) => null;

  MatchEngineResult startGameplay(MatchState match) {
    match.phase = MatchPhase.draw;
    return MatchEngineResult(state: match, message: 'BEGIN!');
  }

  MatchEngineResult drawCard(MatchState match) {
    if (match.cardDrawnThisTurn || match.matchOver) {
      return MatchEngineResult(state: match);
    }

    if (match.activeDeck.isEmpty) {
      if (match.reshuffleEnabled && match.discardPile.isNotEmpty) {
        match.activeDeck = ShuffleService.fisherYates(
          List<GameCard>.from(match.discardPile),
          seed: match.shuffleSeed,
        );
        match.discardPile.clear();
      } else {
        _endMatch(match);
        return MatchEngineResult(
          state: match,
          message: 'Deck empty!',
          matchEnded: true,
        );
      }
    }

    var card = match.activeDeck.removeAt(0);
    match.previousCard = match.currentCard;
    match.currentCard = card;
    match.discardPile.add(card);
    match.cardDrawnThisTurn = true;
    match.phase = MatchPhase.challenge;
    match.armorBrokenThisTurn = false;
    match.comboBrokenThisTurn = false;

    if (card.isJack && match.previousCard == null) {
      return _redrawJack(match);
    }

    if (card.isJack && match.previousCard != null) {
      card = card.copyWith(reps: match.previousCard!.reps);
      match.currentCard = card;
    }

    final drawer = match.currentPlayer;
    final kingGroup = card.isKing && !match.houseRules.kingsOptionalSolo;
    final jokerGroup =
        card.isJoker && card.isGroupChallenge && !match.houseRules.jokerGentle;

    if (kingGroup || jokerGroup) {
      match.awaitingGroupResults = true;
      match.groupPendingPlayerIds = match.players
          .where((p) => !p.eliminated)
          .map((p) => p.id)
          .toList();
      match.groupFailCount = 0;
      match.groupPassCount = 0;
      match.groupPlayerCount = match.groupPendingPlayerIds.length;
    }

    if (card.isJoker && match.houseRules.jokerRest) {
      drawer.skips++;
      match.lastFeedbackMessage = '${drawer.name} draws rest — +1 skip';
    }

    if (AbilityModifierEngine.timerEnabledForPlayer(
      drawer,
      modeTimerEnabled: mode.timerEnabled,
      matchForceTimerOff: match.houseRules.forceTimerOff,
    )) {
      match.timerSecondsRemaining = mode.timerSeconds;
      match.timerRunning = true;
    } else {
      match.timerRunning = false;
    }

    final display = AbilityModifierEngine.personalizeCard(card, drawer);
    return MatchEngineResult(
      state: match,
      message: AbilityModifierEngine.challengeLabel(display, drawer),
    );
  }

  MatchEngineResult _redrawJack(MatchState match) {
    match.discardPile.removeLast();
    match.currentCard = null;
    match.cardDrawnThisTurn = false;
    return drawCard(match);
  }

  MatchEngineResult resolveTurn(
    MatchState match,
    String playerId,
    TurnResultType result, {
    int? customReps,
    int? customPoints,
  }) {
    final player = match.players.firstWhere((p) => p.id == playerId);
    final card = match.currentCard;
    if (card == null) return MatchEngineResult(state: match);

    match.turnCount++;
    final logResult = result.name;

    if (match.awaitingGroupResults && (card.isKing || card.isGroupChallenge)) {
      return _resolveGroupPlayer(match, card, playerId, result, logResult);
    }

    var points = 0;
    var livesDelta = 0;
    final reps = customReps ??
        AbilityModifierEngine.effectiveReps(card, player) ??
        card.reps ??
        _defaultReps(card);
    final useElimination =
        match.houseRules.useEliminationWin && mode.eliminationEnabled;

    switch (result) {
      case TurnResultType.pass:
        points = AbilityModifierEngine.scalePoints(
          customPoints ?? _scoreForPass(card, reps),
          player,
        );
        player.score += points;
        player.totalReps += reps;
        player.cardsCompleted++;
        if (card.isKing || card.isGroupChallenge) {
          player.comboContribution++;
        }
        break;
      case TurnResultType.modified:
        final modMult = AbilityModifierEngine.modifiedMultiplier(
          player,
          mode.modifiedScoreMultiplier,
        );
        points = AbilityModifierEngine.scalePoints(
          ((customPoints ?? _scoreForPass(card, reps)) * modMult).round(),
          player,
        );
        player.score += points;
        player.totalReps += (reps * (modMult >= 1.0 ? 1.0 : 0.75)).round();
        player.cardsCompleted++;
        player.modifiedUsed++;
        break;
      case TurnResultType.skip:
        if (player.skips > 0) {
          player.skips--;
          player.skipsUsed++;
        } else {
          return MatchEngineResult(
            state: match,
            message: 'No skip tokens!',
          );
        }
        break;
      case TurnResultType.fail:
        final hadArmor = player.armor > 0;
        if (hadArmor) {
          player.armor--;
          player.armorUsed++;
          match.armorBrokenThisTurn = true;
        } else if (useElimination) {
          player.lives--;
          livesDelta = -1;
          player.cardsFailed++;
          if (player.lives <= 0) {
            player.eliminated = true;
          }
        } else {
          player.cardsFailed++;
        }
        if (card.isKing || card.isGroupChallenge) {
          match.comboChain = 0;
          match.comboBrokenThisTurn = true;
        }
        break;
    }

    match.turnLog.add(TurnLogEntry(
      turnNumber: match.turnCount,
      playerId: player.id,
      playerName: player.name,
      cardId: card.id,
      cardLabel: '${card.rank} ${card.suit.name}',
      result: logResult,
      pointsDelta: points,
      livesDelta: livesDelta,
      comboAfter: match.comboChain,
    ));

    return _endPlayerTurn(match, comboBroken: result == TurnResultType.fail);
  }

  MatchEngineResult _resolveGroupPlayer(
    MatchState match,
    GameCard card,
    String playerId,
    TurnResultType result,
    String logResult,
  ) {
    var resultLabel = logResult;
    if (match.groupPendingPlayerIds.isEmpty ||
        match.groupPendingPlayerIds.first != playerId) {
      return MatchEngineResult(
        state: match,
        message: 'Wait for ${match.groupAdjudicator?.name ?? "next player"}.',
      );
    }

    final player = match.players.firstWhere((p) => p.id == playerId);
    final reps = AbilityModifierEngine.effectiveReps(card, player) ??
        card.reps ??
        rules.kingGroupReps;
    final useElimination =
        match.houseRules.useEliminationWin && mode.eliminationEnabled;
    var points = 0;
    var livesDelta = 0;
    var armorBroken = false;
    var eliminated = false;

    switch (result) {
      case TurnResultType.pass:
        points = AbilityModifierEngine.scalePoints(reps + 5, player);
        player.score += points;
        player.totalReps += reps;
        player.cardsCompleted++;
        player.comboContribution++;
        match.groupPassCount++;
      case TurnResultType.modified:
        final modMult = AbilityModifierEngine.modifiedMultiplier(
          player,
          mode.modifiedScoreMultiplier,
        );
        points = AbilityModifierEngine.scalePoints(
          ((reps + 5) * modMult).round(),
          player,
        );
        player.score += points;
        player.totalReps += (reps * (modMult >= 1.0 ? 1.0 : 0.75)).round();
        player.cardsCompleted++;
        player.modifiedUsed++;
        match.groupPassCount++;
        resultLabel = 'modified';
      case TurnResultType.skip:
        if (player.skips > 0) {
          player.skips--;
          player.skipsUsed++;
          match.groupPassCount++;
        } else {
          return MatchEngineResult(state: match, message: 'No skip tokens!');
        }
      case TurnResultType.fail:
        match.groupFailCount++;
        if (player.armor > 0) {
          player.armor--;
          player.armorUsed++;
          armorBroken = true;
        } else if (useElimination) {
          player.lives--;
          livesDelta = -1;
          player.cardsFailed++;
          if (player.lives <= 0) {
            player.eliminated = true;
            eliminated = true;
          }
        } else {
          player.cardsFailed++;
        }
    }

    match.turnLog.add(TurnLogEntry(
      turnNumber: match.turnCount,
      playerId: player.id,
      playerName: player.name,
      cardId: card.id,
      cardLabel: 'GROUP ${card.rank}',
      result: resultLabel,
      pointsDelta: points,
      livesDelta: livesDelta,
      comboAfter: match.comboChain,
    ));

    match.groupPendingPlayerIds.removeAt(0);

    if (match.groupPendingPlayerIds.isNotEmpty) {
      return MatchEngineResult(
        state: match,
        message: 'Next: ${match.groupAdjudicator?.name}',
        armorBroken: armorBroken,
        playerEliminated: eliminated,
        groupTurnContinues: true,
      );
    }

    match.awaitingGroupResults = false;
    var comboIncreased = false;
    var comboBroken = false;

    final allSucceeded = match.groupFailCount == 0;

    if (allSucceeded) {
      match.comboChain++;
      _applyComboRewards(match);
      match.hypeMeter =
          (match.hypeMeter + rules.hypePerKing).clamp(0, rules.hypeMax);
      comboIncreased = true;
    } else {
      match.comboChain = 0;
      match.comboBrokenThisTurn = true;
      comboBroken = true;
    }

    match.groupFailCount = 0;
    match.groupPassCount = 0;

    return _endPlayerTurn(
      match,
      comboIncreased: comboIncreased,
      comboBroken: comboBroken,
      playerEliminated: eliminated,
    );
  }

  MatchEngineResult _endPlayerTurn(
    MatchState match, {
    bool comboIncreased = false,
    bool comboBroken = false,
    bool playerEliminated = false,
  }) {
    match.cardDrawnThisTurn = false;
    match.currentCard = null;
    match.timerRunning = false;
    match.phase = MatchPhase.draw;

    _checkWinCondition(match);
    if (!match.matchOver) {
      _advanceTurn(match);
    }

    return MatchEngineResult(
      state: match,
      comboIncreased: comboIncreased,
      comboBroken: comboBroken,
      playerEliminated:
          playerEliminated || match.players.any((p) => p.eliminated),
      matchEnded: match.matchOver,
    );
  }

  void _advanceTurn(MatchState match) {
    if (match.players.length <= 1) return;
    var next = match.currentPlayerIndex;
    for (var i = 0; i < match.players.length; i++) {
      next = (next + 1) % match.players.length;
      if (!match.players[next].eliminated) break;
    }
    match.currentPlayerIndex = next;
  }

  void _checkWinCondition(MatchState match) {
    final alive = match.players.where((p) => !p.eliminated).toList();
    if (mode.teamMode) {
      final redAlive =
          alive.where((p) => p.teamId == 'red').toList();
      final blackAlive =
          alive.where((p) => p.teamId == 'black').toList();
      if (redAlive.isEmpty || blackAlive.isEmpty) {
        match.winnerId = redAlive.isNotEmpty ? 'red' : 'black';
        _endMatch(match);
      }
      return;
    }

    final useElimination =
        match.houseRules.useEliminationWin && mode.eliminationEnabled;

    if (useElimination && alive.length <= 1) {
      match.winnerId = alive.isNotEmpty ? alive.first.id : null;
      _endMatch(match);
      return;
    }

    if (match.activeDeck.isEmpty && !match.reshuffleEnabled) {
      if (alive.length == 1) {
        match.winnerId = alive.first.id;
      } else if (match.houseRules.winByCards) {
        alive.sort((a, b) => b.cardsCompleted.compareTo(a.cardsCompleted));
        match.winnerId = alive.first.id;
      } else {
        alive.sort((a, b) => b.score.compareTo(a.score));
        match.winnerId = alive.first.id;
      }
      _endMatch(match);
    }
  }

  void _endMatch(MatchState match) {
    match.matchOver = true;
    match.phase = MatchPhase.over;
    match.timerRunning = false;
  }

  int _defaultReps(GameCard card) {
    if (card.reps != null) return card.reps!;
    if (card.rank == 'A') return rules.aceDefaultReps;
    final n = int.tryParse(card.rank);
    return n ?? 1;
  }

  int _scoreForPass(GameCard card, int reps) {
    if (card.isKing) return rules.kingGroupReps + 5;
    if (card.isQueen) return (card.reps ?? 30) ~/ 2;
    if (card.isJack) return (matchPreviousReps(card));
    return reps;
  }

  int matchPreviousReps(GameCard card) => card.reps ?? 5;

  int _comboBonus(int chain) {
    var bonus = 1;
    for (final r in rules.comboRewards) {
      if (chain >= r.chain) bonus = r.bonusPoints;
    }
    return bonus;
  }

  void _applyComboRewards(MatchState match) {
    for (final r in rules.comboRewards) {
      if (match.comboChain == r.chain) {
        for (final p in match.players.where((x) => !x.eliminated)) {
          p.score += r.bonusPoints;
          if (r.armorAll > 0) p.armor += r.armorAll;
          if (r.skipAll > 0) p.skips += r.skipAll;
        }
      }
    }
  }

  String _challengeText(GameCard card) {
    if (card.isJack) return 'Repeat previous card!';
    if (card.isKing) return 'ALL PLAYERS: ${card.exerciseName} x${card.reps ?? rules.kingGroupReps}';
    if (card.isQueen) return '${card.exerciseName} — ${card.displayReps}';
    if (card.isJoker) return card.exerciseName;
    return '${card.exerciseName} × ${card.displayReps}';
  }

  bool cpuShouldPass(
    PlayerState cpu,
    GameCard card,
    int comboPressure, {
    int matchTurnCount = 0,
  }) {
    if (cpu.npcPassRate != null) {
      var rate = cpu.npcPassRate!;
      if (card.isQueen) rate -= 0.08;
      if (card.isKing) rate -= 0.04;
      if (comboPressure > 3) rate -= 0.04;

      final earlyGame =
          cpu.cardsCompleted < 1 && matchTurnCount <= 4;
      if (earlyGame) {
        rate = rate.clamp(0.75, 1.0);
        if (card.isKing && cpu.cardsCompleted == 0) {
          rate = 0.92;
        }
      }

      final failWeight = cpu.npcFailRate ?? 0.06;
      final roll = _random.nextDouble();
      if (roll < rate) return true;
      if (earlyGame && roll < rate + failWeight * 0.15) {
        return true;
      }
      return false;
    }

    final rates = {
      'easy': 0.45,
      'normal': 0.72,
      'hard': 0.88,
      'beast': 0.96,
    };
    var rate = rates[cpu.cpuDifficulty] ?? 0.72;
    if (card.isQueen) rate -= 0.1;
    if (card.isKing) rate -= 0.05;
    if (comboPressure > 3) rate -= 0.05;
    if (cpu.cardsCompleted < 1 && matchTurnCount <= 4) {
      rate = rate.clamp(0.7, 1.0);
    }
    return _random.nextDouble() < rate;
  }

  MatchState? restoreSnapshot(Map<String, dynamic> json) =>
      MatchState.fromJson(json);
}
