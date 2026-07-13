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
	RoundLoop.draw_weekly_sudan(state, local_db, RNG.new(701))
	state.schedule_delay({"id": 701, "round": 1, "event_on": 990701}, {"card_uid": 77})
	var saved := SaveSystem.serialize(state)
	var restored := GameState.new()
	SaveSystem.deserialize(saved, restored, local_db)
	assert_eq(restored.delayed_operations.size(), 1)
	assert_eq(int(restored.delayed_operations[0].get("context", {}).get("card_uid", 0)), 77)
	var starting_round := restored.round_number
	var day_result := RoundLoop.advance_day(restored, local_db, RNG.new(702))
	assert_eq(restored.round_number, starting_round, "active Sultan keeps the game in the same round")
	assert_eq(day_result.due_delays.size(), 1, "delay round=1 executes on the next day, not the next Sultan round")
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


func test_v5_save_restores_a_pending_sleep_operation() -> void:
	var state := _state()
	state.queue_operation("sleep", "sleep", {"seconds": 0.5}, {"card_uid": 82})
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(restored.pending_operation().get("kind", ""), "sleep")
	assert_eq(float(restored.pending_operation().get("payload", {}).get("seconds", 0.0)), 0.5)
	assert_eq(int(restored.pending_operation().get("context", {}).get("card_uid", 0)), 82)


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
	assert_true(deferred.choose.has("all"))
	assert_true(deferred.choose.all is Dictionary)
	DeferredEffects.apply(deferred, state, db, RNG.new(705))
	assert_true(state.pending_operations.any(func(operation): return str(operation.get("kind", "")) == "sleep"))
	var group: Dictionary = deferred.choose.all
	DeferredEffects.execute_choice("all", group.get("value", {}), state, db, RNG.new(706))
	var group_prompts := state.pending_operations.filter(func(operation): return str(operation.get("kind", "")) == "prompt")
	assert_eq(group_prompts.size(), 2, "all starts each nested pop operation instead of exposing them as alternatives")


func test_ordered_effects_keep_prompt_before_start_trigger_event() -> void:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events[990702] = {"id": 990702, "on": {}, "start_trigger": true, "condition": {}}
	var state := _state()
	var deferred := ResultExec.execute({
		"prompt": {"id": "before_event", "text": "before"},
		"event_on": 990702,
	}, state, local_db, {"card_uid": 91})
	DeferredEffects.apply(deferred, state, local_db, RNG.new(707))
	assert_eq(state.pending_operations.size(), 2)
	assert_eq(state.pending_operations[0].get("kind", ""), "prompt")
	assert_eq(state.pending_operations[1].get("kind", ""), "event")
	assert_eq(int(state.pending_operations[1].get("context", {}).get("card_uid", 0)), 91)


func test_focused_dsl_audit_is_json_parseable_and_has_no_unknown_target_keys() -> void:
	var report := DslAudit.audit_configs(db.rites, db.events, db.loots, db)
	assert_true(JSON.parse_string(DslAudit.to_json(report)) is Dictionary)
	var targets := [5000001, 5000002, 5001001, 5002006, 5002036, 5002037, 5002038, 5300089, 5300357]
	for family in ["condition", "result", "action"]:
		for key in report[family].unsupported:
			for reference in report[family].references.get(key, []):
				assert_false(int(reference.get("id", 0)) in targets, "%s remains unexplained in focused id %s" % [key, reference.get("id", 0)])


