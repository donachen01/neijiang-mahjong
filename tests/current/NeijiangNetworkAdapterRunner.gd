extends SceneTree

const MANAGER := preload("res://scripts/game/GameManager.gd")
const SESSION := preload("res://scripts/game/neijiang_session_adapter.gd")

var commands: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := get_root().get_node("GameState")
	var controllers := [
		{"seat": 0, "nickname": "甲", "is_ai": false, "player_id": "a"},
		{"seat": 1, "nickname": "电脑一", "is_ai": true, "player_id": ""},
		{"seat": 2, "nickname": "乙", "is_ai": false, "player_id": "b"},
		{"seat": 3, "nickname": "电脑二", "is_ai": true, "player_id": ""},
	]
	state.players[0]["score"] = 999
	state.discard_pile.append({"id": 999, "suit": "tong", "rank": 9})
	state.settlement_data["scores_applied"] = true
	state.round_index = 4
	if not state.prepare_lan_table(controllers):
		_fail("联机等待状态未建立")
		return
	if state.current_phase != state.RoundPhase.TABLE_SETUP or state.round_index != 1 or state.wall_count != 0 or not state.wall.is_empty() or not state.discard_pile.is_empty():
		_fail("联机等待状态残留了上一局牌面")
		return
	if int(state.players[0].get("score", -1)) != state.STARTING_SCORE or bool(state.settlement_data.get("scores_applied", false)):
		_fail("联机等待状态残留了上一局分数或结算")
		return
	var waiting_snapshot: Dictionary = state.get_gameplay_snapshot(2)
	if int(waiting_snapshot.get("current_phase", -1)) != state.RoundPhase.TABLE_SETUP or int(waiting_snapshot.get("wall_count", -1)) != 0:
		_fail("联机等待快照错误")
		return
	if not state.configure_seat_controllers(controllers, true):
		_fail("四座位控制器未接受")
		return
	if str(state.players[2].get("nickname", "")) != "乙" or bool(state.players[2].get("is_ai", true)):
		_fail("真人座位没有进入内江状态机")
		return
	state.complete_opening_roll()
	state.current_phase = state.RoundPhase.DISCARD
	state.current_turn_seat = 2
	state.opening_bao_jiao_pending = false
	if int(state.players[2].get("hand_count", 0)) == 13:
		state.players[2]["hand_tiles"].append(state.wall.pop_back())
		state.players[2]["hand_count"] = 14
		state.wall_count = state.wall.size()
	state.set_human_trainer_hint_enabled(true)
	var private_snapshot: Dictionary = state.get_gameplay_snapshot(2)
	if int(private_snapshot.get("local_seat_id", -1)) != 0 or int(private_snapshot.get("players", [])[0].get("authority_seat", -1)) != 2:
		_fail("真人座位私有快照没有转换成本家")
		return
	var hint: Dictionary = private_snapshot.get("trainer_hint", {})
	if hint.is_empty() or int(hint.get("recommended_tile_id", -1)) < 0:
		_fail("非零真人座位没有收到自己的同步 C# 出牌提示：%s" % hint)
		return
	var manager = MANAGER.new()
	get_root().add_child(manager)
	if not manager.configure_network_client(2, Callable(self, "_record_command")):
		_fail("客户端命令适配器未配置")
		return
	private_snapshot["human_can_discard"] = true
	if not manager.apply_private_snapshot(private_snapshot):
		_fail("私有快照未被客户端接受")
		return
	if not manager.discard_tile(99) or commands.back() != ["discard", {"tile_id": 99}]:
		_fail("客户端出牌没有走命令通道")
		return
	if bool(manager.get_snapshot().get("human_can_discard", true)):
		_fail("待确认的客户端出牌没有防止重复提交")
		return
	manager.apply_network_command_result({"ok": false, "error": "ILLEGAL_ACTION"})
	if not bool(manager.get_snapshot().get("human_can_discard", false)):
		_fail("权威拒绝后没有恢复按钮状态")
		return
	if not manager.execute_bao_jiao_with_selection(["tiao_2"]) or commands.back() != ["bao_jiao", {"selected_bao_gang_keys": ["tiao_2"]}]:
		_fail("报叫/报杠选择没有走命令通道")
		return
	state.start_local_game()
	if not state.seat_controllers.is_empty() or str(state.players[0].get("nickname", "")) != "陈旭":
		_fail("返回单机后未清理联机座位")
		return
	print("NEIJIANG NETWORK ADAPTER OK")
	quit(0)


func _record_command(command: String, arguments: Dictionary) -> bool:
	commands.append([command, arguments.duplicate(true)])
	return true


func _fail(message: String) -> void:
	push_error("NEIJIANG NETWORK ADAPTER FAILED: " + message)
	quit(1)
