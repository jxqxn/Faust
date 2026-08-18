extends GutTest

## Batch-1 DSL expansion (2026-08-14 unfreeze): bare ModifyTag/ModifyRare,
## copy.s<n>, delay_off, steam_achievement/debug no-ops, and the
## rite_end / rite_have / round<op> conditions.
## Semantics are source-cited in sim/result.gd and sim/condition.gd.

const RNG = preload("res://core/rng.gd")
const RiteView = preload("res://ui/rite_view.gd")


func _db_with_batch_rites() -> ConfigDB:
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.rites[992001] = {
		"id": 992001, "name": "Bare key test", "open_conditions": [],
		"cards_slot": {"s1": {}, "s2": {}},
		"round_number": 1, "waiting_round": 0, "waiting_round_end_action": [],
		"settlement_prior": [], "settlement": [], "settlement_extre": [],
		"auto_begin": 0, "auto_result": 0,
	}
	local_db.rites[992002] = {
		"id": 992002, "name": "Settle once test", "open_conditions": [],
		"cards_slot": {"s1": {}},
		"round_number": 1, "waiting_round": 0, "waiting_round_end_action": [],
		"settlement_prior": [], "settlement": [{"condition": {}, "result": {"coin": 1}, "action": {}}],
		"settlement_extre": [], "auto_begin": 0, "auto_result": 0,
	}
	return local_db


func _place_in_slot(state, card_id: int, slot: int, db, rite_uid: int) -> void:
	state.add_card_to_hand(card_id, db)
	state.remove_card_from_hand(card_id)
	state.add_card_to_slot(card_id, slot, db, rite_uid)


func test_bare_card_id_tag_add_and_remove() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var instance = state.create_rite_instance(992001)
	_place_in_slot(state, 2000082, 1, local_db, instance.uid)
	var ctx := {"db": local_db, "state": state, "rite_id": 992001, "rite_uid": instance.uid}

	ResultExec.execute({"2000082+晋升": 1}, state, local_db, ctx)
	ResultExec.execute({"2000082-妓女": 1}, state, local_db, ctx)

	var uid := state.card_uid_for(2000082)
	var data: Dictionary = state.card_data_for(uid, local_db)
	assert_eq(int(data.get("tag", {}).get("晋升", 0)), 1, "bare <id>+<tag> adds the tag to the rite-context card")
	assert_eq(int(data.get("tag", {}).get("妓女", 0)), 0, "bare <id>-<tag> removes the tag")


func test_bare_tag_selector_targets_only_matching_slot_card() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var instance = state.create_rite_instance(992001)
	_place_in_slot(state, 2000082, 1, local_db, instance.uid)
	_place_in_slot(state, 2000113, 2, local_db, instance.uid)
	var ctx := {"db": local_db, "state": state, "rite_id": 992001, "rite_uid": instance.uid}

	ResultExec.execute({"小偷+生存": 1}, state, local_db, ctx)

	var alimu := state.card_data_for(state.card_uid_for(2000113), local_db)
	var shama := state.card_data_for(state.card_uid_for(2000082), local_db)
	assert_eq(int(alimu.get("tag", {}).get("生存", 0)), 3, "tag selector modifies the matching card (2000113 has 小偷)")
	assert_eq(int(shama.get("tag", {}).get("生存", 0)), 0, "non-matching slot card is untouched (夏玛 has no 小偷 tag)")


func test_bare_uprare_raises_rarity() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var instance = state.create_rite_instance(992001)
	_place_in_slot(state, 2000082, 1, local_db, instance.uid)
	var ctx := {"db": local_db, "state": state, "rite_id": 992001, "rite_uid": instance.uid}

	ResultExec.execute({"2000082.uprare": 1}, state, local_db, ctx)

	var data: Dictionary = state.card_data_for(state.card_uid_for(2000082), local_db)
	assert_eq(int(data.get("rare", 0)), 4, "bare <id>.uprare raises 夏玛 from rare 3 to 4")


func test_copy_slot_grants_fresh_copies_to_hand() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var instance = state.create_rite_instance(992001)
	_place_in_slot(state, 2000113, 2, local_db, instance.uid)
	var ctx := {"db": local_db, "state": state, "rite_id": 992001, "rite_uid": instance.uid}
	var hand_before := state.hand.size()

	ResultExec.execute({"copy.s2": 2}, state, local_db, ctx)

	assert_eq(state.hand.size(), hand_before + 2, "copy.s2 grants two copies to the hand")
	var copied_ids := state.hand.map(func(uid): return state.get_card_instance(uid).card_id)
	assert_eq(copied_ids.count(2000113), 2, "copies carry the slot card's config id")


func test_delay_off_clears_all_then_removes_by_id() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.schedule_delay({"id": 5, "round": 2})
	state.schedule_delay({"id": 6, "round": 3})

	ResultExec.execute({"delay_off": 1}, state, local_db, {})
	assert_eq(state.delayed_operations.size(), 0, "delay_off: 1 clears every scheduled delay op")

	state.schedule_delay({"id": 5, "round": 2})
	state.schedule_delay({"id": 7, "round": 2})
	ResultExec.execute({"delay_off": [5]}, state, local_db, {})
	assert_eq(state.delayed_operations.size(), 1, "delay_off with explicit ids removes only those ids")
	assert_eq(int(state.delayed_operations[0].get("id", 0)), 7)


