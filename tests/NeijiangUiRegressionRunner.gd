extends SceneTree

const MAIN_SCENE := preload("res://scenes/table/MainSceneV2.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var root_node := MAIN_SCENE.instantiate()
	get_root().add_child(root_node)
	await process_frame
	await process_frame

	_run_test("self_hu_helper_prioritizes_hu_over_discard_recommendation", _test_self_hu_helper_prioritizes_hu_over_discard_recommendation.bind(root_node), failures)
	_run_test("selected_tile_helper_uses_csharp_candidate_details", _test_selected_tile_helper_uses_csharp_candidate_details.bind(root_node), failures)
	_run_test("neijiang_settlement_hides_stale_ding_que_tags", _test_neijiang_settlement_hides_stale_ding_que_tags.bind(root_node), failures)
	_run_test("top_right_x_exit_button_is_visible", _test_top_right_x_exit_button_is_visible.bind(root_node), failures)
	_run_test("main_controls_are_layered_by_purpose", _test_main_controls_are_layered_by_purpose.bind(root_node), failures)
	_run_test("action_buttons_use_circular_mahjong_style", _test_action_buttons_use_circular_mahjong_style.bind(root_node), failures)

	root_node.queue_free()
	if failures.is_empty():
		print("NEIJIANG UI REGRESSION OK")
		quit(0)
		return

	push_error("NEIJIANG UI REGRESSION FAILED:\n- " + "\n- ".join(failures))
	quit(1)


func _run_test(name: String, callable: Callable, failures: Array[String]) -> void:
	var result = callable.call()
	if typeof(result) == TYPE_BOOL and bool(result):
		print("PASS %s" % name)
		return
	failures.append("%s -> %s" % [name, str(result)])


func _test_self_hu_helper_prioritizes_hu_over_discard_recommendation(root_node: Node):
	root_node.set("ai_helper_enabled", true)
	var snapshot := {
		"players": [
			{
				"seat": 0,
				"nickname": "本家",
				"score": 0,
				"hand_tiles": [_make_tile(9001, "tiao", 9)],
			},
		],
		"rules": {"use_ding_que_phase": false},
	}
	var trainer_hint := {
		"can_self_hu": true,
		"recommended": {
			"tile_name": "9条",
			"tile": _make_tile(9001, "tiao", 9),
			"explanation_hint": "这手先保宽叫",
		},
		"recommended_tile_id": 9001,
		"options": [],
	}
	root_node.call("_update_discard_helper_panel", snapshot, trainer_hint, true)

	var helper_panel: Control = root_node.get("discard_helper_panel") as Control
	var summary: Label = root_node.get("discard_helper_summary") as Label
	var compare: Label = root_node.get("discard_helper_compare") as Label
	if helper_panel == null or summary == null or compare == null:
		return "missing discard helper controls"
	if not helper_panel.visible:
		return "expected helper panel to stay visible with self-hu guidance"
	if not str(summary.text).contains("自摸"):
		return "expected self-hu guidance, got summary=%s" % summary.text
	if str(summary.text).contains("打"):
		return "expected self-hu guidance not to recommend a discard, got summary=%s" % summary.text
	if compare.visible and str(compare.text).contains("打"):
		return "expected helper explanation not to recommend a discard while self-hu is available, got compare=%s" % compare.text
	return true


func _test_selected_tile_helper_uses_csharp_candidate_details(root_node: Node):
	root_node.set("ai_helper_enabled", true)
	root_node.set("selected_tile_id", 9205)
	var recommended_tile := _make_tile(9209, "tiao", 9)
	var selected_tile := _make_tile(9205, "tong", 5)
	var snapshot := {
		"players": [
			{
				"seat": 0,
				"nickname": "本家",
				"score": 0,
				"hand_tiles": [recommended_tile, selected_tile],
			},
		],
		"rules": {"use_ding_que_phase": false},
	}
	var trainer_hint := {
		"recommended": {
			"tile_name": "9条",
			"tile": recommended_tile,
			"shanten": 1,
			"live_ukeire": 9,
			"risk": 12,
			"risk_label": "低危",
			"expected_net_score": 2.40,
			"expected_win_gain": 3.20,
			"expected_deal_in_loss": 0.80,
			"explanation_hint": "C#推荐：边张出清更快成叫",
			"posterior_reasons": ["后验未明显压分"],
			"csharp_expected_net_score": 2.40,
			"csharp_expected_win_gain": 3.20,
			"csharp_expected_deal_in_loss": 0.80,
			"csharp_explanation_hint": "C#推荐：边张出清更快成叫",
		},
		"recommended_tile_id": 9209,
		"options": [
			{
				"tile_name": "9条",
				"tile": recommended_tile,
				"shanten": 1,
				"live_ukeire": 9,
				"risk": 12,
				"risk_label": "低危",
				"expected_net_score": 2.40,
				"expected_win_gain": 3.20,
				"expected_deal_in_loss": 0.80,
				"explanation_hint": "C#推荐：边张出清更快成叫",
			},
			{
				"tile_name": "5筒",
				"tile": selected_tile,
				"shanten": 2,
				"live_ukeire": 4,
				"risk": 31,
				"risk_label": "高危",
				"expected_net_score": 0.60,
				"expected_win_gain": 1.40,
				"expected_deal_in_loss": 2.10,
				"posterior_reasons": ["C#后验：下家疑似等筒"],
				"risk_reasons": ["C#风险：筒门危险"],
				"csharp_expected_net_score": 0.60,
				"csharp_expected_win_gain": 1.40,
				"csharp_expected_deal_in_loss": 2.10,
				"csharp_posterior_reasons": ["C#后验：下家疑似等筒"],
				"csharp_risk_reasons": ["C#风险：筒门危险"],
			},
		],
		"backend_mode": "csharp_native",
	}
	root_node.call("_update_discard_helper_panel", snapshot, trainer_hint, true)

	var summary: Label = root_node.get("discard_helper_summary") as Label
	var compare: Label = root_node.get("discard_helper_compare") as Label
	if summary == null or compare == null:
		return "missing discard helper labels"
	var panel: Panel = root_node.get("discard_helper_panel") as Panel
	if panel == null:
		return "missing discard helper panel"
	if panel.custom_minimum_size.x < 1300.0 or panel.custom_minimum_size.y < 188.0:
		return "expected mobile-readable wide helper panel, got %.1fx%.1f" % [panel.custom_minimum_size.x, panel.custom_minimum_size.y]
	if summary.get_theme_font_size("font_size") < 46:
		return "expected large bold helper summary text, got %d" % summary.get_theme_font_size("font_size")
	if compare.get_theme_font_size("font_size") < 32:
		return "expected large helper reason text, got %d" % compare.get_theme_font_size("font_size")
	if summary.get_theme_constant("outline_size") < 5 or compare.get_theme_constant("outline_size") < 3:
		return "expected helper text to use heavier outline for phone readability"
	if summary.text != "5筒 → 打 9条":
		return "expected selected tile comparison summary, got %s" % summary.text
	if not compare.visible:
		return "expected selected tile C# comparison details to be visible"
	var text := str(compare.text)
	for expected in ["不建议打5筒", "向听更慢1", "活进张少5", "风险高19", "净分低1.80", "C#后验：下家疑似等筒", "推荐9条"]:
		if not text.contains(expected):
			return "expected C# selected-option detail '%s' in helper text, got %s" % [expected, text]
	return true


func _test_neijiang_settlement_hides_stale_ding_que_tags(root_node: Node):
	var snapshot := {
		"current_phase": 7,
		"round_index": 1,
		"current_dealer_seat": 0,
		"rules": {"use_ding_que_phase": false},
		"players": [
			{
				"seat": 0,
				"nickname": "本家",
				"score": 6,
				"hand_tiles": [
					_make_tile(9101, "tiao", 1),
					_make_tile(9102, "tong", 2),
					_make_tile(9103, "tong", 3),
				],
				"melds": [],
				"ding_que": "tong",
			},
			{"seat": 1, "nickname": "上家", "score": 0, "hand_tiles": [], "melds": [], "ding_que": ""},
			{"seat": 2, "nickname": "对家", "score": 0, "hand_tiles": [], "melds": [], "ding_que": ""},
			{"seat": 3, "nickname": "下家", "score": 0, "hand_tiles": [], "melds": [], "ding_que": ""},
		],
		"settlement_data": {
			"round_index": 1,
			"dealer_seat": 0,
			"end_reason": "draw_wall_empty",
			"score_changes": {0: 6, 1: 0, 2: 0, 3: 0},
			"winner_seats": [],
			"win_events": [],
			"gang_events": [],
			"draw_assessment": [],
		},
	}
	root_node.call("_render_settlement", snapshot)
	var hand_row: Control = root_node.get("settlement_hand_row") as Control
	if hand_row == null:
		return "missing settlement hand row"
	var visible_text := _collect_visible_label_text(hand_row)
	if visible_text.contains("缺筒") or visible_text.contains("缺条") or visible_text.contains("缺万"):
		return "expected Neijiang settlement to hide stale ding-que tags, got labels=%s" % visible_text
	return true


func _test_top_right_x_exit_button_is_visible(root_node: Node):
	var button: Button = root_node.get("top_exit_button") as Button
	if button == null:
		return "missing top exit button"
	root_node.call("_update_top_bar", {
		"players": [],
		"rules": {"use_ding_que_phase": false},
		"ai_tuning_config": {"preset_name": "bone_ash"},
		"current_phase": 5,
	})
	if not button.visible:
		return "expected top-right X exit button to be visible"
	if button.text != "X":
		return "expected top-right exit button text X, got %s" % button.text
	var root_ui: Control = root_node.get_node_or_null("UILayer/RootUI") as Control
	if root_ui == null:
		return "missing RootUI"
	var rect := button.get_global_rect()
	var root_rect := root_ui.get_global_rect()
	if rect.size.x < 56.0 or rect.size.y < 56.0:
		return "expected X exit button to be a tappable square, got %.1fx%.1f" % [rect.size.x, rect.size.y]
	if rect.position.x < root_rect.end.x - 104.0 or rect.position.y > root_rect.position.y + 36.0:
		return "expected X exit button in the game UI top-right corner, got %s within %s" % [rect, root_rect]
	return true


func _test_main_controls_are_layered_by_purpose(root_node: Node):
	root_node.call("_update_top_bar", {
		"players": [],
		"rules": {"use_ding_que_phase": false},
		"ai_tuning_config": {"preset_name": "bone_ash"},
		"current_phase": 5,
	})
	var top_bar_button: Button = root_node.get("top_bar_button") as Button
	var settlement_button: Button = root_node.get("top_settlement_info_button") as Button
	var next_button: Button = root_node.get("top_next_round_button") as Button
	var stack: VBoxContainer = root_node.get("v17_top_button_stack") as VBoxContainer
	if top_bar_button == null or settlement_button == null or next_button == null or stack == null:
		return "missing main control buttons"
	if top_bar_button.get_parent() == stack or top_bar_button.visible:
		return "expected AI preset button to stay out of right-side flow controls"
	for child in stack.get_children():
		if child == top_bar_button:
			return "expected right-side stack to contain only settlement/next flow controls"
		if child is Button and child != settlement_button and child != next_button:
			return "unexpected button in right-side flow stack: %s" % child.name

	var drawer: VBoxContainer = root_node.get("floating_left_button_bar") as VBoxContainer
	var toggle: Button = root_node.get("floating_left_toggle_button") as Button
	var helper: Button = root_node.get("floating_ai_helper_button") as Button
	var opponent: Button = root_node.get("floating_opponent_hand_button") as Button
	var preset: Button = root_node.get("floating_preset_button") as Button
	var tuning: Button = root_node.get("floating_ai_tuning_button") as Button
	if drawer == null or toggle == null or helper == null or opponent == null or preset == null or tuning == null:
		return "expected AI tool drawer to expose AI/helper/opponent/preset/tuning buttons"
	if toggle.text != "AI":
		return "expected drawer entry button to read AI, got %s" % toggle.text
	root_node.set("floating_left_buttons_collapsed", false)
	root_node.call("_update_floating_button_texts")
	if not helper.visible or not opponent.visible or not preset.visible or not tuning.visible:
		return "expected expanded AI drawer to show helper, open-hand, preset, and tuning controls"
	if not str(helper.text).begins_with("辅助"):
		return "expected helper toggle label to include status, got %s" % helper.text
	if not str(opponent.text).begins_with("明牌"):
		return "expected open-hand toggle label to include status, got %s" % opponent.text
	if not str(preset.text).begins_with("难度"):
		return "expected preset control to be shown as difficulty status, got %s" % preset.text
	if tuning.text != "调参":
		return "expected tuning control text 调参, got %s" % tuning.text
	if helper.custom_minimum_size.x > 190.0 or helper.custom_minimum_size.y > 64.0:
		return "expected AI drawer buttons to be compact pills, got %.1fx%.1f" % [helper.custom_minimum_size.x, helper.custom_minimum_size.y]
	return true


func _test_action_buttons_use_circular_mahjong_style(root_node: Node):
	root_node.call("_refresh_action_panel", {
		"current_phase": 2,
		"players": [
			{"seat": 0, "nickname": "本家", "score": 0},
			{"seat": 1, "nickname": "上家", "score": 0},
			{"seat": 2, "nickname": "对家", "score": 0},
			{"seat": 3, "nickname": "下家", "score": 0},
		],
		"human_reaction_options": {
			"can_hu": true,
			"can_gang": true,
			"can_peng": true,
			"can_pass": true,
		},
		"human_can_bao_jiao": true,
	})
	var action_panel: Panel = root_node.get("action_panel") as Panel
	var action_buttons: GridContainer = root_node.get("action_buttons") as GridContainer
	var hu_button: Button = root_node.get("hu_button") as Button
	var gang_button: Button = root_node.get("gang_button") as Button
	var peng_button: Button = root_node.get("peng_button") as Button
	var pass_button: Button = root_node.get("pass_button") as Button
	var bao_jiao_button: Button = root_node.get("bao_jiao_button") as Button
	if action_panel == null or action_buttons == null or hu_button == null or gang_button == null or peng_button == null or pass_button == null or bao_jiao_button == null:
		return "missing action panel controls"
	var panel_style := action_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if panel_style == null:
		return "expected circular mahjong action panel stylebox"
	if panel_style.bg_color.a > 0.02 or panel_style.get_border_width(SIDE_LEFT) != 0 or panel_style.border_color.a > 0.02:
		return "expected action panel itself to stay transparent without frame lines"
	if panel_style.content_margin_left != 6:
		return "expected compact action panel padding 6, got %d" % panel_style.content_margin_left
	if action_buttons.get_theme_constant("h_separation") != 24 or action_buttons.get_theme_constant("v_separation") != 24:
		return "expected circular action button gap 24px"
	if action_panel.get_node_or_null("ActionPanelCyberHud") != null:
		return "expected old cyber HUD panel overlay to be removed"
	if action_panel.get_node_or_null("ActionPanelCrystalGlass") != null:
		return "expected old crystal panel overlay to be removed"
	for item in [
		{"button": hu_button, "primary": true, "size": 236.0, "font_size": 172},
		{"button": gang_button, "primary": true, "size": 236.0, "font_size": 172},
		{"button": peng_button, "primary": false, "size": 204.0, "font_size": 148},
		{"button": pass_button, "primary": false, "size": 204.0, "font_size": 148},
		{"button": bao_jiao_button, "primary": false, "size": 204.0, "font_size": 148},
	]:
		var button: Button = item["button"]
		var expected_primary := bool(item["primary"])
		var expected_size := float(item["size"])
		var expected_font_size := int(item["font_size"])
		if not button.visible:
			return "expected %s to be visible in circular mahjong style test" % button.name
		var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
		if normal == null:
			return "expected %s to have circular mahjong normal style" % button.name
		if normal.get_border_width(SIDE_LEFT) != 0 or normal.border_color.a > 0.02:
			return "expected %s StyleBox to stay borderless; circle outline is drawn by overlay" % button.name
		if absf(button.custom_minimum_size.x - expected_size) > 0.1 or absf(button.custom_minimum_size.y - expected_size) > 0.1:
			return "expected %s circular size %.0f, got %.1fx%.1f" % [button.name, expected_size, button.custom_minimum_size.x, button.custom_minimum_size.y]
		if button.get_theme_font_size("font_size") != expected_font_size:
			return "expected %s font size %d, got %d" % [button.name, expected_font_size, button.get_theme_font_size("font_size")]
		var hidden_text_color: Color = button.get_theme_color("font_color")
		if hidden_text_color.a > 0.01 or button.get_theme_constant("outline_size") != 0:
			return "expected %s native Button text to be hidden behind overlay-drawn embossed text" % button.name
		var overlay := button.get_node_or_null("CircularActionButtonOverlay")
		if overlay == null:
			return "expected %s to have circular mahjong overlay" % button.name
		if bool(overlay.get("primary")) != expected_primary:
			return "expected %s primary=%s" % [button.name, str(expected_primary)]
		if str(overlay.get("label_text")) != button.text:
			return "expected %s overlay label to mirror button text, got %s vs %s" % [button.name, str(overlay.get("label_text")), button.text]
		if button.get_node_or_null("CyberHudOverlay") != null:
			return "expected %s old cyber HUD overlay to be removed" % button.name
		if button.get_node_or_null("CrystalGlassOverlay") != null:
			return "expected %s old crystal overlay to be removed" % button.name
	return true


func _collect_visible_label_text(node: Node) -> String:
	var parts: Array[String] = []
	if node is Label:
		var label := node as Label
		if label.visible and not label.text.is_empty():
			parts.append(label.text)
	for child in node.get_children():
		var child_text := _collect_visible_label_text(child)
		if not child_text.is_empty():
			parts.append(child_text)
	return " ".join(parts)


func _make_tile(id: int, suit: String, rank: int) -> Dictionary:
	return {
		"id": id,
		"suit": suit,
		"rank": rank,
		"sort_key": _suit_sort_offset(suit) + rank,
		"display_name": "%d%s" % [rank, _suit_label(suit)],
	}


func _suit_sort_offset(suit: String) -> int:
	match suit:
		"wan":
			return 0
		"tiao":
			return 100
		"tong":
			return 200
		_:
			return 900


func _suit_label(suit: String) -> String:
	match suit:
		"wan":
			return "万"
		"tiao":
			return "条"
		"tong":
			return "筒"
		_:
			return "?"
