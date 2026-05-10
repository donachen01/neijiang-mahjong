extends SceneTree

const GAME_STATE_SCRIPT := preload("res://autoload/GameState.gd")

const DEFAULT_TOTAL_ROUNDS := 40
const DEFAULT_MAX_STEPS_PER_ROUND := 5000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var total_rounds := _read_int_arg("--rounds=", DEFAULT_TOTAL_ROUNDS)
	var max_steps_per_round := _read_int_arg("--max-steps=", DEFAULT_MAX_STEPS_PER_ROUND)
	var preset_name := _read_string_arg("--preset=", "bone_ash")
	var compare_preset_name := _read_string_arg("--compare-preset=", "")
	var output_path := _read_string_arg("--output=", _build_default_report_path(total_rounds, preset_name, compare_preset_name, "json"))
	var csv_output_path := _read_string_arg("--csv-output=", _build_default_report_path(total_rounds, preset_name, compare_preset_name, "csv"))
	var game_state: Node = GAME_STATE_SCRIPT.new()
	get_root().add_child(game_state)
	await process_frame

	var report: Dictionary
	if compare_preset_name != "":
		report = await _run_ab_benchmark(game_state, preset_name, compare_preset_name, total_rounds, max_steps_per_round)
	else:
		report = await _run_single_preset_benchmark(game_state, preset_name, total_rounds, max_steps_per_round)
	_print_summary(report)
	_write_report(report, output_path)
	_write_csv_report(report, csv_output_path)
	quit()


func _run_single_preset_benchmark(game_state: Node, preset_name: String, total_rounds: int, max_steps_per_round: int) -> Dictionary:
	game_state.call("set_ai_preset", preset_name)
	var stats := _create_stats()
	stats["benchmark_mode"] = "single"
	stats["preset_name"] = preset_name
	var round_counter := 0
	while round_counter < total_rounds:
		print("benchmark_round_start=", round_counter + 1, " preset=", preset_name)
		_prepare_all_ai_table(game_state)
		var result := await _play_single_round(game_state, round_counter + 1, max_steps_per_round)
		_accumulate_round_stats(stats, result)
		print("benchmark_round_end=", round_counter + 1, " steps=", int(result.get("steps", 0)), " end_reason=", str(result.get("end_reason", "")), " forced=", bool(result.get("forced_stop", false)))
		round_counter += 1
		if not game_state.call("advance_to_next_round"):
			push_error("Failed to advance after round %d" % round_counter)
			break
		await process_frame
	_finalize_stats(stats, game_state)
	return stats


func _run_ab_benchmark(game_state: Node, preset_a: String, preset_b: String, total_rounds: int, max_steps_per_round: int) -> Dictionary:
	var combined := {
		"benchmark_mode": "ab_compare",
		"preset_a": preset_a,
		"preset_b": preset_b,
	}
	var stats_a := await _run_single_preset_benchmark(game_state, preset_a, total_rounds, max_steps_per_round)
	game_state.call("start_new_round")
	await process_frame
	var stats_b := await _run_single_preset_benchmark(game_state, preset_b, total_rounds, max_steps_per_round)
	combined["report_a"] = stats_a
	combined["report_b"] = stats_b
	combined["comparison"] = _build_comparison(stats_a, stats_b)
	return combined


func _play_single_round(game_state: Node, round_no: int, max_steps_per_round: int) -> Dictionary:
	var step := 0
	while step < max_steps_per_round:
		_prepare_all_ai_table(game_state)
		var phase := int(game_state.get("current_phase"))
		match phase:
			2:
				if bool(game_state.get("opening_roll_pending_completion")):
					game_state.call("complete_opening_roll")
			3:
				game_state.call("_auto_select_ai_ding_que")
				game_state.call("_complete_ding_que_if_ready")
			5:
				if bool(game_state.call("is_ai_turn_ready")):
					game_state.call("run_ai_turn")
			6:
				if bool(game_state.call("is_ai_reaction_pending")):
					game_state.call("run_ai_reaction")
				else:
					game_state.call("_finalize_reaction_without_claim")
			7:
				return _extract_round_result(game_state, round_no, step)
			_:
				pass
		step += 1
		await process_frame

	push_error("Round %d exceeded max steps %d" % [round_no, max_steps_per_round])
	return _extract_round_result(game_state, round_no, step, true)


