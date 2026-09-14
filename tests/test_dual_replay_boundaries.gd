extends GutTest

var db: ConfigDB

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

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
