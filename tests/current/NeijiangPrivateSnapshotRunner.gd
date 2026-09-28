extends SceneTree

const PROJECTOR := preload("res://scripts/network/neijiang_snapshot_projector.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var projector = PROJECTOR.new()
	var players: Array = []
	for seat in range(4):
		players.append({
			"seat": seat, "nickname": "玩家%d" % seat, "score": seat,
			"hand_count": 1, "hand_tiles": [{"id": seat + 100, "display_name": "暗手%d" % seat}],
			"bao_jiao_ting_tiles": ["私有听牌%d" % seat],
			"melds": [{"from_seat": 1, "tiles": []}], "discards": [],
			"winning_source_seat": 1,
		})
	var snapshot := {
		"current_phase": 5, "round_index": 1, "current_dealer_seat": 1, "current_turn_seat": 2,
		"opening_bao_jiao_pending": true, "opening_bao_jiao_current_seat": 2,
		"players": players, "recent_draw_seat": 0, "recent_draw_display": "秘密摸牌",
		"trainer_hint": {"secret": "座位0提示"}, "ai_core_debug": {"secret": "内部AI"},
		"wall": [{"secret": "真实牌墙"}], "settlement_data": {"secret": "未结束账本"},
		"discard_context": {"source_seat": 1, "tile": {"id": 3}, "pending_reactions": ["私人候选"]},
	}
	var view: Dictionary = projector.project(snapshot, 2, {"human_can_discard": true, "trainer_hint": {"secret": "本家提示"}})
	var text_view := JSON.stringify(view)
	for secret in ["暗手0", "暗手1", "暗手3", "私有听牌", "座位0提示", "内部AI", "真实牌墙", "未结束账本", "私人候选", "秘密摸牌"]:
		if text_view.contains(secret):
			_fail("非本家私密数据泄露：" + secret)
			return
	if not text_view.contains("暗手2") or not text_view.contains("本家提示"):
		_fail("本家暗手或专属提示丢失")
		return
	if int(view.get("current_turn_seat", -1)) != 0 or int(view.get("current_dealer_seat", -1)) != 3:
		_fail("权威座位未映射到本家视角")
		return
	if int(view.get("opening_bao_jiao_current_seat", -1)) != 0 or int(view.get("players", [])[0].get("seat", -1)) != 0:
		_fail("报叫座位或玩家排序不正确")
		return
	if int(view.get("players", [])[0].get("melds", [])[0].get("from_seat", -1)) != 3:
		_fail("副露来源座位未映射")
		return
	snapshot["current_phase"] = 7
	snapshot["settlement_data"] = {"score_changes": {0: 3, 1: -1, 2: -1, 3: -1}, "win_events": [{"winner_seat": 0, "source_seat": 1, "payer_seats": [1]}]}
	view = projector.project(snapshot, 2)
	if not JSON.stringify(view).contains("暗手0") or int(view.get("settlement_data", {}).get("win_events", [])[0].get("winner_seat", -1)) != 2:
		_fail("结算揭示或赢家座位映射错误")
		return
	print("NEIJIANG PRIVATE SNAPSHOT OK")
	quit(0)


func _fail(message: String) -> void:
	push_error("NEIJIANG PRIVATE SNAPSHOT FAILED: " + message)
	quit(1)
