import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/config/deck_art_style.dart';
import '../core/config/game_mode_config.dart';
import '../core/engine/cpu_timing.dart';
import '../core/engine/match_engine.dart';
import '../core/engine/ability_modifier_engine.dart';
import '../core/models/game_card.dart';
import '../core/models/match_house_rules.dart';
import '../core/models/match_state.dart';
import '../core/models/npc_bark.dart';
import '../core/models/player_state.dart';
import '../services/achievement_service.dart';
import '../services/audio_service.dart';
import '../services/custom_card_service.dart';
import '../services/entitlement_service.dart';
import '../services/avatar_catalog.dart';
import '../services/card_back_catalog.dart';
import '../services/npc_registry.dart';
import '../services/rules_loader.dart';
import '../services/save_service.dart';

class PostMatchAward {
  final String playerId;
  final String playerName;
  final String awardTitle;

  const PostMatchAward({
    required this.playerId,
    required this.playerName,
    required this.awardTitle,
  });
}

class GameController extends ChangeNotifier {
  final SaveService saveService;
  final AudioService audio;
  final EntitlementService entitlement;
  final CustomCardService customCards;
  final AchievementService achievements;

  RulesConfig? rules;
  MatchEngine? engine;
  GameModeConfig? currentMode;
  MatchState? match;
  Map<String, dynamic> settings = {};
  Map<String, dynamic> stats = {};
  final List<String> _undoStack = [];
  Timer? _matchTimer;
  Timer? _autoSaveTimer;
  bool paused = false;
  bool showComboOverlay = false;
  bool showArmorBreakOverlay = false;
  bool showWinnerOverlay = false;
  bool showForfeitOverlay = false;
  bool matchEndedForfeited = false;
  String? forfeitPlayerName;
  DeckArtStyle activeDeckArt = DeckArtStyle.defaultArt;
  String? overlayMessage;
  List<PostMatchAward> lastAwards = [];
  List<String> newlyUnlockedAchievements = [];
  DateTime? _lastInputTime;
  static const _inputDebounceMs = 400;
  int _cpuGeneration = 0;
  bool cpuExercising = false;
  String cpuExertionCue = '';
  bool lightDeckActive = false;
  bool soloCanContinuePractice = false;
  TurnResultType? _pendingCpuResult;
  DateTime? _cpuExerciseEndsAt;
  Timer? _cpuExertionTimer;
  int _exertionCueIndex = 0;
  Duration? _cpuPausedRemaining;
  TurnResultType? _cpuPausedResult;
  bool _cpuPausedIsGroup = false;

  static const _exertionCues = [
    'Huff…',
    'Straining…',
    'One more rep…',
    'Grunt!',
    'Pushing through…',
    'Burning…',
    'Hold form…',
    'Dig deep…',
  ];

  Duration? get cpuExerciseRemaining {
    if (!cpuExercising || _cpuExerciseEndsAt == null) return null;
    final left = _cpuExerciseEndsAt!.difference(DateTime.now());
    if (left.isNegative) return Duration.zero;
    return left;
  }
  NpcBark? activeNpcBark;
  Timer? _npcBarkTimer;
  final _rng = Random();
  static const _npcBarkChance = 0.34;
  static const _npcBarkLegendaryChance = 0.07;
  static const _npcBarkDurationMs = 2600;

  GameController({
    required this.saveService,
    required this.audio,
    required this.entitlement,
    required this.customCards,
  }) : achievements = AchievementService(saveService);

  Future<void> initialize() async {
    rules = await RulesLoader.load();
    await NpcRegistry.instance.load();
    await AvatarCatalog.instance.load();
    settings = await saveService.loadSettings();
    stats = await saveService.loadStats();
    final achievements = await saveService.loadAchievements();
    if (achievements.contains('first_deck_complete') &&
        settings['firstDeckComplete'] != true) {
      settings['firstDeckComplete'] = true;
      await saveService.saveSettings(settings);
    }
    if (settings['firstDeckComplete'] == true &&
        stats['firstDeckComplete'] != true) {
      stats['firstDeckComplete'] = true;
      await saveService.saveStats(stats);
    }
    audio.soundEnabled = settings['soundEnabled'] as bool? ?? true;
    audio.musicEnabled = settings['musicEnabled'] as bool? ?? true;
    audio.musicVolume =
        ((settings['musicVolume'] as num?)?.toDouble() ?? 75) / 100.0;
    audio.sfxVolume =
        ((settings['sfxVolume'] as num?)?.toDouble() ?? 100) / 100.0;
    notifyListeners();
  }

