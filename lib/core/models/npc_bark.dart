import 'package:flutter/material.dart';

enum NpcBarkKind {
  victory,
  forfeit,
  modified,
  clutch,
  startMatch,
  legendary,
  teamUp,
  respect,
  pain,
  humiliated,
}

class NpcBark {
  final String speakerName;
  final Color color;
  final String message;
  final NpcBarkKind kind;

  const NpcBark({
    required this.speakerName,
    required this.color,
    required this.message,
    required this.kind,
  });
}
