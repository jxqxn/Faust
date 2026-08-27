extends GutTest

## Batch B: the back-to-prev quota moves onto the cross-run global domain
## (original Global, global.json) as COUNTER_BACK_TO_PREV 7100007, with the
## original new-game reset, difficulty rebalance formula, consume-first
## rollback, and archive-restore semantics.
## [SRC: PlayerExtensions.c GetCounter 0x38ce70 / SetCounter 0x38f2d0
##       7100007-to-Global routing; GameController.c OnPrevRound 0x554f80 /
##       PrevRoundInternal 0x555570; Datapool.c StartGame L4497 quota reset,
##       CorrectPlayerData L4130-4134 archive restore; dump.cs:542530/:542532;
##       save_samples/global.json backToPrevRound=9999]

const RNG = preload("res://core/rng.gd")
const CORPUS_GLOBAL := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/global.json"


func before_each() -> void:
	GlobalState.use_default_global_path()
	GlobalState.reset_default_cache()


func after_each() -> void:
	GlobalState.use_default_global_path()
	GlobalState.reset_default_cache()


func _local_db() -> ConfigDB:
	var local_db := ConfigDB.new()
	local_db.load_all()
	return local_db


func test_new_run_quota_matches_difficulty_allowance() -> void:
	var local_db := _local_db()
	var easy := GameState.new()
	easy.setup_new_run(local_db, 0, RNG.new(11))
	assert_eq(easy.back_to_prev_left, 9999, "easy keeps the unlimited baseline")
	var normal := GameState.new()
	normal.setup_new_run(local_db, 1, RNG.new(12))
	assert_eq(normal.back_to_prev_left,
		int(normal.difficulty_config.get("back_to_prev_round_count", 0)),
		"the unlimited baseline minus 9999 plus the allowance equals the allowance")
	var hard := GameState.new()
	hard.setup_new_run(local_db, 2, RNG.new(13))
	assert_eq(hard.back_to_prev_left, 0, "hard starts with no rewinds")


func test_quota_reads_and_writes_route_to_the_global_domain() -> void:
	var state := GameState.new()
	state.back_to_prev_left = 4
	assert_eq(state.get_counter(state.COUNTER_BACK_TO_PREV), 4,
		"the counter id reads the global object")
	assert_false(state.local_counters.has(state.COUNTER_BACK_TO_PREV),
		"the run's counter dict never holds the quota")
	state.add_counter(state.COUNTER_BACK_TO_PREV, 2)
	assert_eq(state.global_state.back_to_prev_round, 6, "AddCounter routes through the global object")
	state.sub_counter(state.COUNTER_BACK_TO_PREV, 99)
	assert_eq(state.global_state.back_to_prev_round, 0,
		"SetCounter's dedicated branch clamps the quota at zero")


func test_run_payload_no_longer_carries_the_quota() -> void:
	var state := GameState.new()
	state.setup_new_run(_local_db(), 1, RNG.new(21))
	state.back_to_prev_left = 7
	var data: Dictionary = SaveSystem.serialize(state)
	assert_false(data.has("back_to_prev_left"),
		"v7 run payloads leave the quota to the global domain")


func test_v6_payload_seeds_the_global_domain() -> void:
	var state := GameState.new()
	state.setup_new_run(_local_db(), 1, RNG.new(22))
	var data: Dictionary = SaveSystem.serialize(state)
	data["version"] = 6
	data["back_to_prev_left"] = 7
	var restored := GameState.new()
	SaveSystem.deserialize(data, restored, _local_db())
	assert_eq(restored.global_state.back_to_prev_round, 7,
		"the recorded quota migrates onto the attached global object")


func test_unlimited_quota_never_decrements() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(31))
	RoundLoop.advance_day(state, local_db, RNG.new(32))
	assert_true(RoundLoop.back_to_prev_round_end(state, local_db))
	assert_eq(state.back_to_prev_left, 9999, "9999 marks unlimited and never spends")
	assert_eq(state.global_state.round_rollback, GlobalState.ROLLBACK_TO_PREV_END,
		"the restore marks the global rollback kind")


func test_finite_quota_spends_before_the_restore() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.setup_new_run(local_db, 1, RNG.new(33))
	state.back_to_prev_left = 2
	var round_before := state.round_number
	RoundLoop.advance_day(state, local_db, RNG.new(34))
	assert_true(RoundLoop.back_to_prev_round_end(state, local_db))
	assert_eq(state.back_to_prev_left, 1,
		"the spend lives on the global object, so the snapshot restore cannot refund it")
	assert_eq(state.round_number, round_before, "the round itself is restored")


func test_begin_round_marks_the_rollback_kind() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.setup_new_run(local_db, 1, RNG.new(35))
	RoundLoop.advance_day(state, local_db, RNG.new(36))
	assert_eq(state.global_state.round_rollback, GlobalState.ROLLBACK_TO_BEGIN,
		"a normal day transition marks BACK_TO_BEGIN")


