## Typed action settlement for the calendar-relationship mode. There is no
## generic effect DSL: every mutation is owned by one of three action kinds.
class_name CalendarCoopActionResolver
extends RefCounted

const RelationStateModel = preload("res://modes/calendar_coop/model/relation_state.gd")
const CaseStateModel = preload("res://modes/calendar_coop/model/case_state.gd")
const ActionResultModel = preload("res://modes/calendar_coop/model/action_result.gd")

var engine
var opportunity_service
var repository
var state
var relations: Dictionary = {}
var cases: Dictionary = {}
var owned_card_ids: Array = ["hero"]
var resolved_request_ids: Array = []


func _init(calendar_engine, opportunities, content_repository) -> void:
	engine = calendar_engine
	opportunity_service = opportunities
	repository = content_repository
	state = engine.state
	_initialize_runtime_state()


func opportunities_for_current_day() -> Array:
	return opportunity_service.opportunities_for_day(state, relations, cases, owned_card_ids)


func find_opportunity(action_id: String):
	for opportunity in opportunities_for_current_day():
		if opportunity.action_id == action_id:
			return opportunity
	return null


func resolve(opportunity, selected_optional_cards: Array = []):
	var failure = _validate_resolution(opportunity, selected_optional_cards)
	if not failure.is_empty():
		return ActionResultModel.failure(failure)
	var action: Dictionary = repository.get_action(opportunity.action_id)
	if not engine.consume_period(opportunity.day, opportunity.period):
		return ActionResultModel.failure("该时段已使用")
	var result
	match str(action.get("kind", "")):
		"relationship_event":
			result = _resolve_relationship_event(action)
		"request_run":
			result = _resolve_request_run(action)
		"heist":
			result = _resolve_heist(action)
		_:
			return ActionResultModel.failure("未知行动种类")
	state.add_history({"id": result.history_id, "day": state.day, "period": opportunity.period, "action_id": opportunity.action_id})
	return result


func resolve_restricted_night_out():
	var mentor = relations.get("mentor", null)
	if mentor == null or "restricted_night_out" not in mentor.unlocks:
		return ActionResultModel.failure("尚未获得受限夜晚外出权限")
	if state.period != "night" or int(mentor.flags.get("restricted_night_day", 0)) != state.day:
		return ActionResultModel.failure("今天没有可用的受限夜晚外出")
	if not engine.consume_current_period():
		return ActionResultModel.failure("该时段已使用")
	mentor.flags.erase("restricted_night_day")
	var result = ActionResultModel.success("在受限夜晚完成了独处安排", ["night"], ["mentor.restricted_night_out used"], [], "restricted_night_out_d%02d" % state.day)
	state.add_history({"id": result.history_id, "day": state.day, "period": "night", "action_id": "restricted_night_out"})
	return result


func export_runtime_data() -> Dictionary:
	var saved_relations: Dictionary = {}
	for id in relations:
		saved_relations[id] = relations[id].to_dict()
	var saved_cases: Dictionary = {}
	for id in cases:
		saved_cases[id] = cases[id].to_dict()
	return {
		"calendar": state.to_dict(),
		"relations": saved_relations,
		"cases": saved_cases,
		"owned_card_ids": owned_card_ids.duplicate(true),
		"resolved_request_ids": resolved_request_ids.duplicate(true),
	}


func restore_runtime_data(data: Dictionary) -> void:
	state = state.from_dict(data.get("calendar", {}))
	engine.state = state
	relations = {}
	for id in data.get("relations", {}):
		relations[str(id)] = RelationStateModel.from_dict(data["relations"][id])
	cases = {}
	for id in data.get("cases", {}):
		cases[str(id)] = CaseStateModel.from_dict(data["cases"][id])
	owned_card_ids = data.get("owned_card_ids", ["hero"]).duplicate(true) if data.get("owned_card_ids", []) is Array else ["hero"]
	resolved_request_ids = data.get("resolved_request_ids", []).duplicate(true) if data.get("resolved_request_ids", []) is Array else []


func _initialize_runtime_state() -> void:
	for character in repository.content.get("characters", {}).get("characters", []):
		if not (character is Dictionary) or str(character.get("role", "")) != "confidant":
			continue
		var relation = RelationStateModel.new(str(character.get("id", "")), str(character.get("progression_source", "affinity")))
		relation.stage = "available"
		relations[relation.relation_id] = relation
	for case_data in repository.content.get("cases", {}).get("cases", []):
		if not (case_data is Dictionary):
			continue
		var case_state = CaseStateModel.new(str(case_data.get("id", "")), int(case_data.get("deadline_day", 1)))
		case_state.failure_outcome = str(case_data.get("failure_outcome", ""))
		cases[case_state.case_id] = case_state


