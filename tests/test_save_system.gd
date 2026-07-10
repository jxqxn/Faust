extends GutTest

## Tests for the save/load system: serialize -> deserialize round-trip must
## preserve all gameplay-relevant GameState fields.

const RNG = preload("res://core/rng.gd")

var db: ConfigDB

func before_all():
	SaveSystem.use_save_path("user://test_save_system_save.json")
	SaveSystem.delete_save()
	db = ConfigDB.new()
	db.load_all()


func after_all():
	SaveSystem.delete_save()
	SaveSystem.use_default_save_path()

func test_save_load_round_trip_preserves_state():
	var rng := RNG.new(42)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	state.add_coin(15)
	state.gold_dice = 1
	state.day = 3
	state.round_number = 2
	state.add_card_to_slot(2000001, 1, db)
	state.table_cards[0].tags["临时标记"] = 7
	state.available_rites.append(5000003)
	state.started_rites.append(5000001)
	state.auto_result_rites.append(5000002)
	state.rite_auto_result = true
	state.queue_event(5310008)
	state.queue_prompt({"id": "prompt.test", "text": "hello"})
	# Serialize.
	var data := SaveSystem.serialize(state)
	assert_true(SaveSystem.is_valid_player_save_data(data), "serialized player saves should be marked as continue-eligible")
	assert_eq(data.get("save_kind", ""), SaveSystem.SAVE_KIND_PLAYER, "save kind should identify player saves")
	# Deserialize into a fresh state.
	var state2 := GameState.new()
	SaveSystem.deserialize(data, state2, db)
	# Verify all fields preserved.
	assert_eq(state2.difficulty_index, 1, "difficulty preserved")
	assert_eq(state2.round_number, 2, "round_number preserved")
	assert_eq(state2.day, 3, "day preserved")
	assert_eq(state2.coin_count, 15, "coin_count preserved")
	assert_eq(state2.gold_dice, 1, "gold_dice preserved")
	assert_eq(state2.hand.size(), state.hand.size(), "hand size preserved")
	assert_eq(state2.sudan_deck.size(), state.sudan_deck.size(), "sudan_deck size preserved")
	assert_eq(state2.active_sudan_cards.size(), 1, "active sudan card preserved")
	assert_eq(state2.table_cards.size(), 1, "table card preserved")
	if state2.table_cards.size() > 0:
		assert_eq(int(state2.table_cards[0].get("id", 0)), 2000001, "table card id preserved")
		assert_eq(int(state2.table_cards[0].get("slot", 0)), 1, "table card slot preserved")
		assert_eq(int(state2.table_cards[0].get("tags", {}).get("临时标记", 0)), 7, "table card tags preserved")
	assert_true(5000001 in state2.started_rites, "started rites preserved")
	assert_true(5000003 in state2.available_rites, "available rites preserved")
	assert_true(5000002 in state2.auto_result_rites, "auto-result rites preserved")
	assert_true(state2.rite_auto_result, "rite_auto_result flag preserved")
	assert_true(5310008 in state2.event_queue, "queued events preserved")
	assert_eq(str(state2.event_prompts[0].get("id", "")), "prompt.test", "queued prompts preserved")
	if state2.active_sudan_cards.size() > 0:
		var asc = state2.active_sudan_cards[0]
		assert_eq(asc.card_id, state.active_sudan_cards[0].card_id, "sudan card_id preserved")
		assert_eq(asc.days_left, state.active_sudan_cards[0].days_left, "sudan days_left preserved")

func test_load_missing_save_returns_null():
	SaveSystem.delete_save()
	var result = SaveSystem.load(db)
	assert_eq(result, null, "no save -> null")


func test_continue_load_rejects_unmarked_legacy_save():
	SaveSystem.delete_save()
	var file := FileAccess.open(SaveSystem.save_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "difficulty_index": 1, "hand": [2000001]}, "\t"))
	file.close()

	assert_false(SaveSystem.has_valid_save(db), "legacy or test data should not count as a player continue save")
	assert_eq(SaveSystem.load_continue(db), null, "continue loading should require a player save marker")


func test_load_rejects_version_mismatch():
	# A save whose schema version doesn't match SAVE_VERSION is rejected,
	# not silently loaded with potentially-wrong state.
	# [SRC: original CorrectPlayerData reconciles configVersion; clone uses
	# a save-schema version gate]
	SaveSystem.delete_save()
	var file := FileAccess.open(SaveSystem.save_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 999, "player_save": true, "save_kind": "player", "difficulty_index": 1}, "\t"))
	file.close()

	assert_eq(SaveSystem.load(db), null, "version-mismatched save is refused")
	assert_eq(SaveSystem.load_continue(db), null, "continue also refuses version mismatch")
