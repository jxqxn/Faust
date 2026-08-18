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
# The player always acts through one concrete protagonist instance. Other
# character cards remain world people that the protagonist can involve in an
# action; moving one into a rite never changes the player actor.
#
# This is an innovation-layer interpretation of the verified CardInstance
# boundary, not a claim about an additional field in the original runtime.
var player_actor_uid := 0
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
# Gold is carried as stacked gold cards (id 2000029) in hand, matching the
# original GenCoin chain: each coin op grants a fresh card object whose count
# is the op value; the player total is the sum of object counts.
# [SRC: GenCoin.c Do 0x510b40: GenCard/AddCard(0x1E849D=2000029) ->
# Card.set_count(value) -> set_bagpos(1) -> OnCardBorn; multi-object stacks
# confirmed in corpus save_samples (神的乙太 2001090 x20, each count=1)]
const GOLD_CARD_ID := 2000029

var coin_count: int:
	get:
		return gold_total()
	set(value):
		reconcile_gold(value)

# Round / calendar.
var round_number := 1
var day := 1
# Lower bound for the back-to-prev rollback (original persists it on the
# player; OnPrevRound reads it directly and clamps to >= 1).
# [SRC: dump.cs Player min_round @0x30; GameController.c OnPrevRound
#       (0x554f80) L2149-2156: if player.round <= max(1, min_round) reject]
var min_round := 1

# Lateral-scene progress is run state, not UI state. Keeping only a location,
# spawn and normalized position makes saves independent from viewport size and
# allows the presentation to be rebuilt safely after loading.
var world_location_id := "school_rooftop"
var world_spawn_id := "default"
var world_position_ratio := 0.5
var visited_world_locations: Array[String] = ["school_rooftop"]

# Difficulty index (0=easy,1=normal,2=hard) and its config.
var difficulty_index := 1
var difficulty_config := {}   # {single_dice_face_weight, sudan_life_time, gold_dice_count, ...}

# Resources.
# Gold dice live in the counter dict (COUNTER_GOLD_DICE), granted from the
# difficulty config and spent through Add/SubCounter; counter-change timing
# events fire on writes like the original TIMING_COUNTER_CHANGED.
# [SRC: dump.cs:542529 COUNTER_GOLD_DICE = 7100006; PlayerExtensions.c
# grant 0x38be50-ish block @ lines 2268-2273 / spend @ 2368-2373; save sample
# difficulty=1 -> counter 7100006=3 matches init gold_dice_count [0,3,2,1]]
const COUNTER_GOLD_DICE := 7100006

var gold_dice: int:
	get:
		return get_counter(COUNTER_GOLD_DICE)
	set(value):
		set_counter(COUNTER_GOLD_DICE, maxi(value, 0))

# Back-to-prev-round quota. Stored on the global object (original Global,
# global.json), not the run payload, so the rollback restore cannot refund the
# spend; 9999 = UNLIMIT_BACK_TO_PREV_TIMES and never decrements.
# [SRC: dump.cs:542530 COUNTER_BACK_TO_PREV = 7100007, :542532
#       UNLIMIT_BACK_TO_PREV_TIMES = 9999; PlayerExtensions.c GetCounter
#       0x38ce70 L1103-1108 / SetCounter 0x38f2d0 L941-966 route the id to
#       Global.backToPrevRound with an unconditional non-negative clamp;
#       GameController.c OnPrevRound 0x554f80 L2169-2174 consume flag]
const COUNTER_BACK_TO_PREV := 7100007
const UNLIMIT_BACK_TO_PREV_TIMES := 9999

var back_to_prev_left: int:
	get:
		return get_counter(COUNTER_BACK_TO_PREV)
	set(value):
		set_counter(COUNTER_BACK_TO_PREV, value)

# Cross-run global domain. Fresh instances own a detached GlobalState so tests
# stay isolated; the UI/save layer attaches the disk-backed default
# (GlobalState.load_default()) for persistence.
var global_state := GlobalState.new()

var redraws_left := 0         # sudan card redraws left this round
# How many new sudan cards a redraw draws (original player+0x68).
# [SRC: GameController.c @ RedrawSudanCard: loop bound = sudan_redraw_count]
var sudan_redraw_count := 1

