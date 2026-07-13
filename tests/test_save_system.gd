extends GutTest

## Tests for the save/load system: serialize -> deserialize round-trip must
## preserve all gameplay-relevant GameState fields.

const RNG = preload("res://core/rng.gd")

var db: ConfigDB

func before_all():
	SaveSystem.use_save_path("user://test_save_system_save.json")
	SaveSystem.use_user_archive_root("user://test_save_system_archives")
	SaveSystem.delete_save()
	SaveSystem.delete_all_user_archives()
	db = ConfigDB.new()
	db.load_all()


func after_all():
	SaveSystem.delete_save()
	SaveSystem.delete_all_user_archives()
	SaveSystem.use_default_save_path()
	SaveSystem.use_default_user_archive_root()

func test_save_load_round_trip_preserves_state():
	var rng := RNG.new(42)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	state.sudan_pool_tags[2010001] = {"存档牌池标签": 2}
	state.auto_gen_sudan_card = false
	state.add_coin(15)
	state.gold_dice = 1
	state.day = 3
	state.round_number = 2
	state.add_card_to_slot(2000001, 1, db)
	var global_slot_uid := int(state.cards_in_slot(1)[0].get("card_uid", 0))
	state.get_card_instance(global_slot_uid).tags["临时标记"] = 7
	state.available_rites.append(5000003)
	state.started_rites.append(5000001)
	state.auto_result_rites.append(5000002)
	state.rite_auto_result = true
	var first_instance = state.find_rite_instance_by_id(5000001)
	var second_instance = state.create_rite_instance(5000003)
	state.start_rite_instance(first_instance.uid)
	second_instance.life = 2
	state.add_card_to_slot(2000006, 1, db, second_instance.uid)
	state.queue_event(5310008, {"rite": 5000001, "card_uid": int(state.hand[0])})
	state.queue_prompt({"id": "prompt.test", "text": "hello"})
	state.enable_event(5310008, db)
	state.disable_event(5300601)
	state.event_done[5310008] = true
	state.set_counter(7000001, 12)
	state.set_global_counter(8000001, 34)
	# Exercise the real JSON boundary; JSON object keys are strings on load.
	assert_true(SaveSystem.save(state), "state should be written to the test save path")
	var data = SaveSystem.read_save_data()
	assert_true(SaveSystem.is_valid_player_save_data(data), "serialized player saves should be marked as continue-eligible")
	assert_eq(data.get("save_kind", ""), SaveSystem.SAVE_KIND_PLAYER, "save kind should identify player saves")
	var state2 = SaveSystem.load(db)
	assert_not_null(state2, "v5 disk save should load")
	if state2 == null:
		return
	# Verify all fields preserved.
	assert_eq(state2.difficulty_index, 1, "difficulty preserved")
	assert_eq(state2.round_number, 2, "round_number preserved")
	assert_eq(state2.day, 3, "day preserved")
	assert_eq(state2.coin_count, 15, "coin_count preserved")
	assert_eq(state2.gold_dice, 1, "gold_dice preserved")
	assert_eq(state2.hand.size(), state.hand.size(), "hand size preserved")
	assert_eq(state2.sudan_deck.size(), state.sudan_deck.size(), "sudan_deck size preserved")
	assert_eq(state2.sudan_pool_tags, state.sudan_pool_tags, "Sultan pool runtime tags preserved")
	assert_eq(state2.auto_gen_sudan_card, state.auto_gen_sudan_card, "Sultan auto-generation flag preserved")
	assert_eq(state2.active_sudan_cards.size(), 1, "active sudan card preserved")
	assert_eq(state2.table_cards.size(), 2, "global and instance-owned table cards preserved")
	if state2.table_cards.size() > 0:
		assert_eq(int(state2.table_cards[0].get("id", 0)), 2000001, "table card id preserved")
		assert_eq(int(state2.table_cards[0].get("slot", 0)), 1, "table card slot preserved")
		assert_eq(int(state2.table_cards[0].get("tags", {}).get("临时标记", 0)), 7, "table card tags preserved")
	assert_true(5000001 in state2.started_rites, "started rites preserved")
	assert_true(5000003 in state2.available_rites, "available rites preserved")
	assert_true(5000002 in state2.auto_result_rites, "auto-result rites preserved")
	assert_true(state2.rite_auto_result, "rite_auto_result flag preserved")
	var loaded_first = state2.get_rite_instance(first_instance.uid)
	var loaded_second = state2.get_rite_instance(second_instance.uid)
	assert_not_null(loaded_first, "first rite instance uid preserved")
	assert_not_null(loaded_second, "second rite instance uid preserved")
	if loaded_first != null:
		assert_true(loaded_first.start, "rite start state preserved per instance")
	if loaded_second != null:
		assert_eq(loaded_second.life, 2, "rite life preserved per instance")
		assert_eq(state2.cards_in_slot(1, loaded_second.uid).size(), 1, "slotted card remains owned by its rite instance")
	assert_true(5310008 in state2.event_queue, "queued events preserved")
	assert_eq(int(state2.event_contexts[5310008].get("rite", 0)), 5000001, "queued event context preserves rite instance binding")
	assert_eq(int(state2.event_contexts[5310008].get("card_uid", 0)), int(state.hand[0]), "queued event context preserves card instance uid")
	assert_eq(state2.get_counter(7000001), 12, "local counter integer keys survive JSON")
	assert_eq(state2.get_global_counter(8000001), 34, "global counter integer keys survive JSON")
	assert_eq(str(state2.event_prompts[0].get("id", "")), "prompt.test", "queued prompts preserved")
	assert_true(state2.is_event_enabled(5310008), "enabled event status preserved")
	assert_false(state2.is_event_enabled(5300601), "disabled event status preserved")
	assert_true(state2.event_done.has(5310008), "completed event history preserved")
	assert_not_null(state2.event_runtime, "event runtime rebuilt after loading")
	assert_true(5310008 in state2.trigger_events("round_begin_ba", {"round": 1}), "loaded active event remains registered")
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


