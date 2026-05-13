extends Node

signal state_changed(snapshot: Dictionary)
signal opening_roll_started(data: Dictionary)

const RuleConfigScript := preload("res://scripts/core/rule_config.gd")
const MahjongStateScript := preload("res://scripts/core/mahjong_state.gd")
const MahjongJudgeScript := preload("res://scripts/core/mahjong_judge.gd")
const DingQueResolverScript := preload("res://scripts/core/ding_que_resolver.gd")
const ReactionResolverScript := preload("res://scripts/core/reaction_resolver.gd")
const HuCheckerScript := preload("res://scripts/core/hu_checker.gd")
const ScoreResolverScript := preload("res://scripts/core/score_resolver.gd")
const ShantenAnalyzerScript := preload("res://scripts/core/shanten_analyzer.gd")
const DiscardAdvisorScript := preload("res://scripts/core/discard_advisor.gd")
const RiskAnalyzerScript := preload("res://scripts/core/risk_analyzer.gd")
const ReactionAdvisorScript := preload("res://scripts/core/reaction_advisor.gd")
const GangAdvisorScript := preload("res://scripts/core/gang_advisor.gd")
const AITuningConfigScript := preload("res://scripts/core/ai_tuning_config.gd")
const AILearningEngineScript := preload("res://scripts/core/ai_learning_engine.gd")
const OpeningRollResolverScript := preload("res://scripts/core/opening_roll_resolver.gd")
const AIManagerScript := preload("res://scripts/ai/AIManager.gd")

enum RoundPhase {
	BOOT,
	MAIN_MENU,
	TABLE_SETUP,
	DING_QUE,
	DRAW,
	DISCARD,
	REACTION,
	SETTLEMENT
}

enum AILevel {
	BEGINNER,
	INTERMEDIATE,
	ADVANCED,
	CHEATING
}

const DEFAULT_SUITS := ["tiao", "tong", "wan"]
const RANKS := [1, 2, 3, 4, 5, 6, 7, 8, 9]
const COPIES_PER_TILE := 4
const STARTING_SCORE := 0
const AI_LEVEL_LABELS := ["初级", "中级", "骨灰级", "作弊级"]
const AI_ASYNC_TIMEOUT_MS := 1000
const AI_REACTION_REVIEW_LIMIT := 24

var current_phase: RoundPhase = RoundPhase.BOOT
var current_dealer_seat: int = 0
var current_turn_seat: int = 0
var players: Array[Dictionary] = []
var wall: Array[Dictionary] = []
var wall_count: int = 0
var discard_pile: Array[Dictionary] = []
var round_winners: Array[int] = []
var previous_dealer_seat: int = -1
var settlement_data: Dictionary = {}
var last_turn_context: Dictionary = {}
var last_gang_context: Dictionary = {}
var pending_qiang_gang_context: Dictionary = {}
var last_draw_tile: Dictionary = {}
var shun_he_locks: Dictionary = {}
var debug_last_message: String = "GameState initialized."
var round_index: int = 1
var rules
var ding_que_resolver
var reaction_resolver
var hu_checker
var score_resolver
var shanten_analyzer
var discard_advisor
var risk_analyzer
var reaction_advisor
var gang_advisor
var ai_tuning_config
var ai_learning_engine
var opening_roll_resolver
var ai_manager
var ai_manual_tuning_overrides: Dictionary = {}
var current_discard_context: Dictionary = {}
var pending_reactions: Array[Dictionary] = []
var ai_level: AILevel = AILevel.ADVANCED
var trainer_history: Array[Dictionary] = []
var human_trainer_hint_enabled: bool = false
var latest_trainer_hint: Dictionary = {}
var latest_trainer_hint_cache_key: String = ""
var ai_decision_metrics: Dictionary = {}
var ai_reaction_review_history: Array[Dictionary] = []
var latest_ai_reaction_review: Dictionary = {}
var self_hu_pass_locks: Dictionary = {}
var opening_roll_data: Dictionary = {}
var opening_roll_pending_completion: bool = false
var mahjong_state
var mahjong_judge
var pending_ai_turn_decision: Dictionary = {}
var pending_ai_reaction_decision: Dictionary = {}
var pending_ai_turn_request_id: int = 0
var pending_ai_reaction_request_id: int = 0
var pending_ai_turn_request_meta: Dictionary = {}
var pending_ai_reaction_request_meta: Dictionary = {}
var ai_chain_debug_history: Array[String] = []
var opening_bao_jiao_pending: bool = false
var opening_bao_jiao_queue: Array[int] = []
var opening_bao_jiao_current_seat: int = -1

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	rules = RuleConfigScript.new(RuleConfigScript.MODE_NEIJIANG_CLASSIC)
	mahjong_state = MahjongStateScript.new()
	mahjong_judge = MahjongJudgeScript.new()
	ding_que_resolver = DingQueResolverScript.new()
	reaction_resolver = ReactionResolverScript.new()
	hu_checker = HuCheckerScript.new()
	score_resolver = ScoreResolverScript.new()
	shanten_analyzer = ShantenAnalyzerScript.new()
	discard_advisor = DiscardAdvisorScript.new()
	risk_analyzer = RiskAnalyzerScript.new()
	reaction_advisor = ReactionAdvisorScript.new()
	gang_advisor = GangAdvisorScript.new()
	ai_tuning_config = AITuningConfigScript.new()
	ai_tuning_config.apply_preset("bone_ash")
	ai_learning_engine = AILearningEngineScript.new()
	ai_learning_engine.load_profile()
	_apply_ai_learning_adjustment()
	opening_roll_resolver = OpeningRollResolverScript.new()
	ai_manager = AIManagerScript.new()
	ai_manager.set_strict_native_runtime_required(true)
	ai_manager.set_prefer_csharp_backend(true)
	_bind_native_csharp_runtime_if_available()
	ai_manager.ai_turn_analysis_ready.connect(_on_ai_turn_analysis_ready)
	ai_manager.ai_reaction_analysis_ready.connect(_on_ai_reaction_analysis_ready)
	start_new_round()


func start_new_round(preserve_dealer: bool = false) -> void:
	current_phase = RoundPhase.TABLE_SETUP
	_reload_ai_learning_for_new_round()
	var previous_players: Array[Dictionary] = players.duplicate(true)
	discard_pile.clear()
	round_winners.clear()
	settlement_data = _create_empty_settlement_data()
	last_turn_context.clear()
	last_gang_context.clear()
	pending_qiang_gang_context.clear()
	last_draw_tile = {}
	shun_he_locks.clear()
	current_discard_context.clear()
	pending_reactions.clear()
	trainer_history.clear()
	latest_trainer_hint.clear()
	ai_decision_metrics = _create_empty_ai_decision_metrics()
	ai_reaction_review_history.clear()
	latest_ai_reaction_review.clear()
	self_hu_pass_locks.clear()
	pending_ai_turn_decision.clear()
	pending_ai_reaction_decision.clear()
	_clear_pending_ai_async_state()
	opening_bao_jiao_pending = false
	opening_bao_jiao_queue.clear()
	opening_bao_jiao_current_seat = -1
	opening_roll_data.clear()
	opening_roll_pending_completion = false
	if preserve_dealer and previous_dealer_seat >= 0:
		current_dealer_seat = previous_dealer_seat
	else:
		current_dealer_seat = _select_initial_dealer()
	current_turn_seat = current_dealer_seat
	players = _create_initial_players(previous_players)
	wall = _build_wall()
	_shuffle_wall()
	wall_count = wall.size()
	_resolve_opening_roll()
	current_phase = RoundPhase.TABLE_SETUP
	debug_last_message = "Round %d ready. Dealer seat=%d is rolling dice." % [
		round_index,
		current_dealer_seat,
	]
	_emit_state_changed()
	opening_roll_started.emit(opening_roll_data.duplicate(true))


func get_debug_snapshot() -> Dictionary:
	var rules_debug: Dictionary = {} if rules == null else rules.to_debug_dict()
	var reaction_summary := ""
	if mahjong_judge != null:
		reaction_summary = mahjong_judge.summarize_candidates(pending_reactions)
	var ai_tuning_debug: Dictionary = {} if ai_tuning_config == null else ai_tuning_config.to_debug_dict()
	return {
		"round_index": round_index,
		"current_phase": current_phase,
		"current_dealer_seat": current_dealer_seat,
		"current_turn_seat": current_turn_seat,
		"wall_count": wall_count,
		"discard_count": discard_pile.size(),
		"winner_count": round_winners.size(),
		"round_winners": round_winners.duplicate(),
		"shun_he_locks": shun_he_locks.duplicate(true),
		"settlement_data": settlement_data.duplicate(true),
		"last_gang_context": last_gang_context.duplicate(true),
		"pending_qiang_gang_context": pending_qiang_gang_context.duplicate(true),
		"debug_last_message": debug_last_message,
		"rules": rules_debug,
		"human_can_discard": can_human_discard(0),
		"human_can_self_hu": can_human_self_hu(0),
		"human_can_add_gang": can_human_add_gang(0),
		"human_can_an_gang": can_human_an_gang(0),
		"human_can_bao_jiao": can_human_bao_jiao(0),
		"human_can_pass_opening_bao_jiao": can_human_pass_opening_bao_jiao(0),
		"human_last_draw_tile_id": _get_last_draw_tile_id_for_seat(0),
		"human_ding_que_pending": is_human_ding_que_pending(0),
		"dealer_ding_que_deferred": _is_dealer_ding_que_deferred(),
		"recent_discard_display": _get_recent_discard_display(),
		"recent_discard_tile_id": _get_recent_discard_tile_id(),
		"recent_draw_display": _get_recent_draw_display(),
		"recent_draw_seat": _get_recent_draw_seat(),
		"reaction_summary": reaction_summary,
		"human_reaction_options": get_human_reaction_options(0),
		"discard_context": current_discard_context.duplicate(true),
		"ai_level_index": int(ai_level),
		"ai_level_name": AI_LEVEL_LABELS[int(ai_level)],
		"ai_tuning_config": ai_tuning_debug,
		"ai_learning_profile": {} if ai_learning_engine == null else ai_learning_engine.get_runtime_summary(),
		"ai_decision_metrics": ai_decision_metrics.duplicate(true),
		"latest_ai_reaction_review": latest_ai_reaction_review.duplicate(true),
		"ai_reaction_review_history": ai_reaction_review_history.duplicate(true),
		"pending_ai_reaction_request_id": pending_ai_reaction_request_id,
		"pending_ai_reaction_request_meta": pending_ai_reaction_request_meta.duplicate(true),
		"pending_ai_reaction_decision": pending_ai_reaction_decision.duplicate(true),
		"pending_ai_turn_request_id": pending_ai_turn_request_id,
		"pending_ai_turn_request_meta": pending_ai_turn_request_meta.duplicate(true),
		"pending_ai_turn_decision": pending_ai_turn_decision.duplicate(true),
		"ai_core_debug": {} if ai_manager == null else ai_manager.get_debug_snapshot(),
		"ai_chain_debug": ai_chain_debug_history.duplicate(),
		"trainer_hint": _get_human_trainer_hint_snapshot() if human_trainer_hint_enabled else {},
		"opening_roll": opening_roll_data.duplicate(true),
		"opening_roll_pending": opening_roll_pending_completion,
		"opening_bao_jiao_pending": opening_bao_jiao_pending,
		"opening_bao_jiao_current_seat": opening_bao_jiao_current_seat,
		"opening_bao_jiao_queue": opening_bao_jiao_queue.duplicate(),
		"players": players.duplicate(true),
	}


func get_ai_level_index() -> int:
	return int(ai_level)


func set_human_trainer_hint_enabled(enabled: bool) -> void:
	human_trainer_hint_enabled = enabled
	if not enabled:
		latest_trainer_hint.clear()
		latest_trainer_hint_cache_key = ""


func set_ai_preset(preset_name: String) -> bool:
	if ai_tuning_config == null:
		return false
	ai_tuning_config.apply_preset(preset_name)
	_apply_ai_runtime_tuning()
	debug_last_message = "AI 参数预设已切换为 %s。" % preset_name
	_emit_state_changed()
	return true


func get_ai_preset_name() -> String:
	return "" if ai_tuning_config == null else str(ai_tuning_config.preset_name)


func _reload_ai_learning_for_new_round() -> void:
	if ai_tuning_config == null or ai_learning_engine == null:
		return
	ai_learning_engine.load_profile()
	ai_tuning_config.apply_preset(str(ai_tuning_config.preset_name))
	_apply_ai_runtime_tuning()


func _apply_ai_learning_adjustment() -> void:
	if ai_tuning_config == null or ai_learning_engine == null:
		return
	if not bool(ai_tuning_config.auto_learning_enabled):
		return
	ai_tuning_config.apply_learning_adjustment(ai_learning_engine.get_profile())


func _apply_ai_manual_tuning() -> void:
	if ai_tuning_config == null:
		return
	for key in ai_manual_tuning_overrides.keys():
		var value: int = int(ai_manual_tuning_overrides.get(key, 0))
		match str(key):
			"lookahead_candidate_count":
				ai_tuning_config.lookahead_candidate_count = clampi(value, 2, 5)
			"lookahead_draw_samples":
				ai_tuning_config.lookahead_draw_samples = clampi(value, 4, 12)
			"add_gang_min_score":
				ai_tuning_config.add_gang_min_score = clampi(value, 8, 50)
			"an_gang_min_score":
				ai_tuning_config.an_gang_min_score = clampi(value, 12, 60)
			"intermediate_top_pick_count":
				ai_tuning_config.intermediate_top_pick_count = clampi(value, 1, 3)
			"attack_tendency":
				ai_tuning_config.attack_tendency = clampi(value, -3, 3)
			"defense_tendency":
				ai_tuning_config.defense_tendency = clampi(value, -3, 3)
			"fast_ting_priority":
				ai_tuning_config.fast_ting_priority = clampi(value, 0, 4)
			"self_draw_priority":
				ai_tuning_config.self_draw_priority = clampi(value, 0, 4)
			"forced_cleanup_tendency":
				ai_tuning_config.forced_cleanup_tendency = clampi(value, 0, 4)
			"big_hand_tendency":
				ai_tuning_config.big_hand_tendency = clampi(value, 0, 4)
			"opponent_read_tendency":
				ai_tuning_config.opponent_read_tendency = clampi(value, 0, 4)


func _apply_ai_runtime_tuning() -> void:
	_apply_ai_learning_adjustment()
	_apply_ai_manual_tuning()


func set_ai_tuning_value(key: String, value: int) -> bool:
	if ai_tuning_config == null:
		return false
	match key:
		"lookahead_candidate_count":
			ai_manual_tuning_overrides[key] = clampi(value, 2, 5)
		"lookahead_draw_samples":
			ai_manual_tuning_overrides[key] = clampi(value, 4, 12)
		"add_gang_min_score":
			ai_manual_tuning_overrides[key] = clampi(value, 8, 50)
		"an_gang_min_score":
			ai_manual_tuning_overrides[key] = clampi(value, 12, 60)
		"intermediate_top_pick_count":
			ai_manual_tuning_overrides[key] = clampi(value, 1, 3)
		"attack_tendency":
			ai_manual_tuning_overrides[key] = clampi(value, -3, 3)
		"defense_tendency":
			ai_manual_tuning_overrides[key] = clampi(value, -3, 3)
		"fast_ting_priority":
			ai_manual_tuning_overrides[key] = clampi(value, 0, 4)
		"self_draw_priority":
			ai_manual_tuning_overrides[key] = clampi(value, 0, 4)
		"forced_cleanup_tendency":
			ai_manual_tuning_overrides[key] = clampi(value, 0, 4)
		"big_hand_tendency":
			ai_manual_tuning_overrides[key] = clampi(value, 0, 4)
		"opponent_read_tendency":
			ai_manual_tuning_overrides[key] = clampi(value, 0, 4)
		_:
			return false
	_apply_ai_runtime_tuning()
	debug_last_message = "AI 调参已更新：%s = %d" % [key, int(ai_manual_tuning_overrides.get(key, value))]
	_emit_state_changed()
	return true


func set_ai_prefer_csharp_backend(enabled: bool) -> bool:
	if ai_manager == null:
		return false
	ai_manager.set_prefer_csharp_backend(enabled)
	debug_last_message = "AI 计算后端偏好已切换为 %s。" % ("C# 主判牌" if enabled else "GDScript")
	_emit_state_changed()
	return true


func set_ai_csharp_host_mode_enabled(enabled: bool, port: int = 38581) -> bool:
	if ai_manager == null:
		return false
	ai_manager.set_csharp_host_mode_enabled(enabled, port)
	debug_last_message = "C# 常驻 Host 模式已%s（端口 %d）。" % [("开启" if enabled else "关闭"), port]
	_emit_state_changed()
	return true


func set_ai_auto_learning_enabled(enabled: bool) -> bool:
	if ai_tuning_config == null:
		return false
	ai_tuning_config.auto_learning_enabled = enabled
	ai_tuning_config.apply_preset(str(ai_tuning_config.preset_name))
	ai_tuning_config.auto_learning_enabled = enabled
	_apply_ai_runtime_tuning()
	debug_last_message = "AI 自动学习调参已%s。" % ("开启" if enabled else "关闭")
	_emit_state_changed()
	return true


func set_ai_endgame_absolute_defense_enabled(enabled: bool) -> bool:
	if ai_tuning_config == null:
		return false
	ai_tuning_config.endgame_absolute_defense = enabled
	_apply_ai_runtime_tuning()
	debug_last_message = "AI 尾盘绝对防炮已%s。" % ("开启" if enabled else "关闭")
	_emit_state_changed()
	return true


func apply_bone_ash_recommended_tuning() -> bool:
	if ai_tuning_config == null:
		return false
	ai_manual_tuning_overrides.clear()
	ai_tuning_config.apply_preset("bone_ash")
	_apply_ai_runtime_tuning()
	debug_last_message = "AI 已恢复骨灰推荐参数。"
	_emit_state_changed()
	return true


func reset_ai_tuning_overrides() -> bool:
	if ai_tuning_config == null:
		return false
	ai_manual_tuning_overrides.clear()
	ai_tuning_config.apply_preset(str(ai_tuning_config.preset_name))
	_apply_ai_runtime_tuning()
	debug_last_message = "AI 手动调参已恢复为预设 + 学习参数。"
	_emit_state_changed()
	return true


func _update_ai_learning_after_round(score_changes: Dictionary) -> void:
	if ai_learning_engine == null:
		return
	if players.is_empty() or bool(players[0].get("is_ai", false)):
		return
	var round_result := {
		"round_index": round_index,
		"end_reason": str(settlement_data.get("end_reason", "")),
		"score_changes": score_changes.duplicate(true),
		"win_events": settlement_data.get("win_events", []).duplicate(true),
		"gang_events": settlement_data.get("gang_events", []).duplicate(true),
		"winner_seats": settlement_data.get("winner_seats", []).duplicate(),
		"ai_decision_metrics": ai_decision_metrics.duplicate(true),
		"latest_ai_reaction_review": latest_ai_reaction_review.duplicate(true),
		"ai_reaction_review_history": ai_reaction_review_history.duplicate(true),
		"ai_core_debug": {} if ai_manager == null else ai_manager.get_debug_snapshot(),
	}
	ai_learning_engine.record_human_round(round_result)
	ai_tuning_config.apply_preset(str(ai_tuning_config.preset_name))
	_apply_ai_runtime_tuning()
	debug_last_message = "AI 已记录本局结果，并按最新学习数据更新参数。"


func set_ai_level(level: int) -> bool:
	if level < int(AILevel.BEGINNER) or level > int(AILevel.CHEATING):
		return false
	ai_level = level
	for player in players:
		if bool(player.get("is_ai", false)):
			player["ai_level"] = int(ai_level)
	debug_last_message = "AI 难度已切换为 %s。" % AI_LEVEL_LABELS[int(ai_level)]
	_emit_state_changed()
	return true


