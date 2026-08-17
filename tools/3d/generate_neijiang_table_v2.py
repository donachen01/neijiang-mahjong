"""Generate the Deep Emerald Neijiang table and its deterministic PBR maps.

Run with Blender 5.2 LTS:
    /Applications/Blender.app/Contents/MacOS/Blender --background \
      --python tools/3d/generate_neijiang_table_v2.py

The script owns only visual assets.  Gameplay dimensions, tiles, scoring and
interaction remain in Godot.  Textures are capped at 2048 for mobile runtime.
"""

from __future__ import annotations

import math
import shutil
import subprocess
from pathlib import Path

import bpy
import numpy as np


PROJECT_ROOT = Path(__file__).resolve().parents[2]
ART_ROOT = PROJECT_ROOT / "res" / "art"
OUTPUT_GLB = ART_ROOT / "3d" / "neijiang_table_v2.glb"
TEXTURE_DIR = ART_ROOT / "materials" / "table_v2"

# Production visual contract: restrained private-club furniture, not a bright
# arcade skin.  The reference is built from one emerald family, an ebonized
# frame, a tailored dark-green rail and two continuous champagne-gold cords.
TABLE_CENTER = np.array([0x1C, 0x73, 0x50], dtype=np.float32) / 255.0
TABLE_BASE = np.array([0x10, 0x56, 0x3D], dtype=np.float32) / 255.0
TABLE_EDGE = np.array([0x09, 0x2F, 0x26], dtype=np.float32) / 255.0
LEATHER_RAIL = np.array([0x08, 0x3A, 0x2D], dtype=np.float32) / 255.0
EBONIZED_FRAME = np.array([0x17, 0x24, 0x1F], dtype=np.float32) / 255.0
CHAMPAGNE_GOLD = np.array([0xC6, 0xA7, 0x5A], dtype=np.float32) / 255.0
CHAMPAGNE_HIGHLIGHT = np.array([0xE4, 0xCB, 0x7D], dtype=np.float32) / 255.0
# A near-neighbour of the felt, never a painted outline.  It is intentionally
# only a little lighter than the cloth so the double inset reads through grazing
# light without competing with tiles or the centre instrument.
PLAYFIELD_GROOVE = np.array([0x3A, 0x82, 0x6B], dtype=np.float32) / 255.0


def srgb_to_linear(value: np.ndarray) -> np.ndarray:
    return np.where(value <= 0.04045, value / 12.92, ((value + 0.055) / 1.055) ** 2.4)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for blocks in (bpy.data.meshes, bpy.data.materials, bpy.data.curves, bpy.data.images):
        for block in list(blocks):
            if block.users == 0:
                blocks.remove(block)


def save_rgba_image(name: str, path: Path, rgb: np.ndarray, alpha: float = 1.0) -> bpy.types.Image:
    height, width, _ = rgb.shape
    rgba = np.empty((height, width, 4), dtype=np.float32)
    # Blender writes byte-buffer PNG pixels without an additional display
    # transform here.  Keep authored base-colour values in sRGB space; feeding
    # linearised values produced a visibly near-black tabletop after import.
    rgba[:, :, :3] = np.clip(rgb, 0.0, 1.0)
    rgba[:, :, 3] = alpha
    image = bpy.data.images.new(name, width=width, height=height, alpha=True, float_buffer=False)
    image.colorspace_settings.name = "sRGB"
    image.pixels.foreach_set(rgba.reshape(-1))
    path.parent.mkdir(parents=True, exist_ok=True)
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    image.pack()
    return image


def save_non_color_image(name: str, path: Path, rgba: np.ndarray) -> bpy.types.Image:
    height, width, _ = rgba.shape
    image = bpy.data.images.new(name, width=width, height=height, alpha=True, float_buffer=False)
    image.colorspace_settings.name = "Non-Color"
    image.pixels.foreach_set(np.clip(rgba, 0.0, 1.0).reshape(-1))
    path.parent.mkdir(parents=True, exist_ok=True)
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    image.pack()
    return image


