class QuestEnemyTemplate {
  final String id;
  final String name;
  final String imageAsset;
  final int hp;
  final int attack;
  final String weakness;
  final int rewardXp;
  final int rewardGold;
  final bool isBoss;
  final Map<String, List<String>> barks;

  const QuestEnemyTemplate({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.hp,
    required this.attack,
    required this.weakness,
    required this.rewardXp,
    required this.rewardGold,
    this.isBoss = false,
    required this.barks,
  });

  factory QuestEnemyTemplate.fromJson(Map<String, dynamic> json) {
    final barkRaw = json['barks'] as Map<String, dynamic>? ?? {};
    final barks = <String, List<String>>{};
    for (final e in barkRaw.entries) {
      barks[e.key] = (e.value as List).cast<String>();
    }
    return QuestEnemyTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      imageAsset: json['imageAsset'] as String? ??
          'assets/images/quest/${json['id']}.png',
      hp: json['hp'] as int,
      attack: json['attack'] as int,
      weakness: json['weakness'] as String,
      rewardXp: json['rewardXp'] as int? ?? 5,
      rewardGold: json['rewardGold'] as int? ?? 3,
      isBoss: json['isBoss'] as bool? ?? false,
      barks: barks,
    );
  }

  String pickBark(String kind) {
    final lines = barks[kind];
    if (lines == null || lines.isEmpty) return '';
    return lines[DateTime.now().millisecond % lines.length];
  }
}

class QuestEnemyInstance {
  final String templateId;
  final String name;
  final String imageAsset;
  final int maxHp;
  int hp;
  final int attack;
  final String weakness;
  final int rewardXp;
  final int rewardGold;
  final bool isBoss;

  QuestEnemyInstance({
    required this.templateId,
    required this.name,
    required this.imageAsset,
    required this.maxHp,
    required this.hp,
    required this.attack,
    required this.weakness,
    required this.rewardXp,
    required this.rewardGold,
    this.isBoss = false,
  });

  factory QuestEnemyInstance.fromTemplate(
    QuestEnemyTemplate t, {
    double hpMult = 1.0,
    int attackBonus = 0,
  }) =>
      QuestEnemyInstance(
        templateId: t.id,
        name: t.name,
        imageAsset: t.imageAsset,
        maxHp: (t.hp * hpMult).round().clamp(1, 999),
        hp: (t.hp * hpMult).round().clamp(1, 999),
        attack: t.attack + attackBonus,
        weakness: t.weakness,
        rewardXp: t.rewardXp,
        rewardGold: t.rewardGold,
        isBoss: t.isBoss,
      );

  bool get defeated => hp <= 0;
  bool get lowHealth => hp <= (maxHp * 0.35).ceil();

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'name': name,
        'imageAsset': imageAsset,
        'maxHp': maxHp,
        'hp': hp,
        'attack': attack,
        'weakness': weakness,
        'rewardXp': rewardXp,
        'rewardGold': rewardGold,
        'isBoss': isBoss,
      };

  factory QuestEnemyInstance.fromJson(Map<String, dynamic> json) =>
      QuestEnemyInstance(
        templateId: json['templateId'] as String,
        name: json['name'] as String,
        imageAsset: json['imageAsset'] as String? ??
            'assets/images/quest/${json['templateId']}.png',
        maxHp: json['maxHp'] as int,
        hp: json['hp'] as int,
        attack: json['attack'] as int,
        weakness: json['weakness'] as String,
        rewardXp: json['rewardXp'] as int,
        rewardGold: json['rewardGold'] as int,
        isBoss: json['isBoss'] as bool? ?? false,
      );
}

class QuestEnemyCatalog {
  QuestEnemyCatalog._();
  static final Map<String, QuestEnemyTemplate> _enemies = {};

  static void loadAll(List<QuestEnemyTemplate> list) {
    _enemies.clear();
    for (final e in list) {
      _enemies[e.id] = e;
    }
  }

  static QuestEnemyTemplate get(String id) => _enemies[id]!;

  static QuestEnemyTemplate? tryGet(String id) => _enemies[id];
}
