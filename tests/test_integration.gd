extends GutTest

const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
const RNG = preload("res://core/rng.gd")
const RoundLoop = preload("res://sim/round_loop.gd")
const RiteResolver = preload("res://sim/rite_resolver.gd")

var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()

func test_waiting_with_active_sudan_does_not_start_round_by_day_modulo():
	var rng := RNG.new(100)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	for i in range(5):
		var result := RoundLoop.advance_day(state, db, rng)
		assert_false(result.new_round, "active sudan card blocks new round")
	assert_eq(state.round_number, 1, "round does not advance on day modulo")
	assert_eq(state.active_sudan_cards.size(), 1, "still the same active sudan card")

func test_consumed_sudan_allows_event_driven_next_round_draw():
	var rng := RNG.new(200)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var first_cid := RoundLoop.draw_weekly_sudan(state, db, rng)
	assert_true(RoundLoop.consume_sudan(state, first_cid))
	var result := RoundLoop.start_round_if_no_sudan(state, db, rng)
	assert_true(result.new_round, "no active sudan starts a new round")
	assert_true(result.drawn_sudan >= 0, "new sudan card drawn")
	assert_eq(state.round_number, 2, "round incremented")
	assert_eq(state.active_sudan_cards.size(), 1, "one new active sudan card")

func test_auto_begin_starts_rites_without_resolving_results():
	var rng := RNG.new(201)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var opened := RoundLoop.start_auto_begin_rites(state, db)
	assert_true(opened.size() > 7, "all auto_begin rites are opened, not just auto_result rites")
	assert_true(5000001 in state.started_rites, "治理家业 is marked started")
	assert_eq(state.coin_count, 0, "auto-begin does not execute settlement rewards")
	assert_eq(state.auto_result_rites.size(), 0, "auto-result runtime state is separate from auto-begin")

func test_rite_resolution_with_placed_cards():
	var rng := RNG.new(300)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.add_card_to_slot(2000001, 1, db)
	state.add_card_to_slot(2000005, 2, db)
	var rite: Dictionary = db.get_rite(5000001)
	var ctx := {"db": db, "state": state, "rng": rng, "rite_state": {"s1": 2000001, "s2": 2000005}, "attr_slots": ["s1", "s2"], "rite_id": 5000001}
	var res := RiteResolver.resolve(rite, ctx, 0)
	assert_false(res.normal_entry.is_empty(), "settlement matched with placed cards")
