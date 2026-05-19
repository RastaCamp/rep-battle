import 'dart:convert';

import 'package:flutter/services.dart';

import '../config/deck_art_style.dart';
import '../models/game_card.dart';
import '../../services/custom_card_service.dart';
import 'asset_paths.dart';

class DeckFactory {
  static Future<List<GameCard>> buildStandardDeck({
    DeckArtStyle artStyle = DeckArtStyle.defaultArt,
    CustomCardService? customCards,
  }) async {
    final raw = await rootBundle.loadString('assets/data/default_deck.json');
    final meta = jsonDecode(raw) as Map<String, dynamic>;
    var deck = artStyle == DeckArtStyle.customTemplate
        ? _buildCustomTemplateDeck(meta)
        : _buildDefaultArtDeck(meta);
    if (customCards != null && artStyle == DeckArtStyle.customTemplate) {
      deck = customCards.applyOverrides(deck);
    }
    return deck;
  }

  static List<GameCard> _buildDefaultArtDeck(Map<String, dynamic> meta) {
    final exercises = meta['exercises'] as Map<String, dynamic>;
    final queens = meta['queens'] as Map<String, dynamic>;
    final cards = <GameCard>[];

    const suits = ['spades', 'hearts', 'clubs', 'diamonds'];
    const ranks = [
      'ace',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
    ];

    for (final suit in suits) {
      final ex = exercises[suit] as Map<String, dynamic>;
      final exerciseId = ex['id'] as String;
      final exerciseName = ex['name'] as String;
      final modified = ex['modified'] as String?;
      final repNote = ex['repNote'] as String?;

      for (final rank in ranks) {
        final rankUpper = rank == 'ace' ? 'A' : rank;
        cards.add(GameCard(
          id: '${suit}_$rank',
          suit: CardSuit.values.byName(suit),
          rank: rankUpper,
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          modifiedName: modified,
          reps: _numberReps(rank),
          repUnit: 'reps',
          repNote: repNote,
          cardType: CardType.number,
          imageAsset: AssetPaths.cardImage(suit, rank),
          useSuitTemplate: false,
        ));
      }

      cards.add(_defaultFace(
        suit: suit,
        rank: 'jack',
        rankLabel: 'J',
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        modified: modified,
        repNote: repNote,
        cardType: CardType.jack,
      ));

      final q = queens[suit] as Map<String, dynamic>;
      cards.add(GameCard(
        id: '${suit}_queen',
        suit: CardSuit.values.byName(suit),
        rank: 'Q',
        exerciseId: q['exercise'] as String,
        exerciseName: q['name'] as String,
        modifiedName: modified,
        reps: q['reps'] as int,
        repUnit: q['unit'] as String? ?? 'reps',
        repNote: repNote,
        cardType: CardType.queen,
        imageAsset: AssetPaths.cardImage(suit, 'queen'),
        useSuitTemplate: false,
      ));

      cards.add(_defaultFace(
        suit: suit,
        rank: 'king',
        rankLabel: 'K',
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        modified: modified,
        reps: 15,
        repNote: repNote,
        cardType: CardType.king,
        isGroup: true,
      ));
    }

    cards.addAll(_jokers(meta));
    return cards;
  }

