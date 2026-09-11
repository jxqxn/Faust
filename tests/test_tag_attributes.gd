extends GutTest

var db: ConfigDB

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func test_new_prisoner_matches_original_saved_builtin_marker() -> void:
	var state := GameState.new()
	var card = state.create_card_instance(2000346, db)
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"))
	var expected: Dictionary = {}
	for entry in original.cards:
		if int(entry.uid) == 120:
			expected = entry.tag
	assert_eq(int(expected.get("adsorb_spec", 0)), 1)
	assert_eq(int(card.tags.get("adsorb_spec", 0)), int(expected.get("adsorb_spec", 0)))
	assert_false(ConditionEval.can_put_card({}, {"acting_card": state.card_data_for(card.uid, db), "db": db}))

func test_result_tag_removal_and_readdition_update_attribute() -> void:
	var state := GameState.new()
	var card = state.create_card_instance(2000346, db)
	ResultExec._mutate_tag(card.tags, state, card.uid, "囚徒", TagSystem.Op.SUB, 1, false, 1, db)
	assert_false(card.tags.has("adsorb_spec"))
	assert_eq(int(state.effective_card_tags(card.uid, db).get("囚徒", 0)), 0)
	ResultExec._mutate_tag(card.tags, state, card.uid, "囚徒", TagSystem.Op.ADD, 1, false, 0, db)
	assert_eq(int(card.tags.get("adsorb_spec", 0)), 1)
	state.validate_tag_attributes(card.uid, "prisoner", db)
	assert_eq(int(card.tags.adsorb_spec), 1, "Builtin is non-additive")

func test_copy_replays_delta_entries_in_original_order() -> void:
	var state := GameState.new()
	var source = state.create_card_instance(2000346, db)
	# Explicit order boundary: last written marker wins after the negative
	# source tag removes the constructor marker. Bulk assignment loses this.
	source.tags = {"囚徒": -1, "adsorb_spec": 1}
	var copied = state.get_card_instance(state.copy_card_instance(source.uid, db))
	assert_eq(int(copied.tags.get("adsorb_spec", 0)), 1)
	source.tags = {"adsorb_spec": 1, "囚徒": -1}
	copied = state.get_card_instance(state.copy_card_instance(source.uid, db))
	assert_false(copied.tags.has("adsorb_spec"))
	assert_eq(source.tags, {"adsorb_spec": 1, "囚徒": -1})

func test_all_current_attribute_keys_are_covered_without_new_content_tables() -> void:
	var count := 0
	for node in db.tags_by_code.values():
		for key in node.get("attributes", {}):
			assert_eq(str(key), "吸附指定")
			count += 1
	assert_gt(count, 0)
