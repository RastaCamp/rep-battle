import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class QuestBarkBanner extends StatelessWidget {
  final String? speaker;
  final String? line;

  const QuestBarkBanner({super.key, this.speaker, this.line});

  @override
  Widget build(BuildContext context) {
    if (line == null || line!.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.arenaGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (speaker != null)
            Text(
              speaker!.toUpperCase(),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          Text(
            line!,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
