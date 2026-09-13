extends GutTest

const RNG = preload("res://core/rng.gd")

var db: ConfigDB


func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_table_and_total_custom_text_visit_all_source_roots_only() -> void:
	var state := GameState.new()
	var first := state.add_card_to_hand(2000246, db)
	var second := state.add_card_to_hand(2000246, db)
	var slot_uid := state.add_card_to_hand(2000246, db)
	var rite := state.create_rite_instance(990318)
	state.remove_card_from_hand(slot_uid)
	state.add_card_to_slot(slot_uid, 1, db, rite.uid)
	var host := state.add_card_to_hand(2001193, db)
	var equipped := state.add_card_to_hand(2000246, db)
	state.attach_equipment(host, equipped, db, false, false)
	assert_eq(state.get_card_instance(equipped).zone, "equipped")
	var removed = state.create_card_instance(2000246, db, "removed")
	var lost := state.add_card_to_hand(2000246, db)
	state.get_card_instance(lost).tags["遗世"] = 1
	ResultExec.execute({"table.change_card_name.5320291_01.2000246": "无名的游商"}, state, db, {})
	for uid in [first, second]:
		assert_eq(state.get_card_instance(uid).custom_name, "change_card_name_5320291_01")
	for uid in [slot_uid, equipped, removed.uid, lost]:
		assert_eq(state.get_card_instance(uid).custom_name, "", "table excludes slot/equip/removed/lost ID matches")
	ResultExec.execute({"total.change_card_text.5000301_01.2000246": "unused by the stored key"}, state, db, {})
	for uid in [first, second, slot_uid]:
		assert_eq(state.get_card_instance(uid).custom_text, "change_card_text_5000301_01")
	for uid in [equipped, removed.uid, lost]:
		assert_eq(state.get_card_instance(uid).custom_text, "", "total includes roots, not nested equipment or removed objects")
	state.get_card_instance(lost).tags["遗世"] = 0
	ResultExec.execute({"total.change_card_name.5320291_01.2000246": "无名的游商"}, state, db, {})
	assert_eq(state.get_card_instance(lost).custom_name, "change_card_name_5320291_01",
		"zero lost tag does not hide the identity")
	state.get_card_instance(lost).custom_name = ""
	state.get_card_instance(lost).tags = {"lost": 1}
	ResultExec.execute({"total.change_card_name.5320291_01.2000246": "无名的游商"}, state, db, {})
	assert_eq(state.get_card_instance(lost).custom_name, "", "original save tags use the code lost")


func test_prompt_name_uses_player_and_definition_domains_across_save_and_generation() -> void:
	var state := GameState.new()
	# Source ChangeName.Do does not enumerate player cards before showing.
	var deferred := ResultExec.execute({"change_name": 2001193}, state, db, {})
	DeferredEffects.apply(deferred, state, db, RNG.new(310))
	assert_eq(state.pending_operation().payload.card_id, 2001193)
	assert_eq(state.pending_operation().payload.initial_text, db.get_card(2001193).name)
	assert_true(state.set_prompt_name(2001193, " 新名字 "))
	var first := state.add_card_to_hand(2001193, db)
	var second := state.add_card_to_hand(2001193, db)
	assert_eq(state.card_data_for(first, db).name, " 新名字 ")
	assert_eq(state.card_data_for(second, db).name, " 新名字 ")
	assert_eq(state.get_card_instance(first).custom_name, "", "prompt must not mutate the instance field")
	assert_eq(state.prompt_initial_name(2001193, db), " 新名字 ")
	assert_true(state.set_prompt_name(0, " 玩家 "))
	var player := state.add_card_to_hand(2000001, db)
	assert_eq(state.card_data_for(player, db).name, " 玩家 ")
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(restored.player_display_name, " 玩家 ")
	assert_eq(restored.card_data_for(first, db).name, " 新名字 ")
	assert_eq(restored.card_data_for(player, db).name, " 玩家 ")
	var third := restored.add_card_to_hand(2001193, db)
	assert_eq(restored.card_data_for(third, db).name, " 新名字 ")
	assert_eq(restored.pending_operation().payload.card_id, 2001193)
	# Definition override precedes Player.name, as GetName does.
	restored.set_prompt_name(2000001, "特别名")
	assert_eq(restored.card_data_for(player, db).name, "特别名")
	restored.setup_new_run(db, 0, RNG.new(311))
	assert_eq(restored.player_display_name, "")
	assert_true(restored.player_card_names.is_empty())
	var no_cards := GameState.new()
	var player_prompt := ResultExec.execute({"change_name": 0}, no_cards, db, {})
	DeferredEffects.apply(player_prompt, no_cards, db, RNG.new(312))
	assert_eq(no_cards.pending_operation().payload.card_id, 0)
	assert_eq(no_cards.pending_operation().payload.initial_text, db.get_card(2000001).name)


