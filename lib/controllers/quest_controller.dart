import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../core/data/deck_factory.dart';
import '../core/engine/quest_cpu.dart';
import '../core/engine/quest_engine.dart';
import '../core/engine/quest_modifier_engine.dart';
import '../core/models/ability_modifier.dart';
import '../core/engine/quest_map_layout.dart';
import '../core/models/game_card.dart';
import '../core/models/quest/quest_dungeon.dart';
import '../core/models/quest/quest_map_node.dart';
import '../core/models/quest/quest_item.dart';
import '../core/models/quest/quest_player_state.dart';
import '../core/models/quest/quest_run_state.dart';
import '../core/services/shuffle_service.dart';
import '../services/audio_service.dart';
import '../services/quest_asset_catalog.dart';
import '../services/quest_data_loader.dart';
import '../services/quest_narration.dart';
import '../services/save_service.dart';

class QuestController extends ChangeNotifier {
  QuestController({
    required this.saveService,
    required this.audio,
  });

  final SaveService saveService;
  final AudioService audio;
  QuestDataBundle? data;
  QuestEngine? engine;
  QuestRunState? run;
  QuestNarration? narration;
  bool canResumeQuest = false;
  bool cpuExercising = false;
  String cpuExertionCue = '';

  Timer? _barkTimer;
  Timer? _autoSaveTimer;
  Timer? _cpuExertionTimer;
  int _cpuGeneration = 0;
  DateTime? _cpuExerciseEndsAt;
  static const _exertionCues = [
    'Working through the reps…',
    'Feeling the burn…',
    'Almost there…',
    'Pushing through…',
  ];
  int _exertionCueIndex = 0;

  Future<void> initialize() async {
    data = await QuestDataLoader.load();
    engine = QuestEngine(data!);
    canResumeQuest = await saveService.loadActiveQuest() != null;
    notifyListeners();
  }

  Future<bool> tryResumeQuest() async {
    final saved = await saveService.loadActiveQuest();
    if (saved == null || saved.runComplete) return false;
    run = saved;
    final bundle = data ?? await QuestDataLoader.load();
    engine = QuestEngine(bundle);
    narration = QuestNarration.fromStory(bundle.story);
    if (run!.mapNodes.isEmpty) {
      _rebuildMapFromProgress();
    }
    if (run!.phase != QuestPhase.map &&
        run!.phase != QuestPhase.runWon &&
        run!.phase != QuestPhase.runLost &&
        run!.currentMapNode == null &&
        !run!.runComplete) {
      run!.phase = QuestPhase.map;
    }
    notifyListeners();
    return true;
  }

  Future<void> startRun({
    required String dungeonId,
    required String difficultyId,
    required List<QuestPlayerState> players,
    int? seed,
  }) async {
    final bundle = data ?? await QuestDataLoader.load();
    final runSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    engine = QuestEngine(bundle, seed: runSeed);
    narration = QuestNarration.fromStory(bundle.story, seed: runSeed);
    final diff = bundle.difficulty(difficultyId);
    final dungeonTemplate = bundle.dungeon(dungeonId);

    var deck = await DeckFactory.buildStandardDeck();
    deck = ShuffleService.fisherYates(deck, seed: runSeed);

    final roster = players.map((p) {
      final copy = QuestPlayerState(
        id: p.id,
        name: p.name,
        colorValue: p.colorValue,
        avatarId: p.avatarId,
        hp: diff.playerHp,
        maxHp: diff.playerHp,
        skips: 1,
        isCpu: p.isCpu,
        title: p.title,
        npcProfileId: p.npcProfileId,
        npcPassRate: p.npcPassRate,
        npcModifiedRate: p.npcModifiedRate,
        npcFailRate: p.npcFailRate,
        npcTimingMultiplier: p.npcTimingMultiplier,
        abilityModifierId: p.abilityModifierId,
      );
      if (!p.isCpu) {
        QuestModifierEngine.applyStartingStats(
          copy,
          AbilityModifiers.get(p.abilityModifierId),
          diff.playerHp,
        );
      }
      engine!.applyRelicsOnRunStart(copy);
      return copy;
    }).toList();

    final mapNodes = QuestMapLayout.build(
      dungeon: dungeonTemplate,
      seed: runSeed,
    );

    run = QuestRunState(
      dungeonId: dungeonId,
      difficultyId: difficultyId,
      roomIndex: 1,
      players: roster,
      activePlayerIndex: 0,
      deck: deck,
      discard: [],
      phase: QuestPhase.map,
      mapNodes: mapNodes,
      entryReason: narration!.pickEntryReason(),
      campaignAnnouncerLine:
          'ACT I — ${narration!.actTitle(1)}: ${narration!.pickActTransition(1)}',
      lastActAnnounced: 1,
      mapLayoutSeed: runSeed,
    );

    run!.lastMessage = run!.entryReason;
    _showBark('Announcer', run!.campaignAnnouncerLine ?? '');
    await _autoSave();
    notifyListeners();
  }

