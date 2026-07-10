## Mutable game state during a run.
## Holds local/global counters, the player's hand, cards on the table (slots),
## gold (as the coin-card stack per spec sec 10.2), calendar/round, difficulty,
## and resource counters (gold dice, redraws, back-to-prev).
class_name GameState
extends RefCounted

# Counter system for non-negative clamping on gated counters.
# Counters. Local counters are per-run; global persist across runs (prestige etc).
var local_counters := {}    # id(int) -> int
var global_counters := {}   # id(int) -> int
# Per-run registry of counter ids gated to non-negative. Seeded with the
# special id (a hardcoded rule from the decompiled source); extend with
# register_nonneg. Kept on the instance so runs/tests stay isolated.
var _nonneg_ids := {CounterSystem.SPECIAL_NONNEG_ID: true}

# Hand: card ids the player holds.
var hand: Array[int] = []
# Visual order for the unified bottom card rail, including hand and active
# sudan cards. Gameplay ownership still lives in hand/active_sudan_cards.
var rail_order: Array[int] = []
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
# Rites started/opened by auto-begin processing. Auto-begin is not the same as
# auto-resolve; the original DoStartAutoBeginRite calls Rite.set_start.
var started_rites: Array[int] = []
# Rites that currently exist in the player's world. Original StartRite creates
# rite instances before DoStartAutoBeginRite starts eligible ones.
var available_rites: Array[int] = []
# Runtime auto-resolution state. The original tracks auto_result_rites and a
# rite_auto_result flag separately from auto_begin.
var auto_result_rites: Array[int] = []
var rite_auto_result := false
var event_queue: Array[int] = []
var event_prompts: Array[Dictionary] = []
# Event trigger dispatcher: rebuilt from db on each run (config is static; the
# match state derives from round/rite/card counters at fire time).
var event_runtime = null


func _init() -> void:
	pass


func setup_new_run(db, diff_index: int, rng) -> void:
	hand.clear()
	rail_order.clear()
	difficulty_index = diff_index
	difficulty_config = db.get_difficulty(diff_index)
	# Resources from difficulty.
	gold_dice = int(difficulty_config.get("gold_dice_count", 0))
	back_to_prev_left = int(difficulty_config.get("back_to_prev_round_count", 0))
	# Redraws per round (sudan_redraw_times_per_round) recovered every
	# sudan_redraw_times_recovery_round rounds.
	redraws_left = _redraws_per_round(db)
	# Starting hand comes through ConfigDB so normal and test profiles stay split.
	for cid in db.get_default_cards():
		hand.append(int(cid))
		rail_order.append(int(cid))
	# Sudan deck from pool (shuffled last-first).
	sudan_deck = SudanCards.build_deck(rng, db.get_sudan_pool(), bool(db.init_config.get("sudan_shuffle", true)))
	# Day/round.
	round_number = 1
	day = 1
	# Gold starts at a sane default (protagonist begins solvent).
	coin_count = 0
	available_rites.clear()
	for rid in db.get_default_rites():
		var id := int(rid)
		if not (id in available_rites):
			available_rites.append(id)
	started_rites.clear()
	auto_result_rites.clear()
	rite_auto_result = false
	event_queue.clear()
	event_prompts.clear()
	# Build the event trigger registry from config.
	event_runtime = EventRuntime.new()
	event_runtime.build(db, self)


func _redraws_per_round(db) -> int:
	return int(difficulty_config.get(
		"sudan_redraw_times_per_round",
		db.init_config.get("sudan_redraw_times_per_round", 1)
	))


# ---- Counter access ----
func register_nonneg(id: int) -> void:
	_nonneg_ids[id] = true


func is_nonneg_gated(id: int) -> bool:
	return CounterSystem.is_nonneg_gated(id, _nonneg_ids)


func get_counter(id: int) -> int:
	return int(local_counters.get(id, 0))


func get_global_counter(id: int) -> int:
	return int(global_counters.get(id, 0))


