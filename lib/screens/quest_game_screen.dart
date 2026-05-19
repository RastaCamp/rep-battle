import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/quest_controller.dart';
import '../core/data/asset_paths.dart';
import '../core/data/quest_assets.dart';
import '../core/engine/ability_modifier_engine.dart';
import '../core/models/game_card.dart';
import '../core/models/player_state.dart';
import '../core/models/quest/quest_item.dart';
import '../core/models/quest/quest_run_state.dart';
import '../core/theme/app_theme.dart';
import '../core/music/music_scope.dart';
import '../services/audio_service.dart';
import '../widgets/music_scope_host.dart';
import '../widgets/pass_fail_controls.dart';
import '../widgets/quest/quest_bark_banner.dart';
import '../widgets/quest/quest_arena_board.dart';
import '../widgets/quest/quest_map_view.dart';
import '../widgets/quest/quest_party_strip.dart';
import '../widgets/quest/quest_room_theme.dart';
import '../widgets/quest/quest_inventory_sheet.dart';
import '../widgets/quest/quest_loot_card.dart';
import 'quest_end_screen.dart';

class QuestGameScreen extends StatelessWidget {
  const QuestGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quest = context.watch<QuestController>();
    final run = quest.run;
    if (run == null) {
      return const Scaffold(body: Center(child: Text('No active quest.')));
    }

