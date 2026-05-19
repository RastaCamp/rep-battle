import '../core/data/asset_paths.dart';
import 'npc_registry.dart';

class AvatarEntry {
  final String id;
  final String asset;
  final String label;

  const AvatarEntry({
    required this.id,
    required this.asset,
    required this.label,
  });
}

/// Resolves portrait paths for humans and NPCs.
class AvatarCatalog {
  static AvatarCatalog? _instance;
  static AvatarCatalog get instance => _instance ??= AvatarCatalog._();

  AvatarCatalog._();

  static const defaultPlayerAvatarId = 'player_default';

  final List<AvatarEntry> _playerAvatars = [
    const AvatarEntry(
      id: defaultPlayerAvatarId,
      asset: 'assets/images/avatars/player_default.png',
      label: 'Fighter',
    ),
  ];

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    await NpcRegistry.instance.load();
    _loaded = true;
  }

  List<AvatarEntry> get playerAvatars => List.unmodifiable(_playerAvatars);

  List<AvatarEntry> get allSelectable {
    final list = <AvatarEntry>[..._playerAvatars];
    for (final p in NpcRegistry.instance.all) {
      list.add(
        AvatarEntry(
          id: 'npc:${p.id}',
          asset: AssetPaths.npcPortrait(p.id),
          label: p.name,
        ),
      );
    }
    return list;
  }

  String assetForId(String? avatarId) {
    if (avatarId == null || avatarId.isEmpty) {
      return _playerAvatars.first.asset;
    }
    if (avatarId.startsWith('npc:')) {
      return AssetPaths.npcPortrait(avatarId.substring(4));
    }
    for (final e in _playerAvatars) {
      if (e.id == avatarId) return e.asset;
    }
    return AssetPaths.npcPortrait(avatarId);
  }

  String assetForPlayer({
    String? avatarAsset,
    String? avatarId,
    String? npcProfileId,
  }) {
    if (avatarAsset != null && avatarAsset.isNotEmpty) return avatarAsset;
    if (avatarId != null && avatarId.isNotEmpty) {
      return assetForId(avatarId);
    }
    if (npcProfileId != null) {
      return AssetPaths.npcPortrait(npcProfileId);
    }
    return _playerAvatars.first.asset;
  }

  String? labelForId(String? avatarId) {
    if (avatarId == null) return null;
    for (final e in allSelectable) {
      if (e.id == avatarId) return e.label;
    }
    return null;
  }
}
