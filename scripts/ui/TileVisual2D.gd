extends Control

class_name TileVisual2D

const BASE_SIZE := Vector2(92.0, 140.0)
const BASE_TOP_SKEW := Vector2(3.0, -5.0)
const BASE_FRONT_INSET := Vector2(6.0, 5.8)
const BASE_SHADOW_OFFSET := Vector2(0.0, 5.4)
const SUIT_TEXTURE_Y_OFFSETS := {
	"wan": 0.0,
	"tiao": -1.0,
	"tong": -1.0,
}
const FACE_COLOR := Color(1.0, 0.968, 0.885, 1.0)
const FACE_BACK_COLOR := Color(0.28, 0.54, 0.16, 1.0)
const TOP_FACE_COLOR := Color(1.0, 0.992, 0.944, 1.0)
const TOP_BACK_COLOR := Color(0.42, 0.66, 0.22, 1.0)
const TOP_FACE_HIGHLIGHT := Color(1.0, 1.0, 0.96, 0.42)
const TOP_FACE_SEAM := Color(0.82, 0.76, 0.58, 0.28)
const BORDER_COLOR := Color(0.82, 0.78, 0.60, 0.62)
const BACK_BORDER_COLOR := Color(0.64, 0.82, 0.40, 0.24)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.34)
const EDGE_LIGHT_COLOR := Color(1.0, 1.0, 0.92, 0.48)
const EDGE_SHADE_COLOR := Color(0.42, 0.42, 0.30, 0.24)
const FACE_TOP_SHADOW := Color(1.0, 0.98, 0.82, 0.12)
const FACE_BOTTOM_SOFT_SHADE := Color(0.44, 0.38, 0.24, 0.10)
const BACK_EDGE_LIGHT := Color(0.78, 0.90, 0.48, 0.16)
const BACK_EDGE_SHADE := Color(0.04, 0.18, 0.055, 0.28)
const BACK_GLAZE_TOP := Color(0.74, 0.88, 0.48, 0.12)
const BACK_GLAZE_CLEAR := Color(0.28, 0.54, 0.16, 0.0)
const BACK_BOTTOM_SHADE := Color(0.035, 0.16, 0.04, 0.19)
const TILE_SIDE_COLOR := Color(0.82, 0.88, 0.68, 1.0)
const TILE_SIDE_SHADE := Color(0.40, 0.51, 0.34, 0.52)
const TILE_BACK_SIDE_COLOR := Color(0.18, 0.40, 0.12, 1.0)
const TILE_BACK_SIDE_SHADE := Color(0.035, 0.20, 0.055, 0.62)
const FACE_INNER_RIM := Color(0.68, 0.58, 0.36, 0.18)
const FACE_INNER_LIGHT := Color(1.0, 1.0, 0.91, 0.20)
const FACE_RIGHT_GLAZE := Color(0.46, 0.38, 0.23, 0.10)
const BACK_INNER_RIM := Color(0.08, 0.24, 0.06, 0.20)
const BACK_INNER_LIGHT := Color(0.88, 1.0, 0.52, 0.13)
const TILE_CORNER_RADIUS := 16
const TILE_FACE_SURFACE_PATH := "res://res/art/ui_3d_cartoon/tile_face_table.png"
const TILE_BACK_SURFACE_PATH := "res://res/art/ui_3d_cartoon/tile_back_table.png"
const TILE_SYMBOL_DIR := "res://res/art/ui_3d_cartoon/tile_symbols"
const HIGHLIGHT_COLOR := Color(1.0, 0.82, 0.28, 1.0)
const SELECT_COLOR := Color(0.97, 0.93, 0.84, 0.92)
const RECENT_DISCARD_PULSE_SPEED := 0.0064
const RECENT_DISCARD_PULSE_RANGE := 0.010
const INNER_BORDER_COLOR := Color(0.0, 0.0, 0.0, 0.0)
const INNER_SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.0)

var tile_data: Dictionary = {}
var tile_scale: float = 1.0
var show_back: bool = false
var is_new_draw: bool = false
var is_selected: bool = false
var is_recent_discard: bool = false

