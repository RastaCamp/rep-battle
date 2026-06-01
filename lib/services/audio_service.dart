import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/data/audio_catalog.dart';
import '../core/music/music_scope.dart';
import 'tone_generator.dart';

class _MusicScopeEntry {
  final Object token;
  final MusicScope scope;
  final bool proTitle;

  const _MusicScopeEntry({
    required this.token,
    required this.scope,
    required this.proTitle,
  });
}

enum SfxType {
  button,
  cardFlip,
  cardSlam,
  pass,
  fail,
  combo,
  comboBreak,
  lifeLost,
  armorBreak,
  crowdCheer,
  crowdBoo,
  eliminated,
  king,
  draw,
  shuffle,
  begin,
  timerTick,
  timerWarning,
  victory,
  enemyDefeated,
  inventory,
  forfeit,
  chatter,
}

class AudioService {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _chatterPlayer = AudioPlayer();
  late final AudioCache _assetCache;
  final Random _rng = Random();

  bool soundEnabled = true;
  bool musicEnabled = true;
  double musicVolume = 0.75;
  double sfxVolume = 1.0;

  bool _initialized = false;
  String? _musicTheme;
  String? _currentMusicPath;
  bool _menuProTitle = false;
  StreamSubscription<void>? _musicCompleteSub;
  final List<_MusicScopeEntry> _scopeStack = [];
  bool _musicBlocked = false;
  MusicScope? _blockedScope;
  bool _blockedProTitle = false;
  bool _chatterActive = false;
  bool _chatterForBark = false;

