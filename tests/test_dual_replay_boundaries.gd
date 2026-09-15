extends GutTest

var db: ConfigDB

func test_rite_result_pop_keeps_card_text_without_global_confirmation() -> void:
	var state := GameState.new()
	var rite = state.create_rite_instance(5001001)
	var uid := state.add_card_to_hand(2000001, db)
	state.add_card_to_slot(uid, 2, db, rite.uid)
	state.rite_settlements[str(rite.uid)] = {"phase": "results"}
	var context := {"rite_uid": rite.uid, "settlement_job": str(rite.uid)}
	var deferred := ResultExec.execute({"pop.test.s2": ["第一句话", "第二句话"]}, state, db, context)
	DeferredEffects.apply(deferred, state, db, GameRNG.new(1))
	assert_true(state.pending_operations.is_empty(), "CardPop.PreDo does not create a fullscreen confirmation")
	assert_eq(deferred.card_ops.size(), 2, "one card operation per authored speech")
	assert_eq(deferred.card_ops[0].op, 9)
	assert_eq(deferred.card_ops[0].card_uid, uid)
	assert_eq(deferred.card_ops[0].pop, "第一句话")
	assert_eq(deferred.card_ops[1].pop, "第二句话")
	state.rite_settlements[str(rite.uid)]["deferred"] = deferred
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(restored.rite_settlements[str(rite.uid)].deferred.card_ops, deferred.card_ops,
		"speech target, authored order and text survive save deserialization")
	var empty := ResultExec.execute({"pop.test.s3": "不应出现"}, state, db, context)
	assert_true(empty.card_ops.is_empty(), "empty slot produces no anonymous speech")
	assert_true(empty.prompts.is_empty())

class LastCandidateRNG extends GameRNG:
	var calls := 0
	var ranges: Array = []
	func range_int_half_open(from_n: int, to_n: int) -> int:
		calls += 1
		ranges.append([from_n, to_n])
		return to_n - 1 if to_n > from_n else from_n

func test_source_shuffle_uses_forward_ranges_and_pair_swap() -> void:
	var rng := LastCandidateRNG.new()
	assert_eq(rng.shuffle(["a", "b", "c", "d"]), ["d", "a", "b", "c"])
	assert_eq(rng.ranges, [[0, 4], [1, 4], [2, 4]])
	assert_eq(rng.shuffle(["a", "b"]), ["b", "a"], "source swaps pair when Range returns 1")
	assert_eq(rng.shuffle(["a"]), ["a"])
	assert_eq(rng.calls, 4, "singleton consumes no draw")

func test_round_timing_rearm_uses_supplied_game_rng_before_event_condition() -> void:
	var state := GameState.new()
	state.event_status[5310809] = true
	state.timing_rounds[531080900] = 5
	state.event_runtime = EventRuntime.new()
	state.event_runtime._db = db
	state.event_runtime._state = weakref(state)
	state.event_runtime.enable_event(5310809)
	var rng := LastCandidateRNG.new()
	var fired: Array[int] = state.event_runtime.fire("round_begin_ba", {"round": 5, "rng": rng})
	assert_false(5310809 in fired, "missing madness/protagonist fails the event condition")
	assert_eq(state.timing_rounds[531080900], 11, "source rearms first: round 5 + Range(3,7)=6")
	assert_eq(rng.calls, 1, "rearming consumes the supplied game stream, not global randi")
	state.event_runtime.fire("round_begin_ba", {"round": 6, "rng": rng})
	assert_eq(rng.calls, 1, "before due date no draw is consumed")
	assert_eq(EventRuntime.next_round([3], 5, {"rng": rng}), 8)
	assert_eq(rng.calls, 1, "single period is deterministic")

func test_adsorption_samples_multiple_candidates_but_not_singletons() -> void:
	var state := GameState.new()
	var rng := LastCandidateRNG.new()
	var first := state.add_card_to_hand(2000001, db)
	var second := state.add_card_to_hand(2000001, db)
	var rite = state.create_rite_instance(5000001)
	var definition := {"cards_slot": {"s1": {"open_adsorb": 1, "condition": {"is": 2000001}}}}
	assert_true(state._adsorb_open_slots(rite, definition, db, rng))
	assert_eq(rite.slot_cards.s1, second, "source random candidate can be the last, not always the first")
	assert_eq(rng.calls, 1)
	assert_eq(state._choose_adsorb_candidate([first], rng), first)
	assert_eq(rng.calls, 1, "a singleton consumes no random draw")

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func test_have_id_tag_counts_source_loot_candidates() -> void:
	var state := GameState.new()
	state.add_card_to_hand(2000081, db)
	var ctx := {"state": state, "db": db}
	assert_true(ConditionEval.evaluate(db.get_loot(6000019).item[1].condition, ctx))
	assert_false(ConditionEval.evaluate(db.get_loot(6000019).item[0].condition, ctx))
	assert_false(ConditionEval.evaluate({"table_have.2000081.妓女>=": 2}, ctx))
	var other := state.add_card_to_hand(2000082, db)
	state.get_card_instance(other).tags["魅力"] = -10
	assert_true(ConditionEval.evaluate({"table_have.魅力<=": -2}, ctx), "sum keeps negative contributions; it is not a positive-tag filter")

