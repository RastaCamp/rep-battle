import 'package:flutter/material.dart';

import 'quest_inventory.dart';

class QuestPlayerState {
  final String id;
  String name;
  int colorValue;
  String avatarId;
  int hp;
  int maxHp;
  int armor;
  int skips;
  int gold;
  int xp;
  int attackBonus;
  int combo;
  bool eliminated;
  QuestInventory inventory;
  final Map<String, int> tempBuffs;
  bool isCpu;
  String? title;
  String? npcProfileId;
  double? npcPassRate;
  double? npcModifiedRate;
  double? npcFailRate;
  double? npcTimingMultiplier;
  String abilityModifierId;

  QuestPlayerState({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.avatarId,
    required this.hp,
    required this.maxHp,
    this.armor = 0,
    this.skips = 0,
    this.gold = 0,
    this.xp = 0,
    this.attackBonus = 0,
    this.combo = 0,
    this.eliminated = false,
    QuestInventory? inventory,
    Map<String, int>? tempBuffs,
    this.isCpu = false,
    this.title,
    this.npcProfileId,
    this.npcPassRate,
    this.npcModifiedRate,
    this.npcFailRate,
    this.npcTimingMultiplier,
    this.abilityModifierId = 'standard',
  })  : inventory = inventory ?? QuestInventory(),
        tempBuffs = tempBuffs ?? {};

  Color get color => Color(colorValue);

  bool get alive => !eliminated && hp > 0;

  void heal(int amount) {
    hp = (hp + amount).clamp(0, maxHp);
  }

  void takeDamage(int dmg) {
    var remaining = dmg;
    if (armor > 0 && remaining > 0) {
      armor--;
      remaining--;
    }
    if (remaining > 0) {
      hp -= remaining;
    }
    if (hp <= 0) {
      hp = 0;
      eliminated = true;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'avatarId': avatarId,
        'hp': hp,
        'maxHp': maxHp,
        'armor': armor,
        'skips': skips,
        'gold': gold,
        'xp': xp,
        'attackBonus': attackBonus,
        'combo': combo,
        'eliminated': eliminated,
        'inventory': inventory.toJson(),
        'tempBuffs': tempBuffs,
        'isCpu': isCpu,
        'title': title,
        'npcProfileId': npcProfileId,
        'npcPassRate': npcPassRate,
        'npcModifiedRate': npcModifiedRate,
        'npcFailRate': npcFailRate,
        'npcTimingMultiplier': npcTimingMultiplier,
        'abilityModifierId': abilityModifierId,
      };

  factory QuestPlayerState.fromJson(Map<String, dynamic> json) =>
      QuestPlayerState(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int,
        avatarId: json['avatarId'] as String,
        hp: json['hp'] as int,
        maxHp: json['maxHp'] as int,
        armor: json['armor'] as int? ?? 0,
        skips: json['skips'] as int? ?? 0,
        gold: json['gold'] as int? ?? 0,
        xp: json['xp'] as int? ?? 0,
        attackBonus: json['attackBonus'] as int? ?? 0,
        combo: json['combo'] as int? ?? 0,
        eliminated: json['eliminated'] as bool? ?? false,
        inventory: QuestInventory.fromJson(
          json['inventory'] as Map<String, dynamic>?,
        ),
        tempBuffs: Map<String, int>.from(
          (json['tempBuffs'] as Map?)?.cast<String, int>() ?? {},
        ),
        isCpu: json['isCpu'] as bool? ?? false,
        title: json['title'] as String?,
        npcProfileId: json['npcProfileId'] as String?,
        npcPassRate: (json['npcPassRate'] as num?)?.toDouble(),
        npcModifiedRate: (json['npcModifiedRate'] as num?)?.toDouble(),
        npcFailRate: (json['npcFailRate'] as num?)?.toDouble(),
        npcTimingMultiplier: (json['npcTimingMultiplier'] as num?)?.toDouble(),
        abilityModifierId: json['abilityModifierId'] as String? ?? 'standard',
      );
}
