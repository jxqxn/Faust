extends GutTest

var db: ConfigDB

func test_final_results_and_actions_reset_to_source_failed_status() -> void:
	var state := GameState.new()
	var rng := GameRNG.new(17)
	var rite = state.create_rite_instance(5000001)
	var context := {"state": state, "db": db, "rng": rng, "rite_uid": rite.uid}
	var definition := {"settlement": [{"result": {"failed": {"coin": 2}},
		"action": {"failed": {"coin": 3}}}]}
	RiteSettlement.begin(rite.uid, RiteResolver.select_settlements(definition, context), context, state, db, rng)
	assert_eq(state.coin_count, 5, "both source final queues call SetLastOpState(FAILED) before each entry")

func test_source_side_selectors_keep_same_non_enemy_branch_before_and_after_return() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.rites[990801] = {"id": 990801, "cards_slot": {"s1": {}, "s2": {"is_enemy": 1}},
		"settlement": [{"result": {"friend+印记": 1, "enemy+印记": 1},
			"action": {"friend+印记": 1, "enemy+印记": 1}}]}
	var state := GameState.new()
	var rng := GameRNG.new(15)
	var rite = state.create_rite_instance(990801)
	var friend_uid := state.add_card_to_hand(2000001, local_db)
	var enemy_uid := state.add_card_to_hand(2000005, local_db)
	for pair in [[friend_uid, 1], [enemy_uid, 2]]:
		state.remove_card_from_hand(int(pair[0]))
		state.add_card_to_slot(int(pair[0]), int(pair[1]), local_db, rite.uid)
	var context := {"state": state, "db": local_db, "rng": rng, "rite_uid": rite.uid}
	var selected := RiteResolver.select_settlements(local_db.get_rite(rite.id), context)
	RiteSettlement.begin(rite.uid, selected, context, state, local_db, rng)
	assert_eq(int(state.get_card_instance(friend_uid).tags.get("印记", 0)), 4)
	assert_eq(int(state.get_card_instance(enemy_uid).tags.get("印记", 0)), 0,
		"OperationFilter side selectors differ from FuncCompare enemy expressions")

func test_think_slot_pop_starts_with_original_failed_status() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events.clear() # Exercise only this synthetic think continuation.
	local_db.rites[5000002] = {"id": 5000002, "cards_slot": {"s1": {"pops": [
		{"condition": {}, "action": {"failed": {"coin": 2}}}]}}, "settlement": []}
	var state := GameState.new()
	var rng := GameRNG.new(16)
	var uid := state.add_card_to_hand(2000001, local_db)
	MethinksEngine.process_card(uid, "hand", state, local_db, rng)
	assert_eq(state.coin_count, 2, "ProcessPop calls SetLastOpState(FAILED) before SlotPop")

func test_final_actions_keep_returned_slot_references_across_reload() -> void:
	var state := GameState.new()
	var rng := GameRNG.new(12)
	var rite = state.create_rite_instance(5000001)
	var uid := state.add_card_to_hand(2000001, db)
	state.remove_card_from_hand(uid)
	state.add_card_to_slot(uid, 1, db, rite.uid)
	var context := {"state": state, "db": db, "rng": rng, "rite_uid": rite.uid}
	var definition := {"settlement": [{"action": {
		"prompt": {"id": "returned_wait"}, "s1+印记": 1, "clean.s1": 1}}]}
	RiteSettlement.begin(rite.uid, RiteResolver.select_settlements(definition, context), context, state, db, rng)
	assert_true(state.has_card_in_hand(uid), "ReturnCards precedes action prompt")
	assert_true(state.cards_in_slot_entries_for_rite(rite.uid).is_empty())
	var restored := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(state))), restored, db)
	OperationsSequence.resume(restored.consume_pending_operation(), restored, db, rng)
	RiteSettlement.pump(restored, db, rng)
	var card = restored.get_card_instance(uid)
	assert_eq(int(card.tags.get("印记", 0)), 1, "action still addresses returned s1 after reload")
	assert_eq(card.zone, "removed", "clean.s1 consumes that same returned card")
	assert_false(restored.has_card_in_hand(uid), "finalizer never resurrects a cleaned card")