def smooth_noise(size: int, seed: int, cells: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    coarse = rng.random((cells, cells), dtype=np.float32)
    image = bpy.data.images.new(f"Noise_{seed}_{cells}", width=cells, height=cells, alpha=False, float_buffer=True)
    rgba = np.ones((cells, cells, 4), dtype=np.float32)
    rgba[:, :, :3] = coarse[:, :, None]
    image.pixels.foreach_set(rgba.reshape(-1))
    image.scale(size, size)
    pixels = np.empty(size * size * 4, dtype=np.float32)
    image.pixels.foreach_get(pixels)
    bpy.data.images.remove(image)
    return pixels.reshape(size, size, 4)[:, :, 0]


def generate_felt_maps(size: int = 2048) -> tuple[bpy.types.Image, bpy.types.Image, bpy.types.Image]:
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    u = x / float(size - 1)
    v = y / float(size - 1)
    edge_distance = np.maximum(np.abs(u - 0.5) / 0.5, np.abs(v - 0.5) / 0.5)
    edge = np.clip((edge_distance - 0.70) / 0.30, 0.0, 1.0)
    centre = np.clip(1.0 - np.sqrt(((u - 0.5) / 0.72) ** 2 + ((v - 0.5) / 0.72) ** 2), 0.0, 1.0)

    medium = smooth_noise(size, 5302, 96)
    fine = smooth_noise(size, 5303, 360)
    phase_noise = smooth_noise(size, 5304, 180)

    # Equal-weight fibres from four unrelated directions remove the previous
    # vertical ribbing while retaining a fine, even short-nap response.
    fibre_fields = (
        np.sin((u * 760.0 + v * 250.0 + phase_noise * 0.34) * math.tau),
        np.sin((-u * 310.0 + v * 830.0 + fine * 0.28) * math.tau),
        np.sin((u * 610.0 - v * 690.0 + phase_noise * 0.30) * math.tau),
        np.sin((u * 520.0 + v * 540.0 + medium * 0.18) * math.tau),
    )
    fibre = sum(fibre_fields) * 0.125 + 0.5

    # A deterministic isotropic band-limited layer remains visible through
    # mobile mipmaps without introducing the broad height islands that read as
    # water stains. Frequencies stay strictly inside the approved 180-320 band.
    mid_rng = np.random.default_rng(5310)
    mid_nap = np.zeros((size, size), dtype=np.float32)
    for _ in range(48):
        angle = mid_rng.uniform(0.0, math.tau)
        cycles = mid_rng.uniform(180.0, 320.0)
        phase = mid_rng.uniform(0.0, math.tau)
        projected = u * math.cos(angle) + v * math.sin(angle)
        mid_nap += np.sin(projected * cycles * math.tau + phase)
    mid_nap /= math.sqrt(24.0)

    # Real short-nap cloth is never a perfectly uniform painted plane. Keep the
    # variation fine and isotropic so it reads as dense fibres after mobile
    # mipmapping without becoming large stains or directional ribbing.
    clean_felt_color = TABLE_BASE * 0.82 + TABLE_CENTER * 0.18
    base = np.broadcast_to(clean_felt_color[None, None, :], (size, size, 3)).copy()
    # The photographic reference has a gentle centre lift and a richer edge,
    # caused by short-nap direction and the table lighting rather than a visible
    # vignette.  Keep the range narrow enough that discarded tiles retain the
    # same contrast anywhere on the playfield.
    base *= (0.992 + centre[:, :, None] * 0.016)
    base *= (1.0 - edge[:, :, None] * 0.010)
    colour_nap = (
        (fine - 0.5) * 0.006
        + (fibre - 0.5) * 0.004
    )
    base *= 1.0 + colour_nap[:, :, None]
    # Preserve a true emerald cloth under the warm key light; the previous blue
    # multiplier pushed the table toward cyan/grey on iPhone displays.
    base *= np.array([0.92, 1.04, 0.94], dtype=np.float32)[None, None, :]
    # Sparse light-facing fibre tips give the surface a soft textile sparkle,
    # not plastic clearcoat. The mask is deterministic and sub-pixel dense.
    fibre_tips = np.clip((fine - 0.76) / 0.24, 0.0, 1.0) ** 3
    base += fibre_tips[:, :, None] * np.array([0.004, 0.008, 0.007], dtype=np.float32)

    # Keep the legacy audit mask deterministic, but do not tint the production
    # base colour with it. The runtime table is clean short-nap felt throughout.
    perimeter = np.clip((edge_distance - 0.82) / 0.10, 0.0, 1.0)
    wave_a = np.sin((u * 13.0 + np.sin(v * 8.0 * math.pi) * 0.18) * math.pi * 2.0)
    wave_b = np.sin((v * 11.0 + np.sin(u * 7.0 * math.pi) * 0.16) * math.pi * 2.0)
    brocade = ((wave_a * wave_b) * 0.5 + 0.5) * perimeter
    mask_rgba = np.ones((size, size, 4), dtype=np.float32)
    mask_rgba[:, :, :3] = brocade[:, :, None]
    save_non_color_image("FeltBrocadeMask2048", TEXTURE_DIR / "brocade_mask.png", mask_rgba)
    felt_base = save_rgba_image("FeltBaseColor2048", TEXTURE_DIR / "felt_basecolor.png", base)

    # The mid layer supplies readable short nap while the dense layer keeps the
    # close-up fibre response. Neither layer writes into BaseColor.
    # Do not put the band-limited mid layer into the normal map. Although it is
    # high-frequency at source resolution, mobile mip filtering can fold it into
    # broad cloudy normals over this very large UV island. Fine fibres and the
    # 360-cell noise keep the textile response without visible water-stain blobs.
    height = sum(field * 0.010 for field in fibre_fields) + (fine - 0.5) * 0.012
    grad_y, grad_x = np.gradient(height)
    normal = np.dstack((-grad_x * 1.20, -grad_y * 1.20, np.ones_like(height)))
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    normal_rgba = np.ones((size, size, 4), dtype=np.float32)
    normal_rgba[:, :, :3] = normal * 0.5 + 0.5
    felt_normal = save_non_color_image("FeltNormal2048", TEXTURE_DIR / "felt_normal.png", normal_rgba)

    roughness = np.clip(
        0.84
        + (fine - 0.5) * 0.022
        + (fibre - 0.5) * 0.016,
        0.80,
        0.89,
    )
    orm = np.ones((size, size, 4), dtype=np.float32)
    orm[:, :, 0] = 0.97  # AO stays uniform; geometry provides the edge depth.
    orm[:, :, 1] = roughness
    orm[:, :, 2] = 0.0  # metallic
    felt_orm = save_non_color_image("FeltORM2048", TEXTURE_DIR / "felt_orm.png", orm)
    return felt_base, felt_normal, felt_orm


def generate_surface_maps(prefix: str, color: np.ndarray, size: int, seed: int, roughness: float, metallic: float):
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    u = x / float(size - 1)
    v = y / float(size - 1)
    medium = smooth_noise(size, seed, 72)
    fine = smooth_noise(size, seed + 1, 220)
    grain = (medium - 0.5) * 0.055 + (fine - 0.5) * 0.018
    if prefix == "walnut":
        # Real furniture grain is carried by low-contrast colour, normal and
        # roughness variation. It must not read as dark lines drawn over the
        # rail from the gameplay camera.
        broad_grain = np.sin(
            (u * 5.0 + np.sin(v * 1.35 * math.pi) * 0.32 + medium * 0.18)
            * math.pi
            * 2.0
        )
        fine_grain = np.sin(
            (u * 17.0 + np.sin(v * 3.4 * math.pi) * 0.10 + fine * 0.08)
            * math.pi
            * 2.0
        )
        grain = (medium - 0.5) * 0.032 + (fine - 0.5) * 0.010
        grain += broad_grain * 0.032 + fine_grain * 0.009
    rgb = color[None, None, :] * (1.0 + grain[:, :, None])
    if prefix == "walnut":
        # Preserve subtle earlywood/latewood separation without the previous
        # near-black veins, then add a restrained warm satin lift.
        dark_vein = ((1.0 - broad_grain) * 0.5) ** 7
        rgb *= 1.0 - dark_vein[:, :, None] * 0.075
        warm_lift = np.array([0.020, 0.009, 0.004], dtype=np.float32)
        rgb += warm_lift[None, None, :] * ((broad_grain + 1.0) * 0.5)[:, :, None]
    base = save_rgba_image(f"{prefix.title()}BaseColor", TEXTURE_DIR / f"{prefix}_basecolor.png", rgb)
    grad_y, grad_x = np.gradient(grain)
    n = np.dstack((-grad_x * 2.2, -grad_y * 2.2, np.ones_like(grain)))
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    nrgba = np.ones((size, size, 4), dtype=np.float32)
    nrgba[:, :, :3] = n * 0.5 + 0.5
    normal = save_non_color_image(f"{prefix.title()}Normal", TEXTURE_DIR / f"{prefix}_normal.png", nrgba)
    orm_data = np.ones((size, size, 4), dtype=np.float32)
    orm_data[:, :, 0] = 0.94
    orm_data[:, :, 1] = np.clip(roughness + (medium - 0.5) * 0.04, 0.0, 1.0)
    orm_data[:, :, 2] = metallic
    orm = save_non_color_image(f"{prefix.title()}ORM", TEXTURE_DIR / f"{prefix}_orm.png", orm_data)
    return base, normal, orm


def pbr_material(name: str, base: bpy.types.Image, normal: bpy.types.Image, orm: bpy.types.Image, normal_strength: float = 0.54) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    for node in list(nodes):
        nodes.remove(node)
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    base_node = nodes.new("ShaderNodeTexImage")
    base_node.image = base
    normal_node = nodes.new("ShaderNodeTexImage")
    normal_node.image = normal
    normal_node.image.colorspace_settings.name = "Non-Color"
    normal_map = nodes.new("ShaderNodeNormalMap")
    normal_map.inputs["Strength"].default_value = normal_strength
    orm_node = nodes.new("ShaderNodeTexImage")
    orm_node.image = orm
    orm_node.image.colorspace_settings.name = "Non-Color"
    separate = nodes.new("ShaderNodeSeparateColor")
    links.new(base_node.outputs["Color"], shader.inputs["Base Color"])
    links.new(normal_node.outputs["Color"], normal_map.inputs["Color"])
    links.new(normal_map.outputs["Normal"], shader.inputs["Normal"])
    links.new(orm_node.outputs["Color"], separate.inputs["Color"])
    links.new(separate.outputs["Green"], shader.inputs["Roughness"])
    links.new(separate.outputs["Blue"], shader.inputs["Metallic"])
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    return mat


def simple_material(
    name: str,
    color: np.ndarray,
    roughness: float,
    metallic: float,
    coat_weight: float = 0.0,
) -> bpy.types.Material:
    """Create an exporter-friendly explicit Principled material graph.

    Blender 5.2 no longer guarantees that toggling ``use_nodes`` leaves a
    default Principled node behind.  Building the graph explicitly keeps the
    production generator valid across Blender 4.x/5.x and avoids the console
    failure encountered during the earlier design study.
    """
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    tree = mat.node_tree
    if tree is None:
        raise RuntimeError(f"Material node tree unavailable: {name}")
    tree.nodes.clear()
    output = tree.nodes.new("ShaderNodeOutputMaterial")
    shader = tree.nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Base Color"].default_value = (*srgb_to_linear(color), 1.0)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    coat = shader.inputs.get("Coat Weight") or shader.inputs.get("Clearcoat")
    if coat is not None:
        coat.default_value = coat_weight
    tree.links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    return mat


def rounded_box(name: str, size, location, bevel: float, segments: int, material: bpy.types.Material):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    mod = obj.modifiers.new(name="SoftManufacturedBevel", type="BEVEL")
    mod.width = bevel
    mod.segments = segments
    mod.profile = 0.62
    mod.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    obj.data.materials.append(material)
    return obj


def rounded_rectangle_ring(
    name: str,
    outer_size: tuple[float, float],
    inner_size: tuple[float, float],
    height: float,
    location: tuple[float, float, float],
    outer_radius: float,
    inner_radius: float,
    corner_segments: int,
    bevel: float,
    material: bpy.types.Material,
):
    """Create one continuous manufactured frame with genuinely rounded corners.

    Four overlapping boxes expose seams and square joins in the oblique game
    camera. A single extruded ring gives the supplied furniture reference's
    uninterrupted tray silhouette while keeping the playable felt dimensions
    unchanged.
    """

    def rounded_loop(size: tuple[float, float], radius: float) -> list[tuple[float, float]]:
        half_width = size[0] * 0.5
        half_depth = size[1] * 0.5
        centres_and_ranges = [
            ((half_width - radius, half_depth - radius), (0.0, 90.0)),
            ((-half_width + radius, half_depth - radius), (90.0, 180.0)),
            ((-half_width + radius, -half_depth + radius), (180.0, 270.0)),
            ((half_width - radius, -half_depth + radius), (270.0, 360.0)),
        ]
        points: list[tuple[float, float]] = []
        for (centre_x, centre_y), (start_angle, end_angle) in centres_and_ranges:
            for segment in range(corner_segments):
                factor = segment / float(corner_segments)
                angle = math.radians(start_angle + (end_angle - start_angle) * factor)
                points.append((
                    centre_x + math.cos(angle) * radius,
                    centre_y + math.sin(angle) * radius,
                ))
        return points

    outer = rounded_loop(outer_size, outer_radius)
    inner = rounded_loop(inner_size, inner_radius)
    count = len(outer)
    half_height = height * 0.5
    vertices = (
        [(x, y, half_height) for x, y in outer]
        + [(x, y, half_height) for x, y in inner]
        + [(x, y, -half_height) for x, y in outer]
        + [(x, y, -half_height) for x, y in inner]
    )
    faces: list[tuple[int, int, int, int]] = []
    for index in range(count):
        next_index = (index + 1) % count
        outer_top = index
        inner_top = count + index
        outer_bottom = count * 2 + index
        inner_bottom = count * 3 + index
        next_outer_top = next_index
        next_inner_top = count + next_index
        next_outer_bottom = count * 2 + next_index
        next_inner_bottom = count * 3 + next_index
        faces.extend([
            (outer_top, next_outer_top, next_inner_top, inner_top),
            (outer_bottom, inner_bottom, next_inner_bottom, next_outer_bottom),
            (outer_bottom, next_outer_bottom, next_outer_top, outer_top),
            (inner_bottom, inner_top, next_inner_top, next_inner_bottom),
        ])

    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    obj.data.materials.append(material)

    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")

    edge_bevel = obj.modifiers.new(name="ContinuousTrayEdgeBevel", type="BEVEL")
    edge_bevel.width = bevel
    edge_bevel.segments = 6
    edge_bevel.profile = 0.58
    edge_bevel.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=edge_bevel.name)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    obj.select_set(False)
    return obj


