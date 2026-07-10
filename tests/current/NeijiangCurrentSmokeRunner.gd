extends SceneTree

const GAME_STATE_SCRIPT := preload("res://autoload/GameState.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_run_test("startup_defaults_to_desktop_debug_hell_training_on", _test_startup_defaults_to_desktop_debug_hell_training_on, failures)
	_run_test("legacy_ai_level_cheating_maps_to_hell_preset", _test_legacy_ai_level_cheating_maps_to_hell_preset, failures)
	_run_test("hell_challenge_mode_executes_oracle_without_recording", _test_hell_challenge_mode_executes_oracle_without_recording, failures)
	_run_test("hell_challenge_sync_delivery_counts_as_direct_analysis", _test_hell_challenge_sync_delivery_counts_as_direct_analysis, failures)
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
	_run_test("ai_helper_snapshot_builds_sync_without_debug_bloat", _test_ai_helper_snapshot_builds_sync_without_debug_bloat, failures)
	_run_test("opening_bao_jiao_queue_stops_at_human_after_ai_declares", _test_opening_bao_jiao_queue_stops_at_human_after_ai_declares, failures)
	_run_test("opening_bao_jiao_pass_resumes_dealer_first_discard", _test_opening_bao_jiao_pass_resumes_dealer_first_discard, failures)
	_run_test("opening_human_bao_jiao_declare_allows_ai_dealer_first_discard", _test_opening_human_bao_jiao_declare_allows_ai_dealer_first_discard, failures)
	_run_test("opening_human_bao_jiao_with_bao_gang_selection_allows_ai_dealer_first_discard", _test_opening_human_bao_jiao_with_bao_gang_selection_allows_ai_dealer_first_discard, failures)
	if failures.is_empty():
		print("NEIJIANG CURRENT SMOKE OK")
		quit(0)
	else:
		push_error("NEIJIANG CURRENT SMOKE FAILED:\n- " + "\n- ".join(failures))
		quit(1)


func _run_test(name: String, callable: Callable, failures: Array[String]) -> void:
	var before_children := get_root().get_child_count()
	var result = callable.call()
	if result is bool and result:
		print("PASS ", name)
	else:
		failures.append("%s -> %s" % [name, str(result)])
	for index in range(get_root().get_child_count() - 1, before_children - 1, -1):
		var child := get_root().get_child(index)
		if child != null:
			child.queue_free()


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


func _test_legacy_ai_level_cheating_maps_to_hell_preset():
	var game_state = _build_game_state()
	if not bool(game_state.set_ai_preset("bone_ash")):
		return "expected bone_ash preset to be available"
	var fair_config: Dictionary = game_state.get_debug_snapshot().get("ai_tuning_config", {})
	if str(fair_config.get("preset_name", "")) != "bone_ash":
		return "expected bone_ash preset before legacy switch, got %s" % [fair_config]
	if bool(fair_config.get("hell_execute_oracle_action", true)):
		return "expected bone_ash to keep hell oracle disabled, got %s" % [fair_config]
	if not bool(game_state.set_ai_level(GAME_STATE_SCRIPT.AILevel.CHEATING)):
		return "expected legacy cheating level switch to succeed"
	var hell_snapshot: Dictionary = game_state.get_debug_snapshot()
	var hell_config: Dictionary = hell_snapshot.get("ai_tuning_config", {})
	if str(hell_config.get("preset_name", "")) != "hell":
		return "expected legacy cheating level to map to hell preset, got %s" % [hell_config]
	if int(hell_snapshot.get("ai_level_index", -1)) != int(GAME_STATE_SCRIPT.AILevel.CHEATING):
		return "expected legacy cheating level to keep ai_level CHEATING, got %s" % [hell_snapshot.get("ai_level_index", -1)]
	if not bool(hell_config.get("hell_ai_can_see_human_hand", false)):
		return "expected legacy cheating level to expose human hand, got %s" % [hell_config]
	if not bool(hell_config.get("hell_ai_can_see_wall", false)):
		return "expected legacy cheating level to expose exact wall, got %s" % [hell_config]
	if not bool(hell_config.get("hell_execute_oracle_action", false)):
		return "expected legacy cheating level to execute oracle, got %s" % [hell_config]
	if not bool(game_state.set_ai_level(GAME_STATE_SCRIPT.AILevel.ADVANCED)):
		return "expected legacy advanced level switch to succeed"
	var advanced_snapshot: Dictionary = game_state.get_debug_snapshot()
	var advanced_config: Dictionary = advanced_snapshot.get("ai_tuning_config", {})
	if str(advanced_config.get("preset_name", "")) != "bone_ash":
		return "expected legacy advanced level to map back to bone_ash, got %s" % [advanced_config]
	if int(advanced_snapshot.get("ai_level_index", -1)) != int(GAME_STATE_SCRIPT.AILevel.ADVANCED):
		return "expected legacy advanced level to keep ai_level ADVANCED, got %s" % [advanced_snapshot.get("ai_level_index", -1)]
	if bool(advanced_config.get("hell_execute_oracle_action", true)):
		return "expected bone_ash mapping to disable hell oracle, got %s" % [advanced_config]
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


func _test_hell_challenge_sync_delivery_counts_as_direct_analysis():
	var game_state = _build_game_state()
	var backends := [
		"hell_challenge_direct",
		"hell_challenge_direct_async",
		"hell_challenge_direct_sync_delivery",
	]
	for backend in backends:
		if not bool(game_state._is_direct_hell_challenge_analysis({"backend_mode": backend})):
			return "expected backend %s to count as direct hell challenge" % backend
	if bool(game_state._is_direct_hell_challenge_analysis({"backend_mode": "hybrid_csharp"})):
		return "expected fair backend not to count as direct hell challenge"
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


func _test_ai_helper_snapshot_builds_sync_without_debug_bloat():
	var game_state = _build_game_state()
	game_state.ai_tuning_config.set_diagnostics_recording_enabled(false)
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	game_state.wall_count = 18
	game_state.players.clear()
	game_state.players.append_array([
		_make_player(0, [
			_make_tile(2810, "tiao", 2), _make_tile(2811, "tiao", 3), _make_tile(2812, "tiao", 4),
			_make_tile(2813, "tiao", 5), _make_tile(2814, "tiao", 6), _make_tile(2815, "tiao", 7),
			_make_tile(2816, "tong", 2), _make_tile(2817, "tong", 3), _make_tile(2818, "tong", 4),
			_make_tile(2819, "tong", 6), _make_tile(2820, "tong", 7), _make_tile(2821, "tong", 8),
			_make_tile(2822, "tong", 9), _make_tile(2823, "tong", 9),
		]),
		_make_player(1, []),
		_make_player(2, []),
		_make_player(3, []),
	])
	game_state.set_human_trainer_hint_enabled(true)
	if not bool(game_state.ai_manager.compact_runtime_snapshots):
		return "expected ai helper to keep compact runtime snapshots"
	var snapshot: Dictionary = game_state.get_debug_snapshot()
	var ai_core_debug: Dictionary = snapshot.get("ai_core_debug", {})
	if ai_core_debug.has("performance_metrics") or ai_core_debug.has("request_state") or ai_core_debug.has("active_async_requests"):
		return "expected ai helper snapshot to avoid full AI debug payload, got %s" % [ai_core_debug.keys()]
	var hint: Dictionary = snapshot.get("trainer_hint", {})
	if bool(hint.get("request_pending", false)):
		return "expected trainer hint snapshot to be built synchronously, got pending hint %s" % [hint]
	if int(hint.get("recommended_tile_id", -1)) < 0:
		return "expected synchronous trainer hint to include C# recommended tile, got %s" % [hint]
	if int(game_state.pending_trainer_hint_request_id) != 0:
		return "expected no pending trainer hint request after synchronous build"
	if int(game_state.pending_ai_turn_request_id) != 0:
		return "expected trainer hint request not to occupy AI turn execution slot"
	return true


func _test_opening_bao_jiao_queue_stops_at_human_after_ai_declares():
	var game_state = _build_game_state()
	game_state.ai_manager = FakeBaoJiaoManager.new()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_dealer_seat = 0
	game_state.current_turn_seat = 0
	game_state.wall_count = 18
	game_state.discard_pile.clear()
	var ready_hand := _opening_ready_hand()
	game_state.players.clear()
	game_state.players.append_array([
		_make_player(0, _tiles_from_types([0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 17], 1000)),
		_make_player(1, ready_hand),
		_make_player(2, ready_hand),
		_make_player(3, ready_hand),
	])
	game_state.players[1]["is_ai"] = true
	game_state.players[2]["is_ai"] = false
	game_state.players[3]["is_ai"] = true
	if not bool(game_state._start_opening_bao_jiao_window()):
		return "expected opening bao-jiao window to start"
	if not bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao-jiao window to remain pending for human"
	if int(game_state.opening_bao_jiao_current_seat) != 2:
		return "expected queue to stop at human seat 2 after AI seat 3 declares, got current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]
	if not bool(game_state.players[3].get("bao_jiao", false)):
		return "expected AI seat 3 to declare before human prompt"
	if bool(game_state.players[2].get("opening_bao_jiao_reviewed", false)) or bool(game_state.players[2].get("bao_jiao", false)):
		return "expected human seat 2 to stay unreviewed until player choice"
	if bool(game_state.players[1].get("opening_bao_jiao_reviewed", false)) or bool(game_state.players[1].get("bao_jiao", false)):
		return "expected later AI seat 1 not to run before human choice"
	if game_state.opening_bao_jiao_queue != [1]:
		return "expected later AI seat 1 to remain queued, got %s" % [game_state.opening_bao_jiao_queue]
	return true


func _test_opening_bao_jiao_pass_resumes_dealer_first_discard():
	var game_state = _build_game_state()
	game_state.ai_manager = FakeBaoJiaoManager.new()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_dealer_seat = 1
	game_state.current_turn_seat = 1
	game_state.wall_count = 18
	game_state.discard_pile.clear()
	var dealer_hand := _tiles_from_types([0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 17], 6000)
	var ready_hand := _opening_ready_hand()
	game_state.players.clear()
	game_state.players.append_array([
		_make_player(0, ready_hand),
		_make_player(1, dealer_hand),
		_make_player(2, ready_hand),
		_make_player(3, ready_hand),
	])
	game_state.players[0]["is_ai"] = false
	game_state.players[1]["is_ai"] = true
	game_state.players[2]["is_ai"] = true
	game_state.players[3]["is_ai"] = true
	if not bool(game_state._start_opening_bao_jiao_window()):
		return "expected opening bao-jiao window to start"
	if int(game_state.opening_bao_jiao_current_seat) != 0:
		return "expected window to stop at human seat 0, got %s queue=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
		]
	if not bool(game_state.pass_human_opening_bao_jiao(0)):
		return "expected human pass to be accepted, debug=%s" % game_state.debug_last_message
	if bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao-jiao window to finish after human pass and queued AI handling"
	if int(game_state.opening_bao_jiao_current_seat) != -1:
		return "expected no current opening bao-jiao seat after finish"
	if int(game_state.current_phase) != int(GAME_STATE_SCRIPT.RoundPhase.DISCARD):
		return "expected phase to return to discard for dealer first discard, got %s" % [game_state.current_phase]
	if int(game_state.current_turn_seat) != 1:
		return "expected dealer seat 1 to remain current turn, got %s" % [game_state.current_turn_seat]
	if not bool(game_state.players[2].get("bao_jiao", false)) or not bool(game_state.players[3].get("bao_jiao", false)):
		return "expected queued AI seats 2 and 3 to declare before dealer first discard"
	if not bool(game_state.players[0].get("opening_bao_jiao_reviewed", false)):
		return "expected human pass to mark opening review complete"
	if str(game_state.debug_last_message).find("庄家") == -1:
		return "expected dealer first discard message after window, got %s" % game_state.debug_last_message
	return true


