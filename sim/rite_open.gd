## Shared rite availability checks for the selector and auto-begin flow.
class_name RiteOpen
extends RefCounted

## Whether a rite offers any player interaction: it has at least one card slot
## and at least one settlement branch (prior, normal, or extre). Single source
## of truth for both the map-pin filter and the selector filter so they agree.
static func is_interactive(rite: Dictionary) -> bool:
	if rite.get("cards_slot", {}).is_empty():
		return false
	for key in ["settlement_prior", "settlement", "settlement_extre"]:
		if (rite.get(key, []) as Array).size() > 0:
			return true
	return false


static func is_rite_open(rite: Dictionary, state, db, rng = null) -> bool:
	if state == null:
		var fallback_open_conditions = rite.get("open_conditions", [])
		if not (fallback_open_conditions is Array) or fallback_open_conditions.is_empty():
			return true
		for entry in fallback_open_conditions:
			if entry is Dictionary and not (entry.get("condition", {}) as Dictionary).is_empty():
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
			var condition: Dictionary = entry.get("condition", {})
			if not ConditionEval.evaluate(condition, ctx):
				return false
	return true
