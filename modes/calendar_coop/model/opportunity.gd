## Immutable-by-convention snapshot of one selectable opportunity for a day
## and period. OpportunityService creates these; UI reads them.
class_name Opportunity
extends RefCounted

const VALID_PERIODS := ["after_school", "night"]
const VALID_KINDS := ["social", "investigate", "mementos", "palace", "fixed"]

var opportunity_id: String = ""
var day: int = 1
var period: String = "after_school"
var kind: String = "social"
var actor_id: String = ""
var required_cards: Array = []
var optional_cards: Array = []
var lock_reason: String = ""
var action_id: String = ""


func _init(id: String = "", target_day: int = 1, target_period: String = "after_school") -> void:
	opportunity_id = id
	day = maxi(target_day, 1)
	period = target_period if target_period in VALID_PERIODS else "after_school"


func is_locked() -> bool:
	return not lock_reason.is_empty()


func is_for(target_day: int, target_period: String) -> bool:
	return day == target_day and period == target_period


func to_dict() -> Dictionary:
	return {
		"id": opportunity_id,
		"day": day,
		"period": period,
		"kind": kind,
		"actor_id": actor_id,
		"required_cards": required_cards.duplicate(true),
		"optional_cards": optional_cards.duplicate(true),
		"lock_reason": lock_reason,
		"action_id": action_id,
	}


static func from_dict(data: Dictionary):
	var opportunity = load("res://modes/calendar_coop/model/opportunity.gd").new(str(data.get("id", "")), int(data.get("day", 1)), str(data.get("period", "after_school")))
	var saved_kind := str(data.get("kind", "social"))
	opportunity.kind = saved_kind if saved_kind in VALID_KINDS else "social"
	opportunity.actor_id = str(data.get("actor_id", ""))
	opportunity.required_cards = data.get("required_cards", []).duplicate(true) if data.get("required_cards", []) is Array else []
	opportunity.optional_cards = data.get("optional_cards", []).duplicate(true) if data.get("optional_cards", []) is Array else []
	opportunity.lock_reason = str(data.get("lock_reason", ""))
	opportunity.action_id = str(data.get("action_id", ""))
	return opportunity