func test_platform_and_logging_operations_are_no_ops() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var deferred := ResultExec.execute({"steam_achievement": "ach_1", "debug": "dbg"}, state, local_db, {})
	assert_eq(state.coin_count, 0, "logging operations leave gameplay state untouched")
	assert_eq(deferred.logs.size(), 2, "both operations are recorded as log lines")


func test_settled_rite_is_recorded_and_satisfies_rite_end() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var instance = state.create_rite_instance(992002)
	_place_in_slot(state, 2000005, 1, local_db, instance.uid)
	state.start_rite_instance(instance.uid)

	RoundLoop.advance_day(state, local_db, RNG.new(11))

	assert_true(state.has_rite_ended(992002), "settlement records the rite as ended")
	var ctx := {"db": local_db, "state": state}
	assert_true(ConditionEval.eval_key("rite_end.992002", 1, ctx))
	assert_false(ConditionEval.eval_key("rite_end.992001", 1, ctx), "an unsettled rite does not satisfy rite_end")


func test_rite_have_counts_cards_placed_in_referenced_rite() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var instance = state.create_rite_instance(992001)
	_place_in_slot(state, 2000113, 1, local_db, instance.uid)
	var ctx := {"db": local_db, "state": state, "rite_id": 992001, "rite_uid": instance.uid}

	assert_true(ConditionEval.eval_key("rite_have.992001.2000113=", 1, ctx), "count by card id")
	assert_true(ConditionEval.eval_key("rite_have.992001.男性=", 1, ctx), "count by tag")
	assert_false(ConditionEval.eval_key("rite_have.992001.2000113=", 2, ctx), "count compare fails when too few")
	assert_false(ConditionEval.eval_key("rite_have.992001.2000113=", 0, ctx), "placed card makes count=0 false")
	assert_true(ConditionEval.eval_key("rite_have.992009.2000113=", 0, ctx), "rite without an instance counts as zero")


func test_round_supports_comparison_suffix() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.round_number = 15
	var ctx := {"db": local_db, "state": state}
	# Original quirk: the non-regex `<=` operator degrades to Equal.
	# [SRC: ConditionManager.c @ GetCondition (0x3872f0); report 3 A9]
	assert_false(ConditionEval.eval_key("round<=", 14, ctx), "round<= degrades to equality: 15 != 14")
	assert_true(ConditionEval.eval_key("round<=", 15, ctx), "round<= degrades to equality: 15 == 15")
	assert_false(ConditionEval.eval_key("round<=", 16, ctx), "round<= degrades to equality: 15 != 16")
	assert_true(ConditionEval.eval_key("round", 15, ctx), "plain round keeps equality semantics")


func test_ended_rites_survive_save_roundtrip() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.record_rite_ended(992001)
	state.record_rite_ended(992001)

	var data := SaveSystem.serialize(state)
	var restored := GameState.new()
	SaveSystem.deserialize(data, restored, local_db)

	assert_true(restored.has_rite_ended(992001))
	assert_eq(int(restored.ended_rites.get(992001, 0)), 2, "ended-rite counts round-trip through the v5 payload")


func test_supported_key_coverage_for_batch1_families() -> void:
	for key in ["2000082+晋升", "妻子+晋升", "2000370-奴隶", "2000082.uprare", "妻子.uprare", "copy.s3", "copy.s10", "delay_off", "steam_achievement", "debug", "error", "warn"]:
		assert_true(ResultExec.is_supported_key(key), "result key supported: %s" % key)
	assert_true(ResultExec.is_supported_key("rebirth.s1"), "rebirth.s<n> is source-confirmed and supported")
	for key in ["rite_end.5000313", "rite_have.5008227.主角=", "rite_have.5008226.主角=", "round<="]:
		assert_true(ConditionEval.is_supported_key(key), "condition key supported: %s" % key)


func test_clean_rite_removes_other_instances_not_cards() -> void:
	# CleanRite removes OTHER rite instances (by config id; 1 = all except the
	# settling rite). It never cleans the settling rite's own slotted cards.
	# [SRC: CleanRite.c @ Do (0x4f3ae0); report 4 A1]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var settle = state.create_rite_instance(992001)
	var other_same = state.create_rite_instance(992001)
	var other_diff = state.create_rite_instance(992002)
	_place_in_slot(state, 2000001, 1, local_db, settle.uid)
	state.active_rite_uid = settle.uid

	var removed := state.remove_rite_instances_by_id(992002, settle.uid)
	assert_eq(removed, 1, "targeted clean removes the matching other instance")
	assert_null(state.get_rite_instance(other_diff.uid))
	assert_not_null(state.get_rite_instance(other_same.uid), "other config ids survive a targeted clean")

	state.active_rite_uid = settle.uid
	removed = state.remove_rite_instances_by_id(1, settle.uid)
	assert_eq(removed, 1, "sentinel 1 removes every other instance")
	assert_not_null(state.get_rite_instance(settle.uid), "the settling rite is always skipped")
	assert_eq(state.cards_in_slot(1, settle.uid).size(), 1, "the settling rite keeps its slotted cards")


