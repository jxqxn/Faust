extends SceneTree

# GPU/input regression fixture. Synthetic prompt isolates the verified
# Settlement promise boundary; this is not an original-runtime replay.
var screen: Control
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event, true)
		await process_frame
	await process_frame

func _run() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var rng := GameRNG.new(614)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	screen = preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view = preload("res://ui/rite_view.gd").new()
	view.setup(state, db, rng, 5000001)
	var instance = state.get_rite_instance(view._rite_uid)
	instance.start = true
	instance.life = int(db.get_rite(5000001).get("round_number", 0))
	view._rite = view._rite.duplicate(true)
	view._rite["settlement_prior"] = []
	view._rite["settlement_extre"] = []
	view._rite["settlement"] = [{"condition": {}, "result": {}, "action": {"prompt": {"id": "wait_regression", "text": "Result waiting"}}}]
	screen.add_source_overlay(view)
	screen.set_world_scene_blocker("rite", true, false, true, true)
	for i in range(12):
		await process_frame
	await _click(view._resolve_btn)
	_check(view._resolution_pending, "Visible resolve button did not open the result")
	_check(not state.pending_operations.is_empty(), "Result prompt missing")
	_check(view._resolve_btn.disabled, "Underlying confirm is enabled")
	# Probe the covered cancel location, away from the prompt's own confirm.
	await _click(view._close_btn)
	_check(state.get_rite_instance(view._rite_uid) != null, "Prompt allowed early rite removal")
	var prompt = screen.get("_event_overlay")
	_check(prompt != null and prompt.visible, "Prompt not visible")
	if prompt != null:
		_check(prompt.z_index > screen._source_overlay_layer.z_index, "Prompt renders behind rite")
		_check(prompt.mouse_filter == Control.MOUSE_FILTER_STOP, "Prompt allows background input")
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var colors := {}
		for y in range(0, image.get_height(), 32):
			for x in range(0, image.get_width(), 32):
				colors[image.get_pixel(x, y).to_rgba32()] = true
		_check(colors.size() > 20, "Rendered frame is blank")
		var output := "res://docs/ui_layout/rite_wait_%d.png" % DisplayServer.window_get_size().x
		image.save_png(output)
		await _click(prompt.get("_confirm_button"))
		_check(state.pending_operations.is_empty(), "Visible prompt continue did not complete")
		await _click(view._result_next_button)
		if state.get_rite_instance(view._rite_uid) != null:
			await _click(view._result_next_button)
		_check(state.get_rite_instance(view._rite_uid) == null, "Confirm did not finish after prompt")
	print("RITE_WAIT_INPUT: ", "PASS" if failures.is_empty() else "FAIL", " viewport=", root.size)
	root.remove_child(screen)
	screen.free()
	FaustTheme.clear_cache()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