func complete_opening_roll() -> bool:
	if current_phase != RoundPhase.TABLE_SETUP or not opening_roll_pending_completion:
		return false
	_deal_initial_hands()
	wall_count = wall.size()
	opening_roll_pending_completion = false
	debug_last_message = "骰子结果 %d + %d = %d，判定%s，开始发牌。" % [
		int(opening_roll_data.get("die_a", 0)),
		int(opening_roll_data.get("die_b", 0)),
		int(opening_roll_data.get("total", 0)),
		str(opening_roll_data.get("opening_side_label", "自家")),
	]
	_enter_ding_que_phase()
	return true


func choose_ding_que(seat: int, suit: String) -> bool:
	if not rules.requires_ding_que_phase():
		return false
	if not rules.requires_ding_que_phase():
		return false
	if current_phase != RoundPhase.DING_QUE:
		return false
	if suit not in _active_suits():
		return false
	if seat < 0 or seat >= players.size():
		return false
	if players[seat]["ding_que"] != "":
		return false
	if seat == current_dealer_seat and not _must_dealer_choose_now():
		return false

	players[seat]["ding_que"] = suit
	debug_last_message = "%s 选择缺门：%s" % [_seat_display_name(seat), _suit_display_name(suit)]
	_emit_state_changed()
	_complete_ding_que_if_ready()
	return true


func get_human_ding_que_options(seat: int) -> Array:
	if not rules.requires_ding_que_phase():
		return []
	if seat < 0 or seat >= players.size():
		return []
	if players[seat]["ding_que"] != "":
		return []
	if seat == current_dealer_seat and not _must_dealer_choose_now():
		return []
	return _active_suits()


func is_human_ding_que_pending(seat: int) -> bool:
	if not rules.requires_ding_que_phase():
		return false
	if current_phase != RoundPhase.DING_QUE:
		return false
	if seat < 0 or seat >= players.size():
		return false
	if players[seat]["is_ai"] or players[seat]["ding_que"] != "":
		return false
	if seat != current_dealer_seat:
		return true
	return _must_dealer_choose_now()


func can_human_discard(seat: int) -> bool:
	if current_phase != RoundPhase.DISCARD:
		return false
	if seat < 0 or seat >= players.size():
		return false
	return current_turn_seat == seat and not players[seat]["is_ai"] and not players[seat]["has_won"]


func is_ai_turn_ready() -> bool:
	if current_phase != RoundPhase.DISCARD:
		return false
	if opening_bao_jiao_pending:
		return false
	if current_turn_seat < 0 or current_turn_seat >= players.size():
		return false
	return players[current_turn_seat]["is_ai"] and not players[current_turn_seat]["has_won"]


func is_ai_reaction_pending() -> bool:
	if current_phase != RoundPhase.REACTION:
		return false
	for candidate in pending_reactions:
		var seat: int = candidate["seat"]
		if seat >= 0 and seat < players.size() and players[seat]["is_ai"]:
			return true
	return false


func get_player_hand_tiles(seat: int) -> Array:
	if seat < 0 or seat >= players.size():
		return []
	return players[seat]["hand_tiles"].duplicate(true)


func _build_player_state(seat: int) -> Dictionary:
	if seat < 0 or seat >= players.size():
		return {}
	return mahjong_state.build_player_state(players[seat])


func _build_table_state() -> Dictionary:
	return mahjong_state.build_table_state(
		players,
		current_turn_seat,
		int(current_phase),
		current_discard_context,
		last_draw_tile,
		pending_reactions,
		wall_count
	)


func can_human_self_hu(seat: int) -> bool:
	if current_phase != RoundPhase.DISCARD:
		return false
	if seat < 0 or seat >= players.size():
		return false
	if current_turn_seat != seat or players[seat]["has_won"]:
		return false
	if not _can_seat_self_hu_now(seat):
		return false
	var lock_key := str(seat)
	if self_hu_pass_locks.has(lock_key):
		var locked_tile_id := int(self_hu_pass_locks.get(lock_key, -1))
		if locked_tile_id == _get_last_draw_tile_id_for_seat(seat):
			return false
	return true


func can_human_add_gang(seat: int) -> bool:
	if current_phase != RoundPhase.DISCARD:
		return false
	if seat < 0 or seat >= players.size():
		return false
	if current_turn_seat != seat or players[seat]["has_won"]:
		return false
	return _find_add_gang_option(seat).size() > 0


func can_human_an_gang(seat: int) -> bool:
	if current_phase != RoundPhase.DISCARD:
		return false
	if seat < 0 or seat >= players.size():
		return false
	if current_turn_seat != seat or players[seat]["has_won"]:
		return false
	return _find_an_gang_option(seat).size() > 0


func _can_seat_self_hu_now(seat: int) -> bool:
	if seat < 0 or seat >= players.size():
		return false
	if current_phase != RoundPhase.DISCARD:
		return false
	if current_turn_seat != seat or players[seat]["has_won"]:
		return false
	if _get_last_draw_tile_id_for_seat(seat) == -1:
		return false
	return mahjong_judge.can_player_self_hu(_build_player_state(seat), rules)


func can_human_bao_jiao(seat: int) -> bool:
	if not bool(rules.enable_bao_jiao):
		return false
	if current_phase != RoundPhase.DISCARD:
		return false
	if seat < 0 or seat >= players.size():
		return false
	var player: Dictionary = players[seat]
	if bool(player.get("has_won", false)) or bool(player.get("bao_jiao", false)):
		return false
	if not Array(player.get("melds", [])).is_empty():
		return false
	if not Array(player.get("discards", [])).is_empty():
		return false
	if rules != null and bool(rules.is_neijiang_mode()):
		if seat == current_dealer_seat:
			return false
		if opening_bao_jiao_pending:
			if opening_bao_jiao_current_seat != seat:
				return false
		elif bool(player.get("opening_bao_jiao_reviewed", false)):
			return false
		if not discard_pile.is_empty():
			return false
		if int(player.get("hand_count", 0)) != 13:
			return false
		return not _build_bao_jiao_plan(seat).is_empty()
	if current_turn_seat != seat:
		return false
	return not _build_bao_jiao_plan(seat).is_empty()


func can_human_pass_opening_bao_jiao(seat: int) -> bool:
	if not opening_bao_jiao_pending:
		return false
	if current_phase != RoundPhase.DISCARD:
		return false
	if seat < 0 or seat >= players.size():
		return false
	return opening_bao_jiao_current_seat == seat and not bool(players[seat].get("is_ai", false))


func get_human_reaction_options(seat: int) -> Dictionary:
	var candidate: Dictionary = _get_reaction_candidate_for_seat(seat)
	if candidate.is_empty():
		return {
			"can_peng": false,
			"can_gang": false,
			"can_hu": false,
			"can_pass": false,
		}
	var bao_jiao_locked := _is_bao_jiao_reaction_locked(seat)
	var reaction_tile: Dictionary = current_discard_context.get("tile", {})
	var ding_que_claim_blocked := not reaction_tile.is_empty() and _is_ding_que_tile_for_seat(seat, reaction_tile)
	var can_peng := false if bao_jiao_locked else bool(candidate["can_peng"])
	var can_gang := false if bao_jiao_locked else bool(candidate["can_gang"])
	if ding_que_claim_blocked:
		can_peng = false
		can_gang = false
	var can_hu := bool(candidate["can_hu"])
	return {
		"can_peng": can_peng and not _has_higher_priority_candidate_than(seat, "peng"),
		"can_gang": can_gang and not _has_higher_priority_candidate_than(seat, "gang"),
		"can_hu": can_hu,
		"can_pass": true,
	}


func execute_human_bao_jiao(seat: int) -> bool:
	if not can_human_bao_jiao(seat):
		return false
	var plan: Dictionary = _build_bao_jiao_plan(seat)
	if plan.is_empty():
		return false
	var discard_tile: Dictionary = plan.get("discard_tile", {})
	if not discard_tile.is_empty():
		if not _discard_tile_internal(seat, int(discard_tile.get("id", -1))):
			return false
	players[seat]["bao_jiao"] = true
	players[seat]["bao_jiao_ting_tiles"] = plan.get("ting_tiles", []).duplicate(true)
	players[seat]["bao_gang_tiles"] = plan.get("bao_gang_keys", []).duplicate(true)
	players[seat]["rule_marks"] = _build_rule_marks_for_player(players[seat])
	var bao_gang_count := int(Array(plan.get("bao_gang_keys", [])).size())
	var bao_gang_suffix := "，报%d杠" % bao_gang_count if bao_gang_count > 0 else ""
	if discard_tile.is_empty():
		debug_last_message = "%s 开局报叫%s，听 %s。" % [
			_seat_display_name(seat),
			bao_gang_suffix,
			_format_tile_name_list(plan.get("ting_tiles", []))
		]
	else:
		debug_last_message = "%s 报叫%s，打出 %s，听 %s。" % [
			_seat_display_name(seat),
			bao_gang_suffix,
			str(discard_tile.get("display_name", "?")),
			_format_tile_name_list(plan.get("ting_tiles", []))
		]
	_emit_state_changed()
	if opening_bao_jiao_pending and opening_bao_jiao_current_seat == seat:
		_mark_opening_bao_jiao_reviewed(seat)
		_process_opening_bao_jiao_queue()
	return true


func pass_human_opening_bao_jiao(seat: int) -> bool:
	if not can_human_pass_opening_bao_jiao(seat):
		return false
	_mark_opening_bao_jiao_reviewed(seat)
	debug_last_message = "%s 放弃开局报叫/报杠，庄家首打前继续询问下一家。" % _seat_display_name(seat)
	_process_opening_bao_jiao_queue()
	return true


func advance_to_next_round() -> bool:
	if current_phase != RoundPhase.SETTLEMENT:
		return false
	previous_dealer_seat = _resolve_next_dealer_seat()
	round_index += 1
	start_new_round(true)
	return true


func execute_human_peng(seat: int) -> bool:
	if current_phase != RoundPhase.REACTION:
		debug_last_message = "当前不在响应阶段，不能碰。"
		return false
	if _is_bao_jiao_reaction_locked(seat):
		debug_last_message = "%s 已报叫，不能碰牌。" % _seat_display_name(seat)
		return false
	var candidate: Dictionary = _get_reaction_candidate_for_seat(seat)
	if candidate.is_empty() or not candidate["can_peng"]:
		debug_last_message = "%s 当前没有可碰候选。" % _seat_display_name(seat)
		return false
	if _has_higher_priority_candidate_than(seat, "peng"):
		debug_last_message = "%s 碰牌需等待更高优先级响应处理。" % _seat_display_name(seat)
		return false
	return _execute_peng(seat)


func execute_human_gang(seat: int) -> bool:
	if current_phase != RoundPhase.REACTION:
		return false
	if _is_bao_jiao_reaction_locked(seat):
		return false
	var candidate: Dictionary = _get_reaction_candidate_for_seat(seat)
	if candidate.is_empty() or not candidate["can_gang"]:
		return false
	if _has_higher_priority_candidate_than(seat, "gang"):
		return false
	return _execute_gang(seat)


func execute_human_hu(seat: int) -> bool:
	if current_phase != RoundPhase.REACTION:
		return false
	var candidate: Dictionary = _get_reaction_candidate_for_seat(seat)
	if candidate.is_empty() or not candidate["can_hu"]:
		return false
	return _execute_hu_on_discard(seat)


func execute_human_self_hu(seat: int) -> bool:
	if not can_human_self_hu(seat):
		return false
	return _execute_self_draw_hu(seat)


func pass_human_self_hu(seat: int) -> bool:
	if current_phase != RoundPhase.DISCARD:
		return false
	if not can_human_discard(seat):
		return false
	var draw_tile_id := _get_last_draw_tile_id_for_seat(seat)
	if draw_tile_id == -1:
		return false
	if not mahjong_judge.can_player_self_hu(_build_player_state(seat), rules):
		return false
	self_hu_pass_locks[str(seat)] = draw_tile_id
	debug_last_message = "%s 本巡放弃自摸，需继续出牌。" % _seat_display_name(seat)
	_emit_state_changed()
	return true


func execute_human_add_gang(seat: int) -> bool:
	if not can_human_add_gang(seat):
		return false
	return _start_add_gang(seat)


func execute_human_an_gang(seat: int) -> bool:
	if not can_human_an_gang(seat):
		return false
	return _execute_an_gang(seat)


func pass_human_reaction(seat: int) -> bool:
	if current_phase != RoundPhase.REACTION:
		return false
	var candidate: Dictionary = _get_reaction_candidate_for_seat(seat)
	if candidate.is_empty():
		return false
	_remove_reaction_candidate_for_seat(seat)
	_apply_passed_hu_lock_if_needed(seat, candidate)
	debug_last_message = "%s 选择过牌。剩余可响应：%s" % [_seat_display_name(seat), mahjong_judge.summarize_candidates(pending_reactions)]
	if pending_reactions.is_empty():
		if str(current_discard_context.get("reaction_type", "discard")) == "qiang_gang_hu":
			_finalize_qiang_gang_after_hu_or_pass()
		else:
			_finalize_reaction_after_hu_or_pass()
	else:
		_emit_state_changed()
	return true


func discard_tile_by_id(seat: int, tile_id: int) -> bool:
	if not can_human_discard(seat):
		return false
	if bool(players[seat].get("bao_jiao", false)) and tile_id != _get_last_draw_tile_id_for_seat(seat):
		debug_last_message = "报叫后需保持听口，当前仅允许打出新摸牌。"
		_emit_state_changed()
		return false
	return _discard_tile_internal(seat, tile_id)


func run_ai_turn() -> bool:
	if not is_ai_turn_ready():
		return false
	_pump_ai_background_requests()

	var decision: Dictionary = _get_or_prepare_ai_turn_decision()
	if decision.is_empty():
		return false
	pending_ai_turn_decision.clear()
	_clear_pending_ai_turn_request()
	return _execute_ai_turn_decision(decision)


func prepare_ai_turn_decision() -> bool:
	if not is_ai_turn_ready():
		return false
	_pump_ai_background_requests()
	if not _get_or_prepare_ai_turn_decision().is_empty():
		return true
	return _is_pending_ai_turn_request_valid()


func prepare_ai_reaction_decision() -> bool:
	if not is_ai_reaction_pending():
		return false
	_pump_ai_background_requests()
	if not _get_or_prepare_ai_reaction_decision().is_empty():
		return true
	return _is_pending_ai_reaction_request_valid()


func _get_or_prepare_ai_turn_decision() -> Dictionary:
	if _is_pending_ai_turn_decision_valid():
		return pending_ai_turn_decision.duplicate(true)
	if _is_pending_ai_turn_request_valid() and _has_native_csharp_runtime():
		_clear_pending_ai_turn_request()
	if _is_pending_ai_turn_request_valid():
		return {}
	var inline_decision := {}
	if _has_native_csharp_runtime():
		inline_decision = _build_ai_turn_decision()
		if not inline_decision.is_empty():
			pending_ai_turn_decision = inline_decision
			return pending_ai_turn_decision.duplicate(true)
		return {}
	if OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web"):
		debug_last_message = "C# AI 运行时未就绪，严格模式下暂停 AI 出牌。"
		return {}
	_start_ai_turn_background_request()
	return {}


func _is_pending_ai_turn_decision_valid() -> bool:
	if pending_ai_turn_decision.is_empty():
		return false
	return int(pending_ai_turn_decision.get("round_index", -1)) == round_index \
		and int(pending_ai_turn_decision.get("seat", -1)) == current_turn_seat \
		and int(pending_ai_turn_decision.get("phase", -1)) == int(current_phase) \
		and int(pending_ai_turn_decision.get("wall_count", -1)) == wall_count \
		and int(pending_ai_turn_decision.get("hand_count", -1)) == int(players[current_turn_seat].get("hand_count", -1))


func _is_pending_ai_turn_request_valid() -> bool:
	if pending_ai_turn_request_id <= 0 or pending_ai_turn_request_meta.is_empty():
		return false
	return int(pending_ai_turn_request_meta.get("round_index", -1)) == round_index \
		and int(pending_ai_turn_request_meta.get("seat", -1)) == current_turn_seat \
		and int(pending_ai_turn_request_meta.get("phase", -1)) == int(current_phase) \
		and int(pending_ai_turn_request_meta.get("wall_count", -1)) == wall_count \
		and int(pending_ai_turn_request_meta.get("hand_count", -1)) == int(players[current_turn_seat].get("hand_count", -1))


func _build_ai_turn_decision(force_lightweight: bool = false) -> Dictionary:
	if not is_ai_turn_ready():
		_record_ai_chain_debug("turn_build_skip_not_ready phase=%s turn=%s" % [str(current_phase), str(current_turn_seat)])
		return {}
	var seat: int = current_turn_seat
	var base := {
		"round_index": round_index,
		"seat": seat,
		"phase": int(current_phase),
		"wall_count": wall_count,
		"hand_count": int(players[seat].get("hand_count", 0)),
	}
	var table_state := _build_table_state()
	var player_state := _build_player_state(seat)
	_record_ai_chain_debug("turn_build_start seat=%d hand=%d wall=%d native=%s" % [
		seat,
		int(players[seat].get("hand_count", 0)),
		wall_count,
		str(_has_native_csharp_runtime()),
	])
	var allow_cheat: bool = int(players[seat].get("ai_level", int(ai_level))) == int(AILevel.CHEATING)
	var self_action: Dictionary = _build_ai_self_action_decision(seat, player_state, table_state)
	if not self_action.is_empty():
		for key in self_action.keys():
			base[key] = self_action[key]
		return base
	var analysis: Dictionary = {}
	if ai_manager != null:
		analysis = ai_manager.analyze_turn_lightweight(player_state, table_state, rules, ai_tuning_config, hu_checker, risk_analyzer, allow_cheat) if force_lightweight else ai_manager.analyze_turn(player_state, table_state, rules, ai_tuning_config, hu_checker, risk_analyzer, allow_cheat)
	if analysis.is_empty():
		var native_error := ""
		if ai_manager != null:
			native_error = str(ai_manager.get_backend_status().get("last_native_turn_error", ""))
		debug_last_message = "C# AI 未返回有效出牌结果：%s" % (native_error if native_error != "" else "empty_analysis")
		_record_ai_chain_debug("turn_build_empty_analysis seat=%d err=%s" % [seat, debug_last_message])
		return {}
	var selected_tile: Dictionary = analysis.get("recommended", {}).get("tile", {})
	if selected_tile.is_empty():
		debug_last_message = "C# AI 已返回，但推荐牌未映射到当前手牌。"
		_record_ai_chain_debug("turn_build_map_failed seat=%d analysis=%s" % [seat, JSON.stringify(analysis).left(900)])
		return {}
	_record_ai_chain_debug("turn_build_ok seat=%d tile=%s id=%d backend=%s" % [
		seat,
		str(selected_tile.get("display_name", selected_tile.get("tile_name", "?"))),
		int(selected_tile.get("id", -1)),
		str(analysis.get("backend_mode", "")),
	])
	base["action"] = "discard"
	base["tile_id"] = int(selected_tile.get("id", -1))
	base["analysis"] = analysis.duplicate(true)
	return base


