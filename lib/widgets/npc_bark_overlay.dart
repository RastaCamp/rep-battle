import 'package:flutter/material.dart';

import '../core/models/npc_bark.dart';

/// Brief speech bubble for an active NPC line.
class NpcBarkOverlay extends StatelessWidget {
  final NpcBark bark;

  const NpcBarkOverlay({super.key, required this.bark});

  Color get _accent => switch (bark.kind) {
        NpcBarkKind.victory => Colors.greenAccent,
        NpcBarkKind.forfeit => Colors.orangeAccent,
        NpcBarkKind.modified => Colors.lightBlueAccent,
        NpcBarkKind.clutch => Colors.amberAccent,
        NpcBarkKind.startMatch => Colors.cyanAccent,
        NpcBarkKind.legendary => Colors.deepPurpleAccent,
        NpcBarkKind.teamUp => Colors.tealAccent,
        NpcBarkKind.respect => Colors.lightGreenAccent,
        NpcBarkKind.pain => Colors.deepOrangeAccent,
        NpcBarkKind.humiliated => Colors.redAccent,
      };

  IconData get _icon => switch (bark.kind) {
        NpcBarkKind.victory => Icons.emoji_events_outlined,
        NpcBarkKind.forfeit => Icons.sentiment_dissatisfied_outlined,
        NpcBarkKind.modified => Icons.tune,
        NpcBarkKind.clutch => Icons.favorite_border,
        NpcBarkKind.startMatch => Icons.flag_outlined,
        NpcBarkKind.legendary => Icons.auto_awesome,
        NpcBarkKind.teamUp => Icons.groups_outlined,
        NpcBarkKind.respect => Icons.thumb_up_outlined,
        NpcBarkKind.pain => Icons.local_fire_department_outlined,
        NpcBarkKind.humiliated => Icons.hide_source_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 88),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 12),
                child: child,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: bark.color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: bark.color.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_icon, size: 14, color: _accent),
                        const SizedBox(width: 6),
                        Text(
                          bark.speakerName.toUpperCase(),
                          style: TextStyle(
                            color: bark.color,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bark.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