func test_difficulty_rebalance_formula() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(41))
	state.apply_difficulty(1, local_db)
	assert_eq(state.back_to_prev_left, 10,
		"leaving the free-rollback difficulty resets to the new allowance")
	state.apply_difficulty(0, local_db)
	assert_eq(state.back_to_prev_left, 10,
		"switching to the unlimited difficulty keeps the finite remainder (old-9999+9999)")
	state.apply_difficulty(2, local_db)
	assert_eq(state.back_to_prev_left, 0,
		"a finite-to-finite switch drains to zero through the clamp")


func test_difficulty_switch_adds_gold_dice() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.setup_new_run(local_db, 1, RNG.new(42))
	var before: int = state.gold_dice
	state.apply_difficulty(2, local_db)
	assert_eq(state.gold_dice, before + int(state.difficulty_config.get("gold_dice_count", 0)),
		"SetDifficulty adds the new difficulty's gold dice to what the player holds")


func test_menu_new_run_defers_resources_until_the_narrator_pick() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.setup_new_run(local_db, 0, RNG.new(43), false)
	assert_eq(state.back_to_prev_left, 9999, "StartGame resets the baseline quota")
	assert_eq(state.gold_dice, 0, "no gold dice exist before the pick")
	state.apply_difficulty(1, local_db)
	assert_eq(state.gold_dice, int(state.difficulty_config.get("gold_dice_count", 0)),
		"the narrator pick is the first and only grant")


func test_global_state_disk_round_trip() -> void:
	GlobalState.use_global_path("user://test_global_domain.json")
	var gs := GlobalState.load_default()
	gs.back_to_prev_round = 6
	gs.round_rollback = GlobalState.ROLLBACK_TO_PREV_END
	assert_true(gs.save())
	GlobalState.reset_default_cache()
	var reloaded := GlobalState.load_default()
	assert_eq(reloaded.back_to_prev_round, 6, "the quota persists across process restarts")
	assert_eq(reloaded.round_rollback, GlobalState.ROLLBACK_TO_PREV_END)
	assert_ne(reloaded, gs, "reset_default_cache forces a fresh disk read")
	DirAccess.remove_absolute("user://test_global_domain.json")


func test_original_global_gallery_fields_load_without_translation() -> void:
	if not FileAccess.file_exists(CORPUS_GLOBAL):
		pending("corpus global sample not available; skipping")
		return
	var original := JSON.parse_string(FileAccess.get_file_as_string(CORPUS_GLOBAL)) as Dictionary
	var global := GlobalState.load_from(CORPUS_GLOBAL)
	assert_eq(global.back_to_prev_round, int(original["backToPrevRound"]))
	assert_eq(global.round_rollback, int(original["roundRollback"]))
	assert_eq(global.over_records, original["overRecord"], "overRecord stays as source-shaped data")
	assert_eq(GlobalState._serialize_int_set(global.over_ids), original["overID"])
	assert_eq(GlobalState._serialize_int_set(global.showed_gallery_cards), original["showedGalleryCards"])


func test_gallery_global_hash_sets_deduplicate_and_keep_source_keys() -> void:
	var global := GlobalState.new()
	global.over_records = [{"id": 7, "char_cards": [], "after_storys": []}]
	global.over_ids = GlobalState._restore_int_set([7, 7, 9])
	global.mark_gallery_card_shown(101)
	global.mark_gallery_card_shown(101)
	var saved := global.to_dict()
	assert_eq(saved["overRecord"], global.over_records)
	assert_eq(saved["overID"], [7, 9], "Global.overID is a HashSet<int>")
	assert_eq(saved["showedGalleryCards"], [101], "gallery unlock ids are a HashSet<int>")
	assert_true(global.has_shown_gallery_card(101))
	assert_true(global.has_over_id(7), "GalleryCGIconController reads Global.overID membership")
	assert_false(global.has_over_id(101), "showedGalleryCards must not unlock GalleryCG icons")


func test_detached_global_state_does_not_touch_disk() -> void:
	var detached := GlobalState.new()
	detached.back_to_prev_round = 3
	assert_false(detached.save(), "bare instances (tests) have no disk binding")


func test_archive_restore_wins_over_the_live_quota() -> void:
	var local_db := _local_db()
	SaveSystem.use_save_path("user://test_global_domain_continue.json")
	SaveSystem.use_user_archive_root("user://test_global_domain_archives")
	GlobalState.use_global_path("user://test_global_domain.json")
	GlobalState.reset_default_cache()
	var state := GameState.new()
	state.global_state = GlobalState.load_default()
	state.setup_new_run(local_db, 1, RNG.new(51))
	assert_true(SaveSystem.save_user_archive(state, 0, "quota snapshot"))
	state.back_to_prev_left = 3 # spent some rewinds after archiving
	var restored = SaveSystem.load_user_archive(local_db, 0)
	assert_not_null(restored)
	assert_eq(restored.back_to_prev_left, 10,
		"the archive index's recorded quota wins over the live global value")
	SaveSystem.use_default_save_path()
	SaveSystem.use_default_user_archive_root()
	DirAccess.remove_absolute("user://test_global_domain_continue.json")
	DirAccess.remove_absolute("user://test_global_domain_archives/archive_00.json")
	DirAccess.remove_absolute("user://test_global_domain_archives/user_archives.json")
	DirAccess.remove_absolute("user://test_global_domain.json")
