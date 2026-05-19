import 'game_card.dart';
import 'match_house_rules.dart';
import 'player_state.dart';

enum MatchPhase { intro, draw, challenge, result, paused, over }

class TurnLogEntry {
  final int turnNumber;
  final String playerId;
  final String playerName;
  final String? cardId;
  final String? cardLabel;
  final String result;
  final int pointsDelta;
  final int livesDelta;
  final int comboAfter;
  final DateTime timestamp;

  TurnLogEntry({
    required this.turnNumber,
    required this.playerId,
    required this.playerName,
    this.cardId,
    this.cardLabel,
    required this.result,
    required this.pointsDelta,
    required this.livesDelta,
    required this.comboAfter,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'turnNumber': turnNumber,
        'playerId': playerId,
        'playerName': playerName,
        'cardId': cardId,
        'cardLabel': cardLabel,
        'result': result,
        'pointsDelta': pointsDelta,
        'livesDelta': livesDelta,
        'comboAfter': comboAfter,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TurnLogEntry.fromJson(Map<String, dynamic> json) => TurnLogEntry(
        turnNumber: json['turnNumber'] as int,
        playerId: json['playerId'] as String,
        playerName: json['playerName'] as String,
        cardId: json['cardId'] as String?,
        cardLabel: json['cardLabel'] as String?,
        result: json['result'] as String,
        pointsDelta: json['pointsDelta'] as int,
        livesDelta: json['livesDelta'] as int,
        comboAfter: json['comboAfter'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class MatchState {
  String matchId;
  String modeId;
  String deckId;
  List<GameCard> activeDeck;
  List<GameCard> discardPile;
  List<PlayerState> players;
  int currentPlayerIndex;
  GameCard? currentCard;
  GameCard? previousCard;
  int comboChain;
  int hypeMeter;
  bool matchOver;
  String? winnerId;
  MatchPhase phase;
  bool cardDrawnThisTurn;
  bool awaitingGroupResults;
  List<String> groupPendingPlayerIds;
  int groupFailCount;
  int groupPassCount;
  int groupPlayerCount;
  int turnCount;
  List<TurnLogEntry> turnLog;
  int? shuffleSeed;
  bool reshuffleEnabled;
  int timerSecondsRemaining;
  bool timerRunning;
  String? lastFeedbackMessage;
  bool armorBrokenThisTurn;
  bool comboBrokenThisTurn;
  MatchHouseRules houseRules;
  int startingDeckSize;

  MatchState({
    required this.matchId,
    required this.modeId,
    required this.deckId,
    required this.activeDeck,
    required this.discardPile,
    required this.players,
    this.currentPlayerIndex = 0,
    this.currentCard,
    this.previousCard,
    this.comboChain = 0,
    this.hypeMeter = 0,
    this.matchOver = false,
    this.winnerId,
    this.phase = MatchPhase.intro,
    this.cardDrawnThisTurn = false,
    this.awaitingGroupResults = false,
    List<String>? groupPendingPlayerIds,
    this.groupFailCount = 0,
    this.groupPassCount = 0,
    this.groupPlayerCount = 0,
    this.turnCount = 0,
    List<TurnLogEntry>? turnLog,
    this.shuffleSeed,
    this.reshuffleEnabled = false,
    this.timerSecondsRemaining = 0,
    this.timerRunning = false,
    this.lastFeedbackMessage,
    this.armorBrokenThisTurn = false,
    this.comboBrokenThisTurn = false,
    this.houseRules = const MatchHouseRules(),
    this.startingDeckSize = 0,
  }) : groupPendingPlayerIds = groupPendingPlayerIds ?? [],
       turnLog = turnLog ?? [];

  PlayerState get currentPlayer => players[currentPlayerIndex];

  /// Next player who must adjudicate a group (King/Joker) challenge.
  PlayerState? get groupAdjudicator {
    if (groupPendingPlayerIds.isEmpty) return null;
    final id = groupPendingPlayerIds.first;
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<PlayerState> get activePlayers =>
      players.where((p) => !p.eliminated).toList();

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'modeId': modeId,
        'deckId': deckId,
        'activeDeck': activeDeck.map((c) => c.toJson()).toList(),
        'discardPile': discardPile.map((c) => c.toJson()).toList(),
        'players': players.map((p) => p.toJson()).toList(),
        'currentPlayerIndex': currentPlayerIndex,
        'currentCard': currentCard?.toJson(),
        'previousCard': previousCard?.toJson(),
        'comboChain': comboChain,
        'hypeMeter': hypeMeter,
        'matchOver': matchOver,
        'winnerId': winnerId,
        'phase': phase.name,
        'cardDrawnThisTurn': cardDrawnThisTurn,
        'awaitingGroupResults': awaitingGroupResults,
        'groupPendingPlayerIds': groupPendingPlayerIds,
        'groupFailCount': groupFailCount,
        'groupPassCount': groupPassCount,
        'groupPlayerCount': groupPlayerCount,
        'turnCount': turnCount,
        'turnLog': turnLog.map((e) => e.toJson()).toList(),
        'shuffleSeed': shuffleSeed,
        'reshuffleEnabled': reshuffleEnabled,
        'timerSecondsRemaining': timerSecondsRemaining,
        'timerRunning': timerRunning,
        'houseRules': houseRules.toJson(),
        'startingDeckSize': startingDeckSize,
      };

  factory MatchState.fromJson(Map<String, dynamic> json) => MatchState(
        matchId: json['matchId'] as String,
        modeId: json['modeId'] as String,
        deckId: json['deckId'] as String,
        activeDeck: (json['activeDeck'] as List)
            .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        discardPile: (json['discardPile'] as List)
            .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        players: (json['players'] as List)
            .map((e) => PlayerState.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentPlayerIndex: json['currentPlayerIndex'] as int? ?? 0,
        currentCard: json['currentCard'] != null
            ? GameCard.fromJson(json['currentCard'] as Map<String, dynamic>)
            : null,
        previousCard: json['previousCard'] != null
            ? GameCard.fromJson(json['previousCard'] as Map<String, dynamic>)
            : null,
        comboChain: json['comboChain'] as int? ?? 0,
        hypeMeter: json['hypeMeter'] as int? ?? 0,
        matchOver: json['matchOver'] as bool? ?? false,
        winnerId: json['winnerId'] as String?,
        phase: MatchPhase.values.byName(json['phase'] as String? ?? 'intro'),
        cardDrawnThisTurn: json['cardDrawnThisTurn'] as bool? ?? false,
        awaitingGroupResults:
            json['awaitingGroupResults'] as bool? ?? false,
        groupPendingPlayerIds:
            (json['groupPendingPlayerIds'] as List?)?.cast<String>() ?? [],
        groupFailCount: json['groupFailCount'] as int? ?? 0,
        groupPassCount: json['groupPassCount'] as int? ?? 0,
        groupPlayerCount: json['groupPlayerCount'] as int? ?? 0,
        turnCount: json['turnCount'] as int? ?? 0,
        turnLog: (json['turnLog'] as List?)
                ?.map((e) =>
                    TurnLogEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        shuffleSeed: json['shuffleSeed'] as int?,
        reshuffleEnabled: json['reshuffleEnabled'] as bool? ?? false,
        timerSecondsRemaining: json['timerSecondsRemaining'] as int? ?? 0,
        timerRunning: json['timerRunning'] as bool? ?? false,
        houseRules: MatchHouseRules.fromJson(
          json['houseRules'] as Map<String, dynamic>?,
        ),
        startingDeckSize: json['startingDeckSize'] as int? ?? 0,
      );
}
