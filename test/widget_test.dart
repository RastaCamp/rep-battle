import 'package:flutter_test/flutter_test.dart';
import 'package:rep_battle/core/config/deck_art_style.dart';
import 'package:rep_battle/core/data/deck_factory.dart';
import 'package:rep_battle/core/services/shuffle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('standard deck has unique ids and 54 cards', () async {
    final deck = await DeckFactory.buildStandardDeck();
    expect(deck.length, 54);
    final errors = DeckFactory.validateDeck(deck);
    expect(errors, isEmpty);
    expect(deck.where((c) => c.useSuitTemplate).length, 0);
  });

  test('custom template deck uses suit templates', () async {
    final deck = await DeckFactory.buildStandardDeck(
      artStyle: DeckArtStyle.customTemplate,
    );
    final nonJokers = deck.where((c) => c.suit.name != 'joker');
    expect(nonJokers.every((c) => c.useSuitTemplate), isTrue);
  });

  test('fisher-yates shuffle empty deck', () {
    expect(ShuffleService.fisherYates([]), isEmpty);
  });
}
