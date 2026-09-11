extends "res://tools/verify_card_equipment_input.gd"

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(38))
	state.begin_guide = {}
	state.event_prompts.clear()
	for instance in state.card_instances.values():
		instance.zone = "removed"
	state.hand.clear()
	state.rail_order.clear()
	state.active_sudan_cards.clear()
	var first := state.add_card_to_hand(2000029, db)
	state.get_card_instance(first).count = 1
	main.state = state
	main.call("_show_game")
	await create_timer(0.5).timeout
	var rite_uid := state.add_available_rite(5000005, db, GameRNG.new(38))
	main.call("_on_open_rite_instance", rite_uid)
	await create_timer(0.5).timeout
	var screen = main.get("_game_screen")
	var view = main.get("_rite_overlay")
	await drag_to(hand_widget(screen, first), view._slot_buttons.s2)
	check(int(view._placed.get("s2", 0)) == first, "partial deposit retains UID")
	check(state.get_card_instance(first).zone == "slot", "partial deposit enters real slot")
	var extra := state.add_card_to_hand(2000029, db)
	state.get_card_instance(extra).count = 5
	screen.refresh()
	await create_timer(0.3).timeout
	await drag_to(hand_widget(screen, extra), view._slot_buttons.s2)
	check(state.get_card_instance(first).count == 3, "slot receives only required three")
	check(state.get_card_instance(extra).count == 3 and extra in state.hand, "excess three stays in hand")
	check(int(view._placed.get("s2", 0)) == first, "top-up preserves original slot UID")
	view.queue_free()
	await process_frame
	var household_uid := state.add_available_rite(5000001, db, GameRNG.new(39))
	main.call("_on_open_rite_instance", household_uid)
	await create_timer(0.5).timeout
	view = main.get("_rite_overlay")
	var old_person := state.add_card_to_hand(2000006, db)
	var new_person := state.add_card_to_hand(2000001, db)
	screen.refresh()
	await create_timer(0.3).timeout
	await drag_to(hand_widget(screen, old_person), view._slot_buttons.s1)
	check(int(view._placed.get("s1", 0)) == old_person, "first person occupies s1")
	await drag_to(hand_widget(screen, new_person), view._slot_buttons.s1)
	check(int(view._placed.get("s1", 0)) == new_person, "real drag replaces the targeted occupied slot")
	check(old_person in state.hand, "displaced person returns to hand")
	check(state.get_card_instance(first).count == 3, "replacement leaves other rite gold untouched")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/slot_cost_%d.png" % DisplayServer.window_get_size().x)
	print("SLOT_COST_INPUT: ", "PASS" if failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
