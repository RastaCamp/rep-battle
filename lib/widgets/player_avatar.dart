import 'package:flutter/material.dart';

import '../core/models/player_state.dart';
import '../services/avatar_catalog.dart';

/// Circular portrait for humans or NPCs in HUD / setup.
class PlayerAvatar extends StatelessWidget {
  final PlayerState? player;
  final String? assetPath;
  final Color borderColor;
  final double size;

  const PlayerAvatar({
    super.key,
    this.player,
    this.assetPath,
    this.borderColor = Colors.white54,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final asset = assetPath ??
        (player != null
            ? AvatarCatalog.instance.assetForPlayer(
                avatarAsset: player!.avatarAsset,
                avatarId: player!.avatarId,
                npcProfileId: player!.npcProfileId,
              )
            : AvatarCatalog.instance.assetForId(null));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: size > 48 ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.35),
            blurRadius: 6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: borderColor.withValues(alpha: 0.2),
          child: Icon(Icons.person, size: size * 0.45, color: borderColor),
        ),
      ),
    );
  }
}
