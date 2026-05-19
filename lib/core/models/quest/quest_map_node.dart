import '../../../core/data/quest_assets.dart';
import '../../../services/quest_asset_catalog.dart';
import 'quest_dungeon.dart';

enum QuestMapNodeStatus { hidden, current, completed }

class QuestMapNode {
  final int roomIndex;
  final QuestRoomType roomType;
  QuestMapNodeStatus status;
  final double x;
  final double y;
  final String locationAssetId;
  final String tagAssetId;
  final String locationLabel;
  final String locationAssetPath;
  final String roomAssetPath;

  QuestMapNode({
    required this.roomIndex,
    required this.roomType,
    required this.status,
    required this.x,
    required this.y,
    required this.locationAssetId,
    required this.tagAssetId,
    required this.locationLabel,
    required this.locationAssetPath,
    required this.roomAssetPath,
  });

  Map<String, dynamic> toJson() => {
        'roomIndex': roomIndex,
        'roomType': roomType.name,
        'status': status.name,
        'x': x,
        'y': y,
        'locationAssetId': locationAssetId,
        'tagAssetId': tagAssetId,
        'locationLabel': locationLabel,
        'locationAssetPath': locationAssetPath,
        'roomAssetPath': roomAssetPath,
      };

  factory QuestMapNode.fromJson(Map<String, dynamic> json) {
    final locId = json['locationAssetId'] as String;
    final roomId = json['tagAssetId'] as String;
    final catalog = QuestAssetCatalog.instance;
    return QuestMapNode(
      roomIndex: json['roomIndex'] as int,
      roomType: QuestRoomType.values.byName(json['roomType'] as String),
      status: QuestMapNodeStatus.values.byName(json['status'] as String),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      locationAssetId: locId,
      tagAssetId: roomId,
      locationLabel: json['locationLabel'] as String,
      locationAssetPath: QuestAssets.key(
        json['locationAssetPath'] as String? ?? catalog.locationPathFor(locId),
      ),
      roomAssetPath: QuestAssets.key(
        json['roomAssetPath'] as String? ?? catalog.roomPathFor(roomId),
      ),
    );
  }
}
