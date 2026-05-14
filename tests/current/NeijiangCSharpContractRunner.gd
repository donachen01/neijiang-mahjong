extends SceneTree

const AI_MANAGER_SCRIPT := preload("res://scripts/ai/AIManager.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_run_test("csharp_action_tile_matches_godot_recommended_tile", _test_csharp_action_tile_matches_godot_recommended_tile, failures)
	_run_test("csharp_candidate_reasons_survive_godot_mapping", _test_csharp_candidate_reasons_survive_godot_mapping, failures)
	_run_test("self_action_gang_subtype_survives_godot_mapping", _test_self_action_gang_subtype_survives_godot_mapping, failures)
	if failures.is_empty():
		print("NEIJIANG CSHARP CONTRACT OK")
		quit(0)
	else:
		push_error("NEIJIANG CSHARP CONTRACT FAILED:\n- " + "\n- ".join(failures))
		quit(1)


func _run_test(name: String, callable: Callable, failures: Array[String]) -> void:
	var result = callable.call()
	if result is bool and result:
		print("PASS ", name)
	else:
		failures.append("%s -> %s" % [name, str(result)])


func _test_csharp_action_tile_matches_godot_recommended_tile():
	var ai_manager = AI_MANAGER_SCRIPT.new()
	var player_state := {
		"seat": 0,
		"hand_tiles": [
			_make_tile(1, "tiao", 1),
			_make_tile(2, "tiao", 2),
		],
	}
	var csharp_result := {
		"action": "discard",
		"tileType": 1,
		"candidates": [
			{
				"tileType": 0,
				"score": 900,
				"shanten": 0,
				"liveUkeire": 8,
				"reasons": ["display sorted first but not final action"],
			},
			{
				"tileType": 1,
				"score": 800,
				"shanten": 0,
				"liveUkeire": 7,
				"reasons": ["C# final action"],
			},
		],
	}
	var analysis: Dictionary = ai_manager._build_csharp_discard_analysis(player_state, csharp_result, null, ai_manager.csharp_bridge, "contract_test")
	var recommended: Dictionary = analysis.get("recommended", {})
	if int(recommended.get("csharp_tile_type", -1)) != 1:
		return "expected Godot recommended to match C# tileType=1, got %s" % [recommended]
	return true


func _test_csharp_candidate_reasons_survive_godot_mapping():
	var ai_manager = AI_MANAGER_SCRIPT.new()
	var player_state := {
		"seat": 0,
		"hand_tiles": [_make_tile(1, "tiao", 2)],
	}
	var csharp_result := {
		"action": "discard",
		"tileType": 1,
		"candidates": [
			{
				"tileType": 1,
				"score": 1000,
				"riskReasons": ["现物偏安全"],
				"posteriorReasons": ["后验未明显压分"],
				"reasons": ["C# 推荐原因"],
			},
		],
	}
	var analysis: Dictionary = ai_manager._build_csharp_discard_analysis(player_state, csharp_result, null, ai_manager.csharp_bridge, "contract_test")
	var recommended: Dictionary = analysis.get("recommended", {})
	if not Array(recommended.get("reasons", [])).has("C# 推荐原因"):
		return "expected C# reasons to survive mapping, got %s" % [recommended]
	if not Array(recommended.get("risk_reasons", [])).has("现物偏安全"):
		return "expected C# risk reasons to survive mapping, got %s" % [recommended]
	return true


func _test_self_action_gang_subtype_survives_godot_mapping():
	var ai_manager = AI_MANAGER_SCRIPT.new()
	var analysis: Dictionary = ai_manager._build_csharp_self_action_analysis(
		{
			"action": "gang",
			"tileType": 1,
			"gangSubtype": "add_gang",
			"score": 312,
			"reason": "补杠后仍可下叫",
			"reasons": ["补杠后最快向听 0"],
			"actionScores": {"pass": 20, "add_gang:1": 312},
			"backendMode": "csharp_native_self_action",
		},
		"csharp_native_self_action"
	)
	if str(analysis.get("gang_subtype", "")) != "add_gang":
		return "expected top-level gang_subtype=add_gang, got %s" % [analysis]
	if str(analysis.get("gangSubtype", "")) != "add_gang":
		return "expected camelCase gangSubtype mirror, got %s" % [analysis]
	return true


func _make_tile(id: int, suit: String, rank: int) -> Dictionary:
	return {
		"id": id,
		"suit": suit,
		"rank": rank,
		"display_name": "%d%s" % [rank, "条" if suit == "tiao" else "筒"],
	}
