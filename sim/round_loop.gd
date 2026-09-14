## Round/calendar loop. Advances visible days, manages sudan card deadlines,
## redraws, and event-driven round starts.
class_name RoundLoop
extends RefCounted

const CardInstanceData = preload("res://sim/card_instance.gd")


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


## Start the first day's serial opening without advancing another day.
static func begin_opening(state, db, rng) -> Dictionary:
	# [SRC: GameController.Start b__5 0x56f9c0 -> b__8/b__9/b__10:
	# OnRoundBeginBa resolves before HandCardArrange and TryGenSudanCard.]
	# Use the persisted transition rather than a UI-only pending-draw flag.
	if not state.round_transition.is_empty():
		return state.round_transition
	var result := {
		"game_over": false, "expired": [], "auto_rites": [],
		"drawn_sudan": -1, "new_round": false, "interactive": true,
		"phase": "opening_events",
	}
	state.round_transition = result
	_pump_day(state, db, rng, result)
	return result


## Advance one visible day; TryGenSudanCard 0x559730 draws only if absent.
static func advance_day(state, db, rng, interactive: bool = false, animate: bool = false) -> Dictionary:
	if not state.round_transition.is_empty():
		return state.round_transition
	# SaveRoundEnd is before the Promise chain, including card updates.
	# [SRC: GameController.OnNextRound 0x554540; script.json method metadata
	# 0x2599300/0x25991a0/0x2592010/0x2599288/0x2599218/0x2591fa0.]
	_snapshot_round(state, "round_end")
	var result := {
		"game_over": false, "expired": [], "expired_cards": [], "new_round": false,
		"auto_rites": [], "drawn_sudan": -1, "settled_rites": [], "expired_rites": [],
		"round_end_events": [], "round_begin_events": [], "due_delays": [],
		"adsorbed": [], "interactive": interactive, "phase": "auto_start",
	}
	state.round_transition = result
	if animate:
		result.animation = preload("res://ui/next_day_clock.gd").create()
		result.phase = "night_enter"
	_pump_day(state, db, rng, result)
	return result


## Persist the next stage BEFORE invoking an operation that may present UI.
## The original Then chain is serial; source order is not the numeric order
## of generated closure names. See docs/replica/loop.md#e040.
static func _pump_day(state, db, rng, result: Dictionary) -> void:
	while state.pending_operations.is_empty() and state.rite_settlements.is_empty():
		if state.over_pending:
			result.game_over = true
			state.round_transition = {}
			return
		match str(result.get("phase", "rites")):
			"night_enter", "day_enter":
				# Only the source animation event releases these Promise gates.
				return
			"opening_events":
				result.phase = "opening_draw"
				state.trigger_events("round_begin_ba", {"round": state.round_number, "rng": rng})
			"opening_draw":
				result.phase = "opening_complete"
				update_hand_card_pos(state)
				if state.auto_gen_sudan_card and state.active_sudan_cards.is_empty():
					result.drawn_sudan = draw_weekly_sudan(state, db, rng)
			"opening_complete":
				state.round_transition = {}
				return
			"auto_start":
				result.phase = "cards"
				result.auto_rites = start_auto_begin_rites(state, db)
			"cards":
				_update_card_lives(state, db, rng, result)
				if not result.get("unupdated_cards", []).is_empty() or not state.pending_operations.is_empty():
					return
				result.phase = "round_end"
			"round_end":
				result.phase = "increment"
				result.round_end_events = state.trigger_events("round_end", {"round": state.round_number})
			"increment":
				result.phase = "rites"
				state.day += 1
				state.round_number += 1
				result.new_round = true
				state.trigger_events("round_begin_fr", {"round": state.round_number})
			"rites":
				var due: Array = result.get("due_rites", [])
				while not due.is_empty() and state.get_rite_instance(int(due[0])) == null:
					due.pop_front()
				if not due.is_empty():
					return
				_update_rite_instances(state, db, rng, result, bool(result.interactive))
				if not result.get("due_rites", []).is_empty() or not state.rite_settlements.is_empty() or not state.pending_operations.is_empty():
					return
				result.phase = "delays"
			"delays":
				if not result.has("remaining_delays"):
					result.remaining_delays = state.take_due_delayed_operations()
				if not result.remaining_delays.is_empty():
					var delayed: Dictionary = result.remaining_delays.pop_front()
					result.due_delays.append(delayed)
					var payload: Dictionary = delayed.get("payload", {}).duplicate(true)
					payload.erase("id")
					payload.erase("round")
					OperationsSequence.start([payload], state, db, rng, delayed.get("context", {}))
				else:
					if result.has("animation"):
						preload("res://ui/next_day_clock.gd").continue_to_day(result.animation)
						result.phase = "day_enter"
					else:
						result.phase = "round_begin"
			"round_begin":
				result.phase = "adsorb"
				result.round_begin_events = state.trigger_events("round_begin_ba", {"round": state.round_number})
			"adsorb":
				result.phase = "draw"
				result.adsorbed = state.adsorb_open_slots_daily(db, rng)
				update_hand_card_pos(state)
			"draw":
				result.phase = "complete"
				if state.auto_gen_sudan_card and state.active_sudan_cards.is_empty():
					result.drawn_sudan = draw_weekly_sudan(state, db, rng)
			"complete":
				_reset_redraw_for_round(state, db)
				state.global_state.round_rollback = GlobalState.ROLLBACK_TO_BEGIN
				state.round_transition = {}
				_snapshot_round(state, "round_begin")
				return
			_:
				push_error("Unknown saved day phase: %s" % result.phase)
				return


