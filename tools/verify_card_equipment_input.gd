extends SceneTree

var failures: Array[String] = []
var _last_pointer := Vector2.ZERO

func _initialize() -> void:
	call_deferred("_run")

func pointer(point: Vector2, held := false) -> void:
	# Drag hover is also polled between input events; keep the window cursor
	# consistent with the injected event instead of letting OS position win.
	root.warp_mouse(point)
	var event := InputEventMouseMotion.new()
	event.position = point
	event.relative = point - _last_pointer
	_last_pointer = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(event, true)
	await process_frame

func button(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(event, true)
	await process_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func hand_widget(screen, uid: int) -> CardWidget:
	for child in screen.get("_card_items").get_children():
		if child is CardWidget and child.card_uid == uid and not child.is_queued_for_deletion():
			return child
	return null

func drag_to(card: CardWidget, target: Control) -> void:
	var start := card.get_global_rect().get_center()
	var finish := target.get_global_rect().get_center()
	await pointer(start)
	await button(start, true)
	for i in range(1, 16):
		await pointer(start.lerp(finish, float(i) / 15), true)
	finish = target.get_global_rect().get_center()
	if target is CardWidget and target._can_equip_dropped_card(card.drag_payload()):
		var delegate = target._drop_delegate()
		if delegate != null and delegate.get("owner_screen") != null:
			var screen: Control = delegate.get("owner_screen")
			var cards: Array = screen._ordered_hand_cards()
			var metrics: Dictionary = screen._hand_layout_metrics(cards, 0)
			var rail: Control = screen.get("_card_items")
			# Exercise the source sticky aperture in the uncompressed row.
			# A gap-shifted rendered card center is not necessarily inside it.
			var aperture_x: float = metrics.slot_positions[cards.find(target)] + target.card_size().x * 0.25
			finish.x = (rail.get_global_transform_with_canvas() * Vector2(aperture_x, 0)).x
	await pointer(finish, true)
	check(root.gui_is_dragging(), "equipment starts a real GUI drag")
	if target is CardWidget and target._can_equip_dropped_card(card.drag_payload()):
		var delegate = target._drop_delegate()
		if delegate != null and delegate.get("owner_screen") != null:
			var screen: Control = delegate.get("owner_screen")
			var local_pointer: Vector2 = screen.get("_card_rail_view").get_global_transform().affine_inverse() * finish
			print("STICKY_TRACE finish=", finish, " local=", local_pointer, " actual=", screen.get("_hand_sticky"), "/", screen.get("_hand_drop_preview_index"), " expected=", screen._resolve_hand_preview(local_pointer, card.card_uid, card.drag_payload(), false, Vector2.ZERO))
			check(bool(screen.get("_hand_sticky")), "actual equipment hover activates source sticky branch")
			check(int(screen.get("_hand_drop_preview_index")) == -1, "actual equipment hover removes insertion gap")
	await button(finish, false)
	await create_timer(0.7).timeout

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(201))
	state.begin_guide = {}
	for instance in state.card_instances.values():
		instance.zone = "removed"
	state.hand.clear()
	state.rail_order.clear()
	state.active_sudan_cards.clear()
	var host_uid := state.add_card_to_hand(2001193, db)
	var first_uid := state.add_card_to_hand(2000246, db)
	var second_uid := state.add_card_to_hand(2000252, db)
	main.state = state
	main.call("_show_game")
	await create_timer(1.0).timeout
	var screen = main.get("_game_screen")
	await drag_to(hand_widget(screen, first_uid), hand_widget(screen, host_uid))
	check(first_uid in state.get_card_instance(host_uid).equipped_uids, "drop on hand character equips weapon")
	check(first_uid not in state.hand, "equipped weapon leaves hand")
	await create_timer(0.3).timeout
	var detail = screen.get("_card_info_view")
	check(detail != null and screen.get("_card_detail_card_uid") == host_uid, "successful hand equip automatically opens host detail")
	if detail != null:
		await drag_to(hand_widget(screen, second_uid), detail.get("_panel"))
		check(second_uid in state.get_card_instance(host_uid).equipped_uids, "drop on detail replaces weapon")
		check(first_uid in state.hand, "replaced weapon returns to hand")
		check(second_uid not in state.hand, "replacement leaves hand")
		check(screen.get("_card_detail_card_uid") == host_uid, "equipment change preserves open detail")
		var shown: Control = detail.find_child("EquippedCard_0", true, false)
		check(shown != null and shown.get("card_uid") == second_uid, "open detail refreshes equipped UID")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/card_equipment_%d.png" % DisplayServer.window_get_size().x)
	print("CARD_EQUIPMENT_INPUT: ", "PASS" if failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
