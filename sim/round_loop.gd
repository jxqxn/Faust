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
	var result := {"game_over": false, "expired": [], "new_round": false, "auto_rites": [], "drawn_sudan": -1}
	state.day += 1
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
	var result := {"game_over": false, "expired": [], "new_round": false, "auto_rites": [], "drawn_sudan": -1}
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
	var candidate_rites: Array = []
	if state != null and state.get("available_rites") != null:
		candidate_rites = state.available_rites
	else:
		candidate_rites = db.rites.keys()
	for rid in candidate_rites:
		if not db.rites.has(int(rid)):
			continue
		var rite: Dictionary = db.rites[int(rid)]
		if int(rite.get("auto_begin", 0)) != 1:
			continue
		if not RiteOpen.is_rite_open(rite, state, db, null):
			continue
		var id := int(rid)
		if not (id in state.started_rites):
			state.started_rites.append(id)
		out.append({"id": id, "started": true})
	return out


static func _redraws_per_round(state, db) -> int:
	return int(state.difficulty_config.get(
		"sudan_redraw_times_per_round",
		db.init_config.get("sudan_redraw_times_per_round", 1)
	))