## DoCardUpdate: every live card ages one day; a card whose life reaches its
## template's card_vanishing dies (vanish ops + card_dead) UNLESS it currently
## sits in any rite slot (shelter, regardless of the rite's start state).
## Sudan cards run the same system — they are born with the head start
## (card_vanishing − sudan_card_init_life) so the difficulty shortens only the
## window; their death is the Sultan execution (vanish.over ending) and the
## visible countdown mirrors card_vanishing − life (it can go negative while
## sheltered). Equipped cards age with their host.
## [SRC: GameController.c @ DoCardUpdate (0x54d4c0) lines 5139-5231: snapshot
##       (Card, flag) with flag=1 for every card in any rite.cards;
##       DisplayClass196_0 @ <UpdateSingleCard>b__1 (0x572420): life+1, death
##       when life >= data.card_vanishing(+0x60) and flag == 0;
##       GameController.c @ UpdateSudanLife (0x55aeb0) L6363-6372 shows the
##       countdown as data.card_vanishing − card.life]
static func _update_card_lives(state, db, rng, progress: Dictionary = {}) -> Array:
	var dead: Array = progress.get("expired_cards", [])
	if state == null or db == null or not state.has_method("get_card_instance"):
		return dead
	if not progress.has("unupdated_cards"):
		# Snapshot player cards followed by rite cards, not the instance registry
		# (which also holds removed cards and unowned/pool objects).
		# [SRC: DoCardUpdate 0x54d4c0 player+0x88 then player+0x90;
		# DisplayClass196_0 b__0 0x572220 updates equipment before host.]
		progress.unupdated_cards = []
		var hosts: Array = []
		for card_uid in state.card_instances:
			var host = state.get_card_instance(int(card_uid))
			if host.zone in ["hand", "sudan"]:
				hosts.append({"uid": host.uid, "shelter": false})
		for rite_uid in state.rite_instances:
			for entry in state.cards_in_slot_entries_for_rite(int(rite_uid)):
				hosts.append({"uid": int(entry.card_uid), "shelter": true})
		for entry in hosts:
			var host = state.get_card_instance(int(entry.uid))
			for equipment_uid in host.equipped_uids:
				progress.unupdated_cards.append({"uid": int(equipment_uid), "shelter": entry.shelter})
			progress.unupdated_cards.append(entry)
	while not progress.unupdated_cards.is_empty():
		var update = progress.unupdated_cards.pop_front()
		var uid := int(update.uid) if update is Dictionary else int(update)
		var inst = state.get_card_instance(int(uid))
		if inst == null or inst.is_lost or inst.zone == "removed":
			continue
		if ResultExec._has_freeze_tag(inst, state, db):
			continue
		var is_sudan: bool = state.is_active_sudan_card(int(uid))
		var card: Dictionary = db.get_card(int(inst.card_id))
		var lifetime := int(card.get("card_vanishing", 0))
		inst.life += 1
		if is_sudan:
			for asc in state.active_sudan_cards:
				if int(asc.card_uid) == int(uid):
					asc.days_left = lifetime - inst.life
		var sheltered: bool = bool(update.shelter) if update is Dictionary else inst.zone == "slot" and inst.rite_uid > 0
		if sheltered or lifetime < 1 or inst.life < lifetime:
			continue
		dead.append({"id": int(inst.card_id), "card_uid": int(uid), "sudan": is_sudan})
		var vanish: Variant = card.get("vanish", {})
		# No card_dead timing is fired here. EventTriggerExtensions.OnCardDead
		# exists (28 On* entry points) but has NO call site anywhere in the
		# decompiled corpus and no `on.card_dead` in any of the 1863 event
		# configs, so the original never dispatches it -- the death surface is
		# the card's own `vanish` block above plus card_clean. Firing it here was
		# a clone-only invention.
		# [SRC: grep EventTriggerExtensions__OnCardDead over
		#       engine_spec/decompiled/*.c -> definition only;
		#       data/config/event/*.json `on` keys -> 21 timings, no card_dead]
		if is_sudan:
			# The execution: retire the rail widget and the active-sudan entry
			# (over_reason comes from the vanish.over op above).
			if state.has_method("remove_card_from_rail"):
				state.remove_card_from_rail(int(uid))
			var still_active: Array = []
			for asc in state.active_sudan_cards:
				if int(asc.card_uid) != int(uid):
					still_active.append(asc)
			state.active_sudan_cards = still_active
		state.remove_card_instance_from_play(uid)
		if is_sudan:
			progress.get("expired", []).append(int(inst.card_id))
		# RemoveCard precedes DoVanish; wait its operations before the next card.
		# [SRC: DisplayClass196_0 b__1 0x572420; freeze literal 0x25ac9e8.]
		OperationsSequence.start([vanish], state, db, rng, {"card_uid": uid, "self_card_uid": uid})
		if not state.pending_operations.is_empty() or state.over_pending:
			return dead
	return dead