# Sudan cards in play (drawn, not yet consumed): each {id, days_left, ...}.
var active_sudan_cards: Array = []
# Sudan deck (shuffled pool, consumed last-first per spec sec 10.6).
var sudan_deck: Array[int] = []
var sudan_pool_tags: Dictionary = {} # card_id -> runtime tags for un-drawn pool entries
var auto_gen_sudan_card := true
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
# Config ids of rites that finished settlement at least once, id -> times ended.
# Backs the `rite_end.<id>` condition; the original keeps an ended-rite lookup
# on the player object.
# [SRC: decompiled/RiteEnd.c @ IsSatisfied (RVA 0x405300): player+0x110 lookup]
var ended_rites: Dictionary = {}
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
# Per-(timing, event) next-fire round for round-based timings, mirroring the
# original Player.timing_rounds dictionary (player+0x128). Armed when the
# event is enabled (TimingRoundBase.OnStart), compared in IsValid, and
# re-armed by NextRound at fire time; removed for non-replay events (OnEnd).
# Key format: "round_begin_ba:5300009" -> 10 (next round this event may fire).
var timing_rounds: Dictionary = {}
# The original auto_start_init checks the current player/template id. The clone
# currently has one normal opening template, id 1; keep it explicit so later
# opening profiles can select a different set without registering all events.
var event_init_profile_id := 1
# Event trigger dispatcher: indexes enabled event definitions for this run.
var event_runtime = null
# Daily full-state snapshots for the back-to-prev-round flow, kept in memory
# for the latest two rounds only (the original Datapool keeps round-formatted
# SavePlayer payloads; not persisted in the v5 player save — they rebuild
# from the current round after loading).
# [SRC: GameController.c @ OnNextRound (0x554540) L1936 SaveRoundEnd at the
#       chain head and b__9 (0x571000) L490 SaveRoundBegin at the tail;
#       DatapoolExtensions.c @ SaveRoundEnd (0x3f9120) / SaveRoundBegin
#       (0x3f9050); report 7 A1]
var round_snapshots := {"round_end": {}, "round_begin": {}}
# The manual rite-panel "restore last placement" cache. The original keeps
# this independently from round rollback: rite config id -> slot guid ->
# LastCardData{id,count}. Auto-adsorb slots are intentionally excluded.
# [SRC: RitePanelController.c @ OnConfirm (0x58f1c0) L1282-1288 stores
#       player.last_round_rite_data; @ OnLastState (0x58fdf0); dump.cs
#       Player.last_round_rite_data @0x158, RiteNode.Slot.open_adsorb @0x20]
var last_round_rite_data: Dictionary = {}
# Player-level display-name overrides, keyed by definition id. They are
# separate from Card.custom_name: GetName checks player_card_name first, and
# rites resolve custom_rite_name before their configured title.
# [SRC: CardExtensions.c @ GetName (0x37ff50) player+0x170 lookup precedes
#       Card.custom_name; Player.c @ SetRiteCustomName (0x3a4520) player+0x168;
#       PlayerExtensions.c @ GetRiteCustomName (0x38dcb0)]
var custom_rite_names: Dictionary = {}
var player_card_names: Dictionary = {}
# Active on-screen beginner-guide directive from the last `begin_guide`
# action (type/anim_type/pos/ring_pos/bind...). `close_begin_guide` clears
# it. Presentation cues (focus/hand_pop/rite_pop/slide/close_*) accumulate
# in guide_cues for the overlay; the rules layer never reads them.
# [SRC: BeginGuideController.c @ ShowBeginGuide (0x526220) /
#       GetBeginGuideItem (0x525630); CloseBeginGuide.c]
var begin_guide: Dictionary = {}
var guide_cues: Array = []
# Ending id from the fatal operation's `over` value (Sultan cards carry
# their execution ending in vanish.over). The game-over screen maps it to
# the over.json ending table entry.
var over_reason := 0
# Set when a silently-settled event chain requests game over; the UI checks
# and clears it after its current surface closes.
var over_pending := false
# Session-local outcome of the last confirm dialog (true = cancelled);
# consumers read it after the interaction resolves. Not persisted.
var last_confirm_cancelled := false
# Deterministic RNG for silent event settlements fired outside a caller's
# RNG scope (round boundaries, counter changes).
var _event_rng = null


func _init() -> void:
	# Keep the dice counter non-negative under direct Add/SubCounter calls
	# (the original gates spends; the clone guards the store itself).
	register_nonneg(COUNTER_GOLD_DICE)


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
	card["tag"] = effective_card_tags(instance.uid, db)
	card["count"] = instance.count
	card["is_lost"] = instance.is_lost
	card["rare"] = clampi(int(card.get("rare", 1)) + instance.rare_up, 1, 4)
	var player_name := str(player_card_names.get(instance.card_id, ""))
	if not player_name.is_empty():
		card["name"] = player_name
	elif not instance.custom_name.is_empty():
		card["name"] = instance.custom_name
	if not instance.custom_text.is_empty():
		card["text"] = instance.custom_text
	card["base_name"] = str(db.get_card(instance.card_id).get("name", "")) if db != null else ""
	card["rare_up"] = instance.rare_up
	card["equip_slots"] = card_equip_slots(instance.uid, db)
	card["equipped_uids"] = instance.equipped_uids.duplicate()
	var equipped_cards: Array[Dictionary] = []
	for equipped_uid in instance.equipped_uids:
		var equipped = get_card_instance(int(equipped_uid))
		if equipped == null:
			continue
		var equipped_definition: Dictionary = db.get_card(equipped.card_id).duplicate(true) if db != null else {}
		equipped_definition["instance_uid"] = equipped.uid
		equipped_definition["equipped_slot"] = equipped.equipped_slot
		equipped_cards.append(equipped_definition)
	card["equipped_cards"] = equipped_cards
	return card


func effective_card_tags(uid: int, db) -> Dictionary:
	var instance = get_card_instance(uid)
	if instance == null:
		return {}
	var effective: Dictionary = instance.tags.duplicate(true)
	for equipped_uid in instance.equipped_uids:
		var equipped = get_card_instance(int(equipped_uid))
		if equipped == null or equipped.zone != "equipped":
			continue
		for tag_name in equipped.tags:
			if not _equipment_tag_contributes(str(tag_name), db):
				continue
			effective[str(tag_name)] = int(effective.get(str(tag_name), 0)) + int(equipped.tags[tag_name])
	return effective


func _equipment_tag_contributes(tag_name: String, db) -> bool:
	if db == null:
		return false
	var code := str(db.tag_name_to_code.get(tag_name, ""))
	if code.is_empty() or not db.tags_by_code.has(code):
		return false
	# The equip recursion gate is TagNode+0x42 (can_inherit); +0x43
	# (can_nagative_and_zero) only masks negative reported values in GetTag.
	# [SRC: CardExtensions.c @ GetTag (RVA 0x3814a0) line 1604 gate at +0x42,
	#       negative mask at 1619-1622 via +0x43; dump.cs:386944-386950
	#       (0x40 can_add / 0x42 can_inherit / 0x43 can_nagative_and_zero)]
	return int(db.tags_by_code[code].get("can_inherit", 0)) != 0


func set_card_custom_name(uid: int, value: String) -> bool:
	var instance = get_card_instance(uid)
	var clean_value := value.strip_edges().left(32)
	if instance == null or clean_value.is_empty():
		return false
	instance.custom_name = clean_value
	return true


