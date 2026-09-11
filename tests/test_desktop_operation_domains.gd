extends GutTest

var db: ConfigDB
func before_all():
	db = ConfigDB.new()
	db.load_all()

func test_equipment_and_rarity_share_desktop_domain_for_table_and_g():
	for prefix in ["table", "g"]:
		var state := GameState.new()
		var desktop := state.add_card_to_hand(2000001, db)
		var slotted := state.add_card_to_hand(2000001, db)
		var rite := state.create_rite_instance(5000001)
		state.remove_card_from_hand(slotted)
		state.add_card_to_slot(slotted, 1, db, rite.uid)
		var operation := {prefix + ".2000001+equip": 2000156, prefix + ".2000001.uprare": 1, prefix + ".2000001+equip_slot": "animal_handling"}
		ResultExec.execute(operation, state, db, {"card_uid": slotted, "rite_uid": rite.uid})
		assert_eq(state.get_card_instance(desktop).equipped_uids.size(), 1)
		assert_eq(state.get_card_instance(slotted).equipped_uids.size(), 0)
		assert_eq(state.get_card_instance(desktop).rare_up, 1)
		assert_eq(state.get_card_instance(slotted).rare_up, 0)
		assert_true("驯兽" in state.get_card_instance(desktop).equip_slots)
		assert_false("驯兽" in state.get_card_instance(slotted).equip_slots)

func test_total_tag_excludes_equipment_but_includes_rite_cards():
	var state := GameState.new()
	var root := state.add_card_to_hand(2000001, db)
	var slot = state.create_card_instance(2000001, db, "hand")
	var rite := state.create_rite_instance(5000001)
	state.add_card_to_slot(slot.uid, 1, db, rite.uid)
	var equip = state.create_card_instance(2000001, db, "equipped")
	ResultExec.execute({"total.2000001+体魄": 1}, state, db)
	assert_eq(int(state.get_card_instance(root).tags.get("体魄", 0)), 1)
	assert_eq(int(slot.tags.get("体魄", 0)), 1)
	assert_eq(int(equip.tags.get("体魄", 0)), 0)

func test_clean_counts_stack_units_on_desktop_and_ignores_context_slot():
	var state := GameState.new()
	var first := state.add_card_to_hand(2000029, db)
	var second := state.add_card_to_hand(2000029, db)
	state.get_card_instance(first).count = 2
	state.get_card_instance(second).count = 5
	var slot = state.create_card_instance(2000029, db, "slot")
	ResultExec.execute({"table.clean.2000029": 4}, state, db, {"card_uid": slot.uid})
	assert_eq(state.get_card_instance(first).zone, "removed")
	assert_eq(state.get_card_instance(second).count, 3)
	assert_eq(slot.zone, "slot")

func test_shared_uid_allocator_and_legacy_collision_migration_preserve_cards():
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(10), false)
	assert_eq(state.player_actor_uid, 29, "original sample: 28 pool Cards then protagonist UID29")
	var before := state.card_instances.duplicate()
	RoundLoop.draw_weekly_sudan(state, db, GameRNG.new(10))
	for uid in before:
		assert_same(state.get_card_instance(uid), before[uid], "draw must not overwrite an NPC")
	var saved := SaveSystem.serialize(state)
	saved.sudan_deck[0].uid = state.player_actor_uid
	var restored := GameState.new()
	SaveSystem.deserialize(saved, restored, db)
	assert_eq(restored.get_card_instance(state.player_actor_uid).card_id, 2000001)
	for entry in restored.sudan_deck:
		assert_false(restored.card_instances.has(int(entry.uid)))
	assert_false(saved.has("world_spawn_id"))
	assert_false(saved.has("world_position_ratio"))

func test_display_sort_does_not_reorder_source_player_cards():
	var state := GameState.new()
	var first := state.add_card_to_hand(2000001, db)
	var second := state.add_card_to_hand(2000006, db)
	state.insert_card_to_hand(second, 0, db)
	assert_eq(state.source_player_cards().map(func(card): return card.uid), [first, second])
	state.remove_card_from_hand(first)
	state.add_card_to_hand(first, db)
	assert_eq(state.source_player_cards().map(func(card): return card.uid), [second, first])