  static const _chatterPath = 'assets/audio/sfx/crowd_cheer.mp3';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb) {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
    }

    _assetCache = AudioCache(prefix: kIsWeb ? '' : 'assets/');
    _musicPlayer.audioCache = _assetCache;
    _sfxPlayer.audioCache = _assetCache;
    _chatterPlayer.audioCache = _assetCache;

    await _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _chatterPlayer.setPlayerMode(PlayerMode.mediaPlayer);

    await _musicPlayer.setReleaseMode(ReleaseMode.release);
    await _chatterPlayer.setReleaseMode(ReleaseMode.loop);

    _musicCompleteSub = _musicPlayer.onPlayerComplete.listen((_) {
      _onMusicComplete();
    });
  }

  void _onMusicComplete() {
    final theme = _musicTheme;
    if (theme == null || !musicEnabled) return;
    if (theme == 'gameplay') {
      unawaited(_playRandomPlayTrack());
    } else if (theme == 'quest') {
      unawaited(_playRandomQuestTrack());
    } else if (theme == 'quest_menu') {
      unawaited(_playAsset(AudioCatalog.questMenuMusic, loop: true));
    }
  }

  Future<void> dispose() async {
    await _musicCompleteSub?.cancel();
    await stopChatter();
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
    await _chatterPlayer.dispose();
  }

  Future<void> playSfx(SfxType type) async {
    if (!soundEnabled) return;
    final path = AudioCatalog.pickSfx(type.name, _rng);
    if (path.isNotEmpty && await _assetExists(path)) {
      unawaited(_playSfxAsset(path));
      return;
    }
    final (freq, ms, vol) = _toneParams(type);
    unawaited(_playTone(freq, ms, vol * sfxVolume));
  }

  /// Loop crowd chatter while an NPC comment is on screen.
  Future<void> startChatterForBark() async {
    if (!soundEnabled || _chatterForBark) return;
    _chatterForBark = true;
    await _playChatter(loop: true);
  }

  /// Short ambient crowd burst during gameplay (not tied to a bark).
  Future<void> playAmbientChatter() async {
    if (!soundEnabled || _chatterForBark) return;
    if (_chatterActive) return;
    await _playChatter(loop: false);
  }

  Future<void> stopChatter() async {
    _chatterForBark = false;
    if (!_chatterActive) return;
    _chatterActive = false;
    await _chatterPlayer.stop();
  }

  Future<void> _playChatter({required bool loop}) async {
    if (!await _assetExists(_chatterPath)) return;
    _chatterActive = true;
    await _chatterPlayer.setReleaseMode(
      loop ? ReleaseMode.loop : ReleaseMode.release,
    );
    await _chatterPlayer.setVolume((sfxVolume * 0.55).clamp(0.0, 1.0));
    try {
      await _chatterPlayer.play(AssetSource(_playerAssetPath(_chatterPath)));
      if (!loop) {
        _chatterActive = false;
      }
    } catch (e) {
      debugPrint('Chatter play failed: $e');
      _chatterActive = false;
    }
  }

  Object enterMusicScope(MusicScope scope, {bool proTitle = false}) {
    final token = Object();
    _scopeStack.add(
      _MusicScopeEntry(token: token, scope: scope, proTitle: proTitle),
    );
    unawaited(_applyTopScope());
    return token;
  }

  void leaveMusicScope(Object token) {
    _scopeStack.removeWhere((e) => e.token == token);
    unawaited(_applyTopScope());
  }

  Future<void> _applyTopScope() async {
    if (!musicEnabled) return;
    if (_scopeStack.isEmpty) {
      await _playScope(MusicScope.title, proTitle: _menuProTitle);
      return;
    }
    final top = _scopeStack.last;
    await _playScope(top.scope, proTitle: top.proTitle);
  }

  Future<void> resumeMusicIfBlocked() async {
    if (!_musicBlocked || !musicEnabled) return;
    _musicBlocked = false;
    if (_scopeStack.isNotEmpty) {
      await _applyTopScope();
    } else if (_blockedScope != null) {
      await _playScope(_blockedScope!, proTitle: _blockedProTitle);
    }
  }

  Future<void> startAppMusic({required bool proTitle}) async {
    _menuProTitle = proTitle;
    if (_scopeStack.isEmpty) {
      await _playScope(MusicScope.title, proTitle: proTitle);
    } else {
      await _applyTopScope();
    }
  }

  Future<void> _playScope(MusicScope scope, {bool proTitle = false}) async {
    switch (scope) {
      case MusicScope.title:
      case MusicScope.matchIntro:
        await playMusic('menu', proTitle: proTitle);
      case MusicScope.settings:
        await playMusic('settings');
      case MusicScope.questSetup:
        await playMusic('quest_menu');
      case MusicScope.questGameplay:
        await playMusic('quest');
      case MusicScope.gameplay:
        await playMusic('gameplay');
      case MusicScope.scoreboard:
        await playMusic('scoreboard');
    }
  }

  Future<void> playMusic(
    String theme, {
    bool proTitle = false,
    bool force = false,
  }) async {
    if (!musicEnabled) return;

    final sameGameplay =
        theme == 'gameplay' && _musicTheme == 'gameplay' && _currentMusicPath != null;
    final sameMenu = theme == 'menu' &&
        _musicTheme == 'menu' &&
        _currentMusicPath != null &&
        _menuProTitle == proTitle;
    final sameOther = theme == _musicTheme &&
        _currentMusicPath != null &&
        theme != 'gameplay' &&
        theme != 'menu';

    if (!force && (sameGameplay || sameMenu || sameOther)) {
      return;
    }

    _musicTheme = theme;
    if (theme == 'menu') _menuProTitle = proTitle;

    switch (theme) {
      case 'menu':
        final path =
            proTitle ? AudioCatalog.titleMusicPro : AudioCatalog.titleMusic;
        await _playAsset(path, loop: true);
      case 'quest_menu':
        await _playAsset(AudioCatalog.questMenuMusic, loop: true);
      case 'settings':
        await _playAsset(AudioCatalog.settingsMusic, loop: true);
      case 'scoreboard':
        await _playAsset(AudioCatalog.scoreboardMusic, loop: true);
      case 'gameplay':
        await _playRandomPlayTrack();
      case 'quest':
        await _playRandomQuestTrack();
      default:
        _musicTheme = null;
        _currentMusicPath = null;
        await _musicPlayer.stop();
    }
  }

  Future<void> _playRandomPlayTrack() async {
    final path = AudioCatalog.pickPlayTrack(_rng, avoid: _currentMusicPath);
    if (path.isEmpty) return;
    _musicTheme = 'gameplay';
    await _playAsset(path, loop: false);
  }

  Future<void> _playRandomQuestTrack() async {
    final path = AudioCatalog.pickQuestTrack(_rng, avoid: _currentMusicPath);
    if (path.isEmpty) return;
    _musicTheme = 'quest';
    await _playAsset(path, loop: false);
  }

  Future<void> _playAsset(String path, {required bool loop}) async {
    if (!await _assetExists(path)) return;

    final switchingTrack = _currentMusicPath != path;
    if (switchingTrack) {
      _currentMusicPath = path;
      await _musicPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      await _musicPlayer.setVolume(musicVolume.clamp(0.0, 1.0));
      try {
        await _musicPlayer.play(AssetSource(_playerAssetPath(path)));
        _musicBlocked = false;
      } catch (e) {
        debugPrint('Music play blocked or failed: $e');
        _musicBlocked = true;
        if (_scopeStack.isNotEmpty) {
          final top = _scopeStack.last;
          _blockedScope = top.scope;
          _blockedProTitle = top.proTitle;
        }
      }
    }
  }

  Future<void> _playSfxAsset(String path) async {
    await _sfxPlayer.setVolume(sfxVolume.clamp(0.0, 1.0));
    await _sfxPlayer.play(AssetSource(_playerAssetPath(path)));
  }

  String _playerAssetPath(String bundlePath) {
    if (bundlePath.startsWith('assets/')) {
      return bundlePath.substring(7);
    }
    return bundlePath;
  }

  Future<bool> _assetExists(String bundlePath) async {
    final key = bundlePath.startsWith('assets/')
        ? bundlePath
        : 'assets/$bundlePath';
    try {
      await rootBundle.load(key);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopMusic() async {
    _musicTheme = null;
    _currentMusicPath = null;
    await _musicPlayer.stop();
  }

  Future<void> applyVolumes() async {
    await _musicPlayer.setVolume(musicVolume.clamp(0.0, 1.0));
    await _sfxPlayer.setVolume(sfxVolume.clamp(0.0, 1.0));
    if (_chatterActive) {
      await _chatterPlayer.setVolume((sfxVolume * 0.55).clamp(0.0, 1.0));
    }
  }

  Future<void> syncMusicEnabled() async {
    if (!musicEnabled) {
      await stopMusic();
      return;
    }
    await _applyTopScope();
  }

  Future<void> _playTone(double freq, int ms, double vol) async {
    if (kIsWeb) return;
    try {
      final bytes = ToneGenerator.wavBytes(
        frequency: freq,
        durationMs: ms,
        volume: vol,
      );
      await _sfxPlayer.play(BytesSource(bytes));
    } catch (_) {}
  }

  (double, int, double) _toneParams(SfxType type) => switch (type) {
        SfxType.button => (520.0, 90, 0.3),
        SfxType.cardFlip => (440.0, 120, 0.45),
        SfxType.cardSlam => (110.0, 200, 0.5),
        SfxType.pass => (392.0, 150, 0.35),
        SfxType.fail => (155.0, 200, 0.4),
        SfxType.combo => (660.0, 200, 0.45),
        SfxType.comboBreak => (98.0, 250, 0.4),
        SfxType.lifeLost => (130.0, 350, 0.45),
        SfxType.armorBreak => (280.0, 180, 0.5),
        SfxType.crowdCheer => (523.0, 400, 0.35),
        SfxType.crowdBoo => (140.0, 350, 0.3),
        SfxType.eliminated => (100.0, 500, 0.4),
        SfxType.king => (262.0, 300, 0.4),
        SfxType.draw => (350.0, 100, 0.35),
        SfxType.shuffle => (200.0, 500, 0.3),
        SfxType.begin => (440.0, 400, 0.4),
        SfxType.timerTick => (800.0, 80, 0.25),
        SfxType.timerWarning => (900.0, 150, 0.4),
        SfxType.victory => (330.0, 600, 0.4),
        SfxType.enemyDefeated => (440.0, 250, 0.4),
        SfxType.inventory => (350.0, 120, 0.35),
        SfxType.forfeit => (100.0, 400, 0.4),
        SfxType.chatter => (523.0, 400, 0.35),
      };

  void hapticLight() {
    if (soundEnabled) HapticFeedback.lightImpact();
  }

  void hapticHeavy() {
    if (soundEnabled) HapticFeedback.heavyImpact();
  }
}
