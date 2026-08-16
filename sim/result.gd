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

const RuntimeOperationFilter = preload("res://sim/operation_filter.gd")

## Execute a result dictionary against the game state.
## Returns a Dictionary of deferred actions: {choose:..., events:[...], rite:id, over:bool, ...}.
static func execute(result: Dictionary, state, db, context: Dictionary = {}) -> Dictionary:
	var deferred := {
		"events": [], "choose": {}, "rite": 0, "over": false, "back_to_prev": false, "back_to_round_begin": false,
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
	if k in ["coin", "金币", "g.coin", "card", "choose", "all", "clean.rite", "event_on", "event_off", "rite", "over", "back_to_prev_round_end", "back_to_round_begin", "confirm", "loot", "prompt", "no_show", "option", "success", "failed", "delay", "no_prompt", "sleep"]:
		return true
	if k.begins_with("case:"):
		return true
	if k.begins_with("rebirth.s") and k.substr("rebirth.s".length()).is_valid_int():
		return true
	if k == "difficulty" or k == "magic_sudan" or k.begins_with("magic_sudan."):
		return true
	if k == "begin_guide" or k == "close_begin_guide" or k == "slide" or k == "change_desk_bg":
		return true
	if k.begins_with("table.change_card_name.") or k.begins_with("total.change_card_name.") \
			or k.begins_with("table.change_card_text.") or k.begins_with("total.change_card_text."):
		return true
	if _is_domain_equip_key(k) and (k.begins_with("table.") or k.begins_with("g.")):
		return true
	if k.begins_with("hand_pop") or k.begins_with("rite_pop") or k.begins_with("focus.") \
			or k.begins_with("close_") or k.begins_with("change_location_icon"):
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
	if _is_modify_rare_key(k) or _is_change_card_copy_key(k):
		return true
	if _is_equip_key(k) or _is_equip_slot_key(k):
		return true
	if k == "change_name":
		return true
	if _is_slot_tag_op(k):
		return true
	if (k.begins_with("table.") or k.begins_with("g.")) and _has_tag_op_after_dot(k):
		return true
	if _is_supported_filtered_tag_op(k, "total."):
		return true
	if _is_supported_filtered_tag_op(k, "sudan_pool."):
		return true
	if k == "enable_auto_gen_sudan_card":
		return true
	if k in ["delay_off", "steam_achievement", "debug", "error", "warn"]:
		return true
	var copy_slot := k.substr(5) if k.begins_with("copy.") else ""
	if copy_slot.begins_with("s") and copy_slot.substr(1).is_valid_int():
		return true
	if _is_bare_uprare_key(k) or _is_bare_tag_key(k):
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
		var granted_id := 0
		if val is Array:
			if not val.is_empty():
				granted_id = int(val[0])
		else:
			granted_id = int(val)
		if granted_id > 0:
			var granted_uid: int = state.add_card_to_hand(granted_id, db)
			# GenCard dispatches OnCardBorn after the card joins the player.
			# [SRC: GenCard.c @ Do (line 298) -> EventTriggerExtensions.OnCardBorn]
			if granted_uid > 0:
				state.trigger_events("card_born", {"card": granted_id, "card_uid": granted_uid})
		return
	# ChooseOperations: shuffle the nested operations and execute N of them
	# (default 1). This is a random settlement-text/branch pick, not a player
	# choice (player choices are `option`).
	# [SRC: ChooseOperations.c @ GetOperations (0x4f3830): copy + Shuffle +
	#       GetRange(0, N); Do (0x4f3750) executes in order; ctor (0x4f3a20)
	#       clamps N < 1 to 1]
	if (k == "choose" or k.begins_with("choose:")) and val is Dictionary and not val.is_empty():
		var pick_n := 1
		if k != "choose":
			var suffix := k.substr("choose:".length())
			if suffix.is_valid_int():
				pick_n = maxi(int(suffix), 1)
		var keys: Array = val.keys().duplicate()
		var rng = context.get("rng", null)
		if rng != null and rng.has_method("randi_range"):
			# Fisher-Yates with the settlement RNG keeps replays deterministic.
			for i in range(keys.size() - 1, 0, -1):
				var j: int = rng.randi_range(0, i)
				var tmp = keys[i]
				keys[i] = keys[j]
				keys[j] = tmp
		else:
			keys.shuffle()
		var take := mini(pick_n, keys.size())
		for i in take:
			var sub_key: String = str(keys[i])
			_apply_key(sub_key, val[sub_key], state, db, deferred, context)
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
	# CleanRite removes OTHER rite instances from the table by config id;
	# value 1 removes every rite except the currently settling one. Cards in
	# removed rites go with them; the settling rite is always skipped.
	# [SRC: CleanRite.c @ Do (RVA 0x4f3ae0): player.rites RemoveAll with the
	#       settling-rite exclusion (report 4 A1 — was inverted to card-clean)]
	if k == "clean.rite":
		var clean_target := 1
		if val is bool:
			clean_target = 1 if val else 0
		elif not (val is Dictionary or val is Array):
			clean_target = int(val)
		if state.has_method("remove_rite_instances_by_id"):
			var removed: int = state.remove_rite_instances_by_id(clean_target, int(state.active_rite_uid))
			if removed > 0:
				deferred.logs.append("clean.rite removed %d rite instance(s)" % removed)
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
	# Persistent runtime-card changes. These must run before the generic slot
	# tag parser because equip/equip_slot are relationships, not ordinary tags.
	if _is_modify_rare_key(k):
		_apply_modify_rare(k, val, state, db, context)
		return
	# rebirth.s<n>: reset the slotted card's life countdown to full. Active
	# Sultan cards restore the difficulty lifetime; ordinary vanishing cards
	# restart from life 0. (The original's second branch aligns an immortal
	# tag's life to card_vanishing - round; that tag name is unrecoverable
	# from metadata and no rebirth config targets it.)
	# [SRC: RebirthSudanCard.c @ Do (0x519d60): OperationFilter over the
	#       slotted cards; <Do>b__4_0 (0x51dec0): Card.set_life(0);
	#       GameController.c @ UpdateSudanLife (0x55aeb0) refresh]
	if k.begins_with("rebirth.s") and k.substr("rebirth.s".length()).is_valid_int():
		var rebirth_slot := int(k.substr("rebirth.s".length()))
		var rebirth_uid := int(context.get("rite_uid", state.active_rite_uid))
		for tc in state.cards_in_slot(rebirth_slot, rebirth_uid):
			var rebirth_instance = state.get_card_instance(int(tc.get("card_uid", 0)))
			if rebirth_instance == null:
				continue
			rebirth_instance.life = 0
			for asc in state.active_sudan_cards:
				if int(asc.card_uid) == int(rebirth_instance.uid):
					asc.days_left = int(state.difficulty_config.get("sudan_life_time", 7))
		return
	if _is_change_card_copy_key(k):
		_apply_change_card_copy(k, val, state, context)
		return
	if k == "change_name":
		_queue_change_name(val, state, db, deferred, context)
		return
	if _is_equip_key(k):
		_apply_equip(k, val, state, db, context)
		return
	if _is_equip_slot_key(k):
		_apply_equip_slot(k, val, state, db, context)
		return
	# Slot tag op: s<n>+/-<tag>  (ModifyTag).
	if _is_slot_tag_op(k):
		_apply_slot_tag(k, val, state, db, context)
		return
	if k.begins_with("table.clean."):
		_apply_table_clean(k, val, state, context)
		return
	# Scoped renames: table/total.change_card_name.<rite>_<seq>.<card_id>
	# sets the matching card's custom name (change_card_text its text); the
	# rite_seq infix only keeps repeated directives in one payload distinct.
	# [SRC: operations.json change_card_name/change_card_text families;
	#       ChangeCardName.c @ Do (report 5 A5)]
	if k.begins_with("table.change_card_name.") or k.begins_with("total.change_card_name.") \
			or k.begins_with("table.change_card_text.") or k.begins_with("total.change_card_text."):
		_apply_scoped_card_text(k, val, state, k.begins_with("total."))
		return
	# Table/g equip ops: table.<selector>(+|-|~)equip / g.<selector>...
	# [SRC: dump.cs:313833 "table\\.([^\\+\\-~]+)([\\+\\-~])equip" ->
	#       TableModifyEquip (same for g.)]
	if (k.begins_with("table.") or k.begins_with("g.")) and _is_domain_equip_key(k):
		_apply_domain_equip(k, val, state, db)
		return
	# Table/g tag ops: table.<x>+/-<tag>, g.<x>+/-<tag>.
	if k.begins_with("table.") or k.begins_with("g."):
		_apply_table_tag(k, val, state, db, context)
		return
	if _is_supported_filtered_tag_op(k, "total."):
		_apply_total_tag(k, val, state, db)
		return
	if _is_supported_filtered_tag_op(k, "sudan_pool."):
		_apply_sudan_pool_tag(k, val, state, db)
		return
	# Bare ModifyRare/ModifyTag: the original dispatches the same regex families
	# without a scope prefix against the operation-context cards. The contextual
	# card takes precedence; otherwise the current rite's placed cards.
	# [SRC: engine_spec/operations.json: "([^\.]+)\.uprare" -> ModifyRare;
	#       "(?!total)(?!sudan_pool)([^\+\-]+)([\+\-\=])(\b(?!equip\b).+)" -> ModifyTag]
	if _is_bare_uprare_key(k):
		_apply_bare_uprare(k, val, state, db, context)
		return
	if _is_bare_tag_key(k):
		_apply_bare_tag(k, val, state, db, context)
		return
	# copy.s<n>: CopyCard filters the context cards by the slot selector and
	# generates `value` new copies of each match.
	# [SRC: engine_spec/operations.json: "copy\.(.+)" -> CopyCard;
	#       decompiled/CopyCard.c @ ctor (RVA 0x4f54b0) builds the filter from
	#       the slot selector]
	if k.begins_with("copy.") and _is_slot_selector(k.substr(5)):
		_apply_copy_slot(k, val, state, db, context)
		return
	# delay_off: value 1 clears every delay op; explicit ids remove by id.
	# [SRC: decompiled/DelayOff.c @ Do (RVA 0x4f7eb0)]
	if k == "delay_off":
		_apply_delay_off(val, state, deferred)
		return
	# Platform/logging operations have no gameplay state in the clone.
	# [SRC: engine_spec/operations.json: steam_achievement -> SteamAchievement,
	#       debug/error/warn -> LogDebug/LogError/LogWarn]
	if k == "steam_achievement" or k == "debug" or k == "error" or k == "warn":
		deferred.logs.append("%s: %s" % [k, str(val)])
		return
	if k == "enable_auto_gen_sudan_card":
		# The original stores a disable flag, so the operation's value itself is
		# the public "automatic generation enabled" state in this clone.
		# [SRC: EnableAutoGenSudanCard.c @ Do (RVA 0x50ecc0); GameController
		# __c__DisplayClass141_0.c @ <Start>b__10 (RVA 0x56f780)]
		state.auto_gen_sudan_card = bool(val)
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
	# Mid-run difficulty switch: the original opens the difficulty panel and
	# applies the chosen index; the config value is that target index.
	# [SRC: SetDifficulty.c @ Do (0x51b5b0) -> ShowDifficulty + Then;
	#       GameState.apply_difficulty mirrors the apply callback]
	if k == "difficulty":
		if state != null and state.has_method("apply_difficulty"):
			state.apply_difficulty(int(val), db)
			deferred.logs.append("difficulty -> %d" % int(val))
		return
	# magic_sudan is a wizard-demo cue (ShowDrawSudan): it drives the tutorial
	# presentation, not the rules layer. No wizard host yet -> audited no-op.
	# [SRC: MagicSudan.c @ Do (0x515160) -> WizardController.ShowDrawSudan]
	if k == "magic_sudan" or k.begins_with("magic_sudan."):
		return
	# Beginner-guide family: `begin_guide` installs the on-screen directive,
	# `close_begin_guide` clears it; the remaining cues (focus/hand_pop/
	# rite_pop/slide/close_box/close_deadline/close_helpbtn/close_prestige/
	# close_story/change_desk_bg/change_location_icon) accumulate for the
	# overlay presentation only.
	# [SRC: BeginGuide.c / CloseBeginGuide.c (DSL ops);
	#       BeginGuideController.c @ ShowBeginGuide (0x526220)]
	if k == "begin_guide":
		if val is Dictionary:
			state.begin_guide = val.duplicate(true)
		return
	if k == "close_begin_guide":
		state.begin_guide = {}
		state.guide_cues.clear()
		return
	if k.begins_with("hand_pop") or k.begins_with("rite_pop") or k.begins_with("focus.") \
			or k == "slide" or k.begins_with("close_") \
			or k == "change_desk_bg" or k.begins_with("change_location_icon"):
		state.guide_cues.append({"key": k, "value": val})
		if state.guide_cues.size() > 32:
			state.guide_cues.remove_at(0)
		return
	# End / back.
	if k == "over":
		deferred.over = bool(val) if val is bool else true
		return
	if k == "back_to_prev_round_end":
		deferred.back_to_prev = true
		return
	# Back to the current round's beginning (retry today with yesterday's
	# settlements kept). [SRC: DoBackToRoundBegin.c @ Do; report 7 A1]
	if k == "back_to_round_begin":
		deferred.back_to_round_begin = true
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
	if k == "no_show" and val is Dictionary:
		# NoShowOperations hides the card-operation presentation, then starts
		# its nested AllOperations payload. [SRC: decompiled/NoShowOperations.c
		# @ PreDo (RVA 0x500410); dump.cs:312597-312612.]
		_merge_case(deferred, execute(val, state, db, context))
		return
	# case:opN reached via execute_choice: run the matched case subtree as a
	# nested result dict. This is the player's chosen branch from an option.
	if k.begins_with("case:") and val is Dictionary:
		var case_deferred := execute(val, state, db, context)
		# Merge the case's effects into the current deferred (in-place).
		_merge_case(deferred, case_deferred)
		return
	# success/failed are mutually exclusive branches keyed on last_op_status:
	# success runs when status != 1, failed when status == 1; whichever reads
	# it resets the status. The clone's `confirm` is a no-op, so status stays 0
	# and success runs until confirm UI writes real results.
	# [SRC: SuccessOperations.c @ Do (0x3a7930): != 1 then reset;
	#       FailedOperations.c @ Do (0x39d5a0): == 1 then reset;
	#       OperationContext.c @ SetLastOpState (0x3a0230)]
	if (k == "success" or k == "failed") and val is Dictionary:
		var status := int(deferred.get("last_op_status", 0))
		deferred["last_op_status"] = 0
		var should_run := (status != 1) if k == "success" else (status == 1)
		if should_run:
			var branch_deferred := execute(val, state, db, context)
			_merge_case(deferred, branch_deferred)
		return
	# Unhandled: log, don't crash.
	deferred.logs.append("UNHANDLED result key: %s=%s" % [k, str(val)])


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


static func _is_modify_rare_key(k: String) -> bool:
	if k.begins_with("s") and k.ends_with(".uprare"):
		return k.substr(1, k.find(".") - 1).is_valid_int()
	if (k.begins_with("table.") or k.begins_with("g.")) and k.ends_with(".uprare"):
		return RuntimeOperationFilter.supports_selector(k.get_slice(".", 1))
	return false


static func _is_change_card_copy_key(k: String) -> bool:
	if not (k.begins_with("change_card_name.") or k.begins_with("change_card_text.")):
		return false
	var parts := k.split(".", false)
	return parts.size() == 3 and str(parts[2]).begins_with("s") and str(parts[2]).substr(1).is_valid_int()


static func _is_equip_key(k: String) -> bool:
	if not k.begins_with("s"):
		return false
	for suffix in ["+equip", "-equip", "~equip"]:
		if k.ends_with(suffix):
			return k.substr(1, k.length() - suffix.length() - 1).is_valid_int()
	return false


static func _is_equip_slot_key(k: String) -> bool:
	if not k.begins_with("s"):
		return false
	for suffix in ["+equip_slot", "-equip_slot"]:
		if k.ends_with(suffix):
			return k.substr(1, k.length() - suffix.length() - 1).is_valid_int()
	return false


static func _is_slot_selector(selector: String) -> bool:
	return selector.begins_with("s") and selector.substr(1).is_valid_int()


## Bare `<selector>.uprare` with no s<n>/table./g. scope prefix.
static func _is_bare_uprare_key(k: String) -> bool:
	if not k.ends_with(".uprare") or k.begins_with("table.") or k.begins_with("g."):
		return false
	if k.begins_with("s") and _is_slot_selector(k.substr(0, k.find("."))):
		return false
	var selector := k.substr(0, k.length() - ".uprare".length())
	return not selector.is_empty() and RuntimeOperationFilter.supports_selector(selector)


## Bare `<selector><+|-|=><tag>` with no dot and no scope prefix. Slot ops,
## counters and event keys are all claimed by earlier branches, so anything
## left with an operator and a valid selector is a context ModifyTag.
static func _is_bare_tag_key(k: String) -> bool:
	if "." in k or ":" in k:
		return false
	var op_idx := maxi(k.rfind("+"), maxi(k.rfind("-"), k.rfind("=")))
	if op_idx < 1:
		return false
	var selector := k.substr(0, op_idx)
	var tag_name := k.substr(op_idx + 1)
	if tag_name == "equip" or tag_name.begins_with("equip_slot"):
		return false
	if _is_slot_selector(selector):
		return false
	return not selector.is_empty() and not tag_name.is_empty() \
		and RuntimeOperationFilter.supports_selector(selector)


## Target cards for a bare ModifyTag/ModifyRare: the contextual card wins;
## otherwise the current rite's placed cards (or, outside a rite, the surface
## cards), filtered through the selector.
static func _context_tag_targets(selector: String, state, db, context: Dictionary) -> Array[int]:
	var targets: Array[int] = []
	if state == null:
		return targets
	var rite_uid := int(context.get("rite_uid", state.active_rite_uid))
	var contextual_uid := int(context.get("card_uid", 0))
	var entries: Array = state.cards_in_slot_entries_for_rite(rite_uid) if rite_uid > 0 else state.surface_card_entries()
	for tc in entries:
		var uid := int(tc.get("card_uid", 0))
		if contextual_uid > 0:
			if uid == contextual_uid:
				targets.append(uid)
			continue
		if RuntimeOperationFilter.matches_card_data(int(tc.get("id", 0)), tc.get("tags", {}), db, selector):
			targets.append(uid)
	return targets


static func _apply_bare_uprare(k: String, val: Variant, state, db, context: Dictionary) -> void:
	var selector := k.substr(0, k.length() - ".uprare".length())
	for uid in _context_tag_targets(selector, state, db, context):
		state.modify_card_rarity(uid, int(val), db)


static func _apply_bare_tag(k: String, val: Variant, state, db, context: Dictionary) -> void:
	var op_idx := maxi(k.rfind("+"), maxi(k.rfind("-"), k.rfind("=")))
	if op_idx < 1:
		return
	var selector := k.substr(0, op_idx)
	var tag_name := k.substr(op_idx + 1)
	var op := TagSystem.op_from_char(k[op_idx])
	var amount := int(val)
	if amount == 0 and op != TagSystem.Op.SET:
		amount = 1
	var can_add := _tag_can_add(db, tag_name)
	for uid in _context_tag_targets(selector, state, db, context):
		var instance = state.get_card_instance(uid)
		if instance != null:
			TagSystem.apply(instance.tags, tag_name, op, amount, can_add)


static func _apply_copy_slot(k: String, val: Variant, state, db, context: Dictionary) -> void:
	# CopyCard generates fresh card copies per count unit. Whether the original
	# clones runtime tags onto the copy is not yet source-confirmed; this clone
	# creates a new instance from the card config, matching GenCard semantics.
	# [SRC: decompiled/CopyCard.__c__DisplayClass4_0.c @ <Do>b__0 (RVA 0x507430)]
	var selector := k.substr("copy.".length())
	var copies := maxi(int(val), 1)
	for uid in _slot_target_uids(selector, state, context):
		var instance = state.get_card_instance(uid)
		if instance == null:
			continue
		for i in copies:
			state.add_card_to_hand(instance.card_id, db)


static func _apply_delay_off(val: Variant, state, deferred: Dictionary) -> void:
	if state == null or not state.has_method("clear_delay_ops"):
		return
	var ids: Array = val if val is Array else [val]
	if ids.size() == 1 and int(ids[0]) == 1:
		state.clear_delay_ops()
		deferred.logs.append("delay_off: cleared all")
		return
	for raw_id in ids:
		if state.remove_delay_op(int(raw_id)):
			deferred.logs.append("delay_off: removed %d" % int(raw_id))


static func _apply_modify_rare(k: String, val: Variant, state, db, context: Dictionary) -> void:
	var targets: Array[int] = []
	if k.begins_with("s"):
		targets = _slot_target_uids(k.substr(0, k.find(".")), state, context)
	else:
		var selector := k.get_slice(".", 1)
		var contextual_uid := int(context.get("card_uid", 0))
		for instance in RuntimeOperationFilter.select_total(state, db, selector):
			if contextual_uid <= 0 or int(instance.uid) == contextual_uid:
				targets.append(int(instance.uid))
	for uid in targets:
		state.modify_card_rarity(uid, int(val), db)


static func _apply_change_card_copy(k: String, val: Variant, state, context: Dictionary) -> void:
	var parts := k.split(".", false)
	if parts.size() != 3:
		return
	for uid in _slot_target_uids(str(parts[2]), state, context):
		if str(parts[0]) == "change_card_name":
			state.set_card_custom_name(uid, str(val))
		else:
			state.set_card_custom_text(uid, str(val))


static func _queue_change_name(val: Variant, state, db, deferred: Dictionary, context: Dictionary) -> void:
	var card_id := int(val)
	var target_uid := int(context.get("card_uid", 0))
	if target_uid > 0:
		var contextual = state.get_card_instance(target_uid)
		if contextual == null or contextual.card_id != card_id:
			target_uid = 0
	var rite_uid := int(context.get("rite_uid", state.active_rite_uid))
	if target_uid <= 0 and rite_uid > 0:
		for entry in state.cards_in_slot_entries_for_rite(rite_uid):
			if int(entry.get("id", 0)) == card_id:
				target_uid = int(entry.get("card_uid", 0))
				break
	if target_uid <= 0:
		target_uid = state.card_uid_for(card_id, "hand")
	if target_uid <= 0:
		return
	var card: Dictionary = state.card_data_for(target_uid, db)
	var payload := {
		"card_uid": target_uid,
		"title": "为卡牌命名",
		"text": "为%s起一个新名字。" % str(card.get("name", "这张卡牌")),
		"initial_text": str(card.get("name", "")),
	}
	var rename_context := context.duplicate(true)
	rename_context["card_uid"] = target_uid
	rename_context["rite_uid"] = rite_uid
	_record_effect(deferred, "rename_card", payload, rename_context)


static func _apply_equip(k: String, val: Variant, state, db, context: Dictionary) -> void:
	var op_index := maxi(k.rfind("+equip"), maxi(k.rfind("-equip"), k.rfind("~equip")))
	if op_index < 0:
		return
	var selector := k.substr(0, op_index)
	var op := k[op_index]
	for host_uid in _slot_target_uids(selector, state, context):
		var host = state.get_card_instance(host_uid)
		if host == null:
			continue
		if op == "+":
			var equipment_id := int(val[0]) if val is Array and not val.is_empty() else int(val)
			var equipment = state.create_card_instance(equipment_id, db, "removed")
			if equipment != null:
				# Result ModifyEquip directly calls AddEquip after generating the
				# card; it does not run the interactive CanEquip replacement gate.
				# [SRC: decompiled/ModifyEquip.c @ HandleCard (RVA 0x516ab0)]
				state.attach_equipment(host_uid, equipment.uid, db, false, false)
			continue
		var equipped_snapshot: Array[int] = host.equipped_uids.duplicate()
		for equipment_uid in equipped_snapshot:
			var equipment = state.get_card_instance(int(equipment_uid))
			if equipment == null or not _equipment_matches(equipment, val, db):
				continue
			state.detach_equipment(host_uid, equipment.uid, op == "~")


static func _equipment_matches(equipment, selector_value: Variant, db) -> bool:
	var selectors: Array = selector_value if selector_value is Array else [selector_value]
	for raw_selector in selectors:
		var selector := str(raw_selector)
		if selector.is_valid_int() and equipment.card_id == selector.to_int():
			return true
		if RuntimeOperationFilter.matches_card_data(equipment.card_id, equipment.tags, db, selector):
			return true
	return false


static func _apply_equip_slot(k: String, val: Variant, state, db, context: Dictionary) -> void:
	var add := "+equip_slot" in k
	var suffix := "+equip_slot" if add else "-equip_slot"
	var selector := k.substr(0, k.length() - suffix.length())
	var values: Array = val if val is Array else [val]
	for uid in _slot_target_uids(selector, state, context):
		for slot in values:
			if add:
				state.add_card_equip_slot(uid, str(slot), db)
			else:
				state.remove_card_equip_slot(uid, str(slot), db)


static func _slot_target_uids(selector: String, state, context: Dictionary) -> Array[int]:
	var targets: Array[int] = []
	if not selector.begins_with("s") or not selector.substr(1).is_valid_int():
		return targets
	var rite_uid := int(context.get("rite_uid", state.active_rite_uid))
	for entry in state.cards_in_slot(selector.substr(1).to_int(), rite_uid):
		targets.append(int(entry.get("card_uid", 0)))
	return targets


static func _has_tag_op_after_dot(k: String) -> bool:
	var dot := k.find(".")
	if dot < 0:
		return false
	var rest := k.substr(dot + 1)
	return "+" in rest or "-" in rest or "=" in rest


static func _is_supported_filtered_tag_op(k: String, prefix: String) -> bool:
	if not k.begins_with(prefix):
		return false
	var rest := k.substr(prefix.length())
	var op_idx := maxi(rest.rfind("+"), maxi(rest.rfind("-"), rest.rfind("=")))
	if op_idx < 1:
		return false
	var tag_name := rest.substr(op_idx + 1)
	return tag_name != "" and tag_name != "equip" and RuntimeOperationFilter.supports_selector(rest.substr(0, op_idx))


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


static func _apply_total_tag(k: String, val: Variant, state, db) -> void:
	var rest := k.substr("total.".length())
	var op_idx := maxi(rest.rfind("+"), maxi(rest.rfind("-"), rest.rfind("=")))
	if op_idx < 1:
		return
	var op := TagSystem.op_from_char(rest[op_idx])
	var amount := int(val)
	if amount == 0 and op != TagSystem.Op.SET:
		amount = 1
	var tag_name := rest.substr(op_idx + 1)
	for instance in RuntimeOperationFilter.select_total(state, db, rest.substr(0, op_idx)):
		TagSystem.apply(instance.tags, tag_name, op, amount, _tag_can_add(db, tag_name))


static func _apply_sudan_pool_tag(k: String, val: Variant, state, db) -> void:
	var rest := k.substr("sudan_pool.".length())
	var op_idx := maxi(rest.rfind("+"), maxi(rest.rfind("-"), rest.rfind("=")))
	if op_idx < 1:
		return
	var selector := rest.substr(0, op_idx)
	var tag_name := rest.substr(op_idx + 1)
	var op := TagSystem.op_from_char(rest[op_idx])
	var amount := int(val)
	if amount == 0 and op != TagSystem.Op.SET:
		amount = 1
	var seen_card_ids: Dictionary = {}
	for card_id in state.sudan_deck:
		var pool_card_id := int(card_id)
		if seen_card_ids.has(pool_card_id):
			continue
		seen_card_ids[pool_card_id] = true
		var tags: Dictionary = state.sudan_pool_tags.get(pool_card_id, db.get_card(pool_card_id).get("tag", {}).duplicate(true)).duplicate(true)
		if RuntimeOperationFilter.matches_card_data(pool_card_id, tags, db, selector):
			TagSystem.apply(tags, tag_name, op, amount, _tag_can_add(db, tag_name))
			state.sudan_pool_tags[pool_card_id] = tags


## Look up a tag's can_add flag from config (default true if not found).
## [SRC: CardExtensions.c ConvertToAddOrSub reads tag config offset 0x40]
static func _tag_can_add(db, tag_name: String) -> bool:
	if db == null:
		return true
	var code: String = db.tag_name_to_code.get(tag_name, "") if db.get("tag_name_to_code") != null else ""
	if code != "" and db.get("tags_by_code") != null and db.tags_by_code.has(code):
		return int(db.tags_by_code[code].get("can_add", 1)) != 0
	return true


static func _is_domain_equip_key(k: String) -> bool:
	return k.ends_with("+equip") or k.ends_with("-equip") or k.ends_with("~equip")


## table.<selector>(+|-|~)equip and g.<selector>... — equip operations over a
## whole domain instead of one rite slot. `+` grants and attaches the value
## card to every matched host; `-`/`~` detach matching equipment (the tilde
## recovers it to the hand like the slot form).
## [SRC: dump.cs:313833-313834 "table/g\.<selector>([\+\-~])equip";
##       ModifyEquip.c @ HandleCard (0x516ab0) attach path]
static func _apply_domain_equip(k: String, val: Variant, state, db) -> void:
	var dot := k.find(".")
	var op_index := maxi(k.rfind("+equip"), maxi(k.rfind("-equip"), k.rfind("~equip")))
	if dot < 0 or op_index <= dot:
		return
	var scope := k.substr(0, dot)
	var selector := k.substr(dot + 1, op_index - dot - 1)
	var op := k[op_index]
	var hosts: Array[int] = []
	if scope == "g":
		for inst in RuntimeOperationFilter.select_total(state, db, selector):
			hosts.append(int(inst.uid))
	else:
		for tc in state.surface_card_entries():
			var inst = state.get_card_instance(int(tc.get("card_uid", 0)))
			if inst == null:
				continue
			if not RuntimeOperationFilter.matches_card_data(int(inst.card_id), inst.tags, db, selector):
				continue
			hosts.append(int(inst.uid))
	for host_uid in hosts:
		var host = state.get_card_instance(host_uid)
		if host == null:
			continue
		if op == "+":
			var equipment_id := int(val[0]) if val is Array and not val.is_empty() else int(val)
			var equipment = state.create_card_instance(equipment_id, db, "removed")
			if equipment != null:
				state.attach_equipment(host_uid, equipment.uid, db, false, false)
			continue
		var equipped_snapshot: Array[int] = host.equipped_uids.duplicate()
		for equipment_uid in equipped_snapshot:
			var equipment = state.get_card_instance(int(equipment_uid))
			if equipment == null or not _equipment_matches(equipment, val, db):
				continue
			state.detach_equipment(host_uid, equipment.uid, op == "~")


## table/total.change_card_name|text.<rite>_<seq>.<card_id> — apply the value
## as the custom name/text of the matching card in the domain.
static func _apply_scoped_card_text(k: String, val: Variant, state, whole_domain: bool) -> void:
	var last_dot := k.rfind(".")
	if last_dot < 0:
		return
	var card_id := k.substr(last_dot + 1)
	if not card_id.is_valid_int():
		return
	var want_id := card_id.to_int()
	var is_name := k.find("change_card_name") >= 0
	var new_value := str(val).strip_edges()
	for uid in state.card_instances.keys():
		var inst = state.get_card_instance(int(uid))
		if inst == null or inst.card_id != want_id:
			continue
		if not whole_domain and inst.zone != "hand" and inst.zone != "slot" and inst.zone != "sudan":
			continue
		if is_name:
			state.set_card_custom_name(int(uid), new_value)
		else:
			state.set_card_custom_text(int(uid), new_value)
		return