func test_choose_executes_one_random_nested_operation() -> void:
	# [SRC: ChooseOperations.c @ GetOperations (0x4f3830): Shuffle + GetRange]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var rng := RNG.new(7)
	var deferred: Dictionary = ResultExec.execute(
		{"choose": {"coin": 3, "counter+7000001": 2}},
		state, local_db, {"rng": rng}
	)
	var coin_settled: bool = state.coin_count == 3 and state.get_counter(7000001) == 0
	var counter_settled: bool = state.coin_count == 0 and state.get_counter(7000001) == 2
	assert_true(coin_settled or counter_settled, "exactly one nested operation executed")
	assert_false(coin_settled and counter_settled, "choose does not run both branches")


func test_success_failed_branches_are_mutually_exclusive() -> void:
	# [SRC: SuccessOperations.c @ Do (0x3a7930) / FailedOperations.c @ Do
	#       (0x39d5a0): keyed on last_op_status, whichever reads it resets]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	ResultExec.execute({"success": {"coin": 5}, "failed": {"coin": 9}}, state, local_db)
	assert_eq(state.coin_count, 5, "default status 0 runs success only")
	assert_ne(state.coin_count, 9, "failed must not double-apply in the same result")

	var state2 := GameState.new()
	ResultExec.execute({"failed": {"coin": 9}}, state2, local_db)
	assert_eq(state2.coin_count, 0, "failed stays inert while no confirm wrote a failure status")


func test_rite_condition_is_instance_existence() -> void:
	# [SRC: HasRite.c @ IsSatisfiedInternal (0x3fdef0): any player.rites
	#       instance with r.id == Value (report 3 A3)]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var ctx := {"state": state, "rite_state": {}, "attr_slots": ["s1", "s2"]}
	assert_false(ConditionEval.eval_key("rite", 992001, ctx), "no instance -> false")
	var instance = state.create_rite_instance(992001)
	assert_true(ConditionEval.eval_key("rite", 992001, ctx), "instance exists -> true")
	state.remove_rite_instance(instance.uid)
	assert_false(ConditionEval.eval_key("rite", 992001, ctx), "removed instance -> false again")
	assert_true(ConditionEval.eval_key("!rite", 992001, ctx), "negative form stays existence-based")


func test_rite_timing_sentinel_one_matches_any_rite() -> void:
	# [SRC: report 6 A2 — rite timing value 1 = match any (10 config events)]
	var local_db := _db_with_batch_rites()
	local_db.events[992011] = {"id": 992011, "on": {"rite_end": 1}, "condition": {}}
	var state := GameState.new()
	state.round_number = 0
	state.enable_event(992011, local_db)
	assert_eq(state.trigger_events("rite_end", {"rite": 5000001}), [992011], "sentinel 1 fires for any rite id")
	assert_eq(state.trigger_events("rite_end", {"rite": 992001}), [], "a settled non-replay event does not fire again")


func test_have_family_counts_values_across_hand_and_slots() -> void:
	# [SRC: BaseHaveCardCount.c @ GetCountFunc (0x3f55a0): tag-value sum with a
	#       tag selector, stacking max(count,1) otherwise; HaveCardCount.c
	#       0x3fed80 covers player.cards + every rite's cards]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	# 巴拉特 2000005: 智慧 2, 社交 2, 异国商人 1 — one copy in hand, one in a
	# rite slot: `have` must see both zones, `hand_have` only the hand copy.
	state.add_card_to_hand(2000005, local_db)
	var instance = state.create_rite_instance(992001)
	_place_in_slot(state, 2000005, 1, local_db, instance.uid)
	var ctx := {"state": state, "db": local_db, "rite_state": {}, "attr_slots": ["s1", "s2"]}
	assert_true(ConditionEval.eval_key("have.智慧", 4, ctx), "have sums tag values across hand + slots")
	assert_false(ConditionEval.eval_key("have.智慧", 5, ctx), "default compare is >=")
	assert_true(ConditionEval.eval_key("hand_have.智慧", 2, ctx), "hand_have only sees the hand copy")
	assert_false(ConditionEval.eval_key("hand_have.智慧", 3, ctx), "hand_have ignores rite slots")
	assert_true(ConditionEval.eval_key("have.2000005", 2, ctx), "id selector counts stacked cards in both zones")
	assert_true(ConditionEval.eval_key("table_have.2000005", 2, ctx), "the desk surface sees the hand rail and rite slots")
	assert_false(ConditionEval.eval_key("table_have.2000005", 3, ctx), "table_have caps at the copies on the desk")


func test_rite_have_zero_spans_every_rite_instance() -> void:
	# [SRC: RiteHaveCardCount.c 0x405500: riteId < 1 -> SkipIsValidRite, i.e.
	#       count across ALL rites, not just the current one]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	var first = state.create_rite_instance(992001)
	var second = state.create_rite_instance(992002)
	# One card instance lives in exactly one slot, so use two distinct cards.
	_place_in_slot(state, 2000005, 1, local_db, first.uid)
	_place_in_slot(state, 2000001, 1, local_db, second.uid)
	var ctx := {"state": state, "db": local_db, "rite_id": 992001, "rite_state": {}, "attr_slots": ["s1"]}
	assert_true(ConditionEval.eval_key("rite_have.0.2000005", 1, ctx), "rite 0 spans every rite instance")
	assert_false(ConditionEval.eval_key("rite_have.0.2000024", 1, ctx), "cards nowhere on the table do not count")
	assert_true(ConditionEval.eval_key("rite_have.992001.2000005", 1, ctx), "a specific id only counts its own instances")
	assert_false(ConditionEval.eval_key("rite_have.992002.2000005", 1, ctx), "the second rite holds a different card")


