extends SceneTree

const SCENE_PATH := "res://scenes/table/MainSceneV2.tscn"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		push_error("Unable to load %s" % SCENE_PATH)
		quit(1)
		return
	var main_scene := scene.instantiate()
	get_root().add_child(main_scene)
	await process_frame
	await process_frame
	var game_state := get_root().get_node_or_null("GameState")
	if game_state != null and bool(game_state.get("opening_roll_pending_completion")):
		game_state.call("complete_opening_roll")
	await process_frame
	await process_frame
	await process_frame
	if OS.get_cmdline_user_args().has("--show-actions"):
		var action_bar := main_scene.get("table_3d_action_bar") as NeijiangActionBar
		if action_bar != null:
			action_bar.render([
				{"id": "hu", "label": "胡"},
				{"id": "gang", "label": "补杠"},
				{"id": "an_gang", "label": "报杠"},
				{"id": "peng", "label": "碰"},
				{"id": "bao_jiao", "label": "报叫/报杠"},
				{"id": "pass", "label": "过"},
			], "内江操作")
			main_scene.call("_queue_neijiang_3d_layout")
			await process_frame
	if OS.get_cmdline_user_args().has("--expand-utilities"):
		var utility_bar := main_scene.get("table_3d_utility_bar") as NeijiangUtilityBar
		if utility_bar != null:
			utility_bar.set_collapsed(false)
			main_scene.call("_queue_neijiang_3d_layout")
			await process_frame
			await process_frame
	if OS.get_cmdline_user_args().has("--click-utilities"):
		var utility_bar := main_scene.get("table_3d_utility_bar") as NeijiangUtilityBar
		if utility_bar != null and utility_bar.toggle_button != null:
			var canvas_click_position := utility_bar.toggle_button.get_global_rect().get_center()
			var click_position := canvas_click_position * Vector2(get_root().size) / Vector2(
				ProjectSettings.get_setting("display/window/size/viewport_width", get_root().size.x),
				ProjectSettings.get_setting("display/window/size/viewport_height", get_root().size.y)
			)
			var press := InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = true
			press.position = click_position
			press.global_position = click_position
			Input.parse_input_event(press)
			await process_frame
			var release := InputEventMouseButton.new()
			release.button_index = MOUSE_BUTTON_LEFT
			release.pressed = false
			release.position = click_position
			release.global_position = click_position
			Input.parse_input_event(release)
			await process_frame
			await process_frame
			print("UTILITY_CLICK_COLLAPSED=%s" % utility_bar.is_collapsed())
			if utility_bar.is_collapsed():
				push_error("实际坐标第一次点击未能展开工具抽屉")
				quit(1)
				return
			if OS.get_cmdline_user_args().has("--click-utilities-twice"):
				await create_timer(0.20).timeout
				var second_press := InputEventMouseButton.new()
				second_press.button_index = MOUSE_BUTTON_LEFT
				second_press.pressed = true
				second_press.position = click_position
				second_press.global_position = click_position
				Input.parse_input_event(second_press)
				await process_frame
				var second_release := InputEventMouseButton.new()
				second_release.button_index = MOUSE_BUTTON_LEFT
				second_release.pressed = false
				second_release.position = click_position
				second_release.global_position = click_position
				Input.parse_input_event(second_release)
				await process_frame
				await process_frame
				print("UTILITY_SECOND_CLICK_COLLAPSED=%s" % utility_bar.is_collapsed())
				if not utility_bar.is_collapsed():
					push_error("实际坐标第二次点击未能收起工具抽屉")
					quit(1)
					return
	if not _validate_mobile_ui_contract(main_scene):
		quit(1)
		return
	var image := get_root().get_texture().get_image()
	if image == null:
		push_error("Viewport capture is unavailable")
		quit(1)
		return
	var output := "res://evidence/neijiang_3d_ui_port_20260813/live_table.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-output="):
			output = argument.trim_prefix("--capture-output=")
	var absolute_path := ProjectSettings.globalize_path(output)
	var result := image.save_png(absolute_path)
	if result != OK:
		push_error("Unable to save %s" % absolute_path)
		quit(1)
		return
	print(absolute_path)
	quit(0)


