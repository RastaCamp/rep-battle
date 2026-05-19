/// Per-player ability / accessibility modifier (affects only that player).
class AbilityModifierId {
  static const standard = 'standard';
  static const beginner = 'beginner';
  static const senior = 'senior';
  static const seated = 'seated';
  static const rehab = 'rehab';
  static const advanced = 'advanced';
  static const beast = 'beast';

  static const all = [
    standard,
    beginner,
    senior,
    seated,
    rehab,
    advanced,
    beast,
  ];
}

class AbilityModifierConfig {
  final String id;
  final String name;
  final String subtitle;
  final int bonusLives;
  final int bonusArmor;
  final int bonusSkips;
  final int lifeDelta;
  final int? fixedLives;
  final double repMultiplier;
  final double scoreMultiplier;
  final double modifiedScoreMultiplier;
  final bool modifiedCountsAsPass;
  final bool disableTimer;
  final bool seatedMode;
  final bool noJumping;
  final bool showAssistedOptions;

  const AbilityModifierConfig({
    required this.id,
    required this.name,
    required this.subtitle,
    this.bonusLives = 0,
    this.bonusArmor = 0,
    this.bonusSkips = 0,
    this.lifeDelta = 0,
    this.fixedLives,
    this.repMultiplier = 1.0,
    this.scoreMultiplier = 1.0,
    this.modifiedScoreMultiplier = -1,
    this.modifiedCountsAsPass = false,
    this.disableTimer = false,
    this.seatedMode = false,
    this.noJumping = false,
    this.showAssistedOptions = false,
  });

  double effectiveModifiedMultiplier(double modeDefault) =>
      modifiedScoreMultiplier < 0 ? modeDefault : modifiedScoreMultiplier;
}

class AbilityModifiers {
  AbilityModifiers._();

  static const configs = <AbilityModifierConfig>[
    AbilityModifierConfig(
      id: AbilityModifierId.standard,
      name: 'Standard',
      subtitle: 'Normal rules for this player.',
    ),
    AbilityModifierConfig(
      id: AbilityModifierId.beginner,
      name: 'Beginner',
      subtitle: '+2 lives, 1 skip, reps −25%.',
      bonusLives: 2,
      bonusSkips: 1,
      repMultiplier: 0.75,
    ),
    AbilityModifierConfig(
      id: AbilityModifierId.senior,
      name: 'Senior / Low Impact',
      subtitle: '+2 lives, 1 armor, 2 skips, reps −50%, no jumping.',
      bonusLives: 2,
      bonusArmor: 1,
      bonusSkips: 2,
      repMultiplier: 0.5,
      noJumping: true,
      showAssistedOptions: true,
    ),
    AbilityModifierConfig(
      id: AbilityModifierId.seated,
      name: 'Seated Mode',
      subtitle: 'Chair-safe exercises, reps −50%, no turn timer.',
      repMultiplier: 0.5,
      disableTimer: true,
      seatedMode: true,
      showAssistedOptions: true,
    ),
    AbilityModifierConfig(
      id: AbilityModifierId.rehab,
      name: 'Rehab / Recovery',
      subtitle: '+3 lives, 2 armor, 2 skips, reps −50%, modified = full pass.',
      bonusLives: 3,
      bonusArmor: 2,
      bonusSkips: 2,
      repMultiplier: 0.5,
      modifiedCountsAsPass: true,
      modifiedScoreMultiplier: 1.0,
      showAssistedOptions: true,
    ),
    AbilityModifierConfig(
      id: AbilityModifierId.advanced,
      name: 'Advanced',
      subtitle: '−1 life, reps +25%, bonus points +25%.',
      lifeDelta: -1,
      repMultiplier: 1.25,
      scoreMultiplier: 1.25,
    ),
    AbilityModifierConfig(
      id: AbilityModifierId.beast,
      name: 'Beast Mode',
      subtitle: '1 life only, reps +50%, score ×1.5.',
      fixedLives: 1,
      repMultiplier: 1.5,
      scoreMultiplier: 1.5,
    ),
  ];

  static AbilityModifierConfig get(String? id) {
    final key = id ?? AbilityModifierId.standard;
    for (final c in configs) {
      if (c.id == key) return c;
    }
    return configs.first;
  }
}