func test_sudan_pool_have_counts_pool_entries() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.sudan_deck = [2010001, 2010001, 2010002]
	var ctx := {"state": state, "db": local_db, "rite_state": {}, "attr_slots": []}
	assert_true(ConditionEval.eval_key("sudan_pool_have.2010001", 2, ctx), "pool counts matched entries")
	assert_false(ConditionEval.eval_key("sudan_pool_have.2010001", 3, ctx))
	assert_true(ConditionEval.eval_key("sudan_pool_have.2010002", 1, ctx))


func test_attr_expr_arithmetic_and_references() -> void:
	# [SRC: FuncCompare.c @ SplitToken (0x3fc810): ( ) + - * / precedence;
	#       GetOpValue (0x3fbcb0): sN.tag slot refs + counter.<id>;
	#       Execute (0x3f9b20): e() iterates enemy-side cards]
	var st := GameState.new()
	st.set_counter(7000001, 6)
	var ctx := {
		"state": st, "rite_state": {}, "attr_slots": [],
		"counter": 1,
		"slot_entries": [
			{"slot": "s1", "card_id": 2000005, "card_uid": 1,
				"tags": {"战斗": 3, "体魄": 2}, "is_enemy": false},
			{"slot": "s5", "card_id": 2001187, "card_uid": 2,
				"tags": {"战斗": 1, "体魄": 4}, "is_enemy": true},
		],
	}
	# Parentheses and precedence: (3+2)*2 = 10 via s1 refs.
	assert_eq(ConditionEval.eval_attr_expr("(s1.战斗+s1.体魄)*2", ctx), 10)
	assert_eq(ConditionEval.eval_attr_expr("s1.战斗-s5.战斗", ctx), 2, "slot refs read their own slot card")
	# counter.<id> resolves through the state.
	assert_eq(ConditionEval.eval_attr_expr("counter.7000001*2", ctx), 12)
	# Bare tags sum the friend side; e() sums the enemy side.
	assert_eq(ConditionEval.eval_attr_expr("战斗", ctx), 3)
	assert_eq(ConditionEval.eval_attr_expr("e(战斗)", ctx), 1)
	assert_eq(ConditionEval.eval_attr_expr("e(战斗+体魄)", ctx), 5, "e() evaluates its inner expression per enemy card")
	# The classic combat check: friend side minus enemy side.
	assert_eq(ConditionEval.eval_attr_expr("战斗+体魄-e(战斗+体魄)", ctx), 0)


func test_slot_entries_split_by_is_enemy_flag() -> void:
	var local_db := _db_with_batch_rites()
	local_db.rites[992001]["cards_slot"] = {
		"s1": {"condition": {}}, "s2": {"condition": {}, "is_enemy": 1},
	}
	var state := GameState.new()
	state.add_card_to_hand(2000005, local_db)
	state.remove_card_from_hand(2000005)
	state.add_card_to_slot(2000005, 1, local_db, 1)
	var entries: Array = state.slot_entries_for_rite(local_db.rites[992001], 1)
	assert_eq(entries.size(), 1)
	assert_false(entries[0].get("is_enemy", true), "s1 stays on the friend side")
	state.add_card_to_hand(2000001, local_db)
	state.remove_card_from_hand(2000001)
	state.add_card_to_slot(2000001, 2, local_db, 1)
	entries = state.slot_entries_for_rite(local_db.rites[992001], 1)
	assert_eq(entries.size(), 2)
	assert_true(entries[1].get("is_enemy", false), "the s2 is_enemy flag marks the enemy side")


func test_card_lifetime_dies_unsheltered_and_survives_in_slots() -> void:
	# Every live card ages daily; card_vanishing death applies only outside
	# rite slots (shelter ignores the rite's start state).
	# [SRC: GameController.c @ DoCardUpdate (0x54d4c0); DisplayClass196_0
	#       @ <UpdateSingleCard>b__1 (0x572420): flag from any rite.cards]
	var local_db := _db_with_batch_rites()
	local_db.rites[992001]["cards_slot"] = {"s1": {"condition": {}}}
	# 2000452 受欢迎的妆扮 has card_vanishing 3. Two independent instances.
	var state := GameState.new()
	var hand_uid: int = state.add_card_to_hand(2000452, local_db)
	var slot_uid: int = state.add_card_to_hand(2000452, local_db)
	var rite = state.create_rite_instance(992001)
	state.remove_card_from_hand(slot_uid)
	state.add_card_to_slot(slot_uid, 1, local_db, rite.uid)

	RoundLoop.advance_day(state, local_db, RNG.new(31))
	RoundLoop.advance_day(state, local_db, RNG.new(32))
	assert_true(state.has_method("get_card_instance") and state.get_card_instance(hand_uid) != null,
		"life 2 of 3 keeps the hand copy alive")
	var day3 := RoundLoop.advance_day(state, local_db, RNG.new(33))
	assert_false(day3.expired_cards.is_empty(), "the unsheltered copy dies on its vanishing day")
	var dead_entry: Dictionary = day3.expired_cards[0]
	assert_eq(int(dead_entry.get("card_uid", 0)), hand_uid, "only the hand copy dies")
	assert_true(state.get_card_instance(slot_uid) != null and state.get_card_instance(slot_uid).zone == "slot",
		"the slotted copy is sheltered even though its rite never started")


