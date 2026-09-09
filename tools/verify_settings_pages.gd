extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await process_frame
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = point
		root.push_input(event, true)
		await process_frame

func _run() -> void:
	var preferences = preload("res://ui/game_application_settings.gd")
	preferences.settings_path = "user://verify-settings-font.json"
	preferences._loaded = true
	preferences.font_size = "md"
	var settings := preload("res://ui/settings_panel.gd").new()
	root.add_child(settings)
	for i in range(8):
		await process_frame
	var ok := true
	var font_choice: OptionButton = settings._pages[0].get_node("Sence/FontSize/Dropdown")
	ok = ok and font_choice.item_count == 5 and not font_choice.disabled
	await _click(font_choice)
	ok = ok and font_choice.get_popup().visible
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/settings_font_popup_%d.png" % root.size.x)
	# Feed the input dispatcher so it routes keys to the popup Window.
	for key in [KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER]:
		for down in [true, false]:
			var event := InputEventKey.new()
			event.keycode = key
			event.pressed = down
			Input.parse_input_event(event)
			await process_frame
	ok = ok and preferences.font_size == "lg"
	print("FONT_SELECTION ", preferences.font_size)
	font_choice.get_popup().hide()
	for i in range(3):
		await _click(settings._tabs[i])
		for j in range(3):
			ok = ok and settings._pages[j].visible == (j == i)
		print("PAGE ", i, " ", settings._pages[i].visible)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/settings_%s_%d.png" % [["display", "keys", "other"][i], root.size.x])
	await _click(settings._tabs[1])
	var scroll: ScrollContainer = settings._pages[1].get_node("Keys")
	for i in range(5):
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		wheel.position = scroll.get_global_rect().get_center()
		root.push_input(wheel, true)
		var release := wheel.duplicate()
		release.pressed = false
		root.push_input(release, true)
		await process_frame
	ok = ok and scroll.scroll_vertical > 0
	print("SCROLL ", scroll.scroll_vertical)
	var closed := [false]
	settings.closed.connect(func(): closed[0] = true)
	await _click(settings.get_node("SettingsPanelNew/Close"))
	ok = ok and closed[0]
	print("CLOSE ", closed[0])
	print("SETTINGS_PAGES_INPUT: ", "PASS" if ok else "FAIL")
	settings.free()
	if FileAccess.file_exists(preferences.settings_path):
		DirAccess.remove_absolute(preferences.settings_path)
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if ok else 1)
