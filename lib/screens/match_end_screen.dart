import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/data/asset_paths.dart';
import '../core/models/player_state.dart';
import '../core/theme/app_theme.dart';
import '../core/music/music_scope.dart';
import '../widgets/arena_button.dart';
import '../widgets/music_scope_host.dart';
import '../widgets/end_screen_name_banner.dart';
import 'match_setup_screen.dart';
import 'title_screen.dart';

/// Winner or forfeit end screen — name sits in the art's bottom black bar.
class MatchEndScreen extends StatelessWidget {
  final bool forfeited;

  const MatchEndScreen({super.key, required this.forfeited});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final match = game.match;
    PlayerState? winner;
    if (match != null && match.winnerId != null) {
      for (final p in match.players) {
        if (p.id == match.winnerId) {
          winner = p;
          break;
        }
      }
    }
    final showWinnerArt = !forfeited && winner != null;
    final forfeitName = game.forfeitPlayerName;
    final showForfeitArt = forfeited && forfeitName != null && forfeitName.isNotEmpty;

    return MusicScopeHost(
      scope: MusicScope.scoreboard,
      child: Scaffold(
      backgroundColor: AppTheme.arenaBlack,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      showWinnerArt
                          ? AssetPaths.winnerOverlay
                          : AssetPaths.forfeitOverlay,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                    if (showWinnerArt)
                      EndScreenNameBanner(name: winner.name),
                    if (showForfeitArt)
                      EndScreenNameBanner(
                        name: forfeitName,
                        forfeit: true,
                      ),
                  ],
                ),
              ),
            ),
            if (!showWinnerArt && !showForfeitArt)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'MATCH ENDED',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(
              height: 140,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (match != null)
                    ...match.players.map(
                      (p) => ListTile(
                        dense: true,
                        tileColor: AppTheme.arenaGray,
                        title: Text(p.name),
                        subtitle: Text(
                          'Score ${p.score} • Reps ${p.totalReps}',
                        ),
                      ),
                    ),
                  ...game.lastAwards.map(
                    (a) => ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 20,
                      ),
                      title: Text(
                        a.awardTitle,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(a.playerName),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  if (game.soloCanContinuePractice) ...[
                    ArenaButton(
                      label: 'KEEP TRAINING',
                      large: true,
                      onPressed: () async {
                        await game.continueSoloPractice();
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/game');
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  ArenaButton(
                    label: 'REMATCH',
                    large: true,
                    onPressed: () {
                      game.clearMatch();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MatchSetupScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
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
          ],
        ),
      ),
    ),
    );
  }
}
