extends "res://tools/verify_card_equipment_input.gd"

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(4357))
	state.begin_guide = {}
	state.event_prompts.clear()
	state.cached_event = [5300001, 5300002]
	main.state = state
	main.call("_show_game")
	await create_timer(0.5).timeout
	var screen = main.get("_game_screen")
	var tray = screen.get("_cached_events_view")
	var item: Control = tray.item_for_id(5300001)
	var origin := item.global_position
	var original_round: int = state.round_number
	var point: Vector2 = screen.get("_cached_event_mask").get_global_rect().get_center()
	await pointer(point)
	print("SHAKE_HIT point=", point, " hit=", root.gui_get_hovered_control(), " mask=", screen.get("_cached_event_mask"), " blockers=", screen.get("_presentation_blockers"))
	await button(point, true)
	await button(point, false)
	check(tray.shake_active_count() == 2, "next-day mask click starts both notice shakers")
	var maximum := 0.0
	for frame in range(12):
		await process_frame
		maximum = maxf(maximum, item.global_position.distance_to(origin))
		if frame == 2:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/ui_layout/cached_shake_%d.png" % DisplayServer.window_get_size().x)
	check(maximum > 0.5, "world shake is visibly projected, not a subpixel local sine")
	await create_timer(0.5).timeout
	check(item.global_position.distance_to(origin) < 0.2, "source decay settles at captured origin")
	check(state.cached_event.size() == 2, "notice does not consume events")
	check(state.round_number == original_round, "cached-event mask prevents next day")
	print("CACHED_SHAKER_INPUT: ", "PASS" if failures.is_empty() else failures, " max_offset=", maximum)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)
