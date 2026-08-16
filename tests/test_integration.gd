extends GutTest

const RNG = preload("res://core/rng.gd")

var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()

func test_waiting_with_active_sudan_still_advances_round_each_day():
	# round advances unconditionally every day; only the Sultan draw is gated
	# on having no active Sultan card.
	# [SRC: DisplayClass142_0.c @ <OnNextRound>b__3: player.round += 1
	#       unconditionally; TryGenSudanCard gate is draw-only]
	var rng := RNG.new(100)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	for i in range(5):
		var result := RoundLoop.advance_day(state, db, rng)
		assert_true(result.new_round, "round advances every day")
		assert_eq(result.drawn_sudan, -1, "active sudan card blocks only the draw")
	assert_eq(state.round_number, 6, "round advanced once per day")
	assert_eq(state.active_sudan_cards.size(), 1, "still the same active sudan card")

func test_consumed_sudan_waits_for_day_boundary_to_draw_next():
	# Consuming the last Sultan card does not draw a replacement the same day;
	# TryGenSudanCard runs only at the day boundary.
	# [SRC: TryGenSudanCard callers: DisplayClass141_0.c:307 (startup chain),
	#       DisplayClass142_0.c:395 (OnNextRound chain); no other callers]
	var rng := RNG.new(200)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var first_cid := RoundLoop.draw_weekly_sudan(state, db, rng)
	assert_true(RoundLoop.consume_sudan(state, first_cid))
	assert_true(state.active_sudan_cards.is_empty(), "no active sudan after consuming")
	var result := RoundLoop.advance_day(state, db, rng)
	assert_true(result.new_round)
	assert_true(result.drawn_sudan >= 0, "next sudan drawn at the day boundary")
	assert_eq(state.round_number, 2, "round incremented")
	assert_eq(state.active_sudan_cards.size(), 1, "one new active sudan card")

func test_auto_begin_starts_rites_without_resolving_results():
	var rng := RNG.new(201)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var opened := RoundLoop.start_auto_begin_rites(state, db)
	assert_eq(opened.size(), 1, "only daily rites whose auto-adsorb prerequisites exist are opened")
	assert_true(5000001 in state.started_rites, "治理家业 is marked started")
	assert_false(5001001 in state.started_rites, "palace rite waits for its Sultan-on-court event chain")
	assert_false(5001001 in state.available_rites, "missing required auto slots prevent an unprepared palace instance")
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

	# auto_begin does not re-check open_conditions once an instance exists:
	# the DSL gate owns availability at generation time.
	# [SRC: DoStartAutoBeginRite (0x54ebc0) L5344-5349; report 8 A7]
	assert_true(9001 in state.started_rites, "a generated auto_begin instance starts regardless of open_condition")
	assert_true(9002 in state.started_rites, "open auto_begin rite should start")
	assert_eq(opened.size(), 2)

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


func test_next_day_orders_round_end_before_round_begin_auto_start_and_sudan_draw():
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.rites[991900] = {
		"id": 991900, "name": "round-order probe", "cards_slot": {},
		"open_conditions": {}, "auto_begin": 1, "auto_result": 0,
		"round_number": 99, "waiting_round": 0,
		"settlement_prior": [], "settlement": [], "settlement_extre": [],
	}
	local_db.events[991901] = {"id": 991901, "on": {"round_end": 0}, "condition": {}}
	local_db.events[991902] = {"id": 991902, "on": {"round_begin_ba": 1}, "condition": {}}
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(80))
	var rite_uid := state.add_available_rite(991900, local_db, RNG.new(81))
	assert_gt(rite_uid, 0)
	# Enable mid-run at round 1: round timings arm as value + current round,
	# so round_end:0 arms for outgoing round 1 and round_begin_ba:1 for round 2.
	assert_true(state.enable_event(991901, local_db))
	assert_true(state.enable_event(991902, local_db))

	var result := RoundLoop.advance_day(state, local_db, RNG.new(82))
	var rite = state.get_rite_instance(rite_uid)
	assert_true(991901 in result.round_end_events, "round_end observes outgoing round 1")
	assert_true(991902 in result.round_begin_events, "round_begin observes incremented round 2")
	assert_true(result.round_end_events.find(991901) >= 0 and result.round_begin_events.find(991902) >= 0,
		"both boundaries settle inside the same transition")

	assert_true(result.new_round)
	assert_eq(state.round_number, 2)
	assert_true(rite.start, "auto_begin starts only after the round-begin boundary")
	assert_gt(int(result.drawn_sudan), 0, "new round draws Sudan after auto-start")


