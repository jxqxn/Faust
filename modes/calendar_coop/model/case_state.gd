## State for one visible deadline case. Case progression is deliberately
## explicit: callers may only move one documented stage forward at a time.
class_name CaseState
extends RefCounted

const PHASE_INTEL := "intel"
const PHASE_INFILTRATION := "infiltration"
const PHASE_ROUTE_CONFIRMED := "route_confirmed"
const PHASE_CALLING_CARD := "calling_card"
const PHASE_TREASURE_SECURED := "treasure_secured"
const PHASES := [PHASE_INTEL, PHASE_INFILTRATION, PHASE_ROUTE_CONFIRMED, PHASE_CALLING_CARD, PHASE_TREASURE_SECURED]

var case_id: String = ""
var phase: String = PHASE_INTEL
var deadline_day: int = 1
var route_id: String = ""
var forecast: Array = []
var outcome: String = ""
var failure_outcome: String = ""
var resolved: bool = false


func _init(id: String = "", deadline: int = 1) -> void:
	case_id = id
	deadline_day = maxi(deadline, 1)


func can_advance_to(next_phase: String) -> bool:
	if resolved or next_phase not in PHASES:
		return false
	var current_index := PHASES.find(phase)
	return current_index >= 0 and current_index + 1 < PHASES.size() and PHASES[current_index + 1] == next_phase


func advance_to(next_phase: String) -> bool:
	if not can_advance_to(next_phase):
		return false
	phase = next_phase
	return true


func resolve(result_id: String) -> bool:
	if resolved or result_id == "":
		return false
	outcome = result_id
	resolved = true
	return true


func is_due_on(target_day: int) -> bool:
	return not resolved and target_day >= deadline_day


func to_dict() -> Dictionary:
	return {
		"case_id": case_id,
		"phase": phase,
		"deadline_day": deadline_day,
		"route_id": route_id,
		"forecast": forecast.duplicate(true),
		"outcome": outcome,
		"failure_outcome": failure_outcome,
		"resolved": resolved,
	}


static func from_dict(data: Dictionary):
	var state = load("res://modes/calendar_coop/model/case_state.gd").new(str(data.get("case_id", "")), int(data.get("deadline_day", 1)))
	var saved_phase := str(data.get("phase", PHASE_INTEL))
	state.phase = saved_phase if saved_phase in PHASES else PHASE_INTEL
	state.route_id = str(data.get("route_id", ""))
	state.forecast = data.get("forecast", []).duplicate(true) if data.get("forecast", []) is Array else []
	state.outcome = str(data.get("outcome", ""))
	state.failure_outcome = str(data.get("failure_outcome", ""))
	state.resolved = bool(data.get("resolved", false))
	return state
