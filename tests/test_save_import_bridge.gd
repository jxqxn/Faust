extends GutTest

## Phase-2 import bridge: original Player save -> clone GameState via the
## normal v7 deserialize path, plus the same-instant diff. The corpus sample
## (save_samples/auto_save.json) is the judge; the synthetic fixture covers
## shapes the round-1 sample happens not to carry (started rite, gold cards,
## non-default min_round).
## [SRC: docs/ORIGINAL_SAVE_SCHEMA.md; sim/original_save_importer.gd SRC notes]

const RNG = preload("res://core/rng.gd")
const CORPUS_AUTO_SAVE := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"


func _local_db() -> ConfigDB:
	var local_db := ConfigDB.new()
	local_db.load_all()
	return local_db


func _card(uid: int, id: int, bagpos := 0, equips: Array = [], tag: Dictionary = {}) -> Dictionary:
	return {
		"uid": uid, "id": id, "count": 1, "life": 0, "rareup": 0, "tag": tag,
		"equip_slots": ["weapon", "cloth", "accessory"], "equips": equips,
		"bag": 0, "bagpos": bagpos, "custom_name": "", "custom_text": "",
	}


func _synthetic_original() -> Dictionary:
	return {
		"configId": 1, "configVersion": 20260306160333, "name": "阿尔图",
		"difficulty": 2, "round": 3, "min_round": 3,
		"saveTime": "2026-06-26T15:37:37+08:00",
		"card_uid_index": 208, "rite_uid_index": 9,
		"sudan_box_show": true, "story_unshow": true, "prestige_unshow": false,
		"deadline_unshow": true, "helpbtn_unshow": false,
		"sudan_card_init_life": 4, "sudan_redraw_count": 1,
		"sudan_redraw_times_per_round": 3, "sudan_redraw_times": 1,
		"sudan_redraw_times_recovery_round": 5,
		"wizard_first_show": true, "success": false, "over_reason": -2147483648,
		"ithink_card": null,
		"cards": [
			_card(29, 2000001, 1),
			_card(30, 2000005, 2),
			_card(31, 2000024, 0, [_card(195, 2000529)]),
			_card(199, 2000029, 1),
			_card(200, 2000029, 1),
			_card(11, 2010006, 3, [], {"sudan_pool_index": 11}),
		],
		"rites": [
			{
				"uid": 7, "id": 5001001, "new_born": true, "is_show": false,
				"start": true, "start_round": 2, "start_life": 4, "life": 1,
				"cards": [null, _card(41, 2000010), null, null, null, null, null],
				"custom_name": "",
			},
		],
		"pins": [5010009, 5010009, 5010012], "sudan_pool_cards": [2010001, 2010002],
		"sudan_pool": "", "sudan_card_pool": [], "sudan_pool_pos": [0, 0],
		"sudan_pool_init_count": 2, "sudan_card_show_times": {}, "sudan_remove_count": 0,
		"counter": {"7100006": 2, "7000060": 5}, "global_counter_cacher": {},
		"random_cache": {}, "only_cards": [2000001], "only_rites": [5001001],
		"event_status": {"5310000": true, "5310001": false},
		"delay_ops": [], "end_rites": {"6": 3},
		"gen_cards": {"2000001": 3, "2000029": 2}, "gen_tags": {"physique": 3, "money": 2},
		"timing_rounds": {"531000000": 6}, "auto_result_rites": [],
		"notes": [[{"type": 1, "id": 5001001, "uid": 7, "count": 0}]],
		"once_new_rites_is_show": {"5001001": false, "5001002": true}, "cached_event": [5310000], "BagIndex": 0,
		"last_round_rite_data": {"5001001": {"s2": {"id": 2000010, "count": 1}}}, "rite_auto_result": false,
		"disable_auto_gen_sudan_card": false, "custom_rite_name": {"5001001": "旧仪式名"},
		"player_card_name": {"2000005": "旧卡名"}, "end_open": false, "is_armageddon": false,
		"armageddon_rite_id": 0,
	}


