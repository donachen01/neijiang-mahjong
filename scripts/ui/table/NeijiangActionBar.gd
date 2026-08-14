class_name NeijiangActionBar
extends Control

signal action_selected(action: String)

const ACTION_TEXTURES := {
	"hu": preload("res://res/art/ui/table_v2/action_hu.png"),
	"gang": preload("res://res/art/ui/table_v2/action_gang.png"),
	"peng": preload("res://res/art/ui/table_v2/action_peng.png"),
	"pass": preload("res://res/art/ui/table_v2/action_pass.png"),
}
const MAX_ACTIONS := 6
const BUTTON_LARGE := Vector2(148.0, 148.0)
const BUTTON_COMPACT := Vector2(122.0, 122.0)
const BUTTON_DENSE := Vector2(108.0, 108.0)
const BODY_FONT := preload("res://res/fonts/app_cjk.ttc")

var status_label: Label
var action_row: HBoxContainer
var action_buttons: Dictionary = {}
var reduced_motion := false


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
	status_label.text = status_text
	status_label.visible = not status_text.is_empty()
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
		"touch_target_minimum": BUTTON_DENSE,
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
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
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
	action_row.add_theme_constant_override("separation", 8)
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
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("FFF0B2"))
	button.add_theme_color_override("font_outline_color", Color("3B170B"))
	button.add_theme_constant_override("outline_size", 5)
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
	var target_size := BUTTON_LARGE
	var font_size := 34
	if visible_count >= 5:
		target_size = Vector2(116.0, 116.0)
		font_size = 29
	elif visible_count == 4:
		target_size = BUTTON_COMPACT
		font_size = 30
	for button_value in action_buttons.values():
		var button := button_value as Button
		if button == null or not button.visible:
			continue
		button.custom_minimum_size = target_size
		button.add_theme_font_size_override("font_size", font_size)
		button.pivot_offset = target_size * 0.5


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
	var visual_id := _visual_role(action_id)
	var texture := ACTION_TEXTURES.get(visual_id) as Texture2D
	var normal := StyleBoxTexture.new()
	normal.texture = texture
	normal.set_texture_margin_all(20)
	var hover := normal.duplicate() as StyleBoxTexture
	hover.modulate_color = Color("FFF1C0")
	var pressed := normal.duplicate() as StyleBoxTexture
	pressed.modulate_color = Color("D9B76B")
	var focus := normal.duplicate() as StyleBoxTexture
	focus.modulate_color = Color("FFF7D2")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)


func _visual_role(action_id: String) -> String:
	if action_id in ["hu", "self_hu"]:
		return "hu"
	if action_id in ["gang", "an_gang", "add_gang", "bao_jiao"]:
		return "gang"
	if action_id == "peng":
		return "peng"
	return "pass"


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.10, 0.84)
	style.border_color = Color(0.72, 0.50, 0.24, 0.82)
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 10
	return style