func add_counter(id: int, delta: int) -> void:
	local_counters[id] = int(local_counters.get(id, 0)) + delta


func sub_counter(id: int, delta: int) -> void:
	# Clamp non-negative for gated counters, matching set_counter. SUB can drive
	# a gated counter negative otherwise, violating the documented invariant.
	local_counters[id] = CounterSystem.clamp_nonneg(id, int(local_counters.get(id, 0)) - delta, _nonneg_ids)


func set_counter(id: int, val: int) -> void:
	# Clamp non-negative for gated counters (PlayerExtensions.SetCounter).
	local_counters[id] = CounterSystem.clamp_nonneg(id, val, _nonneg_ids)


func add_global_counter(id: int, delta: int) -> void:
	global_counters[id] = int(global_counters.get(id, 0)) + delta


func sub_global_counter(id: int, delta: int) -> void:
	global_counters[id] = CounterSystem.clamp_nonneg(id, int(global_counters.get(id, 0)) - delta, _nonneg_ids)


func set_global_counter(id: int, val: int) -> void:
	global_counters[id] = CounterSystem.clamp_nonneg(id, val, _nonneg_ids)


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
	rail_order.append(id)
	_sync_hand_order_from_rail()


func insert_card_to_hand(id: int, index: int) -> void:
	var existing := hand.find(id)
	if existing >= 0:
		hand.remove_at(existing)
	index = clampi(index, 0, hand.size())
	hand.insert(index, id)
	insert_card_to_rail(id, _rail_index_for_hand_index(index))


func remove_card_from_hand(id: int) -> bool:
	var idx := hand.find(id)
	if idx >= 0:
		hand.remove_at(idx)
		_erase_one_from_rail(id)
		return true
	return false


func insert_card_to_rail(id: int, index: int) -> void:
	_erase_one_from_rail(id)
	index = clampi(index, 0, rail_order.size())
	rail_order.insert(index, id)
	_sync_hand_order_from_rail()


func remove_card_from_rail(id: int) -> void:
	_erase_one_from_rail(id)
	_sync_hand_order_from_rail()


func replace_card_in_rail(old_id: int, new_id: int) -> void:
	var idx := rail_order.find(old_id)
	if idx >= 0:
		rail_order[idx] = new_id
	elif new_id not in rail_order:
		rail_order.append(new_id)
	_sync_hand_order_from_rail()


func active_sudan_card_ids() -> Array[int]:
	var out: Array[int] = []
	for asc in active_sudan_cards:
		out.append(int(asc.card_id))
	return out


func is_active_sudan_card(id: int) -> bool:
	for asc in active_sudan_cards:
		if int(asc.card_id) == id:
			return true
	return false


func sync_rail_order() -> void:
	var valid_counts := {}
	for cid in hand:
		var id := int(cid)
		valid_counts[id] = int(valid_counts.get(id, 0)) + 1
	for cid in active_sudan_card_ids():
		var id := int(cid)
		valid_counts[id] = int(valid_counts.get(id, 0)) + 1

	var next_order: Array[int] = []
	var remaining: Dictionary = valid_counts.duplicate()
	for cid in rail_order:
		var id := int(cid)
		if int(remaining.get(id, 0)) > 0:
			next_order.append(id)
			remaining[id] = int(remaining[id]) - 1
	for cid in hand:
		var id := int(cid)
		if int(remaining.get(id, 0)) > 0:
			next_order.append(id)
			remaining[id] = int(remaining[id]) - 1
	for cid in active_sudan_card_ids():
		var id := int(cid)
		if int(remaining.get(id, 0)) > 0:
			next_order.append(id)
			remaining[id] = int(remaining[id]) - 1
	rail_order = next_order
	_sync_hand_order_from_rail()


func visible_rail_card_ids() -> Array[int]:
	sync_rail_order()
	var out: Array[int] = []
	for cid in rail_order:
		var id := int(cid)
		if card_is_on_table(id):
			continue
		if id in hand or is_active_sudan_card(id):
			out.append(id)
	return out