func _prepare_all_ai_table(game_state: Node) -> void:
	var players: Array = game_state.get("players")
	if players.is_empty():
		return
	var ai_level := int(game_state.get("ai_level"))
	for index in range(players.size()):
		var player: Dictionary = players[index]
		player["is_ai"] = true
		player["ai_level"] = ai_level
		players[index] = player
	game_state.set("players", players)


func _extract_round_result(game_state: Node, round_no: int, steps: int, forced_stop: bool = false) -> Dictionary:
	var settlement_data: Dictionary = game_state.get("settlement_data").duplicate(true)
	var players: Array = game_state.get("players").duplicate(true)
	var score_changes: Dictionary = settlement_data.get("score_changes", {})
	var win_events: Array = settlement_data.get("win_events", [])
	var gang_events: Array = settlement_data.get("gang_events", [])
	var round_winners: Array = game_state.get("round_winners")
	return {
		"round_no": round_no,
		"steps": steps,
		"forced_stop": forced_stop,
		"end_reason": str(settlement_data.get("end_reason", "")),
		"winner_seats": round_winners.duplicate(),
		"score_changes": score_changes.duplicate(true),
		"win_events": win_events.duplicate(true),
		"gang_events": gang_events.duplicate(true),
		"players": players,
		"ai_decision_metrics": game_state.get("ai_decision_metrics").duplicate(true),
	}


func _create_stats() -> Dictionary:
	var seats := {}
	for seat in range(4):
		seats[seat] = {
			"wins": 0,
			"self_draw_wins": 0,
			"discard_wins": 0,
			"qiang_gang_hu_wins": 0,
			"gang_count": 0,
			"an_gang_count": 0,
			"add_gang_count": 0,
			"melded_gang_count": 0,
			"total_delta": 0,
			"positive_rounds": 0,
			"negative_rounds": 0,
			"zero_rounds": 0,
			"max_single_round_gain": 0,
			"max_single_round_loss": 0,
			"deal_in_count": 0,
			"deal_in_loss_total": 0,
			"dealt_win_count": 0,
			"self_draw_loss_rounds": 0,
		}
	return {
		"total_rounds": 0,
		"forced_stop_rounds": 0,
		"draw_rounds": 0,
		"battle_end_rounds": 0,
		"total_steps": 0,
		"seat_stats": seats,
		"ai_metrics_total": {},
		"round_summaries": [],
		"generated_at_unix": Time.get_unix_time_from_system(),
	}


