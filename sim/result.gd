## Result DSL executor.
## Dispatch table transcribed from dump.cs [Operation(...)] attributes (lines 312xxx-316xxx).
## Handles the result keys that matter for the core loop:
##   coin / 金币 (GenCoin: gold-card stack)     [spec sec 10.2]
##   counter+/-/=<id>, global_counter+/-/=<id>
##   card <id>, choose{...}, clean.s<n>, clean.rite
##   s<n>+/-<tag>, s<n>+回收 (ModifyTag)
##   event_on <id>, event_off, rite <id>
##   back_to_prev_round_end, over, confirm
## Returns a list of "effects" the UI/sim can apply (some are immediate state
## mutations; choose/event_on/rite produce deferred actions).
class_name ResultExec
extends RefCounted

## Execute a result dictionary against the game state.
## Returns a Dictionary of deferred actions: {choose:..., events:[...], rite:id, over:bool, ...}.
static func execute(result: Dictionary, state, db, context: Dictionary = {}) -> Dictionary:
	var deferred := {
		"events": [], "choose": {}, "rite": 0, "over": false, "back_to_prev": false,
		"logs": [], "clean_slots": [], "clean_card_ids": [], "clean_rite": false,
		"prompts": [], "loots": [], "delays": [], "sleeps": [], "ordered_effects": [],
	}
	# Option branching: if the payload has an `option` key, convert it to a
	# choose prompt and stash the case:opN subtrees as choices. The remaining
	# keys are skipped — only the player's chosen case executes (via
	# execute_choice), matching the original's last_op_tag state machine.
	if result.has("option"):
		_apply_option(result, deferred, context)
		return deferred
	for key in result:
		var val = result[key]
		_apply_key(key, val, state, db, deferred, context)
	return deferred


static func is_supported_key(key: String) -> bool:
	var k := key.strip_edges()
	if k in ["coin", "金币", "g.coin", "card", "choose", "all", "clean.rite", "event_on", "event_off", "rite", "over", "back_to_prev_round_end", "confirm", "loot", "prompt", "no_show", "option", "success", "failed", "delay", "no_prompt", "sleep"]:
		return true
	if k.begins_with("case:"):
		return true
	if k.begins_with("loot."):
		return true
	if k.begins_with("think_pop.") or k.begins_with("think_pop_gamepad.") or k.begins_with("think_pop_normal.") or k.begins_with("pop."):
		return true
	if k.begins_with("counter") or k.begins_with("global_counter"):
		return true
	if k.begins_with("clean."):
		return true
	if k.begins_with("table.clean."):
		return true
	if _is_slot_tag_op(k):
		return true
	if (k.begins_with("table.") or k.begins_with("g.")) and _has_tag_op_after_dot(k):
		return true
	return false


