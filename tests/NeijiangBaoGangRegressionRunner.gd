extends SceneTree

const GAME_STATE_SCRIPT := preload("res://autoload/GameState.gd")
const AI_MANAGER_SCRIPT := preload("res://scripts/ai/AIManager.gd")

class FakeSelfActionAIManager:
	extends RefCounted

	var decision: Dictionary = {}
	var self_action_call_count: int = 0

	func analyze_self_action(_player_state: Dictionary, _table_state: Dictionary, _rules_config, _can_self_hu: bool, _an_gang_tile_types: Array, _add_gang_tile_types: Array, _add_gang_qiang_gang_counts: Dictionary = {}) -> Dictionary:
		self_action_call_count += 1
		return decision.duplicate(true)

	func has_native_csharp_runtime() -> bool:
		return false

	func start_turn_analysis_background(_player_state: Dictionary, _table_state: Dictionary, _rules_config, _ai_tuning_config, _hu_checker, _risk_analyzer, _allow_cheat: bool) -> int:
		return 0

	func pump_async_requests() -> int:
		return 0

	func get_debug_snapshot() -> Dictionary:
		return {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_run_test("csharp_self_action_exposes_gang_subtype", _test_csharp_self_action_exposes_gang_subtype, failures)
	_run_test("game_state_executes_csharp_add_gang_subtype", _test_game_state_executes_csharp_add_gang_subtype, failures)
	_run_test("opening_bao_jiao_queue_scans_ai_and_human_players", _test_opening_bao_jiao_queue_scans_ai_and_human_players, failures)
	_run_test("bao_jiao_blocks_peng_and_non_whitelist_discard_gang", _test_bao_jiao_blocks_peng_and_non_whitelist_discard_gang, failures)
	_run_test("bao_jiao_allows_whitelisted_discard_gang", _test_bao_jiao_allows_whitelisted_discard_gang, failures)
	_run_test("bao_jiao_allows_only_whitelisted_an_gang", _test_bao_jiao_allows_only_whitelisted_an_gang, failures)
	_run_test("ai_reaction_honors_backend_peng_when_gang_available", _test_ai_reaction_honors_backend_peng_when_gang_available, failures)
	_run_test("add_gang_requires_matching_last_draw_after_peng", _test_add_gang_requires_matching_last_draw_after_peng, failures)
	_run_test("peng_does_not_reask_self_action_for_immediate_add_gang", _test_peng_does_not_reask_self_action_for_immediate_add_gang, failures)
	if failures.is_empty():
		print("NEIJIANG BAO GANG REGRESSION OK")
		quit(0)
	else:
		push_error("NEIJIANG BAO GANG REGRESSION FAILED:\n- " + "\n- ".join(failures))
		quit(1)


func _run_test(name: String, callable: Callable, failures: Array[String]) -> void:
	var result = callable.call()
	if result is bool and result:
		print("PASS ", name)
	else:
		failures.append("%s -> %s" % [name, str(result)])


func _test_csharp_self_action_exposes_gang_subtype():
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
		return "expected top-level gang_subtype=add_gang for GameState execution, got %s" % [analysis]
	if str(analysis.get("gangSubtype", "")) != "add_gang":
		return "expected camelCase gangSubtype mirror for compatibility, got %s" % [analysis]
	return true


func _test_game_state_executes_csharp_add_gang_subtype():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(351, "tiao", 2),
			_make_tile(352, "tong", 4), _make_tile(353, "tong", 5), _make_tile(354, "tong", 6),
		], [
			{
				"type": "peng",
				"from_seat": 0,
				"tiles": [
					_make_tile(355, "tiao", 2),
					_make_tile(356, "tiao", 2),
					_make_tile(357, "tiao", 2),
				],
			},
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.last_draw_tile = {
		"seat": 1,
		"tile": game_state.players[1]["hand_tiles"][0].duplicate(true),
	}
	var fake_ai := FakeSelfActionAIManager.new()
	fake_ai.decision = {
		"action": "gang",
		"tile_type": 1,
		"gang_subtype": "add_gang",
		"score": 512,
		"reasons": ["补杠后仍可下叫"],
	}
	game_state.ai_manager = fake_ai
	var decision: Dictionary = game_state._build_ai_self_action_decision(1, game_state._build_player_state(1), game_state._build_table_state())
	if str(decision.get("action", "")) != "add_gang":
		return "expected C# add_gang subtype to become GameState add_gang action, got %s" % [decision]
	var option: Dictionary = decision.get("gang_option", {})
	if int(option.get("meld_index", -1)) != 0:
		return "expected add gang option to reference peng meld 0, got %s" % [option]
	return true


func _test_opening_bao_jiao_queue_scans_ai_and_human_players():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_dealer_seat = 1
	game_state.current_turn_seat = 1
	game_state.wall_count = 19
	_set_test_players(game_state, [
		_make_player_neijiang(0, _ready_13_tiles(4100, "tiao", 1, "tong", 8)),
		_make_player_neijiang(1, _mixed_14_tiles(4200)),
		_make_player_neijiang(2, _ready_13_tiles(4300, "tiao", 4, "tong", 5)),
		_make_player_neijiang(3, []),
	])
	var queue: Array = game_state._build_opening_bao_jiao_queue()
	if not queue.has(0):
		return "expected opening bao jiao queue to scan human player seat 0, got %s" % [queue]
	if not queue.has(2):
		return "expected opening bao jiao queue to scan AI player seat 2, got %s" % [queue]
	if queue.has(1):
		return "expected dealer seat 1 to be excluded because dealer has 14 tiles, got %s" % [queue]
	return true


func _test_bao_jiao_blocks_peng_and_non_whitelist_discard_gang():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_dealer_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(441, "tong", 8), _make_tile(442, "tong", 8), _make_tile(443, "tong", 8),
			_make_tile(444, "tong", 9), _make_tile(445, "tong", 9), _make_tile(446, "tong", 9),
		], [], true),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[0]["bao_gang_tiles"] = ["tong_9"]
	_set_discard_reaction(game_state, 1, _make_tile(447, "tong", 8))
	var options: Dictionary = game_state.get_human_reaction_options(0)
	if bool(options.get("can_peng", false)):
		return "expected bao jiao to block peng"
	if bool(options.get("can_gang", false)):
		return "expected non-whitelist discard gang to be blocked after bao jiao"
	return true


