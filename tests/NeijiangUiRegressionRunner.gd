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
	# These two contracts intentionally describe the retained legacy 2D fallback.
	# The production default is now the 3D kit, where the old X/top stack must be
	# hidden; switch modes explicitly so this runner validates the right surface.
	root_node.call("_set_neijiang_3d_ui_enabled", false)
	_run_test("top_right_x_exit_button_is_visible", _test_top_right_x_exit_button_is_visible.bind(root_node), failures)
	_run_test("main_controls_are_layered_by_purpose", _test_main_controls_are_layered_by_purpose.bind(root_node), failures)
	root_node.call("_set_neijiang_3d_ui_enabled", true)
	_run_test("action_buttons_use_circular_mahjong_style", _test_action_buttons_use_circular_mahjong_style.bind(root_node), failures)
	_run_test("bao_gang_dialog_stays_phone_readable", _test_bao_gang_dialog_stays_phone_readable.bind(root_node), failures)
	_run_test("opening_roll_ui_timer_commits_before_bao_jiao", _test_opening_roll_ui_timer_commits_before_bao_jiao.bind(root_node), failures)
	_run_test("opening_reported_ai_reaction_uses_real_manager_without_stall", _test_opening_reported_ai_reaction_uses_real_manager_without_stall.bind(root_node), failures)
	_run_test("bao_gang_dialog_confirm_advances_opening_bao_jiao", _test_bao_gang_dialog_confirm_advances_opening_bao_jiao.bind(root_node), failures)
	_run_test("opening_ai_bao_gang_before_human_pass_does_not_stick_ui", _test_opening_ai_bao_gang_before_human_pass_does_not_stick_ui.bind(root_node), failures)
	_run_test("opening_ai_bao_gang_after_human_pass_schedules_sync_ai_discard", _test_opening_ai_bao_gang_after_human_pass_schedules_sync_ai_discard.bind(root_node), failures)
	_run_test("opening_ai_bao_gang_before_human_confirm_does_not_stick_ui", _test_opening_ai_bao_gang_before_human_confirm_does_not_stick_ui.bind(root_node), failures)
	_run_test("opening_ai_bao_gang_before_human_dealer_first_discard_does_not_stick_ui", _test_opening_ai_bao_gang_before_human_dealer_first_discard_does_not_stick_ui.bind(root_node), failures)
	_run_test("opening_ai_bao_jiao_only_before_human_pass_does_not_stick_ui", _test_opening_ai_bao_jiao_only_before_human_pass_does_not_stick_ui.bind(root_node), failures)
	_run_test("opening_ai_bao_jiao_only_before_human_confirm_does_not_stick_ui", _test_opening_ai_bao_jiao_only_before_human_confirm_does_not_stick_ui.bind(root_node), failures)
	_run_test("opening_ai_bao_gang_then_human_next_turn_can_draw_and_discard", _test_opening_ai_bao_gang_then_human_next_turn_can_draw_and_discard.bind(root_node), failures)
	_run_test("opening_ai_bao_jiao_only_then_human_next_turn_can_draw_and_discard", _test_opening_ai_bao_jiao_only_then_human_next_turn_can_draw_and_discard.bind(root_node), failures)
	_run_test("bao_gang_tiles_are_framed_in_self_hand", _test_bao_gang_tiles_are_framed_in_self_hand.bind(root_node), failures)
	_run_test("ai_bao_gang_tiles_are_framed_in_opponent_hand", _test_ai_bao_gang_tiles_are_framed_in_opponent_hand.bind(root_node), failures)

	root_node.free()
	await process_frame
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
	if opponent_button == null or not bool(opponent_button.visible):
		return "expected left drawer to expose the open-hand button in user release"
	if not str(opponent_button.text).begins_with("明牌"):
		return "expected open-hand button label to include 明牌 status, got %s" % str(opponent_button.text)
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
	for expected in ["不建议先打5筒", "更建议打9条", "会晚1步", "会少5张", "更危险", "综合收益会少1.80", "下家疑似等筒"]:
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
	for expected in ["大概能赚1.25", "自摸机会31%", "放炮风险8%"]:
		if not text.contains(expected):
			return "expected C# probability detail '%s' in helper text, got %s" % [expected, text]
	if text.split("｜").size() > 3:
		return "expected normal helper detail to stay within three concise segments, got %s" % text
	for hidden_detail in ["收益会少", "牌会更顺", "中盘压力上升", "手形好搭"]:
		if text.contains(hidden_detail):
			return "expected default helper to hide expanded detail '%s', got %s" % [hidden_detail, text]
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
	var settlement_title: Label = root_node.get("settlement_player_list_title") as Label
	if settlement_title == null or settlement_title.text != "流局查叫":
		return "expected draw settlement title 流局查叫, got %s" % (settlement_title.text if settlement_title != null else "<missing>")
	var win_snapshot := snapshot.duplicate(true)
	win_snapshot["settlement_data"]["end_reason"] = "battle_end"
	root_node.call("_render_settlement", win_snapshot)
	if settlement_title.text != "胡牌结算":
		return "expected battle settlement title 胡牌结算, got %s" % settlement_title.text
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
	root_node.call("_layout_v17_top_button_stack")
	var root_ui: Control = root_node.get_node_or_null("UILayer/RootUI") as Control
	if root_ui == null:
		return "missing RootUI"
	for flow_button: Button in [settlement_button, next_button]:
		if not flow_button.visible:
			continue
		var flow_rect: Rect2 = flow_button.get_global_rect()
		if flow_rect.end.x > root_ui.get_global_rect().end.x + 0.1:
			return "expected %s to stay inside the right viewport edge, got %s" % [flow_button.name, flow_rect]

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
	if opponent == null or not opponent.visible:
		return "expected practical-use build to show open-hand control in the left drawer"
	if tuning != null and tuning.visible:
		return "expected practical-use build to hide tuning developer control"
	if not str(helper.text).begins_with("辅助"):
		return "expected helper toggle label to include status, got %s" % helper.text
	if not str(opponent.text).begins_with("明牌"):
		return "expected open-hand toggle label to include status, got %s" % opponent.text
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
	var footer := content_box.get_node_or_null("BaoGangDialogFooter") as HBoxContainer
	if footer == null:
		return "expected bao gang dialog to expose an explicit confirm/cancel footer"
	var confirm_button := footer.get_node_or_null("BaoGangConfirmButton") as Button
	var cancel_button := footer.get_node_or_null("BaoGangCancelButton") as Button
	if confirm_button == null or confirm_button.text != "确认报叫":
		return "expected bao gang dialog to expose a clear confirm button"
	if cancel_button == null or cancel_button.text != "取消":
		return "expected bao gang dialog to expose a cancel button"
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


