import 'package:flutter/material.dart';

import '../core/data/asset_paths.dart';
import '../core/theme/app_theme.dart';

class ComboMeter extends StatelessWidget {
  final int combo;
  final int hype;
  final int hypeMax;

  const ComboMeter({
    super.key,
    required this.combo,
    required this.hype,
    this.hypeMax = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (combo > 0) ...[
          Image.asset(AssetPaths.uiCombo, height: 28),
          const SizedBox(width: 6),
          Text(
            'COMBO ×$combo',
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HYPE',
                style: TextStyle(fontSize: 10, color: Colors.white54),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: hype / hypeMax,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  color: AppTheme.arenaRed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