func add_available_rite(id: int) -> void:
	if id <= 0:
		return
	if not (id in available_rites):
		available_rites.append(id)


func queue_event(id: int) -> void:
	if id > 0:
		event_queue.append(id)


## Fire the event trigger for `timing` and queue any matched events. A thin
## convenience over EventRuntime.fire so callers don't loop the result set.
func trigger_events(timing: String, ctx: Dictionary = {}) -> Array[int]:
	if event_runtime == null:
		return []
	var matched: Array[int] = event_runtime.fire(timing, ctx)
	for eid in matched:
		queue_event(int(eid))
	return matched


func queue_prompt(prompt: Dictionary) -> void:
	if not prompt.is_empty():
		event_prompts.append(prompt.duplicate(true))


func queue_choice_prompt(choices: Dictionary, title: String = "选择", text: String = "请选择回应。") -> void:
	if choices.is_empty():
		return
	queue_prompt({
		"id": "choose",
		"title": title,
		"text": text,
		"choices": choices.duplicate(true),
	})


func reorder_rail_card(id: int, rail_index: int) -> void:
	if not (id in hand or is_active_sudan_card(id)):
		return
	insert_card_to_rail(id, rail_index)


func add_card_to_hand_at_rail(id: int, rail_index: int) -> void:
	hand.append(id)
	rail_index = clampi(rail_index, 0, rail_order.size())
	rail_order.insert(rail_index, id)
	_sync_hand_order_from_rail()


func _sync_hand_order_from_rail() -> void:
	if hand.is_empty():
		return
	var hand_counts := {}
	for cid in hand:
		var id := int(cid)
		hand_counts[id] = int(hand_counts.get(id, 0)) + 1
	var ordered: Array[int] = []
	for cid in rail_order:
		var id := int(cid)
		if int(hand_counts.get(id, 0)) > 0:
			ordered.append(id)
			hand_counts[id] = int(hand_counts[id]) - 1
	for cid in hand:
		var id := int(cid)
		if int(hand_counts.get(id, 0)) > 0:
			ordered.append(id)
			hand_counts[id] = int(hand_counts[id]) - 1
	hand = ordered


func _rail_index_for_hand_index(hand_index: int) -> int:
	if hand_index <= 0:
		return 0
	var seen := 0
	for i in rail_order.size():
		var id := int(rail_order[i])
		if id in hand:
			if seen >= hand_index:
				return i
			seen += 1
	return rail_order.size()


func _erase_one_from_rail(id: int) -> bool:
	var idx := rail_order.find(id)
	if idx >= 0:
		rail_order.remove_at(idx)
		return true
	return false


# ---- Hand tag queries (have.妻子 etc.) ----
func hand_has_tag(db, tag_name: String) -> bool:
	for cid in hand:
		var c: Dictionary = db.get_card(cid)
		if not c.is_empty() and int(c.get("tag", {}).get(tag_name, 0)) != 0:
			return true
	return false


func hand_has_card_id(card_id: int) -> bool:
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


func remove_card_from_slot(card_id: int, slot: int = 0) -> bool:
	for i in range(table_cards.size() - 1, -1, -1):
		var tc: Dictionary = table_cards[i]
		if int(tc.get("id", 0)) != card_id:
			continue
		if slot > 0 and int(tc.get("slot", 0)) != slot:
			continue
		table_cards.remove_at(i)
		return true
	return false


func remove_table_card_id(card_id: int) -> void:
	var keep: Array = []
	for tc in table_cards:
		if int(tc.get("id", 0)) != card_id:
			keep.append(tc)
	table_cards = keep


func card_is_on_table(card_id: int) -> bool:
	for tc in table_cards:
		if int(tc.get("id", 0)) == card_id:
			return true
	return false


func slot_for_table_card(card_id: int) -> int:
	for tc in table_cards:
		if int(tc.get("id", 0)) == card_id:
			return int(tc.get("slot", 0))
	return 0


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
