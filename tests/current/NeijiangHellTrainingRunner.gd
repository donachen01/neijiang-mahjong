extends SceneTree

const GAME_STATE_SCRIPT := preload("res://autoload/GameState.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_run_test("hell_preset_records_oracle_without_executing_it", _test_hell_preset_records_oracle_without_executing_it, failures)
	_run_test("hell_manual_mark_writes_workspace_file", _test_hell_manual_mark_writes_workspace_file, failures)
	_run_test("hell_decision_snapshot_writes_training_file", _test_hell_decision_snapshot_writes_training_file, failures)
	if failures.is_empty():
		print("NEIJIANG HELL TRAINING OK")
		quit(0)
	else:
		push_error("NEIJIANG HELL TRAINING FAILED:\n- " + "\n- ".join(failures))
		quit(1)


func _run_test(name: String, callable: Callable, failures: Array[String]) -> void:
	var result = callable.call()
	if result is bool and result:
		print("PASS ", name)
	else:
		failures.append("%s -> %s" % [name, str(result)])


func _test_hell_preset_records_oracle_without_executing_it():
	var game_state = _build_game_state()
	if not bool(game_state.set_ai_preset("hell")):
		return "expected set_ai_preset hell to succeed"
	if not bool(game_state.set_hell_diagnostics_recording_enabled(true)):
		return "expected diagnostics recording to enable"
	var snapshot: Dictionary = game_state.get_debug_snapshot()
	var config: Dictionary = snapshot.get("ai_tuning_config", {})
	if str(config.get("preset_name", "")) != "hell":
		return "expected preset hell, got %s" % [config]
	if not bool(config.get("hell_record_oracle", false)):
		return "expected hell_record_oracle"
	if bool(config.get("hell_execute_oracle_action", true)):
		return "expected hell oracle to be recorded but not executed"
	if int(snapshot.get("ai_level_index", -1)) != int(GAME_STATE_SCRIPT.AILevel.CHEATING):
		return "expected cheating ai level in hell mode"
	return true


func _test_hell_manual_mark_writes_workspace_file():
	var game_state = _build_game_state()
	game_state.set_test_seed(250514)
	if not bool(game_state.set_ai_preset("hell")):
		return "expected set_ai_preset hell to succeed"
	if not bool(game_state.set_hell_diagnostics_recording_enabled(true)):
		return "expected diagnostics recording to enable"
	if not bool(game_state.mark_current_hell_training_case("test_mark")):
		return "expected mark_current_hell_training_case to succeed"
	if not bool(game_state.mark_current_hell_training_case("duplicate_test_mark")):
		return "expected duplicate mark to be accepted as a no-op"
	var hell: Dictionary = game_state.get_debug_snapshot().get("hell_training", {})
	var session_id := str(hell.get("session_id", ""))
	if session_id.is_empty():
		return "expected hell session id"
	if int(hell.get("marked_count", 0)) != 1:
		return "expected duplicate mark to keep marked_count at 1, got %s" % [hell]
	var path := "res://测试数据统计/hell_marked_cases/%s_mark_0001.json" % session_id
	if not FileAccess.file_exists(path):
		return "expected marked file at %s" % path
	var duplicate_path := "res://测试数据统计/hell_marked_cases/%s_mark_0002.json" % session_id
	if FileAccess.file_exists(duplicate_path):
		return "expected no duplicate marked file at %s" % duplicate_path
	var summary_path := "res://测试数据统计/hell_training/%s_summary.json" % session_id
	if not FileAccess.file_exists(summary_path):
		return "expected summary file at %s" % summary_path
	var replay_path := "res://测试数据统计/hell_replay/%s_replay_manifest.json" % session_id
	if not FileAccess.file_exists(replay_path):
		return "expected replay manifest at %s" % replay_path
	return true


func _test_hell_decision_snapshot_writes_training_file():
	var game_state = _build_game_state()
	game_state.set_test_seed(250515)
	if not bool(game_state.set_ai_preset("hell")):
		return "expected set_ai_preset hell to succeed"
	if not bool(game_state.set_hell_diagnostics_recording_enabled(true)):
		return "expected diagnostics recording to enable"
	game_state._record_hell_decision_snapshot(
		{
			"seat": 1,
			"analysis": {"recommended": {"csharp_tile_type": 3}},
			"hell_oracle": {"category": "hand_efficiency_error", "severity": "medium"},
			"actual_action": {"action": "discard", "tile_type": 4},
		},
		"discard",
		4
	)
	var hell: Dictionary = game_state.get_debug_snapshot().get("hell_training", {})
	var session_id := str(hell.get("session_id", ""))
	var path := "res://测试数据统计/hell_training/%s_decision_000001.json" % session_id
	if not FileAccess.file_exists(path):
		return "expected decision snapshot at %s" % path
	if int(hell.get("decision_count", 0)) != 1:
		return "expected decision_count 1, got %s" % [hell]
	var category_counts: Dictionary = hell.get("category_counts", {})
	if int(category_counts.get("hand_efficiency_error", 0)) != 1:
		return "expected category count, got %s" % [category_counts]
	return true


func _build_game_state():
	var game_state = GAME_STATE_SCRIPT.new()
	get_root().add_child(game_state)
	return game_state
