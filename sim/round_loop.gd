## Round/calendar loop. Advances visible days, manages sudan card deadlines,
## redraws, and event-driven round starts.
class_name RoundLoop
extends RefCounted


## A sudan card in play with a countdown.
class ActiveSudan:
	var card_id: int = 0
	var days_left: int = 0
	var drawn_round: int = 0
	func _init(cid: int, life: int, rnd: int) -> void:
		card_id = cid
		days_left = life
		drawn_round = rnd


## Advance one visible day and decrement active sudan deadlines.
## New sudan cards are generated only when no sudan card is active, matching
## TryGenSudanCard's HasSudanCard gate rather than a fixed day modulo.
## [SRC: GameController.c @ TryGenSudanCard (0x559730)]
static func advance_day(state, db, rng) -> Dictionary:
	var result := {
		"game_over": false, "expired": [], "new_round": false, "auto_rites": [], "drawn_sudan": -1,
		"settled_rites": [], "expired_rites": [],
	}
	state.day += 1
	_update_rite_instances(state, db, rng, result)
	var still_active: Array = []
	for asc in state.active_sudan_cards:
		asc.days_left -= 1
		if asc.days_left <= 0:
			result.expired.append(asc.card_id)
			result.game_over = true
			if state.has_method("remove_card_from_rail"):
				state.remove_card_from_rail(int(asc.card_id))
		else:
			still_active.append(asc)
	state.active_sudan_cards = still_active
	if not result.game_over and state.active_sudan_cards.is_empty():
		_begin_round(state, db, rng, result)
	return result


## Draw one sudan card into the active set.
static func draw_weekly_sudan(state, _db, _rng) -> int:
	var life: int = int(state.difficulty_config.get("sudan_life_time", 7))
	var cid: int = SudanCards.draw(state.sudan_deck)
	if cid < 0:
		return -1
	state.active_sudan_cards.append(ActiveSudan.new(cid, life, state.round_number))
	if state.has_method("insert_card_to_rail"):
		state.insert_card_to_rail(cid, 0)
	return cid


## Start a new round explicitly and draw a sudan card if the pool still has one.
static func start_round(state, db, rng) -> int:
	state.round_number += 1
	var recovery := int(db.init_config.get("sudan_redraw_times_recovery_round", 7))
	if state.round_number % recovery == 0:
		state.redraws_left = _redraws_per_round(state, db)
	return draw_weekly_sudan(state, db, rng)


## Original redraw: draw sudan_redraw_count new cards from the finite pool
## (each inheriting the discarded card's remaining life), then insert the
## discarded card back at Random.Range(0,count). Gate: pool must have at least
## sudan_redraw_count cards. Returns the first new card id (or -1 on failure).
## [SRC: GameController.c @ RedrawSudanCard (0x5558b0): loops sudan_redraw_count
##  times (player+0x68), each inheriting discarded life; pre-loop pool gate]
static func use_redraw(state, rng) -> int:
	if state.redraws_left <= 0:
		return -1
	if state.active_sudan_cards.is_empty():
		return -1
	var draw_count := maxi(state.sudan_redraw_count, 1)
	# Pre-loop gate: pool must hold at least draw_count cards.
	# [SRC: GameController.c:3814 if pool.count < sudan_redraw_count → reject]
	if state.sudan_deck.size() < draw_count:
		return -1
	var old_card = state.active_sudan_cards.pop_back()
	var discarded: int = old_card.card_id
	var carried_life: int = old_card.days_left
	var first_new := -1
	var rail_index: int = state.rail_order.find(discarded) if state.has_method("replace_card_in_rail") else -1
	for i in draw_count:
		var new_id: int = SudanCards.draw(state.sudan_deck)
		if new_id < 0:
			break
		if i == 0:
			first_new = new_id
		state.active_sudan_cards.append(ActiveSudan.new(new_id, carried_life, state.round_number))
		if state.has_method("replace_card_in_rail"):
			if i == 0:
				if rail_index >= 0:
					state.replace_card_in_rail(discarded, new_id)
				else:
					state.insert_card_to_rail(new_id, state.rail_order.size())
			else:
				state.insert_card_to_rail(new_id, state.rail_order.size())
	# Insert the discarded card back into the pool.
	if not state.sudan_deck.is_empty():
		SudanCards.redraw(rng, state.sudan_deck, discarded)
	else:
		state.sudan_deck.append(discarded)
	if first_new >= 0:
		state.redraws_left -= 1
	return first_new