func _test_opening_human_bao_jiao_declare_allows_ai_dealer_first_discard():
	var game_state = _build_game_state()
	game_state.previous_dealer_seat = 1
	game_state.start_new_round(true)
	game_state.wall.clear()
	game_state.wall.append_array(_wall_for_opening_hands([
		_opening_ready_hand(1000),
		_tiles_from_types([0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 17], 2000),
		_tiles_from_types([0, 2, 4, 6, 8, 9, 11, 13, 15, 17, 1, 10, 16], 3000),
		_tiles_from_types([1, 3, 5, 7, 9, 11, 13, 15, 17, 0, 8, 10, 12], 4000),
	], 5000))
	game_state.wall_count = game_state.wall.size()
	if not bool(game_state.complete_opening_roll()):
		return "expected opening roll to complete"
	var snapshot: Dictionary = game_state.get_debug_snapshot()
	if not bool(snapshot.get("opening_bao_jiao_pending", false)):
		return "expected opening bao-jiao prompt after real opening deal, got %s" % [snapshot]
	if int(snapshot.get("opening_bao_jiao_current_seat", -1)) != 0:
		return "expected opening prompt to stop at human seat 0, got %s" % [snapshot.get("opening_bao_jiao_current_seat", -1)]
	if not bool(snapshot.get("human_can_bao_jiao", false)):
		return "expected human to be able to declare opening bao-jiao, got %s" % [snapshot.get("human_bao_jiao_plan", {})]
	if not bool(game_state.execute_human_bao_jiao(0, [])):
		return "expected human opening bao-jiao declaration to succeed, debug=%s" % game_state.debug_last_message
	if bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao-jiao window to finish after human declaration and queued AI review, current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]
	if int(game_state.current_turn_seat) != 1:
		return "expected AI dealer seat 1 to regain first discard turn, got %s" % game_state.current_turn_seat
	if not bool(game_state.is_ai_turn_ready()):
		return "expected AI dealer to be ready after opening bao-jiao window, debug=%s snapshot=%s" % [
			game_state.debug_last_message,
			game_state.get_debug_snapshot(),
		]
	for _attempt in range(400):
		game_state.pump_ai_background_requests()
		if game_state.run_ai_turn():
			if game_state.discard_pile.is_empty():
				return "expected AI dealer first discard to enter discard pile"
			var discard: Dictionary = game_state.discard_pile[-1]
			if int(discard.get("seat", -1)) != 1:
				return "expected dealer seat 1 first discard, got %s" % [discard]
			return true
		OS.delay_msec(10)
	return "timed out waiting for AI dealer first discard after human opening bao-jiao; pending=%s decision=%s debug=%s" % [
		game_state.pending_ai_turn_request_meta,
		game_state.pending_ai_turn_decision,
		game_state.debug_last_message,
	]


