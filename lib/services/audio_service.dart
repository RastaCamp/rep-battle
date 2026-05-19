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
}

class AudioService {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
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

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // audioplayers web builds URLs as `assets/$prefix$file`. Default prefix is
    // `assets/`, which doubles the path. Use empty prefix on web only.
    _assetCache = AudioCache(prefix: kIsWeb ? '' : 'assets/');
    _musicPlayer.audioCache = _assetCache;
    _sfxPlayer.audioCache = _assetCache;
    await _musicPlayer.setReleaseMode(ReleaseMode.release);
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
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
  }

  Future<void> playSfx(SfxType type) async {
    if (!soundEnabled) return;
    final path = AudioCatalog.pickSfx(type.name, _rng);
    if (path.isNotEmpty && await _assetExists(path)) {
      await _playSfxAsset(path);
      return;
    }
    final (freq, ms, vol) = _toneParams(type);
    await _playTone(freq, ms, vol * sfxVolume);
  }

  /// Push a screen music layer; returns a token for [leaveMusicScope].
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

  /// Call once after bootstrap so title music begins immediately (splash/title).
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
        await playMusic('menu', proTitle: proTitle, force: true);
      case MusicScope.settings:
        await playMusic('settings', force: true);
      case MusicScope.questSetup:
        await playMusic('quest_menu', force: true);
      case MusicScope.questGameplay:
        await playMusic('quest', force: true);
      case MusicScope.gameplay:
        await playMusic('gameplay', force: true);
      case MusicScope.scoreboard:
        await playMusic('scoreboard', force: true);
    }
  }

  /// [theme]: menu, gameplay, quest, quest_menu, settings, scoreboard
  Future<void> playMusic(
    String theme, {
    bool proTitle = false,
    bool force = false,
  }) async {
    if (!musicEnabled) return;
    if (!force &&
        _musicTheme == theme &&
        _currentMusicPath != null &&
        (theme != 'menu' || _menuProTitle == proTitle)) {
      return;
    }

    _musicTheme = theme;
    if (theme == 'menu') _menuProTitle = proTitle;
    await _musicPlayer.stop();

    switch (theme) {
      case 'menu':
        final path = proTitle ? AudioCatalog.titleMusicPro : AudioCatalog.titleMusic;
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

  Future<void> _playSfxAsset(String path) async {
    await _sfxPlayer.setVolume(sfxVolume.clamp(0.0, 1.0));
    await _sfxPlayer.play(AssetSource(_playerAssetPath(path)));
  }

  /// For [AssetSource] / [AudioCache]: `audio/...` (no `assets/` prefix).
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
      };

  void hapticLight() {
    if (soundEnabled) HapticFeedback.lightImpact();
  }

  void hapticHeavy() {
    if (soundEnabled) HapticFeedback.heavyImpact();
  }
}