def build_table() -> list[bpy.types.Object]:
    felt_maps = generate_felt_maps()
    leather_maps = generate_surface_maps("leather", LEATHER_RAIL, 1024, 6101, 0.56, 0.0)
    frame_maps = generate_surface_maps("frame", EBONIZED_FRAME, 1024, 6201, 0.43, 0.0)
    felt = pbr_material("DeepEmeraldShortNapFelt", *felt_maps, normal_strength=0.14)
    leather = pbr_material("TailoredDarkEmeraldRail", *leather_maps, normal_strength=0.32)
    frame = pbr_material("EbonizedFurnitureFrame", *frame_maps, normal_strength=0.24)
    groove = simple_material("SubtleEmeraldFeltInset", PLAYFIELD_GROOVE, 0.78, 0.0)
    gold = simple_material("SatinChampagneGold", CHAMPAGNE_GOLD, 0.28, 0.86, coat_weight=0.025)
    gold_high = simple_material(
        "ChampagneGoldHighlight", CHAMPAGNE_HIGHLIGHT, 0.25, 0.88, coat_weight=0.02
    )

    objects = [
        rounded_box("TableEbonizedBase", (14.94, 9.74, 0.58), (0.0, 0.0, -0.31), 0.34, 12, frame),
        # The cloth continues underneath the padded rail.  The previous 13.46
        # x 8.26 top exposed the ebonized base between cloth and rail, creating
        # a heavy black moat in the real gameplay camera.  This overlap leaves
        # only the rail's natural contact shadow, matching the tailored table
        # reference without changing the playable coordinate system.
        rounded_box("TableFelt", (13.76, 8.56, 0.31), (0.0, 0.0, 0.00), 0.25, 12, felt),
        # The apron and padded rail are independent manufactured parts.  Their
        # shared curvature makes the table read as upholstered furniture while
        # preserving the exact existing playfield/牌墙 coordinate system.
        rounded_rectangle_ring(
            "DarkFurnitureApron",
            (14.82, 9.62),
            (13.72, 8.52),
            0.36,
            (0.0, 0.0, 0.055),
            0.43,
            0.25,
            16,
            0.13,
            frame,
        ),
        rounded_rectangle_ring(
            "TailoredDarkEmeraldRail",
            (14.67, 9.47),
            (13.78, 8.58),
            0.31,
            (0.0, 0.0, 0.115),
            0.39,
            0.245,
            16,
            0.12,
            leather,
        ),
        # Both cords are continuous rings.  They are deliberately thin enough
        # to feel inlaid, but thick enough to survive mobile TAA/FSR filtering.
        rounded_rectangle_ring(
            "OuterChampagneGoldPiping",
            (14.76, 9.56),
            (14.68, 9.48),
            0.055,
            (0.0, 0.0, 0.255),
            0.405,
            0.385,
            16,
            0.018,
            gold,
        ),
        rounded_rectangle_ring(
            "InnerChampagneGoldPiping",
            (13.86, 8.66),
            (13.79, 8.59),
            0.050,
            (0.0, 0.0, 0.264),
            0.265,
            0.245,
            16,
            0.016,
            gold_high,
        ),
        # Two calm tonal insets match the reference.  No centre-corner motifs,
        # black partition lines or decorative L-shapes remain on the cloth.
        rounded_rectangle_ring(
            "PlayfieldInsetOuter",
            (12.62, 7.16),
            (12.575, 7.115),
            0.008,
            (0.0, 0.0, 0.158),
            0.23,
            0.215,
            16,
            0.004,
            groove,
        ),
        rounded_rectangle_ring(
            "PlayfieldInsetInner",
            (12.42, 6.96),
            (12.395, 6.935),
            0.006,
            (0.0, 0.0, 0.157),
            0.20,
            0.19,
            16,
            0.003,
            groove,
        ),
    ]
    return objects


