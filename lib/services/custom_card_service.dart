import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/game_card.dart';

class CustomCardOverride {
  final String cardId;
  final String imagePath;
  final String? exerciseName;
  final int? reps;
  final String? exerciseId;

  const CustomCardOverride({
    required this.cardId,
    required this.imagePath,
    this.exerciseName,
    this.reps,
    this.exerciseId,
  });

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'imagePath': imagePath,
        'exerciseName': exerciseName,
        'reps': reps,
        'exerciseId': exerciseId,
      };

  factory CustomCardOverride.fromJson(Map<String, dynamic> json) =>
      CustomCardOverride(
        cardId: json['cardId'] as String,
        imagePath: json['imagePath'] as String,
        exerciseName: json['exerciseName'] as String?,
        reps: json['reps'] as int?,
        exerciseId: json['exerciseId'] as String?,
      );
}

/// Pro: per-card image overrides — replaces one deck slot by id (no duplicates).
class CustomCardService extends ChangeNotifier {
  static const _storageKey = 'rb_custom_card_overrides';
  final Map<String, CustomCardOverride> _overrides = {};

  Map<String, CustomCardOverride> get overrides => Map.unmodifiable(_overrides);

  Future<void> load() async {
    _overrides.clear();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    final list = jsonDecode(raw) as List;
    for (final item in list) {
      final o = CustomCardOverride.fromJson(item as Map<String, dynamic>);
      _overrides[o.cardId] = o;
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_overrides.values.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<String> saveImageBytes(String cardId, Uint8List bytes) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'rb_custom_img_$cardId';
      await prefs.setString(key, base64Encode(bytes));
      return 'web:$key';
    }
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'custom_cards'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final path = p.join(folder.path, '$cardId.png');
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<Uint8List?> loadImageBytes(String imagePath) async {
    if (imagePath.startsWith('web:')) {
      final prefs = await SharedPreferences.getInstance();
      final key = imagePath.substring(4);
      final b64 = prefs.getString(key);
      if (b64 == null) return null;
      return base64Decode(b64);
    }
    final file = File(imagePath);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<void> setOverride(CustomCardOverride override) async {
    _overrides[override.cardId] = override;
    await _persist();
  }

  Future<void> removeOverride(String cardId) async {
    _overrides.remove(cardId);
    await _persist();
  }

  List<GameCard> applyOverrides(List<GameCard> deck) {
    if (_overrides.isEmpty) return deck;
    return deck.map((card) {
      final o = _overrides[card.id];
      if (o == null) return card;
      return GameCard(
        id: card.id,
        suit: card.suit,
        rank: card.rank,
        exerciseId: o.exerciseId ?? card.exerciseId,
        exerciseName: o.exerciseName ?? card.exerciseName,
        modifiedName: card.modifiedName,
        reps: o.reps ?? card.reps,
        repUnit: card.repUnit,
        repNote: card.repNote,
        cardType: CardType.custom,
        isGroupChallenge: card.isGroupChallenge,
        imageAsset: card.imageAsset,
        useSuitTemplate: true,
        customImagePath: o.imagePath,
      );
    }).toList();
  }
}
