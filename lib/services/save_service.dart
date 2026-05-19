import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/match_state.dart';
import '../core/models/quest/quest_run_state.dart';

class SaveService {
  static const _settingsKey = 'rb_settings';
  static const _statsKey = 'rb_stats';
  static const _matchKey = 'rb_active_match';
  static const _questKey = 'rb_active_quest';
  static const _achievementsKey = 'rb_achievements';
  static const _profileKey = 'rb_profile';

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<Map<String, dynamic>> loadSettings() async {
    final p = await _prefs;
    final raw = p.getString(_settingsKey);
    if (raw == null) return _defaultSettings();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final p = await _prefs;
    await p.setString(_settingsKey, jsonEncode(settings));
  }

  Map<String, dynamic> _defaultSettings() => {
        'soundEnabled': true,
        'musicEnabled': true,
        'vibrationEnabled': true,
        'reducedFlashing': false,
        'readableText': false,
        'lowImpactMode': false,
        'seatedMode': false,
        'doNotDisturb': false,
        'devShuffleSeed': null,
        'cardBackId': 'default',
        'deckArtStyle': 'defaultArt',
        'tutorialComplete': false,
        'firstDeckComplete': false,
        'isPro': false,
        'defaultPlayerAvatarId': 'player_default',
      };

  Future<Map<String, dynamic>> loadStats() async {
    final p = await _prefs;
    final raw = p.getString(_statsKey);
    if (raw == null) {
      return {
        'lifetimeReps': 0,
        'matchesPlayed': 0,
        'wins': 0,
        'bestCombo': 0,
        'xp': 0,
        'level': 1,
      };
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveStats(Map<String, dynamic> stats) async {
    final p = await _prefs;
    await p.setString(_statsKey, jsonEncode(stats));
  }

  Future<void> saveActiveMatch(MatchState? match) async {
    final p = await _prefs;
    if (match == null) {
      await p.remove(_matchKey);
      return;
    }
    await p.setString(_matchKey, jsonEncode(match.toJson()));
  }

  Future<MatchState?> loadActiveMatch() async {
    final p = await _prefs;
    final raw = p.getString(_matchKey);
    if (raw == null) return null;
    try {
      return MatchState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> loadAchievements() async {
    final p = await _prefs;
    final list = p.getStringList(_achievementsKey) ?? [];
    return list.toSet();
  }

  Future<void> unlockAchievement(String id) async {
    final p = await _prefs;
    final list = p.getStringList(_achievementsKey) ?? [];
    if (!list.contains(id)) {
      list.add(id);
      await p.setStringList(_achievementsKey, list);
    }
  }

  Future<Map<String, dynamic>> loadProfile() async {
    final p = await _prefs;
    final raw = p.getString(_profileKey);
    if (raw == null) {
      return {'name': 'Player', 'title': null, 'iconId': 'star'};
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final p = await _prefs;
    await p.setString(_profileKey, jsonEncode(profile));
  }

  Future<void> saveActiveQuest(QuestRunState? quest) async {
    final p = await _prefs;
    if (quest == null) {
      await p.remove(_questKey);
      return;
    }
    await p.setString(_questKey, jsonEncode(quest.toJson()));
  }

  Future<QuestRunState?> loadActiveQuest() async {
    final p = await _prefs;
    final raw = p.getString(_questKey);
    if (raw == null) return null;
    try {
      return QuestRunState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveQuest() async {
    final p = await _prefs;
    await p.remove(_questKey);
  }
}
