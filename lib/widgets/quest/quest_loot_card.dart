import 'package:flutter/material.dart';

import '../../core/models/quest/quest_item.dart';
import '../../core/theme/app_theme.dart';
import 'quest_inventory_sheet.dart';
import 'quest_item_icon.dart';

class QuestLootCard extends StatelessWidget {
  final QuestItem item;
  final VoidCallback onTake;
  final VoidCallback onSkip;

  const QuestLootCard({
    super.key,
    required this.item,
    required this.onTake,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final color = questRarityColor(item.rarity);
    return Card(
      color: AppTheme.arenaGray,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ROOM CLEARED — LOOT!',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.arenaRed,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 2),
              ),
              child: Column(
                children: [
                  QuestItemIcon(item: item, size: 88),
                  const SizedBox(height: 12),
                  Text(
                    item.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: color,
                    ),
                  ),
                  Text(
                    item.rarity.toUpperCase(),
                    style: TextStyle(color: color.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSkip,
                    child: const Text('SKIP'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.arenaRed,
                    ),
                    onPressed: onTake,
                    child: const Text('TAKE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
