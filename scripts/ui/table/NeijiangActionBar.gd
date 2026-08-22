class_name NeijiangActionBar
extends Control

signal action_selected(action: String)

const TABLE_SKIN_CATALOG := preload("res://scripts/ui/table/NeijiangTableSkinCatalog.gd")
const MAX_ACTIONS := 6
# 与四川麻将最新操作章保持一致：双按钮时给出明显更大的 iPhone 触控面，
# 多操作冲突时再逐级收紧，但仍高于旧版的 108px 密集按钮。
const PRIMARY_FOCUSED_SIZE := Vector2(368.0, 368.0)
const SECONDARY_FOCUSED_SIZE := Vector2(312.0, 312.0)
const PRIMARY_COMPACT_SIZE := Vector2(264.0, 264.0)
const SECONDARY_COMPACT_SIZE := Vector2(216.0, 216.0)
const BUTTON_DENSE := Vector2(170.0, 170.0)
const BUTTON_MAX_DENSE := Vector2(148.0, 148.0)
const BODY_FONT := preload("res://res/fonts/app_cjk.ttc")

var status_label: Label
var action_row: HBoxContainer
var action_buttons: Dictionary = {}
var reduced_motion := false
var active_skin_id := TABLE_SKIN_CATALOG.DEFAULT_SKIN_ID
var active_skin: Dictionary = TABLE_SKIN_CATALOG.get_skin(TABLE_SKIN_CATALOG.DEFAULT_SKIN_ID)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	visible = false


func render(actions: Array[Dictionary], status_text: String) -> void:
	if action_row == null:
		_build_ui()
	var visible_actions := actions.slice(0, MAX_ACTIONS)
	var visible_ids: Array[String] = []
	for action_data in visible_actions:
		var action_id := str(action_data.get("id", ""))
		if action_id.is_empty():
			continue
		visible_ids.append(action_id)
		var button := _ensure_button(action_id)
		button.text = str(action_data.get("label", action_id))
		button.disabled = not bool(action_data.get("enabled", true))
		button.visible = true
	for action_id_value in action_buttons.keys():
		var existing_id := str(action_id_value)
		(action_buttons[existing_id] as Button).visible = visible_ids.has(existing_id)
	# Keep the table view as clean as the Sichuan action UI: decisions are
	# represented by the badges themselves, not a surrounding status card.
	# Gameplay still owns `status_text` for accessibility/debug consumers.
	status_label.text = status_text
	status_label.visible = false
	visible = not visible_ids.is_empty()
	if not visible:
		return
	_apply_density(visible_ids.size())
	_apply_focus_navigation(visible_ids)
	custom_minimum_size = Vector2(
		maxf(360.0, action_row.get_combined_minimum_size().x + 44.0),
		action_row.get_combined_minimum_size().y + (52.0 if status_label.visible else 26.0)
	)


func hide_actions() -> void:
	visible = false


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled


func set_table_skin(skin_id: String) -> void:
	if not TABLE_SKIN_CATALOG.has_skin(skin_id):
		return
	active_skin_id = skin_id
	active_skin = TABLE_SKIN_CATALOG.get_skin(skin_id)
	for action_id_value in action_buttons.keys():
		var action_id := str(action_id_value)
		var button := action_buttons.get(action_id) as Button
		if button == null:
			continue
		_apply_button_style(button, action_id)
	_apply_panel_skin()


func get_button(action: String) -> Button:
	return action_buttons.get(action) as Button


func get_visible_actions() -> Array[String]:
	var result: Array[String] = []
	for action_id in action_buttons.keys():
		var button := action_buttons[action_id] as Button
		if button != null and button.visible:
			result.append(str(action_id))
	return result


func get_visual_contract() -> Dictionary:
	return {
		"maximum_actions": MAX_ACTIONS,
		"data_driven": true,
		"supports_bao_jiao": true,
		"supports_separate_an_gang": true,
		"focus_navigation": true,
		"touch_target_minimum": BUTTON_MAX_DENSE,
		"focused_primary_touch_target": PRIMARY_FOCUSED_SIZE,
		"focused_secondary_touch_target": SECONDARY_FOCUSED_SIZE,
		"material_family": "sichuan_action_badge_texture",
		"skin_binding": "active_table_skin_action_badge_texture",
		"text_hierarchy": "oversized_engraved_action_word",
		"font_path": BODY_FONT.resource_path,
	}


func _build_ui() -> void:
	if action_row != null:
		return
	var panel := PanelContainer.new()
	panel.name = "ActionBarSurface"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	margin.add_child(column)

	status_label = Label.new()
	status_label.name = "ActionStatus"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 23)
	status_label.add_theme_font_override("font", BODY_FONT)
	status_label.add_theme_color_override("font_color", Color("FFF1CD"))
	status_label.add_theme_color_override("font_outline_color", Color("26170E"))
	status_label.add_theme_constant_override("outline_size", 3)
	column.add_child(status_label)

	action_row = HBoxContainer.new()
	action_row.name = "ActionButtons"
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 14)
	column.add_child(action_row)


func _ensure_button(action_id: String) -> Button:
	var existing := action_buttons.get(action_id) as Button
	if existing != null:
		return existing
	var button := Button.new()
	button.name = "Action_%s" % action_id
	button.focus_mode = Control.FOCUS_ALL
	button.text = action_id
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_font_override("font", BODY_FONT)
	_apply_button_style(button, action_id)
	button.pressed.connect(_on_button_pressed.bind(action_id))
	action_row.add_child(button)
	action_buttons[action_id] = button
	return button