func test_reachability_audit_marks_normal_roots_and_generated_content() -> void:
	var local_db := ConfigDB.new()
	local_db.init_config = {"default_rite": [991000], "event_init_profile_id": 1}
	local_db.cards = {}
	local_db.rites = {
		991000: {"id": 991000, "settlement": [{"result": {"reachable_root_gap": 1}, "action": {"event_on": 992000}}]},
		991001: {"id": 991001, "settlement": [{"result": {"reachable_loot_gap": 1}}]},
		991002: {"id": 991002, "settlement": [{"result": {"unreachable_gap": 1}}]},
	}
	local_db.events = {
		992000: {"id": 992000, "on": {}, "settlement": [{"action": {"loot": 993000}}]},
	}
	local_db.loots = {
		993000: {"id": 993000, "item": [{"id": 991001, "type": "rite"}]},
	}
	var report := DslAudit.audit_potentially_reachable_configs(local_db.rites, local_db.events, local_db.loots, local_db)
	assert_true(991000 in report.reachability.sources.rite, "normal-start rite is a reachability root")
	assert_true(992000 in report.reachability.sources.event, "event_on extends potential reachability")
	assert_true(993000 in report.reachability.sources.loot, "event loot extends potential reachability")
	assert_true(991001 in report.reachability.sources.rite, "rite loot extends potential reachability")
	assert_eq(report.result.references["reachable_root_gap"][0].reachability, "potentially_reachable")
	assert_eq(report.result.references["reachable_loot_gap"][0].reachability, "potentially_reachable")
	assert_eq(report.result.references["unreachable_gap"][0].reachability, "not_reached_by_static_graph")


func test_total_tag_operation_filters_runtime_instances_and_lost_cards() -> void:
	var state := _state()
	var first = state.create_card_instance(2000005, db, "hand")
	var second = state.create_card_instance(2000005, db, "hand")
	var lost = state.create_card_instance(2000005, db, "hand")
	lost.is_lost = true
	ResultExec.execute({"total.2000005+测试标签": 2}, state, db)
	assert_eq(int(first.tags.get("测试标签", 0)), 2)
	assert_eq(int(second.tags.get("测试标签", 0)), 2, "same definition instances are independently modified")
	assert_eq(int(lost.tags.get("测试标签", 0)), 0, "lost instances are excluded by OperationFilter")
	first.tags["门槛"] = 0
	second.tags["门槛"] = 1
	ResultExec.execute({"total.2000005.门槛=0+命中": 1}, state, db)
	assert_eq(int(first.tags.get("命中", 0)), 1, "tag comparison selector matches the runtime instance")
	assert_eq(int(second.tags.get("命中", 0)), 0, "tag comparison selector excludes non-matching instances")


func test_sudan_pool_operations_are_reported_as_supported_dsl():
	assert_true(ResultExec.is_supported_key("sudan_pool.sudan+冻结"))
	assert_true(ResultExec.is_supported_key("total.sudan+冻结"))
	assert_true(ResultExec.is_supported_key("enable_auto_gen_sudan_card"))
	var report := DslAudit.audit_configs({}, {991001: {
		"id": 991001,
		"action": {
			"sudan_pool.sudan+冻结": 1,
			"total.sudan+冻结": 1,
			"enable_auto_gen_sudan_card": false,
		},
	}}, {}, db)
	for key in ["sudan_pool.sudan+冻结", "total.sudan+冻结", "enable_auto_gen_sudan_card"]:
		assert_true(report.action.supported.has(key), "%s has an execution path" % key)
		assert_false(report.action.unsupported.has(key), "%s is not an audit debt" % key)
	for key in ["total.parent+测试标签", "sudan_pool.friend+测试标签", "total.2000005+equip"]:
		assert_false(ResultExec.is_supported_key(key), "%s needs unsupported scope/equip behavior" % key)
	var unsupported_report := DslAudit.audit_configs({}, {991002: {
		"id": 991002,
		"action": {
			"total.parent+测试标签": 1,
			"sudan_pool.friend+测试标签": 1,
			"total.2000005+equip": 1,
		},
	}}, {}, db)
	for key in ["total.parent+测试标签", "sudan_pool.friend+测试标签", "total.2000005+equip"]:
		assert_true(unsupported_report.action.unsupported.has(key), "%s remains explicit audit debt" % key)
