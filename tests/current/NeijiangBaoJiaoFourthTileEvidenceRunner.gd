extends SceneTree

const GAME_STATE_SCRIPT := preload("res://autoload/GameState.gd")
const OUTPUT_PATH := "res://测试数据统计/回归证据_20260520_未报杠摸第四张/case_replay_results.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cases: Array = [
		_build_case(
			"真实规则复盘：未报 9筒杠，摸第 4 张 9筒",
			[
				_make_tile(601, "tong", 9),
				_make_tile(602, "tong", 9),
				_make_tile(603, "tong", 9),
				_make_tile(604, "tong", 9),
			],
			"tong_9",
			17
		),
		_build_case(
			"同类型回归：未报 7条杠，摸第 4 张 7条",
			[
				_make_tile(701, "tiao", 7),
				_make_tile(702, "tiao", 7),
				_make_tile(703, "tiao", 7),
				_make_tile(704, "tiao", 7),
			],
			"tiao_7",
			6
		),
	]
	var output := {
		"schema": "bao_jiao_unreported_fourth_tile_replay_v1",
		"generated_at": Time.get_datetime_string_from_system(),
		"cases": cases,
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("failed to write evidence to %s" % OUTPUT_PATH)
		quit(1)
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()
	print("WROTE ", ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _build_case(case_name: String, four_same_tiles: Array, forbidden_bao_gang_key: String, expected_tile_type: int) -> Dictionary:
	var game_state = _build_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_dealer_seat = 0
	game_state.current_turn_seat = 1
	game_state.wall_count = 12
	var last_draw_tile: Dictionary = four_same_tiles[3].duplicate(true)
	game_state.players.clear()
	game_state.players.append_array([
		_make_player(0, []),
		_make_player(1, [
			_make_tile(621, "tiao", 1),
			_make_tile(622, "tiao", 2),
			_make_tile(623, "tiao", 4),
			_make_tile(624, "tiao", 5),
			_make_tile(625, "tiao", 8),
			_make_tile(626, "tong", 1),
			_make_tile(627, "tong", 3),
			_make_tile(628, "tong", 4),
			_make_tile(629, "tong", 6),
			_make_tile(630, "tong", 8),
			four_same_tiles[0],
			four_same_tiles[1],
			four_same_tiles[2],
			last_draw_tile,
		]),
		_make_player(2, []),
		_make_player(3, []),
	])
	game_state.players[1]["bao_jiao"] = true
	game_state.players[1]["bao_gang_tiles"] = []
	game_state.players[1]["bao_jiao_ting_tiles"] = [_make_tile(631, "tong", 2)]
	game_state.players[1]["rule_marks"] = ["报叫"]
	game_state.last_draw_tile = {"seat": 1, "tile": last_draw_tile.duplicate(true)}
	game_state.last_turn_context = {
		"seat": 1,
		"draw_reason": "normal_draw",
	}
	var an_options: Array = game_state._find_all_an_gang_options(1)
	var add_options: Array = game_state._find_all_add_gang_options(1)
	var mandatory_types: Array = game_state._mandatory_gang_tile_types_for_seat(1, an_options, add_options)
	var self_action: Dictionary = game_state._build_ai_self_action_decision(1, game_state._build_player_state(1), game_state._build_table_state())
	var decision: Dictionary = game_state._build_ai_turn_decision()
	var execution_ok := false
	if str(decision.get("action", "")) == "discard":
		execution_ok = game_state._execute_ai_turn_decision(decision)
	var discarded: Dictionary = {}
	if not game_state.discard_pile.is_empty():
		discarded = game_state.discard_pile[-1].get("tile", {})
	var passed: bool = an_options.is_empty() \
		and add_options.is_empty() \
		and not mandatory_types.has(expected_tile_type) \
		and self_action.is_empty() \
		and str(decision.get("action", "")) == "discard" \
		and int(decision.get("tile_id", -1)) == int(last_draw_tile.get("id", -1)) \
		and execution_ok \
		and game_state.players[1]["melds"].is_empty() \
		and int(discarded.get("id", -1)) == int(last_draw_tile.get("id", -1))
	return {
		"case_name": case_name,
		"input": {
			"seat": 1,
			"bao_jiao": true,
			"bao_gang_tiles": [],
			"forbidden_bao_gang_key": forbidden_bao_gang_key,
			"expected_tile_type": expected_tile_type,
			"hand_tiles_before": game_state.players[1]["hand_tiles"].duplicate(true),
			"last_draw_tile": last_draw_tile.duplicate(true),
		},
		"checks": {
			"an_gang_options": an_options,
			"add_gang_options": add_options,
			"mandatory_gang_tile_types": mandatory_types,
			"self_action_decision": self_action,
			"turn_decision": _summarize_turn_decision(decision),
			"execution_ok": execution_ok,
			"discarded_tile": discarded,
			"melds_after": game_state.players[1]["melds"].duplicate(true),
			"debug_last_message": game_state.debug_last_message,
		},
		"passed": passed,
	}


func _summarize_turn_decision(decision: Dictionary) -> Dictionary:
	var analysis: Dictionary = decision.get("analysis", {})
	var recommended: Dictionary = analysis.get("recommended", {})
	var hell_oracle: Dictionary = decision.get("hell_oracle", {})
	return {
		"action": decision.get("action", ""),
		"tile_id": int(decision.get("tile_id", -1)),
		"actual_action": decision.get("actual_action", {}),
		"recommended_tile": recommended.get("tile", {}),
		"recommended_csharp_tile_type": int(recommended.get("csharp_tile_type", -1)),
		"backend_mode": str(analysis.get("backend_mode", "")),
		"hell_oracle_category": str(hell_oracle.get("category", "")),
		"hell_oracle_reasons": hell_oracle.get("reasons", []),
	}


func _build_game_state():
	var game_state = GAME_STATE_SCRIPT.new()
	get_root().add_child(game_state)
	return game_state


func _make_player(seat: int, hand_tiles: Array) -> Dictionary:
	return {
		"seat": seat,
		"nickname": "Seat %d" % seat,
		"score": 0,
		"is_ai": seat != 0,
		"hand_tiles": hand_tiles.duplicate(true),
		"hand_count": hand_tiles.size(),
		"melds": [],
		"discards": [],
		"ding_que": "",
		"bao_jiao": false,
		"bao_gang_tiles": [],
		"opening_bao_jiao_reviewed": false,
		"bao_jiao_ting_tiles": [],
		"rule_marks": [],
		"has_won": false,
	}


func _make_tile(id: int, suit: String, rank: int) -> Dictionary:
	return {
		"id": id,
		"suit": suit,
		"rank": rank,
		"sort_key": (0 if suit == "tiao" else 100) + rank,
		"display_name": "%d%s" % [rank, "条" if suit == "tiao" else "筒"],
	}