  String get cardBackAsset => CardBackCatalog.assetForId(
        settings['cardBackId'] as String?,
      );

  bool get canResume => match != null && match!.phase != MatchPhase.over;

  bool get firstDeckComplete => settings['firstDeckComplete'] == true;

  static bool isDeckCompletion(MatchState match) {
    final size = match.startingDeckSize;
    if (size <= 0) return false;
    if (!match.reshuffleEnabled) {
      return match.activeDeck.isEmpty || match.discardPile.length >= size;
    }
    return match.discardPile.length >= size;
  }

  Future<bool> tryResumeMatch() async {
    final saved = await saveService.loadActiveMatch();
    if (saved == null || saved.matchOver) return false;
    match = saved;
    currentMode = rules!.mode(saved.modeId);
    engine = MatchEngine(rules: rules!, mode: currentMode!);
    notifyListeners();
    return true;
  }

  Future<void> startMatch({
    required String modeId,
    required List<PlayerState> players,
    int? shuffleSeed,
    DeckArtStyle? deckArtStyle,
    bool lightDeck = false,
    MatchHouseRules houseRules = const MatchHouseRules(),
  }) async {
    currentMode = rules!.mode(modeId);
    engine = MatchEngine(rules: rules!, mode: currentMode!);
    final seed = shuffleSeed ??
        (settings['devShuffleSeed'] as int?) ??
        DateTime.now().millisecondsSinceEpoch;

    if (currentMode!.teamMode) {
      for (var i = 0; i < players.length; i++) {
        players[i].teamId = i.isEven ? 'red' : 'black';
      }
    }

    activeDeckArt = deckArtStyle ??
        DeckArtStyleStorage.fromSettings(
          settings['deckArtStyle'] as String?,
        );
    if (!entitlement.isPro) {
      activeDeckArt = DeckArtStyle.defaultArt;
    }

    lightDeckActive = lightDeck;
    match = await engine!.createMatch(
      players: players,
      shuffleSeed: seed,
      deckArtStyle: activeDeckArt,
      lightDeck: lightDeck,
      houseRules: houseRules,
      customCards: entitlement.isPro && activeDeckArt == DeckArtStyle.customTemplate
          ? customCards
          : null,
    );
    matchEndedForfeited = false;
    soloCanContinuePractice = false;
    match!.reshuffleEnabled = currentMode!.reshuffleOnEmpty;
    _undoStack.clear();
    _pushUndo();
    await _autoSave();
    notifyListeners();
  }

  void beginGameplay() {
    if (match == null || engine == null) return;
    engine!.startGameplay(match!);
    match!.phase = MatchPhase.draw;
    audio.playSfx(SfxType.begin);
    _startAutoSaveLoop();
    _scheduleMatchStartBarks();
    notifyListeners();
    if (match!.currentPlayer.isCpu) {
      _maybeCpuTurn();
    }
  }

  bool _debounceInput() {
    final now = DateTime.now();
    if (_lastInputTime != null &&
        now.difference(_lastInputTime!).inMilliseconds < _inputDebounceMs) {
      return false;
    }
    _lastInputTime = now;
    return true;
  }

  Future<void> drawCard() async {
    if (!_debounceInput() || match == null || engine == null || paused) return;
    if (match!.cardDrawnThisTurn) return;
    _pushUndo();
    engine!.drawCard(match!);
    await audio.playSfx(SfxType.cardFlip);
    if (match!.currentCard?.isKing == true) {
      await audio.playSfx(SfxType.king);
    }
    await _autoSave();
    notifyListeners();
    if (match!.awaitingGroupResults) {
      _maybeGroupTeamBarks();
      _maybeCpuGroupAdjudication();
    } else if (match!.currentPlayer.isCpu) {
      _maybeCpuTurn();
    }
  }