func _db_with_round_timings() -> ConfigDB:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events[991910] = {"id": 991910, "text": "periodic", "is_replay": 1,
		"on": {"round_begin_ba": 3}, "condition": {}}
	local_db.events[991911] = {"id": 991911, "text": "once", "is_replay": 0,
		"on": {"round_begin_ba": 2}, "condition": {}}
	local_db.events[991912] = {"id": 991912, "text": "random period", "is_replay": 1,
		"on": {"round_begin_ba": [1, 2]}, "condition": {}}
	return local_db


func test_round_timing_is_a_period_not_a_single_round():
	# round_begin_ba: N on a replay event re-fires every N rounds; the armed
	# next-fire round advances by N at each fire (NextRound = value + now).
	# [SRC: TimingRoundBase.c @ IsValid (0x465d30) / NextRound (0x465f20)]
	var local_db := _db_with_round_timings()
	local_db.events[991910]["auto_start_init"] = [1]
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(90))
	assert_eq(int(state.timing_rounds.get("round_begin_ba:991910", -1)), 3,
		"armed at enable time as value + round 0")

	state.round_number = 2
	assert_false(991910 in state.trigger_events("round_begin_ba", {"round": 2}),
		"round 2 is below the armed round 3")
	state.round_number = 3
	assert_true(991910 in state.trigger_events("round_begin_ba", {"round": 3}),
		"fires when the armed round is reached")
	assert_eq(int(state.timing_rounds["round_begin_ba:991910"]), 6,
		"re-armed to fire again at round 6")
	state.round_number = 5
	assert_false(991910 in state.trigger_events("round_begin_ba", {"round": 5}),
		"round 5 is below the re-armed round 6")
	state.round_number = 6
	assert_true(991910 in state.trigger_events("round_begin_ba", {"round": 6}),
		"fires again on the second period")


func test_non_replay_round_event_fires_once_then_loses_its_arm():
	# A non-replay event unregisters on completion (OnEnd removes the
	# timing_rounds entry), so its round timing never fires again.
	var local_db := _db_with_round_timings()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(91))
	state.enable_event(991911, local_db)
	# Enabled at round 1: the period-2 timing arms for round 3.
	state.round_number = 3
	assert_true(991911 in state.trigger_events("round_begin_ba", {"round": 3}))
	state.complete_event(991911, false)
	assert_false(state.timing_rounds.has("round_begin_ba:991911"),
		"completing a non-replay event removes its round-timing arm")
	state.round_number = 4
	assert_false(991911 in state.trigger_events("round_begin_ba", {"round": 4}),
		"never fires again after completion")


func test_two_value_round_timing_is_a_random_period():
	# [a, b] arms at Unity Random.Range(a, b) [inclusive, exclusive) + base.
	# [SRC: TimingRoundBase.c @ NextRound: Count==2 -> Random.Range(v0, v1)]
	var local_db := _db_with_round_timings()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(92))
	state.enable_event(991912, local_db)
	# Enabled at round 1; Random.Range(1, 2) is always 1, so armed = 1 + 1.
	var armed: int = int(state.timing_rounds.get("round_begin_ba:991912", -1))
	assert_eq(armed, 2, "the drawn period (always 1) is added to the arming round")
	state.round_number = armed
	assert_true(991912 in state.trigger_events("round_begin_ba", {"round": armed}))


func test_timing_rounds_survive_save_load_without_re_arming():
	var local_db := _db_with_round_timings()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(93))
	state.enable_event(991910, local_db)
	state.timing_rounds["round_begin_ba:991910"] = 42
	var saved := SaveSystem.serialize(state)
	var restored := GameState.new()
	SaveSystem.deserialize(saved, restored, local_db)
	assert_eq(int(restored.timing_rounds.get("round_begin_ba:991910", -1)), 42,
		"saved arms restore verbatim; re-enabling must not overwrite them")


func test_book_search_loot_generates_one_runtime_rite_and_survives_save_load():
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(91))
	# All three 淘书 variants require the bookshop owner in an open-adsorb s1.
	# [SRC: original config rite/5002036-5002038.json cards_slot.s1]
	state.add_card_to_hand(2000199, db)
	var picked: Array = LootSystem.generate(RNG.new(92), db.get_loot(6000101))
	assert_eq(picked.size(), 1, "book-search loot performs one weighted draw")
	if picked.is_empty():
		return
	DeferredEffects._apply_loot_item(int(picked[0]), state, db, RNG.new(93))
	var generated: Array = state.available_rite_instances().filter(func(instance): return instance.id in [5002036, 5002037, 5002038])
	assert_eq(generated.size(), 1, "book-search loot creates exactly one weighted rite variant")
	if generated.is_empty():
		return
	var generated_uid := int(generated[0].uid)
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	var loaded = restored.get_rite_instance(generated_uid)
	assert_not_null(loaded, "generated book-search rite remains a runtime instance after loading")
	if loaded != null:
		assert_true(loaded.id in [5002036, 5002037, 5002038])
