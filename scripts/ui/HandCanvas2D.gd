extends Node2D

class_name HandCanvas2D

const TILE_FACE_SIZE := Vector2(136.0, 204.0)
const TILE_TOP_HEIGHT := 0.0
const TILE_STEP_MAX := 136.0
const TILE_STEP_MIN := 78.0
const SIDE_MARGIN := 28.0
const BASELINE_BOTTOM := 4.0
const ARC_MAX_LIFT := 0.0
const ARC_MAX_ROTATION := 0.0
const TOP_SKEW := Vector2(1.8, -2.2)
const NEW_DRAW_GAP := 22.0
const WINNING_TILE_GAP := 24.0
const SELECTED_LIFT := 10.0
const NEW_DRAW_LIFT := 8.0
const FRONT_INSET := Vector2(5.4, 5.6)
const SHADOW_OFFSET := Vector2(0.0, 6.0)
const SHADOW_ALPHA := 0.30
const SUIT_TEXTURE_Y_OFFSETS := {
	"wan": 2.0,
	"tiao": -2.0,
	"tong": -3.0,
}
const SUIT_TEXTURE_X_OFFSETS := {
	"wan": -1.5,
	"tiao": -3.0,
	"tong": -3.5,
}
const SUIT_TEXTURE_SCALES := {
	"wan": Vector2(0.9, 0.88),
	"tiao": Vector2(0.86, 0.87),
	"tong": Vector2(0.84, 0.865),
}
const SUIT_RANK_TEXTURE_SCALE_OVERRIDES := {
	"tong_8": Vector2(0.81, 0.83),
	"tong_9": Vector2(0.81, 0.83),
}
const TILE_BORDER_COLOR := Color(0.70, 0.73, 0.55, 0.88)
const TILE_FACE_COLOR := Color(0.995, 0.975, 0.905, 1.0)
const TILE_GLOSS_TOP := Color(1.0, 0.995, 0.94, 0.74)
const TILE_GLOSS_CLEAR := Color(1.0, 1.0, 1.0, 0.0)
const TILE_CORNER_RADIUS := 12
const HIGHLIGHT_COLOR := Color(0.90, 0.78, 0.50, 1.0)
const SELECTED_FACE_TINT := Color(0.995, 0.992, 0.978, 1.0)
const SELECTED_EDGE_LIGHT := Color(0.97, 0.93, 0.84, 0.92)
const SELECTED_GLOW_OUTER := Color(0.87, 0.72, 0.42, 0.20)
const SELECTED_GLOW_INNER := Color(1.0, 0.97, 0.89, 0.52)
const SELECTED_BASE_GLOW := Color(0.90, 0.74, 0.40, 0.16)
const SELECTED_SPECULAR := Color(1.0, 0.99, 0.94, 0.42)
const TILE_INNER_BORDER := Color(1.0, 0.99, 0.88, 0.82)
const TILE_INNER_SHADOW := Color(0.48, 0.45, 0.32, 0.13)
const TILE_SIDE_COLOR := Color(0.76, 0.84, 0.63, 1.0)
const TILE_SIDE_SHADE := Color(0.38, 0.53, 0.34, 0.52)
const DANGER_OUTLINE := Color(0.72, 0.28, 0.24, 0.92)
const DANGER_BANNER := Color(0.50, 0.14, 0.12, 0.92)
const RECOMMEND_CONE_HEIGHT := 56.0
const RECOMMEND_CONE_RADIUS := 24.0
const RECOMMEND_CONE_SPIN_SPEED := 2.6
const RECOMMEND_CONE_TOP := Color(1.0, 0.86, 0.20, 0.96)
const RECOMMEND_CONE_SIDE_A := Color(1.0, 0.66, 0.10, 0.90)
const RECOMMEND_CONE_SIDE_B := Color(0.92, 0.38, 0.08, 0.76)
const RECOMMEND_CONE_SHADOW := Color(0.18, 0.09, 0.02, 0.28)

