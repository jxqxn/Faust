extends GutTest

## Batch-1 DSL expansion (2026-08-14 unfreeze): bare ModifyTag/ModifyRare,
## copy.s<n>, delay_off, steam_achievement/debug no-ops, and the
## rite_end / rite_have / round<op> conditions.
## Semantics are source-cited in sim/result.gd and sim/condition.gd.

const RNG = preload("res://core/rng.gd")


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
	assert_false(ConditionEval.eval_key("round<=", 14, ctx), "round 15 does not satisfy round<=14")
	assert_true(ConditionEval.eval_key("round<=", 15, ctx), "round 15 satisfies round<=15")
	assert_true(ConditionEval.eval_key("round<=", 16, ctx), "round 15 satisfies round<=16")
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
	assert_false(ResultExec.is_supported_key("rebirth.s1"), "rebirth stays audited until its semantics are source-confirmed")
	for key in ["rite_end.5000313", "rite_have.5008227.主角=", "rite_have.5008226.主角=", "round<="]:
		assert_true(ConditionEval.is_supported_key(key), "condition key supported: %s" % key)
