extends GutTest

const CalendarStateModel = preload("res://modes/calendar_coop/model/calendar_state.gd")
const RelationStateModel = preload("res://modes/calendar_coop/model/relation_state.gd")
const CaseStateModel = preload("res://modes/calendar_coop/model/case_state.gd")
const ContentRepository = preload("res://modes/calendar_coop/services/content_repository.gd")
const CalendarEngine = preload("res://modes/calendar_coop/services/calendar_engine.gd")
const OpportunityService = preload("res://modes/calendar_coop/services/opportunity_service.gd")


func test_calendar_engine_consumes_each_period_once_and_advances_in_order() -> void:
	var repository = _repository()
	var state = CalendarStateModel.new(1)
	var engine = CalendarEngine.new(state, repository)
	assert_true(engine.consume_current_period())
	assert_false(engine.consume_current_period(), "a period cannot be consumed twice")
	assert_true(engine.advance_period())
	assert_eq(state.period, "night")
	assert_true(engine.consume_current_period())
	assert_true(engine.advance_period())
	assert_eq(state.day, 2)
	assert_eq(state.period, "after_school")


func test_calendar_engine_exposes_fixed_events_and_two_day_forecast() -> void:
	var repository = _repository()
	var state = CalendarStateModel.new(1)
	var engine = CalendarEngine.new(state, repository)
	assert_eq(engine.fixed_events_for_day().size(), 1)
	assert_eq(engine.fixed_events_for_day()[0].get("id", ""), "d01_case_briefing")
	var forecast := engine.forecast_for_next_days(2)
	assert_eq(forecast.size(), 1)
	assert_eq(forecast[0].get("id", ""), "d03_case_warning")


func test_opportunities_are_visible_with_explicit_lock_reasons() -> void:
	var repository = _repository()
	var state = CalendarStateModel.new(3)
	var cases := {"museum_case": CaseStateModel.new("museum_case", 8)}
	var service = OpportunityService.new(repository)
	var locked: Array = service.opportunities_for_day(state, {}, cases, ["hero"])
	var scout = _find_action(locked, "museum_scout")
	assert_not_null(scout)
	assert_eq(scout.lock_reason, "", "the first heist is available at the intel phase")

	var card_locked: Array = service.opportunities_for_day(state, {}, cases, [])
	assert_eq(_find_action(card_locked, "museum_scout").lock_reason, "需要卡牌：hero")
	state.consume_period(3, "after_school")
	var period_locked: Array = service.opportunities_for_day(state, {}, cases, ["hero"])
	assert_eq(_find_action(period_locked, "museum_scout").lock_reason, "该时段已使用")


func test_opportunity_snapshots_cannot_be_reused_on_a_later_day() -> void:
	var repository = _repository()
	var state = CalendarStateModel.new(2)
	var mentor = RelationStateModel.new("mentor")
	mentor.stage = "available"
	var service = OpportunityService.new(repository)
	var snapshot = _find_action(service.opportunities_for_day(state, {"mentor": mentor}, {}, ["hero"]), "mentor_rank_1")
	assert_not_null(snapshot)
	state.day = 3
	assert_false(service.is_current(snapshot, state), "a day-two opportunity expires when day three begins")


func _repository():
	var repository = ContentRepository.new()
	assert_true(repository.load_all())
	return repository


func _find_action(opportunities: Array, action_id: String):
	for opportunity in opportunities:
		if opportunity.action_id == action_id:
			return opportunity
	return null
