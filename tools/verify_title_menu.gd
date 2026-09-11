extends SceneTree

# Windowed GPU/input check. Archive/continue paths are isolated from player files.
var main: Control
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 8:
		await process_frame

func click(control: Control) -> void:
	if control == null:
		failures.append("Missing click target")
		return
	var point := control.get_global_transform_with_canvas() * (control.size / 2)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()

func run() -> void:
	SaveSystem.use_save_path("user://verify_title_menu/continue.json")
	SaveSystem.use_user_archive_root("user://verify_title_menu/archives")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await settle()
	var menu: Control = main._current
	var cont: Button = menu.find_child("ContinueGameButton", true, false)
	if not cont.disabled:
		failures.append("No-save continue must remain present and disabled")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/title_checked_%d.png" % root.size.x)
	await click(menu.find_child("UserArchiveLoadGameButton", true, false))
	if main._user_archive_overlay == null:
		failures.append("Load button failed to open archive picker")
	else:
		var picker: Control = main._user_archive_overlay
		await click(picker.find_child("UserArchiveItem_00", true, false))
		if picker.find_child("LoadArchiveConfirm", true, false) != null:
			failures.append("Empty archive must not load")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/title_archives_%d.png" % root.size.x)
		var scroll: ScrollContainer = picker.find_child("Scroll View", true, false)
		scroll.scroll_vertical = 100000
		await settle()
		if scroll.scroll_vertical < 9000:
			failures.append("Archive list cannot reach final slots")
		await click(picker.find_child("Close", true, false))
	if main._user_archive_overlay != null or main._current != menu:
		failures.append("Archive close did not restore title")
	for route in [
		["Setting", "_settings_overlay", "_close_settings"],
		["StoryButton", "_story_overlay", "_close_story"],
		["ShopButton", "_shop_overlay", "_close_point_shop"],
		["CollectButton", "_gallery_overlay", "_close_gallery"],
		["Credits", "_credits_overlay", "_close_credits"],
	]:
		await click(menu.find_child(route[0], true, false))
		if main.get(route[1]) == null:
			failures.append("Title route failed: " + route[0])
		main.call(route[2])
		await settle()
	print("TITLE_MENU_INPUT: ", "PASS" if failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