  void _rebuildMapFromProgress() {
    if (run == null || data == null) return;
    final d = dungeon;
    run!.mapNodes = QuestMapLayout.build(
      dungeon: d,
      seed: run!.mapLayoutSeed,
    );
    for (final n in run!.mapNodes) {
      if (n.roomIndex < run!.roomIndex) {
        n.status = QuestMapNodeStatus.completed;
      } else if (n.roomIndex == run!.roomIndex) {
        n.status = QuestMapNodeStatus.current;
      } else {
        n.status = QuestMapNodeStatus.hidden;
      }
    }
  }

  void enterMapRoom(int roomIndex) {
    if (run == null) return;
    QuestMapNode? node;
    for (final n in run!.mapNodes) {
      if (n.roomIndex == roomIndex) {
        node = n;
        break;
      }
    }
    if (node == null || node.status != QuestMapNodeStatus.current) return;

    run!.roomIndex = roomIndex;
    run!.roomIntroNarration = narration!.pickRoomIntro(node.roomType);
    run!.lastMessage = run!.roomIntroNarration;
    run!.phase = QuestPhase.roomIntro;
    _showBark('Announcer', run!.roomIntroNarration!);
    notifyListeners();
  }

  void _completeMapNode({bool wasBoss = false}) {
    final node = run!.currentMapNode;
    if (node == null) return;

    node.status = QuestMapNodeStatus.completed;
    final idx = run!.mapNodes.indexWhere((n) => n.roomIndex == node.roomIndex);
    if (idx + 1 < run!.mapNodes.length) {
      run!.mapNodes[idx + 1].status = QuestMapNodeStatus.current;
    }

    if (wasBoss) {
      final line = narration!.pickPostBossVictory();
      run!.lastMessage = line;
      _showBark('Announcer', line);
    }

    _refreshCampaignAct();

    if (run!.mapNodes.every((n) => n.status == QuestMapNodeStatus.completed)) {
      _endRun(won: true);
      return;
    }

    run!.phase = QuestPhase.map;
    run!.enemy = null;
    run!.currentCard = null;
    run!.combatRoomAssetPath = null;
    if (!wasBoss) {
      run!.lastMessage = 'Choose your next location on the map.';
    }
  }

  void _refreshCampaignAct() {
    final act = narration!.actForRoom(run!.roomIndex, dungeon.roomCount);
    if (act > run!.lastActAnnounced) {
      run!.lastActAnnounced = act;
      run!.campaignAnnouncerLine =
          'ACT $act — ${narration!.actTitle(act)}: ${narration!.pickActTransition(act)}';
      _showBark('Announcer', run!.campaignAnnouncerLine!);
    }
  }

  QuestDungeonTemplate get dungeon =>
      data!.dungeon(run!.dungeonId);

  QuestDifficulty get difficulty =>
      data!.difficulty(run!.difficultyId);

  QuestRoomSpec get currentRoomSpec =>
      engine!.roomSpec(dungeon, run!.roomIndex);

