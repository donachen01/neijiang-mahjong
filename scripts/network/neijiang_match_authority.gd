extends RefCounted

# The transport passes the authenticated player ID, never a seat claimed by
# the command payload. GameState remains the sole rules/score authority.

const ACTION_METHODS := {
	"hu": "execute_human_hu",
	"self_hu": "execute_human_self_hu",
	"pass_self_hu": "pass_human_self_hu",
	"peng": "execute_human_peng",
	"gang": "execute_human_gang",
	"add_gang": "execute_human_add_gang",
	"an_gang": "execute_human_an_gang",
	"pass": "pass_human_reaction",
	"pass_opening_bao_jiao": "pass_human_opening_bao_jiao",
}

var game_state: Node
var player_seats: Dictionary = {}
var last_sequence: Dictionary = {}


func configure(authority_state: Node, members: Array) -> bool:
	if authority_state == null:
		return false
	var seats := {}
	var mapped := {}
	for member_value in members:
		if not member_value is Dictionary:
			return false
		var member: Dictionary = member_value
		var player_id := str(member.get("player_id", ""))
		var seat := int(member.get("seat", -1))
		if player_id.is_empty() or seat < 0 or seat >= 4 or seats.has(seat) or mapped.has(player_id):
			return false
		seats[seat] = true
		mapped[player_id] = seat
	if mapped.is_empty():
		return false
	game_state = authority_state
	player_seats = mapped
	last_sequence.clear()
	return true


func handle_command(authenticated_player_id: String, command: Dictionary) -> Dictionary:
	if game_state == null or not player_seats.has(authenticated_player_id):
		return _reject(command, "UNKNOWN_PLAYER")
	var sequence := int(command.get("sequence", 0))
	if sequence <= int(last_sequence.get(authenticated_player_id, 0)):
		return _reject(command, "STALE_SEQUENCE")
	if int(command.get("round_index", -1)) != int(game_state.get("round_index")):
		return _reject(command, "STALE_ROUND")
	var seat := int(player_seats[authenticated_player_id])
	var action := str(command.get("command", ""))
	var accepted := false
	match action:
		"discard":
			var tile_id := int(command.get("tile_id", -1))
			if tile_id <= 0:
				return _reject(command, "INVALID_ARGUMENT")
			accepted = bool(game_state.call("discard_tile_by_id", seat, tile_id))
		"bao_jiao":
			var selected = command.get("selected_bao_gang_keys", [])
			if not selected is Array or Array(selected).size() > 18:
				return _reject(command, "INVALID_ARGUMENT")
			for key in selected:
				if not key is String or String(key).length() > 16:
					return _reject(command, "INVALID_ARGUMENT")
			accepted = bool(game_state.call("execute_human_bao_jiao", seat, selected))
		"action":
			var requested := str(command.get("action", ""))
			var method := str(ACTION_METHODS.get(requested, ""))
			if method.is_empty():
				return _reject(command, "UNKNOWN_ACTION")
			accepted = bool(game_state.call(method, seat))
		_:
			return _reject(command, "UNKNOWN_COMMAND")
	last_sequence[authenticated_player_id] = sequence
	return {"ok": accepted, "sequence": sequence, "error": "" if accepted else "ILLEGAL_ACTION"}


func _reject(command: Dictionary, reason: String) -> Dictionary:
	return {"ok": false, "sequence": int(command.get("sequence", 0)), "error": reason}