func _test_opening_roll_ui_timer_commits_before_bao_jiao(root_node: Node):
	var game_manager: GameManager = root_node.get("game_manager") as GameManager
	if game_manager == null or game_manager.game_state == null:
		return "missing game manager/state"
	var game_state = game_manager.game_state
	game_state.start_new_round(true)
	var starting_snapshot: Dictionary = game_manager.get_fresh_snapshot()
	root_node.call("_on_snapshot_changed", starting_snapshot)
	if int(starting_snapshot.get("current_phase", -1)) != 2 or not bool(starting_snapshot.get("opening_roll_pending", false)):
		return "expected opening roll to start in TABLE_SETUP, got %s" % [starting_snapshot]
	for _index in range(24):
		root_node.call("_on_opening_roll_timer_timeout")
	root_node.call("_on_opening_roll_commit_timer_timeout")
	var latest: Dictionary = game_manager.get_fresh_snapshot()
	if int(latest.get("current_phase", -1)) == 2 or bool(latest.get("opening_roll_pending", false)):
		return "expected UI opening roll timers to commit before bao-jiao/discard, got %s" % [latest]
	if bool(latest.get("human_ding_que_pending", false)):
		return "expected Neijiang opening flow to skip ding-que after roll, got %s" % [latest]
	return true


func _test_opening_reported_ai_reaction_uses_real_manager_without_stall(root_node: Node):
	var game_manager: GameManager = root_node.get("game_manager") as GameManager
	if game_manager == null or game_manager.game_state == null:
		return "missing game manager/state"
	root_node.call("_on_draw_transition_timer_timeout")
	var game_state = game_manager.game_state
	game_state.start_new_round(true)
	if game_state.ai_manager != null:
		game_state.ai_manager.active_async_requests.clear()
		game_state.ai_manager.active_async_request_keys.clear()
		game_state.ai_manager.set_native_async_enabled(false)
	if game_state.ai_tuning_config != null:
		game_state.ai_tuning_config.apply_preset("bone_ash")
	game_state.ai_level = 2
	game_state.current_dealer_seat = 2
	game_state.current_turn_seat = 2
	game_state.current_phase = 5
	game_state.opening_roll_pending_completion = false
	game_state.opening_roll_data.clear()
	game_state.discard_pile.clear()
	game_state.pending_reactions.clear()
	game_state.current_discard_context.clear()
	game_state.last_draw_tile.clear()
	game_state.last_turn_context = {"seat": 2, "draw_reason": "opening_discard"}
	game_state._clear_pending_ai_async_state()
	game_state.opening_bao_jiao_pending = false
	game_state.opening_bao_jiao_queue.clear()
	game_state.opening_bao_jiao_current_seat = -1
	game_state.wall.clear()
	game_state.wall.append_array(_tiles_from_types([14, 15, 16, 17], 13100))
	game_state.wall_count = game_state.wall.size()
	game_state.players.clear()
	game_state.players.append_array([
		_make_player_for_opening(0, _opening_not_ready_hand(13200)),
		_make_player_for_opening(1, _opening_ready_hand(13300)),
		_make_player_for_opening(2, _tiles_from_types([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], 13400)),
		_make_player_for_opening(3, _opening_not_ready_hand(13500)),
	])
	game_state.players[0]["is_ai"] = false
	for seat in [1, 2, 3]:
		game_state.players[seat]["is_ai"] = true
	game_state.players[1]["bao_jiao"] = true
	game_state.players[1]["bao_jiao_ting_tiles"] = [_make_tile(13600, "tong", 9)]
	game_state.players[1]["rule_marks"] = ["报叫"]
	game_state.players[1]["opening_bao_jiao_reviewed"] = true
	for seat in [0, 3]:
		game_state.players[seat]["opening_bao_jiao_reviewed"] = true
	var dealer_discard_id := int(game_state.players[2]["hand_tiles"][0].get("id", -1))
	if not bool(game_state._discard_tile_internal(2, dealer_discard_id)):
		return "expected dealer first discard to execute, debug=%s" % game_state.debug_last_message
	var after_dealer: Dictionary = game_manager.get_fresh_snapshot()
	root_node.call("_on_snapshot_changed", after_dealer)
	if int(after_dealer.get("current_phase", -1)) != 6 or not bool(game_state.is_ai_reaction_pending()):
		return "expected reported AI seat 1 reaction after dealer discard, got %s" % [after_dealer]
	var reaction_summary := str(after_dealer.get("reaction_summary", ""))
	if not reaction_summary.contains("座位1"):
		return "expected reported AI seat 1 in reaction summary, got %s snapshot=%s" % [reaction_summary, after_dealer]
	var ai_reaction_timer := root_node.get("ai_reaction_timer") as Timer
	if ai_reaction_timer == null or ai_reaction_timer.is_stopped():
		return "expected UI to schedule AI reaction timer after reported AI reaction, timer=%s snapshot=%s" % [
			ai_reaction_timer,
			after_dealer,
		]
	root_node.call("_on_ai_reaction_timer_timeout")
	var latest: Dictionary = game_manager.get_fresh_snapshot()
	if int(latest.get("current_phase", -1)) == 6 and bool(game_state.is_ai_reaction_pending()):
		return "reported AI seat 1 stayed stuck after synchronous real-manager reaction, debug=%s pending_meta=%s pending_decision=%s snapshot=%s ai_core=%s" % [
			game_state.debug_last_message,
			game_state.pending_ai_reaction_request_meta,
			game_state.pending_ai_reaction_decision,
			latest,
			latest.get("ai_core_debug", {}),
		]
	if int(latest.get("current_phase", -1)) != 7 and int(latest.get("current_turn_seat", -1)) == 2:
		return "expected reported AI reaction to advance or settle, got snapshot=%s debug=%s" % [
			latest,
			game_state.debug_last_message,
		]
	return true