static var texture_cache: Dictionary = {}
static var face_stylebox: StyleBoxFlat = _build_face_stylebox()
static var back_stylebox: StyleBoxFlat = _build_back_stylebox()


func configure(tile: Dictionary, scale_factor: float, should_show_back: bool = false, highlight_new_draw: bool = false, highlight_selected: bool = false, highlight_recent_discard: bool = false) -> void:
	tile_data = tile
	tile_scale = scale_factor
	show_back = should_show_back
	is_new_draw = highlight_new_draw
	is_selected = highlight_selected
	is_recent_discard = highlight_recent_discard
	custom_minimum_size = _visual_size()
	size = custom_minimum_size
	pivot_offset = custom_minimum_size * 0.5
	scale = Vector2.ONE
	set_process(is_recent_discard)
	queue_redraw()


func _process(_delta: float) -> void:
	if is_recent_discard:
		var pulse_phase := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * RECENT_DISCARD_PULSE_SPEED)
		var pulse_scale := 1.0 + pulse_phase * RECENT_DISCARD_PULSE_RANGE
		scale = Vector2.ONE * pulse_scale
		queue_redraw()
	else:
		scale = Vector2.ONE


func _draw() -> void:
	var front_rect: Rect2 = Rect2(Vector2(0.0, _top_skew().y * -1.0), _face_size())
	var top_points: PackedVector2Array = PackedVector2Array([
		Vector2(front_rect.position.x, front_rect.position.y),
		Vector2(front_rect.end.x, front_rect.position.y),
		Vector2(front_rect.end.x, front_rect.position.y) + _top_skew(),
		Vector2(front_rect.position.x, front_rect.position.y) + _top_skew(),
	])
	var outer_rect: Rect2 = front_rect.expand(top_points[2]).expand(top_points[3])

	var shadow_rect := front_rect
	shadow_rect.position += _shadow_offset()
	shadow_rect.position -= Vector2(2.4, 0.8) * tile_scale
	shadow_rect.size += Vector2(6.6, 6.8) * tile_scale
	var surface_texture := _load_tile_surface(show_back)
	if surface_texture != null:
		var surface_rect := front_rect.grow_individual(5.0 * tile_scale, 3.0 * tile_scale, 13.0 * tile_scale, 17.0 * tile_scale)
		draw_texture_rect(surface_texture, surface_rect, false)
		_draw_inset_face_rim(front_rect)
	else:
		draw_rect(shadow_rect, SHADOW_COLOR, true)
		_draw_tile_side(front_rect, show_back)
		draw_style_box(back_stylebox if show_back else face_stylebox, front_rect)
		_draw_gloss_overlay(front_rect)
		_draw_inset_face_rim(front_rect)

	var texture: Texture2D = _resolve_texture()
	if texture != null and not show_back:
		var texture_rect := _texture_rect(front_rect)
		draw_texture_rect(texture, texture_rect, false)

	if show_back and surface_texture == null:
		_draw_back_pattern(front_rect)

	if is_selected:
		draw_rect(outer_rect.grow(2.0 * tile_scale), SELECT_COLOR, false, maxf(2.0, 2.0 * tile_scale))
	if is_new_draw:
		draw_rect(outer_rect.grow(2.0 * tile_scale), HIGHLIGHT_COLOR, false, maxf(2.0, 2.0 * tile_scale))
	if is_recent_discard:
		var blink_phase := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 120.0)
		_draw_recent_discard_accent(outer_rect, blink_phase)


func _draw_gloss_overlay(front_rect: Rect2) -> void:
	var overlay_height := minf(front_rect.size.y * (0.42 if show_back else 0.38), 42.0 * tile_scale)
	var steps := 12
	for index in range(steps):
		var t := float(index) / float(maxi(1, steps - 1))
		var alpha := lerpf(0.34 if show_back else 0.38, 0.0, t)
		var y := front_rect.position.y + t * overlay_height
		var band_rect := Rect2(
			front_rect.position.x + (2.2 + t * 0.4) * tile_scale,
			y + 0.9 * tile_scale,
			front_rect.size.x - (4.4 + t * 0.8) * tile_scale,
			overlay_height / float(steps) + 2.0 * tile_scale
		)
		var band := StyleBoxFlat.new()
		band.bg_color = Color(1.0, 1.0, 0.94, alpha) if not show_back else BACK_GLAZE_TOP.lerp(BACK_GLAZE_CLEAR, t)
		band.corner_radius_top_left = maxi(4, TILE_CORNER_RADIUS - 1)
		band.corner_radius_top_right = maxi(4, TILE_CORNER_RADIUS - 1)
		band.corner_radius_bottom_left = maxi(3, TILE_CORNER_RADIUS - 7)
		band.corner_radius_bottom_right = maxi(3, TILE_CORNER_RADIUS - 7)
		draw_style_box(band, band_rect)