func test_equipment_inherits_shelter_and_post_rite_expiry_does_not_age_twice() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.cards[990601] = {"id": 990601, "type": "item", "tag": {}, "card_vanishing": 1,
		"vanish": {"prompt": {"id": "equipment_expired"}, "coin": 2}}
	var state := GameState.new()
	var rng := GameRNG.new(13)
	var rite = state.create_rite_instance(5000001)
	var uid := state.add_card_to_hand(2000001, local_db)
	var equip = state.create_card_instance(990601, local_db, "removed")
	state.attach_equipment(uid, equip.uid, local_db, false, false)
	state.remove_card_from_hand(uid)
	state.add_card_to_slot(uid, 1, local_db, rite.uid)
	var unused = state.create_card_instance(2000001, local_db, "pool")
	RoundLoop._update_card_lives(state, local_db, rng)
	assert_eq(equip.life, 1)
	assert_true(equip.uid in state.get_card_instance(uid).equipped_uids, "host shelter also protects expired equipment")
	assert_eq(unused.life, 0, "unowned registry objects do not age")
	var context := {"state": state, "db": local_db, "rng": rng, "rite_uid": rite.uid}
	RiteSettlement.begin(rite.uid, RiteResolver.select_settlements({}, context), context, state, local_db, rng)
	assert_eq(equip.life, 1, "DoPostRite checks expiry without increasing age")
	assert_false(equip.uid in state.get_card_instance(uid).equipped_uids)
	assert_eq(state.pending_operations.size(), 1, "equipment vanish can suspend post-rite cleanup")
	var restored := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(state))), restored, local_db)
	OperationsSequence.resume(restored.consume_pending_operation(), restored, local_db, rng)
	RiteSettlement.pump(restored, local_db, rng)
	assert_eq(restored.coin_count, 2)
	assert_true(restored.rite_settlements.is_empty())

class ConfirmationProbe extends GameState:
	var calls: Array[String] = []
	func trigger_events(timing: String, _ctx: Dictionary = {}) -> Array[int]:
		calls.append(timing)
		if timing == "rite_start":
			queue_prompt({"id": "start_wait"})
		return []

class TimeoutProbe extends GameState:
	func trigger_events(timing: String, _ctx: Dictionary = {}) -> Array[int]:
		if timing == "rite_clean":
			queue_prompt({"id": "clean_wait"})
		return []

class DayTimingProbe extends GameState:
	var calls: Array[String] = []
	func trigger_events(timing: String, _ctx: Dictionary = {}) -> Array[int]:
		calls.append("%s:%d" % [timing, round_number])
		if timing in ["round_end", "round_begin_fr"]:
			queue_prompt({"id": timing})
		return []

func test_day_awaits_round_end_then_increments_before_front_events_and_rites() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.rites[990802] = {"id": 990802, "cards_slot": {}, "waiting_round": 99, "auto_begin": 0}
	var state := DayTimingProbe.new()
	state.auto_gen_sudan_card = false
	var rng := GameRNG.new(14)
	var uid := state.add_card_to_hand(2000001, local_db)
	var rite = state.create_rite_instance(990802)
	var initial_round := state.round_number
	RoundLoop.advance_day(state, local_db, rng)
	assert_eq(state.get_card_instance(uid).life, 1, "card aging precedes round_end")
	assert_eq(state.round_number, initial_round, "round_end prompt blocks increment")
	assert_eq(rite.life, 0)
	OperationsSequence.resume(state.consume_pending_operation(), state, local_db, rng)
	RoundLoop.resume_day(state, local_db, rng)
	assert_eq(state.round_number, initial_round + 1)
	assert_eq(rite.life, 0, "front-of-round prompt precedes rite update")
	assert_eq(state.calls, ["round_end:%d" % initial_round, "round_begin_fr:%d" % (initial_round + 1)])
	var restored := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(state))), restored, local_db)
	OperationsSequence.resume(restored.consume_pending_operation(), restored, local_db, rng)
	RoundLoop.resume_day(restored, local_db, rng)
	assert_eq(restored.get_card_instance(uid).life, 1, "restoring front-of-round wait does not age again")
	assert_eq(restored.round_number, initial_round + 1)
	assert_eq(restored.get_rite_instance(rite.uid).life, 1)
	assert_true(restored.round_transition.is_empty())

