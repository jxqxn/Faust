extends GutTest

const RNG = preload("res://core/rng.gd")


func _db_with_lifecycle_rites() -> ConfigDB:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.rites[991001] = {
		"id": 991001,
		"name": "Timeout test",
		"open_conditions": [],
		"cards_slot": {"s1": {}},
		"round_number": 2,
		"waiting_round": 1,
		"waiting_round_end_action": [{
			"condition": {}, "result_title": "Too late", "result_text": "The chance passed.",
			"result": {"coin": 2}, "action": {},
		}],
		"settlement_prior": [], "settlement": [], "settlement_extre": [],
		"auto_begin": 0, "auto_result": 0,
	}
	local_db.rites[991002] = {
		"id": 991002,
		"name": "Started test",
		"open_conditions": [],
		"cards_slot": {"s1": {}},
		"round_number": 2, "waiting_round": 0, "waiting_round_end_action": [],
		"settlement_prior": [],
		"settlement": [{"condition": {}, "result": {"coin": 3}, "action": {}}],
		"settlement_extre": [], "auto_begin": 0, "auto_result": 0,
	}
	local_db.rites[991003] = {
		"id": 991003,
		"name": "Parallel test",
		"open_conditions": [],
		"cards_slot": {},
		"round_number": 2, "waiting_round": 0, "waiting_round_end_action": [],
		"settlement_prior": [],
		"settlement": [{"condition": {}, "result": {"coin": 4}, "action": {}}],
		"settlement_extre": [], "auto_begin": 0, "auto_result": 1,
	}
	local_db.rites[991004] = {
		"id": 991004,
		"name": "Required adsorb test",
		"open_conditions": [],
		"cards_slot": {"s1": {"condition": {"is": 2000005}, "open_adsorb": 1, "is_empty": 0}},
		"round_number": 0, "waiting_round": 0, "waiting_round_end_action": [],
		"settlement_prior": [], "settlement": [{"condition": {}, "result": {}, "action": {}}],
		"settlement_extre": [], "auto_begin": 0, "auto_result": 0,
	}
	local_db.rites[991005] = {
		"id": 991005,
		"name": "Optional adsorb test",
		"open_conditions": [],
		"cards_slot": {"s1": {"condition": {"is": 2000005}, "open_adsorb": 1, "is_empty": 1}},
		"round_number": 0, "waiting_round": 0, "waiting_round_end_action": [],
		"settlement_prior": [], "settlement": [{"condition": {}, "result": {}, "action": {}}],
		"settlement_extre": [], "auto_begin": 0, "auto_result": 0,
	}
	# Multi-day rite that accepts any card in s1. Used to verify the Sultan-card
	# safe-period rule: a Sultan card placed in an in-progress started rite does
	# not trigger execution even when its deadline reaches zero.
	# [SRC: 知乎专栏 - 全折卡相关: "已被嵌入仪式中的苏丹卡倒计时哪怕退到负数都不会触发处刑"]
	local_db.rites[991006] = {
		"id": 991006,
		"name": "Multi-day shelter test",
		"open_conditions": [],
		"cards_slot": {"s1": {}},
		"round_number": 3, "waiting_round": 0, "waiting_round_end_action": [],
		"settlement_prior": [], "settlement": [{"condition": {}, "result": {}, "action": {}}],
		"settlement_extre": [], "auto_begin": 0, "auto_result": 0,
	}
	return local_db


func test_round_number_is_not_a_global_rite_open_gate():
	var local_db := _db_with_lifecycle_rites()
	var state := GameState.new()
	state.round_number = 1
	assert_true(
		RiteOpen.is_rite_open(local_db.rites[991002], state, local_db, RNG.new(1)),
		"round_number belongs to a RiteInstance lifetime, not map visibility"
	)


func test_waiting_rite_executes_timeout_then_returns_cards_and_is_removed():
	var local_db := _db_with_lifecycle_rites()
	var state := GameState.new()
	var instance = state.create_rite_instance(991001)
	state.add_card_to_hand(2000005)
	state.remove_card_from_hand(2000005)
	state.add_card_to_slot(2000005, 1, local_db, instance.uid)

	var result := RoundLoop.advance_day(state, local_db, RNG.new(2))

	assert_null(state.get_rite_instance(instance.uid), "expired rite instance is removed")
	assert_false(991001 in state.available_rites, "removed timeout rite is not recreated from a stale id view")
	assert_true(state.has_card_in_hand(2000005), "timeout returns its placed card")
	assert_eq(state.coin_count, 2, "waiting_round_end_action ran before removal")
	assert_eq(result.expired_rites, [{"id": 991001, "uid": instance.uid}])
	assert_eq(state.event_prompts.size(), 1, "timeout result text reaches the shared prompt queue")


