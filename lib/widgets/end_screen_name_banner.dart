import 'package:flutter/material.dart';

/// Places player name in the bottom black strip of winner/forfeit art.
class EndScreenNameBanner extends StatelessWidget {
  final String name;
  final bool forfeit;

  const EndScreenNameBanner({
    super.key,
    required this.name,
    this.forfeit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 72,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: forfeit ? Colors.white70 : const Color(0xFFFFD54F),
              fontSize: forfeit ? 18 : 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              height: 1.1,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 8),
                Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