func test_sudan_shelter_requires_any_slot_not_started_rite() -> void:
	# The deadline execution gate is presence in any rite slot — no start or
	# remaining-day conditions. [SRC: DoCardUpdate flag snapshot, report 1 A4]
	var local_db := _db_with_batch_rites()
	local_db.rites[992001]["cards_slot"] = {"s1": {"condition": {}}}
	local_db.rites[992001]["round_number"] = 0
	var state := GameState.new()
	var sudan = RoundLoop.ActiveSudan.new(2010001, 1, state.round_number, 0)
	var inst = state.create_card_instance(2010001, local_db, "sudan")
	inst.life = 6 # template deadline 7 -> 1 day left
	sudan.card_uid = inst.uid
	state.active_sudan_cards.append(sudan)
	var rite = state.create_rite_instance(992001)
	state.add_card_to_slot(inst.uid, 1, local_db, rite.uid)
	assert_false(rite.start, "precondition: the shelter rite is not started")

	var day := RoundLoop.advance_day(state, local_db, RNG.new(34))
	assert_false(day.game_over, "an unstarted rite still shelters the embedded Sultan")
	assert_false(day.expired.is_empty() == false and day.expired.size() > 0, "sanity")


func test_counter_and_card_born_and_game_end_timings_fire() -> void:
	# [SRC: GameController.c:9052/9116 OnCounterChanged/OnGlobalCounterChanged;
	#       GenCard.c:298 OnCardBorn; GameController.c:2868 OnGameEnd with
	#       GameEnd.c @ IsValid (0x45efe0) ending filter]
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events[992021] = {"id": 992021, "on": {"counter": 7000001}, "condition": {}}
	local_db.events[992022] = {"id": 992022, "on": {"global_counter": 8000001}, "condition": {}}
	local_db.events[992023] = {"id": 992023, "on": {"card_born": 2000005}, "condition": {},
		"settlement": [{"action": {"counter+7000003": 1}}]}
	local_db.events[992024] = {"id": 992024, "on": {"game_end": 12}, "condition": {}}
	local_db.events[992025] = {"id": 992025, "on": {"game_end": -1}, "condition": {}}
	var state := GameState.new()
	state.round_number = 0
	state._rebuild_event_runtime(local_db)
	for eid in [992021, 992022, 992023, 992024, 992025]:
		state.enable_event(eid, local_db)

	state.set_counter(7000001, 2)
	assert_true(992021 in state.event_queue, "counter timing fires on value change")
	state.set_global_counter(8000001, 5)
	assert_true(992022 in state.event_queue, "global_counter timing fires on value change")

	state.pending_operations.clear()
	ResultExec.execute({"card": 2000005}, state, local_db)
	assert_eq(state.get_counter(7000003), 1, "card_born settles its payload when a card is granted")
	ResultExec.execute({"card": 2000001}, state, local_db)
	assert_eq(state.get_counter(7000003), 1, "card_born matches only its configured id")

	# GameEnd ending filter: 12 matches, [4,11] would not, -1 matches any.
	# Settled non-replay events unregister, so only -1 survives a second fire.
	assert_eq(state.trigger_events("game_end", {"ending": 12}), [992024, 992025])
	assert_eq(state.trigger_events("game_end", {"ending": 4}), [], "settled non-replay events do not fire again")
	assert_eq(state.trigger_events("game_end", {}), [], "no ending id means no game_end event")


func test_counter_without_op_suffix_defaults_to_gte() -> void:
	# [SRC: HasCounter.c @ ctor (0x3fd8b0) -> Compare.Update default >=]
	var state := GameState.new()
	state.set_counter(7000001, 2)
	var ctx := {"state": state, "rite_state": {}, "attr_slots": []}
	assert_false(ConditionEval.eval_key("counter.7000001", 3, ctx), "2 >= 3 is false")
	assert_true(ConditionEval.eval_key("counter.7000001", 2, ctx), "2 >= 2 is true")
	assert_true(ConditionEval.eval_key("counter.7000001", 1, ctx), "2 >= 1 is true")


func test_redraw_writes_discarded_runtime_tags_back_to_pool() -> void:
	# The original reinserts the discarded Card object itself, so its runtime
	# tag overrides ride back into the pool for the next draw.
	# [SRC: RedrawSudanCard L3840-3842 List.Insert(card); report 7 A3]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.sudan_redraw_count = 1
	state.redraws_left = 1
	state.sudan_deck = [2010002, 2010003]
	RoundLoop.draw_weekly_sudan(state, local_db, RNG.new(45))
	var active_uid: int = int(state.active_sudan_cards[0].card_uid)
	state.get_card_instance(active_uid).tags["重抽回写"] = 5
	var discarded_id := int(state.active_sudan_cards[0].card_id)
	assert_eq(RoundLoop.use_redraw(state, RNG.new(46), local_db), 2010002)
	assert_eq(int(state.sudan_pool_tags.get(discarded_id, {}).get("重抽回写", 0)), 5,
		"the discarded card's runtime tags ride back into the pool")


