extends GutTest

var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()

func _fixture():
	var state = GameState.new()
	state.configure_source_counters(db)
	var rid = state.add_available_rite(5001501, db, GameRNG.new(3))
	var actor = state.add_card_to_hand(2000001, db)
	var coin = state.add_card_to_hand(2000029, db)
	state.get_card_instance(coin).count = 5
	var paid = state.pay_cost_into_slot(coin, 2, 1, db, rid)
	var info = state.add_card_to_hand(2000421, db)
	state.add_card_to_slot(actor, 1, db, rid)
	state.add_card_to_slot(info, 3, db, rid)
	return {"state":state,"rid":rid,"actor":actor,"coin":coin,"paid":paid,"info":info}

func _selected(f, result = {}, action = {}):
	var selected = RiteResolver.RiteResult.new()
	selected.settlements = [{"result":result,"action":action}]
	selected.entry_contexts = [{}]
	return selected

func _begin(f, selected):
	return RiteSettlement.begin(f.rid, selected, {"rite_id":5001501,"rite_uid":f.rid}, f.state, db, GameRNG.new(3))

func test_normal_consumes_only_paid_slice_and_owned_consumable():
	var f = _fixture()
	_begin(f, _selected(f))
	assert_eq(f.state.coin_count, 4)
	assert_eq(f.state.get_card_instance(f.paid).zone, "removed")
	assert_eq(f.state.get_card_instance(f.info).zone, "removed")
	assert_true(f.state.has_card_in_hand(f.actor))
	assert_false(f.state.get_card_instance(f.actor).tags.has("回收"), "absent non-additive tag must stay absent")
	assert_true(f.state.has_card_in_hand(f.coin))
	assert_null(f.state.get_rite_instance(f.rid))
	var restored = GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(f.state))), restored, db)
	assert_eq(restored.coin_count, 4)
	assert_false(restored.has_card_in_hand(f.info))

func test_recovery_and_non_owned_are_returned_without_recovery():
	for non_owned in [false, true]:
		var f = _fixture()
		if non_owned:
			f.state.get_card_instance(f.info).tags["已拥有"] = -1
		else:
			f.state.get_card_instance(f.info).tags["回收"] = 1
		_begin(f, _selected(f))
		assert_true(f.state.has_card_in_hand(f.info))
		assert_eq(int(f.state.effective_card_tags(f.info, db).get("回收", 0)), 0)
		assert_eq(f.state.coin_count, 4)

func test_timeout_returns_consumables_and_preserves_recovery():
	var f = _fixture()
	f.state.get_card_instance(f.info).tags["回收"] = 1
	RiteSettlement.expire(f.rid, f.state, db, GameRNG.new(3))
	assert_eq(f.state.coin_count, 5)
	assert_true(f.state.has_card_in_hand(f.info))
	assert_eq(int(f.state.effective_card_tags(f.info, db).get("回收", 0)), 1)

func test_real_bath_success_and_failure_both_consume_fee_and_info():
	var saw_success = false
	var saw_failure = false
	for seed_value in range(40):
		var f = _fixture()
		var rng = GameRNG.new(seed_value)
		var res = RoundLoop._resolve_rite_instance(db.get_rite(5001501), f.state.get_rite_instance(f.rid), f.state, db, rng)
		for step in range(80):
			if not f.state.pending_operations.is_empty():
				var op = f.state.consume_pending_operation()
				assert_true(op.get("payload", {}).get("choices", {}).is_empty())
				OperationsSequence.resume(op, f.state, db, rng)
			RiteSettlement.pump(f.state, db, rng)
			if f.state.rite_settlements.is_empty(): break
		var successes = res.dice_rolls.filter(func(face): return face >= 5).size()
		saw_success = saw_success or successes > 0
		saw_failure = saw_failure or successes == 0
		assert_eq(f.state.get_card_instance(f.paid).zone, "removed")
		assert_eq(f.state.get_card_instance(f.info).zone, "removed")
		assert_eq(f.state.coin_count, 4)
		if saw_success and saw_failure: break
	assert_true(saw_success)
	assert_true(saw_failure)

func test_clean_events_suspend_after_return_and_resume_once_after_save():
	var eid = 9999001
	db.events[eid] = {"id":eid,"is_replay":1,"on":{"card_clean":1},"condition":{},"settlement":[{"action":{"counter+7999001":1,"prompt":{"id":"clean_pause","text":"pause"}}}]}
	var f = _fixture()
	f.state._rebuild_event_runtime(db)
	f.state.enable_event(eid, db)
	_begin(f, _selected(f, {}, {"counter+7999002":1}))
	assert_true(f.state.has_card_in_hand(f.actor), "all survivors return before first clean event")
	assert_false(f.state.has_card_in_hand(f.info))
	assert_eq(f.state.get_counter(7999001), 1)
	assert_eq(f.state.get_counter(7999002), 0)
	var restored = GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(f.state))), restored, db)
	for step in range(5):
		if not restored.pending_operations.is_empty():
			OperationsSequence.resume(restored.consume_pending_operation(), restored, db, GameRNG.new(3))
		RiteSettlement.pump(restored, db, GameRNG.new(3))
	assert_eq(restored.get_counter(7999001), 2, "exactly one event per consumed card")
	assert_eq(restored.get_counter(7999002), 1, "final actions execute after clean events")
	assert_eq(restored.coin_count, 4)
	assert_eq(restored.get_card_instance(f.info).zone, "removed")
	db.events.erase(eid)

func test_bath_result_real_mouse_consumes_and_reload_does_not_refund():
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		var f = _fixture()
		f.state.start_rite_instance(f.rid)
		f.state.get_rite_instance(f.rid).life = int(db.get_rite(5001501).get("round_number", 1))
		var viewport = SubViewport.new()
		viewport.size = dimensions
		viewport.handle_input_locally = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child_autofree(viewport)
		var view = preload("res://ui/rite_view.gd").new()
		view.setup(f.state, db, GameRNG.new(3), 5001501, f.rid)
		viewport.add_child(view)
		await wait_process_frames(2)
		await _click(viewport, view._resolve_btn)
		assert_true(view._resolution_pending)
		for step in range(40):
			if view._resolution_committed: break
			if view._result_next_button.visible and not view._result_next_button.disabled:
				await _click(viewport, view._result_next_button)
			await wait_seconds(0.05)
		assert_true(view._resolution_committed)
		assert_eq(f.state.coin_count, 4)
		assert_false(f.state.has_card_in_hand(f.info))
		assert_true(f.state.has_card_in_hand(f.actor))
		var restored = GameState.new()
		SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(f.state))), restored, db)
		assert_eq(restored.coin_count, 4)
		assert_false(restored.has_card_in_hand(f.info))
		viewport.queue_free()
		await wait_process_frames(2)

func _click(viewport, button):
	var motion = InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(), button, "real mouse hits target")
	for pressed in [true, false]:
		var click = InputEventMouseButton.new()
		click.position = motion.position
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		viewport.push_input(click, true)
	await wait_process_frames(2)