func set_player_card_name(card_id: int, value: String) -> bool:
	var clean_value := value.strip_edges()
	if card_id <= 0 or clean_value.is_empty():
		return false
	player_card_names[card_id] = clean_value
	return true


func set_rite_custom_name(rite_id: int, value: String) -> bool:
	var clean_value := value.strip_edges()
	if rite_id <= 0 or clean_value.is_empty():
		return false
	custom_rite_names[rite_id] = clean_value
	return true


func rite_display_name(rite_id: int, db) -> String:
	var custom := str(custom_rite_names.get(rite_id, ""))
	if not custom.is_empty():
		return custom
	return str(db.get_rite(rite_id).get("name", rite_id)) if db != null else str(rite_id)


func set_card_custom_text(uid: int, value: String) -> bool:
	var instance = get_card_instance(uid)
	if instance == null:
		return false
	instance.custom_text = value.strip_edges()
	return true


func modify_card_rarity(uid: int, delta: int, db) -> bool:
	var instance = get_card_instance(uid)
	if instance == null or db == null:
		return false
	var base_rare := int(db.get_card(instance.card_id).get("rare", 1))
	var before := clampi(base_rare + instance.rare_up, 1, 4)
	var after := clampi(before + delta, 1, 4)
	instance.rare_up += after - before
	return after != before


func card_equip_slots(uid: int, db) -> Array[String]:
	var instance = get_card_instance(uid)
	if instance == null:
		return []
	var slots: Array[String] = []
	if db != null:
		for slot in db.get_card(instance.card_id).get("equips", []):
			slots.append(str(slot))
	for removed_slot in instance.removed_equip_slots:
		var removed_index := slots.find(str(removed_slot))
		if removed_index >= 0:
			slots.remove_at(removed_index)
	for slot in instance.equip_slots:
		slots.append(str(slot))
	return slots


func add_card_equip_slot(uid: int, slot: String, db) -> bool:
	var instance = get_card_instance(uid)
	if instance == null:
		return false
	var normalized := _equip_slot_name(slot, db)
	if normalized.is_empty():
		return false
	instance.equip_slots.append(normalized)
	return true


func remove_card_equip_slot(uid: int, slot: String, db) -> bool:
	var instance = get_card_instance(uid)
	if instance == null:
		return false
	var normalized := _equip_slot_name(slot, db)
	var added_index: int = instance.equip_slots.find(normalized)
	if added_index >= 0:
		instance.equip_slots.remove_at(added_index)
	elif normalized in card_equip_slots(uid, db):
		instance.removed_equip_slots.append(normalized)
	else:
		return false
	for equipment_uid in instance.equipped_uids.duplicate():
		var equipment = get_card_instance(int(equipment_uid))
		if equipment != null and equipment.equipped_slot == normalized:
			detach_equipment(uid, int(equipment_uid), true)
			break
	return true


func attach_equipment(host_uid: int, equipment_uid: int, db, recover_replaced := false, enforce_slot := false) -> int:
	var host = get_card_instance(host_uid)
	var equipment = get_card_instance(equipment_uid)
	if host == null or equipment == null or host_uid == equipment_uid:
		return -1
	if enforce_slot and (
		host.zone != "hand"
		or equipment.zone != "hand"
		or int(equipment.tags.get("装备", 0)) < 1
	):
		return -1
	var slot := _matching_equip_slot(host_uid, equipment_uid, db)
	if enforce_slot and slot.is_empty():
		return -1
	# Interactive CanEquip accepts only a hand-card host and an equipment-tagged
	# hand card whose category intersects a host slot. Operation-driven +equip
	# deliberately calls this with enforce_slot=false (see ResultExec).
	# [SRC: decompiled/CardExtensions.c @ CanEquip (RVA 0x37ec10);
	#  decompiled/CardController.c @ CardEquip (RVA 0x528020).]
	var replaced_uid := 0
	if recover_replaced and not slot.is_empty():
		var slot_capacity := card_equip_slots(host_uid, db).count(slot)
		var occupying_uids: Array[int] = []
		for current_uid in host.equipped_uids:
			var current = get_card_instance(int(current_uid))
			if current != null and current.equipped_slot == slot:
				occupying_uids.append(int(current.uid))
		if occupying_uids.size() >= slot_capacity and not occupying_uids.is_empty():
			replaced_uid = occupying_uids[0]
			detach_equipment(host_uid, replaced_uid, true)
	if equipment.zone == "hand":
		hand.erase(equipment_uid)
		_erase_one_from_rail(equipment_uid)
	elif equipment.zone == "slot":
		_unlink_slot_instance(equipment)
	if equipment.equipped_to_uid > 0:
		detach_equipment(equipment.equipped_to_uid, equipment_uid, false)
	equipment.zone = "equipped"
	equipment.rite_uid = 0
	equipment.slot_key = ""
	equipment.equipped_to_uid = host_uid
	equipment.equipped_slot = slot
	if equipment_uid not in host.equipped_uids:
		host.equipped_uids.append(equipment_uid)
	return replaced_uid


func detach_equipment(host_uid: int, equipment_uid: int, recover_to_hand := false) -> bool:
	var host = get_card_instance(host_uid)
	var equipment = get_card_instance(equipment_uid)
	if host == null or equipment == null or equipment_uid not in host.equipped_uids:
		return false
	host.equipped_uids.erase(equipment_uid)
	equipment.equipped_to_uid = 0
	equipment.equipped_slot = ""
	equipment.zone = "removed"
	if recover_to_hand:
		add_card_to_hand(equipment_uid)
	return true


func _matching_equip_slot(host_uid: int, equipment_uid: int, db) -> String:
	var equipment = get_card_instance(equipment_uid)
	if equipment == null:
		return ""
	for slot in card_equip_slots(host_uid, db):
		if int(equipment.tags.get(slot, 0)) > 0:
			return slot
	return ""


