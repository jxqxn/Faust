extends SceneTree

# Uses the unmodified original household configuration and no assigned cards.
# Matches the original runtime's no-manager branch; world state is not a save replay.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preferences = preload("res://ui/game_application_settings.gd")
	preferences._loaded = true
	preferences.font_size = "lg"
	var db := ConfigDB.new()
	db.load_all()
	var rng := GameRNG.new(614)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var screen = preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view = preload("res://ui/rite_view.gd").new()
	view.setup(state, db, rng, 5000001)
	var rite = state.get_rite_instance(view._rite_uid)
	rite.start = true
	rite.life = int(db.get_rite(5000001).get("round_number", 0))
	screen.add_source_overlay(view)
	screen.set_world_scene_blocker("rite", true, false, true, true)
	for i in 12:
		await process_frame
	await _click(view._resolve_btn)
	# A click finishes typing without committing the result.
	await _click(view._result_next_button)
	var ok: bool = view._resolution_pending and view._result_text_done
	ok = ok and view._result_surface_text.get_parsed_text().contains("你没有派遣任何人治理家业")
	ok = ok and view._result_surface_text.get_parsed_text().begins_with(str(db.get_rite(5000001).text))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/rite_source_household_result_%d.png" % root.size.x)
	print("RITE_SOURCE_HOUSEHOLD_RESULT: ", "PASS" if ok else "FAIL")
	screen.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if ok else 1)

func _click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
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
