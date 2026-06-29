## Round/calendar loop. Advances days and rounds, manages sudan card deadlines,
## triggers auto-rites, and processes the per-round sudan draw + redraw recovery.
## spec sec 8 + verified life-time: sudan_life_time 7/7/5 (easy/normal/hard) days.
class_name RoundLoop
extends RefCounted

const SudanCards = preload("res://sim/sudan_cards.gd")
const RiteResolver = preload("res://sim/rite_resolver.gd")


## A sudan card in play with a countdown.
class ActiveSudan:
	var card_id: int = 0
	var days_left: int = 0
	var drawn_round: int = 0
	func _init(cid: int, life: int, rnd: int) -> void:
		card_id = cid
		days_left = life
		drawn_round = rnd


## Advance one day: decrement active sudan deadlines; expired cards = game over.
## Returns a Dictionary {game_over: bool, expired:[card_ids], auto_rites:[...]}.
static func advance_day(state, db, rng) -> Dictionary:
	var result := {"game_over": false, "expired": [], "auto_rites": []}
	state.day += 1
	# Each day advances all active sudan deadlines.
	var still_active: Array = []
	for asc in state.active_sudan_cards:
		asc.days_left -= 1
		if asc.days_left <= 0:
			# Deadline expired without consumption -> game over.
			result.expired.append(asc.card_id)
			result.game_over = true
		else:
			still_active.append(asc)
	state.active_sudan_cards = still_active
	# Run auto-rites (auto_begin=1) for the day. The classic example is
	# 治理家业 (5000001) which runs automatically each round.
	_run_auto_rites(state, db, rng, result)
	return result


## Draw the weekly sudan card at the start of a new round.
static func draw_weekly_sudan(state, db, rng) -> int:
	var life: int = int(state.difficulty_config.get("sudan_life_time", 7))
	var cid: int = SudanCards.draw(state.sudan_deck)
	if cid < 0:
		return -1
	state.active_sudan_cards.append(ActiveSudan.new(cid, life, state.round_number))
	return cid


## Start a new round: draw sudan card, recover redraws, increment round.
static func start_round(state, db, rng) -> int:
	state.round_number += 1
	# Recover redraws per sudan_redraw_times_recovery_round.
	var recovery := int(db.init_config.get("sudan_redraw_times_recovery_round", 7))
	if state.round_number % recovery == 0:
		state.redraws_left = int(db.init_config.get("sudan_redraw_times_per_round", 1))
	return draw_weekly_sudan(state, db, rng)


## Use a redraw: discard current sudan card and draw a new one.
## Returns the new card id, or -1 if no redraws left / deck empty.
static func use_redraw(state, rng) -> int:
	if state.redraws_left <= 0 or state.sudan_deck.is_empty():
		return -1
	state.redraws_left -= 1
	# Remove the most recent active sudan card.
	if state.active_sudan_cards.is_empty():
		return -1
	var discarded: int = state.active_sudan_cards.pop_back().card_id
	# Re-insert it into the deck at a random position, then draw.
	SudanCards.redraw(rng, state.sudan_deck, discarded)
	var life: int = int(state.difficulty_config.get("sudan_life_time", 7))
	var new_id: int = SudanCards.draw(state.sudan_deck)
	if new_id >= 0:
		state.active_sudan_cards.append(ActiveSudan.new(new_id, life, state.round_number))
	return new_id


## Consume a sudan card (player satisfied its requirement). Returns true if found.
static func consume_sudan(state, card_id: int) -> bool:
	for i in state.active_sudan_cards.size():
		if state.active_sudan_cards[i].card_id == card_id:
			state.active_sudan_cards.remove_at(i)
			return true
	return false


# Run rites flagged auto_begin for the day. Returns their results in result.auto_rites.
static func _run_auto_rites(state, db, rng, result: Dictionary) -> void:
	# 5000001 治理家业 is the canonical auto rite; run it each round.
	# (A full implementation iterates all rites with auto_begin=1; we start with
	# the canonical one and expand as the UI wires more.)
	var rite: Dictionary = db.get_rite(5000001)
	if rite.is_empty():
		return
	if int(rite.get("auto_begin", 0)) != 1:
		return
	var ctx := {"db": db, "state": state, "rng": rng, "rite_state": {}, "attr_slots": ["s1", "s2"], "rite_id": 5000001}
	var res := RiteResolver.resolve(rite, ctx, 0)
	result.auto_rites.append({"id": 5000001, "result": res})
