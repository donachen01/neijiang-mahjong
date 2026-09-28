extends SceneTree

const CATALOG := preload("res://scripts/ui/table/NeijiangVoiceCatalog.gd")
const ROUTER := preload("res://scripts/game/presentation/neijiang_voice_router.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var options := CATALOG.all_options()
	if options.size() != 14:
		failures.append("音色清单应有14项，实有%d项" % options.size())
	var keys: Array[String] = []
	for suit in ["tiao", "tong"]:
		for rank in range(1, 10):
			keys.append("%s_%d" % [suit, rank])
	keys.append_array(["peng", "gang", "hu", "zimo", "qiang_gang_hu", "gang_shang_hua", "gang_shang_pao", "pass", "win", "lose", "bao_jiao", "bao_gang"])
	var seen := {}
	for option in options:
		var voice_id := str(option.get("id", ""))
		var directory := str(option.get("directory", ""))
		if voice_id.is_empty() or seen.has(voice_id):
			failures.append("音色ID为空或重复：%s" % voice_id)
		seen[voice_id] = true
		for key in keys:
			var path := "res://res/audio/%s/%s.wav" % [directory, key]
			var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
			if stream == null:
				failures.append("缺少可播放声音：%s %s" % [voice_id, key])
	var router = ROUTER.new()
	var snapshot := {"players": [{"seat": 0}, {"seat": 1}, {"seat": 2}, {"seat": 3}]}
	router._assign_voice_profiles_for_round(snapshot, "sichuan")
	for seat in range(4):
		var stream := router._load_voice_stream_for_seat(seat, "tong_5", "sichuan", "") as AudioStream
		if stream == null:
			failures.append("第%d座自动语音无法播放" % seat)
	var selected := router._load_voice_stream_for_seat(0, "tong_5", "sichuan", "mandarin_xiaohe_2") as AudioStream
	var expected := load("res://res/audio/tts/female/tong_5.wav") as AudioStream
	if selected != expected:
		failures.append("本家主动选声未优先于全桌语言")
	if str(router._action_audio_key("报杠")) != "bao_gang" or str(router._action_audio_key("抢杠胡")) != "qiang_gang_hu":
		failures.append("内江声明与特殊胡牌语音映射错误")
	if failures.is_empty():
		print("NEIJIANG VOICE PACK OK: 14 voices, %d clips" % (options.size() * keys.size()))
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