func _accumulate_round_stats(stats: Dictionary, result: Dictionary) -> void:
	stats["total_rounds"] = int(stats.get("total_rounds", 0)) + 1
	stats["total_steps"] = int(stats.get("total_steps", 0)) + int(result.get("steps", 0))
	if bool(result.get("forced_stop", false)):
		stats["forced_stop_rounds"] = int(stats.get("forced_stop_rounds", 0)) + 1
	var end_reason := str(result.get("end_reason", ""))
	if end_reason.begins_with("draw"):
		stats["draw_rounds"] = int(stats.get("draw_rounds", 0)) + 1
	else:
		stats["battle_end_rounds"] = int(stats.get("battle_end_rounds", 0)) + 1

	var seat_stats: Dictionary = stats.get("seat_stats", {})
	var score_changes: Dictionary = result.get("score_changes", {})
	for seat_key in seat_stats.keys():
		var seat := int(seat_key)
		var item: Dictionary = seat_stats[seat]
		var delta := int(score_changes.get(seat, 0))
		item["total_delta"] = int(item.get("total_delta", 0)) + delta
		if delta > 0:
			item["positive_rounds"] = int(item.get("positive_rounds", 0)) + 1
		elif delta < 0:
			item["negative_rounds"] = int(item.get("negative_rounds", 0)) + 1
		else:
			item["zero_rounds"] = int(item.get("zero_rounds", 0)) + 1
		item["max_single_round_gain"] = maxi(int(item.get("max_single_round_gain", 0)), delta)
		item["max_single_round_loss"] = mini(int(item.get("max_single_round_loss", 0)), delta)
		seat_stats[seat] = item

	for event in result.get("win_events", []):
		var winner := int(event.get("winner_seat", -1))
		if not seat_stats.has(winner):
			continue
		var item: Dictionary = seat_stats[winner]
		item["wins"] = int(item.get("wins", 0)) + 1
		var win_type := str(event.get("win_type", ""))
		match win_type:
			"self_draw", "gang_self_draw":
				item["self_draw_wins"] = int(item.get("self_draw_wins", 0)) + 1
			"qiang_gang_hu":
				item["qiang_gang_hu_wins"] = int(item.get("qiang_gang_hu_wins", 0)) + 1
			_:
				item["discard_wins"] = int(item.get("discard_wins", 0)) + 1
				item["dealt_win_count"] = int(item.get("dealt_win_count", 0)) + 1
		seat_stats[winner] = item

		var source_seat := int(event.get("source_seat", -1))
		if source_seat >= 0 and seat_stats.has(source_seat):
			var source_item: Dictionary = seat_stats[source_seat]
			match win_type:
				"discard_win", "gang_discard_win", "qiang_gang_hu":
					source_item["deal_in_count"] = int(source_item.get("deal_in_count", 0)) + 1
					source_item["deal_in_loss_total"] = int(source_item.get("deal_in_loss_total", 0)) + int(score_changes.get(source_seat, 0))
				"self_draw", "gang_self_draw":
					source_item["self_draw_loss_rounds"] = int(source_item.get("self_draw_loss_rounds", 0)) + 1 if source_seat != winner else int(source_item.get("self_draw_loss_rounds", 0))
			seat_stats[source_seat] = source_item

	for event in result.get("gang_events", []):
		var actor := int(event.get("actor_seat", -1))
		if not seat_stats.has(actor):
			continue
		var item: Dictionary = seat_stats[actor]
		item["gang_count"] = int(item.get("gang_count", 0)) + 1
		var gang_type := str(event.get("gang_type", ""))
		match gang_type:
			"an_gang":
				item["an_gang_count"] = int(item.get("an_gang_count", 0)) + 1
			"melded_gang":
				item["melded_gang_count"] = int(item.get("melded_gang_count", 0)) + 1
			"add_gang":
				item["add_gang_count"] = int(item.get("add_gang_count", 0)) + 1
		seat_stats[actor] = item

	stats["seat_stats"] = seat_stats
	_accumulate_ai_metrics(stats, result.get("ai_decision_metrics", {}))
	stats["round_summaries"].append(
		{
			"round_no": int(result.get("round_no", 0)),
			"steps": int(result.get("steps", 0)),
			"end_reason": end_reason,
			"winner_seats": result.get("winner_seats", []).duplicate(),
			"score_changes": score_changes.duplicate(true),
			"ai_decision_metrics": result.get("ai_decision_metrics", {}).duplicate(true),
		}
	)


func _finalize_stats(stats: Dictionary, game_state: Node) -> void:
	var players: Array = game_state.get("players")
	for player in players:
		var seat := int(player.get("seat", -1))
		var seat_stats: Dictionary = stats.get("seat_stats", {})
		if seat_stats.has(seat):
			var item: Dictionary = seat_stats[seat]
			item["final_score"] = int(player.get("score", 0))
			item["avg_delta_per_round"] = 0.0 if int(stats.get("total_rounds", 0)) <= 0 else float(item.get("total_delta", 0)) / float(stats.get("total_rounds", 0))
			item["win_rate"] = 0.0 if int(stats.get("total_rounds", 0)) <= 0 else float(item.get("wins", 0)) / float(stats.get("total_rounds", 0))
			item["deal_in_rate"] = 0.0 if int(stats.get("total_rounds", 0)) <= 0 else float(item.get("deal_in_count", 0)) / float(stats.get("total_rounds", 0))
			seat_stats[seat] = item
			stats["seat_stats"] = seat_stats
	stats["avg_steps_per_round"] = 0.0 if int(stats.get("total_rounds", 0)) <= 0 else float(stats.get("total_steps", 0)) / float(stats.get("total_rounds", 0))
	stats["report_version"] = 1


