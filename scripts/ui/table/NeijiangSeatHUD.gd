class_name NeijiangSeatHUD
extends Control

# 与四川麻将最新版保持一致的“墨玉漆面 + 低饱和古铜”材质语言。
# 状态仍由内江规则数据驱动；这里仅改变信息的视觉承载方式。
const HUD_SIZE := Vector2(230.0, 146.0)
const JADE_SHELL := Color("0D3029")
const JADE_MEDALLION := Color("163E34")
const JADE_BADGE := Color("194B3C")
const AGED_COPPER := Color("8A6A3D")
const COPPER_HIGHLIGHT := Color("D1A75C")
const TEXT_PRIMARY := Color("F2EBDD")
const TEXT_SECONDARY := Color("C9C6BC")
const CINNABAR := Color("982F28")
const GANG_BROWN := Color("76431F")
const AVATAR_MEDALLION_SCRIPT := preload("res://scripts/ui/table/NeijiangSeatAvatarMedallion.gd")

var seat := 0
var background_panel: Panel
var inner_frame: Panel
var avatar_medallion: Control
var avatar_label: Label
var name_label: Label
var score_label: Label
var status_row: HBoxContainer
var dealer_badge: Label
var report_badge: Label
var winner_badge: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = HUD_SIZE
	_build_ui()


func configure(seat_index: int) -> void:
	seat = clampi(seat_index, 0, 3)


func render(player: Dictionary, active_seat: int, dealer_seat: int) -> void:
	if background_panel == null:
		_build_ui()
	var player_name := str(player.get("nickname", player.get("name", "玩家%d" % (seat + 1))))
	name_label.text = player_name
	avatar_label.text = _identity_glyph(player_name)
	score_label.text = "%d分" % int(player.get("score", 0))
	dealer_badge.visible = seat == dealer_seat
	var reported := bool(player.get("bao_jiao", false))
	var bao_gang_count := Array(player.get("bao_gang_tiles", [])).size()
	report_badge.visible = reported
	report_badge.text = "杠×%d" % bao_gang_count if bao_gang_count > 0 else "报叫"
	report_badge.add_theme_stylebox_override(
		"normal",
		_badge_style(GANG_BROWN if bao_gang_count > 0 else JADE_BADGE)
	)
	winner_badge.visible = bool(player.get("has_won", false))
	var is_active := seat == active_seat and not winner_badge.visible
	inner_frame.add_theme_stylebox_override("panel", _inner_frame_style(is_active))
	avatar_medallion.call("configure", seat, is_active, winner_badge.visible)


func get_visual_contract() -> Dictionary:
	return {
		"seat": seat,
		"shows_ding_que": false,
		"shows_bao_jiao": true,
		"shows_bao_gang_count": true,
		"active_state_uses_shape_and_color": true,
		"minimum_size": custom_minimum_size,
		"material_family": "unified_smoked_jade_nameplate",
		"identity_encoding": ["nickname_last_glyph", "name", "score"],
		"active_treatment": "single_thin_antique_gold_edge",
		"active_text_badge": "none",
		"badges_inside_bounds": true,
	}


func _build_ui() -> void:
	if background_panel != null:
		return
	background_panel = Panel.new()
	background_panel.name = "HudBackground"
	background_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_panel.add_theme_stylebox_override("panel", _shell_style())
	add_child(background_panel)

	inner_frame = Panel.new()
	inner_frame.name = "HudInnerFrame"
	inner_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner_frame.offset_left = 5.0
	inner_frame.offset_top = 5.0
	inner_frame.offset_right = -5.0
	inner_frame.offset_bottom = -5.0
	inner_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_frame.add_theme_stylebox_override("panel", _inner_frame_style(false))
	add_child(inner_frame)

	var margin := MarginContainer.new()
	margin.name = "HudContentMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var avatar_center := CenterContainer.new()
	avatar_center.custom_minimum_size = Vector2(72, 72)
	avatar_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	avatar_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(avatar_center)

	avatar_medallion = AVATAR_MEDALLION_SCRIPT.new() as Control
	avatar_medallion.name = "AvatarMedallion"
	avatar_medallion.custom_minimum_size = Vector2(72, 72)
	avatar_center.add_child(avatar_medallion)

	avatar_label = Label.new()
	avatar_label.name = "IdentityMedallion"
	avatar_label.text = "东"
	avatar_label.custom_minimum_size = Vector2(72, 72)
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_font_size_override("font_size", 34)
	avatar_label.add_theme_color_override("font_color", Color("FFF1C4"))
	avatar_label.add_theme_color_override("font_outline_color", Color("05110D"))
	avatar_label.add_theme_constant_override("outline_size", 3)
	avatar_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_medallion.add_child(avatar_label)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.add_theme_constant_override("separation", 0)
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_column)

	name_label = Label.new()
	name_label.name = "PlayerName"
	name_label.text = "玩家"
	name_label.custom_minimum_size = Vector2(0, 38)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 28)
	_apply_text_style(name_label, TEXT_PRIMARY)
	text_column.add_child(name_label)

	score_label = Label.new()
	score_label.name = "PlayerScore"
	score_label.text = "0分"
	score_label.custom_minimum_size = Vector2(0, 36)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 27)
	_apply_text_style(score_label, TEXT_SECONDARY)
	text_column.add_child(score_label)

	status_row = HBoxContainer.new()
	status_row.custom_minimum_size = Vector2(0, 32)
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	status_row.add_theme_constant_override("separation", 5)
	status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(status_row)

	report_badge = _make_badge("报叫", JADE_BADGE, 58)
	status_row.add_child(report_badge)
	winner_badge = _make_badge("已胡", CINNABAR, 54)
	status_row.add_child(winner_badge)

	dealer_badge = _make_badge("庄", CINNABAR, 38)
	dealer_badge.name = "DealerCornerSeal"
	dealer_badge.position = Vector2(185, 6)
	dealer_badge.size = Vector2(38, 34)
	add_child(dealer_badge)


func _identity_glyph(player_name: String) -> String:
	var clean_name := player_name.strip_edges()
	if clean_name.is_empty():
		return ["东", "南", "西", "北"][seat]
	return clean_name.substr(maxi(0, clean_name.length() - 1), 1)


func _apply_text_style(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.05, 0.94))
	label.add_theme_constant_override("outline_size", 3)


func _make_badge(text_value: String, fill: Color, width: float) -> Label:
	var badge := Label.new()
	badge.text = text_value
	badge.visible = false
	badge.custom_minimum_size = Vector2(width, 27)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 16)
	badge.add_theme_color_override("font_color", Color("FFF1C4"))
	badge.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.04, 0.96))
	badge.add_theme_constant_override("outline_size", 2)
	badge.add_theme_stylebox_override("normal", _badge_style(fill))
	return badge


func _shell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = JADE_SHELL
	style.border_color = Color(AGED_COPPER, 0.46)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.02, 0.01, 0.32)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 3)
	style.set_content_margin_all(6)
	return style


func _inner_frame_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(COPPER_HIGHLIGHT if active else AGED_COPPER, 0.90 if active else 0.20)
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(8)
	return style


func _badge_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(COPPER_HIGHLIGHT, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style
