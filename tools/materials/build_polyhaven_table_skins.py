#!/usr/bin/env python3
"""Build mobile-friendly Neijiang table skins from local Poly Haven sources."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE_ROOT = Path("/Volumes/工具/mj/素材")
DEFAULT_OUTPUT_ROOT = PROJECT_ROOT / "res/art/materials/table_skins"
BLENDER_CANDIDATES = (
    Path("/Applications/Blender.app/Contents/MacOS/Blender"),
    Path("/Applications/Blender 5.2.app/Contents/MacOS/Blender"),
)

SKINS = (
    {
        "id": "deep_emerald_crepe",
        "source": "crepe_georgette",
        "shadow": "073D2F",
        "mid": "146047",
        "highlight": "4B9670",
        "contrast": 1.08,
    },
    {
        "id": "emerald_linen",
        "source": "rough_linen",
        "shadow": "082F28",
        "mid": "135644",
        "highlight": "3D8063",
        "contrast": 1.02,
    },
    {
        "id": "warm_caban_velvet",
        "source": "caban",
        "shadow": "0D3028",
        "mid": "1A5842",
        "highlight": "5A8B68",
        "contrast": 0.96,
    },
    {
        "id": "black_gold_jacquard",
        "source": "quatrefoil_jacquard_fabric",
        "shadow": "061C18",
        "mid": "123B30",
        "highlight": "4F684D",
        "contrast": 0.88,
    },
    {
        "id": "champagne_satin",
        "source": "crepe_satin",
        "shadow": "3A2815",
        "mid": "82642D",
        "highlight": "D1B469",
        "contrast": 0.90,
    },
    {
        "id": "teal_teddy_check",
        "source": "curly_teddy_checkered",
        "shadow": "08272A",
        "mid": "145156",
        "highlight": "6B9083",
        "contrast": 0.82,
    },
)


def hex_rgb(value: str) -> np.ndarray:
    return np.array([int(value[i : i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255.0


def colorize(source: Image.Image, skin: dict[str, object]) -> Image.Image:
    image = source.convert("RGB").resize((2048, 2048), Image.Resampling.LANCZOS)
    rgb = np.asarray(image, dtype=np.float32) / 255.0
    luminance = rgb @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    low, high = np.percentile(luminance, (1.0, 99.0))
    value = np.clip((luminance - low) / max(high - low, 1e-5), 0.0, 1.0)
    value = np.clip((value - 0.5) * float(skin["contrast"]) + 0.5, 0.0, 1.0)

    shadow = hex_rgb(str(skin["shadow"]))
    middle = hex_rgb(str(skin["mid"]))
    highlight = hex_rgb(str(skin["highlight"]))
    lower_mix = np.clip(value * 2.0, 0.0, 1.0)[..., None]
    upper_mix = np.clip((value - 0.5) * 2.0, 0.0, 1.0)[..., None]
    lower = shadow + (middle - shadow) * lower_mix
    upper = middle + (highlight - middle) * upper_mix
    tinted = np.where((value < 0.5)[..., None], lower, upper)

    # Retain only a restrained amount of the source chroma. This keeps real
    # fibre variation without allowing beige source photographs to contaminate
    # the authored emerald/champagne palette.
    source_chroma = rgb - luminance[..., None]
    tinted = np.clip(tinted + source_chroma * 0.07, 0.0, 1.0)
    output = Image.fromarray(np.round(tinted * 255.0).astype(np.uint8), "RGB")
    output = output.filter(ImageFilter.GaussianBlur(radius=0.10))
    return ImageEnhance.Sharpness(output).enhance(1.12)


def build_albedo_and_preview(source_root: Path, output_root: Path) -> None:
    for skin in SKINS:
        source_name = str(skin["source"])
        source_path = source_root / f"{source_name}_4k.blend/textures/{source_name}_diff_4k.jpg"
        if not source_path.is_file():
            raise FileNotFoundError(source_path)
        destination = output_root / str(skin["id"])
        destination.mkdir(parents=True, exist_ok=True)
        with Image.open(source_path) as source:
            albedo = colorize(source, skin)
        albedo.save(destination / "albedo_2k.jpg", quality=94, subsampling=0, optimize=True)
        preview = albedo.copy()
        preview.thumbnail((512, 320), Image.Resampling.LANCZOS)
        preview.save(destination / "preview.jpg", quality=91, subsampling=0, optimize=True)


def convert_exr(source_root: Path, output_root: Path, blender_path: Path) -> None:
    # Poly Haven currently ships these maps with DWAA/DWAB compression. Godot's
    # TinyEXR importer intentionally supports a smaller subset and ffmpeg may
    # silently replace unsupported DWA blocks with black pixels. Blender uses
    # OpenImageIO here, so it is also the authoritative integrity-preserving
    # converter for the PBR maps authored for this project.
    for skin in SKINS:
        source_name = str(skin["source"])
        source_dir = source_root / f"{source_name}_4k.blend/textures"
        destination = output_root / str(skin["id"])
        destination.mkdir(parents=True, exist_ok=True)
        mappings = (
            (source_dir / f"{source_name}_nor_gl_4k.exr", destination / "normal_2k.png"),
            (source_dir / f"{source_name}_rough_4k.exr", destination / "roughness_2k.png"),
        )
        for source_path, destination_path in mappings:
            if not source_path.is_file():
                raise FileNotFoundError(source_path)
            expression = (
                "import bpy; "
                f"im=bpy.data.images.load({str(source_path)!r}, check_existing=False); "
                "im.colorspace_settings.name='Non-Color'; "
                "im.scale(2048, 2048); "
                f"im.filepath_raw={str(destination_path)!r}; "
                "im.file_format='PNG'; im.save()"
            )
            command = [
                str(blender_path),
                "--background",
                "--factory-startup",
                "--python-expr",
                expression,
            ]
            subprocess.run(command, check=True, stdout=subprocess.DEVNULL)

            # Blender/OpenImageIO preserves the EXR's 16-bit precision when it
            # writes PNG. The mobile shader only consumes 8-bit normalized
            # normal/roughness channels, so keeping 16-bit files doubles I/O
            # and package size without a visible benefit. Pillow performs the
            # deterministic 8-bit reduction and lossless PNG optimization.
            with Image.open(destination_path) as converted:
                optimized = converted.convert("RGB")
                optimized.save(destination_path, format="PNG", optimize=True)


def write_manifest(output_root: Path) -> None:
    payload = {
        "schema": 1,
        "source": "Poly Haven CC0 local downloads",
        "runtime_resolution": 2048,
        "skins": [
            {
                "id": skin["id"],
                "source_asset": skin["source"],
                "files": ["albedo_2k.jpg", "normal_2k.png", "roughness_2k.png", "preview.jpg"],
            }
            for skin in SKINS
        ],
    }
    (output_root / "manifest.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, default=DEFAULT_SOURCE_ROOT)
    parser.add_argument("--output-root", type=Path, default=DEFAULT_OUTPUT_ROOT)
    parser.add_argument("--blender", type=Path)
    args = parser.parse_args()

    blender_path = args.blender or next((candidate for candidate in BLENDER_CANDIDATES if candidate.is_file()), None)
    if blender_path is None:
        raise FileNotFoundError("Blender executable was not found")
    args.output_root.mkdir(parents=True, exist_ok=True)
    build_albedo_and_preview(args.source_root, args.output_root)
    convert_exr(args.source_root, args.output_root, blender_path)
    write_manifest(args.output_root)
    print(f"Built {len(SKINS)} table skins in {args.output_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