func test_v4_save_is_rejected_after_card_instance_schema_upgrade():
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(52))
	var old_save := SaveSystem.serialize(state)
	old_save["version"] = 4
	old_save.erase("card_instances")
	old_save.erase("next_card_uid")
	SaveSystem.delete_save()
	var file := FileAccess.open(SaveSystem.save_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(old_save))
	file.close()

	assert_eq(SaveSystem.load_continue(db), null, "v4 lacks CardInstance identity and must not be loaded")
	assert_false(SaveSystem.has_valid_save(db), "v4 save must not expose the continue-game entry")
	SaveSystem.delete_save()


func test_v5_save_without_sudan_pool_fields_uses_compatible_defaults():
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(53))
	var old_v5 := SaveSystem.serialize(state)
	old_v5.erase("sudan_pool_tags")
	old_v5.erase("auto_gen_sudan_card")
	var loaded := GameState.new()
	SaveSystem.deserialize(old_v5, loaded, db)
	assert_eq(loaded.sudan_pool_tags, {}, "old v5 saves default to no Sultan pool tag state")
	assert_true(loaded.auto_gen_sudan_card, "old v5 saves keep Sultan auto-generation enabled")


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


func test_user_archives_are_named_selectable_and_deleted_with_payload():
	SaveSystem.delete_all_user_archives()
	var first := GameState.new()
	first.setup_new_run(db, 0, RNG.new(81))
	first.day = 4
	first.round_number = 2
	assert_true(SaveSystem.save_user_archive(first, 0, "Estate before search"), "first archive should save")

	var second := GameState.new()
	second.setup_new_run(db, 1, RNG.new(82))
	second.day = 7
	second.round_number = 3
	assert_true(SaveSystem.save_user_archive(second, 1, "Book shop"), "second archive should save")
	assert_eq(SaveSystem.next_user_archive_index(), 2, "new archive uses the first free slot")

	var archives := SaveSystem.list_user_archives(db)
	assert_eq(archives.size(), 2, "two valid archive entries are listed")
	assert_eq(str(archives[0].get("name", "")), "Estate before search", "archive keeps its player name")
	assert_eq(int(archives[1].get("day", 0)), 7, "archive summary reads the saved day")

	var loaded = SaveSystem.load_user_archive(db, 1)
	assert_not_null(loaded, "selected archive should load")
	if loaded != null:
		assert_eq(loaded.day, 7, "selected archive restores its own state")
		var continued = SaveSystem.load_continue(db)
		assert_not_null(continued, "loading an archive refreshes the current continue save")
		if continued != null:
			assert_eq(continued.day, 7, "continue now follows the loaded archive")

	var payload_path := SaveSystem.user_archive_save_path(0)
	assert_true(FileAccess.file_exists(payload_path), "archive payload exists before deletion")
	assert_true(SaveSystem.delete_user_archive(0), "archive deletion should succeed")
	assert_false(FileAccess.file_exists(payload_path), "deletion removes the archive payload")
	assert_eq(SaveSystem.list_user_archives(db).size(), 1, "deleted archive is no longer selectable")