func test_synthetic_import_maps_core_state() -> void:
	var local_db := _local_db()
	var imported: Dictionary = OriginalSaveImporter.import_save(_synthetic_original(), local_db)
	var state = imported["state"]
	assert_eq(state.round_number, 3, "round imports verbatim")
	assert_eq(state.min_round, 3, "min_round imports from player+0x30")
	assert_eq(state.difficulty_index, 1, "original difficulty is 1-based (2 -> normal)")
	assert_eq(state.next_card_uid, 208, "card uid index imports")
	assert_eq(state.next_rite_uid, 9, "rite uid index imports")
	assert_eq(state.sudan_card_init_life, 4, "Player-owned Sultan birth head start imports")
	assert_eq(state.sudan_redraw_times_per_round, 3, "per-round redraw allowance imports")
	assert_eq(state.sudan_redraw_times, 1, "ordinary redraw usage imports")
	assert_eq(state.sudan_redraw_times_recovery_round, 5, "Init-owned recovery period imports")
	assert_eq(state.redraws_left, 2, "UI remainder derives from allowance minus used redraws")
	assert_false(state.success, "terminal success flag imports")
	assert_eq(state.over_reason, -2147483648, "unended runs keep the original int.MinValue reason")
	assert_true(state.sudan_box_show, "Sudan box visibility preference imports")
	assert_true(state.story_unshow, "story hidden preference imports")
	assert_false(state.prestige_unshow, "prestige hidden preference imports")
	assert_true(state.deadline_unshow, "deadline hidden preference imports")
	assert_false(state.helpbtn_unshow, "help-button hidden preference imports")
	assert_eq(state.gold_total(), 2, "stacked gold card objects sum through 7000105")
	assert_eq(state.get_counter(7100006), 2, "counters import verbatim")
	assert_true(bool(state.event_status.get(5310000, false)), "event status imports")
	assert_eq(int(state.timing_rounds.get(5310000 * 100, -1)), 6,
		"timing arms import under the original int key (eventId*100)")
	assert_eq(int(state.player_actor_uid), 29, "the protagonist instance becomes the actor")
	# Hand order: bagpos>=1 by position first, bag storage (bagpos=0) after.
	assert_eq(state.hand, [29, 199, 200, 30, 31],
		"hand = bagpos>=1 by bagpos (ties by uid), then bagpos=0 by uid; sudan excluded")
	var sudan_instance = state.get_card_instance(11)
	assert_not_null(sudan_instance)
	assert_eq(sudan_instance.zone, "sudan", "drawn sudan cards live in the sudan zone")
	assert_eq(state.active_sudan_cards.size(), 1)
	assert_eq(state.active_sudan_cards[0].card_id, 2010006)
	# Rite: slot cards[i] -> s{i+1}; the started flag survives.
	assert_eq(state.rite_instances.size(), 1, "no phantom legacy instances appear")
	var rite = state.get_rite_instance(7)
	assert_eq(rite.id, 5001001)
	assert_true(rite.start)
	assert_eq(rite.start_round, 2)
	assert_eq(int(rite.slot_cards.get("s2", 0)), 41, "array index 1 maps to s2")
	var slotted = state.get_card_instance(41)
	assert_eq(slotted.zone, "slot")
	assert_eq(slotted.rite_uid, 7)
	assert_eq(slotted.slot_key, "s2")
	# Equipment: nested equips flatten with backlinks.
	var host = state.get_card_instance(31)
	var equip = state.get_card_instance(195)
	assert_eq(host.equipped_uids, [195])
	assert_eq(equip.zone, "equipped")
	assert_eq(int(equip.equipped_to_uid), 31)
	assert_eq(int(state.ended_rites.get(6, 0)), 3, "ended rites import")
	assert_eq(state.last_round_rite_data, {5001001: {"s2": {"id": 2000010, "count": 1}}},
		"rite-panel last placement imports as a separate state from rollback snapshots")
	assert_eq(state.custom_rite_names, {5001001: "旧仪式名"})
	assert_eq(state.player_card_names, {2000005: "旧卡名"})
	assert_eq(state.only_cards, {2000001: true}, "unique-card registration imports as a set")
	assert_eq(state.only_rites, {5001001: true}, "successful rite registrations import as a set")
	assert_eq(state.gen_cards, {2000001: 3, 2000029: 2}, "card generation history imports verbatim")
	assert_eq(state.gen_tags, {"physique": 3, "money": 2}, "tag generation codes import verbatim")
	assert_eq(state.cached_event, [5310000], "cached event notices import in source order")
	assert_eq(state.rite_pins, [5010009, 5010012], "Player.pins imports as an ordered de-duplicated config-id list")
	assert_eq(state.once_new_rites_is_show, {5001001: false, 5001002: true},
		"new-rite first-seen flags import with integer ids")
	assert_eq(state.rite_display_name(5001001, local_db), "旧仪式名", "rite names resolve from the player map")
	assert_eq(str(state.card_data_for(30, local_db).get("name", "")), "旧卡名",
		"player card-name map overrides the per-card/config name")


