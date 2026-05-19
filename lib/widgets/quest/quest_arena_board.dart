import 'package:flutter/material.dart';

import '../../controllers/quest_controller.dart';
import '../../core/engine/ability_modifier_engine.dart';
import '../../core/data/quest_assets.dart';
import '../../core/models/game_card.dart';
import '../../core/models/player_state.dart';
import '../../core/models/quest/quest_player_state.dart';
import '../../core/models/quest/quest_run_state.dart';
import '../ability_modifier_badge.dart';
import '../deck_pile_row.dart';
import '../player_avatar.dart';
import '../playing_card_widget.dart';
import '../npc_avatar.dart';
import '../../services/avatar_catalog.dart';
import '../../services/npc_registry.dart';
import 'quest_enemy_portrait.dart';

/// Play-mode style scrollable arena with quest room background (stretched to fit).
class QuestArenaBoard extends StatelessWidget {
  final QuestRunState run;
  final QuestController quest;
  final String roomBackgroundPath;
  final bool canDraw;
  final GameCard? discardDisplayCard;
  final String? challengeText;

  const QuestArenaBoard({
    super.key,
    required this.run,
    required this.quest,
    required this.roomBackgroundPath,
    required this.canDraw,
    required this.discardDisplayCard,
    this.challengeText,
  });

  @override
  Widget build(BuildContext context) {
    final player = run.activePlayer;
    final card = run.currentCard;
    final displayCard =
        card != null ? _personalizeCard(card, player) : null;
    final turnColor = player.color;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: turnColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: turnColor.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              QuestAssets.key(roomBackgroundPath),
              fit: BoxFit.fill,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF1A1A22),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardMaxH =
                  (constraints.maxHeight * 0.32).clamp(64.0, 160.0);
              final cardMaxW =
                  (constraints.maxWidth * 0.55).clamp(88.0, 150.0);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (run.enemy != null) ...[
                        QuestEnemyPortrait(enemy: run.enemy!, size: 72),
                        const SizedBox(height: 8),
                        Text(
                          run.enemy!.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'HP ${run.enemy!.hp}/${run.enemy!.maxHp}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _playerAvatar(player),
                      const SizedBox(height: 6),
                      Text(
                        player.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: player.color,
                        ),
                      ),
                      if (player.title != null && player.title!.isNotEmpty)
                        Text(
                          player.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      AbilityModifierBadge(modifierId: player.abilityModifierId),
                      if (quest.cpuExercising) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            quest.cpuExertionCue,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: quest.skipCpuWait,
                          child: const Text(
                            'PUSH — hurry them up',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      DeckPileRow(
                        deckCount: run.deck.length,
                        discardCard: discardDisplayCard,
                        discardCount: run.discard.length,
                        canDraw: canDraw,
                        onDraw: quest.drawCard,
                        pileWidth: 64,
                      ),
                      if (run.phase == QuestPhase.draw && canDraw)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Tap deck to draw',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (displayCard != null) ...[
                        const SizedBox(height: 10),
                        PlayingCardWidget(
                          card: displayCard,
                          maxWidth: cardMaxW,
                          maxHeight: cardMaxH,
                        ),
                        if (challengeText != null && challengeText!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                            child: Text(
                              challengeText!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _playerAvatar(QuestPlayerState player) {
    if (player.isCpu && player.npcProfileId != null) {
      final profile = NpcRegistry.instance.byId(player.npcProfileId);
      if (profile != null) {
        return NpcAvatar(profile: profile, size: 52);
      }
    }
    return PlayerAvatar(
      assetPath: AvatarCatalog.instance.assetForId(player.avatarId),
      borderColor: player.color,
      size: 52,
    );
  }

  GameCard _personalizeCard(GameCard base, QuestPlayerState player) {
    final bridge = PlayerState(
      id: player.id,
      name: player.name,
      color: player.color,
      lives: player.hp,
      abilityModifierId: player.abilityModifierId,
    );
    return AbilityModifierEngine.personalizeCard(base, bridge);
  }
}
