## Applies deferred rite/result effects to the live world.
## Keeps UI surfaces thin: RiteView, Methinks, and desktop prompts all send
## their deferred effects here instead of duplicating event/choice/loot wiring.
class_name DeferredEffects
extends RefCounted

static func apply(deferred: Dictionary, state, db, rng) -> void:
	var ordered_effects: Array = deferred.get("ordered_effects", [])
	if not ordered_effects.is_empty():
		for effect in ordered_effects:
			if effect is Dictionary:
				_apply_ordered_effect(effect, state, db, rng)
		return
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
			state.queue_choice_prompt(
				choose["choices"],
				str(choose.get("title", "选择")),
				str(choose.get("text", "")),
				choose.get("context", {}) if choose.get("context", {}) is Dictionary else {}
			)
		else:
			state.queue_choice_prompt(choose)
	for delay_entry in deferred.get("delays", []):
		if not (delay_entry is Dictionary) or not state.has_method("schedule_delay"):
			continue
		var payload: Dictionary = delay_entry.get("payload", {}) if delay_entry.get("payload", {}) is Dictionary else {}
		var context: Dictionary = delay_entry.get("context", {}) if delay_entry.get("context", {}) is Dictionary else {}
		state.schedule_delay(payload, context)
	for sleep_entry in deferred.get("sleeps", []):
		if not (sleep_entry is Dictionary) or not state.has_method("queue_operation"):
			continue
		var sleep_context: Dictionary = sleep_entry.get("context", {}) if sleep_entry.get("context", {}) is Dictionary else {}
		state.queue_operation("sleep", "sleep", {"seconds": float(sleep_entry.get("seconds", 0.0))}, sleep_context)
	var next_rite := int(deferred.get("rite", 0))
	if next_rite > 0 and state.has_method("add_available_rite"):
		_add_rite_and_note(next_rite, state, db, rng)
	for loot_ref in deferred.get("loots", []):
		_apply_loot_ref(loot_ref, state, db, rng)
	# Rollback requests execute at the end of the deferred batch: the current
	# settlement's effects land first, then the snapshot restores the world.
	# [SRC: DoBackToPrevRoundEnd.c @ Do (0x4f89a0) calls OnPrevRound;
	#       DoBackToRoundBegin.c @ Do; report 7 A1]
	if bool(deferred.get("back_to_prev", false)):
		RoundLoop.back_to_prev_round_end(state, db)
	if bool(deferred.get("back_to_round_begin", false)):
		RoundLoop.back_to_round_begin(state, db)


static func _apply_ordered_effect(effect: Dictionary, state, db, rng) -> void:
	var kind := str(effect.get("kind", ""))
	var payload: Dictionary = effect.get("payload", {}) if effect.get("payload", {}) is Dictionary else {}
	var context: Dictionary = effect.get("context", {}) if effect.get("context", {}) is Dictionary else {}
	match kind:
		"event":
			state.queue_event(int(payload.get("id", 0)), context)
		"prompt":
			var prompt := payload.duplicate(true)
			if not prompt.has("context"):
				prompt["context"] = context
			state.queue_prompt(prompt)
		"choice":
			var choices: Dictionary = payload.get("choices", payload) if payload.get("choices", payload) is Dictionary else {}
			state.queue_choice_prompt(
				choices,
				str(payload.get("title", "选择")),
				str(payload.get("text", "")),
				context
			)
		"delay":
			state.schedule_delay(payload, context)
		"sleep":
			state.queue_operation("sleep", "sleep", {"seconds": float(payload.get("seconds", 0.0))}, context)
		"rename_card":
			state.queue_operation(
				"rename_card",
				"rename.%d" % int(context.get("card_uid", payload.get("card_uid", 0))),
				payload,
				context
			)
		"rite":
			_add_rite_and_note(int(payload.get("id", 0)), state, db, rng)
		"loot":
			_apply_loot_ref(payload.get("value", 0), state, db, rng)


## Create the rite instance, then journal the creation (type 1) with the
## instance's id and uid like StartRite's chain.
## [SRC: StartRite.c L120-133 -> NoteRiteStart (0x38ec70) -> AddNote type 1]
static func _add_rite_and_note(rite_id: int, state, db, rng) -> void:
	if not state.has_method("add_available_rite"):
		return
	var new_rite_uid: int = state.add_available_rite(rite_id, db, rng)
	if new_rite_uid > 0 and state.has_method("add_note"):
		var new_rite = state.get_rite_instance(new_rite_uid)
		if new_rite != null:
			state.add_note(1, new_rite.id, new_rite.uid)


static func execute_choice(choice_key: String, choice_value: Variant, state, db, rng, context: Dictionary = {}) -> void:
	if choice_key == "":
		return
	# Confirm dialogs only record which button the player pressed; the
	# branches were selected during settlement execution.
	# [SRC: Confirm.c @ Do (0x4f4e30) writes SetLastOpState]
	if choice_key == "confirm_ok" or choice_key == "confirm_cancel":
		if state != null:
			state.last_confirm_cancelled = choice_key == "confirm_cancel"
		return
	# Difficulty picks apply the chosen narrator.
	# [SRC: SetDifficulty.c @ Do (0x51b5b0) Then-apply callback]
	if choice_key.begins_with("diff_") and choice_key.substr(5).is_valid_int():
		if state != null and state.has_method("apply_difficulty"):
			state.apply_difficulty(int(choice_key.substr(5)), db)
		return
	var result := {choice_key: choice_value}
	var deferred := ResultExec.execute(result, state, db, context)
	apply(deferred, state, db, rng)


