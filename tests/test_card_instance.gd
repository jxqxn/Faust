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
