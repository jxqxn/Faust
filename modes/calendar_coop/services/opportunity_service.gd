## Creates read-only Opportunity snapshots from content and current state.
## This service explains availability but never resolves an action.
class_name OpportunityService
extends RefCounted

const OpportunityModel = preload("res://modes/calendar_coop/model/opportunity.gd")

var repository


func _init(content_repository) -> void:
	repository = content_repository


func opportunities_for_day(calendar_state, relations: Dictionary = {}, cases: Dictionary = {}, available_card_ids: Array = []) -> Array:
	var opportunities: Array = []
	for action in repository.content.get("actions", {}).get("actions", []):
		if not (action is Dictionary) or int(action.get("day", 0)) != calendar_state.day:
			continue
		opportunities.append(_build_opportunity(action, calendar_state, relations, cases, available_card_ids))
	for event in repository.get_calendar().get("fixed_events", []):
		if event is Dictionary and int(event.get("day", 0)) == calendar_state.day:
			opportunities.append(_build_fixed_event(event, calendar_state))
	return opportunities


func is_current(opportunity, calendar_state) -> bool:
	return opportunity.day == calendar_state.day and not calendar_state.is_period_consumed(opportunity.day, opportunity.period)


func _build_opportunity(action: Dictionary, calendar_state, relations: Dictionary, cases: Dictionary, available_card_ids: Array):
	var opportunity = OpportunityModel.new(_opportunity_id(action), int(action.get("day", 0)), str(action.get("period", "after_school")))
	opportunity.kind = _opportunity_kind(str(action.get("kind", "")))
	opportunity.actor_id = str(action.get("actor_id", ""))
	opportunity.required_cards = action.get("required_cards", []).duplicate(true)
	opportunity.optional_cards = action.get("optional_cards", []).duplicate(true)
	opportunity.action_id = str(action.get("id", ""))
	opportunity.lock_reason = _lock_reason(action, calendar_state, relations, cases, available_card_ids)
	return opportunity


func _build_fixed_event(event: Dictionary, calendar_state):
	var opportunity = OpportunityModel.new("fixed_%s" % str(event.get("id", "")), int(event.get("day", 0)), str(event.get("period", "after_school")))
	opportunity.kind = "fixed"
	opportunity.actor_id = ""
	opportunity.action_id = str(event.get("id", ""))
	if calendar_state.is_period_consumed(opportunity.day, opportunity.period):
		opportunity.lock_reason = "该时段已使用"
	return opportunity


func _lock_reason(action: Dictionary, calendar_state, relations: Dictionary, cases: Dictionary, available_card_ids: Array) -> String:
	var period := str(action.get("period", ""))
	if calendar_state.is_period_consumed(calendar_state.day, period):
		return "该时段已使用"
	for card_id in action.get("required_cards", []):
		if str(card_id) not in available_card_ids:
			return "需要卡牌：%s" % str(card_id)
	var kind := str(action.get("kind", ""))
	if kind == "heist":
		var case_state = cases.get(str(action.get("case_id", "")), null)
		var transition: Dictionary = action.get("phase_transition", {})
		if case_state == null or str(case_state.phase) != str(transition.get("from", "")):
			return "案件阶段尚未满足"
	if kind == "relationship_event":
		var relation = relations.get(str(action.get("relation_id", "")), null)
		if relation != null and str(relation.stage) == "locked":
			return "该人物当前无法见面"
	return ""


func _opportunity_id(action: Dictionary) -> String:
	return "d%02d_%s_%s" % [int(action.get("day", 0)), str(action.get("period", "after_school")), str(action.get("id", ""))]


func _opportunity_kind(action_kind: String) -> String:
	match action_kind:
		"relationship_event":
			return "social"
		"request_run":
			return "mementos"
		"heist":
			return "palace"
	return "fixed"
