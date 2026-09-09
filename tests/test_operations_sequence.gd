extends GutTest

var db: ConfigDB
var rng: GameRNG

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func before_each() -> void:
	rng = GameRNG.new(913)

func _state() -> GameState:
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.pending_operations.clear()
	return state

func _finish(state: GameState, choice: String = "") -> void:
	var operation := state.consume_pending_operation()
	OperationsSequence.resume(operation, state, db, rng, choice)

func test_original_confirm_waits_before_enabling_tutorial_event() -> void:
	# [SRC: event/5300000.json; Confirm callback 0x5061a0 -> SetLastOpState.]
	for choice in ["confirm_ok", "confirm_cancel"]:
		var state := _state()
		DeferredEffects.execute_event(db.get_event(5300000), state, db, rng)
		assert_false(state.is_event_enabled(5300066), "neither branch runs before the response")
		assert_true(state.pending_operation().has("continuations"))
		_finish(state, choice)
		assert_true(state.event_done.get(5300066, false), "both branches dispatch the non-replay start event")
		assert_eq(state.pending_operation().payload.id, "5300066_prompt_01")
		assert_eq(state.last_confirm_cancelled, choice == "confirm_cancel")

func test_cancel_skips_success_without_erasing_failed_status() -> void:
	# Boundary fixture for the verified Success/Failed Do truth table.
	var state := _state()
	OperationsSequence.start([{
		"confirm": {"text": "confirm"},
		"success": {"counter+990001": 20},
		"failed": {"counter+990001": 3},
		"counter+990002": 7,
	}], state, db, rng)
	assert_eq(state.get_counter(990001), 0)
	assert_eq(state.get_counter(990002), 0)
	_finish(state, "confirm_cancel")
	assert_eq(state.get_counter(990001), 3, "unmatched success must preserve failure")
	assert_eq(state.get_counter(990002), 7, "siblings continue after the branch")

func test_save_load_retains_nested_source_order_and_already_executed_cursor() -> void:
	var state := _state()
	OperationsSequence.start([{
		"counter+990001": 1,
		"option": {"items": [{"text": "go", "tag": "go"}]},
		"case:go": {"prompt": {"id": "nested", "text": "wait"}, "counter+990002": 4},
		"counter+990003": 8,
	}], state, db, rng)
	# Real serializer, including JSON's default alphabetical dictionary ordering.
	var restored := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(state))), restored, db)
	_finish(restored, "option:0")
	assert_eq(restored.get_counter(990001), 1, "prefix does not replay")
	assert_eq(restored.get_counter(990002), 0, "nested prompt must still precede its counter")
	assert_eq(restored.get_counter(990003), 0)
	assert_eq(restored.pending_operation().payload.id, "nested")
	var restored_again := GameState.new()
	SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(restored))), restored_again, db)
	_finish(restored_again)
	assert_eq(restored_again.get_counter(990001), 1)
	assert_eq(restored_again.get_counter(990002), 4)
	assert_eq(restored_again.get_counter(990003), 8)
	assert_true(restored_again.pending_operations.is_empty())

func test_option_keeps_common_siblings_and_numeric_case_index() -> void:
	var state := _state()
	OperationsSequence.start([{
		"counter+990001": 1,
		"option": {"items": [{"text": "a", "tag": "a"}, {"text": "b", "tag": "b"}]},
		"case:a": {"counter+990001": 100},
		"case:2": {"counter+990001": 2},
		"case:b": {"counter+990001": 1000},
		"counter+990002": 9,
	}], state, db, rng)
	assert_eq(state.get_counter(990001), 1)
	_finish(state, "option:1")
	assert_eq(state.get_counter(990001), 3, "numeric case consumes the selected status/tag once")
	assert_eq(state.get_counter(990002), 9)

func test_nested_start_event_finishes_before_parent_and_next_event() -> void:
	var local_db := ConfigDB.new()
	local_db.events[990101] = {"id": 990101, "start_trigger": true, "settlement": [{"action": {
		"prompt": {"id": "child", "text": "child"}, "counter+990001": 1,
	}}]}
	var state := GameState.new()
	OperationsSequence.start([{"event_on": 990101, "counter+990002": 2}], state, local_db, rng)
	OperationsSequence.start([{"counter+990003": 3}], state, local_db, rng)
	assert_eq(state.pending_operations.size(), 1, "no synthetic event panel")
	assert_eq(state.pending_operation().payload.id, "child")
	assert_eq(state.get_counter(990001), 0)
	assert_eq(state.get_counter(990002), 0)
	assert_eq(state.get_counter(990003), 0)
	var operation := state.consume_pending_operation()
	OperationsSequence.resume(operation, state, local_db, rng)
	assert_eq(state.get_counter(990001), 1)
	assert_eq(state.get_counter(990002), 2)
	assert_eq(state.get_counter(990003), 3)

func test_sleep_and_choose_all_preserve_order_without_consuming_rng() -> void:
	var state := _state()
	var before := rng.get_state()
	OperationsSequence.start([{"choose:9": {
		"sleep": 0.01, "counter+990001": 5,
	}}], state, db, rng)
	assert_eq(rng.get_state(), before, "source skips shuffle when N exceeds operation count")
	assert_eq(state.pending_operation().kind, "sleep")
	assert_eq(state.get_counter(990001), 0)
	_finish(state)
	assert_eq(state.get_counter(990001), 5)

func test_nested_game_over_stops_remaining_parent_operations() -> void:
	var local_db := ConfigDB.new()
	local_db.events[990120] = {"id": 990120, "start_trigger": true, "action": {"over": 1}}
	var state := GameState.new()
	OperationsSequence.start([{"event_on": 990120, "counter+990001": 100}], state, local_db, rng)
	assert_true(state.over_pending)
	assert_eq(state.get_counter(990001), 0)
