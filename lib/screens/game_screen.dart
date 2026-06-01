import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/data/asset_paths.dart';
import '../core/engine/ability_modifier_engine.dart';
import '../core/models/game_card.dart';
import '../core/models/match_state.dart';
import '../core/theme/app_theme.dart';
import '../services/audio_service.dart';
import '../widgets/combo_meter.dart';
import '../widgets/deck_pile_row.dart';
import '../widgets/game_overlays.dart';
import '../widgets/npc_bark_overlay.dart';
import '../widgets/pass_fail_controls.dart';
import '../widgets/ability_modifier_badge.dart';
import '../widgets/player_avatar.dart';
import '../widgets/player_hud.dart';
import '../widgets/playing_card_widget.dart';
import 'match_end_screen.dart';
import 'match_intro_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  Timer? _timerTick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerTick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      context.read<GameController>().onAppLifecyclePaused();
    }
  }

  void _startTimerIfNeeded() {
    _timerTick?.cancel();
    _timerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      final game = context.read<GameController>();
      final match = game.match;
      if (match == null || !match.timerRunning || game.paused) return;
      setState(() {
        match.timerSecondsRemaining--;
        if (match.timerSecondsRemaining <= 10) {
          context.read<AudioService>().playSfx(SfxType.timerWarning);
        } else if (match.timerSecondsRemaining % 5 == 0) {
          context.read<AudioService>().playSfx(SfxType.timerTick);
        }
        if (match.timerSecondsRemaining <= 0) {
          match.timerRunning = false;
          game.resolveResult(TurnResultType.fail);
        }
      });
    });
  }

  void _goToMatchEnd(GameController game) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MatchEndScreen(forfeited: game.matchEndedForfeited),
      ),
    );
  }

  /// Top of discard = current draw; show the last fully resolved card instead.
  GameCard? _discardDisplayCard(MatchState match) {
    if (match.discardPile.isEmpty) return null;
    if (match.cardDrawnThisTurn && match.discardPile.length >= 2) {
      return match.discardPile[match.discardPile.length - 2];
    }
    if (!match.cardDrawnThisTurn) {
      return match.discardPile.last;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final match = game.match;
    if (match == null) {
      return const Scaffold(body: Center(child: Text('No active match')));
    }

    if (match.matchOver && !game.paused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToMatchEnd(game);
      });
    }

    final current = match.currentPlayer;
    final adjudicator =
        match.awaitingGroupResults ? match.groupAdjudicator : current;
    final active = adjudicator ?? current;
    final card = match.currentCard;
    final displayCard = card != null
        ? AbilityModifierEngine.personalizeCard(card, active)
        : null;
    final canDraw = !match.cardDrawnThisTurn && !active.isCpu && !game.cpuExercising;
    final showControls =
        match.cardDrawnThisTurn && !active.isCpu && !game.cpuExercising;
    final groupSize = match.groupPlayerCount;
    final groupTotal = match.awaitingGroupResults
        ? groupSize - match.groupPendingPlayerIds.length
        : 0;
    final discardCard = _discardDisplayCard(match);

    final turnColor = active.color;
    final bgTop = Color.lerp(turnColor, AppTheme.arenaBlack, 0.72)!;
    final bgBottom = Color.lerp(turnColor, AppTheme.arenaBlack, 0.88)!;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [bgTop, bgBottom],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Image.asset(AssetPaths.uiPause, height: 26),
                          onPressed: game.pauseMatch,
                        ),
                        Expanded(
                          child: ComboMeter(
                            combo: match.comboChain,
                            hype: match.hypeMeter,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 76,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    itemCount: match.players.length,
                    itemBuilder: (_, i) {
                      final p = match.players[i];
                      return SizedBox(
                        width: 140,
                        child: PlayerHud(
                          player: p,
                          isActive: p.id == active.id,
                          compact: true,
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardMaxH =
                          (constraints.maxHeight * 0.38).clamp(70.0, 180.0);
                      final cardMaxW =
                          (constraints.maxWidth * 0.5).clamp(90.0, 160.0);

                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PlayerAvatar(
                                player: active,
                                borderColor: active.color,
                                size: 56,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                active.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: active.color,
                                ),
                              ),
                              if (active.title != null && active.title!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    active.title!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              AbilityModifierBadge(
                                modifierId: active.abilityModifierId,
                              ),
                              if (game.cpuExercising) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _cpuExertionLabel(game),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: game.skipCpuWait,
                                  child: const Text(
                                    'PUSH — hurry them up',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                ),
                              ],
                              if (match.awaitingGroupResults && groupSize > 0)
                                Text(
                                  'GROUP ${groupTotal + 1}/$groupSize',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if (match.timerRunning)
                                Text(
                                  '${match.timerSecondsRemaining}s',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              DeckPileRow(
                                deckCount: match.activeDeck.length,
                                discardCard: discardCard,
                                discardCount: match.discardPile.length,
                                canDraw: canDraw,
                                onDraw: () => game.drawCard(),
                                pileWidth: 68,
                              ),
                              if (!match.cardDrawnThisTurn && canDraw)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Tap deck to draw',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              if (match.cardDrawnThisTurn && displayCard != null) ...[
                                const SizedBox(height: 10),
                                PlayingCardWidget(
                                  card: displayCard,
                                  maxWidth: cardMaxW,
                                  maxHeight: cardMaxH,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    6,
                                    12,
                                    0,
                                  ),
                                  child: Text(
                                    AbilityModifierEngine.challengeLabel(
                                      displayCard!,
                                      active,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (match.cardDrawnThisTurn)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: PassFailControls(
                        enabled: showControls,
                        canSkip: active.skips > 0,
                        onPass: () => game.resolveResult(TurnResultType.pass),
                        onFail: () => game.resolveResult(TurnResultType.fail),
                        onModified: () =>
                            game.resolveResult(TurnResultType.modified),
                        onSkip: () => game.resolveResult(TurnResultType.skip),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (game.paused)
            PauseOverlay(
              onResume: game.resumeMatch,
              onUndo: game.undoLastResult,
              onRestart: () async {
                await game.restartMatch();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchIntroScreen(
                        modeName: game.currentMode?.name ?? 'Match',
                      ),
                    ),
                  );
                }
              },
              onForfeit: () async {
                await game.forfeitMatch();
                if (context.mounted) _goToMatchEnd(game);
              },
              onQuit: () {
                game.clearMatch();
                Navigator.popUntil(context, (r) => r.isFirst);
              },
            ),
          if (game.activeNpcBark != null)
            NpcBarkOverlay(bark: game.activeNpcBark!),
          if (game.showComboOverlay) const ComboOverlay(),
          if (game.showArmorBreakOverlay) const ArmorBreakOverlay(),
        ],
      ),
    );
  }

  String _cpuExertionLabel(GameController game) {
    final cue = game.cpuExertionCue;
    final remaining = game.cpuExerciseRemaining;
    if (remaining != null) {
      final sec = remaining.inSeconds.clamp(0, 999);
      return '$cue  (~${sec}s)';
    }
    return cue.isEmpty ? 'Working…' : cue;
  }
}
