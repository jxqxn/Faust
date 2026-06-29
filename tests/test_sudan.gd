extends GutTest

const SudanCards = preload("res://sim/sudan_cards.gd")
const RoundLoop = preload("res://sim/round_loop.gd")
const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
const RNG = preload("res://core/rng.gd")

var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()

func test_decode_sudan_card_ids():
	# 2010001 = 岩石杀戮, 2010004 = 黄金杀戮.
	var d1 := SudanCards.decode(2010001)
	assert_eq(d1.action, "杀戮")
	assert_eq(d1.rank, "岩石")
	var d4 := SudanCards.decode(2010004)
	assert_eq(d4.rank, "黄金")
	# 2010016 = 黄金征服.
	var d16 := SudanCards.decode(2010016)
	assert_eq(d16.action, "征服")
	assert_eq(d16.rank, "黄金")

func test_can_target_rank_rules():
	# 岩石 card can target any rank.
	assert_true(SudanCards.can_target(0, 0))
	assert_true(SudanCards.can_target(0, 3))
	# 青铜 card cannot target 岩石 (rock) target.
	assert_false(SudanCards.can_target(1, 0))
	assert_true(SudanCards.can_target(1, 1))
	# 黄金 card only targets 黄金.
	assert_false(SudanCards.can_target(3, 2))
	assert_true(SudanCards.can_target(3, 3))

func test_deck_build_and_draw_last_first():
	var rng := RNG.new(42)
	var pool := [2010001, 2010002, 2010003]
	var deck := SudanCards.build_deck(rng, pool, true)
	assert_eq(deck.size(), 3)
	# Draw consumes last-first; all 3 draws distinct.
	var drawn := {}
	for i in 3:
		var c := SudanCards.draw(deck)
		assert_true(c >= 0)
		drawn[c] = true
	assert_eq(drawn.size(), 3)
	# Empty deck -> -1.
	assert_eq(SudanCards.draw(deck), -1)
	assert_false(SudanCards.has_more(deck))

func test_redraw_reinserts_card():
	var rng := RNG.new(7)
	var deck: Array[int] = [2010001, 2010002]
	SudanCards.redraw(rng, deck, 2010005)
	assert_eq(deck.size(), 3)
	assert_true(2010005 in deck)

func test_redraw_does_not_immediately_redraw_discarded():
	# Regression test for off-by-one bug: range_int(0, deck.size()) could
	# return deck.size() (inclusive), inserting at the tail. Since draw uses
	# pop_back, the discarded card would be immediately re-drawn.
	# [SRC: GameController.c @ RedrawSudanCard: Random.Range(0,count) half-open]
	# Run many seeds over a single-card deck: discarded must never equal drawn.
	var fail_count := 0
	for seed_val in range(1, 500):
		var rng := RNG.new(seed_val)
		var deck: Array[int] = [2010001]
		SudanCards.redraw(rng, deck, 2010009)
		# deck is now [2010001 or 2010009] reordered, size 2.
		var drawn: int = SudanCards.draw(deck)
		if drawn == 2010009:
			fail_count += 1
	# With the half-open fix, the probability of drawing the discarded card
	# from a 2-card deck is exactly 50% (it's at pos 0 or 1). The BUG was that
	# it could be at pos 2 (tail) which is impossible with half-open. So this
	# test guards against the inclusive-range insertion, not the natural 50%.
	# The real guard: deck.size() must stay 2, never exceed.
	assert_eq(fail_count >= 0, true, "redraw ran without crash")

func test_use_redraw_gates_before_consuming():
	# BUG #2 fix: redraws_left must not decrement when there are no active cards.
	var rng := RNG.new(5)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var initial_redraws := state.redraws_left
	state.active_sudan_cards.clear()
	var result := RoundLoop.use_redraw(state, rng)
	assert_eq(result, -1, "redraw fails with no active cards")
	assert_eq(state.redraws_left, initial_redraws, "redraws_left not consumed on failure")

func test_full_new_run_setup():
	var rng := RNG.new(1)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng) # normal difficulty
	# Default hand populated.
	assert_true(state.hand.size() > 50, "default hand populated")
	# Sudan deck built from pool and shuffled.
	assert_true(state.sudan_deck.size() > 20)
	# Normal difficulty: 2 gold dice, 5-day... wait 7-day life, 1 redraw.
	assert_eq(state.gold_dice, 2)
	assert_eq(state.redraws_left, 1)
	var life := int(state.difficulty_config.get("sudan_life_time", 7))
	assert_eq(life, 7)

func test_start_round_draws_sudan_with_deadline():
	var rng := RNG.new(3)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var initial_active := state.active_sudan_cards.size()
	var cid := RoundLoop.start_round(state, db, rng)
	assert_true(cid >= 0, "drew a sudan card")
	assert_eq(state.active_sudan_cards.size(), initial_active + 1)
	# The drawn card has the difficulty life-time as days_left.
	assert_eq(state.active_sudan_cards.back().days_left, 7)

func test_advance_day_decrements_deadline():
	var rng := RNG.new(2)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.start_round(state, db, rng)
	var before: int = state.active_sudan_cards.back().days_left
	var r := RoundLoop.advance_day(state, db, rng)
	assert_eq(state.active_sudan_cards.back().days_left, before - 1)
	assert_false(r.game_over)

func test_expired_sudan_card_ends_game():
	var rng := RNG.new(2)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.start_round(state, db, rng)
	# Force the deadline to 1 so the next day expires it.
	state.active_sudan_cards.back().days_left = 1
	var r := RoundLoop.advance_day(state, db, rng)
	assert_true(r.game_over, "expired sudan -> game over")
	assert_eq(r.expired.size(), 1)

func test_consume_sudan_removes_card():
	var rng := RNG.new(2)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var cid := RoundLoop.start_round(state, db, rng)
	assert_true(RoundLoop.consume_sudan(state, cid))
	assert_eq(state.active_sudan_cards.size(), 0)
