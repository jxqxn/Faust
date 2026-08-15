## Round/calendar loop. Advances visible days, manages sudan card deadlines,
## redraws, and event-driven round starts.
class_name RoundLoop
extends RefCounted


## A sudan card in play with a countdown.
class ActiveSudan:
	var card_id: int = 0
	var card_uid: int = 0
	var days_left: int = 0
	var drawn_round: int = 0
	func _init(cid: int, life: int, rnd: int, uid: int = 0) -> void:
		card_id = cid
		card_uid = uid
		days_left = life
		drawn_round = rnd


## Advance one visible day and decrement active sudan deadlines.
## New sudan cards are generated only when no sudan card is active, matching
## TryGenSudanCard's HasSudanCard gate rather than a fixed day modulo.
## [SRC: GameController.c @ TryGenSudanCard (0x559730)]
static func advance_day(state, db, rng) -> Dictionary:
	var result := {
		"game_over": false, "expired": [], "new_round": false, "auto_rites": [], "drawn_sudan": -1,
		"settled_rites": [], "expired_rites": [], "round_end_events": [], "round_begin_events": [], "due_delays": [],
	}
	# One day transition has a stable event boundary. Round-end effects observe
	# the outgoing round before any rite life, expiry, or Sudan deadline changes.
	# [SRC: GameController.c @ OnNextRound (RVA 0x554540) dispatches NextDay;
	#       GameController @ UpdateSingleRite (RVA 0x55ab10) updates instances
	#       in that transition; EventTriggerExtensions @ OnRoundEnd.]
	result.round_end_events = state.trigger_events("round_end", {"round": state.round_number})
	state.day += 1
	_update_rite_instances(state, db, rng, result)
	result.due_delays = DeferredEffects.execute_due_delays(state, db, rng)
	result.expired_cards = _update_card_lives(state, db, rng)
	# Sultan deadline decrements unconditionally. Execution is suppressed only
	# while the card is embedded in an in-progress started rite (zone=slot, the
	# rite is started, and life has not yet reached its round_number). The
	# countdown can run to zero or below; only the game-over trigger is gated.
	# [SRC: 知乎专栏 p/1909509257005831882 "已被嵌入仪式中的苏丹卡倒计时哪怕退到负数
	#       都不会触发处刑"; 巴哈姆特 snA=111; BWIKI 新手指南]
	var still_active: Array = []
	for asc in state.active_sudan_cards:
		asc.days_left -= 1
		if asc.days_left <= 0 and not _is_sudan_embedded_in_open_rite(state, db, asc):
			result.expired.append(asc.card_id)
			result.game_over = true
			if state.has_method("remove_card_from_rail"):
				state.remove_card_from_rail(int(asc.card_uid))
			var expired_instance = state.get_card_instance(int(asc.card_uid)) if state.has_method("get_card_instance") else null
			if expired_instance != null:
				expired_instance.zone = "removed"
				expired_instance.is_lost = true
		else:
			still_active.append(asc)
	state.active_sudan_cards = still_active
	# round advances unconditionally every day; only the Sultan draw is gated
	# on having no active Sultan card (inside _begin_round).
	# [SRC: DisplayClass142_0.c @ <OnNextRound>b__3 (0x570790): player.round
	#       (player+0x2c) += 1 unconditionally; TryGenSudanCard (0x559730)
	#       checks HasSudanCard separately]
	if not result.game_over:
		_begin_round(state, db, rng, result)
	return result


