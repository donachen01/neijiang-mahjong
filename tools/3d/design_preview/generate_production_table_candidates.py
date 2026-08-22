"""Build three production-scale Mahjong table candidates for in-game review.

Unlike the earlier isolated concept render, these GLBs contain only the table
furniture.  The Godot review runner loads them into the real MainSceneV2 so the
existing camera, tiles, nameplates, centre instrument and lighting remain the
same for all candidates.

Blender 5.2 LTS usage:
    blender --background --python generate_production_table_candidates.py -- --scheme ALL
"""

from __future__ import annotations

import argparse
import importlib.util
import math
from pathlib import Path

import bpy
import numpy as np


PROJECT_ROOT = Path(__file__).resolve().parents[3]
BASE_GENERATOR = PROJECT_ROOT / "tools" / "3d" / "generate_neijiang_table_v2.py"
OUTPUT_ROOT = PROJECT_ROOT / "res" / "art" / "3d" / "design_preview"
MATERIAL_ROOT = PROJECT_ROOT / "res" / "art" / "materials" / "design_preview"

SCHEMES = {
    "A": {
        "slug": "a_imperial_emerald_double_gold",
        "label": "翡翠御金",
        "felt_center": "176B4D",
        "felt_base": "0D4937",
        "felt_edge": "082F27",
        "leather": "092D25",
        "wood": "231813",
        "gold": "C9A34F",
        "gold_high": "F1D27A",
        "groove": "1B7254",
    },
    "B": {
        "slug": "b_midnight_sapphire_tailored_gold",
        "label": "午夜蓝金",
        "felt_center": "285D7B",
        "felt_base": "173F5C",
        "felt_edge": "0E2C43",
        "leather": "10283A",
        "wood": "181A1D",
        "gold": "C7A45B",
        "gold_high": "E9CC82",
        "groove": "326F91",
    },
    "C": {
        "slug": "c_obsidian_teal_art_deco_bronze",
        "label": "曜石黛青",
        "felt_center": "15585A",
        "felt_base": "0D3C42",
        "felt_edge": "072B31",
        "leather": "081F24",
        "wood": "171413",
        "gold": "9F6E38",
        "gold_high": "D2A15E",
        "groove": "1A6263",
    },
}


def _load_base_generator():
    spec = importlib.util.spec_from_file_location("neijiang_table_base", BASE_GENERATOR)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load {BASE_GENERATOR}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


base = _load_base_generator()


