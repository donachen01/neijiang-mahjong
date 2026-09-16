extends SceneTree

const ScoreResolverScript := preload("res://scripts/core/score_resolver.gd")
const RuleConfigScript := preload("res://scripts/core/rule_config.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_test_special_win_fans(failures)
	_test_qiang_gang_flow_creates_transfer_event(failures)
	_test_gang_discard_transfer_requires_ting(failures)
	_test_qiang_gang_transfer_requires_ting(failures)
	if failures.is_empty():
		print("NEIJIANG GANG SETTLEMENT REGRESSION OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_special_win_fans(failures: Array[String]) -> void:
	var resolver = ScoreResolverScript.new()
	var rules = RuleConfigScript.new(RuleConfigScript.MODE_NEIJIANG_CLASSIC)
	var player := _winning_player_stub(1)
	var tile := _tile("tiao", 5, 99)
	var ordinary: Dictionary = resolver.build_event_fan_detail(player, tile, "discard_win", rules)
	var gang_pao: Dictionary = resolver.build_event_fan_detail(player, tile, "gang_discard_win", rules)
	var qiang: Dictionary = resolver.build_event_fan_detail(player, tile, "qiang_gang_hu", rules)
	_expect(int(gang_pao.get("uncapped_fan", 0)) == int(ordinary.get("uncapped_fan", 0)) + 1, "杠上炮应额外加1番", failures)
	_expect(int(qiang.get("uncapped_fan", 0)) == int(ordinary.get("uncapped_fan", 0)) + 1, "抢杠胡应额外加1番", failures)


func _test_qiang_gang_flow_creates_transfer_event(failures: Array[String]) -> void:
	var game_state = get_root().get_node_or_null("GameState")
	if game_state == null:
		failures.append("GameState自动加载不可用")
		return
	var saved_players: Array[Dictionary] = []
	for player in game_state.players:
		saved_players.append(Dictionary(player).duplicate(true))
	var saved_settlement: Dictionary = game_state.settlement_data.duplicate(true)
	var saved_pending: Dictionary = game_state.pending_qiang_gang_context.duplicate(true)
	var test_players: Array[Dictionary] = [_player_stub(0), _player_stub(1), _player_stub(2), _player_stub(3)]
	game_state.players = test_players
	game_state.settlement_data = {"transfer_events": []}
	game_state.pending_qiang_gang_context = {"tile": _tile("tiao", 5, 99)}
	game_state.call("_append_qiang_gang_zhuan_yi_event", 0, [1])
	var events: Array = game_state.settlement_data.get("transfer_events", [])
	var valid := events.size() == 1 \
		and str(events[0].get("gang_type", "")) == "add_gang" \
		and str(events[0].get("related_outcome", "")) == "qiang_gang_hu" \
		and Array(events[0].get("payer_seats", [])).size() == 2
	_expect(valid, "抢杠胡流程应生成补杠转雨事件且不向胡家自身扣款", failures)
	game_state.players = saved_players
	game_state.settlement_data = saved_settlement
	game_state.pending_qiang_gang_context = saved_pending


func _test_gang_discard_transfer_requires_ting(failures: Array[String]) -> void:
	var ting_changes := _resolve_transfer_case("gang_discard_win", true)
	var no_ting_changes := _resolve_transfer_case("gang_discard_win", false)
	_expect(int(ting_changes[1]) == 4 and int(ting_changes[0]) == -2 and int(ting_changes[2]) == -1 and int(ting_changes[3]) == -1, "杠上炮有叫时应把2份补杠雨钱转给胡家", failures)
	_expect(int(no_ting_changes[1]) == 2 and int(no_ting_changes[0]) == -2 and int(no_ting_changes[2]) == 0 and int(no_ting_changes[3]) == 0, "杠上炮没叫时不应计算雨钱", failures)


func _test_qiang_gang_transfer_requires_ting(failures: Array[String]) -> void:
	var ting_changes := _resolve_transfer_case("qiang_gang_hu", true)
	var no_ting_changes := _resolve_transfer_case("qiang_gang_hu", false)
	_expect(int(ting_changes[1]) == 4 and int(ting_changes[0]) == -2 and int(ting_changes[2]) == -1 and int(ting_changes[3]) == -1, "抢杠胡有叫时应把补杠雨钱转给胡家", failures)
	_expect(int(no_ting_changes[1]) == 2 and int(no_ting_changes[0]) == -2 and int(no_ting_changes[2]) == 0 and int(no_ting_changes[3]) == 0, "抢杠胡杠家没叫时不应计算雨钱", failures)


func _resolve_transfer_case(win_type: String, actor_is_ting: bool) -> Dictionary:
	var resolver = ScoreResolverScript.new()
	var rules = RuleConfigScript.new(RuleConfigScript.MODE_NEIJIANG_CLASSIC)
	var players := [_player_stub(0), _player_stub(1), _player_stub(2), _player_stub(3)]
	var tile := _tile("tiao", 5, 99)
	var gang_events: Array = []
	if win_type == "gang_discard_win":
		gang_events.append({
			"actor_seat": 0,
			"gang_type": "add_gang",
			"related_outcome": "gang_discard_win",
			"payer_seats": [1, 2, 3],
		})
	var settlement := {
		"end_reason": "battle_end",
		"gang_events": gang_events,
		"transfer_events": [{
			"from_seat": 0,
			"to_seat": 1,
			"transfer_type": "hu_jiao_zhuan_yi",
			"gang_type": "add_gang",
			"payer_seats": [2, 3],
			"related_actor_seat": 0,
			"related_outcome": win_type,
		}],
		"win_events": [{
			"winner_seat": 1,
			"payer_seats": [0],
			"win_type": win_type,
			"fan_detail": {"capped_fan": 2, "hand_score": 2},
		}],
		"draw_assessment": [{"seat": 0, "is_ting": actor_is_ting}],
	}
	return resolver.build_score_changes(players, settlement, rules)


func _winning_player_stub(seat: int) -> Dictionary:
	var player := _player_stub(seat)
	player["hand_tiles"] = [
		_tile("tiao", 1, 1), _tile("tiao", 2, 2), _tile("tiao", 3, 3),
		_tile("tiao", 4, 4), _tile("tiao", 5, 5), _tile("tiao", 6, 6),
		_tile("tong", 1, 7), _tile("tong", 2, 8), _tile("tong", 3, 9),
		_tile("tong", 4, 10), _tile("tong", 5, 11), _tile("tong", 6, 12),
		_tile("tiao", 5, 13),
	]
	return player


func _player_stub(seat: int) -> Dictionary:
	return {"seat": seat, "has_won": false, "bao_jiao": false, "hand_tiles": [], "melds": [], "rule_marks": []}


func _tile(suit: String, rank: int, id: int) -> Dictionary:
	return {"suit": suit, "rank": rank, "id": id, "display_name": "%s%d" % [suit, rank]}


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if condition:
		print("PASS ", message)
	else:
		failures.append(message)