func _test_bao_gang_dialog_confirm_advances_opening_bao_jiao(root_node: Node):
	var game_manager: GameManager = root_node.get("game_manager") as GameManager
	if game_manager == null or game_manager.game_state == null:
		return "missing game manager/state"
	var game_state = game_manager.game_state
	game_state.previous_dealer_seat = 1
	game_state.start_new_round(true)
	game_state.wall.clear()
	game_state.wall.append_array(_wall_for_opening_hands([
		_opening_ready_bao_gang_hand(1200),
		_tiles_from_types([0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 17], 2200),
		_tiles_from_types([0, 2, 4, 6, 8, 9, 11, 13, 15, 17, 1, 10, 16], 3200),
		_tiles_from_types([1, 3, 5, 7, 9, 11, 13, 15, 17, 0, 8, 10, 12], 4200),
	], 5200))
	game_state.wall_count = game_state.wall.size()
	if not bool(game_state.complete_opening_roll()):
		return "expected opening roll to complete"
	var snapshot: Dictionary = game_manager.get_fresh_snapshot()
	root_node.call("_on_snapshot_changed", snapshot)
	var plan: Dictionary = snapshot.get("human_bao_jiao_plan", {})
	var options: Array = plan.get("bao_gang_options", [])
	if not bool(snapshot.get("human_can_bao_jiao", false)) or options.is_empty():
		return "expected opening human bao-jiao with bao-gang options, got plan=%s snapshot=%s" % [plan, snapshot]

	root_node.call("_on_bao_jiao_pressed")
	var panel := root_node.get("bao_gang_dialog_content") as Panel
	if panel == null:
		return "expected bao-gang dialog content after pressing bao-jiao"
	var close_button := panel.get_node_or_null("BaoGangCloseButton") as Button
	if close_button == null:
		return "expected close button"
	close_button.pressed.emit()
	if bool(game_state.players[0].get("bao_jiao", false)):
		return "expected close button to cancel selection without declaring"
	if not bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao-jiao window to remain pending after cancel"

	root_node.call("_on_bao_jiao_pressed")
	panel = root_node.get("bao_gang_dialog_content") as Panel
	if panel == null:
		return "expected bao-gang dialog content after reopening"
	var content_box := panel.get_node_or_null("BaoGangSurfaceMargin/BaoGangSurfaceContent") as VBoxContainer
	if content_box == null:
		return "expected bao-gang content box"
	var footer := content_box.get_node_or_null("BaoGangDialogFooter") as HBoxContainer
	if footer == null:
		return "expected confirm/cancel footer"
	var confirm_button := footer.get_node_or_null("BaoGangConfirmButton") as Button
	if confirm_button == null:
		return "expected confirm button"
	confirm_button.pressed.emit()
	if not bool(game_state.players[0].get("bao_jiao", false)):
		return "expected confirm button to declare bao-jiao"
	if Array(game_state.players[0].get("bao_gang_tiles", [])).is_empty():
		return "expected confirm button to submit selected bao-gang keys"
	if bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao-jiao window to finish after confirm, current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]
	if int(game_state.current_turn_seat) != 1 or not bool(game_state.is_ai_turn_ready()):
		return "expected AI dealer first discard to be ready after dialog confirm, turn=%s debug=%s" % [
			game_state.current_turn_seat,
			game_state.debug_last_message,
		]
	return true


func _test_opening_ai_bao_gang_before_human_pass_does_not_stick_ui(root_node: Node):
	var setup_result := _setup_opening_ai_bao_gang_before_human(root_node, 6100)
	if setup_result.has("error"):
		return setup_result["error"]
	var game_state = setup_result["game_state"]
	var pass_button := root_node.get("pass_button") as Button
	if pass_button == null or not pass_button.visible:
		return "expected pass button to be visible while human is asked after AI declarations"
	pass_button.pressed.emit()
	if bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao-jiao window to finish after human pass, current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]
	if not bool(game_state.players[2].get("bao_jiao", false)) or Array(game_state.players[2].get("bao_gang_tiles", [])).is_empty():
		return "expected AI seat 2 to have declared bao-jiao with bao-gang before human pass"
	if int(game_state.current_turn_seat) != 3 or not bool(game_state.is_ai_turn_ready()):
		return "expected AI dealer first discard to be ready after pass, turn=%s debug=%s snapshot=%s" % [
			game_state.current_turn_seat,
			game_state.debug_last_message,
			game_state.get_debug_snapshot(),
		]
		var first_discard_result = _assert_ai_dealer_first_discard_from_ui_timer(root_node, game_state, "human pass")
		if not (first_discard_result is bool and first_discard_result):
			return str(first_discard_result)
	var latest: Dictionary = root_node.get("last_snapshot")
	if bool(latest.get("human_can_pass_opening_bao_jiao", false)) or bool(latest.get("human_can_bao_jiao", false)):
		return "expected UI snapshot to clear opening prompt after pass, got %s" % [latest]
	return true