func _equip_slot_name(slot: String, db) -> String:
	var value := slot.strip_edges()
	if db != null and db.tags_by_code.has(value):
		return str(db.tags_by_code[value].get("name", value))
	return value


func repair_equipment_links() -> void:
	# Treat the parent list and child's backlink as a single persisted relation.
	# Malformed/partial saves must not leave invisible cards contributing stats.
	for host in card_instances.values():
		var valid: Array[int] = []
		var seen: Dictionary = {}
		for raw_uid in host.equipped_uids:
			var equipment_uid := int(raw_uid)
			var equipment = get_card_instance(equipment_uid)
			if (
				equipment == null
				or equipment_uid == int(host.uid)
				or seen.has(equipment_uid)
				or equipment.zone != "equipped"
				or equipment.equipped_to_uid != int(host.uid)
			):
				continue
			seen[equipment_uid] = true
			valid.append(equipment_uid)
		host.equipped_uids = valid
	for equipment in card_instances.values():
		if equipment.zone != "equipped":
			continue
		var host = get_card_instance(int(equipment.equipped_to_uid))
		if host == null or int(equipment.uid) not in host.equipped_uids:
			equipment.zone = "removed"
			equipment.equipped_to_uid = 0
			equipment.equipped_slot = ""


func _resolve_card_uid(card_or_uid: int, preferred_zone: String = "") -> int:
	if card_instances.has(card_or_uid):
		var direct = card_instances[card_or_uid]
		if preferred_zone == "" or direct.zone == preferred_zone:
			return card_or_uid
	return card_uid_for(card_or_uid, preferred_zone)


## Resolve the one character whose attention and decisions the player controls.
## Prefer the saved UID, then the explicit protagonist tag, then the clone's
## established protagonist definition. This keeps old v5 saves compatible.
func ensure_player_actor(db) -> int:
	var current = get_card_instance(player_actor_uid)
	if current != null and not current.is_lost:
		var current_definition: Dictionary = db.get_card(current.card_id) if db != null else {}
		var current_tags: Dictionary = current_definition.get("tag", {})
		if int(current_tags.get("主角", 0)) > 0:
			return player_actor_uid
	var candidate_uids: Array = card_instances.keys()
	candidate_uids.sort()
	for uid in candidate_uids:
		var instance = card_instances[uid]
		if instance.is_lost:
			continue
		var definition: Dictionary = db.get_card(instance.card_id) if db != null else {}
		if int(definition.get("tag", {}).get("主角", 0)) > 0:
			player_actor_uid = int(uid)
			return player_actor_uid
	player_actor_uid = card_uid_for(2000001)
	return player_actor_uid


func player_actor_data(db) -> Dictionary:
	var uid := ensure_player_actor(db)
	return card_data_for(uid, db) if uid > 0 else {}


## Add the single-character perspective to an existing rule context without
## replacing `acting_card`, which still means the card currently inspected by
## a source-compatible condition or event trigger.
func with_player_actor_context(context: Dictionary, db) -> Dictionary:
	var out := context.duplicate(true)
	var uid := ensure_player_actor(db)
	out["player_actor_uid"] = uid
	var actor = get_card_instance(uid)
	out["player_actor_id"] = int(actor.card_id) if actor != null else 0
	return out


## Player-facing semantic role of a runtime card in the single-character
## presentation. Definitions and settlement behavior remain unchanged.
func card_perspective_role(card_or_uid: int, db) -> String:
	var uid := _resolve_card_uid(card_or_uid)
	var card: Dictionary = card_data_for(uid, db) if uid > 0 else db.get_card(card_or_uid)
	if card.is_empty():
		return ""
	if uid > 0 and uid == ensure_player_actor(db):
		return "自身"
	match str(card.get("type", "")):
		"char":
			return "相关人物"
		"sudan":
			return "外部压力"
		"item":
			return "可用事物"
	return "当前对象"


func setup_new_run(db, diff_index: int, rng, apply_resources := true) -> void:
	hand.clear()
	card_instances.clear()
	next_card_uid = 1
	player_actor_uid = 0
	rail_order.clear()
	difficulty_index = diff_index
	difficulty_config = db.get_difficulty(diff_index)
	# A fresh run starts from fresh counters (new Player) and the unlimited
	# back-to-prev baseline. The original grants no resources until the narrator
	# pick (StartGame only resets the quota); menu new games therefore pass
	# apply_resources=false and let the intro panel's SetDifficulty grant.
	# [SRC: Datapool.c @ StartGame L4497: Global.backToPrevRound = 9999, no
	#       counter writes before the pick; PlayerExtensions.c SetDifficulty
	#       L2268-2294 is the first (and additive) gold-dice grant]
	local_counters.clear()
	global_state.back_to_prev_round = UNLIMIT_BACK_TO_PREV_TIMES
	if apply_resources:
		_apply_difficulty_resources()
	global_state.save()
	# Redraws per round (sudan_redraw_times_per_round) recovered every
	# sudan_redraw_times_recovery_round rounds.
	redraws_left = _redraws_per_round(db)
	# How many new sudan cards each redraw produces (init_config sudan_redraw_count).
	# [SRC: GameController.c @ RedrawSudanCard: loops sudan_redraw_count times]
	sudan_redraw_count = int(db.init_config.get("sudan_redraw_count", 1))
	# Starting hand comes through ConfigDB so normal and test profiles stay split.
	for cid in db.get_default_cards():
		add_card_to_hand(int(cid), db)
	ensure_player_actor(db)
	# Sudan deck from pool (shuffled last-first).
	sudan_deck = SudanCards.build_deck(rng, db.get_sudan_pool(), bool(db.init_config.get("sudan_shuffle", true)))
	sudan_pool_tags.clear()
	auto_gen_sudan_card = true
	# Day/round. The first round begins after initial events are armed (see
	# below); day counts start at 1.
	day = 1
	world_location_id = "school_rooftop"
	world_spawn_id = "default"
	world_position_ratio = 0.5
	visited_world_locations = ["school_rooftop"]
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
	timing_rounds.clear()
	event_init_profile_id = int(db.init_config.get("event_init_profile_id", 1))
	# Arm initial events from round 0 like a fresh original Player, then leave
	# the round at 1 for the caller. The actual round-1 OnRoundBeginBa fire
	# belongs to the new-game entry (ui/game.gd _start_new_run), mirroring the
	# original startup chain; sim-level callers reach it on the first advance.
	# [SRC: TimingRoundBase.c @ OnStart arms next = value + player.round;
	#       GameController.__c__DisplayClass141_0.c @ <Start>b__5 (0x56f9c0)]
	round_number = 0
	min_round = 1
	_rebuild_event_runtime(db)
	_enable_initial_events(db)
	round_number = 1


