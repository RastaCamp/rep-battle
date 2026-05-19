import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/avatar_catalog.dart';
import 'player_avatar.dart';

/// Horizontal avatar chooser for human players.
class AvatarPickerRow extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;
  final Color borderColor;

  const AvatarPickerRow({
    super.key,
    required this.selectedId,
    required this.onSelected,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final entries = AvatarCatalog.instance.allSelectable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PORTRAIT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final e = entries[i];
              final selected = e.id == selectedId;
              return GestureDetector(
                onTap: () => onSelected(e.id),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppTheme.arenaRed : Colors.white24,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: PlayerAvatar(
                    assetPath: e.asset,
                    borderColor: borderColor,
                    size: 48,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
