extends GutTest

func _click(viewport: SubViewport, button: Control) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(), button, "real pointer hits source control")
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event, true)
	await wait_process_frames(2)

func test_slide_real_click_and_reload_continue_sequence_once() -> void:
	var db := ConfigDB.new()
	db.load_all()
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.handle_input_locally = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child_autofree(viewport)
		var state := GameState.new()
		var rng := GameRNG.new(12)
		OperationsSequence.start([{"slide": ["slide/1-1", "slide/1-2"]}, {"counter+990124": 1}], state, db, rng)
		assert_eq(state.pending_operation().kind, "slide")
		var screen := preload("res://ui/game_screen.gd").new()
		screen.setup(state, db, rng)
		viewport.add_child(screen)
		screen.refresh()
		await wait_process_frames(3)
		var slide = screen.get_node("SourceSlide")
		assert_eq(slide.pages.get_child_count(), 2)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var capture := OS.get_environment("FAUST_SLIDE_CAPTURE")
			if not capture.is_empty():
				viewport.get_texture().get_image().save_png(capture + str(dimensions.x) + ".png")
		assert_eq(int(state.local_counters.get(990124, 0)), 0, "following effect waits for close")
		await _click(viewport, slide.previous)
		assert_eq(int(slide.payload.index), 0, "source Prev clamps at the first page")
		await _click(viewport, slide.next)
		assert_eq(int(state.pending_operations[0].payload.index), 1)
		await _click(viewport, slide.next)
		assert_eq(int(slide.payload.index), 1, "source Next clamps at the last page")
		var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveSystem.serialize(state)))
		screen.queue_free()
		await wait_process_frames(2)

		state = GameState.new()
		SaveSystem.deserialize(saved, state, db)
		screen = preload("res://ui/game_screen.gd").new()
		screen.setup(state, db, rng)
		viewport.add_child(screen)
		screen.refresh()
		await wait_process_frames(3)
		slide = screen.get_node("SourceSlide")
		assert_eq(int(slide.payload.index), 1, "restored current page")
		await _click(viewport, slide.close_button)
		assert_true(state.pending_operations.is_empty())
		assert_eq(int(state.local_counters.get(990124, 0)), 1)
		screen.queue_free()
		await wait_process_frames(2)



func test_one_page_hides_arrows_blocks_underlying_click_and_resolves_once() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.handle_input_locally = true
	add_child_autofree(viewport)
	var underneath := Button.new()
	underneath.size = Vector2(viewport.size)
	viewport.add_child(underneath)
	var underlying_clicks := [0]
	underneath.pressed.connect(func(): underlying_clicks[0] += 1)
	var slide = preload("res://ui/source_slide.gd").new()
	viewport.add_child(slide)
	slide.setup({"images": ["slide/1-1"], "index": 0, "position": 0.0}, db)
	await wait_process_frames(2)
	assert_false(slide.previous.visible)
	assert_false(slide.next.visible)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(20, 20)
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	var hit := viewport.gui_get_hovered_control()
	assert_true(hit == slide or slide.is_ancestor_of(hit), "real pointer hits the source panel hierarchy, not the underlying button")
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event, true)
	await wait_process_frames(2)
	assert_eq(underlying_clicks[0], 0)
	var completions := [0]
	slide.closed.connect(func(): completions[0] += 1)
	await _click(viewport, slide.close_button)
	assert_false(slide.visible)
	assert_eq(completions[0], 1)
	slide._close() # Auxiliary reentrancy check, after actual mouse acceptance.
	assert_eq(completions[0], 1)