def export_glb(objects: list[bpy.types.Object]) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    OUTPUT_GLB.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT_GLB),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
    )
    # Blender's embedded PNG compressor can emit byte-different IDAT streams
    # for identical pixels. Canonicalise image payloads and JSON so the GLB hash
    # is a meaningful reproducibility gate rather than a compression artefact.
    subprocess.run(
        ["python3", str(PROJECT_ROOT / "tools" / "3d" / "canonicalize_glb_images.py"), str(OUTPUT_GLB)],
        check=True,
    )
    # Godot's GLB importer is configured with embedded_image_handling=1.  It
    # materialises the packed images beside the GLB and subsequently reads
    # those files, rather than the authored copies under materials/table_v2.
    # Keep that import-facing set in lockstep with every Blender regeneration;
    # otherwise an updated mesh silently renders with stale PBR maps.
    for family in ("felt", "frame", "leather"):
        for channel in ("basecolor", "normal", "orm"):
            source = TEXTURE_DIR / f"{family}_{channel}.png"
            target = OUTPUT_GLB.with_name(f"{OUTPUT_GLB.stem}_{family}_{channel}.png")
            shutil.copyfile(source, target)


if __name__ == "__main__":
    clear_scene()
    table_objects = build_table()
    export_glb(table_objects)
    triangles = 0
    for obj in table_objects:
        if hasattr(obj.data, "calc_loop_triangles"):
            obj.data.calc_loop_triangles()
            triangles += len(obj.data.loop_triangles)
    print(f"Generated {OUTPUT_GLB}")
    print(f"Generated PBR maps in {TEXTURE_DIR}")
    print(f"Object count: {len(table_objects)}; triangulated faces before exporter: {triangles}")
