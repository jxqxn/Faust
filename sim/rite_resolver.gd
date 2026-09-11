## Rite settlement pipeline.
## verified-conclusions + spec sec 10.1, re-confirmed vs
## decompiled/RiteResultPanelController.c:
##   settlement_prior  -> FIRST matching entry wins (mutually exclusive)
##   settlement        -> FIRST matching entry wins (mutually exclusive)
##   settlement_extre  -> ALL matching entries execute (non-exclusive)
## Selection enqueues entries without executing them. All finalResults run
## before finalOperations. [SRC: EnqueueSettlement 0x5a2d10;
## DisplayClass56_0 b__4 0x5b3a50 / b__7 0x5b45c0;
## dump.cs:325472-325474.]
class_name RiteResolver
extends RefCounted

## Result of resolving a rite.
class RiteResult:
	var prior_log: Array = []      # executed prior entries
	var normal_entry: Dictionary = {} # the single matched normal entry (may be empty)
	var extre_log: Array = []      # executed extre entries
	var deferred: Dictionary = {}  # merged deferred actions
	var dice_rolls: Array = []     # the dice values rolled (for UI)
	var successes: int = 0         # successes from the r1 check
	var dice_types_seen: Array = []
	var settlements: Array = []
	var entry_contexts: Array = []
	func _init() -> void:
		deferred = {
			"events": [], "choose": {}, "rite": 0, "over": false, "back_to_prev": false, "back_to_round_begin": false,
			"logs": [], "clean_slots": [], "clean_card_ids": [], "clean_rite": false,
			"prompts": [], "loots": [], "delays": [], "sleeps": [], "ordered_effects": [],
		}


## Resolve a rite end-to-end.
## ctx must contain: db, state, rng, rite_state{s1..s4->card_id}, rite_id.
static func select_settlements(rite: Dictionary, ctx: Dictionary, gold_dice_used: Variant = 0) -> RiteResult:
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
			res.settlements.append(entry)
			break
	# A matched prior resolves true and bypasses the normal+extra branch.
	# [SRC: DisplayClass77_0 b__7 0x5b6120 -> Resolve(true);
	# DisplayClass56_0 b__1 0x5b34e0 only calls DoNormalSettlement when false.]
	var normal_candidates: Array = rite.get("settlement", []) if res.prior_log.is_empty() else []
	for entry in normal_candidates:
		if ConditionEval.evaluate(entry.get("condition", {}), ctx):
			res.normal_entry = entry
			res.settlements.append(entry)
			break
	# 3. settlement_extre: all matches execute.
	var extra_candidates: Array = rite.get("settlement_extre", []) if res.prior_log.is_empty() else []
	for entry in extra_candidates:
		if ConditionEval.evaluate(entry.get("condition", {}), ctx):
			res.extre_log.append(entry)
			res.settlements.append(entry)
	for _entry in res.settlements:
		res.entry_contexts.append({})
	# CardNode.post_rite is collected as extra settlements BEFORE finalResults,
	# including when prior matched. DoPostRite is a later equipment-age cleanup,
	# not the executor of this configuration array.
	# [SRC: DisplayClass56_0 b__2 0x5b3620; CollectCardEquipExtraSettlement
	# 0x5a17c0; CardNode.post_rite +0x88, dump.cs:389793.]
	var state = ctx.get("state")
	var db = ctx.get("db")
	if state != null and db != null:
		for slot in ctx.get("slot_entries", []):
			_collect_card_settlements(int(slot.get("card_uid", 0)), ctx, res, [])
	res.dice_types_seen = ctx.get("dice_types_seen", []).duplicate()
	var cache: Dictionary = ctx.get("dice_cache", {})
	for type_key in cache:
		for face in cache[type_key]:
			res.dice_rolls.append(int(face))
	return res


static func _collect_card_settlements(uid: int, ctx: Dictionary, res: RiteResult, ancestors: Array) -> void:
	if uid <= 0 or uid in ancestors:
		return
	var instance = ctx.state.get_card_instance(uid)
	if instance == null or instance.zone == "removed":
		return
	var own := {"card_uid": uid, "self_card_uid": uid, "acting_card_uid": uid,
		"acting_card_id": int(instance.card_id), "acting_card": ctx.state.card_data_for(uid, ctx.db)}
	var probe := ctx.duplicate()
	probe.merge(own, true)
	for entry in ctx.db.get_card(instance.card_id).get("post_rite", []):
		if ConditionEval.evaluate(entry.get("condition", {}), probe):
			res.extre_log.append(entry)
			res.settlements.append(entry)
			res.entry_contexts.append(own)
	var path := ancestors.duplicate()
	path.append(uid)
	for equipped_uid in instance.equipped_uids:
		_collect_card_settlements(int(equipped_uid), ctx, res, path)


## Synchronous adapter for callers not yet hosted by the interactive sequence.
## Selection must finish before any final result changes its condition inputs.
static func resolve(rite: Dictionary, ctx: Dictionary, gold_dice_used: Variant = 0) -> RiteResult:
	var res := select_settlements(rite, ctx, gold_dice_used)
	for phase in ["result", "action"]:
		for i in res.settlements.size():
			var context := ctx.duplicate()
			context.merge(res.entry_contexts[i], true)
			_merge_deferred(res.deferred, ResultExec.execute(res.settlements[i].get(phase, {}), ctx.get("state"), ctx.get("db"), context))
	return res


## Execute a selected phase through the shared serial operation host. A choice
## suspends the remaining entries, rather than letting their mutations leak.
## [SRC: DisplayClass56_0 b__4/b__7 -> ListExtensions.DoSequence;
## DisplayClass56_3 b__13 0x5b4f20 -> OperationsExtensions.Start.]
static func execute_phase(res: RiteResult, phase: String, ctx: Dictionary) -> Dictionary:
	var payloads: Array = []
	for entry in res.settlements:
		payloads.append(entry.get(phase, {}))
	return OperationsSequence.start(payloads, ctx.state, ctx.db, ctx.rng, ctx)


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
	if src.get("back_to_round_begin", false):
		into["back_to_round_begin"] = true
	if src.has("card_ops"):
		if not into.has("card_ops"):
			into["card_ops"] = []
		into.card_ops.append_array(src.card_ops)
	if src.has("logs"):
		into["logs"].append_array(src["logs"])
	if src.has("clean_slots"):
		into["clean_slots"].append_array(src["clean_slots"])
	if src.has("clean_card_ids"):
		into["clean_card_ids"].append_array(src["clean_card_ids"])
	if src.has("clean_rite") and bool(src["clean_rite"]):
		into["clean_rite"] = true
	if src.has("prompts"):
		into["prompts"].append_array(src["prompts"])
	if src.has("loots"):
		into["loots"].append_array(src["loots"])
	if src.has("delays"):
		into["delays"].append_array(src["delays"])
	if src.has("sleeps"):
		into["sleeps"].append_array(src["sleeps"])
	if src.has("ordered_effects"):
		into["ordered_effects"].append_array(src["ordered_effects"])
