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

	_run_test("user_release_hides_diagnostic_and_dev_buttons", _test_user_release_hides_diagnostic_and_dev_buttons.bind(root_node), failures)
	_run_test("ai_action_delay_is_randomized_between_half_and_three_seconds", _test_ai_action_delay_is_randomized_between_half_and_three_seconds.bind(root_node), failures)
	_run_test("self_hu_helper_prioritizes_hu_over_discard_recommendation", _test_self_hu_helper_prioritizes_hu_over_discard_recommendation.bind(root_node), failures)
	_run_test("selected_tile_helper_uses_csharp_candidate_details", _test_selected_tile_helper_uses_csharp_candidate_details.bind(root_node), failures)
	_run_test("recommended_tile_helper_prioritizes_csharp_probability_details", _test_recommended_tile_helper_prioritizes_csharp_probability_details.bind(root_node), failures)
	_run_test("neijiang_settlement_hides_stale_ding_que_tags", _test_neijiang_settlement_hides_stale_ding_que_tags.bind(root_node), failures)
	_run_test("top_right_x_exit_button_is_visible", _test_top_right_x_exit_button_is_visible.bind(root_node), failures)
	_run_test("main_controls_are_layered_by_purpose", _test_main_controls_are_layered_by_purpose.bind(root_node), failures)
	_run_test("action_buttons_use_circular_mahjong_style", _test_action_buttons_use_circular_mahjong_style.bind(root_node), failures)
	_run_test("bao_gang_dialog_stays_phone_readable", _test_bao_gang_dialog_stays_phone_readable.bind(root_node), failures)
	_run_test("bao_gang_tiles_are_framed_in_self_hand", _test_bao_gang_tiles_are_framed_in_self_hand.bind(root_node), failures)
	_run_test("ai_bao_gang_tiles_are_framed_in_opponent_hand", _test_ai_bao_gang_tiles_are_framed_in_opponent_hand.bind(root_node), failures)

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


func _test_ai_action_delay_is_randomized_between_half_and_three_seconds(root_node: Node):
	root_node.call("_set_ai_action_delay_seed", 20260520)
	var observed: Dictionary = {}
	for _index in range(24):
		var delay_seconds := float(root_node.call("_next_ai_action_delay_seconds"))
		if delay_seconds < 0.5 or delay_seconds > 3.0:
			return "expected AI action delay in [0.5, 3.0], got %.4f" % delay_seconds
		observed[int(round(delay_seconds * 1000.0))] = true
	if observed.size() < 2:
		return "expected randomized AI action delays, got one repeated value"
	return true


func _test_user_release_hides_diagnostic_and_dev_buttons(root_node: Node):
	if bool(root_node.call("_is_diagnostic_export_ui_enabled")):
		return "expected diagnostic export UI disabled"
	root_node.set("floating_left_buttons_collapsed", false)
	root_node.call("_update_floating_button_texts")
	var diagnostic_button = root_node.get("floating_diagnostic_export_button")
	if diagnostic_button != null and bool(diagnostic_button.visible):
		return "expected diagnostic export button hidden"
	var tuning_button = root_node.get("floating_ai_tuning_button")
	if tuning_button != null and bool(tuning_button.visible):
		return "expected AI tuning button hidden in user release"
	var opponent_button = root_node.get("floating_opponent_hand_button")
	if opponent_button != null and bool(opponent_button.visible):
		return "expected opponent hand debug button hidden in user release"
	var mark_button = root_node.get("floating_hell_mark_button")
	if mark_button != null and bool(mark_button.visible):
		return "expected hell mark button hidden in user release"
	return true


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


