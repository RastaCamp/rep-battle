import 'package:flutter/material.dart';

import '../core/models/ability_modifier.dart';

class AbilityModifierBadge extends StatelessWidget {
  final String modifierId;
  final bool compact;

  const AbilityModifierBadge({
    super.key,
    required this.modifierId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (modifierId == AbilityModifierId.standard) {
      return const SizedBox.shrink();
    }
    final mod = AbilityModifiers.get(modifierId);
    return Container(
      margin: EdgeInsets.only(top: compact ? 2 : 4),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        mod.name.toUpperCase(),
        style: TextStyle(
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w800,
          color: Colors.white70,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
