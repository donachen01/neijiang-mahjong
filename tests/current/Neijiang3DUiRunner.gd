extends SceneTree

const TABLE_STAGE_SCRIPT := preload("res://scripts/ui/3d/NeijiangTableStage3D.gd")
const ACTION_BAR_SCRIPT := preload("res://scripts/ui/table/NeijiangActionBar.gd")
const SEAT_HUD_SCRIPT := preload("res://scripts/ui/table/NeijiangSeatHUD.gd")
const UTILITY_BAR_SCRIPT := preload("res://scripts/ui/table/NeijiangUtilityBar.gd")
const TILE_SCRIPT := preload("res://scripts/ui/3d/NeijiangTile3D.gd")
const MAIN_SCENE := preload("res://scenes/table/MainSceneV2.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_verify_mobile_renderer_contract(failures)
	await _verify_table_stage_contract(failures)
	await _verify_action_bar_contract(failures)
	await _verify_seat_hud_contract(failures)
	await _verify_utility_bar_contract(failures)
	_verify_tile_manufacturing_contract(failures)
	await _verify_main_scene_adapter(failures)
	if failures.is_empty():
		print("NEIJIANG 3D UI REGRESSION OK")
		quit(0)
		return
	push_error("NEIJIANG 3D UI REGRESSION FAILED:\n- %s" % "\n- ".join(failures))
	quit(1)


func _verify_mobile_renderer_contract(failures: Array[String]) -> void:
	var mobile_renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", ""))
	if mobile_renderer != "forward_plus":
		failures.append(
			"Sichuan-derived PBR table requires forward_plus on mobile, got %s" % mobile_renderer
		)


func _verify_table_stage_contract(failures: Array[String]) -> void:
	var stage := TABLE_STAGE_SCRIPT.new() as NeijiangTableStage3D
	get_root().add_child(stage)
	await process_frame
	var players := _players_fixture()
	var all_hands: Array = []
	for player in players:
		all_hands.append(Array(player.get("hand_tiles", [])).duplicate(true))
	var snapshot := {
		"players": players,
		"rules": {
			"mode": "neijiang_classic",
			"available_suits": ["tiao", "tong"],
			"total_tile_count": 72,
			"use_ding_que_phase": false,
		},
		"wall_count": 19,
		"current_turn_seat": 0,
		"current_dealer_seat": 0,
		"human_can_discard": true,
		"human_last_draw_tile_id": 14,
		"recent_discard_tile_id": 103,
	}
	stage.render_snapshot(snapshot, all_hands, false, -1, {})
	var contract: Dictionary = stage.get_visual_contract()
	if int(contract.get("wall_count", -1)) != 19:
		failures.append("3D stage did not preserve the 72-tile snapshot wall count")
	if str(contract.get("table_asset", "")) != "neijiang_table_v2_pbr":
		failures.append("3D stage did not load the Neijiang-authored PBR table")
	var bao_entry: Dictionary = stage.get_motion_entry_contract("hand_0_2")
	if not bool(bao_entry.get("bao_gang_declared", false)):
		failures.append("declared bao-gang hand tile lost its persistent 3D marker")
	var sorted_hand := stage.call("_sort_human_hand_for_display", [
		{"id": 2, "suit": "tong", "rank": 1},
		{"id": 1, "suit": "tiao", "rank": 9},
	]) as Array
	if sorted_hand.is_empty() or str((sorted_hand[0] as Dictionary).get("suit", "")) != "tiao":
		failures.append("Neijiang 3D hand sorting did not use the two-suit order")
	await process_frame
	var pick_tile := stage.tile_nodes.get("hand_0_2") as NeijiangTile3D
	if pick_tile == null:
		failures.append("3D stage did not create a stable hand tile node for input routing")
	else:
		var pick_rect := pick_tile.get_screen_rect(stage.camera)
		var emitted_ids: Array[int] = []
		stage.tile_pressed.connect(func(tile_id: int) -> void: emitted_ids.append(tile_id))
		var picked_id := stage.pick_tile(pick_rect.get_center())
		if picked_id != 2 or emitted_ids != [2]:
			failures.append("3D stage did not emit the projected hand tile's original tile id")
	stage.queue_free()
	await process_frame


func _verify_action_bar_contract(failures: Array[String]) -> void:
	var action_bar := ACTION_BAR_SCRIPT.new() as NeijiangActionBar
	get_root().add_child(action_bar)
	await process_frame
	action_bar.render([
		{"id": "hu", "label": "胡"},
		{"id": "gang", "label": "补杠"},
		{"id": "an_gang", "label": "报杠"},
		{"id": "peng", "label": "碰"},
		{"id": "bao_jiao", "label": "报叫/报杠"},
		{"id": "pass", "label": "过"},
	], "内江动作合同")
	var visible_actions := action_bar.get_visible_actions()
	if visible_actions.size() != 6:
		failures.append("Neijiang action bar expected 6 simultaneous actions, got %d" % visible_actions.size())
	var bao_button := action_bar.get_button("bao_jiao")
	if bao_button == null or bao_button.text != "报叫/报杠":
		failures.append("Neijiang action bar lost the dynamic bao-jiao/bao-gang label")
	var contract := action_bar.get_visual_contract()
	if int(contract.get("maximum_actions", 0)) < 6:
		failures.append("Neijiang action bar contract does not support all six action slots")
	action_bar.queue_free()
	await process_frame


func _verify_seat_hud_contract(failures: Array[String]) -> void:
	var hud := SEAT_HUD_SCRIPT.new() as NeijiangSeatHUD
	get_root().add_child(hud)
	await process_frame
	hud.configure(0)
	hud.render({
		"nickname": "本家",
		"score": 12,
		"bao_jiao": true,
		"bao_gang_tiles": ["tiao_2", "tong_6"],
		"has_won": false,
	}, 0, 0)
	var contract := hud.get_visual_contract()
	if bool(contract.get("shows_ding_que", true)):
		failures.append("Neijiang SeatHUD incorrectly exposes Sichuan ding-que state")
	if not bool(contract.get("shows_bao_jiao", false)) or not bool(contract.get("shows_bao_gang_count", false)):
		failures.append("Neijiang SeatHUD did not expose bao-jiao/bao-gang state")
	if str(contract.get("material_family", "")) != "unified_smoked_jade_nameplate":
		failures.append("Neijiang SeatHUD did not retain the Sichuan smoked-jade material family")
	if str(contract.get("active_text_badge", "missing")) != "none":
		failures.append("Neijiang SeatHUD reintroduced a text-only active state badge")
	if not bool(contract.get("active_state_uses_shape_and_color", false)):
		failures.append("Neijiang SeatHUD active state lost its stable edge treatment")
	if hud.report_badge == null or hud.report_badge.text != "杠×2":
		failures.append("Neijiang SeatHUD did not render the bao-gang count")
	hud.queue_free()
	await process_frame


func _verify_utility_bar_contract(failures: Array[String]) -> void:
	var utility_bar := UTILITY_BAR_SCRIPT.new() as NeijiangUtilityBar
	get_root().add_child(utility_bar)
	await process_frame
	var contract := utility_bar.get_visual_contract()
	if not bool(contract.get("collapsed_by_default", false)) or not utility_bar.is_collapsed():
		failures.append("牌桌工具未默认折叠到左上角")
	if utility_bar.get_button("toggle") == null or utility_bar.panel == null or utility_bar.panel.visible:
		failures.append("牌桌工具折叠按钮或抽屉初始状态错误")
	utility_bar.set_collapsed(false)
	if not utility_bar.panel.visible:
		failures.append("牌桌工具抽屉无法展开")
	var emitted_actions: Array[String] = []
	utility_bar.utility_selected.connect(func(action: String) -> void: emitted_actions.append(action))
	for action in ["difficulty", "tuning", "helper", "opponents", "settlement", "next_round", "view", "exit"]:
		var action_button := utility_bar.get_button(action)
		if action_button == null:
			failures.append("折叠工具抽屉丢失原有动作: %s" % action)
			continue
		action_button.pressed.emit()
	if emitted_actions != ["difficulty", "tuning", "helper", "opponents", "settlement", "next_round", "view", "exit"]:
		failures.append("折叠工具抽屉改变了原有 utility_selected 事件顺序或 action ID")
	utility_bar.set_collapsed(true)
	if not utility_bar.activate_at_global_position(utility_bar.toggle_button.get_global_rect().get_center(), false) \
		or utility_bar.is_collapsed():
		failures.append("折叠键的实际命中坐标无法展开工具抽屉")
	if not utility_bar.activate_at_global_position(utility_bar.toggle_button.get_global_rect().get_center(), false) \
		or not utility_bar.is_collapsed():
		failures.append("折叠键的实际命中坐标无法收起工具抽屉")
	utility_bar.queue_free()
	await process_frame


func _verify_tile_manufacturing_contract(failures: Array[String]) -> void:
	var contract := TILE_SCRIPT.get_manufacturing_contract()
	if int(contract.get("physical_layer_count", 0)) != 2:
		failures.append("四川玉石麻将牌不再是双实体层结构")
	var layers := contract.get("layers", []) as Array
	if layers.size() != 2:
		failures.append("麻将牌制造合同层数不完整")
		return
	var back := layers[0] as Dictionary
	var body := layers[1] as Dictionary
	if not is_equal_approx((back.get("size", Vector3.ZERO) as Vector3).y, 0.074):
		failures.append("翡翠背层厚度偏离 0.074")
	if not is_equal_approx((body.get("size", Vector3.ZERO) as Vector3).y, 0.166):
		failures.append("象牙牌身厚度偏离 0.166")
	if str(back.get("color", "")) != "178b32" or str(body.get("color", "")) != "e4ded2":
		failures.append("麻将牌翡翠/暖象牙基色偏离本轮制造合同")


func _verify_main_scene_adapter(failures: Array[String]) -> void:
	var main_scene := MAIN_SCENE.instantiate()
	get_root().add_child(main_scene)
	await process_frame
	await process_frame
	if not bool(main_scene.get("table_3d_enabled")):
		failures.append("Neijiang 3D table is not the default UI")
	if main_scene.get("table_stage_3d") == null:
		failures.append("MainScene did not install the snapshot-driven 3D stage")
	if main_scene.get("table_3d_action_bar") == null or main_scene.get("table_3d_utility_bar") == null:
		failures.append("MainScene did not install the Neijiang action/utility adapters")
	main_scene.call("_on_snapshot_changed", main_scene.get("last_snapshot"))
	var top_next_round := main_scene.get_node_or_null(
		"UILayer/RootUI/SafeArea/MainVBox/TopBar/TopBarMargin/TopBarRow/TopNextRoundButton"
	) as Control
	if top_next_round != null and top_next_round.visible:
		failures.append("legacy next-round button resurfaced during a 3D snapshot refresh")
	var legacy_panels: Dictionary = main_scene.get("v17_player_info_panels")
	for panel_value in legacy_panels.values():
		var legacy_panel := panel_value as Control
		if legacy_panel != null and legacy_panel.visible:
			failures.append("legacy seat panel resurfaced during a 3D snapshot refresh")
			break
	main_scene.call("_set_neijiang_3d_ui_enabled", false)
	var restore_button := main_scene.get("table_3d_restore_button") as Button
	if restore_button == null or not restore_button.visible:
		failures.append("legacy 2D fallback cannot restore the 3D table")
	main_scene.call("_set_neijiang_3d_ui_enabled", true)
	if restore_button == null or restore_button.visible:
		failures.append("3D restore control should hide after returning to the 3D table")
	main_scene.queue_free()
	await process_frame


func _players_fixture() -> Array:
	var players: Array = []
	for seat in range(4):
		var hand: Array = []
		for rank in range(1, 10):
			hand.append({"id": seat * 100 + rank, "suit": "tiao" if rank <= 5 else "tong", "rank": rank})
		players.append({
			"seat": seat,
			"nickname": "玩家%d" % seat,
			"score": 0,
			"hand_tiles": hand,
			"hand_count": hand.size(),
			"melds": [],
			"discards": [
				{"id": seat * 100 + 101, "suit": "tiao", "rank": 1},
				{"id": seat * 100 + 102, "suit": "tong", "rank": 2},
				{"id": seat * 100 + 103, "suit": "tiao", "rank": 3},
			],
			"bao_jiao": seat == 0,
			"bao_gang_tiles": ["tiao_2"] if seat == 0 else [],
			"has_won": false,
		})
	return players
