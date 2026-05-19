import 'dart:math';

import '../models/game_card.dart';

class ShuffleService {
  static List<GameCard> fisherYates(List<GameCard> deck, {int? seed}) {
    final copy = List<GameCard>.from(deck);
    final random = seed != null ? Random(seed) : Random();
    for (var i = copy.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = copy[i];
      copy[i] = copy[j];
      copy[j] = temp;
    }
    return copy;
  }
}
