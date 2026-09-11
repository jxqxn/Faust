extends SceneTree

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
	screen.add_source_overlay(view)
	screen.set_world_scene_blocker("rite", true, false, true, true)
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var desc: RichTextLabel = view.find_child("RiteMainContent", true, false)
	print("BODY_HEIGHT: ", desc.size.y, " content=", desc.get_content_height())
	root.get_texture().get_image().save_png("res://docs/ui_layout/rite_description_%d.png" % DisplayServer.window_get_size().x)
	var scroll: ScrollContainer = view.find_child("RiteDescriptionScroll", true, false)
	var ok := scroll.get_v_scroll_bar().max_value > scroll.size.y
	var point := scroll.get_global_rect().get_center()
	for i in range(6):
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = point
			event.button_index = MOUSE_BUTTON_WHEEL_DOWN
			event.pressed = pressed
			root.push_input(event, true)
			await process_frame
	ok = ok and scroll.scroll_vertical > 0
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/rite_description_scrolled_%d.png" % DisplayServer.window_get_size().x)
	await _click(view.find_child("RiteHelpButton", true, false))
	var help: Control = view._source_canvas.get_node_or_null("RiteHelp")
	ok = ok and help != null
	if help != null:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/rite_help_%d.png" % root.size.x)
		await _click_at(Vector2(1900, 1000))
		ok = ok and view._source_canvas.get_node_or_null("RiteHelp") == null
	print("RITE_DESCRIPTION: ", "PASS" if ok else "FAIL", " scroll=", scroll.scroll_vertical)
	screen.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if ok else 1)


func _click(control: Control) -> void:
	await _click_at(control.get_global_rect().get_center())


func _click_at(point: Vector2) -> void:
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
