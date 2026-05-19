enum QuestRoomType { combat, rest, treasure, trap, boss, npc }

class QuestRoomSpec {
  final QuestRoomType type;

  const QuestRoomSpec({required this.type});

  factory QuestRoomSpec.fromJson(Map<String, dynamic> json) {
    final t = json['type'] as String;
    return QuestRoomSpec(
      type: QuestRoomType.values.firstWhere(
        (e) => e.name == t,
        orElse: () => QuestRoomType.combat,
      ),
    );
  }
}

class QuestDungeonTemplate {
  final String id;
  final String name;
  final String subtitle;
  final int roomCount;
  final int bossEvery;
  final List<String> enemyPool;
  final String bossId;
  final List<QuestRoomSpec> rooms;

  const QuestDungeonTemplate({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.roomCount,
    required this.bossEvery,
    required this.enemyPool,
    required this.bossId,
    required this.rooms,
  });

  factory QuestDungeonTemplate.fromJson(Map<String, dynamic> json) => QuestDungeonTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        roomCount: json['roomCount'] as int,
        bossEvery: json['bossEvery'] as int? ?? 5,
        enemyPool: (json['enemyPool'] as List).cast<String>(),
        bossId: json['bossId'] as String,
        rooms: (json['rooms'] as List)
            .map((e) => QuestRoomSpec.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class QuestDifficulty {
  final String id;
  final String name;
  final int playerHp;
  final double enemyHpMult;
  final int enemyAttackBonus;

  const QuestDifficulty({
    required this.id,
    required this.name,
    required this.playerHp,
    required this.enemyHpMult,
    required this.enemyAttackBonus,
  });

  factory QuestDifficulty.fromJson(Map<String, dynamic> json) => QuestDifficulty(
        id: json['id'] as String,
        name: json['name'] as String,
        playerHp: json['playerHp'] as int,
        enemyHpMult: (json['enemyHpMult'] as num).toDouble(),
        enemyAttackBonus: json['enemyAttackBonus'] as int? ?? 0,
      );
}
