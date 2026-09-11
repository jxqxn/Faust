extends SceneTree

# Isolated playable fixture: no continue/save-slot writes. --interactive keeps
# the real Game host open for Computer Use; default probes menu click routes.
var main: Control
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func settle() -> void:
	for i in range(8):
		await process_frame

func click_control(control: Control) -> void:
	var point := control.get_global_transform_with_canvas() * (control.size / 2)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var state := GameState.new()
	state.setup_new_run(main.db, 1, GameRNG.new(201))
	state.begin_guide = {}
	main.state = state
	main._show_game()
	await settle()
	main._show_game_menu()
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/esc_checked_%d.png" % root.size.x)
	if OS.get_cmdline_user_args().has("--interactive"):
		return
	await click_control(main._menu_overlay.get_node("ESCPanel/ButtonGroup/Settings"))
	if main._settings_overlay == null:
		failures.append("Settings button did not open settings")
	else:
		await click_control(main._settings_overlay.get_node("SettingsPanelNew/Close"))
	if main._settings_overlay != null or main._menu_overlay == null:
		failures.append("Settings close did not restore menu")
	await click_control(main._menu_overlay.get_node("ESCPanel/ButtonGroup/SaveGame"))
	if main._user_archive_overlay == null:
		failures.append("Save button did not open archive picker")
	main._close_user_archive_overlay()
	main._show_game_menu()
	await settle()
	await click_control(main._menu_overlay.get_node("ESCPanel/ButtonGroup/Close"))
	if main._menu_overlay != null:
		failures.append("Close button did not dismiss menu")
	print("ESC_MENU_INPUT: ", "PASS" if failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
