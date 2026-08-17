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
	if not bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)):
		failures.append(
			"Sichuan-derived PBR table requires ETC2/ASTC imports for iOS and Android packages"
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
	stage.render_snapshot(snapshot, all_hands, false, -1, {
		"recommended_tile_id": 1,
		"danger_tile_ids": [2],
	})
	var contract: Dictionary = stage.get_visual_contract()
	if int(contract.get("wall_count", -1)) != 19:
		failures.append("3D stage did not preserve the 72-tile snapshot wall count")
	if str(contract.get("table_asset", "")) != "neijiang_table_v2_pbr":
		failures.append("3D stage did not load the Neijiang-authored PBR table")
	if str(contract.get("table_trim_finish", "")) != "continuous_outer_and_inner_champagne_gold_inlay":
		failures.append("3D table lost the reference-matched continuous double champagne-gold inlay")
	if str(contract.get("table_divider_finish", "")) != "two_continuous_low_contrast_emerald_felt_insets_without_corner_motifs":
		failures.append("3D table restored obsolete centre-corner lines instead of the two calm felt insets")
	var manufactured_table := stage.get_node_or_null("ManufacturedClubTable")
	if manufactured_table == null:
		failures.append("3D stage did not instantiate the production manufactured table")
	else:
		for required_mesh_name: String in [
			"OuterChampagneGoldPiping",
			"InnerChampagneGoldPiping",
			"PlayfieldInsetOuter",
			"PlayfieldInsetInner",
		]:
			if manufactured_table.find_child(required_mesh_name, true, false) == null:
				failures.append("Production table GLB is stale or missing %s" % required_mesh_name)
	var helper_visuals := stage.get_ai_helper_visual_contract()
	if helper_visuals.get("recommended_tile_ids", []) != [1] \
		or int(helper_visuals.get("visible_recommended_markers", 0)) != 1:
		failures.append("AI helper recommendation did not reach a visible 3D self-hand marker: %s" % [helper_visuals])
	if helper_visuals.get("danger_tile_ids", []) != [2] \
		or int(helper_visuals.get("visible_danger_markers", 0)) != 1:
		failures.append("AI helper danger data did not reach a visible 3D self-hand marker: %s" % [helper_visuals])
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
	if str(contract.get("font_path", "")) != "res://res/fonts/app_cjk.ttc":
		failures.append("Neijiang action bar does not bind the packaged CJK font")
	if bao_button != null and bao_button.get_theme_font("font").resource_path != "res://res/fonts/app_cjk.ttc":
		failures.append("Neijiang action button theme does not actually use the packaged CJK font")
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
	if str(contract.get("name_font_path", "")) != "res://res/fonts/nameplate_calligraphy.ttf" \
		or str(contract.get("body_font_path", "")) != "res://res/fonts/app_cjk.ttc":
		failures.append("Neijiang SeatHUD does not bind its packaged name/body CJK fonts")
	if hud.name_label.get_theme_font("font").resource_path != "res://res/fonts/nameplate_calligraphy.ttf" \
		or hud.score_label.get_theme_font("font").resource_path != "res://res/fonts/app_cjk.ttc":
		failures.append("Neijiang SeatHUD theme does not actually use the packaged CJK fonts")
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
	if str(contract.get("font_path", "")) != "res://res/fonts/app_cjk.ttc":
		failures.append("牌桌工具没有绑定发布包内置中文字体")
	var difficulty_button := utility_bar.get_button("difficulty")
	if difficulty_button == null or difficulty_button.get_theme_font("font").resource_path != "res://res/fonts/app_cjk.ttc":
		failures.append("牌桌工具按钮主题没有实际使用发布包内置中文字体")
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
	var authored_stage := main_scene.get_node_or_null("GameScene/NeijiangTableStage3D") as Node3D
	if authored_stage == null:
		failures.append("MainScene does not author the 3D stage as a fixed scene node")
	get_root().add_child(main_scene)
	await process_frame
	await process_frame
	if not bool(main_scene.get("table_3d_enabled")):
		failures.append("Neijiang 3D table is not the default UI")
	var installed_stage := main_scene.get("table_stage_3d") as Node3D
	if installed_stage == null:
		failures.append("MainScene did not install the snapshot-driven 3D stage")
	elif installed_stage != authored_stage:
		failures.append("MainScene replaced the fixed 3D stage with a runtime-only node")
	elif not installed_stage.has_method("is_render_ready") or not bool(installed_stage.call("is_render_ready")):
		failures.append("MainScene fixed 3D stage did not reach render-ready state")
	else:
		var stage_contract := installed_stage.call("get_visual_contract") as Dictionary
		if not Array(stage_contract.get("center_direction_labels", ["unexpected"])).is_empty():
			failures.append("Center instrument reintroduced direction glyphs after the numeric-only decision")
		if str(stage_contract.get("camera_aspect_policy", "")) != "keep_width_mobile_full_bleed":
			failures.append("Camera no longer preserves the mobile full-bleed table contract")
		if int(stage_contract.get("mobile_directional_shadow_size", 0)) < 4096:
			failures.append("Mobile directional shadow map must retain the 4096 anti-jagged contract")
		if int(stage_contract.get("mobile_soft_shadow_filter_quality", -1)) < 2:
			failures.append("Mobile soft-shadow filtering must remain medium quality or better")
		if not is_equal_approx(float(stage_contract.get("directional_shadow_opacity", 0.0)), 0.64):
			failures.append("Opponent rack shadow opacity drifted from the Sichuan-matched 0.64")
		if not is_equal_approx(float(stage_contract.get("directional_shadow_blur", 0.0)), 1.90):
			failures.append("Opponent rack shadow blur drifted from the Sichuan-matched 1.90")
		if not installed_stage.find_children("CenterDirectionLabel*", "Label3D", true, false).is_empty():
			failures.append("Center instrument node tree still contains direction Label3D nodes")
		if str(stage_contract.get("center_display_shape", "")) != "single_extruded_deep_jade_body_with_four_flush_colour_fields_and_single_gold_ring":
			failures.append("Center instrument regressed from the single-ring reference-style Blender model")
		for extra_base_index in range(1, 4):
			if installed_stage.find_child("DirectionBase%d" % extra_base_index, true, false) != null:
				failures.append("Center instrument reintroduced an extra physical field boundary at DirectionBase%d" % extra_base_index)
		if str(stage_contract.get("center_component_boundaries", "")).find("without_internal_physical_bevel_seams") < 0:
			failures.append("Center colour fields and pearl separators no longer share the seam-free boundary contract")
		if str(stage_contract.get("center_active_color_hex", "")) != "F4C430":
			failures.append("Center instrument active sector must be signal yellow rather than metallic gold")
		if str(stage_contract.get("center_inactive_color_hex", "")) != "3A644D":
			failures.append("Center instrument inactive plates lost the sampled deep-jade colour")
		if str(stage_contract.get("center_light_rig", "")).find("whole_instrument_warm_spot") < 0:
			failures.append("Center instrument lost its whole-assembly key light")
		if installed_stage.find_child("CounterSingleGoldRing", true, false) == null \
				or installed_stage.find_child("CounterNumberPlate", true, false) == null:
			failures.append("Center instrument lost its single gold ring or number plate")
		if installed_stage.find_child("CounterIvoryRing", true, false) != null \
				or installed_stage.find_child("CounterInnerGoldLip", true, false) != null:
			failures.append("Center instrument incorrectly retained stacked physical rings")
	if main_scene.get("table_3d_action_bar") == null or main_scene.get("table_3d_utility_bar") == null:
		failures.append("MainScene did not install the Neijiang action/utility adapters")
	main_scene.call("_on_snapshot_changed", main_scene.get("last_snapshot"))
	main_scene.call("_apply_neijiang_3d_layout")
	var seat_huds: Dictionary = main_scene.get("table_3d_seat_huds")
	for seat in range(4):
		var seat_hud := seat_huds.get(seat) as Control
		var tile_rects: Array = installed_stage.call("get_seat_play_screen_rects", seat) \
			if installed_stage != null and installed_stage.has_method("get_seat_play_screen_rects") else []
		for tile_rect_value in tile_rects:
			if seat_hud != null and seat_hud.get_global_rect().intersects(tile_rect_value as Rect2):
				failures.append("Seat %d HUD overlaps a projected 3D hand/meld tile" % seat)
				break
		if seat_hud != null and installed_stage != null:
			var play_rect := installed_stage.call("get_seat_play_screen_rect", seat) as Rect2
			if play_rect.size.x > 1.0:
				var hud_center := seat_hud.get_global_rect().get_center()
				var play_center := play_rect.get_center()
				if seat in [0, 1] and hud_center.x >= play_center.x:
					failures.append("Seat %d HUD is not docked to the requested left outer lane" % seat)
				if seat in [2, 3] and hud_center.x <= play_center.x:
					failures.append("Seat %d HUD is not docked to the requested right outer lane" % seat)
	var root_ui := main_scene.get("root_ui") as Control
	var viewport_size := root_ui.size if root_ui != null else Vector2(2560.0, 1440.0)
	var self_rect := (seat_huds.get(0) as Control).get_global_rect()
	var left_rect := (seat_huds.get(1) as Control).get_global_rect()
	var right_rect := (seat_huds.get(3) as Control).get_global_rect()
	var self_play_rect := installed_stage.call("get_seat_play_screen_rect", 0) as Rect2
	var self_clear_left_or_above := self_play_rect.size.y <= 1.0 \
		or self_rect.end.x <= self_play_rect.position.x - 4.0 \
		or self_rect.end.y <= self_play_rect.position.y - 4.0
	if self_rect.position.x > viewport_size.x * 0.04 or not self_clear_left_or_above:
		failures.append("Self HUD is no longer pinned left and above the self hand: hud=%s play=%s viewport=%s" % [self_rect, self_play_rect, viewport_size])
	if left_rect.position.x > viewport_size.x * 0.04 or left_rect.position.y > viewport_size.y * 0.22:
		failures.append("Left HUD is no longer pinned to the requested upper-left screen lane: hud=%s viewport=%s" % [left_rect, viewport_size])
	if right_rect.end.x < viewport_size.x * 0.96 or right_rect.position.y > viewport_size.y * 0.22:
		failures.append("Right HUD is no longer pinned to the requested upper-right screen lane: hud=%s viewport=%s" % [right_rect, viewport_size])
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
	# The AI helper is shared gameplay UI.  Exercise the real utility event path,
	# then prove the 3D legacy-hiding guard no longer removes its advice panel.
	var game_manager := main_scene.get("game_manager") as GameManager
	main_scene.set("ai_helper_enabled", false)
	game_manager.set_human_trainer_hint_enabled(false)
	var utility_bar := main_scene.get("table_3d_utility_bar") as NeijiangUtilityBar
	utility_bar.utility_selected.emit("helper")
	await process_frame
	if not bool(main_scene.get("ai_helper_enabled")) \
		or not bool(game_manager.game_state.get("human_trainer_hint_enabled")):
		failures.append("3D utility helper action did not enable the GameState trainer hint")
	var helper_tile := {"id": 99101, "suit": "tiao", "rank": 1}
	var helper_snapshot := {
		"players": [{"seat": 0, "hand_tiles": [helper_tile], "has_won": false}],
		"rules": {"use_ding_que_phase": false},
		"human_can_discard": true,
	}
	var helper_hint := {
		"recommended": {"tile_name": "1条", "tile": helper_tile, "live_ukeire": 6, "risk": 8},
		"recommended_tile_id": 99101,
		"danger_tile_ids": [],
		"options": [],
	}
	main_scene.call("_update_discard_helper_panel", helper_snapshot, helper_hint, true)
	main_scene.call("_enforce_neijiang_3d_legacy_visibility")
	var helper_panel := main_scene.get("discard_helper_panel") as Control
	var helper_summary := main_scene.get("discard_helper_summary") as Label
	if helper_panel == null or not helper_panel.visible or helper_summary == null or helper_summary.text != "打 1条":
		failures.append("3D mode still hides or loses the AI advice panel")
	elif helper_panel.get_global_rect().intersects(self_play_rect, true):
		failures.append("3D AI advice panel overlaps the projected self hand: helper=%s hand=%s" % [helper_panel.get_global_rect(), self_play_rect])
	utility_bar.utility_selected.emit("helper")
	await process_frame
	if bool(main_scene.get("ai_helper_enabled")) \
		or bool(game_manager.game_state.get("human_trainer_hint_enabled")) \
		or (helper_panel != null and helper_panel.visible):
		failures.append("3D utility helper action did not fully disable helper state and panel")
	main_scene.call("_apply_neijiang_3d_fallback")
	var background := main_scene.get_node_or_null("UILayer/RootUI/Background") as Control
	var safe_area := main_scene.get_node_or_null("UILayer/RootUI/SafeArea") as Control
	var table_ui := main_scene.get("table_3d_ui_root") as Control
	if background == null or not background.visible or safe_area == null or not safe_area.visible:
		failures.append("3D startup failure does not restore the complete legacy table surface")
	if table_ui != null and table_ui.visible:
		failures.append("3D startup failure leaves the partial 3D HUD over the legacy fallback")
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