func _test_opening_human_bao_jiao_with_bao_gang_selection_allows_ai_dealer_first_discard():
	var game_state = _build_game_state()
	game_state.previous_dealer_seat = 1
	game_state.start_new_round(true)
	game_state.wall.clear()
	game_state.wall.append_array(_wall_for_opening_hands([
		_opening_ready_bao_gang_hand(1100),
		_tiles_from_types([0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 17], 2100),
		_tiles_from_types([0, 2, 4, 6, 8, 9, 11, 13, 15, 17, 1, 10, 16], 3100),
		_tiles_from_types([1, 3, 5, 7, 9, 11, 13, 15, 17, 0, 8, 10, 12], 4100),
	], 5100))
	game_state.wall_count = game_state.wall.size()
	if not bool(game_state.complete_opening_roll()):
		return "expected opening roll to complete"
	var snapshot: Dictionary = game_state.get_debug_snapshot()
	var plan: Dictionary = snapshot.get("human_bao_jiao_plan", {})
	var options: Array = plan.get("bao_gang_options", [])
	if not bool(snapshot.get("human_can_bao_jiao", false)) or options.is_empty():
		return "expected human opening bao-jiao with bao-gang options, got plan=%s snapshot=%s" % [plan, snapshot]
	var selected_key := str(options[0].get("key", ""))
	if selected_key.is_empty():
		return "expected first bao-gang option to expose a key, got %s" % [options[0]]
	if not bool(game_state.execute_human_bao_jiao(0, [selected_key])):
		return "expected human opening bao-jiao with selected bao-gang to succeed, debug=%s" % game_state.debug_last_message
	if bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao-jiao window to finish after selected bao-gang declaration, current=%s queue=%s debug=%s" % [
			game_state.opening_bao_jiao_current_seat,
			game_state.opening_bao_jiao_queue,
			game_state.debug_last_message,
		]
	var human: Dictionary = game_state.players[0]
	if not bool(human.get("bao_jiao", false)):
		return "expected human to be marked bao-jiao"
	if not Array(human.get("bao_gang_tiles", [])).has(selected_key):
		return "expected selected bao-gang key %s to be recorded, got %s" % [selected_key, human.get("bao_gang_tiles", [])]
	if int(game_state.current_turn_seat) != 1 or not bool(game_state.is_ai_turn_ready()):
		return "expected AI dealer first discard to be ready after selected bao-gang, turn=%s debug=%s snapshot=%s" % [
			game_state.current_turn_seat,
			game_state.debug_last_message,
			game_state.get_debug_snapshot(),
		]
	for _attempt in range(400):
		game_state.pump_ai_background_requests()
		if game_state.run_ai_turn():
			if game_state.discard_pile.is_empty():
				return "expected AI dealer first discard to enter discard pile"
			var discard: Dictionary = game_state.discard_pile[-1]
			if int(discard.get("seat", -1)) != 1:
				return "expected dealer seat 1 first discard, got %s" % [discard]
			return true
		OS.delay_msec(10)
	return "timed out waiting for AI dealer first discard after selected opening bao-gang; pending=%s decision=%s debug=%s" % [
		game_state.pending_ai_turn_request_meta,
		game_state.pending_ai_turn_decision,
		game_state.debug_last_message,
	]


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


