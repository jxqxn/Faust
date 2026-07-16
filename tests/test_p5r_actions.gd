extends GutTest

const CalendarStateModel = preload("res://modes/calendar_coop/model/calendar_state.gd")
const ContentRepository = preload("res://modes/calendar_coop/services/content_repository.gd")
const CalendarEngine = preload("res://modes/calendar_coop/services/calendar_engine.gd")
const OpportunityService = preload("res://modes/calendar_coop/services/opportunity_service.gd")
const ActionResolver = preload("res://modes/calendar_coop/services/action_resolver.gd")


func test_failed_resolution_is_atomic_and_does_not_consume_a_period() -> void:
	var resolver = _resolver(3, "after_school")
	var opportunity = resolver.find_opportunity("museum_scout")
	resolver.owned_card_ids.erase("hero")
	var result = resolver.resolve(opportunity)
	assert_false(result.ok)
	assert_eq(result.failure_reason, "需要卡牌：hero")
	assert_false(resolver.state.is_period_consumed(3, "after_school"))
	assert_eq(resolver.cases["museum_case"].phase, "intel")


func test_mentor_only_restores_a_restricted_night_after_heist() -> void:
	var resolver = _resolver(2, "night")
	assert_true(resolver.resolve(resolver.find_opportunity("mentor_rank_1")).ok)
	resolver.state.day = 3
	resolver.state.period = "after_school"
	assert_true(resolver.resolve(resolver.find_opportunity("museum_scout")).ok)
	resolver.engine.advance_period()
	var result = resolver.resolve_restricted_night_out()
	assert_true(result.ok)
	assert_eq(result.consumed_periods, ["night"])
	assert_false(resolver.resolve_restricted_night_out().ok, "the restricted night cannot become a second free social turn")


func test_network_ranks_only_from_a_resolved_request_and_grants_support_card() -> void:
	var resolver = _resolver(4, "night")
	assert_true(resolver.resolve(resolver.find_opportunity("network_request")).ok)
	assert_eq(resolver.relations["network"].affinity, 0)
	assert_eq(resolver.relations["network"].rank, 0)
	assert_true("bully_request" in resolver.owned_card_ids)
	resolver.state.day = 5
	resolver.state.period = "after_school"
	assert_true(resolver.resolve(resolver.find_opportunity("station_request_run")).ok)
	assert_eq(resolver.relations["network"].resolved_request_count, 1)
	assert_eq(resolver.relations["network"].rank, 1)
	assert_true("crowd_clue" in resolver.owned_card_ids)


func test_tactician_unlock_changes_the_key_heist_solution() -> void:
	var resolver = _resolver(6, "night")
	assert_true(resolver.resolve(resolver.find_opportunity("tactician_window")).ok)
	resolver.state.day = 7
	resolver.state.period = "after_school"
	resolver.cases["museum_case"].phase = "infiltration"
	var result = resolver.resolve(resolver.find_opportunity("museum_key_action"))
	assert_true(result.ok)
	assert_true(result.state_changes.has("museum_case.solution = reserve_swap"))


func test_day_eight_heists_settle_the_case_after_the_defined_stages() -> void:
	var resolver = _resolver(7, "after_school")
	resolver.cases["museum_case"].phase = "infiltration"
	assert_true(resolver.resolve(resolver.find_opportunity("museum_key_action")).ok)
	resolver.state.day = 8
	resolver.state.period = "after_school"
	assert_true(resolver.resolve(resolver.find_opportunity("museum_calling_card")).ok)
	resolver.engine.advance_period()
	assert_true(resolver.resolve(resolver.find_opportunity("museum_treasure_action")).ok)
	assert_true(resolver.cases["museum_case"].resolved)
	assert_eq(resolver.cases["museum_case"].outcome, "museum_case_resolved")


func _resolver(day: int, period: String):
	var repository = ContentRepository.new()
	assert_true(repository.load_all())
	var engine = CalendarEngine.new(CalendarStateModel.new(day, period), repository)
	return ActionResolver.new(engine, OpportunityService.new(repository), repository)
