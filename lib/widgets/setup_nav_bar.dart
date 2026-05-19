import 'package:flutter/material.dart';

import '../core/data/asset_paths.dart';

class SetupNavBar extends StatelessWidget {
  final bool showBack;
  final bool isFinalStep;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const SetupNavBar({
    super.key,
    required this.showBack,
    required this.isFinalStep,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          if (showBack)
            Expanded(
              child: _NavImageButton(
                asset: AssetPaths.uiCancel,
                label: 'BACK',
                onPressed: onBack,
              ),
            ),
          if (showBack) const SizedBox(width: 12),
          Expanded(
            flex: showBack ? 2 : 1,
            child: _NavImageButton(
              asset: AssetPaths.uiConfirm,
              label: isFinalStep ? 'START' : 'NEXT',
              onPressed: onNext,
              primary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavImageButton extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _NavImageButton({
    required this.asset,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                asset,
                fit: BoxFit.contain,
                height: 56,
                errorBuilder: (_, __, ___) => Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFF333340),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