var hand_tiles: Array = []
var selected_tile_id: int = -1
var new_draw_tile_id: int = -1
var viewport_size: Vector2 = Vector2.ZERO
var tile_layouts: Array = []
var trainer_markers: Dictionary = {}
var embedded_left_width: float = 0.0
var embedded_left_gap: float = 0.0
var embedded_right_width: float = 0.0
var embedded_right_gap: float = 0.0
var recommended_marker_contract: Dictionary = {}

static var texture_cache: Dictionary = {}
static var _face_stylebox: StyleBoxFlat = _build_face_stylebox()
static var _inner_border_stylebox: StyleBoxFlat = _build_inner_border_stylebox()
static var _inner_shadow_stylebox: StyleBoxFlat = _build_inner_shadow_stylebox()
static var _selected_stylebox: StyleBoxFlat = _build_selected_stylebox()


func configure(tiles: Array, selected_id: int, new_id: int, canvas_size: Vector2, markers: Dictionary = {}, layout_options: Dictionary = {}) -> void:
	hand_tiles = tiles.duplicate(true)
	selected_tile_id = selected_id
	new_draw_tile_id = new_id
	viewport_size = canvas_size
	trainer_markers = markers.duplicate(true)
	embedded_left_width = float(layout_options.get("embedded_left_width", 0.0))
	embedded_left_gap = float(layout_options.get("embedded_left_gap", 0.0))
	embedded_right_width = float(layout_options.get("embedded_right_width", 0.0))
	embedded_right_gap = float(layout_options.get("embedded_right_gap", 0.0))
	_rebuild_layout()
	queue_redraw()


func get_tile_id_at_point(point: Vector2) -> int:
	for index in range(tile_layouts.size() - 1, -1, -1):
		var layout: Dictionary = tile_layouts[index]
		var hit_rect: Rect2 = layout.get("hit_rect", Rect2())
		if hit_rect.has_point(point):
			return int(layout.get("tile_id", -1))
	return -1


func get_layout_bounds() -> Rect2:
	if tile_layouts.is_empty():
		return Rect2()
	var bounds: Rect2 = tile_layouts[0].get("outer_rect", Rect2())
	for index in range(1, tile_layouts.size()):
		var layout: Dictionary = tile_layouts[index]
		bounds = bounds.merge(layout.get("outer_rect", Rect2()))
	return bounds


func get_recommended_marker_contract() -> Dictionary:
	return recommended_marker_contract.duplicate(true)


func _draw() -> void:
	if tile_layouts.is_empty():
		return

	var selected_layouts: Array = []
	for layout in tile_layouts:
		if bool(layout.get("selected", false)):
			selected_layouts.append(layout)
		else:
			_draw_single_tile(layout)

	for layout in selected_layouts:
		_draw_single_tile(layout)

	if _has_recommended_tile():
		queue_redraw()


