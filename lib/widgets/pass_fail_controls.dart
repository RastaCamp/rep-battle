import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class PassFailControls extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onFail;
  final VoidCallback onModified;
  final VoidCallback onSkip;
  final bool canSkip;
  final bool enabled;

  const PassFailControls({
    super.key,
    required this.onPass,
    required this.onFail,
    required this.onModified,
    required this.onSkip,
    this.canSkip = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('PASS', Colors.greenAccent, onPass),
              _btn('FAIL', AppTheme.arenaRed, onFail),
              _btn('MODIFIED', Colors.amberAccent, onModified),
              _btn(
                'SKIP',
                canSkip ? Colors.cyanAccent : Colors.grey,
                canSkip ? onSkip : () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