static func _apply_key(key: String, val: Variant, state, db, deferred: Dictionary, context: Dictionary = {}) -> void:
	var k := key.strip_edges()
	# Gold (GenCoin): coin / 金币 / g.coin.
	if k == "coin" or k == "金币" or k == "g.coin":
		state.add_coin(int(val))
		deferred.logs.append("coin +%d" % int(val))
		return
	# Counters.
	if k.begins_with("counter") or k.begins_with("global_counter"):
		_apply_counter(k, val, state)
		return
	# Card grant.
	if k == "card":
		if val is Array:
			if not val.is_empty():
				state.add_card_to_hand(int(val[0]), db)
		else:
			state.add_card_to_hand(int(val), db)
		return
	# Choose (pop options).
	if k == "choose" and val is Dictionary:
		deferred.choose = _prepare_choose(val)
		_record_effect(deferred, "choice", {"choices": deferred.choose}, context)
		return
	if k == "all" and val is Dictionary:
		# AllOperations starts every nested operation in source order.
		# [SRC: decompiled/AllOperations.c @ Do (RVA 0x4ee520)]
		for nested_key in val:
			_apply_key(str(nested_key), val[nested_key], state, db, deferred, context)
		return
	if k == "delay" and val is Dictionary:
		var delay_effect := {"payload": val.duplicate(true), "context": _queue_context(context)}
		deferred.delays.append(delay_effect)
		_record_effect(deferred, "delay", val, context)
		return
	if k == "no_prompt" and val is Dictionary:
		# NoPrompt runs its nested operation immediately and only suppresses the
		# source UI wrapper. The clone has no separate result-popup operation, so
		# execute the nested payload through the same state path.
		# [SRC: decompiled/NoPromptOperations.c @ Do (RVA 0x5001f0)]
		_merge_case(deferred, execute(val, state, db, context))
		return
	if k == "sleep":
		# SleepOperation is a UI promise wait, not a calendar delay.
		# [SRC: decompiled/SleepOperation.c @ Do (RVA 0x51b9f0)]
		var sleep_effect := {"seconds": float(val), "context": _queue_context(context)}
		deferred.sleeps.append(sleep_effect)
		_record_effect(deferred, "sleep", {"seconds": float(val)}, context)
		return
	# Clean slot / clean rite.
	if k == "clean.rite":
		state.clear_rite_cards(int(state.active_rite_uid))
		deferred.clean_rite = true
		return
	if k.begins_with("clean."):
		var slot := _clean_slot_from_key(k)
		if slot > 0:
			state.clear_slot(slot, int(state.active_rite_uid))
			deferred.clean_slots.append(slot)
			return
		var card_id := _clean_card_id_from_key(k, db)
		if card_id > 0:
			if state.has_method("remove_table_card_id"):
				state.remove_table_card_id(card_id, int(state.active_rite_uid))
			deferred.clean_card_ids.append(card_id)
		elif _clean_all_from_key(k):
			state.clear_rite_cards(int(state.active_rite_uid))
			deferred.clean_rite = true
		return
	# Slot tag op: s<n>+/-<tag>  (ModifyTag).
	if _is_slot_tag_op(k):
		_apply_slot_tag(k, val, state, db, context)
		return
	if k.begins_with("table.clean."):
		_apply_table_clean(k, val, state, context)
		return
	# Table/g tag ops: table.<x>+/-<tag>, g.<x>+/-<tag>.
	if k.begins_with("table.") or k.begins_with("g."):
		_apply_table_tag(k, val, state, db, context)
		return
	# Events.
	if k == "event_on":
		if state != null and state.has_method("enable_event"):
			for event_id in _event_ids(val):
				state.enable_event(event_id, db, false)
				var event: Dictionary = db.get_event(event_id) if db != null else {}
				if bool(event.get("start_trigger", false)):
					_record_effect(deferred, "event", {"id": event_id}, context)
		return
	if k == "event_off":
		if state != null and state.has_method("disable_event"):
			for event_id in _event_ids(val):
				state.disable_event(event_id)
		return
	# Rite jump.
	if k == "rite":
		deferred.rite = int(val)
		_record_effect(deferred, "rite", {"id": int(val)}, context)
		return
	# End / back.
	if k == "over":
		deferred.over = bool(val) if val is bool else true
		return
	if k == "back_to_prev_round_end":
		deferred.back_to_prev = true
		return
	if k == "confirm":
		return
	if k == "prompt" and val is Dictionary:
		deferred.prompts.append(val.duplicate(true))
		_record_effect(deferred, "prompt", val, context)
		return
	if k.begins_with("think_pop.") or k.begins_with("think_pop_gamepad.") or k.begins_with("think_pop_normal.") or k.begins_with("pop."):
		var prompt := {"id": k, "text": str(val)}
		deferred.prompts.append(prompt)
		_record_effect(deferred, "prompt", prompt, context)
		return
	if k == "loot":
		deferred.loots.append(val)
		_record_effect(deferred, "loot", {"value": val}, context)
		return
	if k.begins_with("loot."):
		deferred.loots.append(val)
		_record_effect(deferred, "loot", {"value": val}, context)
		return
	if k == "no_show":
		return
	# case:opN reached via execute_choice: run the matched case subtree as a
	# nested result dict. This is the player's chosen branch from an option.
	if k.begins_with("case:") and val is Dictionary:
		var case_deferred := execute(val, state, db, context)
		# Merge the case's effects into the current deferred (in-place).
		_merge_case(deferred, case_deferred)
		return
	# success/failed: terminal branch markers (usually carry event_off).
	# Execute their subtree like a case; for confirm both branches are treated
	# the same initially (the tutorial's success/failed converge).
	if (k == "success" or k == "failed") and val is Dictionary:
		var branch_deferred := execute(val, state, db, context)
		_merge_case(deferred, branch_deferred)
		return
	# Unhandled: log, don't crash.
	deferred.logs.append("UNHANDLED result key: %s=%v" % [k, val])


static func _event_ids(value: Variant) -> Array[int]:
	var ids: Array[int] = []
	if value is Array:
		for entry in value:
			ids.append(int(entry))
	else:
		ids.append(int(value))
	return ids


