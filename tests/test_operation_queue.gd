extends GutTest

const RNG = preload("res://core/rng.gd")

var db: ConfigDB


func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()


func _state() -> GameState:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(701))
	state.pending_operations.clear()
	return state


func test_same_event_id_keeps_distinct_occurrence_contexts_in_order() -> void:
	var state := _state()
	state.queue_event(990001, {"card_uid": 11, "rite_uid": 21})
	state.queue_event(990001, {"card_uid": 12, "rite_uid": 22})
	assert_eq(state.pending_operations.size(), 2)
	assert_eq(int(state.pending_operation().get("context", {}).get("card_uid", 0)), 11)
	state.consume_pending_operation()
	assert_eq(int(state.pending_operation().get("context", {}).get("card_uid", 0)), 12)


func test_prompt_event_and_choice_use_one_fifo_queue() -> void:
	var state := _state()
	state.queue_event(990002, {"card_uid": 1})
	state.queue_prompt({"id": "notice", "text": "first"})
	state.queue_choice_prompt({"pop.test": "second"}, "choice", "body", {"rite_uid": 4})
	assert_eq(state.pending_operation().get("kind", ""), "event")
	state.consume_pending_operation()
	assert_eq(state.pending_operation().get("kind", ""), "prompt")
	state.consume_pending_operation()
	assert_eq(state.pending_operation().get("kind", ""), "choice")
	assert_eq(int(state.pending_operation().get("context", {}).get("rite_uid", 0)), 4)


func test_delay_survives_v5_save_and_executes_once_when_due() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events[990701] = {"id": 990701, "on": {}, "start_trigger": false, "condition": {}}
	var state := _state()
	state.schedule_delay({"id": 701, "round": 1, "event_on": 990701}, {"card_uid": 77})
	var saved := SaveSystem.serialize(state)
	var restored := GameState.new()
	SaveSystem.deserialize(saved, restored, local_db)
	assert_eq(restored.delayed_operations.size(), 1)
	assert_eq(int(restored.delayed_operations[0].get("context", {}).get("card_uid", 0)), 77)
	restored.round_number += 1
	var executed := DeferredEffects.execute_due_delays(restored, local_db, RNG.new(702))
	assert_eq(executed.size(), 1)
	assert_true(restored.is_event_enabled(990701))
	assert_true(restored.delayed_operations.is_empty())
	assert_true(DeferredEffects.execute_due_delays(restored, local_db, RNG.new(703)).is_empty(), "due delays are removed before execution")


func test_legacy_v5_split_queues_are_synthesized() -> void:
	var legacy := SaveSystem.serialize(_state())
	legacy.erase("pending_operations")
	legacy.erase("delayed_operations")
	legacy["event_queue"] = [990801]
	legacy["event_contexts"] = {"990801": {"card_uid": 81}}
	legacy["event_prompts"] = [{"id": "legacy", "text": "prompt"}]
	var restored := GameState.new()
	SaveSystem.deserialize(legacy, restored, db)
	assert_eq(restored.pending_operations.size(), 2)
	assert_eq(restored.pending_operation().get("kind", ""), "event")
	assert_eq(int(restored.pending_operation().get("context", {}).get("card_uid", 0)), 81)
	restored.consume_pending_operation()
	assert_eq(restored.pending_operation().get("kind", ""), "prompt")


func test_focused_rite_loot_and_table_clean_dsl_uses_runtime_instances() -> void:
	var state := _state()
	var ctx := {"db": db, "state": state, "rng": RNG.new(704), "rite_state": {}, "attr_slots": []}
	assert_true(ConditionEval.eval_key("!rite", 990901, ctx))
	state.create_rite_instance(990901)
	assert_false(ConditionEval.eval_key("!rite", 990901, ctx))
	assert_true(ConditionEval.eval_key("!loot", 9999999, ctx))
	assert_false(ConditionEval.eval_key("!loot", 6000005, ctx))
	var rite_a := state.create_rite_instance(990902)
	var rite_b := state.create_rite_instance(990903)
	var card_a = state.create_card_instance(2000005, db, "hand")
	var card_b = state.create_card_instance(2000005, db, "hand")
	state.add_card_to_slot(card_a.uid, 1, db, rite_a.uid)
	state.add_card_to_slot(card_b.uid, 1, db, rite_b.uid)
	ResultExec.execute({"table.clean.2000005": 1}, state, db, {"rite_uid": rite_a.uid, "card_uid": card_a.uid})
	assert_eq(card_a.zone, "removed")
	assert_eq(card_b.zone, "slot", "same-id cards in other rites are not cleaned")


func test_no_prompt_sleep_and_choose_all_are_explicitly_handled() -> void:
	var state := _state()
	var deferred := ResultExec.execute({
		"no_prompt": {"coin": 3},
		"sleep": 0.25,
		"choose": {"all": {"pop.one": "one", "pop.two": "two"}},
	}, state, db)
	assert_eq(state.coin_count, 3)
	assert_eq(float(deferred.sleeps[0].get("seconds", 0.0)), 0.25)
	assert_true(deferred.choose.has("pop.one"))
	assert_true(deferred.choose.has("pop.two"))
	DeferredEffects.apply(deferred, state, db, RNG.new(705))
	assert_true(state.pending_operations.any(func(operation): return str(operation.get("kind", "")) == "sleep"))


func test_focused_dsl_audit_is_json_parseable_and_has_no_unknown_target_keys() -> void:
	var report := DslAudit.audit_configs(db.rites, db.events, db.loots, db)
	assert_true(JSON.parse_string(DslAudit.to_json(report)) is Dictionary)
	var targets := [5000001, 5000002, 5001001, 5002006, 5002036, 5002037, 5002038, 5300089, 5300357]
	for family in ["condition", "result", "action"]:
		for key in report[family].unsupported:
			for reference in report[family].references.get(key, []):
				assert_false(int(reference.get("id", 0)) in targets, "%s remains unexplained in focused id %s" % [key, reference.get("id", 0)])