func test_synthetic_diff_is_clean() -> void:
	var imported: Dictionary = OriginalSaveImporter.import_save(_synthetic_original(), _local_db())
	var failures: Array = []
	for row in imported["report"]["diff"]:
		if not bool(row["pass"]):
			failures.append(row["check"])
	assert_eq(failures, [], "every same-instant check passes for the synthetic fixture")


func test_report_flags_approximations_and_value_drops() -> void:
	var imported: Dictionary = OriginalSaveImporter.import_save(_synthetic_original(), _local_db())
	var report: Dictionary = imported["report"]
	var approximated_texts: Array = []
	for entry in report["approximated"]:
		approximated_texts.append(str(entry))
	assert_true(approximated_texts.any(func(t): return t.contains("active_sudan")),
		"the sudan deadline approximation is reported, never silent")
	var dropped_with_value: Array = []
	for entry in report["dropped"]:
		if bool(entry["has_value"]):
			dropped_with_value.append(str(entry["field"]))
	assert_false("notes" in dropped_with_value, "the notes journal is carried, not dropped")
	assert_false("only_cards" in dropped_with_value, "unique-card registration is converted, not dropped")
	assert_false("only_rites" in dropped_with_value, "unique-rite registration is converted, not dropped")
	assert_false("gen_cards" in dropped_with_value, "card generation history is mapped, not dropped")
	assert_false("gen_tags" in dropped_with_value, "tag generation history is mapped, not dropped")
	assert_false("pins" in dropped_with_value, "completed rite pins are carried, not dropped")
	assert_has(dropped_with_value, "name")


func test_min_round_import_gates_the_rollback() -> void:
	var local_db := _local_db()
	var imported: Dictionary = OriginalSaveImporter.import_save(_synthetic_original(), local_db)
	var state = imported["state"]
	state.round_snapshots["round_end"][2] = SaveSystem.serialize(state)
	assert_false(RoundLoop.back_to_prev_round_end(state, local_db),
		"round-1 below the imported min_round is rejected before any spend")


func test_old_string_timing_keys_migrate_on_load() -> void:
	var local_db := _local_db()
	var imported: Dictionary = OriginalSaveImporter.import_save(_synthetic_original(), local_db)
	var data: Dictionary = SaveSystem.serialize(imported["state"])
	data["timing_rounds"] = {"round_begin_ba:5310000": 9}
	var restored := GameState.new()
	SaveSystem.deserialize(data, restored, local_db)
	assert_eq(int(restored.timing_rounds.get(5310000 * 100, -1)), 9,
		"clone string timing keys migrate to the original int form")


func test_corpus_auto_save_imports_and_diffs_clean() -> void:
	if not FileAccess.file_exists(CORPUS_AUTO_SAVE):
		pending("corpus save sample not available; skipping")
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CORPUS_AUTO_SAVE))
	if not (parsed is Dictionary):
		pending("corpus save sample unreadable; skipping")
		return
	var local_db := _local_db()
	var imported: Dictionary = OriginalSaveImporter.import_save(parsed, local_db)
	var state = imported["state"]
	assert_eq(state.round_number, 1)
	assert_eq(state.difficulty_index, 0, "sample difficulty=1 is easy (counter 7100006=3, backToPrev=9999)")
	assert_eq(int(state.next_card_uid), 219)
	assert_eq(int(state.player_actor_uid), 29)
	assert_eq(state.hand.size(), 181, "all bag=0 non-sudan cards import into the hand")
	assert_eq(state.card_instances.size(), 191,
		"every card object imports: 182 top-level + 3 equips + 5 rite cards + 1 rite equip")
	assert_eq(state.gold_total(), 0, "the round-1 sample carries no gold cards yet")
	assert_eq(state.get_counter(7100006), 3, "gold dice counter imports verbatim")
	assert_eq(state.active_sudan_cards.size(), 1)
	var failures: Array = []
	for row in imported["report"]["diff"]:
		if not bool(row["pass"]):
			failures.append(row["check"])
	assert_eq(failures, [], "the corpus auto_save passes every same-instant check")