  static List<GameCard> _buildCustomTemplateDeck(Map<String, dynamic> meta) {
    final exercises = meta['exercises'] as Map<String, dynamic>;
    final queens = meta['queens'] as Map<String, dynamic>;
    final cards = <GameCard>[];

    const suits = ['spades', 'hearts', 'clubs', 'diamonds'];
    const ranks = [
      'ace',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
    ];

    for (final suit in suits) {
      final template = AssetPaths.suitCustomTemplate(suit);
      final ex = exercises[suit] as Map<String, dynamic>;
      final exerciseId = ex['id'] as String;
      final exerciseName = ex['name'] as String;
      final modified = ex['modified'] as String?;
      final repNote = ex['repNote'] as String?;

      for (final rank in ranks) {
        final rankUpper = rank == 'ace' ? 'A' : rank;
        cards.add(_templateCard(
          id: '${suit}_$rank',
          suit: suit,
          rank: rankUpper,
          template: template,
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          modified: modified,
          reps: _numberReps(rank),
          repNote: repNote,
          cardType: CardType.number,
        ));
      }

      cards.add(_templateCard(
        id: '${suit}_jack',
        suit: suit,
        rank: 'J',
        template: template,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        modified: modified,
        repNote: repNote,
        cardType: CardType.jack,
      ));

      final q = queens[suit] as Map<String, dynamic>;
      cards.add(_templateCard(
        id: '${suit}_queen',
        suit: suit,
        rank: 'Q',
        template: template,
        exerciseId: q['exercise'] as String,
        exerciseName: q['name'] as String,
        modified: modified,
        reps: q['reps'] as int,
        repUnit: q['unit'] as String? ?? 'reps',
        repNote: repNote,
        cardType: CardType.queen,
      ));

      cards.add(_templateCard(
        id: '${suit}_king',
        suit: suit,
        rank: 'K',
        template: template,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        modified: modified,
        reps: 15,
        repNote: repNote,
        cardType: CardType.king,
        isGroup: true,
      ));
    }

    cards.addAll(_jokers(meta));
    return cards;
  }

  static List<GameCard> _jokers(Map<String, dynamic> meta) {
    final jokers = meta['jokers'] as List;
    final cards = <GameCard>[];
    for (final j in jokers) {
      final m = j as Map<String, dynamic>;
      final id = m['id'] as String;
      cards.add(GameCard(
        id: id,
        suit: CardSuit.joker,
        rank: 'Joker',
        exerciseId: m['variant'] as String,
        exerciseName: m['name'] as String,
        cardType: CardType.joker,
        jokerVariant: m['variant'] as String,
        isGroupChallenge: m['variant'] == 'group_challenge',
        imageAsset: id == 'joker_2'
            ? 'assets/images/cards/joker_2.png'
            : 'assets/images/cards/joker_1.png',
        useSuitTemplate: false,
      ));
    }
    return cards;
  }

  static GameCard _defaultFace({
    required String suit,
    required String rank,
    required String rankLabel,
    required String exerciseId,
    required String exerciseName,
    String? modified,
    int? reps,
    String? repNote,
    required CardType cardType,
    bool isGroup = false,
  }) =>
      GameCard(
        id: '${suit}_$rank',
        suit: CardSuit.values.byName(suit),
        rank: rankLabel,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        modifiedName: modified,
        reps: reps,
        repUnit: 'reps',
        repNote: repNote,
        cardType: cardType,
        isGroupChallenge: isGroup,
        imageAsset: AssetPaths.cardImage(suit, rank),
        useSuitTemplate: false,
      );

  static GameCard _templateCard({
    required String id,
    required String suit,
    required String rank,
    required String template,
    required String exerciseId,
    required String exerciseName,
    String? modified,
    int? reps,
    String? repUnit,
    String? repNote,
    required CardType cardType,
    bool isGroup = false,
  }) =>
      GameCard(
        id: id,
        suit: CardSuit.values.byName(suit),
        rank: rank,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        modifiedName: modified,
        reps: reps,
        repUnit: repUnit ?? 'reps',
        repNote: repNote,
        cardType: cardType,
        isGroupChallenge: isGroup,
        imageAsset: template,
        useSuitTemplate: true,
      );

  static int _numberReps(String rank) {
    if (rank == 'ace') return 1;
    return int.parse(rank);
  }

  /// Light weights: ranks 2–7 per suit plus both jokers (26 cards).
  static List<GameCard> trimToLightDeck(List<GameCard> deck) {
    const lightRanks = {'2', '3', '4', '5', '6', '7'};
    return deck
        .where(
          (c) =>
              c.isJoker ||
              (lightRanks.contains(c.rank) && !c.isJack && !c.isQueen && !c.isKing),
        )
        .toList();
  }

  static List<String> validateDeck(List<GameCard> deck, {int minCards = 52}) {
    final errors = <String>[];
    final ids = <String>{};
    for (final c in deck) {
      if (!ids.add(c.id)) errors.add('Duplicate card id: ${c.id}');
      if (c.exerciseId.isEmpty) {
        errors.add('Missing exercise on ${c.id}');
      }
    }
    if (deck.length < minCards) {
      errors.add('Deck has ${deck.length} cards, expected at least $minCards');
    }
    return errors;
  }
}
