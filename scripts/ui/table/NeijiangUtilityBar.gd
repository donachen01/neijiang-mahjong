class_name NeijiangUtilityBar
extends Control

signal utility_selected(action: String)

const BUTTON_SIZE := Vector2(310.0, 82.0)
const BUTTON_GAP := 10
const TOGGLE_SIZE := Vector2(104.0, 104.0)
const DRAWER_LEFT := 246.0
const BODY_FONT := preload("res://res/fonts/app_cjk.ttc")

var buttons: Dictionary = {}
var button_column: GridContainer
var panel: PanelContainer
var toggle_button: Button
var collapsed := true
var last_pointer_toggle_msec := -1000
var active_skin_id := NeijiangTableSkinCatalog.DEFAULT_SKIN_ID


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func render(snapshot: Dictionary, ai_helper_enabled: bool, opponent_hands_enabled: bool, voice_language: String = "mandarin") -> void:
	if button_column == null:
		_build_ui()
	_set_button_text("difficulty", "AI · %s" % _difficulty_label(snapshot))
	_set_button_text("helper", "AI提示 · %s" % ("开" if ai_helper_enabled else "关"))
	_set_button_text("opponents", "明牌 · %s" % ("开" if opponent_hands_enabled else "关"))
	_set_button_text("voice", "语音 · %s" % ("四川话" if voice_language == "sichuan" else "普通话"))
	var settlement_visible := int(snapshot.get("current_phase", 0)) == 7
	_set_button_visible("settlement", true)
	_set_button_visible("next_round", settlement_visible)
	_set_button_text("settlement", "☷  对局详情")
	var next_button := buttons.get("next_round") as Button
	if next_button != null:
		next_button.disabled = not settlement_visible


func get_button(action: String) -> Button:
	if action == "toggle":
		return toggle_button
	return buttons.get(action) as Button


func get_visual_contract() -> Dictionary:
	return {
		"safe_area_owned_by_parent": true,
		"focus_navigation": true,
		"touch_target": BUTTON_SIZE,
		"collapsed_by_default": true,
		"anchor": "top_left",
		"actions": buttons.keys(),
		"font_path": BODY_FONT.resource_path,
	}


func set_collapsed(value: bool) -> void:
	collapsed = value
	_apply_collapsed_state()


func is_collapsed() -> bool:
	return collapsed


func set_table_skin(skin_id: String) -> void:
	if not NeijiangTableSkinCatalog.has_skin(skin_id):
		return
	active_skin_id = skin_id
	if toggle_button == null:
		return
	toggle_button.add_theme_stylebox_override("normal", _button_style(Color("122C27"), Color("B88943"), 1, 52))
	toggle_button.add_theme_stylebox_override("hover", _button_style(Color("245A42"), Color("E2BC6A"), 2, 52))
	toggle_button.add_theme_stylebox_override("pressed", _button_style(Color("102E27"), Color("E2BC6A"), 2, 52))
	toggle_button.add_theme_color_override("font_color", Color("F8FCFF") if skin_id == "blue_glass" else Color("FFF0CF"))
	toggle_button.add_theme_color_override("font_outline_color", Color.TRANSPARENT if skin_id == "blue_glass" else Color("24150C"))
	panel.add_theme_stylebox_override("panel", _panel_style())
	for value in buttons.values():
		var button := value as Button
		button.add_theme_stylebox_override("normal", _button_style(Color("173D31"), Color("B88943"), 1))
		button.add_theme_stylebox_override("hover", _button_style(Color("245A42"), Color("E2BC6A"), 2))
		button.add_theme_stylebox_override("pressed", _button_style(Color("102E27"), Color("E2BC6A"), 2))
		button.add_theme_color_override("font_color", Color("F8FCFF") if skin_id == "blue_glass" else Color("FFF0CF"))
		button.add_theme_color_override("font_outline_color", Color.TRANSPARENT if skin_id == "blue_glass" else Color("24150C"))


func activate_at_global_position(global_position: Vector2, enforce_pointer_debounce: bool = true) -> bool:
	# MainScene 在 _input 阶段显式转发鼠标和触摸，因此即使全屏 3D
	# 输入层优先于 Control GUI，折叠键和抽屉动作仍能稳定响应。
	if toggle_button != null and toggle_button.visible \
		and toggle_button.get_global_rect().has_point(global_position):
		var now := Time.get_ticks_msec()
		# Godot 缩放视口在某些窗口尺寸下会将同一次原生按下转成
		# 两次紧邻的鼠标事件。在独立状态机入口去重，避免展开后立即收起。
		if enforce_pointer_debounce and now - last_pointer_toggle_msec < 160:
			return true
		last_pointer_toggle_msec = now
		set_collapsed(not collapsed)
		return true
	return false


