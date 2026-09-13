## Independent-process companion to test_next_day_resume.gd.
## Run start, night 2, day 2, night 3, day 3, stable 3 with the SAME isolated
## directory. This checks scheduler/UI persistence, not original content parity.
extends SceneTree

var main: Control
var viewport: SubViewport
var fixture_root: String
var failures := 0
var checks := 0

func _init() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("RESTART FAIL: " + message)
	return value

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		printerr("Expected: isolated-directory phase expected-round")
		quit(2)
		return
	fixture_root = args[0]
	var phase := args[1]
	var expected_round := int(args[2])
	# Never fall back to the player's normal paths, even with bad arguments.
	if fixture_root.is_empty() or not fixture_root.get_file().begins_with("faust-day-restart-"):
		printerr("Expected a dedicated faust-day-restart-* fixture directory")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(fixture_root)
	SaveSystem.use_save_path(fixture_root.path_join("save.json"))
	SaveSystem.use_round_save_root(fixture_root)
	GlobalState.use_global_path(fixture_root.path_join("global.json"))
	viewport = SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	if phase == "start":
		check(not FileAccess.file_exists(SaveSystem.save_path()), "start cannot overwrite an existing fixture")
		if failures == 0:
			main.state = GameState.new()
			main.state.setup_new_run(main.db, 1, main.rng)
			main.state.pending_operations.clear()
			main.state.rite_instances.clear()
			for event_id in main.db.events:
				main.state.disable_event(int(event_id))
			main.state.auto_gen_sudan_card = false
			main._show_game()
			await process_frame
			await process_frame
			check(main.state.round_number == expected_round, "initial round")
			await _click_next_day()
			await _save_boundary("night_enter", expected_round)
	else:
		var boundary: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixture_root.path_join("boundary.json")))
		main._on_continue()
		if check(main.state != null, "fresh process loads disk save"):
			check(main.state.round_number == int(boundary.round), "round survives process termination")
			check(main.state.round_transition == boundary.transition, "all transition fields restored before ticking")
			await process_frame
			await process_frame
			if phase == "night":
				check(str(main.state.round_transition.get("phase", "")) == "night_enter", "resume night gate")
				check(main._game_screen._presentation_blockers.has("day_animation"), "restored night input lock")
				await _wait_phase("day_enter")
				await _save_boundary("day_enter", expected_round)
			elif phase == "day":
				check(str(main.state.round_transition.get("phase", "")) == "day_enter", "resume day gate")
				check(main._game_screen._presentation_blockers.has("day_animation"), "restored day input lock")
				await _wait_phase("")
				check(main.state.round_number == expected_round, "day gate never increments twice")
				check(not main._game_screen._presentation_blockers.has("day_animation"), "day lock released")
				if expected_round < 3:
					await _click_next_day()
					await _save_boundary("night_enter", expected_round)
				else:
					await _save_boundary("", expected_round)
			elif phase == "stable":
				check(main.state.round_number == expected_round, "stable round restored")
				check(main.state.round_transition.is_empty(), "stable transition stays empty")
				var button: Button = main._game_screen.get_node("RightActions/AdvanceDayButton/NextDayTextButton")
				check(button.is_visible_in_tree() and not button.disabled, "stable next day visible and enabled")
			else:
				check(false, "unknown replay phase")
	print("PROCESS_RESTART phase=%s round=%d checks=%d failures=%d pid=%d" % [phase, expected_round, checks, failures, OS.get_process_id()])
	viewport.queue_free()
	main = null
	viewport = null
	await process_frame
	await process_frame
	FaustTheme.clear_cache()
	await process_frame
	quit(1 if failures > 0 else 0)

func _click_next_day() -> void:
	var button: Button = main._game_screen.get_node("RightActions/AdvanceDayButton/NextDayTextButton")
	check(button.is_visible_in_tree() and not button.disabled, "next day accepts input")
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await process_frame
	check(viewport.gui_get_hovered_control() == button, "real mouse hits the text button")
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = motion.position
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		viewport.push_input(click, true)
	await process_frame
	check(str(main.state.round_transition.get("phase", "")) == "night_enter", "real click starts night before settlement")

func _wait_phase(phase: String) -> void:
	var deadline := Time.get_ticks_msec() + 20000
	while str(main.state.round_transition.get("phase", "")) != phase and Time.get_ticks_msec() < deadline:
		await process_frame
	check(str(main.state.round_transition.get("phase", "")) == phase, "phase reaches " + phase)

func _save_boundary(phase: String, expected_round: int) -> void:
	# Test sampling interval, not an authored animation parameter.
	await create_timer(0.25).timeout
	check(str(main.state.round_transition.get("phase", "")) == phase, "save is inside expected phase")
	check(main.state.round_number == expected_round, "round at save boundary")
	if failures != 0:
		return
	check(SaveSystem.save(main.state), "write player save")
	var f := FileAccess.open(fixture_root.path_join("boundary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"round": main.state.round_number, "transition": main.state.round_transition}))
	f.close()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(viewport.get_texture().get_image().save_png(fixture_root.path_join("round-%d-%s.png" % [expected_round, phase])) == OK, "capture rendered boundary")