func _test_bao_jiao_allows_whitelisted_discard_gang():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_dealer_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(541, "tong", 8), _make_tile(542, "tong", 8), _make_tile(543, "tong", 8),
			_make_tile(544, "tong", 9), _make_tile(545, "tong", 9), _make_tile(546, "tong", 9),
		], [], true),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[0]["bao_gang_tiles"] = ["tong_8"]
	_set_discard_reaction(game_state, 1, _make_tile(547, "tong", 8))
	var options: Dictionary = game_state.get_human_reaction_options(0)
	if bool(options.get("can_peng", false)):
		return "expected bao jiao to continue blocking peng even when gang is whitelisted"
	if not bool(options.get("can_gang", false)):
		return "expected whitelisted bao gang tile to allow discard gang after bao jiao, got options=%s pending=%s" % [options, game_state.pending_reactions]
	return true


func _test_bao_jiao_allows_only_whitelisted_an_gang():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(641, "tong", 8), _make_tile(642, "tong", 8), _make_tile(643, "tong", 8), _make_tile(644, "tong", 8),
			_make_tile(645, "tiao", 1), _make_tile(646, "tiao", 1), _make_tile(647, "tiao", 2), _make_tile(648, "tiao", 2),
		], [], true),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[0]["bao_gang_tiles"] = ["tong_8"]
	if not bool(game_state.can_human_an_gang(0)):
		return "expected whitelisted an gang to remain allowed after bao jiao"
	game_state.players[0]["bao_gang_tiles"] = ["tiao_1"]
	if bool(game_state.can_human_an_gang(0)):
		return "expected non-whitelist an gang to be blocked after bao jiao"
	return true


