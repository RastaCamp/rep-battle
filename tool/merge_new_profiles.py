"""Append new NPC profile batches to assets/data/npc_profiles.json.

Usage:
  python tool/merge_new_profiles.py
  python tool/merge_new_profiles.py tool/npc_profiles_batch5.json
"""
import json
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
main_path = root / "assets" / "data" / "npc_profiles.json"

batch_names = sys.argv[1:] if len(sys.argv) > 1 else ["tool/npc_profiles_batch5.json"]

data = json.loads(main_path.read_text(encoding="utf-8"))
existing_ids = {p["id"] for p in data["profiles"]}
total_added = 0

for name in batch_names:
    batch_path = Path(name)
    if not batch_path.is_absolute():
        batch_path = root / batch_path
    if not batch_path.exists():
        print(f"Skip missing batch: {batch_path}")
        continue

    new_profiles = json.loads(batch_path.read_text(encoding="utf-8"))
    added = 0
    for p in new_profiles:
        if p["id"] in existing_ids:
            print(f"Skip duplicate id: {p['id']}")
            continue
        data["profiles"].append(p)
        existing_ids.add(p["id"])
        added += 1
    total_added += added
    print(f"From {batch_path.name}: added {added}")

data["version"] = max(data.get("version", 1), 6)
main_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Total profiles: {len(data['profiles'])} (+{total_added} this run)")
