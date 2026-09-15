## Shared rite availability checks for the selector and auto-begin flow.
class_name RiteOpen
extends RefCounted

static func is_rite_open(rite: Dictionary, state, db, rng = null) -> bool:
	if state == null:
		var fallback_open_conditions = rite.get("open_conditions", [])
		if not (fallback_open_conditions is Array) or fallback_open_conditions.is_empty():
			return true
		for entry in fallback_open_conditions:
			if entry is Dictionary and not entry.get("condition", {}).is_empty():
				return false
		return true
	# `round_number` is a lifetime threshold for an already-created rite
	# instance, not a global-round gate for map visibility. The original checks
	# Rite.life against RiteNode.round_number in UpdateSingleRite.
	# [SRC: GameController.c @ UpdateSingleRite (RVA 0x55ab10), lines 5857-5882]
	var open_conditions = rite.get("open_conditions", [])
	if not (open_conditions is Array) or open_conditions.is_empty():
		return true
	var ctx := {"db": db, "state": state, "rng": rng, "rite_state": {}, "attr_slots": ["s1", "s2"]}
	for entry in open_conditions:
		if entry is Dictionary:
			var condition: Variant = entry.get("condition", {})
			if not ConditionEval.evaluate(condition, ctx):
				return false
	return true
