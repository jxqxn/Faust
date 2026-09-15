extends GutTest

var _save_path: String
var _round_root: String
var _global_path: String
var _test_root: String

func before_each() -> void:
	_save_path = SaveSystem.save_path_override
	_round_root = SaveSystem.round_save_root_override
	_global_path = GlobalState.global_path_override
	_test_root = "user://next_day_resume_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_test_root)
	SaveSystem.use_save_path(_test_root.path_join("save.json"))
	SaveSystem.use_round_save_root(_test_root)
	GlobalState.use_global_path(_test_root.path_join("global.json"))

func after_each() -> void:
	SaveSystem.use_save_path(_save_path)
	SaveSystem.use_round_save_root(_round_root)
	GlobalState.use_global_path(_global_path)
	for filename in DirAccess.get_files_at(_test_root):
		DirAccess.remove_absolute(_test_root.path_join(filename))
	DirAccess.remove_absolute(_test_root)

func _restart_from_disk(main: Control, viewport: SubViewport) -> Control:
	assert_true(SaveSystem.save(main.state), "write the actual player save")
	main.queue_free()
	await wait_process_frames(2)
	var rebuilt = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(rebuilt)
	rebuilt._on_continue()
	await wait_process_frames(2)
	assert_not_null(rebuilt.state, "continue loads disk into an entirely new controller")
	return rebuilt

func _click(viewport: SubViewport, button: Button) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(), button, "real input hits " + button.name)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event, true)
	await wait_process_frames(2)

func _capture(viewport: SubViewport, label: String) -> void:
	var prefix := OS.get_environment("FAUST_DAY_REPLAY_CAPTURE")
	if prefix.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	assert_eq(viewport.get_texture().get_image().save_png(prefix + label + ".png"), OK)

func test_original_save_continuous_days_and_pending_settlement_disk_rebuild() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(viewport)
	var main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"))
	var imported := OriginalSaveImporter.import_save(original, main.db)
	main.state = imported.state
	main.state.global_state = GlobalState.load_default()
	main._show_game()
	await wait_process_frames(3)
	var first_round: int = main.state.round_number
	for expected_round in [first_round+1, first_round+2]:
		await _click(viewport, main._game_screen.get_node("RightActions/AdvanceDayButton/NextDayTextButton"))
		assert_eq(str(main.state.round_transition.get("phase", "")), "night_enter")
		var rebuilt_pending := false
		var rebuilt_prompt := false
		var rebuilt_final := false
		var saw_day := false
		var settled_uids := {}
		var deadline := Time.get_ticks_msec() + 90000
		while Time.get_ticks_msec() < deadline and not main.state.round_transition.is_empty():
			await wait_process_frames(2)
			var phase := str(main.state.round_transition.get("phase", ""))
			if phase == "day_enter" and not saw_day:
				await _capture(viewport, "day-%d-enter" % expected_round)
			saw_day = saw_day or phase == "day_enter"
			# Nested operation prompts sit above the rite and must resolve first.
			if not main.state.pending_operations.is_empty():
				if not rebuilt_prompt:
					var pending_id := str(main.state.pending_operation().id)
					main = await _restart_from_disk(main, viewport)
					assert_eq(str(main.state.pending_operation().id), pending_id, "nested prompt survives disk rebuild")
					await _capture(viewport, "day-%d-restored-prompt" % expected_round)
					rebuilt_prompt = true
					continue
				if main._game_screen._event_overlay == null:
					continue
				var confirm = main._game_screen._event_overlay._confirm_button
				if confirm != null and confirm.is_visible_in_tree() and not confirm.disabled:
					await _click(viewport, confirm)
				continue
			if main._rite_overlay != null:
				if main._rite_overlay._result_surface.is_visible_in_tree() and not rebuilt_pending:
					main = await _restart_from_disk(main, viewport)
					rebuilt_pending = true
					continue
				if not main._rite_overlay._result_auto_play and main._rite_overlay._result_auto_button.is_visible_in_tree():
					await _click(viewport, main._rite_overlay._result_auto_button)
					continue
				var button: Button = main._rite_overlay._result_next_button
				if button.is_visible_in_tree() and not button.disabled:
					if main._rite_overlay._resolution_committed and not rebuilt_final:
						var notes: Array = main.state.notes.duplicate(true)
						var counters: Dictionary = main.state.local_counters.duplicate(true)
						var source_text: String = str(main._rite_overlay._result_surface_text.get_meta("source_markup", ""))
						var rendered_text: String = main._rite_overlay._result_surface_text.text
						main = await _restart_from_disk(main, viewport)
						assert_eq(main.state.notes, notes, "loading a completed result does not repeat note writes")
						assert_eq(main.state.local_counters.size(), counters.size())
						for counter_id in counters:
							assert_eq(main.state.get_counter(int(counter_id)), int(counters[counter_id]), "loaded counter %s does not repeat rewards" % counter_id)
						assert_not_null(main._rite_overlay, "completed result still awaits its final close")
						assert_eq(str(main._rite_overlay._result_surface_text.get_meta("source_markup", "")), source_text, "source markup survives result reconstruction for later font changes")
						assert_eq(main._rite_overlay._result_surface_text.text, rendered_text, "restored result retains the displayed paragraphs")
						assert_false(main._rite_overlay._rite_panel.visible, "preparation does not show beneath restored results")
						assert_false(main._rite_overlay._slot_layer.visible)
						assert_false(main._rite_overlay._template_backdrop.visible)
						await _capture(viewport, "day-%d-restored-result" % expected_round)
						rebuilt_final = true
						continue
					var rite_uid_before := int(main._rite_overlay._rite_uid)
					await _click(viewport, button)
					# The source Next button may receive several clicks per result:
					# first finishes typewriter text, then advances paragraphs, then
					# commits. Count the actual result UID once its panel closes or
					# the next source prompt replaces it; notes are written before
					# this final confirmation and cannot identify the UI transition.
					if main._rite_overlay == null or int(main._rite_overlay._rite_uid) != rite_uid_before:
						settled_uids[rite_uid_before] = true
		assert_true(main.state.round_transition.is_empty(), "day completes: %s pending=%s" % [main.state.round_transition.get("phase", ""), main.state.pending_operations.map(func(op): return op.id)])
		assert_eq(main.state.round_number, expected_round)
		assert_true(saw_day, "day entry occurs after settlements")
		assert_true(rebuilt_pending, "rebuild while a real source rite is pending")
		# A source random branch may contain no interactive operation.
		# Mandatory nested-queue coverage is the explicit fixture below;
		# any prompt encountered here still gets the real disk/input checks.
		assert_true(rebuilt_final, "rebuild after effects finish but before final confirmation")
		assert_eq(settled_uids.size(), 2, "both source auto rites retain their final confirmation, including after rebuild")
		if not main.state.round_transition.is_empty():
			return
		main = await _restart_from_disk(main, viewport)
		assert_eq(main.state.round_number, expected_round)
		assert_true(main._game_screen.get_node("RightActions/AdvanceDayButton/NextDayTextButton").is_visible_in_tree())
		await _capture(viewport, "day-%d-ready" % expected_round)