func _validate_resolution(opportunity, selected_optional_cards: Array) -> String:
	if opportunity == null or opportunity.action_id.is_empty():
		return "机会不存在或不可结算"
	if opportunity.day != state.day:
		return "机会已过期"
	if opportunity.period != state.period:
		return "必须先处理当前时段"
	if not opportunity.lock_reason.is_empty():
		return opportunity.lock_reason
	if state.is_period_consumed(opportunity.day, opportunity.period):
		return "该时段已使用"
	var action: Dictionary = repository.get_action(opportunity.action_id)
	if action.is_empty():
		return "行动内容不存在"
	if str(action.get("kind", "")) not in ["relationship_event", "request_run", "heist"]:
		return "未知行动种类"
	for card_id in action.get("required_cards", []):
		if str(card_id) not in owned_card_ids:
			return "需要卡牌：%s" % str(card_id)
	for card_id in selected_optional_cards:
		if str(card_id) not in action.get("optional_cards", []) or str(card_id) not in owned_card_ids:
			return "可选卡牌无效"
	if str(action.get("kind", "")) == "heist":
		var case_state = cases.get(str(action.get("case_id", "")), null)
		var transition: Dictionary = action.get("phase_transition", {})
		if case_state == null or str(case_state.phase) != str(transition.get("from", "")):
			return "案件阶段尚未满足"
		if not case_state.can_advance_to(str(transition.get("to", ""))):
			return "案件阶段转移无效"
	return ""


func _resolve_relationship_event(action: Dictionary):
	var relation = relations[str(action.get("relation_id", ""))]
	var changes: Array = []
	if relation.relation_id == "network":
		relation.stage = "request_open"
		_add_owned_card("bully_request")
		changes.append("network.request = opened")
		return ActionResultModel.success("收到一项需要亲自处理的请求", [state.period], changes, [], "d%02d_network_request" % state.day)
	relation.add_affinity(1)
	relation.rank = maxi(relation.rank, int(action.get("rank_to", 1)))
	relation.stage = str(action.get("stage_to", "available"))
	changes.append("%s.rank = %d" % [relation.relation_id, relation.rank])
	if relation.relation_id == "mentor":
		relation.unlock("restricted_night_out")
		changes.append("mentor.restricted_night_out unlocked")
	if relation.relation_id == "tactician":
		relation.unlock("swap_reserve_member")
		changes.append("tactician.swap_reserve_member unlocked")
	return ActionResultModel.success("关系阶段已推进", [state.period], changes, [], "d%02d_%s" % [state.day, relation.relation_id])


func _resolve_request_run(action: Dictionary):
	var request_id := str(action.get("request_card_id", ""))
	var relation = relations[str(action.get("relation_id", ""))]
	owned_card_ids.erase(request_id)
	if request_id not in resolved_request_ids:
		resolved_request_ids.append(request_id)
	relation.record_resolved_request()
	relation.rank = maxi(relation.rank, relation.resolved_request_count)
	relation.stage = "request_resolved"
	var generated_card := str(action.get("generated_card_id", ""))
	_add_owned_card(generated_card)
	relation.unlock(generated_card)
	return ActionResultModel.success("请求已经解决，新的群众线索可用于怪盗行动", [state.period], ["network.resolved_request_count +1", "%s granted" % generated_card], [], "d%02d_request_run" % state.day)


func _resolve_heist(action: Dictionary):
	var case_state = cases[str(action.get("case_id", ""))]
	var transition: Dictionary = action.get("phase_transition", {})
	case_state.advance_to(str(transition.get("to", "")))
	var changes: Array = ["%s.phase = %s" % [case_state.case_id, case_state.phase]]
	var generated: Array = []
	var tactician = relations.get("tactician", null)
	if tactician != null and "swap_reserve_member" in tactician.unlocks and str(action.get("id", "")) == "museum_key_action":
		changes.append("museum_case.solution = reserve_swap")
	else:
		changes.append("museum_case.solution = standard_route")
	var mentor = relations.get("mentor", null)
	if mentor != null and "restricted_night_out" in mentor.unlocks:
		mentor.flags["restricted_night_day"] = state.day
		generated.append("restricted_night_out_d%02d" % state.day)
		changes.append("mentor.restricted_night_out available")
	return ActionResultModel.success("怪盗行动改变了案件进度", [state.period], changes, generated, "d%02d_%s" % [state.day, str(action.get("id", "heist"))])


func _add_owned_card(card_id: String) -> void:
	if not card_id.is_empty() and card_id not in owned_card_ids:
		owned_card_ids.append(card_id)
