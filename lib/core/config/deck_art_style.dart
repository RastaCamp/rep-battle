enum DeckArtStyle {
  /// Full illustrated card PNG per rank (default).
  defaultArt,

  /// Suit custom template + rank numbers only (Pro option).
  customTemplate,
}

extension DeckArtStyleStorage on DeckArtStyle {
  String get storageKey => name;

  static DeckArtStyle fromSettings(String? value) {
    if (value == DeckArtStyle.customTemplate.name) {
      return DeckArtStyle.customTemplate;
    }
    return DeckArtStyle.defaultArt;
  }
}
