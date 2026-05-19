import 'dart:math';

import 'package:flutter/material.dart';

import 'npc_bark.dart';

class NpcProfile {
  final String id;
  final String name;
  final int age;
  final String job;
  final List<String> conditions;
  final String tagline;
  final String bio;
  final double passRate;
  final double modifiedRate;
  final double failRate;
  final double timingMultiplier;
  final Color color;
  final bool surpriseEntrant;
  final List<String> quotesVictory;
  final List<String> quotesForfeit;
  final List<String> quotesModified;
  final List<String> quotesClutch;
  final List<String> quotesStartMatch;
  final List<String> quotesLegendary;
  final List<String> quotesTeamUp;
  final List<String> quotesRespect;
  final List<String> quotesPain;
  final List<String> quotesHumiliated;

  static final _random = Random();

  const NpcProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.job,
    required this.conditions,
    required this.tagline,
    required this.bio,
    required this.passRate,
    required this.modifiedRate,
    required this.failRate,
    required this.timingMultiplier,
    required this.color,
    this.surpriseEntrant = false,
    this.quotesVictory = const [],
    this.quotesForfeit = const [],
    this.quotesModified = const [],
    this.quotesClutch = const [],
    this.quotesStartMatch = const [],
    this.quotesLegendary = const [],
    this.quotesTeamUp = const [],
    this.quotesRespect = const [],
    this.quotesPain = const [],
    this.quotesHumiliated = const [],
  });

  String? pickQuote(NpcBarkKind kind) {
    final pool = switch (kind) {
      NpcBarkKind.victory => quotesVictory,
      NpcBarkKind.forfeit => quotesForfeit,
      NpcBarkKind.modified => quotesModified,
      NpcBarkKind.clutch => quotesClutch,
      NpcBarkKind.startMatch => quotesStartMatch,
      NpcBarkKind.legendary => quotesLegendary,
      NpcBarkKind.teamUp => quotesTeamUp,
      NpcBarkKind.respect => quotesRespect,
      NpcBarkKind.pain => quotesPain,
      NpcBarkKind.humiliated => quotesHumiliated,
    };
    if (pool.isEmpty) return null;
    return pool[_random.nextInt(pool.length)];
  }

  String get avatarAsset => 'assets/images/npcs/$id.png';

  String get conditionsLabel =>
      conditions.isEmpty ? 'None listed' : conditions.join(', ');

  static List<String> _quotesFromJson(Map<String, dynamic> json, String key) =>
      (json[key] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

  factory NpcProfile.fromJson(Map<String, dynamic> json) => NpcProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int,
        job: json['job'] as String,
        conditions: (json['conditions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        tagline: json['tagline'] as String,
        bio: json['bio'] as String,
        passRate: (json['passRate'] as num).toDouble(),
        modifiedRate: (json['modifiedRate'] as num).toDouble(),
        failRate: (json['failRate'] as num).toDouble(),
        timingMultiplier: (json['timingMultiplier'] as num).toDouble(),
        color: Color(json['colorArgb'] as int),
        surpriseEntrant: json['surpriseEntrant'] as bool? ?? false,
        quotesVictory: _quotesFromJson(json, 'quotesVictory'),
        quotesForfeit: _quotesFromJson(json, 'quotesForfeit'),
        quotesModified: _quotesFromJson(json, 'quotesModified'),
        quotesClutch: _quotesFromJson(json, 'quotesClutch'),
        quotesStartMatch: _quotesFromJson(json, 'quotesStartMatch'),
        quotesLegendary: _quotesFromJson(json, 'quotesLegendary'),
        quotesTeamUp: _quotesFromJson(json, 'quotesTeamUp'),
        quotesRespect: _quotesFromJson(json, 'quotesRespect'),
        quotesPain: _quotesFromJson(json, 'quotesPain'),
        quotesHumiliated: _quotesFromJson(json, 'quotesHumiliated'),
      );
}