func _build_ui() -> void:
	if button_column != null:
		return
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	toggle_button = Button.new()
	toggle_button.name = "UtilityToggle"
	toggle_button.text = "☰"
	toggle_button.tooltip_text = "展开牌桌工具"
	toggle_button.custom_minimum_size = TOGGLE_SIZE
	toggle_button.size = TOGGLE_SIZE
	toggle_button.focus_mode = Control.FOCUS_ALL
	# 指针事件由 MainScene 的 3D UI 输入路由统一处理，避免 Button GUI
	# 与 _input 在同一次鼠标按下中各翻转一次，导致视觉上“点不开”。
	# 键盘/手柄焦点激活不受 mouse_filter 影响，仍走 pressed 信号。
	toggle_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle_button.add_theme_font_size_override("font_size", 52)
	toggle_button.add_theme_color_override("font_color", Color("FFF0CF"))
	toggle_button.add_theme_color_override("font_outline_color", Color("24150C"))
	toggle_button.add_theme_constant_override("outline_size", 2)
	toggle_button.add_theme_stylebox_override("normal", _button_style(Color("122C27"), Color("B88943"), 1, 12))
	toggle_button.add_theme_stylebox_override("hover", _button_style(Color("245A42"), Color("E2BC6A"), 2, 12))
	toggle_button.add_theme_stylebox_override("pressed", _button_style(Color("102E27"), Color("E2BC6A"), 2, 12))
	toggle_button.add_theme_stylebox_override("focus", _button_style(Color("245A42"), Color("FFE29A"), 3, 12))
	toggle_button.pressed.connect(func() -> void: set_collapsed(not collapsed))
	add_child(toggle_button)

	panel = PanelContainer.new()
	panel.name = "UtilityDrawer"
	panel.position = Vector2(TOGGLE_SIZE.x + BUTTON_GAP, 0.0)
	panel.custom_minimum_size = Vector2(0.0, TOGGLE_SIZE.y)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = TOGGLE_SIZE.x + BUTTON_GAP
	panel.offset_top = 0.0
	panel.offset_right = TOGGLE_SIZE.x + BUTTON_GAP + 2.0 * BUTTON_SIZE.x + BUTTON_GAP + 16.0
	panel.offset_bottom = BUTTON_SIZE.y + 20.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	button_column = GridContainer.new()
	button_column.columns = 2
	button_column.add_theme_constant_override("h_separation", BUTTON_GAP)
	button_column.add_theme_constant_override("v_separation", BUTTON_GAP)
	margin.add_child(button_column)
	for entry in [
		{"id": "difficulty", "label": "AI 模式"},
		{"id": "tuning", "label": "调参"},
		{"id": "helper", "label": "辅助"},
		{"id": "opponents", "label": "明牌"},
		{"id": "skin", "label": "桌布皮肤"},
		{"id": "voice", "label": "语音\n普通话"},
		{"id": "choose_voice", "label": "选择声音"},
		{"id": "settlement", "label": "☷  对局详情"},
		{"id": "next_round", "label": "下一局"},
		{"id": "view", "label": "旧版UI"},
		{"id": "exit", "label": "退出"},
	]:
		_create_button(str(entry["id"]), str(entry["label"]))
	custom_minimum_size = TOGGLE_SIZE
	_apply_focus_navigation()
	_apply_collapsed_state()
	set_table_skin(active_skin_id)


func _apply_collapsed_state() -> void:
	if panel == null or toggle_button == null:
		return
	panel.visible = not collapsed
	toggle_button.text = "☰" if collapsed else "▲"
	toggle_button.tooltip_text = "展开牌桌工具" if collapsed else "收起牌桌工具"
	var visible_count := 0
	for button_value in buttons.values():
		var candidate := button_value as Button
		if candidate != null and candidate.visible:
			visible_count += 1
	var drawer_width := 2.0 * BUTTON_SIZE.x + BUTTON_GAP + 24.0
	var rows := ceili(float(visible_count) / 2.0)
	var drawer_height := rows * BUTTON_SIZE.y + maxi(0, rows - 1) * BUTTON_GAP + 24.0
	panel.custom_minimum_size = Vector2(drawer_width, drawer_height)
	panel.offset_left = DRAWER_LEFT
	panel.offset_top = TOGGLE_SIZE.y + BUTTON_GAP
	panel.offset_right = DRAWER_LEFT + drawer_width
	panel.offset_bottom = TOGGLE_SIZE.y + BUTTON_GAP + drawer_height
	custom_minimum_size = TOGGLE_SIZE if collapsed else Vector2(
		DRAWER_LEFT + drawer_width,
		TOGGLE_SIZE.y + BUTTON_GAP + drawer_height
	)
	size = custom_minimum_size
	if not collapsed:
		var first_button := buttons.get("difficulty") as Button
		if first_button != null and get_viewport().gui_get_focus_owner() == toggle_button:
			first_button.grab_focus()