func _redraws_per_round(db) -> int:
	return int(difficulty_config.get(
		"sudan_redraw_times_per_round",
		db.init_config.get("sudan_redraw_times_per_round", 1)
	))


## Difficulty pick resource rebalance, shared by new-run setup and mid-run
## switches (event `difficulty` action opens the narrator choice; the pick
## applies here). Gold dice ADD the difficulty's allowance to what the player
## still holds; the back-to-prev budget rebalances against the unlimited
## baseline (old - 9999 + new), so leaving the free-rollback difficulty resets
## to the new allowance and any finite-to-finite switch drains to zero.
## [SRC: SetDifficulty.c @ Do (0x51b5b0) -> ShowDifficulty + Then-apply;
##       PlayerExtensions.c @ SetDifficulty (0x38f530) L2246-2296: SetCounter
##       (7100006, diff.gold_dice_count + current) and SetCounter(7100007,
##       Global.backToPrevRound - 9999 + diff.back_to_prev_round_count)]
func _apply_difficulty_resources() -> void:
	set_counter(COUNTER_GOLD_DICE, get_counter(COUNTER_GOLD_DICE)
		+ int(difficulty_config.get("gold_dice_count", 0)))
	set_counter(COUNTER_BACK_TO_PREV, get_counter(COUNTER_BACK_TO_PREV)
		- UNLIMIT_BACK_TO_PREV_TIMES
		+ int(difficulty_config.get("back_to_prev_round_count", 0)))


## Mid-run difficulty switch. Per-round redraws refresh; resource counters
## rebalance through _apply_difficulty_resources.
func apply_difficulty(index: int, db) -> void:
	if db == null or db.get_difficulty(index).is_empty():
		return
	difficulty_index = index
	difficulty_config = db.get_difficulty(index)
	redraws_left = _redraws_per_round(db)
	_apply_difficulty_resources()


# ---- Counter access ----
func register_nonneg(id: int) -> void:
	_nonneg_ids[id] = true


func is_nonneg_gated(id: int) -> bool:
	return CounterSystem.is_nonneg_gated(id, _nonneg_ids)


func get_counter(id: int) -> int:
	# COUNTER_BACK_TO_PREV lives on the global object, not the run's counter
	# dict. [SRC: PlayerExtensions.c GetCounter 0x38ce70 L1103-1108]
	if id == COUNTER_BACK_TO_PREV:
		return global_state.back_to_prev_round
	return int(local_counters.get(id, 0))


func get_global_counter(id: int) -> int:
	return int(global_counters.get(id, 0))


func set_counter(id: int, val: int) -> void:
	if id == COUNTER_BACK_TO_PREV:
		# Dedicated branch: unconditional non-negative clamp, write the global
		# object; the run's counter dict is never touched.
		# [SRC: PlayerExtensions.c SetCounter 0x38f2d0 L941-966]
		var clamped_back := maxi(val, 0)
		if global_state.back_to_prev_round != clamped_back:
			global_state.back_to_prev_round = clamped_back
			_notify_counter_changed(id, clamped_back)
		return
	# Clamp non-negative for gated counters (PlayerExtensions.SetCounter).
	var clamped := CounterSystem.clamp_nonneg(id, val, _nonneg_ids)
	if int(local_counters.get(id, 0)) != clamped:
		local_counters[id] = clamped
		_notify_counter_changed(id, clamped)
	else:
		local_counters[id] = clamped


func add_counter(id: int, delta: int) -> void:
	set_counter(id, get_counter(id) + delta)


func sub_counter(id: int, delta: int) -> void:
	set_counter(id, get_counter(id) - delta)


## Counter-timing events fire on actual value changes.
## [SRC: GameController.c @ OnCounterChanged (0x4f9770 callers at 9052/9116)]
func _notify_counter_changed(id: int, new_value: int) -> void:
	if event_runtime != null:
		queue_event_ids(event_runtime.fire("counter", {"counter_id": id, "value": new_value}))


func add_global_counter(id: int, delta: int) -> void:
	var before := int(global_counters.get(id, 0))
	global_counters[id] = before + delta
	if before != int(global_counters[id]):
		_notify_global_counter_changed(id, int(global_counters[id]))


func sub_global_counter(id: int, delta: int) -> void:
	var before := int(global_counters.get(id, 0))
	global_counters[id] = CounterSystem.clamp_nonneg(id, before - delta, _nonneg_ids)
	if before != int(global_counters[id]):
		_notify_global_counter_changed(id, int(global_counters[id]))


func set_global_counter(id: int, val: int) -> void:
	var clamped := CounterSystem.clamp_nonneg(id, val, _nonneg_ids)
	if int(global_counters.get(id, 0)) != clamped:
		global_counters[id] = clamped
		_notify_global_counter_changed(id, clamped)
	else:
		global_counters[id] = clamped


