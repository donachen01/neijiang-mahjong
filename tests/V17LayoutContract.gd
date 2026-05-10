extends SceneTree

const MAIN_SCENE := preload("res://scenes/table/MainSceneV2.tscn")
const PLAYER_UI_SCENE := preload("res://scenes/ui/PlayerUI.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var root_node := MAIN_SCENE.instantiate()
	get_root().add_child(root_node)
	await process_frame
	await process_frame

	_check_self_integrated_row_contract(root_node, failures)
	_check_player_lane_rects(root_node, failures)
	_check_center_discard_rects(root_node, failures)
	_check_center_discard_grid_contract(root_node, failures)
	_check_horizontal_discard_band_contract(root_node, failures)
	_check_side_discard_band_contract(root_node, failures)
	_check_center_discard_space_balance(root_node, failures)
	_check_top_controls_separation(root_node, failures)
	_check_action_helper_layer_contract(root_node, failures)
	_check_top_integrated_row_contract(root_node, failures)
	await _check_self_actual_meld_row_contract(root_node, failures)
	_check_self_embedded_row_contract(root_node, failures)
	_check_self_hand_fill_contract(root_node, failures)
	await _check_self_winning_tile_not_duplicated(root_node, failures)
	_check_frontend_design_layout_contract(root_node, failures)
	_check_self_status_badge_contract(root_node, failures)
	await _check_side_hu_slot_contract(failures)
	await _check_opponent_tile_size_contract(failures)
	_check_cross_plate_separation(root_node, failures)

	if failures.is_empty():
		print("V17 LAYOUT CONTRACT OK")
		quit(0)
		return

	push_error("V17 LAYOUT CONTRACT FAILED:\n- " + "\n- ".join(failures))
	quit(1)


func _check_self_integrated_row_contract(root_node: Node, failures: Array[String]) -> void:
	var root_ui: Control = root_node.get_node_or_null("UILayer/RootUI") as Control
	var self_meld: Control = _find_control(root_node, "SelfInfoHost")
	var hand_host: Control = _find_control(root_node, "SelfHandHost")
	if root_ui == null or self_meld == null or hand_host == null:
		failures.append("缺少 RootUI / SelfInfoHost / SelfHandHost")
		return
	if not hand_host.has_method("embed_left_host") or not hand_host.has_method("embed_right_host"):
		failures.append("本家 18 槽横排必须支持左侧碰杠与右侧胡牌嵌入")
	var dynamic_rect: Rect2 = root_node.call("_v17_self_dynamic_rect")
	var hand_rect: Rect2 = root_node.call("_v17_self_hand_rect")
	if absf(dynamic_rect.size.x - hand_rect.size.x) > 2.0:
		failures.append("本家手牌容器应占用完整 18 槽横排宽度")


func _check_player_lane_rects(root_node: Node, failures: Array[String]) -> void:
	for node_name in ["PlayerTopHost", "PlayerLeftHost", "PlayerRightHost"]:
		var host: Control = _find_control(root_node, node_name)
		if host == null:
			failures.append("缺少玩家牌区 %s" % node_name)
			continue
		var rect := host.get_global_rect()
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			failures.append("玩家牌区 %s 尺寸无效" % node_name)
		if node_name == "PlayerTopHost":
			if rect.size.x < 1380.0 or rect.size.y < 198.0:
				failures.append("对家碰杠+手牌+胡牌区应扩大到红框范围，当前 %.1fx%.1f" % [rect.size.x, rect.size.y])
		else:
			if rect.size.x < 340.0 or rect.size.y < 650.0:
				failures.append("%s 碰杠+手牌+胡牌区应扩大到红框范围，当前 %.1fx%.1f" % [node_name, rect.size.x, rect.size.y])
			if rect.position.y < 176.0:
				failures.append("%s 牌道整体太靠上，应下移避免被上方区域遮挡，当前 y %.1f" % [node_name, rect.position.y])


func _find_control(root_node: Node, node_name: String) -> Control:
	return root_node.find_child(node_name, true, false) as Control


func _check_center_discard_rects(root_node: Node, failures: Array[String]) -> void:
	for property_name in [
		"board_discard_top_lane",
		"board_discard_bottom_lane",
		"board_discard_left_lane",
		"board_discard_right_lane",
	]:
		var lane: Control = root_node.get(property_name) as Control
		if lane == null:
			failures.append("缺少中心出牌区域 %s" % property_name)
			continue
		var rect := lane.get_global_rect()
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			failures.append("中心出牌区域 %s 尺寸无效" % property_name)


func _check_center_discard_grid_contract(root_node: Node, failures: Array[String]) -> void:
	var expected_capacity := int(root_node.get("MAX_DISCARD_PER_SEAT"))
	if int(root_node.get("CENTER_DISCARD_SIDE_COLUMNS")) != 5:
		failures.append("上家/下家中心出牌区应改为 5 张一组分栏，避免 6 张一列太挤")
	for seat in [0, 1, 2, 3]:
		var capacity := int(root_node.call("_center_discard_capacity_for_seat", seat))
		if capacity != expected_capacity:
			failures.append("内江麻将每家弃牌区应按 %d 张上限截断，当前 seat %d = %d" % [expected_capacity, seat, capacity])

	var center_plate: Control = root_node.get("board_cross_center_plate") as Control
	var top_lane: Control = root_node.get("board_discard_top_lane") as Control
	if center_plate == null or top_lane == null:
		failures.append("缺少中心岛或对家弃牌区")
		return
	var center_rect := center_plate.get_global_rect()
	var top_rect := top_lane.get_global_rect()
	if center_rect.size.x > top_rect.size.x * 0.38:
		failures.append("中心骰子岛过宽，应缩小给四家弃牌区让位")
	if center_rect.size.y > top_rect.size.y * 1.05:
		failures.append("中心骰子岛过高，应只保留紧凑风向/骰子信息")


func _check_horizontal_discard_band_contract(root_node: Node, failures: Array[String]) -> void:
	var expected_limit := int(root_node.get("MAX_DISCARD_PER_SEAT"))
	if int(root_node.get("CENTER_DISCARD_TOP_LIMIT")) != expected_limit:
		failures.append("对家弃牌区上限应保持内江麻将 %d 张规则" % expected_limit)
	if int(root_node.get("CENTER_DISCARD_BOTTOM_LIMIT")) != expected_limit:
		failures.append("本家弃牌区上限应保持内江麻将 %d 张规则" % expected_limit)
	if int(root_node.get("CENTER_DISCARD_TOP_COLUMNS")) != 7:
		failures.append("对家弃牌区应改为 7 张一排、两排容纳 14 张，保持与侧家弃牌相同牌尺寸")
	if int(root_node.get("CENTER_DISCARD_BOTTOM_COLUMNS")) != 7:
		failures.append("本家弃牌区应改为 7 张一排、两排容纳 14 张，保持与侧家弃牌相同牌尺寸")
	var side_scale := float(root_node.get("CENTER_DISCARD_SIDE_SCALE"))
	if absf(float(root_node.get("CENTER_DISCARD_TOP_SCALE")) - side_scale) > 0.02:
		failures.append("对家弃牌牌尺寸应与上家/下家弃牌一致")
	if absf(float(root_node.get("CENTER_DISCARD_BOTTOM_SCALE")) - side_scale) > 0.02:
		failures.append("本家弃牌牌尺寸应与上家/下家弃牌一致")
	if side_scale < 0.74:
		failures.append("四家弃牌麻将牌仍偏小，当前缩放 %.2f，应放大到 0.74 左右" % side_scale)
	for item in [
		{"seat": 2, "lane": root_node.get("board_discard_top_lane"), "columns": int(root_node.get("CENTER_DISCARD_TOP_COLUMNS")), "limit": int(root_node.get("CENTER_DISCARD_TOP_LIMIT")), "scale": float(root_node.get("CENTER_DISCARD_TOP_SCALE")), "name": "对家"},
		{"seat": 0, "lane": root_node.get("board_discard_bottom_lane"), "columns": int(root_node.get("CENTER_DISCARD_BOTTOM_COLUMNS")), "limit": int(root_node.get("CENTER_DISCARD_BOTTOM_LIMIT")), "scale": float(root_node.get("CENTER_DISCARD_BOTTOM_SCALE")), "name": "本家"},
	]:
		var lane: Control = item["lane"] as Control
		if lane == null:
			failures.append("%s弃牌区缺少渲染层" % str(item["name"]))
			continue
		root_node.call(
			"_render_center_lane",
			lane,
			_fake_tiles(expected_limit),
			int(item["columns"]),
			int(item["limit"]),
			float(item["scale"]),
			-1,
			int(item["seat"])
		)
		var children := lane.get_children()
		if children.size() != expected_limit:
			failures.append("%s弃牌区应显示规则上限 %d 张，当前只显示 %d 张" % [str(item["name"]), expected_limit, children.size()])
			continue
		var expected_tile_size: Vector2 = root_node.call("_discard_tile_visual_size", float(item["scale"]))
		var used_rect := _children_local_bounds_with_visual_size(children, expected_tile_size)
		var tile_visuals: Array[Control] = []
		_collect_tile_visual_controls(lane, tile_visuals)
		var first_tile := tile_visuals[0] if not tile_visuals.is_empty() else children[0] as Control
		if used_rect.size.x < lane.size.x * 0.32:
			failures.append("%s弃牌区横向利用率不足，当前 %.1f / %.1f，应按 7 张一排居中排布" % [str(item["name"]), used_rect.size.x, lane.size.x])
		if first_tile != null:
			var measured_tile_height := expected_tile_size.y
			if measured_tile_height > 118.0:
				failures.append("%s弃牌区麻将牌过大，当前牌高 %.1f，会挤压中心区" % [str(item["name"]), measured_tile_height])
			if measured_tile_height < 112.0:
				failures.append("%s弃牌区麻将牌仍偏小，当前牌高 %.1f，应继续放大" % [str(item["name"]), measured_tile_height])
			var expected_two_row_height := measured_tile_height * 2.0 + float(root_node.get("CENTER_DISCARD_SEPARATION"))
			if absf(used_rect.size.y - expected_two_row_height) > 16.0:
				failures.append("%s弃牌区应按 7 张一排形成两排，当前用高 %.1f / 预期 %.1f" % [str(item["name"]), used_rect.size.y, expected_two_row_height])
		if int(item["seat"]) == 0 and used_rect.position.y > lane.size.y * 0.24:
			failures.append("本家弃牌应从靠近中心的一侧开始排布，不能沉到底部")
		if int(item["seat"]) == 2 and used_rect.end.y < lane.size.y * 0.76:
			failures.append("对家弃牌应从靠近中心的一侧开始排布，不能浮到顶部")


func _check_side_discard_band_contract(root_node: Node, failures: Array[String]) -> void:
	var expected_limit := int(root_node.get("MAX_DISCARD_PER_SEAT"))
	var side_scale := float(root_node.get("CENTER_DISCARD_SIDE_SCALE"))
	for item in [
		{"seat": 1, "lane": root_node.get("board_discard_left_lane"), "name": "上家"},
		{"seat": 3, "lane": root_node.get("board_discard_right_lane"), "name": "下家"},
	]:
		var lane: Control = item["lane"] as Control
		if lane == null:
			failures.append("%s弃牌区缺少渲染层" % str(item["name"]))
			continue
		root_node.call(
			"_render_center_lane",
			lane,
			_fake_tiles(expected_limit),
			5,
			expected_limit,
			side_scale,
			-1,
			int(item["seat"])
		)
		var children := lane.get_children()
		if children.size() != expected_limit:
			failures.append("%s弃牌区应显示规则上限 %d 张，当前只显示 %d 张" % [str(item["name"]), expected_limit, children.size()])
			continue
		var actual_scale: float = root_node.call(
			"_discard_fit_scale_for_seat",
			int(item["seat"]),
			lane.size,
			expected_limit,
			5,
			side_scale
		)
		var expected_tile_size: Vector2 = root_node.call("_discard_tile_visual_size", actual_scale)
		var oriented_visual_size := Vector2(expected_tile_size.y, expected_tile_size.x)
		var used_rect := _children_local_bounds_with_visual_size(children, oriented_visual_size)
		if oriented_visual_size.x < 98.0:
			failures.append("%s弃牌麻将牌缩得过小，当前长边 %.1f，应优先横向向中心扩展而不是过度缩放" % [str(item["name"]), oriented_visual_size.x])
		if used_rect.size.y > lane.size.y + 2.0:
			failures.append("%s弃牌区高度不足，5 张一列会被裁切，当前用高 %.1f / 槽高 %.1f" % [str(item["name"]), used_rect.size.y, lane.size.y])
		if used_rect.size.x > lane.size.x + 2.0:
			failures.append("%s弃牌区宽度不足，两列弃牌会被裁切，当前用宽 %.1f / 槽宽 %.1f" % [str(item["name"]), used_rect.size.x, lane.size.x])
		var left_margin := used_rect.position.x
		var right_margin := lane.size.x - used_rect.end.x
		var top_margin := used_rect.position.y
		var bottom_margin := lane.size.y - used_rect.end.y
		if left_margin < 4.0 or right_margin < 4.0:
			failures.append("%s弃牌应完整装进绿色框内，左右至少留出内边距，当前 %.1f / %.1f" % [str(item["name"]), left_margin, right_margin])
		if int(item["seat"]) == 1 and top_margin > 12.0:
			failures.append("%s弃牌应从玩家视角靠中心顶格开始排，当前顶部留白 %.1f" % [str(item["name"]), top_margin])
		if int(item["seat"]) == 3 and bottom_margin > 12.0:
			failures.append("下家弃牌应从下家视角左上角开始排，映射到本家视角应贴近左下角，当前底部留白 %.1f" % bottom_margin)
		if int(item["seat"]) == 1:
			if right_margin > 12.0:
				failures.append("上家弃牌应贴近中心侧右边排布，当前右侧留白 %.1f" % right_margin)
			if left_margin < right_margin + 36.0:
				failures.append("上家弃牌不应在框内居中，应靠中心侧顶格")
		if int(item["seat"]) == 3:
			if left_margin > 12.0:
				failures.append("下家弃牌应贴近中心侧左边排布，当前左侧留白 %.1f" % left_margin)
			if right_margin < left_margin + 36.0:
				failures.append("下家弃牌不应在框内居中，应靠中心侧顶格")


func _check_center_discard_space_balance(root_node: Node, failures: Array[String]) -> void:
	var top_lane: Control = root_node.get("board_discard_top_lane") as Control
	var bottom_lane: Control = root_node.get("board_discard_bottom_lane") as Control
	var left_lane: Control = root_node.get("board_discard_left_lane") as Control
	var right_lane: Control = root_node.get("board_discard_right_lane") as Control
	if top_lane == null or bottom_lane == null or left_lane == null or right_lane == null:
		failures.append("缺少弃牌区，无法验证四家空间比例")
		return
	var top_rect := top_lane.get_global_rect()
	var bottom_rect := bottom_lane.get_global_rect()
	var left_rect := left_lane.get_global_rect()
	var right_rect := right_lane.get_global_rect()
	if top_rect.size.y < 232.0:
		failures.append("对家弃牌区应向中心扩展，当前高度 %.1f 太小" % top_rect.size.y)
	if bottom_rect.size.y < 232.0:
		failures.append("本家弃牌区应向中心扩展，当前高度 %.1f 太小" % bottom_rect.size.y)
	if left_rect.size.x < 410.0:
		failures.append("上家弃牌区应向中心扩展，当前宽度 %.1f 太窄" % left_rect.size.x)
	if right_rect.size.x < 410.0:
		failures.append("下家弃牌区应向中心扩展，当前宽度 %.1f 太窄" % right_rect.size.x)
	if left_rect.size.y < 420.0:
		failures.append("上家弃牌区高度不足，当前 %.1f，放大后会裁切" % left_rect.size.y)
	if right_rect.size.y < 420.0:
		failures.append("下家弃牌区高度不足，当前 %.1f，放大后会裁切" % right_rect.size.y)
	if left_rect.intersects(top_rect, true) or right_rect.intersects(top_rect, true):
		failures.append("上家/下家弃牌区不能侵占对家弃牌区，只能横向向中心扩展")
	if left_rect.intersects(bottom_rect, true) or right_rect.intersects(bottom_rect, true):
		failures.append("上家/下家弃牌区不能侵占本家弃牌区，只能横向向中心扩展")
	var left_plate: Control = root_node.get("board_cross_left_plate") as Control
	var right_plate: Control = root_node.get("board_cross_right_plate") as Control
	if left_plate == null or right_plate == null:
		failures.append("缺少左右绿色弃牌框，无法验证侧家弃牌是否装入框中")
		return
	if not _rect_contains_rect(left_plate.get_global_rect().grow(2.0), left_rect):
		failures.append("上家弃牌绿色框应完整包住上家弃牌区域，避免白牌出框")
	if not _rect_contains_rect(right_plate.get_global_rect().grow(2.0), right_rect):
		failures.append("下家弃牌绿色框应完整包住下家弃牌区域，避免白牌出框")


func _check_top_controls_separation(root_node: Node, failures: Array[String]) -> void:
	var top_bar: Control = _find_control(root_node, "TopBar")
	var info_panel: Control = root_node.get("v17_player_info_panels").get(2) as Control
	if top_bar == null or info_panel == null:
		failures.append("缺少顶部按钮栏或对家信息牌，无法验证右上避让")
		return
	var snapshot := {
		"players": [
			{"seat": 1, "nickname": "上家", "score": 0},
			{"seat": 2, "nickname": "对家", "score": 120},
			{"seat": 3, "nickname": "下家", "score": -40},
		],
		"current_dealer_seat": 2,
		"rules": {"use_ding_que_phase": true},
		"ai_tuning_config": {"preset_name": "bone_ash"},
	}
	root_node.call("_update_top_bar", snapshot)
	var legacy_info_card: Control = _find_control(root_node, "InfoCard")
	if legacy_info_card != null and legacy_info_card.visible:
		failures.append("旧 TopBar 信息卡不应在右上角露出，应把空间留给对家信息牌与竖排按钮")
	var settlement_button: Control = _find_control(root_node, "TopSettlementInfoButton")
	if settlement_button != null:
		settlement_button.visible = true
	root_node.call("_layout_v17_top_button_stack")
	root_node.call("_update_v17_player_info_panels", snapshot)
	var top_bar_rect := top_bar.get_global_rect()
	var info_rect := info_panel.get_global_rect()
	if info_rect.position.y > top_bar_rect.position.y + 36.0:
		failures.append("对家姓名/积分牌应靠顶显示，当前 y %.1f" % info_rect.position.y)
	var root_ui: Control = root_node.get_node_or_null("UILayer/RootUI") as Control
	if root_ui != null and info_rect.position.x > root_ui.size.x * 0.76:
		failures.append("对家姓名/积分牌应更靠近牌桌左侧，避免看起来像右家信息，当前 x %.1f" % info_rect.position.x)
	if info_rect.size.x < 260.0 or info_rect.size.y < 118.0:
		failures.append("对家姓名/积分牌不应过小，当前 %.1fx%.1f" % [info_rect.size.x, info_rect.size.y])
	var visible_top_buttons: Array[Control] = []
	for button_name in ["TopBarButton", "TopSettlementInfoButton", "TopNextRoundButton"]:
		var button: Control = _find_control(root_node, button_name)
		if button != null and button.visible:
			visible_top_buttons.append(button)
			if info_rect.intersects(button.get_global_rect(), true):
				failures.append("对家姓名/积分牌不应遮盖顶部按钮 %s" % button_name)
	if visible_top_buttons.size() < 3:
		failures.append("右上角应保留 3 个竖排按钮，当前可见 %d 个" % visible_top_buttons.size())
	else:
		visible_top_buttons.sort_custom(func(a: Control, b: Control) -> bool:
			return a.get_global_rect().position.y < b.get_global_rect().position.y
		)
		var first_rect := visible_top_buttons[0].get_global_rect()
		if first_rect.position.y < 28.0:
			failures.append("右上角竖排按钮太贴顶，应下移与对家信息牌形成同一组顶部控件")
		var previous_rect := first_rect
		for index in range(1, visible_top_buttons.size()):
			var current_rect := visible_top_buttons[index].get_global_rect()
			if absf(current_rect.position.x - first_rect.position.x) > 4.0:
				failures.append("右上角 3 个按钮应竖排同列")
				break
			if current_rect.position.y < previous_rect.end.y + 4.0:
				failures.append("右上角竖排按钮间距不足，仍像横向挤在一起")
				break
			previous_rect = current_rect


func _check_action_helper_layer_contract(root_node: Node, failures: Array[String]) -> void:
	var action_panel: Control = _find_control(root_node, "ActionPanel")
	var helper_panel: Control = _find_control(root_node, "DiscardHelperPanel")
	var helper_button: Control = _find_control(root_node, "DiscardHelperActionButton")
	if action_panel == null:
		failures.append("缺少碰杠胡操作面板")
		return
	if helper_panel == null:
		failures.append("缺少 AI 出牌提示面板")
		return
	if action_panel.z_index <= helper_panel.z_index:
		failures.append("碰杠胡操作面板层级必须高于 AI 提示面板")
	if helper_button != null and helper_button.visible:
		failures.append("AI 提示不应再显示“选中推荐”按钮")
	if helper_panel.custom_minimum_size.x < 480.0:
		failures.append("AI 提示应作为手牌上方横向悬浮信息条，当前宽度 %.1f 太窄" % helper_panel.custom_minimum_size.x)
	if helper_panel.custom_minimum_size.y > 104.0:
		failures.append("AI 提示面板过高，会遮挡主桌面和碰杠胡按钮")
	var action_snapshot := {
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
	}
	root_node.call("_refresh_action_panel", action_snapshot)
	root_node.call("_layout_action_panel")
	helper_panel.visible = true
	root_node.call("_position_discard_helper_panel")
	var action_rect := action_panel.get_global_rect()
	var helper_rect := helper_panel.get_global_rect()
	var hand_host: Control = _find_control(root_node, "SelfHandHost")
	var hand_rect := hand_host.get_global_rect() if hand_host != null else Rect2()
	var action_buttons: GridContainer = _find_control(root_node, "ActionButtons") as GridContainer
	if action_buttons != null and action_buttons.columns < 4:
		failures.append("碰杠胡操作按钮应横排显示，当前 columns = %d" % action_buttons.columns)
	var action_status: Control = _find_control(root_node, "ActionStatusLabel")
	if action_status != null and action_status.visible:
		failures.append("我的碰杠胡按钮上方不要再显示小提示文字")
	if action_rect.size.x <= action_rect.size.y:
		failures.append("碰杠胡操作面板应是横向大按钮条，当前 %.1fx%.1f" % [action_rect.size.x, action_rect.size.y])
	for button_name in ["HuButton", "GangButton", "PengButton", "PassButton"]:
		var button: Control = _find_control(root_node, button_name)
		if button != null and button.visible and (button.size.x < 108.0 or button.size.y < 68.0):
			failures.append("%s 应更大，当前 %.1fx%.1f" % [button_name, button.size.x, button.size.y])
	if hand_rect.size.y > 1.0:
		if helper_rect.end.y > hand_rect.position.y - 8.0:
			failures.append("AI 提示信息应悬浮在手牌上方的主桌面上，不能落入手牌托盘")
		if absf(helper_rect.get_center().x - hand_rect.get_center().x) > hand_rect.size.x * 0.32:
			failures.append("AI 提示信息应位于我的手牌上方附近，而不是远离手牌")
	var board_area: Control = _find_control(root_node, "BoardArea")
	if board_area != null and helper_panel.z_index <= board_area.z_index:
		failures.append("AI 提示层级应高于主桌面")
	if helper_rect.intersects(action_rect, true):
		failures.append("AI 提示浮层不应遮挡碰杠胡悬浮按钮")
	elif helper_rect.end.x > action_rect.position.x - 12.0 and absf(helper_rect.position.y - action_rect.position.y) < action_rect.size.y:
		failures.append("AI 提示浮层应与碰杠胡按钮保留清晰横向避让")


func _check_top_integrated_row_contract(root_node: Node, failures: Array[String]) -> void:
	var top_ui: Control = root_node.get("top_ui") as Control
	if top_ui == null:
		failures.append("缺少对家 UI")
		return
	var sample_player := {
		"seat": 2,
		"name": "对家",
		"score": 0,
		"hand_count": 13,
		"hand_tiles": [],
		"melds": [
			{
				"type": "peng",
				"from_seat": 1,
				"tiles": [
					{"id": 101, "suit": "tiao", "rank": 1},
					{"id": 102, "suit": "tiao", "rank": 1},
					{"id": 103, "suit": "tiao", "rank": 1},
				],
			},
		],
		"has_won": true,
		"winning_tile": {"id": 201, "suit": "wan", "rank": 9},
		"winning_source_seat": 0,
	}
	top_ui.call("apply_snapshot", sample_player, true, -1, -1, true)
	var row_root: Control = top_ui.find_child("HorizontalRowRoot", true, false) as Control
	if row_root == null:
		failures.append("对家应使用 18 槽一体横排容器 HorizontalRowRoot")
		return
	var board_rect: Rect2 = root_node.call("_v17_board_rect")
	var row_rect := row_root.get_global_rect()
	var info_rect: Rect2 = root_node.call("_v17_player_info_rect", 2)
	if row_rect.position.x > board_rect.position.x + 40.0:
		failures.append("对家 18 槽横排应朝左侧空白扩展，当前左边 %.1f / 桌面左边 %.1f" % [row_rect.position.x, board_rect.position.x])
	var info_gap := info_rect.position.x - row_rect.end.x
	if info_gap < 4.0:
		failures.append("对家手牌+碰杠+胡牌区应避开姓名积分框，当前右边 %.1f / 信息框左边 %.1f" % [row_rect.end.x, info_rect.position.x])
	if info_gap > 56.0:
		failures.append("对家手牌+碰杠+胡牌区应再向右靠近姓名积分框，当前间距 %.1f" % info_gap)
	if row_root.size.x > 1470.0:
		failures.append("对家横排容器过宽，会撞到右侧信息区，当前宽 %.1f" % row_root.size.x)
	if row_root.size.x < 1400.0:
		failures.append("对家手牌+碰杠+胡牌区整体偏小，应向右拉长并吃满顶部空间，当前宽 %.1f" % row_root.size.x)
	if row_root.size.y > 192.0:
		failures.append("对家横排容器过高，会挤压牌桌主体，当前高 %.1f" % row_root.size.y)
	if row_root.size.y < 172.0:
		failures.append("对家横排容器偏矮，无法承载放大的手牌/碰杠/胡牌")
	var hand_slot: Control = row_root.find_child("TopHandSlot", true, false) as Control
	if hand_slot == null:
		failures.append("对家一体横排应标记 TopHandSlot，便于约束手牌区域比例")
	elif hand_slot.size.x > row_root.size.x * 0.74:
		failures.append("对家手牌槽过宽，横排空白会过大")
	var meld_slot: Control = row_root.find_child("TopMeldSlot", true, false) as Control
	var hu_slot: Control = row_root.find_child("TopHuSlot", true, false) as Control
	if meld_slot != null and hand_slot != null:
		var meld_to_hand_gap := hand_slot.position.x - meld_slot.get_rect().end.x
		if meld_to_hand_gap < 20.0:
			failures.append("对家碰杠牌和手牌之间应像本家一样留出间距，当前 %.1f" % meld_to_hand_gap)
	if hand_slot != null and hu_slot != null and hu_slot.visible:
		var hand_to_hu_gap := hu_slot.position.x - hand_slot.get_rect().end.x
		if hand_to_hu_gap < 20.0:
			failures.append("对家手牌和胡牌之间应留出间距，当前 %.1f" % hand_to_hu_gap)


func _check_self_actual_meld_row_contract(root_node: Node, failures: Array[String]) -> void:
	var self_info: Control = _find_control(root_node, "SelfInfoHost")
	var hand_host: Control = _find_control(root_node, "SelfHandHost")
	if self_info == null or hand_host == null:
		failures.append("缺少本家碰杠宿主或手牌横排，无法验证真实碰杠牌高度")
		return
	var self_ui := _find_player_ui_in_host(self_info)
	if self_ui == null:
		failures.append("SelfInfoHost 内缺少真正的 PlayerUI 节点")
		return
	var sample_player := {
		"seat": 0,
		"nickname": "本家",
		"score": 0,
		"hand_count": 4,
		"hand_tiles": _fake_tiles(4),
		"melds": [
			{
				"type": "peng",
				"from_seat": 1,
				"tiles": [
					{"id": 3101, "suit": "tong", "rank": 8},
					{"id": 3102, "suit": "tong", "rank": 8},
					{"id": 3103, "suit": "tong", "rank": 8},
				],
			},
			{
				"type": "peng",
				"from_seat": 2,
				"tiles": [
					{"id": 3201, "suit": "wan", "rank": 5},
					{"id": 3202, "suit": "wan", "rank": 5},
					{"id": 3203, "suit": "wan", "rank": 5},
				],
			},
			{
				"type": "gang",
				"from_seat": 3,
				"tiles": [
					{"id": 3301, "suit": "tiao", "rank": 2},
					{"id": 3302, "suit": "tiao", "rank": 2},
					{"id": 3303, "suit": "tiao", "rank": 2},
					{"id": 3304, "suit": "tiao", "rank": 2},
				],
			},
		],
		"discards": [],
		"ding_que": "wan",
		"has_won": true,
		"win_type": "discard_win",
		"winning_tile": {"id": 3401, "suit": "tiao", "rank": 6},
		"winning_source_seat": 1,
	}
	self_ui.call("apply_snapshot", sample_player, false, -1, -1, true)
	root_node.call("_update_self_row_slot_layout", sample_player, 4)
	hand_host.call("configure_hand", _fake_tiles(4), -1, -1, false, {}, {})
	root_node.call("_update_self_hu_tile_display", sample_player["winning_tile"], 1)
	await process_frame
	await process_frame

	var hand_canvas: Node = hand_host.find_child("HandCanvas", true, false)
	if hand_canvas == null or not hand_canvas.has_method("get_layout_bounds"):
		failures.append("本家手牌画布缺少布局边界，无法对齐真实碰杠牌")
		return
	var hand_bounds: Rect2 = hand_canvas.call("get_layout_bounds")
	var hand_global := Rect2(hand_host.get_global_rect().position + hand_bounds.position, hand_bounds.size)
	var meld_lane: Control = self_ui.find_child("MeldLane", true, false) as Control
	if meld_lane == null:
		failures.append("本家碰杠宿主缺少 MeldLane")
		return
	var meld_tiles: Array[Control] = []
	_collect_tile_visual_controls(meld_lane, meld_tiles)
	if meld_tiles.is_empty():
		failures.append("本家有碰杠数据时 MeldLane 必须渲染真实麻将牌")
		return
	var meld_bounds := _controls_global_bounds(meld_tiles)
	if absf(meld_bounds.position.y - hand_global.position.y) > 2.0:
		failures.append("本家真实碰杠牌顶线必须与手牌顶线一致，当前偏差 %.1f" % (meld_bounds.position.y - hand_global.position.y))
	if absf(meld_bounds.size.y - hand_global.size.y) > 2.5:
		failures.append("本家真实碰杠牌高度必须与手牌高度一致，当前碰杠 %.1f / 手牌 %.1f" % [meld_bounds.size.y, hand_global.size.y])
	_assert_no_horizontal_tile_overlap(meld_tiles, "本家碰杠牌", failures)
	var hand_host_rect := hand_host.get_global_rect()
	if meld_bounds.position.x - hand_host_rect.position.x > 42.0:
		failures.append("本家碰杠牌应从底部托盘左侧开始排，当前左侧空出 %.1f" % (meld_bounds.position.x - hand_host_rect.position.x))
	var self_rect := self_info.get_global_rect()
	var visual_overhang_tolerance := 28.0
	if (
		meld_bounds.position.x < self_rect.position.x - visual_overhang_tolerance
		or meld_bounds.end.x > self_rect.end.x + visual_overhang_tolerance
		or meld_bounds.position.y < self_rect.position.y - 1.0
		or meld_bounds.end.y > self_rect.end.y + 1.0
	):
		failures.append("本家碰杠牌被宿主裁切，牌范围 x %.1f-%.1f y %.1f-%.1f / 宿主 x %.1f-%.1f y %.1f-%.1f" % [
			meld_bounds.position.x,
			meld_bounds.end.x,
			meld_bounds.position.y,
			meld_bounds.end.y,
			self_rect.position.x,
			self_rect.end.x,
			self_rect.position.y,
			self_rect.end.y,
		])
	var hu_host: Control = _find_control(root_node, "SelfHuTileHost")
	if hu_host == null:
		failures.append("缺少本家胡牌宿主 SelfHuTileHost")
		return
	var hu_tiles: Array[Control] = []
	_collect_tile_visual_controls(hu_host, hu_tiles)
	if hu_tiles.is_empty():
		failures.append("本家已胡时必须在底部右侧渲染胡张牌")
		return
	var hu_bounds := _controls_global_bounds(hu_tiles)
	if absf(hu_bounds.position.y - hand_global.position.y) > 2.0:
		failures.append("本家胡张顶线必须与手牌顶线一致，当前偏差 %.1f" % (hu_bounds.position.y - hand_global.position.y))
	if absf(hu_bounds.size.y - hand_global.size.y) > 2.5:
		failures.append("本家胡张高度必须与手牌高度一致，当前胡张 %.1f / 手牌 %.1f" % [hu_bounds.size.y, hand_global.size.y])


func _find_player_ui_in_host(host: Control) -> Control:
	if host.has_method("apply_snapshot"):
		return host
	for child in host.get_children():
		if child is Control and child.has_method("apply_snapshot"):
			return child as Control
	return null


func _check_self_embedded_row_contract(root_node: Node, failures: Array[String]) -> void:
	var hand_host: Control = _find_control(root_node, "SelfHandHost")
	if hand_host == null:
		failures.append("缺少本家手牌横排")
		return
	var embedded_layer: Control = hand_host.find_child("EmbeddedLayer", true, false) as Control
	if embedded_layer == null:
		failures.append("本家手牌横排缺少嵌入层 EmbeddedLayer")
		return
	var left_probe := Control.new()
	left_probe.name = "LayoutContractLeftEmbed"
	var right_probe := Control.new()
	right_probe.name = "LayoutContractRightEmbed"
	hand_host.call("embed_left_host", left_probe, 320.0, 16.0)
	hand_host.call("embed_right_host", right_probe, 110.0, 12.0)
	hand_host.call("configure_hand", _fake_tiles(10), -1, -1, false, {}, {})
	var layer_rect := embedded_layer.get_global_rect()
	var left_rect := left_probe.get_global_rect()
	var right_rect := right_probe.get_global_rect()
	if left_rect.position.x < layer_rect.position.x - 1.0 or left_rect.position.y < layer_rect.position.y - 1.0:
		failures.append("本家碰杠嵌入区不应使用负偏移越出底部横排")
	if right_rect.end.x > layer_rect.end.x + 1.0 or right_rect.position.y < layer_rect.position.y - 1.0:
		failures.append("本家胡牌嵌入区必须完整落在底部横排内")
	if left_rect.size.y > 210.0:
		failures.append("本家碰杠嵌入区高度过大，会形成左下角独立大面板")
	if right_rect.size.y > 210.0:
		failures.append("本家胡牌嵌入区高度过大，应与手牌同一基线")
	var hand_canvas: Node = hand_host.find_child("HandCanvas", true, false)
	if hand_canvas == null or not hand_canvas.has_method("get_layout_bounds"):
		failures.append("本家手牌画布必须暴露布局边界，保证碰杠+手牌+胡牌可以做连续 18 槽排布")
	else:
		var hand_bounds: Rect2 = hand_canvas.call("get_layout_bounds")
		var hand_global := Rect2(hand_host.get_global_rect().position + hand_bounds.position, hand_bounds.size)
		if absf(left_rect.position.y - hand_global.position.y) > 2.0:
			failures.append("本家碰杠区顶线必须与手牌顶线一致，当前偏差 %.1f" % (left_rect.position.y - hand_global.position.y))
		if absf(right_rect.position.y - hand_global.position.y) > 2.0:
			failures.append("本家胡牌区顶线必须与手牌顶线一致，当前偏差 %.1f" % (right_rect.position.y - hand_global.position.y))
		if absf(left_rect.size.y - hand_global.size.y) > 2.0:
			failures.append("本家碰杠区高度应先与手牌高度一致，当前碰杠 %.1f / 手牌 %.1f" % [left_rect.size.y, hand_global.size.y])
		if absf(right_rect.size.y - hand_global.size.y) > 2.0:
			failures.append("本家胡牌区高度应先与手牌高度一致，当前胡牌 %.1f / 手牌 %.1f" % [right_rect.size.y, hand_global.size.y])
		var left_gap := hand_global.position.x - left_rect.end.x
		var right_gap := right_rect.position.x - hand_global.end.x
		if left_gap < 6.0 or left_gap > 46.0:
			failures.append("本家碰杠区与手牌区间距应保持连续，当前间距 %.1f" % left_gap)
		if right_gap < 6.0 or right_gap > 46.0:
			failures.append("本家胡牌区应紧跟手牌右侧，当前间距 %.1f" % right_gap)
		var host_left := hand_host.get_global_rect().position.x
		if left_rect.position.x - host_left > 42.0:
			failures.append("本家碰杠区应从底部托盘左侧起排，当前左侧空出 %.1f" % (left_rect.position.x - host_left))
	hand_host.call("clear_left_host")
	hand_host.call("clear_right_host")


func _check_self_hand_fill_contract(root_node: Node, failures: Array[String]) -> void:
	var hand_host: Control = _find_control(root_node, "SelfHandHost")
	if hand_host == null:
		failures.append("缺少本家手牌横排，无法验证手牌填充")
		return
	var hand_canvas: Node = hand_host.find_child("HandCanvas", true, false)
	if hand_canvas == null or not hand_canvas.has_method("get_layout_bounds"):
		failures.append("本家手牌画布缺少布局边界，无法验证手牌大小")
		return
	hand_host.call("configure_hand", _fake_tiles(10), -1, -1, false, {}, {})
	var hand_bounds: Rect2 = hand_canvas.call("get_layout_bounds")
	if hand_bounds.size.y < 188.0:
		failures.append("本家手牌麻将仍偏小，当前高度 %.1f，应进一步放大填满底部托盘" % hand_bounds.size.y)
	var host_height := hand_host.size.y if hand_host.size.y > 1.0 else hand_host.custom_minimum_size.y
	var vertical_fill := hand_bounds.size.y / maxf(1.0, host_height)
	if vertical_fill < 0.86:
		failures.append("本家手牌纵向填充不足，当前 %.2f，应进一步铺满底部托盘" % vertical_fill)


func _check_self_winning_tile_not_duplicated(root_node: Node, failures: Array[String]) -> void:
	var hand_host: Control = _find_control(root_node, "SelfHandHost")
	if hand_host == null:
		failures.append("缺少本家手牌横排，无法验证胡张去重")
		return
	var snapshot := {
		"players": [
			{
				"seat": 0,
				"nickname": "本家",
				"score": 0,
				"hand_count": 5,
				"hand_tiles": [],
				"melds": [],
				"discards": [],
				"ding_que": "wan",
				"has_won": true,
				"win_type": "self_draw",
				"winning_tile": {"id": 9204, "suit": "tong", "rank": 4},
				"winning_source_seat": 0,
			},
		],
		"rules": {"use_ding_que_phase": true},
		"human_can_discard": false,
		"human_last_draw_tile_id": 9204,
	}
	var self_hand := [
		{"id": 9201, "suit": "tong", "rank": 1},
		{"id": 9202, "suit": "tong", "rank": 2},
		{"id": 9203, "suit": "tong", "rank": 3},
		{"id": 9204, "suit": "tong", "rank": 4},
	]
	root_node.call("_update_self_area", snapshot, self_hand)
	await process_frame
	await process_frame
	var hand_canvas: Node = hand_host.find_child("HandCanvas", true, false)
	if hand_canvas == null:
		failures.append("本家手牌画布缺失，无法验证胡张去重")
		return
	var layouts: Array = hand_canvas.get("tile_layouts")
	for item in layouts:
		if int(item.get("tile_id", -1)) == 9204:
			failures.append("本家已胡牌 9204 不应继续留在手牌画布中，避免和右侧胡张重复显示")
			return


func _check_frontend_design_layout_contract(root_node: Node, failures: Array[String]) -> void:
	var root_ui: Control = root_node.get_node_or_null("UILayer/RootUI") as Control
	var root_height := root_ui.size.y if root_ui != null else 1152.0
	var root_width := root_ui.size.x if root_ui != null else 2048.0
	var self_rect: Rect2 = root_node.call("_v17_self_dynamic_rect")
	if self_rect.size.y > root_height * 0.17:
		failures.append("本家底部统一横排过高，应收成手牌+碰杠+胡牌的一体托盘")
	var hu_rect: Rect2 = root_node.call("_v17_self_hu_rect")
	if hu_rect.size.x > root_width * 0.07 or hu_rect.size.y > root_height * 0.145:
		failures.append("本家胡牌嵌入槽过大，应只预留单张胡牌的完整牌位")

	for host_name in ["SelfInfoHost", "SelfHuTileHost"]:
		var host: Control = _find_control(root_node, host_name)
		if host == null:
			failures.append("缺少本家嵌入牌槽 %s" % host_name)
			continue
		var backplate := host.find_child("V17Backplate", true, false) as Control
		if backplate != null and backplate.visible:
			failures.append("%s 不应另画独立大背板，应融入底部统一托盘" % host_name)

	var left_host: Control = _find_control(root_node, "PlayerLeftHost")
	var right_host: Control = _find_control(root_node, "PlayerRightHost")
	if left_host != null:
		var left_info_rect: Rect2 = root_node.call("_v17_player_info_rect", 1)
		if _rects_overlap(left_host.get_global_rect().grow(-6.0), left_info_rect):
			failures.append("上家玩家信息栏不应遮挡上家手牌/碰杠/胡牌道")
	if right_host != null:
		var right_info_rect: Rect2 = root_node.call("_v17_player_info_rect", 3)
		if _rects_overlap(right_host.get_global_rect().grow(-6.0), right_info_rect):
			failures.append("下家玩家信息栏不应遮挡下家手牌/碰杠/胡牌道")


func _check_self_status_badge_contract(root_node: Node, failures: Array[String]) -> void:
	var self_score: Control = _find_control(root_node, "SelfScoreLabel")
	var self_info: Control = _find_control(root_node, "SelfInfoBar")
	var won_stamp: Control = _find_control(root_node, "SelfWonStamp")
	if self_score == null or self_info == null or won_stamp == null:
		failures.append("缺少本家积分牌或已胡标记，无法验证左下角状态牌")
		return
	var snapshot := {
		"players": [
			{"seat": 0, "nickname": "本家", "score": 10, "has_won": true},
			{"seat": 1, "nickname": "上家", "score": 0},
			{"seat": 2, "nickname": "对家", "score": 0},
			{"seat": 3, "nickname": "下家", "score": 0},
		],
		"current_dealer_seat": 0,
		"rules": {"use_ding_que_phase": true},
	}
	root_node.call("_update_self_area", snapshot, [])
	var expected_self_rect: Rect2 = root_node.call("_v17_player_info_rect", 0)
	var self_info_rect := self_info.get_global_rect()
	var self_score_rect := self_score.get_global_rect()
	if self_info_rect.size.x < 280.0 or self_info_rect.size.y < 124.0:
		failures.append("我的信息框应和其他家信息框同一量级，当前 %.1fx%.1f" % [self_info_rect.size.x, self_info_rect.size.y])
	if self_info_rect.position.y < 808.0:
		failures.append("我的姓名/积分框应整体下移，避免遮挡上家手牌/碰杠牌，当前 y %.1f" % self_info_rect.position.y)
	if self_score_rect.size.x < expected_self_rect.size.x - 10.0 or self_score_rect.size.y < expected_self_rect.size.y - 10.0:
		failures.append("我的积分牌应填满我的信息框，当前 %.1fx%.1f / 预期 %.1fx%.1f" % [self_score_rect.size.x, self_score_rect.size.y, expected_self_rect.size.x, expected_self_rect.size.y])
	if absf(won_stamp.rotation_degrees) > 0.1:
		failures.append("本家已胡标记不应再使用斜盖大印章，避免左下角状态牌杂乱")
	if not _rect_contains_rect(self_score.get_global_rect().grow(4.0), won_stamp.get_global_rect()):
		failures.append("本家已胡标记应收进积分牌内部，不能伸出状态牌边界")
	var dealer_badge: Control = self_score.find_child("SelfDealerBadge", true, false) as Control
	if dealer_badge != null and dealer_badge.visible:
		if not _rect_contains_rect(self_score.get_global_rect().grow(4.0), dealer_badge.get_global_rect()):
			failures.append("本家庄家标记应收进积分牌内部，不能挂在边框外")


func _check_side_hu_slot_contract(failures: Array[String]) -> void:
	var left_ui := PLAYER_UI_SCENE.instantiate()
	left_ui.set("seat_dock", 2)
	get_root().add_child(left_ui)
	var right_ui := PLAYER_UI_SCENE.instantiate()
	right_ui.set("seat_dock", 3)
	get_root().add_child(right_ui)
	await process_frame
	var sample_player := {
		"seat": 3,
		"name": "下家",
		"score": 0,
		"hand_count": 13,
		"hand_tiles": [],
		"melds": [
			{
				"type": "peng",
				"from_seat": 1,
				"tiles": [
					{"id": 401, "suit": "tong", "rank": 3},
					{"id": 402, "suit": "tong", "rank": 3},
					{"id": 403, "suit": "tong", "rank": 3},
				],
			},
		],
		"has_won": true,
		"win_type": "discard_win",
		"winning_tile": {"id": 301, "suit": "tong", "rank": 8},
		"winning_source_seat": 1,
	}
	right_ui.call("apply_snapshot", sample_player, true, -1, -1, true)
	var hu_slot: Control = right_ui.find_child("SideHuSlot", true, false) as Control
	var hand_column: Control = right_ui.find_child("SideHandColumn", true, false) as Control
	var meld_column: Control = right_ui.find_child("SideMeldColumn", true, false) as Control
	if hu_slot == null:
		failures.append("侧家胡牌槽应命名为 SideHuSlot 并独立预留完整牌位")
	elif hu_slot.size.x < 170.0 or hu_slot.size.y < 112.0:
		failures.append("侧家胡牌槽应按碰杠牌尺寸重新计算，当前 %.1fx%.1f" % [hu_slot.size.x, hu_slot.size.y])
	if hand_column == null:
		failures.append("侧家手牌列应命名为 SideHandColumn，胡牌必须并入这条牌道")
	if meld_column == null:
		failures.append("侧家碰杠区应命名为 SideMeldColumn，便于约束内容高度")
	elif meld_column.visible and meld_column.size.y < 630.0:
		failures.append("侧家碰杠区外框应拉到牌道上下两端，当前高 %.1f" % meld_column.size.y)
	if hu_slot != null and hand_column != null and hu_slot.visible:
		if hu_slot.get_rect().end.x < hand_column.get_rect().end.x - 1.0:
			failures.append("下家胡牌槽应朝外侧桌边扩展并包住胡牌，当前右边 %.1f / 手牌列右边 %.1f" % [hu_slot.get_rect().end.x, hand_column.get_rect().end.x])
		if hu_slot.position.y < hand_column.get_rect().end.y - 1.0 and hu_slot.get_rect().end.y > hand_column.position.y + 1.0:
			failures.append("侧家胡牌槽不能覆盖手牌列，应排在手牌列末端")
		var hu_backplate := hu_slot.find_child("SlotPlate", true, false) as Control
		if hu_backplate != null and hu_backplate.visible:
			failures.append("侧家胡牌槽不要单独画杂色背景，应与手牌区背景一致")

	sample_player["melds"] = []
	right_ui.call("apply_snapshot", sample_player, true, -1, -1, true)
	hu_slot = right_ui.find_child("SideHuSlot", true, false) as Control
	hand_column = right_ui.find_child("SideHandColumn", true, false) as Control
	if hu_slot != null and hand_column != null and hu_slot.visible:
		if hu_slot.get_rect().end.x < hand_column.get_rect().end.x - 1.0:
			failures.append("侧家无碰杠时，胡牌槽也应朝外侧桌边保留完整牌位")

	var left_player := sample_player.duplicate(true)
	left_player["seat"] = 1
	left_player["name"] = "上家"
	left_player["melds"] = [
		{
			"type": "peng",
			"from_seat": 3,
			"tiles": [
				{"id": 501, "suit": "tiao", "rank": 6},
				{"id": 502, "suit": "tiao", "rank": 6},
				{"id": 503, "suit": "tiao", "rank": 6},
			],
		},
	]
	left_ui.call("apply_snapshot", left_player, true, -1, -1, true)
	var left_hu_slot: Control = left_ui.find_child("SideHuSlot", true, false) as Control
	var left_hand_column: Control = left_ui.find_child("SideHandColumn", true, false) as Control
	if left_hu_slot != null and left_hand_column != null and left_hu_slot.visible:
		if left_hu_slot.size.x < 170.0 or left_hu_slot.size.y < 112.0:
			failures.append("上家胡牌槽应按碰杠牌尺寸重新计算，当前 %.1fx%.1f" % [left_hu_slot.size.x, left_hu_slot.size.y])
		if left_hu_slot.position.x > left_hand_column.position.x + 1.0:
			failures.append("上家胡牌槽应朝外侧桌边扩展，当前左边 %.1f / 手牌列左边 %.1f" % [left_hu_slot.position.x, left_hand_column.position.x])
		if left_hu_slot.position.y < left_hand_column.get_rect().end.y - 1.0 and left_hu_slot.get_rect().end.y > left_hand_column.position.y + 1.0:
			failures.append("上家胡牌槽不能覆盖手牌列，应排在手牌列末端")
	left_ui.queue_free()
	right_ui.queue_free()


func _check_opponent_tile_size_contract(failures: Array[String]) -> void:
	var top_ui := PLAYER_UI_SCENE.instantiate()
	top_ui.set("seat_dock", 1)
	get_root().add_child(top_ui)
	var left_ui := PLAYER_UI_SCENE.instantiate()
	left_ui.set("seat_dock", 2)
	get_root().add_child(left_ui)
	var right_ui := PLAYER_UI_SCENE.instantiate()
	right_ui.set("seat_dock", 3)
	get_root().add_child(right_ui)
	await process_frame
	var sample_melds := [
		{
			"type": "peng",
			"from_seat": 0,
			"tiles": [
				{"id": 4101, "suit": "tong", "rank": 2},
				{"id": 4102, "suit": "tong", "rank": 2},
				{"id": 4103, "suit": "tong", "rank": 2},
			],
		},
	]
	var top_player := {
		"seat": 2,
		"nickname": "对家",
		"score": 0,
		"hand_count": 11,
		"hand_tiles": _fake_tiles(11),
		"melds": sample_melds,
	}
	var side_player := {
		"seat": 1,
		"nickname": "侧家",
		"score": 0,
		"hand_count": 13,
		"hand_tiles": _fake_tiles(13),
		"melds": sample_melds,
	}
	top_ui.call("apply_snapshot", top_player, true, -1, -1, true)
	left_ui.call("apply_snapshot", side_player, true, -1, -1, true)
	right_ui.call("apply_snapshot", side_player, true, -1, -1, true)
	await process_frame
	await process_frame
	var top_row := top_ui.find_child("HorizontalRowRoot", true, false) as Control
	if top_row == null:
		failures.append("对家碰杠+手牌+胡牌区缺少横向承载框")
	elif top_row.size.y < 172.0:
		failures.append("对家碰杠+手牌+胡牌承载框应向下扩展到红框大小，当前高 %.1f" % top_row.size.y)
	elif top_row.size.x < 1400.0:
		failures.append("对家碰杠+手牌+胡牌承载框应向右拉长靠近姓名区，当前宽 %.1f" % top_row.size.x)
	_assert_tile_visual_min(top_ui.find_child("TopHandSlot", true, false), 128.0, "对家手牌", failures)
	_assert_tile_visual_min(top_ui.find_child("TopMeldSlot", true, false), 128.0, "对家碰杠牌", failures)
	_assert_tile_visual_min(left_ui.find_child("SideHandColumn", true, false), 112.0, "上家手牌", failures)
	_assert_tile_visual_min(left_ui.find_child("SideMeldColumn", true, false), 160.0, "上家碰杠牌", failures)
	_assert_tile_visual_min(right_ui.find_child("SideHandColumn", true, false), 112.0, "下家手牌", failures)
	_assert_tile_visual_min(right_ui.find_child("SideMeldColumn", true, false), 160.0, "下家碰杠牌", failures)
	_assert_side_lane_symmetry(left_ui, right_ui, failures)
	_assert_side_meld_column_fill(left_ui.find_child("SideMeldColumn", true, false), "上家碰杠区", failures)
	_assert_side_meld_column_fill(right_ui.find_child("SideMeldColumn", true, false), "下家碰杠区", failures)
	top_ui.queue_free()
	left_ui.queue_free()
	right_ui.queue_free()


func _assert_side_lane_symmetry(left_ui: Control, right_ui: Control, failures: Array[String]) -> void:
	var left_hand := left_ui.find_child("SideHandColumn", true, false) as Control
	var right_hand := right_ui.find_child("SideHandColumn", true, false) as Control
	var left_meld := left_ui.find_child("SideMeldColumn", true, false) as Control
	var right_meld := right_ui.find_child("SideMeldColumn", true, false) as Control
	if left_hand == null or right_hand == null or left_meld == null or right_meld == null:
		failures.append("上家/下家缺少手牌或碰杠列，无法验证左右同规格")
		return
	if absf(left_hand.size.x - right_hand.size.x) > 1.0 or absf(left_hand.size.y - right_hand.size.y) > 1.0:
		failures.append("下家手牌列应与上家同规格，当前上家 %.1fx%.1f / 下家 %.1fx%.1f" % [left_hand.size.x, left_hand.size.y, right_hand.size.x, right_hand.size.y])
	if absf(left_meld.size.x - right_meld.size.x) > 1.0 or absf(left_meld.size.y - right_meld.size.y) > 1.0:
		failures.append("下家碰杠列应与上家同规格，当前上家 %.1fx%.1f / 下家 %.1fx%.1f" % [left_meld.size.x, left_meld.size.y, right_meld.size.x, right_meld.size.y])
	if right_hand.get_rect().intersects(right_meld.get_rect(), true):
		failures.append("下家手牌列不应与碰杠列互相遮挡")
	if left_hand.get_rect().intersects(left_meld.get_rect(), true):
		failures.append("上家手牌列不应与碰杠列互相遮挡")


func _assert_tile_visual_min(root: Node, min_long_side: float, label: String, failures: Array[String]) -> void:
	if root == null:
		failures.append("%s 缺少渲染槽，无法验证牌尺寸" % label)
		return
	var tiles: Array[Control] = []
	_collect_tile_visual_controls(root, tiles)
	if tiles.is_empty():
		failures.append("%s 必须渲染可见麻将牌" % label)
		return
	var largest := 0.0
	for tile in tiles:
		largest = maxf(largest, maxf(tile.custom_minimum_size.x, tile.custom_minimum_size.y))
	if largest < min_long_side:
		failures.append("%s 偏小，最长边 %.1f / 目标至少 %.1f" % [label, largest, min_long_side])


func _assert_side_meld_column_fill(root: Node, label: String, failures: Array[String]) -> void:
	if root == null:
		failures.append("%s 缺少渲染槽，无法验证填充" % label)
		return
	var tiles: Array[Control] = []
	_collect_tile_visual_controls(root, tiles)
	if tiles.is_empty():
		failures.append("%s 必须渲染可见麻将牌" % label)
		return
	var used := _controls_global_bounds(tiles)
	var rect := (root as Control).get_global_rect()
	if rect.size.y < 630.0:
		failures.append("%s 外框应至少拉到牌道上下两端，当前槽高 %.1f" % [label, rect.size.y])
	var first_group := _first_side_meld_group_rect(root as Control)
	if first_group.size != Vector2.ZERO and first_group.position.y - rect.position.y > 18.0:
		failures.append("%s 顶部留白过大，当前 %.1f" % [label, first_group.position.y - rect.position.y])


func _first_side_meld_group_rect(root: Control) -> Rect2:
	for child in root.get_children():
		if child is VBoxContainer:
			var content_box := child as VBoxContainer
			for group in content_box.get_children():
				if group is Control:
					return (group as Control).get_global_rect()
	return Rect2()


func _assert_no_horizontal_tile_overlap(tiles: Array[Control], label: String, failures: Array[String]) -> void:
	if tiles.size() <= 1:
		return
	var sorted_tiles := tiles.duplicate()
	sorted_tiles.sort_custom(func(a: Control, b: Control) -> bool:
		return a.get_global_rect().position.x < b.get_global_rect().position.x
	)
	for index in range(sorted_tiles.size() - 1):
		var current := (sorted_tiles[index] as Control).get_global_rect()
		var next := (sorted_tiles[index + 1] as Control).get_global_rect()
		var vertical_overlap := current.position.y < next.end.y - 2.0 and next.position.y < current.end.y - 2.0
		if vertical_overlap and next.position.x < current.end.x - 2.0:
			failures.append("%s相邻麻将仍有遮挡，当前重叠 %.1fpx" % [label, current.end.x - next.position.x])
			return


func _fake_tiles(count: int) -> Array:
	var tiles: Array = []
	for index in range(count):
		tiles.append({
			"id": 9000 + index,
			"suit": "tiao",
			"rank": index % 9 + 1,
		})
	return tiles


func _children_local_bounds(children: Array) -> Rect2:
	if children.is_empty():
		return Rect2()
	var first := children[0] as Control
	var bounds := Rect2(first.position, first.size)
	for index in range(1, children.size()):
		var child := children[index] as Control
		bounds = bounds.merge(Rect2(child.position, child.size))
	return bounds


func _children_local_bounds_with_visual_size(children: Array, visual_size: Vector2) -> Rect2:
	if children.is_empty():
		return Rect2()
	var first := children[0] as Control
	var bounds := Rect2(first.position, visual_size)
	for index in range(1, children.size()):
		var child := children[index] as Control
		bounds = bounds.merge(Rect2(child.position, visual_size))
	return bounds


func _collect_tile_visual_controls(node: Node, result: Array[Control]) -> void:
	for child in node.get_children():
		if child is TileVisual2D:
			result.append(child as Control)
		_collect_tile_visual_controls(child, result)


func _controls_global_bounds(controls: Array[Control]) -> Rect2:
	if controls.is_empty():
		return Rect2()
	var bounds := controls[0].get_global_rect()
	for index in range(1, controls.size()):
		bounds = bounds.merge(controls[index].get_global_rect())
	return bounds


func _check_cross_plate_separation(root_node: Node, failures: Array[String]) -> void:
	var top_plate: Control = root_node.get("board_cross_top_plate") as Control
	var bottom_plate: Control = root_node.get("board_cross_bottom_plate") as Control
	var left_plate: Control = root_node.get("board_cross_left_plate") as Control
	var right_plate: Control = root_node.get("board_cross_right_plate") as Control
	if top_plate == null or bottom_plate == null or left_plate == null or right_plate == null:
		failures.append("缺少中心牌桌十字分区面板")
		return
	var top_rect := top_plate.get_global_rect()
	var bottom_rect := bottom_plate.get_global_rect()
	var left_rect := left_plate.get_global_rect()
	var right_rect := right_plate.get_global_rect()
	var top_overlap := maxf(top_rect.end.y - left_rect.position.y, top_rect.end.y - right_rect.position.y)
	var bottom_overlap := maxf(left_rect.end.y - bottom_rect.position.y, right_rect.end.y - bottom_rect.position.y)
	if top_overlap > 56.0:
		failures.append("顶部弃牌面板不应过度压到左右弃牌面板，当前重叠 %.1f" % top_overlap)
	if bottom_overlap > 56.0:
		failures.append("底部弃牌面板不应过度压到左右弃牌面板，当前重叠 %.1f" % bottom_overlap)


func _rects_overlap(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b, true)


func _rect_contains_rect(container: Rect2, child: Rect2) -> bool:
	return (
		child.position.x >= container.position.x
		and child.position.y >= container.position.y
		and child.end.x <= container.end.x
		and child.end.y <= container.end.y
	)