func _build_ai_self_action_decision(seat: int, player_state: Dictionary, table_state: Dictionary) -> Dictionary:
	if ai_manager == null:
		return {}
	var an_options := _find_all_an_gang_options(seat)
	var add_options := _find_all_add_gang_options(seat)
	var an_types := _tile_types_from_options(an_options, "tiles")
	var add_types := _tile_types_from_options(add_options, "tile")
	var add_qiang_counts := _add_gang_qiang_counts_by_tile_type(seat, add_options)
	var can_self_hu := _can_seat_self_hu_now(seat)
	if not can_self_hu and an_types.is_empty() and add_types.is_empty():
		return {}
	var csharp_decision: Dictionary = ai_manager.analyze_self_action(player_state, table_state, rules, can_self_hu, an_types, add_types, add_qiang_counts)
	if csharp_decision.is_empty():
		debug_last_message = "C# AI 未返回有效自摸动作结果，当前等待重试。"
		return {}
	var action := str(csharp_decision.get("action", "pass")).strip_edges().to_lower()
	if action == "hu" and can_self_hu:
		return {
			"action": "self_hu",
			"analysis": csharp_decision.duplicate(true),
		}
	if action == "gang":
		var tile_type := int(csharp_decision.get("tile_type", -1))
		var subtype := str(csharp_decision.get("gang_subtype", csharp_decision.get("gangSubtype", "")))
		var option: Dictionary = {}
		if subtype == "add_gang":
			option = _find_option_by_tile_type(add_options, tile_type, "tile")
			if not option.is_empty():
				return {
					"action": "add_gang",
					"gang_option": option.duplicate(true),
					"analysis": csharp_decision.duplicate(true),
				}
		if subtype == "an_gang" or option.is_empty():
			option = _find_option_by_tile_type(an_options, tile_type, "tiles")
			if not option.is_empty():
				return {
					"action": "an_gang",
					"gang_option": option.duplicate(true),
					"analysis": csharp_decision.duplicate(true),
				}
	return {}


func _add_gang_qiang_counts_by_tile_type(seat: int, add_options: Array) -> Dictionary:
	var result := {}
	for option in add_options:
		var tile: Dictionary = option.get("tile", {})
		var tile_type := _neijiang_tile_type(tile)
		if tile_type < 0:
			continue
		result[str(tile_type)] = _build_qiang_gang_hu_candidates(seat, tile).size()
	return result


func _build_ai_turn_forced_decision() -> Dictionary:
	return {}


func _execute_ai_turn_decision(decision: Dictionary) -> bool:
	if not is_ai_turn_ready():
		_record_ai_chain_debug("turn_execute_skip_not_ready decision=%s phase=%s turn=%s" % [
			JSON.stringify(decision).left(500),
			str(current_phase),
			str(current_turn_seat),
		])
		return false
	var seat: int = int(decision.get("seat", -1))
	if seat != current_turn_seat:
		_record_ai_chain_debug("turn_execute_seat_mismatch decision_seat=%d turn=%d" % [seat, current_turn_seat])
		return false
	match str(decision.get("action", "")):
		"self_hu":
			_record_ai_metric("self_hu_actions")
			return _execute_self_draw_hu(seat)
		"bao_jiao":
			_record_ai_metric("bao_jiao_actions")
			return execute_human_bao_jiao(seat)
		"an_gang":
			_record_ai_metric("an_gang_attempts")
			return _execute_an_gang(seat, decision.get("gang_option", {}))
		"add_gang":
			_record_ai_metric("add_gang_attempts")
			return _start_add_gang(seat, decision.get("gang_option", {}))
		"discard":
			var tile_id := int(decision.get("tile_id", -1))
			var ok := _discard_tile_internal(seat, tile_id)
			_record_ai_chain_debug("turn_execute_discard seat=%d tile_id=%d ok=%s msg=%s" % [
				seat,
				tile_id,
				str(ok),
				debug_last_message,
			])
			return ok
	_record_ai_chain_debug("turn_execute_unknown_action decision=%s" % JSON.stringify(decision).left(500))
	return false


func run_ai_reaction() -> bool:
	if current_phase != RoundPhase.REACTION:
		return false

	var prepared: Dictionary = _get_or_prepare_ai_reaction_decision()
	if prepared.is_empty():
		return false

	var candidate: Dictionary = prepared.get("candidate", {})
	var decision: Dictionary = prepared.get("decision", {})
	var seat: int = int(prepared.get("seat", -1))
	if candidate.is_empty() or decision.is_empty() or seat < 0 or seat >= players.size():
		pending_ai_reaction_decision.clear()
		_clear_pending_ai_reaction_request()
		return false
	pending_ai_reaction_decision.clear()
	_clear_pending_ai_reaction_request()
	var requested_action := str(decision.get("action", "pass")).strip_edges().to_lower()
	var resolved_action := _resolve_ai_reaction_action(seat, candidate, requested_action)
	_record_ai_metric("reaction_total")
	_record_ai_metric("reaction_" + resolved_action)
	_record_ai_reaction_review(seat, candidate, decision, requested_action, resolved_action)
	var executed := false
	if resolved_action == "hu":
		executed = _execute_hu_on_discard(seat)
	elif resolved_action == "gang":
		executed = _execute_gang(seat)
	elif resolved_action == "peng":
		executed = _execute_peng(seat)
	else:
		return _pass_ai_reaction(seat)
	if executed:
		return true
	debug_last_message = "AI %s 响应 %s 执行失败，已自动过牌以继续牌局。" % [
		_seat_display_name(seat),
		{"hu": "胡", "gang": "杠", "peng": "碰"}.get(resolved_action, resolved_action),
	]
	return _pass_ai_reaction(seat)


func _get_or_prepare_ai_reaction_decision() -> Dictionary:
	if _is_pending_ai_reaction_decision_valid():
		return pending_ai_reaction_decision.duplicate(true)
	if _is_pending_ai_reaction_request_valid():
		return {}
	if OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web"):
		if not _has_native_csharp_runtime():
			debug_last_message = "C# AI 运行时未就绪，严格模式下暂停 AI 响应。"
			return {}
	if _start_ai_reaction_background_request() and _is_pending_ai_reaction_decision_valid():
		return pending_ai_reaction_decision.duplicate(true)
	return {}


func _is_pending_ai_reaction_decision_valid() -> bool:
	if pending_ai_reaction_decision.is_empty():
		return false
	var tile: Dictionary = current_discard_context.get("tile", {})
	return int(pending_ai_reaction_decision.get("round_index", -1)) == round_index \
		and int(pending_ai_reaction_decision.get("phase", -1)) == int(current_phase) \
		and int(pending_ai_reaction_decision.get("source_seat", -1)) == int(current_discard_context.get("source_seat", -1)) \
		and int(pending_ai_reaction_decision.get("tile_id", -1)) == int(tile.get("id", -1)) \
		and int(pending_ai_reaction_decision.get("pending_count", -1)) == pending_reactions.size()


func _is_pending_ai_reaction_request_valid() -> bool:
	if pending_ai_reaction_request_id <= 0 or pending_ai_reaction_request_meta.is_empty():
		return false
	if _is_pending_ai_reaction_request_stale():
		debug_last_message = "C# AI 响应计算超时，已重新请求。"
		_clear_pending_ai_reaction_request()
		return false
	var tile: Dictionary = current_discard_context.get("tile", {})
	return int(pending_ai_reaction_request_meta.get("round_index", -1)) == round_index 		and int(pending_ai_reaction_request_meta.get("phase", -1)) == int(current_phase) 		and int(pending_ai_reaction_request_meta.get("source_seat", -1)) == int(current_discard_context.get("source_seat", -1)) 		and int(pending_ai_reaction_request_meta.get("tile_id", -1)) == int(tile.get("id", -1)) 		and int(pending_ai_reaction_request_meta.get("pending_count", -1)) == pending_reactions.size()


func _is_pending_ai_reaction_request_stale() -> bool:
	var started_at_ms := int(pending_ai_reaction_request_meta.get("started_at_ms", 0))
	if started_at_ms <= 0:
		return false
	return maxi(0, Time.get_ticks_msec() - started_at_ms) > 2200


func _build_ai_reaction_decision(force_lightweight: bool = false) -> Dictionary:
	if current_phase != RoundPhase.REACTION:
		return {}
	var candidate: Dictionary = _get_next_ai_reaction_candidate()
	if candidate.is_empty():
		return {}
	var seat: int = int(candidate.get("seat", -1))
	if seat < 0 or seat >= players.size():
		return {}
	var allow_cheat: bool = int(players[seat].get("ai_level", int(ai_level))) == int(AILevel.CHEATING)
	var player_state := _build_player_state(seat)
	var table_state := _build_table_state()
	var decision: Dictionary = {}
	if ai_manager != null:
		decision = ai_manager.analyze_reaction_lightweight(candidate, player_state, table_state, current_discard_context, rules, ai_tuning_config, hu_checker, allow_cheat) if force_lightweight else ai_manager.analyze_reaction(candidate, player_state, table_state, current_discard_context, rules, ai_tuning_config, hu_checker, allow_cheat)
	if decision.is_empty():
		debug_last_message = "C# AI 未返回有效响应结果，当前等待重试。"
		return {}
	var tile: Dictionary = current_discard_context.get("tile", {})
	return {
		"round_index": round_index,
		"phase": int(current_phase),
		"source_seat": int(current_discard_context.get("source_seat", -1)),
		"tile_id": int(tile.get("id", -1)),
		"pending_count": pending_reactions.size(),
		"seat": seat,
		"candidate": candidate.duplicate(true),
		"decision": decision.duplicate(true),
	}


func _start_ai_turn_background_request() -> bool:
	if not is_ai_turn_ready():
		return false
	if _has_native_csharp_runtime():
		var decision := _build_ai_turn_decision()
		if decision.is_empty():
			return false
		pending_ai_turn_decision = decision
		_clear_pending_ai_turn_request()
		return true
	if _is_pending_ai_turn_request_valid():
		return true
	var seat: int = current_turn_seat
	var player_state := _build_player_state(seat)
	var table_state := _build_table_state()
	var allow_cheat: bool = int(players[seat].get("ai_level", int(ai_level))) == int(AILevel.CHEATING)
	var request_id: int = 0 if ai_manager == null else ai_manager.start_turn_analysis_background(
		player_state,
		table_state,
		rules,
		ai_tuning_config,
		hu_checker,
		risk_analyzer,
		allow_cheat
	)
	if request_id <= 0:
		return false
	pending_ai_turn_request_id = request_id
	pending_ai_turn_request_meta = {
		"round_index": round_index,
		"seat": seat,
		"phase": int(current_phase),
		"wall_count": wall_count,
		"hand_count": int(players[seat].get("hand_count", 0)),
		"started_at_ms": Time.get_ticks_msec(),
	}
	return true


func _start_ai_reaction_background_request() -> bool:
	if current_phase != RoundPhase.REACTION:
		return false
	if _has_native_csharp_runtime():
		var decision := _build_ai_reaction_decision()
		if decision.is_empty():
			return false
		pending_ai_reaction_decision = decision
		_clear_pending_ai_reaction_request()
		return true
	if _is_pending_ai_reaction_request_valid():
		return true
	var candidate: Dictionary = _get_next_ai_reaction_candidate()
	if candidate.is_empty():
		return false
	var seat: int = int(candidate.get("seat", -1))
	if seat < 0 or seat >= players.size():
		return false
	var allow_cheat: bool = int(players[seat].get("ai_level", int(ai_level))) == int(AILevel.CHEATING)
	var player_state := _build_player_state(seat)
	var table_state := _build_table_state()
	var request_id: int = 0 if ai_manager == null else ai_manager.start_reaction_analysis_background(
		candidate,
		player_state,
		table_state,
		current_discard_context,
		rules,
		ai_tuning_config,
		hu_checker,
		allow_cheat
	)
	if request_id <= 0:
		return false
	var tile: Dictionary = current_discard_context.get("tile", {})
	pending_ai_reaction_request_id = request_id
	pending_ai_reaction_request_meta = {
		"round_index": round_index,
		"phase": int(current_phase),
		"source_seat": int(current_discard_context.get("source_seat", -1)),
		"tile_id": int(tile.get("id", -1)),
		"pending_count": pending_reactions.size(),
		"seat": seat,
		"candidate": candidate.duplicate(true),
		"started_at_ms": Time.get_ticks_msec(),
	}
	return true


func _discard_tile_internal(seat: int, tile_id: int) -> bool:
	if seat < 0 or seat >= players.size():
		return false
	if players[seat]["has_won"]:
		return false
	if seat == current_dealer_seat and players[seat]["ding_que"] == "":
		if not _lock_dealer_ding_que_from_first_discard(tile_id):
			return false

	var hand_tiles: Array = players[seat]["hand_tiles"]
	var remove_index := -1
	for index in range(hand_tiles.size()):
		if hand_tiles[index]["id"] == tile_id:
			remove_index = index
			break

	if remove_index == -1:
		return false

	var discarded_tile: Dictionary = hand_tiles[remove_index]
	var forced_discard_suit: String = _get_forced_discard_suit(players[seat])
	if forced_discard_suit != "" and str(discarded_tile.get("suit", "")) != forced_discard_suit:
		debug_last_message = "%s 需先打出缺门牌 %s。" % [_seat_display_name(seat), _suit_display_name(forced_discard_suit)]
		_emit_state_changed()
		return false

	hand_tiles.remove_at(remove_index)
	players[seat]["hand_tiles"] = hand_tiles
	players[seat]["hand_count"] = hand_tiles.size()
	players[seat]["discards"].append(discarded_tile)
	discard_pile.append(
		{
			"seat": seat,
			"tile": discarded_tile,
		}
	)
	current_phase = RoundPhase.REACTION
	_prepare_reaction_context(seat, discarded_tile)
	if pending_reactions.is_empty():
		debug_last_message = "%s 打出 %s，无人可响应，轮到下一家。" % [
			_seat_display_name(seat),
			discarded_tile["display_name"],
		]
		_finalize_reaction_without_claim()
	else:
		debug_last_message = "%s 打出 %s。可响应：%s" % [
			_seat_display_name(seat),
			discarded_tile["display_name"],
			mahjong_judge.summarize_candidates(pending_reactions),
		]
	_emit_state_changed()
	return true


func _build_bao_jiao_plan(seat: int) -> Dictionary:
	if seat < 0 or seat >= players.size():
		return {}
	var player: Dictionary = players[seat]
	var hand_tiles: Array = player.get("hand_tiles", [])
	if rules != null and bool(rules.is_neijiang_mode()) and int(player.get("hand_count", hand_tiles.size())) == 13 and discard_pile.is_empty():
		var opening_ting_tiles: Array = hu_checker.get_ting_tiles(hand_tiles, "", rules, int(player.get("melds", []).size()), player.get("melds", []))
		if opening_ting_tiles.is_empty():
			return {}
		var opening_plan := {
			"discard_tile": {},
			"ting_tiles": opening_ting_tiles.duplicate(true),
			"bao_gang_keys": _collect_bao_gang_keys_for_seat(seat, {}),
		}
		opening_plan["plan_score"] = _score_bao_jiao_plan(seat, hand_tiles.duplicate(true), opening_plan)
		return opening_plan
	if hand_tiles.size() % 3 != 2:
		return {}
	var best_plan: Dictionary = {}
	var best_plan_score := -999999
	var seen_keys := {}
	for tile in hand_tiles:
		var key := _tile_key(tile)
		if seen_keys.has(key):
			continue
		seen_keys[key] = true
		var simulated_hand := hand_tiles.duplicate(true)
		for i in range(simulated_hand.size()):
			if int(simulated_hand[i].get("id", -1)) == int(tile.get("id", -1)):
				simulated_hand.remove_at(i)
				break
		var ting_tiles: Array = hu_checker.get_ting_tiles(simulated_hand, "", rules, int(player.get("melds", []).size()), player.get("melds", []))
		if ting_tiles.is_empty():
			continue
		var plan := {
			"discard_tile": tile.duplicate(true),
			"ting_tiles": ting_tiles.duplicate(true),
			"bao_gang_keys": _collect_bao_gang_keys_for_seat(seat, tile),
		}
		var plan_score: int = _score_bao_jiao_plan(seat, simulated_hand, plan)
		plan["plan_score"] = plan_score
		if best_plan.is_empty() or plan_score > best_plan_score:
			best_plan = plan
			best_plan_score = plan_score
	return best_plan


func _collect_bao_gang_keys_for_seat(seat: int, discarded_tile: Dictionary = {}) -> Array:
	var keys: Array = []
	for option in _find_all_add_gang_options(seat):
		var tile: Dictionary = option.get("tile", {})
		if tile.is_empty():
			continue
		if not _can_keep_ting_after_bao_gang(seat, discarded_tile, option, false):
			continue
		var key := _tile_key(tile)
		if not keys.has(key):
			keys.append(key)
	for option in _find_all_an_gang_options(seat):
		var tiles: Array = option.get("tiles", [])
		if tiles.is_empty():
			continue
		if not _can_keep_ting_after_bao_gang(seat, discarded_tile, option, true):
			continue
		var key := _tile_key(tiles[0])
		if not keys.has(key):
			keys.append(key)
	return keys


func _can_keep_ting_after_bao_gang(seat: int, discarded_tile: Dictionary, option: Dictionary, is_an_gang: bool) -> bool:
	if seat < 0 or seat >= players.size():
		return false
	var player: Dictionary = players[seat]
	var base_hand: Array = player.get("hand_tiles", []).duplicate(true)
	if not discarded_tile.is_empty():
		for i in range(base_hand.size()):
			if int(base_hand[i].get("id", -1)) == int(discarded_tile.get("id", -1)):
				base_hand.remove_at(i)
				break
	var base_melds: Array = player.get("melds", []).duplicate(true)
	var base_ting_tiles: Array = hu_checker.get_ting_tiles(base_hand, "", rules, int(base_melds.size()), base_melds)
	if base_ting_tiles.is_empty():
		return false
	var gang_key := ""
	if is_an_gang:
		var gang_tiles: Array = option.get("tiles", [])
		if gang_tiles.size() < 4:
			return false
		gang_key = _tile_key(gang_tiles[0])
		for gang_tile in gang_tiles:
			for i in range(base_hand.size() - 1, -1, -1):
				if int(base_hand[i].get("id", -1)) == int(gang_tile.get("id", -1)):
					base_hand.remove_at(i)
					break
		base_melds.append({
			"type": "gang",
			"from_seat": seat,
			"tiles": gang_tiles.duplicate(true),
			"gang_subtype": "an_gang",
		})
	else:
		var gang_tile: Dictionary = option.get("tile", {})
		var meld_index: int = int(option.get("meld_index", -1))
		if gang_tile.is_empty() or meld_index < 0 or meld_index >= base_melds.size():
			return false
		gang_key = _tile_key(gang_tile)
		for i in range(base_hand.size() - 1, -1, -1):
			if int(base_hand[i].get("id", -1)) == int(gang_tile.get("id", -1)):
				base_hand.remove_at(i)
				break
		var target_meld: Dictionary = base_melds[meld_index].duplicate(true)
		var meld_tiles: Array = target_meld.get("tiles", []).duplicate(true)
		meld_tiles.append(gang_tile.duplicate(true))
		target_meld["tiles"] = meld_tiles
		target_meld["type"] = "gang"
		target_meld["gang_subtype"] = "add_gang"
		base_melds[meld_index] = target_meld
	for suit in _active_suits():
		for rank in RANKS:
			var draw_tile := {
				"id": -1,
				"suit": suit,
				"rank": rank,
				"display_name": "%d%s" % [rank, _suit_display_name(suit)],
			}
			var test_hand: Array = base_hand.duplicate(true)
			test_hand.append(draw_tile)
			for j in range(test_hand.size()):
				var discard_candidate: Dictionary = test_hand[j]
				if _tile_key(discard_candidate) == gang_key:
					continue
				var candidate_hand := test_hand.duplicate(true)
				candidate_hand.remove_at(j)
				var ting_tiles: Array = hu_checker.get_ting_tiles(candidate_hand, "", rules, int(base_melds.size()), base_melds)
				if ting_tiles.is_empty():
					continue
				if is_an_gang:
					return true
				if _is_bao_gang_ting_pattern_preserved(base_ting_tiles, ting_tiles):
					return true
	return false


