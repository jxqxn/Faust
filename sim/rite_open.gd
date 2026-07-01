## Shared rite availability checks for the selector and auto-begin flow.
class_name RiteOpen
extends RefCounted

const ConditionEval = preload("res://sim/condition.gd")


static func is_rite_open(rite: Dictionary, state, db, rng = null) -> bool:
	if state == null:
		var open_conditions = rite.get("open_conditions", [])
		if not (open_conditions is Array) or open_conditions.is_empty():
			return true
		for entry in open_conditions:
			if entry is Dictionary and not (entry.get("condition", {}) as Dictionary).is_empty():
				return false
		return true
	var min_round := int(rite.get("round_number", 0))
	if min_round > 0 and int(state.round_number) < min_round:
		return false
	var open_conditions = rite.get("open_conditions", [])
	if not (open_conditions is Array) or open_conditions.is_empty():
		return true
	var ctx := {"db": db, "state": state, "rng": rng, "rite_state": {}, "attr_slots": ["s1", "s2"]}
	for entry in open_conditions:
		if entry is Dictionary:
			var condition: Dictionary = entry.get("condition", {})
			if not ConditionEval.evaluate(condition, ctx):
				return false
	return true