## [SRC: GameController.c @ OnGlobalCounterChanged (0x4f9a30, callers 9052/9116)]
func _notify_global_counter_changed(id: int, new_value: int) -> void:
	if event_runtime != null:
		queue_event_ids(event_runtime.fire("global_counter", {"counter_id": id, "value": new_value}))


func queue_event_ids(ids: Array) -> void:
	for eid in ids:
		queue_event(int(eid))


# ---- Gold (stacked gold card, id 2000029) ----

func gold_total() -> int:
	# GetCounter(COUNTER_CURRENT_COIN_COUNT_ID 7000105) is a derived read summing
	# gold cards across the player's cards AND rite slots; the clone mirrors it
	# by zone. [SRC: PlayerExtensions.c GetCounter 0x38ce70 @ 0x6ad029 branch]
	var total := 0
	for uid in card_instances:
		var instance = card_instances[uid]
		if instance.card_id == GOLD_CARD_ID and instance.zone in ["hand", "slot"]:
			total += instance.count
	return total


func gold_card_uids() -> Array[int]:
	# Payment-side enumeration covers the player's card list (hand objects);
	# slot-embedded gold spending is pending payer-body evidence.
	var uids: Array[int] = []
	for uid in hand:
		var instance = get_card_instance(int(uid))
		if instance != null and instance.card_id == GOLD_CARD_ID:
			uids.append(int(uid))
	return uids


func add_coin(n: int, db = null) -> void:
	# GenCoin writes the op value onto a fresh gold card object whatever the
	# sign (Card.set_count(value)); negative totals are representable.
	if n == 0:
		return
	_grant_gold(n, db)


func spend_coin(n: int) -> bool:
	if gold_total() < n:
		return false
	_remove_gold(n)
	return true


func reconcile_gold(target: int, db = null) -> void:
	var desired := maxi(target, 0)
	var current := gold_total()
	if desired == current:
		return
	if desired < current:
		_remove_gold(current - desired)
	else:
		_grant_gold(desired - current, db)


func _grant_gold(amount: int, db = null) -> void:
	if amount == 0:
		return
	var effective_db = db
	if effective_db == null and event_runtime != null:
		effective_db = event_runtime._db
	if effective_db == null:
		push_warning("GameState: gold granted without db; gold card carries no config tags")
	var uid := add_card_to_hand(GOLD_CARD_ID, effective_db)
	if uid <= 0:
		return
	var instance = get_card_instance(uid)
	instance.count = amount
	# GenCoin pins the gold stack to the front of the hand (set_bagpos(1)).
	insert_card_to_hand(uid, 0)
	instance.bag_pos = 1
	trigger_events("card_born", {"card": GOLD_CARD_ID, "card_uid": uid})


func _remove_gold(amount: int) -> void:
	# CostCondition.IsSatisfied picks payer cards in player.cards enumeration
	# order (insertion order = uid ascending here) until the cost is covered,
	# recording them as need_cost_cards; the payer later consumes exactly that
	# selection. Partial decrement on the last object is total-equivalent to
	# the original remove-and-return-change model (payer body not decompiled).
	# [SRC: CostCondition.c IsSatisfied 0x3f6160 loop @ FUN_1800032d0 add +
	# SetNeedCosts; ConditionContext need_cost_cards dump.cs:383873]
	var remaining := amount
	var instances: Array = []
	for uid in gold_card_uids():
		var instance = get_card_instance(uid)
		if instance != null:
			instances.append(instance)
	instances.sort_custom(func(a, b): return a.uid < b.uid)
	for instance in instances:
		if remaining <= 0:
			break
		if int(instance.count) <= 0:
			continue
		var take: int = mini(int(instance.count), remaining)
		instance.count -= take
		remaining -= take
		if instance.count <= 0:
			remove_card_from_hand(instance.uid)
			card_instances.erase(instance.uid)


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


## Return a hand CardInstance with exactly `amount` of `card_id`, creating a
## Copy-style split or merging later matching hand objects as needed. Returns
## 0 without mutating state when the hand lacks the requested total.
## [SRC: RitePanelController.c @ OnLastState (0x58fdf0): GetHandCards,
##       CardExtensions.Copy, then split/merge to LastCardData.count]
func take_hand_card_count(card_id: int, amount: int) -> int:
	if card_id <= 0 or amount <= 0:
		return 0
	var candidates: Array = []
	var total := 0
	for uid in hand:
		var instance = get_card_instance(int(uid))
		if instance != null and instance.card_id == card_id:
			candidates.append(instance)
			total += int(instance.count)
	if total < amount or candidates.is_empty():
		return 0
	var selected = candidates[0]
	if int(selected.count) > amount:
		var split = _copy_card_for_stack(selected, amount)
		selected.count -= amount
		add_card_to_hand(split.uid)
		return split.uid
	if int(selected.count) == amount:
		return selected.uid
	var remaining := amount - int(selected.count)
	for index in range(1, candidates.size()):
		var donor = candidates[index]
		var donor_count := int(donor.count)
		if donor_count <= remaining:
			remaining -= donor_count
			remove_card_from_hand(donor.uid)
			card_instances.erase(donor.uid)
		else:
			donor.count -= remaining
			remaining = 0
			break
	selected.count = amount
	return selected.uid


func _copy_card_for_stack(source, amount: int):
	var copied = CardInstanceData.new(next_card_uid, source.card_id, source.tags)
	next_card_uid += 1
	copied.count = amount
	copied.life = source.life
	copied.is_lost = source.is_lost
	copied.rare_up = source.rare_up
	copied.custom_name = source.custom_name
	copied.custom_text = source.custom_text
	copied.bag = source.bag
	copied.bag_pos = source.bag_pos
	copied.equip_slots = source.equip_slots.duplicate()
	copied.removed_equip_slots = source.removed_equip_slots.duplicate()
	copied.zone = "hand"
	card_instances[copied.uid] = copied
	return copied


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