func _is_bao_gang_allowed(seat: int, tile: Dictionary) -> bool:
	if seat < 0 or seat >= players.size():
		return false
	if not bool(players[seat].get("bao_jiao", false)):
		return true
	return Array(players[seat].get("bao_gang_tiles", [])).has(_tile_key(tile))


func _is_bao_jiao_reaction_locked(seat: int) -> bool:
	if seat < 0 or seat >= players.size():
		return false
	if not bool(players[seat].get("bao_jiao", false)):
		return false
	return true


func _tile_key(tile: Dictionary) -> String:
	return "%s_%d" % [str(tile.get("suit", "")), int(tile.get("rank", 0))]


func _format_tile_name_list(tiles: Array) -> String:
	if tiles.is_empty():
		return "-"
	var parts: Array[String] = []
	for tile in tiles:
		parts.append(str(tile.get("display_name", "?")))
	return "/".join(parts)


func _build_rule_marks_for_player(player: Dictionary) -> Array:
	var marks: Array = []
	if bool(player.get("bao_jiao", false)):
		marks.append("报叫")
	return marks


func _apply_special_rule_marks_for_win(seat: int, win_type: String) -> void:
	if seat < 0 or seat >= players.size():
		return
	if rules == null or not bool(rules.is_neijiang_mode()):
		return
	var marks: Array = players[seat].get("rule_marks", []).duplicate(true)
	if not marks.has("报叫") and bool(players[seat].get("bao_jiao", false)):
		marks.append("报叫")
	if _should_mark_tian_he(seat, win_type):
		if not marks.has("天和"):
			marks.append("天和")
	elif _should_mark_di_hu(seat, win_type):
		if not marks.has("地胡"):
			marks.append("地胡")
	if _should_mark_hai_di(win_type):
		if not marks.has("海底"):
			marks.append("海底")
	players[seat]["rule_marks"] = marks


func _should_mark_tian_he(seat: int, win_type: String) -> bool:
	if win_type != "self_draw" and win_type != "gang_self_draw":
		return false
	if seat != current_dealer_seat:
		return false
	if not discard_pile.is_empty():
		return false
	if not round_winners.is_empty():
		return false
	return str(last_turn_context.get("draw_reason", "")) == "opening_discard"


func _should_mark_di_hu(seat: int, win_type: String) -> bool:
	if seat < 0 or seat >= players.size():
		return false
	if win_type != "discard_win":
		return false
	if not round_winners.is_empty():
		return false
	if _should_mark_tian_he(seat, win_type):
		return false
	if seat == current_dealer_seat:
		return false
	var source_seat := int(current_discard_context.get("source_seat", -1))
	if source_seat != current_dealer_seat:
		return false
	if int(last_turn_context.get("seat", -1)) != current_dealer_seat:
		return false
	if str(last_turn_context.get("draw_reason", "")) != "opening_discard":
		return false
	for other_seat in range(players.size()):
		if other_seat == current_dealer_seat:
			continue
		if not Array(players[other_seat].get("discards", [])).is_empty():
			return false
	return true


func _should_mark_hai_di(win_type: String) -> bool:
	if win_type == "":
		return false
	return wall_count == 0


func _should_ai_bao_jiao(seat: int) -> bool:
	if not bool(rules.enable_bao_jiao):
		return false
	if seat < 0 or seat >= players.size():
		return false
	if not bool(players[seat].get("is_ai", false)):
		return false
	if not can_human_bao_jiao(seat):
		return false
	var plan: Dictionary = _build_bao_jiao_plan(seat)
	if plan.is_empty():
		return false
	var ting_tiles: Array = plan.get("ting_tiles", [])
	var plan_score: int = int(plan.get("plan_score", 0))
	var live_total: int = _count_live_tiles_for_ting(ting_tiles)
	var bao_gang_count: int = int(Array(plan.get("bao_gang_keys", [])).size())
	var threshold: int = _bao_jiao_threshold_for_seat(seat)
	if rules != null and bool(rules.is_neijiang_mode()):
		if wall_count >= 16:
			if ting_tiles.size() < 2 and live_total < 5 and bao_gang_count <= 0:
				return false
			threshold += 20
		elif wall_count >= 10:
			if ting_tiles.size() < 2 and live_total < 4 and bao_gang_count <= 0:
				return false
			threshold += 8
	if wall_count <= _bao_jiao_force_ready_wall_threshold():
		return not ting_tiles.is_empty()
	return plan_score >= threshold


func _choose_ai_discard_tile(player: Dictionary) -> Dictionary:
	if rules != null and bool(rules.is_neijiang_mode()):
		debug_last_message = "内江 AI 出牌必须走 C# 决策；旧 GDScript 出牌入口已禁用。"
		return {}
	if bool(player.get("bao_jiao", false)):
		var draw_tile_id := _get_last_draw_tile_id_for_seat(int(player.get("seat", -1)))
		if draw_tile_id != -1:
			for tile in player.get("hand_tiles", []):
				if int(tile.get("id", -1)) == draw_tile_id:
					return tile.duplicate(true)
	var level: int = int(player.get("ai_level", int(ai_level)))
	var allow_cheat: bool = level == int(AILevel.CHEATING)
	var analysis: Dictionary = mahjong_judge.analyze_discard_options(player, _build_table_state(), rules, allow_cheat, true, ai_tuning_config)
	var options: Array = analysis.get("options", [])
	if options.is_empty():
		return {}
	var strategy_mode := str(analysis.get("strategy_profile", {}).get("mode_label", "两门速听"))
	_record_ai_metric("discard_strategy_" + strategy_mode)
	return options[0].get("tile", {})


func _get_forced_discard_suit(player: Dictionary) -> String:
	if rules == null or not bool(rules.requires_ding_que_phase()):
		return ""
	var ding_que_suit: String = str(player.get("ding_que", ""))
	if ding_que_suit == "":
		return ""
	for tile in player.get("hand_tiles", []):
		if str(tile.get("suit", "")) == ding_que_suit:
			return ding_que_suit
	return ""


func _build_trainer_hint_for_seat(seat: int) -> Dictionary:
	if seat < 0 or seat >= players.size():
		return {}
	var player: Dictionary = players[seat]
	var table_state := _build_table_state()
	var analysis: Dictionary = {}
	if rules != null and bool(rules.is_neijiang_mode()):
		if ai_manager == null:
			return {}
		analysis = ai_manager.analyze_turn(
			_build_player_state(seat),
			table_state,
			rules,
			ai_tuning_config,
			hu_checker,
			risk_analyzer,
			int(ai_level) == int(AILevel.CHEATING)
		)
	else:
		analysis = mahjong_judge.analyze_discard_options(
			player,
			table_state,
			rules,
			int(ai_level) == int(AILevel.CHEATING),
			true,
			ai_tuning_config
		)
	if analysis.is_empty():
		return {}
	var recommended: Dictionary = analysis.get("recommended", {})
	var can_add_gang_now: bool = seat == 0 and can_human_add_gang(seat)
	var can_an_gang_now: bool = seat == 0 and can_human_an_gang(seat)
	latest_trainer_hint = {
		"recommended": recommended.duplicate(true),
		"options": analysis.get("options", []).duplicate(true),
		"danger_tiles": analysis.get("danger_tiles", []).duplicate(true),
		"recommended_tile_id": int(recommended.get("tile", {}).get("id", -1)),
		"danger_tile_ids": _extract_trainer_tile_ids(analysis.get("danger_tiles", [])),
		"current_routes": analysis.get("current_routes", []).duplicate(true),
		"forced_discard_suit": analysis.get("forced_discard_suit", ""),
		"strategy_profile": analysis.get("strategy_profile", {}).duplicate(true),
		"situation_label": _resolve_trainer_situation_label(player, analysis.get("strategy_profile", {})),
		"can_add_gang": can_add_gang_now,
		"can_an_gang": can_an_gang_now,
		"can_self_hu": seat == 0 and can_human_self_hu(seat),
		"review_count": trainer_history.size(),
	}
	return latest_trainer_hint.duplicate(true)


func _resolve_trainer_situation_label(player: Dictionary, strategy_profile: Dictionary) -> String:
	var dingque_state: Dictionary = strategy_profile.get("dingque_state", {})
	var state_label := str(dingque_state.get("state_label", ""))
	var is_two_suit_table := bool(dingque_state.get("is_two_suit_table", false)) or (rules != null and bool(rules.is_neijiang_mode()))
	if is_two_suit_table:
		if state_label in ["两门均衡", "轻度偏门", "单门偏重"]:
			return state_label
		var suit_counts := {"tiao": 0, "tong": 0}
		for tile in player.get("hand_tiles", []):
			var suit := str(tile.get("suit", ""))
			if suit_counts.has(suit):
				suit_counts[suit] = int(suit_counts.get(suit, 0)) + 1
		var tiao_count: int = int(suit_counts.get("tiao", 0))
		var tong_count: int = int(suit_counts.get("tong", 0))
		var spread: int = absi(tiao_count - tong_count)
		if spread >= 4:
			return "单门偏重"
		if spread >= 2:
			return "轻度偏门"
		return "两门均衡"
	if state_label != "":
		return state_label
	return "两门均衡"


func _get_human_trainer_hint_snapshot() -> Dictionary:
	if not human_trainer_hint_enabled:
		latest_trainer_hint.clear()
		latest_trainer_hint_cache_key = ""
		return {}
	var seat: int = 0
	if seat < 0 or seat >= players.size():
		latest_trainer_hint.clear()
		latest_trainer_hint_cache_key = ""
		return {}
	var can_show_hint: bool = can_human_discard(seat) or can_human_add_gang(seat) or can_human_an_gang(seat) or can_human_self_hu(seat)
	if not can_show_hint:
		latest_trainer_hint.clear()
		latest_trainer_hint_cache_key = ""
		return {}
	var cache_key: String = _build_trainer_hint_cache_key(seat)
	if cache_key == latest_trainer_hint_cache_key and not latest_trainer_hint.is_empty():
		return latest_trainer_hint.duplicate(true)
	latest_trainer_hint_cache_key = cache_key
	return _build_trainer_hint_for_seat(seat)


func _build_trainer_hint_cache_key(seat: int) -> String:
	var player: Dictionary = players[seat]
	var hand_ids: PackedStringArray = []
	for tile in player.get("hand_tiles", []):
		hand_ids.append(str(int(tile.get("id", -1))))
	hand_ids.sort()
	return "%d|%d|%s|%s|%d|%d|%d|%d" % [
		int(current_phase),
		int(current_turn_seat),
		str(player.get("ding_que", "")),
		",".join(hand_ids),
		int(_get_last_draw_tile_id_for_seat(seat)),
		int(_get_recent_discard_tile_id()),
		int(can_human_add_gang(seat)),
		int(can_human_an_gang(seat)),
	]


func _extract_trainer_tile_ids(items: Array) -> Array[int]:
	var ids: Array[int] = []
	for item in items:
		var tile: Dictionary = item.get("tile", {})
		var tile_id: int = int(tile.get("id", -1))
		if tile_id != -1:
			ids.append(tile_id)
	return ids


func _record_human_discard_review(discarded_tile: Dictionary, trainer_context: Dictionary) -> void:
	if trainer_context.is_empty():
		return
	var options: Array = trainer_context.get("options", [])
	if options.is_empty():
		return
	var chosen_option: Dictionary = {}
	var best_option: Dictionary = options[0]
	for option in options:
		var tile: Dictionary = option.get("tile", {})
		if str(tile.get("suit", "")) == str(discarded_tile.get("suit", "")) and int(tile.get("rank", 0)) == int(discarded_tile.get("rank", 0)):
			chosen_option = option
			break
	if chosen_option.is_empty():
		return

	var severity := maxi(0, int(best_option.get("score", 0)) - int(chosen_option.get("score", 0)))
	severity += int(chosen_option.get("risk", 0))
	severity += int(chosen_option.get("route_loss", []).size()) * 12
	if bool(trainer_context.get("can_add_gang", false)) or bool(trainer_context.get("can_an_gang", false)):
		severity += 18

	var reasons: Array[String] = []
	if discarded_tile.get("display_name", "") != best_option.get("tile_name", ""):
		reasons.append("更优出牌应为 %s" % str(best_option.get("tile_name", "?")))
	if int(chosen_option.get("risk", 0)) >= 35:
		reasons.append("该张防守危险度为%s" % str(chosen_option.get("risk_label", "中危")))
	if not chosen_option.get("route_loss", []).is_empty():
		reasons.append("这一打会丢失 %s" % "/".join(chosen_option.get("route_loss", [])))
	if bool(trainer_context.get("can_add_gang", false)):
		reasons.append("此处存在补杠机会，值得复盘是否错过")
	elif bool(trainer_context.get("can_an_gang", false)):
		reasons.append("此处存在暗杠机会，值得复盘是否错过")
	if reasons.is_empty():
		reasons.append("这手整体处理较稳，没有明显失误")

	trainer_history.append(
		{
			"discard": discarded_tile.get("display_name", "?"),
			"best_discard": best_option.get("tile_name", "?"),
			"severity": severity,
			"reasons": reasons,
			"chosen_option": chosen_option.duplicate(true),
			"best_option": best_option.duplicate(true),
		}
	)


func _build_trainer_review_lines() -> Array[String]:
	var lines: Array[String] = []
	if trainer_history.is_empty():
		lines.append("训练复盘：本局尚未记录到明显失误。")
		return lines

	var sorted_history: Array = trainer_history.duplicate(true)
	sorted_history.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("severity", 0)) > int(b.get("severity", 0))
	)
	var limit := mini(3, sorted_history.size())
	lines.append("训练复盘：本局最值得回看的 %d 手" % limit)
	for index in range(limit):
		var item: Dictionary = sorted_history[index]
		lines.append("%d. 打出 %s | 更优 %s | %s" % [
			index + 1,
			str(item.get("discard", "?")),
			str(item.get("best_discard", "?")),
			"；".join(item.get("reasons", [])),
		])
	return lines


func _select_initial_dealer() -> int:
	return _rng.randi_range(0, 3)


func _create_initial_players(previous_players: Array = []) -> Array[Dictionary]:
	return [
		_create_player_state(0, "陈旭", false, _seed_score_for_seat(previous_players, 0)),
		_create_player_state(1, "舒小燕", true, _seed_score_for_seat(previous_players, 1)),
		_create_player_state(2, "陈东", true, _seed_score_for_seat(previous_players, 2)),
		_create_player_state(3, "舒玲", true, _seed_score_for_seat(previous_players, 3)),
	]


func _create_player_state(seat: int, nickname: String, is_ai: bool, score: int = STARTING_SCORE) -> Dictionary:
	return {
		"seat": seat,
		"nickname": nickname,
		"score": score,
		"is_ai": is_ai,
		"ai_level": int(ai_level) if is_ai else -1,
		"ding_que": "",
			"bao_jiao": false,
			"bao_gang_tiles": [],
			"opening_bao_jiao_reviewed": false,
			"rule_marks": [],
		"bao_jiao_ting_tiles": [],
		"hand_tiles": [],
		"hand_count": 0,
		"melds": [],
		"discards": [],
		"has_won": false,
	}


func _seed_score_for_seat(previous_players: Array, seat: int) -> int:
	for player in previous_players:
		if int(player.get("seat", -1)) == seat:
			return int(player.get("score", STARTING_SCORE))
	return STARTING_SCORE


func _build_wall() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var next_id: int = 1

	for suit in _active_suits():
		for rank in RANKS:
			for copy_index in range(COPIES_PER_TILE):
				result.append(
					{
						"id": next_id,
						"suit": suit,
						"rank": rank,
						"display_name": "%d%s" % [rank, _suit_display_name(suit)],
						"sort_key": _sort_key_for(suit, rank),
						"copy_index": copy_index,
					}
				)
				next_id += 1

	return result


func _active_suits() -> Array:
	if rules == null:
		return DEFAULT_SUITS.duplicate()
	return Array(rules.available_suits).duplicate()


