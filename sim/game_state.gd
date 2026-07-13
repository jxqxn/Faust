## Mutable game state during a run.
## Holds local/global counters, the player's hand, cards on the table (slots),
## gold (as the coin-card stack per spec sec 10.2), calendar/round, difficulty,
## and resource counters (gold dice, redraws, back-to-prev).
class_name GameState
extends RefCounted

const CardInstanceData = preload("res://sim/card_instance.gd")

# Counter system for non-negative clamping on gated counters.
# Counters. Local counters are per-run; global persist across runs (prestige etc).
var local_counters := {}    # id(int) -> int
var global_counters := {}   # id(int) -> int
# Per-run registry of counter ids gated to non-negative. Seeded with the
# special id (a hardcoded rule from the decompiled source); extend with
# register_nonneg. Kept on the instance so runs/tests stay isolated.
var _nonneg_ids := {CounterSystem.SPECIAL_NONNEG_ID: true}

# Card instances are the mutable card source of truth.  The id arrays below
# remain compatibility views while callers migrate to uid-based APIs.
var card_instances: Dictionary = {} # uid(int) -> CardInstanceData
var next_card_uid := 1
# Hand and bottom rail contain runtime CardInstance uids.  Config ids only
# cross the public compatibility boundary, where they resolve to one instance.
var hand: Array[int] = []
# Visual order for the unified bottom card rail, including hand and active
# sudan cards. Gameplay ownership still lives in hand/active_sudan_cards.
var rail_order: Array[int] = []
# Compatibility read view for table queries. Placement is owned exclusively by
# CardInstance.zone/rite_uid/slot_key; this list is rebuilt for every read so
# callers cannot create a second mutable card/tag state.
var table_cards: Array:
	get:
		return table_card_entries()
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
# Ordered runtime operation queue.  This is the single mutable presentation
# boundary for events, narration and choices; every entry retains the context
# of the occurrence that created it.
var pending_operations: Array[Dictionary] = []
# Operations scheduled by the DSL `delay` wrapper.  The original record only
# stores an id and a round; we retain the clone payload/context as well so a
# save can resume the exact occurrence.
# [SRC: decompiled/DelayOperations.c @ Do (RVA 0x39b5c0);
#       dump.cs:391358 DelayOp has id and round.]
var delayed_operations: Array[Dictionary] = []

# Legacy read views.  New code must consume `pending_operations`; these are
# retained only while external callers and older v5 saves migrate.
var event_queue: Array[int]:
	get:
		var ids: Array[int] = []
		for operation in pending_operations:
			if str(operation.get("kind", "")) == "event":
				ids.append(int(operation.get("id", 0)))
		return ids
var event_contexts: Dictionary:
	get:
		var contexts := {}
		for operation in pending_operations:
			if str(operation.get("kind", "")) == "event":
				contexts[int(operation.get("id", 0))] = operation.get("context", {}).duplicate(true)
		return contexts
var event_prompts: Array[Dictionary]:
	get:
		var prompts: Array[Dictionary] = []
		for operation in pending_operations:
			if str(operation.get("kind", "")) in ["prompt", "choice"]:
				prompts.append(operation.get("payload", {}).duplicate(true))
		return prompts
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


func create_card_instance(card_id: int, db, zone: String = "hand"):
	if card_id <= 0:
		return null
	var definition: Dictionary = db.get_card(card_id) if db != null else {}
	var instance = CardInstanceData.new(next_card_uid, card_id, definition.get("tag", {}) if not definition.is_empty() else {})
	next_card_uid += 1
	instance.zone = zone
	card_instances[instance.uid] = instance
	return instance


func get_card_instance(uid: int):
	return card_instances.get(uid, null)


func card_uid_for(card_id: int, preferred_zone: String = "") -> int:
	var candidate_uids: Array = card_instances.keys()
	candidate_uids.sort()
	for uid in candidate_uids:
		var instance = card_instances[uid]
		if instance.card_id == card_id and (preferred_zone == "" or instance.zone == preferred_zone):
			return instance.uid
	return 0