## Keep a full-state cache for one boundary, pruning to the latest two rounds.
## Disk-backed runs also execute the original two-file transaction: refresh
## auto_save, then write round_{N}.json / round_{N}_end.json. Detached test
## states remain memory-only.
## [SRC: DatapoolExtensions.c @ SaveRoundBegin (0x3f9050) / SaveRoundEnd
##       (0x3f9120); stringliteral.json 0x258BED0 / 0x258BF40]
static func _snapshot_round(state, kind: String) -> void:
	if not state.has_method("get") or state.get("round_snapshots") == null:
		return
	state.round_snapshots[kind][state.round_number] = SaveSystem.serialize(state)
	while state.round_snapshots[kind].size() > 2:
		var keys: Array = state.round_snapshots[kind].keys()
		keys.sort()
		state.round_snapshots[kind].erase(keys[0])
	if state.global_state != null and state.global_state.is_disk_bound():
		if kind == "round_end":
			SaveSystem.save_round_end(state)
		else:
			SaveSystem.save_round_begin(state)


## Back to the previous round's end (retry the current round): gate on
## round-1 >= max(1, min_round) and the back-to-prev budget (9999 = free),
## then consume first, mark the rollback kind on the global object, persist
## the global side, and restore the round_end snapshot wholesale. The quota
## survives the restore because it lives outside the run payload.
## [SRC: GameController.c @ OnPrevRound (0x554f80) L2149-2174 gates;
##       PrevRoundInternal (0x555570) L2246-2284: UseBackToPrev ->
##       Global.roundRollback = 2 -> Datapool.SaveGlobal -> LoadRound;
##       LoadController.c @ LoadRoundEnd (0x3f8e70); report 7 A1]
static func back_to_prev_round_end(state, db) -> bool:
	if state == null:
		return false
	# The lower bound is the persisted player field, clamped to >= 1.
	# [SRC: GameController.c OnPrevRound (0x554f80) L2149-2156 reads
	#       player+0x30 (min_round) directly]
	if state.round_number - 1 < maxi(1, int(state.get("min_round"))):
		return false
	var budget: int = int(state.get("back_to_prev_left"))
	if budget < 1:
		return false
	var target_round: int = state.round_number - 1
	var snapshot: Dictionary = state.round_snapshots["round_end"].get(target_round, {})
	var use_disk := snapshot.is_empty()
	if use_disk and not SaveSystem.is_valid_round_end(target_round):
		return false
	if budget < state.UNLIMIT_BACK_TO_PREV_TIMES:
		state.back_to_prev_left = budget - 1
	state.global_state.round_rollback = GlobalState.ROLLBACK_TO_PREV_END
	state.global_state.save()
	if use_disk:
		if not SaveSystem.load_round_end(state, db, target_round):
			return false
	else:
		SaveSystem.deserialize(snapshot, state, db)
		if state.global_state != null and state.global_state.is_disk_bound():
			SaveSystem.save(state)
	if state.event_runtime != null:
		state.queue_event_ids(state.event_runtime.fire("back_to_prev_round_end", {}))
	return true


