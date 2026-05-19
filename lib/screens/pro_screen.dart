import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/config/deck_art_style.dart';
import '../core/theme/app_theme.dart';
import '../services/card_back_catalog.dart';
import '../services/entitlement_service.dart';
import '../widgets/arena_button.dart';
import '../widgets/card_back_picker_grid.dart';
import 'custom_card_editor_screen.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  static const _features = [
    ('Quest Mode', 'quest_mode'),
    ('Custom Cards', 'custom_cards'),
    ('Custom Exercise Editor', 'custom_exercises'),
    ('Extra Themes', 'extra_themes'),
    ('Advanced Modes', 'advanced_modes'),
    ('Campaign Mode', 'campaign_mode'),
    ('Deck Builder', 'deck_builder'),
    ('DLC Packs', 'dlc_packs'),
  ];

  @override
  Widget build(BuildContext context) {
    final ent = context.watch<EntitlementService>();
    final game = context.watch<GameController>();
    final s = game.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('REP BATTLE PRO'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Expand your arena. Pro never blocks free play.\n\n'
            'Quest Mode also unlocks free after you play through a full deck in Play Mode.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          ..._features.map((f) {
            final unlocked = ent.isPro && f.$2 != 'dlc_packs';
            final isDlc = f.$2 == 'dlc_packs';
            final isCustomCards = f.$2 == 'custom_cards';
            return Card(
              color: AppTheme.arenaGray,
              child: ListTile(
                title: Text(f.$1),
                trailing: Text(
                  ent.isPro && !isDlc
                      ? 'UNLOCKED'
                      : isDlc
                          ? 'COMING SOON'
                          : 'LOCKED',
                  style: TextStyle(
                    color: unlocked ? Colors.greenAccent : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                onTap: isCustomCards && ent.isPro
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomCardEditorScreen(),
                          ),
                        )
                    : null,
              ),
            );
          }),
          if (ent.isPro) ...[
            const SizedBox(height: 16),
            const Text(
              'CARD BACK',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.amberAccent,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the face-down art for your deck pile.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 8),
            CardBackPickerGrid(
              selectedId:
                  s['cardBackId'] as String? ?? CardBackCatalog.defaultId,
              onSelected: (id) => game.updateSettings({'cardBackId': id}),
            ),
            const SizedBox(height: 16),
            const Text(
              'DECK ART',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.amberAccent,
              ),
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
                  'deckArtStyle': DeckArtStyle.customTemplate.storageKey,
                }),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ArenaButton(
            label: ent.isPro ? 'PRO ACTIVE (DEV)' : 'UNLOCK PRO (DEV TOGGLE)',
            glowColor: Colors.amber,
            large: true,
            onPressed: ent.toggleProForDev,
          ),
          const SizedBox(height: 12),
          const Text(
            'One-time purchase via Google Play Billing — coming soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
