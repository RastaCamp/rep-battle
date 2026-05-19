import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/models/npc_profile.dart';
import '../core/theme/app_theme.dart';
import '../services/npc_registry.dart';
import 'npc_avatar.dart';
import 'npc_profile_dialog.dart';

/// Cycles NPC portraits then lands on a random opponent.
class NpcShufflePicker extends StatefulWidget {
  final void Function(NpcProfile selected) onSelected;
  final bool allowSurprise;
  final Set<String> excludeIds;
  final String? slotLabel;

  const NpcShufflePicker({
    super.key,
    required this.onSelected,
    this.allowSurprise = false,
    this.excludeIds = const {},
    this.slotLabel,
  });

  @override
  State<NpcShufflePicker> createState() => NpcShufflePickerState();
}

class NpcShufflePickerState extends State<NpcShufflePicker> {
  final _random = Random();
  late List<NpcProfile> _pool;
  int _index = 0;
  Timer? _timer;
  bool _locked = false;
  NpcProfile? _finalPick;

  @override
  void initState() {
    super.initState();
    _pool = NpcRegistry.instance.regular
        .where((p) => !widget.excludeIds.contains(p.id))
        .toList()
      ..shuffle(_random);
    if (_pool.isEmpty) {
      _pool = NpcRegistry.instance.all
          .where((p) => !widget.excludeIds.contains(p.id))
          .toList()
        ..shuffle(_random);
    }
    _startShuffle();
  }

  void _startShuffle() {
    _timer?.cancel();
    var ticks = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!mounted) return;
      ticks++;
      setState(() => _index = (_index + 1) % _pool.length);
      if (ticks >= 28) {
        t.cancel();
        _finish();
      }
    });
  }

  void _finish() {
    NpcProfile pick;
    if (widget.allowSurprise && _random.nextDouble() < 0.12) {
      pick = NpcRegistry.instance.pickSurprise();
    } else {
      final candidates = NpcRegistry.instance.pickMany(
        1,
        excludeIds: widget.excludeIds,
      );
      pick = candidates.isNotEmpty
          ? candidates.first
          : NpcRegistry.instance.pickRandom();
    }
    setState(() {
      _locked = true;
      _finalPick = pick;
    });
    widget.onSelected(pick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  NpcProfile get current => _finalPick ?? _pool[_index % _pool.length];

  @override
  Widget build(BuildContext context) {
    final profile = current;

    return Column(
      children: [
        Text(
          widget.slotLabel != null
              ? 'NPC ${widget.slotLabel!.toUpperCase()}'
              : 'OPPONENT SELECTED',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _locked ? () => showNpcProfileDialog(context, profile) : null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: NpcAvatar(
              key: ValueKey(profile.id),
              profile: profile,
              size: 100,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile.name.toUpperCase(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: profile.color,
          ),
        ),
        Text(
          '${profile.age} • ${profile.job}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            profile.tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        if (_locked) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => showNpcProfileDialog(context, profile),
            child: const Text(
              'VIEW FULL PROFILE',
              style: TextStyle(color: AppTheme.arenaRed),
            ),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Shuffling opponents...', style: TextStyle(color: Colors.white38)),
          ),
      ],
    );
  }
}
