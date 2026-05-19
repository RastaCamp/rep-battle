import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../core/config/game_mode_config.dart';
import '../core/data/asset_paths.dart';
import '../core/models/npc_profile.dart';
import '../core/models/player_state.dart';
import '../core/models/quest/quest_player_state.dart';

class NpcRegistry {
  static NpcRegistry? _instance;
  static NpcRegistry get instance => _instance ??= NpcRegistry._();

  NpcRegistry._();

  final _random = Random();
  List<NpcProfile> _profiles = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw =
        await rootBundle.loadString('assets/data/npc_profiles.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _profiles = (data['profiles'] as List<dynamic>)
        .map((e) => NpcProfile.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  List<NpcProfile> get all => List.unmodifiable(_profiles);

  List<NpcProfile> get regular =>
      _profiles.where((p) => !p.surpriseEntrant).toList();

  NpcProfile? byId(String? id) {
    if (id == null) return null;
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  NpcProfile pickRandom({bool allowSurprise = false}) {
    final pool = allowSurprise
        ? _profiles
        : _profiles.where((p) => !p.surpriseEntrant).toList();
    return pool[_random.nextInt(pool.length)];
  }

  NpcProfile pickSurprise() {
    final surprises = _profiles.where((p) => p.surpriseEntrant).toList();
    if (surprises.isEmpty) return pickRandom();
    return surprises[_random.nextInt(surprises.length)];
  }

  List<NpcProfile> pickMany(int count, {Set<String> excludeIds = const {}}) {
    final pool =
        regular.where((p) => !excludeIds.contains(p.id)).toList()..shuffle(_random);
    return pool.take(count.clamp(0, pool.length)).toList();
  }

  PlayerState toPlayer(NpcProfile profile, GameModeConfig mode) {
    var pass = profile.passRate;
    var modified = profile.modifiedRate;
    var fail = profile.failRate;
    var timing = profile.timingMultiplier;

    if (profile.surpriseEntrant) {
      pass = (pass + (_random.nextDouble() - 0.5) * 0.12).clamp(0.4, 0.95);
      modified = (modified + (_random.nextDouble() - 0.5) * 0.1).clamp(0.1, 0.5);
      timing = (timing + (_random.nextDouble() - 0.5) * 0.15).clamp(0.8, 1.3);
    }

    return PlayerState(
      id: const Uuid().v4(),
      name: profile.name,
      color: profile.color,
      lives: mode.lives,
      isCpu: true,
      cpuDifficulty: 'normal',
      title: profile.tagline,
      iconId: profile.id,
      avatarId: 'npc:${profile.id}',
      avatarAsset: AssetPaths.npcPortrait(profile.id),
      npcProfileId: profile.id,
      npcPassRate: pass,
      npcModifiedRate: modified,
      npcFailRate: fail,
      npcTimingMultiplier: timing,
    );
  }

  QuestPlayerState toQuestPlayer(
    NpcProfile profile, {
    required int hp,
    required int colorValue,
  }) {
    var pass = profile.passRate;
    var modified = profile.modifiedRate;
    var fail = profile.failRate;
    var timing = profile.timingMultiplier;

    if (profile.surpriseEntrant) {
      pass = (pass + (_random.nextDouble() - 0.5) * 0.12).clamp(0.4, 0.95);
      modified =
          (modified + (_random.nextDouble() - 0.5) * 0.1).clamp(0.1, 0.5);
      timing = (timing + (_random.nextDouble() - 0.5) * 0.15).clamp(0.8, 1.3);
    }

    return QuestPlayerState(
      id: const Uuid().v4(),
      name: profile.name,
      colorValue: colorValue,
      avatarId: 'npc:${profile.id}',
      hp: hp,
      maxHp: hp,
      skips: 1,
      isCpu: true,
      title: profile.tagline,
      npcProfileId: profile.id,
      npcPassRate: pass,
      npcModifiedRate: modified,
      npcFailRate: fail,
      npcTimingMultiplier: timing,
    );
  }
}