func _shuffle_wall() -> void:
	for index in range(wall.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var temp: Dictionary = wall[index]
		wall[index] = wall[swap_index]
		wall[swap_index] = temp


func _deal_initial_hands() -> void:
	for seat in range(players.size()):
		var tile_count := 14 if seat == current_dealer_seat else 13
		var hand_tiles: Array[Dictionary] = []

		for _i in range(tile_count):
			hand_tiles.append(_draw_from_wall())

		_sort_tiles_in_place(hand_tiles)
		players[seat]["hand_tiles"] = hand_tiles
		players[seat]["hand_count"] = hand_tiles.size()


func _resolve_opening_roll() -> void:
	opening_roll_data = opening_roll_resolver.build_opening_roll(current_dealer_seat, _rng)
	opening_roll_data["round_index"] = round_index
	opening_roll_pending_completion = true


func _enter_ding_que_phase() -> void:
	if not rules.requires_ding_que_phase():
		debug_last_message = "当前为内江规则，直接进入庄家首打。"
		_begin_opening_discard_phase()
		_emit_state_changed()
		return
	current_phase = RoundPhase.DING_QUE
	_auto_select_ai_ding_que()
	_complete_ding_que_if_ready()
	_emit_state_changed()


func _auto_select_ai_ding_que() -> void:
	if not rules.requires_ding_que_phase():
		return
	for player in players:
		if not player["is_ai"] or player["ding_que"] != "":
			continue
		if player["seat"] == current_dealer_seat and not _must_dealer_choose_now():
			continue
		player["ding_que"] = _choose_ai_ding_que(player["hand_tiles"])


func _choose_ai_ding_que(hand_tiles: Array) -> String:
	return ding_que_resolver.choose_ai_missing_suit(hand_tiles, _active_suits(), _rng)


func _complete_ding_que_if_ready() -> void:
	if not rules.requires_ding_que_phase():
		_begin_opening_discard_phase()
		return
	if not ding_que_resolver.can_finish_opening_ding_que(players, current_dealer_seat):
		return

	if _is_dealer_ding_que_deferred():
		debug_last_message = "Non-dealers finished ding que. Dealer seat %d will lock ding que on first discard and discard first with 14 tiles." % current_turn_seat
	else:
		debug_last_message = "All required ding que choices are done. Dealer seat %d will discard first." % current_turn_seat
	_begin_opening_discard_phase()
	_emit_state_changed()


func _advance_turn_after_discard() -> void:
	var next_seat := _find_next_active_seat_after(current_turn_seat)
	if next_seat == -1:
		_enter_settlement_due_to_battle_end()
		return
	current_turn_seat = next_seat
	_begin_turn()


func _build_opening_bao_jiao_queue() -> Array[int]:
	var queue: Array[int] = []
	if rules == null or not bool(rules.is_neijiang_mode()):
		return queue
	if not discard_pile.is_empty():
		return queue
	if players.is_empty():
		return queue
	for step in range(1, players.size()):
		var seat := posmod(current_dealer_seat - step, players.size())
		if seat == current_dealer_seat:
			continue
		var player: Dictionary = players[seat]
		if bool(player.get("has_won", false)) or bool(player.get("bao_jiao", false)):
			continue
		if bool(player.get("opening_bao_jiao_reviewed", false)):
			continue
		if _build_bao_jiao_plan(seat).is_empty():
			player["opening_bao_jiao_reviewed"] = true
			continue
		queue.append(seat)
	return queue


func _start_opening_bao_jiao_window() -> bool:
	opening_bao_jiao_queue = _build_opening_bao_jiao_queue()
	if opening_bao_jiao_queue.is_empty():
		opening_bao_jiao_pending = false
		opening_bao_jiao_current_seat = -1
		return false
	opening_bao_jiao_pending = true
	opening_bao_jiao_current_seat = -1
	_process_opening_bao_jiao_queue()
	return opening_bao_jiao_pending


func _process_opening_bao_jiao_queue() -> void:
	if not opening_bao_jiao_pending:
		return
	while not opening_bao_jiao_queue.is_empty():
		var seat := int(opening_bao_jiao_queue.pop_front())
		if seat < 0 or seat >= players.size():
			continue
		if bool(players[seat].get("opening_bao_jiao_reviewed", false)) or bool(players[seat].get("bao_jiao", false)):
			continue
		if _build_bao_jiao_plan(seat).is_empty():
			_mark_opening_bao_jiao_reviewed(seat)
			continue
		opening_bao_jiao_current_seat = seat
		if bool(players[seat].get("is_ai", false)):
			if _should_ai_bao_jiao(seat):
				execute_human_bao_jiao(seat)
			else:
				_mark_opening_bao_jiao_reviewed(seat)
				debug_last_message = "%s 放弃开局报叫/报杠。" % _seat_display_name(seat)
			continue
		debug_last_message = "%s 起手可报叫/报杠，请先选择报叫或过牌，之后庄家再首打。" % _seat_display_name(seat)
		_emit_state_changed()
		return
	opening_bao_jiao_pending = false
	opening_bao_jiao_current_seat = -1
	debug_last_message = "开局报叫/报杠询问完成，庄家准备首打。"
	_emit_state_changed()
	_finish_opening_discard_after_bao_jiao_window()


func _mark_opening_bao_jiao_reviewed(seat: int) -> void:
	if seat >= 0 and seat < players.size():
		players[seat]["opening_bao_jiao_reviewed"] = true


func _finish_opening_discard_after_bao_jiao_window() -> void:
	if current_phase != RoundPhase.DISCARD:
		return
	if opening_bao_jiao_pending:
		return
	var seat: int = current_turn_seat
	debug_last_message = "%s 为庄家，起手 14 张，先行出牌。" % _seat_display_name(seat)
	if bool(players[seat].get("is_ai", false)):
		_start_ai_turn_background_request()


func _begin_opening_discard_phase() -> void:
	if _should_enter_battle_end_settlement():
		_enter_settlement_due_to_battle_end()
		return
	var seat: int = current_turn_seat
	if seat < 0 or seat >= players.size() or players[seat]["has_won"]:
		var next_seat := _find_next_active_seat_after(seat)
		if next_seat == -1:
			_enter_settlement_due_to_battle_end()
			return
		current_turn_seat = next_seat
		seat = current_turn_seat
	last_draw_tile = {}
	last_turn_context = {
		"seat": seat,
		"draw_reason": "opening_discard",
	}
	self_hu_pass_locks.erase(str(seat))
	current_phase = RoundPhase.DISCARD
	if _start_opening_bao_jiao_window():
		return
	_finish_opening_discard_after_bao_jiao_window()


func _begin_turn() -> void:
	_clear_pending_ai_turn_request()
	if _should_enter_battle_end_settlement():
		_enter_settlement_due_to_battle_end()
		return
	if wall.is_empty():
		_enter_settlement_due_to_draw()
		return

	var seat: int = current_turn_seat
	if seat < 0 or seat >= players.size() or players[seat]["has_won"]:
		var next_seat := _find_next_active_seat_after(seat)
		if next_seat == -1:
			_enter_settlement_due_to_battle_end()
			return
		current_turn_seat = next_seat
		seat = current_turn_seat
	var draw_tile: Dictionary = _draw_from_wall()
	if draw_tile.is_empty():
		_enter_settlement_due_to_draw()
		return
	_clear_shun_he_lock_for_seat(seat)

	var hand_tiles: Array = players[seat]["hand_tiles"]
	hand_tiles.append(draw_tile)
	_sort_tiles_in_place(hand_tiles)
	players[seat]["hand_tiles"] = hand_tiles
	players[seat]["hand_count"] = hand_tiles.size()
	last_draw_tile = {
		"seat": seat,
		"tile": draw_tile,
	}
	last_turn_context = {
		"seat": seat,
		"draw_reason": _consume_next_draw_reason(),
	}
	self_hu_pass_locks.erase(str(seat))
	current_phase = RoundPhase.DISCARD
	var draw_reason_text := "补牌" if last_turn_context["draw_reason"] == "gang_draw" else "摸牌"
	if _can_seat_self_hu_now(seat):
		debug_last_message = "%s 摸到 %s，可直接自摸。" % [
			_seat_display_name(seat),
			draw_tile["display_name"],
		]
	else:
		debug_last_message = "%s %s %s，等待出牌。" % [
			_seat_display_name(seat),
			draw_reason_text,
			draw_tile["display_name"],
		]
	if bool(players[seat].get("is_ai", false)):
		_start_ai_turn_background_request()


func _enter_settlement_due_to_draw() -> void:
	current_phase = RoundPhase.SETTLEMENT
	settlement_data["end_reason"] = "draw_wall_empty"
	_build_draw_settlement_assessment()
	_rebuild_settlement_summary()
	debug_last_message = "Wall is empty. Draw game settlement is not implemented yet."


func _enter_settlement_due_to_battle_end() -> void:
	current_phase = RoundPhase.SETTLEMENT
	last_draw_tile = {}
	_clear_reaction_context()
	settlement_data["end_reason"] = "battle_end"
	_build_draw_settlement_assessment()
	_rebuild_settlement_summary()
	debug_last_message = "Blood battle reached end state. Winners: %s. Settlement details are not implemented yet." % [_format_winner_list()]


func _draw_from_wall() -> Dictionary:
	if wall.is_empty():
		push_error("Attempted to draw from an empty wall.")
		return {}

	var tile: Dictionary = wall.pop_back()
	wall_count = wall.size()
	return tile


func _sort_tiles_in_place(tiles: Array) -> void:
	tiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["sort_key"] == b["sort_key"]:
			return a["id"] < b["id"]
		return a["sort_key"] < b["sort_key"]
	)


func _sort_key_for(suit: String, rank: int) -> int:
	var suit_index := _active_suits().find(suit)
	return suit_index * 100 + rank


func _suit_display_name(suit: String) -> String:
	match suit:
		"tiao":
			return "条"
		"tong":
			return "筒"
		"wan":
			return "万"
		_:
			return "?"


func _get_recent_discard_display() -> String:
	if discard_pile.is_empty():
		return "-"
	var recent: Dictionary = discard_pile[discard_pile.size() - 1]
	return "%s：%s" % [_seat_display_name(int(recent["seat"])), recent["tile"]["display_name"]]


func _get_recent_draw_display() -> String:
	if last_draw_tile.is_empty():
		return "-"
	return "%s：%s" % [_seat_display_name(int(last_draw_tile["seat"])), last_draw_tile["tile"]["display_name"]]


func _get_recent_draw_seat() -> int:
	if last_draw_tile.is_empty():
		return -1
	return int(last_draw_tile.get("seat", -1))


func _get_recent_discard_tile_id() -> int:
	if discard_pile.is_empty():
		return -1
	var recent: Dictionary = discard_pile[discard_pile.size() - 1]
	return int(recent.get("tile", {}).get("id", -1))


func _get_last_draw_tile_id_for_seat(seat: int) -> int:
	if last_draw_tile.is_empty():
		return -1
	if last_draw_tile["seat"] != seat:
		return -1
	return last_draw_tile["tile"]["id"]


func _must_dealer_choose_now() -> bool:
	if current_dealer_seat < 0 or current_dealer_seat >= players.size():
		return false
	return ding_que_resolver.must_choose_before_first_discard(players[current_dealer_seat], current_dealer_seat)


func _is_dealer_ding_que_deferred() -> bool:
	if current_phase != RoundPhase.DING_QUE:
		return false
	if current_dealer_seat < 0 or current_dealer_seat >= players.size():
		return false
	return players[current_dealer_seat]["ding_que"] == "" and not _must_dealer_choose_now()


func _lock_dealer_ding_que_from_first_discard(tile_id: int) -> bool:
	var hand_tiles: Array = players[current_dealer_seat]["hand_tiles"]
	for tile in hand_tiles:
		if tile["id"] == tile_id:
			players[current_dealer_seat]["ding_que"] = tile["suit"]
			return true
	return false


func _emit_state_changed() -> void:
	_pump_ai_background_requests()
	state_changed.emit(get_debug_snapshot())