func card_data_for(uid: int, db) -> Dictionary:
	var instance = get_card_instance(uid)
	if instance == null:
		return {}
	var card: Dictionary = db.get_card(instance.card_id).duplicate(true) if db != null else {}
	# Some legacy/test callers grant by config id before a ConfigDB is threaded
	# through. Materialize the definition tags lazily at the first real lookup;
	# after that only this instance owns and mutates them.
	if instance.tags.is_empty() and not card.is_empty() and card.get("tag", {}) is Dictionary:
		instance.tags = card.get("tag", {}).duplicate(true)
	card["id"] = instance.card_id
	card["instance_uid"] = instance.uid
	card["tag"] = instance.tags.duplicate(true)
	card["count"] = instance.count
	card["is_lost"] = instance.is_lost
	return card


func _resolve_card_uid(card_or_uid: int, preferred_zone: String = "") -> int:
	if card_instances.has(card_or_uid):
		var direct = card_instances[card_or_uid]
		if preferred_zone == "" or direct.zone == preferred_zone:
			return card_or_uid
	return card_uid_for(card_or_uid, preferred_zone)


func setup_new_run(db, diff_index: int, rng) -> void:
	hand.clear()
	card_instances.clear()
	next_card_uid = 1
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
		add_card_to_hand(int(cid), db)
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
	event_contexts.clear()
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
func has_card_in_hand(card_or_uid: int) -> bool:
	var uid := _resolve_card_uid(card_or_uid, "hand")
	return uid > 0


func add_card_to_hand(card_or_uid: int, db = null) -> int:
	# Supplying a uid moves that exact runtime card. Supplying a definition id
	# creates a newly granted card; return paths must pass the uid they removed.
	var uid := card_or_uid if card_instances.has(card_or_uid) else 0
	var instance = get_card_instance(uid)
	if instance == null:
		instance = create_card_instance(card_or_uid, db, "hand")
		if instance == null:
			return 0
		uid = instance.uid
	instance.zone = "hand"
	instance.rite_uid = 0
	instance.slot_key = ""
	if uid not in hand:
		hand.append(uid)
	if uid not in rail_order:
		rail_order.append(uid)
	_sync_hand_order_from_rail()
	return uid


func insert_card_to_hand(card_or_uid: int, index: int, db = null) -> void:
	var uid := _resolve_card_uid(card_or_uid, "hand")
	if uid <= 0:
		uid = add_card_to_hand(card_or_uid, db)
	if uid <= 0:
		return
	var existing := hand.find(uid)
	if existing >= 0:
		hand.remove_at(existing)
	index = clampi(index, 0, hand.size())
	hand.insert(index, uid)
	insert_card_to_rail(uid, _rail_index_for_hand_index(index))


func remove_card_from_hand(card_or_uid: int) -> bool:
	var uid := _resolve_card_uid(card_or_uid, "hand")
	if uid <= 0:
		return false
	var instance = get_card_instance(uid)
	var idx := hand.find(uid)
	if idx >= 0:
		hand.remove_at(idx)
		_erase_one_from_rail(uid)
		instance.zone = "removed"
		return true
	return false


func insert_card_to_rail(card_or_uid: int, index: int) -> void:
	var uid := _resolve_card_uid(card_or_uid)
	if uid <= 0:
		return
	_erase_one_from_rail(uid)
	index = clampi(index, 0, rail_order.size())
	rail_order.insert(index, uid)
	_sync_hand_order_from_rail()


func remove_card_from_rail(card_or_uid: int) -> void:
	var uid := _resolve_card_uid(card_or_uid)
	if uid <= 0:
		return
	_erase_one_from_rail(uid)
	_sync_hand_order_from_rail()


func replace_card_in_rail(old_card_or_uid: int, new_card_or_uid: int) -> void:
	var old_uid := _resolve_card_uid(old_card_or_uid)
	var new_uid := _resolve_card_uid(new_card_or_uid)
	if old_uid <= 0 or new_uid <= 0:
		return
	var idx := rail_order.find(old_uid)
	if idx >= 0:
		rail_order[idx] = new_uid
	elif new_uid not in rail_order:
		rail_order.append(new_uid)
	_sync_hand_order_from_rail()


func active_sudan_card_ids() -> Array[int]:
	var out: Array[int] = []
	for asc in active_sudan_cards:
		out.append(int(asc.card_id))
	return out


func is_active_sudan_card(id: int) -> bool:
	for asc in active_sudan_cards:
		if int(asc.card_id) == id or int(asc.card_uid) == id:
			return true
	return false