func _print_summary(stats: Dictionary) -> void:
	if str(stats.get("benchmark_mode", "")) == "ab_compare":
		print("=== AI PRESSURE BENCHMARK A/B ===")
		print("preset_a=", stats.get("preset_a", ""))
		print("preset_b=", stats.get("preset_b", ""))
		var comparison: Dictionary = stats.get("comparison", {})
		for key in comparison.keys():
			print("%s=%s" % [str(key), str(comparison.get(key))])
		return
	print("=== AI PRESSURE BENCHMARK ===")
	print("total_rounds=", stats.get("total_rounds", 0))
	print("forced_stop_rounds=", stats.get("forced_stop_rounds", 0))
	print("draw_rounds=", stats.get("draw_rounds", 0))
	print("battle_end_rounds=", stats.get("battle_end_rounds", 0))
	print("avg_steps_per_round=", "%.2f" % float(stats.get("avg_steps_per_round", 0.0)))
	var seat_stats: Dictionary = stats.get("seat_stats", {})
	for seat_key in seat_stats.keys():
		var seat := int(seat_key)
		var item: Dictionary = seat_stats[seat]
		print("--- seat %d ---" % seat)
		print("wins=%d self_draw=%d discard=%d qiang_gang_hu=%d" % [
			int(item.get("wins", 0)),
			int(item.get("self_draw_wins", 0)),
			int(item.get("discard_wins", 0)),
			int(item.get("qiang_gang_hu_wins", 0)),
		])
		print("gang_total=%d an_gang=%d add_gang=%d melded_gang=%d" % [
			int(item.get("gang_count", 0)),
			int(item.get("an_gang_count", 0)),
			int(item.get("add_gang_count", 0)),
			int(item.get("melded_gang_count", 0)),
		])
		print("delta_total=%d positive_rounds=%d negative_rounds=%d final_score=%d" % [
			int(item.get("total_delta", 0)),
			int(item.get("positive_rounds", 0)),
			int(item.get("negative_rounds", 0)),
			int(item.get("final_score", 0)),
		])
		print("win_rate=%.3f avg_delta=%.3f max_gain=%d max_loss=%d" % [
			float(item.get("win_rate", 0.0)),
			float(item.get("avg_delta_per_round", 0.0)),
			int(item.get("max_single_round_gain", 0)),
			int(item.get("max_single_round_loss", 0)),
		])
		print("deal_in_rate=%.3f deal_in_count=%d deal_in_loss_total=%d" % [
			float(item.get("deal_in_rate", 0.0)),
			int(item.get("deal_in_count", 0)),
			int(item.get("deal_in_loss_total", 0)),
		])
	print("--- ai_metrics_total ---")
	for key in stats.get("ai_metrics_total", {}).keys():
		print("%s=%d" % [str(key), int(stats["ai_metrics_total"].get(key, 0))])