func test_runtime_name_text_and_rarity_are_instance_scoped_and_clamped() -> void:
	var state := GameState.new()
	var first_uid := state.add_card_to_hand(2001193, db)
	var second_uid := state.add_card_to_hand(2001193, db)

	assert_true(state.set_card_custom_name(first_uid, "change_card_name_5000301_01"))
	assert_true(state.set_card_custom_text(first_uid, "永久变化后的描述"))
	assert_true(state.modify_card_rarity(first_uid, 9, db))

	var first: Dictionary = state.card_data_for(first_uid, db)
	var second: Dictionary = state.card_data_for(second_uid, db)
	assert_eq(str(first.name), "镜中的生灵")
	assert_eq(str(first.text), "永久变化后的描述")
	assert_eq(int(first.rare), 4, "runtime rare is clamped to the original 1..4 range")
	assert_eq(int(second.rare), 1, "a same-definition sibling keeps its own rarity")
	assert_ne(str(second.name), "镜中的生灵", "custom copy never mutates the shared definition")


func test_custom_name_stores_source_key_and_falls_back_when_unresolved() -> void:
	var state := GameState.new()
	var uid := state.add_card_to_hand(2001193, db)
	state.set_card_custom_name(uid, "change_card_name_5000301_01")
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(restored.get_card_instance(uid).custom_name, "change_card_name_5000301_01")
	assert_eq(restored.card_data_for(uid, db).name, "镜中的生灵")
	restored.set_card_custom_name(uid, "unknown_custom_key")
	assert_eq(restored.card_data_for(uid, db).name, db.get_card(2001193).name,
		"GetName ignores a translation identical to its input key")
	restored.set_card_custom_name(uid, "")
	assert_eq(restored.get_card_instance(uid).custom_name, "", "raw setter can clear the field")
	assert_eq(db.custom_card_translates.size(), 38, "original40 definitions collapse to10 name and28 description keys")
	assert_eq(ConfigDB.custom_card_text_key("table.change_card_name.5320291_01.2000005"),
		"change_card_name_5320291_01")
	assert_eq(db.translate_custom_card_text("change_card_name_5320291_01"), "无名的游商")
	var trader := restored.add_card_to_hand(2000005, db)
	ResultExec.execute({"table.change_card_name.5320291_01.2000005": "无名的游商"}, restored, db, {})
	assert_eq(restored.get_card_instance(trader).custom_name, "change_card_name_5320291_01")
	assert_eq(restored.card_data_for(trader, db).name, "无名的游商")
	var player := restored.add_card_to_hand(2000001, db)
	restored.set_prompt_name(0, "玩家名")
	restored.set_card_custom_name(player, "unknown_custom_key")
	assert_eq(restored.card_data_for(player, db).name, "玩家名")
	restored.set_card_custom_name(player, "change_card_name_5000301_01")
	assert_eq(restored.card_data_for(player, db).name, "镜中的生灵")
	restored.set_prompt_name(2000001, "配置名")
	assert_eq(restored.card_data_for(player, db).name, "配置名")


func test_result_dsl_changes_the_exact_slotted_runtime_card() -> void:
	var state := GameState.new()
	var rite := state.create_rite_instance(990301)
	var host_uid := state.add_card_to_hand(2001193, db)
	state.remove_card_from_hand(host_uid)
	state.add_card_to_slot(host_uid, 1, db, rite.uid)
	var context := {"rite_uid": rite.uid}

	ResultExec.execute({
		"s1.uprare": 1,
		"change_card_name.5000301_01.s1": "镜中的生灵",
		"change_card_text.5000301_01.s1": "它刚刚步入现实世界，开始拙劣地模仿着人类，或者任何生物的外形……",
		"s1+equip_slot": "animal_handling",
		"s1+equip": 2000156,
	}, state, db, context)

	var host = state.get_card_instance(host_uid)
	var card: Dictionary = state.card_data_for(host_uid, db)
	assert_eq(int(card.rare), 2)
	assert_eq(str(card.name), "镜中的生灵")
	assert_eq(str(card.text), "它刚刚步入现实世界，开始拙劣地模仿着人类，或者任何生物的外形……")
	assert_eq(host.custom_text, "change_card_text_5000301_01")
	assert_true("驯兽" in card.equip_slots, "config code is normalized to the visible slot name")
	assert_eq(host.equipped_uids.size(), 1)
	assert_eq(int(card.tag.get("战斗", 0)), 4, "inheritable equipment stats contribute to the host")
	assert_eq(state.get_card_instance(host.equipped_uids[0]).zone, "equipped")