func sync_rail_order() -> void:
	var valid_uids: Dictionary = {}
	for uid in hand:
		valid_uids[int(uid)] = true
	for asc in active_sudan_cards:
		var uid := int(asc.card_uid)
		if uid <= 0:
			var instance = create_card_instance(int(asc.card_id), null, "sudan")
			uid = int(instance.uid) if instance != null else 0
			asc.card_uid = uid
		if uid > 0:
			valid_uids[uid] = true

	var next_order: Array[int] = []
	for uid in rail_order:
		if valid_uids.has(int(uid)):
			next_order.append(int(uid))
			valid_uids.erase(int(uid))
	for uid in hand:
		if valid_uids.has(int(uid)):
			next_order.append(int(uid))
			valid_uids.erase(int(uid))
	for asc in active_sudan_cards:
		var uid := int(asc.card_uid)
		if valid_uids.has(uid):
			next_order.append(uid)
			valid_uids.erase(uid)
	rail_order = next_order
	_sync_hand_order_from_rail()


func visible_rail_card_uids() -> Array[int]:
	sync_rail_order()
	var out: Array[int] = []
	for uid in rail_order:
		if card_is_on_table(int(uid)):
			continue
		if int(uid) in hand or is_active_sudan_card(int(uid)):
			out.append(int(uid))
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


func _adsorb_open_slots(instance, rite: Dictionary, db, rng) -> bool:
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
		for card_uid in _adsorbable_card_uids():
			var uid := int(card_uid)
			var card: Dictionary = card_data_for(uid, db)
			if not _can_adsorb_card(slot_def, card, instance, rite, db, rng):
				continue
			candidates.append(uid)
		if candidates.is_empty():
			if int(slot_def.get("is_empty", 0)) == 1:
				continue
			_reback_absorbed_cards(absorbed, instance.uid)
			return false
		var choice_index := 0
		if candidates.size() > 1 and rng != null and rng.has_method("range_int_half_open"):
			choice_index = int(rng.range_int_half_open(0, candidates.size()))
		var chosen_uid := int(candidates[choice_index])
		if not _remove_adsorb_candidate(chosen_uid):
			_reback_absorbed_cards(absorbed, instance.uid)
			return false
		var slot_number := slot_key.substr(1).to_int()
		add_card_to_slot(chosen_uid, slot_number, db, instance.uid)
		absorbed.append({"uid": chosen_uid, "slot": slot_number})
	return true


func _adsorbable_card_uids() -> Array[int]:
	var out: Array[int] = hand.duplicate()
	for active_sudan in active_sudan_cards:
		var uid := int(active_sudan.card_uid)
		if uid > 0 and uid not in out:
			out.append(uid)
	return out


func _remove_adsorb_candidate(card_uid: int) -> bool:
	if has_card_in_hand(card_uid):
		return remove_card_from_hand(card_uid)
	if is_active_sudan_card(card_uid):
		var instance = get_card_instance(card_uid)
		if instance != null:
			instance.zone = "removed"
			return true
	return false


func _can_adsorb_card(slot_def: Dictionary, card: Dictionary, instance, rite: Dictionary, db, rng) -> bool:
	if card.is_empty():
		return false
	var condition: Dictionary = slot_def.get("condition", {})
	if condition.is_empty():
		return true
	var rite_state := {}
	for slot_key in instance.slot_cards:
		var slotted_card = card_data_for(int(instance.slot_cards[slot_key]), db)
		if not slotted_card.is_empty():
			rite_state[str(slot_key)] = int(slotted_card.get("id", 0))
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
		"acting_card_uid": int(card.get("instance_uid", 0)),
		"acting_card_only": true,
	})


func _reback_absorbed_cards(absorbed: Array[Dictionary], rite_uid: int) -> void:
	for entry in absorbed:
		var card_uid := int(entry.get("uid", 0))
		remove_card_from_slot(card_uid, int(entry.get("slot", 0)), rite_uid)
		if is_active_sudan_card(card_uid):
			var sudan_instance = get_card_instance(card_uid)
			if sudan_instance != null:
				sudan_instance.zone = "sudan"
				sudan_instance.rite_uid = 0
				sudan_instance.slot_key = ""
		else:
			add_card_to_hand(card_uid)


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
		var card_uid := int(table_card.get("card_uid", 0))
		var card_id := int(table_card.get("id", 0))
		if card_id <= 0:
			continue
		if is_active_sudan_card(card_uid):
			var sudan_instance = get_card_instance(card_uid)
			if sudan_instance != null:
				sudan_instance.zone = "sudan"
				sudan_instance.rite_uid = 0
				sudan_instance.slot_key = ""
			continue
		if card_uid > 0 and not has_card_in_hand(card_uid):
			add_card_to_hand(card_uid)
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


