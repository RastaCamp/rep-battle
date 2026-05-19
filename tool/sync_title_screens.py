#!/usr/bin/env python3
"""Copy title screen art from project root into assets/images/screens/."""

from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets" / "images" / "screens"

MAPPING = {
    "title screen .PNG": "title_screen.png",
    "title screen 1 .PNG": "title_screen_1.png",
    "title screen 2 .PNG": "title_screen_2.png",
    "title screen 3.PNG": "title_screen_3.png",
    "title screen 4.PNG": "title_screen_4.png",
    "title screen 5.PNG": "title_screen_5.png",
}


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    copied = 0
    for src_name, dest_name in MAPPING.items():
        src = ROOT / src_name
        if not src.is_file():
            print(f"skip (missing): {src_name}")
            continue
        dest = DEST / dest_name
        shutil.copy2(src, dest)
        print(f"copied {src_name} -> {dest.relative_to(ROOT)}")
        copied += 1
    print(f"done ({copied} files)")


if __name__ == "__main__":
    main()