    if (run.runComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuestEndScreen(won: run.runWon),
          ),
        );
      });
    }

    final active = run.activePlayer;
    final showArena = _showArena(run);
    final canDraw = showArena &&
        run.phase == QuestPhase.draw &&
        !run.cardDrawnThisTurn &&
        !active.isCpu &&
        !quest.cpuExercising;
    final showControls = (run.phase == QuestPhase.challenge ||
            run.phase == QuestPhase.jokerChoice) &&
        run.cardDrawnThisTurn &&
        !active.isCpu &&
        !quest.cpuExercising;

    String? challengeText;
    final card = run.currentCard;
    if (card != null) {
      final bridge = PlayerState(
        id: active.id,
        name: active.name,
        color: active.color,
        lives: active.hp,
        abilityModifierId: active.abilityModifierId,
      );
      final display = AbilityModifierEngine.personalizeCard(card, bridge);
      challengeText = AbilityModifierEngine.challengeLabel(display, bridge);
    }

    return MusicScopeHost(
      scope: MusicScope.questGameplay,
      child: Scaffold(
      backgroundColor: AppTheme.arenaBlack,
      appBar: AppBar(
        title: Text('${quest.dungeon.name.toUpperCase()} · ROOM ${run.roomIndex}'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.backpack_outlined),
            onPressed: () => _openInventory(context, quest),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmAbandon(context, quest),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (run.players.length > 1)
              QuestPartyStrip(
                players: run.players,
                activeIndex: run.activePlayerIndex,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'COMBO x${run.combo}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: run.combo >= 3
                          ? Colors.amberAccent
                          : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${active.name} · HP ${active.hp}/${active.maxHp}',
                    style: TextStyle(
                      color: active.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            QuestBarkBanner(
              speaker: run.activeBarkSpeaker,
              line: run.activeBark,
            ),
            Expanded(
              child: _centerContent(
                quest,
                run,
                canDraw: canDraw,
                challengeText: challengeText,
              ),
            ),
            if (run.lastMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  run.lastMessage!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            _bottomControls(context, quest, run, showControls: showControls),
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
    );
  }

  bool _showArena(QuestRunState run) {
    if (run.phase == QuestPhase.map) return false;
    if (run.awaitingLootChoice) return false;
    if (run.runComplete) return false;
    return true;
  }

  GameCard? _discardDisplayCard(QuestRunState run) {
    if (run.discard.isEmpty) return null;
    if (run.cardDrawnThisTurn && run.discard.length >= 2) {
      return run.discard[run.discard.length - 2];
    }
    if (!run.cardDrawnThisTurn) {
      return run.discard.last;
    }
    return null;
  }

  Widget _centerContent(
    QuestController quest,
    QuestRunState run, {
    required bool canDraw,
    String? challengeText,
  }) {
    if (run.phase == QuestPhase.map) {
      return QuestMapView(
        nodes: run.mapNodes,
        announcerLine: run.campaignAnnouncerLine,
        onSelectRoom: quest.enterMapRoom,
      );
    }

    if (run.awaitingLootChoice && run.pendingLootIds.isNotEmpty) {
      final item = QuestItemCatalog.get(run.pendingLootIds.first)!;
      return Center(
        child: QuestLootCard(
          item: item,
          onTake: () => quest.lootChoice(itemId: item.id, equip: true),
          onSkip: () => quest.lootChoice(itemId: item.id, equip: false),
        ),
      );
    }

    if (run.phase == QuestPhase.roomIntro) {
      return _roomIntro(quest, run);
    }

    return QuestArenaBoard(
      run: run,
      quest: quest,
      roomBackgroundPath: _roomBackgroundPath(run, quest),
      canDraw: canDraw,
      discardDisplayCard: _discardDisplayCard(run),
      challengeText: challengeText,
    );
  }

  String _roomBackgroundPath(QuestRunState run, QuestController quest) {
    if (run.combatRoomAssetPath != null &&
        run.combatRoomAssetPath!.isNotEmpty) {
      return run.combatRoomAssetPath!;
    }
    final node = run.currentMapNode;
    if (node != null && node.roomAssetPath.isNotEmpty) {
      return node.roomAssetPath;
    }
    return AssetPaths.questRoom(quest.currentRoomSpec.type.name);
  }

  Widget _roomIntro(QuestController quest, QuestRunState run) {
    final spec = quest.currentRoomSpec;
    final color = QuestRoomTheme.colorFor(spec.type);
    final node = run.currentMapNode;
    final locationPath = QuestAssets.key(
      node?.locationAssetPath ?? AssetPaths.questRoom(spec.type.name),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            QuestRoomTheme.typeLabel(spec.type),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: color,
            ),
          ),
          if (node != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                node.locationLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              locationPath,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(height: 120),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            run.roomIntroNarration ?? run.lastMessage ?? 'Room ${run.roomIndex}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomControls(
    BuildContext context,
    QuestController quest,
    QuestRunState run, {
    required bool showControls,
  }) {
    if (run.awaitingLootChoice && run.pendingLootIds.isNotEmpty) {
      return TextButton(
        onPressed: quest.skipAllLoot,
        child: const Text('SKIP ALL LOOT'),
      );
    }

    if (run.phase == QuestPhase.roomIntro) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.arenaRed,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              context.read<AudioService>().playSfx(SfxType.button);
              quest.proceedFromRoomIntro();
            },
            child: const Text(
              'ENTER ROOM',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );
    }

    if (run.phase == QuestPhase.jokerChoice && showControls) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          _jokerBtn(context, 'REST', () => quest.pickJoker('rest')),
          _jokerBtn(context, 'LOOT', () => quest.pickJoker('loot')),
          _jokerBtn(context, 'CHAOS', () => quest.pickJoker('chaos')),
        ],
      );
    }

    if (run.phase == QuestPhase.challenge && showControls) {
      return PassFailControls(
        onPass: () => quest.resolveTurn(TurnResultType.pass),
        onFail: () => quest.resolveTurn(TurnResultType.fail),
        onModified: () => quest.resolveTurn(TurnResultType.modified),
        onSkip: () => quest.resolveTurn(TurnResultType.skip),
        canSkip: run.activePlayer.skips > 0,
      );
    }

    if (run.phase == QuestPhase.roomClear && !run.awaitingLootChoice) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: quest.returnToMap,
            child: const Text('RETURN TO MAP'),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _jokerBtn(BuildContext context, String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: () {
        context.read<AudioService>().playSfx(SfxType.button);
        onTap();
      },
      child: Text(label),
    );
  }

  void _openInventory(BuildContext context, QuestController quest) {
    context.read<AudioService>().playSfx(SfxType.inventory);
    final run = quest.run!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestInventorySheet(
        inventory: run.activePlayer.inventory,
        onUseConsumable: (slot) {
          quest.useConsumable(slot);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmAbandon(BuildContext context, QuestController quest) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon quest?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('NO')),
          TextButton(
            onPressed: () async {
              await quest.abandonRun();
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }
}
