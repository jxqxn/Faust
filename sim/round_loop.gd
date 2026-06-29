## Round/calendar loop. Advances visible days, manages sudan card deadlines,
## redraws, and event-driven round starts.
class_name RoundLoop
extends RefCounted

const SudanCards = preload("res://sim/sudan_cards.gd")


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
		else:
			still_active.append(asc)
	state.active_sudan_cards = still_active
	if not result.game_over and state.active_sudan_cards.is_empty():
		_begin_round(state, db, rng, result)
	return result


## Draw one sudan card into the active set.
static func draw_weekly_sudan(state, db, rng) -> int:
	var life: int = int(state.difficulty_config.get("sudan_life_time", 7))
	var cid: int = SudanCards.draw(state.sudan_deck)
	if cid < 0:
		return -1
	state.active_sudan_cards.append(ActiveSudan.new(cid, life, state.round_number))
	return cid


## Start a new round explicitly and draw a sudan card if the pool still has one.
static func start_round(state, db, rng) -> int:
	state.round_number += 1
	var recovery := int(db.init_config.get("sudan_redraw_times_recovery_round", 7))
	if state.round_number % recovery == 0:
		state.redraws_left = int(db.init_config.get("sudan_redraw_times_per_round", 1))
	return draw_weekly_sudan(state, db, rng)


## Original redraw order: draw the new card from the finite pool first, then
## insert the discarded card back at Random.Range(0,count).
## [SRC: GameController.c @ RedrawSudanCard (0x5558b0)]
static func use_redraw(state, rng) -> int:
	if state.redraws_left <= 0:
		return -1
	if state.active_sudan_cards.is_empty():
		return -1
	if state.sudan_deck.is_empty():
		return -1
	var discarded: int = state.active_sudan_cards.pop_back().card_id
	var carried_life: int = int(state.difficulty_config.get("sudan_life_time", 7))
	var new_id: int = SudanCards.draw(state.sudan_deck)
	if not state.sudan_deck.is_empty():
		SudanCards.redraw(rng, state.sudan_deck, discarded)
	else:
		state.sudan_deck.append(discarded)
	if new_id >= 0:
		state.active_sudan_cards.append(ActiveSudan.new(new_id, carried_life, state.round_number))
		state.redraws_left -= 1
	return new_id


## Consume a sudan card. The caller may then call start_round_if_no_sudan to
## match TryGenSudanCard's "draw when none active" behavior.
static func consume_sudan(state, card_id: int) -> bool:
	for i in state.active_sudan_cards.size():
		if state.active_sudan_cards[i].card_id == card_id:
			state.active_sudan_cards.remove_at(i)
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


## Open/start auto-begin rites. Do not resolve them: the original
## DoStartAutoBeginRite calls Rite.set_start, while auto-resolve is a separate
## runtime state machine (Player.auto_result_rites / rite_auto_result).
## [SRC: GameController.c @ DoStartAutoBeginRite (0x54ebc0)]
static func start_auto_begin_rites(state, db) -> Array:
	var out: Array = []
	for rid in db.rites:
		var rite: Dictionary = db.rites[rid]
		if int(rite.get("auto_begin", 0)) != 1:
			continue
		var id := int(rid)
		if not (id in state.started_rites):
			state.started_rites.append(id)
		out.append({"id": id, "started": true})
	return out
