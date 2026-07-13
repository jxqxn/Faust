extends GutTest

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
	# Normal runs use a curated starting hand; the huge init/1 list is a test profile.
	var hand_card_ids: Array[int] = []
	for card_uid in state.hand:
		hand_card_ids.append(int(state.get_card_instance(int(card_uid)).card_id))
	assert_eq(hand_card_ids, [2000001, 2000006, 2000523, 2000005])
	assert_true(5000001 in state.available_rites)
	assert_true(state.available_rites.size() < db.rites.size(), "normal start should not expose every configured rite")
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


func test_sudan_pool_tag_operations_only_change_undrawn_ids_once():
	var state := GameState.new()
	state.setup_new_run(db, 1, RNG.new(42))
	state.sudan_deck = [2010001, 2010002, 2010001]
	var next_uid := state.next_card_uid
	ResultExec.execute({"sudan_pool.2010001+牌池测试": 2}, state, db)
	ResultExec.execute({"sudan_pool.2010001-牌池测试": 1}, state, db)
	ResultExec.execute({"sudan_pool.2010001=牌池测试": 3}, state, db)
	assert_eq(state.next_card_uid, next_uid, "pool filtering must not create probe instances")
	assert_eq(state.card_instances.size(), state.hand.size(), "pool filtering leaves runtime instances untouched")
	assert_eq(int(state.sudan_pool_tags[2010001].get("牌池测试", 0)), 3, "plus, minus, and set apply once to a shared duplicate-ID override")
	RoundLoop.draw_weekly_sudan(state, db, RNG.new(43))
	var drawn = state.get_card_instance(state.active_sudan_cards.back().card_uid)
	assert_eq(drawn.card_id, 2010001)
	assert_eq(int(drawn.tags.get("牌池测试", 0)), 3, "drawn instance receives the pool tag state")
	ResultExec.execute({"sudan_pool.2010001+牌池测试": 3}, state, db)
	assert_eq(int(drawn.tags.get("牌池测试", 0)), 3, "drawn instance is not retroactively changed")


func test_redraw_creates_a_new_sudan_instance_from_pool_tags():
	var state := GameState.new()
	state.setup_new_run(db, 1, RNG.new(44))
	state.sudan_deck = [2010002, 2010001]
	RoundLoop.draw_weekly_sudan(state, db, RNG.new(45))
	var discarded_uid: int = int(state.active_sudan_cards.back().card_uid)
	ResultExec.execute({"sudan_pool.2010002=重抽标签": 4}, state, db)
	assert_eq(RoundLoop.use_redraw(state, RNG.new(46), db), 2010002)
	var replacement = state.get_card_instance(state.active_sudan_cards.back().card_uid)
	assert_eq(int(replacement.tags.get("重抽标签", 0)), 4)
	var discarded = state.get_card_instance(discarded_uid)
	assert_true(discarded.is_lost, "discarded runtime Sultan remains lost")
	assert_eq(int(discarded.tags.get("重抽标签", 0)), 0, "discarded instance is independent from the pool")


func test_auto_generate_sudan_uses_original_operation_values_without_stalling_rounds():
	var state := GameState.new()
	state.setup_new_run(db, 1, RNG.new(47))
	ResultExec.execute({"enable_auto_gen_sudan_card": false}, state, db)
	assert_false(state.auto_gen_sudan_card, "false disables automatic Sultan generation")
	var disabled_round := RoundLoop.start_round_if_no_sudan(state, db, RNG.new(48))
	assert_true(disabled_round.new_round, "disabled generation still starts the next round")
	assert_eq(disabled_round.drawn_sudan, -1, "disabled generation skips only the Sultan draw")
	assert_eq(state.round_number, 2, "round number still advances while Sultan generation is disabled")
	var day_result := RoundLoop.advance_day(state, db, RNG.new(49))
	assert_true(day_result.new_round, "day progression keeps the round lifecycle active")
	assert_eq(day_result.drawn_sudan, -1)
	assert_eq(RoundLoop.start_round(state, db, RNG.new(50)), -1, "explicit round draw follows the generation gate")
	ResultExec.execute({"enable_auto_gen_sudan_card": true}, state, db)
	assert_true(state.auto_gen_sudan_card, "true enables automatic Sultan generation")
	var enabled_round := RoundLoop.start_round_if_no_sudan(state, db, RNG.new(51))
	assert_true(enabled_round.new_round)
	assert_true(enabled_round.drawn_sudan >= 0, "enabled generation draws a Sultan card")


func test_redraw_draws_sudan_redraw_count_cards():
	# Redraw draws sudan_redraw_count new cards (each inheriting the discarded
	# card's life), not just one.
	# [SRC: GameController.c @ RedrawSudanCard: loops player+0x68 times]
	var rng := RNG.new(40)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	state.active_sudan_cards.clear()
	state.active_sudan_cards.append(RoundLoop.ActiveSudan.new(2010001, 5, 1))
	state.sudan_redraw_count = 2
	state.sudan_deck = [2010002, 2010003, 2010004, 2010005]
	var new_id := RoundLoop.use_redraw(state, rng)
	assert_true(new_id >= 0, "redraw succeeds")
	assert_eq(state.active_sudan_cards.size(), 2, "redraw draws 2 cards for count=2")
	# Each new card inherits the discarded card's life (5 days).
	for asc in state.active_sudan_cards:
		assert_eq(asc.days_left, 5, "new card inherits discarded life")


func test_redraw_rejects_when_deck_below_count():
	# Pre-loop gate: pool must hold at least sudan_redraw_count cards.
	# [SRC: GameController.c:3814 if pool.count < sudan_redraw_count → reject]
	var rng := RNG.new(41)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	state.active_sudan_cards.clear()
	state.active_sudan_cards.append(RoundLoop.ActiveSudan.new(2010001, 5, 1))
	state.sudan_redraw_count = 3
	state.sudan_deck = [2010002, 2010003]  # only 2 cards, need 3
	var initial_redraws := state.redraws_left
	var new_id := RoundLoop.use_redraw(state, rng)
	assert_eq(new_id, -1, "redraw fails when deck < count")
	assert_eq(state.redraws_left, initial_redraws, "no redraw consumed on gate failure")