func test_description_key_roundtrip_and_unknown_key_differ_from_names() -> void:
	var state := GameState.new()
	var uid := state.add_card_to_hand(2001193, db)
	state.set_card_custom_text(uid, "change_card_text_5000301_01")
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(restored.get_card_instance(uid).custom_text, "change_card_text_5000301_01")
	assert_eq(restored.card_data_for(uid, db).text,
		"它刚刚步入现实世界，开始拙劣地模仿着人类，或者任何生物的外形……")
	restored.set_card_custom_text(uid, "missing_description_key")
	assert_eq(restored.card_data_for(uid, db).text, "missing_description_key",
		"Show translates directly and does not use GetName's missing-key fallback")
	restored.set_card_custom_text(uid, " \n ")
	assert_eq(restored.card_data_for(uid, db).text, " \n ", "nonempty literal survives without trim")
	restored.set_card_custom_text(uid, "")
	assert_eq(restored.card_data_for(uid, db).text, db.get_card(2001193).text)


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


func test_replaced_equipment_returns_to_host_page_end_without_reordering_other_page() -> void:
	var state := GameState.new()
	state.current_bag_index = 2
	var host := state.add_card_to_hand(2001193, db)
	var old_weapon := state.add_card_to_hand(2000246, db)
	var new_weapon := state.add_card_to_hand(2000252, db)
	var other_page := state.add_card_to_hand(2000029, db)
	# Fixture grants ownership; adding an NPC/item to Player.cards alone does
	# not make it a hand card (CardExtensions.IsHandCard 0x3827c0).
	for uid in [host, old_weapon, new_weapon]:
		state.get_card_instance(uid).tags["own"] = 1
	state.get_card_instance(host).bag = 2
	state.get_card_instance(host).bag_pos = 1
	state.get_card_instance(new_weapon).bag = 2
	state.get_card_instance(new_weapon).bag_pos = 2
	state.get_card_instance(old_weapon).bag = 0
	state.get_card_instance(old_weapon).bag_pos = 19
	state.get_card_instance(other_page).bag = 0
	state.get_card_instance(other_page).bag_pos = 7
	state.attach_equipment(host, old_weapon, db, true, true)
	assert_eq(state.attach_equipment(host, new_weapon, db, true, true), old_weapon)
	assert_eq(state.get_card_instance(old_weapon).bag, 2, "return to host page, not equipment's stale page")
	assert_eq(state.visible_rail_card_uids(), [host, old_weapon])
	assert_eq(state.get_card_instance(host).bag_pos, 1)
	assert_eq(state.get_card_instance(old_weapon).bag_pos, 2)
	assert_eq(state.visible_rail_card_uids(0), [other_page])
	assert_eq(state.get_card_instance(other_page).bag_pos, 7, "other page is not renumbered")


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


func test_equipment_drop_gate_uses_live_uid_and_respects_modal_and_zone() -> void:
	var state := GameState.new()
	var host_uid := state.add_card_to_hand(2001193, db)
	var weapon_uid := state.add_card_to_hand(2000246, db)
	var screen = load("res://ui/game_screen.gd").new()
	screen._state = state
	screen._db = db
	var payload := {"type": "card", "source": "hand", "card_uid": weapon_uid}
	assert_true(screen._can_drop_equipment(host_uid, payload))
	screen._presentation_blockers["card_detail"] = true
	assert_true(screen._can_drop_equipment(host_uid, payload), "open details accept equipment")
	screen._presentation_blockers["menu"] = true
	assert_false(screen._can_drop_equipment(host_uid, payload), "another modal blocks the underlying equip target")
	screen._presentation_blockers.clear()
	state.get_card_instance(weapon_uid).zone = "equipped"
	assert_false(screen._can_drop_equipment(host_uid, payload), "stale hand payload cannot equip an already attached card")
	state.get_card_instance(weapon_uid).zone = "hand"
	state.get_card_instance(host_uid).zone = "slot"
	assert_false(screen._can_drop_equipment(host_uid, payload), "ritual host is not an interactive hand host")
	screen.free()


