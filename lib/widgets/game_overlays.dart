import 'package:flutter/material.dart';

import '../core/data/asset_paths.dart';
import '../core/theme/app_theme.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;
  final VoidCallback onUndo;
  final VoidCallback? onRestart;
  final VoidCallback? onForfeit;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onQuit,
    required this.onUndo,
    this.onRestart,
    this.onForfeit,
  });

  @override
  Widget build(BuildContext context) {
    return _OverlayBackdrop(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AssetPaths.uiPause, height: 48),
          const SizedBox(height: 16),
          const Text('PAUSED', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          _overlayBtn('RESUME', onResume),
          const SizedBox(height: 12),
          _overlayBtn('UNDO LAST', onUndo),
          if (onRestart != null) ...[
            const SizedBox(height: 12),
            _overlayBtn('RESTART MATCH', onRestart!),
          ],
          const SizedBox(height: 12),
          _overlayBtn('QUIT MATCH', onQuit, color: AppTheme.arenaRed),
          if (onForfeit != null) ...[
            const SizedBox(height: 12),
            _overlayBtn('FORFEIT', onForfeit!, color: Colors.red.shade900),
          ],
        ],
      ),
    );
  }
}

class ComboOverlay extends StatelessWidget {
  const ComboOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1),
          duration: const Duration(milliseconds: 400),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(AssetPaths.uiFire, height: 80),
              const Text(
                'COMBO!',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.orangeAccent,
                  shadows: [
                    Shadow(color: Colors.red, blurRadius: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArmorBreakOverlay extends StatelessWidget {
  const ArmorBreakOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AssetPaths.uiShield, height: 64, color: Colors.grey),
            const Text(
              'ARMOR BROKEN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WinnerOverlay extends StatelessWidget {
  final String winnerName;

  const WinnerOverlay({super.key, required this.winnerName});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AssetPaths.winnerOverlay, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.7)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AssetPaths.uiCrown, height: 64),
                const SizedBox(height: 12),
                Text(
                  '$winnerName WINS!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayBackdrop extends StatelessWidget {
  final Widget child;
  const _OverlayBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

Widget _overlayBtn(String label, VoidCallback onTap, {Color? color}) {
  return SizedBox(
    width: 240,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppTheme.arenaGray,
      ),
      child: Text(label),
    ),
  );
}