## DoCardUpdate: every live card ages one day; a card whose life reaches its
## template's card_vanishing dies (vanish ops + card_dead) UNLESS it currently
## sits in any rite slot (shelter, regardless of the rite's start state) or is
## an active Sultan card (their death is the deadline check below, not this).
## Equipped cards age with their host.
## [SRC: GameController.c @ DoCardUpdate (0x54d4c0) lines 5139-5231: snapshot
##       (Card, flag) with flag=1 for every card in any rite.cards;
##       DisplayClass196_0 @ <UpdateSingleCard>b__1 (0x572420): life+1, death
##       when life >= data.card_vanishing(+0x60) and flag == 0]
static func _update_card_lives(state, db, rng) -> Array:
	var dead: Array = []
	if state == null or db == null or not state.has_method("get_card_instance"):
		return dead
	var uid_snapshot: Array = state.card_instances.keys().duplicate()
	for uid in uid_snapshot:
		var inst = state.get_card_instance(int(uid))
		if inst == null or inst.is_lost or inst.zone == "removed":
			continue
		if state.is_active_sudan_card(int(uid)):
			continue # Sultan deadline path owns these.
		var card: Dictionary = db.get_card(int(inst.card_id))
		var lifetime := int(card.get("card_vanishing", 0))
		if lifetime < 1:
			continue
		inst.life += 1
		var sheltered: bool = inst.zone == "slot" and inst.rite_uid > 0
		if sheltered or inst.life < lifetime:
			continue
		dead.append({"id": int(inst.card_id), "card_uid": int(uid)})
		var vanish: Dictionary = card.get("vanish", {})
		if not vanish.is_empty():
			DeferredEffects.apply(ResultExec.execute(vanish, state, db), state, db, rng)
		state.trigger_events("card_dead", {"card": int(inst.card_id), "card_uid": int(uid)})
		if inst.zone == "hand" and state.has_method("remove_card_from_hand"):
			state.remove_card_from_hand(int(uid))
		inst.zone = "removed"
		inst.is_lost = true
	return dead


## Draw one sudan card into the active set.
static func draw_weekly_sudan(state, db, _rng) -> int:
	var life: int = int(state.difficulty_config.get("sudan_life_time", 7))
	var cid: int = SudanCards.draw(state.sudan_deck)
	if cid < 0:
		return -1
	var instance = _create_sudan_instance(state, db, cid)
	var card_uid := int(instance.uid) if instance != null else cid
	state.active_sudan_cards.append(ActiveSudan.new(cid, life, state.round_number, card_uid))
	if state.has_method("insert_card_to_rail"):
		state.insert_card_to_rail(card_uid, 0)
	return cid


## Original redraw: draw sudan_redraw_count new cards from the finite pool
## (each inheriting the discarded card's remaining life), then insert the
## discarded card (with its runtime tags) back at Random.Range(0,count).
## Quota: the per-round allowance first, then the extra-redraw counter
## 7100008. A mid-loop generation failure aborts WITHOUT reinserting the
## discarded card or consuming a redraw.
## [SRC: GameController.c @ RedrawSudanCard (0x5558b0): loops sudan_redraw_count
##       times, GenSudanCard failure -> error goto (no reinsert, no consume,
##       L3823-3834); PlayerExtensions.c @ GetSudanRedrawCount (0x38dda0)
##       per-round + counter 7100008; UseSudanExtraRedraw (0x38fb60)]
static func use_redraw(state, rng, db = null) -> int:
	if state.active_sudan_cards.is_empty():
		return -1
	var uses_per_round: bool = state.redraws_left > 0
	var extra_left: int = state.get_counter(7100008) if state.has_method("get_counter") else 0
	if not uses_per_round and extra_left <= 0:
		return -1
	var draw_count := maxi(state.sudan_redraw_count, 1)
	# Pre-loop gate: pool must hold at least draw_count cards.
	# [SRC: GameController.c:3814 if pool.count < sudan_redraw_count → reject]
	if state.sudan_deck.size() < draw_count:
		return -1
	var old_card = state.active_sudan_cards.pop_back()
	var discarded: int = old_card.card_id
	var discarded_uid: int = old_card.card_uid
	var carried_life: int = old_card.days_left
	var first_new := -1
	var rail_index: int = state.rail_order.find(discarded_uid) if state.has_method("replace_card_in_rail") else -1
	var old_instance = state.get_card_instance(discarded_uid) if state.has_method("get_card_instance") else null
	var old_tags: Dictionary = old_instance.tags.duplicate(true) if old_instance != null else {}
	if old_instance != null:
		old_instance.zone = "removed"
		old_instance.is_lost = true
	var generation_failed := false
	for i in draw_count:
		var new_id: int = SudanCards.draw(state.sudan_deck)
		if new_id < 0:
			# Error path: partially drawn cards stay out, the discarded card is
			# NOT reinserted and no redraw is consumed.
			generation_failed = true
			break
		if i == 0:
			first_new = new_id
		var instance = _create_sudan_instance(state, db, new_id)
		var new_uid := int(instance.uid) if instance != null else new_id
		state.active_sudan_cards.append(ActiveSudan.new(new_id, carried_life, state.round_number, new_uid))
		if state.has_method("replace_card_in_rail"):
			if i == 0:
				if rail_index >= 0:
					state.replace_card_in_rail(discarded_uid, new_uid)
				else:
					state.insert_card_to_rail(new_uid, state.rail_order.size())
			else:
				state.insert_card_to_rail(new_uid, state.rail_order.size())
	if generation_failed:
		return first_new
	# Insert the discarded card back into the pool, carrying its runtime tag
	# overrides so the next draw of this id keeps them (the original reinserts
	# the Card object itself).
	# [SRC: RedrawSudanCard L3840-3842: List.Insert(Random.Range(0,count), card)]
	if not old_tags.is_empty():
		state.sudan_pool_tags[discarded] = old_tags
	if not state.sudan_deck.is_empty():
		SudanCards.redraw(rng, state.sudan_deck, discarded)
	else:
		state.sudan_deck.append(discarded)
	if uses_per_round:
		state.redraws_left -= 1
	else:
		state.set_counter(7100008, extra_left - 1)
	return first_new


