import 'package:flutter/material.dart';

import '../core/models/npc_profile.dart';
import '../core/theme/app_theme.dart';
import 'npc_avatar.dart';

void showNpcProfileDialog(BuildContext context, NpcProfile profile) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1C1C22),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: NpcAvatar(profile: profile, size: 88)),
            const SizedBox(height: 12),
            Text(
              '${profile.name}, ${profile.age}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.arenaWhite,
              ),
            ),
            Text(
              profile.job,
              style: TextStyle(color: profile.color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              profile.tagline,
              style: const TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Conditions: ${profile.conditionsLabel}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              profile.bio,
              style: TextStyle(
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.87),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Typical play: ${(profile.passRate * 100).round()}% pass • '
              '${(profile.modifiedRate * 100).round()}% modified • '
              'turn time ≈ reps+3s (×${profile.timingMultiplier.toStringAsFixed(2)})',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('CLOSE'),
        ),
      ],
    ),
  );
}
