import 'package:flutter/material.dart';

import '../../core/models/quest/quest_enemy.dart';
import '../../core/models/quest/quest_player_state.dart';
import '../../core/theme/app_theme.dart';
import 'quest_enemy_portrait.dart';

class QuestHud extends StatelessWidget {
  final QuestPlayerState player;
  final QuestEnemyInstance? enemy;
  final int roomIndex;
  final int roomCount;
  final int combo;

  const QuestHud({
    super.key,
    required this.player,
    this.enemy,
    required this.roomIndex,
    required this.roomCount,
    required this.combo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: player.color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'ROOM $roomIndex / $roomCount',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.arenaRed,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                'COMBO x$combo',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: combo >= 3 ? Colors.amberAccent : Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _statRow(
            player.name.toUpperCase(),
            'HP ${player.hp}/${player.maxHp}  ·  Armor ${player.armor}  ·  Skip ${player.skips}',
            player.color,
          ),
          Text(
            'Gold ${player.gold}  ·  XP ${player.xp}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (enemy != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuestEnemyPortrait(enemy: enemy!, size: 56, showBossBadge: false),
                const SizedBox(width: 10),
                Expanded(
                  child: _statRow(
                    enemy!.name.toUpperCase(),
                    'HP ${enemy!.hp}/${enemy!.maxHp}  ·  ATK ${enemy!.attack}  ·  Weak: ${enemy!.weakness}',
                    Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statRow(String title, String stats, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(stats, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
