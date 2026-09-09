extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _click(control: Control) -> void:
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await process_frame
	_check(root.gui_get_hovered_control() == control, "Wrong input target for " + control.name)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var db := ConfigDB.new()
	db.load_all()
	var rng := GameRNG.new(201)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	state.begin_guide = {}
	main.state = state
	main.call("_show_game")
	for i in range(10):
		await process_frame
	var screen = main.get("_game_screen")
	var card = state.get_card_instance(state.active_sudan_cards[0].card_uid)
	var lifetime := int(db.get_card(card.card_id).card_vanishing)
	for remaining in [7, 6, 3, 2, 1]:
		card.life = lifetime - remaining
		screen.refresh()
		for i in range(3):
			await process_frame
		_check(screen._deadline_number.text == "%d/%d" % [remaining, state.sudan_card_init_life], "Deadline must count down remaining life")
		_check(screen._deadline_track.get_child_count() == 1 + 6 * remaining, "Source countdown sprite token count")
		_check(screen._deadline_strip.size.y == 204, "Source header height must stay fixed")
		_check(screen._deadline_number.atlas_path.ends_with("number_6_red.png") == (remaining < 3), "Danger digits must use the red atlas")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/desktop_header_%d_day%d.png" % [DisplayServer.window_get_size().x, remaining])
	var pulse_before: Vector2 = screen._deadline_title.scale
	await create_timer(0.15).timeout
	_check(not screen._deadline_title.scale.is_equal_approx(pulse_before), "Last-day title must animate")
	card.life = lifetime - 7
	var older = state.create_card_instance(card.card_id, db, "slot")
	older.life = lifetime - 2
	var rite_uid: int = state.rite_instances.keys()[0]
	older.rite_uid = rite_uid
	older.slot_key = "s1"
	state.sudan_card_init_life = 10
	screen.refresh()
	_check(screen._deadline_number.text == "2/10", "Slotted oldest Sudan and player denominator must drive deadline")
	_check(screen._deadline_title.scale == Vector2.ONE, "Leaving last day must reset animation")
	state.deadline_unshow = true
	screen.refresh()
	_check(not screen._deadline_strip.visible, "Hidden deadline must not render")
	state.deadline_unshow = false
	older.zone = "removed"
	card.zone = "removed"
	state.active_sudan_cards.clear()
	screen.refresh()
	_check(not screen._deadline_strip.visible, "No Sudan card must hide deadline")
	var menu: Button = screen.find_child("MenuButton", true, false)
	await _click(menu)
	_check(main.get("_menu_overlay") != null, "Menu click did not open the game menu")
	var overlay: Control = main.get("_menu_overlay")
	if overlay != null:
		var back: Button = overlay.find_child("Return", true, false)
		_check(back != null, "Menu return button missing")
		if back != null:
			await _click(back)
			_check(main.get("_menu_overlay") == null, "Menu did not close")
	state.helpbtn_unshow = false
	screen.refresh()
	await process_frame
	await _click(screen.find_child("MainHelpTrigger", true, false))
	_check(screen.get("_main_help_view") != null, "Help click did not open overlay")
	print("DESKTOP_HEADER: ", "PASS" if failures.is_empty() else "FAIL")
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