func _test_ai_reaction_honors_backend_peng_when_gang_available():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(741, "tiao", 9), _make_tile(742, "tiao", 9), _make_tile(743, "tiao", 9),
			_make_tile(744, "tong", 2), _make_tile(745, "tong", 3), _make_tile(746, "tong", 4),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[0]["is_ai"] = true
	_set_discard_reaction(game_state, 1, _make_tile(747, "tiao", 9))
	var candidate: Dictionary = game_state._get_reaction_candidate_for_seat(0)
	if candidate.is_empty():
		return "expected AI candidate for 9条 discard gang"
	if not bool(candidate.get("can_gang", false)) or not bool(candidate.get("can_peng", false)):
		return "expected same discard claim to expose both gang and peng, got %s" % [candidate]
	var resolved_action := str(game_state._resolve_ai_reaction_action(0, candidate, "peng"))
	if resolved_action != "peng":
		return "expected frontend to honor backend peng request, got %s from %s" % [resolved_action, candidate]
	return true


func _test_add_gang_requires_matching_last_draw_after_peng():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(741, "tiao", 9), _make_tile(742, "tiao", 9), _make_tile(743, "tiao", 9),
			_make_tile(744, "tong", 2), _make_tile(745, "tong", 3), _make_tile(746, "tong", 4),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	_set_discard_reaction(game_state, 1, _make_tile(747, "tiao", 9))
	if not game_state._execute_peng(0):
		return "expected peng execution to succeed"
	if not game_state.last_draw_tile.is_empty():
		return "expected peng claim to clear last_draw_tile"
	if not game_state._find_all_add_gang_options(0).is_empty():
		return "expected no add-gang option immediately after peng without a matching draw"
	game_state.last_draw_tile = {
		"seat": 0,
		"tile": game_state.players[0]["hand_tiles"][0].duplicate(true),
	}
	if game_state._find_all_add_gang_options(0).is_empty():
		return "expected add-gang option when the remaining 9条 is the latest draw"
	return true


func _test_peng_does_not_reask_self_action_for_immediate_add_gang():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(741, "tiao", 9), _make_tile(742, "tiao", 9), _make_tile(743, "tiao", 9),
			_make_tile(744, "tong", 2), _make_tile(745, "tong", 3), _make_tile(746, "tong", 4),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[0]["is_ai"] = true
	var fake_ai := FakeSelfActionAIManager.new()
	fake_ai.decision = {
		"action": "gang",
		"tile_type": 8,
		"gang_subtype": "add_gang",
	}
	game_state.ai_manager = fake_ai
	_set_discard_reaction(game_state, 1, _make_tile(747, "tiao", 9))
	if not game_state._execute_peng(0):
		return "expected AI peng execution to succeed"
	var decision: Dictionary = game_state._build_ai_self_action_decision(0, game_state._build_player_state(0), game_state._build_table_state())
	if not decision.is_empty():
		return "expected no immediate self-action after peng, got %s" % [decision]
	if fake_ai.self_action_call_count != 0:
		return "expected frontend not to ask C# self-action immediately after peng, call_count=%d" % fake_ai.self_action_call_count
	return true


