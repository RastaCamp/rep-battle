import '../models/ability_modifier.dart';
import '../models/quest/quest_player_state.dart';

/// Applies per-player ability modifiers to quest roster at run start.
class QuestModifierEngine {
  static void applyStartingStats(
    QuestPlayerState player,
    AbilityModifierConfig mod,
    int baseHp,
  ) {
    if (player.isCpu) return;
    player.abilityModifierId = mod.id;
    if (mod.fixedLives != null) {
      player.maxHp = mod.fixedLives!;
      player.hp = mod.fixedLives!;
    } else {
      final hp = (baseHp + mod.bonusLives + mod.lifeDelta).clamp(1, 99);
      player.maxHp = hp;
      player.hp = hp;
    }
    player.armor += mod.bonusArmor;
    player.skips += mod.bonusSkips;
  }
}
