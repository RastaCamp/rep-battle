import '../models/ability_modifier.dart';
import '../models/game_card.dart';
import '../models/player_state.dart';

/// Applies per-player modifier to cards, reps, and scoring.
class AbilityModifierEngine {
  static const _seatedNames = {
    'pushups': 'Chair Pushups / Wall Press',
    'squats': 'Seated March / Chair Squats',
    'situps': 'Seated Crunches',
    'mountain_climbers': 'Seated Knee Lifts',
    'pushup_hold': 'Wall Press Hold',
    'wall_sit': 'Seated Posture Hold',
    'plank': 'Seated Core Brace',
  };

  static const _lowImpactNames = {
    'mountain_climbers': 'Slow Knee Drives (seated option)',
  };

  static void applyStartingStats(
    PlayerState player,
    AbilityModifierConfig mod,
    int modeBaseLives,
  ) {
    player.abilityModifierId = mod.id;
    if (mod.fixedLives != null) {
      player.lives = mod.fixedLives!;
    } else {
      player.lives = (modeBaseLives + mod.bonusLives + mod.lifeDelta).clamp(1, 99);
    }
    player.armor += mod.bonusArmor;
    player.skips += mod.bonusSkips;
  }

  static GameCard personalizeCard(GameCard base, PlayerState player) {
    final mod = AbilityModifiers.get(player.abilityModifierId);
    var card = base;

    if (mod.seatedMode) {
      final seated = _seatedNames[card.exerciseId];
      if (seated != null) {
        card = card.copyWith(
          exerciseName: seated,
          modifiedName: 'Easier seated variation',
        );
      }
    } else if (mod.noJumping) {
      final alt = _lowImpactNames[card.exerciseId];
      if (alt != null) {
        card = card.copyWith(exerciseName: alt);
      }
    }

    if (mod.showAssistedOptions && card.modifiedName == null) {
      card = card.copyWith(modifiedName: 'Assisted / seated option');
    }

    final baseReps = _baseReps(card);
    if (baseReps != null) {
      final scaled = _scaleReps(baseReps, mod.repMultiplier);
      card = card.copyWith(reps: scaled);
    }

    if (mod.seatedMode && (card.repNote == null || card.repNote!.isEmpty)) {
      card = card.copyWith(repNote: 'Chair-safe');
    }

    return card;
  }

  static int? effectiveReps(GameCard card, PlayerState player) {
    final mod = AbilityModifiers.get(player.abilityModifierId);
    final base = _baseReps(card);
    if (base == null) return null;
    return _scaleReps(base, mod.repMultiplier);
  }

  static int scalePoints(int points, PlayerState player) {
    final mod = AbilityModifiers.get(player.abilityModifierId);
    return (points * mod.scoreMultiplier).round();
  }

  static double modifiedMultiplier(
    PlayerState player,
    double modeDefault,
  ) {
    final mod = AbilityModifiers.get(player.abilityModifierId);
    if (mod.modifiedCountsAsPass) return 1.0;
    return mod.effectiveModifiedMultiplier(modeDefault);
  }

  static bool timerEnabledForPlayer(
    PlayerState player, {
    required bool modeTimerEnabled,
    required bool matchForceTimerOff,
  }) {
    if (matchForceTimerOff) return false;
    final mod = AbilityModifiers.get(player.abilityModifierId);
    if (mod.disableTimer) return false;
    return modeTimerEnabled;
  }

  static String challengeLabel(GameCard card, PlayerState player) {
    final c = personalizeCard(card, player);
    if (c.isJack) return 'Repeat previous card!';
    if (c.isKing) {
      return 'KING: ${c.exerciseName} x${c.reps ?? 15} (your reps)';
    }
    if (c.isJoker) return c.exerciseName;
    if (c.repNote != null) {
      return '${c.exerciseName} ${c.displayReps} (${c.repNote})';
    }
    return '${c.exerciseName} × ${c.displayReps}';
  }

  static int? _baseReps(GameCard card) {
    if (card.reps != null) return card.reps;
    final n = int.tryParse(card.rank);
    if (n != null) return n;
    if (card.rank == 'A') return 1;
    return null;
  }

  static int _scaleReps(int reps, double mult) {
    final scaled = (reps * mult).round();
    return scaled < 1 ? 1 : scaled;
  }
}