func _create_button(action: String, label_text: String) -> void:
	var button := Button.new()
	button.name = "Utility_%s" % action
	button.text = label_text
	button.custom_minimum_size = BUTTON_SIZE
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 35)
	button.add_theme_font_override("font", BODY_FONT)
	button.add_theme_color_override("font_color", Color("FFF0CF"))
	button.add_theme_color_override("font_outline_color", Color("24150C"))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", _button_style(Color("173D31"), Color("B88943"), 1))
	button.add_theme_stylebox_override("hover", _button_style(Color("245A42"), Color("E2BC6A"), 2))
	button.add_theme_stylebox_override("pressed", _button_style(Color("102E27"), Color("E2BC6A"), 2))
	button.add_theme_stylebox_override("focus", _button_style(Color("245A42"), Color("FFE29A"), 3))
	button.pressed.connect(func() -> void: utility_selected.emit(action))
	button_column.add_child(button)
	buttons[action] = button


func _set_button_text(action: String, label_text: String) -> void:
	var button := buttons.get(action) as Button
	if button != null:
		button.text = label_text


func _set_button_visible(action: String, shown: bool) -> void:
	var button := buttons.get(action) as Button
	if button != null:
		button.visible = shown
		if not collapsed:
			call_deferred("_apply_collapsed_state")


func _difficulty_label(snapshot: Dictionary) -> String:
	match str(snapshot.get("ai_tuning_config", {}).get("preset_name", "bone_ash")):
		"intermediate":
			return "智能"
		"hell":
			return "透视"
		_:
			return "智能"


func _apply_focus_navigation() -> void:
	var ordered: Array[Button] = []
	for action in ["difficulty", "tuning", "helper", "opponents", "skin", "voice", "choose_voice", "settlement", "next_round", "view", "exit"]:
		var button := buttons.get(action) as Button
		if button != null:
			ordered.append(button)
	for index in range(ordered.size()):
		var previous := ordered[(index - 1 + ordered.size()) % ordered.size()]
		var next := ordered[(index + 1) % ordered.size()]
		ordered[index].focus_neighbor_top = ordered[index].get_path_to(previous)
		ordered[index].focus_neighbor_bottom = ordered[index].get_path_to(next)
	if toggle_button != null and not ordered.is_empty():
		var first := ordered[0]
		var last := ordered[ordered.size() - 1]
		toggle_button.focus_neighbor_right = toggle_button.get_path_to(first)
		first.focus_neighbor_left = first.get_path_to(toggle_button)
		last.focus_neighbor_left = last.get_path_to(toggle_button)


func _panel_style() -> StyleBoxFlat:
	if active_skin_id == "blue_glass":
		var glass := StyleBoxFlat.new()
		glass.bg_color = Color(0.015, 0.08, 0.15, 0.76)
		glass.border_color = Color.TRANSPARENT
		glass.set_border_width_all(0)
		glass.set_corner_radius_all(18)
		glass.shadow_color = Color(0.01, 0.06, 0.13, 0.42)
		glass.shadow_size = 18
		return glass
	var style := _button_style(Color(0.025, 0.095, 0.078, 0.97), Color(Color("C49A55"), 0.78), 2, 14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 14
	style.shadow_offset = Vector2(4, 6)
	return style


func _button_style(fill: Color, border: Color, border_width: int, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if active_skin_id == "blue_glass":
		style.bg_color = Color(0.70, 0.91, 1.0, 0.025 if border_width == 1 else 0.20)
		style.border_color = Color.TRANSPARENT if border_width == 1 else Color(0.90, 0.98, 1.0, 0.45)
		style.set_border_width_all(0 if border_width == 1 else 1)
		style.set_corner_radius_all(radius if radius > 12 else 18)
		style.shadow_color = Color(0.01, 0.10, 0.24, 0.14)
		style.shadow_size = 3
		style.set_content_margin_all(7)
		return style
	style.bg_color = Color(Color("172621"), 0.94) if border_width == 1 else fill
	style.border_color = Color(Color("9D743A"), 0.72) if border_width == 1 else border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.shadow_color = Color(0.0, 0.015, 0.01, 0.32)
	style.shadow_size = 4
	style.shadow_offset = Vector2(3, 4)
	style.set_content_margin_all(7)
	return style
