import 'dart:math';

import '../models/game_card.dart';
import '../models/player_state.dart';

/// CPU turn length: card rep value + 3 seconds (× profile timing).
class CpuTiming {
  static final _random = Random();

  static Duration estimateExerciseDelay(
    GameCard card,
    PlayerState cpu, {
    bool willUseModified = false,
  }) {
    final reps = _repValue(card);
    var seconds = reps + 3.0;

    if (cpu.npcTimingMultiplier != null) {
      seconds *= cpu.npcTimingMultiplier!;
    } else {
      seconds *= switch (cpu.cpuDifficulty) {
        'easy' => 1.2,
        'hard' => 0.88,
        'beast' => 0.75,
        _ => 1.0,
      };
    }

    if (card.isKing) seconds += 2;
    if (willUseModified) seconds += 1.5;
    if (card.repUnit == 'seconds') {
      seconds = (card.reps ?? 30) * 0.4 + 3;
    }

    final jitter = 0.9 + _random.nextDouble() * 0.2;
    final ms = (seconds * jitter * 1000).round().clamp(1500, 60000);
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

  static bool cpuLikelyModified(PlayerState cpu, GameCard card) {
    if (cpu.npcModifiedRate != null) {
      var rate = cpu.npcModifiedRate!;
      if (card.isQueen) rate += 0.08;
      if (card.isKing) rate += 0.05;
      return _random.nextDouble() < rate.clamp(0.05, 0.65);
    }
    if (cpu.cpuDifficulty == 'beast') return false;
    if (cpu.cpuDifficulty == 'easy') return _random.nextDouble() < 0.35;
    return _random.nextDouble() < 0.12;
  }
}
