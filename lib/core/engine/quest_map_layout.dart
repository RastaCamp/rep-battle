import 'dart:math';

import '../models/quest/quest_dungeon.dart';
import '../models/quest/quest_map_node.dart';
import '../../services/quest_asset_catalog.dart';

class QuestMapLayout {
  /// Normalized path across the map art (not letterbox padding).
  static const _path = <(double x, double y)>[
    (0.50, 0.84),
    (0.44, 0.74),
    (0.56, 0.65),
    (0.48, 0.56),
    (0.54, 0.47),
    (0.46, 0.38),
    (0.52, 0.29),
    (0.48, 0.20),
    (0.55, 0.12),
    (0.50, 0.06),
  ];

  static List<QuestMapNode> build({
    required QuestDungeonTemplate dungeon,
    required int seed,
  }) {
    final rng = Random(seed);
    final catalog = QuestAssetCatalog.instance;
    final nodes = <QuestMapNode>[];
    final roomCount = dungeon.rooms.length;

    for (var i = 0; i < roomCount; i++) {
      final roomIndex = i + 1;
      final spec = dungeon.rooms[i];
      final type = spec.type;

      final t = roomCount <= 1 ? 0.0 : i / (roomCount - 1);
      final (bx, by) = _pointOnPath(t);
      final jitter = 0.012;
      final x = (bx + (rng.nextDouble() - 0.5) * jitter).clamp(0.08, 0.92);
      final y = (by + (rng.nextDouble() - 0.5) * jitter).clamp(0.05, 0.92);

      final location = catalog.pickLocation(
        type,
        rng,
        dungeonId: dungeon.id,
      );
      final tag = catalog.pickRoomBackground(
        type,
        rng,
        dungeonId: dungeon.id,
      );

      nodes.add(
        QuestMapNode(
          roomIndex: roomIndex,
          roomType: type,
          status: i == 0 ? QuestMapNodeStatus.current : QuestMapNodeStatus.hidden,
          x: x,
          y: y,
          locationAssetId: location.id,
          tagAssetId: tag.id,
          locationLabel: location.label,
          locationAssetPath: location.assetPath,
          roomAssetPath: tag.assetPath,
        ),
      );
    }

    return nodes;
  }

  static (double, double) _pointOnPath(double t) {
    if (_path.isEmpty) return (0.5, 0.5);
    if (_path.length == 1) return _path.first;

    final scaled = t * (_path.length - 1);
    final i = scaled.floor().clamp(0, _path.length - 2);
    final frac = scaled - i;
    final a = _path[i];
    final b = _path[i + 1];
    return (a.$1 + (b.$1 - a.$1) * frac, a.$2 + (b.$2 - a.$2) * frac);
  }
}
