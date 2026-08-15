## Desktop "I think" processor.
## The original routes the selected card to ThinkController.OnDrop, which then
## sends GameEventSender.IThink instead of opening a rite panel.
## [SRC: GameController.c @ DoIThink (RVA 0x54e880);
##       ThinkController.c @ GameEventSender__IThink call;
##       GameEventSender.c @ IThink (RVA 0x4429a0)]
class_name MethinksEngine
extends RefCounted

static func process_card(card_or_uid: int, source: String, state, db, rng) -> Dictionary:
	var result := {"accepted": false, "message": "", "deferred": {}}
	var think_id := int(db.init_config.get("think_id", 5000002))
	var rite: Dictionary = db.get_rite(think_id)
	if rite.is_empty():
		result.message = "俺寻思还没有配置。"
		return result
	var card_uid = state._resolve_card_uid(card_or_uid) if state.has_method("_resolve_card_uid") else card_or_uid
	var card: Dictionary = state.card_data_for(card_uid, db) if state.has_method("card_data_for") else db.get_card(card_or_uid)
	var card_id := int(card.get("id", 0))
	if card.is_empty() and not state.is_active_sudan_card(card_uid):
		result.message = "这张牌暂时不能寻思。"
		return result

	var removed_from_hand := false
	if source == "hand" and state.has_card_in_hand(card_uid):
		removed_from_hand = state.remove_card_from_hand(card_uid)
	state.remove_card_from_slot(card_uid)
	state.add_card_to_slot(card_uid, 1, db)
	var ctx := {
		"db": db,
		"state": state,
		"rng": rng,
		"rite_state": {"s1": card_id},
		"attr_slots": ["s1"],
		"rite_id": think_id,
		"focus_card_uid": card_uid,
		"focus_card_id": card_id,
		"slot_entries": [{
			"slot": "s1", "card_id": card_id, "card_uid": card_uid,
			"tags": card.get("tag", {}), "is_enemy": false,
		}],
	}
	if state.has_method("with_player_actor_context"):
		ctx = state.with_player_actor_context(ctx, db)
	# Think settles EVERY satisfied branch of the think rite — an async
	# multi-branch flow in the original, unlike the rite panel's first-match
	# settlement. [SRC: ThinkController.c @ ProcessPop (0x5c38b0) L488-529;
	#       OnDrop (0x5c3050) L206-253; report 1 A7 — GameEventSender.IThink
	#       (0x4429a0) is PostHog telemetry only, not the rules path]
	ctx["gold_dice_map"] = {"r1": 0, "f": 0}
	var deferred := {
		"events": [], "choose": {}, "rite": 0, "over": false, "back_to_prev": false,
		"back_to_round_begin": false, "logs": [], "clean_slots": [], "clean_card_ids": [],
		"clean_rite": false, "prompts": [], "loots": [], "delays": [], "sleeps": [],
		"ordered_effects": [],
	}
	for entry in rite.get("settlement", []):
		if not ConditionEval.evaluate(entry.get("condition", {}), ctx):
			continue
		RiteResolver._merge_deferred(deferred, ResultExec.execute(entry.get("result", {}), state, db, ctx))
		RiteResolver._merge_deferred(deferred, ResultExec.execute(entry.get("action", {}), state, db, ctx))
	DeferredEffects.apply(deferred, state, db, rng)

	var consumes_card: bool = bool(deferred.get("clean_rite", false)) or (1 in deferred.get("clean_slots", [])) or (card_id in deferred.get("clean_card_ids", []))
	state.remove_card_from_slot(card_uid, 1)
	if state.is_active_sudan_card(card_uid):
		if consumes_card:
			RoundLoop.consume_sudan(state, card_uid)
	elif removed_from_hand and not consumes_card:
		state.add_card_to_hand(card_uid)

	result.accepted = true
	result.deferred = deferred
	result.message = _message_from_result(deferred)
	# No same-day round start after consuming a Sultan card: the next draw
	# happens at the day boundary (TryGenSudanCard only runs in OnNextRound).
	return result


static func _message_from_result(deferred: Dictionary) -> String:
	if not deferred.get("choose", {}).is_empty():
		return "思考产生了几个可选结果。"
	if not deferred.get("prompts", []).is_empty():
		var prompt: Dictionary = deferred.prompts[0]
		return str(prompt.get("text", prompt.get("id", "思考有了结果。")))
	if int(deferred.get("rite", 0)) > 0:
		return "思考产生了一个可执行事项。"
	if not deferred.get("events", []).is_empty():
		return "思考产生了一个事件。"
	return "思考暂时没有新的结果。"