func _test_opening_ai_bao_gang_after_human_pass_schedules_sync_ai_discard(root_node: Node):
	var setup_result := _setup_opening_ai_bao_gang_before_human(root_node, 6600)
	if setup_result.has("error"):
		return setup_result["error"]
	var game_manager: GameManager = root_node.get("game_manager") as GameManager
	var game_state = setup_result["game_state"]
	var pass_button := root_node.get("pass_button") as Button
	if pass_button == null or not pass_button.visible:
		return "expected pass button while human is asked after AI declarations"
	pass_button.pressed.emit()
	var latest: Dictionary = game_manager.get_snapshot()
	if int(game_state.current_turn_seat) != 3 or not bool(game_state.is_ai_turn_ready()):
		return "expected GameState to publish AI dealer first-discard readiness after human pass, latest=%s debug=%s" % [
			latest,
			game_state.debug_last_message,
		]
	var first_discard_result = _assert_ai_dealer_first_discard_from_ui_timer(root_node, game_state, "human pass sync")
	if not (first_discard_result is bool and first_discard_result):
		return str(first_discard_result)
	return true


func _test_opening_ai_bao_gang_before_human_confirm_does_not_stick_ui(root_node: Node):
	var setup_result := _setup_opening_ai_bao_gang_before_human(root_node, 7100)
	if setup_result.has("error"):
		return setup_result["error"]
	var game_state = setup_result["game_state"]
	root_node.call("_on_bao_jiao_pressed")
	var panel := root_node.get("bao_gang_dialog_content") as Panel
	if panel == null:
		return "expected bao-gang dialog after human bao-jiao press"
	var content_box := panel.get_node_or_null("BaoGangSurfaceMargin/BaoGangSurfaceContent") as VBoxContainer
	if content_box == null:
		return "expected bao-gang content box"
	var footer := content_box.get_node_or_null("BaoGangDialogFooter") as HBoxContainer
	if footer == null:
		return "expected confirm/cancel footer"
	var confirm_button := footer.get_node_or_null("BaoGangConfirmButton") as Button
	if confirm_button == null:
		return "expected confirm button"
	confirm_button.pressed.emit()
	if bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao-jiao window to finish after human confirm behind AI declarations, current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]
	if not bool(game_state.players[0].get("bao_jiao", false)) or Array(game_state.players[0].get("bao_gang_tiles", [])).is_empty():
		return "expected human bao-jiao and selected bao-gang to be recorded"
	if not bool(game_state.players[2].get("bao_jiao", false)) or Array(game_state.players[2].get("bao_gang_tiles", [])).is_empty():
		return "expected AI seat 2 to have declared bao-jiao with bao-gang before human confirm"
	if int(game_state.current_turn_seat) != 3 or not bool(game_state.is_ai_turn_ready()):
		return "expected AI dealer first discard to be ready after confirm, turn=%s debug=%s snapshot=%s" % [
			game_state.current_turn_seat,
			game_state.debug_last_message,
			game_state.get_debug_snapshot(),
		]
		var first_discard_result = _assert_ai_dealer_first_discard_from_ui_timer(root_node, game_state, "human confirm")
		if not (first_discard_result is bool and first_discard_result):
			return str(first_discard_result)
	var latest: Dictionary = root_node.get("last_snapshot")
	if bool(latest.get("human_can_pass_opening_bao_jiao", false)) or bool(latest.get("human_can_bao_jiao", false)):
		return "expected UI snapshot to clear opening prompt after confirm, got %s" % [latest]
	return true


func _test_opening_ai_bao_gang_before_human_dealer_first_discard_does_not_stick_ui(root_node: Node):
	var game_manager: GameManager = root_node.get("game_manager") as GameManager
	if game_manager == null or game_manager.game_state == null:
		return "missing game manager/state"
	var game_state = game_manager.game_state
	game_state.start_new_round(true)
	var fake_manager := FakeOpeningBaoJiaoManager.new()
	fake_manager.ai_turn_analysis_ready.connect(game_state._on_ai_turn_analysis_ready)
	game_state.ai_manager = fake_manager
	if game_state.ai_tuning_config != null:
		game_state.ai_tuning_config.apply_preset("bone_ash")
	game_state.ai_level = 2
	game_state.current_dealer_seat = 0
	game_state.current_turn_seat = 0
	game_state.current_phase = 5
	game_state.discard_pile.clear()
	game_state.last_draw_tile.clear()
	game_state.last_turn_context = {"seat": 0, "draw_reason": "opening_discard"}
	game_state.opening_bao_jiao_pending = false
	game_state.opening_bao_jiao_queue.clear()
	game_state.opening_bao_jiao_current_seat = -1
	game_state.players.clear()
	game_state.players.append_array([
		_make_player_for_opening(0, _tiles_from_types([0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 17], 8100)),
		_make_player_for_opening(1, _opening_ready_hand(8200)),
		_make_player_for_opening(2, _opening_ready_bao_gang_hand(8300)),
		_make_player_for_opening(3, _opening_ready_bao_gang_hand(8400)),
	])
	game_state.players[0]["is_ai"] = false
	game_state.players[1]["is_ai"] = true
	game_state.players[2]["is_ai"] = true
	game_state.players[3]["is_ai"] = true
	game_state.wall_count = 18
	if bool(game_state._start_opening_bao_jiao_window()):
		return "expected all-AI opening bao-jiao window to finish without stopping at human dealer, current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]
	if bool(game_state.opening_bao_jiao_pending):
		return "expected opening window to be closed before human dealer first discard"
	if not bool(game_state.players[3].get("bao_jiao", false)) or Array(game_state.players[3].get("bao_gang_tiles", [])).is_empty():
		return "expected AI seat 3 to declare bao-jiao with bao-gang before human dealer discard"
	var snapshot: Dictionary = game_manager.get_fresh_snapshot()
	root_node.call("_on_snapshot_changed", snapshot)
	if not bool(snapshot.get("human_can_discard", false)):
		return "expected human dealer to be able to discard after AI opening declarations, got %s" % [snapshot]
	if bool(snapshot.get("human_can_pass_opening_bao_jiao", false)) or bool(snapshot.get("human_can_bao_jiao", false)):
		return "expected no opening bao-jiao prompt for human dealer, got %s" % [snapshot]
	var self_tiles: Array = game_state.get_player_hand_tiles(0)
	if self_tiles.is_empty():
		return "expected human dealer hand"
	var tile_id := int(self_tiles[0].get("id", -1))
	if tile_id < 0:
		return "expected human dealer tile id"
	root_node.call("_on_hand_tile_pressed", tile_id)
	root_node.call("_on_hand_tile_pressed", tile_id)
	if game_state.discard_pile.is_empty() or int(game_state.discard_pile[-1].get("seat", -1)) != 0:
		return "expected human dealer first discard in discard pile after clicking a hand tile, debug=%s" % game_state.debug_last_message
	return true


