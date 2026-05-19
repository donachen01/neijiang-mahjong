extends Node

const GAME_STATE_SCRIPT := preload("res://autoload/GameState.gd")
const AI_MANAGER_SCRIPT := preload("res://scripts/ai/AIManager.gd")


func _ready() -> void:
	var failures: Array[String] = []
	_run_test("neijiang_mode_uses_two_suits_and_skips_ding_que", _test_neijiang_mode_uses_two_suits_and_skips_ding_que, failures)
	_run_test("neijiang_initial_deal_uses_72_tiles_and_leaves_19_wall", _test_neijiang_initial_deal_uses_72_tiles_and_leaves_19_wall, failures)
	_run_test("neijiang_defaults_to_csharp_primary_turn_analysis", _test_neijiang_defaults_to_csharp_primary_turn_analysis, failures)
	_run_test("neijiang_defaults_to_csharp_primary_reaction_analysis", _test_neijiang_defaults_to_csharp_primary_reaction_analysis, failures)
	_run_test("neijiang_csharp_reaction_passes_risky_late_peng", _test_neijiang_csharp_reaction_passes_risky_late_peng, failures)
	_run_test("neijiang_csharp_reaction_emits_posterior_future_summary", _test_neijiang_csharp_reaction_emits_posterior_future_summary, failures)
	_run_test("neijiang_csharp_reaction_prefers_shape_accelerating_peng", _test_neijiang_csharp_reaction_prefers_shape_accelerating_peng, failures)
	_run_test("neijiang_csharp_reaction_prefers_melded_gang_when_qidui_not_viable", _test_neijiang_csharp_reaction_prefers_melded_gang_when_qidui_not_viable, failures)
	_run_test("neijiang_csharp_reaction_rejects_peng_that_re_discards_same_tile", _test_neijiang_csharp_reaction_rejects_peng_that_re_discards_same_tile, failures)
	_run_test("neijiang_csharp_reaction_search_marks_close_choices", _test_neijiang_csharp_reaction_search_marks_close_choices, failures)
	_run_test("neijiang_csharp_self_action_cli_covers_self_hu_and_gang", _test_neijiang_csharp_self_action_cli_covers_self_hu_and_gang, failures)
	_run_test("neijiang_csharp_self_action_exposes_gang_subtype", _test_neijiang_csharp_self_action_exposes_gang_subtype, failures)
	_run_test("neijiang_reaction_review_log_records_reasoning", _test_neijiang_reaction_review_log_records_reasoning, failures)
	_run_test("neijiang_trainer_hint_uses_two_suit_labels", _test_neijiang_trainer_hint_uses_two_suit_labels, failures)
	_run_test("neijiang_trainer_hint_uses_csharp_analysis", _test_neijiang_trainer_hint_uses_csharp_analysis, failures)
	_run_test("neijiang_dealer_cannot_bao_jiao", _test_neijiang_dealer_cannot_bao_jiao, failures)
	_run_test("neijiang_bao_jiao_plan_is_available_on_opening_ting", _test_neijiang_bao_jiao_plan_is_available_on_opening_ting, failures)
	_run_test("neijiang_bao_jiao_is_opening_ready_only", _test_neijiang_bao_jiao_is_opening_ready_only, failures)
	_run_test("neijiang_opening_bao_jiao_does_not_discard", _test_neijiang_opening_bao_jiao_does_not_discard, failures)
	_run_test("neijiang_opening_bao_jiao_window_blocks_dealer_first_discard", _test_neijiang_opening_bao_jiao_window_blocks_dealer_first_discard, failures)
	_run_test("neijiang_opening_bao_jiao_queue_scans_ai_and_human_players", _test_neijiang_opening_bao_jiao_queue_scans_ai_and_human_players, failures)
	_run_test("neijiang_bao_jiao_blocks_peng_and_discard_gang", _test_neijiang_bao_jiao_blocks_peng_and_discard_gang, failures)
	_run_test("neijiang_bao_jiao_allows_whitelisted_discard_gang", _test_neijiang_bao_jiao_allows_whitelisted_discard_gang, failures)
	_run_test("neijiang_bao_gang_whitelist_requires_keep_ting", _test_neijiang_bao_gang_whitelist_requires_keep_ting, failures)
	_run_test("neijiang_non_whitelist_gang_is_blocked_after_bao_jiao", _test_neijiang_non_whitelist_gang_is_blocked_after_bao_jiao, failures)
	_run_test("neijiang_bao_jiao_payer_pays_extra_on_loss", _test_neijiang_bao_jiao_payer_pays_extra_on_loss, failures)
	_run_test("neijiang_draw_assessment_disables_hua_zhu", _test_neijiang_draw_assessment_disables_hua_zhu, failures)
	_run_test("neijiang_ka_er_tiao_adds_one_fan", _test_neijiang_ka_er_tiao_adds_one_fan, failures)
	_run_test("neijiang_qing_long_qi_dui_is_five_fan_sixteen_points", _test_neijiang_qing_long_qi_dui_is_five_fan_sixteen_points, failures)
	_run_test("neijiang_double_gui_long_qi_dui_is_five_fan_sixteen_points", _test_neijiang_double_gui_long_qi_dui_is_five_fan_sixteen_points, failures)
	_run_test("neijiang_discard_win_does_not_double_count_winning_tile_as_gui", _test_neijiang_discard_win_does_not_double_count_winning_tile_as_gui, failures)
	_run_test("neijiang_qing_yi_se_gui_gang_pao_caps_to_five_fan", _test_neijiang_qing_yi_se_gui_gang_pao_caps_to_five_fan, failures)
	_run_test("neijiang_gui_counts_melds_plus_winning_tile", _test_neijiang_gui_counts_melds_plus_winning_tile, failures)
	_run_test("neijiang_rule_marks_add_special_fans", _test_neijiang_rule_marks_add_special_fans, failures)
	_run_test("neijiang_score_table_matches_expected_points", _test_neijiang_score_table_matches_expected_points, failures)
	_run_test("neijiang_hu_jiao_zhuan_yi_excludes_winner_self_from_payers", _test_neijiang_hu_jiao_zhuan_yi_excludes_winner_self_from_payers, failures)
	_run_test("neijiang_qing_yi_se_gui_gang_pao_with_transfer_scores_twenty", _test_neijiang_qing_yi_se_gui_gang_pao_with_transfer_scores_twenty, failures)
	_run_test("neijiang_auto_marks_tian_he_on_opening_self_hu", _test_neijiang_auto_marks_tian_he_on_opening_self_hu, failures)
	_run_test("neijiang_opening_dealer_self_hu_without_last_draw_is_available", _test_neijiang_opening_dealer_self_hu_without_last_draw_is_available, failures)
	_run_test("neijiang_auto_marks_di_hu_on_dealer_first_discard", _test_neijiang_auto_marks_di_hu_on_dealer_first_discard, failures)
	_run_test("neijiang_auto_marks_hai_di_on_last_tile_win", _test_neijiang_auto_marks_hai_di_on_last_tile_win, failures)
	_run_test("neijiang_draw_assessment_marks_bao_jiao_wei_cheng", _test_neijiang_draw_assessment_marks_bao_jiao_wei_cheng, failures)
	_run_test("neijiang_draw_score_changes_refund_tax_and_pay_ting", _test_neijiang_draw_score_changes_refund_tax_and_pay_ting, failures)
	_run_test("neijiang_battle_end_bao_jiao_wei_cheng_pays_ting", _test_neijiang_battle_end_bao_jiao_wei_cheng_pays_ting, failures)
	_run_test("neijiang_bao_jiao_failed_even_if_ting_still_pays_other_ting", _test_neijiang_bao_jiao_failed_even_if_ting_still_pays_other_ting, failures)
	_run_test("neijiang_settlement_summary_uses_names_and_tax_wording", _test_neijiang_settlement_summary_uses_names_and_tax_wording, failures)
	_run_test("neijiang_ready_discard_beats_non_ready_trim", _test_neijiang_ready_discard_beats_non_ready_trim, failures)
	_run_test("neijiang_ai_prefers_trimming_weak_suit_in_two_suit_mode", _test_neijiang_ai_prefers_trimming_weak_suit_in_two_suit_mode, failures)
	_run_test("neijiang_ai_keeps_ka_er_tiao_ready_shape", _test_neijiang_ai_keeps_ka_er_tiao_ready_shape, failures)
	_run_test("neijiang_ai_prefers_ready_tile_that_avoids_gang_feed", _test_neijiang_ai_prefers_ready_tile_that_avoids_gang_feed, failures)
	_run_test("neijiang_ai_avoids_early_peng_without_ready_gain", _test_neijiang_ai_avoids_early_peng_without_ready_gain, failures)
	_run_test("neijiang_ai_passes_risky_late_peng_under_posterior", _test_neijiang_ai_passes_risky_late_peng_under_posterior, failures)
	_run_test("neijiang_ai_rejects_late_bao_jiao_after_opening", _test_neijiang_ai_rejects_late_bao_jiao_after_opening, failures)
	_run_test("neijiang_ai_preserves_gui_potential_tiles", _test_neijiang_ai_preserves_gui_potential_tiles, failures)
	_run_test("neijiang_ai_penalizes_late_add_gang_when_not_ready", _test_neijiang_ai_penalizes_late_add_gang_when_not_ready, failures)
	_run_test("neijiang_ai_penalizes_high_posterior_add_gang", _test_neijiang_ai_penalizes_high_posterior_add_gang, failures)
	_run_test("neijiang_human_peng_button_hidden_when_higher_priority_blocks", _test_neijiang_human_peng_button_hidden_when_higher_priority_blocks, failures)
	_run_test("neijiang_human_peng_clears_pending_ai_reaction", _test_neijiang_human_peng_clears_pending_ai_reaction, failures)
	_run_test("neijiang_human_peng_8_tiao_ignores_stale_ding_que", _test_neijiang_human_peng_8_tiao_ignores_stale_ding_que, failures)
	_run_test("neijiang_ai_failed_peng_auto_passes", _test_neijiang_ai_failed_peng_auto_passes, failures)
	_run_test("neijiang_pass_reaction_resumes_human_draw_turn", _test_neijiang_pass_reaction_resumes_human_draw_turn, failures)
	_run_test("neijiang_peng_without_draw_does_not_enable_self_hu", _test_neijiang_peng_without_draw_does_not_enable_self_hu, failures)
	_run_test("neijiang_ai_peng_starts_discard_analysis", _test_neijiang_ai_peng_starts_discard_analysis, failures)
	_run_test("neijiang_second_reaction_after_peng_discard_is_fresh", _test_neijiang_second_reaction_after_peng_discard_is_fresh, failures)
	_run_test("neijiang_pass_self_hu_keeps_human_discard_turn", _test_neijiang_pass_self_hu_keeps_human_discard_turn, failures)
	_run_test("neijiang_stale_ding_que_must_not_block_discard", _test_neijiang_stale_ding_que_must_not_block_discard, failures)
	_run_test("neijiang_hybrid_csharp_returns_enriched_candidates", _test_neijiang_hybrid_csharp_returns_enriched_candidates, failures)
	_run_test("neijiang_hybrid_csharp_returns_routes_and_strategy_profile", _test_neijiang_hybrid_csharp_returns_routes_and_strategy_profile, failures)
	_run_test("neijiang_csharp_host_mode_toggle_updates_backend_status", _test_neijiang_csharp_host_mode_toggle_updates_backend_status, failures)
	_run_test("neijiang_csharp_host_mode_analyze_returns_result", _test_neijiang_csharp_host_mode_analyze_returns_result, failures)
	_run_test("neijiang_csharp_exact_safe_tile_reduces_danger", _test_neijiang_csharp_exact_safe_tile_reduces_danger, failures)
	_run_test("neijiang_csharp_belief_posterior_emits_reason", _test_neijiang_csharp_belief_posterior_emits_reason, failures)
	_run_test("neijiang_csharp_learning_record_updates_profile", _test_neijiang_csharp_learning_record_updates_profile, failures)
	_run_test("neijiang_csharp_search_marks_close_candidates", _test_neijiang_csharp_search_marks_close_candidates, failures)
	_run_test("neijiang_ai_manager_records_performance_metrics", _test_neijiang_ai_manager_records_performance_metrics, failures)
	_run_test("neijiang_ai_manager_request_api_updates_state_and_emits", _test_neijiang_ai_manager_request_api_updates_state_and_emits, failures)
	_run_test("neijiang_ai_manager_background_request_pumps_and_emits", _test_neijiang_ai_manager_background_request_pumps_and_emits, failures)
	_run_test("neijiang_turn_analysis_cache_hits_on_same_state", _test_neijiang_turn_analysis_cache_hits_on_same_state, failures)
	_run_test("neijiang_prepare_ai_turn_starts_background_request", _test_neijiang_prepare_ai_turn_starts_background_request, failures)
	_run_test("neijiang_run_ai_turn_executes_after_background_analysis", _test_neijiang_run_ai_turn_executes_after_background_analysis, failures)
	_run_test("neijiang_turn_background_timeout_keeps_waiting_main_chain", _test_neijiang_turn_background_timeout_keeps_waiting_main_chain, failures)
	_run_test("neijiang_reaction_background_timeout_keeps_waiting_main_chain", _test_neijiang_reaction_background_timeout_keeps_waiting_main_chain, failures)
	_run_test("neijiang_slow_reaction_request_keeps_single_csharp_chain", _test_neijiang_slow_reaction_request_keeps_single_csharp_chain, failures)

	if failures.is_empty():
		print("NEIJIANG REGRESSION OK")
		get_tree().quit(0)
	else:
		push_error("NEIJIANG REGRESSION FAILED:\n- " + "\n- ".join(failures))
		get_tree().quit(1)


func _run_test(name: String, callable: Callable, failures: Array[String]) -> void:
	var result = callable.call()
	if result is bool and result:
		print("PASS ", name)
	else:
		failures.append("%s -> %s" % [name, str(result)])


func _test_neijiang_mode_uses_two_suits_and_skips_ding_que():
	var game_state = _build_neijiang_test_game_state()
	if not game_state.rules.is_neijiang_mode():
		return "expected default rule mode to be neijiang"
	if game_state.rules.available_suits != ["tiao", "tong"]:
		return "expected neijiang mode to use only 条/筒, got %s" % [game_state.rules.available_suits]
	game_state.previous_dealer_seat = 0
	game_state.start_new_round(true)
	if not bool(game_state.complete_opening_roll()):
		return "expected opening roll to complete"
	if int(game_state.current_phase) != int(GAME_STATE_SCRIPT.RoundPhase.DISCARD):
		return "expected neijiang opening to skip ding que and enter discard, got %s" % [game_state.current_phase]
	return true


func _test_neijiang_initial_deal_uses_72_tiles_and_leaves_19_wall():
	var game_state = _build_neijiang_test_game_state()
	game_state.previous_dealer_seat = 0
	game_state.start_new_round(true)
	if int(game_state.rules.total_tile_count) != 72:
		return "expected neijiang total tile count 72, got %s" % [game_state.rules.total_tile_count]
	if not bool(game_state.complete_opening_roll()):
		return "expected opening roll to complete"
	if int(game_state.wall_count) != 19:
		return "expected neijiang wall count 19 after initial deal, got %s" % [game_state.wall_count]
	if not Array(game_state.get_human_ding_que_options(0)).is_empty():
		return "expected neijiang to have no ding que options"
	for tile in game_state.wall:
		if str(tile.get("suit", "")) == "wan":
			return "expected neijiang wall to contain no wan tiles"
	return true