func _draw_single_tile(layout: Dictionary) -> void:
	var outer_rect: Rect2 = layout["outer_rect"]
	var front_rect: Rect2 = layout["front_rect"]
	var tile: Dictionary = layout["tile"]
	var is_selected: bool = layout["selected"]
	var is_new_draw: bool = layout["new_draw"]
	var is_recommended: bool = layout.get("recommended", false)
	var is_danger: bool = layout.get("danger", false)
	var is_winning_tile: bool = layout.get("winning", false)
	var rotation_degrees: float = float(layout.get("rotation", 0.0))
	var pivot := front_rect.get_center()

	var shadow_rect := front_rect
	shadow_rect.position += SHADOW_OFFSET
	shadow_rect.position -= Vector2(2.0, 1.0)
	shadow_rect.size += Vector2(4.0, 5.0)
	draw_set_transform(pivot, deg_to_rad(rotation_degrees), Vector2.ONE)
	var local_front_rect := Rect2(front_rect.position - pivot, front_rect.size)
	var local_outer_rect := Rect2(outer_rect.position - pivot, outer_rect.size)
	var local_shadow_rect := Rect2(shadow_rect.position - pivot, shadow_rect.size)

	draw_rect(local_shadow_rect, Color(0.0, 0.0, 0.0, SHADOW_ALPHA), true)

	_draw_tile_side(local_front_rect)
	draw_style_box(_selected_stylebox if is_selected or is_new_draw else _face_stylebox, local_front_rect)
	draw_style_box(_inner_shadow_stylebox, local_front_rect.grow(-1.0))
	draw_style_box(_inner_border_stylebox, local_front_rect.grow(-2.0))
	_draw_gloss_overlay(local_front_rect)

	var texture := _resolve_texture(tile)
	if texture != null:
		var texture_rect := _texture_rect_for_tile(local_front_rect, tile)
		draw_texture_rect(texture, texture_rect, false)

	if is_new_draw:
		_draw_selected_accent(local_front_rect, local_outer_rect)
	if is_danger:
		draw_rect(local_outer_rect.grow(5.0), DANGER_OUTLINE, false, 5.0)
	if is_recommended:
		_draw_recommended_cone(local_front_rect)
	if is_selected:
		_draw_selected_accent(local_front_rect, local_outer_rect)
	if is_winning_tile:
		_draw_winning_highlight(local_front_rect, local_outer_rect)
		_draw_winning_source_arrow(local_front_rect)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_banner(front_rect: Rect2, text: String, fill_color: Color) -> void:
	var badge_rect := Rect2(front_rect.position + Vector2(6.0, 6.0), Vector2(28.0, 26.0))
	draw_rect(badge_rect, fill_color, true)
	draw_rect(badge_rect, Color(1.0, 0.95, 0.82, 0.85), false, 2.0)
	var font := ThemeDB.fallback_font
	if font != null:
		var text_position := badge_rect.position + Vector2(6.0, 21.0)
		draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1, 1, 1, 1))


func _draw_tile_side(front_rect: Rect2) -> void:
	var side_dx := 6.8
	var side_dy := 8.8
	var bottom_points := PackedVector2Array([
		front_rect.position + Vector2(4.0, front_rect.size.y - 4.0),
		front_rect.position + Vector2(front_rect.size.x - 4.0, front_rect.size.y - 4.0),
		front_rect.position + Vector2(front_rect.size.x - 4.0 + side_dx, front_rect.size.y - 4.0 + side_dy),
		front_rect.position + Vector2(4.0 + side_dx, front_rect.size.y - 4.0 + side_dy),
	])
	var right_points := PackedVector2Array([
		front_rect.position + Vector2(front_rect.size.x - 4.0, 7.0),
		front_rect.position + Vector2(front_rect.size.x - 4.0, front_rect.size.y - 4.0),
		front_rect.position + Vector2(front_rect.size.x - 4.0 + side_dx, front_rect.size.y - 4.0 + side_dy),
		front_rect.position + Vector2(front_rect.size.x - 4.0 + side_dx, 7.0 + side_dy),
	])
	draw_colored_polygon(bottom_points, TILE_SIDE_COLOR)
	draw_colored_polygon(right_points, TILE_SIDE_COLOR.darkened(0.12))
	draw_line(bottom_points[0], bottom_points[1], Color(1.0, 0.99, 0.86, 0.26), 1.4)
	draw_line(right_points[0], right_points[1], TILE_SIDE_SHADE, 1.6)


func _draw_polyline_closed(points: PackedVector2Array, color: Color, width: float) -> void:
	for index in range(points.size()):
		var next_index := (index + 1) % points.size()
		draw_line(points[index], points[next_index], color, width)


