## Host for the source finalResults -> return cards -> finalOperations ->
## RemoveRite sequence. The UI owns dice/text decisions, never a player rollback.
## [SRC: RiteResultPanelController.EnqueueSettlement 0x5a2d10;
## DisplayClass56_0 b__4 0x5b3a50, b__5 0x5b3e20, b__7 0x5b45c0,
## b__8 0x5b4850; dump.cs:325472-325474.]
class_name RiteSettlement
extends RefCounted

## Manual confirmation resets life after recording start_life, then awaits
## OnRiteStart -> OnRiteBegin. Opening the panel does neither.
## [SRC: RitePanelController.OnConfirm 0x58f1c0; DisplayClass34_0
## b__1 0x5a06a0, b__2 0x5a0700, b__3 0x5a0980.]
static func confirm_start(uid: int, state) -> void:
	var instance = state.get_rite_instance(uid)
	if instance == null or state.rite_confirmations.has(str(uid)):
		return
	instance.life = 0
	state.rite_confirmations[str(uid)] = 0
	pump_confirmations(state)

static func pump_confirmations(state) -> void:
	if not state.pending_operations.is_empty():
		return
	for key in state.rite_confirmations.keys():
		var instance = state.get_rite_instance(int(key))
		if instance == null:
			state.rite_confirmations.erase(key)
			continue
		while int(state.rite_confirmations[key]) < 2:
			var phase := int(state.rite_confirmations[key])
			state.rite_confirmations[key] = phase + 1
			state.trigger_events("rite_start" if phase == 0 else "rite_begin", {"rite": instance.id})
			if not state.pending_operations.is_empty():
				return
		state.rite_confirmations.erase(key)

static func begin(uid: int, selected, context: Dictionary, state, db, rng) -> Dictionary:
	var key := str(uid)
	if state.rite_settlements.has(key):
		return state.rite_settlements[key]
	var instance = state.get_rite_instance(uid)
	var rite_id := int(context.get("rite_id", 0))
	if rite_id <= 0 and instance != null:
		rite_id = int(instance.id)
	if instance == null:
		return {}
	var job := {
		"uid": uid, "rite_id": rite_id, "phase": "results",
		"entries_json": JSON.stringify(selected.settlements, "", false),
		"entry_index": 0,
		"entry_contexts": selected.entry_contexts.duplicate(true),
		"context": ResultExec._queue_context(context),
		"table": state.cards_in_slot_entries_for_rite(uid).duplicate(true),
		"deferred": ResultExec.execute({}, state, db),
	}
	state.rite_settlements[key] = job
	pump(state, db, rng)
	return job

## Dead has the same result/return/action order but no result presentation,
## rite_end or final_pin. Conditions are collected AFTER OnRiteClean completes.
## [SRC: RiteExtensions.Dead 0x501460; DisplayClass0_0 b__0 0x505130,
## b__2 0x505780, b__1 0x505630; dump.cs:312039-312078.]
static func expire(uid: int, state, db, rng) -> void:
	var key := str(uid)
	if state.rite_settlements.has(key):
		return
	var instance = state.get_rite_instance(uid)
	if instance == null:
		return
	state.rite_settlements[key] = {
		"uid": uid, "kind": "timeout", "phase": "timeout_selection",
		"entry_index": 0, "entry_contexts": [],
		"context": {}, "table": [], "deferred": ResultExec.execute({}, state, db),
	}
	# UpdateSingleRite records the death before entering Dead, even if it waits.
	# [SRC: GameController.UpdateSingleRite 0x55ab10, NoteRiteDead call.]
	state.add_note(2, instance.id, uid)
	state.trigger_events("rite_clean", {"rite": instance.id})
	pump(state, db, rng)

static func _select_timeout(job: Dictionary, instance, state, db, rng) -> void:
	var definition: Dictionary = db.get_rite(instance.id)
	var context := {"state": state, "db": db, "rng": rng,
		"rite_id": instance.id, "rite_uid": instance.uid,
		"slot_entries": state.slot_entries_for_rite(definition, instance.uid)}
	var entries: Array = []
	for entry in definition.get("waiting_round_end_action", []):
		if ConditionEval.evaluate(entry.get("condition", {}), context):
			entries.append(entry)
	job.entries_json = JSON.stringify(entries, "", false)
	job.context = ResultExec._queue_context(context)
	job.table = state.cards_in_slot_entries_for_rite(instance.uid).duplicate(true)
	job.phase = "results"