func _test_neijiang_defaults_to_csharp_primary_turn_analysis():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(1, [
		_make_tile(1501, "tiao", 2), _make_tile(1502, "tiao", 3), _make_tile(1503, "tiao", 4),
		_make_tile(1504, "tiao", 5), _make_tile(1505, "tiao", 6), _make_tile(1506, "tiao", 7),
		_make_tile(1507, "tong", 2), _make_tile(1508, "tong", 3), _make_tile(1509, "tong", 4),
		_make_tile(1510, "tong", 5), _make_tile(1511, "tong", 6), _make_tile(1512, "tong", 7),
		_make_tile(1513, "tong", 8), _make_tile(1514, "tong", 9),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(1515, "tong", 1)]
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(1516, "tiao", 1)]
	var seat3 := _make_player_neijiang(3, [], [], true)
	seat3["discards"] = [_make_tile(1517, "tong", 2)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 19
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected default neijiang turn analysis to use hybrid_csharp, got %s" % [analysis.get("backend_mode", "")]
	var strategy_profile: Dictionary = analysis.get("strategy_profile", {})
	var dingque_state: Dictionary = strategy_profile.get("dingque_state", {})
	if not bool(dingque_state.get("is_two_suit_table", false)):
		return "expected csharp strategy profile to mark two-suit table, got %s" % [dingque_state]
	if str(dingque_state.get("state_label", "")) == "":
		return "expected non-empty two-suit state_label, got %s" % [dingque_state]
	return true


func _test_neijiang_defaults_to_csharp_primary_reaction_analysis():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	var player := _make_player_neijiang(1, [
		_make_tile(2501, "tiao", 2), _make_tile(2502, "tiao", 3), _make_tile(2503, "tiao", 4),
		_make_tile(2504, "tiao", 5), _make_tile(2505, "tiao", 6), _make_tile(2506, "tiao", 7),
		_make_tile(2507, "tong", 3), _make_tile(2508, "tong", 3),
		_make_tile(2509, "tong", 5), _make_tile(2510, "tong", 6), _make_tile(2511, "tong", 7),
		_make_tile(2512, "tong", 8), _make_tile(2513, "tong", 9),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(2514, "tong", 1), _make_tile(2515, "tong", 2)]
	seat0["bao_jiao"] = true
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(2516, "tiao", 1), _make_tile(2517, "tiao", 9)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(2518, "tong", 4), _make_tile(2519, "tong", 5)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 10
	var candidate := {
		"seat": 1,
		"can_hu": false,
		"can_gang": false,
		"can_peng": true,
		"source_seat": 0,
	}
	var discard_context := {
		"source_seat": 0,
		"tile": _make_tile(2520, "tong", 3),
		"reaction_type": "discard",
	}
	var analysis: Dictionary = game_state.ai_manager.analyze_reaction(
		candidate,
		game_state._build_player_state(1),
		game_state._build_table_state(),
		discard_context,
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	if analysis.is_empty():
		return "expected reaction analysis to return a result"
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected default neijiang reaction analysis to use hybrid_csharp, got %s" % [analysis.get("backend_mode", "")]
	if not analysis.has("action_scores"):
		return "expected csharp reaction analysis to expose action_scores, got %s" % [analysis]
	if int(analysis.get("current_shanten", 99)) < -1:
		return "expected current_shanten to be recorded, got %s" % [analysis.get("current_shanten", null)]
	return true


func _test_neijiang_csharp_reaction_passes_risky_late_peng():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	var player := _make_player_neijiang(1, [
		_make_tile(2551, "tiao", 2), _make_tile(2552, "tiao", 3), _make_tile(2553, "tiao", 4),
		_make_tile(2554, "tiao", 6), _make_tile(2555, "tiao", 7),
		_make_tile(2556, "tong", 2), _make_tile(2557, "tong", 3), _make_tile(2558, "tong", 4),
		_make_tile(2559, "tong", 5), _make_tile(2560, "tong", 5),
		_make_tile(2561, "tong", 7), _make_tile(2562, "tong", 8), _make_tile(2563, "tiao", 9),
	])
	player["discards"] = [
		_make_tile(2564, "tiao", 1), _make_tile(2565, "tong", 1), _make_tile(2566, "tiao", 5),
		_make_tile(2567, "tong", 9), _make_tile(2568, "tiao", 8), _make_tile(2569, "tong", 6),
		_make_tile(2570, "tiao", 1), _make_tile(2571, "tong", 1), _make_tile(2572, "tiao", 5),
	]
	var seat0 := _make_player_neijiang(0, [])
	seat0["bao_jiao"] = true
	seat0["discards"] = [_make_tile(2573, "tong", 2), _make_tile(2574, "tong", 3), _make_tile(2575, "tong", 4)]
	var seat2 := _make_player_neijiang(2, [], [{
		"type": "peng",
		"from_seat": 0,
		"tiles": [_make_tile(2576, "tong", 7), _make_tile(2577, "tong", 7), _make_tile(2578, "tong", 7)]
	}], true)
	seat2["discards"] = [_make_tile(2579, "tiao", 2), _make_tile(2580, "tiao", 3), _make_tile(2581, "tiao", 4)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(2582, "tong", 8), _make_tile(2583, "tong", 9), _make_tile(2584, "tiao", 9)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 7
	var analysis: Dictionary = game_state.ai_manager.analyze_reaction(
		{
			"seat": 1,
			"can_hu": false,
			"can_gang": false,
			"can_peng": true,
			"source_seat": 0,
		},
		game_state._build_player_state(1),
		game_state._build_table_state(),
		{
			"source_seat": 0,
			"tile": _make_tile(2585, "tong", 5),
			"reaction_type": "discard",
		},
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected csharp reaction backend, got %s" % [analysis.get("backend_mode", "")]
	if str(analysis.get("action", "")) != "pass":
		return "expected risky late peng to pass under csharp posterior, got %s" % [analysis]
	return true


func _test_neijiang_csharp_reaction_emits_posterior_future_summary():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	var player := _make_player_neijiang(1, [
		_make_tile(2601, "tiao", 2), _make_tile(2602, "tiao", 3), _make_tile(2603, "tiao", 4),
		_make_tile(2604, "tiao", 5), _make_tile(2605, "tiao", 6), _make_tile(2606, "tiao", 7),
		_make_tile(2607, "tong", 3), _make_tile(2608, "tong", 3),
		_make_tile(2609, "tong", 5), _make_tile(2610, "tong", 6), _make_tile(2611, "tong", 7),
		_make_tile(2612, "tong", 8), _make_tile(2613, "tong", 9),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["bao_jiao"] = true
	seat0["discards"] = [_make_tile(2614, "tong", 1), _make_tile(2615, "tong", 2)]
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(2616, "tiao", 1), _make_tile(2617, "tiao", 9)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(2618, "tong", 4), _make_tile(2619, "tong", 5)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 9
	var analysis: Dictionary = game_state.ai_manager.analyze_reaction(
		{
			"seat": 1,
			"can_hu": false,
			"can_gang": false,
			"can_peng": true,
			"source_seat": 0,
		},
		game_state._build_player_state(1),
		game_state._build_table_state(),
		{
			"source_seat": 0,
			"tile": _make_tile(2620, "tong", 3),
			"reaction_type": "discard",
		},
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	var posterior_summary: Array = analysis.get("posterior_summary", [])
	var future_summary: Array = analysis.get("future_summary", [])
	if posterior_summary.is_empty():
		return "expected posterior_summary to be emitted, got %s" % [analysis]
	if future_summary.is_empty():
		return "expected future_summary to be emitted, got %s" % [analysis]
	return true


func _test_neijiang_csharp_reaction_prefers_shape_accelerating_peng():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	var player := _make_player_neijiang(1, [
		_make_tile(2651, "tiao", 2), _make_tile(2652, "tiao", 3), _make_tile(2653, "tiao", 4),
		_make_tile(2654, "tiao", 6), _make_tile(2655, "tiao", 7),
		_make_tile(2656, "tong", 4), _make_tile(2657, "tong", 5), _make_tile(2658, "tong", 6),
		_make_tile(2659, "tong", 8), _make_tile(2660, "tong", 8),
		_make_tile(2661, "tong", 9), _make_tile(2662, "tong", 9), _make_tile(2663, "tiao", 9),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(2664, "tong", 1), _make_tile(2665, "tiao", 1)]
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(2666, "tiao", 8), _make_tile(2667, "tong", 2)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(2668, "tiao", 5), _make_tile(2669, "tong", 3)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 12
	var analysis: Dictionary = game_state.ai_manager.analyze_reaction(
		{
			"seat": 1,
			"can_hu": false,
			"can_gang": false,
			"can_peng": true,
			"source_seat": 0,
		},
		game_state._build_player_state(1),
		game_state._build_table_state(),
		{
			"source_seat": 0,
			"tile": _make_tile(2670, "tong", 9),
			"reaction_type": "discard",
		},
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected csharp reaction backend, got %s" % [analysis.get("backend_mode", "")]
	if str(analysis.get("action", "")) != "peng":
		return "expected shape-accelerating peng to be chosen, got %s" % [analysis]
	return true


func _test_neijiang_csharp_reaction_prefers_melded_gang_when_qidui_not_viable():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	var player := _make_player_neijiang(1, [
		_make_tile(2671, "tiao", 2), _make_tile(2672, "tiao", 3), _make_tile(2673, "tiao", 4),
		_make_tile(2674, "tiao", 7), _make_tile(2675, "tiao", 7), _make_tile(2676, "tiao", 7),
		_make_tile(2677, "tong", 2), _make_tile(2678, "tong", 3), _make_tile(2679, "tong", 4),
		_make_tile(2680, "tong", 5), _make_tile(2681, "tong", 6), _make_tile(2682, "tong", 7),
		_make_tile(2683, "tiao", 9),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(2684, "tong", 1), _make_tile(2685, "tong", 9)]
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(2686, "tiao", 1), _make_tile(2687, "tong", 8)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(2688, "tong", 2), _make_tile(2689, "tiao", 5)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 24
	var analysis: Dictionary = game_state.ai_manager.analyze_reaction(
		{
			"seat": 1,
			"can_hu": false,
			"can_gang": true,
			"can_peng": true,
			"source_seat": 2,
		},
		game_state._build_player_state(1),
		game_state._build_table_state(),
		{
			"source_seat": 2,
			"tile": _make_tile(2690, "tiao", 7),
			"reaction_type": "discard",
		},
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected csharp reaction backend, got %s" % [analysis.get("backend_mode", "")]
	if str(analysis.get("action", "")) != "gang":
		return "expected non-qidui melded 7条 gang to beat peng/pass, got %s" % [analysis]
	var reasons: Array = analysis.get("reasons", [])
	if not str(reasons).contains("非七对路线"):
		return "expected gang reasoning to mention non-qidui route, got %s" % [analysis]
	return true


func _test_neijiang_csharp_reaction_rejects_peng_that_re_discards_same_tile():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	var player := _make_player_neijiang(1, [
		_make_tile(9101, "tiao", 9), _make_tile(9102, "tiao", 9), _make_tile(9103, "tiao", 9),
		_make_tile(9104, "tiao", 1), _make_tile(9105, "tiao", 2), _make_tile(9106, "tiao", 3),
		_make_tile(9107, "tong", 2), _make_tile(9108, "tong", 3), _make_tile(9109, "tong", 4),
		_make_tile(9110, "tong", 5), _make_tile(9111, "tong", 6), _make_tile(9112, "tong", 7),
		_make_tile(9113, "tong", 8),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(9114, "tong", 1), _make_tile(9115, "tong", 9)]
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(9116, "tiao", 4), _make_tile(9117, "tong", 8)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(9118, "tong", 2), _make_tile(9119, "tiao", 5)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 22
	var analysis: Dictionary = game_state.ai_manager.analyze_reaction(
		{
			"seat": 1,
			"can_hu": false,
			"can_gang": true,
			"can_peng": true,
			"source_seat": 0,
		},
		game_state._build_player_state(1),
		game_state._build_table_state(),
		{
			"source_seat": 0,
			"tile": _make_tile(9120, "tiao", 9),
			"reaction_type": "discard",
		},
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected csharp reaction backend, got %s" % [analysis.get("backend_mode", "")]
	if str(analysis.get("action", "")) != "gang":
		return "expected 9条 discard claim to avoid peng-then-rediscard loop and choose gang, got %s" % [analysis]
	var peng_score := int(analysis.get("action_scores", {}).get("peng", 0))
	var gang_score := int(analysis.get("action_scores", {}).get("gang", 0))
	if gang_score <= peng_score:
		return "expected gang score to beat same-tile rediscarding peng, got gang=%d peng=%d in %s" % [gang_score, peng_score, analysis]
	return true


func _test_neijiang_csharp_reaction_search_marks_close_choices():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	var player := _make_player_neijiang(1, [
		_make_tile(2681, "tiao", 2), _make_tile(2682, "tiao", 3), _make_tile(2683, "tiao", 4),
		_make_tile(2684, "tiao", 6), _make_tile(2685, "tiao", 7),
		_make_tile(2686, "tong", 4), _make_tile(2687, "tong", 5), _make_tile(2688, "tong", 6),
		_make_tile(2689, "tong", 8), _make_tile(2690, "tong", 8),
		_make_tile(2691, "tong", 9), _make_tile(2692, "tong", 9), _make_tile(2693, "tiao", 9),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(2694, "tong", 1), _make_tile(2695, "tiao", 1)]
	var seat2 := _make_player_neijiang(2, [])
	var seat3 := _make_player_neijiang(3, [])
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 12
	var analysis: Dictionary = game_state.ai_manager.analyze_reaction(
		{
			"seat": 1,
			"can_hu": false,
			"can_gang": false,
			"can_peng": true,
			"source_seat": 0,
		},
		game_state._build_player_state(1),
		game_state._build_table_state(),
		{
			"source_seat": 0,
			"tile": _make_tile(2696, "tong", 9),
			"reaction_type": "discard",
		},
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	if not bool(analysis.get("search_used", false)):
		return "expected close reaction choice to trigger short search, got %s" % [analysis]
	if int(analysis.get("search_simulations", 0)) <= 0:
		return "expected short search to record simulations, got %s" % [analysis]
	return true


func _test_neijiang_csharp_self_action_cli_covers_self_hu_and_gang():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	var player := _make_player_neijiang(1, [
		_make_tile(2697, "tiao", 2), _make_tile(2698, "tiao", 2),
		_make_tile(2699, "tiao", 2), _make_tile(2700, "tiao", 2),
		_make_tile(2701, "tiao", 3), _make_tile(2702, "tiao", 4), _make_tile(2703, "tiao", 5),
		_make_tile(2704, "tong", 2), _make_tile(2705, "tong", 3), _make_tile(2706, "tong", 4),
		_make_tile(2707, "tong", 5), _make_tile(2708, "tong", 6), _make_tile(2709, "tong", 7),
		_make_tile(2710, "tiao", 9),
	])
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		player,
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.wall_count = 18
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var self_hu: Dictionary = game_state.ai_manager.analyze_self_action(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		true,
		[],
		[]
	)
	if str(self_hu.get("backend_mode", "")) != "csharp_self_action":
		return "expected self-hu self action to use csharp cli, got %s" % [self_hu]
	if str(self_hu.get("action", "")) != "hu":
		return "expected csharp self action to choose hu, got %s" % [self_hu]
	var gang_decision: Dictionary = game_state.ai_manager.analyze_self_action(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		false,
		[1],
		[]
	)
	if str(gang_decision.get("backend_mode", "")) != "csharp_self_action":
		return "expected gang self action to use csharp cli, got %s" % [gang_decision]
	if str(gang_decision.get("action", "")) != "gang":
		return "expected csharp self action to choose gang, got %s" % [gang_decision]
	if str(gang_decision.get("csharp_result", {}).get("gangSubtype", "")) != "an_gang":
		return "expected csharp self action to preserve an_gang subtype, got %s" % [gang_decision]
	return true


func _test_neijiang_csharp_self_action_exposes_gang_subtype():
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


func _test_neijiang_reaction_review_log_records_reasoning():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	var player := _make_player_neijiang(1, [
		_make_tile(2701, "tiao", 2), _make_tile(2702, "tiao", 3), _make_tile(2703, "tiao", 4),
		_make_tile(2704, "tiao", 6), _make_tile(2705, "tiao", 7),
		_make_tile(2706, "tong", 4), _make_tile(2707, "tong", 5), _make_tile(2708, "tong", 6),
		_make_tile(2709, "tong", 8), _make_tile(2710, "tong", 8),
		_make_tile(2711, "tong", 9), _make_tile(2712, "tong", 9), _make_tile(2713, "tiao", 9),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(2714, "tong", 1), _make_tile(2715, "tiao", 1)]
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(2716, "tiao", 8), _make_tile(2717, "tong", 2)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(2718, "tiao", 5), _make_tile(2719, "tong", 3)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 12
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	var reaction_tile := _make_tile(2720, "tong", 9)
	game_state._prepare_reaction_context(0, reaction_tile)
	var candidate: Dictionary = game_state._get_reaction_candidate_for_seat(1)
	if candidate.is_empty():
		return "expected seat 1 reaction candidate"
	var analysis: Dictionary = game_state.ai_manager.analyze_reaction(
		candidate,
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.current_discard_context,
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	game_state.pending_ai_reaction_decision = {
		"round_index": game_state.round_index,
		"phase": int(game_state.current_phase),
		"source_seat": int(game_state.current_discard_context.get("source_seat", -1)),
		"tile_id": int(reaction_tile.get("id", -1)),
		"pending_count": game_state.pending_reactions.size(),
		"seat": 1,
		"candidate": candidate.duplicate(true),
		"decision": analysis.duplicate(true),
	}
	game_state._clear_pending_ai_reaction_request()
	if not bool(game_state.run_ai_reaction()):
		return "expected run_ai_reaction to execute"
	var snapshot: Dictionary = game_state.get_debug_snapshot()
	var latest: Dictionary = snapshot.get("latest_ai_reaction_review", {})
	var history: Array = snapshot.get("ai_reaction_review_history", [])
	if latest.is_empty():
		return "expected latest_ai_reaction_review to be recorded"
	if history.is_empty():
		return "expected ai_reaction_review_history to contain entries"
	if str(latest.get("action", "")) == "":
		return "expected reaction review action, got %s" % [latest]
	if Dictionary(latest.get("action_scores", {})).is_empty():
		return "expected reaction review action_scores, got %s" % [latest]
	if not latest.has("search_used"):
		return "expected reaction review search_used flag, got %s" % [latest]
	if Array(latest.get("posterior_summary", [])).is_empty():
		return "expected reaction review posterior_summary, got %s" % [latest]
	if Array(latest.get("future_summary", [])).is_empty():
		return "expected reaction review future_summary, got %s" % [latest]
	return true


func _test_neijiang_trainer_hint_uses_two_suit_labels():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(0, [
		_make_tile(2721, "tiao", 1), _make_tile(2722, "tiao", 2), _make_tile(2723, "tiao", 3),
		_make_tile(2724, "tiao", 4), _make_tile(2725, "tiao", 5), _make_tile(2726, "tiao", 6),
		_make_tile(2727, "tong", 2), _make_tile(2728, "tong", 4), _make_tile(2729, "tong", 6),
		_make_tile(2730, "tong", 7), _make_tile(2731, "tong", 8), _make_tile(2732, "tong", 9),
		_make_tile(2733, "tong", 9), _make_tile(2734, "tong", 9),
	])
	_set_test_players(game_state, [
		player,
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	var hint: Dictionary = game_state._build_trainer_hint_for_seat(0)
	var label := str(hint.get("situation_label", ""))
	if label in ["均势局", "同缺均势局", "极度劣势局", "大优势局"]:
		return "expected neijiang trainer hint to avoid old sichuan labels, got %s" % [label]
	if label == "":
		return "expected non-empty neijiang trainer hint label"
	if label not in ["两门均衡", "轻度偏门", "单门偏重"]:
		return "expected two-suit label, got %s" % [label]
	return true


func _test_neijiang_trainer_hint_uses_csharp_analysis():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	var player := _make_player_neijiang(0, [
		_make_tile(2735, "tiao", 2), _make_tile(2736, "tiao", 3), _make_tile(2737, "tiao", 4),
		_make_tile(2738, "tiao", 5), _make_tile(2739, "tiao", 6), _make_tile(2740, "tiao", 7),
		_make_tile(2741, "tong", 2), _make_tile(2742, "tong", 3), _make_tile(2743, "tong", 4),
		_make_tile(2744, "tong", 6), _make_tile(2745, "tong", 7), _make_tile(2746, "tong", 8),
		_make_tile(2747, "tong", 9), _make_tile(2748, "tong", 9),
	])
	_set_test_players(game_state, [
		player,
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.wall_count = 18
	var hint: Dictionary = game_state._build_trainer_hint_for_seat(0)
	if hint.is_empty():
		return "expected trainer hint to remain available after gdscript advisor is disabled"
	if str(hint.get("strategy_profile", {}).get("mode_label", "")) == "":
		return "expected trainer hint to include csharp strategy profile, got %s" % [hint]
	if int(hint.get("recommended_tile_id", -1)) < 0:
		return "expected trainer hint to map csharp recommendation to a hand tile, got %s" % [hint]
	return true


func _test_neijiang_dealer_cannot_bao_jiao():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(101, "tiao", 1),
			_make_tile(102, "tiao", 1),
			_make_tile(103, "tiao", 1),
			_make_tile(104, "tiao", 2),
			_make_tile(105, "tiao", 2),
			_make_tile(106, "tiao", 2),
			_make_tile(107, "tiao", 3),
			_make_tile(108, "tiao", 3),
			_make_tile(109, "tiao", 3),
			_make_tile(110, "tong", 5),
			_make_tile(111, "tong", 6),
			_make_tile(112, "tong", 7),
			_make_tile(113, "tong", 8),
			_make_tile(114, "tong", 8),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if bool(game_state.can_human_bao_jiao(0)):
		return "expected dealer to be unable to bao jiao in neijiang mode"
	return true


func _test_neijiang_bao_jiao_plan_is_available_on_opening_ting():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(1, "tiao", 1),
			_make_tile(2, "tiao", 1),
			_make_tile(3, "tiao", 1),
			_make_tile(4, "tiao", 2),
			_make_tile(5, "tiao", 2),
			_make_tile(6, "tiao", 2),
			_make_tile(7, "tiao", 3),
			_make_tile(8, "tiao", 3),
			_make_tile(9, "tiao", 3),
			_make_tile(10, "tong", 5),
			_make_tile(11, "tong", 6),
			_make_tile(12, "tong", 7),
			_make_tile(13, "tong", 8),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if not bool(game_state.can_human_bao_jiao(0)):
		return "expected opening ready hand to allow bao jiao"
	var plan: Dictionary = game_state._build_bao_jiao_plan(0)
	if plan.is_empty():
		return "expected bao jiao plan to be built"
	if not Dictionary(plan.get("discard_tile", {})).is_empty():
		return "expected opening bao jiao plan to avoid discard"
	if Array(plan.get("ting_tiles", [])).is_empty():
		return "expected bao jiao plan to contain ting tiles"
	return true


func _test_neijiang_bao_jiao_is_opening_ready_only():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(201, "tiao", 1), _make_tile(202, "tiao", 1), _make_tile(203, "tiao", 1),
			_make_tile(204, "tiao", 2), _make_tile(205, "tiao", 2), _make_tile(206, "tiao", 2),
			_make_tile(207, "tiao", 3), _make_tile(208, "tiao", 3), _make_tile(209, "tiao", 3),
			_make_tile(210, "tong", 5), _make_tile(211, "tong", 6), _make_tile(212, "tong", 7),
			_make_tile(213, "tong", 8),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if not bool(game_state.can_human_bao_jiao(0)):
		return "expected opening non-dealer ready hand to allow bao jiao"
	game_state.discard_pile.append({"seat": 1, "tile": _make_tile(214, "tong", 9)})
	if bool(game_state.can_human_bao_jiao(0)):
		return "expected bao jiao to be disallowed after opening discard"
	return true


func _test_neijiang_opening_bao_jiao_does_not_discard():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(221, "tiao", 1), _make_tile(222, "tiao", 1), _make_tile(223, "tiao", 1),
			_make_tile(224, "tiao", 2), _make_tile(225, "tiao", 2), _make_tile(226, "tiao", 2),
			_make_tile(227, "tiao", 3), _make_tile(228, "tiao", 3), _make_tile(229, "tiao", 3),
			_make_tile(230, "tong", 5), _make_tile(231, "tong", 6), _make_tile(232, "tong", 7),
			_make_tile(233, "tong", 8),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	var before_count := int(game_state.players[0].get("hand_count", 0))
	if not bool(game_state.execute_human_bao_jiao(0)):
		return "expected opening bao jiao execution to succeed"
	if not bool(game_state.players[0].get("bao_jiao", false)):
		return "expected player to enter bao jiao state"
	if int(game_state.players[0].get("hand_count", 0)) != before_count:
		return "expected opening bao jiao to keep original hand count"
	if not Array(game_state.players[0].get("discards", [])).is_empty():
		return "expected opening bao jiao to avoid discarding a tile"
	return true


func _test_neijiang_opening_bao_jiao_window_blocks_dealer_first_discard():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.TABLE_SETUP
	game_state.current_dealer_seat = 1
	game_state.current_turn_seat = 1
	game_state.wall_count = 19
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(1221, "tiao", 1), _make_tile(1222, "tiao", 1), _make_tile(1223, "tiao", 1),
			_make_tile(1224, "tiao", 2), _make_tile(1225, "tiao", 2), _make_tile(1226, "tiao", 2),
			_make_tile(1227, "tiao", 3), _make_tile(1228, "tiao", 3), _make_tile(1229, "tiao", 3),
			_make_tile(1230, "tong", 5), _make_tile(1231, "tong", 6), _make_tile(1232, "tong", 7),
			_make_tile(1233, "tong", 8),
		]),
		_make_player_neijiang(1, [
			_make_tile(1234, "tiao", 1), _make_tile(1235, "tiao", 2), _make_tile(1236, "tiao", 3),
			_make_tile(1237, "tiao", 4), _make_tile(1238, "tiao", 5), _make_tile(1239, "tiao", 6),
			_make_tile(1240, "tong", 1), _make_tile(1241, "tong", 2), _make_tile(1242, "tong", 3),
			_make_tile(1243, "tong", 4), _make_tile(1244, "tong", 5), _make_tile(1245, "tong", 6),
			_make_tile(1246, "tong", 7), _make_tile(1247, "tong", 8),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state._begin_opening_discard_phase()
	if not bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao jiao window to be pending"
	if int(game_state.opening_bao_jiao_current_seat) != 0:
		return "expected human seat to be asked before dealer discard, got %s" % [game_state.opening_bao_jiao_current_seat]
	if not bool(game_state.can_human_bao_jiao(0)):
		return "expected human bao jiao button to be available during opening window"
	if not bool(game_state.can_human_pass_opening_bao_jiao(0)):
		return "expected human pass button to be available during opening window"
	if game_state.pending_ai_turn_request_id != 0:
		return "expected dealer AI discard request to wait until opening bao jiao window is done"
	if bool(game_state.is_ai_turn_ready()):
		return "expected dealer AI turn readiness to wait until opening bao jiao window is done"
	if bool(game_state.prepare_ai_turn_decision()):
		return "expected dealer AI analysis preparation to wait until opening bao jiao window is done"
	if not bool(game_state.pass_human_opening_bao_jiao(0)):
		return "expected human to pass opening bao jiao window"
	if bool(game_state.opening_bao_jiao_pending):
		return "expected opening bao jiao window to finish after pass"
	if not bool(game_state.is_ai_turn_ready()):
		return "expected dealer AI turn readiness to resume after opening bao jiao window"
	if int(game_state.pending_ai_turn_request_id) == 0:
		return "expected dealer AI discard request to start after opening window"
	return true


func _test_neijiang_opening_bao_jiao_queue_scans_ai_and_human_players():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_dealer_seat = 1
	game_state.current_turn_seat = 1
	game_state.wall_count = 19
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(3121, "tiao", 1), _make_tile(3122, "tiao", 1), _make_tile(3123, "tiao", 1),
			_make_tile(3124, "tiao", 2), _make_tile(3125, "tiao", 2), _make_tile(3126, "tiao", 2),
			_make_tile(3127, "tiao", 3), _make_tile(3128, "tiao", 3), _make_tile(3129, "tiao", 3),
			_make_tile(3130, "tong", 5), _make_tile(3131, "tong", 6), _make_tile(3132, "tong", 7),
			_make_tile(3133, "tong", 8),
		]),
		_make_player_neijiang(1, [
			_make_tile(3134, "tiao", 1), _make_tile(3135, "tiao", 2), _make_tile(3136, "tiao", 3),
			_make_tile(3137, "tiao", 4), _make_tile(3138, "tiao", 5), _make_tile(3139, "tiao", 6),
			_make_tile(3140, "tong", 1), _make_tile(3141, "tong", 2), _make_tile(3142, "tong", 3),
			_make_tile(3143, "tong", 4), _make_tile(3144, "tong", 5), _make_tile(3145, "tong", 6),
			_make_tile(3146, "tong", 7), _make_tile(3147, "tong", 8),
		]),
		_make_player_neijiang(2, [
			_make_tile(3148, "tiao", 4), _make_tile(3149, "tiao", 4), _make_tile(3150, "tiao", 4),
			_make_tile(3151, "tiao", 5), _make_tile(3152, "tiao", 5), _make_tile(3153, "tiao", 5),
			_make_tile(3154, "tiao", 6), _make_tile(3155, "tiao", 6), _make_tile(3156, "tiao", 6),
			_make_tile(3157, "tong", 2), _make_tile(3158, "tong", 3), _make_tile(3159, "tong", 4),
			_make_tile(3160, "tong", 5),
		]),
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


func _test_neijiang_bao_jiao_blocks_peng_and_discard_gang():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_dealer_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(241, "tong", 8), _make_tile(242, "tong", 8), _make_tile(243, "tong", 8),
			_make_tile(244, "tong", 9), _make_tile(245, "tong", 9), _make_tile(246, "tong", 9),
		], [], true),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.current_discard_context = {
		"source_seat": 1,
		"tile": _make_tile(247, "tong", 8),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	game_state.pending_reactions = game_state.mahjong_judge.build_reaction_candidates(game_state._build_table_state(), game_state.current_discard_context, game_state.rules)
	var options: Dictionary = game_state.get_human_reaction_options(0)
	if bool(options.get("can_peng", false)):
		return "expected bao jiao to block peng"
	if bool(options.get("can_gang", false)):
		return "expected bao jiao to block discard gang"
	return true


func _test_neijiang_bao_jiao_allows_whitelisted_discard_gang():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_dealer_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(3241, "tong", 8), _make_tile(3242, "tong", 8), _make_tile(3243, "tong", 8),
			_make_tile(3244, "tong", 9), _make_tile(3245, "tong", 9), _make_tile(3246, "tong", 9),
		], [], true),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[0]["bao_gang_tiles"] = ["tong_8"]
	game_state.current_discard_context = {
		"source_seat": 1,
		"tile": _make_tile(3247, "tong", 8),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	game_state.pending_reactions = game_state.mahjong_judge.build_reaction_candidates(game_state._build_table_state(), game_state.current_discard_context, game_state.rules)
	var options: Dictionary = game_state.get_human_reaction_options(0)
	if bool(options.get("can_peng", false)):
		return "expected bao jiao to continue blocking peng even when gang is whitelisted"
	if not bool(options.get("can_gang", false)):
		return "expected whitelisted bao gang tile to allow discard gang after bao jiao, got options=%s pending=%s" % [options, game_state.pending_reactions]
	return true


func _test_neijiang_bao_gang_whitelist_requires_keep_ting():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(21, "tong", 8),
			_make_tile(22, "tong", 8),
			_make_tile(23, "tong", 8),
			_make_tile(24, "tong", 8),
			_make_tile(25, "tiao", 1),
			_make_tile(26, "tiao", 1),
			_make_tile(27, "tiao", 1),
			_make_tile(28, "tiao", 1),
			_make_tile(29, "tiao", 2),
			_make_tile(30, "tiao", 2),
			_make_tile(31, "tiao", 2),
		], [
			{
				"type": "peng",
				"from_seat": 1,
				"tiles": [
					_make_tile(37, "tong", 9),
					_make_tile(38, "tong", 9),
					_make_tile(39, "tong", 9),
				],
			},
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	var keys: Array = game_state._collect_bao_gang_keys_for_seat(0, {})
	if keys.has("tong_8"):
		return "expected stricter bao gang filter to reject tong 8 when听型可能变化"
	if keys.has("tong_9"):
		return "expected add gang tong 9 to be filtered when it cannot keep ting"
	return true


func _test_neijiang_non_whitelist_gang_is_blocked_after_bao_jiao():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(121, "tong", 8),
			_make_tile(122, "tong", 8),
			_make_tile(123, "tong", 8),
			_make_tile(124, "tong", 8),
			_make_tile(125, "tiao", 1),
			_make_tile(126, "tiao", 1),
			_make_tile(127, "tiao", 1),
			_make_tile(128, "tiao", 1),
			_make_tile(129, "tiao", 2),
			_make_tile(130, "tiao", 2),
			_make_tile(131, "tiao", 2),
		], [
			{
				"type": "peng",
				"from_seat": 1,
				"tiles": [
					_make_tile(132, "tong", 9),
					_make_tile(133, "tong", 9),
					_make_tile(134, "tong", 9),
				],
			},
		], true),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[0]["bao_gang_tiles"] = ["tong_8"]
	if not bool(game_state.can_human_an_gang(0)):
		return "expected whitelisted an gang to remain allowed after bao jiao"
	if bool(game_state.can_human_add_gang(0)):
		return "expected non-whitelist add gang to be blocked after bao jiao"
	return true


func _test_neijiang_bao_jiao_payer_pays_extra_on_loss():
	var game_state = _build_neijiang_test_game_state()
	var players := [
		_make_player_neijiang(0, [], [], true),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	]
	var settlement_data := {
		"end_reason": "battle_end",
		"gang_events": [],
		"tui_gang_refunds": [],
		"transfer_events": [],
		"draw_assessment": [],
		"win_events": [
			{
				"winner_seat": 1,
				"payer_seats": [0],
				"win_type": "discard_win",
				"fan_detail": {"capped_fan": 2},
			}
		],
	}
	var changes: Dictionary = game_state.score_resolver.build_score_changes(players, settlement_data, game_state.rules)
	if int(changes.get(1, 0)) != 3:
		return "expected winner to receive 3 points (2番基础2分 + 报叫补罚1分), got %s" % [changes]
	if int(changes.get(0, 0)) != -3:
		return "expected bao jiao payer to lose 3 points, got %s" % [changes]
	return true


func _test_neijiang_draw_assessment_disables_hua_zhu():
	var game_state = _build_neijiang_test_game_state()
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(51, "tiao", 1), _make_tile(52, "tiao", 1), _make_tile(53, "tiao", 1),
			_make_tile(54, "tiao", 2), _make_tile(55, "tiao", 3), _make_tile(56, "tiao", 4),
			_make_tile(57, "tiao", 5), _make_tile(58, "tiao", 6), _make_tile(59, "tiao", 7),
			_make_tile(60, "tong", 2), _make_tile(61, "tong", 3), _make_tile(62, "tong", 4),
			_make_tile(63, "tong", 8),
		]),
		_make_player_neijiang(1, []),
	])
	game_state.settlement_data = game_state._create_empty_settlement_data()
	game_state._build_draw_settlement_assessment()
	var assessment: Array = game_state.settlement_data.get("draw_assessment", [])
	if assessment.is_empty():
		return "expected draw assessment items"
	if bool(assessment[0].get("hua_zhu", true)):
		return "expected neijiang draw assessment to disable hua zhu"
	return true


func _test_neijiang_ka_er_tiao_adds_one_fan():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(0, [
		_make_tile(201, "tiao", 1),
		_make_tile(202, "tiao", 3),
		_make_tile(203, "tiao", 4),
		_make_tile(204, "tiao", 5),
		_make_tile(205, "tiao", 6),
		_make_tile(206, "tiao", 4),
		_make_tile(207, "tiao", 5),
		_make_tile(208, "tiao", 6),
		_make_tile(209, "tong", 2),
		_make_tile(210, "tong", 3),
		_make_tile(211, "tong", 4),
		_make_tile(212, "tong", 9),
		_make_tile(213, "tong", 9),
	])
	var fan_detail: Dictionary = game_state.score_resolver.build_event_fan_detail(
		player,
		_make_tile(214, "tiao", 2),
		"discard_win",
		game_state.rules
	)
	if not bool(fan_detail.get("flags", {}).get("ka_er_tiao", false)):
		return "expected winning on 2条 to be recognized as 卡二条"
	if int(fan_detail.get("capped_fan", 0)) != 2:
		return "expected 平胡 + 卡二条 = 2番, got %s" % [fan_detail]
	if int(fan_detail.get("per_payer_score", 0)) != 2:
		return "expected 平胡 + 卡二条 = 2分, got %s" % [fan_detail]
	return true


func _test_neijiang_qing_long_qi_dui_is_five_fan_sixteen_points():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(0, [
		_make_tile(221, "tong", 1), _make_tile(222, "tong", 1),
		_make_tile(223, "tong", 2), _make_tile(224, "tong", 2),
		_make_tile(225, "tong", 3), _make_tile(226, "tong", 3),
		_make_tile(227, "tong", 4), _make_tile(228, "tong", 4),
		_make_tile(229, "tong", 5), _make_tile(230, "tong", 5),
		_make_tile(231, "tong", 8), _make_tile(232, "tong", 8),
		_make_tile(233, "tong", 8),
	])
	var fan_detail: Dictionary = game_state.score_resolver.build_event_fan_detail(
		player,
		_make_tile(234, "tong", 8),
		"discard_win",
		game_state.rules
	)
	if str(fan_detail.get("hand_type", "")) != "qing_long_qi_dui":
		return "expected pure dragon seven pairs hand type, got %s" % [fan_detail]
	if int(fan_detail.get("base_fan", 0)) != 5:
		return "expected 青龙七对基础番 = 5番, got %s" % [fan_detail]
	if int(fan_detail.get("uncapped_fan", 0)) != 5:
		return "expected 青龙七对未封顶番 = 5番, got %s" % [fan_detail]
	if int(fan_detail.get("capped_fan", 0)) != 5:
		return "expected 青龙七对按 5番封顶显示, got %s" % [fan_detail]
	if int(fan_detail.get("per_payer_score", 0)) != 16:
		return "expected 青龙七对 = 16分, got %s" % [fan_detail]
	return true


func _test_neijiang_double_gui_long_qi_dui_is_five_fan_sixteen_points():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(0, [
		_make_tile(235, "tiao", 1), _make_tile(236, "tiao", 1),
		_make_tile(237, "tiao", 1), _make_tile(238, "tiao", 1),
		_make_tile(239, "tiao", 4), _make_tile(240, "tiao", 4),
		_make_tile(241, "tiao", 4), _make_tile(242, "tiao", 4),
		_make_tile(243, "tong", 2), _make_tile(244, "tong", 2),
		_make_tile(245, "tong", 5), _make_tile(246, "tong", 5),
		_make_tile(247, "tong", 8), _make_tile(248, "tong", 8),
	])
	var fan_detail: Dictionary = game_state.score_resolver.build_event_fan_detail(
		player,
		_make_tile(249, "tong", 8),
		"self_draw",
		game_state.rules
	)
	if str(fan_detail.get("hand_type", "")) != "long_qi_dui":
		return "expected double-gui dragon seven pairs hand type, got %s" % [fan_detail]
	if int(fan_detail.get("gui_count", 0)) != 2:
		return "expected two gui/gen in dragon seven pairs, got %s" % [fan_detail]
	if int(fan_detail.get("base_fan", 0)) != 5:
		return "expected 多归龙七对基础番 = 5番, got %s" % [fan_detail]
	if int(fan_detail.get("capped_fan", 0)) != 5:
		return "expected 多归龙七对按 5番封顶显示, got %s" % [fan_detail]
	if int(fan_detail.get("hand_score", 0)) != 16:
		return "expected 多归龙七对牌型分 = 16分, got %s" % [fan_detail]
	if int(fan_detail.get("per_payer_score", 0)) != 17:
		return "expected 多归龙七对自摸每家 16+1=17分, got %s" % [fan_detail]
	return true


func _test_neijiang_discard_win_does_not_double_count_winning_tile_as_gui():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(0, [
		_make_tile(401, "tong", 1), _make_tile(402, "tong", 1), _make_tile(403, "tong", 1),
		_make_tile(404, "tong", 2), _make_tile(405, "tong", 3), _make_tile(406, "tong", 4),
		_make_tile(407, "tiao", 4), _make_tile(408, "tiao", 5), _make_tile(409, "tiao", 6),
		_make_tile(410, "tiao", 9), _make_tile(411, "tiao", 9),
		_make_tile(412, "tong", 8), _make_tile(413, "tong", 8),
	])
	var fan_detail: Dictionary = game_state.score_resolver.build_event_fan_detail(
		player,
		_make_tile(414, "tong", 8),
		"discard_win",
		game_state.rules
	)
	var labels: Array = fan_detail.get("labels", [])
	if int(fan_detail.get("gui_count", 0)) != 0:
		return "expected three 8筒 after win not to count as 归, got %s" % [fan_detail]
	if labels.has("归"):
		return "expected labels not to include 归, got %s" % [labels]
	if int(fan_detail.get("capped_fan", 0)) != 1:
		return "expected 平胡点炮 without 归 to remain 1番, got %s" % [fan_detail]
	if int(fan_detail.get("per_payer_score", 0)) != 1:
		return "expected 平胡点炮 without 归 to remain 1分, got %s" % [fan_detail]
	return true


func _test_neijiang_qing_yi_se_gui_gang_pao_caps_to_five_fan():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(0, [
		_make_tile(235, "tong", 1), _make_tile(236, "tong", 1), _make_tile(237, "tong", 1),
		_make_tile(238, "tong", 2), _make_tile(239, "tong", 3),
		_make_tile(240, "tong", 4), _make_tile(241, "tong", 5), _make_tile(242, "tong", 6),
		_make_tile(243, "tong", 7), _make_tile(244, "tong", 8),
		_make_tile(245, "tong", 9), _make_tile(246, "tong", 9), _make_tile(247, "tong", 9),
	])
	var fan_detail: Dictionary = game_state.score_resolver.build_event_fan_detail(
		player,
		_make_tile(248, "tong", 1),
		"gang_discard_win",
		game_state.rules
	)
	var labels: Array = fan_detail.get("labels", [])
	if int(fan_detail.get("gui_count", 0)) != 1:
		return "expected win-completed four-of-a-kind to count as 1归, got %s" % [fan_detail]
	if int(fan_detail.get("capped_fan", 0)) != 5:
		return "expected 清一色+归+杠上炮 to cap at 5番, got %s" % [fan_detail]
	if int(fan_detail.get("per_payer_score", 0)) != 16:
		return "expected 清一色+归+杠上炮 = 16分, got %s" % [fan_detail]
	if not labels.has("清一色") or not labels.has("归") or not labels.has("杠上炮"):
		return "expected labels to include 清一色/归/杠上炮, got %s" % [labels]
	return true


func _test_neijiang_gui_counts_melds_plus_winning_tile():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(0, [
		_make_tile(420, "tong", 1), _make_tile(421, "tong", 2), _make_tile(422, "tong", 3),
		_make_tile(423, "tong", 4), _make_tile(424, "tong", 5), _make_tile(425, "tong", 6),
		_make_tile(426, "tong", 7), _make_tile(427, "tong", 8), _make_tile(428, "tong", 9),
		_make_tile(429, "tong", 9),
	], [{
		"type": "peng",
		"from_seat": 1,
		"tiles": [_make_tile(430, "tong", 8), _make_tile(431, "tong", 8), _make_tile(432, "tong", 8)]
	}])
	var fan_detail: Dictionary = game_state.score_resolver.build_event_fan_detail(
		player,
		_make_tile(433, "tong", 8),
		"discard_win",
		game_state.rules
	)
	if int(fan_detail.get("gui_count", 0)) != 1:
		return "expected melded three 8筒 plus winning 8筒 to count as 1归, got %s" % [fan_detail]
	if not Array(fan_detail.get("labels", [])).has("归"):
		return "expected labels to include 归, got %s" % [fan_detail]
	return true


func _test_neijiang_rule_marks_add_special_fans():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(0, [
		_make_tile(241, "tiao", 1), _make_tile(242, "tiao", 1), _make_tile(243, "tiao", 1),
		_make_tile(244, "tiao", 2), _make_tile(245, "tiao", 3), _make_tile(246, "tiao", 4),
		_make_tile(247, "tiao", 5), _make_tile(248, "tiao", 6), _make_tile(249, "tiao", 7),
		_make_tile(250, "tong", 2), _make_tile(251, "tong", 3), _make_tile(252, "tong", 4),
		_make_tile(253, "tong", 9),
	])
	player["rule_marks"] = ["地胡", "海底"]
	var first_fan: Dictionary = game_state.score_resolver.build_event_fan_detail(
		player,
		_make_tile(254, "tong", 9),
		"discard_win",
		game_state.rules
	)
	if int(first_fan.get("capped_fan", 0)) != 5:
		return "expected 平胡 + 地胡 + 海底 capped to 5番, got %s" % [first_fan]
	if int(first_fan.get("per_payer_score", 0)) != 16:
		return "expected 平胡 + 地胡 + 海底 under 5番封顶 = 16分, got %s" % [first_fan]
	var first_labels: Array = first_fan.get("labels", [])
	if not first_labels.has("地胡") or not first_labels.has("海底"):
		return "expected 地胡 and 海底 labels, got %s" % [first_labels]

	player["rule_marks"] = ["天和"]
	var tian_fan: Dictionary = game_state.score_resolver.build_event_fan_detail(
		player,
		_make_tile(255, "tong", 9),
		"self_draw",
		game_state.rules
	)
	if int(tian_fan.get("capped_fan", 0)) != 5:
		return "expected 平胡 + 天和 capped to 5番, got %s" % [tian_fan]
	if int(tian_fan.get("per_payer_score", 0)) != 17:
		return "expected 平胡 + 天和自摸 = 16分底 + 1分自摸 = 17分, got %s" % [tian_fan]
	if not bool(tian_fan.get("flags", {}).get("tian_he", false)):
		return "expected 天和 flag to be set"
	return true


func _test_neijiang_score_table_matches_expected_points():
	var game_state = _build_neijiang_test_game_state()
	var players: Array[Dictionary] = [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	]
	game_state.players = players

	var ping_hu_discard: Dictionary = game_state.score_resolver.build_score_changes(
		players,
		{
			"win_events": [
				{
					"winner_seat": 0,
					"payer_seats": [1],
					"win_type": "discard_win",
					"fan_detail": {"capped_fan": 1, "hand_score": 1, "per_payer_score": 1},
				},
			],
		},
		game_state.rules
	)
	if int(ping_hu_discard.get(0, 0)) != 1 or int(ping_hu_discard.get(1, 0)) != -1:
		return "expected 平胡点炮 +/-1, got %s" % [ping_hu_discard]

	var da_dui_discard: Dictionary = game_state.score_resolver.build_score_changes(
		players,
		{
			"win_events": [
				{
					"winner_seat": 0,
					"payer_seats": [1],
					"win_type": "discard_win",
					"fan_detail": {"capped_fan": 3, "hand_score": 4, "per_payer_score": 4},
				},
			],
		},
		game_state.rules
	)
	if int(da_dui_discard.get(0, 0)) != 4 or int(da_dui_discard.get(1, 0)) != -4:
		return "expected 大对子点炮 +/-4, got %s" % [da_dui_discard]

	var gang_hu_discard: Dictionary = game_state.score_resolver.build_score_changes(
		players,
		{
			"win_events": [
				{
					"winner_seat": 0,
					"payer_seats": [1],
					"win_type": "gang_discard_win",
					"fan_detail": {"capped_fan": 4, "hand_score": 8, "per_payer_score": 8},
				},
			],
		},
		game_state.rules
	)
	if int(gang_hu_discard.get(0, 0)) != 8 or int(gang_hu_discard.get(1, 0)) != -8:
		return "expected 大对子+杠胡 +/-8, got %s" % [gang_hu_discard]

	var ka_er_tiao_discard: Dictionary = game_state.score_resolver.build_score_changes(
		players,
		{
			"win_events": [
				{
					"winner_seat": 0,
					"payer_seats": [1],
					"win_type": "discard_win",
					"fan_detail": {"capped_fan": 2, "hand_score": 2, "per_payer_score": 2},
				},
			],
		},
		game_state.rules
	)
	if int(ka_er_tiao_discard.get(0, 0)) != 2 or int(ka_er_tiao_discard.get(1, 0)) != -2:
		return "expected 卡二条点炮 +/-2, got %s" % [ka_er_tiao_discard]

	var ping_hu_self_draw: Dictionary = game_state.score_resolver.build_score_changes(
		players,
		{
			"win_events": [
				{
					"winner_seat": 0,
					"payer_seats": [1, 2, 3],
					"win_type": "self_draw",
					"fan_detail": {"capped_fan": 1, "hand_score": 1, "per_payer_score": 2},
				},
			],
		},
		game_state.rules
	)
	if int(ping_hu_self_draw.get(0, 0)) != 6:
		return "expected 平胡自摸 +(1+1)x3 = 6, got %s" % [ping_hu_self_draw]
	if int(ping_hu_self_draw.get(1, 0)) != -2 or int(ping_hu_self_draw.get(2, 0)) != -2 or int(ping_hu_self_draw.get(3, 0)) != -2:
		return "expected each payer to lose 2 on 平胡自摸, got %s" % [ping_hu_self_draw]

	var tian_hu_self_draw: Dictionary = game_state.score_resolver.build_score_changes(
		players,
		{
			"win_events": [
				{
					"winner_seat": 0,
					"payer_seats": [1, 2, 3],
					"win_type": "self_draw",
					"fan_detail": {"capped_fan": 5, "hand_score": 16, "per_payer_score": 17},
				},
			],
		},
		game_state.rules
	)
	if int(tian_hu_self_draw.get(0, 0)) != 51:
		return "expected 天胡自摸 (16+1)x3 = 51, got %s" % [tian_hu_self_draw]
	if int(tian_hu_self_draw.get(1, 0)) != -17 or int(tian_hu_self_draw.get(2, 0)) != -17 or int(tian_hu_self_draw.get(3, 0)) != -17:
		return "expected each payer to lose 17 on 天胡自摸, got %s" % [tian_hu_self_draw]
	return true


func _test_neijiang_hu_jiao_zhuan_yi_excludes_winner_self_from_payers():
	var game_state = _build_neijiang_test_game_state()
	game_state.settlement_data = game_state._create_empty_settlement_data()
	game_state.settlement_data["gang_events"] = [
		{
			"actor_seat": 3,
			"source_seat": 3,
			"tile": _make_tile(298, "tong", 8),
			"gang_type": "an_gang",
			"related_outcome": "gang_discard_win",
			"payer_seats": [0, 1, 2],
		},
	]
	game_state._append_hu_jiao_zhuan_yi_event(3, 0, _make_tile(299, "tong", 8))
	var transfer_events: Array = game_state.settlement_data.get("transfer_events", [])
	if transfer_events.size() != 1:
		return "expected one 呼叫转移 event, got %s" % [transfer_events]
	var payer_seats: Array = transfer_events[0].get("payer_seats", [])
	if payer_seats != [1, 2]:
		return "expected winner self to be excluded from 呼叫转移付款方, got %s" % [payer_seats]
	return true


func _test_neijiang_qing_yi_se_gui_gang_pao_with_transfer_scores_twenty():
	var game_state = _build_neijiang_test_game_state()
	var players := [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	]
	for player in players:
		player["has_won"] = true
	var changes: Dictionary = game_state.score_resolver.build_score_changes(
		players,
		{
			"end_reason": "battle_end",
			"gang_events": [
				{
					"actor_seat": 3,
					"source_seat": 3,
					"tile": _make_tile(300, "tong", 8),
					"gang_type": "an_gang",
					"related_outcome": "gang_discard_win",
					"payer_seats": [0, 1, 2],
				},
			],
			"transfer_events": [
				{
					"from_seat": 3,
					"to_seat": 0,
					"tile": _make_tile(301, "tong", 8),
					"transfer_type": "hu_jiao_zhuan_yi",
					"gang_type": "an_gang",
					"payer_seats": [1, 2],
				},
			],
			"win_events": [
				{
					"winner_seat": 0,
					"payer_seats": [3],
					"win_type": "gang_discard_win",
					"fan_detail": {"capped_fan": 5, "hand_score": 16, "per_payer_score": 16},
				},
			],
			"tui_gang_refunds": [],
			"draw_assessment": [],
		},
		game_state.rules
	)
	if int(changes.get(0, 999)) != 20 or int(changes.get(1, 999)) != -2 or int(changes.get(2, 999)) != -2 or int(changes.get(3, 999)) != -16:
		return "expected 清一色归杠上炮16分 + 暗杠呼叫转移4分 => {0:+20,1:-2,2:-2,3:-16}, got %s" % [changes]
	return true


func _test_neijiang_auto_marks_tian_he_on_opening_self_hu():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	game_state.last_turn_context = {
		"seat": 0,
		"draw_reason": "opening_discard",
	}
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(301, "tiao", 1), _make_tile(302, "tiao", 1), _make_tile(303, "tiao", 1),
			_make_tile(304, "tiao", 2), _make_tile(305, "tiao", 3), _make_tile(306, "tiao", 4),
			_make_tile(307, "tiao", 5), _make_tile(308, "tiao", 6), _make_tile(309, "tiao", 7),
			_make_tile(310, "tong", 2), _make_tile(311, "tong", 3), _make_tile(312, "tong", 4),
			_make_tile(313, "tong", 9), _make_tile(314, "tong", 9),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if not bool(game_state._execute_self_draw_hu(0)):
		return "expected dealer opening self hu to succeed"
	var marks: Array = game_state.players[0].get("rule_marks", [])
	if not marks.has("天和"):
		return "expected 天和 to be auto-marked, got %s" % [marks]
	return true


func _test_neijiang_opening_dealer_self_hu_without_last_draw_is_available():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	game_state.last_draw_tile = {}
	game_state.last_turn_context = {
		"seat": 0,
		"draw_reason": "opening_discard",
	}
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(801, "tiao", 1), _make_tile(802, "tiao", 1), _make_tile(803, "tiao", 1),
			_make_tile(804, "tiao", 2), _make_tile(805, "tiao", 3), _make_tile(806, "tiao", 4),
			_make_tile(807, "tiao", 5), _make_tile(808, "tiao", 6), _make_tile(809, "tiao", 7),
			_make_tile(810, "tong", 2), _make_tile(811, "tong", 3), _make_tile(812, "tong", 4),
			_make_tile(813, "tong", 9), _make_tile(814, "tong", 9),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if not bool(game_state.can_human_self_hu(0)):
		return "expected opening dealer 14-tile hu to be available without last_draw_tile"
	var decision: Dictionary = game_state._build_ai_self_action_decision(0, game_state._build_player_state(0), game_state._build_table_state())
	if str(decision.get("action", "")) != "self_hu":
		return "expected opening dealer self action to choose self_hu before discard, got %s" % [decision]
	return true


func _test_neijiang_auto_marks_di_hu_on_dealer_first_discard():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	game_state.wall_count = 40
	game_state.last_turn_context = {
		"seat": 0,
		"draw_reason": "opening_discard",
	}
	var dealer_discard := _make_tile(321, "tong", 9)
	game_state.last_draw_tile = {
		"seat": 0,
		"tile": dealer_discard,
	}
	game_state.discard_pile.clear()
	game_state.discard_pile.append({
		"seat": 0,
		"tile": dealer_discard.duplicate(true),
	})
	game_state.current_discard_context = {
		"source_seat": 0,
		"tile": dealer_discard.duplicate(true),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(322, "tiao", 1), _make_tile(323, "tiao", 1), _make_tile(324, "tiao", 1),
			_make_tile(325, "tiao", 2), _make_tile(326, "tiao", 3), _make_tile(327, "tiao", 4),
			_make_tile(328, "tiao", 5), _make_tile(329, "tiao", 6), _make_tile(330, "tiao", 7),
			_make_tile(331, "tong", 2), _make_tile(332, "tong", 3), _make_tile(333, "tong", 4),
			_make_tile(334, "tong", 9),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if not bool(game_state._execute_hu_on_discard(1)):
		return "expected non-dealer hu on dealer first discard to succeed"
	var marks: Array = game_state.players[1].get("rule_marks", [])
	if not marks.has("地胡"):
		return "expected 地胡 to be auto-marked, got %s" % [marks]
	if marks.has("天和"):
		return "expected 地胡 case not to be marked as 天和"
	return true


func _test_neijiang_auto_marks_hai_di_on_last_tile_win():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	game_state.wall_count = 0
	game_state.last_turn_context = {
		"seat": 1,
		"draw_reason": "normal_draw",
	}
	game_state.last_draw_tile = {
		"seat": 1,
		"tile": _make_tile(341, "tong", 9),
	}
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(342, "tiao", 1), _make_tile(343, "tiao", 1), _make_tile(344, "tiao", 1),
			_make_tile(345, "tiao", 2), _make_tile(346, "tiao", 3), _make_tile(347, "tiao", 4),
			_make_tile(348, "tiao", 5), _make_tile(349, "tiao", 6), _make_tile(350, "tiao", 7),
			_make_tile(351, "tong", 2), _make_tile(352, "tong", 3), _make_tile(353, "tong", 4),
			_make_tile(354, "tong", 9), _make_tile(355, "tong", 9),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if not bool(game_state._execute_self_draw_hu(1)):
		return "expected last-tile self hu to succeed"
	var marks: Array = game_state.players[1].get("rule_marks", [])
	if not marks.has("海底"):
		return "expected 海底 to be auto-marked, got %s" % [marks]
	return true


func _test_neijiang_draw_assessment_marks_bao_jiao_wei_cheng():
	var game_state = _build_neijiang_test_game_state()
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(361, "tiao", 1),
			_make_tile(362, "tiao", 4),
			_make_tile(363, "tiao", 7),
			_make_tile(364, "tong", 2),
			_make_tile(365, "tong", 9),
		], [], true),
		_make_player_neijiang(1, [
			_make_tile(374, "tiao", 4), _make_tile(375, "tiao", 5), _make_tile(376, "tiao", 6),
			_make_tile(377, "tiao", 4), _make_tile(378, "tiao", 5), _make_tile(379, "tiao", 6),
			_make_tile(380, "tong", 2), _make_tile(381, "tong", 3), _make_tile(382, "tong", 4),
			_make_tile(383, "tong", 7), _make_tile(384, "tong", 8), _make_tile(385, "tong", 9),
			_make_tile(386, "tong", 1),
		]),
	])
	game_state.settlement_data = game_state._create_empty_settlement_data()
	game_state._build_draw_settlement_assessment()
	var assessment: Array = game_state.settlement_data.get("draw_assessment", [])
	if assessment.size() != 2:
		return "expected two assessment items, got %s" % [assessment]
	var seat0: Dictionary = assessment[0]
	if not bool(seat0.get("is_bao_jiao", false)):
		return "expected seat 0 to keep 报叫标记 in draw assessment"
	if bool(seat0.get("is_ting", true)):
		return "expected seat 0 to be 报叫未成 rather than 有叫"
	return true


func _test_neijiang_draw_score_changes_refund_tax_and_pay_ting():
	var game_state = _build_neijiang_test_game_state()
	var players := [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, []),
	]
	for player in players:
		player["has_won"] = false
	var settlement_data: Dictionary = game_state._create_empty_settlement_data()
	settlement_data["end_reason"] = "draw_wall_empty"
	settlement_data["gang_events"] = [
		{
			"actor_seat": 0,
			"source_seat": 1,
			"tile": _make_tile(391, "tong", 9),
			"gang_type": "melded_gang",
			"related_outcome": "",
			"payer_seats": [1],
		},
	]
	settlement_data["tui_gang_refunds"] = [
		{
			"actor_seat": 0,
			"gang_type": "melded_gang",
			"payer_seats": [1],
			"refund_reason": "draw_tui_gang",
		},
	]
	settlement_data["draw_assessment"] = [
		{"seat": 0, "hua_zhu": false, "is_ting": false, "is_bao_jiao": true, "ting_tiles": []},
		{"seat": 1, "hua_zhu": false, "is_ting": true, "is_bao_jiao": false, "ting_tiles": [_make_tile(392, "tong", 3)], "cha_jiao_score": 4, "cha_jiao_fan": 3},
	]
	var changes: Dictionary = game_state.score_resolver.build_score_changes(players, settlement_data, game_state.rules)
	if int(changes.get(0, 99)) != -4 or int(changes.get(1, 99)) != 4:
		return "expected refund to cancel gang tax and no-ting seat to pay ting seat 4, got %s" % [changes]
	return true


func _test_neijiang_battle_end_bao_jiao_wei_cheng_pays_ting():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.SETTLEMENT
	game_state.current_dealer_seat = 0
	game_state.round_winners.clear()
	game_state.round_winners.append(2)
	game_state.round_winners.append(3)
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(801, "tiao", 1), _make_tile(802, "tiao", 1), _make_tile(803, "tiao", 2),
			_make_tile(804, "tiao", 3), _make_tile(805, "tiao", 4), _make_tile(806, "tiao", 5),
			_make_tile(807, "tong", 1), _make_tile(808, "tong", 1), _make_tile(809, "tong", 2),
			_make_tile(810, "tong", 3), _make_tile(811, "tong", 5), _make_tile(812, "tong", 7),
			_make_tile(813, "tong", 9),
		], [], true),
		_make_player_neijiang(1, [
			_make_tile(821, "tiao", 1), _make_tile(822, "tiao", 1), _make_tile(823, "tiao", 1),
			_make_tile(824, "tiao", 2), _make_tile(825, "tiao", 3), _make_tile(826, "tiao", 4),
			_make_tile(827, "tiao", 5), _make_tile(828, "tiao", 6), _make_tile(829, "tiao", 7),
			_make_tile(830, "tong", 2), _make_tile(831, "tong", 3), _make_tile(832, "tong", 4),
			_make_tile(833, "tong", 8),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[2]["has_won"] = true
	game_state.players[3]["has_won"] = true
	game_state.settlement_data = game_state._create_empty_settlement_data()
	game_state._enter_settlement_due_to_battle_end()
	var assessment: Array = game_state.settlement_data.get("draw_assessment", [])
	if assessment.size() != 2:
		return "expected battle end to assess remaining two table players, got %s" % [assessment]
	var changes: Dictionary = game_state.settlement_data.get("score_changes", {})
	if int(changes.get(0, 999)) != -1 or int(changes.get(1, 999)) != 1:
		return "expected 报叫未成 seat 0 to pay remaining ting seat 1 at battle end, got %s" % [changes]
	return true


func _test_neijiang_bao_jiao_failed_even_if_ting_still_pays_other_ting():
	var game_state = _build_neijiang_test_game_state()
	var players := [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
	]
	for player in players:
		player["has_won"] = false
	var settlement_data: Dictionary = game_state._create_empty_settlement_data()
	settlement_data["end_reason"] = "draw_wall_empty"
	settlement_data["draw_assessment"] = [
		{"seat": 0, "hua_zhu": false, "is_ting": true, "is_bao_jiao": true, "ting_tiles": [_make_tile(841, "tong", 2)], "cha_jiao_score": 1, "cha_jiao_fan": 1},
		{"seat": 1, "hua_zhu": false, "is_ting": true, "is_bao_jiao": false, "ting_tiles": [_make_tile(842, "tong", 8)], "cha_jiao_score": 4, "cha_jiao_fan": 3},
		{"seat": 2, "hua_zhu": false, "is_ting": false, "is_bao_jiao": false, "ting_tiles": []},
	]
	var changes: Dictionary = game_state.score_resolver.build_score_changes(players, settlement_data, game_state.rules)
	if int(changes.get(0, 999)) != -3 or int(changes.get(1, 999)) != 8 or int(changes.get(2, 999)) != -5:
		return "expected bao_jiao failed ting seat 0 to additionally pay ting seat 1 while no-ting seat 2 still pays both ting seats, got %s" % [changes]
	return true


func _test_neijiang_settlement_summary_uses_names_and_tax_wording():
	var game_state = _build_neijiang_test_game_state()
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, []),
	])
	game_state.players[0]["nickname"] = "陈东"
	game_state.players[1]["nickname"] = "舒小燕"
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.SETTLEMENT
	game_state.current_dealer_seat = 0
	game_state.round_index = 3
	game_state.settlement_data = game_state._create_empty_settlement_data()
	game_state.settlement_data["end_reason"] = "draw_wall_empty"
	game_state.settlement_data["gang_events"] = [
		{
			"actor_seat": 0,
			"source_seat": 1,
			"tile": _make_tile(401, "tong", 9),
			"gang_type": "melded_gang",
			"related_outcome": "",
			"payer_seats": [1],
		},
	]
	game_state.settlement_data["tui_gang_refunds"] = [
		{
			"actor_seat": 0,
			"gang_type": "melded_gang",
			"payer_seats": [1],
			"refund_reason": "draw_tui_gang",
		},
	]
	game_state._rebuild_settlement_summary()
	var summary := str(game_state.settlement_data.get("summary_text", ""))
	if summary.contains("Seat "):
		return "expected settlement summary not to use Seat wording, got %s" % [summary]
	if not summary.contains("陈东") or not summary.contains("舒小燕"):
		return "expected settlement summary to use player nicknames, got %s" % [summary]
	if not summary.contains("退税"):
		return "expected settlement summary to use 退税 wording, got %s" % [summary]
	return true


func _test_neijiang_ai_prefers_trimming_weak_suit_in_two_suit_mode():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(1, [
		_make_tile(401, "tiao", 2), _make_tile(402, "tiao", 3), _make_tile(403, "tiao", 4),
		_make_tile(404, "tiao", 4), _make_tile(405, "tiao", 5), _make_tile(406, "tiao", 6),
		_make_tile(407, "tiao", 6), _make_tile(408, "tiao", 7), _make_tile(409, "tiao", 8),
		_make_tile(410, "tiao", 9), _make_tile(411, "tiao", 9),
		_make_tile(412, "tong", 1), _make_tile(413, "tong", 8), _make_tile(414, "tong", 9),
	])
	var players := [
		_make_player_neijiang(0, []),
		player,
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	]
	_set_test_players(game_state, players)
	game_state.wall_count = 19
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false,
	)
	var recommended: Dictionary = analysis.get("recommended", {})
	var tile: Dictionary = recommended.get("tile", {})
	if str(tile.get("suit", "")) != "tong":
		return "expected two-suit AI to first trim weak 筒门, got %s" % [recommended]
	return true


func _test_neijiang_ready_discard_beats_non_ready_trim():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(1, [
		_make_tile(3001, "tiao", 4), _make_tile(3002, "tiao", 4),
		_make_tile(3003, "tiao", 5), _make_tile(3004, "tiao", 5),
		_make_tile(3005, "tiao", 8), _make_tile(3006, "tiao", 8),
		_make_tile(3007, "tong", 1), _make_tile(3008, "tong", 1),
		_make_tile(3009, "tong", 6), _make_tile(3010, "tong", 6), _make_tile(3011, "tong", 6),
		_make_tile(3012, "tong", 7),
		_make_tile(3013, "tong", 9), _make_tile(3014, "tong", 9),
	])
	var players := [
		_make_player_neijiang(0, []),
		player,
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	]
	_set_test_players(game_state, players)
	game_state.wall_count = 19
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false,
	)
	var recommended: Dictionary = analysis.get("recommended", {})
	if str(recommended.get("tile_name", "")) not in ["6筒", "7筒"]:
		return "expected ready discard to beat non-ready 8条 trim, got %s" % [recommended]
	if Array(recommended.get("ting_tiles", [])).is_empty():
		return "expected recommended discard to be ready, got %s" % [recommended]
	var option_map := {}
	for option in analysis.get("options", []):
		option_map[str(option.get("tile_name", ""))] = option
	if not option_map.has("8条"):
		return "expected 8条 option to exist, got %s" % [analysis.get("options", [])]
	if not Array(option_map.get("6筒", {}).get("ting_tiles", [])).is_empty() and int(option_map.get("6筒", {}).get("shanten", 9)) != 0:
		return "expected 6筒 ready discard to be normalized as shanten 0, got %s" % [option_map.get("6筒", {})]
	if not Array(option_map.get("6筒", {}).get("ting_tiles", [])).is_empty() and int(option_map.get("6筒", {}).get("ukeire", 0)) <= 0:
		return "expected 6筒 ready discard to expose winning ukeire, got %s" % [option_map.get("6筒", {})]
	if not Array(option_map.get("6筒", {}).get("ting_tiles", [])).is_empty() and int(option_map.get("6筒", {}).get("live_ukeire", 0)) <= 0:
		return "expected 6筒 ready discard to expose live winning tiles, got %s" % [option_map.get("6筒", {})]
	if not Array(option_map.get("7筒", {}).get("ting_tiles", [])).is_empty() and int(option_map.get("7筒", {}).get("shanten", 9)) != 0:
		return "expected 7筒 ready discard to be normalized as shanten 0, got %s" % [option_map.get("7筒", {})]
	if not Array(option_map.get("7筒", {}).get("ting_tiles", [])).is_empty() and int(option_map.get("7筒", {}).get("ukeire", 0)) <= 0:
		return "expected 7筒 ready discard to expose winning ukeire, got %s" % [option_map.get("7筒", {})]
	if not Array(option_map.get("7筒", {}).get("ting_tiles", [])).is_empty() and int(option_map.get("7筒", {}).get("live_ukeire", 0)) <= 0:
		return "expected 7筒 ready discard to expose live winning tiles, got %s" % [option_map.get("7筒", {})]
	if not Array(option_map.get("8条", {}).get("ting_tiles", [])).is_empty():
		return "expected 8条 discard to stay non-ready, got %s" % [option_map.get("8条", {})]
	return true


func _test_neijiang_ai_keeps_ka_er_tiao_ready_shape():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(1, [
		_make_tile(421, "tiao", 1),
		_make_tile(422, "tiao", 3),
		_make_tile(423, "tiao", 4),
		_make_tile(424, "tiao", 5),
		_make_tile(425, "tiao", 6),
		_make_tile(426, "tiao", 4),
		_make_tile(427, "tiao", 5),
		_make_tile(428, "tiao", 6),
		_make_tile(429, "tong", 2),
		_make_tile(430, "tong", 3),
		_make_tile(431, "tong", 4),
		_make_tile(432, "tong", 9),
		_make_tile(433, "tong", 9),
		_make_tile(434, "tong", 1),
	])
	var players := [
		_make_player_neijiang(0, []),
		player,
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	]
	_set_test_players(game_state, players)
	game_state.wall_count = 19
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false,
	)
	var recommended: Dictionary = analysis.get("recommended", {})
	if str(recommended.get("tile_name", "")) != "1筒":
		return "expected AI to keep 卡二条成叫并先打 1筒, got %s" % [recommended]
	var ting_tiles: Array = recommended.get("ting_tiles", [])
	if ting_tiles.is_empty():
		return "expected recommended discard to enter ready state"
	var has_er_tiao := false
	for tile in ting_tiles:
		if str(tile.get("suit", "")) == "tiao" and int(tile.get("rank", 0)) == 2:
			has_er_tiao = true
			break
	if not has_er_tiao:
		return "expected recommended discard to preserve 卡二条听口, got %s" % [ting_tiles]
	return true


func _test_neijiang_ai_prefers_ready_tile_that_avoids_gang_feed():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected csharp backend to be available"
	var player := _make_player_neijiang(1, [
		_make_tile(4351, "tiao", 1), _make_tile(4352, "tiao", 1), _make_tile(4353, "tiao", 1),
		_make_tile(4354, "tiao", 2), _make_tile(4355, "tiao", 3), _make_tile(4356, "tiao", 4),
		_make_tile(4357, "tiao", 5), _make_tile(4358, "tiao", 6), _make_tile(4359, "tiao", 7),
		_make_tile(4360, "tong", 2), _make_tile(4361, "tong", 3),
		_make_tile(4362, "tong", 7), _make_tile(4363, "tong", 8), _make_tile(4364, "tong", 9),
	])
	var seat0 := _make_player_neijiang(0, [], [{
		"type": "peng",
		"from_seat": 2,
		"tiles": [
			_make_tile(4365, "tiao", 4),
			_make_tile(4366, "tiao", 4),
			_make_tile(4367, "tiao", 4),
		],
	}])
	var seat2 := _make_player_neijiang(2, [])
	var seat3 := _make_player_neijiang(3, [])
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 13
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	var options := {}
	var option_order: Array = []
	for option in analysis.get("options", []):
		options[str(option.get("tile_name", ""))] = option
		option_order.append(str(option.get("tile_name", "")))
	if not options.has("4条") or not options.has("7条"):
		return "expected both 4条 and 7条 options, got %s" % [analysis.get("options", [])]
	if int(options["4条"].get("live_ukeire", -1)) != int(options["7条"].get("live_ukeire", -2)):
		return "expected 4条 and 7条 to stay comparable on live ukeire, got %s / %s" % [options["4条"], options["7条"]]
	if int(options["4条"].get("risk", 0)) <= int(options["7条"].get("risk", 0)):
		return "expected 4条 risk to be higher because it can feed gang, got %s / %s" % [options["4条"], options["7条"]]
	if option_order.find("7条") == -1 or option_order.find("4条") == -1:
		return "expected 4条 and 7条 to appear in candidate order, got %s" % [option_order]
	if option_order.find("7条") > option_order.find("4条"):
		return "expected safer 7条 to rank ahead of 4条 among comparable ready options, got %s" % [option_order]
	return true


func _test_neijiang_ai_avoids_early_peng_without_ready_gain():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(1, [
		_make_tile(441, "tiao", 2), _make_tile(442, "tiao", 3), _make_tile(443, "tiao", 4),
		_make_tile(444, "tiao", 5), _make_tile(445, "tiao", 6), _make_tile(446, "tiao", 7),
		_make_tile(447, "tong", 2), _make_tile(448, "tong", 3), _make_tile(449, "tong", 4),
		_make_tile(450, "tong", 5), _make_tile(451, "tong", 5),
		_make_tile(452, "tong", 7), _make_tile(453, "tong", 8),
	])
	var players := [
		_make_player_neijiang(0, []),
		player,
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	]
	_set_test_players(game_state, players)
	game_state.wall_count = 20
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	var decision: Dictionary = game_state.ai_manager.analyze_reaction(
		{
			"seat": 1,
			"can_hu": false,
			"can_gang": false,
			"can_peng": true,
			"source_seat": 0,
		},
		game_state._build_player_state(1),
		game_state._build_table_state(),
		{"source_seat": 0, "tile": _make_tile(454, "tong", 5), "reaction_type": "discard"},
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	if str(decision.get("action", "")) != "pass":
		return "expected early neijiang AI to pass on low-value peng, got %s" % [decision]
	return true


func _test_neijiang_ai_passes_risky_late_peng_under_posterior():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(1, [
		_make_tile(4551, "tiao", 2), _make_tile(4552, "tiao", 3), _make_tile(4553, "tiao", 4),
		_make_tile(4554, "tiao", 6), _make_tile(4555, "tiao", 7),
		_make_tile(4556, "tong", 2), _make_tile(4557, "tong", 3), _make_tile(4558, "tong", 4),
		_make_tile(4559, "tong", 5), _make_tile(4560, "tong", 5),
		_make_tile(4561, "tong", 7), _make_tile(4562, "tong", 8), _make_tile(4563, "tiao", 9),
	])
	player["discards"] = [
		_make_tile(4564, "tiao", 1), _make_tile(4565, "tong", 1), _make_tile(4566, "tiao", 5),
		_make_tile(4567, "tong", 9), _make_tile(4568, "tiao", 8), _make_tile(4569, "tong", 6),
		_make_tile(4570, "tiao", 1), _make_tile(4571, "tong", 1), _make_tile(4572, "tiao", 5),
	]
	var seat0 := _make_player_neijiang(0, [])
	seat0["bao_jiao"] = true
	seat0["discards"] = [_make_tile(4573, "tong", 2), _make_tile(4574, "tong", 3), _make_tile(4575, "tong", 4)]
	var seat2 := _make_player_neijiang(2, [], [{
		"type": "peng",
		"from_seat": 0,
		"tiles": [_make_tile(4576, "tong", 7), _make_tile(4577, "tong", 7), _make_tile(4578, "tong", 7)]
	}], true)
	seat2["discards"] = [_make_tile(4579, "tiao", 2), _make_tile(4580, "tiao", 3), _make_tile(4581, "tiao", 4)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(4582, "tong", 8), _make_tile(4583, "tong", 9), _make_tile(4584, "tiao", 9)]
	var players := [seat0, player, seat2, seat3]
	_set_test_players(game_state, players)
	game_state.wall_count = 7
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	var decision: Dictionary = game_state.ai_manager.analyze_reaction(
		{
			"seat": 1,
			"can_hu": false,
			"can_gang": false,
			"can_peng": true,
			"source_seat": 0,
		},
		game_state._build_player_state(1),
		game_state._build_table_state(),
		{"source_seat": 0, "tile": _make_tile(4585, "tong", 5), "reaction_type": "discard"},
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	if str(decision.get("action", "")) != "pass":
		return "expected late risky peng to pass under posterior pressure, got %s" % [decision]
	return true


func _test_neijiang_ai_rejects_late_bao_jiao_after_opening():
	var game_state = _build_neijiang_test_game_state()
	game_state.wall_count = 8
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(481, "tiao", 1), _make_tile(482, "tiao", 1), _make_tile(483, "tiao", 1),
			_make_tile(484, "tiao", 2), _make_tile(485, "tiao", 2), _make_tile(486, "tiao", 2),
			_make_tile(487, "tiao", 3), _make_tile(488, "tiao", 3), _make_tile(489, "tiao", 3),
			_make_tile(490, "tong", 5), _make_tile(491, "tong", 6), _make_tile(492, "tong", 7),
			_make_tile(493, "tong", 8), _make_tile(494, "tong", 8),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[1]["discards"] = [_make_tile(495, "tong", 1)]
	if bool(game_state._should_ai_bao_jiao(1)):
		return "expected late-stage bao jiao to be rejected after opening"
	return true


func _test_neijiang_ai_preserves_gui_potential_tiles():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(1, [
		_make_tile(501, "tong", 8), _make_tile(502, "tong", 8), _make_tile(503, "tong", 8), _make_tile(504, "tong", 8),
		_make_tile(505, "tiao", 2), _make_tile(506, "tiao", 3), _make_tile(507, "tiao", 4),
		_make_tile(508, "tiao", 5), _make_tile(509, "tiao", 6), _make_tile(510, "tiao", 7),
		_make_tile(511, "tong", 2), _make_tile(512, "tong", 3), _make_tile(513, "tong", 4),
		_make_tile(514, "tong", 6),
	])
	var players := [
		_make_player_neijiang(0, []),
		player,
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	]
	_set_test_players(game_state, players)
	game_state.wall_count = 19
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false,
	)
	var recommended: Dictionary = analysis.get("recommended", {})
	if str(recommended.get("tile_name", "")) == "8筒":
		return "expected AI not to break obvious 归 potential, got %s" % [recommended]
	return true


func _test_neijiang_ai_penalizes_late_add_gang_when_not_ready():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(1, [
		_make_tile(521, "tong", 9),
		_make_tile(522, "tiao", 1), _make_tile(523, "tiao", 3), _make_tile(524, "tiao", 5),
		_make_tile(525, "tiao", 7), _make_tile(526, "tong", 1), _make_tile(527, "tong", 3),
		_make_tile(528, "tong", 5), _make_tile(529, "tong", 7), _make_tile(530, "tong", 8),
	], [{
		"type": "peng",
		"from_seat": 0,
		"tiles": [
			_make_tile(531, "tong", 9), _make_tile(532, "tong", 9), _make_tile(533, "tong", 9)
		]
	}])
	player["discards"] = [
		_make_tile(540, "tiao", 9), _make_tile(541, "tong", 2), _make_tile(542, "tong", 4),
		_make_tile(543, "tiao", 8), _make_tile(544, "tong", 6), _make_tile(545, "tiao", 6),
		_make_tile(546, "tong", 1), _make_tile(547, "tiao", 4), _make_tile(548, "tong", 3),
		_make_tile(549, "tiao", 2), _make_tile(550, "tong", 7), _make_tile(551, "tiao", 5),
	]
	var players := [
		_make_player_neijiang(0, []),
		player,
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	]
	_set_test_players(game_state, players)
	game_state.wall_count = 7
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var tile_type := 17
	var decision: Dictionary = game_state.ai_manager.analyze_self_action(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		false,
		[],
		[tile_type],
		{str(tile_type): 0}
	)
	if str(decision.get("action", "")) == "gang":
		return "expected C# late non-ready add gang to pass, got %s" % [decision]
	return true


func _test_neijiang_ai_penalizes_high_posterior_add_gang():
	var game_state = _build_neijiang_test_game_state()
	var player := _make_player_neijiang(1, [
		_make_tile(5591, "tong", 9),
		_make_tile(5592, "tiao", 2), _make_tile(5593, "tiao", 4), _make_tile(5594, "tiao", 6),
		_make_tile(5595, "tiao", 8), _make_tile(5596, "tong", 1), _make_tile(5597, "tong", 3),
		_make_tile(5598, "tong", 5), _make_tile(5599, "tong", 7), _make_tile(5600, "tong", 8),
	], [{
		"type": "peng",
		"from_seat": 0,
		"tiles": [_make_tile(5601, "tong", 9), _make_tile(5602, "tong", 9), _make_tile(5603, "tong", 9)]
	}])
	player["discards"] = [
		_make_tile(5604, "tiao", 9), _make_tile(5605, "tong", 2), _make_tile(5606, "tong", 4),
		_make_tile(5607, "tiao", 8), _make_tile(5608, "tong", 6), _make_tile(5609, "tiao", 6),
		_make_tile(5610, "tong", 1), _make_tile(5611, "tiao", 4), _make_tile(5612, "tong", 3),
	]
	var seat0 := _make_player_neijiang(0, [])
	seat0["bao_jiao"] = true
	seat0["discards"] = [_make_tile(5613, "tong", 7), _make_tile(5614, "tong", 8), _make_tile(5615, "tong", 9)]
	var seat2 := _make_player_neijiang(2, [], [{
		"type": "peng",
		"from_seat": 0,
		"tiles": [_make_tile(5616, "tong", 5), _make_tile(5617, "tong", 5), _make_tile(5618, "tong", 5)]
	}], true)
	seat2["discards"] = [_make_tile(5619, "tiao", 2), _make_tile(5620, "tiao", 3), _make_tile(5621, "tiao", 4)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(5622, "tong", 2), _make_tile(5623, "tong", 3), _make_tile(5624, "tong", 4)]
	var players := [seat0, player, seat2, seat3]
	_set_test_players(game_state, players)
	game_state.wall_count = 8
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var tile_type := 17
	var decision: Dictionary = game_state.ai_manager.analyze_self_action(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		false,
		[],
		[tile_type],
		{str(tile_type): 1}
	)
	if str(decision.get("action", "")) == "gang":
		return "expected C# high-posterior/qiang-gang-risk add gang to pass, got %s" % [decision]
	var reasons: Array = decision.get("reasons", [])
	if not str(reasons).contains("抢杠胡"):
		return "expected C# add gang reasons to mention 抢杠胡 risk, got %s" % [decision]
	return true


func _test_neijiang_human_peng_button_hidden_when_higher_priority_blocks():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 3
	game_state.current_dealer_seat = 0
	var discarded_tile := _make_tile(5700, "tiao", 9)
	game_state.current_discard_context = {
		"source_seat": 3,
		"tile": discarded_tile.duplicate(true),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(5701, "tiao", 9), _make_tile(5702, "tiao", 9),
			_make_tile(5703, "tiao", 1), _make_tile(5704, "tiao", 2), _make_tile(5705, "tiao", 3),
			_make_tile(5706, "tiao", 4), _make_tile(5707, "tiao", 5), _make_tile(5708, "tiao", 6),
			_make_tile(5709, "tong", 2), _make_tile(5710, "tong", 3), _make_tile(5711, "tong", 4),
			_make_tile(5712, "tong", 6), _make_tile(5713, "tong", 7),
		]),
		_make_player_neijiang(1, [
			_make_tile(5714, "tiao", 1), _make_tile(5715, "tiao", 2), _make_tile(5716, "tiao", 3),
			_make_tile(5717, "tiao", 4), _make_tile(5718, "tiao", 5), _make_tile(5719, "tiao", 6),
			_make_tile(5720, "tong", 1), _make_tile(5721, "tong", 2), _make_tile(5722, "tong", 3),
			_make_tile(5723, "tong", 4), _make_tile(5724, "tong", 5), _make_tile(5725, "tong", 6),
			_make_tile(5726, "tiao", 9), _make_tile(5727, "tiao", 9),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.pending_reactions.clear()
	game_state.pending_reactions.append_array([
		{"seat": 1, "can_hu": true, "can_gang": false, "can_peng": false},
		{"seat": 0, "can_hu": false, "can_gang": false, "can_peng": true},
	])
	var options: Dictionary = game_state.get_human_reaction_options(0)
	if bool(options.get("can_peng", false)):
		return "expected human peng button hidden while a higher-priority hu is unresolved, got %s" % [options]
	if bool(game_state.execute_human_peng(0)):
		return "expected direct peng execution to remain blocked by higher-priority hu"
	return true


func _test_neijiang_human_peng_clears_pending_ai_reaction():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 3
	game_state.current_dealer_seat = 0
	var discarded_tile := _make_tile(5730, "tiao", 9)
	game_state.current_discard_context = {
		"source_seat": 3,
		"tile": discarded_tile.duplicate(true),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	game_state.discard_pile.clear()
	game_state.discard_pile.append({"seat": 3, "tile": discarded_tile.duplicate(true)})
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(5731, "tiao", 9), _make_tile(5732, "tiao", 9),
			_make_tile(5733, "tiao", 1), _make_tile(5734, "tiao", 2), _make_tile(5735, "tiao", 3),
			_make_tile(5736, "tiao", 4), _make_tile(5737, "tiao", 5), _make_tile(5738, "tiao", 6),
			_make_tile(5739, "tong", 2), _make_tile(5740, "tong", 3), _make_tile(5741, "tong", 4),
			_make_tile(5742, "tong", 6), _make_tile(5743, "tong", 7),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.pending_reactions.clear()
	game_state.pending_reactions.append({"seat": 0, "can_hu": false, "can_gang": false, "can_peng": true})
	game_state.pending_ai_reaction_request_id = 5701
	game_state.pending_ai_reaction_request_meta = {
		"round_index": game_state.round_index,
		"phase": int(game_state.current_phase),
		"source_seat": 3,
		"tile_id": 5730,
		"pending_count": 1,
	}
	game_state.pending_ai_reaction_decision = {
		"round_index": game_state.round_index,
		"phase": int(game_state.current_phase),
		"source_seat": 3,
		"tile_id": 5730,
		"pending_count": 1,
		"seat": 2,
		"candidate": {"seat": 2, "can_peng": true},
		"decision": {"action": "peng"},
	}
	var options: Dictionary = game_state.get_human_reaction_options(0)
	if not bool(options.get("can_peng", false)):
		return "expected human peng to be offered when no higher-priority reaction exists, got %s" % [options]
	if not bool(game_state.execute_human_peng(0)):
		return "expected human peng to execute"
	if int(game_state.current_phase) != int(GAME_STATE_SCRIPT.RoundPhase.DISCARD):
		return "expected human peng to enter discard phase, got %s" % [game_state.current_phase]
	if int(game_state.current_turn_seat) != 0:
		return "expected current turn to move to human after peng, got %s" % [game_state.current_turn_seat]
	if game_state.pending_ai_reaction_request_id != 0 or not game_state.pending_ai_reaction_request_meta.is_empty():
		return "expected pending ai reaction request to clear after human peng"
	if not game_state.pending_ai_reaction_decision.is_empty():
		return "expected pending ai reaction decision to clear after human peng"
	if Array(game_state.players[0].get("melds", [])).size() != 1:
		return "expected human melds to contain one peng, got %s" % [game_state.players[0].get("melds", [])]
	return true


func _test_neijiang_human_peng_8_tiao_ignores_stale_ding_que():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 2
	game_state.current_dealer_seat = 0
	var discarded_tile := _make_tile(5750, "tiao", 8)
	game_state.current_discard_context = {
		"source_seat": 2,
		"tile": discarded_tile.duplicate(true),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	game_state.discard_pile.clear()
	game_state.discard_pile.append({"seat": 2, "tile": discarded_tile.duplicate(true)})
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(5751, "tiao", 8), _make_tile(5752, "tiao", 8),
			_make_tile(5753, "tiao", 1), _make_tile(5754, "tiao", 2), _make_tile(5755, "tiao", 3),
			_make_tile(5756, "tiao", 4), _make_tile(5757, "tiao", 5), _make_tile(5758, "tiao", 6),
			_make_tile(5759, "tong", 2), _make_tile(5760, "tong", 3), _make_tile(5761, "tong", 4),
			_make_tile(5762, "tong", 6), _make_tile(5763, "tong", 7),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[0]["ding_que"] = "tiao"
	game_state.pending_reactions.clear()
	game_state.pending_reactions.append({"seat": 0, "can_hu": false, "can_gang": false, "can_peng": true})
	var options: Dictionary = game_state.get_human_reaction_options(0)
	if not bool(options.get("can_peng", false)):
		return "expected stale ding_que not to hide 8条 peng in Neijiang, got %s" % [options]
	if not bool(game_state.execute_human_peng(0)):
		return "expected 8条 peng to execute despite stale ding_que, debug=%s" % [game_state.debug_last_message]
	if int(game_state.current_phase) != int(GAME_STATE_SCRIPT.RoundPhase.DISCARD):
		return "expected human peng to enter discard phase, got %s" % [game_state.current_phase]
	if int(game_state.current_turn_seat) != 0:
		return "expected current turn to move to human after 8条 peng, got %s" % [game_state.current_turn_seat]
	return true


func _test_neijiang_ai_failed_peng_auto_passes():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 2
	game_state.current_dealer_seat = 0
	game_state.wall.clear()
	game_state.wall.append_array([
		_make_tile(5760, "tiao", 1),
		_make_tile(5761, "tong", 2),
	])
	game_state.wall_count = game_state.wall.size()
	var discarded_tile := _make_tile(5750, "tong", 9)
	game_state.current_discard_context = {
		"source_seat": 2,
		"tile": discarded_tile.duplicate(true),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	game_state.discard_pile.clear()
	game_state.discard_pile.append({"seat": 2, "tile": discarded_tile.duplicate(true)})
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, [
			_make_tile(5751, "tong", 9),
			_make_tile(5752, "tiao", 1), _make_tile(5753, "tiao", 2), _make_tile(5754, "tiao", 3),
		]),
	])
	game_state.pending_reactions.clear()
	game_state.pending_reactions.append({"seat": 3, "can_hu": false, "can_gang": false, "can_peng": true})
	game_state.pending_ai_reaction_decision = {
		"round_index": game_state.round_index,
		"phase": int(game_state.current_phase),
		"source_seat": 2,
		"tile_id": 5750,
		"pending_count": 1,
		"seat": 3,
		"candidate": game_state.pending_reactions[0].duplicate(true),
		"decision": {"action": "peng", "backend_mode": "test"},
	}
	if not bool(game_state.run_ai_reaction()):
		return "expected failed AI peng to auto-pass and resolve"
	if int(game_state.current_phase) != int(GAME_STATE_SCRIPT.RoundPhase.DISCARD):
		return "expected failed AI peng auto-pass to resume discard phase, got %s" % [game_state.current_phase]
	if int(game_state.current_turn_seat) != 1:
		return "expected next active seat after source 2 to be seat 1, got %s" % [game_state.current_turn_seat]
	if not game_state.pending_reactions.is_empty():
		return "expected pending reactions to clear after failed AI peng auto-pass"
	if str(game_state.debug_last_message).find("自动过牌") == -1:
		return "expected debug message to mention auto-pass, got %s" % [game_state.debug_last_message]
	return true


func _test_neijiang_pass_reaction_resumes_human_draw_turn():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	game_state.wall.clear()
	game_state.wall.append_array([
		_make_tile(701, "tong", 9),
		_make_tile(702, "tiao", 8),
	])
	game_state.wall_count = game_state.wall.size()
	var discarded_tile := _make_tile(700, "tong", 5)
	game_state.current_discard_context = {
		"source_seat": 1,
		"tile": discarded_tile.duplicate(true),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	game_state.pending_reactions.clear()
	game_state.pending_reactions.append_array([
		{
			"seat": 0,
			"can_peng": true,
			"can_gang": false,
			"can_hu": false,
		},
		{
			"seat": 2,
			"can_peng": false,
			"can_gang": false,
			"can_hu": false,
		},
	])
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(711, "tiao", 1), _make_tile(712, "tiao", 1), _make_tile(713, "tiao", 2),
			_make_tile(714, "tiao", 3), _make_tile(715, "tiao", 4), _make_tile(716, "tiao", 5),
			_make_tile(717, "tong", 2), _make_tile(718, "tong", 3), _make_tile(719, "tong", 4),
			_make_tile(720, "tong", 6), _make_tile(721, "tong", 7), _make_tile(722, "tong", 8),
			_make_tile(723, "tong", 8),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if not bool(game_state.pass_human_reaction(0)):
		return "expected human pass on reaction to succeed"
	if not bool(game_state._pass_ai_reaction(2)):
		return "expected remaining ai reaction pass to succeed"
	if int(game_state.current_phase) != int(GAME_STATE_SCRIPT.RoundPhase.DISCARD):
		return "expected reaction resolution to resume discard phase, got %s" % [game_state.current_phase]
	if int(game_state.current_turn_seat) != 0:
		return "expected next draw turn to resume at human seat 0, got %s" % [game_state.current_turn_seat]
	if not bool(game_state.can_human_discard(0)):
		return "expected human to be able to discard after resumed draw turn"
	if int(game_state.players[0].get("hand_count", 0)) != 14:
		return "expected human hand count to become 14 after resumed draw, got %s" % [game_state.players[0].get("hand_count", 0)]
	return true


func _test_neijiang_peng_without_draw_does_not_enable_self_hu():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	game_state.last_draw_tile = {}
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(731, "tiao", 1), _make_tile(732, "tiao", 1), _make_tile(733, "tiao", 1),
			_make_tile(734, "tiao", 2), _make_tile(735, "tiao", 3), _make_tile(736, "tiao", 4),
			_make_tile(737, "tiao", 5), _make_tile(738, "tiao", 6), _make_tile(739, "tiao", 7),
			_make_tile(740, "tong", 2), _make_tile(741, "tong", 2),
		], [{
			"type": "peng",
			"from_seat": 1,
			"tiles": [
				_make_tile(742, "tong", 9), _make_tile(743, "tong", 9), _make_tile(744, "tong", 9)
			]
		}]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if bool(game_state.can_human_self_hu(0)):
		return "expected no self-hu prompt after peng/discard phase without a fresh draw"
	return true


func _test_neijiang_ai_peng_starts_discard_analysis():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	var discarded_tile := _make_tile(760, "tong", 9)
	game_state.current_discard_context = {
		"source_seat": 0,
		"tile": discarded_tile.duplicate(true),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(761, "tong", 9), _make_tile(762, "tong", 9),
			_make_tile(763, "tiao", 1), _make_tile(764, "tiao", 2), _make_tile(765, "tiao", 3),
			_make_tile(766, "tiao", 4), _make_tile(767, "tiao", 5), _make_tile(768, "tiao", 6),
			_make_tile(769, "tong", 2), _make_tile(770, "tong", 3), _make_tile(771, "tong", 4),
			_make_tile(772, "tong", 6), _make_tile(773, "tong", 7),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.pending_reactions.clear()
	game_state.pending_reactions.append({
		"seat": 1,
		"can_peng": true,
		"can_gang": false,
		"can_hu": false,
	})
	game_state.pending_ai_reaction_decision = {
		"round_index": game_state.round_index,
		"phase": int(game_state.current_phase),
		"source_seat": 0,
		"tile_id": int(discarded_tile.get("id", -1)),
		"pending_count": game_state.pending_reactions.size(),
		"seat": 1,
		"candidate": game_state.pending_reactions[0].duplicate(true),
		"decision": {"action": "peng", "backend_mode": "test"},
	}
	if not bool(game_state.run_ai_reaction()):
		return "expected AI peng reaction to execute"
	if int(game_state.current_phase) != int(GAME_STATE_SCRIPT.RoundPhase.DISCARD):
		return "expected AI peng to enter discard phase, got %s" % [game_state.current_phase]
	if int(game_state.current_turn_seat) != 1:
		return "expected AI peng seat to become current turn, got %s" % [game_state.current_turn_seat]
	if game_state.pending_ai_turn_request_id <= 0 and game_state.pending_ai_turn_decision.is_empty():
		return "expected AI peng to start or prepare discard analysis"
	return true


func _test_neijiang_stale_ding_que_must_not_block_discard():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 1
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(901, "tiao", 3),
			_make_tile(902, "tong", 6),
			_make_tile(903, "tiao", 7),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.players[0]["ding_que"] = "tong"
	if not bool(game_state.discard_tile_by_id(0, 901)):
		return "内江模式不应因残留 ding_que=筒 而禁止打出条牌"
	return true


func _test_neijiang_second_reaction_after_peng_discard_is_fresh():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	var first_discard := _make_tile(780, "tong", 8)
	game_state.current_discard_context = {
		"source_seat": 0,
		"tile": first_discard.duplicate(true),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(781, "tong", 9), _make_tile(782, "tong", 9),
			_make_tile(783, "tiao", 1), _make_tile(784, "tiao", 2), _make_tile(785, "tiao", 3),
			_make_tile(786, "tiao", 4), _make_tile(787, "tiao", 5), _make_tile(788, "tiao", 6),
			_make_tile(789, "tong", 2), _make_tile(790, "tong", 3), _make_tile(791, "tong", 4),
			_make_tile(792, "tong", 6), _make_tile(793, "tong", 7),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, [
			_make_tile(794, "tong", 8), _make_tile(795, "tong", 8), _make_tile(796, "tong", 9),
			_make_tile(797, "tiao", 1), _make_tile(798, "tiao", 2), _make_tile(799, "tiao", 3),
			_make_tile(800, "tiao", 4), _make_tile(801, "tiao", 5), _make_tile(802, "tiao", 6),
			_make_tile(803, "tong", 2), _make_tile(804, "tong", 3), _make_tile(805, "tong", 4),
			_make_tile(806, "tong", 6),
		]),
	])
	game_state.pending_reactions.clear()
	game_state.pending_reactions.append({
		"seat": 3,
		"can_peng": true,
		"can_gang": false,
		"can_hu": false,
	})
	game_state.pending_ai_reaction_decision = {
		"round_index": game_state.round_index,
		"phase": int(game_state.current_phase),
		"source_seat": 0,
		"tile_id": int(first_discard.get("id", -1)),
		"pending_count": game_state.pending_reactions.size(),
		"seat": 3,
		"candidate": game_state.pending_reactions[0].duplicate(true),
		"decision": {"action": "peng", "backend_mode": "test"},
	}
	if not bool(game_state.run_ai_reaction()):
		return "expected first AI peng to execute"
	game_state.pending_ai_turn_decision.clear()
	game_state._clear_pending_ai_turn_request()
	game_state.pending_ai_reaction_decision = {
		"round_index": game_state.round_index,
		"phase": int(GAME_STATE_SCRIPT.RoundPhase.REACTION),
		"source_seat": 0,
		"tile_id": int(first_discard.get("id", -1)),
		"pending_count": 1,
		"seat": 3,
		"candidate": {"seat": 3, "can_peng": true},
		"decision": {"action": "peng"},
	}
	if not bool(game_state._discard_tile_internal(3, 796)):
		return "expected peng player to discard 9筒"
	var second_tile: Dictionary = game_state.current_discard_context.get("tile", {})
	if int(game_state.current_discard_context.get("source_seat", -1)) != 3 or int(second_tile.get("id", -1)) != 796:
		return "expected fresh second discard context for seat 3 / 9筒, got %s" % [game_state.current_discard_context]
	var candidate: Dictionary = game_state._get_reaction_candidate_for_seat(1)
	if candidate.is_empty() or not bool(candidate.get("can_peng", false)):
		return "expected seat 1 to have fresh peng candidate on 9筒, got %s" % [game_state.pending_reactions]
	if not game_state.pending_ai_reaction_decision.is_empty():
		var decision_tile_id := int(game_state.pending_ai_reaction_decision.get("tile_id", -1))
		if decision_tile_id != 796:
			return "expected pending reaction decision to match second 9筒, got %s" % [game_state.pending_ai_reaction_decision]
	return true


func _test_neijiang_pass_self_hu_keeps_human_discard_turn():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	game_state.last_draw_tile = {
		"seat": 0,
		"tile": _make_tile(765, "tong", 4),
	}
	_set_test_players(game_state, [
		_make_player_neijiang(0, [
			_make_tile(751, "tiao", 1), _make_tile(752, "tiao", 1), _make_tile(753, "tiao", 1),
			_make_tile(754, "tiao", 2), _make_tile(755, "tiao", 2), _make_tile(756, "tiao", 2),
			_make_tile(757, "tiao", 3), _make_tile(758, "tiao", 3), _make_tile(759, "tiao", 3),
			_make_tile(760, "tong", 4), _make_tile(761, "tong", 4), _make_tile(762, "tong", 4),
			_make_tile(763, "tong", 5), _make_tile(764, "tong", 5),
		]),
		_make_player_neijiang(1, []),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if not bool(game_state.can_human_self_hu(0)):
		return "expected winning hand to allow self-hu before pass"
	if not bool(game_state.pass_human_self_hu(0)):
		return "expected pass self-hu to succeed"
	if bool(game_state.can_human_self_hu(0)):
		return "expected passed self-hu lock to suppress immediate repeat prompt"
	if not bool(game_state.can_human_discard(0)):
		return "expected player to keep discard right after passing self-hu"
	if not bool(game_state.discard_tile_by_id(0, 764)):
		return "expected player to still be able to discard after passing self-hu"
	return true


func _test_neijiang_hybrid_csharp_returns_enriched_candidates():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	var player := _make_player_neijiang(1, [
		_make_tile(931, "tiao", 2), _make_tile(932, "tiao", 3), _make_tile(933, "tiao", 4),
		_make_tile(934, "tiao", 5), _make_tile(935, "tiao", 6), _make_tile(936, "tiao", 7),
		_make_tile(937, "tong", 2), _make_tile(938, "tong", 3), _make_tile(939, "tong", 4),
		_make_tile(940, "tong", 5), _make_tile(941, "tong", 6), _make_tile(942, "tong", 8),
		_make_tile(943, "tong", 8), _make_tile(944, "tong", 9),
	], [
		{
			"type": "peng",
			"from_seat": 2,
			"tiles": [
				_make_tile(945, "tiao", 9),
				_make_tile(946, "tiao", 9),
				_make_tile(947, "tiao", 9),
			],
		},
	])
	player["discards"] = [
		_make_tile(948, "tong", 1),
		_make_tile(949, "tiao", 1),
	]
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(950, "tiao", 8), _make_tile(951, "tong", 7)]
	var seat2 := _make_player_neijiang(2, [], [{
		"type": "peng",
		"from_seat": 0,
		"tiles": [
			_make_tile(952, "tong", 6),
			_make_tile(953, "tong", 6),
			_make_tile(954, "tong", 6),
		],
	}])
	seat2["discards"] = [_make_tile(955, "tong", 2)]
	var seat3 := _make_player_neijiang(3, [], [], true)
	seat3["discards"] = [_make_tile(956, "tiao", 7), _make_tile(957, "tiao", 6)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 36
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected hybrid_csharp backend_mode, got %s" % [analysis.get("backend_mode", "")]
	var recommended: Dictionary = analysis.get("recommended", {})
	if recommended.is_empty():
		return "expected hybrid backend to return recommended discard"
	if not recommended.has("wait_count") or not recommended.has("strategy_mode") or not recommended.has("expected_value"):
		return "expected enriched candidate fields from csharp merge, got %s" % [recommended.keys()]
	if not recommended.has("csharp_wait_count") or not recommended.has("csharp_strategy_mode"):
		return "expected raw csharp candidate fields to be preserved, got %s" % [recommended.keys()]
	if not recommended.has("posterior_adjustment") or not recommended.has("posterior_reasons"):
		return "expected posterior explanation fields on recommended option, got %s" % [recommended.keys()]
	if str(recommended.get("risk_label", "")) == "":
		return "expected merged risk label to be non-empty"
	return true


func _test_neijiang_hybrid_csharp_returns_routes_and_strategy_profile():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	var player := _make_player_neijiang(1, [
		_make_tile(961, "tiao", 2), _make_tile(962, "tiao", 2),
		_make_tile(963, "tiao", 3), _make_tile(964, "tiao", 3),
		_make_tile(965, "tiao", 4), _make_tile(966, "tiao", 4),
		_make_tile(967, "tong", 6), _make_tile(968, "tong", 6),
		_make_tile(969, "tong", 7), _make_tile(970, "tong", 7),
		_make_tile(971, "tong", 8), _make_tile(972, "tong", 8),
		_make_tile(973, "tong", 9), _make_tile(974, "tong", 9),
	])
	player["discards"] = [_make_tile(975, "tiao", 1)]
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(976, "tong", 1), _make_tile(977, "tong", 2)]
	var seat2 := _make_player_neijiang(2, [], [{
		"type": "peng",
		"from_seat": 0,
		"tiles": [
			_make_tile(978, "tong", 5),
			_make_tile(979, "tong", 5),
			_make_tile(980, "tong", 5),
		],
	}])
	seat2["discards"] = [_make_tile(981, "tiao", 7), _make_tile(982, "tiao", 8)]
	var seat3 := _make_player_neijiang(3, [], [], true)
	seat3["discards"] = [_make_tile(983, "tong", 3), _make_tile(984, "tong", 4)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 18
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected hybrid_csharp backend_mode, got %s" % [analysis.get("backend_mode", "")]
	var current_routes: Array = analysis.get("current_routes", [])
	if current_routes.is_empty() or not current_routes.has("七对"):
		return "expected csharp current_routes to contain 七对, got %s" % [current_routes]
	var strategy_profile: Dictionary = analysis.get("strategy_profile", {})
	if str(strategy_profile.get("round_stage_label", "")) == "":
		return "expected merged strategy_profile round_stage_label"
	var opponent_state: Dictionary = strategy_profile.get("opponent_state", {})
	if int(opponent_state.get("flush_watch_count", -1)) < 0:
		return "expected merged opponent_state flush_watch_count, got %s" % [opponent_state]
	var top_threat_profile: Dictionary = opponent_state.get("top_threat_profile", {})
	if not top_threat_profile.has("seat"):
		return "expected merged top_threat_profile seat field, got %s" % [top_threat_profile]
	var belief_summary: Dictionary = analysis.get("belief_summary", {})
	if not belief_summary.has("ready_posteriors") or not belief_summary.has("hold_summary") or not belief_summary.has("wall_summary"):
		return "expected belief_summary ready/hold/wall fields, got %s" % [belief_summary]
	var recommended: Dictionary = analysis.get("recommended", {})
	var routes_after: Array = recommended.get("routes_after", [])
	var route_loss: Array = recommended.get("route_loss", [])
	if routes_after.is_empty():
		return "expected csharp routes_after to be present on recommended option"
	if typeof(route_loss) != TYPE_ARRAY:
		return "expected csharp route_loss to remain an array"
	return true


func _test_neijiang_csharp_host_mode_toggle_updates_backend_status():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_csharp_host_mode_enabled(true, 38591)):
		return "expected csharp host mode setter to succeed"
	var snapshot: Dictionary = game_state.ai_manager.get_debug_snapshot()
	var backend_status: Dictionary = snapshot.get("backend_status", {})
	if not bool(backend_status.get("csharp_host_mode_enabled", false)):
		return "expected backend_status csharp_host_mode_enabled=true, got %s" % [backend_status]
	if int(backend_status.get("csharp_host_port", 0)) != 38591:
		return "expected backend_status csharp_host_port=38591, got %s" % [backend_status]
	if not bool(game_state.set_ai_csharp_host_mode_enabled(false, 38591)):
		return "expected csharp host mode disable to succeed"
	var snapshot_off: Dictionary = game_state.ai_manager.get_debug_snapshot()
	var backend_status_off: Dictionary = snapshot_off.get("backend_status", {})
	if bool(backend_status_off.get("csharp_host_mode_enabled", true)):
		return "expected backend_status csharp_host_mode_enabled=false, got %s" % [backend_status_off]
	return true


func _test_neijiang_csharp_host_mode_analyze_returns_result():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	if not bool(game_state.set_ai_csharp_host_mode_enabled(true, 38592)):
		return "expected csharp host mode enable to succeed"
	var player := _make_player_neijiang(1, [
		_make_tile(9801, "tiao", 2), _make_tile(9802, "tiao", 2),
		_make_tile(9803, "tiao", 3), _make_tile(9804, "tiao", 4),
		_make_tile(9805, "tiao", 5), _make_tile(9806, "tiao", 6),
		_make_tile(9807, "tong", 3), _make_tile(9808, "tong", 3),
		_make_tile(9809, "tong", 4), _make_tile(9810, "tong", 5),
		_make_tile(9811, "tong", 6), _make_tile(9812, "tong", 7),
		_make_tile(9813, "tong", 8), _make_tile(9814, "tong", 8),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(9815, "tiao", 1)]
	var seat2 := _make_player_neijiang(2, [])
	var seat3 := _make_player_neijiang(3, [])
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 18
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if analysis.is_empty():
		return "expected host-enabled analyze_turn to return result"
	var backend_status: Dictionary = game_state.ai_manager.get_backend_status()
	var transport_mode := str(backend_status.get("csharp_last_transport_mode", ""))
	if transport_mode == "":
		return "expected host-enabled analyze_turn to record transport mode"
	return true


func _test_neijiang_csharp_exact_safe_tile_reduces_danger():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	var player := _make_player_neijiang(1, [
		_make_tile(9851, "tiao", 2), _make_tile(9852, "tiao", 3), _make_tile(9853, "tiao", 4),
		_make_tile(9854, "tiao", 5), _make_tile(9855, "tiao", 6), _make_tile(9856, "tiao", 7),
		_make_tile(9857, "tong", 1), _make_tile(9858, "tong", 4), _make_tile(9859, "tong", 5),
		_make_tile(9860, "tong", 6), _make_tile(9861, "tong", 7), _make_tile(9862, "tong", 8),
		_make_tile(9863, "tong", 9), _make_tile(9864, "tong", 9),
	])
	player["discards"] = [_make_tile(9865, "tiao", 1)]
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(9866, "tong", 1), _make_tile(9867, "tong", 3), _make_tile(9868, "tong", 5)]
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(9869, "tiao", 8), _make_tile(9870, "tiao", 9)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(9871, "tiao", 1)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 24
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected hybrid_csharp backend_mode, got %s" % [analysis.get("backend_mode", "")]
	var options: Array = analysis.get("options", [])
	var tong_1 := {}
	var tong_9 := {}
	for option in options:
		var tile: Dictionary = option.get("tile", {})
		if str(tile.get("suit", "")) != "tong":
			continue
		if int(tile.get("rank", 0)) == 1:
			tong_1 = option
		elif int(tile.get("rank", 0)) == 9:
			tong_9 = option
	if tong_1.is_empty() or tong_9.is_empty():
		return "expected tong 1 and tong 9 discard options, got %s" % [options]
	var tong_1_reasons: Array = tong_1.get("risk_reasons", [])
	var found_exact_safe := false
	for reason in tong_1_reasons:
		if str(reason).find("现物") != -1:
			found_exact_safe = true
			break
	if not found_exact_safe:
		return "expected csharp risk reasons to mention 现物, got %s" % [tong_1_reasons]
	var tong_9_reasons: Array = tong_9.get("risk_reasons", [])
	var found_abandoned_suit := false
	for reason in tong_9_reasons:
		if str(reason).find("该门已弃多张") != -1:
			found_abandoned_suit = true
			break
	if not found_abandoned_suit:
		return "expected csharp risk reasons to mention 该门已弃多张, got %s" % [tong_9_reasons]
	return true


func _test_neijiang_csharp_belief_posterior_emits_reason():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	var player := _make_player_neijiang(1, [
		_make_tile(98721, "tiao", 2), _make_tile(98722, "tiao", 3), _make_tile(98723, "tiao", 4),
		_make_tile(98724, "tiao", 5), _make_tile(98725, "tiao", 6), _make_tile(98726, "tiao", 7),
		_make_tile(98727, "tong", 2), _make_tile(98728, "tong", 4), _make_tile(98729, "tong", 5),
		_make_tile(98730, "tong", 6), _make_tile(98731, "tong", 7), _make_tile(98732, "tong", 8),
		_make_tile(98733, "tong", 9), _make_tile(98734, "tong", 9),
	])
	var seat0 := _make_player_neijiang(0, [], [{
		"type": "peng",
		"from_seat": 2,
		"tiles": [
			_make_tile(98735, "tong", 3), _make_tile(98736, "tong", 3), _make_tile(98737, "tong", 3),
		],
	}], true)
	seat0["discards"] = [_make_tile(98738, "tiao", 1)]
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(98739, "tiao", 9)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(98740, "tong", 1)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 20
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected hybrid_csharp backend_mode, got %s" % [analysis.get("backend_mode", "")]
	var options: Array = analysis.get("options", [])
	if options.is_empty():
		return "expected hybrid csharp options"
	var found_posterior_reason := false
	for option in options:
		for reason in option.get("risk_reasons", []):
			var text := str(reason)
			if text.find("听牌后验高") != -1 or text.find("持张后验高") != -1:
				found_posterior_reason = true
				break
		if found_posterior_reason:
			break
	if not found_posterior_reason:
		return "expected posterior risk reasons from csharp belief engine"
	return true


func _test_neijiang_csharp_learning_record_updates_profile():
	var engine = load("res://scripts/core/ai_learning_engine.gd").new()
	var cli_path := ProjectSettings.globalize_path("res://dotnet/AI.Core.Cli/bin/Release/net10.0/AI.Core.Cli.dll")
	if not FileAccess.file_exists(cli_path):
		return "expected csharp learning cli to exist"
	var tmp_dir := ProjectSettings.globalize_path("user://tmp_ai_learning_regression")
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var learning_file := tmp_dir.path_join("ai学习数据_test.json")
	var history_file := tmp_dir.path_join("ai参数学习历史_test.json")
	var payload_file := tmp_dir.path_join("learning_payload_test.json")
	for path in [learning_file, history_file, payload_file]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var payload := {
		"learning_file_path": learning_file,
		"learning_history_file_path": history_file,
		"round_result": {
			"round_index": 1,
			"end_reason": "draw_wall_empty",
			"score_changes": {"0": -2, "1": 1, "2": 1, "3": 0},
			"win_events": [],
			"gang_events": [{"actor_seat": 2}],
		},
	}
	var file := FileAccess.open(payload_file, FileAccess.WRITE)
	if file == null:
		return "expected learning payload file to be writable"
	file.store_string(JSON.stringify(payload))
	file.close()
	var output: Array = []
	var exit_code := OS.execute(
		"/opt/homebrew/Cellar/dotnet/10.0.107/libexec/dotnet",
		[cli_path, "learning-record", payload_file],
		output,
		true,
		true
	)
	if exit_code != 0:
		return "expected csharp learning-record exit_code 0, got %d" % exit_code
	if not FileAccess.file_exists(learning_file):
		return "expected csharp learning to create learning file"
	if not FileAccess.file_exists(history_file):
		return "expected csharp learning to create history file"
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(learning_file))
	if typeof(parsed) != TYPE_DICTIONARY:
		return "expected learning profile json dictionary"
	if int(parsed.get("total_human_rounds", 0)) != 1:
		return "expected csharp learning profile total_human_rounds=1, got %s" % [parsed]
	return true


func _test_neijiang_csharp_search_marks_close_candidates():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	var player := _make_player_neijiang(1, [
		_make_tile(9873, "tiao", 2), _make_tile(9874, "tiao", 3), _make_tile(9875, "tiao", 4),
		_make_tile(9876, "tiao", 5), _make_tile(9877, "tiao", 6), _make_tile(9878, "tiao", 7),
		_make_tile(9879, "tong", 2), _make_tile(9880, "tong", 3), _make_tile(9881, "tong", 4),
		_make_tile(9882, "tong", 5), _make_tile(9883, "tong", 6), _make_tile(9884, "tong", 7),
		_make_tile(9885, "tong", 8), _make_tile(9886, "tong", 9),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(9887, "tiao", 1), _make_tile(9888, "tong", 1)]
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(9889, "tiao", 9)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(9890, "tong", 9)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 28
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if str(analysis.get("backend_mode", "")) != "hybrid_csharp":
		return "expected hybrid_csharp backend_mode, got %s" % [analysis.get("backend_mode", "")]
	var options: Array = analysis.get("options", [])
	if options.is_empty():
		return "expected hybrid csharp options"
	var found_search_used := false
	for option in options:
		if bool(option.get("search_used", false)):
			found_search_used = true
			if not option.has("search_bonus"):
				return "expected search_used option to expose search_bonus"
			break
	if not found_search_used:
		return "expected at least one option to mark search_used"
	return true


func _test_neijiang_ai_manager_records_performance_metrics():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	var player := _make_player_neijiang(1, [
		_make_tile(991, "tiao", 2), _make_tile(992, "tiao", 2),
		_make_tile(993, "tiao", 3), _make_tile(994, "tiao", 4),
		_make_tile(995, "tiao", 5), _make_tile(996, "tiao", 6),
		_make_tile(997, "tong", 3), _make_tile(998, "tong", 3),
		_make_tile(999, "tong", 4), _make_tile(1000, "tong", 5),
		_make_tile(1001, "tong", 6), _make_tile(1002, "tong", 7),
		_make_tile(1003, "tong", 8), _make_tile(1004, "tong", 8),
	])
	player["discards"] = [_make_tile(1005, "tiao", 1)]
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(1006, "tong", 1)]
	var seat2 := _make_player_neijiang(2, [])
	seat2["discards"] = [_make_tile(1007, "tiao", 7)]
	var seat3 := _make_player_neijiang(3, [])
	seat3["discards"] = [_make_tile(1008, "tong", 9)]
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 24
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var turn_analysis: Dictionary = game_state.ai_manager.analyze_turn(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if turn_analysis.is_empty():
		return "expected analyze_turn to return a result"
	var candidate := {
		"seat": 1,
		"action": "peng",
		"source_seat": 0,
		"tile": _make_tile(1009, "tong", 3),
		"tiles": [
			_make_tile(1010, "tong", 3),
			_make_tile(1011, "tong", 3),
			_make_tile(1012, "tong", 3),
		],
	}
	var discard_context := {
		"source_seat": 0,
		"tile": _make_tile(1013, "tong", 3),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	var reaction_analysis: Dictionary = game_state.ai_manager.analyze_reaction(
		candidate,
		game_state._build_player_state(1),
		game_state._build_table_state(),
		discard_context,
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		false
	)
	if reaction_analysis.is_empty():
		return "expected analyze_reaction to return a result"
	var snapshot: Dictionary = game_state.ai_manager.get_debug_snapshot()
	var metrics: Dictionary = snapshot.get("performance_metrics", {})
	if int(metrics.get("turn_count", 0)) < 1:
		return "expected turn_count >= 1, got %s" % [metrics.get("turn_count", 0)]
	if float(metrics.get("turn_avg_ms", -1.0)) < 0.0:
		return "expected non-negative turn_avg_ms, got %s" % [metrics.get("turn_avg_ms", -1.0)]
	if int(metrics.get("turn_max_ms", -1)) < 0:
		return "expected non-negative turn_max_ms, got %s" % [metrics.get("turn_max_ms", -1)]
	if int(metrics.get("reaction_count", 0)) < 1:
		return "expected reaction_count >= 1, got %s" % [metrics.get("reaction_count", 0)]
	if float(metrics.get("reaction_avg_ms", -1.0)) < 0.0:
		return "expected non-negative reaction_avg_ms, got %s" % [metrics.get("reaction_avg_ms", -1.0)]
	var backend_turns: Dictionary = metrics.get("backend_turns", {})
	var hybrid_stats: Dictionary = backend_turns.get("hybrid_csharp", {})
	if int(hybrid_stats.get("count", 0)) < 1:
		return "expected hybrid_csharp backend stats count >= 1, got %s" % [hybrid_stats]
	if float(hybrid_stats.get("avg_ms", -1.0)) < 0.0:
		return "expected non-negative hybrid avg_ms, got %s" % [hybrid_stats]
	var turn_snapshot: Dictionary = snapshot.get("latest_turn_snapshot", {})
	if int(turn_snapshot.get("elapsed_ms", -1)) < 0:
		return "expected latest turn snapshot elapsed_ms to be recorded"
	var reaction_snapshot: Dictionary = snapshot.get("latest_reaction_snapshot", {})
	if int(reaction_snapshot.get("elapsed_ms", -1)) < 0:
		return "expected latest reaction snapshot elapsed_ms to be recorded"
	return true


func _test_neijiang_ai_manager_request_api_updates_state_and_emits():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	var player := _make_player_neijiang(1, [
		_make_tile(1021, "tiao", 2), _make_tile(1022, "tiao", 2),
		_make_tile(1023, "tiao", 3), _make_tile(1024, "tiao", 3),
		_make_tile(1025, "tiao", 4), _make_tile(1026, "tiao", 5),
		_make_tile(1027, "tong", 3), _make_tile(1028, "tong", 3),
		_make_tile(1029, "tong", 4), _make_tile(1030, "tong", 5),
		_make_tile(1031, "tong", 6), _make_tile(1032, "tong", 7),
		_make_tile(1033, "tong", 8), _make_tile(1034, "tong", 8),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(1035, "tiao", 1)]
	var seat2 := _make_player_neijiang(2, [])
	var seat3 := _make_player_neijiang(3, [])
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 22
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var turn_signal_payloads: Array = []
	game_state.ai_manager.ai_turn_analysis_ready.connect(func(request_id: int, seat_index: int, analysis: Dictionary) -> void:
		turn_signal_payloads.append({
			"request_id": request_id,
			"seat_index": seat_index,
			"analysis": analysis.duplicate(true),
		})
	)
	var request_id: int = game_state.ai_manager.request_turn_analysis_async(
		game_state._build_player_state(1),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if request_id <= 0:
		return "expected positive request id"
	if turn_signal_payloads.is_empty():
		return "expected turn signal payloads to be recorded"
	var turn_signal_payload: Dictionary = turn_signal_payloads[0]
	if int(turn_signal_payload.get("request_id", -1)) != request_id:
		return "expected turn signal to emit matching request id, got %s" % [turn_signal_payload]
	if int(turn_signal_payload.get("seat_index", -1)) != 1:
		return "expected turn signal seat_index=1, got %s" % [turn_signal_payload]
	var emitted_analysis: Dictionary = turn_signal_payload.get("analysis", {})
	if emitted_analysis.is_empty():
		return "expected turn signal analysis payload"
	var snapshot: Dictionary = game_state.ai_manager.get_debug_snapshot()
	var request_state: Dictionary = snapshot.get("request_state", {})
	if int(request_state.get("inflight_count", -1)) != 0:
		return "expected no inflight requests after sync facade completion, got %s" % [request_state]
	if str(request_state.get("last_completed_kind", "")) != "turn":
		return "expected last_completed_kind=turn, got %s" % [request_state]
	var completed: Dictionary = request_state.get("last_completed_request", {})
	if int(completed.get("request_id", -1)) != request_id:
		return "expected completed request id to match, got %s" % [completed]
	var summary: Dictionary = completed.get("analysis_summary", {})
	if str(summary.get("backend_mode", "")) == "":
		return "expected completed request summary to include backend mode"
	return true


func _test_neijiang_ai_manager_background_request_pumps_and_emits():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	var player := _make_player_neijiang(2, [
		_make_tile(1041, "tiao", 2), _make_tile(1042, "tiao", 3),
		_make_tile(1043, "tiao", 4), _make_tile(1044, "tiao", 5),
		_make_tile(1045, "tiao", 6), _make_tile(1046, "tiao", 7),
		_make_tile(1047, "tong", 3), _make_tile(1048, "tong", 3),
		_make_tile(1049, "tong", 4), _make_tile(1050, "tong", 5),
		_make_tile(1051, "tong", 6), _make_tile(1052, "tong", 7),
		_make_tile(1053, "tong", 8), _make_tile(1054, "tong", 8),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(1055, "tiao", 1)]
	var seat1 := _make_player_neijiang(1, [])
	seat1["discards"] = [_make_tile(1056, "tong", 1)]
	var seat3 := _make_player_neijiang(3, [])
	_set_test_players(game_state, [seat0, seat1, player, seat3])
	game_state.wall_count = 20
	game_state.current_turn_seat = 2
	game_state.current_dealer_seat = 0
	var turn_signal_payloads: Array = []
	game_state.ai_manager.ai_turn_analysis_ready.connect(func(request_id: int, seat_index: int, analysis: Dictionary) -> void:
		turn_signal_payloads.append({
			"request_id": request_id,
			"seat_index": seat_index,
			"analysis": analysis.duplicate(true),
		})
	)
	var request_id: int = game_state.ai_manager.start_turn_analysis_background(
		game_state._build_player_state(2),
		game_state._build_table_state(),
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if request_id <= 0:
		return "expected positive background request id"
	var deadline := Time.get_ticks_msec() + 3000
	while turn_signal_payloads.is_empty() and Time.get_ticks_msec() < deadline:
		game_state.ai_manager.pump_async_requests()
		OS.delay_msec(10)
	if turn_signal_payloads.is_empty():
		return "expected background request to emit result before timeout"
	var turn_signal_payload: Dictionary = turn_signal_payloads[0]
	if int(turn_signal_payload.get("request_id", -1)) != request_id:
		return "expected background signal request id to match, got %s" % [turn_signal_payload]
	if int(turn_signal_payload.get("seat_index", -1)) != 2:
		return "expected background signal seat_index=2, got %s" % [turn_signal_payload]
	var snapshot: Dictionary = game_state.ai_manager.get_debug_snapshot()
	var request_state: Dictionary = snapshot.get("request_state", {})
	if bool(game_state.ai_manager.has_pending_async_requests()):
		return "expected no pending async requests after pump"
	if int(request_state.get("last_background_request_id", -1)) != request_id:
		return "expected last_background_request_id to match, got %s" % [request_state]
	if int(request_state.get("inflight_count", -1)) != 0:
		return "expected inflight_count=0 after background completion, got %s" % [request_state]
	return true


func _test_neijiang_turn_analysis_cache_hits_on_same_state():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	var player := _make_player_neijiang(1, [
		_make_tile(10501, "tiao", 2), _make_tile(10502, "tiao", 2),
		_make_tile(10503, "tiao", 3), _make_tile(10504, "tiao", 4),
		_make_tile(10505, "tiao", 5), _make_tile(10506, "tiao", 6),
		_make_tile(10507, "tong", 3), _make_tile(10508, "tong", 3),
		_make_tile(10509, "tong", 4), _make_tile(10510, "tong", 5),
		_make_tile(10511, "tong", 6), _make_tile(10512, "tong", 7),
		_make_tile(10513, "tong", 8), _make_tile(10514, "tong", 8),
	])
	var seat0 := _make_player_neijiang(0, [])
	seat0["discards"] = [_make_tile(10515, "tiao", 1)]
	var seat2 := _make_player_neijiang(2, [])
	var seat3 := _make_player_neijiang(3, [])
	_set_test_players(game_state, [seat0, player, seat2, seat3])
	game_state.wall_count = 20
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	var player_state: Dictionary = game_state._build_player_state(1)
	var table_state: Dictionary = game_state._build_table_state()
	var first: Dictionary = game_state.ai_manager.analyze_turn(
		player_state,
		table_state,
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	var second: Dictionary = game_state.ai_manager.analyze_turn(
		player_state,
		table_state,
		game_state.rules,
		game_state.ai_tuning_config,
		game_state.hu_checker,
		game_state.risk_analyzer,
		false
	)
	if first.is_empty() or second.is_empty():
		return "expected both cached analyses to return decisions"
	var snapshot: Dictionary = game_state.ai_manager.get_debug_snapshot()
	var cache_stats: Dictionary = snapshot.get("cache_stats", {})
	if int(cache_stats.get("turn_cache_hits", 0)) < 1:
		return "expected at least one cache hit, got %s" % [cache_stats]
	if int(cache_stats.get("turn_cache_size", 0)) < 1:
		return "expected cache to contain at least one entry, got %s" % [cache_stats]
	return true


func _test_neijiang_prepare_ai_turn_starts_background_request():
	var game_state = _build_neijiang_test_game_state()
	if not bool(game_state.set_ai_prefer_csharp_backend(true)):
		return "expected hybrid csharp backend to be available in regression env"
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(1061, "tiao", 1), _make_tile(1062, "tiao", 2),
			_make_tile(1063, "tiao", 4), _make_tile(1064, "tiao", 5),
			_make_tile(1065, "tiao", 7), _make_tile(1066, "tiao", 8),
			_make_tile(1067, "tong", 1), _make_tile(1068, "tong", 2),
			_make_tile(1069, "tong", 4), _make_tile(1070, "tong", 5),
			_make_tile(1071, "tong", 7), _make_tile(1072, "tong", 8),
			_make_tile(1073, "tiao", 9), _make_tile(1074, "tong", 9),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	var prepared: bool = bool(game_state.prepare_ai_turn_decision())
	if not prepared:
		return "expected prepare_ai_turn_decision to return true while background analysis starts"
	if int(game_state.pending_ai_turn_request_id) <= 0 and game_state.pending_ai_turn_decision.is_empty():
		return "expected pending turn request or ready decision to exist"
	return true


func _test_neijiang_run_ai_turn_executes_after_background_analysis():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(1081, "tiao", 1), _make_tile(1082, "tiao", 2),
			_make_tile(1083, "tiao", 4), _make_tile(1084, "tiao", 5),
			_make_tile(1085, "tiao", 7), _make_tile(1086, "tiao", 8),
			_make_tile(1087, "tong", 1), _make_tile(1088, "tong", 2),
			_make_tile(1089, "tong", 4), _make_tile(1090, "tong", 5),
			_make_tile(1091, "tong", 7), _make_tile(1092, "tong", 8),
			_make_tile(1093, "tiao", 9), _make_tile(1094, "tong", 9),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	if not bool(game_state.prepare_ai_turn_decision()):
		return "expected prepare_ai_turn_decision to start analysis"
	var executed := false
	var deadline := Time.get_ticks_msec() + 3000
	while not executed and Time.get_ticks_msec() < deadline:
		executed = bool(game_state.run_ai_turn())
		if not executed:
			OS.delay_msec(10)
	if not executed:
		return "expected run_ai_turn to execute after background analysis"
	if game_state.discard_pile.is_empty():
		return "expected ai turn to produce a discard"
	if int(game_state.current_turn_seat) == 1 and int(game_state.current_phase) == int(GAME_STATE_SCRIPT.RoundPhase.DISCARD):
		return "expected turn state to advance after ai discard"
	return true


func _test_neijiang_turn_background_timeout_keeps_waiting_main_chain():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.DISCARD
	game_state.current_turn_seat = 1
	game_state.current_dealer_seat = 0
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(1101, "tiao", 1), _make_tile(1102, "tiao", 2),
			_make_tile(1103, "tiao", 4), _make_tile(1104, "tiao", 5),
			_make_tile(1105, "tiao", 7), _make_tile(1106, "tiao", 8),
			_make_tile(1107, "tong", 1), _make_tile(1108, "tong", 2),
			_make_tile(1109, "tong", 4), _make_tile(1110, "tong", 5),
			_make_tile(1111, "tong", 7), _make_tile(1112, "tong", 8),
			_make_tile(1113, "tiao", 9), _make_tile(1114, "tong", 9),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.pending_ai_turn_request_id = 999
	game_state.pending_ai_turn_request_meta = {
		"round_index": game_state.round_index,
		"seat": 1,
		"phase": int(game_state.current_phase),
		"wall_count": game_state.wall_count,
		"hand_count": int(game_state.players[1].get("hand_count", 0)),
		"started_at_ms": Time.get_ticks_msec() - 1100,
	}
	var prepared: bool = bool(game_state.prepare_ai_turn_decision())
	if not prepared:
		return "expected timed-out turn request to keep waiting on main chain"
	if not game_state.pending_ai_turn_decision.is_empty():
		return "expected timed-out turn request to avoid lightweight fallback decision"
	if game_state.pending_ai_turn_request_id != 999:
		return "expected timed-out turn request id to remain active"
	if game_state.debug_last_message.find("超时") != -1:
		return "expected no timeout fallback debug message, got %s" % [game_state.debug_last_message]
	return true


func _test_neijiang_reaction_background_timeout_keeps_waiting_main_chain():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(1121, "tong", 3), _make_tile(1122, "tong", 3),
			_make_tile(1123, "tiao", 1), _make_tile(1124, "tiao", 2),
			_make_tile(1125, "tiao", 3),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.current_discard_context = {
		"source_seat": 0,
		"tile": _make_tile(1126, "tong", 3),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	var candidate := {
		"seat": 1,
		"can_hu": false,
		"can_gang": false,
		"can_peng": true,
		"tile": _make_tile(1127, "tong", 3),
	}
	game_state.pending_reactions.clear()
	game_state.pending_reactions.append(candidate)
	game_state.pending_ai_reaction_request_id = 1001
	game_state.pending_ai_reaction_request_meta = {
		"round_index": game_state.round_index,
		"phase": int(game_state.current_phase),
		"source_seat": 0,
		"tile_id": 1126,
		"pending_count": 1,
		"seat": 1,
		"candidate": candidate.duplicate(true),
		"started_at_ms": Time.get_ticks_msec() - 1100,
	}
	var prepared: bool = bool(game_state.prepare_ai_reaction_decision())
	if not prepared:
		return "expected timed-out reaction request to keep waiting on main chain"
	if not game_state.pending_ai_reaction_decision.is_empty():
		return "expected timed-out reaction request to avoid lightweight fallback decision"
	if game_state.pending_ai_reaction_request_id != 1001:
		return "expected timed-out reaction request id to remain active"
	if game_state.debug_last_message.find("超时") != -1:
		return "expected no reaction timeout fallback debug message, got %s" % [game_state.debug_last_message]
	return true


func _test_neijiang_slow_reaction_request_keeps_single_csharp_chain():
	var game_state = _build_neijiang_test_game_state()
	game_state.current_phase = GAME_STATE_SCRIPT.RoundPhase.REACTION
	game_state.current_turn_seat = 0
	game_state.current_dealer_seat = 0
	_set_test_players(game_state, [
		_make_player_neijiang(0, []),
		_make_player_neijiang(1, [
			_make_tile(1131, "tong", 3), _make_tile(1132, "tong", 3),
			_make_tile(1133, "tiao", 1), _make_tile(1134, "tiao", 2),
			_make_tile(1135, "tiao", 3),
		]),
		_make_player_neijiang(2, []),
		_make_player_neijiang(3, []),
	])
	game_state.current_discard_context = {
		"source_seat": 0,
		"tile": _make_tile(1136, "tong", 3),
		"reaction_type": "discard",
		"winner_seats": [],
	}
	var candidate := {
		"seat": 1,
		"can_hu": false,
		"can_gang": false,
		"can_peng": true,
		"tile": _make_tile(1137, "tong", 3),
	}
	game_state.pending_reactions.clear()
	game_state.pending_reactions.append(candidate)
	game_state.pending_ai_reaction_request_id = 1001
	game_state.pending_ai_reaction_request_meta = {
		"round_index": game_state.round_index,
		"phase": int(game_state.current_phase),
		"source_seat": 0,
		"tile_id": 1136,
		"pending_count": 1,
		"seat": 1,
		"candidate": candidate.duplicate(true),
		"started_at_ms": Time.get_ticks_msec() - 2600,
	}
	var prepared: bool = bool(game_state.prepare_ai_reaction_decision())
	if not prepared:
		return "expected slow reaction request to keep waiting on C# chain"
	if game_state.pending_ai_reaction_request_id != 1001:
		return "expected slow reaction request id to remain active"
	if not game_state.pending_ai_reaction_decision.is_empty():
		return "expected no GDScript fallback decision while waiting for C# chain"
	if game_state.debug_last_message.find("较慢") == -1:
		return "expected slow wait debug message, got %s" % [game_state.debug_last_message]
	return true


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
	game_state.ai_manager.ai_turn_analysis_ready.connect(game_state._on_ai_turn_analysis_ready)
	game_state.ai_manager.ai_reaction_analysis_ready.connect(game_state._on_ai_reaction_analysis_ready)
	game_state.ai_tuning_config = load("res://scripts/core/ai_tuning_config.gd").new()
	game_state.ai_tuning_config.apply_preset("bone_ash")
	game_state.ai_learning_engine = load("res://scripts/core/ai_learning_engine.gd").new()
	game_state.ai_learning_engine.profile = game_state.ai_learning_engine._default_profile()
	game_state.opening_roll_resolver = load("res://scripts/core/opening_roll_resolver.gd").new()
	game_state.ai_decision_metrics = game_state._create_empty_ai_decision_metrics()
	game_state.settlement_data = game_state._create_empty_settlement_data()
	game_state._rng = RandomNumberGenerator.new()
	game_state._rng.randomize()
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


func _make_tile(id: int, suit: String, rank: int) -> Dictionary:
	var suit_index: int = {
		"tiao": 0,
		"tong": 1,
		"wan": 2,
	}.get(suit, 9)
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
			return "?"
