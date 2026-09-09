## Graphical Windows integration check. Uses isolated application preferences.
## Run --write then --read in separate processes; --hold probes crash cleanup.
## This intentionally changes the monitor mode and requires a graphical backend.
extends SceneTree

const Settings = preload("res://ui/game_application_settings.gd")
const TEST_PATH := "user://display-verification-preferences.json"
var desktop_before: Dictionary

func _initialize() -> void:
	call_deferred("_boot")

func _boot() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Display verification needs the Windows graphical backend.")
		quit(2)
		return
	Settings.settings_path = TEST_PATH
	desktop_before = Settings.DisplayAdapter.new().query(root)
	if "--write" in OS.get_cmdline_user_args() or "--hold" in OS.get_cmdline_user_args() or "--windowed-start" in OS.get_cmdline_user_args():
		if FileAccess.file_exists(TEST_PATH):
			DirAccess.remove_absolute(TEST_PATH)
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	call_deferred("_verify")

func _verify() -> void:
	for i in range(12):
		await process_frame
	if Settings._display_backend == null or Settings.display_error != "":
		_fail("Startup: " + Settings.display_error)
		return
	var actual: Dictionary = Settings._display_backend.query(root)
	print("DISPLAY_INITIAL ", JSON.stringify(actual), " window=", root.size, " mode=", root.mode)
	if "--windowed-start" in OS.get_cmdline_user_args():
		if actual.get("width") != desktop_before.get("width") or actual.get("height") != desktop_before.get("height") or root.mode != Window.MODE_WINDOWED or root.size != Vector2i(1920, 1080):
			_fail("Windowed startup changed the desktop or requested window dimensions.")
			return
		print("DISPLAY_WINDOWED_START_PASS desktop=", actual.get("width"), "x", actual.get("height"), " window=1920x1080")
		quit()
		return
	if "--hold" in OS.get_cmdline_user_args():
		Settings.set_full_screen("ExclusiveFullScreen")
		actual = Settings._display_backend.query(root)
		if int(actual.get("width", 0)) != 1920 or int(actual.get("height", 0)) != 1080:
			_fail("Crash probe did not enter the source default display mode.")
			return
		print("DISPLAY_HOLD_PID=", OS.get_process_id())
		await create_timer(60).timeout
		quit()
		return
	if "--write" in OS.get_cmdline_user_args():
		current_scene._show_settings()
		await process_frame
		var panel = current_scene._settings_overlay
		var mode: OptionButton = panel.find_child("ShowMode", true, false).get_node("Dropdown")
		var sizes: OptionButton = panel.find_child("Resolution", true, false).get_node("Dropdown")
		mode.select(1)
		mode.item_selected.emit(1)
		for i in range(sizes.item_count):
			if sizes.get_item_text(i) == "1280x720":
				sizes.select(i)
				sizes.item_selected.emit(i)
		for i in range(8):
			await process_frame
		if not _window_matches():
			_fail("UI controls did not apply Windowed 1280x720.")
			return
		root.get_texture().get_image().save_png("res://docs/ui_layout/display_settings_connected.png")
		print("DISPLAY_WRITE_PASS Windowed 1280x720")
	else:
		if not _window_matches():
			_fail("Fresh-process preference restoration did not match.")
			return
		print("DISPLAY_RESTART_PASS Windowed 1280x720")
		DirAccess.remove_absolute(TEST_PATH)
	quit()

func _window_matches() -> bool:
	return Settings.full_screen == "Windowed" and Settings.resolution == "1280x720" and root.mode == Window.MODE_WINDOWED and root.size == Vector2i(1280, 720)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