func _write_report(stats: Dictionary, output_path: String) -> void:
	var serialized := JSON.stringify(stats, "\t", false)
	var resolved_path := ProjectSettings.globalize_path(output_path)
	var dir_path := resolved_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(resolved_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open benchmark report path: %s" % resolved_path)
		return
	file.store_string(serialized)
	file.flush()
	file.close()
	print("benchmark_report_path=", resolved_path)


func _write_csv_report(stats: Dictionary, output_path: String) -> void:
	if str(stats.get("benchmark_mode", "")) == "ab_compare":
		_write_ab_csv_report(stats, output_path)
		return
	var resolved_path := ProjectSettings.globalize_path(output_path)
	var dir_path := resolved_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(resolved_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open benchmark csv path: %s" % resolved_path)
		return
	var lines: Array[String] = []
	lines.append("seat,wins,self_draw_wins,discard_wins,qiang_gang_hu_wins,gang_count,an_gang_count,add_gang_count,melded_gang_count,total_delta,avg_delta_per_round,win_rate,deal_in_count,deal_in_rate,deal_in_loss_total,positive_rounds,negative_rounds,zero_rounds,max_single_round_gain,max_single_round_loss,final_score")
	var seat_stats: Dictionary = stats.get("seat_stats", {})
	var sorted_seats := seat_stats.keys()
	sorted_seats.sort()
	for seat_key in sorted_seats:
		var seat := int(seat_key)
		var item: Dictionary = seat_stats[seat]
		lines.append(",".join([
			str(seat),
			str(int(item.get("wins", 0))),
			str(int(item.get("self_draw_wins", 0))),
			str(int(item.get("discard_wins", 0))),
			str(int(item.get("qiang_gang_hu_wins", 0))),
			str(int(item.get("gang_count", 0))),
			str(int(item.get("an_gang_count", 0))),
			str(int(item.get("add_gang_count", 0))),
			str(int(item.get("melded_gang_count", 0))),
			str(int(item.get("total_delta", 0))),
			str(float(item.get("avg_delta_per_round", 0.0))),
			str(float(item.get("win_rate", 0.0))),
			str(int(item.get("deal_in_count", 0))),
			str(float(item.get("deal_in_rate", 0.0))),
			str(int(item.get("deal_in_loss_total", 0))),
			str(int(item.get("positive_rounds", 0))),
			str(int(item.get("negative_rounds", 0))),
			str(int(item.get("zero_rounds", 0))),
			str(int(item.get("max_single_round_gain", 0))),
			str(int(item.get("max_single_round_loss", 0))),
			str(int(item.get("final_score", 0))),
		]))
	file.store_string("\n".join(lines))
	file.flush()
	file.close()
	print("benchmark_csv_report_path=", resolved_path)


func _write_ab_csv_report(stats: Dictionary, output_path: String) -> void:
	var resolved_path := ProjectSettings.globalize_path(output_path)
	var dir_path := resolved_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(resolved_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open benchmark csv path: %s" % resolved_path)
		return
	var comparison: Dictionary = stats.get("comparison", {})
	var lines: Array[String] = []
	lines.append("metric,preset_a,preset_b")
	for key in comparison.keys():
		var value: Dictionary = comparison.get(key, {})
		lines.append("%s,%s,%s" % [str(key), str(value.get("a", "")), str(value.get("b", ""))])
	file.store_string("\n".join(lines))
	file.flush()
	file.close()
	print("benchmark_csv_report_path=", resolved_path)


func _accumulate_ai_metrics(stats: Dictionary, metrics: Dictionary) -> void:
	var totals: Dictionary = stats.get("ai_metrics_total", {})
	for key in metrics.keys():
		totals[key] = int(totals.get(key, 0)) + int(metrics.get(key, 0))
	stats["ai_metrics_total"] = totals


func _build_comparison(stats_a: Dictionary, stats_b: Dictionary) -> Dictionary:
	return {
		"avg_steps_per_round": {
			"a": stats_a.get("avg_steps_per_round", 0.0),
			"b": stats_b.get("avg_steps_per_round", 0.0),
		},
		"draw_rounds": {
			"a": stats_a.get("draw_rounds", 0),
			"b": stats_b.get("draw_rounds", 0),
		},
		"battle_end_rounds": {
			"a": stats_a.get("battle_end_rounds", 0),
			"b": stats_b.get("battle_end_rounds", 0),
		},
		"reaction_hu": {
			"a": int(stats_a.get("ai_metrics_total", {}).get("reaction_hu", 0)),
			"b": int(stats_b.get("ai_metrics_total", {}).get("reaction_hu", 0)),
		},
		"reaction_peng": {
			"a": int(stats_a.get("ai_metrics_total", {}).get("reaction_peng", 0)),
			"b": int(stats_b.get("ai_metrics_total", {}).get("reaction_peng", 0)),
		},
		"reaction_gang": {
			"a": int(stats_a.get("ai_metrics_total", {}).get("reaction_gang", 0)),
			"b": int(stats_b.get("ai_metrics_total", {}).get("reaction_gang", 0)),
		},
		"strategy_full_attack": {
			"a": int(stats_a.get("ai_metrics_total", {}).get("discard_strategy_全攻", 0)),
			"b": int(stats_b.get("ai_metrics_total", {}).get("discard_strategy_全攻", 0)),
		},
		"strategy_full_defense": {
			"a": int(stats_a.get("ai_metrics_total", {}).get("discard_strategy_全守", 0)),
			"b": int(stats_b.get("ai_metrics_total", {}).get("discard_strategy_全守", 0)),
		},
	}


func _read_int_arg(prefix: String, fallback: int) -> int:
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with(prefix):
			return maxi(1, int(String(arg).trim_prefix(prefix)))
	return fallback


func _read_string_arg(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		var arg_text := String(arg)
		if arg_text.begins_with(prefix):
			return arg_text.trim_prefix(prefix)
	return fallback


func _build_default_report_path(total_rounds: int, preset_name: String, compare_preset_name: String, extension: String) -> String:
	var timestamp := _build_timestamp_slug()
	var mode_slug := "single_%s" % preset_name if compare_preset_name == "" else "ab_%s_vs_%s" % [preset_name, compare_preset_name]
	var file_name := "ai压测_%s_%d局_%s.%s" % [timestamp, total_rounds, mode_slug, extension]
	return "res://测试数据统计/%s" % file_name


func _build_timestamp_slug() -> String:
	var now := Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d" % [
		int(now.get("year", 0)),
		int(now.get("month", 0)),
		int(now.get("day", 0)),
		int(now.get("hour", 0)),
		int(now.get("minute", 0)),
		int(now.get("second", 0)),
	]
