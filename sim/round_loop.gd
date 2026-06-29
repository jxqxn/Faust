## Round/calendar loop. Advances days and rounds, manages sudan card deadlines,
## triggers auto-rites (per-round), and processes the per-round sudan draw +
## redraw recovery.
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
## When the day count reaches the round length, start a new round.
## Returns {game_over, expired, new_round, auto_rites, drawn_sudan}.
static func advance_day(state, db, rng) -> Dictionary:
	var result := {"game_over": false, "expired": [], "new_round": false, "auto_rites": [], "drawn_sudan": -1}
	state.day += 1
	# Each day advances all active sudan deadlines.
	var still_active: Array = []
	for asc in state.active_sudan_cards:
		asc.days_left -= 1
		if asc.days_left <= 0:
			result.expired.append(asc.card_id)
			result.game_over = true
		else:
			still_active.append(asc)
	state.active_sudan_cards = still_active
	# Round transition: a round spans `sudan_life_time` days (same as the sudan
	# deadline). When the day count crosses a round boundary, start a new round:
	# draw weekly sudan, recover redraws, fire auto-rites.
	# [SRC: GameController.c @ OnBeginRound (0x5537b0) -> RoundBegin event]
	var life: int = int(state.difficulty_config.get("sudan_life_time", 7))
	if state.day % life == 0 and not result.game_over:
		result.new_round = true
		var drawn := start_round(state, db, rng)
		result.drawn_sudan = drawn
		result.auto_rites = run_auto_rites(state, db, rng)
	return result


## Draw the weekly sudan card at the start of a new round.
static func draw_weekly_sudan(state, db, rng) -> int:
	var life: int = int(state.difficulty_config.get("sudan_life_time", 7))
	var cid: int = SudanCards.draw(state.sudan_deck)
	if cid < 0:
		return -1
	state.active_sudan_cards.append(ActiveSudan.new(cid, life, state.round_number))
	return cid


## Start a new round: increment round, recover redraws, draw weekly sudan.
## Auto-rites are fired separately by advance_day (caller controls ordering).
static func start_round(state, db, rng) -> int:
	state.round_number += 1
	var recovery := int(db.init_config.get("sudan_redraw_times_recovery_round", 7))
	if state.round_number % recovery == 0:
		state.redraws_left = int(db.init_config.get("sudan_redraw_times_per_round", 1))
	return draw_weekly_sudan(state, db, rng)


## Use a redraw: gate up front, generate new card, THEN consume a redraw charge.
## [SRC: GameController.c @ RedrawSudanCard (0x5558b0):
##   gate: GetSudanRedrawCount(player) <= redraw_used -> early return;
##   success: GenSudanCard loop -> set_life(old,0) -> Insert(Random.Range(0,count),old);
##   counter: redraw_used += 1 AFTER success, else UseSudanExtraRedraw]
## The original generates fresh cards (GenSudanCard), not pops from a finite
## deck. We approximate by re-inserting the discarded card and drawing from the
## pool (finite deck is a [RUNTIME_OPEN] simplification until GenSudanCard is
## reverse-engineered in full).
static func use_redraw(state, rng) -> int:
	# Gate FIRST: no redraws left or no active card to discard -> fail before consuming.
	if state.redraws_left <= 0:
		return -1
	if state.active_sudan_cards.is_empty():
		return -1
	if state.sudan_deck.is_empty():
		return -1
	# Remove the most recent active sudan card.
	var discarded: int = state.active_sudan_cards.pop_back().card_id
	# Re-insert it into the deck at a random position, then draw.
	SudanCards.redraw(rng, state.sudan_deck, discarded)
	var life: int = int(state.difficulty_config.get("sudan_life_time", 7))
	var new_id: int = SudanCards.draw(state.sudan_deck)
	if new_id >= 0:
		state.active_sudan_cards.append(ActiveSudan.new(new_id, life, state.round_number))
		# Consume the redraw charge ONLY after a successful generate+insert.
		state.redraws_left -= 1
	return new_id


## Consume a sudan card (player satisfied its requirement). Returns true if found.
static func consume_sudan(state, card_id: int) -> bool:
	for i in state.active_sudan_cards.size():
		if state.active_sudan_cards[i].card_id == card_id:
			state.active_sudan_cards.remove_at(i)
			return true
	return false


## Run all rites flagged auto_begin, once per round (NOT per day).
## [SRC: GameController.c @ OnBeginRound (0x5537b0) -> RoundBegin event
##  -> DoStartAutoBeginRite (0x54ebc0); 5000001 tips_text: "每回合自动进行"]
static func run_auto_rites(state, db, rng) -> Array:
	var out: Array = []
	for rid in db.rites:
		var rite: Dictionary = db.rites[rid]
		if int(rite.get("auto_begin", 0)) != 1:
			continue
		# Only auto-resolve rites with auto_result=1. Many rites have auto_begin=1
		# (404) but only 7 also have auto_result=1 — those are the ones that
		# actually fire their settlement automatically. The rest are auto-opened
		# but require player interaction.
		if int(rite.get("auto_result", 0)) != 1:
			continue
		var ctx := {"db": db, "state": state, "rng": rng, "rite_state": {}, "attr_slots": ["s1", "s2"], "rite_id": int(rid)}
		var res := RiteResolver.resolve(rite, ctx, 0)
		out.append({"id": int(rid), "result": res})
	return out
