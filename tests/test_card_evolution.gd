extends GutTest

const RNG = preload("res://core/rng.gd")

var db: ConfigDB


func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_runtime_name_text_and_rarity_are_instance_scoped_and_clamped() -> void:
	var state := GameState.new()
	var first_uid := state.add_card_to_hand(2001193, db)
	var second_uid := state.add_card_to_hand(2001193, db)

	assert_true(state.set_card_custom_name(first_uid, "新名字"))
	assert_true(state.set_card_custom_text(first_uid, "永久变化后的描述"))
	assert_true(state.modify_card_rarity(first_uid, 9, db))

	var first: Dictionary = state.card_data_for(first_uid, db)
	var second: Dictionary = state.card_data_for(second_uid, db)
	assert_eq(str(first.name), "新名字")
	assert_eq(str(first.text), "永久变化后的描述")
	assert_eq(int(first.rare), 4, "runtime rare is clamped to the original 1..4 range")
	assert_eq(int(second.rare), 1, "a same-definition sibling keeps its own rarity")
	assert_ne(str(second.name), "新名字", "custom copy never mutates the shared definition")


func test_result_dsl_changes_the_exact_slotted_runtime_card() -> void:
	var state := GameState.new()
	var rite := state.create_rite_instance(990301)
	var host_uid := state.add_card_to_hand(2001193, db)
	state.remove_card_from_hand(host_uid)
	state.add_card_to_slot(host_uid, 1, db, rite.uid)
	var context := {"rite_uid": rite.uid}

	ResultExec.execute({
		"s1.uprare": 1,
		"change_card_name.test.s1": "镜中的生灵",
		"change_card_text.test.s1": "它已经改变。",
		"s1+equip_slot": "animal_handling",
		"s1+equip": 2000156,
	}, state, db, context)

	var host = state.get_card_instance(host_uid)
	var card: Dictionary = state.card_data_for(host_uid, db)
	assert_eq(int(card.rare), 2)
	assert_eq(str(card.name), "镜中的生灵")
	assert_eq(str(card.text), "它已经改变。")
	assert_true("驯兽" in card.equip_slots, "config code is normalized to the visible slot name")
	assert_eq(host.equipped_uids.size(), 1)
	assert_eq(int(card.tag.get("战斗", 0)), 4, "inheritable equipment stats contribute to the host")
	assert_eq(state.get_card_instance(host.equipped_uids[0]).zone, "equipped")


func test_minus_destroys_equipment_while_tilde_recovers_it_to_hand() -> void:
	var state := GameState.new()
	var rite := state.create_rite_instance(990302)
	var host_uid := state.add_card_to_hand(2001193, db)
	state.remove_card_from_hand(host_uid)
	state.add_card_to_slot(host_uid, 1, db, rite.uid)
	var context := {"rite_uid": rite.uid}

	ResultExec.execute({"s1+equip": 2000156}, state, db, context)
	var destroyed_uid := int(state.get_card_instance(host_uid).equipped_uids[0])
	ResultExec.execute({"s1-equip": 2000156}, state, db, context)
	assert_eq(state.get_card_instance(destroyed_uid).zone, "removed")
	assert_true(destroyed_uid not in state.hand)

	ResultExec.execute({"s1+equip": 2000156}, state, db, context)
	var recovered_uid := int(state.get_card_instance(host_uid).equipped_uids[0])
	ResultExec.execute({"no_show": {"s1~equip": ["装备"]}}, state, db, context)
	assert_eq(state.get_card_instance(recovered_uid).zone, "hand")
	assert_true(recovered_uid in state.hand)


func test_interactive_attach_replaces_same_slot_and_recovers_old_card() -> void:
	var state := GameState.new()
	var host_uid := state.add_card_to_hand(2001193, db)
	var dagger_uid := state.add_card_to_hand(2000246, db)
	var sword_uid := state.add_card_to_hand(2000252, db)

	assert_eq(state.attach_equipment(host_uid, dagger_uid, db, true, true), 0)
	var replaced_uid := state.attach_equipment(host_uid, sword_uid, db, true, true)
	assert_eq(replaced_uid, dagger_uid)
	assert_true(dagger_uid in state.hand, "the replaced equipment returns to the hand")
	assert_true(sword_uid not in state.hand)
	assert_eq(state.get_card_instance(sword_uid).equipped_slot, "武器")


func test_duplicate_slots_fill_before_interactive_replacement() -> void:
	var state := GameState.new()
	var host_uid := state.add_card_to_hand(2001193, db)
	state.add_card_equip_slot(host_uid, "weapon", db)
	var first_uid := state.add_card_to_hand(2000246, db)
	var second_uid := state.add_card_to_hand(2000252, db)

	assert_eq(state.attach_equipment(host_uid, first_uid, db, true, true), 0)
	assert_eq(state.attach_equipment(host_uid, second_uid, db, true, true), 0)
	assert_eq(state.get_card_instance(host_uid).equipped_uids, [first_uid, second_uid])
	assert_true(first_uid not in state.hand, "an open duplicate slot must be filled instead of replacing its occupant")


