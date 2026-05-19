import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../controllers/game_controller.dart';
import '../controllers/quest_controller.dart';
import '../services/entitlement_service.dart';
import '../core/models/ability_modifier.dart';
import '../core/models/npc_profile.dart';
import '../core/models/quest/quest_player_state.dart';
import '../widgets/player_avatar.dart';
import '../core/theme/app_theme.dart';
import '../core/music/music_scope.dart';
import '../services/audio_service.dart';
import '../widgets/music_scope_host.dart';
import '../services/avatar_catalog.dart';
import '../services/npc_registry.dart';
import '../services/quest_data_loader.dart' show QuestDataBundle;
import '../widgets/avatar_picker_row.dart';
import '../widgets/npc_avatar.dart';
import '../widgets/npc_profile_dialog.dart';
import '../widgets/npc_shuffle_picker.dart';
import '../widgets/setup_nav_bar.dart';
import 'quest_game_screen.dart';

class QuestSetupScreen extends StatefulWidget {
  const QuestSetupScreen({super.key});

  @override
  State<QuestSetupScreen> createState() => _QuestSetupScreenState();
}

class _QuestSetupScreenState extends State<QuestSetupScreen> {
  int _step = 0;
  int _playerCount = 1;
  int _npcCount = 0;
  int _modifierPlayerIndex = 0;
  String _difficultyId = 'normal';
  String _dungeonId = 'rust_arena';
  final List<NpcProfile> _npcs = [];
  final List<_QSlot> _slots = List.generate(
    6,
    (i) => _QSlot(
      name: 'Player ${i + 1}',
      colorIndex: i % GameController.playerColors.length,
    ),
  );

  int get _maxNpc => (6 - _playerCount).clamp(0, 6);

