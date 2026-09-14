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

## External oracle: original executable, real mouse input, round 4 -> 5.
## FAUST_HOUSEHOLD_ORACLE must contain original-before.json/original-after.json.
## Never import the expected after-state into the running controller.
func test_household_original_runtime_oracle() -> void:
	var evidence := OS.get_environment("FAUST_HOUSEHOLD_ORACLE")
	if evidence.is_empty():
		pending("Requires captured original runtime before/after oracle")
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(viewport)
	var main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("original-before.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("original-after.json")))
	var imported := OriginalSaveImporter.import_save(before, main.db)
	main.state = imported.state
	main.state.global_state = GlobalState.load_default()
	main._show_game()
	await wait_process_frames(3)
	var receipt := {"before": imported.report, "actions": [], "phases": []}
	for row in imported.report.diff:
		assert_true(row.pass, "initial oracle import: " + row.check)
	await _capture(viewport, "oracle-before")
	await _click(viewport, main._game_screen.get_node("RightActions/AdvanceDayButton/NextDayTextButton"))
	var deadline := Time.get_ticks_msec() + 120000
	var household_rebuilt := false
	var closed: Array = []
	while Time.get_ticks_msec() < deadline and not main.state.round_transition.is_empty():
		await wait_process_frames(2)
		var phase: String = str(main.state.round_transition.get("phase", ""))
		if not receipt.phases.has(phase):
			receipt.phases.append(phase)
		if not main.state.pending_operations.is_empty():
			if main._game_screen._event_overlay == null:
				continue
			var confirm = main._game_screen._event_overlay._confirm_button
			if confirm != null and confirm.is_visible_in_tree() and not confirm.disabled:
				receipt.actions.append({"prompt": str(main.state.pending_operation().id)})
				await _click(viewport, confirm)
			continue
		if main._rite_overlay == null:
			continue
		var button: Button = main._rite_overlay._result_next_button
		if not button.is_visible_in_tree() or button.disabled:
			continue
		var uid: int = main._rite_overlay._rite_uid
		var rite_id: int = main._rite_overlay._rite_id
		# Match the original trace: wait for automatic text/settlement, then
		# click the final close once. Repeated Next clicks race the commit.
		if not main._rite_overlay._resolution_committed:
			continue
		if main._rite_overlay._resolution_committed and rite_id == 5000001 and not household_rebuilt:
			var text_before: String = main._rite_overlay._result_surface_text.text
			assert_true(text_before.contains("没有派遣任何人治理家业"), "original no-manager branch")
			await _capture(viewport, "oracle-household-before-close")
			receipt.household_committed = SaveSystem.serialize(main.state)
			main = await _restart_from_disk(main, viewport)
			assert_eq(main._rite_overlay._result_surface_text.text, text_before)
			household_rebuilt = true
			continue
		receipt.actions.append({"rite": rite_id, "uid": uid, "committed": main._rite_overlay._resolution_committed})
		await _click(viewport, button)
		if main._rite_overlay == null or int(main._rite_overlay._rite_uid) != uid:
			closed.append(rite_id)
	assert_true(main.state.round_transition.is_empty(), "transition completes")
	assert_eq(closed, [5001001, 5000001], "same original final-close order")
	assert_true(household_rebuilt, "disk rebuild before household final close")
	assert_eq(main.state.round_number, int(expected.round))
	# The original trace dismisses TIME_OUT, then BACK_ROUND, before saving.
	for guide_type in ["TIME_OUT", "BACK_ROUND"]:
		assert_eq(str(main.state.begin_guide.get("type", "")), guide_type)
		var guide = main._game_screen._begin_guide_bar
		if guide != null and guide.is_visible_in_tree():
			receipt.actions.append({"close_guide": guide_type})
			await _click(viewport, guide._close)
	receipt.after = OriginalSaveImporter.diff_against_original(expected, main.state)
	receipt.clone_after = SaveSystem.serialize(main.state)
	for row in receipt.after:
		assert_true(row.pass, "after runtime transition: " + row.check)
	await _capture(viewport, "oracle-after")
	main = await _restart_from_disk(main, viewport)
	receipt.reloaded = OriginalSaveImporter.diff_against_original(expected, main.state)
	for row in receipt.reloaded:
		assert_true(row.pass, "after disk reload: " + row.check)
	assert_null(main._rite_overlay)
	assert_true(main.state.round_transition.is_empty())
	await _capture(viewport, "oracle-reloaded")
	var output := FileAccess.open(evidence.path_join("clone-replay.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(receipt, "\t"))
