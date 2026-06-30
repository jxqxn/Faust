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
	# Higher-rank targets can satisfy lower-rank Sultan cards.
	assert_true(SudanCards.can_target(0, 0), "rock target satisfies rock card")
	assert_true(SudanCards.can_target(0, 3), "gold target satisfies rock card")
	assert_true(SudanCards.can_target(1, 2), "silver target satisfies bronze card")
	assert_true(SudanCards.can_target(2, 3), "gold target satisfies silver card")
	# Lower-rank targets cannot satisfy higher-rank Sultan cards.
	assert_false(SudanCards.can_target(1, 0), "rock target cannot satisfy bronze card")
	assert_false(SudanCards.can_target(3, 2), "silver target cannot satisfy gold card")
	assert_true(SudanCards.can_target(3, 3), "gold target satisfies gold card")

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
	for seed_val in range(1, 500):
		var rng := RNG.new(seed_val)
		var deck: Array[int] = [2010001]
		SudanCards.redraw(rng, deck, 2010009)
		assert_eq(deck.back(), 2010001, "discarded card is never inserted at the pop_back tail")

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

func test_new_run_uses_sudan_shuffle_flag():
	var rng_a := RNG.new(11)
	var rng_b := RNG.new(12)
	var state_a := GameState.new()
	var state_b := GameState.new()
	state_a.setup_new_run(db, 1, rng_a)
	state_b.setup_new_run(db, 1, rng_b)
	var raw_pool: Array = db.get_sudan_pool()
	assert_ne(state_a.sudan_deck, raw_pool, "setup_new_run shuffles the configured sudan pool")
	assert_ne(state_a.sudan_deck, state_b.sudan_deck, "different seeds produce different sudan deck order")

func test_easy_difficulty_uses_difficulty_redraw_count():
	var rng := RNG.new(1)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	assert_eq(state.redraws_left, 3, "easy difficulty has 3 redraws per round")

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

func test_redraw_preserves_visible_deadline():
	# Original copies Card.life (elapsed days) from old card to new card; the
	# visible countdown is config_life - life. This clone stores the inverse
	# value directly as days_left, so preserving the visible countdown means
	# copying days_left to the replacement sudan card.
	var rng := RNG.new(9)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	state.active_sudan_cards.back().days_left = 3
	var new_id := RoundLoop.use_redraw(state, rng)
	assert_true(new_id >= 0, "redrew a replacement sudan card")
	assert_eq(state.active_sudan_cards.back().days_left, 3, "redraw keeps the visible deadline unchanged")

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
