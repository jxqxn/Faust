extends "res://tools/verify_card_equipment_input.gd"

func click_control(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	await pointer(point)
	await button(point, true)
	await button(point, false)
	await create_timer(0.08).timeout

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var db: ConfigDB = main.db
	for id in [990701, 990702]:
		db.rites[id] = {"id": id, "name": "串行结算验证", "text": "仪式介绍", "round_number": 1,
			"cards_slot": {}, "settlement": [{"result_text": "结果第一段\n结果第二段", "result": {"coin": 2}}]}
	var state := GameState.new()
	state.auto_gen_sudan_card = false
	var first = state.create_rite_instance(990701)
	var second = state.create_rite_instance(990702)
	state.start_rite_instance(first.uid)
	state.start_rite_instance(second.uid)
	main.state = state
	main.call("_show_game")
	await create_timer(0.8).timeout
	var day := state.day
	await click_control(main._game_screen._advance_button)
	check(main._rite_overlay != null, "actual next-day input opens the first due rite")
	if main._rite_overlay != null:
		check(main._rite_overlay._rite_uid == first.uid, "first runtime UID settles first")
		check(second.life == 0, "second rite does not age before first presentation finishes")
		await click_control(main._game_screen._advance_button)
		check(state.day == day + 1, "clicking next day beneath result cannot advance another day")
		for expected_uid in [first.uid, second.uid]:
			var view = main._rite_overlay
			if view == null:
				check(false, "missing next result panel")
				break
			check(view._rite_uid == expected_uid, "correct due rite is presented")
			check(view._result_next_button.disabled, "confirmation cannot skip unread result")
			var deadline := Time.get_ticks_msec() + 12000
			while not view._resolution_committed and Time.get_ticks_msec() < deadline:
				await click_control(view._result_surface_text)
			check(view._resolution_committed, "clicking real result text advances every paragraph and commits")
			check(not view._result_next_button.disabled, "confirmation becomes usable after settlement")
			await click_control(view._result_next_button)
			await create_timer(0.2).timeout
	check(state.coin_count == 4, "two settlements execute exactly once")
	check(state.round_transition.is_empty(), "confirmation of final result completes the day")
	check(state.day == day + 1, "serial results share one day transition")
	print("RITE_ROUND_INPUT: ", "PASS" if failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
