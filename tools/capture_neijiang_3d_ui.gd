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
