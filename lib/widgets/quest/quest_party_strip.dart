import 'package:flutter/material.dart';

import '../../core/models/quest/quest_player_state.dart';
import '../../core/theme/app_theme.dart';
import '../npc_avatar.dart';
import '../player_avatar.dart';
import '../../services/avatar_catalog.dart';
import '../../services/npc_registry.dart';

class QuestPartyStrip extends StatelessWidget {
  final List<QuestPlayerState> players;
  final int activeIndex;

  const QuestPartyStrip({
    super.key,
    required this.players,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        itemCount: players.length,
        itemBuilder: (_, i) {
          final p = players[i];
          final active = i == activeIndex;
          return SizedBox(
            width: 132,
            child: _PartyChip(player: p, active: active),
          );
        },
      ),
    );
  }
}

class _PartyChip extends StatelessWidget {
  final QuestPlayerState player;
  final bool active;

  const _PartyChip({required this.player, required this.active});

  @override
  Widget build(BuildContext context) {
    final opacity = player.alive ? 1.0 : 0.4;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.arenaGray.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? player.color : player.color.withValues(alpha: 0.35),
            width: active ? 2.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (player.isCpu && player.npcProfileId != null)
              NpcAvatar(
                profile: NpcRegistry.instance.byId(player.npcProfileId)!,
                size: 36,
              )
            else
              PlayerAvatar(
                assetPath: AvatarCatalog.instance.assetForId(player.avatarId),
                borderColor: player.color,
                size: 36,
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: player.color,
                    ),
                  ),
                  Text(
                    'HP ${player.hp}/${player.maxHp}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
