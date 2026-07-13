extends GutTest

const RNG = preload("res://core/rng.gd")

var db: ConfigDB


func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_instance_tags_survive_hand_slot_and_hand_round_trip() -> void:
	var state := GameState.new()
	var card_uid := state.add_card_to_hand(2000005, db)
	var instance = state.get_card_instance(card_uid)
	instance.tags["临时标记"] = 7

	assert_true(state.remove_card_from_hand(card_uid))
	state.add_card_to_slot(card_uid, 1, db, 11)
	assert_eq(int(state.cards_in_slot(1, 11)[0].get("card_uid", 0)), card_uid)
	assert_eq(int(state.cards_in_slot(1, 11)[0].get("tags", {}).get("临时标记", 0)), 7)

	assert_true(state.remove_card_from_slot(card_uid, 1, 11))
	state.add_card_to_hand(card_uid, db)
	assert_eq(state.hand, [card_uid])
	assert_eq(int(state.get_card_instance(card_uid).tags.get("临时标记", 0)), 7)


func test_same_definition_instances_keep_independent_tags() -> void:
	var state := GameState.new()
	var first_uid := state.add_card_to_hand(2000005, db)
	var second_uid := state.add_card_to_hand(2000005, db)
	assert_ne(first_uid, second_uid)
	assert_eq(state.hand, [first_uid, second_uid])

	state.get_card_instance(first_uid).tags["临时标记"] = 1
	state.get_card_instance(second_uid).tags["临时标记"] = 9
	assert_eq(int(state.get_card_instance(first_uid).tags["临时标记"]), 1)
	assert_eq(int(state.get_card_instance(second_uid).tags["临时标记"]), 9)


func test_slot_tag_operation_is_scoped_to_the_active_rite_instance() -> void:
	var state := GameState.new()
	var first_rite := state.create_rite_instance(990101)
	var second_rite := state.create_rite_instance(990102)
	var first_uid := state.add_card_to_hand(2000005, db)
	var second_uid := state.add_card_to_hand(2000005, db)
	state.remove_card_from_hand(first_uid)
	state.remove_card_from_hand(second_uid)
	state.add_card_to_slot(first_uid, 1, db, first_rite.uid)
	state.add_card_to_slot(second_uid, 1, db, second_rite.uid)
	assert_eq(int(first_rite.slot_cards.get("s1", 0)), first_uid)
	assert_eq(int(second_rite.slot_cards.get("s1", 0)), second_uid)

	state.active_rite_uid = first_rite.uid
	ResultExec.execute({"s1+临时标记": 3}, state, db)
	state.active_rite_uid = 0
	assert_eq(int(state.get_card_instance(first_uid).tags.get("临时标记", 0)), 3)
	assert_eq(int(state.get_card_instance(second_uid).tags.get("临时标记", 0)), 0)


func test_v5_save_restores_instance_uids_and_runtime_tags() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(77))
	var card_uid := int(state.hand[0])
	state.get_card_instance(card_uid).tags["临时标记"] = 4
	state.remove_card_from_hand(card_uid)
	state.add_card_to_slot(card_uid, 1, db, 0)
	var saved := SaveSystem.serialize(state)
	var restored := GameState.new()
	SaveSystem.deserialize(saved, restored, db)

	assert_eq(int(saved.get("version", 0)), SaveSystem.SAVE_VERSION)
	assert_eq(int(restored.cards_in_slot(1)[0].get("card_uid", 0)), card_uid)
	assert_eq(int(restored.get_card_instance(card_uid).tags.get("临时标记", 0)), 4)


func test_event_context_modifies_only_the_triggering_sultan_instance() -> void:
	var state := GameState.new()
	var first_uid: int = state.create_card_instance(2000024, db, "sudan").uid
	var second_uid: int = state.create_card_instance(2000024, db, "sudan").uid
	DeferredEffects.execute_event({
		"id": 990120,
		"settlement": [{"action": {"table.2000024=上朝": 1}}],
	}, state, db, RNG.new(17), {"card_uid": first_uid, "card": 2000024})

	assert_eq(int(state.get_card_instance(first_uid).tags.get("上朝", 0)), 1)
	assert_eq(int(state.get_card_instance(second_uid).tags.get("上朝", 0)), 0)
	ResultExec.execute({"table.2000024=上朝": 0}, state, db, {"card_uid": first_uid})
	assert_eq(int(state.get_card_instance(first_uid).tags.get("上朝", 0)), 0, "set-zero removes the triggering Sultan state")
	assert_eq(int(state.get_card_instance(second_uid).tags.get("上朝", 0)), 0, "set-zero remains scoped to the triggering instance")