func _test_recommended_tile_helper_prioritizes_csharp_probability_details(root_node: Node):
	root_node.set("ai_helper_enabled", true)
	root_node.set("selected_tile_id", -1)
	var recommended_tile := _make_tile(9304, "tiao", 4)
	var snapshot := {
		"players": [
			{
				"seat": 0,
				"nickname": "本家",
				"score": 0,
				"hand_tiles": [recommended_tile],
			},
		],
		"rules": {"use_ding_que_phase": false},
	}
	var trainer_hint := {
		"recommended": {
			"tile_name": "4条",
			"tile": recommended_tile,
			"shanten": 1,
			"live_ukeire": 7,
			"risk": 44,
			"risk_label": "中危",
			"expected_net_score": 1.25,
			"self_draw_probability": 0.31,
			"deal_in_probability": 0.08,
			"defense_adjustment": 0.42,
			"shape_score": 16.0,
			"explanation_hint": "这手先抢速度",
			"posterior_reasons": ["中盘压力上升，开始压风险"],
			"risk_reasons": ["座位2近期不要这张"],
			"reasons": ["最小向听 1", "活进张 7", "策略 抢听", "手形好搭 5"],
			"csharp_expected_net_score": 1.25,
			"csharp_self_draw_probability": 0.31,
			"csharp_deal_in_probability": 0.08,
			"csharp_defense_adjustment": 0.42,
			"csharp_shape_score": 16.0,
			"csharp_posterior_reasons": ["中盘压力上升，开始压风险"],
			"csharp_risk_reasons": ["座位2近期不要这张"],
			"csharp_reasons": ["最小向听 1", "活进张 7", "策略 抢听", "手形好搭 5"],
		},
		"recommended_tile_id": 9304,
		"options": [],
		"backend_mode": "csharp_native",
	}
	root_node.call("_update_discard_helper_panel", snapshot, trainer_hint, true)

	var compare: Label = root_node.get("discard_helper_compare") as Label
	if compare == null:
		return "missing discard helper compare label"
	if not compare.visible:
		return "expected recommended C# probability details to be visible"
	var text := str(compare.text)
	for expected in ["净分1.25", "自摸31%", "点炮8%", "防守压分0.42", "牌效+16", "中盘压力上升", "座位2近期不要这张", "手形好搭 5"]:
		if not text.contains(expected):
			return "expected C# probability detail '%s' in helper text, got %s" % [expected, text]
	if text == "这手先抢速度":
		return "expected C# probability details to override short explanation_hint"
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
	if drawer == null or toggle == null or helper == null or preset == null:
		return "expected AI tool drawer to expose AI/helper/preset controls"
	if toggle.text != "AI":
		return "expected drawer entry button to read AI, got %s" % toggle.text
	root_node.set("floating_left_buttons_collapsed", false)
	root_node.call("_update_floating_button_texts")
	if not helper.visible or not preset.visible:
		return "expected expanded AI drawer to show helper and preset controls"
	if opponent != null and opponent.visible:
		return "expected practical-use build to hide open-hand developer control"
	if tuning != null and tuning.visible:
		return "expected practical-use build to hide tuning developer control"
	if not str(helper.text).begins_with("辅助"):
		return "expected helper toggle label to include status, got %s" % helper.text
	if not str(preset.text).begins_with("难度"):
		return "expected preset control to be shown as difficulty status, got %s" % preset.text
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


