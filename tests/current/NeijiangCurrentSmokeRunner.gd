extends SceneTree

const GAME_STATE_SCRIPT := preload("res://autoload/GameState.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_run_test("startup_defaults_to_debug_training_release_safe", _test_startup_defaults_to_debug_training_release_safe, failures)
	_run_test("hell_challenge_mode_executes_oracle_without_recording", _test_hell_challenge_mode_executes_oracle_without_recording, failures)
	_run_test("hell_challenge_oracle_replaces_deal_in_discard", _test_hell_challenge_oracle_replaces_deal_in_discard, failures)
	_run_test("hell_challenge_async_decision_applies_oracle", _test_hell_challenge_async_decision_applies_oracle, failures)
	_run_test("debug_training_records_analysis_event", _test_debug_training_records_analysis_event, failures)
	_run_test("neijiang_uses_two_suits_without_ding_que", _test_neijiang_uses_two_suits_without_ding_que, failures)
	_run_test("neijiang_initial_deal_uses_72_tiles", _test_neijiang_initial_deal_uses_72_tiles, failures)
	_run_test("opening_dealer_self_hu_without_last_draw_is_available", _test_opening_dealer_self_hu_without_last_draw_is_available, failures)
	_run_test("ai_async_decisions_reject_changed_hand_signature", _test_ai_async_decisions_reject_changed_hand_signature, failures)
	_run_test("ai_bao_jiao_discard_forces_last_draw", _test_ai_bao_jiao_discard_forces_last_draw, failures)
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


func _test_startup_defaults_to_debug_training_release_safe():
	var game_state = _build_game_state()
	var snapshot: Dictionary = game_state.get_debug_snapshot()
	var config: Dictionary = snapshot.get("ai_tuning_config", {})
	if str(config.get("preset_name", "")) != "hell":
		return "expected startup preset hell, got %s" % [config]
	if int(snapshot.get("ai_level_index", -1)) != int(GAME_STATE_SCRIPT.AILevel.CHEATING):
		return "expected startup ai level cheating in hell mode, got %s" % [snapshot.get("ai_level_index", -1)]
	var expected_debug_recording := OS.is_debug_build()
	if bool(config.get("diagnostics_recording_enabled", false)) != expected_debug_recording:
		return "expected diagnostics recording to match debug build=%s, got %s" % [str(expected_debug_recording), config]
	if not bool(config.get("hell_ai_can_see_wall", false)):
		return "expected hell challenge to see wall, got %s" % [config]
	if not bool(config.get("hell_ai_can_see_human_hand", false)):
		return "expected hell challenge to see human hand, got %s" % [config]
	if not bool(config.get("hell_execute_oracle_action", false)):
		return "expected hell challenge to execute oracle action, got %s" % [config]
	var hell: Dictionary = snapshot.get("hell_training", {})
	if bool(hell.get("enabled", false)) != expected_debug_recording:
		return "expected hell diagnostics to match debug build=%s, got %s" % [str(expected_debug_recording), hell]
	if not bool(hell.get("challenge_enabled", false)):
		return "expected hell challenge to be enabled independent of diagnostics, got %s" % [hell]
	var recording: Dictionary = snapshot.get("ai_analysis_recording", {})
	if bool(recording.get("enabled", false)) != expected_debug_recording:
		return "expected ai analysis recording to match debug build=%s, got %s" % [str(expected_debug_recording), recording]
	return true


func _test_hell_challenge_mode_executes_oracle_without_recording():
	var game_state = _build_game_state()
	game_state.ai_tuning_config.set_diagnostics_recording_enabled(false)
	var snapshot: Dictionary = game_state.get_debug_snapshot()
	var hell: Dictionary = snapshot.get("hell_training", {})
	if bool(hell.get("enabled", true)):
		return "expected hell training recording disabled, got %s" % [hell]
	if not bool(hell.get("challenge_enabled", false)):
		return "expected hell challenge to stay enabled when recording is disabled, got %s" % [hell]
	var hidden: Dictionary = game_state._build_hell_hidden_state_snapshot()
	if not bool(hidden.get("human_hand_visible_to_ai", false)):
		return "expected challenge hidden state to include human hand permission, got %s" % [hidden]
	var exact_wall: Array = hidden.get("exact_wall18", [])
	var wall_total := 0
	for count in exact_wall:
		wall_total += int(count)
	if wall_total <= 0:
		return "expected challenge hidden state to expose exact wall, got %s" % [hidden]
	return true


func _test_hell_challenge_oracle_replaces_deal_in_discard():
	var fixture := _setup_hell_oracle_deal_in_fixture()
	var game_state = fixture["game_state"]
	var fair_tile: Dictionary = fixture["fair_tile"]
	var analysis: Dictionary = fixture["analysis"]
	var result: Dictionary = game_state._try_apply_hell_oracle_to_discard(
		1,
		game_state._build_player_state(1),
		game_state._build_table_state(),
		analysis,
		fair_tile
	)
	var oracle: Dictionary = result.get("oracle", {})
	if oracle.is_empty():
		return "expected challenge oracle result"
	if int(oracle.get("tileType", -1)) == 0:
		return "expected oracle to avoid fair deal-in tile, got %s" % [oracle]
	var selected: Dictionary = result.get("selected_tile", {})
	if int(selected.get("id", -1)) == int(fair_tile.get("id", -1)):
		return "expected challenge to replace selected deal-in discard, oracle=%s" % [oracle]
	if int(game_state._neijiang_tile_type(selected)) != int(oracle.get("tileType", -1)):
		return "expected selected tile to match oracle tile type, selected=%s oracle=%s" % [selected, oracle]
	if not bool(oracle.get("fairExactDealIn", false)):
		return "expected oracle to identify fair tile as exact deal-in, got %s" % [oracle]
	return true


func _test_hell_challenge_async_decision_applies_oracle():
	var fixture := _setup_hell_oracle_deal_in_fixture()
	var game_state = fixture["game_state"]
	var fair_tile: Dictionary = fixture["fair_tile"]
	var analysis: Dictionary = fixture["analysis"]
	var base_decision := {
		"round_index": game_state.round_index,
		"seat": 1,
		"phase": int(game_state.current_phase),
		"wall_count": game_state.wall_count,
		"hand_count": int(game_state.players[1].get("hand_count", 0)),
		"state_signature": game_state._ai_turn_state_signature(1),
		"action": "discard",
		"tile_id": int(fair_tile.get("id", -1)),
		"analysis": analysis.duplicate(true),
	}
	var result: Dictionary = game_state._apply_hell_oracle_to_discard_decision(
		base_decision,
		1,
		game_state._build_player_state(1),
		game_state._build_table_state(),
		analysis,
		fair_tile
	)
	var decision: Dictionary = result.get("decision", {})
	var oracle: Dictionary = decision.get("hell_oracle", {})
	if oracle.is_empty():
		return "expected async decision to carry hell oracle"
	if int(decision.get("tile_id", -1)) == int(fair_tile.get("id", -1)):
		return "expected async decision to replace fair tile, got %s" % [decision]
	if str(decision.get("actual_action", {}).get("source", "")) != "hell_oracle":
		return "expected async actual_action source hell_oracle, got %s" % [decision.get("actual_action", {})]
	if not bool(oracle.get("fairExactDealIn", false)):
		return "expected async oracle to flag fair exact deal-in, got %s" % [oracle]
	return true


func _test_debug_training_records_analysis_event():
	var game_state = _build_game_state()
	game_state._record_ai_analysis_event("training_probe", {
		"turn_diagnostic": {
			"selected": {"tile_type": 4, "tile_name": "5条"},
			"diagnostic_flags": ["probe"],
		},
	})
	var recording: Dictionary = game_state.get_debug_snapshot().get("ai_analysis_recording", {})
	if OS.is_debug_build():
		if int(recording.get("event_count", 0)) < 1:
			return "expected debug training event to be recorded, got %s" % [recording]
		if str(recording.get("session_id", "")).is_empty():
			return "expected debug training session id, got %s" % [recording]
		var export_result: Dictionary = game_state.export_diagnostic_package(false)
		if not bool(export_result.get("ok", false)):
			return "expected debug diagnostic export to succeed, got %s" % [export_result]
	else:
		if int(recording.get("event_count", 0)) != 0:
			return "expected release build to skip training events, got %s" % [recording]
		var release_export_result: Dictionary = game_state.export_diagnostic_package(false)
		if bool(release_export_result.get("ok", false)) or str(release_export_result.get("error", "")) != "diagnostic_export_disabled":
			return "expected release diagnostic export disabled, got %s" % [release_export_result]
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


func _test_opening_dealer_self_hu_without_last_draw_is_available():
	var game_state = _build_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	game_state.last_draw_tile = {}
	game_state.last_turn_context = {
		"seat": 0,
		"draw_reason": "opening_discard",
	}
	game_state.players.clear()
	for player in [
		_make_player(0, [
			_make_tile(801, "tiao", 1), _make_tile(802, "tiao", 1), _make_tile(803, "tiao", 1),
			_make_tile(804, "tiao", 2), _make_tile(805, "tiao", 3), _make_tile(806, "tiao", 4),
			_make_tile(807, "tiao", 5), _make_tile(808, "tiao", 6), _make_tile(809, "tiao", 7),
			_make_tile(810, "tong", 2), _make_tile(811, "tong", 3), _make_tile(812, "tong", 4),
			_make_tile(813, "tong", 9), _make_tile(814, "tong", 9),
		]),
		_make_player(1, []),
		_make_player(2, []),
		_make_player(3, []),
	]:
		game_state.players.append(player)
	if not bool(game_state.can_human_self_hu(0)):
		return "expected opening dealer 14-tile hu to be available without last_draw_tile"
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


func _test_ai_bao_jiao_discard_forces_last_draw():
	var game_state = _build_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_dealer_seat = 0
	game_state.current_turn_seat = 1
	game_state.wall_count = 7
	var locked_tile := _make_tile(301, "tiao", 8)
	var drawn_tile := _make_tile(399, "tong", 2)
	game_state.players.clear()
	game_state.players.append_array([
		_make_player(0, []),
		_make_player(1, [
			locked_tile,
			_make_tile(302, "tiao", 5),
			_make_tile(303, "tiao", 5),
			_make_tile(304, "tiao", 6),
			_make_tile(305, "tiao", 7),
			_make_tile(306, "tiao", 9),
			_make_tile(307, "tong", 3),
			_make_tile(308, "tong", 4),
			_make_tile(309, "tong", 5),
			_make_tile(310, "tong", 6),
			_make_tile(311, "tong", 7),
			_make_tile(312, "tong", 8),
			_make_tile(313, "tong", 9),
			drawn_tile,
		]),
		_make_player(2, []),
		_make_player(3, []),
	])
	game_state.players[1]["bao_jiao"] = true
	game_state.players[1]["bao_jiao_ting_tiles"] = [_make_tile(401, "tiao", 5)]
	game_state.players[1]["rule_marks"] = ["报叫"]
	game_state.last_draw_tile = {
		"seat": 1,
		"tile": drawn_tile.duplicate(true),
	}
	game_state.last_turn_context = {
		"seat": 1,
		"draw_reason": "normal_draw",
	}
	var ok: bool = game_state._execute_ai_turn_decision({
		"action": "discard",
		"seat": 1,
		"tile_id": int(locked_tile.get("id")),
		"hand_count": int(game_state.players[1].get("hand_count")),
	})
	if not ok:
		return "expected forced last-draw discard to execute, msg=%s" % game_state.debug_last_message
	if not _hand_contains_tile_id(game_state.players[1].get("hand_tiles", []), int(locked_tile.get("id"))):
		return "expected locked bao-jiao tile to remain in hand"
	if _hand_contains_tile_id(game_state.players[1].get("hand_tiles", []), int(drawn_tile.get("id"))):
		return "expected drawn tile to be discarded"
	if game_state.discard_pile.is_empty() or int(game_state.discard_pile[-1].get("tile", {}).get("id", -1)) != int(drawn_tile.get("id")):
		return "expected discard pile to contain forced drawn tile, got %s" % [game_state.discard_pile]
	return true


func _build_game_state():
	var game_state = GAME_STATE_SCRIPT.new()
	get_root().add_child(game_state)
	return game_state


func _setup_hell_oracle_deal_in_fixture() -> Dictionary:
	var game_state = _build_game_state()
	game_state.ai_tuning_config.set_diagnostics_recording_enabled(false)
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_dealer_seat = 0
	game_state.current_turn_seat = 1
	game_state.wall_count = 8
	var fair_tile := _make_tile(100, "tiao", 1)
	var oracle_expected_tile := _make_tile(117, "tong", 8)
	game_state.players.clear()
	game_state.players.append_array([
		_make_player(0, []),
		_make_player(1, _tiles_from_types([0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 17], 100)),
		_make_player(2, _tiles_from_types([1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 16], 200)),
		_make_player(3, []),
	])
	game_state.players[1]["hand_tiles"][0] = fair_tile.duplicate(true)
	game_state.players[1]["hand_tiles"][-1] = oracle_expected_tile.duplicate(true)
	game_state.players[1]["hand_count"] = game_state.players[1]["hand_tiles"].size()
	game_state.players[2]["hand_count"] = game_state.players[2]["hand_tiles"].size()
	game_state.wall.clear()
	game_state.wall.append_array(_tiles_from_types([17, 17, 17, 1, 2, 4, 9, 11], 300))
	return {
		"game_state": game_state,
		"fair_tile": fair_tile,
		"analysis": {
			"recommended": {
				"csharp_tile_type": 0,
				"tile": fair_tile.duplicate(true),
			},
		},
	}


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


func _hand_contains_tile_id(hand_tiles: Array, tile_id: int) -> bool:
	for tile in hand_tiles:
		if int(tile.get("id", -1)) == tile_id:
			return true
	return false


func _tiles_from_types(tile_types: Array, id_start: int) -> Array:
	var result: Array = []
	var index := 0
	for tile_type in tile_types:
		var type_value := int(tile_type)
		var suit := "tiao" if type_value < 9 else "tong"
		var rank := type_value + 1 if type_value < 9 else type_value - 8
		result.append(_make_tile(id_start + index, suit, rank))
		index += 1
	return result


func _make_tile(id: int, suit: String, rank: int) -> Dictionary:
	return {
		"id": id,
		"suit": suit,
		"rank": rank,
		"sort_key": (0 if suit == "tiao" else 100) + rank,
		"display_name": "%d%s" % [rank, "条" if suit == "tiao" else "筒"],
	}
