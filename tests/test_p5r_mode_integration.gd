extends GutTest

const MainGame = preload("res://ui/game.gd")
const CalendarCoopGame = preload("res://modes/calendar_coop/ui/calendar_coop_game.gd")
const CalendarCoopSave = preload("res://modes/calendar_coop/services/calendar_coop_save.gd")
const ContentRepository = preload("res://modes/calendar_coop/services/content_repository.gd")
const CalendarStateModel = preload("res://modes/calendar_coop/model/calendar_state.gd")
const CalendarEngine = preload("res://modes/calendar_coop/services/calendar_engine.gd")
const OpportunityService = preload("res://modes/calendar_coop/services/opportunity_service.gd")
const ActionResolver = preload("res://modes/calendar_coop/services/action_resolver.gd")


func before_each() -> void:
	CalendarCoopSave.use_save_path("user://test_calendar_coop/save.json")
	CalendarCoopSave.delete_save()
	SaveSystem.use_save_path("user://test_calendar_sultan_v5.json")
	SaveSystem.delete_save()


func after_each() -> void:
	CalendarCoopSave.delete_save()
	CalendarCoopSave.use_default_save_path()
	SaveSystem.delete_save()
	SaveSystem.use_default_save_path()


func test_calendar_save_is_independent_and_rejects_non_calendar_data() -> void:
	var resolver = _resolver()
	resolver.state.day = 5
	resolver.owned_card_ids.append("crowd_clue")
	assert_true(CalendarCoopSave.save(resolver))
	assert_true(CalendarCoopSave.has_valid_save())
	var db = ConfigDB.new()
	db.load_all()
	var sultan_state = GameState.new()
	sultan_state.setup_new_run(db, 0, GameRNG.new(31))
	sultan_state.day = 4
	assert_true(SaveSystem.save(sultan_state), "the Sultan v5 save can be written beside the calendar save")
	var calendar_data = JSON.parse_string(FileAccess.get_file_as_string(CalendarCoopSave.save_path()))
	var sultan_data = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.save_path()))
	assert_eq(calendar_data.get("save_kind", ""), CalendarCoopSave.SAVE_KIND)
	assert_eq(int(calendar_data.get("runtime", {}).get("calendar", {}).get("day", 0)), 5)
	assert_eq(sultan_data.get("save_kind", ""), SaveSystem.SAVE_KIND_PLAYER)
	assert_eq(int(sultan_data.get("day", 0)), 4)
	var repository = ContentRepository.new()
	assert_true(repository.load_all())
	var restored = CalendarCoopSave.load(repository)
	assert_not_null(restored)
	assert_eq(restored.state.day, 5)
	assert_true("crowd_clue" in restored.owned_card_ids)

	var file := FileAccess.open(CalendarCoopSave.save_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_kind": "player", "version": 5}))
	file.close()
	assert_false(CalendarCoopSave.has_valid_save(), "a Sultan-style save marker is never accepted as calendar data")
	assert_eq(CalendarCoopSave.load(repository), null)


func test_main_menu_can_new_continue_and_return_calendar_mode() -> void:
	var stage := Control.new()
	add_child_autofree(stage)
	var game = MainGame.new()
	stage.add_child(game)
	await wait_process_frames(2)
	var menu = game._current
	assert_not_null(menu.find_child("CalendarNewButton", true, false))
	menu.calendar_new_requested.emit()
	await wait_process_frames(2)
	assert_true(game._current is CalendarCoopGame)
	game._current.return_to_title.emit()
	await wait_process_frames(2)
	assert_not_null(game._current.find_child("CalendarContinueButton", true, false))
	game._current.calendar_continue_requested.emit()
	await wait_process_frames(2)
	assert_true(game._current is CalendarCoopGame)


func _resolver():
	var repository = ContentRepository.new()
	assert_true(repository.load_all())
	var engine = CalendarEngine.new(CalendarStateModel.new(1), repository)
	return ActionResolver.new(engine, OpportunityService.new(repository), repository)