func _test_bao_gang_dialog_stays_phone_readable(root_node: Node):
	root_node.call("_show_bao_gang_selection_dialog", [
		{"key": "tiao_1", "display_name": "1条", "tile": _make_tile(9401, "tiao", 1), "subtype": "ming"},
		{"key": "tiao_8", "display_name": "8条", "tile": _make_tile(9408, "tiao", 8), "subtype": "an"},
		{"key": "tong_9", "display_name": "9筒", "tile": _make_tile(9509, "tong", 9), "subtype": "ming"},
		{"key": "tong_5", "display_name": "5筒", "tile": _make_tile(9505, "tong", 5), "subtype": "ming"},
	])
	var dialog: ConfirmationDialog = root_node.get("bao_gang_dialog") as ConfirmationDialog
	var content: Control = root_node.get("bao_gang_dialog_content") as Control
	var checks: Array = root_node.get("bao_gang_option_checks")
	if dialog == null or content == null:
		return "missing bao gang dialog/content"
	if dialog.get_ok_button().visible or dialog.get_cancel_button().visible:
		return "expected bao gang dialog to hide bottom confirm/cancel buttons"
	if dialog.min_size.x < 880.0 or dialog.min_size.y < 420.0:
		return "expected bao gang dialog minimum size to be phone-readable, got %.1fx%.1f" % [dialog.min_size.x, dialog.min_size.y]
	if content.custom_minimum_size.x < 820.0 or content.custom_minimum_size.y < 320.0:
		return "expected bao gang dialog content to keep a large single panel, got %.1fx%.1f" % [content.custom_minimum_size.x, content.custom_minimum_size.y]
	if checks.size() != 4:
		return "expected four bao gang tile buttons, got %d" % checks.size()
	var panel := content as Panel
	if panel == null or panel.name != "BaoGangSurface":
		return "expected bao gang dialog to use one table-style surface panel"
	var close_button := panel.get_node_or_null("BaoGangCloseButton") as Button
	if close_button == null or close_button.text != "×":
		return "expected bao gang panel to expose a top-right close button"
	var content_box := panel.get_node_or_null("BaoGangSurfaceMargin/BaoGangSurfaceContent") as VBoxContainer
	if content_box == null:
		return "expected bao gang surface content box"
	var title := content_box.get_child(0) as Label
	if title == null or title.get_theme_font_size("font_size") < 38:
		return "expected large bao gang dialog title font, got %s" % [title]
	var panel_style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if panel_style == null:
		return "expected bao gang surface to have custom StyleBoxFlat"
	if panel_style.bg_color.r > 0.16 or panel_style.bg_color.g < 0.22 or panel_style.bg_color.b > 0.24:
		return "expected bao gang surface to use deep green felt, got %s" % [panel_style.bg_color]
	if panel_style.border_color.r < 0.55 or panel_style.border_color.g < 0.42 or panel_style.border_color.b > 0.55:
		return "expected bao gang surface to use warm gold border, got %s" % [panel_style.border_color]
	if panel_style.get_border_width(SIDE_LEFT) < 2:
		return "expected bao gang surface to have visible table-style border"
	if panel_style.corner_radius_top_left < 18:
		return "expected bao gang surface to have rounded tabletop corners"
	if title.get_theme_color("font_color").r < 0.85 or title.get_theme_color("font_color").g < 0.72:
		return "expected bao gang title to use ivory/gold table text"
	var tile_row := content_box.get_node_or_null("BaoGangTileRow") as HBoxContainer
	if tile_row == null:
		return "expected bao gang options to be arranged as one horizontal tile row"
	if tile_row.get_theme_constant("separation") < 22:
		return "expected generous spacing between bao gang tiles"
	for check_item in checks:
		var check := check_item as Button
		if check == null:
			return "expected bao gang option tile button"
		if not check.text.strip_edges().is_empty():
			return "expected bao gang option to render the selectable tile instead of text-only label, got text=%s" % check.text
		if not check.toggle_mode:
			return "expected bao gang tile button to toggle selection"
		if check.custom_minimum_size.x < 150.0 or check.custom_minimum_size.y < 200.0:
			return "expected bao gang selectable tile to be large, got %.1fx%.1f" % [check.custom_minimum_size.x, check.custom_minimum_size.y]
		if not check.button_pressed:
			return "expected bao gang options to default selected"
		var tile_visual := _find_descendant(check, "BaoGangOptionTile") as TileVisual2D
		if tile_visual == null:
			return "expected bao gang tile button to contain a Mahjong tile visual"
		if tile_visual.tile_data.is_empty():
			return "expected bao gang tile visual to receive tile data"
		if tile_visual.show_back:
			return "expected bao gang selectable tile to show face, not tile back"
		if tile_visual.tile_scale < 0.84:
			return "expected bao gang tile visual to be larger than the old list tile, got scale %.2f" % tile_visual.tile_scale
		if not tile_visual.is_selected or tile_visual.scale.x < 1.04:
			return "expected default selected bao gang tile to use discard-like selected lift/scale"
		root_node.call("_refresh_bao_gang_option_selection_visual", check, tile_visual, false)
		if tile_visual.is_selected or tile_visual.scale.x > 1.01:
			return "expected bao gang tile visual to clear selected effect when unchecked"
		root_node.call("_refresh_bao_gang_option_selection_visual", check, tile_visual, true)
		if not tile_visual.is_selected or tile_visual.scale.x < 1.04:
			return "expected bao gang tile visual to restore selected effect when checked"
		var check_style := check.get_theme_stylebox("normal") as StyleBoxFlat
		if check_style == null:
			return "expected bao gang option to have custom tabletop row style"
		if check_style.bg_color.g < 0.20 or check_style.bg_color.a < 0.60:
			return "expected bao gang option tile to use translucent green tabletop color"
		if check_style.border_color.r < 0.45 or check_style.border_color.g < 0.35:
			return "expected bao gang option tile to use warm border"
	dialog.hide()
	return true


