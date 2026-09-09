extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	var rng := GameRNG.new(614)
	state.setup_new_run(db, 1, rng)
	state.begin_guide = {"type": "CARD_INFO", "bind": "UI/Help"}
	var screen = preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	root.add_child(screen)
	for i in range(8):
		await process_frame
	var guide: Control = screen.get("_begin_guide_bar")
	var close: Button = guide.get_node("Default/Close")
	# A real event prompt must still intercept input ahead of the guide.
	state.queue_prompt({"id": "guide-modal-check", "text": "Modal input check"})
	screen.refresh()
	await process_frame
	await _click(close.get_global_transform_with_canvas() * Vector2(40, 40))
	_check(not state.begin_guide.is_empty(), "Close clicked through a blocking event prompt")
	_check(not state.pending_operations.is_empty(), "Guide click dismissed the unrelated prompt")
	var continue_button: Button = screen.find_child("EventPromptContinueButton", true, false)
	await _click(continue_button.get_global_transform_with_canvas() * (continue_button.size * 0.5))
	_check(state.pending_operations.is_empty(), "Event prompt did not release input")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/guide_close_before_%d.png" % DisplayServer.window_get_size().x)
	# Include the part protruding beyond Default's rectangle.
	for local_point in [Vector2(40, 40), Vector2(70, 65)]:
		state.begin_guide = {"type": "CARD_INFO", "bind": "UI/Help"}
		screen.refresh()
		await process_frame
		var point: Vector2 = close.get_global_transform_with_canvas() * local_point
		var motion := InputEventMouseMotion.new()
		motion.position = point
		root.push_input(motion, true)
		await process_frame
		print("GUIDE_HIT: ", root.gui_get_hovered_control())
		_check(root.gui_get_hovered_control() == close, "Visible close button is not the input target")
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = point
			event.pressed = pressed
			root.push_input(event, true)
			await process_frame
		_check(state.begin_guide.is_empty(), "Click did not clear the guide directive")
		_check(not guide.visible, "Guide remains visible after close")
		screen.refresh()
		_check(not guide.visible, "Refresh reopened the dismissed guide")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/guide_close_after_%d.png" % DisplayServer.window_get_size().x)
	print("GUIDE_CLOSE: ", "PASS" if failures.is_empty() else "FAIL", " window=", DisplayServer.window_get_size())
	screen.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
