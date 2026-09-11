extends GutTest

const SOURCE := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/"
const Game = preload("res://ui/game.gd")
var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()
	SaveSystem.use_save_path("user://test_archive_flow/continue.json")
	SaveSystem.use_user_archive_root("user://test_archive_flow/archives")
	SaveSystem.use_round_save_root("user://test_archive_flow/rounds")
	SaveSystem.delete_all_user_archives()

func after_all():
	SaveSystem.delete_all_user_archives()
	SaveSystem.delete_save()
	SaveSystem.use_default_save_path()
	SaveSystem.use_default_user_archive_root()
	SaveSystem.use_default_round_save_root()

func test_summary_matches_original_archive_and_slot_save():
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE + "save_slot_000.json"))
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string(SOURCE + "user_archive.json"))
	var imported: Dictionary = OriginalSaveImporter.import_save(source, db)
	var state = imported.state
	var summary := SaveSystem.archive_sudan_summary(state, db)
	assert_eq(summary.left_sudan, int(entries[0].left_sudan), "same-instant source archive pool+live count")
	assert_eq(summary.execution_day, int(entries[0].execution_day), "source remaining days, not absolute day")
	state.day = 99
	assert_eq(SaveSystem.archive_sudan_summary(state, db), summary, "calendar day cannot alter the archive countdown")
	assert_true(SaveSystem.save_user_archive(state, 4, "原作快照", db))
	var saved := SaveSystem.list_user_archives(db)
	assert_eq(int(saved[0].execution_day), int(entries[0].execution_day))


func test_archive_item_formats_source_timestamp_and_confirm_surfaces_keep_structure():
	var panel: Control = load("res://ui/user_archive_panel.gd").new()
	add_child_autofree(panel)
	assert_eq(
		panel._format_archive_time("2026-06-26T15:37:11.0841133+08:00"),
		"2026/6/26 15:37:11",
		"archive rows use the source short timestamp format")
	panel.setup([{
		"index": 0,
		"name": "原作",
		"live_days": 1,
		"left_sudan": 28,
		"execution_day": 7,
		"save_time": "2026-06-26T15:37:11.0841133+08:00",
	}], true)
	panel.refresh_archives([{
		"index": 0,
		"name": "原作",
		"live_days": 1,
		"left_sudan": 28,
		"execution_day": 7,
		"save_time": "2026-06-26T15:37:11.0841133+08:00",
	}])
	var row: Control = panel.find_child("UserArchiveItem_00", true, false) as Control
	assert_not_null(row)
	assert_eq(row.size, Vector2(2471.2, 240), "archive row keeps runtime viewport width")
	assert_not_null(panel.find_child("footer", true, false), "archive row includes the source footer rule")
	panel.queue_free()
	await wait_process_frames(3)

func test_save_rename_overwrite_cancel_and_delete_keep_picker():
	SaveSystem.delete_all_user_archives()
	var game = Game.new()
	add_child_autofree(game)
	await wait_process_frames(3)
	game.state = GameState.new()
	game.state.setup_new_run(db, 1, GameRNG.new(34))
	game._show_user_archive_overlay()
	var panel = game._user_archive_overlay
	panel._on_item_clicked(0)
	panel._name_input.text = "路线甲"
	panel._refresh_name_confirm()
	panel._confirm_name_input()
	await wait_process_frames(2)
	assert_eq(game._user_archive_overlay, panel, "save refreshes the source row without dismissing picker")
	var payload := FileAccess.get_sha256(SaveSystem.user_archive_save_path(0))
	panel._open_rename(0)
	panel._name_input.text = "路线乙"
	panel._confirm_name_input()
	await wait_process_frames(2)
	assert_eq(FileAccess.get_sha256(SaveSystem.user_archive_save_path(0)), payload, "rename changes index metadata only")
	assert_eq(SaveSystem.list_user_archives(db)[0].name, "路线乙")
	panel._on_item_clicked(0)
	panel._confirmation._finish(false)
	await wait_process_frames(2)
	assert_eq(FileAccess.get_sha256(SaveSystem.user_archive_save_path(0)), payload, "cancel overwrite preserves bytes")
	panel._on_item_clicked(0)
	panel._confirmation._finish(true)
	await wait_process_frames(2)
	assert_not_null(panel._name_popup, "overwrite confirmation opens name input")
	panel._close_name_input()
	await wait_process_frames(2)
	assert_eq(FileAccess.get_sha256(SaveSystem.user_archive_save_path(0)), payload, "cancel name preserves bytes")
	panel._confirm_delete(0)
	panel._delete_confirmation.get_node("Close").pressed.emit()
	await wait_process_frames(2)
	assert_eq(SaveSystem.list_user_archives(db).size(), 1)
	panel._confirm_delete(0)
	panel._delete_confirmation.get_node("Confirm").pressed.emit()
	await wait_process_frames(2)
	assert_true(SaveSystem.list_user_archives(db).is_empty())
	assert_eq(game._user_archive_overlay, panel, "delete replaces row with empty slot")
	assert_not_null(panel.find_child("EmptyContent", true, false))
