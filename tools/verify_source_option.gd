extends SceneTree

# Original event payload with GPU and real input; not an original-runtime replay.
func _initialize() -> void:
	call_deferred("_run")

func _click(button: Control) -> void:
	var point := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event, true)
		await process_frame

func _run() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var rng := GameRNG.new(901)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.pending_operations.clear()
	DeferredEffects.execute_event(db.get_event(5300102), state, db, rng)
	var screen := preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(10):
		await process_frame
	var prompt = screen._event_overlay
	var ok: bool = prompt != null and prompt._portrait.texture != null
	if ok:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/source_option_%d.png" % root.size.x)
		await _click(prompt._options_box.get_child(0))
		ok = ok and not prompt._confirm_button.disabled and not state.is_event_enabled(5300104)
		await _click(prompt._confirm_button)
		ok = ok and state.pending_operation().kind == "prompt" and not state.is_event_enabled(5300104)
		await _click(screen._event_overlay._confirm_button)
		ok = ok and state.is_event_enabled(5300104)
	print("SOURCE_OPTION_INPUT: ", "PASS" if ok else "FAIL")
	root.remove_child(screen)
	screen.free()
	FaustTheme.clear_cache()
	await process_frame
	await process_frame
	quit(0 if ok else 1)