func _rebuild_layout() -> void:
	tile_layouts.clear()
	recommended_marker_contract = {}
	if hand_tiles.is_empty():
		return

	var step: float = _compute_step()
	var row_width: float = TILE_FACE_SIZE.x
	if hand_tiles.size() > 1:
		row_width += step * float(hand_tiles.size() - 1)
	if _should_apply_new_draw_gap():
		row_width += NEW_DRAW_GAP
	if _should_apply_winning_tile_gap():
		row_width += WINNING_TILE_GAP
	var left_reserved := embedded_left_width + (embedded_left_gap if embedded_left_width > 0.0 and row_width > 0.0 else 0.0)
	var right_reserved := embedded_right_width + (embedded_right_gap if embedded_right_width > 0.0 and row_width > 0.0 else 0.0)
	var has_embedded_hosts := left_reserved > 0.0 or right_reserved > 0.0
	var start_x: float
	if has_embedded_hosts:
		var total_group_width: float = left_reserved + row_width + right_reserved
		var group_left: float = SIDE_MARGIN if embedded_left_width > 0.0 else floor((viewport_size.x - total_group_width) * 0.5)
		var min_group_left: float = SIDE_MARGIN
		var max_group_left: float = viewport_size.x - SIDE_MARGIN - total_group_width
		if max_group_left < min_group_left:
			group_left = min_group_left
		else:
			group_left = clampf(group_left, min_group_left, max_group_left)
		start_x = group_left + left_reserved
	else:
		start_x = floor((viewport_size.x - row_width) * 0.5)
	var front_top_y: float = viewport_size.y - BASELINE_BOTTOM - TILE_FACE_SIZE.y

	for index in range(hand_tiles.size()):
		var tile: Dictionary = hand_tiles[index]
		var tile_id := int(tile.get("id", -1))
		var x: float = start_x + float(index) * step
		if _should_apply_new_draw_gap() and index == hand_tiles.size() - 1:
			x += NEW_DRAW_GAP
		if _should_apply_winning_tile_gap() and index == hand_tiles.size() - 1:
			x += WINNING_TILE_GAP

		var arc_factor := 0.0
		var arc_lift := 0.0
		var lift := arc_lift
		if tile_id == selected_tile_id:
			lift = arc_lift + SELECTED_LIFT
		elif tile_id == new_draw_tile_id:
			lift = arc_lift + NEW_DRAW_LIFT

		var front_rect := Rect2(
			Vector2(x, front_top_y - lift),
			TILE_FACE_SIZE
		)
		var outer_rect := front_rect
		tile_layouts.append({
			"tile": tile,
			"tile_id": tile_id,
			"selected": tile_id == selected_tile_id,
			"new_draw": tile_id == new_draw_tile_id,
			"recommended": int(trainer_markers.get("recommended_tile_id", -1)) == tile_id,
			"danger": trainer_markers.get("danger_tile_ids", []).has(tile_id),
			"winning": index == hand_tiles.size() - 1 and int(trainer_markers.get("winning_tile_id", -1)) == tile_id,
			"rotation": 0.0,
			"front_rect": front_rect,
			"outer_rect": outer_rect,
			"hit_rect": outer_rect.grow_individual(10.0, 12.0, 10.0, 10.0),
		})
		if int(trainer_markers.get("recommended_tile_id", -1)) == tile_id:
			recommended_marker_contract = {
				"mode": "rotating_cone",
				"uses_outline": false,
				"is_rotating": true,
				"center": front_rect.get_center(),
				"front_rect": front_rect,
				"tile_id": tile_id,
			}


func _has_recommended_tile() -> bool:
	return int(trainer_markers.get("recommended_tile_id", -1)) != -1


func _draw_recommended_cone(front_rect: Rect2) -> void:
	var center := front_rect.get_center()
	var time := Time.get_ticks_msec() / 1000.0
	var spin := time * TAU * RECOMMEND_CONE_SPIN_SPEED
	var radius := RECOMMEND_CONE_RADIUS
	var height := RECOMMEND_CONE_HEIGHT
	var base_center := Vector2(center.x, center.y + height * 0.20)
	var tip := Vector2(center.x + cos(spin) * radius * 0.18, center.y - height * 0.42)
	var left := base_center + Vector2(cos(spin + PI * 0.88) * radius, sin(spin + PI * 0.88) * radius * 0.34)
	var right := base_center + Vector2(cos(spin - PI * 0.88) * radius, sin(spin - PI * 0.88) * radius * 0.34)
	var back := base_center + Vector2(cos(spin + PI) * radius * 0.72, sin(spin + PI) * radius * 0.26)
	var front := base_center + Vector2(cos(spin) * radius * 0.72, sin(spin) * radius * 0.26)

	draw_colored_polygon(_ellipse_points(base_center + Vector2(0, 7), radius * 0.92, radius * 0.24, 36), RECOMMEND_CONE_SHADOW)
	draw_colored_polygon(PackedVector2Array([tip, left, back]), RECOMMEND_CONE_SIDE_B)
	draw_colored_polygon(PackedVector2Array([tip, back, right]), RECOMMEND_CONE_SIDE_A.darkened(0.10))
	draw_colored_polygon(PackedVector2Array([tip, left, front]), RECOMMEND_CONE_SIDE_A)
	draw_colored_polygon(PackedVector2Array([tip, front, right]), RECOMMEND_CONE_SIDE_B.lightened(0.06))
	draw_colored_polygon(PackedVector2Array([
		tip + Vector2(0, 3),
		front.lerp(left, 0.42),
		front.lerp(right, 0.42),
	]), Color(1.0, 0.98, 0.64, 0.30))
	draw_colored_polygon(_ellipse_points(base_center, radius, radius * 0.34, 36), RECOMMEND_CONE_TOP)
	draw_arc(base_center, radius, 0.0, TAU, 48, Color(0.82, 0.38, 0.04, 0.82), 2.0)


