## ThinkController's SlotPop -> OnCardLocked -> shared Settlement lifecycle.
## [SRC: ThinkController.ProcessPop 0x5c38b0 / OnCardLocked 0x5c2d10;
## dump.cs:327529 SlotPop, Player.ithink_card +0x80.]
class_name MethinksEngine
extends RefCounted

static func process_card(card_or_uid: int, source: String, state, db, rng, presentation: bool = false) -> Dictionary:
	var result := {"accepted": false, "message": "", "deferred": {}}
	if not state.think_session.is_empty() or not state.pending_operations.is_empty():
		return result
	var think_id := int(db.init_config.get("think_id", 5000002))
	var definition: Dictionary = db.get_rite(think_id)
	var uid: int = state._resolve_card_uid(card_or_uid)
	if definition.is_empty() or not ((source == "hand" and state.has_card_in_hand(uid)) or (source == "active_sudan" and state.is_active_sudan_card(uid))):
		return result
	var card: Dictionary = state.card_data_for(uid, db)
	# ProcessPop calls InitRite, including its adsorption and only_rites writes.
	# [SRC: ThinkController.ProcessPop 0x5c38b0 -> PlayerExtensions.InitRite
	# 0x38e140; dump.cs RiteNode.cards_slot +0xB0 / Player.only_rites.]
	var instance = state.get_rite_instance(state.add_available_rite(think_id, db, rng))
	if instance == null:
		return result
	state.remove_card_from_hand(uid)
	state.add_card_to_slot(uid, 1, db, instance.uid)
	state.ithink_card_uid = uid
	var ctx := {"state": state, "db": db, "rng": rng,
		"rite_id": think_id, "rite_uid": instance.uid,
		"rite_state": {"s1": int(card.id)}, "attr_slots": ["s1"],
		"slot_entries": [{"slot": "s1", "card_id": int(card.id), "card_uid": uid, "tags": card.get("tag", {}), "is_enemy": false}],
		"focus_card_uid": uid, "focus_card_id": int(card.id),
	}
	ctx = state.with_player_actor_context(ctx, db)
	state.think_session = {"uid": instance.uid, "stage": "pops", "presentation": presentation,
		"context": ResultExec._queue_context(ctx), "deferred": ResultExec.execute({}, state, db)}
	# SlotPop checks the dropped card and collects every match before execution.
	var pop_ctx := ctx.duplicate()
	pop_ctx["acting_card"] = card
	pop_ctx["acting_card_id"] = int(card.id)
	pop_ctx["acting_card_uid"] = uid
	var payloads: Array = []
	var slots: Dictionary = definition.get("cards_slot", {})
	if not slots.is_empty():
		for pop in slots.values()[0].get("pops", []):
			if ConditionEval.evaluate(pop.get("condition", {}), pop_ctx):
				payloads.append(pop.get("action", {}))
	# ProcessPop explicitly starts FAILED, unlike normal operation contexts.
	# [SRC: ThinkController.ProcessPop 0x5c38b0 SetLastOpState(1);
	# dump.cs:394463 OperationContext.LastOpStatus.FAILED = 1.]
	OperationsSequence.start(payloads, state, db, rng, ctx, 1)
	var session: Dictionary = state.think_session
	pump(state, db, rng)
	result.accepted = true
	result.deferred = session.deferred
	return result

static func pump(state, db, rng, card_locked: bool = false) -> void:
	if state.think_session.is_empty() or not state.pending_operations.is_empty():
		return
	var session: Dictionary = state.think_session
	if session.stage == "pops":
		session.stage = "wait_lock"
	if session.stage == "wait_lock":
		if bool(session.presentation) and not card_locked:
			return
		session.stage = "settlement"
		var instance = state.get_rite_instance(int(session.uid))
		if instance != null:
			var context: Dictionary = session.context.duplicate(true)
			context.merge({"state": state, "db": db, "rng": rng}, true)
			var selected := RiteResolver.select_settlements(db.get_rite(instance.id), context)
			var job := RiteSettlement.begin(instance.uid, selected, context, state, db, rng)
			session.deferred = job.deferred
	if session.stage == "settlement":
		RiteSettlement.pump(state, db, rng)
		if state.rite_settlements.has(str(session.uid)) or not state.pending_operations.is_empty():
			return
		# [SRC: ThinkController.<OnCardLocked>b__24_0 0x5c3ec0.]
		state.ithink_card_uid = 0
		state.think_session = {}
