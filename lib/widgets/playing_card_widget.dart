import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/models/game_card.dart';
import '../services/custom_card_service.dart';
import 'card_face_painter.dart';

/// Universal card frame — content scales with [BoxFit.contain] inside fixed bounds.
class PlayingCardWidget extends StatelessWidget {
  final GameCard? card;
  final bool faceDown;
  final double? maxWidth;
  final double? maxHeight;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    this.card,
    this.faceDown = false,
    this.maxWidth,
    this.maxHeight,
    this.onTap,
  });

  static const double aspectRatio = 1.4;

  @override
  Widget build(BuildContext context) {
    final customService = context.watch<CustomCardService>();
    final cardBack = context.watch<GameController>().cardBackAsset;

    return LayoutBuilder(
      builder: (context, constraints) {
        var w = maxWidth ?? constraints.maxWidth;
        var h = maxHeight ?? constraints.maxHeight;
        if (w.isInfinite || w <= 0) w = 160;
        if (h.isInfinite || h <= 0) h = w * aspectRatio;

        final byWidth = Size(w, w * aspectRatio);
        final byHeight = Size(h / aspectRatio, h);
        final size = byWidth.height <= h ? byWidth : byHeight;

        return Center(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: ColoredBox(
                  color: const Color(0xFF0D0D10),
                  child: faceDown || card == null
                      ? Image.asset(
                          cardBack,
                          fit: BoxFit.contain,
                          width: size.width,
                          height: size.height,
                        )
                      : card!.useSuitTemplate
                          ? CardFacePainter(
                              card: card!,
                              customCardService: customService,
                            )
                          : Image.asset(
                              card!.imageAsset,
                              fit: BoxFit.contain,
                              width: size.width,
                              height: size.height,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  card!.rank,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
