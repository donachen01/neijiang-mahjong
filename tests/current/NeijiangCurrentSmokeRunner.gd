extends SceneTree

const GAME_STATE_SCRIPT := preload("res://autoload/GameState.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_run_test("startup_defaults_to_hell_ai_without_training_recording", _test_startup_defaults_to_hell_ai_without_training_recording, failures)
	_run_test("neijiang_uses_two_suits_without_ding_que", _test_neijiang_uses_two_suits_without_ding_que, failures)
	_run_test("neijiang_initial_deal_uses_72_tiles", _test_neijiang_initial_deal_uses_72_tiles, failures)
	_run_test("ai_async_decisions_reject_changed_hand_signature", _test_ai_async_decisions_reject_changed_hand_signature, failures)
	if failures.is_empty():
		print("NEIJIANG CURRENT SMOKE OK")
		quit(0)
	else:
		push_error("NEIJIANG CURRENT SMOKE FAILED:\n- " + "\n- ".join(failures))
		quit(1)


func _run_test(name: String, callable: Callable, failures: Array[String]) -> void:
	var result = callable.call()
	if result is bool and result:
		print("PASS ", name)
	else:
		failures.append("%s -> %s" % [name, str(result)])


func _test_neijiang_uses_two_suits_without_ding_que():
	var game_state = _build_game_state()
	if not game_state.rules.is_neijiang_mode():
		return "expected Neijiang mode"
	if game_state.rules.available_suits != ["tiao", "tong"]:
		return "expected only tiao/tong active suits, got %s" % [game_state.rules.available_suits]
	game_state.previous_dealer_seat = 0
	game_state.start_new_round(true)
	if not bool(game_state.complete_opening_roll()):
		return "expected opening roll to complete"
	if int(game_state.current_phase) != int(GAME_STATE_SCRIPT.RoundPhase.DISCARD):
		return "expected Neijiang to skip ding que and enter discard, got %s" % [game_state.current_phase]
	return true


func _test_startup_defaults_to_hell_ai_without_training_recording():
	var game_state = _build_game_state()
	var snapshot: Dictionary = game_state.get_debug_snapshot()
	var config: Dictionary = snapshot.get("ai_tuning_config", {})
	if str(config.get("preset_name", "")) != "hell":
		return "expected startup preset hell, got %s" % [config]
	if int(snapshot.get("ai_level_index", -1)) != int(GAME_STATE_SCRIPT.AILevel.CHEATING):
		return "expected startup ai level cheating in hell mode, got %s" % [snapshot.get("ai_level_index", -1)]
	var hell: Dictionary = snapshot.get("hell_training", {})
	if bool(hell.get("enabled", false)):
		return "expected hell diagnostics disabled at startup, got %s" % [hell]
	if not str(hell.get("session_id", "")).is_empty():
		return "expected no startup hell session id, got %s" % [hell]
	return true


func _test_neijiang_initial_deal_uses_72_tiles():
	var game_state = _build_game_state()
	game_state.previous_dealer_seat = 0
	game_state.start_new_round(true)
	if int(game_state.rules.total_tile_count) != 72:
		return "expected 72 total tiles, got %s" % [game_state.rules.total_tile_count]
	if not bool(game_state.complete_opening_roll()):
		return "expected opening roll to complete"
	if int(game_state.wall_count) != 19:
		return "expected wall count 19 after deal, got %s" % [game_state.wall_count]
	if not Array(game_state.get_human_ding_que_options(0)).is_empty():
		return "expected Neijiang to have no ding que options"
	for tile in game_state.wall:
		if str(tile.get("suit", "")) == "wan":
			return "expected Neijiang wall to contain no wan tiles"
	return true


func _test_ai_async_decisions_reject_changed_hand_signature():
	var game_state = _build_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	game_state.wall_count = 15
	game_state.players.clear()
	game_state.players.append_array([
		_make_player(0, []),
		_make_player(1, [
			_make_tile(101, "tiao", 1),
			_make_tile(102, "tiao", 2),
			_make_tile(103, "tiao", 3),
			_make_tile(104, "tiao", 4),
			_make_tile(105, "tiao", 4),
			_make_tile(106, "tiao", 4),
			_make_tile(107, "tiao", 6),
			_make_tile(108, "tiao", 7),
			_make_tile(109, "tiao", 8),
			_make_tile(110, "tong", 2),
			_make_tile(111, "tong", 3),
			_make_tile(112, "tong", 4),
			_make_tile(113, "tong", 8),
			_make_tile(114, "tong", 9),
		]),
		_make_player(2, []),
		_make_player(3, []),
	])
	var original_turn_signature := str(game_state._ai_turn_state_signature(1))
	game_state.pending_ai_turn_decision = {
		"round_index": game_state.round_index,
		"seat": 1,
		"phase": int(game_state.current_phase),
		"wall_count": game_state.wall_count,
		"hand_count": int(game_state.players[1].get("hand_count", 0)),
		"state_signature": original_turn_signature,
		"action": "discard",
		"tile_id": 104,
	}
	game_state.players[1]["hand_tiles"][0] = _make_tile(115, "tong", 1)
	if bool(game_state._is_pending_ai_turn_decision_valid()):
		return "expected stale turn decision to be invalid after same-count hand composition changed"

	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_discard_context = {
		"source_seat": 0,
		"tile": _make_tile(200, "tong", 5),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	game_state.pending_reactions.clear()
	game_state.pending_reactions.append({
		"seat": 1,
		"can_hu": false,
		"can_gang": false,
		"can_peng": true,
	})
	var original_reaction_signature := str(game_state._ai_reaction_state_signature(1))
	game_state.pending_ai_reaction_decision = {
		"round_index": game_state.round_index,
		"phase": int(game_state.current_phase),
		"source_seat": 0,
		"tile_id": 200,
		"pending_count": game_state.pending_reactions.size(),
		"seat": 1,
		"state_signature": original_reaction_signature,
		"candidate": game_state.pending_reactions[0].duplicate(true),
		"decision": {"action": "peng"},
	}
	game_state.players[1]["hand_tiles"][1] = _make_tile(116, "tong", 6)
	if bool(game_state._is_pending_ai_reaction_decision_valid()):
		return "expected stale reaction decision to be invalid after same-count hand composition changed"
	return true


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
