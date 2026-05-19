import 'dart:math';

import '../models/game_card.dart';
import '../models/quest/quest_player_state.dart';

/// CPU decision helpers for quest party members (mirrors play-mode NPC logic).
class QuestCpu {
  static final _random = Random();

  static bool shouldPass(
    QuestPlayerState cpu,
    GameCard card,
    int comboPressure,
  ) {
    if (!cpu.isCpu) return true;
    if (cpu.npcPassRate != null) {
      var rate = cpu.npcPassRate!;
      if (card.isQueen) rate -= 0.08;
      if (card.isKing) rate -= 0.04;
      if (comboPressure > 3) rate -= 0.04;
      final failWeight = cpu.npcFailRate ?? 0.06;
      final roll = _random.nextDouble();
      if (roll < rate) return true;
      if (roll < rate + failWeight) return false;
      return false;
    }
    return _random.nextDouble() < 0.82;
  }

  static bool likelyModified(QuestPlayerState cpu, GameCard card) {
    if (!cpu.isCpu) return false;
    if (cpu.npcModifiedRate != null) {
      var rate = cpu.npcModifiedRate!;
      if (card.isQueen) rate += 0.08;
      if (card.isKing) rate += 0.05;
      return _random.nextDouble() < rate.clamp(0.05, 0.65);
    }
    return _random.nextDouble() < 0.12;
  }

  static Duration estimateExerciseDelay(
    GameCard card,
    QuestPlayerState cpu, {
    bool willUseModified = false,
  }) {
    final reps = _repValue(card);
    var seconds = reps + 3.0;
    if (cpu.npcTimingMultiplier != null) {
      seconds *= cpu.npcTimingMultiplier!;
    }
    if (card.isKing) seconds += 2;
    if (willUseModified) seconds += 1.5;
    if (card.repUnit == 'seconds') {
      seconds = (card.reps ?? 30) * 0.4 + 3;
    }
    final jitter = 0.9 + _random.nextDouble() * 0.2;
    final ms = (seconds * jitter * 1000).round().clamp(1500, 45000);
    return Duration(milliseconds: ms);
  }

  static int _repValue(GameCard card) {
    if (card.reps != null && card.reps! > 0) return card.reps!;
    final n = int.tryParse(card.rank);
    if (n != null) return n;
    if (card.rank == 'A') return 1;
    if (card.isKing) return 15;
    if (card.isQueen) return 30;
    return 10;
  }
}