func test_slot_equipment_drop_replaces_and_refreshes_origin_with_live_locks() -> void:
	var state := GameState.new()
	var host_uid := state.add_card_to_hand(2001193, db)
	var old_uid := state.add_card_to_hand(2000246, db)
	var new_uid := state.add_card_to_hand(2000252, db)
	state.attach_equipment(host_uid, old_uid, db, true, true)
	var screen := preload("res://ui/game_screen.gd").new()
	screen.size = Vector2(3840, 2160)
	var rng := preload("res://core/rng.gd").new(9324)
	screen.setup(state, db, rng)
	add_child_autofree(screen)
	await wait_process_frames(2)
	# Build the source runtime rite explicitly. add_available_rite performs
	# open-slot adsorption and correctly rejects this isolated fixture because
	# its hand contains only the cards under test.
	var rite_instance := state.create_rite_instance(5000001)
	var view := preload("res://ui/rite_view.gd").new()
	view.setup(state, db, rng, 5000001, rite_instance.uid)
	screen.add_source_overlay(view)
	await wait_process_frames(2)
	view._place_card_in_slot("s4", new_uid, "hand", "")
	view._after_placement_changed()
	screen._presentation_blockers["rite"] = false
	var payload := {"type": "card", "card_uid": new_uid, "source": "slot",
		"source_slot": "s4", "source_rite_uid": view._rite_uid}
	assert_true(screen._can_drop_equipment(host_uid, payload))
	var rite = state.get_rite_instance(view._rite_uid)
	rite.start = true
	assert_false(screen._can_drop_equipment(host_uid, payload))
	assert_eq(state.attach_equipment(host_uid, new_uid, db, true, true), -1,
		"direct interactive state call cannot bypass running slot lock")
	rite.start = false
	view._resolution_pending = true
	screen._on_equipment_dropped(host_uid, new_uid)
	assert_eq(state.get_card_instance(new_uid).zone, "slot")
	assert_true(old_uid in state.get_card_instance(host_uid).equipped_uids)
	view._resolution_pending = false
	screen._on_equipment_dropped(host_uid, new_uid)
	assert_eq(state.get_card_instance(host_uid).equipped_uids, [new_uid])
	assert_eq(state.get_card_instance(new_uid).zone, "equipped")
	assert_eq(state.get_card_instance(new_uid).equipped_to_uid, host_uid)
	assert_true(old_uid in state.hand)
	assert_false(new_uid in state.hand)
	assert_false(view._placed.has("s4"))
	assert_true(state.cards_in_slot(4, view._rite_uid).is_empty())
	assert_eq(screen._card_detail_card_uid, host_uid, "successful equip automatically opens host details")
	assert_not_null(screen._card_info_view)
	screen._on_equipment_dropped(host_uid, new_uid)
	assert_eq(state.get_card_instance(host_uid).equipped_uids, [new_uid], "repeated drop cannot reattach")
	await wait_process_frames(3)


func test_removing_slot_recovers_its_equipment_and_hides_base_slot() -> void:
	var state := GameState.new()
	var host_uid := state.add_card_to_hand(2001193, db)
	var weapon_uid := state.add_card_to_hand(2000246, db)
	state.attach_equipment(host_uid, weapon_uid, db, true, true)

	assert_true(state.remove_card_equip_slot(host_uid, "weapon", db))
	assert_true(weapon_uid in state.hand)
	assert_false("武器" in state.card_equip_slots(host_uid, db))


func test_change_name_queues_config_id_and_save_restores_all_relations() -> void:
	var state := GameState.new()
	var rite := state.create_rite_instance(990303)
	var host_uid := state.add_card_to_hand(2001193, db)
	state.remove_card_from_hand(host_uid)
	state.add_card_to_slot(host_uid, 1, db, rite.uid)
	var deferred := ResultExec.execute({"change_name": 2001193}, state, db, {"rite_uid": rite.uid})
	DeferredEffects.apply(deferred, state, db, RNG.new(303))

	var operation: Dictionary = state.pending_operation()
	assert_eq(str(operation.kind), "rename_card")
	assert_eq(int(operation.payload.card_id), 2001193)
	state.set_prompt_name(2001193, "被命名者")
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