func test_redraw_spends_extra_counter_when_per_round_is_exhausted() -> void:
	# Quota order: per-round allowance first, then counter 7100008.
	# [SRC: PlayerExtensions.c @ GetSudanRedrawCount (0x38dda0) per-round +
	#       counter 7100008; UseSudanExtraRedraw (0x38fb60); report 7 A4]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.sudan_redraw_count = 1
	state.redraws_left = 0
	state.set_counter(7100008, 1)
	state.sudan_deck = [2010002, 2010003]
	RoundLoop.draw_weekly_sudan(state, local_db, RNG.new(47))
	assert_eq(RoundLoop.use_redraw(state, RNG.new(48), local_db), 2010002,
		"the extra redraw counter funds a redraw")
	assert_eq(state.get_counter(7100008), 0, "the extra redraw counter is spent")
	assert_eq(RoundLoop.use_redraw(state, RNG.new(49), local_db), -1,
		"no allowance and no extra counter leaves the redraw rejected")


func test_back_to_prev_round_restores_snapshot_and_spends_budget() -> void:
	# Daily round_end snapshots + gated rollback: min_round, budget (9999 =
	# free), and wholesale state restore; the budget survives the restore.
	# [SRC: OnPrevRound (0x554f80) gates; PrevRoundInternal (0x555570);
	#       report 7 A1]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(61))
	state.back_to_prev_left = 2
	var coin_before := state.coin_count
	var round_before := state.round_number
	RoundLoop.advance_day(state, local_db, RNG.new(62))
	state.add_coin(9)
	assert_eq(state.round_number, round_before + 1)

	assert_true(RoundLoop.back_to_prev_round_end(state, local_db))
	assert_eq(state.round_number, round_before, "the round_end snapshot restores the prior round")
	assert_eq(state.coin_count, coin_before, "world effects after the snapshot are rolled back")
	assert_eq(state.back_to_prev_left, 1, "the budget decrement survives the restore")
	assert_false(RoundLoop.back_to_prev_round_end(state, local_db),
		"round 0 is below min_round 1 after the first rollback")
	assert_eq(state.back_to_prev_left, 1, "a gated rollback does not consume the budget")


func test_back_to_round_begin_restores_today_start() -> void:
	# [SRC: DoBackToRoundBegin.c @ Do; LoadRoundBegin; report 7 A1]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(63))
	RoundLoop.advance_day(state, local_db, RNG.new(64))
	var round_now := state.round_number
	var coin_at_begin := state.coin_count
	state.add_coin(7)
	assert_true(RoundLoop.back_to_round_begin(state, local_db))
	assert_eq(state.round_number, round_now, "the round_begin snapshot keeps the current round")
	assert_eq(state.coin_count, coin_at_begin, "effects after the boundary roll back")


func test_think_settles_every_satisfied_branch() -> void:
	# Think runs ALL satisfied settlement branches of the think rite, not the
	# first match. [SRC: ThinkController.c @ ProcessPop (0x5c38b0) L488-529;
	#       report 1 A7]
	var local_db := _db_with_batch_rites()
	local_db.init_config["think_id"] = 992003
	local_db.rites[992003] = {
		"id": 992003, "cards_slot": {"s1": {"condition": {}}},
		"settlement_prior": [],
		"settlement": [
			{"condition": {"s1.主角": 1}, "result": {"coin": 2}, "action": {}},
			{"condition": {"s1.type": "char"}, "result": {"counter+7000002": 3}, "action": {}},
			{"condition": {"s1.type": "sudan"}, "result": {"coin": 50}, "action": {}},
		],
		"settlement_extre": [],
	}
	var state := GameState.new()
	state.add_card_to_hand(2000001, local_db) # 阿尔图: 主角 + char
	var result: Dictionary = MethinksEngine.process_card(2000001, "hand", state, local_db, RNG.new(71))
	assert_true(result.get("accepted", false))
	assert_eq(state.coin_count, 2, "the first satisfied branch runs")
	assert_eq(state.get_counter(7000002), 3, "the second satisfied branch also runs")
	assert_ne(state.coin_count, 52, "the unsatisfied sudan branch stays silent")


func test_is_without_acting_card_checks_slotted_cards() -> void:
	# [SRC: IsCardId.c @ 0x402180: ctx.main first, otherwise any slot card;
	#       report 3 A7]
	var ctx_no_slots := {"state": null, "rite_state": {}, "attr_slots": [], "slot_entries": []}
	assert_false(ConditionEval.eval_key("is", 2000005, ctx_no_slots), "no acting card and no slots -> false")
	var ctx := {"state": null, "rite_state": {}, "attr_slots": [], "slot_entries": [
		{"slot": "s1", "card_id": 2000005, "card_uid": 1, "tags": {}, "is_enemy": false},
	]}
	assert_true(ConditionEval.eval_key("is", 2000005, ctx), "a slotted card matches without an acting card")
	assert_false(ConditionEval.eval_key("is", 2000001, ctx), "unmatched ids stay false")
	var acting_ctx := ctx.duplicate()
	acting_ctx["acting_card_id"] = 2000001
	assert_false(ConditionEval.eval_key("is", 2000005, acting_ctx), "the acting card takes priority over slots")


