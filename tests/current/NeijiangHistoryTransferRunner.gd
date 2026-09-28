extends SceneTree

const CODEC := preload("res://scripts/network/protocol_codec.gd")
const SESSION := preload("res://scripts/network/lan_room_session.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var sender = SESSION.new()
	var receiver = SESSION.new()
	get_root().add_child(sender)
	get_root().add_child(receiver)
	var received: Array = []
	receiver.history_received.connect(func(records: Array): received.assign(records))
	var history: Array = []
	for index in range(60):
		history.append({"round_index": index + 1, "ledger": "甲乙丙丁".repeat(400), "score": [index, -index]})
	var messages: Array[Dictionary] = sender._build_history_messages(history)
	if messages.size() < 2:
		_fail("长战绩未分包")
		return
	for index in range(messages.size() - 1, -1, -1):
		var envelope: Dictionary = sender._history_envelope(messages[index])
		var bytes: PackedByteArray = CODEC.new().encode(envelope)
		if bytes.is_empty() or not bool(CODEC.new().decode(bytes).get("ok", false)):
			_fail("战绩分包超出协议限制")
			return
		receiver._handle_client_message(envelope)
	if received.size() != history.size() or int(received.back().get("round_index", -1)) != 60:
		_fail("逆序到达的战绩分包未完整重组")
		return
	var short_messages: Array[Dictionary] = sender._build_history_messages([history[0]])
	if short_messages.size() != 1 or str(short_messages[0].get("kind", "")) != "room_history":
		_fail("短战绩未保留单包兼容")
		return
	print("NEIJIANG HISTORY TRANSFER OK")
	quit(0)

func _fail(message: String) -> void:
	push_error("NEIJIANG HISTORY TRANSFER FAILED: " + message)
	quit(1)
