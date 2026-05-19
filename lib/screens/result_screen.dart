import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/data/asset_paths.dart';
import '../core/theme/app_theme.dart';
import '../widgets/arena_button.dart';
import 'title_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final match = game.match;
    final winnerList =
        match!.players.where((p) => p.id == match.winnerId).toList();
    final winner = winnerList.isNotEmpty ? winnerList.first : null;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AssetPaths.winnerOverlay,
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.5),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset(AssetPaths.uiTrophy, height: 64),
                  const SizedBox(height: 12),
                  Text(
                    winner != null
                        ? '${winner.name.toUpperCase()} WINS!'
                        : 'MATCH COMPLETE',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        if (match != null)
                          ...match.players.map(
                            (p) => ListTile(
                              tileColor: AppTheme.arenaGray,
                              title: Text(p.name),
                              subtitle: Text(
                                'Score ${p.score} • Reps ${p.totalReps} • '
                                'Done ${p.cardsCompleted} • Failed ${p.cardsFailed}',
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          'AWARDS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        ...game.lastAwards.map(
                          (a) => ListTile(
                            leading: const Icon(Icons.emoji_events, color: Colors.amber),
                            title: Text(a.awardTitle),
                            subtitle: Text(a.playerName),
                          ),
                        ),
                        if (game.newlyUnlockedAchievements.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('ACHIEVEMENTS UNLOCKED'),
                          ...game.newlyUnlockedAchievements.map(
                            (t) => ListTile(
                              leading: Image.asset(AssetPaths.uiStar, height: 24),
                              title: Text(t),
                            ),
                          ),
                        ],
                        ListTile(
                          tileColor: AppTheme.arenaGray,
                          title: Text('XP +${25 + (match?.players.fold<int>(0, (s, p) => s + p.totalReps) ?? 0) ~/ 5}'),
                          subtitle: Text('Level ${game.stats['level'] ?? 1}'),
                        ),
                      ],
                    ),
                  ),
                  ArenaButton(
                    label: 'REMATCH',
                    imageAsset: AssetPaths.uiRerun,
                    large: true,
                    onPressed: () {
                      game.clearMatch();
                      Navigator.popUntil(context, (r) => r.isFirst);
                    },
                  ),
                  const SizedBox(height: 12),
                  ArenaButton(
                    label: 'MAIN MENU',
                    onPressed: () {
                      game.clearMatch();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const TitleScreen()),
                        (_) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