func test_drop_auto_routes_to_first_satisfied_slot() -> void:
	# [SRC: RiteExtensions.c @ GetSatisfiedSlotIndex (0x392ac0); report 8 A5]
	var local_db := _db_with_batch_rites()
	local_db.rites[992001]["cards_slot"] = {
		"s1": {"condition": {"type": "char"}, "open_adsorb": 0},
		"s2": {"condition": {"type": "char"}},
		"s3": {"condition": {"is": 2000001}},
	}
	local_db.rites[992001]["auto_begin"] = 0
	var state := GameState.new()
	state.add_card_to_hand(2000005, local_db) # char
	var view := RiteView.new()
	view.setup(state, local_db, RNG.new(81), 992001)
	var card: Dictionary = state.card_data_for(int(state.hand[0]), local_db)
	assert_eq(view._first_satisfied_slot(card), "s1", "the first accepting slot wins")
	view._placed["s1"] = int(state.hand[0])
	assert_eq(view._first_satisfied_slot(card), "s2", "filled slots are skipped")
	view.free()


func test_rebirth_resets_slot_card_countdown() -> void:
	# [SRC: RebirthSudanCard.c @ Do (0x519d60) + <Do>b__4_0 (0x51dec0):
	#       Card.set_life(0); active Sultan deadlines restore to the
	#       difficulty lifetime via UpdateSudanLife]
	var local_db := _db_with_batch_rites()
	local_db.rites[992001]["cards_slot"] = {"s1": {"condition": {}}}
	var state := GameState.new()
	var sudan = RoundLoop.ActiveSudan.new(2010001, 2, state.round_number, 0)
	var inst = state.create_card_instance(2010001, local_db, "sudan")
	sudan.card_uid = inst.uid
	state.active_sudan_cards.append(sudan)
	var rite = state.create_rite_instance(992001)
	state.add_card_to_slot(inst.uid, 1, local_db, rite.uid)
	inst.life = 5

	ResultExec.execute({"rebirth.s1": 1}, state, local_db, {"rite_uid": rite.uid})

	assert_eq(inst.life, 0, "the slotted card's life restarts from zero")
	assert_eq(sudan.days_left, int(state.difficulty_config.get("sudan_life_time", 7)),
		"the active Sultan deadline restores to the difficulty lifetime")


func test_difficulty_action_switches_mid_run() -> void:
	# [SRC: SetDifficulty.c @ Do (0x51b5b0); GameState.apply_difficulty]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(91))
	state.redraws_left = 0
	state.back_to_prev_left = 9999 # easy allowance
	ResultExec.execute({"difficulty": 1}, state, local_db)
	var pick: Dictionary = {}
	for prompt in state.event_prompts:
		if str(prompt.get("title", "")) == "选择你的叙事者":
			pick = prompt
	assert_false(pick.get("choices", {}).is_empty(), "the difficulty action opens the narrator choice")
	DeferredEffects.execute_choice("diff_1", pick["choices"]["diff_1"], state, local_db, RNG.new(1))
	assert_eq(state.difficulty_index, 1, "the chosen narrator switches the difficulty")
	assert_eq(state.redraws_left, int(state.difficulty_config.get("sudan_redraw_times_per_round", 0)),
		"per-round redraws refresh from the new difficulty")
	assert_eq(state.back_to_prev_left, int(state.difficulty_config.get("back_to_prev_round_count", 0)),
		"leaving the free-rollback difficulty drops the budget to its allowance")


func test_begin_guide_family_installs_and_clears_directive() -> void:
	# [SRC: BeginGuide.c / CloseBeginGuide.c; BeginGuideController.c
	#       @ ShowBeginGuide (0x526220) / OnCloseBtnClick (0x525fa0)]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(101))
	assert_true(state.begin_guide.is_empty(), "no directive at start")
	ResultExec.execute({"begin_guide": {"type": "NEXT_DAY", "bind": "UI/Submit"}}, state, local_db)
	assert_eq(str(state.begin_guide.get("type", "")), "NEXT_DAY", "begin_guide installs the directive")
	ResultExec.execute({"hand_pop.1_1.主角": "看这里", "focus.2": 1}, state, local_db)
	assert_eq(state.guide_cues.size(), 2, "presentation cues accumulate")
	ResultExec.execute({"close_begin_guide": 1}, state, local_db)
	assert_true(state.begin_guide.is_empty(), "close_begin_guide clears the directive")
	assert_true(state.guide_cues.is_empty(), "and drops the cue queue")
	# The guide state round-trips through the save.
	ResultExec.execute({"begin_guide": {"type": "BACK_ROUND"}}, state, local_db)
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, local_db)
	assert_eq(str(restored.begin_guide.get("type", "")), "BACK_ROUND", "guide directives survive save/load")


func test_close_guide_operations_update_persisted_hud_visibility_preferences() -> void:
	# close_* uses value 0 to ShowX(true), and non-zero to hide. The four
	# `*_unshow` Player fields therefore have the inverse polarity.
	# [SRC: CloseBox.c Do (0x4f44c0), CloseDeadline.c Do (0x4f46b0),
	#       CloseHelpBtn.c Do (0x4f48a0), ClosePrestige.c Do (0x4f4a90),
	#       CloseStory.c Do (0x4f4c80); GameController.c Show* methods]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(102))
	ResultExec.execute({"close_box": 1, "close_story": 1, "close_prestige": 1,
		"close_deadline": 1, "close_helpbtn": 1}, state, local_db)
	assert_false(state.sudan_box_show, "non-zero close_box hides the box")
	assert_true(state.story_unshow, "non-zero close_story records hidden")
	assert_true(state.prestige_unshow, "non-zero close_prestige records hidden")
	assert_true(state.deadline_unshow, "non-zero close_deadline records hidden")
	assert_true(state.helpbtn_unshow, "non-zero close_helpbtn records hidden")
	ResultExec.execute({"close_box": 0, "close_story": 0, "close_prestige": 0,
		"close_deadline": 0, "close_helpbtn": 0}, state, local_db)
	assert_true(state.sudan_box_show, "zero close_box shows the box")
	assert_false(state.story_unshow, "zero close_story records visible")
	assert_false(state.prestige_unshow, "zero close_prestige records visible")
	assert_false(state.deadline_unshow, "zero close_deadline records visible")
	assert_false(state.helpbtn_unshow, "zero close_helpbtn records visible")


