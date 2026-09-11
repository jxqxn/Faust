extends "res://tools/verify_card_equipment_input.gd"

func _run() -> void:
	var equipment_mode := "--equipment" in OS.get_cmdline_user_args()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(9323))
	state.begin_guide = {}
	state.event_prompts.clear()
	for instance in state.card_instances.values():
		instance.zone = "removed"
	state.hand.clear()
	state.rail_order.clear()
	state.active_sudan_cards.clear()
	var target := state.add_card_to_hand(2001193 if equipment_mode else 2000029, db)
	var source := state.add_card_to_hand(2000252 if equipment_mode else 2000029, db)
	var old_equipment := 0
	if equipment_mode:
		state.current_bag_index = 2
		state.get_card_instance(target).bag = 2
		state.get_card_instance(source).bag = 2
		old_equipment = state.add_card_to_hand(2000246, db)
		state.get_card_instance(old_equipment).bag = 0
		state.attach_equipment(target, old_equipment, db, true, true)
	else:
		state.get_card_instance(target).count = 5
		state.get_card_instance(source).count = 3
	main.state = state
	main.call("_show_game")
	await create_timer(0.5).timeout
	var rite_uid: int = state.add_available_rite(5000001, db, GameRNG.new(9323))
	main.call("_on_open_rite_instance", rite_uid)
	await create_timer(0.5).timeout
	var screen = main.get("_game_screen")
	var view = main.get("_rite_overlay")
	view._place_card_in_slot("s4", source, "hand", "")
	view._after_placement_changed()
	await create_timer(0.3).timeout
	var slot_card: CardWidget = view._slot_buttons["s4"].find_child("PlacedCard_*", true, false)
	check(slot_card != null, "source slot card exists")
	if slot_card != null:
		await drag_to(slot_card, hand_widget(screen, target))
	if equipment_mode:
		check(state.get_card_instance(target).equipped_uids == [source], "actual slot equipment replaces old weapon")
		check(state.get_card_instance(source).zone == "equipped", "source attached")
		check(old_equipment in state.hand, "replaced weapon returns to hand")
		check(state.get_card_instance(old_equipment).bag == 2, "replaced weapon follows host page")
		check(state.visible_rail_card_uids() == [target, old_equipment], "replaced weapon is visible at page end")
		check(screen.get("_card_detail_card_uid") == target, "successful equip automatically opens host details")
	else:
		check(state.get_card_instance(target).count == 8, "actual slot-to-hand drop merges counts")
		check(state.get_card_instance(source).zone == "removed", "source consumed")
	check(not view._placed.has("s4"), "source slot UI cleared")
	check(state.cards_in_slot(4, rite_uid).is_empty(), "source slot state cleared")
	check(source not in state.hand, "consumed source not resurrected")
	await RenderingServer.frame_post_draw
	var mode_name := "equip" if equipment_mode else "stack"
	root.get_texture().get_image().save_png("res://docs/ui_layout/slot_hand_%s_%d.png" % [mode_name, DisplayServer.window_get_size().x])
	print("SLOT_HAND_", mode_name.to_upper(), "_INPUT: ", "PASS" if failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
