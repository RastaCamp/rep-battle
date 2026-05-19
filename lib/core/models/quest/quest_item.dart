class QuestItem {
  final String id;
  final String name;
  final String rarity;
  final String type;
  final String description;
  final String? imageAsset;
  final Map<String, dynamic> effects;

  const QuestItem({
    required this.id,
    required this.name,
    required this.rarity,
    required this.type,
    required this.description,
    this.imageAsset,
    required this.effects,
  });

  String get portraitPath =>
      imageAsset ?? 'assets/images/quest/$id.png';

  factory QuestItem.fromJson(Map<String, dynamic> json) => QuestItem(
        id: json['id'] as String,
        name: json['name'] as String,
        rarity: json['rarity'] as String,
        type: json['type'] as String,
        description: json['description'] as String,
        imageAsset: json['imageAsset'] as String?,
        effects: Map<String, dynamic>.from(json['effects'] as Map),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rarity': rarity,
        'type': type,
        'description': description,
        'effects': effects,
      };
}

class QuestItemCatalog {
  QuestItemCatalog._();
  static final Map<String, QuestItem> _items = {};

  static void loadAll(List<QuestItem> items) {
    _items.clear();
    for (final i in items) {
      _items[i.id] = i;
    }
  }

  static QuestItem? get(String? id) => id == null ? null : _items[id];

  static List<QuestItem> get all => _items.values.toList();

  static int raritySort(String r) => switch (r) {
        'legendary' => 4,
        'epic' => 3,
        'rare' => 2,
        _ => 1,
      };

  static int effectValue(QuestItem item, String key, [int fallback = 0]) =>
      (item.effects[key] as num?)?.toInt() ?? fallback;
}
