extends SceneTree

const ScoreResolverScript := preload("res://scripts/core/score_resolver.gd")
const RuleConfigScript := preload("res://scripts/core/rule_config.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_test_special_win_fans(failures)
	_test_melds_participate_in_settlement_fans(failures)
	_test_next_dealer_contract(failures)
	_test_no_replacement_tile_blocks_gang(failures)
	_test_add_gang_upgrade_contract(failures)
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


func _test_melds_participate_in_settlement_fans(failures: Array[String]) -> void:
	var resolver = ScoreResolverScript.new()
	var rules = RuleConfigScript.new(RuleConfigScript.MODE_NEIJIANG_CLASSIC)
	var player := _player_stub(1)
	player["hand_tiles"] = [
		_tile("tiao", 1, 201), _tile("tiao", 2, 202), _tile("tiao", 3, 203),
		_tile("tiao", 4, 204), _tile("tiao", 5, 205), _tile("tiao", 6, 206),
		_tile("tiao", 7, 207), _tile("tiao", 7, 208), _tile("tiao", 7, 209),
		_tile("tiao", 9, 210),
	]
	player["melds"] = [{
		"type": "peng", "from_seat": 0,
		"tiles": [_tile("tiao", 8, 211), _tile("tiao", 8, 212), _tile("tiao", 8, 213)],
	}]
	var detail: Dictionary = resolver.build_event_fan_detail(player, _tile("tiao", 9, 214), "discard_win", rules)
	_expect(str(detail.get("hand_type", "")) == "qing_yi_se", "结算番型必须把手牌和副露一起识别为清一色", failures)

	player["melds"][0]["tiles"][0]["suit"] = "tong"
	var mixed_detail: Dictionary = resolver.build_event_fan_detail(player, _tile("tiao", 9, 215), "discard_win", rules)
	_expect(str(mixed_detail.get("hand_type", "")) != "qing_yi_se", "副露异色时结算不得把手牌单独误判为清一色", failures)


func _test_next_dealer_contract(failures: Array[String]) -> void:
	var game_state = get_root().get_node_or_null("GameState")
	if game_state == null:
		failures.append("GameState自动加载不可用")
		return
	var saved_players: Array[Dictionary] = []
	for player in game_state.players:
		saved_players.append(Dictionary(player).duplicate(true))
	var saved_settlement: Dictionary = game_state.settlement_data.duplicate(true)
	var saved_dealer := int(game_state.current_dealer_seat)
	var test_players: Array[Dictionary] = [_player_stub(0), _player_stub(1), _player_stub(2), _player_stub(3)]
	game_state.players = test_players
	game_state.current_dealer_seat = 0
	game_state.settlement_data = {"win_events": [{"winner_seat": 2, "source_seat": 1, "win_type": "discard_win", "winning_tile": _tile("tong", 3, 401)}]}
	_expect(int(game_state.call("_resolve_next_dealer_seat")) == 2, "单家胡牌后由首个胡牌玩家坐庄", failures)
	game_state.settlement_data = {"win_events": [
		{"winner_seat": 1, "source_seat": 3, "win_type": "discard_win", "winning_tile": _tile("tong", 3, 402)},
		{"winner_seat": 2, "source_seat": 3, "win_type": "discard_win", "winning_tile": _tile("tong", 3, 402)},
	]}
	_expect(int(game_state.call("_resolve_next_dealer_seat")) == 3, "一炮多响后由点炮玩家坐庄", failures)
	game_state.settlement_data = {"win_events": [
		{"winner_seat": 1, "source_seat": 3, "win_type": "discard_win", "winning_tile": _tile("tong", 3, 403)},
		{"winner_seat": 2, "source_seat": 3, "win_type": "discard_win", "winning_tile": _tile("tong", 3, 404)},
	]}
	_expect(int(game_state.call("_resolve_next_dealer_seat")) == 1, "同一人先后两次点炮不能算作首次一炮多响", failures)
	game_state.players = saved_players
	game_state.settlement_data = saved_settlement
	game_state.current_dealer_seat = saved_dealer


func _test_no_replacement_tile_blocks_gang(failures: Array[String]) -> void:
	var game_state = get_root().get_node_or_null("GameState")
	if game_state == null:
		failures.append("GameState自动加载不可用")
		return
	var saved_players: Array[Dictionary] = game_state.players.duplicate(true)
	var saved_wall: Array[Dictionary] = game_state.wall.duplicate(true)
	var saved_wall_count: int = game_state.wall_count
	var saved_phase: int = game_state.current_phase
	var saved_turn: int = game_state.current_turn_seat
	var saved_draw: Dictionary = game_state.last_draw_tile.duplicate(true)
	var test_players: Array[Dictionary] = [_player_stub(0), _player_stub(1), _player_stub(2), _player_stub(3)]
	game_state.players = test_players
	game_state.players[0]["hand_tiles"] = [
		_tile("tong", 4, 501), _tile("tong", 4, 502), _tile("tong", 4, 503), _tile("tong", 4, 504),
		_tile("tiao", 5, 505),
	]
	game_state.players[0]["melds"] = [{"type": "peng", "from_seat": 1, "tiles": [
		_tile("tiao", 5, 506), _tile("tiao", 5, 507), _tile("tiao", 5, 508),
	]}]
	var empty_wall: Array[Dictionary] = []
	game_state.wall = empty_wall
	game_state.wall_count = 0
	game_state.current_phase = game_state.RoundPhase.DISCARD
	game_state.current_turn_seat = 0
	game_state.last_draw_tile = {"seat": 0, "tile": _tile("tiao", 5, 505)}
	_expect(not game_state.can_human_an_gang(0) and game_state._find_all_an_gang_options(0).is_empty(), "无补张时不出现暗杠候选", failures)
	_expect(not game_state.can_human_add_gang(0) and game_state._find_all_add_gang_options(0).is_empty(), "无补张时不出现补杠候选", failures)
	var an_option := {"tiles": game_state.players[0]["hand_tiles"].slice(0, 4)}
	var add_option := {"meld_index": 0, "tile": _tile("tiao", 5, 505), "source_seat": 1}
	_expect(not game_state.call("_execute_an_gang", 0, an_option), "直接请求暗杠也须拒绝", failures)
	_expect(not game_state.call("_start_add_gang", 0, add_option), "直接请求补杠也须拒绝", failures)
	_expect(game_state.players[0]["melds"].size() == 1 and game_state.players[0]["hand_tiles"].size() == 5, "拒绝后手牌和副露不变", failures)
	game_state.players = saved_players
	game_state.wall = saved_wall
	game_state.wall_count = saved_wall_count
	game_state.current_phase = saved_phase
	game_state.current_turn_seat = saved_turn
	game_state.last_draw_tile = saved_draw


func _test_add_gang_upgrade_contract(failures: Array[String]) -> void:
	var game_state = get_root().get_node_or_null("GameState")
	if game_state == null:
		failures.append("GameState自动加载不可用")
		return
	var saved_players: Array[Dictionary] = []
	for player in game_state.players:
		saved_players.append(Dictionary(player).duplicate(true))
	var test_players: Array[Dictionary] = [_player_stub(0), _player_stub(1), _player_stub(2), _player_stub(3)]
	game_state.players = test_players
	game_state.players[0]["melds"] = [{
		"type": "peng", "from_seat": 1,
		"tiles": [_tile("tong", 4, 301), _tile("tong", 4, 302), _tile("tong", 4, 303)],
	}]
	var upgraded := bool(game_state.call("_upgrade_peng_to_gang", 0, 0, _tile("tong", 4, 304)))
	var meld: Dictionary = game_state.players[0]["melds"][0]
	_expect(upgraded and str(meld.get("gang_subtype", "")) == "add_gang" and bool(meld.get("gang_upgrade", false)), "碰后补杠必须固化为add_gang而非保留碰牌来源方向", failures)
	game_state.players = saved_players


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
