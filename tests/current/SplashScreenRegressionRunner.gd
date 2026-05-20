extends SceneTree

const SPLASH_SCENE := preload("res://scenes/boot/SplashScreen.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var root_node := SPLASH_SCENE.instantiate()
	get_root().add_child(root_node)
	await process_frame

	_run_test("splash_displays_project_version", _test_splash_displays_project_version.bind(root_node), failures)

	root_node.queue_free()
	if failures.is_empty():
		print("SPLASH SCREEN REGRESSION OK")
		quit(0)
		return

	push_error("SPLASH SCREEN REGRESSION FAILED:\n- " + "\n- ".join(failures))
	quit(1)


func _run_test(name: String, callable: Callable, failures: Array[String]) -> void:
	var result = callable.call()
	if typeof(result) == TYPE_BOOL and bool(result):
		print("PASS %s" % name)
		return
	failures.append("%s -> %s" % [name, str(result)])


func _test_splash_displays_project_version(root_node: Node):
	var version_label := root_node.get_node_or_null("%VersionLabel") as Label
	if version_label == null:
		return "expected splash to expose VersionLabel"
	var app_version := str(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
	var expected := "版本 v%s" % app_version
	if str(version_label.text) != expected:
		return "expected splash version text %s, got %s" % [expected, version_label.text]
	if not version_label.visible:
		return "expected splash version label to be visible"
	return true
