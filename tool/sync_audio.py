#!/usr/bin/env python3
"""Copy labeled MP3s from project root into assets/audio/."""

from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets" / "audio"

# (source relative to ROOT, destination under assets/audio)
FILES: list[tuple[str, str]] = [
    # Title / menu
    ("rep battle title.mp3", "music/title/rep_battle_title.mp3"),
    ("rep battle title pro.mp3", "music/title/rep_battle_title_pro.mp3"),
    ("on quest button press and setup loop.mp3", "music/quest_menu/quest_setup_loop.mp3"),
    ("rep settings.mp3", "music/settings/rep_settings.mp3"),
    ("played on scoreboard screen.mp3", "music/scoreboard/scoreboard.mp3"),
    # Play mode tracks
    ("tracks/rep track.mp3", "music/play/rep_track.mp3"),
    ("tracks/rep track 1.mp3", "music/play/rep_track_1.mp3"),
    ("tracks/rep track 2.mp3", "music/play/rep_track_2.mp3"),
    ("tracks/rep track 3.mp3", "music/play/rep_track_3.mp3"),
    ("tracks/rep track 4.mp3", "music/play/rep_track_4.mp3"),
    ("tracks/rep track 5.mp3", "music/play/rep_track_5.mp3"),
    ("tracks/rep track 6.mp3", "music/play/rep_track_6.mp3"),
    ("tracks/rep track 7.mp3", "music/play/rep_track_7.mp3"),
    ("tracks/rep track 8.mp3", "music/play/rep_track_8.mp3"),
    ("tracks/rep track 9.mp3", "music/play/rep_track_9.mp3"),
    # Quest tracks
    ("quest/rep quest track.mp3", "music/quest/rep_quest_track.mp3"),
    ("quest/rep quest track 1.mp3", "music/quest/rep_quest_track_1.mp3"),
    ("quest/rep quest track 2.mp3", "music/quest/rep_quest_track_2.mp3"),
    ("quest/rep quest track 3.mp3", "music/quest/rep_quest_track_3.mp3"),
    ("quest/rep quest track 4.mp3", "music/quest/rep_quest_track_4.mp3"),
    ("quest/rep quest track 5.mp3", "music/quest/rep_quest_track_5.mp3"),
    ("quest/rep quest track 6.mp3", "music/quest/rep_quest_track_6.mp3"),
    ("quest/rep quest track 7.mp3", "music/quest/rep_quest_track_7.mp3"),
    # SFX — pools use subfolders
    ("confirm.mp3", "sfx/confirm/confirm.mp3"),
    ("confirm 1.mp3", "sfx/confirm/confirm_1.mp3"),
    ("confirm 2.mp3", "sfx/confirm/confirm_2.mp3"),
    ("decline.mp3", "sfx/decline/decline.mp3"),
    ("decline 1.mp3", "sfx/decline/decline_1.mp3"),
    ("decline 2.mp3", "sfx/decline/decline_2.mp3"),
    ("basic attack.mp3", "sfx/card_flip.mp3"),
    ("chain combo.mp3", "sfx/combo.mp3"),
    ("combo breaker.mp3", "sfx/combo_break.mp3"),
    ("hit armor.mp3", "sfx/armor_break.mp3"),
    ("swing miss.mp3", "sfx/life_lost.mp3"),
    ("ambient chatter.mp3", "sfx/crowd_cheer.mp3"),
    ("match start play mode.mp3", "sfx/begin.mp3"),
    ("match start play mode.mp3", "sfx/shuffle.mp3"),
    ("enemy defeated.mp3", "sfx/enemy_defeated.mp3"),
    ("forfeit.mp3", "sfx/forfeit/forfeit.mp3"),
    ("forfeit 1.mp3", "sfx/forfeit/forfeit_1.mp3"),
    ("forfeit 3.mp3", "sfx/forfeit/forfeit_3.mp3"),
    ("winner.mp3", "sfx/victory/winner.mp3"),
    ("winner 1.mp3", "sfx/victory/winner_1.mp3"),
    ("rep danger, time running out.mp3", "sfx/timer_warning.mp3"),
    ("times up.mp3", "sfx/timer_tick.mp3"),
    ("use inventory.mp3", "sfx/inventory.mp3"),
]


def main() -> None:
    copied = 0
    for src_rel, dest_rel in FILES:
        src = ROOT / src_rel
        dest = DEST / dest_rel
        if not src.is_file():
            print(f"skip (missing): {src_rel}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        print(f"copied -> {dest_rel}")
        copied += 1
    print(f"done ({copied} files)")


if __name__ == "__main__":
    main()