func test_option_prompt_preserves_triggering_card_context() -> void:
	var state := GameState.new()
	var first_uid: int = state.create_card_instance(2000024, db, "sudan").uid
	var second_uid: int = state.create_card_instance(2000024, db, "sudan").uid
	var action := {
		"option": {"text": "选择", "items": [{"text": "上朝", "tag": "op1"}]},
		"case:op1": {"table.2000024=上朝": 1},
	}
	var deferred := ResultExec.execute(action, state, db, {"card_uid": first_uid, "card": 2000024})
	DeferredEffects.apply(deferred, state, db, RNG.new(18))
	var prompt: Dictionary = state.event_prompts[0]
	var choice: Dictionary = prompt.choices["case:op1"]
	DeferredEffects.execute_choice("case:op1", choice.value, state, db, RNG.new(18), prompt.context)

	assert_eq(int(state.get_card_instance(first_uid).tags.get("上朝", 0)), 1)
	assert_eq(int(state.get_card_instance(second_uid).tags.get("上朝", 0)), 0)


func test_rite_cleanup_consumes_the_exact_sultan_instance() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(19))
	var first_instance = state.create_card_instance(2000024, db, "sudan")
	var second_instance = state.create_card_instance(2000024, db, "sudan")
	state.active_sudan_cards.append(RoundLoop.ActiveSudan.new(2000024, 3, 1, first_instance.uid))
	state.active_sudan_cards.append(RoundLoop.ActiveSudan.new(2000024, 3, 1, second_instance.uid))
	var rite := state.create_rite_instance(990121)
	state.add_card_to_slot(second_instance.uid, 1, db, rite.uid)
	var source_entries := state.cards_in_slot_entries_for_rite(rite.uid)

	RoundLoop.finalize_rite_settlement(rite, {"clean_rite": true}, state, db, source_entries)

	assert_eq(state.active_sudan_cards.size(), 1)
	assert_eq(int(state.active_sudan_cards[0].card_uid), first_instance.uid, "the unslotted duplicate remains active")
	assert_eq(second_instance.zone, "removed", "the slotted instance is the one consumed")


func test_power_game_event_adsorbs_the_tagged_active_sultan_instance() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(91))
	var sudan = RoundLoop.ActiveSudan.new(2000024, 3, state.round_number, 0)
	var sultan_instance = state.create_card_instance(2000024, db, "sudan")
	sudan.card_uid = sultan_instance.uid
	state.active_sudan_cards.append(sudan)

	var event := db.get_event(5300089)
	assert_false(event.is_empty(), "the configured power-game event must be available")
	DeferredEffects.execute_event(event, state, db, RNG.new(91))

	var rite := state.find_rite_instance_by_id(5001001)
	assert_not_null(rite, "the event should generate the configured Power Game rite")
	if rite == null:
		return
	assert_eq(int(sultan_instance.tags.get("上朝", 0)), 1)
	assert_eq(int(rite.slot_cards.get("s2", 0)), sultan_instance.uid)
	assert_eq(sultan_instance.zone, "slot")
	assert_true(sultan_instance.uid not in state.hand, "the active Sultan is not copied into hand during adsorption")

	var started := RoundLoop.start_auto_begin_rites(state, db)
	assert_true(started.any(func(entry): return int(entry.get("uid", 0)) == rite.uid), "the generated rite auto-starts")
	RoundLoop.advance_day(state, db, RNG.new(91))
	assert_null(state.get_rite_instance(rite.uid), "the one-round rite settles exactly once and is removed")
	assert_eq(sultan_instance.zone, "slot", "the configured settlement reuses the same Sultan in its next rite")
	assert_eq(int(sultan_instance.tags.get("上朝", 0)), 1, "the successor rite preserves the runtime state")

	# `!rite` is now a runtime-instance gate. Move the Sultan to a neutral
	# table slot after the repeatable Power Game instance has ended.
	var successor := state.find_rite_instance_by_id(5001001)
	if successor != null:
		state.remove_rite_instance(successor.uid)
	state.add_card_to_slot(sultan_instance.uid, 1, db)
	DeferredEffects.execute_event(db.get_event(5300357), state, db, RNG.new(91))
	assert_eq(int(sultan_instance.tags.get("上朝", 0)), 0, "the configured follow-up removes 上朝 from the same Sultan instance")
