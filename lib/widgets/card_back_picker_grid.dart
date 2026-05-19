import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/card_back_catalog.dart';

class CardBackPickerGrid extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;

  const CardBackPickerGrid({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: CardBackCatalog.options.length,
      itemBuilder: (context, i) {
        final opt = CardBackCatalog.options[i];
        final selected = opt.id == selectedId;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(opt.id),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? AppTheme.arenaRed : Colors.white24,
                  width: selected ? 3 : 1,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      child: Image.asset(
                        opt.assetPath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFF222228),
                          child: Icon(Icons.style, color: Colors.white38),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      opt.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                        color: selected ? AppTheme.arenaWhite : Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