func test_started_rite_settles_only_when_its_life_reaches_round_number():
	var local_db := _db_with_lifecycle_rites()
	var state := GameState.new()
	var instance = state.create_rite_instance(991002)
	state.add_card_to_hand(2000005)
	state.remove_card_from_hand(2000005)
	state.add_card_to_slot(2000005, 1, local_db, instance.uid)
	state.start_rite_instance(instance.uid)

	var first_day := RoundLoop.advance_day(state, local_db, RNG.new(3))
	assert_not_null(state.get_rite_instance(instance.uid), "life 1 is below round_number 2")
	assert_eq(instance.life, 1)
	assert_eq(state.coin_count, 0)
	assert_true(first_day.settled_rites.is_empty())

	var second_day := RoundLoop.advance_day(state, local_db, RNG.new(4))
	assert_null(state.get_rite_instance(instance.uid), "life 2 settles and removes only this instance")
	assert_false(991002 in state.available_rites, "settled rite is removed from the compatibility view too")
	assert_eq(state.coin_count, 3)
	assert_true(state.has_card_in_hand(2000005), "uncleaned settlement cards return to the rail")
	assert_eq(second_day.settled_rites, [{"id": 991002, "uid": instance.uid, "auto_result": false}])


func test_rite_instances_track_life_and_settlement_independently():
	var local_db := _db_with_lifecycle_rites()
	var state := GameState.new()
	var first = state.create_rite_instance(991002)
	var second = state.create_rite_instance(991003)
	state.start_rite_instance(first.uid)
	state.start_rite_instance(second.uid)
	second.life = 1

	var result := RoundLoop.advance_day(state, local_db, RNG.new(5))

	assert_not_null(state.get_rite_instance(first.uid), "first instance is still at life 1")
	assert_eq(first.life, 1)
	assert_null(state.get_rite_instance(second.uid), "second instance reaches life 2 and settles")
	assert_eq(state.coin_count, 4)
	assert_eq(result.settled_rites.size(), 1)
	assert_eq(int(result.settled_rites[0].get("uid", 0)), second.uid)


func test_auto_begin_only_reports_a_newly_started_instance_once():
	var local_db := _db_with_lifecycle_rites()
	local_db.rites[991002]["auto_begin"] = 1
	var state := GameState.new()
	var instance = state.create_rite_instance(991002)

	assert_eq(RoundLoop.start_auto_begin_rites(state, local_db).size(), 1)
	assert_true(instance.start)
	assert_true(RoundLoop.start_auto_begin_rites(state, local_db).is_empty(), "already-started rites are skipped")


func test_generation_adsorbs_required_open_slot_before_the_rite_is_available():
	var local_db := _db_with_lifecycle_rites()
	var state := GameState.new()
	state.add_card_to_hand(2000005)

	var rite_uid := state.add_available_rite(991004, local_db, RNG.new(6))
	var instance = state.get_rite_instance(rite_uid)

	assert_gt(rite_uid, 0, "matching required open_adsorb card permits rite generation")
	assert_not_null(instance)
	assert_false(state.has_card_in_hand(2000005), "adsorbed card leaves hand during rite generation")
	assert_eq(state.cards_in_slot(1, rite_uid).size(), 1, "adsorbed card enters the generated rite slot immediately")


func test_generation_rejects_missing_required_open_slot_and_keeps_hand_intact():
	var local_db := _db_with_lifecycle_rites()
	var state := GameState.new()

	assert_eq(state.add_available_rite(991004, local_db, RNG.new(7)), 0, "missing required auto slot aborts the rite instance")
	assert_true(state.available_rite_instances().is_empty(), "failed adsorption leaves no partial rite behind")


func test_generation_allows_empty_optional_open_slot():
	var local_db := _db_with_lifecycle_rites()
	var state := GameState.new()

	var rite_uid := state.add_available_rite(991005, local_db, RNG.new(8))
	assert_gt(rite_uid, 0, "is_empty permits generation without an auto-adsorbed card")
	assert_true(state.cards_in_slot(1, rite_uid).is_empty(), "optional auto slot remains empty")


