import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/models/game_card.dart';
import 'playing_card_widget.dart';

/// Face-down draw pile + face-up discard pile.
class DeckPileRow extends StatelessWidget {
  final int deckCount;
  final GameCard? discardCard;
  final int discardCount;
  final bool canDraw;
  final VoidCallback? onDraw;
  final double pileWidth;

  const DeckPileRow({
    super.key,
    required this.deckCount,
    this.discardCard,
    this.discardCount = 0,
    this.canDraw = false,
    this.onDraw,
    this.pileWidth = 72,
  });

  @override
  Widget build(BuildContext context) {
    final cardBack = context.watch<GameController>().cardBackAsset;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : pileWidth * 2 + 20;
        final w = pileWidth.clamp(48.0, (maxW - 20) / 2).toDouble();
        final pileHeight = w * PlayingCardWidget.aspectRatio;

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
        _PileStack(
          label: 'DRAW',
          count: deckCount,
          width: w,
          height: pileHeight,
          cardBackAsset: cardBack,
          onTap: canDraw ? onDraw : null,
          child: PlayingCardWidget(
            faceDown: true,
            maxWidth: w,
            maxHeight: pileHeight,
          ),
        ),
        const SizedBox(width: 20),
        _PileStack(
          label: 'DISCARD',
          count: discardCount > 0 ? discardCount : (discardCard != null ? 1 : 0),
          width: w,
          height: pileHeight,
          cardBackAsset: cardBack,
          child: discardCard != null
              ? PlayingCardWidget(
                  card: discardCard,
                  maxWidth: w,
                  maxHeight: pileHeight,
                )
              : Container(
                  width: w,
                  height: pileHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                    color: Colors.black26,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '—',
                    style: TextStyle(color: Colors.white24, fontSize: 24),
                  ),
                ),
        ),
            ],
          ),
        );
      },
    );
  }
}

class _PileStack extends StatelessWidget {
  final String label;
  final int count;
  final double width;
  final double height;
  final Widget child;
  final String cardBackAsset;
  final VoidCallback? onTap;

  const _PileStack({
    required this.label,
    required this.count,
    required this.width,
    required this.height,
    required this.cardBackAsset,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (onTap != null && count > 1)
                  Positioned(
                    left: 4,
                    top: -4,
                    child: _ghost(width, height, 0.5, cardBackAsset),
                  ),
                if (onTap != null && count > 2)
                  Positioned(
                    left: 8,
                    top: -8,
                    child: _ghost(width, height, 0.35, cardBackAsset),
                  ),
                child,
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count > 0 ? '$count' : '',
          style: const TextStyle(fontSize: 11, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _ghost(double w, double h, double opacity, String backAsset) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(
        backAsset,
        width: w,
        height: h,
        fit: BoxFit.contain,
      ),
    );
  }
}
