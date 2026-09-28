extends Node

class_name GameManager

const SessionAdapterScript := preload("res://scripts/game/neijiang_session_adapter.gd")

signal snapshot_changed(snapshot: Dictionary)
signal opening_roll_started(data: Dictionary)

@onready var game_state: Node = get_node("/root/GameState")

var latest_snapshot: Dictionary = {}
var session_adapter = SessionAdapterScript.new()
var network_command_sender: Callable
var snapshot_before_pending_command: Dictionary = {}


func configure_session(role: int, local_seat: int) -> bool:
	return session_adapter.configure(role, local_seat)


func configure_network_client(local_seat: int, command_sender: Callable) -> bool:
	if not command_sender.is_valid() or not session_adapter.configure(SessionAdapterScript.Role.CLIENT, local_seat):
		return false
	network_command_sender = command_sender
	latest_snapshot.clear()
	return true


func apply_private_snapshot(snapshot: Dictionary) -> bool:
	if session_adapter.role != SessionAdapterScript.Role.CLIENT:
		return false
	if int(snapshot.get("schema_version", 0)) != 1 or int(snapshot.get("local_seat_id", -1)) != 0:
		return false
	latest_snapshot = _normalize_network_snapshot(snapshot)
	snapshot_before_pending_command.clear()
	snapshot_changed.emit(latest_snapshot.duplicate(true))
	return true


func _normalize_network_snapshot(snapshot: Dictionary) -> Dictionary:
	var normalized := snapshot.duplicate(true)
	var settlement: Dictionary = normalized.get("settlement_data", {})
	for score_key in ["score_changes", "preapplied_score_changes"]:
		var changes: Dictionary = settlement.get(score_key, {})
		var score_by_seat := {}
		for key in changes:
			var seat := int(str(key))
			if seat >= 0 and seat < 4:
				score_by_seat[seat] = int(changes[key])
		settlement[score_key] = score_by_seat
	normalized["settlement_data"] = settlement
	return normalized


func apply_network_command_result(result: Dictionary) -> void:
	if session_adapter.role != SessionAdapterScript.Role.CLIENT:
		return
	if not bool(result.get("ok", false)) and not snapshot_before_pending_command.is_empty():
		latest_snapshot = snapshot_before_pending_command.duplicate(true)
		snapshot_changed.emit(latest_snapshot.duplicate(true))
	snapshot_before_pending_command.clear()


func get_local_seat() -> int:
	return int(session_adapter.local_seat)


func _can_call_authority() -> bool:
	return game_state != null and session_adapter.may_call_authority()


func get_local_hand_tiles() -> Array:
	if session_adapter.role == SessionAdapterScript.Role.CLIENT:
		var players: Array = latest_snapshot.get("players", [])
		for player in players:
			if int(player.get("seat", -1)) == 0:
				return Array(player.get("hand_tiles", [])).duplicate(true)
		return []
	return [] if not _can_call_authority() else game_state.call("get_player_hand_tiles", get_local_seat())


func execute_bao_jiao_with_selection(selected_keys: Array) -> bool:
	if session_adapter.role == SessionAdapterScript.Role.CLIENT:
		return _send_client_action("bao_jiao", {"selected_bao_gang_keys": selected_keys}, "reaction")
	return false if not _can_call_authority() else bool(game_state.call("execute_human_bao_jiao", get_local_seat(), selected_keys))


func _send_client_action(command: String, arguments: Dictionary, pending_kind: String) -> bool:
	if not network_command_sender.is_valid() or not snapshot_before_pending_command.is_empty():
		return false
	var before := latest_snapshot.duplicate(true)
	if not bool(network_command_sender.call(command, arguments)):
		return false
	snapshot_before_pending_command = before
	if pending_kind == "discard":
		latest_snapshot["human_can_discard"] = false
	else:
		for key in ["human_can_self_hu", "human_can_add_gang", "human_can_an_gang", "human_can_bao_jiao", "human_can_pass_opening_bao_jiao"]:
			latest_snapshot[key] = false
		latest_snapshot["human_reaction_options"] = {}
	snapshot_changed.emit(latest_snapshot.duplicate(true))
	return true


