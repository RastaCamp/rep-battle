import 'package:flutter/foundation.dart';

import 'save_service.dart';

class EntitlementService extends ChangeNotifier {
  EntitlementService(this._save);

  final SaveService _save;
  bool isPro = false;
  final Set<String> ownedDlcIds = {};

  static const proContentIds = {
    'custom_cards',
    'custom_exercises',
    'extra_themes',
    'advanced_modes',
    'campaign_mode',
    'deck_builder',
    'quest_mode',
  };

  Future<void> load() async {
    final settings = await _save.loadSettings();
    isPro = settings['isPro'] as bool? ?? false;
    notifyListeners();
  }

  Future<void> _persist() async {
    final settings = await _save.loadSettings();
    settings['isPro'] = isPro;
    await _save.saveSettings(settings);
  }

  bool canUseCustomCards() => isPro;
  bool canUseProThemes() => isPro;
  bool canUseAdvancedModes() => isPro;
  bool canUseCampaign() => isPro;

  /// Quest unlocks after playing through a full deck once, or with Pro.
  bool canAccessQuest({required bool firstDeckComplete}) =>
      isPro || firstDeckComplete;

  bool canUseContent(String contentId) {
    if (contentId == 'default_deck' || contentId == 'default_rep_battle') {
      return true;
    }
    if (isPro && proContentIds.contains(contentId)) return true;
    if (ownedDlcIds.contains(contentId)) return true;
    return false;
  }

  Future<void> toggleProForDev() async {
    isPro = !isPro;
    await _persist();
    notifyListeners();
  }
}
