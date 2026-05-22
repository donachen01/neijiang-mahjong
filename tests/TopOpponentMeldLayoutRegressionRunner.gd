extends SceneTree

const PLAYER_UI_SCENE := preload("res://scenes/ui/PlayerUI.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var top_ui: PlayerUI = PLAYER_UI_SCENE.instantiate() as PlayerUI
	top_ui.seat_dock = PlayerUI.SeatDock.TOP
	get_root().add_child(top_ui)
	await process_frame

	var melds := [
		_make_meld(5100, "tong", 9, 0, 3),
		_make_meld(5200, "tong", 8, 1, 3),
		_make_meld(5300, "tong", 7, 3, 3),
	]
	var player := {
		"seat": 2,
		"nickname": "对家",
		"score": -14,
		"hand_count": 9,
		"hand_tiles": _fake_tiles(9),
		"melds": melds,
		"discards": [],
	}
	top_ui.apply_snapshot(player, true, -1, -1, true)
	await process_frame
	await process_frame

	_assert_top_row_fits(top_ui, 9, 9, failures)
	top_ui.queue_free()
	if failures.is_empty():
		print("PASS top_opponent_three_melds_and_hand_fit_18_slots")
		print("TOP OPPONENT MELD LAYOUT REGRESSION OK")
		quit(0)
		return
	push_error("TOP OPPONENT MELD LAYOUT REGRESSION FAILED:\n- " + "\n- ".join(failures))
	quit(1)


func _assert_top_row_fits(top_ui: PlayerUI, expected_meld_tiles: int, expected_hand_tiles: int, failures: Array[String]) -> void:
	var row_root := top_ui.find_child("HorizontalRowRoot", true, false) as Control
	var meld_slot := top_ui.find_child("TopMeldSlot", true, false) as Control
	var hand_slot := top_ui.find_child("TopHandSlot", true, false) as Control
	if row_root == null or meld_slot == null or hand_slot == null:
		failures.append("missing top row slots")
		return
	var meld_tiles: Array[Control] = []
	var hand_tiles: Array[Control] = []
	_collect_tile_visual_controls(meld_slot, meld_tiles)
	_collect_tile_visual_controls(hand_slot, hand_tiles)
	if meld_tiles.size() != expected_meld_tiles:
		failures.append("expected %d meld tiles, got %d" % [expected_meld_tiles, meld_tiles.size()])
	if hand_tiles.size() != expected_hand_tiles:
		failures.append("expected %d hand tiles, got %d" % [expected_hand_tiles, hand_tiles.size()])
	var row_rect := row_root.get_global_rect()
	for tile in meld_tiles + hand_tiles:
		var tile_rect := tile.get_global_rect()
		if tile_rect.position.x < row_rect.position.x - 1.0 or tile_rect.end.x > row_rect.end.x + 1.0:
			failures.append("tile outside 18-slot top row: %s / row %s" % [tile_rect, row_rect])
			break
	var meld_bounds := _controls_global_bounds(meld_tiles)
	var hand_bounds := _controls_global_bounds(hand_tiles)
	var meld_rect := meld_slot.get_global_rect()
	var hand_rect := hand_slot.get_global_rect()
	if meld_bounds.size.x > meld_rect.size.x + 1.0:
		failures.append("meld tiles clipped: tiles %.1f / slot %.1f" % [meld_bounds.size.x, meld_rect.size.x])
	if hand_bounds.size.x > hand_rect.size.x + 1.0:
		failures.append("hand tiles clipped: tiles %.1f / slot %.1f" % [hand_bounds.size.x, hand_rect.size.x])
	if meld_slot.position.x > 38.0:
		failures.append("top row did not expand left enough, meld slot x %.1f" % meld_slot.position.x)


func _fake_tiles(count: int) -> Array:
	var tiles: Array = []
	for index in range(count):
		tiles.append({
			"id": 9000 + index,
			"suit": "tiao",
			"rank": index % 9 + 1,
		})
	return tiles


func _make_meld(base_id: int, suit: String, rank: int, from_seat: int, count: int) -> Dictionary:
	var tiles: Array = []
	for index in range(count):
		tiles.append({
			"id": base_id + index,
			"suit": suit,
			"rank": rank,
		})
	return {
		"type": "peng" if count == 3 else "gang",
		"from_seat": from_seat,
		"tiles": tiles,
	}


func _collect_tile_visual_controls(node: Node, result: Array[Control]) -> void:
	if node is TileVisual2D:
		result.append(node as Control)
	for child in node.get_children():
		_collect_tile_visual_controls(child, result)


func _controls_global_bounds(controls: Array[Control]) -> Rect2:
	if controls.is_empty():
		return Rect2()
	var bounds := controls[0].get_global_rect()
	for index in range(1, controls.size()):
		bounds = bounds.merge(controls[index].get_global_rect())
	return bounds