func test_deferred_rite_generation_uses_the_same_open_adsorb_gate():
	var local_db := _db_with_lifecycle_rites()
	var state := GameState.new()

	DeferredEffects.apply({"rite": 991004}, state, local_db, RNG.new(9))
	assert_true(state.available_rite_instances().is_empty(), "result DSL cannot create a rite when required auto slots are missing")

	state.add_card_to_hand(2000005)
	DeferredEffects.apply({"rite": 991004}, state, local_db, RNG.new(10))
	assert_eq(state.available_rite_instances().size(), 1, "result DSL creates the rite once its auto slot can be filled")


# Helper: build a minimal state with one active Sultan card placed in the s1
# slot of an in-progress started rite. Avoids setup_new_run's heavy allocation
# (which would leak across tests). `rite_id` selects the shelter rite config,
# `days_left` sets the deadline on the active Sultan card.
func _state_with_embedded_sudan(local_db, rite_id: int, days_left: int) -> Dictionary:
	var state := GameState.new()
	var instance = state.create_rite_instance(rite_id)
	state.start_rite_instance(instance.uid)
	# Create a runtime Sultan card instance and register it as active.
	var sudan_instance = state.create_card_instance(2010001, local_db, "sudan")
	state.active_sudan_cards.append(RoundLoop.ActiveSudan.new(
		2010001, days_left, state.round_number, int(sudan_instance.uid)))
	# Place it into the rite's s1 slot. add_card_to_slot expects the uid.
	state.add_card_to_slot(int(sudan_instance.uid), 1, local_db, instance.uid)
	return {"state": state, "instance": instance, "sudan_uid": int(sudan_instance.uid)}


# A Sultan card placed in an in-progress started rite does NOT trigger execution
# when its deadline reaches zero. The deadline still decrements (it can even go
# negative); only the game-over trigger is suppressed while the card is embedded.
# [SRC: 知乎专栏 p/1909509257005831882; 巴哈姆特 snA=111; BWIKI 新手指南]
func test_sudan_card_in_started_rite_does_not_trigger_execution():
	var local_db := _db_with_lifecycle_rites()
	var ctx := _state_with_embedded_sudan(local_db, 991006, 1)  # round_number=3
	var state: GameState = ctx.state
	var instance = ctx.instance

	var r := RoundLoop.advance_day(state, local_db, RNG.new(22))

	assert_false(r.game_over, "embedded Sultan card does not execute even at deadline 0")
	assert_eq(r.expired.size(), 0)
	# Deadline still decremented per original rule (countdown keeps running).
	assert_eq(state.active_sudan_cards.back().days_left, 0, "deadline keeps decrementing while embedded")
	# The shelter rite is still in progress (life 1 < round_number 3).
	assert_not_null(state.get_rite_instance(instance.uid))


# Once the shelter rite settles, the Sultan card leaves its embedded state and
# the expiry check resumes. Settlement runs before the deadline check in the
# same advance_day cycle, so a now-due Sultan card executes on the very day the
# shelter rite settles (the card was sheltered only while the rite was open).
func test_sudan_card_executes_again_after_shelter_rite_settles():
	var local_db := _db_with_lifecycle_rites()
	# Use the round_number=2 shelter so we can settle it within the test window.
	var ctx := _state_with_embedded_sudan(local_db, 991002, 1)
	var state: GameState = ctx.state
	var instance = ctx.instance

	# Day 1: rite still in progress (life 1 < 2). Sultan deadline hits 0 but
	# execution is suppressed because the card is embedded.
	var r1 := RoundLoop.advance_day(state, local_db, RNG.new(32))
	assert_false(r1.game_over, "embedded card survives deadline 0")
	assert_not_null(state.get_rite_instance(instance.uid), "shelter rite still in progress")

	# Day 2: shelter rite settles (life 2 == round_number 2). Settlement moves
	# the Sultan card out of the slot (zone="sudan", rite_uid=0), so it is no
	# longer embedded. The deadline check then runs in the same advance_day and
	# executes the now-due, no-longer-sheltered card.
	var r2 := RoundLoop.advance_day(state, local_db, RNG.new(33))
	assert_null(state.get_rite_instance(instance.uid), "shelter rite has settled")
	assert_true(r2.game_over, "Sultan card executes once the shelter settles and the card leaves the slot")
	assert_eq(r2.expired.size(), 1)
