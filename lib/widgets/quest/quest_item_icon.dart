import 'package:flutter/material.dart';

import '../../core/models/quest/quest_item.dart';
import '../../core/theme/app_theme.dart';
import 'quest_inventory_sheet.dart';

class QuestItemIcon extends StatelessWidget {
  final QuestItem? item;
  final double size;
  final String? placeholderAsset;

  const QuestItemIcon({
    super.key,
    this.item,
    this.size = 48,
    this.placeholderAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return _emptySlot();
    }
    final border = questRarityColor(item!.rarity);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        item!.portraitPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(border),
      ),
    );
  }

  Widget _emptySlot() {
    final asset = placeholderAsset;
    if (asset != null) {
      return Opacity(
        opacity: 0.45,
        child: Image.asset(asset, width: size, height: size, fit: BoxFit.contain),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.arenaGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
    );
  }

  Widget _fallback(Color border) {
    return Container(
      color: AppTheme.arenaGray,
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2, color: border, size: size * 0.45),
    );
  }
}