func queue_event(id: int, ctx: Dictionary = {}) -> void:
	if id > 0:
		queue_operation("event", id, {}, ctx)


func queue_operation(kind: String, id: Variant, payload: Dictionary = {}, context: Dictionary = {}) -> void:
	if kind.is_empty():
		return
	var operation_context := context.duplicate(true)
	# Context fields are deliberately top-level and persisted even when the
	# payload has a similar shape. This prevents same-id event occurrences from
	# overwriting each other's card/rite target.
	for key in ["card_uid", "rite_uid"]:
		if not operation_context.has(key) and payload.has(key):
			operation_context[key] = payload[key]
	pending_operations.append({
		"kind": kind,
		"id": id,
		"payload": payload.duplicate(true),
		"context": operation_context,
	})


func pending_operation() -> Dictionary:
	return pending_operations[0].duplicate(true) if not pending_operations.is_empty() else {}


func consume_pending_operation() -> Dictionary:
	if pending_operations.is_empty():
		return {}
	var operation: Dictionary = pending_operations[0]
	pending_operations.remove_at(0)
	return operation


func schedule_delay(payload: Dictionary, context: Dictionary = {}) -> void:
	if payload.is_empty():
		return
	var delay_round := maxi(int(payload.get("round", 0)), 0)
	delayed_operations.append({
		"id": int(payload.get("id", 0)),
		"round": round_number + delay_round,
		"payload": payload.duplicate(true),
		"context": context.duplicate(true),
	})


func take_due_delayed_operations() -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	var pending: Array[Dictionary] = []
	for operation in delayed_operations:
		if int(operation.get("round", 0)) <= round_number:
			due.append(operation.duplicate(true))
		else:
			pending.append(operation)
	delayed_operations = pending
	return due


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
	var trigger_ctx := ctx.duplicate(true)
	if not trigger_ctx.has("acting_card") and timing in ["card_clean", "card_born", "card_dead"]:
		var card_uid := int(trigger_ctx.get("card_uid", 0))
		if card_uid <= 0:
			card_uid = card_uid_for(int(trigger_ctx.get("card", 0)))
		var card := card_data_for(card_uid, event_runtime._db) if card_uid > 0 else {}
		if not card.is_empty():
			trigger_ctx["card_uid"] = card_uid
			trigger_ctx["acting_card"] = card
			trigger_ctx["acting_card_id"] = int(card.get("id", 0))
	var matched: Array[int] = event_runtime.fire(timing, trigger_ctx)
	for eid in matched:
		queue_event(int(eid), trigger_ctx)
	return matched


func queue_prompt(prompt: Dictionary) -> void:
	if not prompt.is_empty():
		var context: Dictionary = prompt.get("context", {}) if prompt.get("context", {}) is Dictionary else {}
		queue_operation("choice" if prompt.has("choices") else "prompt", prompt.get("id", "prompt"), prompt, context)


func queue_choice_prompt(choices: Dictionary, title: String = "选择", text: String = "请选择回应。", context: Dictionary = {}) -> void:
	if choices.is_empty():
		return
	queue_prompt({
		"id": "choose",
		"title": title,
		"text": text,
		"choices": choices.duplicate(true),
		"context": context.duplicate(true),
	})


func reorder_rail_card(card_or_uid: int, rail_index: int) -> void:
	var uid := _resolve_card_uid(card_or_uid)
	if uid <= 0 or not (uid in hand or is_active_sudan_card(uid)):
		return
	insert_card_to_rail(uid, rail_index)


func add_card_to_hand_at_rail(card_or_uid: int, rail_index: int, db = null) -> void:
	var uid := card_or_uid if card_instances.has(card_or_uid) else add_card_to_hand(card_or_uid, db)
	var instance = get_card_instance(uid)
	if instance == null:
		return
	instance.zone = "hand"
	instance.rite_uid = 0
	instance.slot_key = ""
	hand.erase(uid)
	hand.append(uid)
	_erase_one_from_rail(uid)
	rail_index = clampi(rail_index, 0, rail_order.size())
	rail_order.insert(rail_index, uid)
	_sync_hand_order_from_rail()