func _test_bao_gang_tiles_are_framed_in_self_hand(root_node: Node):
	var bao_gang_tile := _make_tile(9602, "tiao", 2)
	var normal_tile := _make_tile(9605, "tong", 5)
	var snapshot := {
		"current_dealer_seat": 0,
		"human_can_discard": true,
		"human_last_draw_tile_id": -1,
		"rules": {"use_ding_que_phase": false},
		"players": [
			{
				"seat": 0,
				"nickname": "本家",
				"score": 10,
				"hand_tiles": [bao_gang_tile, normal_tile],
				"bao_jiao": true,
				"bao_gang_tiles": ["tiao_2"],
				"melds": [],
				"ding_que": "",
			},
		],
	}
	root_node.call("_update_self_area", snapshot, snapshot["players"][0]["hand_tiles"])
	var self_hand_host: PlayerHandViewport = root_node.get("self_hand_host") as PlayerHandViewport
	if self_hand_host == null:
		return "missing self hand host"
	var hand_canvas: HandCanvas2D = self_hand_host.get("hand_canvas") as HandCanvas2D
	if hand_canvas == null:
		return "missing self hand canvas"
	var layouts: Array = hand_canvas.get("tile_layouts")
	var framed_bao_gang := false
	var framed_normal := false
	for layout_item in layouts:
		var layout: Dictionary = layout_item
		if int(layout.get("tile_id", -1)) == int(bao_gang_tile["id"]):
			framed_bao_gang = bool(layout.get("bao_gang", false))
		if int(layout.get("tile_id", -1)) == int(normal_tile["id"]):
			framed_normal = bool(layout.get("bao_gang", false))
	if not framed_bao_gang:
		return "expected self bao gang tile to be separately framed in hand layout"
	if framed_normal:
		return "expected non-bao-gang self tile not to be framed"
	return true


func _test_ai_bao_gang_tiles_are_framed_in_opponent_hand(root_node: Node):
	var left_ui: PlayerUI = root_node.get("left_ui") as PlayerUI
	if left_ui == null:
		return "missing left player UI"
	var bao_gang_tile := _make_tile(9702, "tiao", 2)
	var normal_tile := _make_tile(9705, "tong", 5)
	left_ui.apply_snapshot({
		"seat": 1,
		"nickname": "AI",
		"score": 0,
		"hand_count": 2,
		"hand_tiles": [bao_gang_tile, normal_tile],
		"bao_jiao": true,
		"bao_gang_tiles": ["tiao_2"],
		"melds": [],
		"discards": [],
	}, true, -1, -1, false)
	var tiles: Array = []
	_collect_nodes_by_class(left_ui, "TileVisual2D", tiles)
	var highlighted_back_count := 0
	for node_item in tiles:
		var tile := node_item as TileVisual2D
		if tile != null and tile.show_back and tile.is_selected:
			highlighted_back_count += 1
	if highlighted_back_count != 1:
		return "expected exactly one hidden AI bao gang back tile to be framed, got %d" % highlighted_back_count
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


func _find_descendant(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_descendant(child, node_name)
		if found != null:
			return found
	return null


func _collect_nodes_by_class(node: Node, target_class_name: String, result: Array) -> void:
	if node.get_class() == target_class_name or node.is_class(target_class_name) or (target_class_name == "TileVisual2D" and node is TileVisual2D):
		result.append(node)
	for child in node.get_children():
		_collect_nodes_by_class(child, target_class_name, result)


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
