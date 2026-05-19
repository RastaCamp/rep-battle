import 'package:flutter/material.dart';

import '../../core/data/quest_assets.dart';
import '../../core/models/quest/quest_enemy.dart';
import '../../core/theme/app_theme.dart';

class QuestEnemyPortrait extends StatelessWidget {
  final QuestEnemyInstance enemy;
  final double size;
  final bool showBossBadge;

  const QuestEnemyPortrait({
    super.key,
    required this.enemy,
    this.size = 160,
    this.showBossBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enemy.isBoss ? Colors.amberAccent : AppTheme.arenaRed,
              width: enemy.isBoss ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (enemy.isBoss ? Colors.amber : AppTheme.arenaRed)
                    .withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            QuestAssets.key(enemy.imageAsset),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppTheme.arenaGray,
              alignment: Alignment.center,
              child: Icon(
                enemy.isBoss ? Icons.whatshot : Icons.pest_control,
                size: size * 0.4,
                color: Colors.white38,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          enemy.name.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: enemy.isBoss ? 16 : 14,
            color: enemy.isBoss ? Colors.amberAccent : Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        if (enemy.isBoss && showBossBadge)
          const Text(
            'BOSS',
            style: TextStyle(
              color: AppTheme.arenaRed,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
      ],
    );
  }
}
