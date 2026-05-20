extends SceneTree

const AI_MANAGER_SCRIPT := preload("res://scripts/ai/AIManager.gd")
const RULE_CONFIG_SCRIPT := preload("res://scripts/core/rule_config.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_run_test("csharp_action_tile_matches_godot_recommended_tile", _test_csharp_action_tile_matches_godot_recommended_tile, failures)
	_run_test("csharp_candidate_reasons_survive_godot_mapping", _test_csharp_candidate_reasons_survive_godot_mapping, failures)
	_run_test("csharp_route_plan_survives_godot_mapping", _test_csharp_route_plan_survives_godot_mapping, failures)
	_run_test("bao_jiao_csharp_tile_type_maps_to_last_draw_tile", _test_bao_jiao_csharp_tile_type_maps_to_last_draw_tile, failures)
	_run_test("self_action_gang_subtype_survives_godot_mapping", _test_self_action_gang_subtype_survives_godot_mapping, failures)
	_run_test("native_runtime_async_reaction_returns_result", _test_native_runtime_async_reaction_returns_result, failures)
	_run_test("native_runtime_mobile_compact_discard_returns_action_candidate", _test_native_runtime_mobile_compact_discard_returns_action_candidate, failures)
	_run_test("ai_manager_sync_hell_challenge_preserves_pressure_diagnostics", _test_ai_manager_sync_hell_challenge_preserves_pressure_diagnostics, failures)
	_run_test("ai_manager_sync_hell_challenge_bao_jiao_uses_last_draw", _test_ai_manager_sync_hell_challenge_bao_jiao_uses_last_draw, failures)
	_run_test("ai_manager_sync_hell_challenge_allows_ordinary_peng_interaction", _test_ai_manager_sync_hell_challenge_allows_ordinary_peng_interaction, failures)
	_run_test("ai_manager_uses_native_async_hell_challenge_discard_path", _test_ai_manager_uses_native_async_hell_challenge_discard_path, failures)
	_run_test("ai_manager_sync_hell_challenge_reaction_blocks_human", _test_ai_manager_sync_hell_challenge_reaction_blocks_human, failures)
	_run_test("ai_manager_async_hell_challenge_reaction_blocks_human", _test_ai_manager_async_hell_challenge_reaction_blocks_human, failures)
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


func _test_bao_jiao_csharp_tile_type_maps_to_last_draw_tile():
	var ai_manager = AI_MANAGER_SCRIPT.new()
	var locked_same_type := _make_tile(41, "tong", 2)
	var last_draw_tile := _make_tile(99, "tong", 2)
	var player_state := {
		"seat": 1,
		"bao_jiao": true,
		"hand_tiles": [
			locked_same_type,
			_make_tile(42, "tiao", 1),
			last_draw_tile,
		],
	}
	var table_state := {
		"last_draw_tile": {
			"seat": 1,
			"tile": last_draw_tile.duplicate(true),
		},
	}
	var csharp_result := {
		"action": "discard",
		"tileType": 10,
		"candidates": [
			{
				"tileType": 10,
				"score": 130000,
				"shanten": 0,
				"liveUkeire": 8,
				"reasons": ["报叫专线：已报叫后摸什么出什么"],
			},
		],
	}
	var analysis: Dictionary = ai_manager._build_csharp_discard_analysis(player_state, csharp_result, null, ai_manager.csharp_bridge, "contract_test", table_state)
	var recommended: Dictionary = analysis.get("recommended", {})
	var recommended_tile: Dictionary = recommended.get("tile", {})
	if int(recommended.get("csharp_tile_type", -1)) != 10:
		return "expected C# tileType 10 to survive mapping, got %s" % [recommended]
	if int(recommended_tile.get("id", -1)) != int(last_draw_tile.get("id", -1)):
		return "expected bao-jiao mapping to use last_draw tile id, got %s" % [recommended]
	if int(recommended_tile.get("id", -1)) == int(locked_same_type.get("id", -1)):
		return "expected locked same-type tile to stay unselected, got %s" % [recommended]
	return true


func _test_csharp_route_plan_survives_godot_mapping():
	var ai_manager = AI_MANAGER_SCRIPT.new()
	var player_state := {
		"seat": 0,
		"hand_tiles": [_make_tile(1, "tiao", 2)],
	}
	var csharp_result := {
		"action": "discard",
		"tileType": 1,
		"routePlan": {
			"primaryRoute": "暗七对",
			"constraints": ["forbid_melds", "forbid_gangs", "preserve_pairs"],
			"routeWeights": {"暗七对": 920, "平胡": 640},
			"reasons": ["七对路线：碰杠会破坏七对，优先门清推进"],
		},
		"candidates": [
			{
				"tileType": 1,
				"score": 1000,
				"routePlanPrimary": "暗七对",
				"routePlanScore": 360,
				"reasons": ["路线规划：暗七对"],
			},
		],
	}
	var analysis: Dictionary = ai_manager._build_csharp_discard_analysis(player_state, csharp_result, null, ai_manager.csharp_bridge, "contract_test")
	var route_plan: Dictionary = analysis.get("route_plan", {})
	if str(route_plan.get("primaryRoute", "")) != "暗七对":
		return "expected top-level C# routePlan to survive mapping, got %s" % [analysis]
	var recommended: Dictionary = analysis.get("recommended", {})
	if str(recommended.get("route_plan_primary", "")) != "暗七对":
		return "expected candidate route_plan_primary=暗七对, got %s" % [recommended]
	if int(recommended.get("route_plan_score", 0)) != 360:
		return "expected candidate route_plan_score=360, got %s" % [recommended]
	if str(recommended.get("csharp_route_plan_primary", "")) != "暗七对":
		return "expected mirrored csharp_route_plan_primary=暗七对, got %s" % [recommended]
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
		var route_plan: Dictionary = result.get("routePlan", {})
		if str(route_plan.get("primaryRoute", "")).is_empty():
			return "expected compact native discard routePlan.primaryRoute, got %s" % [result]
		var candidates: Array = result.get("candidates", [])
		if candidates.is_empty() or candidates.size() > 4:
			return "expected 1-4 compact candidates, got %s" % [candidates]
		var action_tile := int(result.get("tileType", -1))
		var has_action_candidate := false
		for candidate in candidates:
			var candidate_dict: Dictionary = candidate
			if str(candidate_dict.get("routePlanPrimary", "")).is_empty():
				return "expected compact candidate routePlanPrimary, got %s" % [candidate_dict]
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


func _test_ai_manager_uses_native_async_hell_challenge_discard_path():
	var runtime = root.get_node_or_null("NeijiangCSharpRuntime")
	if runtime == null:
		return "expected native C# runtime autoload"
	var ai_manager = AI_MANAGER_SCRIPT.new()
	ai_manager.set_native_csharp_runtime(runtime)
	var rules = RULE_CONFIG_SCRIPT.new(RULE_CONFIG_SCRIPT.MODE_NEIJIANG_CLASSIC)
	var fixture := _build_hell_challenge_fixture()
	var request_id := ai_manager.start_turn_analysis_background(
		fixture.get("player_state", {}),
		fixture.get("table_state", {}),
		rules,
		null,
		null,
		null,
		false,
		fixture.get("hell_payload", {})
	)
	if request_id <= 0:
		return "expected AIManager native async hell challenge request id"
	for _attempt in range(400):
		if ai_manager.pump_async_requests() > 0:
			var snapshot: Dictionary = ai_manager.latest_turn_snapshot
			var analysis: Dictionary = snapshot.get("analysis", {})
			var recommended: Dictionary = analysis.get("recommended", {})
			if str(snapshot.get("active_backend", "")) != "hell_challenge_direct_async":
				return "expected hell challenge async backend, got %s" % [snapshot]
			if str(analysis.get("backend_mode", "")) != "hell_challenge_direct_async":
				return "expected mapped hell challenge backend_mode, got %s" % [analysis]
			if int(recommended.get("csharp_tile_type", -1)) == 5:
				return "expected direct hell challenge to avoid feeding human peng tile 5, got %s" % [recommended]
			var native: Dictionary = analysis.get("csharp_result", {})
			if str(native.get("category", "")) != "hell_challenge_direct":
				return "expected native category hell_challenge_direct, got %s" % [native]
			if int(native.get("humanPressureLevel", 0)) != 4:
				return "expected leading human pressure level 4, got %s" % [native]
			if str(native.get("teamRole", "")) != "lead_suppressor":
				return "expected async hell challenge team role lead_suppressor, got %s" % [native]
			if int(native.get("teamPressureBonus", 0)) <= 0:
				return "expected async hell challenge team pressure bonus, got %s" % [native]
			if bool(native.get("oracleFeedsHumanPeng", true)):
				return "expected selected direct discard not to feed human peng, got %s" % [native]
			return true
		OS.delay_msec(10)
	return "timed out waiting for AIManager native async hell challenge discard"


func _test_ai_manager_sync_hell_challenge_preserves_pressure_diagnostics():
	var runtime = root.get_node_or_null("NeijiangCSharpRuntime")
	if runtime == null:
		return "expected native C# runtime autoload"
	var ai_manager = AI_MANAGER_SCRIPT.new()
	ai_manager.set_native_csharp_runtime(runtime)
	var rules = RULE_CONFIG_SCRIPT.new(RULE_CONFIG_SCRIPT.MODE_NEIJIANG_CLASSIC)
	var fixture := _build_hell_challenge_fixture()
	var analysis: Dictionary = ai_manager.analyze_hell_challenge_discard(
		fixture.get("player_state", {}),
		fixture.get("table_state", {}),
		rules,
		fixture.get("hell_payload", {})
	)
	if str(analysis.get("backend_mode", "")) != "hell_challenge_direct":
		return "expected sync hell challenge backend, got %s" % [analysis]
	var recommended: Dictionary = analysis.get("recommended", {})
	if int(recommended.get("csharp_tile_type", -1)) == 5:
		return "expected sync direct hell challenge to avoid feeding human peng tile 5, got %s" % [recommended]
	var native: Dictionary = analysis.get("csharp_result", {})
	if str(native.get("category", "")) != "hell_challenge_direct":
		return "expected compact native category hell_challenge_direct, got %s" % [native]
	if int(native.get("humanPressureLevel", 0)) != 4:
		return "expected compact native pressure level 4, got %s" % [native]
	if str(native.get("teamRole", "")) != "lead_suppressor":
		return "expected compact native team role lead_suppressor, got %s" % [native]
	if int(native.get("teamPressureBonus", 0)) <= 0:
		return "expected compact native team pressure bonus, got %s" % [native]
	if not _array_contains_substring(native.get("teamPlanSummary", []), "三家协作"):
		return "expected compact native team plan summary to mention 三家协作, got %s" % [native]
	if bool(native.get("oracleFeedsHumanPeng", true)):
		return "expected compact native selected discard not to feed human peng, got %s" % [native]
	if Array(native.get("reasons", [])).is_empty():
		return "expected compact native direct reasons to survive mapping, got %s" % [native]
	return true


func _test_ai_manager_sync_hell_challenge_bao_jiao_uses_last_draw():
	var runtime = root.get_node_or_null("NeijiangCSharpRuntime")
	if runtime == null:
		return "expected native C# runtime autoload"
	var ai_manager = AI_MANAGER_SCRIPT.new()
	ai_manager.set_native_csharp_runtime(runtime)
	var rules = RULE_CONFIG_SCRIPT.new(RULE_CONFIG_SCRIPT.MODE_NEIJIANG_CLASSIC)
	var locked_same_type := _make_tile(501, "tong", 2)
	var last_draw_tile := _make_tile(599, "tong", 2)
	var players := []
	for seat in range(4):
		players.append({
			"seat": seat,
			"hand_tiles": [],
			"discards": [],
			"melds": [],
			"bao_jiao": seat == 1,
			"has_won": false,
		})
	var all_hands18 := [_empty18(), _empty18(), _empty18(), _empty18()]
	all_hands18[1][10] = 2
	var exact_wall18 := _empty18()
	exact_wall18[10] = 2
	var analysis: Dictionary = ai_manager.analyze_hell_challenge_discard(
		{
			"seat": 1,
			"bao_jiao": true,
			"hand_tiles": [
				locked_same_type,
				_make_tile(502, "tiao", 1),
				_make_tile(503, "tiao", 2),
				last_draw_tile,
			],
		},
		{
			"players": players,
			"current_turn_seat": 1,
			"wall_count": 17,
			"dealer_seat": 0,
			"last_draw_tile": {
				"seat": 1,
				"tile": last_draw_tile.duplicate(true),
			},
			"reaction_pass_evidence": [],
		},
		rules,
		{
			"allHands18": all_hands18,
			"exactWall18": exact_wall18,
			"currentScores": [0, 0, 0, 0],
		}
	)
	if str(analysis.get("backend_mode", "")) != "hell_challenge_direct":
		return "expected hell challenge backend, got %s" % [analysis]
	var native: Dictionary = analysis.get("csharp_result", {})
	if str(native.get("category", "")) != "bao_jiao_route":
		return "expected backend bao_jiao_route, got %s" % [native]
	if int(native.get("tileType", -1)) != 10:
		return "expected backend to choose last-draw tile type 10, got %s" % [native]
	var recommended: Dictionary = analysis.get("recommended", {})
	var tile: Dictionary = recommended.get("tile", {})
	if int(tile.get("id", -1)) != int(last_draw_tile.get("id", -1)):
		return "expected recommended Godot tile id to be last_draw, got %s" % [recommended]
	if int(tile.get("id", -1)) == int(locked_same_type.get("id", -1)):
		return "expected locked same-type tile to remain unselected, got %s" % [recommended]
	return true


func _test_ai_manager_sync_hell_challenge_allows_ordinary_peng_interaction():
	var runtime = root.get_node_or_null("NeijiangCSharpRuntime")
	if runtime == null:
		return "expected native C# runtime autoload"
	var ai_manager = AI_MANAGER_SCRIPT.new()
	ai_manager.set_native_csharp_runtime(runtime)
	var rules = RULE_CONFIG_SCRIPT.new(RULE_CONFIG_SCRIPT.MODE_NEIJIANG_CLASSIC)
	var fixture := _build_hell_challenge_peng_interaction_fixture()
	var analysis: Dictionary = ai_manager.analyze_hell_challenge_discard(
		fixture.get("player_state", {}),
		fixture.get("table_state", {}),
		rules,
		fixture.get("hell_payload", {})
	)
	if str(analysis.get("backend_mode", "")) != "hell_challenge_direct":
		return "expected sync hell challenge backend, got %s" % [analysis]
	var recommended: Dictionary = analysis.get("recommended", {})
	if int(recommended.get("csharp_tile_type", -1)) != 5:
		return "expected ordinary peng interaction to keep live ready tile 5, got %s" % [recommended]
	var native: Dictionary = analysis.get("csharp_result", {})
	if not bool(native.get("oracleFeedsHumanPeng", false)):
		return "expected selected discard to allow ordinary human peng, got %s" % [native]
	if not bool(native.get("exactKeepsReady", false)):
		return "expected selected ordinary peng discard to keep AI ready, got %s" % [native]
	if not _array_contains_substring(native.get("reasons", []), "互动保真"):
		return "expected reasons to mention 互动保真, got %s" % [native]
	return true


func _test_ai_manager_sync_hell_challenge_reaction_blocks_human():
	var runtime = root.get_node_or_null("NeijiangCSharpRuntime")
	if runtime == null:
		return "expected native C# runtime autoload"
	var ai_manager = AI_MANAGER_SCRIPT.new()
	ai_manager.set_native_csharp_runtime(runtime)
	var rules = RULE_CONFIG_SCRIPT.new(RULE_CONFIG_SCRIPT.MODE_NEIJIANG_CLASSIC)
	var fixture := _build_hell_challenge_reaction_fixture()
	var analysis: Dictionary = ai_manager.analyze_hell_challenge_reaction(
		fixture.get("candidate", {}),
		fixture.get("player_state", {}),
		fixture.get("table_state", {}),
		fixture.get("discard_context", {}),
		rules,
		fixture.get("hell_payload", {})
	)
	return _assert_hell_challenge_reaction_analysis(analysis, "hell_challenge_reaction_direct")


func _test_ai_manager_async_hell_challenge_reaction_blocks_human():
	var runtime = root.get_node_or_null("NeijiangCSharpRuntime")
	if runtime == null:
		return "expected native C# runtime autoload"
	var ai_manager = AI_MANAGER_SCRIPT.new()
	ai_manager.set_native_csharp_runtime(runtime)
	var rules = RULE_CONFIG_SCRIPT.new(RULE_CONFIG_SCRIPT.MODE_NEIJIANG_CLASSIC)
	var fixture := _build_hell_challenge_reaction_fixture()
	var request_id := ai_manager.start_reaction_analysis_background(
		fixture.get("candidate", {}),
		fixture.get("player_state", {}),
		fixture.get("table_state", {}),
		fixture.get("discard_context", {}),
		rules,
		null,
		null,
		false,
		fixture.get("hell_payload", {})
	)
	if request_id <= 0:
		return "expected AIManager native async hell challenge reaction request id"
	for _attempt in range(400):
		if ai_manager.pump_async_requests() > 0:
			var snapshot: Dictionary = ai_manager.latest_reaction_snapshot
			if str(snapshot.get("active_backend", "")) != "hell_challenge_reaction_direct_async":
				return "expected hell challenge reaction async backend, got %s" % [snapshot]
			return _assert_hell_challenge_reaction_analysis(snapshot.get("analysis", {}), "hell_challenge_reaction_direct_async")
		OS.delay_msec(10)
	return "timed out waiting for AIManager native async hell challenge reaction"


func _assert_hell_challenge_reaction_analysis(analysis: Dictionary, expected_backend: String):
	if str(analysis.get("backend_mode", "")) != expected_backend:
		return "expected backend %s, got %s" % [expected_backend, analysis]
	if str(analysis.get("action", "")) != "peng":
		return "expected hell challenge reaction to peng human discard, got %s" % [analysis]
	var scores: Dictionary = analysis.get("action_scores", {})
	if int(scores.get("team_block_human", 0)) <= 0:
		return "expected positive team_block_human score, got %s" % [scores]
	if int(scores.get("team_plan_pressure", 0)) <= 0:
		return "expected positive team_plan_pressure score, got %s" % [scores]
	var reasons: Array = analysis.get("reasons", [])
	if not _array_contains_substring(reasons, "围剿"):
		return "expected hell challenge reaction reasons to mention 围剿, got %s" % [reasons]
	if not _array_contains_substring(reasons, "三家协作"):
		return "expected hell challenge reaction reasons to mention 三家协作, got %s" % [reasons]
	return true


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


func _build_hell_challenge_fixture() -> Dictionary:
	var hand_tiles := _tiles_from_types([0, 0, 0, 3, 3, 3, 5, 6, 6, 6, 10, 10, 10, 17], 100)
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
	var all_hands18 := [_empty18(), _empty18(), _empty18(), _empty18()]
	all_hands18[0][5] = 2
	var exact_wall18 := []
	for _tile_type in range(18):
		exact_wall18.append(1)
	exact_wall18[5] = 3
	exact_wall18[17] = 1
	return {
		"player_state": {
			"seat": 1,
			"hand_tiles": hand_tiles,
		},
		"table_state": {
			"players": players,
			"current_turn_seat": 1,
			"wall_count": 18,
			"dealer_seat": 0,
			"reaction_pass_evidence": [],
		},
		"hell_payload": {
			"allHands18": all_hands18,
			"exactWall18": exact_wall18,
			"currentScores": [26, 18, 4, 2],
		},
	}


func _build_hell_challenge_peng_interaction_fixture() -> Dictionary:
	var hand_tiles := _tiles_from_types([1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 16, 16, 17, 17], 100)
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
	var all_hands18 := [_empty18(), _empty18(), _empty18(), _empty18()]
	all_hands18[0][5] = 2
	var exact_wall18 := []
	for _tile_type in range(18):
		exact_wall18.append(0)
	exact_wall18[16] = 3
	exact_wall18[17] = 1
	return {
		"player_state": {
			"seat": 3,
			"hand_tiles": hand_tiles,
		},
		"table_state": {
			"players": players,
			"current_turn_seat": 3,
			"wall_count": 18,
			"dealer_seat": 0,
			"reaction_pass_evidence": [],
		},
		"hell_payload": {
			"allHands18": all_hands18,
			"exactWall18": exact_wall18,
			"currentScores": [32, 16, 8, 4],
		},
	}


func _build_hell_challenge_reaction_fixture() -> Dictionary:
	var reaction_tile := _make_tile(205, "tiao", 6)
	var hand_tiles := _tiles_from_types([5, 5, 1, 2, 3, 6, 7, 8, 10, 11, 12, 14, 15], 100)
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
	var all_hands18 := [_empty18(), _empty18(), _empty18(), _empty18()]
	all_hands18[0][4] = 1
	all_hands18[0][6] = 1
	all_hands18[0][7] = 1
	var exact_wall18 := []
	for _tile_type in range(18):
		exact_wall18.append(1)
	exact_wall18[5] = 2
	return {
		"candidate": {
			"seat": 1,
			"can_hu": false,
			"can_peng": true,
			"can_gang": false,
		},
		"player_state": {
			"seat": 1,
			"hand_tiles": hand_tiles,
		},
		"table_state": {
			"players": players,
			"current_turn_seat": 0,
			"wall_count": 18,
			"dealer_seat": 0,
			"reaction_pass_evidence": [],
		},
		"discard_context": {
			"source_seat": 0,
			"tile": reaction_tile,
			"reaction_type": "discard",
		},
		"hell_payload": {
			"allHands18": all_hands18,
			"exactWall18": exact_wall18,
			"currentScores": [28, 8, 6, 4],
		},
	}


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


func _array_contains_substring(values: Array, needle: String) -> bool:
	for value in values:
		if str(value).contains(needle):
			return true
	return false


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
