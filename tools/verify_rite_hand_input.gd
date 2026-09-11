extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func settle(n: int = 4) -> void:
	for i in n:
		await process_frame

func pointer(point: Vector2, held: bool = false) -> void:
	var e := InputEventMouseMotion.new()
	e.position = point
	e.relative = Vector2(20, -20)
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(e, true)
	await process_frame

func button(point: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.position = point
	e.button_index = MOUSE_BUTTON_LEFT
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	e.pressed = down
	root.push_input(e, true)
	await process_frame

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(201))
	state.begin_guide = {}
	main.state = state
	main.call("_show_game")
	await settle(20)
	var uid: int = state.create_rite_instance(5001501).uid
	main.call("_on_open_rite_instance", uid)
	await settle(20)
	var screen = main.get("_game_screen")
	var rite = main.get("_rite_overlay")
	var cards: Control = screen.get("_card_items")
	var card: CardWidget
	for child in cards.get_children():
		if child is CardWidget and child.card_id == 2000001:
			card = child
	if card == null:
		push_error("Artu absent")
		main.free()
		quit(1)
		return
	var card_uid := card.card_uid
	var slot_key: String = rite.get("_slot_buttons").keys()[0]
	var slot: Control = rite.get("_slot_buttons")[slot_key]
	var start := card.get_global_transform_with_canvas() * (card.size * 0.5)
	var finish := slot.get_global_transform_with_canvas() * (slot.size * 0.5)
	await pointer(start)
	print("START HIT ", root.gui_get_hovered_control(), " card ", card, " at ", start)
	await button(start, true)
	for i in range(1, 16):
		await pointer(start.lerp(finish, float(i) / 15), true)
	print("DRAG ", root.gui_is_dragging(), " TARGET ", root.gui_get_hovered_control(), " slot ", slot)
	await button(finish, false)
	await settle(15)
	var placed: bool = rite.get("_placed").get(slot_key, 0) == card_uid
	print("PLACED ", placed)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/rite_hand_input.png")
	# Continue the actual host flow: start, reopen running, lock slots, stop.
	var confirm: Control = rite.get("_resolve_btn")
	var confirm_point := confirm.get_global_rect().get_center()
	await pointer(confirm_point)
	await button(confirm_point, true)
	await button(confirm_point, false)
	await settle(12)
	var running = state.get_rite_instance(uid)
	if running == null or not running.start:
		failures.append("visible confirm failed to start one-day rite")
	else:
		main.call("_on_open_rite_instance", uid)
		await settle(12)
		rite = main.get("_rite_overlay")
		if rite._can_edit_slot(slot_key):
			failures.append("running rite accepts slot edits")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/rite_running_%d.png" % root.size.x)
		var stop: Control = rite.get("_stop_btn")
		if not stop.is_visible_in_tree():
			failures.append("same-round running rite has no stop action")
		else:
			var stop_point := stop.get_global_rect().get_center()
			await pointer(stop_point)
			await button(stop_point, true)
			await button(stop_point, false)
			await settle(8)
			if state.get_rite_instance(uid).start:
				failures.append("visible stop did not restore preparation")
	print("RITE_PREPARE_RUNNING_INPUT: ", "PASS" if placed and failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if placed and failures.is_empty() else 1)
