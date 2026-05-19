import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/models/quest/quest_dungeon.dart';
import '../core/models/quest/quest_enemy.dart';
import '../core/models/quest/quest_item.dart';
import 'quest_asset_catalog.dart';

class QuestDataBundle {
  final List<QuestDifficulty> difficulties;
  final List<QuestDungeonTemplate> dungeons;
  final Map<String, List<String>> lootTables;
  final Map<String, dynamic> story;

  QuestDataBundle({
    required this.difficulties,
    required this.dungeons,
    required this.lootTables,
    required this.story,
  });

  QuestDungeonTemplate dungeon(String id) =>
      dungeons.firstWhere((d) => d.id == id);

  QuestDifficulty difficulty(String id) =>
      difficulties.firstWhere((d) => d.id == id);
}

class QuestDataLoader {
  static QuestDataBundle? _cached;

  static Future<QuestDataBundle> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/data/quest_mode.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final difficulties = (json['difficulties'] as List)
        .map((e) => QuestDifficulty.fromJson(e as Map<String, dynamic>))
        .toList();

    final dungeons = (json['dungeons'] as List)
        .map((e) => QuestDungeonTemplate.fromJson(e as Map<String, dynamic>))
        .toList();

    final enemies = (json['enemies'] as List)
        .map((e) => QuestEnemyTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    QuestEnemyCatalog.loadAll(enemies);

    final items = (json['items'] as List)
        .map((e) => QuestItem.fromJson(e as Map<String, dynamic>))
        .toList();
    QuestItemCatalog.loadAll(items);

    final lootRaw = json['lootTables'] as Map<String, dynamic>;
    final lootTables = lootRaw.map(
      (k, v) => MapEntry(k, (v as List).cast<String>()),
    );

    Map<String, dynamic> story = {};
    try {
      final storyRaw =
          await rootBundle.loadString('assets/data/quest_story.json');
      story = jsonDecode(storyRaw) as Map<String, dynamic>;
    } catch (_) {}

    await QuestAssetCatalog.instance.load();

    _cached = QuestDataBundle(
      difficulties: difficulties,
      dungeons: dungeons,
      lootTables: lootTables,
      story: story,
    );
    return _cached!;
  }
}