## Back to the current round's beginning: restore the round_begin snapshot
## taken at the end of the previous day transition (all of yesterday's
## settlements applied, today untouched).
## [SRC: DoBackToRoundBegin.c @ Do (operations.json); DatapoolExtensions.c
##       @ LoadRoundBegin; report 7 A1]
static func back_to_round_begin(state, db) -> bool:
	if state == null:
		return false
	var snapshot: Dictionary = state.round_snapshots["round_begin"].get(state.round_number, {})
	var use_disk := snapshot.is_empty()
	if use_disk and not SaveSystem.is_valid_round(state.round_number):
		return false
	if use_disk:
		if not SaveSystem.load_round(state, db, state.round_number):
			return false
	else:
		SaveSystem.deserialize(snapshot, state, db)
		if state.global_state != null and state.global_state.is_disk_bound():
			SaveSystem.save(state)
	if state.event_runtime != null:
		state.queue_event_ids(state.event_runtime.fire("back_to_round_begin", {}))
	return true


## Draw one sudan card into the active set. The pool entry IS the card: the
## original removes the Card object from player.sudan_card_pool (shuffling the
## list first when init sudan_shuffle is on) and promotes that same object, so
## its uid, count, life and runtime tag delta travel with it.
## [SRC: GameController.c @ GenSudanCard (0x54f6f0) L3610-3662:
##       Shuffle(pool) -> RemoveLast -> Card.set_bag(BagIndex) ->
##       Card.set_life(data.card_vanishing − player.sudan_card_init_life) ->
##       PlayerExtensions.AddCard/MarkCardGen -> PutCardOnTable.]
static func draw_weekly_sudan(state, db, rng) -> int:
	var entry = state.draw_sudan_pool_card(rng, db)
	if entry == null:
		return -1
	var cid := int(entry.card_id)
	var instance = _promote_sudan_pool_entry(state, db, entry)
	var card_uid := int(entry.uid)
	var lifetime: int = int(db.get_card(cid).get("card_vanishing", 7)) if db != null else 7
	var init_life: int = int(state.sudan_card_init_life)
	state.active_sudan_cards.append(
		ActiveSudan.new(cid, mini(init_life, lifetime), state.round_number, card_uid))
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
	if state.sudan_pool_size() < draw_count:
		return -1
	var old_card = state.active_sudan_cards.pop_back()
	var discarded: int = old_card.card_id
	var discarded_uid: int = old_card.card_uid
	var first_new := -1
	var rail_index: int = state.rail_order.find(discarded_uid) if state.has_method("replace_card_in_rail") else -1
	var old_instance = state.get_card_instance(discarded_uid) if state.has_method("get_card_instance") else null
	# New cards carry the discarded card's elapsed life, so the visible
	# deadline (card_vanishing − life) stays unchanged.
	# [SRC: GameController.c @ RedrawSudanCard (0x5558b0) L3830-3832:
	#       new = GenSudanCard(...); Card.set_life(new, discarded.life)]
	var carried_life: int = int(old_instance.life) if old_instance != null else 0
	if old_instance != null:
		old_instance.zone = "removed"
		old_instance.is_lost = true
	var generation_failed := false
	for i in draw_count:
		var entry = state.draw_sudan_pool_card(rng, db)
		if entry == null:
			# Error path: partially drawn cards stay out, the discarded card is
			# NOT reinserted and no redraw is consumed.
			generation_failed = true
			break
		var new_id := int(entry.card_id)
		if i == 0:
			first_new = new_id
		_promote_sudan_pool_entry(state, db, entry, carried_life)
		var new_uid := int(entry.uid)
		var new_lifetime: int = int(db.get_card(new_id).get("card_vanishing", 7)) if db != null else 7
		state.active_sudan_cards.append(
			ActiveSudan.new(new_id, new_lifetime - carried_life, state.round_number, new_uid))
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
	# The original re-inserts the discarded Card OBJECT, so its runtime delta
	# stays with it. The clone keeps a live reference to the same instance.
	# [SRC: GameController.c @ RedrawSudanCard L3840-3842:
	#       pool.Insert(Random.Range(0, pool.count), card)]
	if old_instance != null:
		state.insert_sudan_pool_card(rng, old_instance)
	# The discarded object leaves play but keeps existing for the pool.
	if old_instance != null:
		state.card_instances.erase(old_instance.uid)
	if uses_per_round:
		if state.has_method("use_sudan_per_round_redraw"):
			state.use_sudan_per_round_redraw()
		else:
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


