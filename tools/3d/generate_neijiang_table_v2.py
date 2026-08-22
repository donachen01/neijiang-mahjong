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
TABLE_CENTER = np.array([0x4A, 0x9C, 0x78], dtype=np.float32) / 255.0
TABLE_BASE = np.array([0x34, 0x7D, 0x60], dtype=np.float32) / 255.0
TABLE_EDGE = np.array([0x07, 0x31, 0x27], dtype=np.float32) / 255.0
LEATHER_RAIL = np.array([0x03, 0x30, 0x27], dtype=np.float32) / 255.0
EBONIZED_FRAME = np.array([0x07, 0x13, 0x10], dtype=np.float32) / 255.0
CHAMPAGNE_GOLD = np.array([0xB8, 0x96, 0x50], dtype=np.float32) / 255.0
CHAMPAGNE_HIGHLIGHT = np.array([0xE9, 0xCF, 0x86], dtype=np.float32) / 255.0
CHAMPAGNE_SHADOW = np.array([0x4B, 0x35, 0x16], dtype=np.float32) / 255.0
# A near-neighbour of the felt, never a painted outline.  It is intentionally
# only a little lighter than the cloth so the double inset reads through grazing
# light without competing with tiles or the centre instrument.
PLAYFIELD_GROOVE = np.array([0x1B, 0x57, 0x44], dtype=np.float32) / 255.0
PLAYFIELD_GROOVE_HIGHLIGHT = np.array([0x3C, 0x80, 0x64], dtype=np.float32) / 255.0
INNER_CONTACT_SHADOW = np.array([0x08, 0x2F, 0x26], dtype=np.float32) / 255.0


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


def periodic_blur(field: np.ndarray, radii: tuple[int, ...]) -> np.ndarray:
    """Blur a tileable scalar field without introducing seams at the borders."""
    result = field.astype(np.float32, copy=True)
    for radius in radii:
        result = (
            result * 4.0
            + np.roll(result, radius, axis=0)
            + np.roll(result, -radius, axis=0)
            + np.roll(result, radius, axis=1)
            + np.roll(result, -radius, axis=1)
        ) / 8.0
    return result


def normalize_field(field: np.ndarray) -> np.ndarray:
    lower = float(np.percentile(field, 1.0))
    upper = float(np.percentile(field, 99.0))
    return np.clip((field - lower) / max(1.0e-6, upper - lower), 0.0, 1.0)