func test_sudan_execution_records_its_ending_id() -> void:
	# The executed Sultan's vanish.over id becomes the ending shown on the
	# game-over screen (over.json is indexed by it).
	# [SRC: 2010001 vanish {"over":12}; data/config/over.json entry 12]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(111))
	var sudan = RoundLoop.ActiveSudan.new(2010001, 1, state.round_number, 0)
	var inst = state.create_card_instance(2010001, local_db, "sudan")
	inst.life = 6 # template deadline 7 -> 1 day left
	sudan.card_uid = inst.uid
	state.active_sudan_cards.append(sudan)
	var day := RoundLoop.advance_day(state, local_db, RNG.new(112))
	assert_true(day.game_over, "the deadline executes")
	assert_eq(state.over_reason, 12, "the ending id comes from the card's vanish.over")


func test_over_action_value_sets_ending_id() -> void:
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	ResultExec.execute({"over": 7}, state, local_db)
	assert_false(state.success, "GameOver operation writes the original failure flag")
	assert_eq(state.over_reason, 7, "a numeric over value selects the ending")


func test_difficulty_choices_carry_narrator_presentation() -> void:
	# The choice entries are built from the init difficulty configs with the
	# narrator portrait + desc the DifficultyPanel shows per item.
	# [SRC: DifficultyPanelController.c UpdateShow portrait+desc; init/1.json]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(92))
	ResultExec.execute({"difficulty": 1}, state, local_db)
	var pick: Dictionary = {}
	for prompt in state.event_prompts:
		if str(prompt.get("title", "")) == "选择你的叙事者":
			pick = prompt
	assert_false(pick.get("choices", {}).is_empty(), "the difficulty action opens the narrator choice")
	var first: Dictionary = pick["choices"].get("diff_0", {})
	assert_eq(int(first.get("value", -1)), 0, "each narrator choice carries its difficulty index")
	assert_true(str(first.get("text", "")).contains("梅姬"), "choice text names the narrator from the config")
	assert_true(str(first.get("icon", "")).begins_with("ui/710000"), "choice icon points at the narrator portrait art")
	assert_true(str(first.get("desc", "")).length() > 10, "choice desc carries the narrator introduction")


func test_hand_card_refresh_is_a_presentation_noop() -> void:
	# [SRC: HandCardRefresh.c @ Do (0x513e40) -> GameController.UpdateHandCards]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(93))
	var hand_size := state.hand.size()
	var coin := state.coin_count
	var deferred: Dictionary = ResultExec.execute({"hand_card_refresh": 1}, state, local_db)
	assert_eq(state.hand.size(), hand_size, "hand refresh must not mutate the hand")
	assert_eq(state.coin_count, coin, "hand refresh must not mutate gold")
	assert_false(deferred.get("ordered_effects", []).is_empty(), "the refresh records its effect for the UI layer")


func test_display_text_placeholders_substitute_live_values() -> void:
	# Prompt/result texts carry config placeholders the original formats with
	# live run values before display. [SRC: event/5300066.json
	#       "[sudan_life_time]天时间"; event/5300339.json
	#       "[sudan_redraw_total_left_times]次重抽"]
	var local_db := _db_with_batch_rites()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(94))
	state.redraws_left = 2
	state.queue_prompt({"id": "probe", "text": "你有[sudan_life_time]天时间，[sudan_redraw_total_left_times]次重抽。"})
	var queued: Dictionary = {}
	for prompt in state.event_prompts:
		if str(prompt.get("id", "")) == "probe":
			queued = prompt
	assert_eq(str(queued.get("text", "")), "你有%s天时间，%d次重抽。" % [
		str(int(state.difficulty_config.get("sudan_life_time", 7))), 2,
	], "queued prompt text substitutes the live run values")


func test_dsl_audit_scans_case_subtree_interiors() -> void:
	# case:opN subtrees execute real result ops after a choice; their keys
	# must reach the audit (hand_card_refresh once hid inside one).
	var local_db := _db_with_batch_rites()
	local_db.events[990042] = {
		"id": 990042,
		"on": {"round_begin_ba": 1},
		"settlement": [{"action": {
			"option": {"id": "probe_opt", "text": "选", "items": [{"text": "a", "tag": "op1"}]},
			"case:op1": {"hand_card_refresh": 1, "coin": 3},
		}}],
	}
	var report: Dictionary = DslAudit.audit_configs({}, local_db.events, {}, local_db)
	assert_true(report.action.supported.has("hand_card_refresh"), "case subtree keys are audited")
	assert_true(report.action.supported.has("coin"), "case subtree ops are audited")
	assert_false(report.action.unsupported.has("items"), "option display payloads stay opaque")