## Move one un-drawn pool object into play as the live CardInstance. The
## original promotes the SAME Card object, so the clone promotes onto the same
## uid and keeps count plus the runtime tag delta. Documented divergences: the
## clone derives life from the head-start formula instead of reading the pool
## object's field, and re-applies the bag-page entry rule. Both are inert with
## the current content (every pool object enters at life 0, count 1, bag 0).
## [SRC: GameController.c @ GenSudanCard (0x54f6f0) L3648-3672:
##       Card.set_bag(player.BagIndex); Card.set_life(vanishing − init_life);
##       PlayerExtensions.AddCard; MarkCardGen; PutCardOnTable.]
static func _promote_sudan_pool_entry(state, db, entry, life_override: int = -1):
	var card_id := int(entry.card_id)
	# Reuse the original Card.uid; do not consume a fresh one from the counter.
	var instance = CardInstanceData.new()
	assert(not state.card_instances.has(int(entry.uid)), "Pool UID must not overwrite an existing card")
	state.card_instances[int(entry.uid)] = instance
	state.player_card_order.append(int(entry.uid))
	instance.uid = int(entry.uid)
	instance.card_id = card_id
	instance.zone = "sudan"
	instance.count = maxi(int(entry.count), 1)
	if life_override >= 0:
		instance.life = life_override
	else:
		var lifetime: int = int(db.get_card(card_id).get("card_vanishing", 7)) if db != null else 7
		instance.life = lifetime - int(state.sudan_card_init_life)
	# Pool tags are the entry's own runtime delta and travel with it.
	instance.tags = entry.tags.duplicate(true)
	instance.bag = state.current_bag_index
	if state.has_method("record_card_generation"):
		state.record_card_generation(instance, db)
	# GenSudanCard's drawn Card goes onto the table rail, so the same
	# PutCardOnTable is_only registration applies even though Sultan cards do
	# not travel through the regular hand grant helper.
	# [SRC: GameController.c @ GenSudanCard (0x54f6f0) -> PutCardOnTable (0x5556c0)]
	if state.has_method("record_only_card"):
		state.record_only_card(card_id, db)
	return instance


static func _begin_round(state, db, rng, result: Dictionary) -> void:
	result.new_round = true
	state.round_number += 1
	_reset_redraw_for_round(state, db)
	result.round_begin_events = state.trigger_events("round_begin_ba", {"round": state.round_number})
	result.auto_rites = start_auto_begin_rites(state, db)
	if state.auto_gen_sudan_card and state.active_sudan_cards.is_empty():
		result.drawn_sudan = draw_weekly_sudan(state, db, rng)