func _sync_hand_order_from_rail() -> void:
	if hand.is_empty():
		return
	var hand_uids := {}
	for uid in hand:
		hand_uids[int(uid)] = true
	var ordered: Array[int] = []
	for uid in rail_order:
		if hand_uids.has(int(uid)):
			ordered.append(int(uid))
			hand_uids.erase(int(uid))
	for uid in hand:
		if hand_uids.has(int(uid)):
			ordered.append(int(uid))
			hand_uids.erase(int(uid))
	hand = ordered


func _rail_index_for_hand_index(hand_index: int) -> int:
	if hand_index <= 0:
		return 0
	var seen := 0
	for i in rail_order.size():
		var uid := int(rail_order[i])
		if uid in hand:
			if seen >= hand_index:
				return i
			seen += 1
	return rail_order.size()


func _erase_one_from_rail(uid: int) -> bool:
	var idx := rail_order.find(uid)
	if idx >= 0:
		rail_order.remove_at(idx)
		return true
	return false


# ---- Hand tag queries (have.妻子 etc.) ----
func hand_has_tag(db, tag_name: String) -> bool:
	for uid in hand:
		var card: Dictionary = card_data_for(int(uid), db)
		if int(card.get("tag", {}).get(tag_name, 0)) != 0:
			return true
	return false


func hand_has_card_id(card_id: int) -> bool:
	return card_uid_for(card_id, "hand") > 0


# ---- Table (derived slot queries) ----
## Every table entry is a snapshot derived from CardInstance placement. Tags
## are intentionally duplicated so consumers must use the mutation APIs below.
func table_card_entries() -> Array:
	var out: Array = []
	var uids: Array = card_instances.keys()
	uids.sort()
	for raw_uid in uids:
		var instance = card_instances[raw_uid]
		if instance.zone != "slot" or not instance.slot_key.begins_with("s"):
			continue
		var slot: int = instance.slot_key.substr(1).to_int()
		if slot <= 0:
			continue
		out.append({
			"id": instance.card_id,
			"card_uid": instance.uid,
			"slot": slot,
			"rite_uid": instance.rite_uid,
			"tags": instance.tags.duplicate(true),
			"count": instance.count,
			"is_lost": instance.is_lost,
		})
	return out


## "table" DSL operations also see active Sudan cards, which are displayed on
## the same desktop surface but are not assigned to a rite slot.
func surface_card_entries() -> Array:
	var out := table_card_entries()
	var uids: Array = card_instances.keys()
	uids.sort()
	for raw_uid in uids:
		var instance = card_instances[raw_uid]
		if instance.zone != "sudan":
			continue
		out.append({
			"id": instance.card_id,
			"card_uid": instance.uid,
			"slot": 0,
			"rite_uid": 0,
			"tags": instance.tags.duplicate(true),
			"count": instance.count,
			"is_lost": instance.is_lost,
		})
	return out


func cards_in_slot(slot: int, rite_uid: int = 0) -> Array:
	var out: Array = []
	for entry in table_card_entries():
		if int(entry.get("slot", 0)) == slot and (rite_uid <= 0 or int(entry.get("rite_uid", 0)) == rite_uid):
			out.append(entry)
	return out


func cards_in_slot_entries_for_rite(rite_uid: int) -> Array:
	if rite_uid <= 0:
		return []
	return table_card_entries().filter(func(entry): return int(entry.get("rite_uid", 0)) == rite_uid)


func slot_has_cards(slot: int, rite_uid: int = 0) -> bool:
	return not cards_in_slot(slot, rite_uid).is_empty()


func clear_slot(slot: int, rite_uid: int = 0) -> void:
	for entry in cards_in_slot(slot, rite_uid):
		_remove_slot_instance(int(entry.get("card_uid", 0)))


func remove_card_from_slot(card_id: int, slot: int = 0, rite_uid: int = 0) -> bool:
	var target_uid := _resolve_card_uid(card_id)
	for entry in table_card_entries():
		if target_uid > 0 and int(entry.get("card_uid", 0)) != target_uid:
			continue
		if target_uid <= 0 and int(entry.get("id", 0)) != card_id:
			continue
		if slot > 0 and int(entry.get("slot", 0)) != slot:
			continue
		if rite_uid > 0 and int(entry.get("rite_uid", 0)) != rite_uid:
			continue
		_remove_slot_instance(int(entry.get("card_uid", 0)))
		return true
	return false


func remove_table_card_id(card_id: int, rite_uid: int = 0) -> void:
	for entry in table_card_entries():
		if int(entry.get("id", 0)) == card_id and (rite_uid <= 0 or int(entry.get("rite_uid", 0)) == rite_uid):
			_remove_slot_instance(int(entry.get("card_uid", 0)))


