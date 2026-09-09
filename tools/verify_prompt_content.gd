extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var prefs = preload("res://ui/game_application_settings.gd")
	prefs._loaded = true
	prefs.font_size = "lg"
	var db := ConfigDB.new()
	db.load_all()
	var rng := GameRNG.new(614)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	state.queue_choice_prompt({"继续阅读": {}, "稍后再说": {}}, "", "<b>长正文滚动验证</b> 3 > 2\n".repeat(70))
	var screen = preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	root.add_child(screen)
	for i in range(12):
		await process_frame
	var body: RichTextLabel = screen.find_child("EventPromptBody", true, false)
	var choice: Button = screen.find_child("EventPromptChoiceButton", true, false)
	var confirm: Button = screen.find_child("EventPromptConfirmButton", true, false)
	var ok := body != null and choice != null and confirm != null
	if not ok:
		quit(1)
		return
	ok = confirm.disabled and body.size.y == 1100.0
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/prompt_long_%d.png" % DisplayServer.window_get_size().x)
	var point := body.get_global_transform_with_canvas() * (body.size * 0.5)
	for i in range(6):
		await _mouse(point, MOUSE_BUTTON_WHEEL_DOWN)
	ok = ok and body.get_v_scroll_bar().value > 0.0
	await _mouse(choice.get_global_transform_with_canvas() * (choice.size * 0.5), MOUSE_BUTTON_LEFT)
	ok = ok and not confirm.disabled and not state.pending_operations.is_empty()
	await _mouse(confirm.get_global_transform_with_canvas() * (confirm.size * 0.5), MOUSE_BUTTON_LEFT)
	for i in range(4):
		await process_frame
	ok = ok and state.pending_operations.is_empty()
	# Real source configuration also crosses selection -> branch prompt -> event_on.
	DeferredEffects.execute_event(db.get_event(5300102), state, db, rng)
	screen.refresh()
	for i in range(6):
		await process_frame
	var group: Control = screen.find_child("OptionGroup", true, false)
	confirm = screen.find_child("EventPromptConfirmButton", true, false)
	ok = ok and confirm.disabled
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/prompt_source_5300102_%d.png" % DisplayServer.window_get_size().x)
	for index in range(2):
		var row: Button = group.get_child(index)
		await _mouse(row.get_global_transform_with_canvas() * (row.size * 0.5), MOUSE_BUTTON_LEFT)
	ok = ok and not state.is_event_enabled(5300174)
	await _mouse(confirm.get_global_transform_with_canvas() * (confirm.size * 0.5), MOUSE_BUTTON_LEFT)
	ok = ok and str(state.pending_operation().get("payload", {}).get("id", "")) == "5300102_prompt_2"
	ok = ok and not state.is_event_enabled(5300174)
	var cont: Button = screen.find_child("EventPromptContinueButton", true, false)
	await _mouse(cont.get_global_transform_with_canvas() * (cont.size * 0.5), MOUSE_BUTTON_LEFT)
	ok = ok and state.is_event_enabled(5300174)
	state.queue_prompt({"id": "icon-groups", "text": "人物与卡牌组合", "icon": ["cards/2000001", [2000001, 2000001], "common/introduction"]})
	screen.refresh()
	for i in range(6):
		await process_frame
	var slot: Control = screen.find_child("PromptIconSlot2", true, false)
	ok = ok and slot.get_child_count() == 3
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/prompt_icon_groups_%d.png" % DisplayServer.window_get_size().x)
	cont = screen.find_child("EventPromptContinueButton", true, false)
	await _mouse(cont.get_global_transform_with_canvas() * (cont.size * 0.5), MOUSE_BUTTON_LEFT)
	var confirm_data: Dictionary = db.get_event(5300000).settlement[0].action.confirm
	DeferredEffects.apply(ResultExec.execute({"confirm": confirm_data}, state, db, {}), state, db, rng)
	screen.refresh()
	for i in range(6):
		await process_frame
	group = screen.find_child("OptionGroup", true, false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/prompt_confirm_%d.png" % DisplayServer.window_get_size().x)
	var cancel: Button = group.get_child(1)
	await _mouse(cancel.get_global_transform_with_canvas() * (cancel.size * 0.5), MOUSE_BUTTON_LEFT)
	ok = ok and state.pending_operations.is_empty()
	print("PROMPT_CONTENT: ", "PASS" if ok else "FAIL")
	screen.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if ok else 1)

func _mouse(point: Vector2, button: MouseButton) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = button
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
