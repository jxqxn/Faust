extends GutTest

func test_jsonc_strings_comments_trailing_commas_and_repeated_conditions():
	var parsed = SourceJSON.parse_string('{/*c*/"text":"https://a/*literal*/\\\"", "condition":{"any":{"is":1,"is":2,},"all":{"rare>=":1,"rare>=":3,},},}')
	assert_eq(parsed.text, 'https://a/*literal*/"')
	var ctx := {"acting_card": {"id": 1, "rare": 2}, "acting_card_id": 1}
	assert_true(ConditionEval.evaluate({"any": parsed.condition.any}, ctx), "first same-name OR candidate is retained")
	assert_false(ConditionEval.evaluate({"all": parsed.condition.all}, ctx), "all same-name requirements are enforced")
	ctx.acting_card.rare = 3
	assert_true(ConditionEval.evaluate(parsed.condition, ctx))

func test_repeated_operations_keep_cursor_nested_order_and_status_across_save():
	var config = SourceJSON.parse_string('''{"action":{
		"counter+990001":1,
		"option":{"items":[{"text":"go","tag":"go"}]},
		"case:go":{"counter+990001":2,"prompt":{"id":"pause","text":"wait"},"counter+990001":4},
		"counter+990001":8,
		"counter+990001":16
	}}''')
	var db := ConfigDB.new()
	var state := GameState.new()
	var rng := GameRNG.new(42)
	OperationsSequence.start([config.action], state, db, rng)
	assert_eq(state.get_counter(990001), 1)
	var restored := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(state))), restored, db)
	OperationsSequence.resume(restored.consume_pending_operation(), restored, db, rng, "option:0")
	assert_eq(restored.get_counter(990001), 3)
	var restored_again := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(restored))), restored_again, db)
	OperationsSequence.resume(restored_again.consume_pending_operation(), restored_again, db, rng)
	assert_eq(restored_again.get_counter(990001), 31, "each occurrence runs once in order across both pauses")
	assert_true(restored_again.pending_operations.is_empty())

func test_duplicate_choose_candidates_and_delay_keep_all_occurrences():
	var config = SourceJSON.parse_string('''{"action":{
		"choose:4":{"counter+990001":1,"counter+990001":2,"counter+990001":4},
		"delay":{"id":123,"round":1,"counter+990002":1,"prompt":{"id":"delay","text":"wait"},"counter+990002":2,"all":{"counter+990003":1,"prompt":{"id":"nested","text":"wait"},"counter+990004":2}}
	}}''')
	var db := ConfigDB.new()
	var state := GameState.new()
	var rng := GameRNG.new(42)
	OperationsSequence.start([config.action], state, db, rng)
	assert_eq(state.get_counter(990001), 7)
	var restored := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(state))), restored, db)
	DeferredEffects.execute_due_delays(restored, db, rng)
	assert_eq(restored.get_counter(990002), 1)
	OperationsSequence.resume(restored.consume_pending_operation(), restored, db, rng)
	assert_eq(restored.get_counter(990002), 3)
	assert_eq(restored.get_counter(990003), 1)
	assert_eq(restored.get_counter(990004), 0, "sorted save JSON must not move nested suffix before prompt")
	OperationsSequence.resume(restored.consume_pending_operation(), restored, db, rng)
	assert_eq(restored.get_counter(990004), 2)

func test_original_repeated_event_timings_match_each_candidate_once():
	# [SRC: TimingJsonConverter.Read 0x3a7bc0; raw event/5300157.json]
	var db := ConfigDB.new()
	var source = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/event/5300157.json"))
	db.events[5300157] = source
	var state := GameState.new()
	state.enable_event(5300157, db)
	for rite in [5001100, 5000521, 5000526, 5000641, 5000842, 5000002]:
		assert_eq(state.event_runtime.fire("rite_end", {"rite": rite}), [5300157])
	assert_eq(state.event_runtime.fire("rite_end", {"rite": 123}), [])

func test_raw_opening_has_all_three_rite_operations_and_nested_event_order():
	var source = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/event/5300066.json"))
	var creation: Array = []
	for entry in SourceJSON.entries(source.settlement[0].action):
		for key in entry:
			if key in ["rite", "event_on"]:
				creation.append([key, int(entry[key])])
	assert_eq(creation, [["rite", 5001001], ["rite", 5001501], ["event_on", 5300029], ["rite", 5000001]])

func test_reader_cache_does_not_share_mutable_config_nodes():
	var first = SourceJSON.parse_string('{"action":{"card":1,"card":2}}')
	first.action.clear()
	var second = SourceJSON.parse_string('{"action":{"card":1,"card":2}}')
	assert_eq(second.action.size(), 2)

func test_legacy_eager_adapter_keeps_option_boundary_for_repeated_member_list():
	var config = SourceJSON.parse_string('{"action":{"option":{"items":[{"text":"go","tag":"go"}]},"case:go":{"counter+990001":1,"counter+990001":2},"counter+990002":1,"counter+990002":2}}')
	var state := GameState.new()
	var deferred := ResultExec.execute(config.action, state, ConfigDB.new())
	assert_eq(state.get_counter(990001), 0, "legacy adapter must not execute option branches before a response")
	assert_true(deferred.choose.choices.has("case:go"))
	assert_eq(deferred.choose.choices["case:go"].value.size(), 2)

func test_legacy_save_frame_keeps_its_cursor_and_failed_branch():
	var db := ConfigDB.new()
	var state := GameState.new()
	var operation := {"continuations": [{
		"frames": [{
			"source_json": '{"counter+990001":100,"success":{"counter+990001":200},"failed":{"counter+990001":3},"counter+990002":7}',
			"keys": ["counter+990001", "success", "failed", "counter+990002"], "index": 1,
		}],
		"context": {}, "status": 1, "tag": "",
	}]}
	OperationsSequence.resume(operation, state, db, GameRNG.new(42))
	assert_eq(state.get_counter(990001), 3, "legacy frame neither replays prefix nor loses failed status")
	assert_eq(state.get_counter(990002), 7)
