import 'dart:math';

import '../core/models/quest/quest_dungeon.dart';
class QuestNarration {
  QuestNarration._(this._data, this._rng);

  final Map<String, dynamic> _data;
  final Random _rng;

  factory QuestNarration.fromStory(Map<String, dynamic> story, {int? seed}) =>
      QuestNarration._(story, Random(seed));

  String pickRoomIntro(QuestRoomType type) {
    final key = type.name;
    if (type == QuestRoomType.boss) {
      return _pick('roomIntros', 'boss');
    }
    if (type == QuestRoomType.npc) {
      return _pick('roomIntros', 'rest');
    }
    return _pick('roomIntros', key);
  }

  String pickReturnIntro() => _pick('returnRoomIntros', null);

  String pickPostBossVictory() => _pick('postBossVictory', null);

  String pickEntryReason() => _pick('entryReasons', null);

  String pickBossPurpose() => _pick('bossPurposes', null);

  String pickActTransition(int act) =>
      _pickFromList(
        (_data['acts'] as Map<String, dynamic>?)?['$act']?['transitions']
            as List?,
      ) ??
      'The dungeon deepens.';

  String actTitle(int act) =>
      (_data['acts'] as Map<String, dynamic>?)?['$act']?['title'] as String? ??
      'Unknown';

  int actForRoom(int roomIndex, int roomCount) {
    if (roomCount <= 0) return 1;
    final progress = roomIndex / roomCount;
    if (progress <= 0.3) return 1;
    if (progress <= 0.55) return 2;
    if (progress <= 0.85) return 3;
    return 4;
  }

  String _pick(String section, String? subKey) {
    final block = _data[section];
    if (subKey != null && block is Map) {
      return _pickFromList(block[subKey] as List?) ?? '';
    }
    return _pickFromList(block as List?) ?? '';
  }

  String? _pickFromList(List? lines) {
    if (lines == null || lines.isEmpty) return null;
    return lines[_rng.nextInt(lines.length)] as String;
  }
}