func _set_discard_reaction(game_state, source_seat: int, tile: Dictionary) -> void:
	game_state.current_discard_context = {
		"source_seat": source_seat,
		"tile": tile.duplicate(true),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	game_state.pending_reactions = game_state.mahjong_judge.build_reaction_candidates(game_state._build_table_state(), game_state.current_discard_context, game_state.rules)


func _build_neijiang_test_game_state():
	var game_state = GAME_STATE_SCRIPT.new()
	game_state.rules = load("res://scripts/core/rule_config.gd").new(load("res://scripts/core/rule_config.gd").MODE_NEIJIANG_CLASSIC)
	game_state.mahjong_state = load("res://scripts/core/mahjong_state.gd").new()
	game_state.mahjong_judge = load("res://scripts/core/mahjong_judge.gd").new()
	game_state.ding_que_resolver = load("res://scripts/core/ding_que_resolver.gd").new()
	game_state.reaction_resolver = load("res://scripts/core/reaction_resolver.gd").new()
	game_state.hu_checker = load("res://scripts/core/hu_checker.gd").new()
	game_state.score_resolver = load("res://scripts/core/score_resolver.gd").new()
	game_state.shanten_analyzer = load("res://scripts/core/shanten_analyzer.gd").new()
	game_state.discard_advisor = load("res://scripts/core/discard_advisor.gd").new()
	game_state.risk_analyzer = load("res://scripts/core/risk_analyzer.gd").new()
	game_state.reaction_advisor = load("res://scripts/core/reaction_advisor.gd").new()
	game_state.gang_advisor = load("res://scripts/core/gang_advisor.gd").new()
	game_state.ai_manager = load("res://scripts/ai/AIManager.gd").new()
	game_state.ai_tuning_config = load("res://scripts/core/ai_tuning_config.gd").new()
	game_state.ai_tuning_config.apply_preset("bone_ash")
	game_state.ai_learning_engine = load("res://scripts/core/ai_learning_engine.gd").new()
	game_state.ai_learning_engine.profile = game_state.ai_learning_engine._default_profile()
	game_state.opening_roll_resolver = load("res://scripts/core/opening_roll_resolver.gd").new()
	game_state.ai_decision_metrics = game_state._create_empty_ai_decision_metrics()
	game_state.settlement_data = game_state._create_empty_settlement_data()
	return game_state


func _set_test_players(game_state, new_players: Array) -> void:
	game_state.players.clear()
	for player in new_players:
		game_state.players.append(player)


func _make_player_neijiang(seat: int, hand_tiles: Array, melds: Array = [], bao_jiao: bool = false) -> Dictionary:
	return {
		"seat": seat,
		"nickname": "Seat %d" % seat,
		"score": 0,
		"is_ai": seat != 0,
		"hand_tiles": hand_tiles.duplicate(true),
		"hand_count": hand_tiles.size(),
		"melds": melds.duplicate(true),
		"discards": [],
		"ding_que": "",
		"bao_jiao": bao_jiao,
		"bao_gang_tiles": [],
		"opening_bao_jiao_reviewed": false,
		"bao_jiao_ting_tiles": [],
		"rule_marks": ["报叫"] if bao_jiao else [],
		"has_won": false,
	}


func _ready_13_tiles(base_id: int, suit_a: String, rank_a: int, suit_b: String, rank_b: int) -> Array:
	return [
		_make_tile(base_id + 1, suit_a, rank_a), _make_tile(base_id + 2, suit_a, rank_a), _make_tile(base_id + 3, suit_a, rank_a),
		_make_tile(base_id + 4, suit_a, rank_a + 1), _make_tile(base_id + 5, suit_a, rank_a + 1), _make_tile(base_id + 6, suit_a, rank_a + 1),
		_make_tile(base_id + 7, suit_a, rank_a + 2), _make_tile(base_id + 8, suit_a, rank_a + 2), _make_tile(base_id + 9, suit_a, rank_a + 2),
		_make_tile(base_id + 10, suit_b, rank_b), _make_tile(base_id + 11, suit_b, rank_b), _make_tile(base_id + 12, suit_b, rank_b),
		_make_tile(base_id + 13, suit_b, rank_b + 1),
	]


func _mixed_14_tiles(base_id: int) -> Array:
	return [
		_make_tile(base_id + 1, "tiao", 1), _make_tile(base_id + 2, "tiao", 2), _make_tile(base_id + 3, "tiao", 3),
		_make_tile(base_id + 4, "tiao", 4), _make_tile(base_id + 5, "tiao", 5), _make_tile(base_id + 6, "tiao", 6),
		_make_tile(base_id + 7, "tong", 1), _make_tile(base_id + 8, "tong", 2), _make_tile(base_id + 9, "tong", 3),
		_make_tile(base_id + 10, "tong", 4), _make_tile(base_id + 11, "tong", 5), _make_tile(base_id + 12, "tong", 6),
		_make_tile(base_id + 13, "tong", 7), _make_tile(base_id + 14, "tong", 8),
	]


func _make_tile(id: int, suit: String, rank: int) -> Dictionary:
	var suit_index: int = {"tiao": 0, "tong": 1, "wan": 2}.get(suit, 9)
	return {
		"id": id,
		"suit": suit,
		"rank": rank,
		"sort_key": int(suit_index) * 100 + rank,
		"display_name": "%d%s" % [rank, _suit_name(suit)],
	}


func _suit_name(suit: String) -> String:
	match suit:
		"tiao":
			return "条"
		"tong":
			return "筒"
		"wan":
			return "万"
		_:
			return suit