## Consume a sudan card. The next Sultan draw happens at the following day
## boundary (TryGenSudanCard runs only in the startup chain and the daily
## OnNextRound chain); there is no same-day replacement draw.
## [SRC: TryGenSudanCard callers: DisplayClass141_0.c:307 (startup),
##       DisplayClass142_0.c:395 (OnNextRound); no other callers exist]
static func consume_sudan(state, card_or_uid: int) -> bool:
	for i in state.active_sudan_cards.size():
		var active = state.active_sudan_cards[i]
		if active.card_id == card_or_uid or active.card_uid == card_or_uid:
			state.active_sudan_cards.remove_at(i)
			if state.has_method("remove_card_from_rail"):
				state.remove_card_from_rail(int(active.card_uid))
			var instance = state.get_card_instance(int(active.card_uid)) if state.has_method("get_card_instance") else null
			if instance != null:
				instance.zone = "removed"
				instance.is_lost = true
			# Fire card-clean event triggers for the consumed card.
			# [SRC: DesktopCleanCard/RiteResultPanelController -> OnCardClean]
			state.trigger_events("card_clean", {"card": active.card_id, "card_uid": active.card_uid})
			return true
	return false


## Pool tags are copied only when an ID becomes a runtime Sultan instance.
## The pool never owns speculative CardInstances, so its operations cannot
## consume a UID or mutate already drawn cards.
static func _create_sudan_instance(state, db, card_id: int):
	if state == null or not state.has_method("create_card_instance"):
		return null
	var instance = state.create_card_instance(card_id, db, "sudan")
	if instance != null and state.sudan_pool_tags.has(card_id):
		for tag_name in state.sudan_pool_tags[card_id]:
			instance.tags[tag_name] = state.sudan_pool_tags[card_id][tag_name]
	return instance