func _validate_mobile_ui_contract(main_scene: Node) -> bool:
	var stage := main_scene.get("table_stage_3d") as Node
	var seat_huds := main_scene.get("table_3d_seat_huds") as Dictionary
	if stage == null or not stage.has_method("get_seat_play_screen_rect"):
		push_error("多比例截图缺少 3D 牌桌投影数据")
		return false
	var stage_contract := stage.call("get_visual_contract") as Dictionary
	if not Array(stage_contract.get("center_direction_labels", ["unexpected"])).is_empty():
		push_error("中心面板不应包含东南西北文字")
		return false
	if str(stage_contract.get("camera_aspect_policy", "")) != "keep_width_mobile_full_bleed":
		push_error("摄像机必须保留手机满屏桌面合同")
		return false
	if str(stage_contract.get("center_display_shape", "")) != "raised_four_plate_deep_jade_body_with_single_gold_ring" \
			or str(stage_contract.get("center_active_color_hex", "")) != "F4C430" \
			or str(stage_contract.get("center_inactive_color_hex", "")) != "3A644D":
		push_error("中心区域未保持深绿立体板、黄色活动区与单金环设计")
		return false
	if stage.find_child("CounterSingleGoldRing", true, false) == null \
			or stage.find_child("CounterNumberPlate", true, false) == null:
		push_error("中心区域缺少 Blender 单一金色圆环或数字底板")
		return false
	if stage.find_child("CounterIvoryRing", true, false) != null \
			or stage.find_child("CounterInnerGoldLip", true, false) != null:
		push_error("中心区域错误保留了多层实体圆环")
		return false
	if int(stage_contract.get("mobile_directional_shadow_size", 0)) < 4096 \
			or int(stage_contract.get("mobile_soft_shadow_filter_quality", -1)) < 2:
		push_error("移动端上下家阴影未启用 4096 阴影图和中等软过滤")
		return false
	for seat in range(4):
		var seat_hud := seat_huds.get(seat) as NeijiangSeatHUD
		if seat_hud == null:
			push_error("缺少座位 %d 名牌" % seat)
			return false
		var tile_rects: Array = stage.call("get_seat_play_screen_rects", seat) \
			if stage.has_method("get_seat_play_screen_rects") else [stage.call("get_seat_play_screen_rect", seat)]
		for tile_rect_value in tile_rects:
			if seat_hud.get_global_rect().intersects(tile_rect_value as Rect2):
				push_error("屏幕比例回归失败：座位 %d 名牌遮挡麻将牌" % seat)
				return false
		var hud_contract := seat_hud.get_visual_contract()
		if str(hud_contract.get("name_font_path", "")) != "res://res/fonts/nameplate_calligraphy.ttf":
			push_error("座位 %d 姓名字体未显式打包" % seat)
			return false
		if str(hud_contract.get("body_font_path", "")) != "res://res/fonts/app_cjk.ttc":
			push_error("座位 %d 正文字体未显式打包" % seat)
			return false
		var play_rect := stage.call("get_seat_play_screen_rect", seat) as Rect2
		if play_rect.size.x > 1.0:
			var hud_center := seat_hud.get_global_rect().get_center()
			var play_center := play_rect.get_center()
			if seat in [0, 1] and hud_center.x >= play_center.x:
				push_error("座位 %d 名牌未停靠在牌区左外侧" % seat)
				return false
			if seat in [2, 3] and hud_center.x <= play_center.x:
				push_error("座位 %d 名牌未停靠在牌区右外侧" % seat)
				return false
	var viewport_size := Vector2(get_root().size)
	var self_rect := (seat_huds.get(0) as Control).get_global_rect()
	var left_rect := (seat_huds.get(1) as Control).get_global_rect()
	var right_rect := (seat_huds.get(3) as Control).get_global_rect()
	var self_play_rect := stage.call("get_seat_play_screen_rect", 0) as Rect2
	var self_clear_left_or_above := self_play_rect.size.y <= 1.0 \
		or self_rect.end.x <= self_play_rect.position.x - 4.0 \
		or self_rect.end.y <= self_play_rect.position.y - 4.0
	if self_rect.position.x > viewport_size.x * 0.04 or not self_clear_left_or_above:
		push_error("本家名牌未固定在手牌左上方，仍存在遮牌风险 hud=%s play=%s viewport=%s" % [self_rect, self_play_rect, viewport_size])
		return false
	if left_rect.position.x > viewport_size.x * 0.04 or left_rect.position.y > viewport_size.y * 0.22:
		push_error("左家名牌未按图2固定在左上外沿")
		return false
	if right_rect.end.x < viewport_size.x * 0.96 or right_rect.position.y > viewport_size.y * 0.22:
		push_error("右家名牌未按图2固定在右上外沿")
		return false
	print("MOBILE_UI_CONTRACT_OK viewport=%s" % get_root().size)
	return true
