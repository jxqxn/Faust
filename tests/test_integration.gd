extends GutTest

## End-to-end integration test: exercises the full round loop from new run
## through sudan expiry / game over, verifying the round transition and
## auto-rite scheduling (per-round, not per-day) work correctly.

const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
const RNG = preload("res://core/rng.gd")
const RoundLoop = preload("res://sim/round_loop.gd")
const SudanCards = preload("res://sim/sudan_cards.gd")
const RiteResolver = preload("res://sim/rite_resolver.gd")

var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()

func test_full_round_loop_to_game_over():
	var rng := RNG.new(100)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng) # normal: 7-day life
	# Draw the first weekly sudan card.
	var first_cid := RoundLoop.draw_weekly_sudan(state, db, rng)
	assert_true(first_cid >= 0, "drew first sudan card")
	assert_eq(state.active_sudan_cards.size(), 1, "one active sudan card")
	# The card has life=7. advance_day decrements first. So:
	#   day 2: life=6, day 3: life=5, ... day 7: life=1, day 8: life=0 -> expired.
	# Round transition fires at day % life_time == 0 (day 7), BEFORE expiry.
	var saw_round_transition := false
	var game_over := false
	var day := 1
	while day < 15 and not game_over:
		day += 1
		var result := RoundLoop.advance_day(state, db, rng)
		game_over = result.game_over
		if result.get("new_round", false):
			saw_round_transition = true
			# Auto-rites should fire at round begin (per-round).
			assert_true(result.auto_rites.size() > 0, "auto-rites fired at round begin")
	# The card should expire by day 8.
	assert_true(game_over, "game over after sudan expiry")
	assert_true(saw_round_transition, "round transition happened before expiry")

func test_auto_rites_fire_per_round_not_per_day():
	var rng := RNG.new(200)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	# Advance one day (should NOT fire auto-rites - not a round boundary).
	var r1 := RoundLoop.advance_day(state, db, rng)
	assert_false(r1.get("new_round", true), "day 2 is not a round boundary")
	assert_eq(r1.auto_rites.size(), 0, "no auto-rites on non-round day")
	# Advance to day 7 (7-day life -> day % 7 == 0 -> round boundary).
	# We're at day 2, need to reach day 7: 5 more advance_day calls.
	for i in range(5):
		var _r := RoundLoop.advance_day(state, db, rng)
	# Now at day 7.
	assert_eq(state.day, 7, "at day 7")
	# Only 7 rites have auto_begin=1 AND auto_result=1.
	var rites := RoundLoop.run_auto_rites(state, db, rng)
	assert_true(rites.size() > 0, "auto-rites resolved")
	assert_true(rites.size() <= 7, "only auto_result rites resolved, not all 404")

func test_rite_resolution_with_placed_cards():
	var rng := RNG.new(300)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng) # easy difficulty
	# Place 阿尔图 (2000001) into slot 1 and 巴拉特 (2000005) into slot 2.
	state.add_card_to_slot(2000001, 1, db)
	state.add_card_to_slot(2000005, 2, db)
	var rite: Dictionary = db.get_rite(5000001)
	var ctx := {"db": db, "state": state, "rng": rng, "rite_state": {"s1": 2000001, "s2": 2000005}, "attr_slots": ["s1", "s2"], "rite_id": 5000001}
	var res := RiteResolver.resolve(rite, ctx, 0)
	# With cards placed, a settlement should match (not the empty-slots branch).
	assert_false(res.normal_entry.is_empty(), "settlement matched with placed cards")
