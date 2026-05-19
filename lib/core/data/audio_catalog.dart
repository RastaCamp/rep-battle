import 'dart:math';

/// Bundled audio paths (populated by tool/sync_audio.py).
class AudioCatalog {
  AudioCatalog._();

  static const _base = 'assets/audio';

  static const titleMusic = '$_base/music/title/rep_battle_title.mp3';
  static const titleMusicPro = '$_base/music/title/rep_battle_title_pro.mp3';
  static const questMenuMusic = '$_base/music/quest_menu/quest_setup_loop.mp3';
  static const settingsMusic = '$_base/music/settings/rep_settings.mp3';
  static const scoreboardMusic = '$_base/music/scoreboard/scoreboard.mp3';

  static const playTracks = [
    '$_base/music/play/rep_track.mp3',
    '$_base/music/play/rep_track_1.mp3',
    '$_base/music/play/rep_track_2.mp3',
    '$_base/music/play/rep_track_3.mp3',
    '$_base/music/play/rep_track_4.mp3',
    '$_base/music/play/rep_track_5.mp3',
    '$_base/music/play/rep_track_6.mp3',
    '$_base/music/play/rep_track_7.mp3',
    '$_base/music/play/rep_track_8.mp3',
    '$_base/music/play/rep_track_9.mp3',
  ];

  static const questTracks = [
    '$_base/music/quest/rep_quest_track.mp3',
    '$_base/music/quest/rep_quest_track_1.mp3',
    '$_base/music/quest/rep_quest_track_2.mp3',
    '$_base/music/quest/rep_quest_track_3.mp3',
    '$_base/music/quest/rep_quest_track_4.mp3',
    '$_base/music/quest/rep_quest_track_5.mp3',
    '$_base/music/quest/rep_quest_track_6.mp3',
    '$_base/music/quest/rep_quest_track_7.mp3',
  ];

  static const confirmPool = [
    '$_base/sfx/confirm/confirm.mp3',
    '$_base/sfx/confirm/confirm_1.mp3',
    '$_base/sfx/confirm/confirm_2.mp3',
  ];

  static const declinePool = [
    '$_base/sfx/decline/decline.mp3',
    '$_base/sfx/decline/decline_1.mp3',
    '$_base/sfx/decline/decline_2.mp3',
  ];

  static const forfeitPool = [
    '$_base/sfx/forfeit/forfeit.mp3',
    '$_base/sfx/forfeit/forfeit_1.mp3',
    '$_base/sfx/forfeit/forfeit_3.mp3',
  ];

  static const victoryPool = [
    '$_base/sfx/victory/winner.mp3',
    '$_base/sfx/victory/winner_1.mp3',
  ];

  static const Map<String, List<String>> sfx = {
    'button': confirmPool,
    'pass': confirmPool,
    'cardFlip': ['$_base/sfx/card_flip.mp3'],
    'cardSlam': ['$_base/sfx/card_flip.mp3'],
    'fail': declinePool,
    'combo': ['$_base/sfx/combo.mp3'],
    'comboBreak': ['$_base/sfx/combo_break.mp3'],
    'lifeLost': ['$_base/sfx/life_lost.mp3'],
    'armorBreak': ['$_base/sfx/armor_break.mp3'],
    'crowdCheer': ['$_base/sfx/crowd_cheer.mp3'],
    'crowdBoo': declinePool,
    'eliminated': forfeitPool,
    'king': ['$_base/sfx/begin.mp3'],
    'draw': ['$_base/sfx/card_flip.mp3'],
    'shuffle': ['$_base/sfx/shuffle.mp3'],
    'begin': ['$_base/sfx/begin.mp3'],
    'timerTick': ['$_base/sfx/timer_tick.mp3'],
    'timerWarning': ['$_base/sfx/timer_warning.mp3'],
    'victory': victoryPool,
    'enemyDefeated': ['$_base/sfx/enemy_defeated.mp3'],
    'inventory': ['$_base/sfx/inventory.mp3'],
    'forfeit': forfeitPool,
  };

  static String pickRandom(List<String> pool, Random rng) {
    if (pool.isEmpty) return '';
    return pool[rng.nextInt(pool.length)];
  }

  static String pickSfx(String typeName, Random rng) {
    final pool = sfx[typeName];
    if (pool == null || pool.isEmpty) return '';
    return pickRandom(pool, rng);
  }

  static String pickPlayTrack(Random rng, {String? avoid}) {
    return _pickFromList(playTracks, rng, avoid: avoid);
  }

  static String pickQuestTrack(Random rng, {String? avoid}) {
    return _pickFromList(questTracks, rng, avoid: avoid);
  }

  static String _pickFromList(List<String> tracks, Random rng, {String? avoid}) {
    if (tracks.isEmpty) return '';
    if (tracks.length == 1) return tracks.first;
    var pick = tracks[rng.nextInt(tracks.length)];
    if (avoid != null && tracks.length > 1 && pick == avoid) {
      final others = tracks.where((t) => t != avoid).toList();
      pick = others[rng.nextInt(others.length)];
    }
    return pick;
  }
}
