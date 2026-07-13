extends SceneTree

var _gut = null
var _exit_code := 0

func _init() -> void:
	call_deferred("_start")

func _start() -> void:
	await create_timer(0.0).timeout
	var gut_config = load("res://addons/gut/gut_config.gd").new()
	gut_config.load_options("res://.gutconfig.json")
	var test_path := OS.get_environment("GUT_TEST_PATH").strip_edges()
	if test_path != "":
		gut_config.options.dirs = []

	gut_config.options.should_exit = true
	_gut = load("res://addons/gut/gut.gd").new()
	_gut.end_run.connect(_on_end_run)
	get_root().add_child(_gut)
	gut_config.apply_options(_gut)
	_gut.show_orphans(true)
	_gut._ignore_pause_before_teardown = true
	_gut.add_children_to = get_root()
	if test_path != "":
		_gut.add_script(test_path)
		_gut.test_scripts(false)
		return
	_gut.test_scripts(gut_config.options.unit_test_name == "")

func _on_end_run() -> void:
	_exit_code = 1 if _gut.get_fail_count() > 0 else 0
	# Do not await while handling Gut.end_run: that signal stack keeps the test
	# runner and its cached script resources alive.  Tear down on the next idle
	# turn instead.
	call_deferred("_finish")


func _finish() -> void:
	if _gut == null:
		quit(_exit_code)
		return
	var finished_gut = _gut
	get_root().remove_child(finished_gut)
	finished_gut.free()
	_gut = null
	# Give the scene tree and renderer enough frames to release CanvasItem RIDs
	# before the process terminates.
	await process_frame
	await process_frame
	FaustTheme.clear_cache()
	await process_frame
	quit(_exit_code)
