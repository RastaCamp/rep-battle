import 'package:flutter/material.dart';

import '../core/models/npc_profile.dart';

/// Portrait slot: add PNG at assets/images/npcs/{profile.id}.png
class NpcAvatar extends StatelessWidget {
  final NpcProfile profile;
  final double size;

  const NpcAvatar({super.key, required this.profile, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: profile.color, width: 3),
        boxShadow: [
          BoxShadow(
            color: profile.color.withValues(alpha: 0.35),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        profile.avatarAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: profile.color.withValues(alpha: 0.25),
          child: Icon(Icons.person, size: size * 0.5, color: profile.color),
        ),
      ),
    );
  }
}
