import 'package:flutter/material.dart';

class PlayerState {
  final String id;
  String name;
  Color color;
  String? teamId;

  int lives;
  int armor;
  int skips;
  int score;
  int totalReps;
  int cardsCompleted;
  int cardsFailed;
  int comboContribution;
  int armorUsed;
  int skipsUsed;
  int modifiedUsed;

  bool eliminated;
  bool isCpu;
  String cpuDifficulty;
  String? title;
  String? iconId;
  String? avatarId;
  String? avatarAsset;
  String? npcProfileId;
  String abilityModifierId;
  double? npcPassRate;
  double? npcModifiedRate;
  double? npcFailRate;
  double? npcTimingMultiplier;

  PlayerState({
    required this.id,
    required this.name,
    required this.color,
    this.teamId,
    required this.lives,
    this.armor = 0,
    this.skips = 0,
    this.score = 0,
    this.totalReps = 0,
    this.cardsCompleted = 0,
    this.cardsFailed = 0,
    this.comboContribution = 0,
    this.armorUsed = 0,
    this.skipsUsed = 0,
    this.modifiedUsed = 0,
    this.eliminated = false,
    this.isCpu = false,
    this.cpuDifficulty = 'normal',
    this.title,
    this.iconId,
    this.avatarId,
    this.avatarAsset,
    this.npcProfileId,
    this.abilityModifierId = 'standard',
    this.npcPassRate,
    this.npcModifiedRate,
    this.npcFailRate,
    this.npcTimingMultiplier,
  });

  PlayerState copy() => PlayerState(
        id: id,
        name: name,
        color: color,
        teamId: teamId,
        lives: lives,
        armor: armor,
        skips: skips,
        score: score,
        totalReps: totalReps,
        cardsCompleted: cardsCompleted,
        cardsFailed: cardsFailed,
        comboContribution: comboContribution,
        armorUsed: armorUsed,
        skipsUsed: skipsUsed,
        modifiedUsed: modifiedUsed,
        eliminated: eliminated,
        isCpu: isCpu,
        cpuDifficulty: cpuDifficulty,
        title: title,
        iconId: iconId,
        avatarId: avatarId,
        avatarAsset: avatarAsset,
        npcProfileId: npcProfileId,
        abilityModifierId: abilityModifierId,
        npcPassRate: npcPassRate,
        npcModifiedRate: npcModifiedRate,
        npcFailRate: npcFailRate,
        npcTimingMultiplier: npcTimingMultiplier,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
        'teamId': teamId,
        'lives': lives,
        'armor': armor,
        'skips': skips,
        'score': score,
        'totalReps': totalReps,
        'cardsCompleted': cardsCompleted,
        'cardsFailed': cardsFailed,
        'comboContribution': comboContribution,
        'armorUsed': armorUsed,
        'skipsUsed': skipsUsed,
        'modifiedUsed': modifiedUsed,
        'eliminated': eliminated,
        'isCpu': isCpu,
        'cpuDifficulty': cpuDifficulty,
        'title': title,
        'iconId': iconId,
        'avatarId': avatarId,
        'avatarAsset': avatarAsset,
        'npcProfileId': npcProfileId,
        'abilityModifierId': abilityModifierId,
        'npcPassRate': npcPassRate,
        'npcModifiedRate': npcModifiedRate,
        'npcFailRate': npcFailRate,
        'npcTimingMultiplier': npcTimingMultiplier,
      };

  factory PlayerState.fromJson(Map<String, dynamic> json) => PlayerState(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        teamId: json['teamId'] as String?,
        lives: json['lives'] as int,
        armor: json['armor'] as int? ?? 0,
        skips: json['skips'] as int? ?? 0,
        score: json['score'] as int? ?? 0,
        totalReps: json['totalReps'] as int? ?? 0,
        cardsCompleted: json['cardsCompleted'] as int? ?? 0,
        cardsFailed: json['cardsFailed'] as int? ?? 0,
        comboContribution: json['comboContribution'] as int? ?? 0,
        armorUsed: json['armorUsed'] as int? ?? 0,
        skipsUsed: json['skipsUsed'] as int? ?? 0,
        modifiedUsed: json['modifiedUsed'] as int? ?? 0,
        eliminated: json['eliminated'] as bool? ?? false,
        isCpu: json['isCpu'] as bool? ?? false,
        cpuDifficulty: json['cpuDifficulty'] as String? ?? 'normal',
        title: json['title'] as String?,
        iconId: json['iconId'] as String?,
        avatarId: json['avatarId'] as String?,
        avatarAsset: json['avatarAsset'] as String?,
        npcProfileId: json['npcProfileId'] as String?,
        abilityModifierId:
            json['abilityModifierId'] as String? ?? 'standard',
        npcPassRate: (json['npcPassRate'] as num?)?.toDouble(),
        npcModifiedRate: (json['npcModifiedRate'] as num?)?.toDouble(),
        npcFailRate: (json['npcFailRate'] as num?)?.toDouble(),
        npcTimingMultiplier: (json['npcTimingMultiplier'] as num?)?.toDouble(),
      );
}