func _ready() -> void:
	var runtime := get_node_or_null("/root/LanRuntime")
	if runtime != null and bool(runtime.get("match_active")):
		runtime.call("configure_game_manager", self)
	if game_state != null and game_state.has_signal("state_changed"):
		game_state.state_changed.connect(_on_state_changed)
	if game_state != null and game_state.has_signal("opening_roll_started"):
		game_state.opening_roll_started.connect(_on_opening_roll_started)
		if session_adapter.role != SessionAdapterScript.Role.CLIENT:
			_emit_snapshot()


func get_snapshot() -> Dictionary:
	if session_adapter.role == SessionAdapterScript.Role.CLIENT:
		return latest_snapshot.duplicate(true)
	if game_state == null:
		return {}
	if not latest_snapshot.is_empty():
		return latest_snapshot.duplicate(true)
	return _build_local_snapshot()


func get_fresh_snapshot() -> Dictionary:
	if session_adapter.role == SessionAdapterScript.Role.CLIENT:
		return latest_snapshot.duplicate(true)
	if game_state == null:
		return {}
	latest_snapshot = _build_local_snapshot()
	return latest_snapshot.duplicate(true)


func set_human_trainer_hint_enabled(enabled: bool) -> void:
	if game_state == null or session_adapter.role == SessionAdapterScript.Role.CLIENT:
		return
	game_state.call("set_human_trainer_hint_enabled", true if session_adapter.role == SessionAdapterScript.Role.HOST else enabled)


func set_ai_level(level: int) -> bool:
	return false if game_state == null else bool(game_state.call("set_ai_level", level))


func set_ai_preset(preset_name: String) -> bool:
	return false if game_state == null else bool(game_state.call("set_ai_preset", preset_name))


func mark_current_hell_training_case(reason: String = "manual_mark") -> bool:
	return false if game_state == null else bool(game_state.call("mark_current_hell_training_case", reason))


func set_hell_diagnostics_recording_enabled(enabled: bool) -> bool:
	return false if game_state == null else bool(game_state.call("set_hell_diagnostics_recording_enabled", enabled))


func export_diagnostic_package() -> Dictionary:
	if game_state == null or not game_state.has_method("export_diagnostic_package"):
		return {"ok": false, "error": "game_state_export_unavailable"}
	return game_state.call("export_diagnostic_package")


func set_ai_tuning_value(key: String, value: int) -> bool:
	return false if game_state == null else bool(game_state.call("set_ai_tuning_value", key, value))


func reset_ai_tuning_overrides() -> bool:
	return false if game_state == null else bool(game_state.call("reset_ai_tuning_overrides"))


func set_ai_auto_learning_enabled(enabled: bool) -> bool:
	return false if game_state == null else bool(game_state.call("set_ai_auto_learning_enabled", enabled))


func set_ai_endgame_absolute_defense_enabled(enabled: bool) -> bool:
	return false if game_state == null else bool(game_state.call("set_ai_endgame_absolute_defense_enabled", enabled))


func apply_bone_ash_recommended_tuning() -> bool:
	return false if game_state == null else bool(game_state.call("apply_bone_ash_recommended_tuning"))


func set_ai_prefer_csharp_backend(enabled: bool) -> bool:
	return false if game_state == null else bool(game_state.call("set_ai_prefer_csharp_backend", enabled))


func set_ai_csharp_host_mode_enabled(enabled: bool, port: int = 38581) -> bool:
	return false if game_state == null else bool(game_state.call("set_ai_csharp_host_mode_enabled", enabled, port))


func advance_to_next_round() -> bool:
	return false if not _can_call_authority() else bool(game_state.call("advance_to_next_round"))


func complete_opening_roll() -> bool:
	return false if not _can_call_authority() else bool(game_state.call("complete_opening_roll"))


func discard_tile(tile_id: int) -> bool:
	if session_adapter.role == SessionAdapterScript.Role.CLIENT:
		return _send_client_action("discard", {"tile_id": tile_id}, "discard")
	return false if not _can_call_authority() else bool(game_state.call("discard_tile_by_id", get_local_seat(), tile_id))


func choose_ding_que(suit: String) -> bool:
	return false if not _can_call_authority() else bool(game_state.call("choose_ding_que", get_local_seat(), suit))