  @override
  void initState() {
    super.initState();
    NpcRegistry.instance.load();
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.controller.dispose();
    }
    super.dispose();
  }

  int get _humanCount => _playerCount;

  List<_SetupStep> get _steps {
    final s = <_SetupStep>[_SetupStep.party, _SetupStep.modifiers, _SetupStep.npcs];
    if (_npcCount > 0) s.add(_SetupStep.npcPick);
    s.addAll([_SetupStep.difficulty, _SetupStep.dungeon]);
    return s;
  }

  bool _canAdvance(_SetupStep step) {
    if (step == _SetupStep.npcPick && _npcs.length < _npcCount) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final ent = context.watch<EntitlementService>();
    final questUnlocked =
        ent.canAccessQuest(firstDeckComplete: game.firstDeckComplete);
    if (!questUnlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QUEST MODE'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.white38),
                const SizedBox(height: 16),
                const Text(
                  'Quest Mode is locked',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Play through an entire deck in Play Mode, or unlock Pro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('BACK'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final quest = context.watch<QuestController>();
    final bundle = quest.data;
    final steps = _steps;
    final current = steps[_step.clamp(0, steps.length - 1)];

    return MusicScopeHost(
      scope: MusicScope.questSetup,
      child: Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(current)),
        backgroundColor: Colors.transparent,
      ),
      body: bundle == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                LinearProgressIndicator(
                  value: (_step + 1) / steps.length,
                  color: AppTheme.arenaRed,
                  backgroundColor: Colors.white12,
                ),
                Expanded(child: _buildStep(bundle, current)),
                SetupNavBar(
                  showBack: _step > 0,
                  isFinalStep: _step >= steps.length - 1,
                  onBack: _back,
                  onNext: _canAdvance(current) ? _next : () {},
                ),
              ],
            ),
    ),
    );
  }

  String _titleFor(_SetupStep step) => switch (step) {
        _SetupStep.party => 'PARTY',
        _SetupStep.modifiers => 'ABILITY MODIFIER',
        _SetupStep.npcs => 'NPC ALLIES',
        _SetupStep.npcPick => 'PICK ALLIES',
        _SetupStep.difficulty => 'DIFFICULTY',
        _SetupStep.dungeon => 'DUNGEON',
      };

  Widget _buildStep(QuestDataBundle bundle, _SetupStep step) {
    return switch (step) {
      _SetupStep.party => _partyStep(),
      _SetupStep.modifiers => _modifierStep(),
      _SetupStep.npcs => _npcCountStep(),
      _SetupStep.npcPick => _npcPickStep(),
      _SetupStep.difficulty => _difficultyStep(bundle.difficulties),
      _SetupStep.dungeon => _dungeonStep(bundle.dungeons),
    };
  }

  Widget _partyStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Who is delving the dungeon? Up to 6 humans pass-and-play.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 12),
        Text(
          '$_playerCount HUMAN${_playerCount == 1 ? '' : 'S'}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
            _syncNpcCount();
          }),
        ),
        const SizedBox(height: 8),
        ...List.generate(_playerCount, (i) {
          final slot = _slots[i];
          final color = GameController.playerColors[slot.colorIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: slot.controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Player ${i + 1}',
                    labelStyle: TextStyle(color: color),
                    filled: true,
                    fillColor: AppTheme.arenaGray,
                  ),
                ),
                const SizedBox(height: 8),
                AvatarPickerRow(
                  selectedId: slot.avatarId,
                  borderColor: color,
                  onSelected: (id) => setState(() => slot.avatarId = id),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _npcCountStep() {
    _syncNpcCount();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Add NPC allies to your party (optional). They fight beside you using the same card rules.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 16),
        Text(
          '$_npcCount NPC ALL${_npcCount == 1 ? 'Y' : 'IES'}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(
          'Up to $_maxNpc (${_playerCount + _npcCount}/6 party members).',
          style: const TextStyle(color: Colors.white54),
        ),
        Slider(
          value: _npcCount.toDouble(),
          min: 0,
          max: _maxNpc.toDouble(),
          divisions: _maxNpc > 0 ? _maxNpc : 1,
          label: '$_npcCount',
          activeColor: AppTheme.arenaRed,
          onChanged: _maxNpc == 0
              ? null
              : (v) => setState(() {
                    _npcCount = v.round();
                    while (_npcs.length > _npcCount) {
                      _npcs.removeLast();
                    }
                  }),
        ),
      ],
    );
  }

  Widget _npcPickStep() {
    while (_npcs.length > _npcCount) {
      _npcs.removeLast();
    }

    if (_npcCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No NPC allies — tap NEXT to continue with humans only.',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final shuffling = _npcs.length < _npcCount;
    final slot = _npcs.length + 1;
    final exclude = _npcs.map((n) => n.id).toSet();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_npcs.isNotEmpty) ...[
          Text(
            'LOCKED IN (${_npcs.length}/$_npcCount)',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.arenaRed,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_npcs.length, (i) {
            final npc = _npcs[i];
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
                        () => _npcs.removeRange(i, _npcs.length),
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
          Text(
            'ALLY $slot OF $_npcCount',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          NpcShufflePicker(
            key: ValueKey(
              'quest_npc_${_npcs.length}_${_npcs.map((e) => e.id).join('_')}',
            ),
            slotLabel: 'Shuffle for ally $slot',
            excludeIds: exclude,
            onSelected: (profile) => setState(() => _npcs.add(profile)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Next shuffle starts automatically when this one finishes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ] else ...[
          const Text(
            'All allies ready. Tap NEXT to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(_npcs.clear),
            icon: const Icon(Icons.shuffle),
            label: const Text('RESHUFFLE ALL ALLIES'),
          ),
        ],
      ],
    );
  }

  Widget _difficultyStep(List difficulties) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Choose difficulty', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        ...difficulties.map<Widget>((d) {
          final sel = _difficultyId == d.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: sel ? AppTheme.arenaRed.withValues(alpha: 0.2) : AppTheme.arenaGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: sel ? AppTheme.arenaRed : Colors.white24),
              ),
              title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('${d.playerHp} HP start · enemies ×${d.enemyHpMult}'),
              onTap: () => setState(() => _difficultyId = d.id),
            ),
          );
        }),
      ],
    );
  }

  Widget _dungeonStep(List dungeons) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Each room = draw a card. Exercise success attacks; fail = enemy hits you.',
          style: TextStyle(color: Colors.amberAccent, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...dungeons.map<Widget>((d) {
          final sel = _dungeonId == d.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: sel ? AppTheme.arenaRed.withValues(alpha: 0.2) : AppTheme.arenaGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: sel ? AppTheme.arenaRed : Colors.white24),
              ),
              title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(d.subtitle),
              onTap: () => setState(() => _dungeonId = d.id),
            ),
          );
        }),
      ],
    );
  }

  void _syncNpcCount() {
    final maxNpc = (6 - _playerCount).clamp(0, 6);
    if (_npcCount > maxNpc) _npcCount = maxNpc;
    while (_npcs.length > _npcCount) {
      _npcs.removeLast();
    }
  }

  Widget _modifierStep() {
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
              child: Text(
                name.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...AbilityModifiers.configs.map((mod) {
          final selected = slot.abilityModifierId == mod.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor:
                  selected ? AppTheme.arenaRed.withValues(alpha: 0.2) : AppTheme.arenaGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: selected ? AppTheme.arenaRed : Colors.white24),
              ),
              title: Text(mod.name, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(mod.subtitle),
              onTap: () => setState(() => slot.abilityModifierId = mod.id),
            ),
          );
        }),
        if (!isLast)
          const Text(
            'NEXT goes to the next player\'s modifier.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
      ],
    );
  }

  void _back() {
    final steps = _steps;
    final current = steps[_step.clamp(0, steps.length - 1)];
    if (current == _SetupStep.modifiers && _modifierPlayerIndex > 0) {
      setState(() => _modifierPlayerIndex--);
      return;
    }
    if (_step > 0) {
      setState(() {
        _step--;
        if (steps[_step] == _SetupStep.modifiers) {
          _modifierPlayerIndex = _humanCount - 1;
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _next() async {
    context.read<AudioService>().playSfx(SfxType.button);
    final steps = _steps;
    final current = steps[_step.clamp(0, steps.length - 1)];

    if (current == _SetupStep.modifiers &&
        _modifierPlayerIndex < _humanCount - 1) {
      setState(() => _modifierPlayerIndex++);
      return;
    }

    if (_step < steps.length - 1) {
      setState(() {
        if (current == _SetupStep.modifiers) {
          _modifierPlayerIndex = 0;
        }
        _step++;
      });
      return;
    }

    final quest = context.read<QuestController>();
    final registry = NpcRegistry.instance;
    final diff = quest.data!.difficulty(_difficultyId);
    final players = <QuestPlayerState>[];

    for (var i = 0; i < _playerCount; i++) {
      final s = _slots[i];
      final name =
          s.controller.text.trim().isEmpty ? s.name : s.controller.text.trim();
      final color = GameController.playerColors[s.colorIndex];
      players.add(
        QuestPlayerState(
          id: const Uuid().v4(),
          name: name,
          colorValue: color.value,
          avatarId: s.avatarId,
          hp: diff.playerHp,
          maxHp: diff.playerHp,
          abilityModifierId: s.abilityModifierId,
        ),
      );
    }

    var colorIdx = _playerCount;
    for (final npc in _npcs) {
      final color = GameController
          .playerColors[colorIdx % GameController.playerColors.length];
      colorIdx++;
      players.add(
        registry.toQuestPlayer(npc, hp: diff.playerHp, colorValue: color.value),
      );
    }

    await quest.startRun(
      dungeonId: _dungeonId,
      difficultyId: _difficultyId,
      players: players,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const QuestGameScreen()),
    );
  }
}

enum _SetupStep { party, modifiers, npcs, npcPick, difficulty, dungeon }

class _QSlot {
  String name;
  int colorIndex;
  String avatarId;
  String abilityModifierId;
  late final TextEditingController controller;

  _QSlot({
    required this.name,
    required this.colorIndex,
    String? avatarId,
    this.abilityModifierId = AbilityModifierId.standard,
  })  : avatarId = avatarId ?? AvatarCatalog.defaultPlayerAvatarId {
    controller = TextEditingController(text: name);
  }
}