## Consume a sudan card. The caller may then call start_round_if_no_sudan to
## match TryGenSudanCard's "draw when none active" behavior.
static func consume_sudan(state, card_id: int) -> bool:
	for i in state.active_sudan_cards.size():
		if state.active_sudan_cards[i].card_id == card_id:
			state.active_sudan_cards.remove_at(i)
			if state.has_method("remove_card_from_rail"):
				state.remove_card_from_rail(card_id)
			# Fire card-clean event triggers for the consumed card.
			# [SRC: DesktopCleanCard/RiteResultPanelController -> OnCardClean]
			state.trigger_events("card_clean", {"card": card_id})
			return true
	return false


## Start a new round only if the player currently has no active sudan card.
static func start_round_if_no_sudan(state, db, rng) -> Dictionary:
	var result := {
		"game_over": false, "expired": [], "new_round": false, "auto_rites": [], "drawn_sudan": -1,
		"settled_rites": [], "expired_rites": [],
	}
	if state.active_sudan_cards.is_empty():
		_begin_round(state, db, rng, result)
	return result


static func _begin_round(state, db, rng, result: Dictionary) -> void:
	result.new_round = true
	result.auto_rites = start_auto_begin_rites(state, db)
	result.drawn_sudan = start_round(state, db, rng)
	# Fire round-begin event triggers after settlement (round_begin_ba).
	# [SRC: GameController.__c__DisplayClass141_0.c:138 -> OnRoundBeginBa]
	state.trigger_events("round_begin_ba", {"round": state.round_number})


## Open/start auto-begin rites. Do not resolve them: the original
## DoStartAutoBeginRite calls Rite.set_start, while auto-resolve is a separate
## runtime state machine (Player.auto_result_rites / rite_auto_result).
## The original iterates the player's current rite list, skips already-started
## rites, then sets start only when the rite config has auto-begin enabled.
## [SRC: GameController.c @ DoStartAutoBeginRite (RVA 0x54ebc0, dump.cs:320166)]
static func start_auto_begin_rites(state, db) -> Array:
	var out: Array = []
	if state == null or db == null:
		return out
	var candidate_rites: Array = state.available_rite_instances() if state.has_method("available_rite_instances") else []
	for instance in candidate_rites:
		if instance == null or not db.rites.has(instance.id):
			continue
		if instance.start:
			continue
		var rite: Dictionary = db.rites[instance.id]
		if int(rite.get("auto_begin", 0)) != 1:
			continue
		if not RiteOpen.is_rite_open(rite, state, db, null):
			continue
		state.start_rite_instance(instance.uid)
		out.append({"id": instance.id, "uid": instance.uid, "started": true})
	return out


## Update every player-owned rite once per visible day. The original advances
## Rite.life first; unstarted rites expire at waiting_round, while started
## rites settle at round_number. `auto_result` changes presentation, not this
## eligibility rule.
## [SRC: GameController.c @ UpdateSingleRite (RVA 0x55ab10), lines 5853-5882]
static func _update_rite_instances(state, db, rng, result: Dictionary) -> void:
	if state == null or db == null or not state.has_method("available_rite_instances"):
		return
	var instances: Array = state.available_rite_instances().duplicate()
	for instance in instances:
		if instance == null or not db.rites.has(instance.id):
			continue
		var rite: Dictionary = db.rites[instance.id]
		instance.life += 1
		if not instance.start:
			var waiting_round := int(rite.get("waiting_round", 0))
			if waiting_round > 0 and instance.life >= waiting_round:
				# RiteExtensions.Dead dispatches OnRiteClean before it runs the
				# configured timeout operations and returns cards.
				# [SRC: RiteExtensions.c @ Dead (RVA 0x501460), lines 44-60]
				state.trigger_events("rite_clean", {"rite": instance.id})
				_execute_waiting_round_end(rite, instance, state, db, rng)
				state.return_rite_cards(instance.uid, db)
				state.remove_rite_instance(instance.uid)
				result.expired_rites.append({"id": instance.id, "uid": instance.uid})
			continue
		if instance.life < int(rite.get("round_number", 0)):
			continue
		# A started rite is resolved by the normal settlement pipeline. In this
		# headless path no gold-dice retry is possible, which is the role of
		# auto_result in the original UI.
		var table_entries: Array = state.cards_in_slot_entries_for_rite(instance.uid)
		var res: Variant = _resolve_rite_instance(rite, instance, state, db, rng)
		finalize_rite_settlement(instance, res.deferred, state, db, table_entries)
		DeferredEffects.apply(res.deferred, state, db, rng)
		state.trigger_events("rite_end", {"rite": instance.id})
		result.settled_rites.append({"id": instance.id, "uid": instance.uid, "auto_result": int(rite.get("auto_result", 0)) == 1})


