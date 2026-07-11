extends GutTest

const RNG = preload("res://core/rng.gd")

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
	assert_eq(opened.size(), 2, "generated eligible auto_begin daily rites are opened")
	assert_true(5000001 in state.started_rites, "治理家业 is marked started")
	assert_true(5001001 in state.started_rites, "daily palace rite is marked started when generated")
	assert_eq(state.coin_count, 0, "auto-begin does not execute settlement rewards")
	assert_eq(state.auto_result_rites.size(), 0, "auto-result runtime state is separate from auto-begin")

func test_auto_begin_respects_open_conditions():
	var fake_db := ConfigDB.new()
	fake_db.rites = {
		9001: {
			"id": 9001,
			"auto_begin": 1,
			"round_number": 1,
			"open_conditions": [{"condition": {"counter.7000001=": 1}}],
		},
		9002: {
			"id": 9002,
			"auto_begin": 1,
			"round_number": 1,
			"open_conditions": [{"condition": {}}],
		},
	}
	var state := GameState.new()
	state.round_number = 1
	state.available_rites = [9001, 9002]

	var opened := RoundLoop.start_auto_begin_rites(state, fake_db)

	assert_false(9001 in state.started_rites, "closed auto_begin rite should not start")
	assert_true(9002 in state.started_rites, "open auto_begin rite should start")
	assert_eq(opened.size(), 1)

func test_auto_begin_ignores_uncreated_config_rites():
	var fake_db := ConfigDB.new()
	fake_db.rites = {
		9003: {
			"id": 9003,
			"auto_begin": 1,
			"round_number": 1,
			"open_conditions": [{"condition": {}}],
		},
	}
	var state := GameState.new()
	state.round_number = 1

	var opened := RoundLoop.start_auto_begin_rites(state, fake_db)

	assert_eq(opened.size(), 0)
	assert_false(9003 in state.started_rites, "config-only rites should not start until generated")

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


func test_auto_result_rite_settles_on_advance_day_with_empty_slots():
	# An auto_begin+auto_result rite (治理家业) settles at round end (advance_day)
	# with empty slots, landing on the "no one sent" branch (no income). The
	# player should NOT need to manually resolve it.
	# [SRC: GameController.c @ UpdateSingleRite: started rite settles normally]
	var rng := RNG.new(300)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	# Draw a sudan so advance_day doesn't start a new round mid-test.
	RoundLoop.draw_weekly_sudan(state, db, rng)
	# Start the auto_begin rite.
	RoundLoop.start_auto_begin_rites(state, db)
	assert_true(5000001 in state.started_rites, "治理家业 started")
	var coin_before := state.coin_count
	# Advance a day: auto_result rites settle at round end.
	RoundLoop.advance_day(state, db, rng)
	# With empty slots, the "no one sent" branch matches → no income change.
	# The key assertion: it settled without crashing and without player input.
	assert_eq(state.coin_count, coin_before, "empty-slot auto_result grants no income")


func test_auto_result_rite_with_slotted_card_grants_reward():
	# If the player placed a 贵族 card before advance_day, the auto_result rite
	# should settle using that card and grant income.
	var rng := RNG.new(301)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	RoundLoop.start_auto_begin_rites(state, db)
	# Manually place a card with high 智慧+社交 into slot 1.
	state.add_card_to_slot(2000005, 1, db)  # 异国商人 (贵族)
	var coin_before := state.coin_count
	RoundLoop.advance_day(state, db, rng)
	# With a 贵族 slotted, the r1:智慧+社交 branches become reachable.
	# At minimum, the rite should not grant 0 (some income branch matched).
	assert_ne(state.coin_count, coin_before, "slotted-card auto_result grants income")
