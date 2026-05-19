"""Copy NPC PICTURES/*.PNG into assets/images/npcs/{profile_id}.png"""
import json
import shutil
from pathlib import Path

root = Path(__file__).resolve().parent.parent
src_dir = root / "NPC PICTURES"
dst_dir = root / "assets" / "images" / "npcs"
profiles_path = root / "assets" / "data" / "npc_profiles.json"

# Filename (uppercase stem) -> profile id
FILE_TO_ID = {
    "ANTON": "anton_40",
    "MIA": "mia_12",
    "ROSA": "rosa_67",
    "DEREK": "derek_28",
    "JIN": "jin_19",
    "CARMEN": "carmen_35",
    "TYLER": "tyler_16",
    "GRACE": "grace_52",
    "OMAR": "omar_45",
    "LILY": "lily_9",
    "VIC": "vic_31",
    "ELENA": "elena_24",
    "FRANK": "frank_58",
    "ZOE": "zoe_22",
    "SAM": "sam_70",
    "NOVA": "nova_27",
    "REX": "rex_43",
    "MILO": "milo_34",
    "BROCK": "brock_26",
    "IRIS": "iris_38",
    "COLE": "cole_33",
    "HANK": "hank_49",
    "ZION": "zion_41",
    "BIIG MOE": "bigmoe_37",
    "BIG MOE": "bigmoe_37",
    "DEVIN": "devin_21",
    "TRISH": "trish_42",
    "MARCUS": "marcus_47",
    "NINA": "nina_29",
    "SASHA": "sasha_31",
    # Unlabeled descriptions (best-guess mapping for sync)
    "CAR MECHANIC THAT LIKES FAST CARS": "frank_58",
    "ELDERLY HBP FEMALE": None,
}

data = json.loads(profiles_path.read_text(encoding="utf-8"))
all_ids = {p["id"] for p in data["profiles"]}

dst_dir.mkdir(parents=True, exist_ok=True)
copied = []
skipped = []
unmapped_files = []
unmapped_profiles = set(all_ids)

if not src_dir.exists():
    print(f"Missing folder: {src_dir}")
    raise SystemExit(1)

seen = set()
for path in sorted(src_dir.iterdir()):
    if path.suffix.upper() != ".PNG" or not path.is_file():
        continue
    if path.name.upper() in seen:
        continue
    seen.add(path.name.upper())
    key = path.stem.upper()
    npc_id = FILE_TO_ID.get(key)
    if npc_id is None:
        unmapped_files.append(path.name)
        continue
    if npc_id not in all_ids:
        skipped.append(f"{path.name} -> unknown id {npc_id}")
        continue
    dest = dst_dir / f"{npc_id}.png"
    shutil.copy2(path, dest)
    copied.append(f"{path.name} -> {npc_id}.png")
    unmapped_profiles.discard(npc_id)

# Generic player portrait
avatars_dir = root / "assets" / "images" / "avatars"
avatars_dir.mkdir(parents=True, exist_ok=True)
player_src = root / "1 player.PNG"
if player_src.exists():
    shutil.copy2(player_src, avatars_dir / "player_default.png")
    copied.append("1 player.PNG -> avatars/player_default.png")

print(f"Copied {len(copied)} images to assets/")
for line in copied:
    print(" ", line)

if unmapped_files:
    print("\nUnmapped files (no profile id):")
    for f in unmapped_files:
        print(" ", f)

if unmapped_profiles:
    print("\nProfiles missing portrait files:")
    for pid in sorted(unmapped_profiles):
        print(" ", pid)
