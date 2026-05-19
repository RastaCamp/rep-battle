import '../core/models/match_state.dart';
import '../core/models/player_state.dart';
import 'save_service.dart';

class AchievementDef {
  final String id;
  final String title;
  final bool Function(PlayerState player, MatchState? match, Map<String, dynamic> stats) check;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.check,
  });
}

class AchievementService {
  final SaveService save;
  AchievementService(this.save);

  static final defs = [
    AchievementDef(
      id: 'first_combo',
      title: 'First Combo',
      check: (_, match, __) => (match?.comboChain ?? 0) >= 1,
    ),
    AchievementDef(
      id: 'combo_x5',
      title: 'Combo x5',
      check: (_, match, __) => (match?.comboChain ?? 0) >= 5,
    ),
    AchievementDef(
      id: 'first_victory',
      title: 'First Victory',
      check: (player, match, __) =>
          match?.matchOver == true && match?.winnerId == player.id,
    ),
    AchievementDef(
      id: 'reps_100',
      title: '100 Reps',
      check: (player, _, stats) =>
          (stats['lifetimeReps'] as int? ?? 0) + player.totalReps >= 100,
    ),
    AchievementDef(
      id: 'king_survivor',
      title: 'King Slayer',
      check: (player, _, __) => player.comboContribution >= 3,
    ),
    AchievementDef(
      id: 'first_deck_complete',
      title: 'Deck Complete',
      check: (_, __, stats) => stats['firstDeckComplete'] == true,
    ),
  ];

  Future<List<String>> evaluate({
    required PlayerState player,
    MatchState? match,
    required Map<String, dynamic> stats,
  }) async {
    final existing = await save.loadAchievements();
    final unlocked = <String>[];
    for (final def in defs) {
      if (existing.contains(def.id)) continue;
      if (def.check(player, match, stats)) {
        await save.unlockAchievement(def.id);
        unlocked.add(def.title);
      }
    }
    return unlocked;
  }
}
