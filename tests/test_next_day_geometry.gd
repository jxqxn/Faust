extends GutTest

func test_next_day_text_source_geometry_and_viewport_input() -> void:
	var screen = preload("res://ui/game_screen.gd").new()
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	var rng := preload("res://core/rng.gd").new(17)
	state.setup_new_run(db, 1, rng)
	while not state.pending_operation().is_empty():
		state.consume_pending_operation()
	screen.setup(state, db, rng)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(viewport)
	viewport.add_child(screen)
	await wait_process_frames(3)
	var actions: Control = screen.get_node("RightActions")
	var button: Button = actions.get_node("AdvanceDayButton")
	var text_button: Button = button.get_node("NextDayTextButton")
	var normal: TextureRect = text_button.get_node("Normal")
	var hover: TextureRect = text_button.get_node("Hover")
	assert_almost_eq(actions.position.y, screen.size.y - 634 * actions.scale.y, 0.01)
	assert_almost_eq(normal.get_global_rect().get_center().x, screen.size.x - 240.5 * actions.scale.x, 0.01)
	assert_almost_eq(normal.get_global_rect().get_center().y, screen.size.y - 275 * actions.scale.y, 0.01)
	assert_almost_eq(normal.size.x, 486.4, 0.01)
	assert_null(screen.get_node_or_null("NextDayLabel"), "no duplicate clone text node")
	watch_signals(screen)
	var motion := InputEventMouseMotion.new()
	motion.position = text_button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await wait_process_frames(2)
	assert_eq(viewport.gui_get_hovered_control(), text_button)
	assert_false(normal.visible)
	assert_true(hover.visible)
	var click := InputEventMouseButton.new()
	click.position = motion.position
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	viewport.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	viewport.push_input(click, true)
	await wait_process_frames(2)
	assert_signal_emit_count(screen, "advance_pressed", 1)
	state.round_transition = {"phase": "rites", "due_rites": []}
	screen.refresh()
	assert_true(button.visible, "the watch plate survives the transition")
	assert_false(text_button.visible, "only source GO45 is hidden")
	state.round_transition.clear()
	screen.refresh()
	assert_true(button.visible, "settled state restores the button without rebuilding the scene")
	motion = InputEventMouseMotion.new()
	motion.position = Vector2(10, 10)
	viewport.push_input(motion, true)
	await wait_process_frames(2)
	assert_true(normal.visible)
	assert_false(hover.visible)
	if OS.get_environment("FAUST_NEXT_DAY_CAPTURE") != "":
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(OS.get_environment("FAUST_NEXT_DAY_CAPTURE"))
	screen.set_world_scene_blocker("test", true)
	assert_true(text_button.disabled)
	assert_eq(text_button.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	screen.set_world_scene_blocker("test", false)
	assert_false(text_button.disabled)
	viewport.size = Vector2i(1280, 720)
	await wait_process_frames(3)
	assert_almost_eq(normal.get_global_rect().get_center().x, 1199.833333, 0.01)
	assert_almost_eq(normal.get_global_rect().get_center().y, 628.333333, 0.01)
	screen.play_next_day_transition()
	assert_false(text_button.is_visible_in_tree())
	# A hidden clock must not remain a rectangular _unhandled_input target.
	motion.position = text_button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	click.position = motion.position
	click.pressed = true
	viewport.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	viewport.push_input(click, true)
	await wait_process_frames(2)
	assert_signal_emit_count(screen, "advance_pressed", 1)