func _on_button_pressed(action_id: String) -> void:
	var button := action_buttons.get(action_id) as Button
	if button != null and not reduced_motion:
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2(0.93, 0.93), 0.06)
		tween.tween_property(button, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK)
	action_selected.emit(action_id)


func _apply_density(visible_count: int) -> void:
	var focused := visible_count > 0 and visible_count <= 2
	var target_size := SECONDARY_FOCUSED_SIZE if focused else SECONDARY_COMPACT_SIZE
	var font_size := 92 if focused else 80
	if visible_count == 5:
		target_size = BUTTON_DENSE
		font_size = 62
	elif visible_count >= 6:
		target_size = BUTTON_MAX_DENSE
		font_size = 54
	for button_value in action_buttons.values():
		var button := button_value as Button
		if button == null or not button.visible:
			continue
		var is_hu := str(button.name) == "Action_hu"
		button.custom_minimum_size = PRIMARY_FOCUSED_SIZE if focused and is_hu else (PRIMARY_COMPACT_SIZE if not focused and is_hu and visible_count <= 4 else target_size)
		button.add_theme_font_size_override("font_size", (104 if focused else 92) if is_hu and visible_count <= 4 else font_size)
		button.pivot_offset = button.custom_minimum_size * 0.5


func _apply_focus_navigation(visible_ids: Array[String]) -> void:
	var ordered: Array[Button] = []
	for action_id in visible_ids:
		var button := action_buttons.get(action_id) as Button
		if button != null:
			ordered.append(button)
	for index in range(ordered.size()):
		var previous := ordered[(index - 1 + ordered.size()) % ordered.size()]
		var next := ordered[(index + 1) % ordered.size()]
		ordered[index].focus_neighbor_left = ordered[index].get_path_to(previous)
		ordered[index].focus_neighbor_right = ordered[index].get_path_to(next)
		ordered[index].focus_previous = ordered[index].get_path_to(previous)
		ordered[index].focus_next = ordered[index].get_path_to(next)


func _apply_button_style(button: Button, action_id: String) -> void:
	var colors := _resolve_action_colors(action_id)
	var normal := _make_action_badge_style(false)
	var hover := _make_action_badge_style(false)
	hover.modulate_color = Color(1.10, 1.07, 0.92, 1.0)
	var pressed := _make_action_badge_style(true)
	var focus := _make_action_badge_style(false)
	focus.expand_margin_left = 4.0
	focus.expand_margin_top = 4.0
	focus.expand_margin_right = 4.0
	focus.expand_margin_bottom = 4.0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color(colors["text"]))
	button.add_theme_color_override("font_hover_color", Color(colors["text"]).lightened(0.10))
	button.add_theme_color_override("font_pressed_color", Color(colors["text"]).darkened(0.08))
	button.add_theme_color_override("font_disabled_color", Color(colors["text"], 0.42))
	button.add_theme_color_override("font_outline_color", Color(colors["outline"]))
	button.add_theme_constant_override("outline_size", 6)
	button.add_theme_color_override("font_shadow_color", Color(0.0, 0.02, 0.015, 0.64))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 3)


func _resolve_action_colors(action_id: String) -> Dictionary:
	var cloth := Color(active_skin.get("albedo_tint", Color("4E6F61")))
	var light := Color(active_skin.get("light_color", Color("F8E2C2")))
	var center := cloth.darkened(0.12)
	var edge := cloth.darkened(0.48)
	if action_id in ["hu", "self_hu"]:
		center = cloth.lerp(Color("B96A1B"), 0.58).lightened(0.08)
		edge = Color("6A3108")
	elif action_id == "pass":
		center = cloth.darkened(0.34)
		edge = cloth.darkened(0.62)
	elif action_id in ["gang", "an_gang", "add_gang", "bao_jiao"]:
		center = cloth.lerp(Color("6B5134"), 0.30).darkened(0.04)
		edge = cloth.darkened(0.52)
	return {
		"center": center,
		"edge": edge,
		"light": light,
		"text": light.lerp(Color("FFF7DF"), 0.56),
		"outline": edge.darkened(0.42),
	}


func _make_action_badge_style(pressed: bool) -> StyleBoxTexture:
	# This is deliberately the same skin-specific badge asset used by Sichuan
	# Mahjong. It preserves the separate dark-green centre and copper ring rather
	# than approximating the look with a flat grey circular border.
	var style := StyleBoxTexture.new()
	style.texture = ResourceLoader.load(TABLE_SKIN_CATALOG.texture_path(active_skin_id, "action_badge.png")) as Texture2D
	style.draw_center = true
	style.modulate_color = Color(0.80, 0.80, 0.80, 1.0) if pressed else Color.WHITE
	style.expand_margin_left = 3.0
	style.expand_margin_top = 3.0
	style.expand_margin_right = 3.0
	style.expand_margin_bottom = 3.0
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 4.0 if not pressed else 8.0
	style.content_margin_bottom = 8.0
	return style


func _apply_panel_skin() -> void:
	var panel := get_node_or_null("ActionBarSurface") as PanelContainer
	if panel != null:
		panel.add_theme_stylebox_override("panel", _panel_style())


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var cloth := Color(active_skin.get("albedo_tint", Color("4E6F61")))
	var light := Color(active_skin.get("light_color", Color("F8E2C2")))
	style.bg_color = Color(cloth.darkened(0.72), 0.0)
	style.border_color = Color(light, 0.0)
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	style.shadow_size = 0
	return style
