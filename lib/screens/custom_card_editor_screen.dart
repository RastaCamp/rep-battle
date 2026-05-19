import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/data/asset_paths.dart';
import '../core/models/game_card.dart';
import '../services/custom_card_service.dart';
import '../services/entitlement_service.dart';
import '../widgets/arena_button.dart';
import '../widgets/card_face_painter.dart';

class CustomCardEditorScreen extends StatefulWidget {
  const CustomCardEditorScreen({super.key});

  @override
  State<CustomCardEditorScreen> createState() => _CustomCardEditorScreenState();
}

class _CustomCardEditorScreenState extends State<CustomCardEditorScreen> {
  String _suit = 'spades';
  String _rank = 'ace';
  String? _savedPreviewPath;
  Uint8List? _pickedBytes;
  final _exerciseController = TextEditingController();
  final _repsController = TextEditingController(text: '10');

  static const _suits = ['spades', 'hearts', 'clubs', 'diamonds'];
  static const _ranks = [
    'ace',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'jack',
    'queen',
    'king',
  ];

  String get _cardId => '${_suit}_$_rank';

  String get _rankLabel {
    if (_rank == 'ace') return 'A';
    if (_rank == 'jack') return 'J';
    if (_rank == 'queen') return 'Q';
    if (_rank == 'king') return 'K';
    return _rank;
  }

  GameCard _buildPreviewCard({String? imagePath}) => GameCard(
        id: _cardId,
        suit: CardSuit.values.byName(_suit),
        rank: _rankLabel,
        exerciseId: 'custom',
        exerciseName: _exerciseController.text.isEmpty
            ? 'Custom Challenge'
            : _exerciseController.text,
        reps: int.tryParse(_repsController.text),
        cardType: CardType.custom,
        imageAsset: AssetPaths.suitCustomTemplate(_suit),
        useSuitTemplate: true,
        customImagePath: imagePath,
      );

  @override
  void dispose() {
    _exerciseController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _pickedBytes = file.bytes;
      _savedPreviewPath = null;
    });
  }

  Future<void> _save() async {
    final ent = context.read<EntitlementService>();
    if (!ent.isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pro required for custom cards')),
      );
      return;
    }
    if (_pickedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload an image first')),
      );
      return;
    }

    final service = context.read<CustomCardService>();
    final path = await service.saveImageBytes(_cardId, _pickedBytes!);
    await service.setOverride(CustomCardOverride(
      cardId: _cardId,
      imagePath: path,
      exerciseName:
          _exerciseController.text.isEmpty ? null : _exerciseController.text,
      reps: int.tryParse(_repsController.text),
      exerciseId: 'custom',
    ));

    setState(() {
      _savedPreviewPath = path;
      _pickedBytes = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved $_cardId — one deck slot updated')),
      );
    }
  }

  Future<void> _remove() async {
    await context.read<CustomCardService>().removeOverride(_cardId);
    setState(() {
      _savedPreviewPath = null;
      _pickedBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CustomCardService>();
    final existing = service.overrides[_cardId];
    final previewPath = _savedPreviewPath ?? existing?.imagePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CUSTOM CARD CREATOR'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Uses suit custom template art. Rank & suit are added in-app. '
            'Your image fills the center. Each save replaces that one card in the deck.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _suit,
                  decoration: const InputDecoration(labelText: 'Suit'),
                  items: _suits
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _suit = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _rank,
                  decoration: const InputDecoration(labelText: 'Rank'),
                  items: _ranks
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _rank = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _exerciseController,
            decoration: const InputDecoration(labelText: 'Exercise (optional)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _repsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Reps (optional)'),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 180,
              height: 252,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CardFacePainter(
                      card: _buildPreviewCard(imagePath: previewPath),
                      customCardService: service,
                    ),
                    if (_pickedBytes != null)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_pickedBytes!, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ArenaButton(label: 'UPLOAD IMAGE', onPressed: _pickImage),
          const SizedBox(height: 12),
          ArenaButton(
            label: 'SAVE CARD',
            glowColor: Colors.amber,
            onPressed: _save,
          ),
          if (existing != null) ...[
            const SizedBox(height: 12),
            ArenaButton(label: 'REMOVE OVERRIDE', onPressed: _remove),
          ],
          const SizedBox(height: 24),
          Text(
            'Saved overrides: ${service.overrides.length}',
            style: const TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
