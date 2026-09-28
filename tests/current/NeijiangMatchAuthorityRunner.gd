extends SceneTree

const AUTHORITY := preload("res://scripts/network/neijiang_match_authority.gd")

class FakeGameState extends Node:
	var round_index := 2
	var calls: Array = []
	func discard_tile_by_id(seat: int, tile_id: int) -> bool:
		calls.append(["discard", seat, tile_id])
		return tile_id == 7
	func execute_human_bao_jiao(seat: int, selected: Array) -> bool:
		calls.append(["bao_jiao", seat, selected.duplicate()])
		return true
	func pass_human_opening_bao_jiao(seat: int) -> bool:
		calls.append(["pass_opening", seat])
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := FakeGameState.new()
	get_root().add_child(state)
	var authority = AUTHORITY.new()
	if authority.configure(state, [{"player_id": "host", "seat": 1}, {"player_id": "guest", "seat": 3}]) == false:
		_fail("有效房间成员未配置")
		return
	if authority.handle_command("guest", {"sequence": 1, "round_index": 2, "command": "discard", "seat": 1, "tile_id": 7}).get("ok") != true or state.calls.back() != ["discard", 3, 7]:
		_fail("客户端伪造座位影响权威出牌")
		return
	if authority.handle_command("guest", {"sequence": 1, "round_index": 2, "command": "discard", "tile_id": 7}).get("error") != "STALE_SEQUENCE":
		_fail("重复命令未拦截")
		return
	if authority.handle_command("host", {"sequence": 1, "round_index": 1, "command": "bao_jiao"}).get("error") != "STALE_ROUND":
		_fail("上一局迟到报叫未拦截")
		return
	if authority.handle_command("host", {"sequence": 2, "round_index": 2, "command": "bao_jiao", "selected_bao_gang_keys": ["tiao_2"]}).get("ok") != true or state.calls.back() != ["bao_jiao", 1, ["tiao_2"]]:
		_fail("报叫/报杠选择未交给权威状态机")
		return
	if authority.handle_command("host", {"sequence": 3, "round_index": 2, "command": "action", "action": "pass_opening_bao_jiao"}).get("ok") != true or state.calls.back() != ["pass_opening", 1]:
		_fail("开局过牌未交给正确座位")
		return
	if authority.handle_command("host", {"sequence": 4, "round_index": 2, "command": "action", "action": "ding_que"}).get("error") != "UNKNOWN_ACTION":
		_fail("四川定缺动作不应进入内江房间")
		return
	if authority.handle_command("intruder", {"sequence": 1, "round_index": 2, "command": "discard", "tile_id": 7}).get("error") != "UNKNOWN_PLAYER":
		_fail("非房间成员命令未拦截")
		return
	print("NEIJIANG MATCH AUTHORITY OK")
	quit(0)


func _fail(message: String) -> void:
	push_error("NEIJIANG MATCH AUTHORITY FAILED: " + message)
	quit(1)
