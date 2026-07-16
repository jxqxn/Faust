## Per-character relationship state for the calendar-relationship mode.
class_name RelationState
extends RefCounted

const PROGRESSION_AFFINITY := "affinity"
const PROGRESSION_RESOLVED_REQUESTS := "resolved_requests"
const VALID_PROGRESSION_SOURCES := [PROGRESSION_AFFINITY, PROGRESSION_RESOLVED_REQUESTS]

var relation_id: String = ""
var rank: int = 0
var affinity: int = 0
var stage: String = "locked"
var progression_source: String = PROGRESSION_AFFINITY
var resolved_request_count: int = 0
var request_count: int = 0
var unlocks: Array = []
var flags: Dictionary = {}


func _init(id: String = "", source: String = PROGRESSION_AFFINITY) -> void:
	relation_id = id
	progression_source = source if source in VALID_PROGRESSION_SOURCES else PROGRESSION_AFFINITY


func add_affinity(amount: int) -> void:
	affinity = maxi(affinity + amount, 0)


func record_resolved_request() -> void:
	resolved_request_count += 1


func add_request_count(amount: int = 1) -> void:
	request_count = maxi(request_count + amount, 0)


func can_advance_from_affinity(required_affinity: int) -> bool:
	return progression_source == PROGRESSION_AFFINITY and affinity >= required_affinity


func can_advance_from_resolved_requests(required_count: int) -> bool:
	return progression_source == PROGRESSION_RESOLVED_REQUESTS and resolved_request_count >= required_count


func advance_rank(next_stage: String) -> void:
	rank += 1
	stage = next_stage


func unlock(ability_id: String) -> void:
	if ability_id != "" and ability_id not in unlocks:
		unlocks.append(ability_id)


func to_dict() -> Dictionary:
	return {
		"relation_id": relation_id,
		"rank": rank,
		"affinity": affinity,
		"stage": stage,
		"progression_source": progression_source,
		"resolved_request_count": resolved_request_count,
		"request_count": request_count,
		"unlocks": unlocks.duplicate(true),
		"flags": flags.duplicate(true),
	}


static func from_dict(data: Dictionary):
	var state = load("res://modes/calendar_coop/model/relation_state.gd").new(str(data.get("relation_id", "")), str(data.get("progression_source", PROGRESSION_AFFINITY)))
	state.rank = maxi(int(data.get("rank", 0)), 0)
	state.affinity = maxi(int(data.get("affinity", 0)), 0)
	state.stage = str(data.get("stage", "locked"))
	state.resolved_request_count = maxi(int(data.get("resolved_request_count", 0)), 0)
	state.request_count = maxi(int(data.get("request_count", 0)), 0)
	state.unlocks = data.get("unlocks", []).duplicate(true) if data.get("unlocks", []) is Array else []
	state.flags = data.get("flags", {}).duplicate(true) if data.get("flags", {}) is Dictionary else {}
	return state
