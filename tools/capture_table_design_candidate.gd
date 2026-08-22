extends SceneTree

## Captures a design-candidate table inside the real MainSceneV2 composition.
## This runner never mutates the shipping table asset or gameplay state.

const SCENE_PATH := "res://scenes/table/MainSceneV2.tscn"
const DEFAULT_SIZE := Vector2i(2560, 1440)


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := _arguments()
	var table_path := str(args.get("table", ""))
	var output_path := str(args.get("output", "res://evidence/neijiang_3d_ui_port_20260813/tabletop_redesign_20260815/candidate.png"))
	if table_path.is_empty():
		push_error("Missing --table-preview=res://...glb")
		quit(2)
		return
	get_root().size = DEFAULT_SIZE
	var packed_main := load(SCENE_PATH) as PackedScene
	if packed_main == null:
		push_error("Unable to load %s" % SCENE_PATH)
		quit(2)
		return
	var main_scene := packed_main.instantiate()
	get_root().add_child(main_scene)
	for _frame in range(8):
		await process_frame
	var game_state := get_root().get_node_or_null("GameState")
	if game_state != null and bool(game_state.get("opening_roll_pending_completion")):
		game_state.call("complete_opening_roll")
	for _frame in range(5):
		await process_frame
	var stage := main_scene.get("table_stage_3d") as Node3D
	if stage == null:
		push_error("Real 3D stage is unavailable")
		quit(2)
		return
	var current_table := stage.find_child("ManufacturedClubTable", true, false) as Node3D
	if current_table == null:
		push_error("Shipping table instance was not found")
		quit(2)
		return
	var table_parent := current_table.get_parent()
	var shipping_transform := current_table.transform
	current_table.name = "ShippingTablePendingRemoval"
	current_table.queue_free()
	await process_frame
	var packed_candidate := load(table_path) as PackedScene
	if packed_candidate == null:
		push_error("Unable to load design candidate %s" % table_path)
		quit(2)
		return
	var candidate := packed_candidate.instantiate() as Node3D
	if candidate == null:
		push_error("Design candidate root is not Node3D: %s" % table_path)
		quit(2)
		return
	candidate.name = "ManufacturedClubTable"
	table_parent.add_child(candidate)
	candidate.transform = shipping_transform
	if stage.has_method("_set_center_panel_state"):
		stage.call("_set_center_panel_state", 18, 0)
	for _frame in range(10):
		await process_frame
	var absolute_path := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var image := get_root().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Viewport capture is unavailable")
		quit(2)
		return
	var result := image.save_png(absolute_path)
	if result != OK:
		push_error("Unable to save %s" % absolute_path)
		quit(2)
		return
	print("REAL_SCENE_TABLE_PREVIEW=%s|%s|%s" % [table_path, absolute_path, image.get_size()])
	quit(0)


func _arguments() -> Dictionary:
	var parsed := {}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--table-preview="):
			parsed["table"] = argument.trim_prefix("--table-preview=")
		elif argument.begins_with("--capture-output="):
			parsed["output"] = argument.trim_prefix("--capture-output=")
	return parsed
