## Applies deferred rite/result effects to the live world.
## Keeps UI surfaces thin: RiteView, Methinks, and desktop prompts all send
## their deferred effects here instead of duplicating event/choice/loot wiring.
class_name DeferredEffects
extends RefCounted

static func apply(deferred: Dictionary, state, db, rng) -> void:
	for event_id in deferred.get("events", []):
		if state.has_method("queue_event"):
			state.queue_event(int(event_id))
	for prompt in deferred.get("prompts", []):
		if prompt is Dictionary and state.has_method("queue_prompt"):
			state.queue_prompt(prompt)
	var choose: Dictionary = deferred.get("choose", {})
	if not choose.is_empty() and state.has_method("queue_choice_prompt"):
		# Two formats: a plain {key: value} choices dict (legacy choose), or a
		# wrapped {choices: {...}, title, text} from an option payload.
		if choose.has("choices"):
			state.queue_choice_prompt(choose["choices"], str(choose.get("title", "选择")), str(choose.get("text", "")))
		else:
			state.queue_choice_prompt(choose)
	var next_rite := int(deferred.get("rite", 0))
	if next_rite > 0 and state.has_method("add_available_rite"):
		state.add_available_rite(next_rite)
	for loot_ref in deferred.get("loots", []):
		_apply_loot_ref(loot_ref, state, db, rng)


static func execute_choice(choice_key: String, choice_value: Variant, state, db, rng) -> void:
	if choice_key == "":
		return
	var result := {choice_key: choice_value}
	var deferred := ResultExec.execute(result, state, db)
	apply(deferred, state, db, rng)


## Execute an event's settlement payloads and apply their deferred effects.
## Real events nest their payload at `settlement[].action` (no result/condition
## per entry — the condition is top-level). Mirrors RiteResolver's per-entry
## pattern. Returns the merged deferred dict so callers can inspect flags like
## `over`. Falls back to top-level result/action for synthetic/test events.
static func execute_event(event: Dictionary, state, db, rng) -> Dictionary:
	if event.is_empty():
		return {}
	# Gate on the event's top-level condition (events have no per-entry conditions).
	var cond: Dictionary = event.get("condition", {})
	if not cond.is_empty():
		var ctx := {"db": db, "state": state, "rng": rng, "rite_state": {}, "attr_slots": ["s1", "s2"]}
		if not ConditionEval.evaluate(cond, ctx):
			return {}
	var merged := {
		"events": [], "choose": {}, "rite": 0, "over": false, "back_to_prev": false,
		"logs": [], "clean_slots": [], "clean_card_ids": [], "clean_rite": false,
		"prompts": [], "loots": [],
	}
	var settlements: Array = event.get("settlement", [])
	if not settlements.is_empty():
		for entry in settlements:
			if not (entry is Dictionary):
				continue
			var payload: Dictionary = entry.get("action", {})
			if payload.is_empty():
				continue
			var deferred := ResultExec.execute(payload, state, db)
			_merge(merged, deferred)
	else:
		# Fallback for synthetic/test events using top-level result/action.
		for key in ["result", "action"]:
			var payload_alt: Dictionary = event.get(key, {})
			if payload_alt.is_empty():
				continue
			var deferred := ResultExec.execute(payload_alt, state, db)
			_merge(merged, deferred)
	apply(merged, state, db, rng)
	if state != null and state.has_method("complete_event"):
		state.complete_event(int(event.get("id", 0)), bool(event.get("is_replay", false)))
	return merged


static func _merge(into: Dictionary, src: Dictionary) -> void:
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


static func _apply_loot_ref(loot_ref: Variant, state, db, rng) -> void:
	if loot_ref is Array:
		for nested in loot_ref:
			_apply_loot_ref(nested, state, db, rng)
		return
	var loot_id := int(loot_ref)
	var loot: Dictionary = db.get_loot(loot_id) if db != null and db.has_method("get_loot") else {}
	if loot.is_empty():
		if state.has_method("queue_prompt"):
			state.queue_prompt({"id": "loot.%d" % loot_id, "text": "获得掉落 %d" % loot_id})
		return
	var owned := _owned_ids(state)
	# condition_ok: gate items by their condition field before weighting.
	# [SRC: GenLoot.c: items filtered by Where condition before weighting]
	var ctx := {"db": db, "state": state, "rng": rng, "rite_state": {}, "attr_slots": ["s1", "s2"]}
	var condition_ok := Callable(func(item):
		if not (item is Dictionary):
			return true
		var cond: Dictionary = item.get("condition", {})
		if cond.is_empty():
			return true
		return ConditionEval.evaluate(cond, ctx))
	var generated: Array = LootSystem.generate(rng, loot, owned, condition_ok)
	for id in generated:
		_apply_loot_item(int(id), state, db, rng)


static func _apply_loot_item(id: int, state, db, rng) -> void:
	if id <= 0:
		return
	if db != null and not db.get_card(id).is_empty():
		state.add_card_to_hand(id)
		if state.has_method("queue_prompt"):
			var card: Dictionary = db.get_card(id)
			state.queue_prompt({"id": "card.%d" % id, "text": "获得卡牌：%s" % str(card.get("name", id))})
		return
	if db != null and not db.get_rite(id).is_empty():
		if state.has_method("add_available_rite"):
			state.add_available_rite(id)
		if state.has_method("queue_prompt"):
			var rite: Dictionary = db.get_rite(id)
			state.queue_prompt({"id": "rite.%d" % id, "text": "出现新的仪式：%s" % str(rite.get("name", id))})
		return
	if db != null and not db.get_event(id).is_empty():
		if state.has_method("enable_event"):
			state.enable_event(id, db, true)
		return
	if db != null and not db.get_loot(id).is_empty():
		_apply_loot_ref(id, state, db, rng)
		return
	if state.has_method("queue_prompt"):
		state.queue_prompt({"id": "loot_item.%d" % id, "text": "获得内容 %d" % id})


static func _owned_ids(state) -> Array:
	var ids: Array = []
	for cid in state.hand:
		ids.append(int(cid))
	for rid in state.available_rites:
		ids.append(int(rid))
	for eid in state.event_queue:
		ids.append(int(eid))
	for asc in state.active_sudan_cards:
		ids.append(int(asc.card_id))
	return ids
