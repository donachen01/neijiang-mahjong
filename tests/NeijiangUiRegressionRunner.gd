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
	_run_test("neijiang_settlement_hides_stale_ding_que_tags", _test_neijiang_settlement_hides_stale_ding_que_tags.bind(root_node), failures)
	_run_test("top_right_x_exit_button_is_visible", _test_top_right_x_exit_button_is_visible.bind(root_node), failures)
	_run_test("main_controls_are_layered_by_purpose", _test_main_controls_are_layered_by_purpose.bind(root_node), failures)

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