func _draw_inset_face_rim(front_rect: Rect2) -> void:
	var radius := maxi(4, int(round((TILE_CORNER_RADIUS - 5) * tile_scale)))
	var inset := maxf(2.4, 3.6 * tile_scale)
	var rim_rect := front_rect.grow(-inset)
	if rim_rect.size.x <= 0.0 or rim_rect.size.y <= 0.0:
		return

	var rim := StyleBoxFlat.new()
	rim.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	rim.border_color = BACK_INNER_RIM if show_back else FACE_INNER_RIM
	rim.set_border_width_all(maxi(1, int(round(1.35 * tile_scale))))
	rim.corner_radius_top_left = radius
	rim.corner_radius_top_right = radius
	rim.corner_radius_bottom_left = radius
	rim.corner_radius_bottom_right = radius
	rim.anti_aliasing = true
	rim.anti_aliasing_size = 1.2
	draw_style_box(rim, rim_rect)

	var top_highlight := Rect2(
		rim_rect.position + Vector2(2.2, 1.6) * tile_scale,
		Vector2(rim_rect.size.x - 4.4 * tile_scale, maxf(1.0, 1.7 * tile_scale))
	)
	var left_highlight := Rect2(
		rim_rect.position + Vector2(1.7, 4.0) * tile_scale,
		Vector2(maxf(1.0, 1.4 * tile_scale), rim_rect.size.y * 0.46)
	)
	var right_shade := Rect2(
		rim_rect.position + Vector2(rim_rect.size.x - 3.3 * tile_scale, rim_rect.size.y * 0.18),
		Vector2(maxf(1.0, 1.5 * tile_scale), rim_rect.size.y * 0.68)
	)
	draw_rect(top_highlight, BACK_INNER_LIGHT if show_back else FACE_INNER_LIGHT, true)
	draw_rect(left_highlight, BACK_INNER_LIGHT if show_back else FACE_INNER_LIGHT, true)
	draw_rect(right_shade, BACK_EDGE_SHADE if show_back else FACE_RIGHT_GLAZE, true)
	draw_rect(Rect2(front_rect.position + Vector2(2.0, 0.32) * tile_scale, Vector2(front_rect.size.x - 4.0 * tile_scale, 1.2 * tile_scale)), FACE_TOP_SHADOW if not show_back else BACK_EDGE_LIGHT, true)
	draw_rect(Rect2(front_rect.position + Vector2(2.6, front_rect.size.y - 8.0 * tile_scale), Vector2(front_rect.size.x - 5.2 * tile_scale, 3.4 * tile_scale)), FACE_BOTTOM_SOFT_SHADE if not show_back else BACK_BOTTOM_SHADE, true)
	draw_line(front_rect.position + Vector2(front_rect.size.x - 1.4 * tile_scale, 2.4 * tile_scale), front_rect.position + Vector2(front_rect.size.x - 1.4 * tile_scale, front_rect.size.y - 3.0 * tile_scale), EDGE_SHADE_COLOR if not show_back else BACK_EDGE_SHADE, maxf(1.0, 1.25 * tile_scale))


