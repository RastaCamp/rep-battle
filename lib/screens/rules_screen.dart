import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOW TO PLAY'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            title: 'Quick start',
            body:
                '1. Tap PLAY and pick a mode.\n'
                '2. Enter player names and colors, then optional ability modifiers.\n'
                '3. Draw from the deck on your turn.\n'
                '4. Do the exercise, then tap PASS, MODIFIED, FAIL, or SKIP.\n'
                '5. Last player standing (or highest score) wins.',
          ),
          _Section(
            title: 'How to play',
            body:
                'On your turn, tap the face-down DRAW pile. The card shows an exercise and rep count (or seconds for holds).\n\n'
                'PASS — you completed full reps.\n'
                'MODIFIED — easier variation (half points in most modes).\n'
                'FAIL — you could not finish; lose a life (armor may block once).\n'
                'SKIP — spend a skip token to avoid the card.',
          ),
          _Section(
            title: 'Special cards',
            body:
                'JACK — repeat the previous card.\n'
                'QUEEN — long hold (30s default).\n'
                'KING — everyone does the exercise; each player judges their own result.\n'
                'JOKER — wild challenge from the deck.',
          ),
          _Section(
            title: 'Combos',
            body:
                'Passing in a row builds a combo chain. Higher chains grant bonus points and rewards at 3, 5, and 10 passes. '
                'Failing breaks the combo for everyone.',
          ),
          _Section(
            title: 'Ability modifiers (per player)',
            body:
                'After names, each human can pick a modifier that affects only them — not the whole table.\n\n'
                'Example: you draw 8♠ and do 8 pushups. Mom draws 8♠ in Seated Mode and sees 4 chair pushups / wall presses.\n\n'
                'Standard — normal rules.\n'
                'Beginner — +2 lives, 1 skip, reps −25%.\n'
                'Senior / Low Impact — +2 lives, 1 armor, 2 skips, reps −50%, no jumping, assisted options.\n'
                'Seated Mode — chair-safe exercises, reps −50%, no timer for that player.\n'
                'Rehab / Recovery — +3 lives, 2 armor, 2 skips, reps −50%, modified counts as full pass.\n'
                'Advanced — −1 life, reps +25%, bonus points +25%.\n'
                'Beast Mode — 1 life, reps +50%, score multiplier ×1.5.\n\n'
                'Optional table rules: win by points or cards completed, turn timer off, gentler jokers/kings.',
          ),
          _Section(
            title: 'How to win',
            body:
                'Standard / Battle / Team: lose all lives and you are out; last player or team wins (unless you chose points or cards at setup).\n'
                'Casual: more lives and starting armor — same goal, more forgiving.\n'
                'Solo: practice mode — no elimination; keep score and reps. NPC opponents use their own stats.',
          ),
          _Section(
            title: 'Quest Mode (Dungeon Crawl)',
            body:
                'From the title screen, tap QUEST. Pick players, difficulty, and dungeon.\n\n'
                'Each room: draw a card. The exercise is your attack — PASS deals damage, FAIL lets the enemy hit you.\n\n'
                'Spades = Power (pushups), Hearts = Endurance (squats), Clubs = Core (situps), Diamonds = Speed (mountain climbers).\n\n'
                'Aces = weak hits, 2–10 = damage by rank, Jack = repeat last attack, Queen = armor, King = 15 damage, Joker = Rest / Loot / Chaos.\n\n'
                'Boss every 5 rooms. Clear all 10 rooms to win. Loot consumables and relics along the way.',
          ),
          _Section(
            title: 'Light weights deck',
            body:
                'Optional 26-card deck (ranks 2–7 plus jokers) for shorter, lighter sessions.',
          ),
          _Section(
            title: 'Safety',
            body:
                'Exercise at your own pace. Stop if dizzy, in pain, or unsure. Modified reps exist so everyone can participate.',
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: AppTheme.arenaGray,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.arenaRed,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: TextStyle(height: 1.45, color: Colors.white.withValues(alpha: 0.87)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
