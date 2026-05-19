import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/models/game_card.dart';
import '../services/custom_card_service.dart';

/// Custom template: rank numbers only (suits are already in the art).
class CardFacePainter extends StatelessWidget {
  final GameCard card;
  final CustomCardService? customCardService;

  const CardFacePainter({
    super.key,
    required this.card,
    this.customCardService,
  });

  @override
  Widget build(BuildContext context) {
    final rankStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      height: 1,
      shadows: const [
        Shadow(color: Colors.black, blurRadius: 6),
        Shadow(color: Colors.black, blurRadius: 2),
      ],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          card.imageAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)),
        ),
        if (card.customImagePath != null)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 44),
              child: _CustomImage(
                path: card.customImagePath!,
                service: customCardService,
              ),
            ),
          ),
        Positioned(top: 6, left: 8, child: Text(card.rank, style: rankStyle)),
        Positioned(
          bottom: 6,
          right: 8,
          child: Transform.rotate(
            angle: 3.14159,
            child: Text(card.rank, style: rankStyle),
          ),
        ),
        if (card.reps != null && card.cardType == CardType.number)
          Positioned(
            left: 8,
            right: 8,
            bottom: 28,
            child: Text(
              card.displayReps.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        if (card.isFace)
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Text(
              _faceLabel(card),
              textAlign: TextAlign.center,
              style: rankStyle.copyWith(fontSize: 14),
            ),
          ),
      ],
    );
  }

  String _faceLabel(GameCard card) {
    if (card.isJack) return 'J';
    if (card.isQueen) return 'Q';
    if (card.isKing) return 'K';
    if (card.isJoker) return 'JK';
    return card.rank;
  }
}

class _CustomImage extends StatelessWidget {
  final String path;
  final CustomCardService? service;

  const _CustomImage({required this.path, this.service});

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('web:')) {
      return FutureBuilder<Uint8List?>(
        future: service?.loadImageBytes(path),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: Icon(Icons.image, color: Colors.white24));
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(snap.data!, fit: BoxFit.contain),
          );
        },
      );
    }
    if (kIsWeb) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(File(path), fit: BoxFit.contain),
    );
  }
}
