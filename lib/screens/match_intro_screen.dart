import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/music/music_scope.dart';
import '../services/audio_service.dart';
import '../services/entitlement_service.dart';
import '../widgets/music_scope_host.dart';
import '../widgets/card_shuffle_animation.dart';

class MatchIntroScreen extends StatefulWidget {
  final String modeName;

  const MatchIntroScreen({super.key, required this.modeName});

  @override
  State<MatchIntroScreen> createState() => _MatchIntroScreenState();
}

class _MatchIntroScreenState extends State<MatchIntroScreen> {
  String _status = 'Shuffling...';

  @override
  void initState() {
    super.initState();
    _runIntro();
  }

  Future<void> _runIntro() async {
    final audio = context.read<AudioService>();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await audio.playSfx(SfxType.shuffle);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _status = 'Crowd ready...');
    await audio.playSfx(SfxType.crowdCheer);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _status = 'BEGIN!');
    await audio.playSfx(SfxType.begin);
    if (!mounted) return;
    context.read<GameController>().beginGameplay();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/game');
  }

  @override
  Widget build(BuildContext context) {
    final pro = context.watch<EntitlementService>().isPro;
    return MusicScopeHost(
      scope: MusicScope.matchIntro,
      proTitle: pro,
      child: Scaffold(
      backgroundColor: AppTheme.arenaBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CardShuffleAnimation(cardWidth: 100),
            const SizedBox(height: 24),
            Text(
              _status,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