def generate_felt_maps(size: int = 2048) -> tuple[bpy.types.Image, bpy.types.Image, bpy.types.Image]:
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    u = x / float(size - 1)
    v = y / float(size - 1)
    rng = np.random.default_rng(5305)

    # Target-reference cloth: a restrained woven foundation under a directional
    # short nap.  The previous pass relied too heavily on isotropic colour noise;
    # after mobile mipmapping it read as fine sand rather than soft cloth.  These
    # higher-frequency, phase-warped fibres carry the detail through normals and
    # roughness, while the base colour remains calm.
    warp_a = normalize_field(periodic_blur(rng.standard_normal((size, size)), (2, 4, 8, 16))) - 0.5
    warp_b = normalize_field(periodic_blur(rng.standard_normal((size, size)), (3, 6, 12, 24))) - 0.5
    phase_a = math.tau * (u * 296.0 + v * 37.0 + warp_a * 0.18)
    phase_b = math.tau * (-u * 43.0 + v * 317.0 + warp_b * 0.16)
    thread_a = np.clip(np.sin(phase_a) * 0.5 + 0.5, 0.0, 1.0) ** 9
    thread_b = np.clip(np.sin(phase_b) * 0.5 + 0.5, 0.0, 1.0) ** 9
    intersections = np.sqrt(thread_a * thread_b)

    # The target cloth is read as a continuous premium baize surface first and
    # as individual fibres only on close inspection.  A robustly normalised raw
    # field supplies sub-pixel pin-fuzz; the lightly filtered fields below keep
    # it organic without creating the 3-8 screen-pixel cloudy blobs seen in the
    # previous mobile capture.
    pin_fuzz = normalize_field(rng.standard_normal((size, size)).astype(np.float32))
    micro = normalize_field(periodic_blur(rng.standard_normal((size, size)), (1,)))
    pixel_grain = normalize_field(periodic_blur(rng.standard_normal((size, size)), (1, 2)))
    # Short directional fibre bundles.  Rolling instead of convolving preserves
    # exact tileability, and the shallow diagonal follows the reference's
    # brushed nap without turning into visible parallel stripes.
    fibre_source = rng.standard_normal((size, size)).astype(np.float32)
    fibre_streaks = np.zeros_like(fibre_source)
    fibre_weight = 0.0
    for offset in range(-5, 6):
        weight = math.exp(-((float(offset) / 3.1) ** 2))
        fibre_streaks += np.roll(
            np.roll(fibre_source, offset, axis=1),
            int(round(offset * 0.28)),
            axis=0,
        ) * weight
        fibre_weight += weight
    fibre_streaks = normalize_field(fibre_streaks / fibre_weight)
    # Three overlapping, non-directional pile scales create dense short velvet
    # without exposing a woven grid.  ``dense_fuzz`` provides the 1-2 screen-px
    # sparkle that was still missing after mobile mipmapping; the two broader
    # fields keep it soft rather than reading as sand or compression noise.
    dense_fuzz = normalize_field(periodic_blur(rng.standard_normal((size, size)), (1, 2)))
    soft_fuzz = normalize_field(periodic_blur(rng.standard_normal((size, size)), (2, 3, 5)))
    visible_grain = normalize_field(periodic_blur(rng.standard_normal((size, size)), (5, 8, 12)))
    velvet_cloud = normalize_field(periodic_blur(rng.standard_normal((size, size)), (18, 32, 54)))
    nap = normalize_field(
        thread_a * 0.018
        + thread_b * 0.012
        + intersections * 0.008
        + fibre_streaks * 0.225
        + pin_fuzz * 0.255
        + dense_fuzz * 0.285
        + soft_fuzz * 0.150
        + visible_grain * 0.025
        + micro * 0.022
    )
    fibre_tips = np.clip(
        (pin_fuzz * 0.38 + dense_fuzz * 0.36 + soft_fuzz * 0.18 + nap * 0.08 - 0.61) / 0.39,
        0.0,
        1.0,
    ) ** 1.75

    # Colour stays calm and even; the tactile response is carried mainly by the
    # normal/roughness maps. This avoids the old cloud-shaped stains while
    # retaining the target's restrained 1-pixel emerald grain in mobile shots.
    clean_felt_color = TABLE_BASE * 0.35 + TABLE_CENTER * 0.65
    base = np.broadcast_to(clean_felt_color[None, None, :], (size, size, 3)).copy()
    # Felt is recognised by a dense field of tiny, soft highlights carried by
    # short fibres—not by a visible textile grid.  Fine and broad random pile
    # fields overlap here so mobile minification keeps the target's micro-fuzz
    # while adjacent pixels still blend into a plush continuous surface.
    colour_nap = (
        (pin_fuzz - 0.5) * 0.052
        + (pixel_grain - 0.5) * 0.026
        + (fibre_streaks - 0.5) * 0.017
        + (dense_fuzz - 0.5) * 0.038
        + (soft_fuzz - 0.5) * 0.012
        + (visible_grain - 0.5) * 0.002
        + (velvet_cloud - 0.5) * 0.001
        + (nap - 0.5) * 0.003
        + (micro - 0.5) * 0.018
    )
    base *= 1.0 + colour_nap[:, :, None]
    # The target emerald retains a muted blue component under warm light; this
    # prevents the cloth from drifting into yellow casino green on mobile.
    base *= np.array([1.035, 1.005, 1.040], dtype=np.float32)[None, None, :]
    base += fibre_tips[:, :, None] * np.array([0.007, 0.013, 0.009], dtype=np.float32)

    # Retain the deterministic audit mask asset but keep it out of the visible
    # production colour. The actual table decoration remains the two inset
    # rings authored as geometry below.
    edge_distance = np.maximum(np.abs(u - 0.5) / 0.5, np.abs(v - 0.5) / 0.5)
    perimeter = np.clip((edge_distance - 0.82) / 0.10, 0.0, 1.0)
    brocade = intersections * perimeter
    mask_rgba = np.ones((size, size, 4), dtype=np.float32)
    mask_rgba[:, :, :3] = brocade[:, :, None]
    save_non_color_image("FeltBrocadeMask2048", TEXTURE_DIR / "brocade_mask.png", mask_rgba)
    felt_base = save_rgba_image("FeltBaseColor2048", TEXTURE_DIR / "felt_basecolor.png", base)

    # The weave ridges and irregular nap are deliberately wider than one source
    # texel. After the UV repeat and mobile mipmaps they remain a fine textile
    # response instead of disappearing or shimmering.
    height = (
        (thread_a - float(thread_a.mean())) * 0.0008
        + (thread_b - float(thread_b.mean())) * 0.0006
        + (intersections - float(intersections.mean())) * 0.0004
        + (fibre_streaks - 0.5) * 0.0045
        + (pin_fuzz - 0.5) * 0.013
        + (dense_fuzz - 0.5) * 0.010
        + (soft_fuzz - 0.5) * 0.004
        + (pixel_grain - 0.5) * 0.005
        + (visible_grain - 0.5) * 0.0015
        + (micro - 0.5) * 0.005
    )
    grad_y, grad_x = np.gradient(height)
    normal = np.dstack((-grad_x * 2.65, -grad_y * 2.65, np.ones_like(height)))
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    normal_rgba = np.ones((size, size, 4), dtype=np.float32)
    normal_rgba[:, :, :3] = normal * 0.5 + 0.5
    felt_normal = save_non_color_image("FeltNormal2048", TEXTURE_DIR / "felt_normal.png", normal_rgba)

    roughness = np.clip(
        0.885
        + (pin_fuzz - 0.5) * 0.026
        + (pixel_grain - 0.5) * 0.012
        + (dense_fuzz - 0.5) * 0.022
        + (visible_grain - 0.5) * 0.005
        + (soft_fuzz - 0.5) * 0.010
        + (fibre_streaks - 0.5) * 0.014
        + (micro - 0.5) * 0.010
        - fibre_tips * 0.030,
        0.805,
        0.940,
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


def pbr_material(
    name: str,
    base: bpy.types.Image,
    normal: bpy.types.Image,
    orm: bpy.types.Image,
    normal_strength: float = 0.54,
    anisotropy: float = 0.0,
    sheen_weight: float = 0.0,
) -> bpy.types.Material:
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
    anisotropic_input = shader.inputs.get("Anisotropic IOR Level") or shader.inputs.get("Anisotropic")
    if anisotropic_input is not None:
        anisotropic_input.default_value = anisotropy
    sheen_input = shader.inputs.get("Sheen Weight") or shader.inputs.get("Sheen")
    if sheen_input is not None:
        sheen_input.default_value = sheen_weight
    sheen_roughness = shader.inputs.get("Sheen Roughness")
    if sheen_roughness is not None:
        sheen_roughness.default_value = 0.72
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


def apply_planar_repeat_uv(obj: bpy.types.Object, size: tuple[float, float], repeat: tuple[float, float]) -> None:
    """Give the tabletop predictable real-world texel density.

    Blender's default cube atlas stretched one texture over the entire 14 m
    playfield, while an overly dense repeat made mobile mipmaps erase the nap.
    A 1.6-by-1.0 planar repeat preserves square real-world texel scale.  The
    previous 3.4 repeat pushed the woven normal into coarse mip levels and left
    only sand-like colour noise at the gameplay camera.
    """
    mesh = obj.data
    uv_layer = mesh.uv_layers.active or mesh.uv_layers.new(name="FeltUV")
    for polygon in mesh.polygons:
        for loop_index in polygon.loop_indices:
            coordinate = mesh.vertices[mesh.loops[loop_index].vertex_index].co
            uv_layer.data[loop_index].uv = (
                (coordinate.x / size[0] + 0.5) * repeat[0],
                (coordinate.y / size[1] + 0.5) * repeat[1],
            )


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
    felt = pbr_material(
        "DeepEmeraldDirectionalVelvetFelt",
        *felt_maps,
        normal_strength=0.58,
        anisotropy=0.17,
        sheen_weight=0.16,
    )
    leather = pbr_material("TailoredDarkEmeraldRail", *leather_maps, normal_strength=0.38)
    frame = pbr_material("EbonizedFurnitureFrame", *frame_maps, normal_strength=0.28)
    groove = simple_material("PressedEmeraldFeltGroove", PLAYFIELD_GROOVE, 0.90, 0.0)
    groove_high = simple_material(
        "PressedEmeraldFeltEdgeHighlight", PLAYFIELD_GROOVE_HIGHLIGHT, 0.86, 0.0
    )
    inner_shadow = simple_material("SoftInnerContactShadow", INNER_CONTACT_SHADOW, 0.94, 0.0)
    gold_shadow = simple_material(
        "RecessedChampagneGoldShadow", CHAMPAGNE_SHADOW, 0.31, 0.82, coat_weight=0.01
    )
    gold = simple_material("SatinChampagneGold", CHAMPAGNE_GOLD, 0.21, 0.86, coat_weight=0.045)
    gold_high = simple_material(
        "ChampagneGoldHighlight", CHAMPAGNE_HIGHLIGHT, 0.17, 0.82, coat_weight=0.055
    )

    felt_surface = rounded_box(
        "TableFelt", (13.76, 8.56, 0.31), (0.0, 0.0, 0.00), 0.25, 12, felt
    )
    apply_planar_repeat_uv(felt_surface, (13.76, 8.56), (1.6, 1.0))

    objects = [
        rounded_box("TableEbonizedBase", (15.18, 9.98, 0.82), (0.0, 0.0, -0.44), 0.40, 12, frame),
        # The cloth continues underneath the padded rail.  The previous 13.46
        # x 8.26 top exposed the ebonized base between cloth and rail, creating
        # a heavy black moat in the real gameplay camera.  This overlap leaves
        # only the rail's natural contact shadow, matching the tailored table
        # reference without changing the playable coordinate system.
        felt_surface,
        # The apron and padded rail are independent manufactured parts.  Their
        # shared curvature makes the table read as upholstered furniture while
        # preserving the exact existing playfield/牌墙 coordinate system.
        rounded_rectangle_ring(
            "DarkFurnitureApron",
            (15.08, 9.88),
            (13.62, 8.42),
            0.56,
            (0.0, 0.0, 0.005),
            0.49,
            0.235,
            16,
            0.16,
            frame,
        ),
        rounded_rectangle_ring(
            "TailoredDarkEmeraldRail",
            (14.88, 9.68),
            (13.72, 8.52),
            0.44,
            (0.0, 0.0, 0.145),
            0.45,
            0.245,
            16,
            0.155,
            leather,
        ),
        # Each champagne cord is a three-dimensional inlay: a darker recessed
        # bed supplies the contact line, the rounded satin body catches the key
        # light, and a hairline highlight gives the continuous jewellery-like
        # response of the supplied furniture reference. The playable opening
        # and all tile coordinates remain unchanged.
        rounded_rectangle_ring(
            "OuterChampagneGoldRecess",
            (14.86, 9.66),
            (14.68, 9.48),
            0.072,
            (0.0, 0.0, 0.292),
            0.445,
            0.390,
            16,
            0.021,
            gold_shadow,
        ),
        rounded_rectangle_ring(
            "OuterChampagneGoldPiping",
            (14.82, 9.62),
            (14.70, 9.50),
            0.076,
            (0.0, 0.0, 0.326),
            0.430,
            0.392,
            16,
            0.027,
            gold,
        ),
        rounded_rectangle_ring(
            "OuterChampagneGoldGlint",
            (14.790, 9.590),
            (14.752, 9.552),
            0.026,
            (0.0, 0.0, 0.370),
            0.418,
            0.405,
            16,
            0.009,
            gold_high,
        ),
        rounded_rectangle_ring(
            "InnerChampagneGoldRecess",
            (13.93, 8.73),
            (13.77, 8.57),
            0.070,
            (0.0, 0.0, 0.296),
            0.288,
            0.238,
            16,
            0.021,
            gold_shadow,
        ),
        rounded_rectangle_ring(
            "InnerChampagneGoldPiping",
            (13.90, 8.70),
            (13.79, 8.59),
            0.074,
            (0.0, 0.0, 0.330),
            0.277,
            0.242,
            16,
            0.025,
            gold,
        ),
        rounded_rectangle_ring(
            "InnerChampagneGoldGlint",
            (13.870, 8.670),
            (13.835, 8.635),
            0.024,
            (0.0, 0.0, 0.373),
            0.267,
            0.255,
            16,
            0.008,
            gold_high,
        ),
        # The narrow dark contact band makes the cloth visibly recessed into
        # the upholstered rail without adding a painted outline to the felt.
        rounded_rectangle_ring(
            "FeltInnerContactShadow",
            (13.62, 8.42),
            (13.46, 8.26),
            0.020,
            (0.0, 0.0, 0.161),
            0.235,
            0.210,
            16,
            0.008,
            inner_shadow,
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
            groove_high,
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
