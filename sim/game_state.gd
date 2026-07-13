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
# Table index: cards placed in a rite slot, each
# {id, slot, rite_uid, tags, count, is_lost}. RiteInstance.cards is the
# per-instance view; this flat list remains for global table conditions.
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
# How many new sudan cards a redraw draws (original player+0x68).
# [SRC: GameController.c @ RedrawSudanCard: loop bound = sudan_redraw_count]
var sudan_redraw_count := 1

# Sudan cards in play (drawn, not yet consumed): each {id, days_left, ...}.
var active_sudan_cards: Array = []
# Sudan deck (shuffled pool, consumed last-first per spec sec 10.6).
var sudan_deck: Array[int] = []
# Runtime rite instances are the authoritative player-owned ritual state.
# Config ids below remain compatibility views for code not migrated yet.
# [SRC: dump.cs:392391 Rite has uid/id/start/life/cards; StartRite.c @ Do
#       (RVA 0x51bcf0) creates an instance before GameController.AddRite.]
var rite_instances: Dictionary = {} # uid(int) -> RiteInstance
var next_rite_uid := 1
var active_rite_uid := 0
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
# Event status mirrors the original Player event-status map. Definitions in
# ConfigDB do not become live triggers until their status is enabled.
# `event_done` is a clone-side history/audit record; status remains the rule
# governing future trigger registration.
var event_status: Dictionary = {}
var event_done: Dictionary = {}
# The original auto_start_init checks the current player/template id. The clone
# currently has one normal opening template, id 1; keep it explicit so later
# opening profiles can select a different set without registering all events.
var event_init_profile_id := 1
# Event trigger dispatcher: indexes enabled event definitions for this run.
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
	# How many new sudan cards each redraw produces (init_config sudan_redraw_count).
	# [SRC: GameController.c @ RedrawSudanCard: loops sudan_redraw_count times]
	sudan_redraw_count = int(db.init_config.get("sudan_redraw_count", 1))
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
	rite_instances.clear()
	next_rite_uid = 1
	active_rite_uid = 0
	available_rites.clear()
	for rid in db.get_default_rites():
		add_available_rite(int(rid), db, rng)
	started_rites.clear()
	auto_result_rites.clear()
	rite_auto_result = false
	event_queue.clear()
	event_prompts.clear()
	event_status.clear()
	event_done.clear()
	event_init_profile_id = int(db.init_config.get("event_init_profile_id", 1))
	_rebuild_event_runtime(db)
	_enable_initial_events(db)


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


func add_available_rite(id: int, db = null, rng = null) -> int:
	if id <= 0:
		return 0
	# A generated RiteNode always becomes a fresh player-owned Rite. `once_new`
	# only changes new_born; it does not coalesce matching config ids.
	# InitRite performs open-slot adsorption before it appends the instance; a
	# missing required auto slot aborts creation and returns earlier cards.
	# [SRC: PlayerExtensions.c @ InitRite (RVA 0x38e140); RiteExtensions.c @
	# AdsorbCards (RVA 0x38fca0), RebackCards (RVA 0x392ea0)]
	var instance := create_rite_instance(id)
	if db == null:
		return instance.uid
	var rite: Dictionary = db.get_rite(id)
	if rite.is_empty():
		remove_rite_instance(instance.uid)
		return 0
	if not _adsorb_open_slots(instance, rite, db, rng):
		remove_rite_instance(instance.uid)
		return 0
	return instance.uid


