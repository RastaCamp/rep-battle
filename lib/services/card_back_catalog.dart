import '../core/data/asset_paths.dart';

class CardBackOption {
  final String id;
  final String label;
  final String assetPath;

  const CardBackOption({
    required this.id,
    required this.label,
    required this.assetPath,
  });
}

/// Selectable card backs (Pro).
class CardBackCatalog {
  CardBackCatalog._();

  static const defaultId = 'default';

  static const List<CardBackOption> options = [
    CardBackOption(id: 'default', label: 'Default', assetPath: AssetPaths.cardBackDefault),
    CardBackOption(id: 'bicycle', label: 'Bicycle', assetPath: 'assets/images/card_backs/bicycle.png'),
    CardBackOption(id: 'black_bicycle', label: 'Black Bicycle', assetPath: 'assets/images/card_backs/black_bicycle.png'),
    CardBackOption(id: 'brick', label: 'Brick', assetPath: 'assets/images/card_backs/brick.png'),
    CardBackOption(id: 'cage', label: 'Cage', assetPath: 'assets/images/card_backs/cage.png'),
    CardBackOption(id: 'custom', label: 'Custom', assetPath: 'assets/images/card_backs/custom.png'),
    CardBackOption(id: 'cyber', label: 'Cyber', assetPath: 'assets/images/card_backs/cyber.png'),
    CardBackOption(id: 'dumbells', label: 'Dumbbells', assetPath: 'assets/images/card_backs/dumbells.png'),
    CardBackOption(id: 'iron', label: 'Iron', assetPath: 'assets/images/card_backs/iron.png'),
    CardBackOption(id: 'king', label: 'King', assetPath: 'assets/images/card_backs/king.png'),
    CardBackOption(id: 'neon', label: 'Neon', assetPath: 'assets/images/card_backs/neon.png'),
    CardBackOption(id: 'purp', label: 'Purple', assetPath: 'assets/images/card_backs/purp.png'),
    CardBackOption(id: 'swoosh', label: 'Swoosh', assetPath: 'assets/images/card_backs/swoosh.png'),
    CardBackOption(id: 'zen', label: 'Zen', assetPath: 'assets/images/card_backs/zen.png'),
  ];

  static String assetForId(String? id) {
    final key = id ?? defaultId;
    for (final o in options) {
      if (o.id == key) return o.assetPath;
    }
    return AssetPaths.cardBackDefault;
  }
}
