extends SceneTree

const GAME_STATE_SCRIPT := preload("res://autoload/GameState.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_run_test("startup_defaults_to_desktop_debug_hell_training_on", _test_startup_defaults_to_desktop_debug_hell_training_on, failures)
	_run_test("hell_challenge_mode_executes_oracle_without_recording", _test_hell_challenge_mode_executes_oracle_without_recording, failures)
	_run_test("hell_challenge_oracle_replaces_deal_in_discard", _test_hell_challenge_oracle_replaces_deal_in_discard, failures)
	_run_test("hell_challenge_async_decision_applies_oracle", _test_hell_challenge_async_decision_applies_oracle, failures)
	_run_test("desktop_debug_records_training_event", _test_desktop_debug_records_training_event, failures)
	_run_test("debug_decision_trace_appends_complete_events", _test_debug_decision_trace_appends_complete_events, failures)
	_run_test("neijiang_uses_two_suits_without_ding_que", _test_neijiang_uses_two_suits_without_ding_que, failures)
	_run_test("neijiang_initial_deal_uses_72_tiles", _test_neijiang_initial_deal_uses_72_tiles, failures)
	_run_test("opening_dealer_self_hu_without_last_draw_is_available", _test_opening_dealer_self_hu_without_last_draw_is_available, failures)
	_run_test("ai_async_decisions_reject_changed_hand_signature", _test_ai_async_decisions_reject_changed_hand_signature, failures)
	_run_test("ai_bao_jiao_discard_rejects_non_last_draw", _test_ai_bao_jiao_discard_rejects_non_last_draw, failures)
	_run_test("ai_bao_jiao_unreported_fourth_9tong_discards_last_draw", _test_ai_bao_jiao_unreported_fourth_9tong_discards_last_draw, failures)
	_run_test("ai_bao_jiao_unreported_fourth_same_type_discards_last_draw", _test_ai_bao_jiao_unreported_fourth_same_type_discards_last_draw, failures)
	_run_test("ai_bao_jiao_reported_fourth_8tiao_gangs_not_discards", _test_ai_bao_jiao_reported_fourth_8tiao_gangs_not_discards, failures)
	_run_test("ai_bao_jiao_signature_tracks_last_draw", _test_ai_bao_jiao_signature_tracks_last_draw, failures)
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


func _test_startup_defaults_to_desktop_debug_hell_training_on():
	var game_state = _build_game_state()
	var snapshot: Dictionary = game_state.get_debug_snapshot()
	var config: Dictionary = snapshot.get("ai_tuning_config", {})
	if str(config.get("preset_name", "")) != "hell":
		return "expected startup preset hell, got %s" % [config]
	if int(snapshot.get("ai_level_index", -1)) != int(GAME_STATE_SCRIPT.AILevel.CHEATING):
		return "expected startup ai level cheating in hell mode, got %s" % [snapshot.get("ai_level_index", -1)]
	if not bool(config.get("diagnostics_recording_enabled", false)):
		return "expected desktop debug diagnostics recording enabled for hell training, got %s" % [config]
	if bool(config.get("auto_learning_enabled", true)):
		return "expected auto learning recording disabled for user release, got %s" % [config]
	if not bool(config.get("hell_ai_can_see_wall", false)):
		return "expected hell challenge to see wall, got %s" % [config]
	if not bool(config.get("hell_ai_can_see_human_hand", false)):
		return "expected hell challenge to see human hand, got %s" % [config]
	if not bool(config.get("hell_execute_oracle_action", false)):
		return "expected hell challenge to execute oracle action, got %s" % [config]
	var hell: Dictionary = snapshot.get("hell_training", {})
	if not bool(hell.get("enabled", false)):
		return "expected hell diagnostics enabled for desktop debug training, got %s" % [hell]
	if not bool(hell.get("challenge_enabled", false)):
		return "expected hell challenge to be enabled independent of diagnostics, got %s" % [hell]
	var output_dirs: Dictionary = hell.get("output_dirs", {})
	if not str(output_dirs.get("training", "")).begins_with("res://测试数据统计/hell_training"):
		return "expected project hell_training output dir, got %s" % [output_dirs]
	var recording: Dictionary = snapshot.get("ai_analysis_recording", {})
	if not bool(recording.get("enabled", false)):
		return "expected ai analysis recording enabled for desktop debug, got %s" % [recording]
	var export_result: Dictionary = game_state.export_diagnostic_package(false)
	if not bool(export_result.get("ok", false)):
		return "expected diagnostic export available in desktop debug training, got %s" % [export_result]
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


func _test_desktop_debug_records_training_event():
	var game_state = _build_game_state()
	game_state._record_ai_analysis_event("training_probe", {
		"turn_diagnostic": {
			"selected": {"tile_type": 4, "tile_name": "5条"},
			"diagnostic_flags": ["probe"],
		},
	})
	var recording: Dictionary = game_state.get_debug_snapshot().get("ai_analysis_recording", {})
	if int(recording.get("event_count", 0)) <= 0:
		return "expected desktop debug to record training events, got %s" % [recording]
	if str(recording.get("session_id", "")).is_empty():
		return "expected training session id in desktop debug, got %s" % [recording]
	var events_path := str(recording.get("events_path", ""))
	if events_path.is_empty() or not FileAccess.file_exists(events_path):
		return "expected ai analysis events file, got %s" % [recording]
	var export_result: Dictionary = game_state.export_diagnostic_package(false)
	if not bool(export_result.get("ok", false)):
		return "expected desktop debug diagnostic export enabled, got %s" % [export_result]
	return true


func _test_debug_decision_trace_appends_complete_events():
	var game_state = _build_game_state()
	if not bool(game_state._is_debug_decision_trace_enabled()):
		return "expected debug decision trace enabled in debug run"
	var initial_trace: Dictionary = game_state.get_debug_snapshot().get("debug_decision_trace", {})
	if bool(initial_trace.get("enabled", false)) != true:
		return "expected debug snapshot to expose enabled trace, got %s" % [initial_trace]
	game_state._record_ai_decision_trace_event("turn_analysis_ready", {
		"seat": 1,
		"decision": {
			"action": "discard",
			"analysis": {
				"action_scores": {"discard:7": 116, "gang:7": 208},
				"reasons": ["probe turn"],
			},
		},
		"player_state": {"seat": 1, "isBaoJiao": false},
		"table_state": {"wallCount": 13},
	})
	game_state._record_ai_decision_trace_event("reaction_analysis_ready", {
		"seat": 1,
		"decision": {
			"decision": {
				"action": "gang",
				"action_scores": {"pass": 24, "peng": 212, "gang": 406},
				"reasons": ["明杠收益明确"],
			},
		},
		"candidate": {"can_gang": true, "tile": _make_tile(808, "tiao", 8)},
	})
	var trace: Dictionary = game_state.get_debug_snapshot().get("debug_decision_trace", {})
	if int(trace.get("event_count", 0)) != 2:
		return "expected two trace events, got %s" % [trace]
	var path := str(trace.get("events_path", ""))
	if path.is_empty():
		return "expected events path in trace snapshot, got %s" % [trace]
	var raw := FileAccess.get_file_as_string(path)
	var lines := raw.split("\n", false)
	if lines.size() != 2:
		return "expected two jsonl lines, got %d raw=%s" % [lines.size(), raw]
	var first = JSON.parse_string(lines[0])
	var second = JSON.parse_string(lines[1])
	if not (first is Dictionary) or not (second is Dictionary):
		return "expected json objects in trace file, got %s / %s" % [first, second]
	if str(first.get("event_type", "")) != "turn_analysis_ready":
		return "expected first event type turn_analysis_ready, got %s" % [first]
	if str(second.get("event_type", "")) != "reaction_analysis_ready":
		return "expected second event type reaction_analysis_ready, got %s" % [second]
	if int(second.get("event_index", 0)) != 2:
		return "expected append event index 2, got %s" % [second]
	if not Dictionary(second.get("payload", {})).has("decision"):
		return "expected decision payload preserved, got %s" % [second]
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


func _test_ai_bao_jiao_discard_rejects_non_last_draw():
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
	if ok:
		return "expected illegal bao-jiao discard to be rejected instead of frontend-forced"
	if not _hand_contains_tile_id(game_state.players[1].get("hand_tiles", []), int(locked_tile.get("id"))):
		return "expected locked bao-jiao tile to remain in hand"
	if not _hand_contains_tile_id(game_state.players[1].get("hand_tiles", []), int(drawn_tile.get("id"))):
		return "expected drawn tile to remain because frontend must not substitute C# decision"
	if not game_state.discard_pile.is_empty():
		return "expected no discard after rejecting illegal C# decision, got %s" % [game_state.discard_pile]
	if str(game_state.debug_last_message).find("C#") == -1:
		return "expected debug message to identify C# contract failure, got %s" % game_state.debug_last_message
	return true


func _test_ai_bao_jiao_unreported_fourth_9tong_discards_last_draw():
	var tong_9_tiles := [
		_make_tile(601, "tong", 9),
		_make_tile(602, "tong", 9),
		_make_tile(603, "tong", 9),
		_make_tile(604, "tong", 9),
	]
	return _assert_bao_jiao_unreported_fourth_tile_discards_last_draw(
		"真实规则复盘：未报 9筒杠，摸第 4 张 9筒",
		tong_9_tiles,
		"tong_9",
		17
	)


func _test_ai_bao_jiao_unreported_fourth_same_type_discards_last_draw():
	var tiao_7_tiles := [
		_make_tile(701, "tiao", 7),
		_make_tile(702, "tiao", 7),
		_make_tile(703, "tiao", 7),
		_make_tile(704, "tiao", 7),
	]
	return _assert_bao_jiao_unreported_fourth_tile_discards_last_draw(
		"同类型回归：未报 7条杠，摸第 4 张 7条",
		tiao_7_tiles,
		"tiao_7",
		6
	)


func _test_ai_bao_jiao_reported_fourth_8tiao_gangs_not_discards():
	var tiao_8_tiles := [
		_make_tile(801, "tiao", 8),
		_make_tile(802, "tiao", 8),
		_make_tile(803, "tiao", 8),
		_make_tile(804, "tiao", 8),
	]
	var game_state = _build_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_dealer_seat = 0
	game_state.current_turn_seat = 2
	game_state.wall_count = 13
	var last_draw_tile: Dictionary = tiao_8_tiles[3].duplicate(true)
	game_state.players.clear()
	game_state.players.append_array([
		_make_player(0, []),
		_make_player(1, []),
		_make_player(2, [
			_make_tile(821, "tiao", 1),
			_make_tile(822, "tiao", 2),
			_make_tile(823, "tiao", 4),
			_make_tile(824, "tiao", 5),
			_make_tile(825, "tong", 1),
			_make_tile(826, "tong", 3),
			_make_tile(827, "tong", 4),
			_make_tile(828, "tong", 6),
			_make_tile(829, "tong", 8),
			_make_tile(830, "tong", 9),
			tiao_8_tiles[0],
			tiao_8_tiles[1],
			tiao_8_tiles[2],
			last_draw_tile,
		]),
		_make_player(3, []),
	])
	game_state.players[2]["bao_jiao"] = true
	game_state.players[2]["bao_gang_tiles"] = ["tiao_8"]
	game_state.players[2]["bao_jiao_ting_tiles"] = [_make_tile(831, "tong", 2)]
	game_state.players[2]["rule_marks"] = ["报叫"]
	game_state.last_draw_tile = {"seat": 2, "tile": last_draw_tile.duplicate(true)}
	game_state.last_turn_context = {"seat": 2, "draw_reason": "normal_draw"}
	var decision: Dictionary = game_state._build_ai_turn_decision()
	if str(decision.get("action", "")) != "an_gang":
		return "expected reported 8条 fourth draw to build an_gang decision, got %s debug=%s" % [decision, game_state.debug_last_message]
	var ok: bool = game_state._execute_ai_turn_decision(decision)
	if not ok:
		return "expected an_gang execution to succeed, debug=%s decision=%s" % [game_state.debug_last_message, decision]
	if game_state.players[2]["melds"].is_empty():
		return "expected gang meld after reported 8条 draw, got none"
	var meld: Dictionary = game_state.players[2]["melds"][-1]
	if str(meld.get("gang_subtype", "")) != "an_gang":
		return "expected an_gang meld, got %s" % [meld]
	if not game_state.discard_pile.is_empty():
		return "expected no discard pile entry for reported 8条 gang, got %s" % [game_state.discard_pile]
	return true


func _assert_bao_jiao_unreported_fourth_tile_discards_last_draw(case_name: String, four_same_tiles: Array, forbidden_bao_gang_key: String, expected_tile_type: int):
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
	if not an_options.is_empty():
		return "%s expected no an-gang options when %s is not in bao_gang_tiles, got %s" % [case_name, forbidden_bao_gang_key, an_options]
	var mandatory_types: Array = game_state._mandatory_gang_tile_types_for_seat(1, an_options, game_state._find_all_add_gang_options(1))
	if mandatory_types.has(expected_tile_type):
		return "%s expected unreported tile type %d not to be mandatory gang, got %s" % [case_name, expected_tile_type, mandatory_types]
	var self_action: Dictionary = game_state._build_ai_self_action_decision(1, game_state._build_player_state(1), game_state._build_table_state())
	if not self_action.is_empty():
		return "%s expected no C# self gang action for unreported fourth tile, got %s" % [case_name, self_action]
	var decision: Dictionary = game_state._build_ai_turn_decision()
	if str(decision.get("action", "")) != "discard":
		return "%s expected discard decision, got %s" % [case_name, decision]
	if int(decision.get("tile_id", -1)) != int(last_draw_tile.get("id", -1)):
		return "%s expected decision to discard last draw id %d, got %s" % [case_name, int(last_draw_tile.get("id", -1)), decision]
	var ok: bool = game_state._execute_ai_turn_decision(decision)
	if not ok:
		return "%s expected AI discard execution to succeed, debug=%s decision=%s" % [case_name, game_state.debug_last_message, decision]
	if not game_state.players[1]["melds"].is_empty():
		return "%s expected no gang meld after execution, got %s" % [case_name, game_state.players[1]["melds"]]
	if game_state.discard_pile.is_empty():
		return "%s expected discard pile to contain last draw" % case_name
	var discarded: Dictionary = game_state.discard_pile[-1].get("tile", {})
	if int(discarded.get("id", -1)) != int(last_draw_tile.get("id", -1)):
		return "%s expected discarded tile id %d, got %s" % [case_name, int(last_draw_tile.get("id", -1)), discarded]
	return true


func _test_ai_bao_jiao_signature_tracks_last_draw():
	var game_state = _build_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_dealer_seat = 0
	game_state.current_turn_seat = 1
	game_state.wall_count = 13
	var first_draw := _make_tile(501, "tong", 5)
	var second_draw := _make_tile(502, "tong", 6)
	game_state.players.clear()
	game_state.players.append_array([
		_make_player(0, []),
		_make_player(1, [
			_make_tile(503, "tiao", 2),
			_make_tile(504, "tiao", 2),
			_make_tile(505, "tiao", 3),
			_make_tile(506, "tiao", 4),
			_make_tile(507, "tiao", 5),
			_make_tile(508, "tiao", 6),
			_make_tile(509, "tiao", 7),
			_make_tile(510, "tiao", 8),
			_make_tile(511, "tong", 3),
			_make_tile(512, "tong", 4),
			_make_tile(513, "tong", 5),
			_make_tile(514, "tong", 5),
			_make_tile(515, "tong", 7),
			first_draw,
		]),
		_make_player(2, []),
		_make_player(3, []),
	])
	game_state.players[1]["bao_jiao"] = true
	game_state.players[1]["bao_jiao_ting_tiles"] = [_make_tile(516, "tong", 2)]
	game_state.players[1]["rule_marks"] = ["报叫"]
	game_state.last_draw_tile = {"seat": 1, "tile": first_draw.duplicate(true)}
	var first_signature: String = game_state._ai_turn_state_signature(1)
	game_state.players[1]["hand_tiles"][13] = second_draw
	game_state.last_draw_tile = {"seat": 1, "tile": second_draw.duplicate(true)}
	var second_signature: String = game_state._ai_turn_state_signature(1)
	if first_signature == second_signature:
		return "expected bao-jiao AI turn signature to change when last_draw_tile changes"
	if first_signature.find("draw=1:501:13") == -1:
		return "expected first signature to include first draw identity, got %s" % first_signature
	if second_signature.find("draw=1:502:14") == -1:
		return "expected second signature to include second draw identity, got %s" % second_signature
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