func _adsorb_open_slots(instance: RiteInstance, rite: Dictionary, db, rng) -> bool:
	var slots: Dictionary = rite.get("cards_slot", {})
	var slot_keys: Array[String] = []
	for key in slots.keys():
		slot_keys.append(str(key))
	slot_keys.sort_custom(func(a: String, b: String) -> bool: return a.substr(1).to_int() < b.substr(1).to_int())
	var absorbed: Array[Dictionary] = []
	for slot_key in slot_keys:
		var slot_def: Dictionary = slots.get(slot_key, {})
		if int(slot_def.get("open_adsorb", 0)) != 1:
			continue
		var candidates: Array[int] = []
		for card_id in hand:
			var id := int(card_id)
			var card: Dictionary = db.get_card(id)
			if not _can_adsorb_card(slot_def, card, instance, rite, db, rng):
				continue
			candidates.append(id)
		if candidates.is_empty():
			if int(slot_def.get("is_empty", 0)) == 1:
				continue
			_reback_absorbed_cards(absorbed, instance.uid)
			return false
		var choice_index := 0
		if candidates.size() > 1 and rng != null and rng.has_method("range_int_half_open"):
			choice_index = int(rng.range_int_half_open(0, candidates.size()))
		var chosen_id := int(candidates[choice_index])
		if not remove_card_from_hand(chosen_id):
			_reback_absorbed_cards(absorbed, instance.uid)
			return false
		var slot_number := slot_key.substr(1).to_int()
		add_card_to_slot(chosen_id, slot_number, db, instance.uid)
		absorbed.append({"id": chosen_id, "slot": slot_number})
	return true


func _can_adsorb_card(slot_def: Dictionary, card: Dictionary, instance: RiteInstance, rite: Dictionary, db, rng) -> bool:
	if card.is_empty():
		return false
	var condition: Dictionary = slot_def.get("condition", {})
	if condition.is_empty():
		return true
	var rite_state := {}
	for entry in instance.cards:
		rite_state["s%d" % int(entry.get("slot", 0))] = int(entry.get("id", 0))
	var attr_slots: Array[String] = []
	for key in rite.get("cards_slot", {}).keys():
		attr_slots.append(str(key))
	return ConditionEval.evaluate(condition, {
		"db": db,
		"state": self,
		"rng": rng,
		"rite_state": rite_state,
		"attr_slots": attr_slots,
		"acting_card": card,
		"acting_card_id": int(card.get("id", 0)),
		"acting_card_only": true,
	})


func _reback_absorbed_cards(absorbed: Array[Dictionary], rite_uid: int) -> void:
	for entry in absorbed:
		var card_id := int(entry.get("id", 0))
		remove_card_from_slot(card_id, int(entry.get("slot", 0)), rite_uid)
		add_card_to_hand(card_id)


## Create a distinct runtime rite. Callers that intentionally generate a
## second copy must use this rather than assuming a config id is an instance.
func create_rite_instance(rite_id: int) -> RiteInstance:
	if rite_id <= 0:
		return null
	var instance := RiteInstance.new(next_rite_uid, rite_id)
	next_rite_uid += 1
	rite_instances[instance.uid] = instance
	_sync_rite_legacy_lists()
	return instance


func get_rite_instance(rite_uid: int) -> RiteInstance:
	return rite_instances.get(rite_uid, null)


func find_rite_instance_by_id(rite_id: int) -> RiteInstance:
	# Map pins are keyed by config id, while their panel needs a concrete runtime
	# Rite. The clone picks the oldest matching instance deterministically.
	var rite_uids: Array = rite_instances.keys()
	rite_uids.sort()
	for rite_uid in rite_uids:
		var instance: RiteInstance = rite_instances[rite_uid]
		if instance.id == rite_id:
			return instance
	return null


func available_rite_instances() -> Array[RiteInstance]:
	_ensure_legacy_rite_instances()
	var out: Array[RiteInstance] = []
	for rite_uid in rite_instances:
		out.append(rite_instances[rite_uid])
	out.sort_custom(func(a: RiteInstance, b: RiteInstance) -> bool: return a.uid < b.uid)
	return out


func start_rite_instance(rite_uid: int) -> bool:
	var instance := get_rite_instance(rite_uid)
	if instance == null:
		return false
	if not instance.start:
		instance.start = true
		instance.start_round = round_number
		instance.start_life = instance.life
	_sync_rite_legacy_lists()
	return true


## Return cards placed in one rite to the player's rail. This is the timeout
## path used by RiteExtensions.Dead; active Sudan cards stay active and simply
## become visible again once their table entries are removed.
## [SRC: RiteExtensions.c @ ReturnCards (RVA 0x5016d0)]
func return_rite_cards(rite_uid: int, _db) -> void:
	if rite_uid <= 0:
		return
	var cards := cards_in_slot_entries_for_rite(rite_uid)
	for table_card in cards:
		var card_id := int(table_card.get("id", 0))
		if card_id <= 0 or is_active_sudan_card(card_id):
			continue
		if not has_card_in_hand(card_id):
			add_card_to_hand(card_id)
	clear_rite_cards(rite_uid)