static func _resolve_rite_instance(rite: Dictionary, instance, state, db, rng):
	var rite_state := {}
	var attr_slots: Array = []
	for slot_key in rite.get("cards_slot", {}):
		var key := str(slot_key)
		var cards: Array = state.cards_in_slot(key.substr(1).to_int(), instance.uid)
		if not cards.is_empty():
			rite_state[key] = int(cards[0].get("id", 0))
		attr_slots.append(key)
	var ctx := {
		"db": db, "state": state, "rng": rng, "rite_state": rite_state,
		"attr_slots": attr_slots, "rite_id": instance.id, "rite_uid": instance.uid,
	}
	state.active_rite_uid = instance.uid
	var res = RiteResolver.resolve(rite, ctx, 0)
	state.active_rite_uid = 0
	return res


## Apply explicit clean instructions, return every remaining placed card, then
## remove only this runtime instance. Rite result UI does the same removal
## after its settlement pipeline completes.
## [SRC: RiteResultPanelController.__c__DisplayClass56_0.c @ <Settlement>b__8
##       (RVA 0x5b4850): RemoveRite after settlement; RiteExtensions.ReturnCards
##       (RVA 0x5016d0) for the timeout path.]
static func finalize_rite_settlement(instance, deferred: Dictionary, state, db, source_table_entries: Array = []) -> void:
	var clean_rite := bool(deferred.get("clean_rite", false))
	var clean_slots: Array = deferred.get("clean_slots", [])
	var clean_card_ids: Array = deferred.get("clean_card_ids", [])
	# ResultExec applies clean.sN immediately to the table index. Keep the
	# pre-resolution entries so a cleaned card still reaches its real cleanup
	# path (especially active Sudan cards).
	var table_entries: Array = source_table_entries if not source_table_entries.is_empty() else state.cards_in_slot_entries_for_rite(instance.uid)
	for table_card in table_entries:
		var card_id := int(table_card.get("id", 0))
		var slot_num := int(table_card.get("slot", 0))
		var is_cleaned := clean_rite or slot_num in clean_slots or card_id in clean_card_ids
		if is_cleaned:
			if state.is_active_sudan_card(card_id):
				consume_sudan(state, card_id)
			else:
				state.trigger_events("card_clean", {"card": card_id})
		elif not state.is_active_sudan_card(card_id) and not state.has_card_in_hand(card_id):
			state.add_card_to_hand(card_id)
	state.remove_rite_instance(instance.uid)


## waiting_round_end_action is a conditional sequence. It runs before cards
## return and the rite is removed, matching RiteExtensions.Dead.
static func _execute_waiting_round_end(rite: Dictionary, instance, state, db, rng) -> void:
	var attr_slots: Array = []
	var rite_state := {}
	for slot_key in rite.get("cards_slot", {}):
		var key := str(slot_key)
		attr_slots.append(key)
		var cards: Array = state.cards_in_slot(key.substr(1).to_int(), instance.uid)
		if not cards.is_empty():
			rite_state[key] = int(cards[0].get("id", 0))
	var ctx := {"db": db, "state": state, "rng": rng, "rite_state": rite_state, "attr_slots": attr_slots, "rite_id": instance.id, "rite_uid": instance.uid}
	state.active_rite_uid = instance.uid
	for entry in rite.get("waiting_round_end_action", []):
		if not (entry is Dictionary) or not ConditionEval.evaluate(entry.get("condition", {}), ctx):
			continue
		var deferred := ResultExec.execute(entry.get("result", {}), state, db)
		_merge_deferred(deferred, ResultExec.execute(entry.get("action", {}), state, db))
		DeferredEffects.apply(deferred, state, db, rng)
		var title := str(entry.get("result_title", ""))
		var text := str(entry.get("result_text", ""))
		if (title != "" or text != "") and state.has_method("queue_prompt"):
			state.queue_prompt({"id": "rite_timeout.%d.%d" % [instance.uid, state.day], "title": title, "text": text})
	state.active_rite_uid = 0


static func _merge_deferred(into: Dictionary, src: Dictionary) -> void:
	for key in ["events", "logs", "clean_slots", "clean_card_ids", "prompts", "loots"]:
		if src.has(key):
			if not into.has(key):
				into[key] = []
			into[key].append_array(src[key])
	if src.has("choose") and not src["choose"].is_empty():
		into["choose"] = src["choose"]
	if src.has("rite") and int(src["rite"]) != 0:
		into["rite"] = src["rite"]
	if src.has("clean_rite") and bool(src["clean_rite"]):
		into["clean_rite"] = true
	if src.has("over") and bool(src["over"]):
		into["over"] = true


static func _redraws_per_round(state, db) -> int:
	return int(state.difficulty_config.get(
		"sudan_redraw_times_per_round",
		db.init_config.get("sudan_redraw_times_per_round", 1)
	))
