extends SceneTree

const HISTORY_SCRIPT := preload("res://scripts/game/presentation/neijiang_match_history.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var history = HISTORY_SCRIPT.new()
	var first := _snapshot(1, {0: 6, 1: -2, 2: -2, 3: -2}, "本家甲")
	if not history.remember(first) or history.remember(first):
		_fail("同一局结算快照重复入账")
		return
	if history.remember(_snapshot(2, {0: 2, 1: -1, 2: -1, 3: 0}, "本家甲", false)):
		_fail("尚未应用积分的快照提前入账")
		return
	if not history.remember(_snapshot(2, {0: -3, 1: 3, 2: 0, 3: 0}, "本家甲")):
		_fail("第二局有效结算没有入账")
		return
	var ranks: Array[Dictionary] = history.rankings()
	if ranks.size() != 4 or int(ranks[0]["seat"]) != 0 or int(ranks[0]["score"]) != 3:
		_fail("排行没有累计权威积分")
		return
	var rows: Array[Dictionary] = history.ledger_rows()
	if rows.size() != 8 or int(rows[4]["delta"]) != -3 or int(rows[4]["cumulative"]) != 3 or str(rows[4]["name"]) != "本家甲":
		_fail("逐局流水没有保留姓名、本局和累计积分")
		return
	print("NEIJIANG MATCH HISTORY OK")
	quit(0)


func _snapshot(round_number: int, changes: Dictionary, first_name: String, scores_applied := true) -> Dictionary:
	return {
		"current_phase": 7,
		"round_index": round_number,
		"players": [
			{"seat": 0, "nickname": first_name, "score": changes[0]},
			{"seat": 1, "nickname": "上家", "score": changes[1]},
			{"seat": 2, "nickname": "对家", "score": changes[2]},
			{"seat": 3, "nickname": "下家", "score": changes[3]},
		],
		"settlement_data": {
			"scores_applied": scores_applied,
			"score_changes": changes,
			"win_events": [{"winner_seat": 0, "source_seat": 1}],
			"gang_events": [],
		},
	}


func _fail(message: String) -> void:
	push_error("NEIJIANG MATCH HISTORY FAILED: " + message)
	quit(1)