## Record the manual slots exactly as RitePanelController.OnConfirm does.
## The cache key is the rite definition id (not the runtime instance uid),
## because the original indexes Player.last_round_rite_data by Rite.id.
func record_last_round_rite_data(rite_uid: int, db) -> void:
	var rite := get_rite_instance(rite_uid)
	if rite == null or db == null:
		return
	var definition: Dictionary = db.get_rite(rite.id)
	var slot_defs: Dictionary = definition.get("cards_slot", {})
	var saved_slots := {}
	for raw_slot_key in rite.slot_cards:
		var slot_key := str(raw_slot_key)
		var slot_def: Dictionary = slot_defs.get(slot_key, {})
		# Slot.open_adsorb lives at +0x20 in the original RiteNode.Slot. The
		# confirmation snapshot skips it; this is not the is_enemy flag.
		if int(slot_def.get("open_adsorb", 0)) != 0:
			continue
		var card = get_card_instance(int(rite.slot_cards[raw_slot_key]))
		if card != null:
			saved_slots[slot_key] = {"id": card.card_id, "count": int(card.count)}
	last_round_rite_data[rite.id] = saved_slots


func get_last_round_rite_data(rite_id: int) -> Dictionary:
	var saved = last_round_rite_data.get(rite_id, last_round_rite_data.get(str(rite_id), {}))
	return saved.duplicate(true) if saved is Dictionary else {}


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


## Stop a started rite: keep the instance and its placed cards, roll life back
## to start_life, clear new_born so the panel no longer treats it as fresh.
## [SRC: RitePanelController.c @ OnStop (RVA 0x5906e0): set_start(0),
##       set_life(start_life @+0x28), new_born=false, then Show again]
func stop_rite_instance(rite_uid: int) -> bool:
	var instance := get_rite_instance(rite_uid)
	if instance == null or not instance.start:
		return false
	instance.start = false
	instance.life = instance.start_life
	instance.new_born = false
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
## Remove rite instances by config id (CleanRite). rite_id <= 1 removes every
## instance except `except_uid` (the settling rite); otherwise only instances
## of that config id are removed. Cards placed in removed rites go with them.
## [SRC: CleanRite.c @ Do (RVA 0x4f3ae0): player.rites(+0x90) RemoveAll with
##       the settling-rite exclusion; single value 1 = all others]
func remove_rite_instances_by_id(rite_id: int, except_uid: int = 0) -> int:
	var removed := 0
	for uid in rite_instances.keys().duplicate():
		var instance: RiteInstance = rite_instances[uid]
		if int(instance.uid) == except_uid:
			continue
		if rite_id <= 1 or int(instance.id) == rite_id:
			remove_rite_instance(int(instance.uid))
			removed += 1
	return removed


## Slot entries for condition contexts: every slotted card annotated with its
## slot key and is_enemy side. FuncCompare expressions split friend/enemy card
## sets from this (e() iterates the enemy side, bare tags the friend side).
## [SRC: RiteNode cards_slot is_enemy flags; FuncCompare.c @ Execute 0x3f9b20
##       iterates ctx.friends / ctx.enemys]
func slot_entries_for_rite(rite: Dictionary, rite_uid: int) -> Array:
	var out: Array = []
	var slots: Dictionary = rite.get("cards_slot", {})
	for slot_key in slots:
		var key := str(slot_key)
		var num := key.substr(1).to_int() if key.begins_with("s") else 0
		for tc in cards_in_slot(num, rite_uid):
			out.append({
				"slot": key,
				"card_id": int(tc.get("id", 0)),
				"card_uid": int(tc.get("card_uid", 0)),
				"tags": tc.get("tags", {}),
				"is_enemy": int(slots[key].get("is_enemy", 0)) == 1,
			})
	return out


## The card this equipment instance is attached to (0 when unattached).
## Equipment relationships live on the host's equipped_uids.
func host_uid_of_equipment(equipment_uid: int) -> int:
	if equipment_uid <= 0:
		return 0
	for uid in card_instances:
		var inst = get_card_instance(int(uid))
		if inst != null and equipment_uid in inst.equipped_uids:
			return int(uid)
	return 0


## Record a tag exercised by an attribute check during settlement; HasTagTips
## conditions read this in post_rite. [SRC: HasTagTips.c @ IsSatisfied]
func record_tag_tip(card_uid: int, tag_name: String) -> void:
	if tag_name == "":
		return
	var inst = get_card_instance(card_uid)
	if inst == null or tag_name in inst.tag_tips:
		return
	inst.tag_tips.append(tag_name)


## Clear the per-rite tag exercise records for the rite's cards before its
## settlement starts fresh.
func clear_tag_tips(rite_uid: int) -> void:
	for uid in card_instances:
		var inst = get_card_instance(int(uid))
		if inst != null and (rite_uid <= 0 or int(inst.rite_uid) == rite_uid):
			inst.tag_tips.clear()


## Every card instance currently sitting in the given rite's slots.
func rite_slot_card_uids(rite_uid: int) -> Array[int]:
	var out: Array[int] = []
	for uid in card_instances:
		var inst = get_card_instance(int(uid))
		if inst != null and inst.zone == "slot" and int(inst.rite_uid) == rite_uid:
			out.append(int(uid))
	return out