func _test_opening_ai_bao_jiao_only_before_human_pass_does_not_stick_ui(root_node: Node):
	var setup_result := _setup_opening_ai_bao_gang_before_human(root_node, 9100, false)
	if setup_result.has("error"):
		return setup_result["error"]
	var game_state = setup_result["game_state"]
	var pass_button := root_node.get("pass_button") as Button
	if pass_button == null or not pass_button.visible:
		return "expected pass button to be visible while human is asked after AI bao-jiao-only declaration"
	pass_button.pressed.emit()
	if bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao-jiao-only window to finish after human pass, current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]
	if not bool(game_state.players[2].get("bao_jiao", false)):
		return "expected AI seat 2 to declare bao-jiao before human pass"
	if not Array(game_state.players[2].get("bao_gang_tiles", [])).is_empty():
		return "expected AI seat 2 to declare bao-jiao without bao-gang, got %s" % [
			game_state.players[2].get("bao_gang_tiles", []),
		]
	if int(game_state.current_turn_seat) != 3 or not bool(game_state.is_ai_turn_ready()):
		return "expected AI dealer first discard to be ready after bao-jiao-only pass, turn=%s debug=%s snapshot=%s" % [
			game_state.current_turn_seat,
			game_state.debug_last_message,
			game_state.get_debug_snapshot(),
		]
		var first_discard_result = _assert_ai_dealer_first_discard_from_ui_timer(root_node, game_state, "bao-jiao-only human pass")
		if not (first_discard_result is bool and first_discard_result):
			return str(first_discard_result)
	var latest: Dictionary = root_node.get("last_snapshot")
	if bool(latest.get("human_can_pass_opening_bao_jiao", false)) or bool(latest.get("human_can_bao_jiao", false)):
		return "expected UI snapshot to clear opening bao-jiao-only prompt after pass, got %s" % [latest]
	return true


func _test_opening_ai_bao_jiao_only_before_human_confirm_does_not_stick_ui(root_node: Node):
	var setup_result := _setup_opening_ai_bao_gang_before_human(root_node, 10100, false)
	if setup_result.has("error"):
		return setup_result["error"]
	var game_state = setup_result["game_state"]
	var snapshot: Dictionary = root_node.get("last_snapshot")
	var plan: Dictionary = snapshot.get("human_bao_jiao_plan", {})
	if not Array(plan.get("bao_gang_options", [])).is_empty():
		return "expected human bao-jiao-only plan without bao-gang options, got %s" % [plan]
	root_node.call("_on_bao_jiao_pressed")
	if bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao-jiao-only window to finish after human confirm, current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]
	if not bool(game_state.players[0].get("bao_jiao", false)):
		return "expected human bao-jiao-only declaration to be recorded"
	if not Array(game_state.players[0].get("bao_gang_tiles", [])).is_empty():
		return "expected human bao-jiao-only declaration without bao-gang, got %s" % [
			game_state.players[0].get("bao_gang_tiles", []),
		]
	if not bool(game_state.players[2].get("bao_jiao", false)):
		return "expected AI seat 2 to declare bao-jiao before human confirm"
	if not Array(game_state.players[2].get("bao_gang_tiles", [])).is_empty():
		return "expected AI seat 2 to declare bao-jiao without bao-gang before human confirm, got %s" % [
			game_state.players[2].get("bao_gang_tiles", []),
		]
	if int(game_state.current_turn_seat) != 3 or not bool(game_state.is_ai_turn_ready()):
		return "expected AI dealer first discard to be ready after bao-jiao-only confirm, turn=%s debug=%s snapshot=%s" % [
			game_state.current_turn_seat,
			game_state.debug_last_message,
			game_state.get_debug_snapshot(),
		]
		var first_discard_result = _assert_ai_dealer_first_discard_from_ui_timer(root_node, game_state, "bao-jiao-only human confirm")
		if not (first_discard_result is bool and first_discard_result):
			return str(first_discard_result)
	var latest: Dictionary = root_node.get("last_snapshot")
	if bool(latest.get("human_can_pass_opening_bao_jiao", false)) or bool(latest.get("human_can_bao_jiao", false)):
		return "expected UI snapshot to clear opening bao-jiao-only prompt after confirm, got %s" % [latest]
	return true


func _test_opening_ai_bao_gang_then_human_next_turn_can_draw_and_discard(root_node: Node):
	var setup_result := _setup_ai_opening_declaration_then_human_draw(root_node, 11100, true)
	if setup_result.has("error"):
		return setup_result["error"]
	return _assert_human_next_turn_can_discard_after_ai_opening_declaration(
		root_node,
		setup_result["game_state"],
		"AI bao-jiao with bao-gang"
	)


