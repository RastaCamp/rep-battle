import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../controllers/quest_controller.dart';
import '../core/data/asset_paths.dart';
import '../core/theme/app_theme.dart';
import '../core/music/music_scope.dart';
import '../services/audio_service.dart';
import '../services/entitlement_service.dart';
import '../widgets/music_scope_host.dart';
import 'match_setup_screen.dart';
import 'quest_game_screen.dart';
import 'quest_setup_screen.dart';
import 'pro_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => TitleScreenState();
}

class TitleScreenState extends State<TitleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  void _maybeShowOnboarding() {
    final game = context.read<GameController>();
    if (game.settings['tutorialComplete'] == true) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C22),
        title: const Text('Welcome to Rep Battle'),
        content: const SingleChildScrollView(
          child: Text(
            'Pick a mode, gather players, draw cards, and complete exercises.\n\n'
            'PASS / FAIL / MODIFIED / SKIP each turn.\n\n'
            'Exercise at your own pace. Stop if dizzy or in pain.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              game.updateSettings({'tutorialComplete': true});
              Navigator.pop(ctx);
            },
            child: const Text('ENTER ARENA'),
          ),
        ],
      ),
    );
  }

  void _showQuestLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C22),
        title: const Text('Quest Mode Locked'),
        content: const Text(
          'Finish a full match and play through the entire deck once to unlock Quest Mode.\n\n'
          'Or unlock Rep Battle Pro for instant access.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProScreen()),
              );
            },
            child: const Text('VIEW PRO'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final quest = context.watch<QuestController>();
    final ent = context.watch<EntitlementService>();
    final questUnlocked =
        ent.canAccessQuest(firstDeckComplete: game.firstDeckComplete);
    final useProArt = ent.isPro;
    final titleArt =
        useProArt ? AssetPaths.titleScreenPro : AssetPaths.titleScreen;

    return MusicScopeHost(
      scope: MusicScope.title,
      proTitle: useProArt,
      child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            titleArt,
            key: ValueKey('title_bg_$useProArt'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            gaplessPlayback: true,
            errorBuilder: (_, __, stack) {
              debugPrint('Title asset failed: $titleArt\n$stack');
              return Image.asset(
                AssetPaths.titleScreen,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              );
            },
          ),
          if (useProArt)
            const Positioned(
              top: 48,
              right: 12,
              child: SafeArea(
                child: _ProBadge(),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                _TitleMenuButton(
                  label: 'PLAY',
                  onTap: () {
                    context.read<AudioService>().playSfx(SfxType.button);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MatchSetupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _TitleMenuButton(
                  label: questUnlocked ? 'QUEST' : 'QUEST (LOCKED)',
                  dimmed: !questUnlocked,
                  onTap: () {
                    context.read<AudioService>().playSfx(SfxType.button);
                    if (!questUnlocked) {
                      _showQuestLockedDialog(context);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuestSetupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (questUnlocked && quest.canResumeQuest) ...[
                  _TitleMenuButton(
                    label: 'RESUME QUEST',
                    onTap: () async {
                      final ok = await quest.tryResumeQuest();
                      if (ok && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QuestGameScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                _TitleMenuButton(
                  label: 'RULES',
                  onTap: () {
                    context.read<AudioService>().playSfx(SfxType.button);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RulesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (game.canResume) ...[
                  _TitleMenuButton(
                    label: 'RESUME',
                    onTap: () async {
                      final ok = await game.tryResumeMatch();
                      if (ok && context.mounted) {
                        Navigator.pushNamed(context, '/game');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                _TitleMenuButton(
                  label: ent.isPro ? 'PRO ✓' : 'PRO',
                  onTap: () async {
                    context.read<AudioService>().playSfx(SfxType.button);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProScreen()),
                    );
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _TitleMenuButton(
                  label: 'SETTINGS',
                  onTap: () {
                    context.read<AudioService>().playSfx(SfxType.button);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amberAccent, width: 1.5),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.amberAccent,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TitleMenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool dimmed;

  const _TitleMenuButton({
    required this.label,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = dimmed
        ? Colors.white24
        : AppTheme.arenaRed.withValues(alpha: 0.7);
    final textColor = dimmed ? Colors.white38 : AppTheme.arenaWhite;

    return Material(
      color: Colors.black.withValues(alpha: dimmed ? 0.55 : 0.45),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