static func _reset_redraw_for_round(state, db) -> void:
	var recovery := int(state.sudan_redraw_times_recovery_round)
	# The original guards against a zero-remainder divisor: recovery < 2 resets
	# every day instead of dividing by zero.
	# [SRC: DisplayClass142_0.c @ <OnNextRound>b__9 (0x571000) lines 465-473]
	if recovery < 2 or state.round_number % recovery == 0:
		if state.has_method("reset_sudan_redraw_usage"):
			state.reset_sudan_redraw_usage()
		else:
			state.redraws_left = _redraws_per_round(state, db)


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
		# No open_condition re-check here: the DSL gate owns availability at
		# generation time; DoStartAutoBeginRite only checks start + auto_begin.
		# [SRC: GameController.c @ DoStartAutoBeginRite (0x54ebc0) L5344-5349;
		#       report 8 A7]
		state.start_rite_instance(instance.uid)
		out.append({"id": instance.id, "uid": instance.uid, "started": true})
	return out


## Update every player-owned rite once per visible day. The original advances
## Rite.life first; unstarted rites expire at waiting_round, while started
## rites settle at round_number. `auto_result` changes presentation, not this
## eligibility rule.
## [SRC: GameController.c @ UpdateSingleRite (RVA 0x55ab10), lines 5853-5882]
static func _update_rite_instances(state, db, rng, result: Dictionary, interactive: bool = false) -> void:
	if state == null or db == null or not state.has_method("available_rite_instances"):
		return
	if not result.has("unupdated_rites"):
		result["unupdated_rites"] = []
		for instance in state.available_rite_instances():
			result.unupdated_rites.append(instance.uid)
	while not result.unupdated_rites.is_empty():
		var instance = state.get_rite_instance(int(result.unupdated_rites.pop_front()))
		if instance == null or not db.rites.has(instance.id):
			continue
		var rite: Dictionary = db.rites[instance.id]
		instance.life += 1
		if not instance.start:
			var waiting_round := int(rite.get("waiting_round", 0))
			if waiting_round > 0 and instance.life >= waiting_round:
				RiteSettlement.expire(instance.uid, state, db, rng)
				result.expired_rites.append({"id": instance.id, "uid": instance.uid})
				if not state.pending_operations.is_empty() or not state.rite_settlements.is_empty():
					return
			continue
		if instance.life < int(rite.get("round_number", 0)):
			continue
		if interactive:
			if not result.has("due_rites"):
				result["due_rites"] = []
			result.due_rites.append(instance.uid)
			return
		# Headless callers use the same pausable execution host; presentation
		# decisions are supplied by RiteView only in interactive mode.
		_resolve_rite_instance(rite, instance, state, db, rng)
		result.settled_rites.append({"id": instance.id, "uid": instance.uid, "auto_result": int(rite.get("auto_result", 0)) == 1})
		# Journal: the rite settled. The original notes from the result panel
		# after settlement completes.
		# [SRC: RiteResultPanelController.__c__DisplayClass56_0 ->
		#       NoteRiteDone (0x38ec30) -> AddNote type 3]
		if not state.pending_operations.is_empty() or not state.rite_settlements.is_empty():
			return


## Continue a headless transition after its pending UI decision was answered.
## UI callers present due_rites themselves, then call the same update stage.
static func resume_day(state, db, rng) -> Dictionary:
	var result: Dictionary = state.round_transition
	if result.is_empty():
		return result
	RiteSettlement.pump(state, db, rng)
	if not state.pending_operations.is_empty() or not state.rite_settlements.is_empty():
		return result
	_pump_day(state, db, rng, result)
	return result