func test_timeout_waits_before_selection_and_returns_before_actions_after_reload() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.rites[990501] = {"id": 990501, "waiting_round": 1, "cards_slot": {"s1": {}},
		"waiting_round_end_action": [
			{"condition": {"counter.7100001=": 1}, "result": {"prompt": {"id": "result_wait"}, "counter+7100001": 1},
				"action": {"prompt": {"id": "action_wait"}, "coin": 2}},
			{"condition": {"counter.7100001=": 1}, "result": {"coin": 3}},
			{"condition": {"counter.7100001=": 2}, "result": {"coin": 100}},
		]}
	var state := TimeoutProbe.new()
	state.auto_gen_sudan_card = false
	var rng := GameRNG.new(11)
	var rite = state.create_rite_instance(990501)
	var uid := state.add_card_to_hand(2000001, local_db)
	state.remove_card_from_hand(uid)
	state.add_card_to_slot(uid, 1, local_db, rite.uid)
	RoundLoop.advance_day(state, local_db, rng)
	assert_eq(str(state.pending_operations[0].id), "clean_wait")
	assert_eq(state.get_card_instance(uid).zone, "slot")
	state.set_counter(7100001, 1)
	OperationsSequence.resume(state.consume_pending_operation(), state, local_db, rng)
	RoundLoop.resume_day(state, local_db, rng)
	assert_eq(str(state.pending_operations[0].id), "result_wait", "selection observes completed rite_clean")
	var restored := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(state))), restored, local_db)
	OperationsSequence.resume(restored.consume_pending_operation(), restored, local_db, rng)
	RoundLoop.resume_day(restored, local_db, rng)
	assert_eq(restored.coin_count, 3, "all timeout conditions were selected before any reward")
	assert_true(restored.has_card_in_hand(uid), "card returned before action prompt")
	assert_not_null(restored.get_rite_instance(rite.uid), "action still owns the live rite")
	OperationsSequence.resume(restored.consume_pending_operation(), restored, local_db, rng)
	RoundLoop.resume_day(restored, local_db, rng)
	assert_eq(restored.coin_count, 5)
	assert_null(restored.get_rite_instance(rite.uid))
	assert_false(restored.has_rite_ended(rite.id), "expiry is not successful settlement")

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func test_manual_confirmation_waits_for_start_event_and_resets_running_life() -> void:
	var state := ConfirmationProbe.new()
	var rite = state.create_rite_instance(5000001)
	rite.life = 3
	state.start_rite_instance(rite.uid)
	RiteSettlement.confirm_start(rite.uid, state)
	assert_eq(rite.start_life, 3)
	assert_eq(rite.life, 0)
	assert_eq(state.calls, ["rite_start"])
	RiteSettlement.pump_confirmations(state)
	assert_eq(state.calls, ["rite_start"], "pending start prompt suspends rite_begin")
	state.consume_pending_operation()
	RiteSettlement.pump_confirmations(state)
	assert_eq(state.calls, ["rite_start", "rite_begin"])
	RiteSettlement.pump_confirmations(state)
	assert_eq(state.calls.size(), 2, "completed confirmation cannot repeat its events")

func test_selection_does_not_apply_results_or_actions() -> void:
	var state := GameState.new()
	var ctx := {"state": state, "db": db, "rng": GameRNG.new(1)}
	var definition := {"settlement": [{"condition": {}, "result": {"coin": 2}, "action": {"coin": 4}}]}
	var selected := RiteResolver.select_settlements(definition, ctx)
	assert_eq(selected.settlements.size(), 1)
	assert_eq(state.coin_count, 0, "EnqueueSettlement only records finalResults/finalOperations")

