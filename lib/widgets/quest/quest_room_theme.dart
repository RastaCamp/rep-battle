import 'package:flutter/material.dart';

import '../../core/models/quest/quest_dungeon.dart';

class QuestRoomTheme {
  static Color colorFor(QuestRoomType type) => switch (type) {
        QuestRoomType.combat => Colors.orangeAccent,
        QuestRoomType.trap => Colors.purpleAccent,
        QuestRoomType.treasure => Colors.amberAccent,
        QuestRoomType.rest => Colors.greenAccent,
        QuestRoomType.boss => Colors.redAccent,
        QuestRoomType.npc => Colors.cyanAccent,
      };

  static String typeLabel(QuestRoomType type) => switch (type) {
        QuestRoomType.combat => 'COMBAT',
        QuestRoomType.trap => 'TRAP',
        QuestRoomType.treasure => 'TREASURE',
        QuestRoomType.rest => 'REST',
        QuestRoomType.boss => 'BOSS',
        QuestRoomType.npc => 'NPC',
      };
}
