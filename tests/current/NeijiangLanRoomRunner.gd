extends SceneTree

const CODEC := preload("res://scripts/network/protocol_codec.gd")
const REGISTRY := preload("res://scripts/network/room_registry.gd")
const SESSION := preload("res://scripts/network/lan_room_session.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var codec = CODEC.new()
	var packet: PackedByteArray = codec.encode({"protocol_version": 2, "game_id": "neijiang_mahjong", "kind": "ready", "ready": true})
	if packet.is_empty() or not bool(codec.decode(packet).get("ok", false)):
		_fail("内江协议包无法编解码")
		return
	if not codec.encode({"protocol_version": 2, "game_id": "sichuan_mahjong", "kind": "ready"}).is_empty():
		_fail("四川房间协议被错误接受")
		return
	var registry = REGISTRY.new()
	if not bool(registry.create(1, "房主").get("ok", false)) or not bool(registry.join(2, "客人").get("ok", false)):
		_fail("双真人房间登记失败")
		return
	registry.set_ready(1, true)
	registry.set_ready(2, true)
	if not registry.can_start(2) or registry.build_seat_controllers().size() != 4:
		_fail("真人准备或 AI 补位错误")
		return
	var host = SESSION.new()
	var guest = SESSION.new()
	get_root().add_child(host)
	get_root().add_child(guest)
	var port := 29000 + randi_range(0, 500)
	if host.host("房主", port) != OK:
		_fail("回环房主监听失败")
		return
	if guest.join("127.0.0.1", port, "客人") != OK:
		_fail("回环客户端连接失败")
		return
	var joined := false
	for _step in range(120):
		await create_timer(0.025).timeout
		if guest.local_seat >= 0 and host.registry.members.size() == 2:
			joined = true
			break
	if not joined:
		_fail("回环房间握手超时")
		return
	if not guest.set_ready(true) or not host.set_ready(true):
		_fail("双真人准备消息未发送")
		return
	var started := false
	for _step in range(120):
		await create_timer(0.025).timeout
		if bool(host.get("_match_start_dispatched")) and bool(guest.get("_match_start_dispatched")):
			started = true
			break
		if bool(host.get("_match_start_dispatched")):
			started = true
			break
	if not started:
		_fail("准备后房间未自动开局")
		return
	host.reset()
	guest.reset()
	print("NEIJIANG LAN ROOM OK")
	quit(0)


func _fail(message: String) -> void:
	push_error("NEIJIANG LAN ROOM FAILED: " + message)
	quit(1)
