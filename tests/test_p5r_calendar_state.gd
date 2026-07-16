extends GutTest

const CalendarStateModel = preload("res://modes/calendar_coop/model/calendar_state.gd")
const RelationStateModel = preload("res://modes/calendar_coop/model/relation_state.gd")
const CaseStateModel = preload("res://modes/calendar_coop/model/case_state.gd")
const PrototypeCardModel = preload("res://modes/calendar_coop/model/prototype_card.gd")
const OpportunityModel = preload("res://modes/calendar_coop/model/opportunity.gd")
const ActionResultModel = preload("res://modes/calendar_coop/model/action_result.gd")


func test_calendar_state_tracks_periods_forecast_history_and_deep_round_trip() -> void:
	var state = CalendarStateModel.new(3, CalendarStateModel.PERIOD_NIGHT)
	state.fixed_events.append({"id": "d03_exam", "day": 3})
	state.forecast.append({"id": "d04_network", "day": 4, "period": "night"})
	state.add_history({"id": "d03_palace", "cards": ["hero"]})

	assert_true(state.consume_period(3, CalendarStateModel.PERIOD_AFTER_SCHOOL))
	assert_false(state.consume_period(3, CalendarStateModel.PERIOD_AFTER_SCHOOL), "one period cannot be consumed twice")
	assert_false(state.consume_period(3, "morning"), "only contract periods are accepted")
	assert_true(state.is_period_consumed(3, CalendarStateModel.PERIOD_AFTER_SCHOOL))

	var restored = CalendarStateModel.from_dict(state.to_dict())
	state.forecast[0]["id"] = "mutated"
	state.history[0]["cards"].append("mutated")
	assert_eq(restored.day, 3)
	assert_eq(restored.period, CalendarStateModel.PERIOD_NIGHT)
	assert_true(restored.is_period_consumed(3, CalendarStateModel.PERIOD_AFTER_SCHOOL))
	assert_eq(restored.forecast[0]["id"], "d04_network")
	assert_eq(restored.history[0]["cards"], ["hero"])


func test_relation_state_keeps_affinity_and_request_progression_independent() -> void:
	var mentor = RelationStateModel.new("mentor", RelationStateModel.PROGRESSION_AFFINITY)
	mentor.add_affinity(3)
	mentor.record_resolved_request()
	assert_true(mentor.can_advance_from_affinity(3))
	assert_false(mentor.can_advance_from_resolved_requests(1))

	var network = RelationStateModel.new("network", RelationStateModel.PROGRESSION_RESOLVED_REQUESTS)
	network.add_affinity(99)
	assert_false(network.can_advance_from_affinity(1), "network must not rank up from affinity")
	network.record_resolved_request()
	network.record_resolved_request()
	assert_true(network.can_advance_from_resolved_requests(2))
	network.add_request_count()
	network.unlock("crowd_clue")
	var restored = RelationStateModel.from_dict(network.to_dict())
	network.flags["changed"] = true
	assert_eq(restored.resolved_request_count, 2)
	assert_eq(restored.request_count, 1)
	assert_eq(restored.unlocks, ["crowd_clue"])
	assert_false(restored.flags.has("changed"))


func test_case_state_only_allows_defined_forward_stages_and_round_trips() -> void:
	var state = CaseStateModel.new("museum_case", 8)
	state.route_id = "north"
	state.forecast.append({"day": 6, "message": "deadline soon"})
	assert_false(state.advance_to(CaseStateModel.PHASE_ROUTE_CONFIRMED), "stages cannot be skipped")
	assert_true(state.advance_to(CaseStateModel.PHASE_INFILTRATION))
	assert_true(state.advance_to(CaseStateModel.PHASE_ROUTE_CONFIRMED))
	assert_true(state.is_due_on(8))
	assert_true(state.resolve("success"))
	assert_false(state.is_due_on(9), "resolved cases are no longer due")
	assert_false(state.advance_to(CaseStateModel.PHASE_CALLING_CARD), "resolved cases cannot change phase")

	var restored = CaseStateModel.from_dict(state.to_dict())
	state.forecast[0]["message"] = "mutated"
	assert_eq(restored.phase, CaseStateModel.PHASE_ROUTE_CONFIRMED)
	assert_eq(restored.route_id, "north")
	assert_eq(restored.forecast[0]["message"], "deadline soon")
	assert_true(restored.resolved)


func test_card_opportunity_and_action_result_are_isolated_serializable_models() -> void:
	var card = PrototypeCardModel.new("crowd_clue", "support")
	card.tags = ["network"]
	card.state = {"charges": 1}
	var restored_card = PrototypeCardModel.from_dict(card.to_dict())
	card.state["charges"] = 0
	assert_true(restored_card.has_tag("network"))
	assert_eq(restored_card.state["charges"], 1)

	var opportunity = OpportunityModel.new("d07_after_school_network_rank_2", 7, "after_school")
	opportunity.kind = "social"
	opportunity.actor_id = "network"
	opportunity.required_cards = ["hero"]
	opportunity.optional_cards = ["arcana_moon"]
	opportunity.lock_reason = "先完成请求"
	opportunity.action_id = "network_rank_2"
	var restored_opportunity = OpportunityModel.from_dict(opportunity.to_dict())
	opportunity.required_cards.append("mutated")
	assert_true(restored_opportunity.is_locked())
	assert_true(restored_opportunity.is_for(7, "after_school"))
	assert_eq(restored_opportunity.required_cards, ["hero"])

	var success = ActionResultModel.success("完成委托", ["after_school"], ["network.request_count +1"], ["d08_night_network_rank_3"], "d07_mementos_bully")
	var restored_success = ActionResultModel.from_dict(success.to_dict())
	success.state_changes.append("mutated")
	assert_true(restored_success.ok)
	assert_eq(restored_success.consumed_periods, ["after_school"])
	assert_eq(restored_success.state_changes, ["network.request_count +1"])
	assert_eq(restored_success.generated_opportunity_ids, ["d08_night_network_rank_3"])

	var failure = ActionResultModel.failure("时段已消耗")
	assert_false(failure.ok)
	assert_eq(failure.failure_reason, "时段已消耗")
