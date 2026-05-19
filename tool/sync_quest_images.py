"""Sync quest art from quest/ into assets/images/quest and rebuild manifest."""
import json
import re
import shutil
from pathlib import Path

root = Path(__file__).resolve().parent.parent
src_dir = root / "quest"
dst = root / "assets" / "images" / "quest"
manifest_path = root / "assets" / "data" / "quest_assets_manifest.json"

FILE_TO_DEST = {
    "rust goblin": "rust_goblin.png",
    "dust sprite": "dust_sprite.png",
    "iron rat": "iron_rat.png",
    "iron brute": "iron_brute.png",
    "room type combat": "room_combat.png",
    "room type rest": "room_rest.png",
    "room type trap": "room_trap.png",
    "room type treasure": "room_treasure.png",
    "room type boss": "room_boss.png",
    "loot item protien shake": "protein_shake.png",
    "loot item skip token": "skip_token.png",
    "loot item armor": "armor_plate.png",
    "loot item lucky card": "lucky_card.png",
    "loot item combo charm": "combo_charm.png",
    "loot item crown of kings": "crown_of_kings.png",
    "loot item titan heart": "titan_heart.png",
    "backpack items 1 lucky card": "ui_lucky_card.png",
    "backpack items 1 skip": "ui_skip.png",
    "backpack items 2 protein shakes": "ui_protein_shake.png",
    "backpack items relic slot": "ui_relic_slot.png",
    "inventory bag": "inventory_bag.png",
    "map": "map.png",
}


def slugify(stem: str) -> str:
    s = stem.lower().strip()
    s = re.sub(r"\s*-\s*copy\s*$", "", s, flags=re.I)
    s = re.sub(r"[^a-z0-9]+", "_", s)
    return s.strip("_")


def parse_type(stem: str) -> str | None:
    lower = stem.lower()
    for t in ("combat", "trap", "treasure", "rest", "boss"):
        if lower.startswith(t):
            return t
    return None


def collect_pngs(folder: Path) -> list[Path]:
    if not folder.is_dir():
        return []
    return sorted(
        p for p in folder.rglob("*") if p.is_file() and p.suffix.upper() == ".PNG"
    )


dst.mkdir(parents=True, exist_ok=True)
(dst / "locations").mkdir(exist_ok=True)
(dst / "rooms").mkdir(exist_ok=True)

locations = []
rooms = []
copied = []
unmapped = []
seen_loc: set[str] = set()
seen_room: set[str] = set()

if src_dir.exists():
    if (src_dir / "map.png").is_file():
        shutil.copy2(src_dir / "map.png", dst / "map.png")
        copied.append("map.png -> map.png")

    for path in sorted(src_dir.iterdir()):
        if path.suffix.upper() != ".PNG" or not path.is_file():
            continue
        key = path.stem.lower().strip()
        dest_name = FILE_TO_DEST.get(key)
        if dest_name:
            shutil.copy2(path, dst / dest_name)
            copied.append(f"{path.name} -> {dest_name}")
        else:
            unmapped.append(path.name)

    for folder, bucket, seen in (
        ("locations", locations, seen_loc),
        ("rooms", rooms, seen_room),
    ):
        sub = src_dir / folder
        for path in collect_pngs(sub):
            sid = slugify(path.stem)
            if sid in seen:
                continue
            seen.add(sid)
            room_type = parse_type(path.stem)
            dest_name = f"{sid}.png"
            rel = f"{folder}/{dest_name}"
            shutil.copy2(path, dst / rel)
            bucket.append(
                {
                    "id": sid,
                    "path": f"assets/images/quest/{rel}",
                    "label": path.stem,
                    "type": room_type,
                }
            )
            copied.append(f"{path.relative_to(src_dir)} -> {rel}")

manifest = {
    "map": "assets/images/quest/map.png",
    "locations": locations,
    "rooms": rooms,
}
manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

print(f"Copied {len(copied)} files; manifest: {len(locations)} locations, {len(rooms)} rooms")
if unmapped:
    print(f"Unmapped root ({len(unmapped)}):")
    for name in unmapped[:20]:
        print(f"  {name}")