## Remove a finished or expired rite instance after its cards have been
## returned or consumed. PlayerExtensions.RemoveRite removes by runtime uid,
## so duplicate config ids remain independent.
## [SRC: PlayerExtensions.c @ RemoveRite (RVA 0x38f040)]
func remove_rite_instance(rite_uid: int) -> bool:
	if rite_uid <= 0 or not rite_instances.has(rite_uid):
		return false
	clear_rite_cards(rite_uid)
	rite_instances.erase(rite_uid)
	if active_rite_uid == rite_uid:
		active_rite_uid = 0
	_sync_rite_legacy_lists()
	return true


func _ensure_legacy_rite_instances() -> void:
	# Existing test fixtures and older callers may still write the compatibility
	# id arrays directly. Materialize missing instances once at this boundary.
	for rite_id in available_rites:
		if find_rite_instance_by_id(int(rite_id)) == null:
			create_rite_instance(int(rite_id))
	for rite_id in started_rites:
		var instance := find_rite_instance_by_id(int(rite_id))
		if instance == null:
			instance = create_rite_instance(int(rite_id))
		instance.start = true
	_sync_rite_legacy_lists()


func _sync_rite_legacy_lists() -> void:
	var available: Array[int] = []
	var started: Array[int] = []
	for instance in rite_instances.values():
		if not (instance.id in available):
			available.append(instance.id)
		if instance.start and not (instance.id in started):
			started.append(instance.id)
	available.sort()
	started.sort()
	available_rites = available
	started_rites = started


func queue_event(id: int) -> void:
	# A trigger can run again before the UI consumes its queued event. Keep one
	# pending entry, matching the original's immediate operation dispatch.
	if id > 0 and not (id in event_queue):
		event_queue.append(id)


## Enable and register an event. `event_on` requests start-trigger handling;
## normal new-run registration does not.
## [SRC: decompiled/EventOn.__c__DisplayClass2_0.c @ <Do>b__0 (RVA 0x51f1a0);
##       decompiled/EventTrigger.c @ Add(EventNode) (RVA 0x4fa9d0)]
func enable_event(id: int, db, fire_start_trigger: bool = false) -> bool:
	if id <= 0 or db == null or db.get_event(id).is_empty():
		return false
	event_status[id] = true
	if event_runtime == null:
		_rebuild_event_runtime(db)
	if not event_runtime.enable_event(id):
		return false
	var event: Dictionary = db.get_event(id)
	if fire_start_trigger and bool(event.get("start_trigger", false)):
		# The original starts this event's settlement immediately. The clone's
		# event display is the settlement boundary, so queue it once here.
		queue_event(id)
	return true


## Disable and unregister an event. This is the shared EventOff path.
## [SRC: decompiled/EventOff.c @ Do (RVA 0x50ef60): SetEventStatus(id, false)
##       followed by EventTrigger.Remove(id)]
func disable_event(id: int) -> void:
	if id <= 0:
		return
	event_status[id] = false
	if event_runtime != null:
		event_runtime.disable_event(id)


## Complete the currently executing event. Non-replay events unregister only
## after their settlement actually executes; replay events stay active.
## [SRC: decompiled/EventTrigger.__c__DisplayClass4_0.c @ <Add>b__0
##       (RVA 0x507360), EventNode.is_replay in dump.cs:385232]
func complete_event(id: int, is_replay: bool) -> void:
	if id <= 0:
		return
	event_done[id] = true
	if not is_replay:
		disable_event(id)


func is_event_enabled(id: int) -> bool:
	return bool(event_status.get(id, false))


func _rebuild_event_runtime(db) -> void:
	event_runtime = EventRuntime.new()
	event_runtime.build(db, self)


func _enable_initial_events(db) -> void:
	if db == null:
		return
	for eid in db.events:
		var event: Dictionary = db.events[eid]
		var init_profiles: Array = event.get("auto_start_init", [])
		if _int_list_contains(init_profiles, event_init_profile_id):
			enable_event(int(eid), db, false)