## Execute an event's settlement payloads and apply their deferred effects.
## Real events nest their payload at `settlement[].action` (no result/condition
## per entry — the condition is top-level). Mirrors RiteResolver's per-entry
## pattern. Returns the merged deferred dict so callers can inspect flags like
## `over`. Falls back to top-level result/action for synthetic/test events.
static func execute_event(event: Dictionary, state, db, rng, trigger_ctx: Dictionary = {}) -> Dictionary:
	if event.is_empty():
		return {}
	# Gate on the event's top-level condition (events have no per-entry conditions).
	var cond: Dictionary = event.get("condition", {})
	if not cond.is_empty():
		var ctx := trigger_ctx.duplicate(true)
		ctx["db"] = db
		ctx["state"] = state
		ctx["rng"] = rng
		if not ctx.has("rite_state"):
			ctx["rite_state"] = {}
		if not ctx.has("attr_slots"):
			ctx["attr_slots"] = ["s1", "s2"]
		if not ConditionEval.evaluate(cond, ctx):
			return {}
	var merged := {
		"events": [], "choose": {}, "rite": 0, "over": false, "back_to_prev": false, "back_to_round_begin": false,
		"logs": [], "clean_slots": [], "clean_card_ids": [], "clean_rite": false,
		"prompts": [], "loots": [], "delays": [], "sleeps": [], "ordered_effects": [],
	}
	var settlements: Array = event.get("settlement", [])
	if not settlements.is_empty():
		for entry in settlements:
			if not (entry is Dictionary):
				continue
			var payload: Dictionary = entry.get("action", {})
			if payload.is_empty():
				continue
			var deferred := ResultExec.execute(payload, state, db, trigger_ctx)
			_merge(merged, deferred)
	else:
		# Fallback for synthetic/test events using top-level result/action.
		for key in ["result", "action"]:
			var payload_alt: Dictionary = event.get(key, {})
			if payload_alt.is_empty():
				continue
			var deferred := ResultExec.execute(payload_alt, state, db, trigger_ctx)
			_merge(merged, deferred)
	apply(merged, state, db, rng)
	if state != null and state.has_method("complete_event"):
		state.complete_event(int(event.get("id", 0)), bool(event.get("is_replay", false)))
	return merged


## Execute each due DelayOp once at the Next Day boundary. `delay` carries
## operation metadata (`id`, `round`) plus the actual payload to run later.
static func execute_due_delays(state, db, rng) -> Array[Dictionary]:
	var executed: Array[Dictionary] = []
	if state == null or not state.has_method("take_due_delayed_operations"):
		return executed
	for delayed in state.take_due_delayed_operations():
		var payload: Dictionary = delayed.get("payload", {}) if delayed.get("payload", {}) is Dictionary else {}
		var context: Dictionary = delayed.get("context", {}) if delayed.get("context", {}) is Dictionary else {}
		payload.erase("id")
		payload.erase("round")
		if payload.is_empty():
			continue
		var deferred := ResultExec.execute(payload, state, db, context)
		apply(deferred, state, db, rng)
		executed.append(delayed)
	return executed


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
	if src.has("back_to_round_begin") and bool(src["back_to_round_begin"]):
		into["back_to_round_begin"] = true
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
	# Type-3 loot reads Player.only_cards / Player.only_rites, not current
	# ownership. A consumed unique card remains excluded on later draws.
	# [SRC: GenLoot.c @ ExcludeAlreadyHave (0x511610), IsCardExists (0x511d20),
	# IsRiteExists (0x511e20)]
	var owned := _only_generated_ids(state)
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
		state.add_card_to_hand(id, db)
		if state.has_method("queue_prompt"):
			var card: Dictionary = db.get_card(id)
			state.queue_prompt({"id": "card.%d" % id, "text": "获得卡牌：%s" % str(card.get("name", id))})
		return
	if db != null and not db.get_rite(id).is_empty():
		var rite_uid := 0
		if state.has_method("add_available_rite"):
			rite_uid = int(state.add_available_rite(id, db, rng))
		if rite_uid > 0 and state.has_method("queue_prompt"):
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


static func _only_generated_ids(state) -> Array:
	var ids: Array = []
	for raw_id in state.only_cards:
		ids.append(int(raw_id))
	for raw_id in state.only_rites:
		ids.append(int(raw_id))
	return ids


## Non-mutating CanLoot predicate. It mirrors the original's existence checks
## for only-new loot while applying item conditions before considering a
## candidate. It deliberately does not draw RNG or grant anything.
static func can_generate_loot(loot_id: int, ctx: Dictionary) -> bool:
	var db = ctx.get("db")
	var state = ctx.get("state")
	if db == null or state == null:
		return false
	var loot: Dictionary = db.get_loot(loot_id) if db.has_method("get_loot") else {}
	if loot.is_empty():
		return false
	var owned := {}
	for raw_id in state.only_cards:
		owned[int(raw_id)] = true
	for raw_id in state.only_rites:
		owned[int(raw_id)] = true
	for item in loot.get("item", []):
		if not (item is Dictionary):
			continue
		var condition: Dictionary = item.get("condition", {})
		if not condition.is_empty() and not ConditionEval.evaluate(condition, ctx):
			continue
		var item_id := int(item.get("id", 0))
		if item_id <= 0:
			continue
		if int(loot.get("type", 2)) == 3 and owned.has(item_id):
			continue
		return true
	return false
