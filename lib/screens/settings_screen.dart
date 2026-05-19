import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/config/deck_art_style.dart';
import '../core/data/asset_paths.dart';
import '../core/theme/app_theme.dart';
import '../core/music/music_scope.dart';
import '../services/avatar_catalog.dart';
import '../widgets/music_scope_host.dart';
import '../services/card_back_catalog.dart';
import '../services/entitlement_service.dart';
import '../widgets/arena_button.dart';
import '../widgets/avatar_picker_row.dart';
import '../widgets/card_back_picker_grid.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final ent = context.watch<EntitlementService>();
    final s = game.settings;
    final musicVol = (s['musicVolume'] as num?)?.toDouble() ?? 75;
    final sfxVol = (s['sfxVolume'] as num?)?.toDouble() ?? 100;

    return MusicScopeHost(
      scope: MusicScope.settings,
      child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AssetPaths.uiSettings,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => Container(color: AppTheme.arenaBlack),
          ),
          Container(color: Colors.black.withValues(alpha: 0.55)),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text('SETTINGS'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _switch(context, 'Sound Effects', 'soundEnabled', s),
                      ListTile(
                        title: const Text('Sound volume'),
                        subtitle: Slider(
                          value: sfxVol,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${sfxVol.round()}%',
                          onChanged: (s['soundEnabled'] as bool? ?? true)
                              ? (v) => game.updateSettings({'sfxVolume': v.round()})
                              : null,
                        ),
                      ),
                      _switch(context, 'Music', 'musicEnabled', s),
                      ListTile(
                        title: const Text('Music volume'),
                        subtitle: Slider(
                          value: musicVol,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${musicVol.round()}%',
                          onChanged: (s['musicEnabled'] as bool? ?? true)
                              ? (v) => game.updateSettings({'musicVolume': v.round()})
                              : null,
                        ),
                      ),
                      _switch(context, 'Vibration / Haptics', 'vibrationEnabled', s),
                      _switch(context, 'Reduced Flashing', 'reducedFlashing', s),
                      _switch(context, 'Readable Text Mode', 'readableText', s),
                      _switch(context, 'Low Impact Mode', 'lowImpactMode', s),
                      _switch(context, 'Seated / Chair Mode', 'seatedMode', s),
                      _switch(context, 'Do Not Disturb', 'doNotDisturb', s),
                      const Divider(color: Colors.white24),
                      const ListTile(
                        title: Text('Default player portrait'),
                        subtitle: Text(
                          'Used for new matches; change per player during setup',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: AvatarPickerRow(
                          selectedId: s['defaultPlayerAvatarId'] as String? ??
                              AvatarCatalog.defaultPlayerAvatarId,
                          borderColor: Colors.cyanAccent,
                          onSelected: (id) =>
                              game.updateSettings({'defaultPlayerAvatarId': id}),
                        ),
                      ),
                      if (ent.isPro) ...[
                        const Divider(color: Colors.white24),
                        const ListTile(
                          title: Text('Default card deck'),
                          subtitle: Text('Face art for numbered cards'),
                        ),
                        ListTile(
                          title: const Text('Standard deck'),
                          trailing: Radio<DeckArtStyle>(
                            value: DeckArtStyle.defaultArt,
                            groupValue: DeckArtStyleStorage.fromSettings(
                              s['deckArtStyle'] as String?,
                            ),
                            onChanged: (_) => game.updateSettings({
                              'deckArtStyle': DeckArtStyle.defaultArt.storageKey,
                            }),
                          ),
                        ),
                        ListTile(
                          title: const Text('Custom template deck'),
                          trailing: Radio<DeckArtStyle>(
                            value: DeckArtStyle.customTemplate,
                            groupValue: DeckArtStyleStorage.fromSettings(
                              s['deckArtStyle'] as String?,
                            ),
                            onChanged: (_) => game.updateSettings({
                              'deckArtStyle':
                                  DeckArtStyle.customTemplate.storageKey,
                            }),
                          ),
                        ),
                        const ListTile(
                          title: Text('Card back'),
                          subtitle: Text('Face-down pile and shuffle animation'),
                        ),
                        CardBackPickerGrid(
                          selectedId: s['cardBackId'] as String? ??
                              CardBackCatalog.defaultId,
                          onSelected: (id) =>
                              game.updateSettings({'cardBackId': id}),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const Divider(color: Colors.white24),
                      ListTile(
                        title: const Text('Stats'),
                        subtitle: Text(
                          'Matches: ${game.stats['matchesPlayed'] ?? 0} • '
                          'Wins: ${game.stats['wins'] ?? 0} • '
                          'XP: ${game.stats['xp'] ?? 0}',
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Exercise at your own pace. Stop if you feel dizzy or in pain.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                      if (!(s['tutorialComplete'] as bool? ?? false))
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ArenaButton(
                            label: 'COMPLETE TUTORIAL',
                            onPressed: () {
                              game.updateSettings({'tutorialComplete': true});
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _switch(
    BuildContext context,
    String title,
    String key,
    Map<String, dynamic> settings,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: settings[key] as bool? ?? (key == 'soundEnabled' || key == 'musicEnabled'),
      activeColor: AppTheme.arenaRed,
      onChanged: (v) =>
          context.read<GameController>().updateSettings({key: v}),
    );
  }
}
