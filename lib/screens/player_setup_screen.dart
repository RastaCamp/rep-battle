import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/data/asset_paths.dart';
import '../core/theme/app_theme.dart';
import '../services/audio_service.dart';
import '../widgets/arena_button.dart';
import 'mode_select_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final List<_Slot> slots = [
    _Slot(name: 'Player 1', colorIndex: 0),
    _Slot(name: 'Player 2', colorIndex: 1),
  ];

  @override
  void dispose() {
    for (final s in slots) {
      s.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('PLAYER SETUP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(AssetPaths.uiMultiplayer, height: 64),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: slots.length,
                itemBuilder: (context, i) => _playerRow(i),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ArenaButton(
                    label: 'ADD PLAYER',
                    onPressed: slots.length < 6
                        ? () => setState(() {
                              slots.add(_Slot(
                                name: 'Player ${slots.length + 1}',
                                colorIndex: slots.length %
                                    GameController.playerColors.length,
                              ));
                            })
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                if (slots.length > 2)
                  ArenaButton(
                    label: 'REMOVE',
                    onPressed: () => setState(() => slots.removeLast()),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ArenaButton(
              label: 'CONTINUE',
              imageAsset: AssetPaths.uiConfirm,
              large: true,
              onPressed: () {
                context.read<AudioService>().playSfx(SfxType.button);
                final players = slots
                    .map(
                      (s) => GameController.newPlayer(
                        s.name,
                        GameController.playerColors[s.colorIndex],
                      ),
                    )
                    .toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModeSelectScreen(players: players),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerRow(int index) {
    final slot = slots[index];
    return Card(
      color: AppTheme.arenaGray,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              controller: slot.controller,
              onChanged: (v) => slot.name = v.isEmpty ? 'Player' : v,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(GameController.playerColors.length, (ci) {
                final selected = slot.colorIndex == ci;
                return GestureDetector(
                  onTap: () => setState(() => slot.colorIndex = ci),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GameController.playerColors[ci],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slot {
  String name;
  int colorIndex;
  late final TextEditingController controller;

  _Slot({required this.name, required this.colorIndex}) {
    controller = TextEditingController(text: name);
  }
}