func _draw_tile_side(front_rect: Rect2, use_back_side: bool) -> void:
	var side_dx := 5.6 * tile_scale
	var side_dy := 7.4 * tile_scale
	var side_color := TILE_BACK_SIDE_COLOR if use_back_side else TILE_SIDE_COLOR
	var shade_color := TILE_BACK_SIDE_SHADE if use_back_side else TILE_SIDE_SHADE
	var bottom_points := PackedVector2Array([
		front_rect.position + Vector2(3.0 * tile_scale, front_rect.size.y - 3.0 * tile_scale),
		front_rect.position + Vector2(front_rect.size.x - 3.0 * tile_scale, front_rect.size.y - 3.0 * tile_scale),
		front_rect.position + Vector2(front_rect.size.x - 3.0 * tile_scale + side_dx, front_rect.size.y - 3.0 * tile_scale + side_dy),
		front_rect.position + Vector2(3.0 * tile_scale + side_dx, front_rect.size.y - 3.0 * tile_scale + side_dy),
	])
	var right_points := PackedVector2Array([
		front_rect.position + Vector2(front_rect.size.x - 3.0 * tile_scale, 4.0 * tile_scale),
		front_rect.position + Vector2(front_rect.size.x - 3.0 * tile_scale, front_rect.size.y - 3.0 * tile_scale),
		front_rect.position + Vector2(front_rect.size.x - 3.0 * tile_scale + side_dx, front_rect.size.y - 3.0 * tile_scale + side_dy),
		front_rect.position + Vector2(front_rect.size.x - 3.0 * tile_scale + side_dx, 4.0 * tile_scale + side_dy),
	])
	draw_colored_polygon(bottom_points, side_color)
	draw_colored_polygon(right_points, side_color.darkened(0.12))
	draw_line(bottom_points[0], bottom_points[1], Color(1.0, 1.0, 0.88, 0.22), maxf(1.0, 1.2 * tile_scale))
	draw_line(right_points[0], right_points[1], shade_color, maxf(1.0, 1.4 * tile_scale))


func _draw_recent_discard_accent(outer_rect: Rect2, pulse_phase: float) -> void:
	var glow_rect := outer_rect.grow(4.0 * tile_scale)
	var glow := StyleBoxFlat.new()
	glow.bg_color = Color(1.0, 0.86, 0.42, 0.035 + pulse_phase * 0.025)
	glow.border_color = Color(1.0, 0.88, 0.50, 0.28 + pulse_phase * 0.10)
	glow.set_border_width_all(maxi(1, int(round(1.0 * tile_scale))))
	glow.corner_radius_top_left = TILE_CORNER_RADIUS + 2
	glow.corner_radius_top_right = TILE_CORNER_RADIUS + 2
	glow.corner_radius_bottom_left = TILE_CORNER_RADIUS + 2
	glow.corner_radius_bottom_right = TILE_CORNER_RADIUS + 2
	glow.shadow_color = Color(1.0, 0.72, 0.24, 0.18 + pulse_phase * 0.08)
	glow.shadow_size = maxi(4, int(round(7.0 * tile_scale)))
	glow.shadow_offset = Vector2.ZERO
	draw_style_box(glow, glow_rect)

	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	inner.border_color = Color(1.0, 0.96, 0.76, 0.24 + pulse_phase * 0.08)
	inner.set_border_width_all(maxi(1, int(round(0.8 * tile_scale))))
	inner.corner_radius_top_left = TILE_CORNER_RADIUS
	inner.corner_radius_top_right = TILE_CORNER_RADIUS
	inner.corner_radius_bottom_left = TILE_CORNER_RADIUS
	inner.corner_radius_bottom_right = TILE_CORNER_RADIUS
	draw_style_box(inner, outer_rect.grow(1.2 * tile_scale))

	var base_width := outer_rect.size.x * 0.62
	var base_rect := Rect2(
		outer_rect.position + Vector2((outer_rect.size.x - base_width) * 0.5, outer_rect.size.y - 1.5 * tile_scale),
		Vector2(base_width, 3.0 * tile_scale)
	)
	draw_rect(base_rect, Color(1.0, 0.72, 0.24, 0.12 + pulse_phase * 0.05), true)


