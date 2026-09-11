extends SceneTree

# GPU/input verification for the complete source-shaped archive flow.  All
# paths are isolated from the player's continue save and manual archives.
var main: Control
var failures: Array[String] = []
var shot_index := 0

func _initialize() -> void:
	call_deferred("run")

func settle(frames := 8) -> void:
	for i in frames:
		await process_frame

func click(control: Control, ratio := Vector2(0.5, 0.5)) -> void:
	if control == null:
		failures.append("missing click target")
		return
	var point := control.get_global_transform_with_canvas() * (control.size * ratio)
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

func type_text(value: String) -> void:
	# InputEventKey unicode entry exercises LineEdit's real input route.
	for offset in value.length():
		for down in [true, false]:
			var event := InputEventKey.new()
			event.pressed = down
			event.keycode = value.unicode_at(offset)
			event.unicode = value.unicode_at(offset)
			root.push_input(event, true)
			await process_frame
	await settle(2)

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var suffix := "%02d_%s_%d" % [shot_index, label, root.size.x]
	root.get_texture().get_image().save_png("res://docs/ui_layout/archive_%s.png" % suffix)
	shot_index += 1

func require_node(root_node: Node, node_name: String) -> Node:
	var node := root_node.find_child(node_name, true, false)
	if node == null:
		failures.append("missing node: " + node_name)
	return node

func run() -> void:
	var run_root := "user://verify_archive_flow_%d" % root.size.x
	SaveSystem.use_save_path(run_root + "/continue.json")
	SaveSystem.use_user_archive_root(run_root + "/archives")
	SaveSystem.use_round_save_root(run_root + "/rounds")
	SaveSystem.delete_all_user_archives()
	SaveSystem.delete_save()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await settle()
	var state := GameState.new()
	state.setup_new_run(main.db, 1, GameRNG.new(609))
	state.begin_guide = {}
	main.state = state
	main._show_game()
	SaveSystem.save_user_archive(state, 0, "路线甲", main.db)
	main._show_user_archive_overlay(true)
	await settle()
	var picker: Control = main._user_archive_overlay
	await capture("save_list")

	# Empty row -> name controller -> actual LineEdit input -> save in place.
	await click(require_node(picker, "UserArchiveItem_01") as Control)
	var input := require_node(picker, "InputField (TMP)") as LineEdit
	var name_confirm := require_node(picker, "Confirm") as Button
	if input != null:
		input.select_all()
		for down in [true, false]:
			var erase := InputEventKey.new()
			erase.keycode = KEY_BACKSPACE
			erase.pressed = down
			root.push_input(erase, true)
			await process_frame
	await create_timer(0.15).timeout
	if name_confirm != null:
		var art: CanvasItem = name_confirm.get_node("Image")
		if not name_confirm.disabled or not art.modulate.is_equal_approx(Color(0.39215687, 0.39215687, 0.39215687, 1)):
			failures.append("empty name must use source opaque disabled graphic color")
		if not name_confirm.modulate.is_equal_approx(Color.WHITE):
			failures.append("name confirmation must not dim its entire subtree")
	if input != null:
		input.select_all()
		await type_text("R")
		if input.text != "R":
			failures.append("LineEdit did not receive unicode input: " + input.text)
		# IME composition is owned by the OS window; complete the deterministic
		# archive-name fixture after proving the focused field accepts key input.
		input.text = "Route B"
	await capture("name_input")
	await click(require_node(picker, "Confirm") as Control)
	if SaveSystem.list_user_archives(main.db).size() != 2 or main._user_archive_overlay != picker:
		failures.append("save did not refresh the picker in place")

	# Child rename/delete buttons must not also activate the parent row.
	await click(require_node(picker.find_child("UserArchiveItem_01", true, false), "ModifyName") as Control)
	if picker.find_child("UserArchiveNameInput", true, false) == null or picker.find_child("OverwriteArchiveConfirm", true, false) != null:
		failures.append("rename click leaked into parent row")
	await click(require_node(picker.find_child("UserArchiveNameInput", true, false), "Cancel") as Control)

	# Filled row -> overwrite ConfirmNew -> cancel keeps payload and picker.
	var before_hash := FileAccess.get_sha256(SaveSystem.user_archive_save_path(1))
	await click(require_node(picker, "UserArchiveItem_01") as Control, Vector2(0.4, 0.5))
	await capture("overwrite_confirm")
	var overwrite := require_node(picker, "OverwriteArchiveConfirm")
	await click(require_node(overwrite, "Cancel") as Control)
	if FileAccess.get_sha256(SaveSystem.user_archive_save_path(1)) != before_hash:
		failures.append("overwrite cancel changed payload")

	# Inline delete confirmation: cancel then confirm.  Buttons must remain in
	# the visible row and must not open overwrite.
	var row1 := require_node(picker, "UserArchiveItem_01")
	await click(require_node(row1, "Delete") as Control)
	var inline := require_node(row1, "DeleteConfirm")
	var inline_close := require_node(inline, "Close") as Button
	var hover_point := inline_close.get_global_transform_with_canvas() * (inline_close.size * 0.5)
	root.warp_mouse(hover_point)
	var hover_event := InputEventMouseMotion.new()
	hover_event.position = hover_point
	root.push_input(hover_event, true)
	await create_timer(0.15).timeout
	if not inline_close.get_node("Image").modulate.is_equal_approx(Color(0.9607843, 0.9607843, 0.9607843, 1)):
		failures.append("inline cancellation hover must use source ColorTint")
	await capture("delete_inline")
	await click(require_node(inline, "Close") as Control)
	if SaveSystem.list_user_archives(main.db).size() != 2:
		failures.append("delete cancel removed archive")
	await click(require_node(row1, "Delete") as Control)
	inline = require_node(row1, "DeleteConfirm")
	await click(require_node(inline, "Confirm") as Control)
	if SaveSystem.list_user_archives(main.db).size() != 1 or picker.find_child("EmptyContent", true, false) == null:
		failures.append("delete confirm did not refresh empty row")

	# Load mode: the explicit stamp must open ConfirmNew; cancel must keep the
	# picker, and confirm must restore then dismiss it.
	main._close_user_archive_overlay()
	main._show_user_archive_overlay(false)
	await settle()
	picker = main._user_archive_overlay
	var row0 := require_node(picker, "UserArchiveItem_00")
	await click(require_node(row0, "Load") as Control)
	await capture("load_confirm")
	var load_confirm := require_node(picker, "LoadArchiveConfirm")
	await click(require_node(load_confirm, "Cancel") as Control)
	if main._user_archive_overlay != picker:
		failures.append("load cancel dismissed picker")
	await click(require_node(row0, "Load") as Control)
	load_confirm = require_node(picker, "LoadArchiveConfirm")
	await click(require_node(load_confirm, "Confirm") as Control)
	if main._user_archive_overlay != null or main.state == null:
		failures.append("load confirm did not restore and dismiss")

	print("ARCHIVE_FLOW_INPUT: ", "PASS" if failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	SaveSystem.delete_all_user_archives()
	SaveSystem.delete_save()
	SaveSystem.use_default_save_path()
	SaveSystem.use_default_user_archive_root()
	SaveSystem.use_default_round_save_root()
	await process_frame
	quit(0 if failures.is_empty() else 1)