func test_all_conditions_observe_state_before_final_results() -> void:
	# [SRC: EnqueueSettlement 0x5a2d10 and finalResults execution 0x5b3a50;
	# dump.cs finalResults+0x110 / finalOperations+0x118.]
	var state := GameState.new()
	var ctx := {"state": state, "db": db, "rng": GameRNG.new(1)}
	var definition := {
		"settlement": [{"condition": {}, "result": {"counter+7100001": 1}, "action": {"coin": 10}}],
		"settlement_extre": [
			{"condition": {"counter.7100001=": 0}, "result": {"coin": 2}, "action": {"coin": 20}},
			{"condition": {"counter.7100001>": 0}, "result": {"coin": 100}, "action": {}},
		],
	}
	var result := RiteResolver.resolve(definition, ctx)
	assert_eq(result.extre_log.size(), 1)
	assert_eq(state.coin_count, 32, "the normal reward cannot activate a later extra condition")
	assert_eq(result.deferred.logs.filter(func(line): return str(line).begins_with("coin")), ["coin +2", "coin +10", "coin +20"], "all finalResults precede finalOperations")

func test_think_uses_prior_and_shared_normal_exclusion() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events.clear() # Exercise only this synthetic think continuation.
	local_db.rites[5000002] = {
		"id": 5000002,
		"settlement_prior": [{"condition": {}, "result": {"coin": 2}, "action": {}}],
		"settlement": [{"condition": {}, "result": {"coin": 10}, "action": {}}],
		"settlement_extre": [{"condition": {}, "result": {"coin": 100}, "action": {}}],
	}
	var state := GameState.new()
	var uid := state.add_card_to_hand(2000001, local_db)
	var result := MethinksEngine.process_card(uid, "hand", state, local_db, GameRNG.new(2))
	assert_true(result.accepted)
	assert_eq(state.coin_count, 2, "IThink no longer bypasses the prior settlement")
	assert_true(state.has_card_in_hand(uid))

func test_phase_waits_for_choice_before_sibling_and_next_entry() -> void:
	var state := GameState.new()
	var rng := GameRNG.new(3)
	var ctx := {"state": state, "db": db, "rng": rng}
	var definition := {
		"settlement": [{"condition": {}, "result": {
			"option": {"text": "Choose", "items": [{"text": "A", "tag": "a"}]},
			"case:a": {"coin": 2}, "coin": 3,
		}}],
		"settlement_extre": [{"condition": {}, "result": {"coin": 5}}],
	}
	var selected := RiteResolver.select_settlements(definition, ctx)
	RiteResolver.execute_phase(selected, "result", ctx)
	assert_eq(state.coin_count, 0, "no later result executes before the option response")
	assert_eq(state.pending_operations.size(), 1)
	var operation: Dictionary = state.consume_pending_operation()
	OperationsSequence.resume(operation, state, db, rng, "option:0")
	assert_eq(state.coin_count, 10, "chosen case, sibling, and following entry execute in order")
	assert_true(state.pending_operations.is_empty())

func test_settlement_resumes_after_save_without_repeating_reward() -> void:
	var state := GameState.new()
	var rng := GameRNG.new(4)
	var rite = state.create_rite_instance(5000001)
	var ctx := {"state": state, "db": db, "rng": rng, "rite_uid": rite.uid, "rite_id": rite.id}
	var definition := {"settlement": [{"condition": {},
		"result": {"coin": 2, "prompt": {"id": "checkpoint", "text": "Wait"}, "金币": 3},
		"action": {"coin": 5}}]}
	var selected := RiteResolver.select_settlements(definition, ctx)
	RiteSettlement.begin(rite.uid, selected, ctx, state, db, rng)
	assert_eq(state.coin_count, 2)
	assert_not_null(state.get_rite_instance(rite.uid))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveSystem.serialize(state)))
	var restored := GameState.new()
	SaveSystem.deserialize(saved, restored, db)
	assert_eq(restored.rite_settlements.size(), 1)
	var operation := restored.consume_pending_operation()
	OperationsSequence.resume(operation, restored, db, rng)
	RiteSettlement.pump(restored, db, rng)
	assert_eq(restored.coin_count, 10)
	assert_null(restored.get_rite_instance(rite.uid))
	assert_true(restored.rite_settlements.is_empty())
	RiteSettlement.pump(restored, db, rng)
	assert_eq(restored.coin_count, 10, "completion is idempotent")

