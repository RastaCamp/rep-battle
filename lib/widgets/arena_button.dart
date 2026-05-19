import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class ArenaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final String? imageAsset;
  final Color? glowColor;
  final bool large;

  const ArenaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.imageAsset,
    this.glowColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 32 : 20,
            vertical: large ? 18 : 12,
          ),
          decoration: AppTheme.glowBorder(glowColor ?? AppTheme.arenaRed).copyWith(
            color: AppTheme.arenaGray.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageAsset != null) ...[
                Image.asset(imageAsset!, height: large ? 36 : 28),
                const SizedBox(width: 10),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: large ? 18 : 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.arenaWhite,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
