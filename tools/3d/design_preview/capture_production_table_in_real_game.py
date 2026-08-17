"""Capture the shipping table inside the real MainSceneV2 composition.

Run this helper from Blender's Python console on macOS.  Blender owns a normal
desktop GUI session, so the launched Godot process can render with the same
onscreen Metal path used by the game instead of the headless dummy renderer.
"""

from __future__ import annotations

import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[3]
GODOT = Path("/Applications/Godot.NET.app/Contents/MacOS/Godot")
OUTPUT_ROOT = (
    PROJECT_ROOT
    / "evidence"
    / "neijiang_3d_ui_port_20260813"
    / "production_reference_20260815"
)
TABLE_PATH = "res://res/art/3d/neijiang_table_v2.glb"
CAPTURE_PATH = (
    "res://evidence/neijiang_3d_ui_port_20260813/"
    "production_reference_20260815/production_deep_emerald_real_scene.png"
)


def main() -> None:
    if not GODOT.exists():
        raise FileNotFoundError(GODOT)
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    print("START_PRODUCTION_REFERENCE_CAPTURE", flush=True)
    # Runtime launches consume .godot/imported and do not guarantee that a
    # freshly regenerated GLB (or its extracted PBR textures) is reimported.
    # Refresh the editor cache first so the evidence image always represents
    # the files that will be exported to mobile builds.
    imported = subprocess.run(
        [
            str(GODOT),
            "--headless",
            "--editor",
            "--path",
            str(PROJECT_ROOT),
            "--quit",
            "--log-file",
            str(OUTPUT_ROOT / "production_godot_import.log"),
        ],
        cwd=PROJECT_ROOT,
        check=False,
    )
    if imported.returncode != 0:
        raise RuntimeError(
            f"Godot asset import failed with exit code {imported.returncode}"
        )
    completed = subprocess.run(
        [
            str(GODOT),
            "--log-file",
            str(OUTPUT_ROOT / "production_godot_capture.log"),
            "--path",
            str(PROJECT_ROOT),
            "--resolution",
            "2560x1440",
            "--windowed",
            "--script",
            "res://tools/capture_table_design_candidate.gd",
            "--",
            f"--table-preview={TABLE_PATH}",
            f"--capture-output={CAPTURE_PATH}",
        ],
        cwd=PROJECT_ROOT,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            f"Godot production capture failed with exit code {completed.returncode}"
        )
    print(f"PRODUCTION_REFERENCE_CAPTURE={OUTPUT_ROOT / 'production_deep_emerald_real_scene.png'}")
    print("PRODUCTION_REFERENCE_CAPTURE_COMPLETE", flush=True)


if __name__ == "__main__":
    main()