func _ellipse_points(center: Vector2, radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(maxi(8, segments)):
		var angle := TAU * float(index) / float(maxi(8, segments))
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _arc_factor_for_index(index: int) -> float:
	if hand_tiles.size() <= 1:
		return 0.0
	var center := float(hand_tiles.size() - 1) * 0.5
	var half_span := maxf(1.0, center)
	return (float(index) - center) / half_span


func _compute_step() -> float:
	if hand_tiles.size() <= 1:
		return TILE_STEP_MAX
	var extra_gap := 0.0
	if _should_apply_new_draw_gap():
		extra_gap += NEW_DRAW_GAP
	if _should_apply_winning_tile_gap():
		extra_gap += WINNING_TILE_GAP
	var left_reserved := embedded_left_width + (embedded_left_gap if embedded_left_width > 0.0 else 0.0)
	var right_reserved := embedded_right_width + (embedded_right_gap if embedded_right_width > 0.0 else 0.0)
	var row_allowance := maxf(0.0, viewport_size.x - SIDE_MARGIN * 2.0 - TILE_FACE_SIZE.x - extra_gap - left_reserved - right_reserved)
	var fit_step := row_allowance / float(hand_tiles.size() - 1)
	return clampf(fit_step, TILE_STEP_MIN, TILE_STEP_MAX)


func _should_apply_new_draw_gap() -> bool:
	if hand_tiles.is_empty():
		return false
	return int(hand_tiles.back().get("id", -1)) == new_draw_tile_id


func _should_apply_winning_tile_gap() -> bool:
	if hand_tiles.is_empty():
		return false
	return int(trainer_markers.get("winning_tile_id", -1)) == int(hand_tiles.back().get("id", -1))


func _draw_winning_highlight(front_rect: Rect2, outer_rect: Rect2) -> void:
	var glow_rect := outer_rect.grow(6.0)
	var glow := StyleBoxFlat.new()
	glow.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	glow.border_color = Color(1.0, 0.86, 0.34, 0.72)
	glow.set_border_width_all(3)
	glow.corner_radius_top_left = 10
	glow.corner_radius_top_right = 10
	glow.corner_radius_bottom_left = 10
	glow.corner_radius_bottom_right = 10
	glow.shadow_color = Color(1.0, 0.74, 0.18, 0.20)
	glow.shadow_size = 10
	glow.shadow_offset = Vector2.ZERO
	draw_style_box(glow, glow_rect)

	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	inner.border_color = Color(1.0, 0.96, 0.76, 0.58)
	inner.set_border_width_all(2)
	inner.corner_radius_top_left = 7
	inner.corner_radius_top_right = 7
	inner.corner_radius_bottom_left = 7
	inner.corner_radius_bottom_right = 7
	draw_style_box(inner, front_rect.grow(1.5))


func _draw_winning_source_arrow(front_rect: Rect2) -> void:
	var source_seat := int(trainer_markers.get("winning_source_seat", -1))
	if source_seat <= 0:
		return
	var badge_size := Vector2(30.0, 24.0)
	var center := front_rect.get_center() + Vector2(0.0, 12.0)
	var rotation := _winning_source_arrow_rotation(source_seat)
	var points := PackedVector2Array([
		Vector2(0.0, -badge_size.y * 0.5),
		Vector2(badge_size.x * 0.56, badge_size.y * 0.46),
		Vector2(0.0, badge_size.y * 0.18),
		Vector2(-badge_size.x * 0.56, badge_size.y * 0.46),
	])
	var shadow_points := _transform_points(points, center + Vector2(0.0, 2.0), rotation)
	var arrow_points := _transform_points(points, center, rotation)
	var highlight_points := _transform_points(PackedVector2Array([
		Vector2(0.0, -badge_size.y * 0.42),
		Vector2(badge_size.x * 0.28, badge_size.y * 0.12),
		Vector2(-badge_size.x * 0.28, badge_size.y * 0.12),
	]), center + Vector2(0.0, -1.0), rotation)
	draw_colored_polygon(shadow_points, Color(0.34, 0.22, 0.02, 0.18))
	draw_colored_polygon(arrow_points, Color(1.0, 0.84, 0.18, 0.72))
	draw_colored_polygon(highlight_points, Color(1.0, 0.97, 0.70, 0.36))
	_draw_polyline_closed(arrow_points, Color(0.70, 0.48, 0.04, 0.76), 1.6)


func _winning_source_arrow_rotation(source_seat: int) -> float:
	match source_seat:
		1:
			return -PI * 0.5
		2:
			return 0.0
		3:
			return PI * 0.5
		_:
			return PI


func _transform_points(points: PackedVector2Array, center: Vector2, rotation: float) -> PackedVector2Array:
	var transformed := PackedVector2Array()
	for point in points:
		transformed.append(center + point.rotated(rotation))
	return transformed


func _resolve_texture(tile: Dictionary) -> Texture2D:
	var suit := str(tile.get("suit", ""))
	var rank := int(tile.get("rank", 0))
	if suit == "" or rank <= 0:
		return null
	var cache_key := "%s_%d" % [suit, rank]
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]
	var texture := _load_preferred_texture([
		"res://res/art/tiles/%s_%d.png" % [suit, rank],
		"res://res/art/tiles/%s_%d.jpg" % [suit, rank],
	])
	if texture != null:
		texture_cache[cache_key] = texture
	return texture


