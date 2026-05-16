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
	_run_test("native_runtime_mobile_compact_discard_returns_action_candidate", _test_native_runtime_mobile_compact_discard_returns_action_candidate, failures)
	_run_test("ai_manager_uses_native_async_reaction_path", _test_ai_manager_uses_native_async_reaction_path, failures)
	_run_test("ai_manager_reuses_duplicate_native_reaction_request", _test_ai_manager_reuses_duplicate_native_reaction_request, failures)
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


func _test_native_runtime_mobile_compact_discard_returns_action_candidate():
	var runtime = root.get_node_or_null("NeijiangCSharpRuntime")
	if runtime == null:
		return "expected native C# runtime autoload"
	if not runtime.has_method("StartAnalyzeDiscardJson") or not runtime.has_method("PollAiResultJson"):
		return "expected native runtime async discard methods"
	var hand18 := _empty18()
	for tile_type in [0, 1, 2, 3, 4, 5, 10, 11, 12, 13, 13, 15, 16, 17]:
		hand18[tile_type] += 1
	var remaining18 := []
	for tile_type in range(18):
		remaining18.append(maxi(0, 4 - int(hand18[tile_type])))
	var payload := {
		"seatIndex": 1,
		"dealerSeat": 0,
		"currentSeat": 1,
		"wallCount": 12,
		"mobileSpeedMode": true,
		"compactResult": true,
		"hand18": hand18,
		"visible18": hand18.duplicate(),
		"remaining18": remaining18,
		"discards18": _empty_matrix(),
		"melds18": _empty_matrix(),
		"passedHu18": _empty_pass_matrix(),
		"passedPeng18": _empty_pass_matrix(),
		"passedGang18": _empty_pass_matrix(),
		"isCalled": [false, false, false, false],
		"isReady": [false, false, false, false],
		"hasHu": [false, false, false, false],
	}
	var request_id := int(runtime.call("StartAnalyzeDiscardJson", JSON.stringify(payload)))
	if request_id <= 0:
		return "expected positive async discard request id"
	for _attempt in range(400):
		var parsed = JSON.parse_string(str(runtime.call("PollAiResultJson", request_id)))
		var result: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
		if bool(result.get("pending", false)):
			OS.delay_msec(10)
			continue
		if not bool(result.get("ok", false)):
			return "expected ok mobile compact discard result, got %s" % [result]
		if not bool(result.get("mobileSpeedMode", false)):
			return "expected mobileSpeedMode=true, got %s" % [result]
		if not bool(result.get("compactResult", false)):
			return "expected compactResult=true, got %s" % [result]
		var candidates: Array = result.get("candidates", [])
		if candidates.is_empty() or candidates.size() > 4:
			return "expected 1-4 compact candidates, got %s" % [candidates]
		var action_tile := int(result.get("tileType", -1))
		var has_action_candidate := false
		for candidate in candidates:
			var candidate_dict: Dictionary = candidate
			if int(candidate_dict.get("tileType", -1)) == action_tile:
				has_action_candidate = true
				break
		if not has_action_candidate:
			return "expected compact candidates to include final action tile %d, got %s" % [action_tile, candidates]
		var belief_summary: Dictionary = result.get("beliefSummary", {})
		if not bool(belief_summary.get("compact", false)):
			return "expected compact belief summary marker, got %s" % [belief_summary]
		return true
	return "timed out waiting for native compact discard result"


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


func _test_ai_manager_reuses_duplicate_native_reaction_request():
	var runtime = root.get_node_or_null("NeijiangCSharpRuntime")
	if runtime == null:
		return "expected native C# runtime autoload"
	var ai_manager = AI_MANAGER_SCRIPT.new()
	ai_manager.set_native_csharp_runtime(runtime)
	var rules = RULE_CONFIG_SCRIPT.new(RULE_CONFIG_SCRIPT.MODE_NEIJIANG_CLASSIC)
	var tile := _make_tile(61, "tong", 9)
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
	var candidate := {
		"seat": 3,
		"can_hu": false,
		"can_peng": true,
		"can_gang": false,
	}
	var player_state := {
		"seat": 3,
		"hand_tiles": [_make_tile(62, "tong", 9), _make_tile(63, "tong", 9)],
	}
	var table_state := {
		"players": players,
		"current_turn_seat": 2,
		"wall_count": 14,
		"dealer_seat": 0,
		"reaction_pass_evidence": [],
	}
	var discard_context := {"source_seat": 2, "tile": tile, "reaction_type": "discard"}
	var first_id := ai_manager.start_reaction_analysis_background(candidate, player_state, table_state, discard_context, rules, null, null, false)
	var second_id := ai_manager.start_reaction_analysis_background(candidate, player_state, table_state, discard_context, rules, null, null, false)
	if first_id <= 0:
		return "expected first async request id"
	if second_id != first_id:
		return "expected duplicate request to reuse id %d, got %d" % [first_id, second_id]
	var request_state: Dictionary = ai_manager.request_state
	if int(request_state.get("inflight_count", -1)) != 1:
		return "expected one inflight request after duplicate reuse, got %s" % [request_state]
	if int(request_state.get("active_key_count", -1)) != 1:
		return "expected one active request key after duplicate reuse, got %s" % [request_state]
	if int(request_state.get("duplicate_reuse_count", 0)) < 1:
		return "expected duplicate reuse metric, got %s" % [request_state]
	for _attempt in range(400):
		if ai_manager.pump_async_requests() > 0:
			var after_state: Dictionary = ai_manager.request_state
			if int(after_state.get("inflight_count", -1)) != 0:
				return "expected no inflight requests after delivery, got %s" % [after_state]
			if int(after_state.get("active_key_count", -1)) != 0:
				return "expected active request key cleanup after delivery, got %s" % [after_state]
			return true
		OS.delay_msec(10)
	return "timed out waiting for reused native reaction request"


func _make_tile(id: int, suit: String, rank: int) -> Dictionary:
	return {
		"id": id,
		"suit": suit,
		"rank": rank,
		"display_name": "%d%s" % [rank, "条" if suit == "tiao" else "筒"],
	}


func _empty18() -> Array:
	var values := []
	for _i in range(18):
		values.append(0)
	return values


func _empty_matrix() -> Array:
	var matrix := []
	for _seat in range(4):
		matrix.append([])
	return matrix


func _empty_pass_matrix() -> Array:
	var matrix := []
	for _seat in range(4):
		matrix.append(_empty18())
	return matrix