## Remove a card instance from play wherever it sits (hand, rite slot, active
## Sultan, or equipped). Selector-cleaned cards funnel through here.
func remove_card_instance_from_play(uid: int) -> bool:
	var instance = get_card_instance(uid)
	if instance == null or instance.zone == "removed":
		return false
	var host_uid := host_uid_of_equipment(uid)
	if host_uid > 0 and has_method("detach_equipment"):
		detach_equipment(host_uid, uid, false)
	match instance.zone:
		"hand":
			var idx := hand.find(uid)
			if idx >= 0:
				hand.remove_at(idx)
				_erase_one_from_rail(uid)
		"slot":
			_unlink_slot_instance(instance)
			instance.rite_uid = 0
			instance.slot_key = ""
		"sudan":
			for active_sudan in active_sudan_cards.duplicate():
				if int(active_sudan.card_uid) == uid:
					active_sudan_cards.erase(active_sudan)
	instance.zone = "removed"
	return true


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
	if player_actor_uid > 0 and not operation_context.has("player_actor_uid"):
		operation_context["player_actor_uid"] = player_actor_uid
	if player_actor_uid > 0 and not operation_context.has("player_actor_id"):
		var player_actor = get_card_instance(player_actor_uid)
		operation_context["player_actor_id"] = int(player_actor.card_id) if player_actor != null else 0
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
	# DelayOp.round is a remaining Next Day countdown. The original decrements
	# it in UpdateSingleDelayOps on every NextDay, regardless of Player.round.
	# [SRC: PlayerExtensions.c @ AddDelayOp (RVA 0x38be90);
	#       GameController.c @ UpdateSingleDelayOps (RVA 0x55a700)]
	var delay_round := maxi(int(payload.get("round", 0)), 0)
	delayed_operations.append({
		"id": int(payload.get("id", 0)),
		"round": delay_round,
		"delay_mode": "next_day_countdown",
		"payload": payload.duplicate(true),
		"context": context.duplicate(true),
	})


func take_due_delayed_operations() -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	var pending: Array[Dictionary] = []
	for operation in delayed_operations:
		var next_operation: Dictionary = operation.duplicate(true)
		next_operation["round"] = int(next_operation.get("round", 0)) - 1
		if int(next_operation["round"]) < 1:
			due.append(next_operation)
		else:
			pending.append(next_operation)
	delayed_operations = pending
	return due


## DelayOff with value 1 clears every scheduled delay operation.
## [SRC: decompiled/DelayOff.c @ Do (RVA 0x4f7eb0): value 1 calls
##       PlayerExtensions.ClearDelayOp]
func clear_delay_ops() -> void:
	delayed_operations.clear()


## DelayOff with explicit ids removes only the matching delay operations.
## [SRC: decompiled/DelayOff.c @ Do: PlayerExtensions.RemoveDelayOp(player, id)]
func remove_delay_op(op_id: int) -> bool:
	var remaining: Array[Dictionary] = []
	var removed := false
	for operation in delayed_operations:
		if int(operation.get("id", 0)) == op_id:
			removed = true
			continue
		remaining.append(operation)
	delayed_operations = remaining
	return removed


## Record that a rite finished settlement; feeds `rite_end.<id>` conditions.
func record_rite_ended(rite_id: int) -> void:
	if rite_id <= 0:
		return
	ended_rites[rite_id] = int(ended_rites.get(rite_id, 0)) + 1


func has_rite_ended(rite_id: int) -> bool:
	return ended_rites.has(rite_id)


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
	# Matched events run their settlements immediately; only the ones whose
	# settlement carries interaction (prompts/choices) enter the display
	# queue. World-initialization events (hospital activation, scheduled
	# rite generation, counters) stay silent like the original's DoSettlements.
	# [SRC: EventTrigger.c @ DoSettlements (0x4fb1c0): fire -> settle;
	#       UI panels only for interaction-bearing payloads]
	if _event_rng == null:
		_event_rng = GameRNG.new()
	var settle_rng = trigger_ctx.get("rng")
	if settle_rng == null:
		settle_rng = _event_rng
	for eid in matched:
		var event: Dictionary = event_runtime._db.get_event(int(eid))
		var merged: Dictionary = DeferredEffects.execute_event(event, self, event_runtime._db, settle_rng, trigger_ctx)
		if bool(merged.get("over", false)):
			over_pending = true
		if not merged.get("prompts", []).is_empty() or not merged.get("choose", {}).is_empty():
			queue_event(int(eid), trigger_ctx)
	return matched


## Substitute config-value placeholders in display texts. The original
## formats prompt/result texts with live run values before display.
## [SRC: event/5300066.json "[sudan_life_time]天时间", event/5300339.json
##       "[sudan_redraw_total_left_times]次重抽"; init difficulty configs
##       carry the substituted values]
func substitute_text(text: String) -> String:
	var out := text
	if out.contains("[sudan_life_time]"):
		out = out.replace("[sudan_life_time]", str(int(difficulty_config.get("sudan_life_time", 7))))
	if out.contains("[sudan_redraw_total_left_times]"):
		out = out.replace("[sudan_redraw_total_left_times]", str(int(redraws_left)))
	return out


func queue_prompt(prompt: Dictionary) -> void:
	if not prompt.is_empty():
		var context: Dictionary = prompt.get("context", {}) if prompt.get("context", {}) is Dictionary else {}
		var formatted: Dictionary = prompt.duplicate(true)
		formatted["text"] = substitute_text(str(formatted.get("text", "")))
		if formatted.has("title"):
			formatted["title"] = substitute_text(str(formatted["title"]))
		if formatted.has("choices") and formatted["choices"] is Dictionary:
			var choices: Dictionary = {}
			for choice_key in formatted["choices"]:
				var choice = formatted["choices"][choice_key]
				if choice is Dictionary and choice.has("text"):
					choice = choice.duplicate(true)
					choice["text"] = substitute_text(str(choice.get("text", "")))
				choices[choice_key] = choice
			formatted["choices"] = choices
		queue_operation("choice" if formatted.has("choices") else "prompt", formatted.get("id", "prompt"), formatted, context)


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
