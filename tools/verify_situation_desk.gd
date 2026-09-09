extends SceneTree

## Runtime verification for the situation-desk map projection and the RiteNew
## event signs.  It boots the real main scene, then for each window size checks
## that expanded title bounds never overlap and that both the icon surface and
## the title banner open the correct rite instance.  Screenshots are written to
## docs/ui_layout/ for visual comparison against original_runtime/desktop.jpg.

const SIZES := [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(1600, 1000)]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _click_local(control: Control, local_point: Vector2) -> Control:
	var point := control.get_global_transform_with_canvas() * local_point
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await process_frame
	var hovered := root.gui_get_hovered_control()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	return hovered


func _settle(frames: int = 3) -> void:
	for i in frames:
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
	await _settle(8)

	var screen = main.get("_game_screen")
	var desk = screen.get_node_or_null("SituationDesk")
	_check(desk != null, "SituationDesk missing from the game screen")
	if desk == null:
		_finish(main)
		return

	# Stress the source collision pass: four rites sharing 自宅's child range,
	# matching test_situation_desk_tabletop's authored case.  Created once so
	# every window size sees the same map state.
	for i in 3:
		state.create_rite_instance(5000003)
	desk.refresh_context()
	await _settle(4)

	for window_size in SIZES:
		DisplayServer.window_set_size(window_size)
		await _settle(6)
		var label := "%dx%d" % [window_size.x, window_size.y]
		var canvas: Vector2 = root.get_visible_rect().size
		_check(desk.size == canvas, "%s: SituationDesk must fill the canvas %s, got %s" % [label, canvas, desk.size])
		_check_no_overlap(desk, label)
		await _check_clicks(main, desk, label)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(
			"res://docs/ui_layout/desktop_map_%d.png" % window_size.x
		)

	_finish(main)


func _check_no_overlap(desk, label: String) -> void:
	var roots: Dictionary = desk._allocate_rite_card_positions()
	var uids: Array = roots.keys()
	for i in uids.size():
		var first: Rect2 = desk._rite_card_bound(uids[i])
		first.position += roots[uids[i]]
		for j in range(i + 1, uids.size()):
			var second: Rect2 = desk._rite_card_bound(uids[j])
			second.position += roots[uids[j]]
			_check(
				not first.grow(-0.01).intersects(second),
				"%s: expanded bounds of rites %s/%s overlap" % [label, uids[i], uids[j]]
			)


func _check_clicks(main, desk, label: String) -> void:
	var uids: Array = desk.rite_cards.keys()
	uids.sort()
	_check(uids.size() >= 4, "%s: expected the opening rites plus the 自宅 stress set" % label)
	for uid in uids:
		var card: Control = desk.rite_cards[uid]
		var banner := card.get_node_or_null("TitleBG") as TextureButton
		_check(banner != null, "%s: rite %s has no TitleBG" % [label, uid])
		if banner == null:
			continue
		# Icon surface: left of the banner inside the RiteNew root button.
		var icon_point := Vector2(card.size.x * 0.2, card.size.y * 0.65)
		var hovered := await _click_local(card, icon_point)
		_check(hovered == card, "%s: icon click on rite %s hit %s" % [label, uid, hovered])
		_check(main.get("_current_rite_uid") == uid, "%s: icon click opened the wrong rite" % label)
		_check(desk.last_rite == uid, "%s: icon click did not set last_rite" % label)
		main.call("_close_rite_overlay")
		await _settle(3)
		_check(main.get("_rite_overlay") == null, "%s: rite overlay did not close" % label)
		# Title banner surface.
		var banner_hovered := await _click_local(banner, banner.size * 0.5)
		_check(banner_hovered == banner, "%s: title click on rite %s hit %s" % [label, uid, banner_hovered])
		_check(main.get("_current_rite_uid") == uid, "%s: title click opened the wrong rite" % label)
		main.call("_close_rite_overlay")
		await _settle(3)
		_check(main.get("_rite_overlay") == null, "%s: rite overlay did not close after title click" % label)


func _finish(main) -> void:
	print("SITUATION_DESK: ", "PASS" if failures.is_empty() else "FAIL")
	for failure in failures:
		print("  - ", failure)
	if main != null and is_instance_valid(main):
		main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