## Merge a case/branch subtree's deferred into the parent deferred.
static func _merge_case(into: Dictionary, src: Dictionary) -> void:
	if src.has("events"):
		into["events"].append_array(src["events"])
	if src.has("choose") and not src["choose"].is_empty():
		into["choose"] = src["choose"]
	if src.has("rite") and int(src["rite"]) != 0:
		into["rite"] = src["rite"]
	if src.has("over") and bool(src["over"]):
		into["over"] = true
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
	if src.has("clean_slots"):
		into["clean_slots"].append_array(src["clean_slots"])
	if src.has("clean_card_ids"):
		into["clean_card_ids"].append_array(src["clean_card_ids"])
	if src.has("clean_rite") and bool(src["clean_rite"]):
		into["clean_rite"] = true
	if src.has("logs"):
		into["logs"].append_array(src["logs"])


## Convert an `option` payload into a choose prompt. The option's items become
## choices keyed by their case tag (op1/op2/...), and each case:opN sibling in
## the same action dict becomes the choice's executable value (a result dict
## run via execute_choice when the player picks it).
## `case:def` remains an execution fallback; it is not a player-facing option.
## [SRC: Option.c @ Do (shows UI, resolves with tag);
##       CaseOperations.c @ Do (matches last_op_tag, or 'def' wildcard
##       when last_op_status - 2 >= 3, runs case subtree, resets state),
##       RVA 0x518ac0 / 0x399570, dump.cs:315655 / 394112]
static func _apply_option(action: Dictionary, deferred: Dictionary, context: Dictionary = {}) -> void:
	var opt: Dictionary = action.get("option", {})
	if opt.is_empty():
		return
	var items: Array = opt.get("items", [])
	var choices: Dictionary = {}
	for item in items:
		if not (item is Dictionary):
			continue
		var tag := str(item.get("tag", ""))
		if tag == "":
			continue
		# Keep the player-facing label separate from the executable case subtree.
		var case_key := "case:" + tag
		choices[case_key] = {
			"text": str(item.get("text", tag)),
			"value": action.get(case_key, {}),
		}
	# Stash as a choose prompt; DeferredEffects.apply routes it to the UI via
	# queue_choice_prompt. The option text is the body narration; the title is
	# a short label (the prompt id or "选择").
	deferred.choose = {
		"choices": choices,
		"title": str(opt.get("id", "选择")),
		"text": str(opt.get("text", "")),
		"context": _queue_context(context),
	}
	_record_effect(deferred, "choice", deferred.choose, context)


static func _prepare_choose(choices: Dictionary) -> Dictionary:
	var prepared := {}
	for key in choices:
		if str(key) == "all" and choices[key] is Dictionary:
			var lines: Array[String] = []
			for nested_value in choices[key].values():
				lines.append(str(nested_value))
			prepared[key] = {"text": "\n".join(lines), "value": choices[key]}
		else:
			prepared[key] = choices[key]
	return prepared


static func _record_effect(deferred: Dictionary, kind: String, payload: Dictionary, context: Dictionary = {}) -> void:
	deferred.ordered_effects.append({
		"kind": kind,
		"payload": payload.duplicate(true),
		"context": _queue_context(context),
	})


static func _queue_context(context: Dictionary) -> Dictionary:
	# Execution helpers are injected into evaluation contexts but cannot be
	# serialized or used after a UI boundary. Keep the trigger data only.
	var persisted := {}
	for key in context:
		if str(key) in ["state", "db", "rng", "rite_state", "attr_slots", "dice_cache", "gold_dice_map", "dice_types_seen", "gold_dice_used"]:
			continue
		persisted[key] = context[key]
	return persisted


static func _apply_counter(k: String, val: Variant, state) -> void:
	var parsed := CounterSystem.parse_key(k)
	if parsed.is_empty():
		return
	var delta := int(val)
	if parsed.op == CounterSystem.Op.SET:
		if parsed.global:
			state.set_global_counter(parsed.id, delta)
		else:
			state.set_counter(parsed.id, delta)
	elif parsed.op == CounterSystem.Op.ADD:
		if parsed.global:
			state.add_global_counter(parsed.id, delta)
		else:
			state.add_counter(parsed.id, delta)
	elif parsed.op == CounterSystem.Op.SUB:
		if parsed.global:
			state.sub_global_counter(parsed.id, delta)
		else:
			state.sub_counter(parsed.id, delta)


static func _clean_slot_from_key(k: String) -> int:
	var rest := k.substr("clean.".length())
	# "s4" -> 4 ; bare (no s) -> -1 (all slots).
	if rest.begins_with("s"):
		return rest.substr(1).to_int()
	return -1


static func _clean_card_id_from_key(k: String, db) -> int:
	var rest := k.substr("clean.".length())
	if rest.begins_with("s") or rest == "rite":
		return 0
	if db != null and db.has_method("resolve_card_id"):
		return int(db.resolve_card_id(rest))
	if rest.is_valid_int():
		return rest.to_int()
	return 0


