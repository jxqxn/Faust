extends GutTest

const GameModeRouter = preload("res://core/game_mode_router.gd")


func test_three_eight_day_paths_produce_explainable_different_results() -> void:
	var time_priority = _run_time_priority_path()
	var request_priority = _run_request_priority_path()
	var tactical_priority = _run_tactical_priority_path()

	assert_eq(time_priority.state.day, 8)
	assert_true("restricted_night_out" in time_priority.relations["mentor"].unlocks)
	assert_true(_history_has_action(time_priority, "restricted_night_out"))
	assert_false(_history_has_action(time_priority, "station_request_run"), "time priority deliberately gives up the request path")

	assert_eq(request_priority.state.day, 8)
	assert_eq(request_priority.relations["network"].resolved_request_count, 1)
	assert_true("crowd_clue" in request_priority.owned_card_ids)
	assert_false(request_priority.cases["museum_case"].resolved, "the request-first path visibly misses the case route")
	assert_true(request_priority.cases["museum_case"].is_due_on(8))
	assert_ne(request_priority.cases["museum_case"].failure_outcome, "")

	assert_eq(tactical_priority.state.day, 8)
	assert_true("swap_reserve_member" in tactical_priority.relations["tactician"].unlocks)
	assert_true(tactical_priority.cases["museum_case"].resolved)
	assert_eq(tactical_priority.cases["museum_case"].outcome, "museum_case_resolved")
	assert_true(_history_has_action(tactical_priority, "museum_treasure_action"))
	assert_false(_history_has_action(tactical_priority, "station_request_run"), "tactical priority gives up the request path")


func test_formal_router_creates_isolated_calendar_runtime_without_sultan_state() -> void:
	var resolver = GameModeRouter.new().new_calendar_resolver()
	assert_not_null(resolver)
	assert_eq(resolver.state.day, 1)
	assert_true(resolver.cases.has("museum_case"))
	assert_false(resolver.get("game_state") != null, "calendar runtime has no Sultan GameState field")


func _run_time_priority_path():
	var resolver = _new_resolver()
	_reach(resolver, 2, "night")
	assert_true(resolver.resolve(resolver.find_opportunity("mentor_rank_1")).ok)
	_reach(resolver, 3, "after_school")
	var scout = resolver.resolve(resolver.find_opportunity("museum_scout"))
	assert_true(scout.ok)
	assert_true(scout.generated_opportunity_ids.any(func(id): return str(id).begins_with("restricted_night_out")))
	resolver.engine.advance_period()
	assert_true(resolver.resolve_restricted_night_out().ok)
	_reach(resolver, 8, "night")
	return resolver


func _run_request_priority_path():
	var resolver = _new_resolver()
	_reach(resolver, 4, "night")
	assert_true(resolver.resolve(resolver.find_opportunity("network_request")).ok)
	_reach(resolver, 5, "after_school")
	assert_true(resolver.resolve(resolver.find_opportunity("station_request_run")).ok)
	_reach(resolver, 8, "night")
	return resolver


func _run_tactical_priority_path():
	var resolver = _new_resolver()
	_reach(resolver, 3, "after_school")
	assert_true(resolver.resolve(resolver.find_opportunity("museum_scout")).ok)
	_reach(resolver, 6, "night")
	assert_true(resolver.resolve(resolver.find_opportunity("tactician_window")).ok)
	_reach(resolver, 7, "after_school")
	var key_result = resolver.resolve(resolver.find_opportunity("museum_key_action"))
	assert_true(key_result.ok)
	assert_true(key_result.state_changes.has("museum_case.solution = reserve_swap"))
	_reach(resolver, 8, "after_school")
	assert_true(resolver.resolve(resolver.find_opportunity("museum_calling_card")).ok)
	resolver.engine.advance_period()
	assert_true(resolver.resolve(resolver.find_opportunity("museum_treasure_action")).ok)
	return resolver


func _new_resolver():
	var resolver = GameModeRouter.new().new_calendar_resolver()
	assert_not_null(resolver)
	return resolver


func _reach(resolver, target_day: int, target_period: String) -> void:
	while resolver.state.day < target_day or (resolver.state.day == target_day and resolver.state.period != target_period):
		if not resolver.state.is_period_consumed(resolver.state.day, resolver.state.period):
			assert_true(resolver.engine.consume_current_period(), "passing a period is an explicit opportunity cost")
		assert_true(resolver.engine.advance_period())


func _history_has_action(resolver, action_id: String) -> bool:
	return resolver.state.history.any(func(entry): return str(entry.get("action_id", "")) == action_id)
