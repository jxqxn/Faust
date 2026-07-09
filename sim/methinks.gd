## Desktop "I think" processor.
## The original routes the selected card to ThinkController.OnDrop, which then
## sends GameEventSender.IThink instead of opening a rite panel.
## [SRC: GameController.c @ DoIThink (RVA 0x54e880);
##       ThinkController.c @ GameEventSender__IThink call;
##       GameEventSender.c @ IThink (RVA 0x4429a0)]
class_name MethinksEngine
extends RefCounted

static func process_card(card_id: int, source: String, state, db, rng) -> Dictionary:
	var result := {"accepted": false, "message": "", "deferred": {}}
	var think_id := int(db.init_config.get("think_id", 5000002))
	var rite: Dictionary = db.get_rite(think_id)
	if rite.is_empty():
		result.message = "俺寻思还没有配置。"
		return result
	var card: Dictionary = db.get_card(card_id)
	if card.is_empty() and not state.is_active_sudan_card(card_id):
		result.message = "这张牌暂时不能寻思。"
		return result

	var removed_from_hand := false
	if source == "hand" and state.has_card_in_hand(card_id):
		removed_from_hand = state.remove_card_from_hand(card_id)
	state.remove_card_from_slot(card_id)
	state.add_card_to_slot(card_id, 1, db)
	var ctx := {"db": db, "state": state, "rng": rng, "rite_state": {"s1": card_id}, "attr_slots": ["s1"], "rite_id": think_id}
	var resolved = RiteResolver.resolve(rite, ctx, 0)
	var deferred: Dictionary = resolved.deferred
	DeferredEffects.apply(deferred, state, db, rng)

	var consumes_card: bool = bool(deferred.get("clean_rite", false)) or (1 in deferred.get("clean_slots", [])) or (card_id in deferred.get("clean_card_ids", []))
	state.remove_card_from_slot(card_id, 1)
	var sudan_consumed := false
	if state.is_active_sudan_card(card_id):
		if consumes_card:
			sudan_consumed = RoundLoop.consume_sudan(state, card_id)
	elif removed_from_hand and not consumes_card:
		state.add_card_to_hand(card_id)

	result.accepted = true
	result.deferred = deferred
	result.message = _message_from_result(resolved, deferred)
	# Consuming the last sudan card must trigger the round-start check, mirroring
	# consume_sudan's contract and advance_day's event-driven round start.
	# Otherwise the player is left with no active sudan and no new round.
	if sudan_consumed:
		var round_result := RoundLoop.start_round_if_no_sudan(state, db, rng)
		if round_result.get("new_round", false):
			result.new_round = true
			result.drawn_sudan = int(round_result.get("drawn_sudan", -1))
			if result.drawn_sudan >= 0:
				var dec = SudanCards.decode(result.drawn_sudan)
				result.message += "\n—— 第 %d 回合开始 ——\n新苏丹卡: %s%s" % [state.round_number, dec.rank, dec.action]
	return result


static func _message_from_result(resolved, deferred: Dictionary) -> String:
	if not deferred.get("choose", {}).is_empty():
		return "俺寻思有了几个念头。"
	if not deferred.get("prompts", []).is_empty():
		var prompt: Dictionary = deferred.prompts[0]
		return str(prompt.get("text", prompt.get("id", "俺寻思有了结果。")))
	var entry: Dictionary = resolved.normal_entry
	if not entry.is_empty():
		var title := str(entry.get("result_title", ""))
		var text := str(entry.get("result_text", ""))
		if title != "":
			return title
		if text != "":
			return text
	if int(deferred.get("rite", 0)) > 0:
		return "俺寻思出了一件新事。"
	if not deferred.get("events", []).is_empty():
		return "俺寻思触发了一段事件。"
	return "俺寻思了一下，但暂时没有新的结果。"
