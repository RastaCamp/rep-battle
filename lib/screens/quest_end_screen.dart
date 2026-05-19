import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../services/audio_service.dart';
import 'quest_setup_screen.dart';
import '../screens/title_screen.dart';

class QuestEndScreen extends StatefulWidget {
  final bool won;

  const QuestEndScreen({super.key, required this.won});

  @override
  State<QuestEndScreen> createState() => _QuestEndScreenState();
}

class _QuestEndScreenState extends State<QuestEndScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audio = context.read<AudioService>();
      if (widget.won) {
        audio.playSfx(SfxType.victory);
      } else {
        audio.playSfx(SfxType.eliminated);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.won ? Icons.emoji_events : Icons.heart_broken,
                size: 80,
                color: widget.won ? Colors.amberAccent : AppTheme.arenaRed,
              ),
              const SizedBox(height: 16),
              Text(
                widget.won ? 'DUNGEON CLEARED!' : 'QUEST FAILED',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.won
                    ? 'You conquered the Rust Arena.'
                    : 'Your party fell in the dungeon.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.arenaRed,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuestSetupScreen(),
                      ),
                    );
                  },
                  child: const Text('NEW QUEST'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const TitleScreen()),
                    (_) => false,
                  );
                },
                child: const Text('MAIN MENU'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
