"""Launch Godot three times and capture the table candidates in MainSceneV2.

This helper is intended to run from Blender's Python console on macOS.  The
Blender process already owns a normal desktop GUI session, avoiding the dummy
renderer used by sandboxed/headless test commands.
"""

from __future__ import annotations

import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[3]
GODOT = Path("/Applications/Godot.NET.app/Contents/MacOS/Godot")
OUTPUT_ROOT = PROJECT_ROOT / "evidence" / "neijiang_3d_ui_port_20260813" / "tabletop_redesign_20260815"

CANDIDATES = (
    (
        "A",
        "res://res/art/3d/design_preview/a_imperial_emerald_double_gold.glb",
        "res://evidence/neijiang_3d_ui_port_20260813/tabletop_redesign_20260815/a_imperial_emerald_real_scene.png",
    ),
    (
        "B",
        "res://res/art/3d/design_preview/b_midnight_sapphire_tailored_gold.glb",
        "res://evidence/neijiang_3d_ui_port_20260813/tabletop_redesign_20260815/b_midnight_sapphire_real_scene.png",
    ),
    (
        "C",
        "res://res/art/3d/design_preview/c_obsidian_teal_art_deco_bronze.glb",
        "res://evidence/neijiang_3d_ui_port_20260813/tabletop_redesign_20260815/c_obsidian_teal_real_scene.png",
    ),
)


def main() -> None:
    if not GODOT.exists():
        raise FileNotFoundError(GODOT)
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    for key, table_path, output_path in CANDIDATES:
        print(f"START_REAL_SCENE_CAPTURE={key}", flush=True)
        completed = subprocess.run(
            [
                str(GODOT),
                "--log-file",
                str(OUTPUT_ROOT / f"{key.lower()}_godot_capture.log"),
                "--path",
                str(PROJECT_ROOT),
                "--resolution",
                "2560x1440",
                "--windowed",
                "--script",
                "res://tools/capture_table_design_candidate.gd",
                "--",
                f"--table-preview={table_path}",
                f"--capture-output={output_path}",
            ],
            cwd=PROJECT_ROOT,
            check=False,
        )
        if completed.returncode != 0:
            raise RuntimeError(f"Godot capture {key} failed with exit code {completed.returncode}")
        print(f"FINISH_REAL_SCENE_CAPTURE={key}", flush=True)
    print("REAL_SCENE_DESIGN_PREVIEWS_COMPLETE", flush=True)


if __name__ == "__main__":
    main()