  Future<void> proceedFromRoomIntro() async {
    if (run == null) return;
    final spec = currentRoomSpec;

    switch (spec.type) {
      case QuestRoomType.rest:
        for (final p in run!.livingPlayers) {
          p.heal(1);
        }
        run!.lastMessage = 'Rest Room — everyone heals 1 HP.';
        _showBark('Rest Shrine', 'Warm fire restores your strength.');
        await _finishRoom();
        break;
      case QuestRoomType.trap:
        run!.activePlayer.takeDamage(1);
        run!.lastMessage = 'Trap! ${run!.activePlayer.name} takes 1 damage.';
        _showBark('Trap', 'Watch your step!');
        if (run!.activePlayer.eliminated) {
          _checkRunEnd();
        } else {
          await _startCombatRoom();
        }
        break;
      case QuestRoomType.treasure:
        run!.pendingLootIds = engine!.rollRoomLoot(spec);
        run!.phase = QuestPhase.roomClear;
        run!.awaitingLootChoice = true;
        run!.lastMessage = 'Treasure Room!';
        _showBark('Chest', 'Loot awaits!');
        break;
      case QuestRoomType.boss:
      case QuestRoomType.combat:
        await _startCombatRoom();
        break;
      case QuestRoomType.npc:
        run!.lastMessage = 'Friendly trainer — +1 skip.';
        run!.activePlayer.skips++;
        await _finishRoom();
        break;
    }
    await _autoSave();
    notifyListeners();
  }

  Future<void> _startCombatRoom() async {
    final spec = currentRoomSpec;
    final isBoss = spec.type == QuestRoomType.boss;
    final enemyTemplateId = engine!.pickEnemyTemplateId(
      dungeon: dungeon,
      roomIndex: run!.roomIndex,
      spec: spec,
    );
    run!.enemy = engine!.spawnEnemy(
      dungeon: dungeon,
      difficulty: difficulty,
      roomIndex: run!.roomIndex,
      spec: spec,
      templateId: enemyTemplateId,
    );
    final roomArt = QuestAssetCatalog.instance.pickRoomBackground(
      spec.type,
      Random(run!.mapLayoutSeed + run!.roomIndex * 31),
      dungeonId: dungeon.id,
      enemyId: enemyTemplateId,
    );
    run!.combatRoomAssetPath = roomArt.bundleKey;
    run!.phase = QuestPhase.draw;
    run!.lastMessage = isBoss
        ? 'BOSS ROOM — ${run!.enemy!.name}!'
        : 'Combat — ${run!.enemy!.name} appears!';
    final bark = engine!.enemyBark(run!.enemy!, 'start');
    _showBark(run!.enemy!.name, bark.isEmpty ? 'Battle!' : bark);
    await _autoSave();
    notifyListeners();
    _maybeCpuTurn();
  }

  void drawCard() {
    if (run == null || run!.phase != QuestPhase.draw) return;
    final card = engine!.drawCard(run!);
    run!.phase = card.isJoker ? QuestPhase.jokerChoice : QuestPhase.challenge;
    run!.lastMessage = engine!.challengeText(card);
    _showBark('Card Draw', '${engine!.cardRpgAction(card)} — ${card.rank}');
    audio.playSfx(SfxType.cardFlip);
    notifyListeners();
    if (run!.phase == QuestPhase.jokerChoice && run!.activePlayer.isCpu) {
      _cpuPickJoker();
    } else {
      _maybeCpuTurn();
    }
  }

  Future<void> resolveTurn(
    TurnResultType result, {
    String? jokerChoice,
  }) async {
    if (run == null || run!.phase == QuestPhase.draw) return;
    if (run!.phase == QuestPhase.jokerChoice &&
        result == TurnResultType.pass &&
        jokerChoice == null) {
      return;
    }

    final outcome = engine!.resolveTurn(
      run: run!,
      result: result,
      jokerChoice: jokerChoice,
    );
    run!.lastMessage = outcome.message;
    run!.currentCard = null;
    run!.cardDrawnThisTurn = false;

    if (outcome.barkKind != null && run!.enemy != null) {
      _showBark(
        run!.enemy!.name,
        engine!.enemyBark(run!.enemy!, outcome.barkKind!),
      );
    }

    if (outcome.comboBroken) {
      _showBark('Combo', 'Combo broken!');
    } else if (run!.combo >= 3) {
      _showBark('Combo', 'Combo x${run!.combo}!');
    }

    switch (result) {
      case TurnResultType.pass:
        await audio.playSfx(SfxType.pass);
        break;
      case TurnResultType.fail:
        await audio.playSfx(SfxType.fail);
        break;
      default:
        await audio.playSfx(SfxType.button);
    }

    if (outcome.enemyDefeated) {
      await audio.playSfx(SfxType.enemyDefeated);
      final spec = currentRoomSpec;
      run!.pendingLootIds.addAll(
        engine!.rollRoomLoot(spec, isBoss: run!.enemy!.isBoss),
      );
      run!.enemy = null;
      await _finishRoom();
    } else if (run!.allPlayersDead) {
      _endRun(won: false);
    } else if (run!.enemy != null) {
      if (run!.livingPlayers.length > 1) {
        _advanceActivePlayer();
      }
      run!.phase = QuestPhase.draw;
      final who = run!.activePlayer;
      run!.lastMessage = who.isCpu
          ? '${outcome.message}\n${who.name} is up…'
          : '${outcome.message}\n${who.name}\'s turn — tap the deck.';
    } else {
      if (run!.livingPlayers.isEmpty) {
        _endRun(won: false);
      } else {
        run!.phase = QuestPhase.draw;
      }
    }

    await _autoSave();
    notifyListeners();
    _maybeCpuTurn();
  }

