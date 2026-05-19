"""Merge quote-only patches into assets/data/npc_profiles.json by NPC id."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from npc_quotes_batch5_extra import EXTRA_QUOTES

root = Path(__file__).resolve().parent.parent
main_path = root / "assets" / "data" / "npc_profiles.json"

data = json.loads(main_path.read_text(encoding="utf-8"))
updated = 0

for profile in data["profiles"]:
    patch = EXTRA_QUOTES.get(profile["id"])
    if patch is None:
        continue
    profile.update(patch)
    updated += 1

main_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Updated quotes for {updated} profiles.")