func _draw_back_pattern(front_rect: Rect2) -> void:
	var edge_inset := 5.0 * tile_scale
	var top_line := Rect2(front_rect.position + Vector2(edge_inset, 3.8 * tile_scale), Vector2(front_rect.size.x - edge_inset * 2.0, 1.4 * tile_scale))
	var bottom_line := Rect2(front_rect.position + Vector2(edge_inset, front_rect.size.y - 6.5 * tile_scale), Vector2(front_rect.size.x - edge_inset * 2.0, 2.0 * tile_scale))
	draw_rect(top_line, BACK_EDGE_LIGHT, true)
	draw_rect(bottom_line, BACK_BOTTOM_SHADE, true)
	draw_line(
		front_rect.position + Vector2(front_rect.size.x - 3.2 * tile_scale, 7.0 * tile_scale),
		front_rect.position + Vector2(front_rect.size.x - 3.2 * tile_scale, front_rect.size.y - 8.0 * tile_scale),
		BACK_EDGE_SHADE,
		maxf(1.0, 1.0 * tile_scale)
	)


func _draw_polygon_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	for index in range(points.size()):
		var next_index: int = (index + 1) % points.size()
		draw_line(points[index], points[next_index], color, width)


func _visual_size() -> Vector2:
	return Vector2(
		_face_size().x + maxf(absf(_top_skew().x), 6.0 * tile_scale),
		_face_size().y + absf(_top_skew().y) + 8.0 * tile_scale
	)


func _face_size() -> Vector2:
	return BASE_SIZE * tile_scale


func _top_skew() -> Vector2:
	return BASE_TOP_SKEW * tile_scale


func _shadow_offset() -> Vector2:
	return BASE_SHADOW_OFFSET * tile_scale


func _front_inset() -> Vector2:
	return BASE_FRONT_INSET * tile_scale


func _texture_rect(front_rect: Rect2) -> Rect2:
	var inset: Vector2 = _front_inset()
	var texture_rect := Rect2(front_rect.position + inset, front_rect.size - inset * 2.0)
	texture_rect = texture_rect.grow_individual(0.9 * tile_scale, 1.1 * tile_scale, 0.9 * tile_scale, 0.8 * tile_scale)
	var suit: String = str(tile_data.get("suit", ""))
	texture_rect.position.y += float(SUIT_TEXTURE_Y_OFFSETS.get(suit, 0.0)) * tile_scale
	texture_rect.position.x -= 0.15 * tile_scale
	return texture_rect


func _resolve_texture() -> Texture2D:
	if show_back:
		return null
	var suit: String = str(tile_data.get("suit", ""))
	var rank: int = int(tile_data.get("rank", 0))
	if suit == "" or rank <= 0:
		return null
	return _load_preferred_texture([
		"%s/%s_%d.png" % [TILE_SYMBOL_DIR, suit, rank],
		"res://res/art/tiles/%s_%d.png" % [suit, rank],
		"res://res/art/tiles/%s_%d.jpg" % [suit, rank],
	])


func _load_tile_surface(back: bool) -> Texture2D:
	return _load_texture(TILE_BACK_SURFACE_PATH if back else TILE_FACE_SURFACE_PATH)


func _load_texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture == null:
		texture = _load_texture_from_image(path)
	if texture != null:
		texture_cache[path] = texture
	return texture


func _load_preferred_texture(paths: Array) -> Texture2D:
	for path in paths:
		if ResourceLoader.exists(path):
			return _load_texture(path)
	return null


func _load_texture_from_image(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


static func _build_face_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = FACE_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(1)
	style.corner_radius_top_left = TILE_CORNER_RADIUS
	style.corner_radius_top_right = TILE_CORNER_RADIUS
	style.corner_radius_bottom_left = TILE_CORNER_RADIUS
	style.corner_radius_bottom_right = TILE_CORNER_RADIUS
	style.shadow_color = SHADOW_COLOR
	style.shadow_size = 4
	style.shadow_offset = BASE_SHADOW_OFFSET
	return style


static func _build_back_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = FACE_BACK_COLOR
	style.border_color = BACK_BORDER_COLOR
	style.set_border_width_all(1)
	style.corner_radius_top_left = TILE_CORNER_RADIUS
	style.corner_radius_top_right = TILE_CORNER_RADIUS
	style.corner_radius_bottom_left = TILE_CORNER_RADIUS
	style.corner_radius_bottom_right = TILE_CORNER_RADIUS
	return style
