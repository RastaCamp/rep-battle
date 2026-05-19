import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/music/music_scope.dart';
import '../services/audio_service.dart';

/// Binds background music to this route while mounted.
class MusicScopeHost extends StatefulWidget {
  final MusicScope scope;
  final bool proTitle;
  final Widget child;

  const MusicScopeHost({
    super.key,
    required this.scope,
    this.proTitle = false,
    required this.child,
  });

  @override
  State<MusicScopeHost> createState() => _MusicScopeHostState();
}

class _MusicScopeHostState extends State<MusicScopeHost> {
  AudioService? _audio;
  Object? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio ??= context.read<AudioService>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
  }

  @override
  void didUpdateWidget(MusicScopeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope || oldWidget.proTitle != widget.proTitle) {
      _enter();
    }
  }

  void _enter() {
    final audio = _audio ?? context.read<AudioService>();
    _audio = audio;
    _token = audio.enterMusicScope(
      widget.scope,
      proTitle: widget.proTitle,
    );
  }

  @override
  void dispose() {
    if (_token != null) {
      _audio?.leaveMusicScope(_token!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
