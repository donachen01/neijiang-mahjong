extends RefCounted

const MAPPER := preload("res://scripts/network/neijiang_seat_view_mapper.gd")

enum Role { LOCAL, HOST, CLIENT }

var role := Role.LOCAL
var local_seat := 0


func configure(next_role: Role, next_local_seat: int) -> bool:
	if next_local_seat < 0 or next_local_seat >= 4:
		return false
	role = next_role
	local_seat = next_local_seat
	return true


func may_call_authority() -> bool:
	return role != Role.CLIENT


func authority_to_view(seat: int) -> int:
	return MAPPER.authority_to_view(seat, local_seat)