static func _run_phase(job: Dictionary, phase: String, state, db, rng) -> void:
	var entries: Array = JSON.parse_string(job.entries_json) if job.has("entries_json") else job.entries
	while int(job.get("entry_index", 0)) < entries.size():
		var index := int(job.get("entry_index", 0))
		job.entry_index = index + 1
		var context: Dictionary = job.context.duplicate(true)
		var contexts: Array = job.get("entry_contexts", [])
		if index < contexts.size():
			context.merge(contexts[index], true)
		context["settlement_job"] = str(job.uid)
		# Each source entry starts FAILED with an empty tag. An option tag from
		# one settlement cannot select a case in another settlement.
		# [SRC: DisplayClass56_3 b__13 0x5b4f20 and 56_5 b__15 0x5b5070:
		# SetLastOpState(1); dump.cs:394463 FAILED = 1. Dead uses a new context.]
		var initial_status := 0 if job.get("kind", "settlement") == "timeout" else 1
		OperationsSequence.start([entries[index].get(phase, {})], state, db, rng, context, initial_status)
		if not state.pending_operations.is_empty() or state.over_pending:
			return

static func record(context: Dictionary, deferred: Dictionary, state) -> void:
	var key := str(context.get("settlement_job", ""))
	if state.rite_settlements.has(key):
		var job: Dictionary = state.rite_settlements[key]
		RiteResolver._merge_deferred(job.get("deferred", {}), deferred)

static func pump(state, db, rng) -> void:
	if not state.pending_operations.is_empty():
		return
	for key in state.rite_settlements.keys():
		var job: Dictionary = state.rite_settlements[key]
		if state.over_pending:
			job.deferred.over = true
			job.phase = "done"
			state.rite_settlements.erase(key)
			continue
		var instance = state.get_rite_instance(int(job.uid))
		if instance == null and job.phase not in ["post_lives", "rite_end", "done"]:
			state.rite_settlements.erase(key)
			continue
		if job.phase == "timeout_selection":
			_select_timeout(job, instance, state, db, rng)
		if job.phase == "results":
			_run_phase(job, "result", state, db, rng)
			if not state.pending_operations.is_empty():
				return
			if state.over_pending:
				return
			job.returned_slots = state.cards_in_slot_entries_for_rite(int(job.uid)).duplicate(true)
			job.phase = "return_cards"
		if job.phase == "return_cards":
			if job.get("kind", "settlement") == "timeout":
				# Dead uses ReturnCards, not normal Settlement b__5.
				state.return_rite_cards(int(job.uid), db)
			else:
				_return_normal_cards(job, state, db)
				if not state.pending_operations.is_empty() or state.over_pending:
					return
			if job.get("kind", "settlement") != "timeout":
				# [SRC: Settlement b__6 0x5b44b0 precedes finalOperations b__7.]
				state.add_note(3, instance.id, instance.uid)
				if state.once_new_rites_is_show.has(instance.id):
					state.once_new_rites_is_show[instance.id] = true
			job.phase = "actions"
			job.entry_index = 0
		if job.phase == "actions":
			_run_phase(job, "action", state, db, rng)
			if not state.pending_operations.is_empty():
				return
			if state.over_pending:
				return
		if job.phase == "actions":
			job.phase = "finalizing"
			if job.get("kind", "settlement") == "timeout":
				state.remove_rite_instance(instance.uid)
				job.phase = "done"
			else:
				# Consumed objects remain in Rite.cards through finalOperations,
				# but are never returned to Player.cards by b__5.
				for raw_uid in job.get("consumed_cards", []):
					var consumed = state.get_card_instance(int(raw_uid))
					if consumed != null and consumed.zone == "slot" and consumed.rite_uid == int(job.uid):
						state.remove_card_instance_from_play(consumed.uid, false)
				RoundLoop.finalize_rite_settlement(instance, job.deferred, state, db, job.table, rng)
				job.phase = "post_lives"
		if job.phase == "post_lives":
			_post_lives(job, state, db, rng)
			if not state.pending_operations.is_empty():
				return
			job.phase = "rite_end"
		if job.phase == "rite_end":
			job.phase = "done"
			if not state.over_pending:
				state.trigger_events("rite_end", {"rite": int(job.rite_id)})
		if job.phase == "done":
			state.rite_settlements.erase(key)
			if not state.pending_operations.is_empty():
				return


