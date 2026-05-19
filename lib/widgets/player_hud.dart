import 'package:flutter/material.dart';

import '../core/data/asset_paths.dart';
import '../core/models/player_state.dart';
import '../core/theme/app_theme.dart';
import 'ability_modifier_badge.dart';
import 'player_avatar.dart';

class PlayerHud extends StatelessWidget {
  final PlayerState player;
  final bool isActive;
  final bool compact;

  const PlayerHud({
    super.key,
    required this.player,
    this.isActive = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = player.eliminated ? 0.4 : 1.0;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: EdgeInsets.all(compact ? 6 : 12),
        decoration: BoxDecoration(
          color: AppTheme.arenaGray.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? player.color
                : player.color.withValues(alpha: 0.3),
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: player.color.withValues(alpha: 0.45),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            PlayerAvatar(
              player: player,
              borderColor: player.color,
              size: compact ? 36 : 44,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    player.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: player.eliminated
                          ? Colors.grey
                          : AppTheme.arenaWhite,
                      fontSize: compact ? 11 : 14,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (player.eliminated)
                    const Text(
                      'ELIMINATED',
                      style: TextStyle(
                        color: AppTheme.arenaRed,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    )
                  else
                    Text(
                      'SCORE ${player.score}',
                      style: TextStyle(
                        color: player.color.withValues(alpha: 0.9),
                        fontSize: compact ? 9 : 12,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (!compact)
                    AbilityModifierBadge(
                      modifierId: player.abilityModifierId,
                      compact: true,
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconStat(AssetPaths.uiLives, '${player.lives}', compact),
                if (player.armor > 0)
                  _iconStat(AssetPaths.uiShield, '${player.armor}', compact),
                if (player.skips > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      'SKIP×${player.skips}',
                      style: const TextStyle(fontSize: 10, color: Colors.amber),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconStat(String asset, String value, bool compact) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        children: [
          Image.asset(asset, height: compact ? 16 : 20),
          const SizedBox(width: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