func _record_ai_chain_debug(message: String) -> void:
	var line := "%d R%d P%s T%s %s" % [
		Time.get_ticks_msec(),
		round_index,
		str(current_phase),
		str(current_turn_seat),
		message,
	]
	ai_chain_debug_history.append(line)
	while ai_chain_debug_history.size() > 80:
		ai_chain_debug_history.pop_front()
	var log_path := "user://ai_chain_debug.log"
	var file := FileAccess.open(log_path, FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(line)
	file.close()


func _pump_ai_background_requests() -> int:
	return 0 if ai_manager == null else int(ai_manager.pump_async_requests())


func pump_ai_background_requests() -> int:
	return _pump_ai_background_requests()


func _clear_pending_ai_turn_request() -> void:
	pending_ai_turn_request_id = 0
	pending_ai_turn_request_meta.clear()


func _clear_pending_ai_reaction_request() -> void:
	pending_ai_reaction_request_id = 0
	pending_ai_reaction_request_meta.clear()


func _clear_pending_ai_async_state() -> void:
	_clear_pending_ai_turn_request()
	_clear_pending_ai_reaction_request()
	pending_ai_turn_decision.clear()
	pending_ai_reaction_decision.clear()


func _has_native_csharp_runtime() -> bool:
	_bind_native_csharp_runtime_if_available()
	return ai_manager != null and ai_manager.has_native_csharp_runtime()


func _bind_native_csharp_runtime_if_available() -> bool:
	if ai_manager == null:
		return false
	if ai_manager.has_native_csharp_runtime():
		return true
	if not is_inside_tree():
		return false
	var native_csharp_runtime := get_node_or_null("/root/NeijiangCSharpRuntime")
	if native_csharp_runtime == null:
		return false
	ai_manager.set_native_csharp_runtime(native_csharp_runtime)
	if ai_learning_engine != null:
		ai_learning_engine.set_native_csharp_runtime(native_csharp_runtime)
	print("[GameState] bound native C# runtime ready=", ai_manager.has_native_csharp_runtime())
	return ai_manager.has_native_csharp_runtime()


func _on_ai_turn_analysis_ready(request_id: int, seat_index: int, analysis: Dictionary) -> void:
	if request_id != pending_ai_turn_request_id:
		return
	if not _is_pending_ai_turn_request_valid():
		_clear_pending_ai_turn_request()
		return
	var selected_tile: Dictionary = _resolve_analysis_recommended_tile(seat_index, analysis)
	if selected_tile.is_empty():
		debug_last_message = "后台 C# AI 已返回，但推荐牌未成功映射到手牌，等待下一次计算。"
		_clear_pending_ai_turn_request()
		_emit_state_changed()
		return
	pending_ai_turn_decision = {
		"round_index": round_index,
		"seat": seat_index,
		"phase": int(current_phase),
		"wall_count": wall_count,
		"hand_count": int(players[seat_index].get("hand_count", 0)),
		"action": "discard",
		"tile_id": int(selected_tile.get("id", -1)),
		"analysis": analysis.duplicate(true),
	}
	_clear_pending_ai_turn_request()
	_emit_state_changed()


func _resolve_analysis_recommended_tile(seat: int, analysis: Dictionary) -> Dictionary:
	var selected_tile: Dictionary = analysis.get("recommended", {}).get("tile", {})
	if seat < 0 or seat >= players.size():
		return selected_tile
	var hand_tiles: Array = players[seat].get("hand_tiles", [])
	var selected_id := int(selected_tile.get("id", -1))
	if selected_id != -1:
		for hand_tile in hand_tiles:
			if int(hand_tile.get("id", -1)) == selected_id:
				return hand_tile.duplicate(true)
	var target_suit := str(selected_tile.get("suit", ""))
	var target_rank := int(selected_tile.get("rank", -1))
	if target_suit == "" or target_rank <= 0:
		return {}
	for hand_tile in hand_tiles:
		if str(hand_tile.get("suit", "")) == target_suit and int(hand_tile.get("rank", -1)) == target_rank:
			return hand_tile.duplicate(true)
	return {}


func _on_ai_reaction_analysis_ready(request_id: int, seat_index: int, analysis: Dictionary) -> void:
	if request_id != pending_ai_reaction_request_id:
		return
	if not _is_pending_ai_reaction_request_valid():
		_clear_pending_ai_reaction_request()
		return
	var candidate: Dictionary = pending_ai_reaction_request_meta.get("candidate", {}).duplicate(true)
	var tile: Dictionary = current_discard_context.get("tile", {})
	pending_ai_reaction_decision = {
		"round_index": round_index,
		"phase": int(current_phase),
		"source_seat": int(current_discard_context.get("source_seat", -1)),
		"tile_id": int(tile.get("id", -1)),
		"pending_count": pending_reactions.size(),
		"seat": seat_index,
		"candidate": candidate,
		"decision": analysis.duplicate(true),
	}
	_clear_pending_ai_reaction_request()
	_emit_state_changed()


func _prepare_reaction_context(source_seat: int, discarded_tile: Dictionary) -> void:
	pending_ai_turn_decision.clear()
	pending_ai_reaction_decision.clear()
	_clear_pending_ai_reaction_request()
	current_discard_context = {
		"source_seat": source_seat,
		"tile": discarded_tile.duplicate(true),
		"reaction_type": "discard",
		"allow_chi": rules.allow_chi,
		"winner_seats": [],
	}
	pending_reactions = mahjong_judge.build_reaction_candidates(_build_table_state(), current_discard_context, rules)
	_apply_shun_he_lock_filter()
	if is_ai_reaction_pending():
		_start_ai_reaction_background_request()


func _clear_reaction_context() -> void:
	current_discard_context.clear()
	pending_reactions.clear()
	pending_ai_reaction_decision.clear()
	_clear_pending_ai_reaction_request()


func _apply_passed_hu_lock_if_needed(seat: int, candidate: Dictionary) -> void:
	if not candidate.get("can_hu", false):
		return
	if current_discard_context.is_empty():
		return
	var tile: Dictionary = current_discard_context.get("tile", {})
	if tile.is_empty():
		return
	var fan_detail: Dictionary = score_resolver.build_event_fan_detail(players[seat], tile, _resolve_discard_win_type(int(current_discard_context.get("source_seat", -1)), str(current_discard_context.get("reaction_type", "discard"))), rules)
	shun_he_locks[seat] = {
		"min_fan": int(fan_detail.get("capped_fan", 1)),
		"tile": tile.duplicate(true),
	}


func _clear_shun_he_lock_for_seat(seat: int) -> void:
	if shun_he_locks.has(seat):
		shun_he_locks.erase(seat)


func _apply_shun_he_lock_filter() -> void:
	var filtered: Array[Dictionary] = []
	var source_seat: int = int(current_discard_context.get("source_seat", -1))
	var reaction_type: String = str(current_discard_context.get("reaction_type", "discard"))
	var tile: Dictionary = current_discard_context.get("tile", {})
	for candidate in pending_reactions:
		var seat: int = int(candidate.get("seat", -1))
		if candidate.get("can_hu", false) and shun_he_locks.has(seat):
			var lock_info: Dictionary = shun_he_locks[seat]
			var win_type := _resolve_discard_win_type(source_seat, reaction_type)
			var fan_detail: Dictionary = score_resolver.build_event_fan_detail(players[seat], tile, win_type, rules)
			if int(fan_detail.get("capped_fan", 1)) <= int(lock_info.get("min_fan", 0)):
				candidate["can_hu"] = false
		if candidate.get("can_hu", false) or candidate.get("can_gang", false) or candidate.get("can_peng", false):
			filtered.append(candidate)
	pending_reactions = filtered


func _find_add_gang_option(seat: int) -> Dictionary:
	if seat < 0 or seat >= players.size():
		return {}
	var hand_tiles: Array = players[seat]["hand_tiles"]
	var melds: Array = players[seat]["melds"]
	for meld_index in range(melds.size()):
		var meld: Dictionary = melds[meld_index]
		if meld.get("type", "") != "peng":
			continue
		var meld_tiles: Array = meld.get("tiles", [])
		if meld_tiles.is_empty():
			continue
		var target_tile: Dictionary = meld_tiles[0]
		# Only the ding-que suit is blocked; other suits remain gang-eligible.
		if _is_ding_que_tile_for_seat(seat, target_tile):
			continue
		for hand_tile in hand_tiles:
			if hand_tile["suit"] == target_tile["suit"] and hand_tile["rank"] == target_tile["rank"]:
				if _is_ding_que_tile_for_seat(seat, hand_tile):
					continue
				if not _is_bao_gang_allowed(seat, hand_tile):
					continue
				return {
					"meld_index": meld_index,
					"tile": hand_tile.duplicate(true),
					"source_seat": int(meld.get("from_seat", seat)),
				}
	return {}


func _find_an_gang_option(seat: int) -> Dictionary:
	if seat < 0 or seat >= players.size():
		return {}
	var hand_tiles: Array = players[seat]["hand_tiles"]
	var counts := {}
	for tile in hand_tiles:
		var key := "%s_%d" % [tile["suit"], tile["rank"]]
		if not counts.has(key):
			counts[key] = []
		counts[key].append(tile)
	for key in counts.keys():
		var tiles: Array = counts[key]
		if tiles.size() >= 4:
			# Only the ding-que suit is blocked; other suits remain gang-eligible.
			if _is_ding_que_tile_for_seat(seat, tiles[0]):
				continue
			if not _is_bao_gang_allowed(seat, tiles[0]):
				continue
			return {
				"tiles": tiles.slice(0, 4),
			}
	return {}


func _tile_types_from_options(options: Array, tile_field: String) -> Array:
	var result: Array = []
	for option in options:
		var tile: Dictionary = {}
		if tile_field == "tiles":
			var tiles: Array = Array(option.get("tiles", []))
			if not tiles.is_empty():
				tile = tiles[0]
		else:
			tile = option.get(tile_field, {})
		var tile_type := _neijiang_tile_type(tile)
		if tile_type >= 0 and not result.has(tile_type):
			result.append(tile_type)
	return result


func _find_option_by_tile_type(options: Array, tile_type: int, tile_field: String) -> Dictionary:
	for option in options:
		var tile: Dictionary = {}
		if tile_field == "tiles":
			var tiles: Array = Array(option.get("tiles", []))
			if not tiles.is_empty():
				tile = tiles[0]
		else:
			tile = option.get(tile_field, {})
		if _neijiang_tile_type(tile) == tile_type:
			return option.duplicate(true)
	return {}


func _neijiang_tile_type(tile: Dictionary) -> int:
	if tile.is_empty():
		return -1
	var rank := int(tile.get("rank", 0))
	if rank < 1 or rank > 9:
		return -1
	match str(tile.get("suit", "")):
		"tiao":
			return rank - 1
		"tong":
			return 9 + rank - 1
		_:
			return -1


func _should_ai_add_gang(seat: int) -> bool:
	return not _choose_ai_add_gang_option(seat).is_empty()


func _should_ai_an_gang(seat: int) -> bool:
	return not _choose_ai_an_gang_option(seat).is_empty()


func _start_add_gang(seat: int, selected_option: Dictionary = {}) -> bool:
	var option: Dictionary = selected_option.duplicate(true) if not selected_option.is_empty() else ({} if bool(players[seat].get("is_ai", false)) else _find_add_gang_option(seat))
	if option.is_empty():
		return false

	var gang_tile: Dictionary = option["tile"]
	var meld_index: int = int(option["meld_index"])
	pending_qiang_gang_context = {
		"actor_seat": seat,
		"tile": gang_tile.duplicate(true),
		"meld_index": meld_index,
		"source_seat": int(option.get("source_seat", seat)),
		"placeholder_type": "add_gang_qiang_gang_hu",
		"status": "awaiting_reactions",
		"winner_seats": [],
	}
	current_phase = RoundPhase.REACTION
	current_discard_context = {
		"source_seat": seat,
		"tile": gang_tile.duplicate(true),
		"reaction_type": "qiang_gang_hu",
		"winner_seats": [],
	}
	pending_reactions = _build_qiang_gang_hu_candidates(seat, gang_tile)
	_register_qiang_gang_context(seat, gang_tile, "add_gang_qiang_gang_hu")

	if pending_reactions.is_empty():
		return _finalize_add_gang_without_qiang()

	debug_last_message = "%s 尝试补杠 %s。可抢杠：%s" % [
		_seat_display_name(seat),
		gang_tile["display_name"],
		mahjong_judge.summarize_candidates(pending_reactions),
	]
	_emit_state_changed()
	return true


func _execute_an_gang(seat: int, selected_option: Dictionary = {}) -> bool:
	var option: Dictionary = selected_option.duplicate(true) if not selected_option.is_empty() else ({} if bool(players[seat].get("is_ai", false)) else _find_an_gang_option(seat))
	if option.is_empty():
		return false

	var tiles: Array = option["tiles"]
	var first_tile: Dictionary = tiles[0]
	var removed_tiles: Array[Dictionary] = _remove_matching_tiles_from_hand(seat, first_tile, 4)
	if removed_tiles.size() != 4:
		return false

	players[seat]["melds"].append(
		{
			"type": "gang",
			"from_seat": seat,
			"tiles": removed_tiles.duplicate(true),
			"gang_subtype": "an_gang",
		}
	)
	current_turn_seat = seat
	last_gang_context = {
		"seat": seat,
		"source_seat": seat,
		"tile": first_tile.duplicate(true),
		"gang_type": "an_gang",
		"resolved": false,
	}
	_append_settlement_gang_event(seat, seat, first_tile, "an_gang", _get_active_non_winner_seats_excluding(seat))
	debug_last_message = "%s 暗杠 %s，开始补牌。" % [
		_seat_display_name(seat),
		first_tile["display_name"],
	]
	_begin_turn()
	_emit_state_changed()
	return true


func _choose_ai_add_gang_option(seat: int) -> Dictionary:
	var options := _find_all_add_gang_options(seat)
	if options.is_empty():
		return {}
	if ai_manager == null:
		return {}
	var decision: Dictionary = ai_manager.analyze_self_action(
		_build_player_state(seat),
		_build_table_state(),
		rules,
		false,
		[],
		_tile_types_from_options(options, "tile"),
		_add_gang_qiang_counts_by_tile_type(seat, options)
	)
	if str(decision.get("action", "")).strip_edges().to_lower() != "gang":
		return {}
	if str(decision.get("csharp_result", {}).get("gangSubtype", "")) != "add_gang":
		return {}
	var option := _find_option_by_tile_type(options, int(decision.get("tile_type", -1)), "tile")
	if not option.is_empty():
		option["evaluation"] = decision.duplicate(true)
	return option


func _choose_ai_an_gang_option(seat: int) -> Dictionary:
	var options := _find_all_an_gang_options(seat)
	if options.is_empty():
		return {}
	if ai_manager == null:
		return {}
	var decision: Dictionary = ai_manager.analyze_self_action(
		_build_player_state(seat),
		_build_table_state(),
		rules,
		false,
		_tile_types_from_options(options, "tiles"),
		[],
		{}
	)
	if str(decision.get("action", "")).strip_edges().to_lower() != "gang":
		return {}
	if str(decision.get("csharp_result", {}).get("gangSubtype", "")) != "an_gang":
		return {}
	var option := _find_option_by_tile_type(options, int(decision.get("tile_type", -1)), "tiles")
	if not option.is_empty():
		option["evaluation"] = decision.duplicate(true)
	return option


func _can_aggressive_gang_override(seat: int, reasons: Array, is_an_gang: bool) -> bool:
	if seat < 0 or seat >= players.size():
		return false
	if bool(players[seat].get("bao_jiao", false)):
		return false
	if wall_count <= 6:
		return false
	var has_speed_hold := false
	var has_speed_drop := false
	var has_qiang_gang_risk := false
	for item in reasons:
		var text := str(item)
		if text.find("不损速度") != -1 or text.find("不明显降速") != -1 or text.find("仍保持成叫") != -1 or text.find("结构更清晰") != -1 or text.find("结构变优") != -1:
			has_speed_hold = true
		if text.find("向听变差") != -1 or text.find("结构变差") != -1 or text.find("拖慢速度") != -1:
			has_speed_drop = true
		if text.find("抢杠胡风险") != -1:
			has_qiang_gang_risk = true
	if has_speed_drop:
		return false
	if not is_an_gang and has_qiang_gang_risk:
		return false
	return has_speed_hold


func _create_empty_ai_decision_metrics() -> Dictionary:
	return {
		"reaction_total": 0,
		"reaction_hu": 0,
		"reaction_gang": 0,
		"reaction_peng": 0,
		"reaction_pass": 0,
		"self_hu_actions": 0,
		"bao_jiao_actions": 0,
		"an_gang_attempts": 0,
		"add_gang_attempts": 0,
		"discard_strategy_全攻": 0,
		"discard_strategy_进攻平衡": 0,
		"discard_strategy_均衡": 0,
		"discard_strategy_防守平衡": 0,
		"discard_strategy_全守": 0,
	}


func _record_ai_metric(key: String, amount: int = 1) -> void:
	ai_decision_metrics[key] = int(ai_decision_metrics.get(key, 0)) + amount

func _resolve_ai_reaction_action(seat: int, candidate: Dictionary, requested_action: String) -> String:
	if requested_action == "hu" and bool(candidate.get("can_hu", false)):
		return "hu"
	if requested_action == "gang" and bool(candidate.get("can_gang", false)) and not _has_higher_priority_candidate_than(seat, "gang"):
		return "gang"
	if requested_action == "peng" and bool(candidate.get("can_peng", false)) and not _has_higher_priority_candidate_than(seat, "peng"):
		return "peng"
	return "pass"


func _record_ai_reaction_review(seat: int, candidate: Dictionary, decision: Dictionary, requested_action: String, resolved_action: String) -> void:
	var tile: Dictionary = current_discard_context.get("tile", {}).duplicate(true)
	var source_seat := int(current_discard_context.get("source_seat", -1))
	var review := {
		"round_index": round_index,
		"phase": int(current_phase),
		"phase_name": _phase_debug_name(current_phase),
		"wall_count": wall_count,
		"seat": seat,
		"seat_name": _seat_display_name(seat),
		"source_seat": source_seat,
		"source_name": _seat_display_name(source_seat),
		"reaction_type": str(current_discard_context.get("reaction_type", "discard")),
		"tile": tile,
		"tile_name": str(tile.get("display_name", "")),
		"candidate": candidate.duplicate(true),
		"requested_action": requested_action,
		"action": resolved_action,
		"action_scores": decision.get("action_scores", {}).duplicate(true),
		"reasons": Array(decision.get("reasons", [])).duplicate(true),
		"posterior_summary": Array(decision.get("posterior_summary", [])).duplicate(true),
		"future_summary": Array(decision.get("future_summary", [])).duplicate(true),
		"search_used": bool(decision.get("search_used", false)),
		"search_simulations": int(decision.get("search_simulations", 0)),
		"search_bonus": float(decision.get("search_bonus", 0.0)),
		"current_shanten": int(decision.get("current_shanten", -1)),
		"backend_mode": str(decision.get("backend_mode", "")),
	}
	latest_ai_reaction_review = review.duplicate(true)
	ai_reaction_review_history.append(review)
	while ai_reaction_review_history.size() > AI_REACTION_REVIEW_LIMIT:
		ai_reaction_review_history.remove_at(0)


func _phase_debug_name(phase_value: int) -> String:
	match phase_value:
		RoundPhase.BOOT:
			return "BOOT"
		RoundPhase.MAIN_MENU:
			return "MAIN_MENU"
		RoundPhase.TABLE_SETUP:
			return "TABLE_SETUP"
		RoundPhase.DING_QUE:
			return "DING_QUE"
		RoundPhase.DRAW:
			return "DRAW"
		RoundPhase.DISCARD:
			return "DISCARD"
		RoundPhase.REACTION:
			return "REACTION"
		RoundPhase.SETTLEMENT:
			return "SETTLEMENT"
		_:
			return str(phase_value)



func _find_all_add_gang_options(seat: int) -> Array:
	var results: Array = []
	if seat < 0 or seat >= players.size():
		return results
	var hand_tiles: Array = players[seat]["hand_tiles"]
	var melds: Array = players[seat]["melds"]
	for meld_index in range(melds.size()):
		var meld: Dictionary = melds[meld_index]
		if meld.get("type", "") != "peng":
			continue
		var meld_tiles: Array = meld.get("tiles", [])
		if meld_tiles.is_empty():
			continue
		var target_tile: Dictionary = meld_tiles[0]
		if _is_ding_que_tile_for_seat(seat, target_tile):
			continue
		for hand_tile in hand_tiles:
			if hand_tile["suit"] == target_tile["suit"] and hand_tile["rank"] == target_tile["rank"]:
				if _is_ding_que_tile_for_seat(seat, hand_tile):
					continue
				if not _is_bao_gang_allowed(seat, hand_tile):
					continue
				results.append(
					{
						"meld_index": meld_index,
						"tile": hand_tile.duplicate(true),
						"source_seat": int(meld.get("from_seat", seat)),
					}
				)
	return results


func _find_all_an_gang_options(seat: int) -> Array:
	var results: Array = []
	if seat < 0 or seat >= players.size():
		return results
	var hand_tiles: Array = players[seat]["hand_tiles"]
	var counts := {}
	for tile in hand_tiles:
		var key := "%s_%d" % [tile["suit"], tile["rank"]]
		if not counts.has(key):
			counts[key] = []
		counts[key].append(tile)
	for key in counts.keys():
		var tiles: Array = counts[key]
		if tiles.size() >= 4:
			if _is_ding_que_tile_for_seat(seat, tiles[0]):
				continue
			if not _is_bao_gang_allowed(seat, tiles[0]):
				continue
			results.append({"tiles": tiles.slice(0, 4)})
	return results


func _build_qiang_gang_hu_candidates(actor_seat: int, gang_tile: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for player in players:
		var seat: int = player["seat"]
		if seat == actor_seat or player.get("has_won", false):
			continue
		if mahjong_judge.can_hu_on_discard(_build_player_state(seat), gang_tile, rules):
			result.append(
				{
					"seat": seat,
					"can_hu": true,
					"can_gang": false,
					"can_peng": false,
				}
			)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _reaction_distance_from_source(actor_seat, int(a["seat"])) < _reaction_distance_from_source(actor_seat, int(b["seat"]))
	)
	return result


func _finalize_add_gang_without_qiang() -> bool:
	if pending_qiang_gang_context.is_empty():
		return false
	var seat: int = int(pending_qiang_gang_context["actor_seat"])
	var tile: Dictionary = pending_qiang_gang_context["tile"]
	if not pending_qiang_gang_context.has("meld_index"):
		debug_last_message = "ADD GANG context missing meld_index for seat %d." % seat
		pending_qiang_gang_context.clear()
		_clear_reaction_context()
		_emit_state_changed()
		return false
	var meld_index: int = int(pending_qiang_gang_context["meld_index"])
	if not _remove_tile_from_hand_by_id(seat, int(tile["id"])):
		return false
	if not _upgrade_peng_to_gang(seat, meld_index, tile):
		return false

	last_gang_context = {
		"seat": seat,
		"source_seat": int(pending_qiang_gang_context.get("source_seat", seat)),
		"tile": tile.duplicate(true),
		"gang_type": "add_gang",
		"resolved": false,
	}
	_append_settlement_gang_event(seat, int(pending_qiang_gang_context.get("source_seat", seat)), tile, "add_gang", _get_active_non_winner_seats_excluding(seat))
	_clear_reaction_context()
	pending_qiang_gang_context.clear()
	current_turn_seat = seat
	debug_last_message = "%s 完成补杠 %s，开始补牌。" % [
		_seat_display_name(seat),
		tile["display_name"],
	]
	_begin_turn()
	_emit_state_changed()
	return true


func _remove_tile_from_hand_by_id(seat: int, tile_id: int) -> bool:
	var hand_tiles: Array = players[seat]["hand_tiles"]
	for index in range(hand_tiles.size()):
		if hand_tiles[index]["id"] == tile_id:
			hand_tiles.remove_at(index)
			players[seat]["hand_tiles"] = hand_tiles
			players[seat]["hand_count"] = hand_tiles.size()
			return true
	return false


func _upgrade_peng_to_gang(seat: int, meld_index: int, extra_tile: Dictionary) -> bool:
	var melds: Array = players[seat]["melds"]
	if meld_index < 0 or meld_index >= melds.size():
		return false
	var meld: Dictionary = melds[meld_index]
	if meld.get("type", "") != "peng":
		return false
	var tiles: Array = meld.get("tiles", []).duplicate(true)
	tiles.append(extra_tile.duplicate(true))
	meld["type"] = "gang"
	meld["tiles"] = tiles
	meld["gang_upgrade"] = true
	melds[meld_index] = meld
	players[seat]["melds"] = melds
	return true


func _execute_peng(seat: int) -> bool:
	if current_discard_context.is_empty():
		return false

	_clear_pending_ai_async_state()
	var source_seat: int = current_discard_context["source_seat"]
	var discarded_tile: Dictionary = current_discard_context["tile"]
	# Ding-que blocks claiming the missing suit itself, but not other suits.
	if _is_ding_que_tile_for_seat(seat, discarded_tile):
		debug_last_message = "%s 定缺 %s，不能碰 %s。" % [
			_seat_display_name(seat),
			_suit_display_name(str(discarded_tile.get("suit", ""))),
			str(discarded_tile.get("display_name", "?")),
		]
		return false
	var claimed_pair: Array[Dictionary] = _remove_matching_tiles_from_hand(seat, discarded_tile, 2)
	if claimed_pair.size() != 2:
		return false
	_consume_claimed_discard(source_seat, discarded_tile)

	players[seat]["melds"].append(
		{
			"type": "peng",
			"from_seat": source_seat,
			"tiles": [
				claimed_pair[0],
				claimed_pair[1],
				discarded_tile.duplicate(true),
			],
		}
	)
	current_turn_seat = seat
	current_phase = RoundPhase.DISCARD
	last_draw_tile = {}
	debug_last_message = "%s 碰了 %s（来自 %s），等待出牌。" % [
		_seat_display_name(seat),
		discarded_tile["display_name"],
		_seat_display_name(source_seat),
	]
	_clear_reaction_context()
	if bool(players[seat].get("is_ai", false)):
		pending_ai_turn_decision.clear()
		_start_ai_turn_background_request()
	_emit_state_changed()
	return true


func _execute_gang(seat: int) -> bool:
	if current_discard_context.is_empty():
		return false

	_clear_pending_ai_async_state()
	var source_seat: int = current_discard_context["source_seat"]
	var discarded_tile: Dictionary = current_discard_context["tile"]
	# Ding-que blocks claiming the missing suit itself, but not other suits.
	if _is_ding_que_tile_for_seat(seat, discarded_tile):
		return false
	var claimed_tiles: Array[Dictionary] = _remove_matching_tiles_from_hand(seat, discarded_tile, 3)
	if claimed_tiles.size() != 3:
		return false
	_consume_claimed_discard(source_seat, discarded_tile)

	var meld_tiles: Array[Dictionary] = claimed_tiles.duplicate(true)
	meld_tiles.append(discarded_tile.duplicate(true))
	players[seat]["melds"].append(
		{
			"type": "gang",
			"from_seat": source_seat,
			"tiles": meld_tiles,
		}
	)
	current_turn_seat = seat
	_clear_reaction_context()
	last_gang_context = {
		"seat": seat,
		"source_seat": source_seat,
		"tile": discarded_tile.duplicate(true),
		"gang_type": "melded_gang",
		"resolved": false,
	}
	_append_settlement_gang_event(seat, source_seat, discarded_tile, "melded_gang", [source_seat])
	debug_last_message = "%s 明杠 %s（来自 %s），开始补牌。" % [
		_seat_display_name(seat),
		discarded_tile["display_name"],
		_seat_display_name(source_seat),
	]
	_begin_turn()
	_emit_state_changed()
	return true


func _is_ding_que_tile_for_seat(seat: int, tile: Dictionary) -> bool:
	if rules != null and rules.is_neijiang_mode():
		return false
	if seat < 0 or seat >= players.size():
		return false
	var ding_que: String = str(players[seat].get("ding_que", ""))
	if ding_que == "":
		return false
	return str(tile.get("suit", "")) == ding_que


func _execute_hu_on_discard(seat: int) -> bool:
	if current_discard_context.is_empty():
		return false

	_clear_pending_ai_async_state()
	var source_seat: int = current_discard_context["source_seat"]
	var discarded_tile: Dictionary = current_discard_context["tile"]
	var reaction_type: String = str(current_discard_context.get("reaction_type", "discard"))
	if not mahjong_judge.can_hu_on_discard(_build_player_state(seat), discarded_tile, rules):
		return false
	_consume_claimed_discard(source_seat, discarded_tile)

	players[seat]["has_won"] = true
	players[seat]["winning_tile"] = discarded_tile.duplicate(true)
	players[seat]["winning_source_seat"] = source_seat
	var win_type := _resolve_discard_win_type(source_seat, reaction_type)
	players[seat]["win_type"] = win_type
	_apply_special_rule_marks_for_win(seat, win_type)
	if not round_winners.has(seat):
		round_winners.append(seat)
		_append_settlement_win_event(seat, source_seat, discarded_tile, win_type, _get_payer_seats_for_win(win_type, source_seat))
	var current_winner_seats: Array = current_discard_context.get("winner_seats", [])
	if not current_winner_seats.has(seat):
		current_winner_seats.append(seat)
	current_discard_context["winner_seats"] = current_winner_seats
	if reaction_type == "qiang_gang_hu":
		var qiang_winner_seats: Array = pending_qiang_gang_context.get("winner_seats", [])
		if not qiang_winner_seats.has(seat):
			qiang_winner_seats.append(seat)
		pending_qiang_gang_context["winner_seats"] = qiang_winner_seats
	if win_type == "gang_discard_win":
		_mark_latest_gang_outcome("gang_discard_win")
		_append_hu_jiao_zhuan_yi_event(source_seat, seat, discarded_tile)
	elif win_type == "qiang_gang_hu":
		_consume_qiang_gang_robbed_tile()
		_mark_pending_qiang_gang_resolution("claimed_by_hu")
	_remove_reaction_candidate_for_seat(seat)
	_filter_pending_reactions_after_hu()
	debug_last_message = "%s 胡了 %s（来自 %s）。当前胡牌：%s" % [
		_seat_display_name(seat),
		discarded_tile["display_name"],
		_seat_display_name(source_seat),
		_format_winner_list(),
	]
	if _should_enter_battle_end_settlement():
		_enter_settlement_due_to_battle_end()
		_emit_state_changed()
	elif pending_reactions.is_empty():
		if reaction_type == "qiang_gang_hu":
			_finalize_qiang_gang_after_hu_or_pass()
		else:
			_finalize_reaction_after_hu_or_pass()
	else:
		current_phase = RoundPhase.REACTION
		_emit_state_changed()
	return true


func _execute_self_draw_hu(seat: int) -> bool:
	if seat < 0 or seat >= players.size():
		return false
	if players[seat]["has_won"]:
		return false

	var winning_tile: Dictionary = {}
	if not last_draw_tile.is_empty() and last_draw_tile["seat"] == seat:
		winning_tile = last_draw_tile["tile"].duplicate(true)
	elif not players[seat]["hand_tiles"].is_empty():
		winning_tile = players[seat]["hand_tiles"][players[seat]["hand_tiles"].size() - 1].duplicate(true)

	players[seat]["has_won"] = true
	players[seat]["winning_tile"] = winning_tile.duplicate(true)
	players[seat]["winning_source_seat"] = seat
	var win_type := _resolve_self_draw_win_type(seat)
	players[seat]["win_type"] = win_type
	_apply_special_rule_marks_for_win(seat, win_type)
	if not round_winners.has(seat):
		round_winners.append(seat)
		_append_settlement_win_event(seat, seat, winning_tile, win_type, _get_payer_seats_for_win(win_type, seat))
	if win_type == "gang_self_draw":
		_mark_latest_gang_outcome("gang_self_draw")

	debug_last_message = "%s 自摸成功。当前胡牌：%s" % [
		_seat_display_name(seat),
		_format_winner_list(),
	]

	if _should_enter_battle_end_settlement():
		_enter_settlement_due_to_battle_end()
		_emit_state_changed()
		return true

	var next_seat := _find_next_active_seat_after(seat)
	if next_seat == -1:
		_enter_settlement_due_to_battle_end()
	else:
		current_turn_seat = next_seat
		last_draw_tile = {}
		_begin_turn()
	_emit_state_changed()
	return true


func _consume_claimed_discard(source_seat: int, tile: Dictionary) -> void:
	if source_seat < 0 or source_seat >= players.size():
		return
	var source_discards: Array = players[source_seat].get("discards", [])
	for index in range(source_discards.size() - 1, -1, -1):
		var discard: Dictionary = source_discards[index]
		if int(discard.get("id", -1)) == int(tile.get("id", -1)):
			source_discards.remove_at(index)
			break
	players[source_seat]["discards"] = source_discards

	for index in range(discard_pile.size() - 1, -1, -1):
		var item: Dictionary = discard_pile[index]
		if int(item.get("seat", -1)) == source_seat and int(item.get("tile", {}).get("id", -1)) == int(tile.get("id", -1)):
			discard_pile.remove_at(index)
			break


func _consume_qiang_gang_robbed_tile() -> void:
	if pending_qiang_gang_context.is_empty():
		return
	if bool(pending_qiang_gang_context.get("robbed_tile_removed", false)):
		return
	var actor_seat: int = int(pending_qiang_gang_context.get("actor_seat", -1))
	var tile: Dictionary = pending_qiang_gang_context.get("tile", {})
	if actor_seat < 0 or actor_seat >= players.size() or tile.is_empty():
		return
	if _remove_tile_from_hand_by_id(actor_seat, int(tile.get("id", -1))):
		pending_qiang_gang_context["robbed_tile_removed"] = true


func _remove_matching_tiles_from_hand(seat: int, target_tile: Dictionary, count_needed: int) -> Array[Dictionary]:
	var removed_tiles: Array[Dictionary] = []
	var hand_tiles: Array = players[seat]["hand_tiles"]
	var remove_indices: Array[int] = []

	for index in range(hand_tiles.size()):
		var tile: Dictionary = hand_tiles[index]
		if tile["suit"] == target_tile["suit"] and tile["rank"] == target_tile["rank"]:
			remove_indices.append(index)
			removed_tiles.append(tile)
			if removed_tiles.size() == count_needed:
				break

	if removed_tiles.size() != count_needed:
		return []

	remove_indices.reverse()
	for index in remove_indices:
		hand_tiles.remove_at(index)
	players[seat]["hand_tiles"] = hand_tiles
	players[seat]["hand_count"] = hand_tiles.size()
	return removed_tiles


func _get_reaction_candidate_for_seat(seat: int) -> Dictionary:
	for candidate in pending_reactions:
		if candidate["seat"] == seat:
			return candidate
	return {}


func _get_next_ai_reaction_candidate() -> Dictionary:
	var best_candidate: Dictionary = {}
	var best_priority := -1
	var best_distance := 99
	var source_seat: int = int(current_discard_context.get("source_seat", -1))

	for candidate in pending_reactions:
		var seat: int = candidate["seat"]
		if seat < 0 or seat >= players.size() or not players[seat]["is_ai"]:
			continue

		var priority: int = mahjong_judge.get_candidate_priority(candidate)
		var distance := _reaction_distance_from_source(source_seat, seat)
		if priority > best_priority or (priority == best_priority and distance < best_distance):
			best_candidate = candidate
			best_priority = priority
			best_distance = distance

	return best_candidate


func _remove_reaction_candidate_for_seat(seat: int) -> void:
	for index in range(pending_reactions.size()):
		if pending_reactions[index]["seat"] == seat:
			pending_reactions.remove_at(index)
			return


func _pass_ai_reaction(seat: int) -> bool:
	_remove_reaction_candidate_for_seat(seat)
	debug_last_message = "AI seat %d passed. Remaining reactions: %s" % [
		seat,
		mahjong_judge.summarize_candidates(pending_reactions),
	]
	if pending_reactions.is_empty():
		if str(current_discard_context.get("reaction_type", "discard")) == "qiang_gang_hu":
			_finalize_qiang_gang_after_hu_or_pass()
		else:
			_finalize_reaction_after_hu_or_pass()
	else:
		_emit_state_changed()
	return true


func _has_higher_priority_candidate_than(seat: int, action: String) -> bool:
	var current_priority := _priority_for_action(action)
	var source_seat: int = int(current_discard_context.get("source_seat", -1))
	var current_distance := _reaction_distance_from_source(source_seat, seat)

	for candidate in pending_reactions:
		if candidate["seat"] == seat:
			continue
		var priority: int = mahjong_judge.get_candidate_priority(candidate)
		if priority > current_priority:
			return true
		if priority == current_priority and priority > 0:
			var distance := _reaction_distance_from_source(source_seat, candidate["seat"])
			if distance < current_distance:
				return true
	return false


func _priority_for_action(action: String) -> int:
	match action:
		"hu":
			return 3
		"gang":
			return 2
		"peng":
			return 1
		_:
			return 0


func _reaction_distance_from_source(source_seat: int, target_seat: int) -> int:
	if source_seat == -1:
		return 99
	return posmod(source_seat - target_seat, players.size())


func _finalize_reaction_without_claim() -> void:
	pending_ai_reaction_decision.clear()
	pending_ai_turn_decision.clear()
	_clear_pending_ai_async_state()
	_clear_reaction_context()
	_advance_turn_after_discard()
	_emit_state_changed()


func _finalize_reaction_after_hu_or_pass() -> void:
	if _should_enter_battle_end_settlement():
		_enter_settlement_due_to_battle_end()
		_emit_state_changed()
		return

	var source_seat: int = int(current_discard_context.get("source_seat", current_turn_seat))
	var winner_seats: Array = current_discard_context.get("winner_seats", [])
	pending_ai_reaction_decision.clear()
	pending_ai_turn_decision.clear()
	_clear_pending_ai_async_state()
	_clear_reaction_context()
	var next_seat := _resolve_resume_seat_after_discard_hu(source_seat, winner_seats)
	if next_seat == -1:
		_enter_settlement_due_to_battle_end()
	else:
		current_turn_seat = next_seat
		_begin_turn()
	_emit_state_changed()


func _finalize_qiang_gang_after_hu_or_pass() -> void:
	if pending_qiang_gang_context.is_empty():
		_finalize_reaction_after_hu_or_pass()
		return

	if _should_enter_battle_end_settlement():
		_enter_settlement_due_to_battle_end()
		_emit_state_changed()
		return

	var qiang_status: String = str(pending_qiang_gang_context.get("status", ""))
	if qiang_status == "claimed_by_hu":
		var actor_seat: int = int(pending_qiang_gang_context.get("actor_seat", current_turn_seat))
		var winner_seats: Array = pending_qiang_gang_context.get("winner_seats", [])
		pending_qiang_gang_context.clear()
		_clear_reaction_context()
		var next_seat := _resolve_resume_seat_after_discard_hu(actor_seat, winner_seats)
		if next_seat == -1:
			_enter_settlement_due_to_battle_end()
		else:
			current_turn_seat = next_seat
			_begin_turn()
		_emit_state_changed()
		return

	if round_winners.has(int(pending_qiang_gang_context.get("actor_seat", -1))):
		_mark_pending_qiang_gang_resolution("actor_already_won")
		pending_qiang_gang_context.clear()
		_clear_reaction_context()
		_emit_state_changed()
		return

	_mark_pending_qiang_gang_resolution("no_claim_then_add_gang")
	_finalize_add_gang_without_qiang()


func _filter_pending_reactions_after_hu() -> void:
	var filtered: Array[Dictionary] = []
	for candidate in pending_reactions:
		if not candidate.get("can_hu", false):
			continue
		if players[candidate["seat"]]["has_won"]:
			continue
		filtered.append(candidate)
	pending_reactions = filtered
	if not rules.allow_multi_win_on_discard:
		pending_reactions.clear()


func _should_enter_battle_end_settlement() -> bool:
	if round_winners.size() >= rules.max_winners_per_round:
		return true
	return _count_active_players() <= 1


func _count_active_players() -> int:
	var count := 0
	for player in players:
		if not player["has_won"]:
			count += 1
	return count


func _find_next_active_seat_after(from_seat: int) -> int:
	if players.is_empty():
		return -1
	for step in range(1, players.size() + 1):
		var seat := posmod(from_seat - step, players.size())
		if not players[seat]["has_won"]:
			return seat
	return -1


func _resolve_resume_seat_after_discard_hu(source_seat: int, winner_seats: Array) -> int:
	if winner_seats.is_empty():
		return _find_next_active_seat_after(source_seat)
	var last_winner := source_seat
	for step in range(1, players.size() + 1):
		var seat := posmod(source_seat - step, players.size())
		if winner_seats.has(seat):
			last_winner = seat
	return _find_next_active_seat_after(last_winner)


func _get_active_non_winner_seats_excluding(seat: int) -> Array:
	var result: Array = []
	for player in players:
		var target_seat: int = player["seat"]
		if target_seat == seat or player.get("has_won", false):
			continue
		result.append(target_seat)
	return result


func _get_payer_seats_for_win(win_type: String, source_seat: int) -> Array:
	match win_type:
		"self_draw", "gang_self_draw":
			return _get_active_non_winner_seats_excluding(int(current_turn_seat))
		"discard_win", "gang_discard_win", "qiang_gang_hu":
			return [source_seat]
		_:
			return [source_seat]


func _build_draw_settlement_assessment() -> void:
	var assessment: Array = []
	var ting_seats: Array[int] = []
	var no_ting_seats: Array[int] = []
	var hua_zhu_seats: Array[int] = []
	var use_hua_zhu := false if rules == null else bool(rules.enable_hua_zhu)

	for player in players:
		if player.get("has_won", false):
			continue
		var hand_tiles: Array = player.get("hand_tiles", [])
		var suit_count: int = _count_distinct_suits(hand_tiles)
		var has_ding_que_tiles: bool = _contains_ding_que_tiles(player)
		var hua_zhu: bool = use_hua_zhu and (suit_count == 3 or has_ding_que_tiles)
		var ting_tiles: Array = mahjong_judge.get_ting_tiles(_build_player_state(int(player.get("seat", -1))), rules)
		var is_ting: bool = not hua_zhu and not ting_tiles.is_empty()
		var cha_jiao_detail := _resolve_cha_jiao_detail(player, ting_tiles)
		var item := {
			"seat": player["seat"],
			"hua_zhu": hua_zhu,
			"is_ting": is_ting,
			"is_bao_jiao": bool(player.get("bao_jiao", false)),
			"ting_tiles": ting_tiles,
			"cha_jiao_fan": int(cha_jiao_detail.get("fan", 0)),
			"cha_jiao_score": int(cha_jiao_detail.get("score", 0)),
			"cha_jiao_tile": cha_jiao_detail.get("tile", {}).duplicate(true),
			"distinct_suit_count": suit_count,
			"has_ding_que_tiles": has_ding_que_tiles,
		}
		assessment.append(item)
		if hua_zhu:
			hua_zhu_seats.append(player["seat"])
		elif is_ting:
			ting_seats.append(player["seat"])
		else:
			no_ting_seats.append(player["seat"])

	settlement_data["draw_assessment"] = assessment
	settlement_data["tui_gang_refunds"] = _build_tui_gang_refunds(ting_seats, no_ting_seats, hua_zhu_seats)


func _resolve_cha_jiao_detail(player: Dictionary, ting_tiles: Array) -> Dictionary:
	var best_fan := 0
	var best_score := 0
	var best_tile: Dictionary = {}
	for tile in ting_tiles:
		var fan_detail: Dictionary = score_resolver.build_event_fan_detail(player, tile, "discard_win", rules)
		var capped_fan: int = int(fan_detail.get("capped_fan", 0))
		var basic_score := _resolve_basic_score_from_fan(capped_fan)
		if basic_score > best_score or (basic_score == best_score and capped_fan > best_fan):
			best_fan = capped_fan
			best_score = basic_score
			best_tile = tile.duplicate(true)
	return {
		"fan": best_fan,
		"score": best_score,
		"tile": best_tile,
	}


func _resolve_basic_score_from_fan(capped_fan: int) -> int:
	if rules != null and bool(rules.is_neijiang_mode()):
		if capped_fan <= 1:
			return 1
		if capped_fan == 2:
			return 2
		if capped_fan == 3:
			return 4
		if capped_fan == 4:
			return 8
		return 16
	if capped_fan <= 0:
		return 1
	return int(pow(2.0, capped_fan - 1))


func _score_bao_jiao_plan(seat: int, simulated_hand: Array, plan: Dictionary) -> int:
	if seat < 0 or seat >= players.size():
		return -999999
	var player: Dictionary = players[seat]
	var ting_tiles: Array = plan.get("ting_tiles", [])
	if ting_tiles.is_empty():
		return -999999
	var visible_counts := _build_visible_tile_counts_for_bao_jiao(simulated_hand)
	var live_total := 0
	var ka_er_tiao_bonus := 0
	for tile in ting_tiles:
		var key := _tile_key(tile)
		live_total += maxi(0, 4 - int(visible_counts.get(key, 0)))
		if str(tile.get("suit", "")) == "tiao" and int(tile.get("rank", 0)) == 2:
			ka_er_tiao_bonus = 24
	var cha_jiao_detail := _resolve_cha_jiao_detail(player, ting_tiles)
	var cha_jiao_score: int = int(cha_jiao_detail.get("score", 0))
	var cha_jiao_fan: int = int(cha_jiao_detail.get("fan", 0))
	var score := 0
	score += ting_tiles.size() * 28
	score += live_total * 10
	score += cha_jiao_score * 24
	score += cha_jiao_fan * 12
	score += ka_er_tiao_bonus
	score += int(Array(plan.get("bao_gang_keys", [])).size()) * 8
	if wall_count <= _bao_jiao_bonus_wall_threshold():
		score += 18
	if wall_count <= _bao_jiao_force_ready_wall_threshold():
		score += 24
	return score


func _count_live_tiles_for_ting(ting_tiles: Array) -> int:
	var visible_counts := _build_visible_tile_counts_for_bao_jiao([])
	var live_total := 0
	for tile in ting_tiles:
		var key := _tile_key(tile)
		live_total += maxi(0, 4 - int(visible_counts.get(key, 0)))
	return live_total


func _build_visible_tile_counts_for_bao_jiao(simulated_hand: Array) -> Dictionary:
	var counts := {}
	for tile in simulated_hand:
		var key := _tile_key(tile)
		counts[key] = int(counts.get(key, 0)) + 1
	for player in players:
		for discard in player.get("discards", []):
			var discard_key := _tile_key(discard)
			counts[discard_key] = int(counts.get(discard_key, 0)) + 1
		for meld in player.get("melds", []):
			for tile in meld.get("tiles", []):
				var meld_key := _tile_key(tile)
				counts[meld_key] = int(counts.get(meld_key, 0)) + 1
	return counts


func _is_bao_gang_ting_pattern_preserved(base_ting_tiles: Array, candidate_ting_tiles: Array) -> bool:
	if base_ting_tiles.is_empty() or candidate_ting_tiles.is_empty():
		return false
	var base_keys := {}
	var candidate_keys := {}
	for tile in base_ting_tiles:
		base_keys[_tile_key(tile)] = true
	for tile in candidate_ting_tiles:
		candidate_keys[_tile_key(tile)] = true
	var overlap := 0
	for tile in base_ting_tiles:
		if candidate_keys.has(_tile_key(tile)):
			overlap += 1
	if overlap > 0 and candidate_keys.size() >= maxi(base_keys.size(), 1):
		return true
	return candidate_keys.size() > base_keys.size()


func _bao_jiao_threshold_for_seat(seat: int) -> int:
	var threshold := 110
	if rules != null and bool(rules.is_neijiang_mode()):
		threshold = 126
	if wall_count <= _bao_jiao_bonus_wall_threshold():
		threshold -= 12
	if wall_count <= _bao_jiao_mid_wall_threshold():
		threshold -= 12
	if wall_count <= _bao_jiao_low_wall_threshold():
		threshold -= 18
	var player: Dictionary = players[seat]
	var meld_count: int = int(player.get("melds", []).size())
	if meld_count >= 2:
		threshold -= 8
	return maxi(42, threshold)


func _bao_jiao_bonus_wall_threshold() -> int:
	if rules != null and bool(rules.is_neijiang_mode()):
		return 14
	return 24


func _bao_jiao_mid_wall_threshold() -> int:
	if rules != null and bool(rules.is_neijiang_mode()):
		return 9
	return 16


func _bao_jiao_low_wall_threshold() -> int:
	if rules != null and bool(rules.is_neijiang_mode()):
		return 4
	return 8


func _bao_jiao_force_ready_wall_threshold() -> int:
	if rules != null and bool(rules.is_neijiang_mode()):
		return 7
	return 12


func _count_distinct_suits(hand_tiles: Array) -> int:
	var suits := {}
	for tile in hand_tiles:
		suits[tile.get("suit", "")] = true
	return suits.size()


func _contains_ding_que_tiles(player: Dictionary) -> bool:
	var ding_que: String = player.get("ding_que", "")
	if ding_que == "":
		return false
	for tile in player.get("hand_tiles", []):
		if tile.get("suit", "") == ding_que:
			return true
	return false


func _build_tui_gang_refunds(ting_seats: Array, no_ting_seats: Array, hua_zhu_seats: Array) -> Array:
	var refunds: Array = []
	if no_ting_seats.is_empty() and hua_zhu_seats.is_empty():
		return refunds

	var refund_actor_seats := {}
	for seat in no_ting_seats:
		refund_actor_seats[int(seat)] = true
	for seat in hua_zhu_seats:
		refund_actor_seats[int(seat)] = true

	for event in settlement_data.get("gang_events", []):
		var outcome: String = str(event.get("related_outcome", ""))
		if outcome != "":
			continue
		var actor_seat: int = int(event.get("actor_seat", -1))
		if not refund_actor_seats.has(actor_seat):
			continue
		refunds.append(
			{
				"actor_seat": actor_seat,
				"gang_type": str(event.get("gang_type", "")),
				"payer_seats": event.get("payer_seats", []).duplicate(),
				"refund_reason": "draw_tui_gang",
			}
		)
	return refunds


func _format_winner_list() -> String:
	if round_winners.is_empty():
		return "-"
	var parts: Array[String] = []
	for seat in round_winners:
		parts.append(_seat_display_name(int(seat)))
	return ", ".join(parts)


func _seat_display_name(seat: int) -> String:
	if seat >= 0 and seat < players.size():
		var player: Dictionary = players[seat]
		var nickname := str(player.get("nickname", ""))
		if not nickname.is_empty():
			return nickname
	match seat:
		0:
			return "本家"
		1:
			return "上家"
		2:
			return "对家"
		3:
			return "下家"
		_:
			return "座位%d" % seat


func _resolve_next_dealer_seat() -> int:
	var end_reason: String = str(settlement_data.get("end_reason", ""))
	if end_reason == "draw_wall_empty":
		return posmod(current_dealer_seat - 1, players.size())
	var win_events: Array = settlement_data.get("win_events", [])
	if win_events.is_empty():
		return posmod(current_dealer_seat - 1, players.size())
	var dealer_keeps := false
	for event in win_events:
		if int(event.get("winner_seat", -1)) == current_dealer_seat:
			dealer_keeps = true
			break
	if dealer_keeps:
		return current_dealer_seat
	return posmod(current_dealer_seat - 1, players.size())


func _consume_next_draw_reason() -> String:
	if not last_gang_context.is_empty() and not last_gang_context.get("resolved", false):
		last_gang_context["resolved"] = true
		return "gang_draw"
	return "normal_draw"


func _resolve_self_draw_win_type(seat: int) -> String:
	if last_turn_context.get("seat", -1) == seat and last_turn_context.get("draw_reason", "") == "gang_draw":
		return "gang_self_draw"
	return "self_draw"


func _resolve_discard_win_type(source_seat: int, reaction_type: String = "discard") -> String:
	if reaction_type == "qiang_gang_hu":
		return "qiang_gang_hu"
	if last_turn_context.get("seat", -1) == source_seat and last_turn_context.get("draw_reason", "") == "gang_draw":
		return "gang_discard_win"
	return "discard_win"


func _create_empty_settlement_data() -> Dictionary:
	return {
		"round_index": round_index,
		"dealer_seat": current_dealer_seat,
		"end_reason": "",
		"winner_seats": [],
		"win_events": [],
		"gang_events": [],
		"kong_resolution_events": [],
		"transfer_events": [],
		"qiang_gang_hu_placeholders": [],
		"draw_assessment": [],
		"tui_gang_refunds": [],
		"score_changes": {},
		"scores_applied": false,
		"notes": [
			"当前结算已接入内江血战式流程、抢杠胡、呼叫转移、退税与流局查叫主链。",
			"杠分在存在未胡玩家时不计入最终分数，相关事件仍会保留在结算明细中。",
			"如后续补充海底、查大叫加严版细则，可在此结构继续扩展。",
		],
		"pending_features": [],
		"summary_text": "",
	}


func _append_settlement_win_event(winner_seat: int, source_seat: int, winning_tile: Dictionary, win_type: String, payer_seats: Array) -> void:
	var events: Array = settlement_data.get("win_events", [])
	var fan_detail: Dictionary = score_resolver.build_event_fan_detail(players[winner_seat], winning_tile, win_type, rules)
	events.append(
		{
			"winner_seat": winner_seat,
			"source_seat": source_seat,
			"winning_tile": winning_tile.duplicate(true),
			"win_type": win_type,
			"payer_seats": payer_seats.duplicate(),
			"fan_detail": fan_detail,
		}
	)
	settlement_data["win_events"] = events
	settlement_data["winner_seats"] = round_winners.duplicate()
	_rebuild_settlement_summary()


func _append_settlement_gang_event(actor_seat: int, source_seat: int, tile: Dictionary, gang_type: String, payer_seats: Array) -> void:
	var events: Array = settlement_data.get("gang_events", [])
	events.append(
		{
			"actor_seat": actor_seat,
			"source_seat": source_seat,
			"tile": tile.duplicate(true),
			"gang_type": gang_type,
			"related_outcome": "",
			"payer_seats": payer_seats.duplicate(),
		}
	)
	settlement_data["gang_events"] = events
	_append_kong_resolution_event(actor_seat, source_seat, tile, gang_type, "pending_review")
	_rebuild_settlement_summary()


func _mark_latest_gang_outcome(outcome: String) -> void:
	var events: Array = settlement_data.get("gang_events", [])
	if events.is_empty():
		return
	var last_index := events.size() - 1
	var event: Dictionary = events[last_index]
	event["related_outcome"] = outcome
	events[last_index] = event
	settlement_data["gang_events"] = events
	_mark_latest_kong_resolution_outcome(outcome)
	_rebuild_settlement_summary()


func _append_kong_resolution_event(actor_seat: int, source_seat: int, tile: Dictionary, gang_type: String, resolution_state: String) -> void:
	var events: Array = settlement_data.get("kong_resolution_events", [])
	events.append(
		{
			"actor_seat": actor_seat,
			"source_seat": source_seat,
			"tile": tile.duplicate(true),
			"gang_type": gang_type,
			"resolution_state": resolution_state,
			"related_outcome": "",
		}
	)
	settlement_data["kong_resolution_events"] = events


func _mark_latest_kong_resolution_outcome(outcome: String) -> void:
	var events: Array = settlement_data.get("kong_resolution_events", [])
	if events.is_empty():
		return
	var last_index := events.size() - 1
	var event: Dictionary = events[last_index]
	event["related_outcome"] = outcome
	if outcome == "gang_discard_win":
		event["resolution_state"] = "needs_tui_gang_and_transfer_review"
	elif outcome == "gang_self_draw":
		event["resolution_state"] = "gang_shang_hua_pending_score"
	events[last_index] = event
	settlement_data["kong_resolution_events"] = events


func _append_transfer_event(from_seat: int, to_seat: int, tile: Dictionary, transfer_type: String, reason: String) -> void:
	var events: Array = settlement_data.get("transfer_events", [])
	events.append(
		{
			"from_seat": from_seat,
			"to_seat": to_seat,
			"tile": tile.duplicate(true),
			"transfer_type": transfer_type,
			"reason": reason,
		}
	)
	settlement_data["transfer_events"] = events
	_rebuild_settlement_summary()


func _append_hu_jiao_zhuan_yi_event(from_seat: int, to_seat: int, tile: Dictionary) -> void:
	var gang_event := _find_latest_transferable_gang_event(from_seat)
	if gang_event.is_empty():
		_append_transfer_event(from_seat, to_seat, tile, "hu_jiao_zhuan_yi", "杠后打出的补牌被胡，按呼叫转移处理。")
		return
	var transfer_payer_seats: Array = []
	for payer in gang_event.get("payer_seats", []):
		var payer_seat: int = int(payer)
		if payer_seat == to_seat:
			continue
		transfer_payer_seats.append(payer_seat)

	var events: Array = settlement_data.get("transfer_events", [])
	events.append(
		{
			"from_seat": from_seat,
			"to_seat": to_seat,
			"tile": tile.duplicate(true),
			"transfer_type": "hu_jiao_zhuan_yi",
			"reason": "杠后打出的补牌被胡，按呼叫转移处理。",
			"gang_type": str(gang_event.get("gang_type", "")),
			"payer_seats": transfer_payer_seats,
			"related_actor_seat": int(gang_event.get("actor_seat", -1)),
		}
	)
	settlement_data["transfer_events"] = events
	_rebuild_settlement_summary()


func _append_qiang_gang_hu_placeholder(actor_seat: int, tile: Dictionary, placeholder_type: String) -> void:
	var items: Array = settlement_data.get("qiang_gang_hu_placeholders", [])
	items.append(
		{
			"actor_seat": actor_seat,
			"tile": tile.duplicate(true),
			"placeholder_type": placeholder_type,
			"status": "registered",
		}
	)
	settlement_data["qiang_gang_hu_placeholders"] = items
	_rebuild_settlement_summary()


func _register_qiang_gang_context(actor_seat: int, tile: Dictionary, placeholder_type: String) -> void:
	var preserved_context: Dictionary = pending_qiang_gang_context.duplicate(true)
	pending_qiang_gang_context = preserved_context
	pending_qiang_gang_context["actor_seat"] = actor_seat
	pending_qiang_gang_context["tile"] = tile.duplicate(true)
	pending_qiang_gang_context["placeholder_type"] = placeholder_type
	pending_qiang_gang_context["status"] = "waiting_for_add_gang_flow"
	_append_qiang_gang_hu_placeholder(actor_seat, tile, placeholder_type)


func _mark_pending_qiang_gang_resolution(status: String) -> void:
	if pending_qiang_gang_context.is_empty():
		return
	pending_qiang_gang_context["status"] = status
	var items: Array = settlement_data.get("qiang_gang_hu_placeholders", [])
	if items.is_empty():
		return
	var last_index := items.size() - 1
	var item: Dictionary = items[last_index]
	item["status"] = status
	items[last_index] = item
	settlement_data["qiang_gang_hu_placeholders"] = items
	_rebuild_settlement_summary()


func _rebuild_settlement_summary() -> void:
	settlement_data["round_index"] = round_index
	settlement_data["dealer_seat"] = current_dealer_seat
	settlement_data["winner_seats"] = round_winners.duplicate()
	settlement_data["score_changes"] = score_resolver.build_score_changes(players, settlement_data, rules)
	_apply_settlement_scores_once()

	var lines: Array[String] = []
	lines.append("第 %d 局｜庄家 %s" % [round_index, _seat_display_name(current_dealer_seat)])

	var end_reason: String = str(settlement_data.get("end_reason", ""))
	match end_reason:
		"battle_end":
			lines.append("结束原因：内江血战终局条件")
		"draw_wall_empty":
			lines.append("结束原因：牌墙摸完流局")
		_:
			lines.append("结束原因：进行中或未定")

	if round_winners.is_empty():
		lines.append("胡牌结果：暂无胡牌者")
	else:
		lines.append("胡牌结果：%s" % _format_winner_list())
	lines.append("下局庄家：%s" % _seat_display_name(_resolve_next_dealer_seat()))

	var events: Array = settlement_data.get("win_events", [])
	if events.is_empty():
		lines.append("胡牌事件：暂无")
	else:
		for event in events:
			var winner_seat: int = int(event.get("winner_seat", -1))
			var source_seat: int = int(event.get("source_seat", -1))
			var tile_name := "?"
			var winning_tile: Dictionary = event.get("winning_tile", {})
			if not winning_tile.is_empty():
				tile_name = winning_tile.get("display_name", "?")
			var win_type: String = str(event.get("win_type", "discard_win"))
			var fan_detail: Dictionary = event.get("fan_detail", {})
			var hand_type: String = _hand_type_display_name(str(fan_detail.get("hand_type", "ping_hu")))
			var fan_text := _format_fan_score_text(fan_detail, win_type)
			var labels: Array = fan_detail.get("labels", [])
			var label_text := "/".join(labels)
			if win_type == "self_draw" or win_type == "gang_self_draw":
				lines.append("胡牌事件：%s %s %s｜%s｜%s｜%s" % [
					_seat_display_name(winner_seat),
					_win_type_display_name(win_type),
					tile_name,
					hand_type,
					fan_text,
					label_text,
				])
			else:
				lines.append("胡牌事件：%s %s %s 的 %s｜%s｜%s｜%s" % [
					_seat_display_name(winner_seat),
					_win_type_display_name(win_type),
					_seat_display_name(source_seat),
					tile_name,
					hand_type,
					fan_text,
					label_text,
				])

	var gang_events: Array = settlement_data.get("gang_events", [])
	if gang_events.is_empty():
		lines.append("杠事件：暂无")
	else:
		for event in gang_events:
			var actor_seat: int = int(event.get("actor_seat", -1))
			var source_seat: int = int(event.get("source_seat", -1))
			var tile_name := "?"
			var tile: Dictionary = event.get("tile", {})
			if not tile.is_empty():
				tile_name = tile.get("display_name", "?")
			var gang_type: String = str(event.get("gang_type", "melded_gang"))
			var outcome: String = str(event.get("related_outcome", ""))
			var line := "杠事件：%s %s %s" % [_seat_display_name(actor_seat), _gang_type_display_name(gang_type), tile_name]
			if source_seat != actor_seat and source_seat != -1:
				line += "（来自 %s）" % _seat_display_name(source_seat)
			if outcome != "":
				line += " -> %s" % _win_type_display_name(outcome)
			lines.append(line)

	var kong_resolution_events: Array = settlement_data.get("kong_resolution_events", [])
	if kong_resolution_events.is_empty():
		lines.append("杠结算审查：暂无")
	else:
		for event in kong_resolution_events:
			var actor_seat: int = int(event.get("actor_seat", -1))
			var state_text: String = _resolution_state_display_name(str(event.get("resolution_state", "pending_review")))
			lines.append("杠结算审查：%s -> %s" % [_seat_display_name(actor_seat), state_text])

	var transfer_events: Array = settlement_data.get("transfer_events", [])
	if transfer_events.is_empty():
		lines.append("转移事件：暂无")
	else:
		for event in transfer_events:
			var from_seat: int = int(event.get("from_seat", -1))
			var to_seat: int = int(event.get("to_seat", -1))
			lines.append("转移事件：%s -> %s｜%s" % [
				_seat_display_name(from_seat),
				_seat_display_name(to_seat),
				_transfer_type_display_name(str(event.get("transfer_type", ""))),
			])

	var qiang_gang_items: Array = settlement_data.get("qiang_gang_hu_placeholders", [])
	if qiang_gang_items.is_empty():
		lines.append("抢杠胡占位：暂无")
	else:
		for item in qiang_gang_items:
			lines.append("抢杠胡占位：%s｜%s｜%s" % [
				_seat_display_name(int(item.get("actor_seat", -1))),
				str(item.get("placeholder_type", "")),
				str(item.get("status", "")),
			])

	if not shun_he_locks.is_empty():
		for seat in shun_he_locks.keys():
			var info: Dictionary = shun_he_locks[seat]
			lines.append("顺和限制：%s｜锁定至高于 %d 番" % [_seat_display_name(int(seat)), int(info.get("min_fan", 0))])

	var draw_assessment: Array = settlement_data.get("draw_assessment", [])
	if not draw_assessment.is_empty():
		for item in draw_assessment:
			var seat: int = int(item.get("seat", -1))
			var tags: Array[String] = []
			if item.get("hua_zhu", false):
				tags.append("花猪")
			elif item.get("is_ting", false):
				tags.append("报叫" if item.get("is_bao_jiao", false) else "有叫")
			else:
				tags.append("报叫未成" if item.get("is_bao_jiao", false) else "未叫")
			if bool(item.get("is_ting", false)):
				tags.append("%d番/%d分" % [
					maxi(1, int(item.get("cha_jiao_fan", 0))),
					maxi(1, int(item.get("cha_jiao_score", 0))),
				])
			var ting_tiles: Array = item.get("ting_tiles", [])
			if not ting_tiles.is_empty():
				var names: Array[String] = []
				for tile in ting_tiles:
					names.append(tile.get("display_name", "?"))
				tags.append("听%s" % "/".join(names))
			lines.append("流局判定：%s｜%s" % [_seat_display_name(seat), "｜".join(tags)])

	var tui_gang_refunds: Array = settlement_data.get("tui_gang_refunds", [])
	if tui_gang_refunds.is_empty():
		lines.append("退税：暂无")
	else:
		for refund in tui_gang_refunds:
			lines.append("退税：%s 的 %s 需退回给 %s" % [
				_seat_display_name(int(refund.get("actor_seat", -1))),
				_gang_type_display_name(str(refund.get("gang_type", ""))),
				_refund_payers_display(refund.get("payer_seats", [])),
			])

	lines.append("积分变化：%s" % _format_score_change_summary(settlement_data["score_changes"]))
	for review_line in _build_trainer_review_lines():
		lines.append(review_line)
	settlement_data["summary_text"] = "\n".join(lines)


func _apply_settlement_scores_once() -> void:
	if current_phase != RoundPhase.SETTLEMENT:
		return
	if bool(settlement_data.get("scores_applied", false)):
		return
	var score_changes: Dictionary = settlement_data.get("score_changes", {})
	for player in players:
		var seat: int = int(player.get("seat", -1))
		player["score"] = int(player.get("score", STARTING_SCORE)) + int(score_changes.get(seat, 0))
	settlement_data["scores_applied"] = true
	_update_ai_learning_after_round(score_changes)


func _format_score_change_summary(score_changes: Dictionary) -> String:
	var parts: Array[String] = []
	for player in players:
		var seat: int = player["seat"]
		var delta: int = int(score_changes.get(seat, 0))
		var prefix := "+" if delta > 0 else ""
		parts.append("%s %s%d" % [_seat_display_name(seat), prefix, delta])
	return " | ".join(parts)


func _format_fan_score_text(fan_detail: Dictionary, win_type: String = "") -> String:
	var capped_fan := int(fan_detail.get("capped_fan", 0))
	var hand_score := int(fan_detail.get("hand_score", _resolve_basic_score_from_fan(capped_fan)))
	var basic_score := int(fan_detail.get("per_payer_score", hand_score))
	if (win_type == "self_draw" or win_type == "gang_self_draw") and not fan_detail.has("per_payer_score"):
		basic_score += 1
	var fan_text := "%d番（封顶）" % capped_fan if rules != null and bool(rules.is_neijiang_mode()) and capped_fan >= 5 else "%d番" % capped_fan
	if basic_score != hand_score and (win_type == "self_draw" or win_type == "gang_self_draw"):
		return "%s/%d+自摸1=%d分" % [fan_text, hand_score, basic_score]
	return "%s/%d分" % [fan_text, basic_score]


func _gang_type_display_name(gang_type: String) -> String:
	match gang_type:
		"melded_gang":
			return "明杠"
		"add_gang":
			return "补杠"
		"an_gang":
			return "暗杠"
		_:
			return gang_type


func _win_type_display_name(win_type: String) -> String:
	match win_type:
		"self_draw":
			return "自摸胡"
		"gang_self_draw":
			return "杠上花"
		"gang_discard_win":
			return "杠上炮"
		"qiang_gang_hu":
			return "抢杠胡"
		"discard_win":
			return "点炮胡"
		_:
			return win_type


func _hand_type_display_name(hand_type: String) -> String:
	match hand_type:
		"qing_yi_se":
			return "清一色"
		"qi_dui":
			return "暗七对"
		"long_qi_dui":
			return "龙七对"
		"qing_dui":
			return "清对"
		"qing_qi_dui":
			return "清七对"
		"qing_long_qi_dui":
			return "青龙七对"
		"da_dui_zi":
			return "大对子"
		"ping_hu":
			return "平胡"
		_:
			return hand_type


func _resolution_state_display_name(state: String) -> String:
	match state:
		"pending_review":
			return "待结算审查"
		"needs_tui_gang_and_transfer_review":
			return "待退税/呼叫转移审查"
		"gang_shang_hua_pending_score":
			return "杠上花待记分"
		_:
			return state


func _transfer_type_display_name(transfer_type: String) -> String:
	match transfer_type:
		"hu_jiao_zhuan_yi":
			return "呼叫转移"
		_:
			return transfer_type


func _find_latest_transferable_gang_event(actor_seat: int) -> Dictionary:
	var events: Array = settlement_data.get("gang_events", [])
	for index in range(events.size() - 1, -1, -1):
		var event: Dictionary = events[index]
		if int(event.get("actor_seat", -1)) != actor_seat:
			continue
		return event
	return {}


func _refund_payers_display(payer_seats: Array) -> String:
	if payer_seats.is_empty():
		return "-"
	var parts: Array[String] = []
	for payer in payer_seats:
		parts.append(_seat_display_name(int(payer)))
	return ", ".join(parts)


func _create_player_stub(seat: int, nickname: String, is_ai: bool) -> Dictionary:
	return {
		"seat": seat,
		"nickname": nickname,
		"score": STARTING_SCORE,
		"is_ai": is_ai,
		"ding_que": "",
		"hand_count": 13 if seat != current_dealer_seat else 14,
		"melds": [],
		"discards": [],
	}
