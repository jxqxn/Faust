extends SceneTree

var _gut = null

func _init() -> void:
	call_deferred("_start")

func _start() -> void:
	await create_timer(0.0).timeout
	var gut_config = load("res://addons/gut/gut_config.gd").new()
	gut_config.load_options("res://.gutconfig.json")

	gut_config.options.should_exit = true
	_gut = load("res://addons/gut/gut.gd").new()
	_gut.end_run.connect(_on_end_run)
	get_root().add_child(_gut)
	gut_config.apply_options(_gut)
	_gut._ignore_pause_before_teardown = true
	_gut.add_children_to = get_root()
	_gut.test_scripts(gut_config.options.unit_test_name == "")

func _on_end_run() -> void:
	var exit_code := 1 if _gut.get_fail_count() > 0 else 0
	_gut.queue_free()
	await create_timer(0.1).timeout
	quit(exit_code)
