import '../game_card.dart';
import 'quest_enemy.dart';
import 'quest_map_node.dart';
import 'quest_player_state.dart';

enum QuestPhase {
  map,
  roomIntro,
  draw,
  challenge,
  jokerChoice,
  resolving,
  roomClear,
  runWon,
  runLost,
}

class QuestRunState {
  final String dungeonId;
  final String difficultyId;
  int roomIndex;
  final List<QuestPlayerState> players;
  int activePlayerIndex;
  QuestEnemyInstance? enemy;
  final List<GameCard> deck;
  final List<GameCard> discard;
  GameCard? currentCard;
  GameCard? previousCard;
  QuestPhase phase;
  int combo;
  String? lastMessage;
  String? activeBark;
  String? activeBarkSpeaker;
  bool runComplete;
  bool runWon;
  List<String> pendingLootIds;
  String? pendingRoomReward;
  bool awaitingLootChoice;
  int totalRoomsCleared;
  List<QuestMapNode> mapNodes;
  String? entryReason;
  String? roomIntroNarration;
  String? campaignAnnouncerLine;
  int lastActAnnounced;
  int mapLayoutSeed;
  bool cardDrawnThisTurn;
  String? combatRoomAssetPath;

  QuestRunState({
    required this.dungeonId,
    required this.difficultyId,
    required this.roomIndex,
    required this.players,
    required this.activePlayerIndex,
    this.enemy,
    required this.deck,
    required this.discard,
    this.currentCard,
    this.previousCard,
    required this.phase,
    this.combo = 0,
    this.lastMessage,
    this.activeBark,
    this.activeBarkSpeaker,
    this.runComplete = false,
    this.runWon = false,
    List<String>? pendingLootIds,
    this.pendingRoomReward,
    this.awaitingLootChoice = false,
    this.totalRoomsCleared = 0,
    List<QuestMapNode>? mapNodes,
    this.entryReason,
    this.roomIntroNarration,
    this.campaignAnnouncerLine,
    this.lastActAnnounced = 1,
    required this.mapLayoutSeed,
    this.cardDrawnThisTurn = false,
    this.combatRoomAssetPath,
  })  : pendingLootIds = pendingLootIds ?? [],
        mapNodes = mapNodes ?? [];

  QuestMapNode? get currentMapNode {
    for (final n in mapNodes) {
      if (n.status == QuestMapNodeStatus.current) return n;
    }
    return null;
  }

  QuestPlayerState get activePlayer => players[activePlayerIndex];

  List<QuestPlayerState> get livingPlayers =>
      players.where((p) => p.alive).toList();

  bool get allPlayersDead => livingPlayers.isEmpty;

  Map<String, dynamic> toJson() => {
        'dungeonId': dungeonId,
        'difficultyId': difficultyId,
        'roomIndex': roomIndex,
        'players': players.map((p) => p.toJson()).toList(),
        'activePlayerIndex': activePlayerIndex,
        'enemy': enemy?.toJson(),
        'deck': deck.map((c) => c.toJson()).toList(),
        'discard': discard.map((c) => c.toJson()).toList(),
        'currentCard': currentCard?.toJson(),
        'previousCard': previousCard?.toJson(),
        'phase': phase.name,
        'combo': combo,
        'lastMessage': lastMessage,
        'activeBark': activeBark,
        'activeBarkSpeaker': activeBarkSpeaker,
        'runComplete': runComplete,
        'runWon': runWon,
        'pendingLootIds': pendingLootIds,
        'pendingRoomReward': pendingRoomReward,
        'awaitingLootChoice': awaitingLootChoice,
        'totalRoomsCleared': totalRoomsCleared,
        'mapNodes': mapNodes.map((n) => n.toJson()).toList(),
        'entryReason': entryReason,
        'roomIntroNarration': roomIntroNarration,
        'campaignAnnouncerLine': campaignAnnouncerLine,
        'lastActAnnounced': lastActAnnounced,
        'mapLayoutSeed': mapLayoutSeed,
        'cardDrawnThisTurn': cardDrawnThisTurn,
        'combatRoomAssetPath': combatRoomAssetPath,
      };

  factory QuestRunState.fromJson(Map<String, dynamic> json) => QuestRunState(
        dungeonId: json['dungeonId'] as String,
        difficultyId: json['difficultyId'] as String,
        roomIndex: json['roomIndex'] as int,
        players: (json['players'] as List)
            .map((e) => QuestPlayerState.fromJson(e as Map<String, dynamic>))
            .toList(),
        activePlayerIndex: json['activePlayerIndex'] as int,
        enemy: json['enemy'] != null
            ? QuestEnemyInstance.fromJson(
                json['enemy'] as Map<String, dynamic>,
              )
            : null,
        deck: (json['deck'] as List)
            .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        discard: (json['discard'] as List)
            .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentCard: json['currentCard'] != null
            ? GameCard.fromJson(json['currentCard'] as Map<String, dynamic>)
            : null,
        previousCard: json['previousCard'] != null
            ? GameCard.fromJson(json['previousCard'] as Map<String, dynamic>)
            : null,
        phase: QuestPhase.values.byName(json['phase'] as String),
        combo: json['combo'] as int? ?? 0,
        lastMessage: json['lastMessage'] as String?,
        activeBark: json['activeBark'] as String?,
        activeBarkSpeaker: json['activeBarkSpeaker'] as String?,
        runComplete: json['runComplete'] as bool? ?? false,
        runWon: json['runWon'] as bool? ?? false,
        pendingLootIds: (json['pendingLootIds'] as List?)?.cast<String>() ?? [],
        pendingRoomReward: json['pendingRoomReward'] as String?,
        awaitingLootChoice: json['awaitingLootChoice'] as bool? ?? false,
        totalRoomsCleared: json['totalRoomsCleared'] as int? ?? 0,
        mapNodes: (json['mapNodes'] as List?)
                ?.map((e) => QuestMapNode.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        entryReason: json['entryReason'] as String?,
        roomIntroNarration: json['roomIntroNarration'] as String?,
        campaignAnnouncerLine: json['campaignAnnouncerLine'] as String?,
        lastActAnnounced: json['lastActAnnounced'] as int? ?? 1,
        mapLayoutSeed: json['mapLayoutSeed'] as int? ??
            json['roomIndex'] as int? ??
            1,
        cardDrawnThisTurn: json['cardDrawnThisTurn'] as bool? ?? false,
        combatRoomAssetPath: json['combatRoomAssetPath'] as String?,
      );
}
