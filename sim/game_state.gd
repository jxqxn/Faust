## Mutable game state during a run.
## Holds local/global counters, the player's hand, cards on the table (slots),
## gold (as the coin-card stack per spec sec 10.2), calendar/round, difficulty,
## and resource counters (gold dice, redraws, back-to-prev).
class_name GameState
extends RefCounted

const GameModels = preload("res://data/models.gd")

# Counter system for non-negative clamping on gated counters.
const CounterSystem = preload("res://core/counter.gd")

# Counters. Local counters are per-run; global persist across runs (prestige etc).
var local_counters := {}    # id(int) -> int
var global_counters := {}   # id(int) -> int

# Hand: card ids the player holds.
var hand: Array[int] = []
# Table: cards placed on the rite table, each {id, slot, tags, count, is_lost}.
var table_cards: Array = []
# Coin stack: the coin card (2000093) count. Gold = coin-card stack (spec 10.2).
var coin_count := 0

# Round / calendar.
var round_number := 1
var day := 1

# Difficulty index (0=easy,1=normal,2=hard) and its config.
var difficulty_index := 1
var difficulty_config := {}   # {single_dice_face_weight, sudan_life_time, gold_dice_count, ...}

# Resources.
var gold_dice := 0            # remaining gold dice this run
var redraws_left := 0         # sudan card redraws left this round
var back_to_prev_left := 0    # back-to-prev-round uses left

# Sudan cards in play (drawn, not yet consumed): each {id, days_left, ...}.
var active_sudan_cards: Array = []
# Sudan deck (shuffled pool, consumed last-first per spec sec 10.6).
var sudan_deck: Array[int] = []


func _init() -> void:
	pass


func setup_new_run(db, diff_index: int, rng) -> void:
	difficulty_index = diff_index
	difficulty_config = db.get_difficulty(diff_index)
	# Resources from difficulty.
	gold_dice = int(difficulty_config.get("gold_dice_count", 0))
	back_to_prev_left = int(difficulty_config.get("back_to_prev_round_count", 0))
	# Redraws per round (sudan_redraw_times_per_round) recovered every
	# sudan_redraw_times_recovery_round rounds.
	redraws_left = int(db.init_config.get("sudan_redraw_times_per_round", 1))
	# Starting hand: default_cards.
	for cid in db.get_default_cards():
		hand.append(int(cid))
	# Sudan deck from pool (shuffled last-first).
	sudan_deck = []
	for cid in db.get_sudan_pool():
		sudan_deck.append(int(cid))
	# Day/round.
	round_number = 1
	day = 1
	# Gold starts at a sane default (protagonist begins solvent).
	coin_count = 0


# ---- Counter access ----
func get_counter(id: int) -> int:
	return int(local_counters.get(id, 0))


func get_global_counter(id: int) -> int:
	return int(global_counters.get(id, 0))


func add_counter(id: int, delta: int) -> void:
	local_counters[id] = int(local_counters.get(id, 0)) + delta


func sub_counter(id: int, delta: int) -> void:
	local_counters[id] = int(local_counters.get(id, 0)) - delta


func set_counter(id: int, val: int) -> void:
	# Clamp non-negative for gated counters (PlayerExtensions.SetCounter).
	local_counters[id] = CounterSystem.clamp_nonneg(id, val)


func add_global_counter(id: int, delta: int) -> void:
	global_counters[id] = int(global_counters.get(id, 0)) + delta


func sub_global_counter(id: int, delta: int) -> void:
	global_counters[id] = int(global_counters.get(id, 0)) - delta


func set_global_counter(id: int, val: int) -> void:
	global_counters[id] = CounterSystem.clamp_nonneg(id, val)


# ---- Gold (coin-card stack) ----
func add_coin(n: int) -> void:
	coin_count += n


func spend_coin(n: int) -> bool:
	if coin_count < n:
		return false
	coin_count -= n
	return true


# ---- Hand ----
func has_card_in_hand(id: int) -> bool:
	return id in hand


func add_card_to_hand(id: int) -> void:
	hand.append(id)


func remove_card_from_hand(id: int) -> bool:
	var idx := hand.find(id)
	if idx >= 0:
		hand.remove_at(idx)
		return true
	return false


# ---- Hand tag queries (have.妻子 etc.) ----
func hand_has_tag(db, tag_name: String) -> bool:
	for cid in hand:
		var c: Dictionary = db.get_card(cid)
		if not c.is_empty() and int(c.get("tag", {}).get(tag_name, 0)) != 0:
			return true
	return false


func hand_has_card_id(db, card_id: int) -> bool:
	return card_id in hand


# ---- Table (slots) ----
## Cards currently in a given slot index (1-based: s1..s4).
func cards_in_slot(slot: int) -> Array:
	var out: Array = []
	for tc in table_cards:
		if int(tc.get("slot", 0)) == slot:
			out.append(tc)
	return out


func slot_has_cards(slot: int) -> bool:
	return cards_in_slot(slot).size() > 0


func clear_slot(slot: int) -> void:
	var keep: Array = []
	for tc in table_cards:
		if int(tc.get("slot", 0)) != slot:
			keep.append(tc)
	table_cards = keep


func add_card_to_slot(card_id: int, slot: int, db) -> void:
	var c: Dictionary = db.get_card(card_id)
	var entry := {
		"id": card_id,
		"slot": slot,
		"tags": c.get("tag", {}).duplicate() if not c.is_empty() else {},
		"count": 1,
		"is_lost": false,
	}
	table_cards.append(entry)
