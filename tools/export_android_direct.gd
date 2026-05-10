@tool
extends SceneTree

const MONO_TEMPLATE_DIR := "/Users/chendong/Library/Application Support/Godot/export_templates/4.6.2.stable.mono/templates"
const STABLE_TEMPLATE_DIR := "/Users/chendong/Library/Application Support/Godot/export_templates/4.6.2.stable"


func _resolve_template_file(file_name: String) -> String:
	var mono_path := MONO_TEMPLATE_DIR.path_join(file_name)
	if FileAccess.file_exists(mono_path):
		return mono_path
	var stable_path := STABLE_TEMPLATE_DIR.path_join(file_name)
	if FileAccess.file_exists(stable_path):
		return stable_path
	return ""


func _initialize() -> void:
	await _wait_for_editor_filesystem()
	_export_android()


func _wait_for_editor_filesystem() -> void:
	if not Engine.is_editor_hint():
		return
	var filesystem := EditorInterface.get_resource_filesystem()
	if filesystem == null:
		return
	var safety := 0
	while filesystem.is_scanning() and safety < 600:
		safety += 1
		await process_frame
	for index in range(10):
		await process_frame


func _export_android() -> void:
	var export_mode := OS.get_environment("GODOT_ANDROID_EXPORT_MODE").to_lower()
	if export_mode == "":
		export_mode = "debug"
	var is_debug := export_mode != "release"
	var platform: Object = ClassDB.instantiate("EditorExportPlatformAndroid")
	if not platform:
		push_error("无法实例化 EditorExportPlatformAndroid")
		quit(1)
		return

	var preset: Object = platform.call("create_preset")
	preset.set("custom_features", "C#")
	preset.set("export_filter", "all_resources")
	preset.set("include_filter", "")
	preset.set("exclude_filter", "tests/*,tools/*,backups/*,测试数据统计/*,.tmp_tts/*,.venv_tts/*,.git/*,.godot/*")
	preset.set("script_export_mode", 2)
	preset.set("gradle_build/use_gradle_build", true)
	preset.set("gradle_build/gradle_build_directory", "/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/build/android/gradle_build")
	preset.set("gradle_build/android_source_template", _resolve_template_file("android_source.zip"))
	preset.set("gradle_build/compress_native_libraries", false)
	preset.set("gradle_build/export_format", 0)
	preset.set("architectures/armeabi-v7a", false)
	preset.set("architectures/arm64-v8a", true)
	preset.set("architectures/x86", false)
	preset.set("architectures/x86_64", false)
	preset.set("custom_template/debug", _resolve_template_file("android_debug.apk"))
	preset.set("custom_template/release", _resolve_template_file("android_release.apk"))
	preset.set("version/code", 1)
	preset.set("version/name", "1.0.0")
	preset.set("package/unique_name", "com.chendong.neijiangmahjong")
	preset.set("package/name", "内江麻将")
	preset.set("package/signed", true)
	preset.set("package/app_category", 2)
	preset.set("package/show_in_android_tv", false)
	preset.set("screen/immersive_mode", true)
	preset.set("screen/edge_to_edge", false)
	preset.set("screen/support_small", true)
	preset.set("screen/support_normal", true)
	preset.set("screen/support_large", true)
	preset.set("screen/support_xlarge", true)
	preset.set("screen/background_color", Color.BLACK)
	preset.set("user_data_backup/allow", false)
	preset.set("shader_baker/enabled", false)
	preset.set("xr_features/xr_mode", 0)
	preset.set("permissions/internet", false)
	preset.set("dotnet/include_scripts_content", true)
	preset.set("dotnet/include_debug_symbols", true)
	preset.set("dotnet/embed_build_outputs", true)
	preset.set("dotnet/android_use_linux_bionic", false)

	if is_debug:
		preset.set("keystore/release", "/Users/chendong/Library/Application Support/Godot/keystores/debug.keystore")
		preset.set("keystore/release_user", "androiddebugkey")
		preset.set("keystore/release_password", "android")
	else:
		preset.set("keystore/release", OS.get_environment("GODOT_ANDROID_RELEASE_KEYSTORE"))
		preset.set("keystore/release_user", OS.get_environment("GODOT_ANDROID_RELEASE_ALIAS"))
		preset.set("keystore/release_password", OS.get_environment("GODOT_ANDROID_RELEASE_PASSWORD"))

	var output_path := OS.get_environment("GODOT_ANDROID_OUTPUT")
	if output_path == "":
		output_path = "/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/build/android/NeijiangMahjong-direct-debug.apk" if is_debug else "/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/build/android/NeijiangMahjong-release.apk"

	var result: int = platform.call("export_project", preset, is_debug, output_path, 0)
	print("export_result=", result)
	print("message_count=", platform.call("get_message_count"))
	for index in range(platform.call("get_message_count")):
		print("message[%d].type=%s" % [index, str(platform.call("get_message_type", index))])
		print("message[%d].text=%s" % [index, str(platform.call("get_message_text", index))])
	if FileAccess.file_exists(output_path):
		print("output_exists=true")
		print("output_size=", FileAccess.get_file_as_bytes(output_path).size())
		quit(0)
		return
	quit(result)