## Normal settlement first returns all survivors, then dispatches the queued
## OnCardClean calls serially. Unlike Dead/ReturnCards, owned consumables without
## recovery stay out of the hand. Snapshot the decision before events mutate tags.
## [SRC: DisplayClass56_0.<Settlement>b__5 0x5b3e20;
## DisplayClass56_4.b__14 0x5b5010; dump.cs:324962/325044;
## stringliteral 0x259A5A0 consumable, 0x2580360 own, 0x2586BD0 recovery.]
static func _return_normal_cards(job: Dictionary, state, db) -> void:
	if not job.has("consumed_cards"):
		job.consumed_cards = []
		job.clean_cursor = 0
		for entry in job.returned_slots:
			var card = state.get_card_instance(int(entry.get("card_uid", 0)))
			if card == null or card.zone == "removed":
				continue
			var tags: Dictionary = state.effective_card_tags(card.uid, db)
			var consumable: String = db.tag_code_to_name.get("consumable", "consumable")
			var own: String = db.tag_code_to_name.get("own", "own")
			var recovery: String = db.tag_code_to_name.get("recovery", "recovery")
			if int(tags.get(consumable, 0)) > 0 and int(tags.get(own, 0)) > 0 and int(tags.get(recovery, 0)) <= 0:
				job.consumed_cards.append(card.uid)
				continue
			# recovery is non-additive: RemoveTag removes its instance override.
			# It is invisible; this is not a ModifyTag operation-card animation.
			# RemoveTag 0x382e40 is not the additive SUB helper: absent
			# non-additive tags stay absent; an existing override is erased.
			if card.tags.has(recovery):
				card.tags.erase(recovery)
			elif db.get_card(card.card_id).get("tag", {}).has(recovery):
				card.tags[recovery] = -1
			state.validate_tag_attributes(card.uid, recovery, db)
			if state.is_active_sudan_card(card.uid):
				if card.uid not in state.player_card_order:
					state.player_card_order.append(card.uid)
				state._unlink_slot_instance(card)
				card.zone = "sudan"
				card.rite_uid = 0
				card.slot_key = ""
			else:
				state.add_card_to_hand(card.uid)
	while int(job.clean_cursor) < job.consumed_cards.size():
		var uid := int(job.consumed_cards[int(job.clean_cursor)])
		job.clean_cursor = int(job.clean_cursor) + 1
		var card = state.get_card_instance(uid)
		if card != null:
			state.trigger_events("card_clean", {"card": card.card_id, "card_uid": uid})
		if not state.pending_operations.is_empty() or state.over_pending:
			return


## OnClose checks returned cards again without increasing life: shelter
## suppresses daily removal, not the post-rite lifetime check. Equipment
## expires before its host; vanish operations can suspend the continuation.
## [SRC: RiteResultPanelController.OnClose 0x5a3ae0; CardExtensions.DoPostRite
## 0x4f0d70; DisplayClass2_0 b__0 0x506010; DisplayClass1_1 b__0 0x505a60.]
static func _post_lives(job: Dictionary, state, db, rng) -> void:
	if not job.has("post_cards"):
		job.post_cards = []
		for entry in job.table:
			var card = state.get_card_instance(int(entry.get("card_uid", 0)))
			if card == null or card.zone == "removed":
				continue
			for equipment in card.equipped_uids:
				job.post_cards.append(int(equipment))
			job.post_cards.append(card.uid)
	while not job.post_cards.is_empty():
		var uid := int(job.post_cards.pop_front())
		var card = state.get_card_instance(uid)
		if card == null or card.zone == "removed":
			continue
		var definition: Dictionary = db.get_card(card.card_id)
		var lifetime := int(definition.get("card_vanishing", 0))
		if lifetime < 1 or card.life < lifetime:
			continue
		var is_sudan: bool = state.is_active_sudan_card(uid)
		state.remove_card_instance_from_play(uid)
		if is_sudan and not state.round_transition.is_empty():
			state.round_transition.expired.append(card.card_id)
		OperationsSequence.start([definition.get("vanish", {})], state, db, rng,
			{"card_uid": uid, "self_card_uid": uid, "settlement_job": str(job.uid)})
		if not state.pending_operations.is_empty() or state.over_pending:
			return