func _opening_ready_hand(id_start: int = 5000) -> Array:
	return _tiles_from_types([0, 0, 1, 2, 3, 4, 5, 9, 10, 11, 15, 16, 17], id_start)


func _opening_ready_bao_gang_hand(id_start: int = 6000) -> Array:
	return _tiles_from_types([0, 0, 0, 1, 2, 3, 4, 5, 9, 9, 15, 16, 17], id_start)


func _wall_for_opening_hands(hands_by_seat: Array, filler_id_start: int) -> Array:
	var result: Array = _tiles_from_types([2, 4, 6, 8, 10, 12, 14, 16, 3, 5, 7, 9, 11, 13, 15, 17, 1, 0, 6], filler_id_start)
	for seat in range(hands_by_seat.size() - 1, -1, -1):
		result.append_array(Array(hands_by_seat[seat]).duplicate(true))
	return result


func _make_tile(id: int, suit: String, rank: int) -> Dictionary:
	return {
		"id": id,
		"suit": suit,
		"rank": rank,
		"sort_key": (0 if suit == "tiao" else 100) + rank,
		"display_name": "%d%s" % [rank, "条" if suit == "tiao" else "筒"],
	}


class FakeBaoJiaoManager:
	extends RefCounted

	func analyze_bao_jiao(_player_state: Dictionary, _table_state: Dictionary, _rules_config, plan: Dictionary) -> Dictionary:
		return {
			"action": "bao_jiao",
			"declare": true,
			"selected_bao_gang_keys": plan.get("bao_gang_keys", []).duplicate(true),
			"score": 100,
			"reasons": ["test fake declaration"],
			"backend_mode": "test_fake_bao_jiao",
		}

	func pump_async_requests() -> int:
		return 0

	func get_backend_status() -> Dictionary:
		return {"backend_mode": "test_fake_bao_jiao"}

	func get_debug_snapshot() -> Dictionary:
		return {"backend_status": get_backend_status()}

	func has_native_csharp_runtime() -> bool:
		return false

	func has_native_hell_challenge_runtime() -> bool:
		return false

	func set_native_csharp_runtime(_runtime) -> void:
		pass

	func start_turn_analysis_background(_player_state: Dictionary, _table_state: Dictionary, _rules_config, _ai_config, _hu_checker, _risk_analyzer, _allow_cheat: bool = false, _hell_payload: Dictionary = {}, _force_lightweight: bool = false, _compact_result: bool = false, _force_native_async: bool = false, _allow_sync_delivery: bool = true) -> int:
		return 0

	var latest_turn_snapshot: Dictionary = {}
	var latest_reaction_snapshot: Dictionary = {}
