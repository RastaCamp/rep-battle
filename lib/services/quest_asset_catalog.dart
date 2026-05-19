import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../core/data/quest_assets.dart';
import '../core/models/quest/quest_dungeon.dart';

class QuestAssetRef {
  final String id;
  final String assetPath;
  final String label;
  final QuestRoomType? roomType;

  const QuestAssetRef({
    required this.id,
    required this.assetPath,
    required this.label,
    this.roomType,
  });

  String get bundleKey => QuestAssets.key(assetPath);
}

class QuestAssetCatalog {
  QuestAssetCatalog._();

  static final QuestAssetCatalog instance = QuestAssetCatalog._();

  static const _dungeonKeywords = {
    'rust_arena': ['rust', 'rusty', 'brute', 'iron'],
  };

  static const _enemyKeywords = {
    'rust_goblin': ['rust', 'rusty'],
    'dust_sprite': ['dust', 'dusty', 'sprite', 'trap'],
    'iron_rat': ['rust', 'rat', 'combat'],
    'iron_brute': ['brute', 'boss'],
  };

  String mapPath = 'assets/images/quest/map.png';
  final List<QuestAssetRef> locations = [];
  final List<QuestAssetRef> roomTags = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw =
          await rootBundle.loadString('assets/data/quest_assets_manifest.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      mapPath = QuestAssets.key(json['map'] as String? ?? mapPath);

      for (final e in json['locations'] as List? ?? []) {
        locations.add(_refFromJson(e as Map<String, dynamic>));
      }
      for (final e in json['rooms'] as List? ?? []) {
        roomTags.add(_refFromJson(e as Map<String, dynamic>));
      }
    } catch (_) {
      _loadDefaults();
    }
    if (locations.isEmpty) _loadDefaults();
    _loaded = true;
  }

  QuestAssetRef _refFromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    QuestRoomType? type;
    if (typeStr != null) {
      for (final t in QuestRoomType.values) {
        if (t.name == typeStr) {
          type = t;
          break;
        }
      }
    }
    return QuestAssetRef(
      id: json['id'] as String,
      assetPath: QuestAssets.key(json['path'] as String),
      label: json['label'] as String? ?? json['id'] as String,
      roomType: type,
    );
  }

  QuestAssetRef pickLocation(
    QuestRoomType type,
    Random rng, {
    String? dungeonId,
    String? enemyId,
  }) {
    final pool = _rankedPool(
      locations,
      type,
      dungeonId: dungeonId,
      enemyId: enemyId,
      preferRoom: false,
    );
    return pool[rng.nextInt(pool.length)];
  }

  QuestAssetRef pickRoomBackground(
    QuestRoomType type,
    Random rng, {
    String? dungeonId,
    String? enemyId,
  }) {
    final pool = _rankedPool(
      roomTags,
      type,
      dungeonId: dungeonId,
      enemyId: enemyId,
      preferRoom: true,
    );
    return pool[rng.nextInt(pool.length)];
  }

  @Deprecated('Use pickRoomBackground')
  QuestAssetRef pickRoomTag(
    QuestRoomType type,
    Random rng, {
    String? dungeonId,
    String? enemyId,
  }) =>
      pickRoomBackground(type, rng, dungeonId: dungeonId, enemyId: enemyId);

  List<QuestAssetRef> _rankedPool(
    List<QuestAssetRef> all,
    QuestRoomType type, {
    String? dungeonId,
    String? enemyId,
    required bool preferRoom,
  }) {
    final typed = _poolForType(all, type);
    final keywords = <String>[
      ...?_dungeonKeywords[dungeonId],
      ...?_enemyKeywords[enemyId],
      if (type == QuestRoomType.trap) ...['trap', 'dust', 'sprite'],
      if (type == QuestRoomType.combat && dungeonId == 'rust_arena')
        ...['rust', 'rusty', 'brute'],
      if (type == QuestRoomType.boss) ...['boss', 'brute'],
    ];
    if (keywords.isEmpty) return typed;

    final preferred = typed.where((a) {
      final hay = '${a.id} ${a.label}'.toLowerCase();
      return keywords.any(hay.contains);
    }).toList();

    return preferred.isNotEmpty ? preferred : typed;
  }

  List<QuestAssetRef> _poolForType(List<QuestAssetRef> all, QuestRoomType type) {
    final matched = all.where((a) => a.roomType == type).toList();
    if (matched.isNotEmpty) return matched;
    return all;
  }

  QuestAssetRef? locationById(String id) {
    for (final l in locations) {
      if (l.id == id) return l;
    }
    return null;
  }

  QuestAssetRef? roomById(String id) {
    for (final r in roomTags) {
      if (r.id == id) return r;
    }
    return null;
  }

  String locationPathFor(String id) =>
      locationById(id)?.bundleKey ?? QuestAssets.key('images/quest/room_combat.png');

  String roomPathFor(String id) =>
      roomById(id)?.bundleKey ?? QuestAssets.key('images/quest/room_combat.png');

  void _loadDefaults() {
    locations.clear();
    roomTags.clear();
    for (final type in QuestRoomType.values) {
      if (type == QuestRoomType.npc) continue;
      final id = type.name;
      locations.add(
        QuestAssetRef(
          id: '${id}_default',
          assetPath: QuestAssets.key('images/quest/room_$id.png'),
          label: id.toUpperCase(),
          roomType: type,
        ),
      );
      roomTags.add(
        QuestAssetRef(
          id: 'tag_$id',
          assetPath: QuestAssets.key('images/quest/room_$id.png'),
          label: id.toUpperCase(),
          roomType: type,
        ),
      );
    }
  }
}
