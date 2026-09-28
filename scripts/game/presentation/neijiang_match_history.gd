extends RefCounted

const MAPPER := preload("res://scripts/network/neijiang_seat_view_mapper.gd")

# A display-only copy of completed, authoritative Neijiang round results.
# Repeated settlement snapshots must never count as extra rounds.

var rounds: Array[Dictionary] = []


func clear() -> void:
	rounds.clear()


func import_authority_records(records: Array, local_seat: int) -> void:
	if local_seat < 0 or local_seat >= 4:
		return
	rounds.clear()
	for value in records:
		if not value is Dictionary:
			continue
		var record: Dictionary = MAPPER.map_settlement_for_view(value, local_seat)
		var names := {}
		for authority_key in Dictionary(value.get("player_names", {})):
			var seat := MAPPER.authority_to_view(int(str(authority_key)), local_seat)
			if seat >= 0:
				names[seat] = str(value["player_names"][authority_key])
		record["player_names"] = names
		rounds.append(record)
	rounds.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("round_index", 0)) < int(b.get("round_index", 0)))


func remember(snapshot: Dictionary) -> bool:
	if int(snapshot.get("current_phase", -1)) != 7:
		return false
	var settlement: Dictionary = snapshot.get("settlement_data", {})
	if settlement.is_empty() or not bool(settlement.get("scores_applied", false)):
		return false
	var round_number := int(snapshot.get("round_index", settlement.get("round_index", 0)))
	if round_number <= 0:
		return false
	for record in rounds:
		if int(record.get("round_index", -1)) == round_number:
			return false
	var names := {}
	var scores := {}
	for player in snapshot.get("players", []):
		var seat := int(player.get("seat", -1))
		if seat < 0:
			continue
		names[seat] = str(player.get("nickname", player.get("name", "玩家%d" % (seat + 1))))
		scores[seat] = int(player.get("score", 0))
	var record := settlement.duplicate(true)
	record["round_index"] = round_number
	record["player_names"] = names
	record["scores_after_round"] = scores
	rounds.append(record)
	rounds.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("round_index", 0)) < int(b.get("round_index", 0)))
	return true


func seat_name(seat: int) -> String:
	for record in rounds:
		var names: Dictionary = record.get("player_names", {})
		if names.has(seat) or names.has(str(seat)):
			return str(names.get(seat, names.get(str(seat), "")))
	return ["本家", "上家", "对家", "下家"][seat] if seat >= 0 and seat < 4 else "玩家%d" % (seat + 1)


func score_delta(record: Dictionary, seat: int) -> int:
	var changes: Dictionary = record.get("score_changes", {})
	return int(changes.get(seat, changes.get(str(seat), 0)))


func rankings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for seat in range(4):
		var row := {"seat": seat, "name": seat_name(seat), "score": 0, "wins": 0, "discards": 0, "gangs": 0}
		for record in rounds:
			row["score"] = int(row["score"]) + score_delta(record, seat)
			for event in record.get("win_events", []):
				if int(event.get("winner_seat", -1)) == seat:
					row["wins"] = int(row["wins"]) + 1
				if int(event.get("source_seat", -1)) == seat and int(event.get("winner_seat", -1)) != seat:
					row["discards"] = int(row["discards"]) + 1
			for event in record.get("gang_events", []):
				if int(event.get("actor_seat", -1)) == seat and str(event.get("related_outcome", "")) != "gang_discard_win":
					row["gangs"] = int(row["gangs"]) + 1
		result.append(row)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["score"]) > int(b["score"]) if int(a["score"]) != int(b["score"]) else int(a["seat"]) < int(b["seat"]))
	return result


func ledger_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var totals := {0: 0, 1: 0, 2: 0, 3: 0}
	for record in rounds:
		for seat in range(4):
			var delta := score_delta(record, seat)
			totals[seat] = int(totals[seat]) + delta
			var names: Dictionary = record.get("player_names", {})
			result.append({
				"round_index": int(record.get("round_index", 0)),
				"seat": seat,
				"name": str(names.get(seat, names.get(str(seat), seat_name(seat)))),
				"delta": delta,
				"cumulative": int(totals[seat]),
			})
	return result
