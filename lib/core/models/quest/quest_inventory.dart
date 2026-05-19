class QuestInventory {
  static const consumableSlots = 3;
  static const relicSlots = 1;

  final List<String?> consumables;
  final List<String?> relics;

  QuestInventory({
    List<String?>? consumables,
    List<String?>? relics,
  })  : consumables = consumables ?? List.filled(consumableSlots, null),
        relics = relics ?? List.filled(relicSlots, null);

  bool get hasSpaceConsumable => consumables.any((s) => s == null);

  bool get hasSpaceRelic => relics.any((s) => s == null);

  int? firstEmptyConsumableSlot() {
    for (var i = 0; i < consumables.length; i++) {
      if (consumables[i] == null) return i;
    }
    return null;
  }

  int? firstEmptyRelicSlot() {
    for (var i = 0; i < relics.length; i++) {
      if (relics[i] == null) return i;
    }
    return null;
  }

  bool addItem(String itemId, String type) {
    if (type == 'relic') {
      final slot = firstEmptyRelicSlot();
      if (slot == null) return false;
      relics[slot] = itemId;
      return true;
    }
    final slot = firstEmptyConsumableSlot();
    if (slot == null) return false;
    consumables[slot] = itemId;
    return true;
  }

  bool removeConsumable(int slot) {
    if (slot < 0 || slot >= consumables.length) return false;
    if (consumables[slot] == null) return false;
    consumables[slot] = null;
    return true;
  }

  List<String> get activeRelicIds =>
      relics.whereType<String>().toList();

  bool hasRelic(String id) => relics.contains(id);

  Map<String, dynamic> toJson() => {
        'consumables': consumables,
        'relics': relics,
      };

  factory QuestInventory.fromJson(Map<String, dynamic>? json) {
    if (json == null) return QuestInventory();
    final c = (json['consumables'] as List?)
            ?.map((e) => e as String?)
            .toList() ??
        List.filled(consumableSlots, null);
    final r = (json['relics'] as List?)
            ?.map((e) => e as String?)
            .toList() ??
        List.filled(relicSlots, null);
    while (c.length < consumableSlots) {
      c.add(null);
    }
    while (r.length < relicSlots) {
      r.add(null);
    }
    return QuestInventory(
      consumables: c.take(consumableSlots).toList(),
      relics: r.take(relicSlots).toList(),
    );
  }
}