def rgb(hex_value: str) -> np.ndarray:
    return np.array([int(hex_value[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255.0


def solid_material(name: str, hex_value: str, roughness: float, metallic: float = 0.0) -> bpy.types.Material:
    """Create an exporter-friendly explicit Principled material graph."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    tree = mat.node_tree
    if tree is None:
        raise RuntimeError(f"Material node tree unavailable: {name}")
    tree.nodes.clear()
    output = tree.nodes.new("ShaderNodeOutputMaterial")
    shader = tree.nodes.new("ShaderNodeBsdfPrincipled")
    colour = rgb(hex_value)
    shader.inputs["Base Color"].default_value = (*base.srgb_to_linear(colour), 1.0)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    coat = shader.inputs.get("Coat Weight") or shader.inputs.get("Clearcoat")
    if coat is not None:
        coat.default_value = 0.12 if metallic < 0.5 else 0.05
    tree.links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    return mat


def configure_pbr_maps(scheme: dict) -> tuple[bpy.types.Material, bpy.types.Material, bpy.types.Material]:
    slug = scheme["slug"]
    base.TEXTURE_DIR = MATERIAL_ROOT / slug
    base.TABLE_CENTER = rgb(scheme["felt_center"])
    base.TABLE_BASE = rgb(scheme["felt_base"])
    base.TABLE_EDGE = rgb(scheme["felt_edge"])
    felt_maps = base.generate_felt_maps()
    leather_maps = base.generate_surface_maps(
        "leather", rgb(scheme["leather"]), 1024, 7101 + ord(slug[0]), 0.68, 0.0
    )
    wood_maps = base.generate_surface_maps(
        "walnut", rgb(scheme["wood"]), 1024, 7201 + ord(slug[0]), 0.48, 0.0
    )
    felt = base.pbr_material(f"{slug}_ShortNapFelt", *felt_maps, normal_strength=0.62)
    leather = base.pbr_material(f"{slug}_TailoredLeather", *leather_maps, normal_strength=0.42)
    wood = base.pbr_material(f"{slug}_DarkFurnitureFrame", *wood_maps, normal_strength=0.30)
    return felt, leather, wood


def ring(
    name: str,
    outer: tuple[float, float],
    inner: tuple[float, float],
    height: float,
    z: float,
    outer_radius: float,
    inner_radius: float,
    bevel: float,
    material: bpy.types.Material,
):
    return base.rounded_rectangle_ring(
        name, outer, inner, height, (0.0, 0.0, z), outer_radius, inner_radius, 16, bevel, material
    )


def strip(name: str, size, location, material, bevel: float = 0.018):
    return base.rounded_box(name, size, location, bevel, 5, material)


def add_felt_border(objects: list, material, *, outer=(12.62, 7.12), gap=0.18, prefix="Tailored") -> None:
    objects.extend([
        ring(f"{prefix}FeltLineOuter", outer, (outer[0] - 0.045, outer[1] - 0.045), 0.008, 0.158,
             0.23, 0.215, 0.004, material),
        ring(f"{prefix}FeltLineInner", (outer[0] - gap, outer[1] - gap),
             (outer[0] - gap - 0.025, outer[1] - gap - 0.025), 0.006, 0.157,
             0.20, 0.19, 0.003, material),
    ])


def build_a(scheme: dict, felt, leather, wood, gold, gold_high, groove) -> list:
    """Continuous double champagne-gold piping and tailored emerald rail."""
    objects = [
        base.rounded_box("A_EbonizedFurnitureBase", (14.94, 9.74, 0.58), (0.0, 0.0, -0.31), 0.34, 12, wood),
        base.rounded_box("A_ImperialEmeraldFelt", (13.46, 8.26, 0.31), (0.0, 0.0, 0.00), 0.25, 12, felt),
        ring("A_DarkApron", (14.82, 9.62), (13.72, 8.52), 0.36, 0.055, 0.43, 0.25, 0.13, wood),
        ring("A_TailoredRail", (14.67, 9.47), (13.78, 8.58), 0.31, 0.115, 0.39, 0.245, 0.12, leather),
        ring("A_OuterChampagnePiping", (14.76, 9.56), (14.68, 9.48), 0.055, 0.255, 0.405, 0.385, 0.018, gold),
        ring("A_InnerChampagnePiping", (13.86, 8.66), (13.79, 8.59), 0.050, 0.264, 0.265, 0.245, 0.016, gold_high),
    ]
    add_felt_border(objects, groove, outer=(12.62, 7.16), gap=0.20, prefix="A_DoubleTailored")
    return objects


def add_corner_l(objects: list, prefix: str, sx: float, sy: float, material, z: float, inset_x=5.85, inset_y=3.14):
    # Two stepped strokes form a restrained bespoke corner signature.  They sit
    # outside all tile lanes and are real inlay geometry, not a flat decal.
    objects.extend([
        strip(f"{prefix}_CornerH_{sx}_{sy}", (0.78, 0.022, 0.010), (sx * (inset_x - 0.39), sy * inset_y, z), material, 0.006),
        strip(f"{prefix}_CornerV_{sx}_{sy}", (0.022, 0.58, 0.010), (sx * inset_x, sy * (inset_y - 0.29), z), material, 0.006),
        strip(f"{prefix}_CornerH2_{sx}_{sy}", (0.48, 0.016, 0.008), (sx * (inset_x - 0.24), sy * (inset_y - 0.13), z + 0.001), material, 0.005),
        strip(f"{prefix}_CornerV2_{sx}_{sy}", (0.016, 0.36, 0.008), (sx * (inset_x - 0.13), sy * (inset_y - 0.18), z + 0.001), material, 0.005),
    ])


def build_b(scheme: dict, felt, leather, wood, gold, gold_high, groove) -> list:
    """Sapphire upholstered rail, stepped inner gold edge and corner tailoring."""
    objects = [
        base.rounded_box("B_BlackLacquerBase", (14.96, 9.76, 0.60), (0.0, 0.0, -0.32), 0.34, 12, wood),
        base.rounded_box("B_MidnightSapphireFelt", (13.48, 8.28, 0.31), (0.0, 0.0, 0.00), 0.25, 12, felt),
        ring("B_BlackLacquerApron", (14.84, 9.64), (13.66, 8.46), 0.37, 0.05, 0.43, 0.23, 0.13, wood),
        ring("B_WideSapphireUpholsteredRail", (14.67, 9.47), (13.74, 8.54), 0.34, 0.12, 0.39, 0.24, 0.13, leather),
        ring("B_SingleOuterGoldCord", (14.78, 9.58), (14.71, 9.51), 0.052, 0.26, 0.41, 0.395, 0.016, gold),
        ring("B_SteppedInnerGoldBand", (13.90, 8.70), (13.79, 8.59), 0.060, 0.268, 0.28, 0.245, 0.020, gold_high),
        ring("B_InnerNavyShadowLine", (13.73, 8.53), (13.68, 8.48), 0.028, 0.238, 0.235, 0.22, 0.010, leather),
    ]
    add_felt_border(objects, groove, outer=(12.68, 7.18), gap=0.30, prefix="B_Pinstripe")
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            add_corner_l(objects, "B_GoldTailoring", sx, sy, gold, 0.162, inset_x=5.96, inset_y=3.18)
    return objects


def build_c(scheme: dict, felt, leather, wood, gold, gold_high, groove) -> list:
    """Dark teal Art-Deco furniture with segmented bronze corner hardware."""
    objects = [
        base.rounded_box("C_ObsidianFurnitureBase", (14.98, 9.78, 0.62), (0.0, 0.0, -0.33), 0.32, 10, wood),
        base.rounded_box("C_DeepTealFelt", (13.42, 8.22, 0.31), (0.0, 0.0, 0.00), 0.22, 10, felt),
        ring("C_ArchitecturalApron", (14.86, 9.66), (13.64, 8.44), 0.39, 0.045, 0.36, 0.20, 0.095, wood),
        ring("C_BlackTealRail", (14.64, 9.44), (13.70, 8.50), 0.32, 0.115, 0.33, 0.21, 0.095, leather),
        ring("C_InnerBurnishedBronzeBand", (13.88, 8.68), (13.78, 8.58), 0.052, 0.262, 0.24, 0.215, 0.012, gold),
    ]
    # Segmented hardware deliberately replaces the continuous bright outer
    # piping of A/B.  The open corner rhythm is the scheme's defining feature.
    for sx in (-1.0, 1.0):
        objects.extend([
            strip(f"C_TopBronzeSegment_{sx}", (2.10, 0.080, 0.060), (sx * 4.98, -4.72, 0.270), gold, 0.020),
            strip(f"C_BottomBronzeSegment_{sx}", (2.10, 0.080, 0.060), (sx * 4.98, 4.72, 0.270), gold, 0.020),
        ])
    for sy in (-1.0, 1.0):
        objects.extend([
            strip(f"C_LeftBronzeSegment_{sy}", (0.080, 1.62, 0.060), (-7.31, sy * 3.58, 0.270), gold, 0.020),
            strip(f"C_RightBronzeSegment_{sy}", (0.080, 1.62, 0.060), (7.31, sy * 3.58, 0.270), gold, 0.020),
        ])
    add_felt_border(objects, groove, outer=(12.54, 7.06), gap=0.24, prefix="C_Architectural")
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            add_corner_l(objects, "C_DecoBronze", sx, sy, gold_high, 0.162, inset_x=5.78, inset_y=3.05)
    return objects


def build_scheme(key: str) -> Path:
    scheme = SCHEMES[key]
    base.clear_scene()
    felt, leather, wood = configure_pbr_maps(scheme)
    gold = solid_material(f"{scheme['slug']}_ChampagneMetal", scheme["gold"], 0.24, 0.92)
    gold_high = solid_material(f"{scheme['slug']}_HighlightMetal", scheme["gold_high"], 0.19, 0.94)
    groove = solid_material(f"{scheme['slug']}_TonalEmboss", scheme["groove"], 0.86, 0.0)
    builders = {"A": build_a, "B": build_b, "C": build_c}
    objects = builders[key](scheme, felt, leather, wood, gold, gold_high, groove)
    output = OUTPUT_ROOT / f"{scheme['slug']}.glb"
    base.OUTPUT_GLB = output
    base.export_glb(objects)
    print(f"DESIGN_CANDIDATE={key}|{scheme['label']}|{output}")
    return output


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scheme", choices=["A", "B", "C", "ALL"], default="ALL")
    arguments = bpy.app.driver_namespace.get("argv_override")
    if arguments is not None:
        return parser.parse_args(arguments)
    import sys
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])


if __name__ == "__main__":
    args = parse_arguments()
    keys = ("A", "B", "C") if args.scheme == "ALL" else (args.scheme,)
    for scheme_key in keys:
        build_scheme(scheme_key)
    print("DESIGN_CANDIDATES_COMPLETE")
