extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preferences = preload("res://ui/game_application_settings.gd")
	preferences._loaded = true
	preferences.font_size = "lg"
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	var rng := GameRNG.new(614)
	state.setup_new_run(db, 1, rng)
	var screen = preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var uid := int(state.hand[0])
	screen.show_card_detail(uid)
	var view: CardInfoView = screen._card_info_view
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/card_info_normal_%d.png" % root.size.x)
	var ok := view._panel.scale.is_equal_approx(Vector2(1.1, 1.1))
	var badges := view.find_children("Icon", "TextureRect", true, false)
	for badge in badges:
		ok = ok and badge.texture != null
	ok = ok and badges.size() == 6
	await _click(view.find_child("CardInfoHelpButton", true, false))
	print("Help opened: ", view._help_overlay != null)
	ok = ok and view._help_overlay != null
	if view._help_overlay != null:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/card_info_help_%d.png" % root.size.x)
		await _click_at(Vector2(root.size) * Vector2(0.1, 0.1))
		print("Help dismissed: ", view._help_overlay == null)
		ok = ok and view._help_overlay == null
	var closed := [false]
	view.closed.connect(func(): closed[0] = true)
	await _click(view.find_child("CloseCardDetailButton", true, false))
	print("Detail closed: ", closed[0])
	ok = ok and closed[0]
	print("CARD_INFO_NORMAL: ", "PASS" if ok else "FAIL", " badges=", badges.size())
	screen.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if ok else 1)


func _click(control: Control) -> void:
	await _click_at(control.get_global_transform_with_canvas() * (control.size * 0.5))


func _click_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await process_frame
	print("Click ", point, " hover=", root.gui_get_hovered_control())
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	for i in range(3):
		await process_frame