func get_human_reaction_options() -> Dictionary:
	if session_adapter.role == SessionAdapterScript.Role.CLIENT:
		return Dictionary(latest_snapshot.get("human_reaction_options", {})).duplicate(true)
	return {} if not _can_call_authority() else game_state.call("get_human_reaction_options", get_local_seat())


func can_human_add_gang() -> bool:
	return bool(latest_snapshot.get("human_can_add_gang", false)) if session_adapter.role == SessionAdapterScript.Role.CLIENT else (false if not _can_call_authority() else bool(game_state.call("can_human_add_gang", get_local_seat())))


func can_human_an_gang() -> bool:
	return bool(latest_snapshot.get("human_can_an_gang", false)) if session_adapter.role == SessionAdapterScript.Role.CLIENT else (false if not _can_call_authority() else bool(game_state.call("can_human_an_gang", get_local_seat())))


func can_human_bao_jiao() -> bool:
	return bool(latest_snapshot.get("human_can_bao_jiao", false)) if session_adapter.role == SessionAdapterScript.Role.CLIENT else (false if not _can_call_authority() else bool(game_state.call("can_human_bao_jiao", get_local_seat())))


func execute_action(action: String) -> bool:
	if session_adapter.role == SessionAdapterScript.Role.CLIENT:
		return _send_client_action("action", {"action": action}, "reaction")
	if not _can_call_authority():
		return false
	var seat := get_local_seat()
	match action:
		"hu":
			return bool(game_state.call("execute_human_hu", seat))
		"self_hu":
			return bool(game_state.call("execute_human_self_hu", seat))
		"pass_self_hu":
			return bool(game_state.call("pass_human_self_hu", seat))
		"peng":
			return bool(game_state.call("execute_human_peng", seat))
		"gang":
			return bool(game_state.call("execute_human_gang", seat))
		"add_gang":
			return bool(game_state.call("execute_human_add_gang", seat))
		"an_gang":
			return bool(game_state.call("execute_human_an_gang", seat))
		"bao_jiao":
			return bool(game_state.call("execute_human_bao_jiao", seat))
		"pass_opening_bao_jiao":
			return bool(game_state.call("pass_human_opening_bao_jiao", seat))
		"pass":
			return bool(game_state.call("pass_human_reaction", seat))
		_:
			return false


func is_ai_turn_ready() -> bool:
	return false if not _can_call_authority() else bool(game_state.call("is_ai_turn_ready"))


func is_ai_reaction_pending() -> bool:
	return false if not _can_call_authority() else bool(game_state.call("is_ai_reaction_pending"))


func run_ai_turn() -> bool:
	return false if not _can_call_authority() else bool(game_state.call("run_ai_turn"))


func prepare_ai_turn_decision() -> bool:
	return false if not _can_call_authority() else bool(game_state.call("prepare_ai_turn_decision"))


func prepare_ai_reaction_decision() -> bool:
	return false if not _can_call_authority() else bool(game_state.call("prepare_ai_reaction_decision"))


func run_ai_reaction() -> bool:
	return false if not _can_call_authority() else bool(game_state.call("run_ai_reaction"))


func pump_ai_background_requests() -> int:
	return 0 if not _can_call_authority() else int(game_state.call("pump_ai_background_requests"))


func _on_state_changed(snapshot: Dictionary) -> void:
	if session_adapter.role == SessionAdapterScript.Role.CLIENT:
		return
	latest_snapshot = snapshot.duplicate(true) if session_adapter.role == SessionAdapterScript.Role.LOCAL else _build_local_snapshot()
	snapshot_changed.emit(latest_snapshot.duplicate(true))


func _on_opening_roll_started(data: Dictionary) -> void:
	if session_adapter.role == SessionAdapterScript.Role.CLIENT:
		return
	opening_roll_started.emit(data)


func _emit_snapshot() -> void:
	if not _can_call_authority():
		return
	latest_snapshot = _build_local_snapshot()
	snapshot_changed.emit(latest_snapshot.duplicate(true))


func _build_local_snapshot() -> Dictionary:
	if game_state == null:
		return {}
	if session_adapter.role == SessionAdapterScript.Role.HOST:
		return _normalize_network_snapshot(game_state.call("get_gameplay_snapshot", get_local_seat()))
	return game_state.call("get_debug_snapshot")