func _texture_rect_for_tile(front_rect: Rect2, tile: Dictionary) -> Rect2:
	var base_rect := Rect2(
		front_rect.position + FRONT_INSET,
		front_rect.size - FRONT_INSET * 2.0
	)
	base_rect = base_rect.grow_individual(0.4, 0.4, 0.4, 0.4)
	var suit := str(tile.get("suit", ""))
	var rank := int(tile.get("rank", 0))
	var texture_scale: Vector2 = SUIT_TEXTURE_SCALES.get(suit, Vector2.ONE)
	var suit_rank_key := "%s_%d" % [suit, rank]
	if SUIT_RANK_TEXTURE_SCALE_OVERRIDES.has(suit_rank_key):
		texture_scale = SUIT_RANK_TEXTURE_SCALE_OVERRIDES[suit_rank_key]
	var scaled_size := Vector2(
		base_rect.size.x * texture_scale.x,
		base_rect.size.y * texture_scale.y
	)
	var texture_rect := Rect2(
		base_rect.position + (base_rect.size - scaled_size) * 0.5,
		scaled_size
	)
	texture_rect.position.x += float(SUIT_TEXTURE_X_OFFSETS.get(suit, 0.0))
	var y_offset := float(SUIT_TEXTURE_Y_OFFSETS.get(suit, 0.0))
	texture_rect.position.y += y_offset
	return texture_rect


func _load_preferred_texture(paths: Array) -> Texture2D:
	for path in paths:
		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			if texture != null:
				return texture
			texture = _load_texture_from_image(path)
			if texture != null:
				return texture
	return null