func _test_opening_ai_bao_jiao_only_then_human_next_turn_can_draw_and_discard(root_node: Node):
	var setup_result := _setup_ai_opening_declaration_then_human_draw(root_node, 12100, false)
	if setup_result.has("error"):
		return setup_result["error"]
	return _assert_human_next_turn_can_discard_after_ai_opening_declaration(
		root_node,
		setup_result["game_state"],
		"AI bao-jiao only"
	)


func _setup_ai_opening_declaration_then_human_draw(root_node: Node, id_start: int, with_bao_gang: bool) -> Dictionary:
	var game_manager: GameManager = root_node.get("game_manager") as GameManager
	if game_manager == null or game_manager.game_state == null:
		return {"error": "missing game manager/state"}
	root_node.call("_on_draw_transition_timer_timeout")
	var game_state = game_manager.game_state
	game_state.start_new_round(true)
	var fake_manager := FakeOpeningBaoJiaoManager.new()
	fake_manager.discard_from_end = true
	fake_manager.ai_turn_analysis_ready.connect(game_state._on_ai_turn_analysis_ready)
	game_state.ai_manager = fake_manager
	if game_state.ai_tuning_config != null:
		game_state.ai_tuning_config.apply_preset("bone_ash")
	game_state.ai_level = 2
	game_state.current_dealer_seat = 3
	game_state.current_turn_seat = 3
	game_state.current_phase = 5
	game_state.discard_pile.clear()
	game_state.last_draw_tile.clear()
	game_state.last_turn_context = {"seat": 3, "draw_reason": "opening_discard"}
	game_state.opening_bao_jiao_pending = false
	game_state.opening_bao_jiao_queue.clear()
	game_state.opening_bao_jiao_current_seat = -1
	game_state.wall.clear()
	game_state.wall.append_array(_tiles_from_types([17, 16, 15, 14], id_start + 500))
	game_state.wall_count = game_state.wall.size()
	var ai_opening_hand := _opening_ready_bao_gang_hand(id_start + 200) if with_bao_gang else _opening_ready_hand(id_start + 200)
	game_state.players.clear()
	game_state.players.append_array([
		_make_player_for_opening(0, _opening_not_ready_hand(id_start)),
		_make_player_for_opening(1, _opening_not_ready_hand(id_start + 100)),
		_make_player_for_opening(2, ai_opening_hand),
		_make_player_for_opening(3, _tiles_from_types([0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 17], id_start + 300)),
	])
	game_state.players[0]["is_ai"] = false
	game_state.players[1]["is_ai"] = true
	game_state.players[2]["is_ai"] = true
	game_state.players[3]["is_ai"] = true
	if bool(game_state._start_opening_bao_jiao_window()):
		return {"error": "expected AI-only opening declarations to finish without stopping at human, current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]}
	if not bool(game_state.players[2].get("bao_jiao", false)):
		return {"error": "expected AI seat 2 to declare opening bao-jiao"}
	var ai_bao_gang_tiles: Array = game_state.players[2].get("bao_gang_tiles", [])
	if with_bao_gang and ai_bao_gang_tiles.is_empty():
		return {"error": "expected AI seat 2 to declare bao-gang tiles"}
	if not with_bao_gang and not ai_bao_gang_tiles.is_empty():
		return {"error": "expected AI seat 2 to declare bao-jiao only, got bao_gang_tiles=%s" % [ai_bao_gang_tiles]}
	var snapshot: Dictionary = game_manager.get_fresh_snapshot()
	root_node.call("_on_snapshot_changed", snapshot)
	if bool(snapshot.get("human_can_bao_jiao", false)) or bool(snapshot.get("human_can_pass_opening_bao_jiao", false)):
		return {"error": "expected human not to be in opening bao-jiao prompt, got %s" % [snapshot]}
	if int(snapshot.get("current_turn_seat", -1)) != 3 or not bool(game_state.is_ai_turn_ready()):
		return {"error": "expected AI dealer to be ready for first discard after AI declaration, got %s" % [snapshot]}
	return {"game_state": game_state}


func _assert_human_next_turn_can_discard_after_ai_opening_declaration(root_node: Node, game_state, context: String):
	var first_discard_result = _assert_ai_dealer_first_discard_from_ui_timer(root_node, game_state, context)
	if typeof(first_discard_result) != TYPE_BOOL or not bool(first_discard_result):
		return first_discard_result
	var game_manager: GameManager = root_node.get("game_manager") as GameManager
	var latest: Dictionary = game_manager.get_fresh_snapshot()
	root_node.call("_on_snapshot_changed", latest)
	for _step in range(8):
		if int(latest.get("current_phase", -1)) == 5 and int(latest.get("current_turn_seat", -1)) == 0:
			break
		if not bool(game_state.is_ai_turn_ready()):
			break
		if not _drive_one_ai_turn_from_ui_timer(root_node, game_state, "%s step %d" % [context, _step]):
			break
		latest = game_manager.get_fresh_snapshot()
		root_node.call("_on_snapshot_changed", latest)
	if int(latest.get("current_phase", -1)) != 5 or int(latest.get("current_turn_seat", -1)) != 0:
		return "expected human seat 0 discard turn after %s, got %s" % [context, latest]
	if not bool(latest.get("human_can_discard", false)):
		return "expected human_can_discard after %s, got %s" % [context, latest]
	if int(latest.get("recent_draw_seat", -1)) != 0:
		return "expected human to have drawn before discard after %s, got %s" % [context, latest]
	var self_tiles: Array = game_state.get_player_hand_tiles(0)
	if self_tiles.is_empty():
		return "expected human hand after drawing from %s" % context
	root_node.call("_on_draw_transition_timer_timeout")
	var tile_id := int(self_tiles[0].get("id", -1))
	if tile_id < 0:
		return "expected a playable human tile id after %s" % context
	root_node.call("_on_hand_tile_pressed", tile_id)
	root_node.call("_on_hand_tile_pressed", tile_id)
	if game_state.discard_pile.is_empty() or int(game_state.discard_pile[-1].get("seat", -1)) != 0:
		return "expected human discard to enter discard pile after %s, debug=%s" % [context, game_state.debug_last_message]
	return true


func _drive_one_ai_turn_from_ui_timer(root_node: Node, game_state, context: String) -> bool:
	var game_manager: GameManager = root_node.get("game_manager") as GameManager
	root_node.call("_on_snapshot_changed", game_manager.get_fresh_snapshot())
	var ai_turn_timer := root_node.get("ai_turn_timer") as Timer
	if ai_turn_timer == null or ai_turn_timer.is_stopped():
		root_node.call("_on_draw_transition_timer_timeout")
		root_node.call("_on_snapshot_changed", game_manager.get_fresh_snapshot())
		if ai_turn_timer == null or ai_turn_timer.is_stopped():
			return false
	game_state.pump_ai_background_requests()
	root_node.call("_on_ai_turn_timer_timeout")
	return true


func _setup_opening_ai_bao_gang_before_human(root_node: Node, id_start: int, with_bao_gang: bool = true) -> Dictionary:
	var game_manager: GameManager = root_node.get("game_manager") as GameManager
	if game_manager == null or game_manager.game_state == null:
		return {"error": "missing game manager/state"}
	var game_state = game_manager.game_state
	game_state.start_new_round(true)
	var fake_manager := FakeOpeningBaoJiaoManager.new()
	fake_manager.ai_turn_analysis_ready.connect(game_state._on_ai_turn_analysis_ready)
	game_state.ai_manager = fake_manager
	if game_state.ai_tuning_config != null:
		game_state.ai_tuning_config.apply_preset("bone_ash")
	game_state.ai_level = 2
	game_state.current_dealer_seat = 3
	game_state.current_turn_seat = 3
	game_state.current_phase = 5
	game_state.discard_pile.clear()
	game_state.last_draw_tile.clear()
	game_state.last_turn_context = {"seat": 3, "draw_reason": "opening_discard"}
	game_state.opening_bao_jiao_pending = false
	game_state.opening_bao_jiao_queue.clear()
	game_state.opening_bao_jiao_current_seat = -1
	var human_opening_hand := _opening_ready_bao_gang_hand(id_start) if with_bao_gang else _opening_ready_hand(id_start)
	var ai_opening_hand := _opening_ready_bao_gang_hand(id_start + 200) if with_bao_gang else _opening_ready_hand(id_start + 200)
	game_state.players.clear()
	game_state.players.append_array([
		_make_player_for_opening(0, human_opening_hand),
		_make_player_for_opening(1, _opening_ready_hand(id_start + 100)),
		_make_player_for_opening(2, ai_opening_hand),
		_make_player_for_opening(3, _tiles_from_types([0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 17], id_start + 300)),
	])
	game_state.players[0]["is_ai"] = false
	game_state.players[1]["is_ai"] = true
	game_state.players[2]["is_ai"] = true
	game_state.players[3]["is_ai"] = true
	game_state.wall_count = 18
	if not bool(game_state._start_opening_bao_jiao_window()):
		return {"error": "expected opening bao-jiao window to start"}
	if int(game_state.opening_bao_jiao_current_seat) != 0:
		return {"error": "expected AI seats before human to be processed before stopping at human, current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]}
	if not bool(game_state.players[2].get("bao_jiao", false)):
		return {"error": "expected AI seat 2 to declare before human prompt"}
	var snapshot: Dictionary = game_manager.get_fresh_snapshot()
	root_node.call("_on_snapshot_changed", snapshot)
	if not bool(snapshot.get("human_can_pass_opening_bao_jiao", false)):
		return {"error": "expected human pass to be available after AI declarations, got %s" % [snapshot]}
	if not bool(snapshot.get("human_can_bao_jiao", false)):
		return {"error": "expected human bao-jiao to be available after AI declarations, got %s" % [snapshot]}
	return {"game_state": game_state}


func _assert_ai_dealer_first_discard_from_ui_timer(root_node: Node, game_state, context: String):
	var ai_turn_timer := root_node.get("ai_turn_timer") as Timer
	if ai_turn_timer == null:
		return "expected AI turn timer to exist after %s" % context
	if ai_turn_timer.is_stopped():
		return "expected UI to schedule AI dealer first-discard timer after %s" % context
	root_node.call("_on_ai_turn_timer_timeout")
	if game_state.discard_pile.is_empty():
		return "expected AI dealer first discard to enter discard pile after %s" % context
	var discard: Dictionary = game_state.discard_pile[-1]
	if int(discard.get("seat", -1)) != 3:
		return "expected dealer seat 3 first discard after %s, got %s" % [context, discard]
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


func _tiles_from_types(tile_types: Array, id_start: int) -> Array:
	var result: Array = []
	var index := 0
	for tile_type in tile_types:
		var type_value := int(tile_type)
		var suit := "tiao" if type_value < 9 else "tong"
		var rank := type_value + 1 if type_value < 9 else type_value - 8
		result.append(_make_tile(id_start + index, suit, rank))
		index += 1
	return result


func _opening_ready_bao_gang_hand(id_start: int = 6000) -> Array:
	return _tiles_from_types([0, 0, 0, 1, 2, 3, 4, 5, 9, 9, 15, 16, 17], id_start)


func _opening_ready_hand(id_start: int = 5000) -> Array:
	return _tiles_from_types([0, 0, 1, 2, 3, 4, 5, 9, 10, 11, 15, 16, 17], id_start)


func _opening_not_ready_hand(id_start: int = 7000) -> Array:
	return _tiles_from_types([0, 2, 4, 6, 8, 9, 11, 13, 15, 1, 3, 5, 7], id_start)


func _make_player_for_opening(seat: int, hand_tiles: Array) -> Dictionary:
	return {
		"seat": seat,
		"name": "玩家%d" % seat,
		"is_ai": seat != 0,
		"hand_tiles": hand_tiles.duplicate(true),
		"hand_count": hand_tiles.size(),
		"melds": [],
		"discards": [],
		"score": 0,
		"ding_que": "",
		"bao_jiao": false,
		"bao_gang_tiles": [],
		"opening_bao_jiao_reviewed": false,
		"bao_jiao_ting_tiles": [],
		"rule_marks": [],
		"has_won": false,
	}


func _wall_for_opening_hands(hands_by_seat: Array, filler_id_start: int) -> Array:
	var result: Array = _tiles_from_types([2, 4, 6, 8, 10, 12, 14, 16, 3, 5, 7, 9, 11, 13, 15, 17, 1, 0, 6], filler_id_start)
	for seat in range(hands_by_seat.size() - 1, -1, -1):
		result.append_array(Array(hands_by_seat[seat]).duplicate(true))
	return result


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


class FakeOpeningBaoJiaoManager:
	extends RefCounted

	signal ai_turn_analysis_ready(request_id: int, seat_index: int, analysis: Dictionary)

	var latest_turn_snapshot: Dictionary = {}
	var latest_reaction_snapshot: Dictionary = {}
	var next_request_id: int = 1
	var pending_turn_requests: Dictionary = {}
	var preferred_discard_key: String = ""
	var discard_from_end: bool = false

	func analyze_bao_jiao(_player_state: Dictionary, _table_state: Dictionary, _rules_config, plan: Dictionary) -> Dictionary:
		return {
			"action": "bao_jiao",
			"declare": true,
			"selected_bao_gang_keys": plan.get("bao_gang_keys", []).duplicate(true),
			"score": 100,
			"reasons": ["ui regression fake opening declaration"],
			"backend_mode": "ui_regression_fake_bao_jiao",
		}

	func analyze_turn(player_state: Dictionary, table_state: Dictionary, _rules_config, _ai_config, _hu_checker, _risk_analyzer, _allow_cheat: bool = false) -> Dictionary:
		return _build_turn_analysis(player_state, table_state)

	func analyze_turn_lightweight(player_state: Dictionary, table_state: Dictionary, _rules_config, _ai_config, _hu_checker, _risk_analyzer, _allow_cheat: bool = false) -> Dictionary:
		return _build_turn_analysis(player_state, table_state)

	func start_turn_analysis_background(player_state: Dictionary, table_state: Dictionary, _rules_config, _ai_config, _hu_checker, _risk_analyzer, _allow_cheat: bool = false, _hell_payload: Dictionary = {}, _force_lightweight: bool = false, _compact_result: bool = false, _force_native_async: bool = false, _allow_sync_delivery: bool = true) -> int:
		var analysis := _build_turn_analysis(player_state, table_state)
		if analysis.is_empty():
			return 0
		var request_id := next_request_id
		next_request_id += 1
		latest_turn_snapshot = {
			"seat": int(player_state.get("seat", -1)),
			"analysis": analysis.duplicate(true),
		}
		ai_turn_analysis_ready.emit(request_id, int(player_state.get("seat", -1)), analysis.duplicate(true))
		return request_id

	func _build_turn_analysis(player_state: Dictionary, table_state: Dictionary) -> Dictionary:
		var hand_tiles: Array = player_state.get("hand_tiles", [])
		if hand_tiles.is_empty():
			return {}
		var tile: Dictionary = hand_tiles[0].duplicate(true)
		var last_draw: Dictionary = table_state.get("last_draw_tile", {})
		var last_draw_tile: Dictionary = last_draw.get("tile", {})
		if bool(player_state.get("bao_jiao", false)) and int(last_draw.get("seat", -1)) == int(player_state.get("seat", -1)) and not last_draw_tile.is_empty():
			tile = last_draw_tile.duplicate(true)
		elif not preferred_discard_key.is_empty():
			for tile_item in hand_tiles:
				var candidate: Dictionary = tile_item
				if _key_for_tile(candidate) == preferred_discard_key:
					tile = candidate.duplicate(true)
					break
		elif discard_from_end:
			tile = Dictionary(hand_tiles[hand_tiles.size() - 1]).duplicate(true)
		return {
			"action": "discard",
			"backend": "ui_regression_fake_turn",
			"backend_mode": "ui_regression_fake_turn",
			"recommended": {
				"tile": tile.duplicate(true),
				"csharp_tile_type": _tile_type(tile),
			},
			"options": [],
			"danger_tiles": [],
		}

	func pump_async_requests() -> int:
		var delivered := 0
		for request_id in pending_turn_requests.keys():
			var request: Dictionary = pending_turn_requests[request_id]
			ai_turn_analysis_ready.emit(int(request_id), int(request.get("seat", -1)), request.get("analysis", {}).duplicate(true))
			delivered += 1
		pending_turn_requests.clear()
		return delivered

	func has_native_csharp_runtime() -> bool:
		return false

	func has_native_hell_challenge_runtime() -> bool:
		return false

	func set_native_csharp_runtime(_runtime) -> void:
		pass

	func set_compact_runtime_snapshots(_enabled: bool) -> void:
		pass

	func get_backend_status() -> Dictionary:
		return {"backend_mode": "ui_regression_fake_bao_jiao"}

	func get_debug_snapshot() -> Dictionary:
		return {"backend_status": get_backend_status()}

	func _tile_type(tile: Dictionary) -> int:
		var suit := str(tile.get("suit", ""))
		var rank := int(tile.get("rank", 0))
		if suit == "tiao":
			return rank - 1
		if suit == "tong":
			return 9 + rank - 1
		return -1

	func _key_for_tile(tile: Dictionary) -> String:
		return "%s_%d" % [str(tile.get("suit", "")), int(tile.get("rank", 0))]
