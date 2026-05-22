extends SceneTree

const GAME_STATE_SCRIPT := preload("res://autoload/GameState.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_run_test("hell_preset_records_oracle_and_keeps_challenge_execution", _test_hell_preset_records_oracle_and_keeps_challenge_execution, failures)
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


func _test_hell_preset_records_oracle_and_keeps_challenge_execution():
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
	if not bool(config.get("hell_execute_oracle_action", false)):
		return "expected hell challenge oracle execution to stay enabled"
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
	var output_dirs: Dictionary = hell.get("output_dirs", {})
	var marked_dir := str(output_dirs.get("marked_cases", ""))
	var training_dir := str(output_dirs.get("training", ""))
	var replay_dir := str(output_dirs.get("replay", ""))
	if not training_dir.begins_with("res://测试数据统计/hell_training"):
		return "expected project hell_training dir, got %s" % [output_dirs]
	var path := "%s/%s_mark_%04d.json" % [marked_dir, session_id, 1]
	if not FileAccess.file_exists(path):
		return "expected marked file at %s" % path
	var duplicate_path := "%s/%s_mark_%04d.json" % [marked_dir, session_id, 2]
	if FileAccess.file_exists(duplicate_path):
		return "expected no duplicate marked file at %s" % duplicate_path
	var summary_path := "%s/%s_summary.json" % [training_dir, session_id]
	if not FileAccess.file_exists(summary_path):
		return "expected summary file at %s" % summary_path
	var replay_path := "%s/%s_replay_manifest.json" % [replay_dir, session_id]
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
			"analysis": {
				"recommended": {
					"csharp_tile_type": 16,
					"tile_name": "8筒",
					"score": 2558,
					"shanten": 0,
					"live_ukeire": 2,
					"keeps_ready": true,
					"feeds_human_hu": false,
					"feeds_human_peng": true,
					"feeds_human_gang": false,
					"human_peng_threat": 2,
					"human_peng_penalty": -180,
					"tempo_peng_allowance_bonus": 260,
					"peng_only_interaction_bonus": 420,
					"exact_wall_remaining": 1,
					"deal_in_target_seats": [],
				},
				"options": [
					{
						"csharp_tile_type": 16,
						"tile_name": "8筒",
						"score": 2558,
						"shanten": 0,
						"live_ukeire": 2,
						"keeps_ready": true,
						"feeds_human_hu": false,
						"feeds_human_peng": true,
						"feeds_human_gang": false,
						"human_peng_threat": 2,
						"human_peng_penalty": -180,
						"tempo_peng_allowance_bonus": 260,
						"peng_only_interaction_bonus": 420,
						"exact_wall_remaining": 1,
						"deal_in_target_seats": [],
					},
					{
						"csharp_tile_type": 14,
						"tile_name": "6筒",
						"score": -1200,
						"shanten": 0,
						"exact_deal_in": true,
						"feeds_human_hu": true,
						"feeds_human_peng": false,
						"deal_in_target_seats": [0],
					},
				],
			},
			"hell_oracle": {"category": "hand_efficiency_error", "severity": "medium"},
			"actual_action": {"action": "discard", "tile_type": 16},
		},
		"discard",
		16
	)
	var hell: Dictionary = game_state.get_debug_snapshot().get("hell_training", {})
	var session_id := str(hell.get("session_id", ""))
	var training_dir := str(Dictionary(hell.get("output_dirs", {})).get("training", ""))
	var path := "%s/%s_decision_%06d.json" % [training_dir, session_id, 1]
	if not FileAccess.file_exists(path):
		return "expected decision snapshot at %s" % path
	if int(hell.get("decision_count", 0)) != 1:
		return "expected decision_count 1, got %s" % [hell]
	var category_counts: Dictionary = hell.get("category_counts", {})
	if int(category_counts.get("hand_efficiency_error", 0)) != 1:
		return "expected category count, got %s" % [category_counts]
	var raw := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return "expected decision snapshot json object, got %s" % raw
	var diagnostic: Dictionary = Dictionary(parsed).get("extra", {}).get("decision", {}).get("analysis", {}).get("turn_diagnostic", {})
	if diagnostic.is_empty():
		return "expected turn_diagnostic in stored decision snapshot, got %s" % [parsed]
	var selected: Dictionary = diagnostic.get("selected", {})
	if not bool(selected.get("keeps_ready", false)):
		return "expected stored selected candidate keeps_ready=true, got %s" % [selected]
	if not bool(selected.get("feeds_human_peng", false)):
		return "expected stored selected candidate feeds_human_peng=true, got %s" % [selected]
	var components: Dictionary = selected.get("score_components", {})
	if int(components.get("peng_only_interaction_bonus", 0)) != 420:
		return "expected peng_only_interaction_bonus in score components, got %s" % [components]
	return true


func _build_game_state():
	var game_state = GAME_STATE_SCRIPT.new()
	get_root().add_child(game_state)
	return game_state
