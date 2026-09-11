extends "res://tools/verify_card_equipment_input.gd"

func pointer(point: Vector2, held := false) -> void:
	# Edge-scroll polls the viewport pointer each frame, beyond dispatched events.
	# Move the engine window's actual cursor as well as injecting GUI events.
	root.warp_mouse(point)
	await process_frame
	await super.pointer(point, held)

func _run() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(202))
	state.begin_guide = {}
	state.event_prompts.clear()
	for instance in state.card_instances.values():
		instance.zone = "removed"
	state.hand.clear()
	state.rail_order.clear()
	state.active_sudan_cards.clear()
	for i in 20:
		state.add_card_to_hand(2000001, db)
	var screen := preload("res://ui/game_screen.gd").new()
	screen.size = Vector2(3840, 2160)
	screen.setup(state, db, GameRNG.new(203))
	root.add_child(screen)
	await create_timer(0.2).timeout
	var rail: Control = screen.get("_card_items")
	var transform := rail.get_global_transform_with_canvas()
	var original_order := state.rail_order.duplicate()
	screen.set("_hand_normalized_range", 0.0)
	screen.call("_layout_hand_cards")
	await pointer(transform * Vector2(rail.size.x * 0.5, 200))
	var first_order := _uids(rail)
	check(first_order != original_order, "overflow changes painter order independently of bag order")
	await capture("left")
	await pointer(transform * Vector2(rail.size.x * 0.95, 200))
	for i in 100:
		await process_frame
	check(float(screen.get("_hand_normalized_range")) > 0.99, "right edge input scrolls to final cards")
	check(_uids(rail) != first_order, "scrolling changes source clamp sibling order")
	var hovered := root.gui_get_hovered_control() as CardWidget
	check(hovered != null and hovered.get_global_rect().has_point(root.get_mouse_position()), "stationary pointer hover follows scrolling cards")
	check(state.rail_order == original_order, "painter reordering cannot rewrite card bag order")
	await capture("right")
	await pointer(transform * Vector2(rail.size.x * 0.05, 200))
	print("EDGE_LEFT_START range=", screen.get("_hand_normalized_range"), " hovered=", root.gui_get_hovered_control(), " pointer=", rail.get_local_mouse_position())
	for i in 100:
		await process_frame
	print("EDGE_LEFT_END range=", screen.get("_hand_normalized_range"), " hovered=", root.gui_get_hovered_control(), " pointer=", rail.get_local_mouse_position())
	check(float(screen.get("_hand_normalized_range")) < 0.01, "left edge input scrolls back to first cards")
	check(state.rail_order == original_order, "both directions preserve runtime bag order")
	screen.queue_free()
	await process_frame
	print("HAND_EDGE_INPUT: ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)

func _uids(rail: Control) -> Array:
	var result: Array = []
	for child in rail.get_children():
		if child is CardWidget and child.visible:
			result.append(child.card_uid)
	return result

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/hand_edge_%s_%d.png" % [label, DisplayServer.window_get_size().x])