func test_nested_queue_disk_rebuild_and_real_confirmation() -> void:
	# Isolated persistence fixture, not original outcome evidence. Do not
	# depend on a random court branch producing an extra (incorrect) modal.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.handle_input_locally = true
	add_child_autofree(viewport)
	var main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	main.state = GameState.new()
	OperationsSequence.start([{
		"counter+990001": 1,
		"all": {"prompt": {"id": "resume_fixture", "text": "Continue nested operation"}, "counter+990002": 4},
		"counter+990003": 8,
	}], main.state, main.db, main.rng)
	main._show_game()
	await wait_process_frames(3)
	assert_eq(main.state.get_counter(990001), 1)
	assert_eq(main.state.get_counter(990002), 0)
	main = await _restart_from_disk(main, viewport)
	assert_eq(str(main.state.pending_operation().id), "resume_fixture")
	assert_not_null(main._game_screen._event_overlay)
	await _click(viewport, main._game_screen._event_overlay._confirm_button)
	assert_true(main.state.pending_operations.is_empty())
	assert_eq(main.state.get_counter(990001), 1, "executed prefix must not repeat")
	assert_eq(main.state.get_counter(990002), 4, "nested continuation runs once")
	assert_eq(main.state.get_counter(990003), 8, "parent resumes after child")
	main = await _restart_from_disk(main, viewport)
	assert_true(main.state.pending_operations.is_empty())
	assert_eq(main.state.get_counter(990002), 4)
	assert_eq(main.state.get_counter(990003), 8)

func test_continuous_rounds_rebuild_mid_night_and_day_without_double_advance() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	viewport.handle_input_locally = true
	add_child_autofree(viewport)
	var main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	# Isolated scheduler boundary fixture, not a source opening walkthrough.
	main.state = GameState.new()
	main.state.setup_new_run(main.db,1,main.rng)
	main.state.pending_operations.clear()
	main.state.rite_instances.clear()
	# Disable events through persisted state, rather than deleting the runtime
	# (load legitimately rebuilds it). Full source-content replay is separate.
	for event_id in main.db.events:
		main.state.disable_event(int(event_id))
	main.state.auto_gen_sudan_card = false
	main._show_game()
	await wait_process_frames(3)
	for expected_round in [2,3]:
		var target: Button = main._game_screen.get_node("RightActions/AdvanceDayButton/NextDayTextButton")
		assert_false(target.disabled)
		var motion := InputEventMouseMotion.new()
		motion.position = target.get_global_rect().get_center()
		viewport.push_input(motion,true)
		await wait_process_frames(1)
		assert_eq(viewport.gui_get_hovered_control(),target)
		for pressed in [true,false]:
			var click := InputEventMouseButton.new()
			click.position = motion.position
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			viewport.push_input(click,true)
		await wait_seconds(0.2)
		assert_eq(str(main.state.round_transition.phase),"night_enter")
		assert_eq(main.state.round_number,expected_round-1)
		var before: float = main.state.round_transition.animation.night_time
		main = await _restart_from_disk(main, viewport)
		assert_gte(float(main.state.round_transition.animation.night_time),before)
		assert_true(main._game_screen._presentation_blockers.has("day_animation"))
		var deadline := Time.get_ticks_msec()+12000
		while str(main.state.round_transition.get("phase","")) != "day_enter" and Time.get_ticks_msec()<deadline:
			await wait_process_frames(1)
		assert_eq(str(main.state.round_transition.get("phase","")),"day_enter")
		assert_eq(main.state.round_number,expected_round)
		main = await _restart_from_disk(main, viewport)
		deadline = Time.get_ticks_msec()+15000
		while not main.state.round_transition.is_empty() and Time.get_ticks_msec()<deadline:
			await wait_process_frames(1)
		assert_true(main.state.round_transition.is_empty())
		assert_eq(main.state.round_number,expected_round)
		assert_false(main._game_screen._presentation_blockers.has("day_animation"))
		assert_true(main._game_screen.get_node("RightActions/AdvanceDayButton").is_visible_in_tree())
