"""Render three Blender-authored premium tabletop concept options.

This is deliberately isolated from the shipping Godot assets.  It reuses the
production table proportions and the centre-instrument visual contract, but it
does not overwrite ``neijiang_table_v2.glb``.  The renders are decision aids:
one fixed camera, one fixed tile layout and one fixed lighting rig make colour,
metal inlay and pattern density directly comparable.

Usage (Blender 5.2 LTS):
    Blender --background --python render_premium_tabletop_options.py -- --scheme A
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

import bpy
from mathutils import Vector


PROJECT_ROOT = Path(__file__).resolve().parents[3]
OUTPUT_ROOT = PROJECT_ROOT / "evidence" / "neijiang_3d_ui_port_20260813" / "tabletop_design_preview_20260815"

SCHEMES = {
    "A": {
        "slug": "a_peacock_jade_champagne_gold",
        "felt": "155C55",
        "felt_center": "24736A",
        "felt_shadow": "0B403D",
        "gold": "C7A45A",
        "gold_high": "F1D486",
        "wood": "5A3024",
        "wood_dark": "2D1713",
        "gasket": "173B37",
        "outside": "17243D",
        "pattern": "1C6A61",
        "motif": "river",
        "gold_roughness": 0.28,
    },
    "B": {
        "slug": "b_black_peacock_burnished_bronze",
        "felt": "123E46",
        "felt_center": "1B5660",
        "felt_shadow": "082A31",
        "gold": "9B6A36",
        "gold_high": "D1A266",
        "wood": "38251F",
        "wood_dark": "1D1210",
        "gasket": "10282C",
        "outside": "111B2B",
        "pattern": "184B52",
        "motif": "deco",
        "gold_roughness": 0.34,
    },
    "C": {
        "slug": "c_deep_emerald_warm_gold",
        "felt": "164F3A",
        "felt_center": "226B4D",
        "felt_shadow": "0A3528",
        "gold": "C18B3A",
        "gold_high": "F4C66D",
        "wood": "573126",
        "wood_dark": "291612",
        "gasket": "13352C",
        "outside": "18263A",
        "pattern": "1C6047",
        "motif": "ruyi",
        "gold_roughness": 0.25,
    },
}


def srgb_channel(value: float) -> float:
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def color(hex_value: str, alpha: float = 1.0) -> tuple[float, float, float, float]:
    values = [int(hex_value[index:index + 2], 16) / 255.0 for index in (0, 2, 4)]
    return tuple(srgb_channel(value) for value in values) + (alpha,)


def set_input(shader: bpy.types.ShaderNodeBsdfPrincipled, names: tuple[str, ...], value) -> None:
    for name in names:
        socket = shader.inputs.get(name)
        if socket is not None:
            socket.default_value = value
            return


def ensure_principled_nodes(
    mat: bpy.types.Material,
) -> tuple[bpy.types.NodeTree, bpy.types.ShaderNodeBsdfPrincipled]:
    """Create an explicit Principled material graph for Blender 5.2+.

    Blender 5.2 deprecates ``Material.use_nodes`` and no longer guarantees that
    toggling it creates the historical default node pair.  Preview generation
    must therefore own the graph instead of looking up a possibly absent node.
    """
    mat.use_nodes = True
    tree = mat.node_tree
    if tree is None:
        raise RuntimeError(f"Material node tree unavailable for {mat.name}")
    nodes = tree.nodes
    output = next((node for node in nodes if node.type == "OUTPUT_MATERIAL"), None)
    if output is None:
        output = nodes.new("ShaderNodeOutputMaterial")
    shader = next((node for node in nodes if node.type == "BSDF_PRINCIPLED"), None)
    if shader is None:
        shader = nodes.new("ShaderNodeBsdfPrincipled")
    if not any(link.to_node == output and link.to_socket == output.inputs["Surface"] for link in tree.links):
        tree.links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    return tree, shader


def clean_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for blocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(blocks):
            if block.users == 0:
                blocks.remove(block)


def material(
    name: str,
    hex_value: str,
    *,
    roughness: float,
    metallic: float = 0.0,
    coat: float = 0.0,
    coat_roughness: float = 0.2,
    emission: str | None = None,
    emission_strength: float = 0.0,
) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    _tree, shader = ensure_principled_nodes(mat)
    set_input(shader, ("Base Color",), color(hex_value))
    set_input(shader, ("Roughness",), roughness)
    set_input(shader, ("Metallic",), metallic)
    set_input(shader, ("Coat Weight", "Clearcoat"), coat)
    set_input(shader, ("Coat Roughness", "Clearcoat Roughness"), coat_roughness)
    if emission is not None:
        set_input(shader, ("Emission Color", "Emission"), color(emission))
        set_input(shader, ("Emission Strength",), emission_strength)
    return mat


def felt_material(name: str, base_hex: str, centre_hex: str, shadow_hex: str) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    texcoord = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    separate = nodes.new("ShaderNodeSeparateXYZ")
    x_offset = nodes.new("ShaderNodeMath")
    x_offset.operation = "SUBTRACT"
    x_offset.inputs[1].default_value = 0.5
    y_offset = nodes.new("ShaderNodeMath")
    y_offset.operation = "SUBTRACT"
    y_offset.inputs[1].default_value = 0.5
    x_square = nodes.new("ShaderNodeMath")
    x_square.operation = "MULTIPLY"
    y_square = nodes.new("ShaderNodeMath")
    y_square.operation = "MULTIPLY"
    distance_sum = nodes.new("ShaderNodeMath")
    distance_sum.operation = "ADD"
    distance_sqrt = nodes.new("ShaderNodeMath")
    distance_sqrt.operation = "SQRT"
    distance_scale = nodes.new("ShaderNodeMath")
    distance_scale.operation = "MULTIPLY"
    distance_scale.inputs[1].default_value = 1.62
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.05
    ramp.color_ramp.elements[0].color = color(shadow_hex)
    ramp.color_ramp.elements[1].position = 0.78
    ramp.color_ramp.elements[1].color = color(centre_hex)
    base_stop = ramp.color_ramp.elements.new(0.42)
    base_stop.color = color(base_hex)
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 165.0
    noise.inputs["Detail"].default_value = 3.0
    noise.inputs["Roughness"].default_value = 0.76
    noise.inputs["Distortion"].default_value = 0.08
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.32
    bump.inputs["Distance"].default_value = 0.045
    rough_noise = nodes.new("ShaderNodeMapRange")
    rough_noise.inputs["From Min"].default_value = 0.0
    rough_noise.inputs["From Max"].default_value = 1.0
    rough_noise.inputs["To Min"].default_value = 0.82
    rough_noise.inputs["To Max"].default_value = 0.92
    links.new(texcoord.outputs["Generated"], mapping.inputs["Vector"])
    links.new(mapping.outputs["Vector"], separate.inputs["Vector"])
    links.new(separate.outputs["X"], x_offset.inputs[0])
    links.new(separate.outputs["Y"], y_offset.inputs[0])
    links.new(x_offset.outputs[0], x_square.inputs[0])
    links.new(x_offset.outputs[0], x_square.inputs[1])
    links.new(y_offset.outputs[0], y_square.inputs[0])
    links.new(y_offset.outputs[0], y_square.inputs[1])
    links.new(x_square.outputs[0], distance_sum.inputs[0])
    links.new(y_square.outputs[0], distance_sum.inputs[1])
    links.new(distance_sum.outputs[0], distance_sqrt.inputs[0])
    links.new(distance_sqrt.outputs[0], distance_scale.inputs[0])
    links.new(distance_scale.outputs[0], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], shader.inputs["Base Color"])
    links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    links.new(noise.outputs["Fac"], rough_noise.inputs["Value"])
    links.new(rough_noise.outputs["Result"], shader.inputs["Roughness"])
    set_input(shader, ("Sheen Weight", "Sheen"), 0.18)
    set_input(shader, ("Sheen Roughness",), 0.74)
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    return mat


def wood_material(name: str, base_hex: str, dark_hex: str) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    tree, shader = ensure_principled_nodes(mat)
    nodes = tree.nodes
    links = tree.links
    texcoord = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (0.55, 7.0, 1.2)
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 3.8
    noise.inputs["Detail"].default_value = 5.0
    noise.inputs["Roughness"].default_value = 0.62
    noise.inputs["Distortion"].default_value = 0.28
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = color(dark_hex)
    ramp.color_ramp.elements[0].position = 0.24
    ramp.color_ramp.elements[1].color = color(base_hex)
    ramp.color_ramp.elements[1].position = 0.77
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.15
    bump.inputs["Distance"].default_value = 0.06
    links.new(texcoord.outputs["Generated"], mapping.inputs["Vector"])
    links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], shader.inputs["Base Color"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    set_input(shader, ("Roughness",), 0.43)
    set_input(shader, ("Coat Weight", "Clearcoat"), 0.28)
    set_input(shader, ("Coat Roughness", "Clearcoat Roughness"), 0.24)
    return mat


def rounded_box(name: str, dimensions, location, bevel: float, mat: bpy.types.Material) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    modifier = obj.modifiers.new("ManufacturedBevel", "BEVEL")
    modifier.width = bevel
    modifier.segments = 5
    modifier.profile = 0.62
    modifier.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def rounded_loop(size: tuple[float, float], radius: float, segments: int = 14) -> list[tuple[float, float]]:
    half_x, half_y = size[0] * 0.5, size[1] * 0.5
    result: list[tuple[float, float]] = []
    for cx, cy, start in (
        (half_x - radius, half_y - radius, 0.0),
        (-half_x + radius, half_y - radius, 90.0),
        (-half_x + radius, -half_y + radius, 180.0),
        (half_x - radius, -half_y + radius, 270.0),
    ):
        for index in range(segments):
            angle = math.radians(start + index / segments * 90.0)
            result.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius))
    return result


def rectangle_ring(
    name: str,
    outer_size: tuple[float, float],
    inner_size: tuple[float, float],
    z: float,
    height: float,
    mat: bpy.types.Material,
    radius: float,
) -> bpy.types.Object:
    outer = rounded_loop(outer_size, radius)
    inner = rounded_loop(inner_size, max(0.03, radius - (outer_size[0] - inner_size[0]) * 0.5))
    count = len(outer)
    top = z + height * 0.5
    bottom = z - height * 0.5
    vertices = (
        [(x, y, top) for x, y in outer]
        + [(x, y, top) for x, y in inner]
        + [(x, y, bottom) for x, y in outer]
        + [(x, y, bottom) for x, y in inner]
    )
    faces = []
    for index in range(count):
        nxt = (index + 1) % count
        ot, it = index, count + index
        ob, ib = 2 * count + index, 3 * count + index
        not_, nit = nxt, count + nxt
        nob, nib = 2 * count + nxt, 3 * count + nxt
        faces.extend(((ot, not_, nit, it), (ob, ib, nib, nob), (ob, nob, not_, ot), (ib, it, nit, nib)))
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bevel = obj.modifiers.new("InlayEdgeBevel", "BEVEL")
    bevel.width = min(height * 0.22, 0.025)
    bevel.segments = 3
    bevel.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    return obj


def curve_object(
    name: str,
    points: list[tuple[float, float, float]],
    mat: bpy.types.Material,
    bevel_depth: float,
    *,
    cyclic: bool = False,
) -> bpy.types.Object:
    curve = bpy.data.curves.new(f"{name}Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 2
    curve.bevel_depth = bevel_depth
    curve.bevel_resolution = 3
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, coordinate in zip(spline.points, points):
        point.co = (*coordinate, 1.0)
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def rounded_inlay(
    name: str,
    size: tuple[float, float],
    radius: float,
    z: float,
    mat,
    thickness: float,
    origin: tuple[float, float] = (0.0, 0.0),
) -> None:
    points = [(origin[0] + x, origin[1] + y, z) for x, y in rounded_loop(size, radius, 18)]
    curve_object(name, points, mat, thickness, cyclic=True)


def transform_points(points, origin, mirror_x=1.0, mirror_y=1.0, z=0.188):
    return [(origin[0] + x * mirror_x, origin[1] + y * mirror_y, z) for x, y in points]


def add_corner_motifs(scheme, gold, pattern) -> None:
    motif = scheme["motif"]
    if motif == "river":
        base = [
            (0.00, 0.48), (0.00, 0.15), (0.18, 0.15), (0.18, 0.34),
            (0.36, 0.34), (0.36, 0.00), (0.70, 0.00),
        ]
        waves = [[(0.0, y + math.sin(index / 8 * math.tau) * 0.05) for index, y in enumerate([0, .08, .14, .17, .14, .08, 0, -.06, 0])] for _ in range(1)]
        for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            origin = (sx * 5.72, sy * 3.34)
            curve_object(f"RiverKey_{sx}_{sy}", transform_points(base, origin, -sx, -sy), gold, 0.022)
            wave = [(index * 0.09, math.sin(index / 8 * math.tau) * 0.055) for index in range(9)]
            curve_object(f"RiverWave_{sx}_{sy}", transform_points(wave, (origin[0] - sx * 0.03, origin[1] - sy * 0.62), -sx, -sy), pattern, 0.014)
    elif motif == "deco":
        base = [(0.0, .55), (0.0, .18), (.18, 0), (.60, 0), (.78, .18), (.78, .38), (.60, .56)]
        inner = [(0.10, .45), (.10, .22), (.25, .08), (.52, .08), (.66, .22)]
        for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            origin = (sx * 5.75, sy * 3.38)
            curve_object(f"DecoOuter_{sx}_{sy}", transform_points(base, origin, -sx, -sy), gold, 0.026)
            curve_object(f"DecoInner_{sx}_{sy}", transform_points(inner, origin, -sx, -sy), pattern, 0.016)
    else:
        # Restrained ruyi cloud: a warm-gold shoulder with a dyed inner echo.
        for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            origin = (sx * 5.72, sy * 3.36)
            points = []
            for index in range(24):
                angle = index / 23.0 * math.pi
                x = index / 23.0 * 0.92
                y = math.sin(angle) * 0.18 + math.sin(angle * 3.0) * 0.055
                points.append((x, y))
            curve_object(f"RuyiGold_{sx}_{sy}", transform_points(points, origin, -sx, -sy), gold, 0.023)
            inner = [(x * 0.78, y * 0.72) for x, y in points]
            curve_object(f"RuyiShadow_{sx}_{sy}", transform_points(inner, (origin[0] - sx * 0.05, origin[1] - sy * 0.18), -sx, -sy), pattern, 0.014)


def add_midfield_accents(scheme, gold, pattern) -> None:
    motif = scheme["motif"]
    if motif == "deco":
        for y in (-2.64, 2.64):
            points = [(-1.25, y, .186), (-.72, y, .186), (-.48, y + .14 * (1 if y < 0 else -1), .186),
                      (0, y, .186), (.48, y + .14 * (1 if y < 0 else -1), .186), (.72, y, .186), (1.25, y, .186)]
            curve_object(f"DecoMid_{y}", points, pattern, 0.012)
    else:
        for y in (-2.68, 2.68):
            for row in range(2):
                points = []
                for index in range(29):
                    x = -1.15 + index / 28 * 2.30
                    yy = y + row * (0.10 if y < 0 else -0.10) + math.sin(index / 7 * math.tau) * 0.035
                    points.append((x, yy, .184))
                curve_object(f"WaterMid_{y}_{row}", points, pattern if row else gold, 0.010 if row else 0.013)


def prism(name: str, points: list[tuple[float, float]], z: float, height: float, mat) -> bpy.types.Object:
    count = len(points)
    bottom, top = z - height * .5, z + height * .5
    vertices = [(x, y, bottom) for x, y in points] + [(x, y, top) for x, y in points]
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    for index in range(count):
        nxt = (index + 1) % count
        faces.append((index, nxt, count + nxt, count + index))
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bevel = obj.modifiers.new("PanelBevel", "BEVEL")
    bevel.width = .035
    bevel.segments = 3
    bevel.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    return obj


def add_center_instrument(gold, gold_high, dark_jade, active_yellow, pearl) -> None:
    z = .30
    # Four colour fields exactly meet at the circular counter; only pearl rays separate them.
    top = [(-1.55, .70), (1.55, .70), (.55, .18), (-.55, .18)]
    bottom = [(-1.55, -.70), (-.55, -.18), (.55, -.18), (1.55, -.70)]
    left = [(-1.55, -.70), (-.55, -.18), (-.55, .18), (-1.55, .70)]
    right = [(1.55, -.70), (1.55, .70), (.55, .18), (.55, -.18)]
    prism("DirectionTop", top, z, .11, dark_jade)
    prism("DirectionActiveBottom", bottom, z + .006, .122, active_yellow)
    prism("DirectionLeft", left, z, .11, dark_jade)
    prism("DirectionRight", right, z, .11, dark_jade)
    for start, end in (((-.55,.18),(-1.55,.70)), ((.55,.18),(1.55,.70)), ((-.55,-.18),(-1.55,-.70)), ((.55,-.18),(1.55,-.70))):
        curve_object("PearlSeparator", [(start[0], start[1], z+.069), (end[0], end[1], z+.069)], pearl, .009)
    bpy.ops.mesh.primitive_torus_add(major_radius=.48, minor_radius=.085, major_segments=64, minor_segments=12, location=(0,0,z+.16))
    outer = bpy.context.object
    outer.name = "SingleGoldCounterRing"
    outer.data.materials.append(gold)
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=.385, depth=.085, location=(0,0,z+.145))
    lens = bpy.context.object
    lens.name = "CounterLens"
    lens.data.materials.append(dark_jade)
    bpy.ops.object.text_add(location=(0, -.012, z+.205))
    text = bpy.context.object
    text.name = "WallCount17"
    text.data.body = "17"
    text.data.align_x = "CENTER"
    text.data.align_y = "CENTER"
    text.data.size = .48
    text.data.extrude = .008
    text.data.bevel_depth = .004
    text.data.materials.append(pearl)


def create_tile_materials():
    ivory = material("WarmIvoryTileFace", "F4EDD8", roughness=.42, coat=.16, coat_roughness=.28)
    edge = material("JadeTileBacking", "095B36", roughness=.38, coat=.20, coat_roughness=.22)
    red = material("TileRed", "B62226", roughness=.36)
    green = material("TileGreen", "0D6A36", roughness=.36)
    navy = material("TileNavy", "234A55", roughness=.36)
    return ivory, edge, red, green, navy


def add_face_tile(name: str, x: float, y: float, pips: int, mats) -> None:
    ivory, edge, red, green, navy = mats
    rounded_box(f"{name}Backing", (.73, 1.08, .19), (x, y, .285), .075, edge)
    rounded_box(f"{name}Face", (.70, 1.04, .17), (x, y-.015, .365), .065, ivory)
    patterns = {
        1: [(0,0,green)],
        2: [(-.15,.22,navy),(.15,-.22,green)],
        3: [(-.16,.25,navy),(0,0,red),(.16,-.25,green)],
        4: [(-.16,.25,green),(.16,.25,navy),(-.16,-.25,red),(.16,-.25,green)],
        5: [(-.16,.25,navy),(.16,.25,green),(0,0,red),(-.16,-.25,green),(.16,-.25,navy)],
        6: [(-.16,.28,green),(.16,.28,green),(-.16,0,red),(.16,0,red),(-.16,-.28,navy),(.16,-.28,navy)],
        8: [(-.16,.31,green),(.16,.31,green),(-.16,.105,green),(.16,.105,green),(-.16,-.105,red),(.16,-.105,red),(-.16,-.31,navy),(.16,-.31,navy)],
    }
    for index, (px, py, mat) in enumerate(patterns.get(pips, patterns[5])):
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=.055, depth=.018, location=(x+px,y+py-.015,.463))
        pip = bpy.context.object
        pip.name = f"{name}Pip{index}"
        pip.data.materials.append(mat)


def add_tile_context() -> None:
    mats = create_tile_materials()
    pips = [1, 2, 3, 4, 5, 6, 8, 3, 4, 6, 8, 5, 2]
    for index, pip_count in enumerate(pips):
        add_face_tile(f"SelfTile{index}", -4.68 + index * .78, -3.18, pip_count, mats)
    ivory, edge, *_ = mats
    for index in range(13):
        x = -4.25 + index * .70
        rounded_box(f"FarWall{index}", (.64,.25,.76), (x,3.05,.56), .055, edge)
        rounded_box(f"FarWallCap{index}", (.61,.255,.13), (x,2.998,.95), .045, ivory)
    for side in (-1,1):
        for index in range(10):
            y = -2.35 + index * .52
            rounded_box(f"SideWall{side}_{index}", (.25,.47,.72), (side*5.65,y,.54), .05, edge)
            rounded_box(f"SideWallCap{side}_{index}", (.255,.44,.12), (side*5.70,y,.91), .04, ivory)


def add_nameplate(name: str, x: float, y: float, z: float, scheme, gold) -> None:
    glass = material(f"{name}Glass", scheme["felt_shadow"], roughness=.26, coat=.48, coat_roughness=.18)
    rounded_box(name, (1.55,.72,.10), (x,y,z), .10, glass)
    rounded_inlay(f"{name}GoldBorder", (1.46,.63), .09, z+.065, gold, .012, (x, y))
    bpy.ops.mesh.primitive_torus_add(major_radius=.20, minor_radius=.025, major_segments=40, minor_segments=8, location=(x-.45,y,z+.09))
    coin = bpy.context.object
    coin.data.materials.append(gold)


def add_lighting_and_camera(scheme) -> None:
    world = bpy.context.scene.world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = color(scheme["outside"])
    background.inputs["Strength"].default_value = .22

    def area(name, location, energy, size, hex_value, target=(0,0,0)):
        data = bpy.data.lights.new(name, "AREA")
        data.energy = energy
        data.shape = "DISK"
        data.size = size
        data.color = tuple(int(hex_value[i:i+2],16)/255 for i in (0,2,4))
        obj = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(obj)
        obj.location = location
        point_camera(obj, target)
        return obj

    area("LargeWarmKey", (-3.5,-4.0,9.0), 1150, 7.0, "FFE2BC", (0,0,0))
    area("NeutralFill", (5.2,-1.5,6.2), 720, 5.5, "D8F0FF", (0,0,0))
    area("FarRim", (0,5.0,5.5), 920, 4.0, scheme["gold_high"], (0,1.5,.2))
    area("CenterPool", (0,0,5.0), 420, 2.4, "FFE6AF", (0,0,.2))

    camera_data = bpy.data.cameras.new("ComparisonCamera")
    camera = bpy.data.objects.new("ComparisonCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = (0,-12.8,11.5)
    camera_data.lens = 49
    camera_data.sensor_width = 36
    point_camera(camera, (0,.05,.15))
    bpy.context.scene.camera = camera


def point_camera(obj: bpy.types.Object, target) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def build_scene(scheme_key: str) -> Path:
    scheme = SCHEMES[scheme_key]
    clean_scene()
    felt = felt_material("PremiumShortNapFelt", scheme["felt"], scheme["felt_center"], scheme["felt_shadow"])
    wood = wood_material("SatinWalnut", scheme["wood"], scheme["wood_dark"])
    gasket = material("DarkInnerRail", scheme["gasket"], roughness=.58, coat=.16)
    gold = material("MetalInlay", scheme["gold"], roughness=scheme["gold_roughness"], metallic=.86, coat=.16)
    gold_high = material("MetalHighlight", scheme["gold_high"], roughness=.22, metallic=.82)
    pattern = material("DyedFeltPattern", scheme["pattern"], roughness=.88)
    dark_jade = material("InstrumentJade", "315F4B", roughness=.42, coat=.14)
    active_yellow = material("SignalYellowNotGold", "F4C430", roughness=.38, coat=.08)
    pearl = material("PearlSeparator", "F1EFE4", roughness=.36)

    rounded_box("TableFoundation", (15.3,9.95,.62), (0,0,-.34), .34, wood)
    rounded_box("ShortNapFelt", (13.62,8.42,.34), (0,0,0), .24, felt)
    rectangle_ring("SatinWalnutApron", (15.02,9.72), (13.88,8.60), .06,.38,wood,.42)
    rectangle_ring("DarkInnerGasket", (13.90,8.62), (13.58,8.30), .13,.24,gasket,.27)
    rectangle_ring("ChampagneMetalLip", (13.60,8.32), (13.49,8.21), .185,.055,gold,.22)

    # A double inset line is readable only in the furniture margin; it never
    # competes with the discard river or the live tile interaction zones.
    rounded_inlay("OuterHairlineInlay", (12.70,7.46), .25, .184, gold, .014)
    rounded_inlay("InnerShadowInlay", (12.48,7.24), .22, .181, pattern, .010)
    add_corner_motifs(scheme, gold, pattern)
    add_midfield_accents(scheme, gold, pattern)
    add_center_instrument(gold, gold_high, dark_jade, active_yellow, pearl)
    add_tile_context()
    add_nameplate("LeftNameplate", -5.15,1.55,.35,scheme,gold)
    add_nameplate("RightNameplate", 5.15,1.55,.35,scheme,gold)
    add_nameplate("TopNameplate", 4.45,2.38,.35,scheme,gold)
    add_lighting_and_camera(scheme)

    scene = bpy.context.scene
    # Blender 4.x exposed Eevee Next as ``BLENDER_EEVEE_NEXT`` while Blender
    # 5.2 exposes the production Eevee renderer as ``BLENDER_EEVEE`` again.
    # Use the enum advertised by the running build instead of pinning a name.
    render_engines = {
        item.identifier
        for item in scene.render.bl_rna.properties["engine"].enum_items
    }
    preferred_engine = next(
        (candidate for candidate in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT") if candidate in render_engines),
        "BLENDER_WORKBENCH",
    )
    scene.render.engine = preferred_engine
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    scene.render.filepath = str(OUTPUT_ROOT / f"{scheme['slug']}_1920x1080.png")
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    scene.render.image_settings.compression = 15
    scene.render.resolution_percentage = 100
    scene.render.pixel_aspect_x = 1
    scene.render.pixel_aspect_y = 1
    scene.render.film_transparent = False
    scene.render.bake.margin = 16
    try:
        scene.view_settings.look = "AgX - Medium High Contrast"
    except TypeError:
        # Keep the scene renderable on builds whose OCIO configuration uses a
        # shorter AgX look identifier; exposure and authored lights remain the
        # same, so comparisons between A/B/C stay controlled.
        pass
    scene.view_settings.exposure = .15
    scene.render.filepath = str(OUTPUT_ROOT / f"{scheme['slug']}_1920x1080.png")
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_ROOT / f"{scheme['slug']}.blend"))
    bpy.ops.render.render(write_still=True)
    return Path(scene.render.filepath)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scheme", choices=[*sorted(SCHEMES), "ALL"], required=True)
    argv = []
    if "--" in __import__("sys").argv:
        argv = __import__("sys").argv[__import__("sys").argv.index("--") + 1:]
    return parser.parse_args(argv)


if __name__ == "__main__":
    args = parse_arguments()
    scheme_keys = sorted(SCHEMES) if args.scheme == "ALL" else [args.scheme]
    for scheme_key in scheme_keys:
        output = build_scene(scheme_key)
        print(f"PREVIEW_RENDER_OK scheme={scheme_key} output={output}")