func test_interactive_attach_rejects_non_equipment_and_non_hand_host() -> void:
	var state := GameState.new()
	var host_uid := state.add_card_to_hand(2001193, db)
	var status_uid := state.add_card_to_hand(2000098, db)
	assert_eq(state.attach_equipment(host_uid, status_uid, db, true, true), -1)
	assert_true(status_uid in state.hand)

	var equipment_uid := state.add_card_to_hand(2000246, db)
	state.remove_card_from_hand(host_uid)
	state.add_card_to_slot(host_uid, 1, db)
	assert_eq(state.attach_equipment(host_uid, equipment_uid, db, true, true), -1)
	assert_true(equipment_uid in state.hand)


func test_removing_slot_recovers_its_equipment_and_hides_base_slot() -> void:
	var state := GameState.new()
	var host_uid := state.add_card_to_hand(2001193, db)
	var weapon_uid := state.add_card_to_hand(2000246, db)
	state.attach_equipment(host_uid, weapon_uid, db, true, true)

	assert_true(state.remove_card_equip_slot(host_uid, "weapon", db))
	assert_true(weapon_uid in state.hand)
	assert_false("武器" in state.card_equip_slots(host_uid, db))


func test_change_name_queues_uid_bound_input_and_save_restores_all_relations() -> void:
	var state := GameState.new()
	var rite := state.create_rite_instance(990303)
	var host_uid := state.add_card_to_hand(2001193, db)
	state.remove_card_from_hand(host_uid)
	state.add_card_to_slot(host_uid, 1, db, rite.uid)
	var deferred := ResultExec.execute({"change_name": 2001193}, state, db, {"rite_uid": rite.uid})
	DeferredEffects.apply(deferred, state, db, RNG.new(303))

	var operation: Dictionary = state.pending_operation()
	assert_eq(str(operation.kind), "rename_card")
	assert_eq(int(operation.context.card_uid), host_uid)
	state.set_card_custom_name(host_uid, "被命名者")
	var equipment_uid := state.add_card_to_hand(2000246, db)
	state.attach_equipment(host_uid, equipment_uid, db, false, false)

	var saved := SaveSystem.serialize(state)
	var restored := GameState.new()
	SaveSystem.deserialize(saved, restored, db)
	var restored_host = restored.get_card_instance(host_uid)
	assert_eq(str(restored.card_data_for(host_uid, db).name), "被命名者")
	assert_eq(restored_host.equipped_uids, [equipment_uid])
	assert_eq(restored.get_card_instance(equipment_uid).equipped_to_uid, host_uid)
	assert_eq(str(restored.pending_operation().kind), "rename_card")


func test_change_name_preserves_result_operation_order() -> void:
	var state := GameState.new()
	var host_uid := state.add_card_to_hand(2001193, db)
	var deferred := ResultExec.execute({
		"prompt": {"id": "before", "text": "先显示"},
		"change_name": 2001193,
	}, state, db, {"card_uid": host_uid})
	DeferredEffects.apply(deferred, state, db, RNG.new(304))

	assert_eq(str(state.pending_operations[0].kind), "prompt")
	assert_eq(str(state.pending_operations[1].kind), "rename_card")
	assert_eq(int(state.pending_operations[1].context.card_uid), host_uid)


func test_load_repairs_one_sided_equipment_relationships() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(14))
	var orphan_uid := state.add_card_to_hand(2000246, db)
	var orphan = state.get_card_instance(orphan_uid)
	orphan.zone = "equipped"
	orphan.equipped_to_uid = 999999
	state.hand.erase(orphan_uid)
	state.rail_order.erase(orphan_uid)

	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(restored.get_card_instance(orphan_uid).zone, "removed")
	assert_eq(restored.get_card_instance(orphan_uid).equipped_to_uid, 0)


func test_earlier_v5_card_instances_load_with_evolution_defaults() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(15))
	var saved := SaveSystem.serialize(state)
	for card_data in saved.card_instances:
		for field in [
			"rare_up", "custom_name", "custom_text", "equip_slots",
			"removed_equip_slots", "equipped_uids", "equipped_to_uid", "equipped_slot",
		]:
			card_data.erase(field)

	var restored := GameState.new()
	SaveSystem.deserialize(saved, restored, db)
	var card = restored.get_card_instance(int(restored.hand[0]))
	assert_eq(card.rare_up, 0)
	assert_eq(card.custom_name, "")
	assert_true(card.equipped_uids.is_empty())
	assert_eq(int(restored.card_data_for(card.uid, db).rare), int(db.get_card(card.card_id).rare))
