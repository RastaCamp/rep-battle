import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/config/game_mode_config.dart';

class RulesLoader {
  static RulesConfig? _cached;

  static Future<RulesConfig> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/data/rules.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final modesRaw = json['modes'] as Map<String, dynamic>;
    final modes = <String, GameModeConfig>{};
    modesRaw.forEach((key, value) {
      modes[key] = GameModeConfig.fromJson(key, value as Map<String, dynamic>);
    });
    final comboRewards = (json['comboRewards'] as List)
        .map((e) => ComboReward.fromJson(e as Map<String, dynamic>))
        .toList();
    _cached = RulesConfig(
      modes: modes,
      comboRewards: comboRewards,
      kingGroupReps: json['kingGroupReps'] as int? ?? 15,
      aceDefaultReps: json['aceDefaultReps'] as int? ?? 1,
      aceHighReps: json['aceHighReps'] as int? ?? 11,
      hypePerCombo: json['hypePerCombo'] as int? ?? 10,
      hypePerKing: json['hypePerKing'] as int? ?? 15,
      hypeMax: json['hypeMax'] as int? ?? 100,
    );
    return _cached!;
  }
}
