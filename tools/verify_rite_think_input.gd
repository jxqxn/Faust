extends "res://tools/verify_card_equipment_input.gd"

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(201))
	state.begin_guide = {}
	var uid := state.add_card_to_hand(2000472, db)
	main.state = state
	main.call("_show_game")
	await create_timer(1.0).timeout
	var screen = main.get("_game_screen")
	var target: Control = screen._desk_content._think_drop_zone
	var animation = target.get_node("open_03")
	var before: Texture2D = animation.texture
	await create_timer(0.2).timeout
	check(animation.texture != before, "IThink idle uses changing source sprite frames")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/think_idle.png")
	await drag_to(hand_widget(screen, uid), target)
	print("THINK after drag clip=", animation.clip_name, " pending=", state.pending_operations.size())
	check(animation.clip_name in ["Thinking", "ThinkOver"], "real GUI drop reaches the source think animation chain")
	check(state.ithink_card_uid == uid, "drop holds the card until OnCardLocked settlement")
	check(5000113 not in state.available_rites, "reading rite is not generated before the lock animation event")
	var deadline := Time.get_ticks_msec() + 15000
	while not state.think_session.is_empty() and Time.get_ticks_msec() < deadline:
		if not state.pending_operations.is_empty():
			screen.call("_consume_event_display")
		await create_timer(0.05).timeout
	await create_timer(0.15).timeout
	check(5000113 in state.available_rites, "dropping the original poetry card creates its configured reading rite")
	check(not state.has_card_in_hand(uid), "the reading rite retains the absorbed book instead of duplicating it in hand")
	check(int(state.get_card_instance(uid).rite_uid) > 0, "the book belongs to the created rite")
	check(not screen._desk_content.is_thinking(), "consuming the result releases the think input lock")
	check(animation.clip_name == "Idle", "completed processing returns to the source idle loop")
	check(screen._desk_content.can_drop_card_on_think_button({"type": "card", "source": "hand", "card_uid": state.card_uid_for(2000001, "hand")}), "another live hand card can be accepted after completion")
	main.call("_on_open_rite", 5000001)
	await create_timer(0.3).timeout
	var rite = main._rite_overlay
	var slot: Control = rite._slot_buttons["s1"]
	await pointer(slot.get_global_rect().get_center())
	await create_timer(0.1).timeout
	check(rite._slot_tips.visible, "ritual slot hover opens source Tips")
	check(rite._slot_tips.text_label.text == str(db.get_rite(5000001).cards_slot.s1.text), "slot text comes from original config")
	check(slot.get_node("SourceHighlight").visible, "slot hover enables source highlight sprite")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/rite_slot_hover.png")
	await pointer(Vector2(1900, 300))
	check(not rite._slot_tips.visible, "slot hover exit hides Tips")
	print("RITE_THINK_INPUT: ", "PASS" if failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