## Remove matching slotted instances for `table.clean.<card>`. A card_uid in
## the triggering context wins over config-id matching, preventing an event
## from cleaning the same-id card in another rite instance.
func clean_table_card_instances(card_id: int, rite_uid: int = 0, card_uid: int = 0, count: int = 0) -> Array:
	var cleaned: Array = []
	for entry in table_card_entries():
		if rite_uid > 0 and int(entry.get("rite_uid", 0)) != rite_uid:
			continue
		if card_uid > 0 and int(entry.get("card_uid", 0)) != card_uid:
			continue
		if int(entry.get("id", 0)) != card_id:
			continue
		cleaned.append(entry.duplicate(true))
		if count > 0 and cleaned.size() >= count:
			break
	for entry in cleaned:
		_remove_slot_instance(int(entry.get("card_uid", 0)))
	return cleaned


func card_is_on_table(card_or_uid: int) -> bool:
	var uid := _resolve_card_uid(card_or_uid)
	if uid > 0:
		var instance = get_card_instance(uid)
		return instance != null and instance.zone == "slot"
	for entry in table_card_entries():
		if int(entry.get("id", 0)) == card_or_uid:
			return true
	return false


func slot_for_table_card(card_or_uid: int, rite_uid: int = 0) -> int:
	var uid := _resolve_card_uid(card_or_uid)
	for entry in table_card_entries():
		var matches := int(entry.get("card_uid", 0)) == uid if uid > 0 else int(entry.get("id", 0)) == card_or_uid
		if matches and (rite_uid <= 0 or int(entry.get("rite_uid", 0)) == rite_uid):
			return int(entry.get("slot", 0))
	return 0


func add_card_to_slot(card_or_uid: int, slot: int, db, rite_uid: int = 0) -> void:
	if slot <= 0:
		return
	var uid := _resolve_card_uid(card_or_uid)
	var instance = get_card_instance(uid)
	if instance == null:
		instance = create_card_instance(card_or_uid, db, "slot")
		if instance == null:
			return
		uid = instance.uid
	_unlink_slot_instance(instance)
	if rite_uid > 0:
		var rite := get_rite_instance(rite_uid)
		if rite != null:
			var slot_key := "s%d" % slot
			var previous_uid := int(rite.slot_cards.get(slot_key, 0))
			if previous_uid > 0 and previous_uid != uid:
				_remove_slot_instance(previous_uid)
			rite.slot_cards[slot_key] = uid
	if uid in hand:
		hand.erase(uid)
		_erase_one_from_rail(uid)
	instance.zone = "slot"
	instance.rite_uid = rite_uid
	instance.slot_key = "s%d" % slot


func clear_rite_cards(rite_uid: int) -> void:
	for entry in table_card_entries():
		if rite_uid <= 0 or int(entry.get("rite_uid", 0)) == rite_uid:
			_remove_slot_instance(int(entry.get("card_uid", 0)))


func _remove_slot_instance(uid: int) -> void:
	var instance = get_card_instance(uid)
	if instance == null or instance.zone != "slot":
		return
	_unlink_slot_instance(instance)
	instance.zone = "removed"
	instance.rite_uid = 0
	instance.slot_key = ""


func _unlink_slot_instance(card_instance) -> void:
	if card_instance == null or card_instance.rite_uid <= 0:
		return
	var rite := get_rite_instance(int(card_instance.rite_uid))
	if rite != null and int(rite.slot_cards.get(card_instance.slot_key, 0)) == int(card_instance.uid):
		rite.slot_cards.erase(card_instance.slot_key)


## Rebuild the RiteInstance lookup from the authoritative card positions after
## a load. Invalid/duplicate positions are discarded deterministically.
func _sync_rite_instance_cards(_rite_uid: int = 0) -> void:
	for rite in rite_instances.values():
		rite.slot_cards.clear()
	var entries := table_card_entries()
	for entry in entries:
		var uid := int(entry.get("card_uid", 0))
		var rite_uid := int(entry.get("rite_uid", 0))
		if rite_uid <= 0:
			continue
		var rite := get_rite_instance(rite_uid)
		if rite == null:
			_remove_slot_instance(uid)
			continue
		var slot_key := "s%d" % int(entry.get("slot", 0))
		if rite.slot_cards.has(slot_key):
			_remove_slot_instance(uid)
			continue
		rite.slot_cards[slot_key] = uid