static func _begin_round(state, db, rng, result: Dictionary) -> void:
	result.new_round = true
	state.round_number += 1
	var recovery := int(db.init_config.get("sudan_redraw_times_recovery_round", 7))
	# The original guards against a zero-remainder divisor: recovery < 2 resets
	# every day instead of dividing by zero.
	# [SRC: DisplayClass142_0.c @ <OnNextRound>b__9 (0x571000) lines 465-473]
	if recovery < 2 or state.round_number % recovery == 0:
		state.redraws_left = _redraws_per_round(state, db)
	# The original increments Player.round then runs OnRoundBeginBa before its
	# follow-up round pipeline. Auto-start only changes Rite.start; it belongs
	# after that event boundary and before the next Sudan draw.
	# [SRC: GameController.__c__DisplayClass141_0.c @ <Start>b__5 (RVA 0x56f9c0),
	#       lines 120-150; GameController.c @ DoStartAutoBeginRite (0x54ebc0)]
	result.round_begin_events = state.trigger_events("round_begin_ba", {"round": state.round_number})
	result.auto_rites = start_auto_begin_rites(state, db)
	# Only the Sultan draw is gated on having no active Sultan card; the round
	# itself always advances. The disabled-generation flag skips only the draw.
	# [SRC: GameController.c @ TryGenSudanCard (0x559730) lines 3563-3566:
	#       HasSudanCard gate + player+0x161 disable flag]
	if state.auto_gen_sudan_card and state.active_sudan_cards.is_empty():
		result.drawn_sudan = draw_weekly_sudan(state, db, rng)


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
		"slot_entries": state.slot_entries_for_rite(rite, instance.uid),
	}
	if state.has_method("with_player_actor_context"):
		ctx = state.with_player_actor_context(ctx, db)
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
	# Both the headless batch path and the rite-view commit path funnel through
	# here, so this is where a settled rite becomes "ended" for rite_end.<id>.
	if state != null and state.has_method("record_rite_ended"):
		state.record_rite_ended(instance.id)
	var clean_rite := bool(deferred.get("clean_rite", false))
	var clean_slots: Array = deferred.get("clean_slots", [])
	var clean_card_ids: Array = deferred.get("clean_card_ids", [])
	# ResultExec applies clean.sN immediately to the table index. Keep the
	# pre-resolution entries so a cleaned card still reaches its real cleanup
	# path (especially active Sudan cards).
	var table_entries: Array = source_table_entries if not source_table_entries.is_empty() else state.cards_in_slot_entries_for_rite(instance.uid)
	for table_card in table_entries:
		var card_id := int(table_card.get("id", 0))
		var card_uid := int(table_card.get("card_uid", 0))
		var slot_num := int(table_card.get("slot", 0))
		var is_cleaned := clean_rite or slot_num in clean_slots or card_id in clean_card_ids
		if is_cleaned:
			if state.is_active_sudan_card(card_uid):
				consume_sudan(state, card_uid)
			else:
				state.trigger_events("card_clean", {"card": card_id, "card_uid": card_uid})
		elif state.is_active_sudan_card(card_uid):
			var sudan_instance = state.get_card_instance(card_uid) if state.has_method("get_card_instance") else null
			if sudan_instance != null:
				sudan_instance.zone = "sudan"
				sudan_instance.rite_uid = 0
				sudan_instance.slot_key = ""
		elif not state.has_card_in_hand(int(table_card.get("card_uid", card_id))):
			state.add_card_to_hand(int(table_card.get("card_uid", card_id)), db)
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
	if state.has_method("with_player_actor_context"):
		ctx = state.with_player_actor_context(ctx, db)
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
	for key in ["events", "logs", "clean_slots", "clean_card_ids", "prompts", "loots", "delays", "sleeps", "ordered_effects"]:
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


## A Sultan card is "embedded" (safe from execution) when it currently sits in
## the slot zone of a started rite that has not yet reached its round_number.
## This covers multi-day rites whose lifetime window shelters the card; a
## settled or 0-day rite no longer qualifies because life >= round_number.
## Defensive against missing state APIs and partially-built instances.
## [SRC: 知乎专栏 p/1909509257005831882; 巴哈姆特 snA=111]
static func _is_sudan_embedded_in_open_rite(state, _db, asc) -> bool:
	# Shelter is presence in ANY rite slot: the original death check receives
	# flag=1 for every card in any rite.cards without inspecting rite.start or
	# remaining days. The countdown itself is unconditional.
	# [SRC: GameController.c @ DoCardUpdate (0x54d4c0) lines 5175-5231]
	if asc == null or not state.has_method("get_card_instance"):
		return false
	var sudan_uid := int(asc.card_uid)
	var instance = state.get_card_instance(sudan_uid)
	return instance != null and instance.zone == "slot" and instance.rite_uid > 0
