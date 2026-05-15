extends SceneTree

const AI_MANAGER_SCRIPT := preload("res://scripts/ai/AIManager.gd")
const RULE_CONFIG_SCRIPT := preload("res://scripts/core/rule_config.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_run_test("csharp_action_tile_matches_godot_recommended_tile", _test_csharp_action_tile_matches_godot_recommended_tile, failures)
	_run_test("csharp_candidate_reasons_survive_godot_mapping", _test_csharp_candidate_reasons_survive_godot_mapping, failures)
	_run_test("self_action_gang_subtype_survives_godot_mapping", _test_self_action_gang_subtype_survives_godot_mapping, failures)
	_run_test("native_runtime_async_reaction_returns_result", _test_native_runtime_async_reaction_returns_result, failures)
	_run_test("ai_manager_uses_native_async_reaction_path", _test_ai_manager_uses_native_async_reaction_path, failures)
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


func _test_native_runtime_async_reaction_returns_result():
	var runtime = root.get_node_or_null("NeijiangCSharpRuntime")
	if runtime == null:
		return "expected native C# runtime autoload"
	if not runtime.has_method("StartAnalyzeReactionJson") or not runtime.has_method("PollAiResultJson"):
		return "expected native runtime async methods"
	var empty18 := []
	for _i in range(18):
		empty18.append(0)
	var matrix := []
	for _seat in range(4):
		matrix.append([])
	var payload := {
		"seatIndex": 1,
		"dealerSeat": 0,
		"currentSeat": 0,
		"wallCount": 12,
		"hand18": empty18.duplicate(),
		"visible18": empty18.duplicate(),
		"remaining18": empty18.duplicate(),
		"discards18": matrix.duplicate(true),
		"melds18": matrix.duplicate(true),
		"passedHu18": [empty18.duplicate(), empty18.duplicate(), empty18.duplicate(), empty18.duplicate()],
		"passedPeng18": [empty18.duplicate(), empty18.duplicate(), empty18.duplicate(), empty18.duplicate()],
		"passedGang18": [empty18.duplicate(), empty18.duplicate(), empty18.duplicate(), empty18.duplicate()],
		"isCalled": [false, false, false, false],
		"isReady": [false, false, false, false],
		"hasHu": [false, false, false, false],
		"reactionTileType": 4,
		"sourceSeat": 0,
		"reactionType": "discard",
		"canHu": true,
		"canPeng": false,
		"canGang": false,
	}
	var request_id := int(runtime.call("StartAnalyzeReactionJson", JSON.stringify(payload)))
	if request_id <= 0:
		return "expected positive async request id"
	for _attempt in range(80):
		var parsed = JSON.parse_string(str(runtime.call("PollAiResultJson", request_id)))
		var result: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
		if bool(result.get("pending", false)):
			OS.delay_msec(10)
			continue
		if not bool(result.get("ok", false)):
			return "expected ok async result, got %s" % [result]
		if str(result.get("action", "")) != "hu":
			return "expected async hu result, got %s" % [result]
		return true
	return "timed out waiting for native async result"


func _test_ai_manager_uses_native_async_reaction_path():
	var runtime = root.get_node_or_null("NeijiangCSharpRuntime")
	if runtime == null:
		return "expected native C# runtime autoload"
	var ai_manager = AI_MANAGER_SCRIPT.new()
	ai_manager.set_native_csharp_runtime(runtime)
	var rules = RULE_CONFIG_SCRIPT.new(RULE_CONFIG_SCRIPT.MODE_NEIJIANG_CLASSIC)
	var tile := _make_tile(51, "tiao", 5)
	var players := []
	for seat in range(4):
		players.append({
			"seat": seat,
			"hand_tiles": [],
			"discards": [],
			"melds": [],
			"bao_jiao": false,
			"has_won": false,
		})
	var request_id := ai_manager.start_reaction_analysis_background(
		{
			"seat": 1,
			"can_hu": true,
			"can_peng": false,
			"can_gang": false,
		},
		{"seat": 1, "hand_tiles": []},
		{"players": players, "current_turn_seat": 0, "wall_count": 12, "dealer_seat": 0, "reaction_pass_evidence": []},
		{"source_seat": 0, "tile": tile, "reaction_type": "discard"},
		rules,
		null,
		null,
		false
	)
	if request_id <= 0:
		return "expected AIManager native async request id"
	for _attempt in range(80):
		if ai_manager.pump_async_requests() > 0:
			var snapshot: Dictionary = ai_manager.latest_reaction_snapshot
			var analysis: Dictionary = snapshot.get("analysis", {})
			if str(snapshot.get("active_backend", "")) != "hybrid_csharp_native_async":
				return "expected async backend, got %s" % [snapshot]
			if str(analysis.get("action", "")) != "hu":
				return "expected async mapped hu analysis, got %s" % [analysis]
			return true
		OS.delay_msec(10)
	return "timed out waiting for AIManager native async reaction"


func _make_tile(id: int, suit: String, rank: int) -> Dictionary:
	return {
		"id": id,
		"suit": suit,
		"rank": rank,
		"display_name": "%d%s" % [rank, "条" if suit == "tiao" else "筒"],
	}
