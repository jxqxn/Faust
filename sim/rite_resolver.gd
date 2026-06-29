## Rite settlement pipeline.
## verified-conclusions + spec sec 10.1, re-confirmed vs
## decompiled/RiteResultPanelController.c:
##   settlement_prior  -> FIRST matching entry wins (mutually exclusive)
##   settlement        -> FIRST matching entry wins (mutually exclusive)
##   settlement_extre  -> ALL matching entries execute (non-exclusive)
## Each entry: evaluate condition -> if match, execute result + apply action.
class_name RiteResolver
extends RefCounted

const ConditionEval = preload("res://sim/condition.gd")
const ResultExec = preload("res://sim/result.gd")


## Result of resolving a rite.
class RiteResult:
	var prior_log: Array = []      # executed prior entries
	var normal_entry: Dictionary = {} # the single matched normal entry (may be empty)
	var extre_log: Array = []      # executed extre entries
	var deferred: Dictionary = {}  # merged deferred actions
	var dice_rolls: Array = []     # the dice values rolled (for UI)
	var successes: int = 0         # successes from the r1 check
	var dice_types_seen: Array = []
	func _init() -> void:
		deferred = {"events": [], "choose": {}, "rite": 0, "over": false, "back_to_prev": false, "logs": []}


## Resolve a rite end-to-end.
## ctx must contain: db, state, rng, rite_state{s1..s4->card_id}, rite_id.
static func resolve(rite: Dictionary, ctx: Dictionary, gold_dice_used: Variant = 0) -> RiteResult:
	var res := RiteResult.new()
	ctx["gold_dice_used"] = gold_dice_used
	# Per-type gold dice map for FuncCompare conditions keyed by check-type.
	# [SRC: FuncCompare.c @ IsSatisfied: goldDiceCounts[type] at param_2+0x50]
	if typeof(gold_dice_used) == TYPE_DICTIONARY:
		ctx["gold_dice_map"] = gold_dice_used
	else:
		ctx["gold_dice_map"] = {"r1": gold_dice_used, "f": gold_dice_used}
	ctx["rite_id"] = int(rite.get("id", 0))
	# 1. settlement_prior: first match wins.
	for entry in rite.get("settlement_prior", []):
		if ConditionEval.evaluate(entry.get("condition", {}), ctx):
			res.prior_log.append(entry)
			_merge_deferred(res.deferred, ResultExec.execute(entry.get("result", {}), ctx.get("state"), ctx.get("db")))
			break
	# 2. settlement: first match wins.
	for entry in rite.get("settlement", []):
		if ConditionEval.evaluate(entry.get("condition", {}), ctx):
			res.normal_entry = entry
			_merge_deferred(res.deferred, ResultExec.execute(entry.get("result", {}), ctx.get("state"), ctx.get("db")))
			break
	# 3. settlement_extre: all matches execute.
	for entry in rite.get("settlement_extre", []):
		if ConditionEval.evaluate(entry.get("condition", {}), ctx):
			res.extre_log.append(entry)
			_merge_deferred(res.deferred, ResultExec.execute(entry.get("result", {}), ctx.get("state"), ctx.get("db")))
	res.dice_types_seen = ctx.get("dice_types_seen", []).duplicate()
	var cache: Dictionary = ctx.get("dice_cache", {})
	for type_key in cache:
		for face in cache[type_key]:
			res.dice_rolls.append(int(face))
	return res


static func _merge_deferred(into: Dictionary, src: Dictionary) -> void:
	# Append event lists, take non-empty choose/rite, OR over/back flags.
	if src.has("events"):
		into["events"].append_array(src["events"])
	if src.has("choose") and not src["choose"].is_empty():
		into["choose"] = src["choose"]
	if src.has("rite") and int(src["rite"]) != 0:
		into["rite"] = src["rite"]
	if src.has("over") and bool(src["over"]):
		into["over"] = true
	if src.has("back_to_prev") and bool(src["back_to_prev"]):
		into["back_to_prev"] = true
	if src.has("logs"):
		into["logs"].append_array(src["logs"])
