extends RefCounted

# Network display data is built from an allowlist. Debug snapshots contain
# private hands, AI diagnostics and exact wall state and must not be sent raw.

const MAPPER := preload("res://scripts/network/neijiang_seat_view_mapper.gd")
const PUBLIC_KEYS := [
	"round_index", "current_phase", "wall_count", "discard_count", "winner_count",
	"recent_discard_display", "recent_discard_tile_id", "opening_roll", "opening_roll_pending", "opening_bao_jiao_pending", "rules",
]
const PLAYER_PUBLIC_KEYS := [
	"seat", "nickname", "score", "is_ai", "hand_count", "melds", "discards",
	"has_won", "bao_jiao", "bao_gang_tiles", "rule_marks", "ding_que",
	"winning_tile", "winning_source_seat", "winning_type",
]
const PRIVATE_KEYS := [
	"human_can_discard", "human_can_self_hu", "human_can_add_gang", "human_can_an_gang",
	"human_can_bao_jiao", "human_can_pass_opening_bao_jiao", "human_bao_jiao_plan",
	"human_last_draw_tile_id", "human_reaction_options", "trainer_hint",
]


func project(snapshot: Dictionary, receiver_seat: int, private_actions: Dictionary = {}) -> Dictionary:
	if receiver_seat < 0 or receiver_seat >= 4:
		return {}
	var result := {"schema_version": 1, "local_seat_id": 0}
	for key in PUBLIC_KEYS:
		if snapshot.has(key):
			result[key] = _copy(snapshot[key])
	for key in PRIVATE_KEYS:
		if private_actions.has(key):
			result[key] = _copy(private_actions[key])
	result["current_dealer_seat"] = MAPPER.authority_to_view(int(snapshot.get("current_dealer_seat", -1)), receiver_seat)
	result["current_turn_seat"] = MAPPER.authority_to_view(int(snapshot.get("current_turn_seat", -1)), receiver_seat)
	result["round_winners"] = MAPPER.map_seat_list(snapshot.get("round_winners", []), receiver_seat)
	result["opening_bao_jiao_current_seat"] = MAPPER.authority_to_view(int(snapshot.get("opening_bao_jiao_current_seat", -1)), receiver_seat)
	var draw_seat := int(snapshot.get("recent_draw_seat", -1))
	result["recent_draw_seat"] = MAPPER.authority_to_view(draw_seat, receiver_seat)
	result["recent_draw_display"] = str(snapshot.get("recent_draw_display", "")) if draw_seat == receiver_seat else ""
	var context: Dictionary = snapshot.get("discard_context", {})
	var public_context := {}
	for key in ["reaction_type", "tile", "source_seat"]:
		if context.has(key):
			public_context[key] = _copy(context[key])
	if public_context.has("source_seat"):
		public_context["source_seat"] = MAPPER.authority_to_view(int(public_context["source_seat"]), receiver_seat)
	result["discard_context"] = public_context
	var reveal_hands := int(snapshot.get("current_phase", -1)) == 7
	var projected_players: Array = []
	for player_value in snapshot.get("players", []):
		var player: Dictionary = player_value
		var authority_seat := int(player.get("seat", -1))
		if authority_seat < 0 or authority_seat >= 4:
			continue
		var visible := {}
		for key in PLAYER_PUBLIC_KEYS:
			if player.has(key):
				visible[key] = _copy(player[key])
		if authority_seat == receiver_seat or reveal_hands:
			visible["hand_tiles"] = _copy(player.get("hand_tiles", []))
		visible["hand_count"] = int(player.get("hand_count", Array(player.get("hand_tiles", [])).size()))
		projected_players.append(MAPPER.map_player_for_view(visible, receiver_seat))
	projected_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("seat", -1)) < int(b.get("seat", -1)))
	result["players"] = projected_players
	if reveal_hands and snapshot.has("settlement_data"):
		result["settlement_data"] = MAPPER.map_settlement_for_view(snapshot["settlement_data"], receiver_seat)
	else:
		result["settlement_data"] = {}
	return _network_safe(result)


func _copy(value: Variant) -> Variant:
	return value.duplicate(true) if value is Dictionary or value is Array else value


func _network_safe(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value:
			result[str(key)] = _network_safe(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_network_safe(item))
		return result
	return value
