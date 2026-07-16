extends GutTest

const CalendarCoopGame = preload("res://modes/calendar_coop/ui/calendar_coop_game.gd")


func test_calendar_mode_ui_shows_required_planning_information() -> void:
	var stage := Control.new()
	add_child_autofree(stage)
	var game = CalendarCoopGame.new()
	stage.add_child(game)
	await wait_process_frames(2)

	assert_not_null(game.find_child("CalendarDayLabel", true, false))
	assert_not_null(game.find_child("CaseDeadlineLabel", true, false))
	assert_not_null(game.find_child("PeriodSlot_after_school", true, false))
	assert_not_null(game.find_child("PeriodSlot_night", true, false))
	assert_not_null(game.find_child("OpportunityCards", true, false))
	assert_not_null(game.find_child("ActionBoard", true, false))
	assert_true(game.find_child("OpportunityCards", true, false).get_child_count() >= 1)


func test_closing_action_board_does_not_change_calendar_state() -> void:
	var stage := Control.new()
	add_child_autofree(stage)
	var game = CalendarCoopGame.new()
	stage.add_child(game)
	await wait_process_frames(2)
	var board = game.find_child("ActionBoard", true, false)
	var original_day: int = int(game.resolver.state.day)
	var original_period: String = str(game.resolver.state.period)
	board.visible = false
	assert_eq(game.resolver.state.day, original_day)
	assert_eq(game.resolver.state.period, original_period)
