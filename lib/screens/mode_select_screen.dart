import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/models/player_state.dart';
import '../core/theme/app_theme.dart';
import '../services/audio_service.dart';
import '../widgets/arena_button.dart';
import 'match_intro_screen.dart';

class ModeSelectScreen extends StatelessWidget {
  final List<PlayerState> players;

  const ModeSelectScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final rules = context.watch<GameController>().rules;
    final modes = rules?.modes.values.toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('SELECT MODE'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final mode in modes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                color: AppTheme.arenaGray,
                child: ListTile(
                  title: Text(
                    mode.name.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${mode.lives} lives'
                    '${mode.timerEnabled ? ' • ${mode.timerSeconds}s timer' : ''}'
                    '${mode.teamMode ? ' • Teams' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.arenaRed),
                  onTap: () async {
                    context.read<AudioService>().playSfx(SfxType.button);
                    final game = context.read<GameController>();
                    await game.startMatch(
                      modeId: mode.id,
                      players: players.map((p) => p.copy()).toList(),
                    );
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MatchIntroScreen(modeName: mode.name),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          ArenaButton(
            label: 'ADD CPU (SOLO)',
            onPressed: () async {
              final cpu = GameController.newPlayer(
                'CPU',
                GameController.playerColors[2],
                isCpu: true,
              );
              final list = [...players.map((p) => p.copy()), cpu];
              final game = context.read<GameController>();
              await game.startMatch(modeId: 'solo', players: list);
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MatchIntroScreen(modeName: 'Solo'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
