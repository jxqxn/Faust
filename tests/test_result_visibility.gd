extends GutTest

const RiteView = preload("res://ui/rite_view.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const RNG = preload("res://core/rng.gd")

class TraceState extends GameState:
	var timings: Array[String] = []
	var block_end := false
	var reveal_on_end_uid := 0
	func trigger_events(timing: String, _ctx: Dictionary = {}) -> Array[int]:
		timings.append(timing)
		if timing == "rite_end" and reveal_on_end_uid > 0:
			get_card_instance(reveal_on_end_uid).bag = current_bag_index
		var result: Array[int] = [] # Controlled timing probe; real event content has separate oracle tests.
		if timing == "rite_end" and block_end:
			queue_prompt({"id": "close-boundary", "text": "仪式结束后的提示"})
		return result

var db: ConfigDB
var old_save_path: String
var test_path: String
var old_global_path: String
var old_round_root: String
var test_root: String

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func before_each() -> void:
	old_save_path = SaveSystem.save_path_override
	old_global_path = GlobalState.global_path_override
	old_round_root = SaveSystem.round_save_root_override
	test_root = "user://rite-close-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(test_root)
	test_path = test_root.path_join("save.json")
	SaveSystem.use_save_path(test_path)
	SaveSystem.use_round_save_root(test_root)
	GlobalState.use_global_path(test_root.path_join("global.json"))

func after_each() -> void:
	SaveSystem.use_save_path(old_save_path)
	SaveSystem.use_round_save_root(old_round_root)
	GlobalState.use_global_path(old_global_path)
	for filename in DirAccess.get_files_at(test_root):
		DirAccess.remove_absolute(test_root.path_join(filename))
	DirAccess.remove_absolute(test_root)

func _viewport(dimensions: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(viewport)
	return viewport

func _mount(viewport: SubViewport, state: GameState, uid: int) -> Control:
	var screen := GameScreen.new()
	screen.setup(state, db, RNG.new(9615))
	viewport.add_child(screen)
	var view := RiteView.new()
	view.setup(state, db, RNG.new(9615), 5000001, uid)
	screen.add_source_overlay(view)
	screen.set_world_scene_blocker("rite", true, false, true, true)
	view.set_meta("test_screen", screen)
	return view

# An empty selected result isolates the close continuation from story selection.
# This fixture is not an original runtime trace or a full rite input sequence.
func _prepare(view: Control) -> void:
	view._last_result = RiteResolver.RiteResult.new()
	view._resolution_pending = true
	view._settlement_phase = "selection"
	view._settlement_context = {"rite_id": 5000001, "rite_uid": view._rite_uid}
	view._result_surface.show()
	view._result_text_done = true
	view._result_paragraph_index = 0
	view._result_paragraphs.clear()

func _click(viewport: SubViewport, button: Button) -> void:
	assert_not_null(button)
	if button == null:
		return
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(), button, "real mouse hits " + button.name)
	for pressed in [true, false]:
		var input := InputEventMouseButton.new()
		input.position = motion.position
		input.button_index = MOUSE_BUTTON_LEFT
		input.pressed = pressed
		viewport.push_input(input, true)
		await wait_process_frames(1)

func _read_saved() -> TraceState:
	var restored := TraceState.new()
	SaveSystem.deserialize(JSON.parse_string(FileAccess.get_file_as_string(test_path)), restored, db)
	return restored

func _capture(viewport: SubViewport, label: String) -> void:
	var prefix := OS.get_environment("FAUST_CLOSE_CAPTURE")
	if prefix.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	assert_eq(viewport.get_texture().get_image().save_png(prefix + label + ".png"), OK)

func _physical(screen: Control, uid: int) -> CardWidget:
	for widget in screen._ordered_hand_cards():
		if widget.card_uid == uid:
			return widget
	return null

func test_result_visibility_and_return_at_both_sizes() -> void:
	# Diagnostic source/asset expectation, not an original runtime capture.
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		var state := TraceState.new()
		var rite = state.create_rite_instance(5000001)
		var viewport := _viewport(dimensions)
		var view := _mount(viewport, state, rite.uid)
		await wait_process_frames(2)
		_prepare(view)
		view._last_result.settlements = [{"result": {"card": [2000372, "own+1"]}}]
		view._last_result.entry_contexts = [{}]
		await _click(viewport, view._result_next_button)
		assert_eq(state.result_card_rewards.size(), 1)
		var uid := int(state.result_card_rewards[0])
		var screen = view.get_meta("test_screen")
		screen.refresh()
		await wait_seconds(1.2)
		var widget := _physical(screen, uid)
		var visible_before := widget != null and widget.is_visible_in_tree()
		assert_false(visible_before, "bound real result card is hidden under source inactive Container")
		await _capture(viewport, "result-%d" % dimensions.x)
		assert_true(SaveSystem.save(state))
		screen.queue_free()
		await wait_process_frames(2)
		state = _read_saved()
		view = _mount(viewport, state, rite.uid)
		view.restore_round_result(state.rite_result_display)
		screen = view.get_meta("test_screen")
		await wait_seconds(1.2)
		widget = _physical(screen, uid)
		var visible_reload := widget != null and widget.is_visible_in_tree()
		assert_false(visible_reload, "result ownership survives scene reconstruction")
		await _click(viewport, view._result_next_button)
		screen.refresh()
		await wait_process_frames(2)
		widget = _physical(screen, uid)
		assert_not_null(widget)
		var visible_close := widget != null and widget.is_visible_in_tree()
		assert_true(visible_close)
		assert_true(state.result_card_rewards.is_empty())
		assert_true(state.rite_result_display.is_empty())
		var flashing := widget != null and (widget._flash_rising or widget._flash_time > 0.0)
		assert_true(flashing, "close callback triggers returned-card flash")
		await _capture(viewport, "closed-%d" % dimensions.x)
		assert_true(SaveSystem.save(state))
		screen.queue_free()
		await wait_process_frames(2)
		state = _read_saved()
		screen = GameScreen.new()
		screen.setup(state, db, RNG.new(9615))
		viewport.add_child(screen)
		await wait_process_frames(3)
		widget = _physical(screen, uid)
		assert_true(widget != null and widget.is_visible_in_tree(), "closed hand survives disk reload")
		assert_true(state.rite_result_display.is_empty())
		print("VISIBILITY_DIAGNOSTIC ", JSON.stringify({"size":dimensions.x,"uid":uid,"result_visible":visible_before,"result_reload_visible":visible_reload,"closed_visible":visible_close,"closed_flash":flashing}))
		viewport.queue_free()
		await wait_process_frames(2)
