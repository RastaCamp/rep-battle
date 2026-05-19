/// Normalized Flutter asset keys for quest images.
class QuestAssets {
  QuestAssets._();

  /// Ensures a single `assets/` prefix for [Image.asset].
  static String key(String path) {
    var p = path.trim();
    if (p.isEmpty) return p;
    while (p.startsWith('assets/assets/')) {
      p = p.substring('assets/'.length);
    }
    if (!p.startsWith('assets/')) {
      p = 'assets/$p';
    }
    return p;
  }
}
