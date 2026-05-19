class GameModeConfig {
  final String id;
  final String name;
  final int lives;
  final bool timerEnabled;
  final int timerSeconds;
  final bool eliminationEnabled;
  final bool reshuffleOnEmpty;
  final double modifiedScoreMultiplier;
  final int startingArmor;
  final int startingSkips;
  final bool teamMode;

  const GameModeConfig({
    required this.id,
    required this.name,
    required this.lives,
    required this.timerEnabled,
    required this.timerSeconds,
    required this.eliminationEnabled,
    required this.reshuffleOnEmpty,
    required this.modifiedScoreMultiplier,
    required this.startingArmor,
    required this.startingSkips,
    this.teamMode = false,
  });

  factory GameModeConfig.fromJson(String id, Map<String, dynamic> json) =>
      GameModeConfig(
        id: id,
        name: json['name'] as String,
        lives: json['lives'] as int,
        timerEnabled: json['timerEnabled'] as bool? ?? false,
        timerSeconds: json['timerSeconds'] as int? ?? 0,
        eliminationEnabled: json['eliminationEnabled'] as bool? ?? true,
        reshuffleOnEmpty: json['reshuffleOnEmpty'] as bool? ?? false,
        modifiedScoreMultiplier:
            (json['modifiedScoreMultiplier'] as num?)?.toDouble() ?? 0.5,
        startingArmor: json['startingArmor'] as int? ?? 0,
        startingSkips: json['startingSkips'] as int? ?? 0,
        teamMode: json['teamMode'] as bool? ?? false,
      );
}

class ComboReward {
  final int chain;
  final int bonusPoints;
  final int armorAll;
  final int skipAll;

  const ComboReward({
    required this.chain,
    required this.bonusPoints,
    this.armorAll = 0,
    this.skipAll = 0,
  });

  factory ComboReward.fromJson(Map<String, dynamic> json) => ComboReward(
        chain: json['chain'] as int,
        bonusPoints: json['bonusPoints'] as int? ?? 0,
        armorAll: json['armorAll'] as int? ?? 0,
        skipAll: json['skipAll'] as int? ?? 0,
      );
}

class RulesConfig {
  final Map<String, GameModeConfig> modes;
  final List<ComboReward> comboRewards;
  final int kingGroupReps;
  final int aceDefaultReps;
  final int aceHighReps;
  final int hypePerCombo;
  final int hypePerKing;
  final int hypeMax;

  const RulesConfig({
    required this.modes,
    required this.comboRewards,
    required this.kingGroupReps,
    required this.aceDefaultReps,
    required this.aceHighReps,
    required this.hypePerCombo,
    required this.hypePerKing,
    required this.hypeMax,
  });

  GameModeConfig mode(String id) =>
      modes[id] ?? modes['standard'] ?? modes.values.first;
}
