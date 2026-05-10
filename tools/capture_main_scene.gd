extends SceneTree

const OUTPUT_PATH := "user://capture_main_scene.png"
const SCENE_PATH := "res://scenes/table/MainSceneV2.tscn"
const AUTO_DING_QUE_SUIT := "tong"
const MAX_AI_STEPS := 24
const DEMO_DISCARDS := {
	0: [["tiao", 1], ["tiao", 3], ["tiao", 5], ["tong", 2], ["tong", 4], ["tong", 6], ["wan", 2], ["wan", 4], ["wan", 6], ["wan", 8]],
	1: [["wan", 1], ["wan", 2], ["wan", 3], ["tong", 5], ["tong", 6], ["tong", 7], ["tiao", 6], ["tiao", 7]],
	2: [["tong", 1], ["tong", 2], ["tong", 3], ["wan", 4], ["wan", 5], ["wan", 6], ["tiao", 7], ["tiao", 8], ["tiao", 9]],
	3: [["tiao", 2], ["tiao", 4], ["tiao", 6], ["tong", 7], ["tong", 8], ["tong", 9], ["wan", 7], ["wan", 9]],
}


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: PackedScene = load(SCENE_PATH) as PackedScene
	if scene == null:
		push_error("Failed to load scene: %s" % SCENE_PATH)
		quit(1)
		return

	var root_node: Node = scene.instantiate()
	get_root().add_child(root_node)

	await process_frame
	_force_playable_snapshot()
	_force_discard_demo()
	_log_self_hand_debug(root_node)

	await process_frame
	await process_frame
	_force_ai_helper_preview(root_node)
	_force_self_hand_preview(root_node)

	var image: Image = get_root().get_texture().get_image()
	if image == null:
		push_error("Failed to capture viewport image")
		quit(1)
		return

	var path := ProjectSettings.globalize_path(OUTPUT_PATH)
	var err := image.save_png(path)
	if err != OK:
		push_error("Failed to save capture: %s" % path)
		quit(1)
		return

	print(path)
	quit()


func _force_playable_snapshot() -> void:
	var game_state: Node = get_root().get_node_or_null("GameState")
	if game_state == null:
		return

	var players: Array = game_state.get("players")
	if players.is_empty():
		return

	for index in range(players.size()):
		var player: Dictionary = players[index]
		if str(player.get("ding_que", "")) == "":
			if index == 0:
				player["ding_que"] = AUTO_DING_QUE_SUIT
			else:
				player["ding_que"] = str(game_state.call("_choose_ai_ding_que", player.get("hand_tiles", [])))
			players[index] = player
	game_state.set("players", players)
	if bool(game_state.get("opening_roll_pending_completion")):
		game_state.call("complete_opening_roll")
	else:
		game_state.call("_complete_ding_que_if_ready")

	var step_count := 0
	while step_count < MAX_AI_STEPS and not bool(game_state.call("can_human_discard", 0)):
		if bool(game_state.call("is_ai_reaction_pending")):
			game_state.call("run_ai_reaction")
		elif bool(game_state.call("is_ai_turn_ready")):
			game_state.call("run_ai_turn")
		else:
			break
		step_count += 1
		await process_frame


func _log_self_hand_debug(root_node: Node) -> void:
	var hand_host := root_node.get_node_or_null("UILayer/RootUI/SafeArea/MainVBox/TableRow/CenterColumn/SelfSection/SelfSectionMargin/SelfSectionVBox/SelfHandHost")
	if hand_host is Control:
		var control := hand_host as Control
		print("SelfHandHost size=", control.size, " position=", control.global_position)


func _force_discard_demo() -> void:
	var game_state: Node = get_root().get_node_or_null("GameState")
	if game_state == null:
		return

	var players: Array = game_state.get("players")
	var wall: Array = game_state.get("wall")
	var discard_pile: Array = []

	for seat in range(players.size()):
		var player: Dictionary = players[seat]
		player["discards"] = []
		var requests: Array = DEMO_DISCARDS.get(seat, [])
		for request in requests:
			var tile := _take_tile_from_wall(wall, str(request[0]), int(request[1]))
			if tile.is_empty():
				continue
			player["discards"].append(tile)
			discard_pile.append(
				{
					"seat": seat,
					"tile": tile,
				}
			)
		players[seat] = player

	game_state.set("players", players)
	game_state.set("wall", wall)
	game_state.set("discard_pile", discard_pile)
	game_state.set("wall_count", wall.size())
	game_state.call("_emit_state_changed")


func _force_ai_helper_preview(root_node: Node) -> void:
	if root_node == null:
		return
	root_node.set("ai_helper_enabled", true)
	root_node.call("_update_discard_helper_panel", {
		"players": [
			{
				"seat": 0,
				"nickname": "本家",
				"score": 0,
				"hand_tiles": [
					{"id": 9001, "suit": "tiao", "rank": 1},
					{"id": 9002, "suit": "tiao", "rank": 2},
					{"id": 9003, "suit": "tiao", "rank": 3},
					{"id": 9004, "suit": "tong", "rank": 5},
					{"id": 9005, "suit": "wan", "rank": 7},
					{"id": 9006, "suit": "wan", "rank": 8},
				],
			},
		],
	}, {
		"recommended": {
			"tile": {"id": 9009, "suit": "tiao", "rank": 9},
			"tile_name": "9条",
			"shanten": 1,
			"ukeire": 8,
			"win_probability": 0.24,
			"risk_label": "低危",
			"score": 120,
			"explanation_hint": "边九孤张，先拆掉",
		},
		"recommended_tile_id": 9009,
		"options": [],
		"strategy_profile": {"mode_label": "快攻"},
		"situation_label": "缺门",
	}, true)


func _force_self_hand_preview(root_node: Node) -> void:
	if root_node == null:
		return
	var self_hand_host: Node = root_node.get("self_hand_host") as Node
	if self_hand_host == null:
		return
	self_hand_host.call(
		"configure_hand",
		[
			{"id": 9001, "suit": "tiao", "rank": 1},
			{"id": 9002, "suit": "tiao", "rank": 2},
			{"id": 9003, "suit": "tiao", "rank": 3},
			{"id": 9004, "suit": "tong", "rank": 5},
			{"id": 9005, "suit": "wan", "rank": 7},
			{"id": 9006, "suit": "wan", "rank": 8},
		],
		-1,
		-1,
		false,
		{"recommended_tile_id": 9002},
		{}
	)


func _take_tile_from_wall(wall: Array, suit: String, rank: int) -> Dictionary:
	for index in range(wall.size()):
		var tile: Dictionary = wall[index]
		if str(tile.get("suit", "")) == suit and int(tile.get("rank", 0)) == rank:
			wall.remove_at(index)
			return tile
	return {}