func test_clean_after_prompt_is_scoped_to_the_correct_runtime_rite() -> void:
	var state := GameState.new()
	var rng := GameRNG.new(5)
	var rite = state.create_rite_instance(5000001)
	var other = state.create_rite_instance(5000001)
	var uid := state.add_card_to_hand(2000001, db)
	var other_uid := state.add_card_to_hand(2000005, db)
	state.remove_card_from_hand(uid)
	state.add_card_to_slot(uid, 1, db, rite.uid)
	state.remove_card_from_hand(other_uid)
	state.add_card_to_slot(other_uid, 1, db, other.uid)
	var ctx := {"state": state, "db": db, "rng": rng, "rite_uid": rite.uid, "rite_id": rite.id}
	var selected := RiteResolver.select_settlements({"settlement": [{"condition": {}, "result": {"prompt": {"id": "wait"}, "clean.s1": 1}}]}, ctx)
	RiteSettlement.begin(rite.uid, selected, ctx, state, db, rng)
	OperationsSequence.resume(state.consume_pending_operation(), state, db, rng)
	RiteSettlement.pump(state, db, rng)
	assert_eq(state.get_card_instance(other_uid).rite_uid, other.uid)
	assert_false(state.has_card_in_hand(uid), "cleaned card is not restored")
	assert_null(state.get_rite_instance(rite.uid))
	assert_not_null(state.get_rite_instance(other.uid))


func test_think_waits_for_pops_and_animation_lock_then_shared_results() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events.clear() # Exercise only this synthetic think continuation.
	local_db.rites[5000002] = {"id": 5000002,
		"cards_slot": {"s1": {"pops": [{"condition": {}, "action": {"prompt": {"id": "pop"}}}]}},
		"settlement": [{"condition": {}, "result": {"coin": 2}, "action": {"prompt": {"id": "result"}}}]}
	var state := GameState.new()
	var rng := GameRNG.new(7)
	var uid := state.add_card_to_hand(2000001, local_db)
	assert_true(MethinksEngine.process_card(uid, "hand", state, local_db, rng, true).accepted)
	assert_eq(state.ithink_card_uid, uid)
	assert_false(state.has_card_in_hand(uid))
	assert_eq(state.coin_count, 0, "SlotPop is before settlement")
	assert_false(MethinksEngine.process_card(uid, "hand", state, local_db, rng, true).accepted)
	OperationsSequence.resume(state.consume_pending_operation(), state, local_db, rng)
	MethinksEngine.pump(state, local_db, rng)
	assert_eq(state.think_session.stage, "wait_lock")
	assert_eq(state.coin_count, 0, "reward waits for OnCardLocked")
	var restored := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(state))), restored, local_db)
	MethinksEngine.pump(restored, local_db, rng, true)
	assert_eq(restored.coin_count, 2)
	assert_false(restored.think_session.is_empty(), "action prompt holds the busy state")
	OperationsSequence.resume(restored.consume_pending_operation(), restored, local_db, rng)
	MethinksEngine.pump(restored, local_db, rng)
	assert_true(restored.think_session.is_empty())
	assert_eq(restored.ithink_card_uid, 0)
	assert_true(restored.has_card_in_hand(uid))
	assert_eq(restored.coin_count, 2)


