/// Optional table rules — apply to the whole match.
class MatchHouseRules {
  final String winCondition;
  final bool forceTimerOff;
  final String jokerRule;
  final String kingRule;

  const MatchHouseRules({
    this.winCondition = 'elimination',
    this.forceTimerOff = false,
    this.jokerRule = 'default',
    this.kingRule = 'default',
  });

  bool get winByPoints => winCondition == 'points';
  bool get winByCards => winCondition == 'cards';
  bool get useEliminationWin => winCondition == 'elimination';
  bool get kingsOptionalSolo => kingRule == 'optional_group';
  bool get jokerRest => jokerRule == 'rest';
  bool get jokerGentle => jokerRule == 'gentle';

  Map<String, dynamic> toJson() => {
        'winCondition': winCondition,
        'forceTimerOff': forceTimerOff,
        'jokerRule': jokerRule,
        'kingRule': kingRule,
      };

  factory MatchHouseRules.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MatchHouseRules();
    return MatchHouseRules(
      winCondition: json['winCondition'] as String? ?? 'elimination',
      forceTimerOff: json['forceTimerOff'] as bool? ?? false,
      jokerRule: json['jokerRule'] as String? ?? 'default',
      kingRule: json['kingRule'] as String? ?? 'default',
    );
  }
}
