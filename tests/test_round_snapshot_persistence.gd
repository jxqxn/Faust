extends GutTest

## Persistent rollback snapshots mirror DatapoolExtensions' round-formatted
## Player saves and survive a process-like GameState/global reload.
## [SRC: DatapoolExtensions.c SaveRoundBegin 0x3f9050, SaveRoundEnd
##       0x3f9120, LoadRound 0x3f8fa0, LoadRoundEnd 0x3f8e70,
##       IsValidRoundEnd 0x3f8d50; dump.cs:418323-418343;
##       stringliteral.json 0x258BED0 "round_{0}" / 0x258BF40
##       "round_{0}_end"; Datapool.c LoadUserArchive 0x417350]

const RNG = preload("res://core/rng.gd")
const TEST_ROOT := "res://.gut_round_snapshot_persistence"

var db: ConfigDB


func before_each() -> void:
	SaveSystem.use_save_path("%s/save.json" % TEST_ROOT)
	SaveSystem.use_round_save_root(TEST_ROOT)
	SaveSystem.use_user_archive_root("%s/archives" % TEST_ROOT)
	GlobalState.use_global_path("%s/global.json" % TEST_ROOT)
	GlobalState.reset_default_cache()
	_cleanup_files()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_ROOT))
	db = ConfigDB.new()
	db.load_all()


func after_each() -> void:
	_cleanup_files()
	SaveSystem.use_default_save_path()
	SaveSystem.use_default_round_save_root()
	SaveSystem.use_default_user_archive_root()
	GlobalState.use_default_global_path()
	GlobalState.reset_default_cache()


func _persistent_state(seed: int = 1) -> GameState:
	var state := GameState.new()
	state.global_state = GlobalState.load_default()
	state.setup_new_run(db, 1, RNG.new(seed))
	state.back_to_prev_left = 2
	assert_true(state.global_state.save())
	return state


func _cleanup_files() -> void:
	SaveSystem.delete_round_saves()
	SaveSystem.delete_save()
	SaveSystem.delete_all_user_archives()
	var global_path := "%s/global.json" % TEST_ROOT
	if FileAccess.file_exists(global_path):
		DirAccess.remove_absolute(global_path)
	var archives_root := "%s/archives" % TEST_ROOT
	if DirAccess.dir_exists_absolute(archives_root):
		DirAccess.remove_absolute(archives_root)
	if DirAccess.dir_exists_absolute(TEST_ROOT):
		DirAccess.remove_absolute(TEST_ROOT)


func test_round_end_snapshot_survives_process_like_reload() -> void:
	var state := _persistent_state(11)
	assert_eq(state.round_number, 1)
	RoundLoop.advance_day(state, db, RNG.new(12))
	assert_true(FileAccess.file_exists(SaveSystem.round_end_save_path(1)),
		"SaveRoundEnd writes round_1_end.json")
	assert_true(FileAccess.file_exists(SaveSystem.round_begin_save_path(2)),
		"SaveRoundBegin writes round_2.json")

	GlobalState.reset_default_cache()
	var restored = SaveSystem.load_continue(db)
	assert_not_null(restored)
	if restored == null:
		return
	assert_true(restored.round_snapshots["round_end"].is_empty(),
		"a new GameState has no in-memory rollback cache")
	assert_true(RoundLoop.back_to_prev_round_end(restored, db),
		"the disk round-end file replaces the missing cache")
	assert_eq(restored.round_number, 1)
	assert_eq(restored.back_to_prev_left, 1,
		"the global quota spends before loading the Player snapshot")


func test_round_begin_snapshot_survives_process_like_reload() -> void:
	var state := _persistent_state(21)
	RoundLoop.advance_day(state, db, RNG.new(22))
	GlobalState.reset_default_cache()
	var restored = SaveSystem.load_continue(db)
	assert_not_null(restored)
	if restored == null:
		return
	var gold_before: int = int(restored.coin_count)
	restored.add_coin(9)
	assert_eq(restored.coin_count, gold_before + 9)
	assert_true(RoundLoop.back_to_round_begin(restored, db))
	assert_eq(restored.coin_count, gold_before,
		"LoadRound restores the persisted start-of-round Player")


func test_corrupt_round_end_is_invalid_and_does_not_spend_quota() -> void:
	var state := _persistent_state(31)
	RoundLoop.advance_day(state, db, RNG.new(32))
	state.round_snapshots["round_end"].clear()
	var file := FileAccess.open(SaveSystem.round_end_save_path(1), FileAccess.WRITE)
	file.store_string("{not valid json")
	file.close()
	var before := state.back_to_prev_left
	assert_false(SaveSystem.is_valid_round_end(1))
	assert_false(RoundLoop.back_to_prev_round_end(state, db))
	assert_eq(state.back_to_prev_left, before,
		"IsValidRoundEnd gates the spend when the disk save is corrupt")


func test_loading_archive_deletes_round_files_from_old_timeline() -> void:
	var state := _persistent_state(41)
	RoundLoop.advance_day(state, db, RNG.new(42))
	assert_true(SaveSystem.save_user_archive(state, 0, "round cleanup"))
	assert_true(FileAccess.file_exists(SaveSystem.round_end_save_path(1)))
	assert_true(FileAccess.file_exists(SaveSystem.round_begin_save_path(2)))
	var restored = SaveSystem.load_user_archive(db, 0)
	assert_not_null(restored)
	assert_false(FileAccess.file_exists(SaveSystem.round_end_save_path(1)))
	assert_false(FileAccess.file_exists(SaveSystem.round_begin_save_path(2)),
		"LoadUserArchive deletes round_*.json before installing its Player")
