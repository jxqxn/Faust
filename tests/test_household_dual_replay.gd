extends GutTest

var _save_path: String
var _round_root: String
var _global_path: String
var _test_root: String

## Test-only independent input, captured from the original executable.
## Fail closed on missing, extra, reordered or differently bounded draws.
class RecordedRNG extends GameRNG:
	var calls: Array = []
	var cursor := 0
	var errors: Array = []
	var observed: Array = []
	func range_int_half_open(lo: int, hi: int) -> int:
		observed.append([lo, hi])
		if cursor >= calls.size():
			errors.append("extra draw [%d,%d)" % [lo, hi])
			return lo
		var call: Dictionary = calls[cursor]
		cursor += 1
		if int(call.min) != lo or int(call.max) != hi:
			errors.append("seq %s expected [%s,%s), got [%d,%d)" % [call.seq, call.min, call.max, lo, hi])
			return lo
		var value := int(call.value)
		if value < lo or value >= hi:
			errors.append("invalid captured value")
			return lo
		return value
	func range_int(lo: int, hi: int) -> int:
		return range_int_half_open(lo, hi + 1)
	func value() -> float:
		errors.append("uncaptured floating point gameplay draw")
		return 0.0

func test_recorded_rng_rejects_invalid_replay_inputs() -> void:
	var tape := RecordedRNG.new()
	tape.calls = [{"seq": 7, "min": 0, "max": 4, "value": 2}]
	assert_eq(tape.range_int_half_open(0, 4), 2)
	assert_true(tape.errors.is_empty())
	tape.range_int_half_open(0, 4)
	assert_eq(tape.errors.size(), 1, "exhaustion must fail, never use a fresh random stream")
	tape.cursor = 0
	tape.errors.clear()
	tape.range_int_half_open(0, 5)
	assert_eq(tape.errors.size(), 1, "candidate count mismatch must fail")
	tape.cursor = 0
	tape.errors.clear()
	tape.calls[0].value = 4
	tape.range_int_half_open(0, 4)
	assert_eq(tape.errors.size(), 1, "out-of-range evidence must fail")
	tape.errors.clear()
	tape.value()
	assert_eq(tape.errors.size(), 1, "missing float evidence must fail")

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
	var tape: RecordedRNG = null
	var tape_path := evidence.path_join("gameplay-random-tape.json")
	if FileAccess.file_exists(tape_path):
		tape = RecordedRNG.new()
		tape.calls = JSON.parse_string(FileAccess.get_file_as_string(tape_path)).calls
		main.rng = tape
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
		if rite_id == 5001001 and tape == null:
			var court_ops: Array = main._rite_overlay._last_result.deferred.get("card_ops", [])
			receipt["court_card_ops"] = court_ops.duplicate(true)
			var speeches := court_ops.filter(func(op): return int(op.get("op", -1)) == 9)
			assert_false(speeches.is_empty(), "original court speech remains in card result stream")
			var rendered_speech := false
			for row in main._rite_overlay._result_ops_layer.get_children():
				if int(row.get_meta("source_card_op", -1)) == 9:
					rendered_speech = row is Label and not row.text.is_empty() and row.is_visible_in_tree()
			assert_true(rendered_speech, "real result panel renders the card speech without an extra modal")
		if main._rite_overlay._resolution_committed and rite_id == 5000001 and not household_rebuilt:
			var text_before: String = main._rite_overlay._result_surface_text.text
			assert_true(text_before.contains("没有派遣任何人治理家业"), "original no-manager branch")
			await _capture(viewport, "oracle-household-before-close")
			receipt.household_committed = SaveSystem.serialize(main.state)
			# Taped run follows the original operation trace exactly; the
			# independent untaped regression retains the mid-result restart.
			if tape == null:
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
	assert_true(household_rebuilt, "household final-close boundary reached")
	for action in receipt.actions:
		assert_false(str(action.get("prompt", "")).begins_with("pop."), "original trace has no fullscreen CardPop confirmation")
		assert_false(str(action.get("prompt", "")).begins_with("card."), "original trace has no generated-card confirmation")
		assert_false(str(action.get("prompt", "")).begins_with("rite."), "original trace has no generated-rite confirmation")
	assert_eq(main.state.round_number, int(expected.round))
	# The original trace dismisses TIME_OUT, then BACK_ROUND, before saving.
	for guide_type in ["TIME_OUT", "BACK_ROUND"]:
		assert_eq(str(main.state.begin_guide.get("type", "")), guide_type)
		var guide = main._game_screen._begin_guide_bar
		if guide != null and guide.is_visible_in_tree():
			receipt.actions.append({"close_guide": guide_type})
			await _click(viewport, guide._close)
	receipt.after = OriginalSaveImporter.diff_against_original(expected, main.state)
	if tape != null:
		receipt.random_tape = {"consumed": tape.cursor, "total": tape.calls.size(), "errors": tape.errors, "observed": tape.observed}
		assert_eq(tape.errors, [], "original random call boundaries and order")
		assert_eq(tape.cursor, tape.calls.size(), "all original gameplay draws consumed")
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
	var receipt_path := OS.get_environment("FAUST_DAY_REPLAY_RECEIPT")
	if receipt_path.is_empty():
		receipt_path = "user://clone-replay.json"
	var output := FileAccess.open(receipt_path, FileAccess.WRITE)
	output.store_string(JSON.stringify(receipt, "\t"))