func _int_list_contains(values: Array, wanted: int) -> bool:
	for value in values:
		if int(value) == wanted:
			return true
	return false


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
## Cards currently in a given slot index. Passing rite_uid scopes the query to
## one RiteInstance; the default remains a global compatibility query.
func cards_in_slot(slot: int, rite_uid: int = 0) -> Array:
	var out: Array = []
	for tc in table_cards:
		if int(tc.get("slot", 0)) == slot and (rite_uid <= 0 or int(tc.get("rite_uid", 0)) == rite_uid):
			out.append(tc)
	return out


func cards_in_slot_entries_for_rite(rite_uid: int) -> Array:
	var out: Array = []
	if rite_uid <= 0:
		return out
	for table_card in table_cards:
		if int(table_card.get("rite_uid", 0)) == rite_uid:
			out.append(table_card.duplicate(true))
	return out


func slot_has_cards(slot: int, rite_uid: int = 0) -> bool:
	return cards_in_slot(slot, rite_uid).size() > 0


func clear_slot(slot: int, rite_uid: int = 0) -> void:
	var keep: Array = []
	for tc in table_cards:
		if int(tc.get("slot", 0)) != slot or (rite_uid > 0 and int(tc.get("rite_uid", 0)) != rite_uid):
			keep.append(tc)
	table_cards = keep
	_sync_rite_instance_cards(rite_uid)


func remove_card_from_slot(card_id: int, slot: int = 0, rite_uid: int = 0) -> bool:
	for i in range(table_cards.size() - 1, -1, -1):
		var tc: Dictionary = table_cards[i]
		if int(tc.get("id", 0)) != card_id:
			continue
		if slot > 0 and int(tc.get("slot", 0)) != slot:
			continue
		if rite_uid > 0 and int(tc.get("rite_uid", 0)) != rite_uid:
			continue
		table_cards.remove_at(i)
		_sync_rite_instance_cards(rite_uid if rite_uid > 0 else int(tc.get("rite_uid", 0)))
		return true
	return false


func remove_table_card_id(card_id: int, rite_uid: int = 0) -> void:
	var keep: Array = []
	for tc in table_cards:
		if int(tc.get("id", 0)) != card_id or (rite_uid > 0 and int(tc.get("rite_uid", 0)) != rite_uid):
			keep.append(tc)
	table_cards = keep
	_sync_rite_instance_cards(rite_uid)


func card_is_on_table(card_id: int) -> bool:
	for tc in table_cards:
		if int(tc.get("id", 0)) == card_id:
			return true
	return false


func slot_for_table_card(card_id: int, rite_uid: int = 0) -> int:
	for tc in table_cards:
		if int(tc.get("id", 0)) == card_id and (rite_uid <= 0 or int(tc.get("rite_uid", 0)) == rite_uid):
			return int(tc.get("slot", 0))
	return 0


func add_card_to_slot(card_id: int, slot: int, db, rite_uid: int = 0) -> void:
	var c: Dictionary = db.get_card(card_id)
	var entry := {
		"id": card_id,
		"slot": slot,
		"rite_uid": rite_uid,
		"tags": c.get("tag", {}).duplicate() if not c.is_empty() else {},
		"count": 1,
		"is_lost": false,
	}
	table_cards.append(entry)
	_sync_rite_instance_cards(rite_uid)


func clear_rite_cards(rite_uid: int) -> void:
	if rite_uid <= 0:
		table_cards.clear()
		for instance in rite_instances.values():
			instance.cards.clear()
		return
	var keep: Array = []
	for tc in table_cards:
		if int(tc.get("rite_uid", 0)) != rite_uid:
			keep.append(tc)
	table_cards = keep
	_sync_rite_instance_cards(rite_uid)


func _sync_rite_instance_cards(rite_uid: int = 0) -> void:
	if rite_uid > 0:
		var instance := get_rite_instance(rite_uid)
		if instance == null:
			return
		instance.cards.clear()
		for tc in table_cards:
			if int(tc.get("rite_uid", 0)) == rite_uid:
				instance.cards.append(tc)
		return
	for instance in rite_instances.values():
		_sync_rite_instance_cards(instance.uid)