func test_tag_generation_counts_add_calls_not_units_or_removals() -> void:
	var state := GameState.new()
	var uid := state.add_card_to_hand(2000001, db)
	var tags: Dictionary = state.get_card_instance(uid).tags
	state.gen_tags.clear()
	ResultExec._mutate_tag(tags, state, uid, "倦怠", TagSystem.Op.ADD, 4, true, 0, db)
	assert_eq(state.gen_tags.get("ennui", 0), 1)
	ResultExec._mutate_tag(tags, state, uid, "倦怠", TagSystem.Op.SUB, 2, true, 4, db)
	assert_eq(state.gen_tags.get("ennui", 0), 1)
	ResultExec._mutate_tag(tags, state, uid, "倦怠", TagSystem.Op.SET, 3, true, 2, db)
	assert_eq(state.gen_tags.get("ennui", 0), 2)
	ResultExec._mutate_tag(tags, state, uid, "倦怠", TagSystem.Op.SET, 3, true, 3, db)
	ResultExec._mutate_tag(tags, state, uid, "已拥有", TagSystem.Op.ADD, 1, false, 1, db)
	assert_eq(state.gen_tags.get("ennui", 0), 2)
	assert_false(state.gen_tags.has("own"))

func test_empty_household_does_not_see_another_rites_slots() -> void:
	var state := GameState.new()
	var household = state.create_rite_instance(5000001)
	var other = state.create_rite_instance(5001001)
	state.add_card_to_slot(2000005, 1, db, other.uid)
	var ctx := {"state": state, "db": db, "rite_uid": household.uid}
	assert_true(ConditionEval.evaluate({"!s1": 1, "!s2": 1}, ctx))
	ctx.rite_uid = other.uid
	assert_false(ConditionEval.evaluate({"!s1": 1}, ctx))

func test_bare_rite_tag_sums_friends_and_excludes_unrelated_cards() -> void:
	var state := GameState.new()
	var court = state.create_rite_instance(5001001)
	var calumny := state.add_card_to_hand(2000168, db)
	state.get_card_instance(calumny).count = 3
	state.add_card_to_slot(calumny, 1, db, court.uid)
	state.add_card_to_hand(2000001, db)
	var ctx := {"state": state, "db": db, "rite_uid": court.uid}
	assert_true(ConditionEval.evaluate({"谗言>=": 3}, ctx))
	assert_false(ConditionEval.evaluate({"谗言<": 3}, ctx))

func test_default_events_keep_original_timing_ordinals_without_overrides() -> void:
	var state := GameState.new()
	state.round_number = 4
	state.event_init_profile_id = 1
	state.timing_rounds[531045301] = 5
	state._rebuild_event_runtime(db)
	assert_true(state.event_runtime._by_timing["round_begin_ba"].has(5310453))
	assert_false(state.event_status.has(5310453))
	assert_false(state.timing_rounds.has(531045300))
	assert_eq(state.timing_rounds[531045301], 5)
	state.event_status[5310453] = false
	state._rebuild_event_runtime(db)
	assert_false(state.event_runtime._by_timing["round_begin_ba"].has(5310453))

func test_loaded_special_counters_clamp_but_regular_counters_do_not() -> void:
	var state := GameState.new()
	var loaded := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), loaded, db)
	loaded.sub_counter(7100003, 5)
	loaded.sub_counter(7000073, 5)
	assert_eq(loaded.get_counter(7100003), 0)
	assert_eq(loaded.get_counter(7000073), -5)

func test_repeat_household_is_not_new_and_adds_no_new_rite_note() -> void:
	var state := GameState.new()
	var first := DeferredEffects._add_rite_and_note(5000001, state, db, GameRNG.new(1))
	assert_true(state.get_rite_instance(first).new_born)
	assert_false(state.once_new_rites_is_show[5000001])
	var count: int = state.notes[0].size()
	var second := DeferredEffects._add_rite_and_note(5000001, state, db, GameRNG.new(1))
	assert_false(state.get_rite_instance(second).new_born)
	assert_eq(state.notes[0].size(), count)

func test_original_comparison_excludes_removed_card_tombstones() -> void:
	var state := GameState.new()
	var uid := state.add_card_to_hand(2000168, db)
	state.get_card_instance(uid).count = 3
	state.remove_card_instance_from_play(uid)
	assert_true(state.card_instances.has(uid), "pending operations can still identify the removed card")
	assert_true(OriginalSaveImporter._clone_per_id_counts(state).is_empty())
	assert_true(OriginalSaveImporter._live_clone_cards(state).is_empty())
	assert_true(OriginalSaveImporter._clone_bag_positions(state).is_empty())

func test_loot_keeps_stack_quantity_and_nonstack_object_count() -> void:
	var state := GameState.new()
	DeferredEffects._apply_loot_ref(6000051, state, db, GameRNG.new(1))
	var counts := OriginalSaveImporter._clone_per_id_counts(state)
	assert_eq(counts.get(2001051), 4)
	assert_eq(state.gen_cards.get(2001051), 1, "one generated stack, four units")
	DeferredEffects._apply_loot_item(2000001, state, db, GameRNG.new(1), {"num": "2"})
	assert_eq(OriginalSaveImporter._clone_per_id_counts(state).get(2000001), 2)
	assert_eq(state.gen_cards.get(2000001), 2, "nonstack cards are separate objects")

func test_clean_rite_returns_npcs_for_recreated_shop() -> void:
	var state := GameState.new()
	var shop = state.create_rite_instance(5002006)
	var npc := state.add_card_to_hand(2000199, db)
	state.add_card_to_slot(npc, 5, db, shop.uid)
	ResultExec.execute({"clean.rite": 5002006}, state, db)
	assert_null(state.get_rite_instance(shop.uid))
	assert_ne(state.get_card_instance(npc).zone, "removed")
	assert_true(npc in state.player_card_order)
