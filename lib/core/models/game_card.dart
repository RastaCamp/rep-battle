enum CardSuit { spades, hearts, clubs, diamonds, joker }

enum CardType { number, jack, queen, king, joker, custom }

enum TurnResultType { pass, fail, modified, skip }

class GameCard {
  final String id;
  final CardSuit suit;
  final String rank;
  final String exerciseId;
  final String exerciseName;
  final String? modifiedName;
  final int? reps;
  final String? repUnit;
  final String? repNote;
  final CardType cardType;
  final String? jokerVariant;
  final bool isGroupChallenge;
  /// Asset path or suit template path when [useSuitTemplate] is true.
  final String imageAsset;
  /// One shared custom art per suit; rank/suit drawn in UI.
  final bool useSuitTemplate;
  /// Pro: user-uploaded center image (local path).
  final String? customImagePath;

  const GameCard({
    required this.id,
    required this.suit,
    required this.rank,
    required this.exerciseId,
    required this.exerciseName,
    this.modifiedName,
    this.reps,
    this.repUnit,
    this.repNote,
    required this.cardType,
    this.jokerVariant,
    this.isGroupChallenge = false,
    required this.imageAsset,
    this.useSuitTemplate = false,
    this.customImagePath,
  });

  bool get isFace => cardType != CardType.number;
  bool get isKing => cardType == CardType.king;
  bool get isQueen => cardType == CardType.queen;
  bool get isJack => cardType == CardType.jack;
  bool get isJoker => cardType == CardType.joker;
  bool get usesProceduralFace =>
      useSuitTemplate || customImagePath != null || cardType == CardType.custom;

  String get displayReps {
    if (reps == null) return exerciseName;
    final unit = repUnit ?? 'reps';
    if (unit == 'seconds') return '$reps sec';
    return '$reps $unit';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'suit': suit.name,
        'rank': rank,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'modifiedName': modifiedName,
        'reps': reps,
        'repUnit': repUnit,
        'repNote': repNote,
        'cardType': cardType.name,
        'jokerVariant': jokerVariant,
        'isGroupChallenge': isGroupChallenge,
        'imageAsset': imageAsset,
        'useSuitTemplate': useSuitTemplate,
        'customImagePath': customImagePath,
      };

  factory GameCard.fromJson(Map<String, dynamic> json) => GameCard(
        id: json['id'] as String,
        suit: CardSuit.values.byName(json['suit'] as String),
        rank: json['rank'] as String,
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        modifiedName: json['modifiedName'] as String?,
        reps: json['reps'] as int?,
        repUnit: json['repUnit'] as String?,
        repNote: json['repNote'] as String?,
        cardType: CardType.values.byName(json['cardType'] as String),
        jokerVariant: json['jokerVariant'] as String?,
        isGroupChallenge: json['isGroupChallenge'] as bool? ?? false,
        imageAsset: json['imageAsset'] as String,
        useSuitTemplate: json['useSuitTemplate'] as bool? ?? false,
        customImagePath: json['customImagePath'] as String?,
      );

  GameCard copyWith({
    int? reps,
    String? customImagePath,
    String? exerciseName,
    String? modifiedName,
    String? repNote,
    CardType? cardType,
    bool? isGroupChallenge,
  }) =>
      GameCard(
        id: id,
        suit: suit,
        rank: rank,
        exerciseId: exerciseId,
        exerciseName: exerciseName ?? this.exerciseName,
        modifiedName: modifiedName ?? this.modifiedName,
        reps: reps ?? this.reps,
        repUnit: repUnit,
        repNote: repNote ?? this.repNote,
        cardType: cardType ?? this.cardType,
        jokerVariant: jokerVariant,
        isGroupChallenge: isGroupChallenge ?? this.isGroupChallenge,
        imageAsset: imageAsset,
        useSuitTemplate: useSuitTemplate,
        customImagePath: customImagePath ?? this.customImagePath,
      );
}
