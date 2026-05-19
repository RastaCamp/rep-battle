import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../core/config/deck_art_style.dart';
import '../core/models/ability_modifier.dart';
import '../core/models/match_house_rules.dart';
import '../core/models/npc_profile.dart';
import '../core/theme/app_theme.dart';
import '../services/audio_service.dart';
import '../services/avatar_catalog.dart';
import '../core/music/music_scope.dart';
import '../services/entitlement_service.dart';
import '../widgets/music_scope_host.dart';
import '../services/npc_registry.dart';
import '../widgets/avatar_picker_row.dart';
import '../widgets/player_avatar.dart';
import '../widgets/npc_avatar.dart';
import '../widgets/npc_profile_dialog.dart';
import '../widgets/npc_shuffle_picker.dart';
import '../widgets/setup_nav_bar.dart';
import 'match_intro_screen.dart';

/// Setup: Mode → Solo/Multi → [count] → Names → Modifiers → House rules → [NPC] → [deck Pro].
class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  int _step = 0;
  String _modeId = 'standard';
  bool _isSolo = false;
  bool _lightDeck = false;
  bool _surpriseEntrant = false;
  int _playerCount = 2;
  int _npcCount = 0;
  NpcProfile? _soloNpc;
  bool _soloNpcReady = false;
  final List<NpcProfile> _multiNpcs = [];
  final List<_Slot> _slots = [
    _Slot(name: 'Player 1', colorIndex: 0, avatarId: AvatarCatalog.defaultPlayerAvatarId),
    _Slot(name: 'Player 2', colorIndex: 1, avatarId: AvatarCatalog.defaultPlayerAvatarId),
  ];
  DeckArtStyle _deckArt = DeckArtStyle.defaultArt;
  int _modifierPlayerIndex = 0;
  MatchHouseRules _houseRules = const MatchHouseRules();

  int get _humanCount => _isSolo ? 1 : _playerCount;

  static const _modes = [
    (
      'standard',
      'Standard',
      'Classic Rep Battle: 3 lives, elimination on. Draw, exercise, PASS / MODIFIED / FAIL. '
          'Last player standing wins. Kings hit everyone; combos reward streaks.',
    ),
    (
      'casual',
      'Casual (Forgiving)',
      '5 lives, +1 armor and +1 skip to start. Modified reps score a bit more. '
          'Same rules as Standard — more room for mistakes while you learn.',
    ),
    (
      'battle',
      'Battle (Timer on)',
      '3 lives plus a countdown each turn (45s). Run out of time = FAIL. '
          'High pressure — great for fast sessions.',
    ),
    (
      'team',
      'Team mode',
      'Players split Red vs Black (alternating seats). A team wins when the other side has no '
          'active players left. Share the glory — Kings still challenge everyone.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyDefaultAvatars());
  }

  void _applyDefaultAvatars() {
    final def = context.read<GameController>().settings['defaultPlayerAvatarId']
            as String? ??
        AvatarCatalog.defaultPlayerAvatarId;
    setState(() {
      for (final s in _slots) {
        if (s.avatarId == AvatarCatalog.defaultPlayerAvatarId) {
          s.avatarId = def;
        }
      }
    });
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.controller.dispose();
    }
    super.dispose();
  }

  List<_SetupStep> _steps(bool pro) {
    final s = <_SetupStep>[_SetupStep.mode, _SetupStep.soloMulti];
    if (!_isSolo) s.add(_SetupStep.playerCount);
    s.add(_SetupStep.players);
    s.add(_SetupStep.abilityModifier);
    s.add(_SetupStep.houseRules);
    if (_isSolo || _npcCount > 0) {
      s.add(_isSolo ? _SetupStep.soloNpc : _SetupStep.multiNpc);
    }
    if (pro) s.add(_SetupStep.deck);
    return s;
  }

  bool _canAdvance(_SetupStep step) {
    if (step == _SetupStep.soloNpc && !_soloNpcReady) return false;
    if (step == _SetupStep.multiNpc &&
        _npcCount > 0 &&
        _multiNpcs.length < _npcCount) {
      return false;
    }
    return true;
  }

  void _next() {
    final pro = context.read<EntitlementService>().isPro;
    final steps = _steps(pro);
    final current = steps[_step.clamp(0, steps.length - 1)];
    if (!_canAdvance(current)) return;

    if (current == _SetupStep.abilityModifier &&
        _modifierPlayerIndex < _humanCount - 1) {
      setState(() => _modifierPlayerIndex++);
      return;
    }

    if (_step < steps.length - 1) {
      setState(() {
        if (current == _SetupStep.abilityModifier) {
          _modifierPlayerIndex = 0;
        }
        _step++;
      });
    } else {
      _startMatch();
    }
  }

  void _back() {
    final pro = context.read<EntitlementService>().isPro;
    final steps = _steps(pro);
    final current = steps[_step.clamp(0, steps.length - 1)];

    if (current == _SetupStep.abilityModifier && _modifierPlayerIndex > 0) {
      setState(() => _modifierPlayerIndex--);
      return;
    }

    if (_step > 0) {
      setState(() {
        _step--;
        final prev = steps[_step];
        if (prev == _SetupStep.abilityModifier) {
          _modifierPlayerIndex = _humanCount - 1;
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _startMatch() async {
    context.read<AudioService>().playSfx(SfxType.button);
    final game = context.read<GameController>();
    final mode = game.rules!.mode(_isSolo && _modeId != 'team' ? 'solo' : _modeId);
    final registry = NpcRegistry.instance;

    final players = _slots
        .take(_isSolo ? 1 : _playerCount)
        .map(
          (s) => GameController.newPlayer(
            s.controller.text.trim().isEmpty ? s.name : s.controller.text.trim(),
            GameController.playerColors[s.colorIndex],
            avatarId: s.avatarId,
            abilityModifierId: s.abilityModifierId,
          ),
        )
        .toList();

    if (_isSolo && _soloNpc != null) {
      players.add(registry.toPlayer(_soloNpc!, mode));
    } else if (!_isSolo) {
      for (final npc in _multiNpcs) {
        players.add(registry.toPlayer(npc, mode));
      }
    }

    if (_surpriseEntrant && _isSolo && players.length < 3) {
      players.add(registry.toPlayer(registry.pickSurprise(), mode));
    }

    final modeId = _isSolo && _modeId != 'team' ? 'solo' : _modeId;

    await game.updateSettings({
      'deckArtStyle': _deckArt.storageKey,
      'defaultPlayerAvatarId': _slots.first.avatarId,
    });
    await game.startMatch(
      modeId: modeId,
      players: players,
      deckArtStyle: _deckArt,
      lightDeck: _lightDeck,
      houseRules: _houseRules,
    );

    if (!mounted) return;
    final modeName = game.currentMode?.name ?? 'Match';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MatchIntroScreen(modeName: modeName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pro = context.watch<EntitlementService>().isPro;
    final steps = _steps(pro);
    final current = steps[_step.clamp(0, steps.length - 1)];

    return MusicScopeHost(
      scope: MusicScope.title,
      proTitle: pro,
      child: Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(current)),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / steps.length,
            color: AppTheme.arenaRed,
            backgroundColor: Colors.white12,
          ),
          Expanded(child: _buildStep(current)),
          SetupNavBar(
            showBack: true,
            isFinalStep: _step == steps.length - 1,
            onBack: _back,
            onNext: _canAdvance(current) ? _next : () {},
          ),
        ],
      ),
    ),
    );
  }

  String _titleFor(_SetupStep step) => switch (step) {
        _SetupStep.mode => 'GAME MODE',
        _SetupStep.soloMulti => 'SOLO OR MULTIPLAYER',
        _SetupStep.playerCount => 'HUMAN PLAYERS',
        _SetupStep.players => 'PLAYER NAMES',
        _SetupStep.abilityModifier => 'ABILITY MODIFIER',
        _SetupStep.houseRules => 'TABLE RULES (OPTIONAL)',
        _SetupStep.soloNpc => 'OPPONENT',
        _SetupStep.multiNpc => 'NPC FIGHTERS',
        _SetupStep.deck => 'CARD DECK',
      };

  Widget _buildStep(_SetupStep step) => switch (step) {
        _SetupStep.mode => _modeStep(),
        _SetupStep.soloMulti => _soloMultiStep(),
        _SetupStep.playerCount => _countStep(),
        _SetupStep.players => _playersStep(),
        _SetupStep.abilityModifier => _abilityModifierStep(),
        _SetupStep.houseRules => _houseRulesStep(),
        _SetupStep.soloNpc => _soloNpcStep(),
        _SetupStep.multiNpc => _multiNpcStep(),
        _SetupStep.deck => _deckStep(),
      };

  Widget _modeStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._modes.map(
          (m) => RadioListTile<String>(
            title: Text(m.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(m.$3, style: const TextStyle(height: 1.35)),
            value: m.$1,
            groupValue: _modeId,
            activeColor: AppTheme.arenaRed,
            onChanged: (v) => setState(() => _modeId = v!),
          ),
        ),
        const Divider(height: 32),
        SwitchListTile(
          title: const Text('Light weights deck'),
          subtitle: const Text('26 cards (2–7 + jokers) for shorter games'),
          value: _lightDeck,
          activeColor: AppTheme.arenaRed,
          onChanged: (v) => setState(() => _lightDeck = v),
        ),
      ],
    );
  }

  Widget _soloMultiStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _choiceTile(
            title: 'SOLO',
            subtitle: 'You vs a random NPC opponent (shuffle pick)',
            selected: _isSolo,
            onTap: () => setState(() => _isSolo = true),
          ),
          const SizedBox(height: 12),
          _choiceTile(
            title: 'MULTIPLAYER',
            subtitle: 'Humans pass-and-play; add up to 6 NPCs total',
            selected: !_isSolo,
            onTap: () => setState(() {
              _isSolo = false;
              _playerCount = _playerCount.clamp(1, 6);
              _syncNpcCount();
            }),
          ),
        ],
      ),
    );
  }

  void _syncNpcCount() {
    final maxNpc = (6 - _playerCount).clamp(0, 6);
    if (_npcCount > maxNpc) _npcCount = maxNpc;
    while (_multiNpcs.length > _npcCount) {
      _multiNpcs.removeLast();
    }
  }

  Widget _countStep() {
    _syncNpcCount();
    final maxNpc = 6 - _playerCount;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '$_playerCount HUMAN${_playerCount == 1 ? '' : 'S'}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          Slider(
            value: _playerCount.toDouble(),
            min: 1,
            max: 6,
            divisions: 5,
            label: '$_playerCount',
            activeColor: AppTheme.arenaRed,
            onChanged: (v) => setState(() {
              _playerCount = v.round();
              _syncSlots();
              _syncNpcCount();
            }),
          ),
          const SizedBox(height: 24),
          Text(
            '$_npcCount NPC${_npcCount == 1 ? '' : 'S'}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            'Up to $maxNpc NPCs (${_playerCount + _npcCount}/6 players). '
            'Each NPC is chosen with a shuffle on the next screen.',
            style: const TextStyle(color: Colors.white54, height: 1.35),
            textAlign: TextAlign.center,
          ),
          Slider(
            value: _npcCount.toDouble(),
            min: 0,
            max: maxNpc.toDouble(),
            divisions: maxNpc > 0 ? maxNpc : 1,
            label: '$_npcCount',
            activeColor: AppTheme.arenaRed,
            onChanged: maxNpc == 0
                ? null
                : (v) => setState(() {
                      _npcCount = v.round();
                      _trimMultiNpcs();
                    }),
          ),
        ],
      ),
    );
  }

  void _trimMultiNpcs() {
    while (_multiNpcs.length > _npcCount) {
      _multiNpcs.removeLast();
    }
  }

  void _syncSlots() {
    final count = _isSolo ? 1 : _playerCount;
    while (_slots.length < count) {
      final def = context.read<GameController>().settings['defaultPlayerAvatarId']
              as String? ??
          AvatarCatalog.defaultPlayerAvatarId;
      _slots.add(_Slot(
        name: 'Player ${_slots.length + 1}',
        colorIndex: _slots.length % GameController.playerColors.length,
        avatarId: _slots.isNotEmpty ? _slots.first.avatarId : def,
      ));
    }
    while (_slots.length > count) {
      _slots.removeLast().controller.dispose();
    }
  }

  Widget _abilityModifierStep() {
    final slot = _slots[_modifierPlayerIndex];
    final name =
        slot.controller.text.trim().isEmpty ? slot.name : slot.controller.text.trim();
    final color = GameController.playerColors[slot.colorIndex];
    final isLast = _modifierPlayerIndex >= _humanCount - 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'PLAYER ${_modifierPlayerIndex + 1} OF $_humanCount',
          style: const TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            PlayerAvatar(
              assetPath: AvatarCatalog.instance.assetForId(slot.avatarId),
              borderColor: color,
              size: 52,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const Text(
                    'Choose how this player experiences the match.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Modifiers affect only this player — everyone can play at their own level.',
          style: TextStyle(color: Colors.amberAccent, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ...AbilityModifiers.configs.map((mod) {
          final selected = slot.abilityModifierId == mod.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selected
                  ? AppTheme.arenaRed.withValues(alpha: 0.2)
                  : AppTheme.arenaGray,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => setState(() => slot.abilityModifierId = mod.id),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppTheme.arenaRed : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mod.name.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mod.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Tap NEXT for the next player\'s modifier.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _houseRulesStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Optional table rules for everyone. Skip anything you don\'t need.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 16),
        const Text(
          'WIN CONDITION',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.arenaRed,
            letterSpacing: 1,
          ),
        ),
        ...[
          ('elimination', 'Elimination', 'Last player with lives wins'),
          ('points', 'Highest score', 'Most points when deck ends'),
          ('cards', 'Most cards', 'Most completed cards when deck ends'),
        ].map(
          (o) => RadioListTile<String>(
            title: Text(o.$2),
            subtitle: Text(o.$3),
            value: o.$1,
            groupValue: _houseRules.winCondition,
            activeColor: AppTheme.arenaRed,
            onChanged: (v) => setState(
              () => _houseRules = MatchHouseRules(
                winCondition: v!,
                forceTimerOff: _houseRules.forceTimerOff,
                jokerRule: _houseRules.jokerRule,
                kingRule: _houseRules.kingRule,
              ),
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Turn timer off (all players)'),
          value: _houseRules.forceTimerOff,
          activeColor: AppTheme.arenaRed,
          onChanged: (v) => setState(
            () => _houseRules = MatchHouseRules(
              winCondition: _houseRules.winCondition,
              forceTimerOff: v,
              jokerRule: _houseRules.jokerRule,
              kingRule: _houseRules.kingRule,
            ),
          ),
        ),
        const Divider(height: 24),
        const Text(
          'JOKERS',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.arenaRed),
        ),
        ...[
          ('default', 'Standard', 'Default joker behavior'),
          ('rest', 'Rest', 'Joker grants +1 skip (recovery)'),
          ('gentle', 'Gentle group', 'Softer group challenge, solo-friendly'),
        ].map(
          (o) => RadioListTile<String>(
            title: Text(o.$2),
            subtitle: Text(o.$3),
            value: o.$1,
            groupValue: _houseRules.jokerRule,
            activeColor: AppTheme.arenaRed,
            onChanged: (v) => setState(
              () => _houseRules = MatchHouseRules(
                winCondition: _houseRules.winCondition,
                forceTimerOff: _houseRules.forceTimerOff,
                jokerRule: v!,
                kingRule: _houseRules.kingRule,
              ),
            ),
          ),
        ),
        const Divider(height: 24),
        const Text(
          'KINGS',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.arenaRed),
        ),
        RadioListTile<String>(
          title: const Text('Group challenge'),
          subtitle: const Text('Everyone does the King (each with their own reps)'),
          value: 'default',
          groupValue: _houseRules.kingRule,
          activeColor: AppTheme.arenaRed,
          onChanged: (v) => setState(
            () => _houseRules = MatchHouseRules(
              winCondition: _houseRules.winCondition,
              forceTimerOff: _houseRules.forceTimerOff,
              jokerRule: _houseRules.jokerRule,
              kingRule: v!,
            ),
          ),
        ),
        RadioListTile<String>(
          title: const Text('Solo King'),
          subtitle: const Text('Only the drawer performs the King challenge'),
          value: 'optional_group',
          groupValue: _houseRules.kingRule,
          activeColor: AppTheme.arenaRed,
          onChanged: (v) => setState(
            () => _houseRules = MatchHouseRules(
              winCondition: _houseRules.winCondition,
              forceTimerOff: _houseRules.forceTimerOff,
              jokerRule: _houseRules.jokerRule,
              kingRule: v!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _playersStep() {
    _syncSlots();
    final count = _isSolo ? 1 : _playerCount;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (_, i) {
        final slot = _slots[i];
        return Card(
          color: AppTheme.arenaGray,
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: slot.controller,
                  decoration: InputDecoration(labelText: 'Player ${i + 1}'),
                ),
                const SizedBox(height: 10),
                AvatarPickerRow(
                  selectedId: slot.avatarId,
                  borderColor: GameController.playerColors[slot.colorIndex],
                  onSelected: (id) => setState(() => slot.avatarId = id),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: List.generate(
                    GameController.playerColors.length,
                    (ci) => GestureDetector(
                      onTap: () => setState(() => slot.colorIndex = ci),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: GameController.playerColors[ci],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: slot.colorIndex == ci
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _soloNpcStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NpcShufflePicker(
          allowSurprise: _surpriseEntrant,
          onSelected: (p) => setState(() {
            _soloNpc = p;
            _soloNpcReady = true;
          }),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Allow surprise entrant'),
          subtitle: const Text('Rare chance Nova joins mid-setup'),
          value: _surpriseEntrant,
          activeColor: AppTheme.arenaRed,
          onChanged: (v) => setState(() => _surpriseEntrant = v),
        ),
        if (_soloNpcReady && _soloNpc != null)
          TextButton(
            onPressed: () => showNpcProfileDialog(context, _soloNpc!),
            child: const Text('READ OPPONENT PROFILE'),
          ),
      ],
    );
  }

  Widget _multiNpcStep() {
    _trimMultiNpcs();

    if (_npcCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No NPCs selected — go back to add fighters, or tap NEXT for humans only.',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final shuffling = _multiNpcs.length < _npcCount;
    final slot = _multiNpcs.length + 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_multiNpcs.isNotEmpty) ...[
          Text(
            'LOCKED IN (${_multiNpcs.length}/$_npcCount)',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.arenaRed,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_multiNpcs.length, (i) {
            final npc = _multiNpcs[i];
            return Card(
              color: AppTheme.arenaGray,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: NpcAvatar(profile: npc, size: 44),
                title: Text('${i + 1}. ${npc.name}'),
                subtitle: Text(
                  '${npc.age} · ${npc.job}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Reshuffle from this slot',
                      onPressed: () => setState(
                        () => _multiNpcs.removeRange(i, _multiNpcs.length),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: () => showNpcProfileDialog(context, npc),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (shuffling) ...[
          NpcShufflePicker(
            key: ValueKey(
              'npc_shuffle_${_multiNpcs.length}_${_multiNpcs.map((e) => e.id).join('_')}',
            ),
            excludeIds: _multiNpcs.map((e) => e.id).toSet(),
            slotLabel: '$slot of $_npcCount',
            onSelected: (p) => setState(() => _multiNpcs.add(p)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Next shuffle starts automatically when this one finishes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Text(
            'All NPC fighters ready. Tap NEXT to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(_multiNpcs.clear),
            icon: const Icon(Icons.shuffle),
            label: const Text('RESHUFFLE ALL NPCs'),
          ),
        ],
      ],
    );
  }

  Widget _deckStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _choiceTile(
            title: 'DEFAULT DECK',
            subtitle: 'Full illustrated card art',
            selected: _deckArt == DeckArtStyle.defaultArt,
            onTap: () => setState(() => _deckArt = DeckArtStyle.defaultArt),
          ),
          const SizedBox(height: 12),
          _choiceTile(
            title: 'CUSTOM TEMPLATE DECK',
            subtitle: 'Suit templates + rank numbers (Pro)',
            selected: _deckArt == DeckArtStyle.customTemplate,
            onTap: () =>
                setState(() => _deckArt = DeckArtStyle.customTemplate),
          ),
        ],
      ),
    );
  }

  Widget _choiceTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? AppTheme.arenaRed.withValues(alpha: 0.2)
          : AppTheme.arenaGray,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.arenaRed : Colors.white24,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SetupStep {
  mode,
  soloMulti,
  playerCount,
  players,
  abilityModifier,
  houseRules,
  soloNpc,
  multiNpc,
  deck,
}

class _Slot {
  String name;
  int colorIndex;
  String avatarId;
  String abilityModifierId;
  late final TextEditingController controller;

  _Slot({
    required this.name,
    required this.colorIndex,
    String? avatarId,
    String? abilityModifierId,
  })  : avatarId = avatarId ?? AvatarCatalog.defaultPlayerAvatarId,
        abilityModifierId = abilityModifierId ?? AbilityModifierId.standard {
    controller = TextEditingController(text: name);
  }
}