  void pickJoker(String choice) {
    if (run?.phase != QuestPhase.jokerChoice) return;
    resolveTurn(TurnResultType.pass, jokerChoice: choice);
  }

  Future<void> _finishRoom() async {
    run!.totalRoomsCleared++;
    if (run!.pendingLootIds.isNotEmpty) {
      run!.phase = QuestPhase.roomClear;
      run!.awaitingLootChoice = true;
      notifyListeners();
      return;
    }
    final wasBoss = currentRoomSpec.type == QuestRoomType.boss;
    run!.phase = QuestPhase.roomClear;
    if (run!.pendingLootIds.isEmpty) {
      _completeMapNode(wasBoss: wasBoss);
    }
    notifyListeners();
  }

  void _maybeEndRunAfterLoot() {
    if (run!.pendingLootIds.isNotEmpty) return;
    if (run!.mapNodes.isNotEmpty &&
        run!.mapNodes.every((n) => n.status == QuestMapNodeStatus.completed)) {
      _endRun(won: true);
    }
  }

  Future<void> lootChoice({
    required String itemId,
    required bool equip,
  }) async {
    if (run == null || !run!.awaitingLootChoice) return;
    final item = QuestItemCatalog.get(itemId);
    if (item == null) return;

    final player = run!.activePlayer;
    if (equip) {
      if (!player.inventory.addItem(itemId, item.type)) {
        run!.lastMessage = 'Inventory full — item lost.';
      } else if (item.type == 'relic') {
        engine!.applyRelicsOnRunStart(player);
      }
    } else {
      run!.lastMessage = 'Skipped $itemId.';
    }

    run!.pendingLootIds.remove(itemId);
    if (run!.pendingLootIds.isEmpty) {
      run!.awaitingLootChoice = false;
      _maybeEndRunAfterLoot();
      if (!run!.runComplete) {
        _completeMapNode(wasBoss: currentRoomSpec.type == QuestRoomType.boss);
      }
    }
    await _autoSave();
    notifyListeners();
  }

  Future<void> skipAllLoot() async {
    if (run == null) return;
    run!.pendingLootIds.clear();
    run!.awaitingLootChoice = false;
    _maybeEndRunAfterLoot();
    if (!run!.runComplete) {
      _completeMapNode(wasBoss: currentRoomSpec.type == QuestRoomType.boss);
    }
    notifyListeners();
  }

  Future<void> returnToMap() async {
    if (run == null) return;
    run!.phase = QuestPhase.map;
    run!.awaitingLootChoice = false;
    run!.lastMessage = 'Choose your next location on the map.';
    await _autoSave();
    notifyListeners();
  }

  void useConsumable(int slot) {
    final player = run?.activePlayer;
    if (player == null) return;
    final id = player.inventory.consumables[slot];
    if (id == null) return;
    final item = QuestItemCatalog.get(id);
    if (item == null) return;
    engine!.applyItemEffects(player, item);
    player.inventory.removeConsumable(slot);
    run!.lastMessage = 'Used ${item.name}.';
    notifyListeners();
  }

  void _advanceActivePlayer() {
    if (run == null) return;
    if (run!.livingPlayers.length <= 1) return;
    var next = (run!.activePlayerIndex + 1) % run!.players.length;
    for (var i = 0; i < run!.players.length; i++) {
      if (run!.players[next].alive) {
        run!.activePlayerIndex = next;
        return;
      }
      next = (next + 1) % run!.players.length;
    }
  }