  Future<void> resolveResult(TurnResultType type) async {
    if (!_debounceInput() || match == null || engine == null || paused) return;
    if (!match!.cardDrawnThisTurn) return;

    _pushUndo();
    final cardBeforeResolve = match!.currentCard;
    final targetId = match!.awaitingGroupResults
        ? (match!.groupAdjudicator?.id ?? match!.currentPlayer.id)
        : match!.currentPlayer.id;
    final result = engine!.resolveTurn(match!, targetId, type);

    switch (type) {
      case TurnResultType.pass:
        await audio.playSfx(SfxType.pass);
        await audio.playSfx(SfxType.crowdCheer);
        audio.hapticLight();
      case TurnResultType.modified:
        await audio.playSfx(SfxType.pass);
      case TurnResultType.fail:
        await audio.playSfx(SfxType.fail);
        if (result.armorBroken) {
          showArmorBreakOverlay = true;
          await audio.playSfx(SfxType.armorBreak);
        } else {
          await audio.playSfx(SfxType.lifeLost);
        }
        if (result.playerEliminated) {
          await audio.playSfx(SfxType.eliminated);
        }
        audio.hapticHeavy();
      case TurnResultType.skip:
        await audio.playSfx(SfxType.button);
    }

    if (result.comboIncreased) {
      showComboOverlay = true;
      await audio.playSfx(SfxType.combo);
    }
    if (result.comboBroken) {
      await audio.playSfx(SfxType.comboBreak);
      await audio.playSfx(SfxType.crowdBoo);
    }

    _maybeRespectBarkAfterHumanPlay(
      playerId: targetId,
      type: type,
      card: cardBeforeResolve,
      comboIncreased: result.comboIncreased,
    );

    if (result.matchEnded) {
      await _finishMatch();
    } else if (result.groupTurnContinues) {
      _maybeCpuGroupAdjudication();
    } else if (match!.currentPlayer.isCpu && !match!.matchOver) {
      _maybeCpuTurn();
    }

    await _autoSave();
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      showComboOverlay = false;
      showArmorBreakOverlay = false;
      notifyListeners();
    });
  }

  void _maybeCpuTurn() {
    final gen = ++_cpuGeneration;
    Future(() async {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!_cpuTurnStillValid(gen)) return;
      if (match!.awaitingGroupResults) {
        _maybeCpuGroupAdjudication();
        return;
      }
      final current = match!.currentPlayer;
      if (!current.isCpu) return;

      if (!match!.cardDrawnThisTurn) {
        await drawCard();
        return;
      }

      final card = match!.currentCard!;
      final useModified = CpuTiming.cpuLikelyModified(current, card);
      final pass = engine!.cpuShouldPass(
        current,
        card,
        match!.comboChain,
        matchTurnCount: match!.turnCount,
      );

      final result = !pass
          ? TurnResultType.fail
          : (useModified ? TurnResultType.modified : TurnResultType.pass);

      _maybeShowNpcBark(current, _barkKindForCpuTurn(result, card));

      final completed = await _runCpuExerciseDelay(
        gen: gen,
        player: current,
        card: card,
        result: result,
        useModified: useModified,
      );
      if (completed) {
        await resolveResult(result);
      }
    });
  }

  void _maybeCpuGroupAdjudication() {
    final gen = _cpuGeneration;
    Future(() async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!_cpuTurnStillValid(gen)) return;
      if (!match!.awaitingGroupResults) return;
      final adj = match!.groupAdjudicator;
      if (adj == null || !adj.isCpu) return;

      final card = match!.currentCard!;
      final useModified = CpuTiming.cpuLikelyModified(adj, card);
      final pass = engine!.cpuShouldPass(
        adj,
        card,
        match!.comboChain,
        matchTurnCount: match!.turnCount,
      );

      final result = !pass
          ? TurnResultType.fail
          : (useModified ? TurnResultType.modified : TurnResultType.pass);

      _maybeShowNpcBark(adj, _barkKindForCpuTurn(result, card));

      final completed = await _runCpuExerciseDelay(
        gen: gen,
        player: adj,
        card: card,
        result: result,
        useModified: useModified,
      );
      if (completed) {
        await resolveResult(result);
      }
    });
  }

  bool _cpuTurnStillValid(int gen) =>
      gen == _cpuGeneration &&
      match != null &&
      !match!.matchOver &&
      !paused;

  void _startExertionTicker() {
    _exertionCueIndex = 0;
    cpuExertionCue = _exertionCues.first;
    _cpuExertionTimer?.cancel();
    _cpuExertionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _exertionCueIndex = (_exertionCueIndex + 1) % _exertionCues.length;
      cpuExertionCue = _exertionCues[_exertionCueIndex];
      notifyListeners();
    });
  }

  void _stopExertionTicker() {
    _cpuExertionTimer?.cancel();
    _cpuExertionTimer = null;
    cpuExertionCue = '';
    _cpuExerciseEndsAt = null;
  }

  void _clearCpuExerciseState() {
    cpuExercising = false;
    _pendingCpuResult = null;
    _stopExertionTicker();
  }

  /// Returns true if exercise finished and [result] should be resolved.
  Future<bool> _runCpuExerciseDelay({
    required int gen,
    required PlayerState player,
    required GameCard card,
    required TurnResultType result,
    required bool useModified,
  }) async {
    _pendingCpuResult = result;
    cpuExercising = true;
    _startExertionTicker();
    notifyListeners();

    final delay = CpuTiming.estimateExerciseDelay(
      card,
      player,
      willUseModified: useModified,
    );
    _cpuExerciseEndsAt = DateTime.now().add(delay);

    final finished = await _waitCpuExerciseWindow(gen);
    if (!finished) {
      if (!paused) {
        _clearCpuExerciseState();
      }
      return false;
    }

    _clearCpuExerciseState();
    return true;
  }

  Future<bool> _waitCpuExerciseWindow(int gen) async {
    while (true) {
      if (gen != _cpuGeneration || match == null || match!.matchOver) {
        return false;
      }
      if (paused) {
        return false;
      }
      final end = _cpuExerciseEndsAt;
      if (end == null) return false;
      final remaining = end.difference(DateTime.now());
      if (remaining <= Duration.zero) break;
      final wait = remaining > const Duration(milliseconds: 250)
          ? const Duration(milliseconds: 250)
          : remaining;
      await Future.delayed(wait);
    }
    return gen == _cpuGeneration &&
        match != null &&
        !match!.matchOver &&
        !paused;
  }

  void _resumeCpuExerciseAfterPause() {
    final result = _cpuPausedResult!;
    final remaining = _cpuPausedRemaining ?? Duration.zero;
    final isGroup = _cpuPausedIsGroup;
    _cpuPausedResult = null;
    _cpuPausedRemaining = null;

    final gen = ++_cpuGeneration;
    Future(() async {
      if (match == null || match!.matchOver || paused) return;

      if (isGroup) {
        if (!match!.awaitingGroupResults) {
          _maybeCpuGroupAdjudication();
          return;
        }
        final adj = match!.groupAdjudicator;
        if (adj == null || !adj.isCpu) return;
      } else {
        if (!match!.currentPlayer.isCpu) return;
        if (!match!.cardDrawnThisTurn) {
          await drawCard();
          return;
        }
      }

      _pendingCpuResult = result;
      cpuExercising = true;
      _startExertionTicker();
      _cpuExerciseEndsAt = DateTime.now().add(remaining);
      notifyListeners();

      final finished = await _waitCpuExerciseWindow(gen);
      if (!finished) {
        if (!paused) _clearCpuExerciseState();
        return;
      }

      _clearCpuExerciseState();
      await resolveResult(result);
    });
  }

  NpcBarkKind _barkKindForCpuTurn(TurnResultType result, GameCard card) {
    if (result == TurnResultType.fail) {
      if (_rng.nextDouble() < 0.58) return NpcBarkKind.humiliated;
      return NpcBarkKind.forfeit;
    }
    if (result == TurnResultType.modified) {
      if (_rng.nextDouble() < 0.32) return NpcBarkKind.pain;
      return NpcBarkKind.modified;
    }
    final reps = card.reps ?? int.tryParse(card.rank) ?? 0;
    final tough =
        reps >= 8 || card.isQueen || card.isKing || card.isJoker;
    if (tough) {
      final roll = _rng.nextDouble();
      if (roll < 0.22) return NpcBarkKind.pain;
      if (roll < 0.55) return NpcBarkKind.clutch;
    }
    return NpcBarkKind.victory;
  }

  void _maybeRespectBarkAfterHumanPlay({
    required String playerId,
    required TurnResultType type,
    required GameCard? card,
    required bool comboIncreased,
  }) {
    if (match == null) return;

    PlayerState? human;
    for (final p in match!.players) {
      if (p.id == playerId) {
        human = p;
        break;
      }
    }
    if (human == null || human.isCpu) return;
    if (type == TurnResultType.fail || type == TurnResultType.skip) return;

    var trigger = comboIncreased && match!.comboChain >= 3;
    if (!trigger && card != null) {
      final reps = card.reps ?? int.tryParse(card.rank) ?? 0;
      trigger = reps >= 8 || card.isQueen || card.isKing || card.isJoker;
    }
    if (!trigger) return;

    final cpus = match!.players
        .where((p) => p.isCpu && !p.eliminated && p.npcProfileId != null)
        .toList();
    if (cpus.isEmpty) return;

    final cpu = cpus[_rng.nextInt(cpus.length)];
    _maybeShowNpcBark(
      cpu,
      NpcBarkKind.respect,
      chance: 0.42,
      delayMs: 700,
      allowLegendaryOverride: false,
    );
  }

  void _scheduleMatchStartBarks() {
    if (match == null) return;
    final cpus = match!.players
        .where((p) => p.isCpu && p.npcProfileId != null)
        .toList();
    var delay = 500;
    for (final cpu in cpus) {
      _maybeShowNpcBark(
        cpu,
        NpcBarkKind.startMatch,
        chance: 0.52,
        delayMs: delay,
      );
      delay += _npcBarkDurationMs + 200;
    }
  }

  void _maybeGroupTeamBarks() {
    if (match == null) return;
    final card = match!.currentCard;
    if (card == null || (!card.isKing && !card.isGroupChallenge)) return;

    final cpus = match!.players
        .where((p) => p.isCpu && !p.eliminated && p.npcProfileId != null)
        .toList();
    if (cpus.isEmpty) return;

    final multiPlayer = match!.players.where((p) => !p.eliminated).length > 2;
    if (!multiPlayer && currentMode?.teamMode != true) return;

    var delay = 400;
    final count = cpus.length > 2 ? 2 : cpus.length;
    for (var i = 0; i < count; i++) {
      _maybeShowNpcBark(
        cpus[i],
        NpcBarkKind.teamUp,
        chance: 0.4,
        delayMs: delay,
      );
      delay += _npcBarkDurationMs + 250;
    }
  }

  void _maybeShowNpcBark(
    PlayerState cpu,
    NpcBarkKind kind, {
    double chance = _npcBarkChance,
    int delayMs = 0,
    bool allowLegendaryOverride = true,
  }) {
    void show() {
      if (match == null || match!.matchOver || paused) return;
      if (!cpu.isCpu || cpu.npcProfileId == null) return;
      if (_rng.nextDouble() > chance) return;

      final profile = NpcRegistry.instance.byId(cpu.npcProfileId);
      if (profile == null) return;

      var kindToUse = kind;
      final noLegendary = kind == NpcBarkKind.respect ||
          kind == NpcBarkKind.pain ||
          kind == NpcBarkKind.humiliated;
      if (allowLegendaryOverride &&
          !noLegendary &&
          profile.quotesLegendary.isNotEmpty &&
          _rng.nextDouble() < _npcBarkLegendaryChance) {
        kindToUse = NpcBarkKind.legendary;
      }

      final line = profile.pickQuote(kindToUse);
      if (line == null) return;

      _npcBarkTimer?.cancel();
      activeNpcBark = NpcBark(
        speakerName: profile.name,
        color: profile.color,
        message: line,
        kind: kindToUse,
      );
      _npcBarkTimer = Timer(
        const Duration(milliseconds: _npcBarkDurationMs),
        () {
          activeNpcBark = null;
          notifyListeners();
        },
      );
      notifyListeners();
    }

    if (delayMs > 0) {
      Future.delayed(Duration(milliseconds: delayMs), show);
    } else {
      show();
    }
  }

  void _clearNpcBark() {
    _npcBarkTimer?.cancel();
    _npcBarkTimer = null;
    activeNpcBark = null;
  }

  Future<void> undoLastResult() async {
    if (_undoStack.length <= 1 || match == null) return;
    _undoStack.removeLast();
    final json = jsonDecode(_undoStack.last) as Map<String, dynamic>;
    match = MatchState.fromJson(json);
    await _autoSave();
    notifyListeners();
  }

  void _pushUndo() {
    if (match == null) return;
    _undoStack.add(jsonEncode(match!.toJson()));
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  void skipCpuWait() {
    if (!cpuExercising || _pendingCpuResult == null) return;
    _cpuPausedResult = null;
    _cpuPausedRemaining = null;
    _cpuGeneration++;
    final result = _pendingCpuResult!;
    _clearCpuExerciseState();
    resolveResult(result);
  }

  void pauseMatch() {
    if (cpuExercising && _pendingCpuResult != null) {
      _cpuPausedResult = _pendingCpuResult;
      _cpuPausedIsGroup = match?.awaitingGroupResults ?? false;
      if (_cpuExerciseEndsAt != null) {
        _cpuPausedRemaining = _cpuExerciseEndsAt!.difference(DateTime.now());
        if (_cpuPausedRemaining!.isNegative) {
          _cpuPausedRemaining = Duration.zero;
        }
      } else {
        _cpuPausedRemaining = Duration.zero;
      }
    }
    _cpuGeneration++;
    cpuExercising = false;
    _pendingCpuResult = null;
    _stopExertionTicker();
    _clearNpcBark();
    paused = true;
    match?.phase = MatchPhase.paused;
    match?.timerRunning = false;
    _matchTimer?.cancel();
    notifyListeners();
  }

  void resumeMatch() {
    paused = false;
    if (match != null && !match!.cardDrawnThisTurn) {
      match!.phase = MatchPhase.draw;
    } else if (match != null) {
      match!.phase = MatchPhase.challenge;
    }
    notifyListeners();

    if (match == null || match!.matchOver) return;

    if (_cpuPausedResult != null) {
      _resumeCpuExerciseAfterPause();
      return;
    }

    if (match!.currentPlayer.isCpu || match!.awaitingGroupResults) {
      _maybeCpuTurn();
    }
  }

  Future<void> forfeitMatch() async {
    matchEndedForfeited = true;
    forfeitPlayerName = match?.currentPlayer.name;
    if (match != null) {
      match!.matchOver = true;
      match!.phase = MatchPhase.over;
      match!.winnerId = null;
    }
    await audio.playSfx(SfxType.forfeit);
    await _finishMatch(forfeited: true);
    notifyListeners();
  }

  Future<void> restartMatch() async {
    if (match == null || currentMode == null) return;
    final modeId = match!.modeId;
    final players = match!.players.map(_clonePlayerForRestart).toList();
    paused = false;
    await startMatch(
      modeId: modeId,
      players: players,
      deckArtStyle: activeDeckArt,
      lightDeck: lightDeckActive,
      houseRules: match!.houseRules,
    );
    notifyListeners();
  }

  Future<void> _maybeMarkFirstDeckComplete() async {
    if (firstDeckComplete || match == null) return;
    if (!isDeckCompletion(match!)) return;
    settings['firstDeckComplete'] = true;
    stats['firstDeckComplete'] = true;
    await saveService.saveSettings(settings);
    await saveService.saveStats(stats);
    await saveService.unlockAchievement('first_deck_complete');
    notifyListeners();
  }

  Future<void> _finishMatch({bool forfeited = false}) async {
    matchEndedForfeited = forfeited;
    soloCanContinuePractice = _computeSoloContinueOffer();
    _matchTimer?.cancel();
    _autoSaveTimer?.cancel();
    await audio.stopMusic();
    if (!forfeited) {
      await audio.playSfx(SfxType.victory);
    }

    if (match != null && !forfeited) {
      await _maybeMarkFirstDeckComplete();
      lastAwards = _calculateAwards(match!);
      final winners =
          match!.players.where((p) => p.id == match!.winnerId).toList();
      final winner = winners.isNotEmpty ? winners.first : null;
      if (winner != null) {
        newlyUnlockedAchievements = await achievements.evaluate(
          player: winner,
          match: match,
          stats: stats,
        );
        stats['wins'] = (stats['wins'] as int? ?? 0) + 1;
      }
      var totalReps = 0;
      for (final p in match!.players) {
        totalReps += p.totalReps;
      }
      stats['lifetimeReps'] = (stats['lifetimeReps'] as int? ?? 0) + totalReps;
      stats['matchesPlayed'] = (stats['matchesPlayed'] as int? ?? 0) + 1;
      if (match!.comboChain > (stats['bestCombo'] as int? ?? 0)) {
        stats['bestCombo'] = match!.comboChain;
      }
      final xpGain = 25 + totalReps ~/ 5;
      stats['xp'] = (stats['xp'] as int? ?? 0) + xpGain;
      stats['level'] = 1 + ((stats['xp'] as int) ~/ 100);
      await saveService.saveStats(stats);
    }

    await saveService.saveActiveMatch(null);
    notifyListeners();
  }

  List<PostMatchAward> _calculateAwards(MatchState m) {
    final awards = <PostMatchAward>[];
    if (m.players.isEmpty) return awards;

    PlayerState top(PlayerState Function(PlayerState, PlayerState) cmp) {
      return m.players.reduce(cmp);
    }

    final mostReps = top((a, b) => a.totalReps >= b.totalReps ? a : b);
    awards.add(PostMatchAward(
      playerId: mostReps.id,
      playerName: mostReps.name,
      awardTitle: 'Iron Will — Most Reps',
    ));

    final mostCards = top((a, b) =>
        a.cardsCompleted >= b.cardsCompleted ? a : b);
    awards.add(PostMatchAward(
      playerId: mostCards.id,
      playerName: mostCards.name,
      awardTitle: 'Card Shark',
    ));

    final bestCombo = top((a, b) =>
        a.comboContribution >= b.comboContribution ? a : b);
    if (bestCombo.comboContribution > 0) {
      awards.add(PostMatchAward(
        playerId: bestCombo.id,
        playerName: bestCombo.name,
        awardTitle: 'Combo King',
      ));
    }

    final winner = m.players.where((p) => p.id == m.winnerId).firstOrNull;
    if (winner != null && winner.lives == 1) {
      awards.add(PostMatchAward(
        playerId: winner.id,
        playerName: winner.name,
        awardTitle: 'Last Stand',
      ));
    }

    return awards;
  }

  void _startAutoSaveLoop() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 8), (_) => _autoSave());
  }

  Future<void> _autoSave() async {
    if (match != null && !match!.matchOver) {
      await saveService.saveActiveMatch(match);
    }
  }

  Future<void> onAppLifecyclePaused() async {
    if (match != null && !match!.matchOver) {
      pauseMatch();
      await _autoSave();
    }
  }

  Future<void> updateSettings(Map<String, dynamic> patch) async {
    settings.addAll(patch);
    audio.soundEnabled = settings['soundEnabled'] as bool? ?? true;
    audio.musicEnabled = settings['musicEnabled'] as bool? ?? true;
    audio.musicVolume =
        ((settings['musicVolume'] as num?)?.toDouble() ?? 75) / 100.0;
    audio.sfxVolume =
        ((settings['sfxVolume'] as num?)?.toDouble() ?? 100) / 100.0;
    await audio.applyVolumes();
    if (patch.containsKey('musicEnabled')) {
      await audio.syncMusicEnabled();
    }
    await saveService.saveSettings(settings);
    notifyListeners();
  }

  bool _computeSoloContinueOffer() {
    if (match == null || match!.modeId != 'solo') return false;
    final humans = match!.players.where((p) => !p.isCpu && !p.eliminated);
    if (humans.isEmpty) return false;
    final cpus = match!.players.where((p) => p.isCpu);
    if (cpus.isEmpty) return false;
    final npcOut = cpus.any((p) => p.eliminated || p.lives <= 0);
    return npcOut && humans.length == 1;
  }

  Future<void> continueSoloPractice() async {
    if (match == null || engine == null) return;
    final human = match!.players.firstWhere(
      (p) => !p.isCpu && !p.eliminated,
      orElse: () => match!.players.first,
    );
    match!.players.removeWhere((p) => p.isCpu);
    match!.matchOver = false;
    match!.winnerId = null;
    match!.phase = MatchPhase.draw;
    match!.cardDrawnThisTurn = false;
    match!.currentCard = null;
    match!.previousCard = null;
    match!.awaitingGroupResults = false;
    match!.groupPendingPlayerIds.clear();
    match!.currentPlayerIndex =
        match!.players.indexWhere((p) => p.id == human.id).clamp(0, match!.players.length - 1);
    soloCanContinuePractice = false;
    await _autoSave();
    notifyListeners();
  }

  void clearMatch() {
    match = null;
    _undoStack.clear();
    _matchTimer?.cancel();
    _autoSaveTimer?.cancel();
    _cpuGeneration++;
    _cpuPausedResult = null;
    _cpuPausedRemaining = null;
    _clearCpuExerciseState();
    _clearNpcBark();
    matchEndedForfeited = false;
    forfeitPlayerName = null;
    soloCanContinuePractice = false;
    notifyListeners();
  }

  PlayerState _clonePlayerForRestart(PlayerState p) {
    if (p.npcProfileId != null) {
      final profile = NpcRegistry.instance.byId(p.npcProfileId);
      if (profile != null && currentMode != null) {
        return NpcRegistry.instance.toPlayer(profile, currentMode!);
      }
    }
    return newPlayer(
      p.name,
      p.color,
      isCpu: p.isCpu,
      difficulty: p.cpuDifficulty,
      avatarId: p.avatarId,
      avatarAsset: p.avatarAsset,
      abilityModifierId: p.abilityModifierId,
    );
  }

  static List<Color> playerColors = [
    Colors.redAccent,
    Colors.cyanAccent,
    Colors.limeAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.amberAccent,
  ];

  GameCard? personalizedCardFor(PlayerState player) {
    final card = match?.currentCard;
    if (card == null) return null;
    return AbilityModifierEngine.personalizeCard(card, player);
  }

  static PlayerState newPlayer(
    String name,
    Color color, {
    bool isCpu = false,
    String difficulty = 'normal',
    String? avatarId,
    String? avatarAsset,
    String abilityModifierId = 'standard',
  }) {
    final id = avatarId ?? AvatarCatalog.defaultPlayerAvatarId;
    return PlayerState(
      id: const Uuid().v4(),
      name: name,
      color: color,
      lives: 3,
      isCpu: isCpu,
      cpuDifficulty: difficulty,
      avatarId: id,
      avatarAsset: avatarAsset ?? AvatarCatalog.instance.assetForId(id),
      abilityModifierId: abilityModifierId,
    );
  }
}