func _load_texture_from_image(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


static func _build_face_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TILE_FACE_COLOR
	style.border_color = TILE_BORDER_COLOR
	style.set_border_width_all(1)
	style.corner_radius_top_left = TILE_CORNER_RADIUS
	style.corner_radius_top_right = TILE_CORNER_RADIUS
	style.corner_radius_bottom_left = TILE_CORNER_RADIUS
	style.corner_radius_bottom_right = TILE_CORNER_RADIUS
	style.shadow_color = Color(0.0, 0.0, 0.0, SHADOW_ALPHA)
	style.shadow_size = 4
	style.shadow_offset = SHADOW_OFFSET
	return style


func _draw_gloss_overlay(front_rect: Rect2) -> void:
	var overlay_height := minf(front_rect.size.y * 0.34, 34.0)
	var steps := 12
	for index in range(steps):
		var t := float(index) / float(maxi(1, steps - 1))
		var color := TILE_GLOSS_TOP.lerp(TILE_GLOSS_CLEAR, t)
		var y := front_rect.position.y + t * overlay_height
		var band_rect := Rect2(
			front_rect.position.x + 2.0 + t * 0.5,
			y + 1.0,
			front_rect.size.x - 4.0 - t,
			overlay_height / float(steps) + 2.0
		)
		var band := StyleBoxFlat.new()
		band.bg_color = color
		band.corner_radius_top_left = TILE_CORNER_RADIUS - 1
		band.corner_radius_top_right = TILE_CORNER_RADIUS - 1
		band.corner_radius_bottom_left = max(4, TILE_CORNER_RADIUS - 6)
		band.corner_radius_bottom_right = max(4, TILE_CORNER_RADIUS - 6)
		draw_style_box(band, band_rect)


static func _build_inner_border_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = TILE_INNER_BORDER
	style.set_border_width_all(1)
	style.corner_radius_top_left = TILE_CORNER_RADIUS - 2
	style.corner_radius_top_right = TILE_CORNER_RADIUS - 2
	style.corner_radius_bottom_left = TILE_CORNER_RADIUS - 2
	style.corner_radius_bottom_right = TILE_CORNER_RADIUS - 2
	return style


static func _build_inner_shadow_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = TILE_INNER_SHADOW
	style.set_border_width_all(1)
	style.corner_radius_top_left = TILE_CORNER_RADIUS - 1
	style.corner_radius_top_right = TILE_CORNER_RADIUS - 1
	style.corner_radius_bottom_left = TILE_CORNER_RADIUS - 1
	style.corner_radius_bottom_right = TILE_CORNER_RADIUS - 1
	return style


static func _build_selected_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SELECTED_FACE_TINT
	style.border_color = SELECTED_EDGE_LIGHT
	style.set_border_width_all(1)
	style.corner_radius_top_left = TILE_CORNER_RADIUS
	style.corner_radius_top_right = TILE_CORNER_RADIUS
	style.corner_radius_bottom_left = TILE_CORNER_RADIUS
	style.corner_radius_bottom_right = TILE_CORNER_RADIUS
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _draw_selected_accent(front_rect: Rect2, outer_rect: Rect2) -> void:
	draw_rect(outer_rect.grow(3.0), SELECTED_GLOW_OUTER, false, 2.0)
	draw_rect(outer_rect.grow(1.5), SELECTED_GLOW_INNER, false, 1.0)
	var specular_rect := Rect2(
		front_rect.position + Vector2(10.0, 8.0),
		Vector2(front_rect.size.x - 20.0, 14.0)
	)
	var specular := StyleBoxFlat.new()
	specular.bg_color = SELECTED_SPECULAR
	specular.corner_radius_top_left = 10
	specular.corner_radius_top_right = 10
	specular.corner_radius_bottom_left = 8
	specular.corner_radius_bottom_right = 8
	draw_style_box(specular, specular_rect)
	var glow_width := front_rect.size.x * 0.62
	var glow_y := front_rect.end.y - 5.0
	var steps := 6
	for index in range(steps):
		var t := float(index) / float(maxi(1, steps - 1))
		var alpha := (1.0 - t) * SELECTED_BASE_GLOW.a
		var width := glow_width + t * 16.0
		var x := front_rect.position.x + (front_rect.size.x - width) * 0.5
		draw_rect(
			Rect2(x, glow_y + t * 0.8, width, 4.0),
			Color(SELECTED_BASE_GLOW.r, SELECTED_BASE_GLOW.g, SELECTED_BASE_GLOW.b, alpha),
			true
		)