static func _clean_all_from_key(k: String) -> bool:
	var rest := k.substr("clean.".length())
	return rest.is_empty() or rest == "0"


static func _is_slot_tag_op(k: String) -> bool:
	# s<n>[+\-=]<tag> OR s<n>+回收. Must start with s and contain an op char.
	if not k.begins_with("s"):
		return false
	return ("+" in k or "-" in k or "=" in k) and not k.begins_with("sudan")


static func _has_tag_op_after_dot(k: String) -> bool:
	var dot := k.find(".")
	if dot < 0:
		return false
	var rest := k.substr(dot + 1)
	return "+" in rest or "-" in rest or "=" in rest


static func _apply_slot_tag(k: String, val: Variant, state, db, context: Dictionary = {}) -> void:
	# Parse "s4+回收" -> slot=4, op=+, tag=回收.
	var op_idx := -1
	var op_char := ""
	for i in range(1, k.length()):
		if k[i] == "+" or k[i] == "-" or k[i] == "=":
			op_idx = i
			op_char = k[i]
			break
	if op_idx < 0:
		return
	var slot_num := k.substr(1, op_idx - 1).to_int()
	var tag_name := k.substr(op_idx + 1)
	var op := TagSystem.op_from_char(op_char)
	var amount := int(val)
	if amount == 0 and op != TagSystem.Op.SET:
		amount = 1
	var can_add := _tag_can_add(db, tag_name)
	var rite_uid := int(context.get("rite_uid", state.active_rite_uid))
	for tc in state.cards_in_slot(slot_num, rite_uid):
		var instance = state.get_card_instance(int(tc.get("card_uid", 0)))
		if instance != null:
			TagSystem.apply(instance.tags, tag_name, op, amount, can_add)


static func _apply_table_clean(k: String, val: Variant, state, context: Dictionary = {}) -> void:
	var card_id_text := k.substr("table.clean.".length())
	if not card_id_text.is_valid_int() or state == null or not state.has_method("clean_table_card_instances"):
		return
	var rite_uid := int(context.get("rite_uid", state.active_rite_uid))
	var card_uid := int(context.get("card_uid", 0))
	var cleaned: Array = state.clean_table_card_instances(card_id_text.to_int(), rite_uid, card_uid, int(val))
	for entry in cleaned:
		var clean_context := context.duplicate(true)
		clean_context["card_uid"] = int(entry.get("card_uid", 0))
		clean_context["card"] = int(entry.get("id", 0))
		clean_context["rite_uid"] = int(entry.get("rite_uid", rite_uid))
		state.trigger_events("card_clean", clean_context)


static func _apply_table_tag(k: String, val: Variant, state, db, context: Dictionary = {}) -> void:
	# table.<card-or-tag>+/-<tag> or g.<...>. An event card_uid takes
	# precedence, so two same-id Sultan instances cannot cross-modify each other.
	var rest := k.substr(k.find(".") + 1)
	var op_idx := -1
	var op_char := ""
	for i in rest.length():
		if rest[i] == "+" or rest[i] == "-" or rest[i] == "=":
			op_idx = i
			op_char = rest[i]
			break
	if op_idx < 0:
		return
	var tag_name := rest.substr(op_idx + 1)
	var selector := rest.substr(0, op_idx)
	var op := TagSystem.op_from_char(op_char)
	var amount := int(val)
	if amount == 0 and op != TagSystem.Op.SET:
		amount = 1
	var can_add := _tag_can_add(db, tag_name)
	var target_uid := int(context.get("card_uid", 0))
	var rite_uid := int(context.get("rite_uid", state.active_rite_uid))
	for tc in state.surface_card_entries():
		var instance = state.get_card_instance(int(tc.get("card_uid", 0)))
		if instance == null:
			continue
		if target_uid > 0 and instance.uid != target_uid:
			continue
		if target_uid <= 0 and selector.is_valid_int() and instance.card_id != selector.to_int():
			continue
		if rite_uid > 0 and instance.rite_uid != rite_uid:
			continue
		if target_uid <= 0 and not selector.is_valid_int() and int(instance.tags.get(selector, 0)) == 0:
			continue
		TagSystem.apply(instance.tags, tag_name, op, amount, can_add)


## Look up a tag's can_add flag from config (default true if not found).
## [SRC: CardExtensions.c ConvertToAddOrSub reads tag config offset 0x40]
static func _tag_can_add(db, tag_name: String) -> bool:
	if db == null:
		return true
	var code: String = db.tag_name_to_code.get(tag_name, "") if db.get("tag_name_to_code") != null else ""
	if code != "" and db.get("tags_by_code") != null and db.tags_by_code.has(code):
		return int(db.tags_by_code[code].get("can_add", 1)) != 0
	return true
