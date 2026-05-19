class AssetPaths {
  /// One template per suit — rank/face drawn procedurally in UI.
  static String suitCustomTemplate(String suit) =>
      'assets/images/cards/${suit.toLowerCase()}_custom.png';

  static String cardImage(String suit, String rank) {
    final s = suit.toLowerCase();
    final r = rank.toLowerCase();
    if (r == 'joker') {
      return 'assets/images/cards/joker_${rank == 'Joker2' ? '2' : '1'}.png';
    }
    return 'assets/images/cards/${s}_$r.png';
  }

  static String cardImageFromId(String id) {
    if (id.startsWith('joker')) {
      return id == 'joker_2'
          ? 'assets/images/cards/joker_2.png'
          : 'assets/images/cards/joker_1.png';
    }
    final parts = id.split('_');
    if (parts.length >= 2) {
      return 'assets/images/cards/${parts[0]}_${parts.sublist(1).join('_')}.png';
    }
    return 'assets/images/card_backs/default.png';
  }

  static const cardBackDefault = 'assets/images/card_backs/default.png';
  static const titleScreen = 'assets/images/screens/title_screen.png';
  static const titleScreenPro = 'assets/images/screens/title_screen_1.png';
  static const winnerOverlay = 'assets/images/screens/winner.png';
  static const forfeitOverlay = 'assets/images/screens/forfeit.png';

  static const uiPlay = 'assets/images/ui/play.png';
  static const uiPause = 'assets/images/ui/pause.png';
  static const uiSettings = 'assets/images/ui/settings.png';
  static const uiConfirm = 'assets/images/ui/confirm.png';
  static const uiCancel = 'assets/images/ui/cancel.png';
  static const uiLives = 'assets/images/ui/lives.png';
  static const uiShield = 'assets/images/ui/shield.png';
  static const uiTimer = 'assets/images/ui/timer.png';
  static const uiCombo = 'assets/images/ui/combo.png';
  static const uiTrophy = 'assets/images/ui/trophy.png';
  static const uiRerun = 'assets/images/ui/rerun.png';
  static const uiMultiplayer = 'assets/images/ui/multiplayer.png';
  static const uiSolo = 'assets/images/ui/solo.png';
  static const uiScoreboard = 'assets/images/ui/scoreboard.png';
  static const uiFire = 'assets/images/ui/fire.png';
  static const uiCrown = 'assets/images/ui/crown.png';
  static const uiStar = 'assets/images/ui/star.png';

  static String npcPortrait(String profileId) =>
      'assets/images/npcs/$profileId.png';

  static const playerAvatarDefault = 'assets/images/avatars/player_default.png';

  static String questEnemy(String enemyId) =>
      'assets/images/quest/$enemyId.png';

  static String questItem(String itemId) =>
      'assets/images/quest/$itemId.png';

  static String questRoom(String roomType) =>
      'assets/images/quest/room_$roomType.png';

  static const questUiRelicSlot = 'assets/images/quest/ui_relic_slot.png';
  static const questUiSkip = 'assets/images/quest/ui_skip.png';
  static const questUiLuckyCard = 'assets/images/quest/ui_lucky_card.png';
  static const questUiProteinShake = 'assets/images/quest/ui_protein_shake.png';
}
