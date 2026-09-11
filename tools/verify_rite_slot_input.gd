extends "res://tools/verify_card_equipment_input.gd"

func right_click(control: Control) -> void:
	if control == null:
		check(false, "right click target exists")
		return
	var point := control.get_global_rect().get_center()
	await pointer(point)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_RIGHT
		event.pressed = down
		event.button_mask = MOUSE_BUTTON_MASK_RIGHT if down else 0
		root.push_input(event, true)
		await process_frame
	await create_timer(0.2).timeout

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(201))
	# Input fixture: the opening story normally creates these map instances.
	state.add_available_rite(5000001, db)
	state.add_available_rite(5001501, db)
	state.begin_guide = {}
	var uid := state.add_card_to_hand(2000001, db)
	var second := state.add_card_to_hand(2000001, db)
	var third := state.add_card_to_hand(2000001, db)
	main.state = state
	main.call("_show_game")
	await create_timer(1.0).timeout
	var screen = main._game_screen
	main.call("_on_open_rite", 5000001)
	await create_timer(0.5).timeout
	var rite = main._rite_overlay
	# Do not repair the fixture with stop(): boot must preserve preparation.
	check(not state.get_rite_instance(rite._rite_uid).start, "opening desktop preserves household preparation")
	var slot: Control = rite._slot_buttons.s1
	await pointer(slot.get_global_rect().get_center())
	await create_timer(0.1).timeout
	check(slot.get_node("SourceHighlight").visible, "ordinary slot hover enables its material-backed highlight")
	check(rite._slot_tips.visible, "ordinary slot hover shows original slot text")
	var slot_point := slot.get_global_rect().get_center()
	await button(slot_point, true)
	await button(slot_point, false)
	await create_timer(0.2).timeout
	check(slot.get_node("SourceHighlight").visible, "slot click focuses matching hand and keeps pointer highlight")
	await pointer(Vector2(3456, 1036.8))
	check(not slot.get_node("SourceHighlight").visible, "leaving clicked slot clears pointer highlight")
	await pointer(slot_point)
	check(slot.get_node("SourceHighlight").visible, "reentering clicked slot restores pointer highlight")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/rite_hover_material.png")
	var start: Vector2 = hand_widget(screen, uid).get_global_rect().get_center()
	var finish := Vector2(3456, 1036.8)
	await pointer(start)
	await button(start, true)
	for i in range(1, 16):
		await pointer(start.lerp(finish, i / 15.0), true)
	await create_timer(0.4).timeout
	check(root.gui_is_dragging(), "hand card begins real drag while rite is open")
	check(rite._slot_buttons.s1.get_node("SourceSatisfiedOutline").modulate.a > 0.99, "drag broadcasts to matching first slot")
	check(rite._slot_buttons.s2.get_node("SourceSatisfiedOutline").modulate.a > 0.99, "drag broadcasts to matching second slot")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/rite_drag_slots.png")
	await button(finish, false)
	await create_timer(0.4).timeout
	check(int(rite._placed.get("s1", 0)) == uid, "drop on panel background selects first eligible slot")
	check(not state.has_card_in_hand(uid), "successful panel drop transfers UID out of hand")
	check(rite.find_child("RiteOverlayToast", true, false) == null, "card drop leaves no invented debug toast above the hand")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/rite_drop_no_toast.png")
	if int(rite._placed.get("s1", 0)) == uid:
		var card: Control = rite._slot_buttons.s1.get_node("Container/PlacedCard_S1")
		var point := card.get_global_rect().get_center()
		await pointer(point)
		await button(point, true)
		await button(point, false)
		await create_timer(0.2).timeout
		check(screen._card_detail_card_uid == uid, "left click on placed card opens its own details")
		check(int(rite._placed.get("s1", 0)) == uid, "left click does not return placed card")
		await right_click(hand_widget(screen, second))
		check(not rite._placed.has("s2"), "card detail blocks hand quick actions behind the modal")
		screen.close_card_detail()
		await create_timer(0.2).timeout
		await right_click(card)
		check(state.has_card_in_hand(uid), "right click returns editable placed card")
	await right_click(hand_widget(screen, uid))
	check(int(rite._placed.get("s1", 0)) == uid, "right click on hand card uses panel automatic slot selection")
	await right_click(hand_widget(screen, second))
	check(int(rite._placed.get("s2", 0)) == second, "second quick placement prioritizes next empty slot")
	if int(rite._placed.get("s1", 0)) == uid:
		await drag_to(hand_widget(screen, third), rite._slot_buttons.s1.get_node("Container/PlacedCard_S1"))
		check(int(rite._placed.get("s1", 0)) == third, "drop onto occupied card delegates to slot replacement")
		check(state.has_card_in_hand(uid), "replacement returns previous card without duplication")
	if int(rite._placed.get("s1", 0)) == third:
		state.start_rite_instance(rite._rite_uid)
		var card: Control = rite._slot_buttons.s1.get_node("Container/PlacedCard_S1")
		await right_click(card)
		check(int(rite._placed.get("s1", 0)) == third, "running rite ignores right-click removal")
		state.stop_rite_instance(rite._rite_uid)
		var drag_start := card.get_global_rect().get_center()
		await pointer(drag_start)
		await button(drag_start, true)
		await pointer(drag_start + Vector2(120, 0), true)
		await process_frame
		check(root.gui_is_dragging(), "unlocked slot starts a real drag")
		check(not rite._placed.has("s1"), "source slot clears before mouse release")
		check(not state.get_rite_instance(rite._rite_uid).slot_cards.has("s1"), "source rite loses card before mouse release")
		check(not state.has_card_in_hand(third), "held card is not prematurely added to hand")
		check(rite._slot_buttons.s1.get_node("SlotBackground").visible, "empty slot background restored during drag")
		await pointer(Vector2(-200, -200), true)
		await button(Vector2(-200, -200), false)
		await create_timer(0.3).timeout
		check(state.has_card_in_hand(third), "invalid drop from slot falls back to hand rather than old slot")
		check(not rite._placed.has("s1"), "invalid drop leaves original slot empty")
		await right_click(hand_widget(screen, third))
		await drag_to(rite._slot_buttons.s1.get_node("Container/PlacedCard_S1"), screen._card_rail_view)
		check(state.has_card_in_hand(third), "explicit hand drop accepts detached source")
		check(not rite._placed.has("s1"), "explicit hand drop leaves source empty")
		await right_click(hand_widget(screen, third))
		await right_click(rite._slot_buttons.s2.get_node("Container/PlacedCard_S2"))
		await drag_to(rite._slot_buttons.s1.get_node("Container/PlacedCard_S1"), rite._slot_buttons.s2)
		check(int(rite._placed.get("s2", 0)) == third, "real slot-to-slot drag retains target ownership")
		check(not rite._placed.has("s1"), "real slot-to-slot drag leaves source empty")
		await right_click(rite._slot_buttons.s2.get_node("Container/PlacedCard_S2"))
	# Same input sequence in a manual rite: no ID-specific input behavior.
	main.call("_on_open_rite", 5001501)
	await create_timer(0.3).timeout
	rite = main._rite_overlay
	slot = rite._slot_buttons.s1
	slot_point = slot.get_global_rect().get_center()
	await pointer(slot_point)
	check(slot.get_node("SourceHighlight").visible, "bath slot hover follows shared relay")
	await button(slot_point, true)
	await button(slot_point, false)
	await create_timer(0.2).timeout
	check(slot.get_node("SourceHighlight").visible, "bath click retains hover like household")
	await pointer(Vector2(3456, 1036.8))
	check(not slot.get_node("SourceHighlight").visible, "bath pointer exit clears highlight")
	await pointer(slot_point)
	check(slot.get_node("SourceHighlight").visible, "bath pointer reentry restores highlight")
	await drag_to(hand_widget(screen, third), slot)
	check(int(rite._placed.get("s1", 0)) == third, "bath shares real hand-to-slot drag")
	if int(rite._placed.get("s1", 0)) == third:
		await right_click(slot.get_node("Container/PlacedCard_S1"))
		check(state.has_card_in_hand(third), "bath shares slot-to-hand quick return")
	print("RITE_SLOT_INPUT: ", "PASS" if failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
