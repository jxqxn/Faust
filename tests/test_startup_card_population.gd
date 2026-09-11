extends GutTest

const SOURCE_SAVE := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"
var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()

func fresh() -> GameState:
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(201), false)
	return state

func test_initial_population_preserves_source_order_and_stack_rules():
	var state := fresh()
	var expected: Array = []
	var counts := {}
	for raw_id in db.init_config.default_cards:
		var id := int(raw_id)
		if counts.has(id) and int(db.get_card(id).get("tag", {}).get("可堆叠", 0)) > 0:
			counts[id] += 1
		else:
			expected.append(id)
			counts[id] = 1
	var actual: Array = []
	for uid in state.hand:
		var card = state.get_card_instance(uid)
		actual.append(card.card_id)
		assert_eq(card.count, counts[card.card_id])
	assert_eq(actual, expected)
	assert_eq(state.visible_rail_card_uids(), [state.player_actor_uid], "NPC population is not a visible starting hand")

func test_bookshop_adsorbs_existing_hidden_owner_and_return_stays_hidden():
	var state := fresh()
	var owner := state.card_uid_for(2000199, "hand")
	assert_gt(owner, 0)
	assert_false(owner in state.visible_rail_card_uids())
	var rite_uid := state.add_available_rite(5002006, db, GameRNG.new(4))
	assert_gt(rite_uid, 0)
	assert_eq(state.cards_in_slot(5, rite_uid)[0].card_uid, owner)
	assert_false(owner in state.hand)
	state.return_rite_cards(rite_uid, db)
	assert_true(owner in state.hand)
	assert_false(owner in state.visible_rail_card_uids())
	assert_eq(state.take_hand_card_count(2000199, 1), 0, "restore-last-placement cannot take a hidden NPC")

func test_ownership_tags_drive_all_bags_and_hand_have_without_recreating_card():
	var state := fresh()
	var uid := state.card_uid_for(2000199, "hand")
	var card = state.get_card_instance(uid)
	var ctx := {"state": state, "db": db}
	assert_false(ConditionEval.evaluate({"hand_have.2000199": 1}, ctx))
	for code in ["own", "adherent", "player"]:
		card.tags[code] = 1
		card.bag = 2
		assert_true(state.is_hand_card(uid, db))
		assert_false(uid in state.visible_rail_card_uids(0))
		assert_true(uid in state.visible_rail_card_uids(2))
		assert_true(ConditionEval.evaluate({"hand_have.2000199": 1}, ctx), "hand_have crosses bag pages")
		card.tags[code] = 0
		assert_false(state.is_hand_card(uid, db))
		card.tags.erase(code)
	assert_true(state.get_card_instance(uid) == card)
	assert_false(ConditionEval.evaluate({"hand_have.受伤": 1}, ctx), "hidden injured NPC does not unlock hospital")

func test_table_have_excludes_rite_slots_but_have_includes_them():
	var state := fresh()
	var ctx := {"state": state, "db": db}
	assert_true(ConditionEval.evaluate({"table_have.2000199": 1}, ctx))
	state.add_available_rite(5002006, db)
	assert_false(ConditionEval.evaluate({"table_have.2000199": 1}, ctx))
	assert_true(ConditionEval.evaluate({"have.2000199": 1}, ctx))

func test_owned_equipment_does_not_turn_hidden_npc_into_a_hand_card():
	var state := fresh()
	var owner := state.card_uid_for(2000199, "hand")
	var equipment := state.add_card_to_hand(2000246, db)
	var item = state.get_card_instance(equipment)
	for code in ["own", "adherent", "player"]:
		item.tags[code] = 1
	assert_true(state.is_hand_card(equipment, db))
	state.attach_equipment(owner, equipment, db)
	assert_false(state.is_hand_card(owner, db), "non-inheritable ownership must not leak from gear")
	assert_false(owner in state.visible_rail_card_uids())
	assert_false(ConditionEval.evaluate({"hand_have.2000199": 1}, {"state": state, "db": db}))
	assert_false(state.effective_card_tag_names(owner, db).has("已拥有"))

func test_original_sample_equipment_and_hand_membership_are_preserved():
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_SAVE))
	var state := fresh()
	var imported: GameState = OriginalSaveImporter.import_save(source, db).state
	var compared_equipment_hosts := 0
	var expected_visible: Array = []
	for raw in source.cards:
		var definition: Dictionary = db.get_card(int(raw.id))
		var eligible := false
		for code in ["own", "adherent", "player"]:
			var value := int(definition.get("tag", {}).get(db.tag_code_to_name[code], 0)) + int(raw.tag.get(code, 0))
			eligible = eligible or value * int(raw.count) > 0
		# The existing host renders active Sultan cards alongside ordinary
		# hand cards; keep that separate path while checking NPC eligibility.
		if (eligible or str(definition.get("type", "")) == "sudan") and int(raw.bag) == int(source.get("BagIndex", 0)):
			expected_visible.append(int(raw.uid))
		if db.init_config.card_equips.has(str(int(raw.id))):
			compared_equipment_hosts += 1
			var uid := state.card_uid_for(int(raw.id), "hand")
			var equips: Array = []
			for equip_uid in state.get_card_instance(uid).equipped_uids:
				equips.append(state.get_card_instance(equip_uid).card_id)
			assert_eq(equips, raw.equips.map(func(e): return int(e.id)), "initial gear compared to actual original save")
	assert_eq(compared_equipment_hosts, 3, "the sample retains these three initial hosts outside rites")
	var sultan = state.get_card_instance(state.card_uid_for(2000024, "hand"))
	assert_eq(sultan.equipped_uids.size(), 1)
	assert_eq(state.get_card_instance(sultan.equipped_uids[0]).card_id, 2000529)
	var actual: Array = imported.visible_rail_card_uids()
	actual.sort()
	expected_visible.sort()
	assert_eq(actual, expected_visible, "original save is the independent visibility judge")
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(imported), restored, db)
	assert_eq(restored.visible_rail_card_uids(), imported.visible_rail_card_uids())

func test_position_compaction_leaves_hidden_cards_and_other_pages_untouched():
	var state := fresh()
	var hidden = state.get_card_instance(state.card_uid_for(2000199, "hand"))
	hidden.bag_pos = 73
	var actor = state.get_card_instance(state.player_actor_uid)
	actor.bag = 2
	state.current_bag_index = 2
	RoundLoop.update_hand_card_pos(state)
	assert_eq(actor.bag_pos, 1)
	assert_eq(hidden.bag_pos, 73)

func test_rendered_rail_uses_original_sample_visibility_instead_of_player_population():
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_SAVE))
	var state: GameState = OriginalSaveImporter.import_save(source, db).state
	var screen := preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, GameRNG.new(9))
	add_child_autofree(screen)
	await wait_process_frames(2)
	var displayed: Array = screen._ordered_hand_cards().map(func(card): return card.card_uid)
	assert_eq(displayed, state.visible_rail_card_uids())
	assert_eq(displayed.size(), 5, "four ordinary cards plus the active Sultan card")