func test_saved_future_action_retains_raw_order_and_entry_status_is_reset() -> void:
	var state := GameState.new()
	var rng := GameRNG.new(8)
	var rite = state.create_rite_instance(5000001)
	var ctx := {"state": state, "db": db, "rng": rng, "rite_uid": rite.uid, "rite_id": rite.id}
	var definition := {"settlement": [{"result": {"prompt": {"id": "wait"}},
		"action": {"option": {"items": [{"text": "A", "tag": "a"}]}, "case:a": {"coin": 2}}}],
		"settlement_extre": [{"action": {"case:a": {"coin": 100}, "coin": 3}}]}
	RiteSettlement.begin(rite.uid, RiteResolver.select_settlements(definition, ctx), ctx, state, db, rng)
	var restored := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(state))), restored, db)
	OperationsSequence.resume(restored.consume_pending_operation(), restored, db, rng)
	RiteSettlement.pump(restored, db, rng)
	assert_eq(restored.coin_count, 0)
	OperationsSequence.resume(restored.consume_pending_operation(), restored, db, rng, "option:0")
	RiteSettlement.pump(restored, db, rng)
	assert_eq(restored.coin_count, 5, "case follows option after save; tag cannot leak to next entry")


func test_day_updates_rites_serially_and_cannot_advance_again_while_waiting() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.rites[990301] = {"id": 990301, "round_number": 1, "cards_slot": {},
		"settlement": [{"result": {"prompt": {"id": "first"}}, "action": {"coin": 2}}]}
	local_db.rites[990302] = {"id": 990302, "round_number": 1, "cards_slot": {},
		"settlement": [{"result": {"coin": 3}}]}
	var state := GameState.new()
	state.auto_gen_sudan_card = false
	var rng := GameRNG.new(9)
	var first = state.create_rite_instance(990301)
	var second = state.create_rite_instance(990302)
	state.start_rite_instance(first.uid)
	state.start_rite_instance(second.uid)
	var day := state.day
	var round_number := state.round_number
	RoundLoop.advance_day(state, local_db, rng)
	assert_eq(state.day, day + 1)
	assert_eq(second.life, 0, "second rite has not been updated while first awaits its response")
	assert_eq(state.round_number, round_number + 1, "OnNextRound increments round before DoRiteUpdate")
	RoundLoop.advance_day(state, local_db, rng)
	assert_eq(state.day, day + 1, "pending transition cannot advance twice")
	OperationsSequence.resume(state.consume_pending_operation(), state, local_db, rng)
	RoundLoop.resume_day(state, local_db, rng)
	assert_eq(state.coin_count, 5)
	assert_eq(state.round_number, round_number + 1)
	assert_true(state.round_transition.is_empty())
	assert_null(state.get_rite_instance(first.uid))
	assert_null(state.get_rite_instance(second.uid))


func test_card_post_rite_is_selected_before_rewards_and_keeps_its_self_context() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.cards[990401] = {"id": 990401, "type": "item", "tag": {},
		"post_rite": [{"condition": {"counter.7100001=": 0},
			"result": {"clean.self": 1}, "action": {"coin": 3}}]}
	local_db.rites[990402] = {"id": 990402, "cards_slot": {"s1": {}},
		"settlement_prior": [{"result": {"counter+7100001": 1}, "action": {"coin": 2}}]}
	var state := GameState.new()
	var rng := GameRNG.new(10)
	var rite = state.create_rite_instance(990402)
	var uid := state.add_card_to_hand(990401, local_db)
	state.remove_card_from_hand(uid)
	state.add_card_to_slot(uid, 1, local_db, rite.uid)
	var ctx := {"state": state, "db": local_db, "rng": rng, "rite_uid": rite.uid,
		"slot_entries": state.slot_entries_for_rite(local_db.get_rite(rite.id), rite.uid)}
	var selected := RiteResolver.select_settlements(local_db.get_rite(rite.id), ctx)
	assert_eq(selected.settlements.size(), 2, "card extra still participates after a matched prior")
	assert_eq(state.get_card_instance(uid).zone, "slot", "selection does not consume the card")
	RiteSettlement.begin(rite.uid, selected, ctx, state, local_db, rng)
	assert_eq(state.coin_count, 5)
	assert_eq(state.get_card_instance(uid).zone, "removed", "clean.self uses the card extra owner and cannot resurrect at return")
