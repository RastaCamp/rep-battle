import 'package:flutter/material.dart';

import '../../core/data/asset_paths.dart';
import '../../core/models/quest/quest_inventory.dart';
import '../../core/models/quest/quest_item.dart';
import '../../core/theme/app_theme.dart';
import 'quest_item_icon.dart';

Color questRarityColor(String rarity) => switch (rarity) {
      'legendary' => const Color(0xFFFFD700),
      'epic' => const Color(0xFF9B59B6),
      'rare' => const Color(0xFF3498DB),
      _ => Colors.grey,
    };

class QuestInventorySheet extends StatelessWidget {
  final QuestInventory inventory;
  final void Function(int slot) onUseConsumable;

  const QuestInventorySheet({
    super.key,
    required this.inventory,
    required this.onUseConsumable,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.75,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'INVENTORY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.arenaRed,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            const Text('CONSUMABLES', style: TextStyle(fontWeight: FontWeight.w800)),
            ...List.generate(QuestInventory.consumableSlots, (i) {
              final id = inventory.consumables[i];
              return _slotTile(
                label: 'Slot ${i + 1}',
                itemId: id,
                emptyPlaceholder: AssetPaths.questUiProteinShake,
                onTap: id != null ? () => onUseConsumable(i) : null,
              );
            }),
            const SizedBox(height: 12),
            const Text('RELICS', style: TextStyle(fontWeight: FontWeight.w800)),
            ...List.generate(QuestInventory.relicSlots, (i) {
              final id = inventory.relics[i];
              return _slotTile(
                label: 'Relic',
                itemId: id,
                emptyPlaceholder: AssetPaths.questUiRelicSlot,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _slotTile({
    required String label,
    required String? itemId,
    String? emptyPlaceholder,
    VoidCallback? onTap,
  }) {
    final item = QuestItemCatalog.get(itemId);
    return ListTile(
      leading: QuestItemIcon(
        item: item,
        size: 44,
        placeholderAsset: emptyPlaceholder,
      ),
      title: Text(item?.name ?? '$label — empty'),
      subtitle: item != null
          ? Text(
              item.description,
              style: TextStyle(color: questRarityColor(item.rarity)),
            )
          : null,
      trailing: onTap != null
          ? TextButton(onPressed: onTap, child: const Text('USE'))
          : null,
    );
  }
}
