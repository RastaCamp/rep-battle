import 'package:flutter/material.dart';

import '../../core/models/quest/quest_map_node.dart';
import '../../core/ui/box_fit_rect.dart';
import '../../core/data/quest_assets.dart';
import '../../services/quest_asset_catalog.dart';
import 'quest_room_theme.dart';

class QuestMapView extends StatelessWidget {
  static const mapImageSize = Size(1731, 909);

  final List<QuestMapNode> nodes;
  final void Function(int roomIndex) onSelectRoom;
  final String? announcerLine;

  const QuestMapView({
    super.key,
    required this.nodes,
    required this.onSelectRoom,
    this.announcerLine,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (announcerLine != null && announcerLine!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              announcerLine!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final container =
                  Size(constraints.maxWidth, constraints.maxHeight);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    QuestAssets.key(QuestAssetCatalog.instance.mapPath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A22),
                    ),
                  ),
                  ...nodes
                      .where((n) => n.status != QuestMapNodeStatus.hidden)
                      .map((n) {
                    final center = mapNormalizedOnImage(
                      nx: n.x,
                      ny: n.y,
                      imageSize: mapImageSize,
                      containerSize: container,
                    );
                    return _LocationMarker(
                      node: n,
                      left: center.dx - 40,
                      top: center.dy - 30,
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight,
                      onTap: n.status == QuestMapNodeStatus.current
                          ? () => onSelectRoom(n.roomIndex)
                          : null,
                    );
                  }),
                ],
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Tap the glowing location to enter.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _LocationMarker extends StatelessWidget {
  final QuestMapNode node;
  final double left;
  final double top;
  final double maxWidth;
  final double maxHeight;
  final VoidCallback? onTap;

  const _LocationMarker({
    required this.node,
    required this.left,
    required this.top,
    required this.maxWidth,
    required this.maxHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = QuestRoomTheme.colorFor(node.roomType);
    final isCurrent = node.status == QuestMapNodeStatus.current;
    final isDone = node.status == QuestMapNodeStatus.completed;
    const markerW = 80.0;
    const markerH = 56.0;

    return Positioned(
      left: left.clamp(0, maxWidth - markerW),
      top: top.clamp(0, maxHeight - markerH - 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: markerW,
              height: markerH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent ? color : color.withValues(alpha: 0.45),
                  width: isCurrent ? 2.5 : 1,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.55),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Opacity(
                  opacity: isDone ? 0.5 : 1,
                  child: Image.asset(
                    QuestAssets.key(node.locationAssetPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: color.withValues(alpha: 0.25),
                      child: Icon(Icons.place, color: color, size: 28),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              constraints: const BoxConstraints(maxWidth: markerW + 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${node.roomIndex}',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