static func _resolve_rite_instance(rite: Dictionary, instance, state, db, rng):
	var rite_state := {}
	var attr_slots: Array = []
	for slot_key in rite.get("cards_slot", {}):
		var key := str(slot_key)
		var cards: Array = state.cards_in_slot(key.substr(1).to_int(), instance.uid)
		if not cards.is_empty():
			rite_state[key] = int(cards[0].get("id", 0))
		attr_slots.append(key)
	# Fresh tag-exercise records for this settlement; post_rite's HasTagTips
	# reads them right after resolution.
	if state.has_method("clear_tag_tips"):
		state.clear_tag_tips(instance.uid)
	var ctx := {
		"db": db, "state": state, "rng": rng, "rite_state": rite_state,
		"attr_slots": attr_slots, "rite_id": instance.id, "rite_uid": instance.uid,
		"slot_entries": state.slot_entries_for_rite(rite, instance.uid),
	}
	if state.has_method("with_player_actor_context"):
		ctx = state.with_player_actor_context(ctx, db)
	state.active_rite_uid = instance.uid
	var res = RiteResolver.select_settlements(rite, ctx, 0)
	state.active_rite_uid = 0
	var job := RiteSettlement.begin(instance.uid, res, ctx, state, db, rng)
	res.deferred = job.deferred
	return res


## Apply explicit clean instructions, return every remaining placed card, then
## remove only this runtime instance. Rite result UI does the same removal
## after its settlement pipeline completes.
## [SRC: RiteResultPanelController.__c__DisplayClass56_0.c @ <Settlement>b__8
##       (RVA 0x5b4850): RemoveRite after settlement; RiteExtensions.ReturnCards
##       (RVA 0x5016d0) for the timeout path.]
static func finalize_rite_settlement(instance, deferred: Dictionary, state, db, source_table_entries: Array = [], rng = null) -> void:
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
		var current_card = state.get_card_instance(card_uid)
		if current_card == null:
			continue
		if current_card.zone == "removed":
			# clear_slot already retires the CardInstance; the separate active
			# Sultan rail still needs to consume that same UID exactly once.
			if state.is_active_sudan_card(card_uid) and (slot_num in clean_slots or card_id in clean_card_ids):
				consume_sudan(state, card_uid)
			continue
		# An action may already have absorbed a returned card into a successor.
		# Removing the old rite must not take it back from that live owner.
		if current_card != null and current_card.zone == "slot" and current_card.rite_uid > 0 and current_card.rite_uid != instance.uid:
			continue
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
	# A completed final_pin becomes a persistent endpoint only after the live
	# Rite is removed.  It is not a new runtime Rite and cannot open a panel.
	# [SRC: RiteResultPanelController.__c__DisplayClass56_0 <Settlement>b__8:
	#       RemoveRite(player, rite.uid) -> if RiteNode.final_pin@0x34 then
	#       PlayerExtensions.AddRitePin(player, rite.id) -> GameController.AddRitePin]
	var rite_definition: Dictionary = db.get_rite(instance.id) if db != null else {}
	if bool(rite_definition.get("final_pin", false)) and state.has_method("add_rite_pin"):
		state.add_rite_pin(instance.id)




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
	return int(state.sudan_redraw_times_per_round)


## UpdateHandCardPos: normalize bag positions on the current page to 1..N in
## hand order. IsCurrentHandCard checks BagIndex and own/adherent/player;
## hidden NPCs and other pages retain their existing positions.
## [SRC: GameController.c @ UpdateHandCardPos (0x559a70) L1060-1097]
static func update_hand_card_pos(state) -> void:
	if state == null or not state.has_method("get_card_instance"):
		return
	# Active Sultan presentation is a host rail extension, not IsHandCard.
	var page: Array = state.visible_rail_card_uids().filter(func(uid): return state.is_hand_card(int(uid)))
	for index in page.size():
		state.get_card_instance(int(page[index])).bag_pos = index + 1


## Shelter for ANY card (sudan execution included) is presence in any rite
## slot, regardless of the rite's start state — the generic death check reads
## the any-slot flag directly.
## [SRC: GameController.c @ DoCardUpdate (0x54d4c0) lines 5139-5231:
##       (Card, flag) snapshot with flag=1 for every card in any rite.cards;
##       DisplayClass196_0 @ <UpdateSingleCard>b__1 (0x572420) gates only the
##       death branch on the flag while aging stays unconditional]
static func is_sheltered_in_rite_slot(state, uid: int) -> bool:
	if state == null or not state.has_method("get_card_instance"):
		return false
	var instance = state.get_card_instance(int(uid))
	return instance != null and instance.zone == "slot" and instance.rite_uid > 0
