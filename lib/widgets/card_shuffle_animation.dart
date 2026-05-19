import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import 'playing_card_widget.dart';

/// Animated card backs for splash / intro.
class CardShuffleAnimation extends StatefulWidget {
  final double cardWidth;

  const CardShuffleAnimation({super.key, this.cardWidth = 100});

  @override
  State<CardShuffleAnimation> createState() => _CardShuffleAnimationState();
}

class _CardShuffleAnimationState extends State<CardShuffleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.cardWidth * PlayingCardWidget.aspectRatio;
    final cardBack = context.watch<GameController>().cardBackAsset;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.cardWidth * 1.8,
          height: h * 1.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _cardAt(-0.18, 0.08, -0.12, h, cardBack),
              _cardAt(0.18, -0.06, 0.1, h, cardBack),
              _cardAt(0, 0, 0, h, cardBack, scale: 1.05),
            ],
          ),
        );
      },
    );
  }

  Widget _cardAt(
    double dx,
    double dy,
    double rot,
    double h,
    String cardBack, {
    double scale = 1,
  }) {
    final t = _controller.value * 2 * math.pi;
    final wobble = math.sin(t + rot * 10) * 0.04;
    return Transform.translate(
      offset: Offset(dx * widget.cardWidth * 1.2, dy * h * 0.3),
      child: Transform.rotate(
        angle: rot + wobble,
        child: Transform.scale(
          scale: scale,
          child: Image.asset(
            cardBack,
            width: widget.cardWidth,
            height: h,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