  void _endRun({required bool won}) {
    run!.runComplete = true;
    run!.runWon = won;
    run!.phase = won ? QuestPhase.runWon : QuestPhase.runLost;
    _showBark(
      won ? 'Victory' : 'Defeat',
      won ? 'Dungeon cleared!' : 'Run over.',
    );
    saveService.clearActiveQuest();
    notifyListeners();
  }

  void _checkRunEnd() {
    if (run!.allPlayersDead) _endRun(won: false);
  }

  void _showBark(String speaker, String line) {
    if (line.isEmpty) return;
    run!.activeBark = line;
    run!.activeBarkSpeaker = speaker;
    _barkTimer?.cancel();
    _barkTimer = Timer(const Duration(milliseconds: 2600), () {
      if (run != null) {
        run!.activeBark = null;
        run!.activeBarkSpeaker = null;
        notifyListeners();
      }
    });
  }

  Future<void> _autoSave() async {
    if (run == null || run!.runComplete) return;
    await saveService.saveActiveQuest(run!);
  }

  Future<void> abandonRun() async {
    await saveService.clearActiveQuest();
    run = null;
    canResumeQuest = false;
    notifyListeners();
  }

  void skipCpuWait() {
    if (!cpuExercising) return;
    _cpuExerciseEndsAt = DateTime.now();
    notifyListeners();
  }

  void _maybeCpuTurn() {
    if (run == null || run!.runComplete) return;
    if (run!.phase != QuestPhase.draw &&
        run!.phase != QuestPhase.challenge &&
        run!.phase != QuestPhase.jokerChoice) {
      return;
    }
    if (!run!.activePlayer.isCpu) return;

    final gen = ++_cpuGeneration;
    Future(() async {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!_cpuTurnStillValid(gen)) return;

      if (run!.phase == QuestPhase.draw && !run!.cardDrawnThisTurn) {
        drawCard();
        return;
      }

      if (run!.phase == QuestPhase.jokerChoice) {
        _cpuPickJoker();
        return;
      }

      if (run!.phase != QuestPhase.challenge || run!.currentCard == null) {
        return;
      }

      final player = run!.activePlayer;
      final card = run!.currentCard!;
      final useModified = QuestCpu.likelyModified(player, card);
      final pass = QuestCpu.shouldPass(player, card, run!.combo);
      final result = !pass
          ? TurnResultType.fail
          : (useModified ? TurnResultType.modified : TurnResultType.pass);

      final completed = await _runCpuExerciseDelay(
        gen: gen,
        card: card,
        result: result,
        useModified: useModified,
      );
      if (completed) {
        await resolveTurn(result);
      }
    });
  }

  void _cpuPickJoker() {
    const choices = ['rest', 'loot', 'chaos'];
    pickJoker(choices[Random().nextInt(choices.length)]);
  }

  bool _cpuTurnStillValid(int gen) =>
      gen == _cpuGeneration && run != null && !run!.runComplete;

  Future<bool> _runCpuExerciseDelay({
    required int gen,
    required GameCard card,
    required TurnResultType result,
    required bool useModified,
  }) async {
    cpuExercising = true;
    _startExertionTicker();
    notifyListeners();

    final delay = QuestCpu.estimateExerciseDelay(
      card,
      run!.activePlayer,
      willUseModified: useModified,
    );
    _cpuExerciseEndsAt = DateTime.now().add(delay);

    while (true) {
      if (!_cpuTurnStillValid(gen)) {
        _clearCpuExerciseState();
        return false;
      }
      final end = _cpuExerciseEndsAt;
      if (end == null) return false;
      final remaining = end.difference(DateTime.now());
      if (remaining <= Duration.zero) break;
      await Future.delayed(
        remaining > const Duration(milliseconds: 250)
            ? const Duration(milliseconds: 250)
            : remaining,
      );
    }

    _clearCpuExerciseState();
    return _cpuTurnStillValid(gen);
  }

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

  void _clearCpuExerciseState() {
    cpuExercising = false;
    _cpuExertionTimer?.cancel();
    _cpuExertionTimer = null;
    cpuExertionCue = '';
    _cpuExerciseEndsAt = null;
  }

  @override
  void dispose() {
    _barkTimer?.cancel();
    _autoSaveTimer?.cancel();
    _cpuExertionTimer?.cancel();
    super.dispose();
  }
}
