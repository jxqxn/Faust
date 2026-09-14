## Mutable game state during a run.
## Holds local/global counters, the player's hand, cards on the table (slots),
## gold (as the coin-card stack per spec sec 10.2), calendar/round, difficulty,
## and resource counters (gold dice, redraws, back-to-prev).
class_name GameState
extends RefCounted

const CardInstanceData = preload("res://sim/card_instance.gd")
const SudanPoolCardData = preload("res://sim/sudan_pool_card.gd")

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
var player_card_order: Array[int] = []
# The player always acts through one concrete protagonist instance. Other
# character cards remain world people that the protagonist can involve in an
# action; moving one into a rite never changes the player actor.
#
# This is an innovation-layer interpretation of the verified CardInstance
# boundary, not a claim about an additional field in the original runtime.
var player_actor_uid := 0
# [SRC: Player.name@0x20 dump.cs:391488; SetPlayerName0x585530.]
var player_display_name := ""
# Hand and bottom rail contain runtime CardInstance uids.  Config ids only
# cross the public compatibility boundary, where they resolve to one instance.
var hand: Array[int] = []
# Visual order for the unified bottom card rail, including hand and active
# sudan cards. Gameplay ownership still lives in hand/active_sudan_cards.
var rail_order: Array[int] = []
var current_bag_index := 0
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

# Original Player stores the redraw profile and how many ordinary redraws
# have already been used separately. `redraws_left` remains a clone/UI
# compatibility view and is always synchronized from the two source fields.
# [SRC: dump.cs Player @0x64/0x6C/0x70/0x74; PlayerExtensions.c
#       SetDifficulty (0x38f530), GetSudanRedrawCount (0x38dda0)]
var sudan_card_init_life := 7
var sudan_redraw_times_per_round := 1
var sudan_redraw_times := 0
var sudan_redraw_times_recovery_round := 7
var redraws_left := 0         # compatibility/UI: max(0, per_round - used)
# How many new sudan cards a redraw draws (original player+0x68).
# [SRC: GameController.c @ RedrawSudanCard: loop bound = sudan_redraw_count]
var sudan_redraw_count := 1

# Sudan cards in play (drawn, not yet consumed): each {id, days_left, ...}.
var active_sudan_cards: Array = []
# The un-drawn Sultan pool, as the original keeps it: ordered Card OBJECTS, not
# config ids. Duplicate ids are real (the corpus sample has 27 entries over 16
# ids), each carrying its own uid/count/life/tag delta. Consumed last-first.
# [SRC: dump.cs Player.sudan_card_pool @0xB0 List<Card>;
#       GameController.c @ GenSudanCard 0x54f6f0 / RedrawSudanCard 0x5558b0]
var sudan_deck: Array = []
var sudan_pool_next_uid := 1
var auto_gen_sudan_card := true
# Runtime rite instances are the authoritative player-owned ritual state.
# Config ids below remain compatibility views for code not migrated yet.
# [SRC: dump.cs:392391 Rite has uid/id/start/life/cards; StartRite.c @ Do
#       (RVA 0x51bcf0) creates an instance before GameController.AddRite.]
var rite_instances: Dictionary = {} # uid(int) -> RiteInstance
var next_rite_uid := 1
var active_rite_uid := 0
# Completed-map endpoints are not live Rite instances.  Player.pins is an
# ordered, duplicate-free List<int> of rite *definition* ids; the result UI
# appends a final_pin rite only after RemoveRite has removed its runtime uid.
# [SRC: dump.cs Player.pins @0x98; PlayerExtensions.c AddRitePin/RemoveRitePin;
#       RiteResultPanelController.__c__DisplayClass56_0 <Settlement>b__8]
var rite_pins: Array[int] = []
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
# Host continuation for the source result/action Promise queues. Original
# content is retained unchanged; this records execution position, not content.
var rite_settlements: Dictionary = {}
var rite_confirmations: Dictionary = {}
var round_transition: Dictionary = {}
var think_session: Dictionary = {}
# [SRC: Player.ithink_card +0x80; ThinkController.OnDrop 0x5c3050.]
var ithink_card_uid := 0
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
## Lazily loaded ConfigDB for snapshots taken on states that never ran
## setup_new_run (tests, tools). Never written to.
var _fallback_db = null
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
# Player's persistent "generated once" registries. These are not ownership
# lists: losing a card or removing a rite never removes its definition id.
# [SRC: GameController.c @ PutCardOnTable (0x5556c0) adds CardNode.is_only
# ids to player.only_cards; PlayerExtensions.c @ InitRite (0x38e140) adds
# each successfully initialized rite id to player.only_rites]
var only_cards: Dictionary = {}
var only_rites: Dictionary = {}
# A separate Player-persisted list of events whose cached settlement has been
# triggered and is awaiting its clickable notice. It is not the transient
# prompt/event operation queue.
# [SRC: dump.cs Player.cached_event @0x148; PlayerExtensions.c
#       AddCacheEvent (0x38b580) / RemoveCacheEvent (0x38ecb0)]
var cached_event: Array[int] = []
# Per-round journal pages (original Player.notes List<List<Note>> @0x138).
# Page index = round - 1; AddNote grows the page list up to the current round.
# A note is {type, id, uid, count}: type 1 = rite created, 2 = rite expired,
# 3 = rite settled, 4 = rite adsorbed a card (count carries that card's id),
# 10001 = card became a follower, 10002 = reward card gained (tag-gated).
# [SRC: dump.cs:391430 Player.Note {type@0x10,id@0x14,uid@0x18,count@0x1C};
#       PlayerExtensions.c AddNote (0x38c130) pages by round-1; StartRite.c
#       L133 type 1; GameController.c L5867 type 2; NoteRiteDone 0x38ec30
#       type 3; NoteRiteAdsorbCard 0x38eb10 type 4; NoteCardBeFollower
#       0x38e9c0 type 10001; NoteCardBeReward 0x38ea40 type 10002]
var notes: Array = []
# Player-owned visibility preferences for the original desktop HUD. The
# `*_unshow` fields are true when their corresponding element is hidden;
# sudan_box_show uses the inverse wording and is true when visible.
# [SRC: dump.cs Player @0x48-0x4C/@0x140; Player.c field accessors;
#       GameController.c ShowSudanBox (0x557af0), ShowStory (0x5578f0),
#       ShowPrestige (0x557390), ShowSudanLife (0x557c50), ShowHelpBtn (0x5571e0)]
var sudan_box_show := false
var story_unshow := false
var prestige_unshow := false
var deadline_unshow := false
var helpbtn_unshow := false
var once_new_rites_is_show: Dictionary = {}
# Historical generation counters. They are event history rather than current
# ownership: a card's id increments once when PlayerExtensions.AddCard creates
# it, and every distinct effective tag increments once at that same boundary.
# [SRC: Player.gen_cards @0x118 / gen_tags @0x120 (dump.cs:391580-391582);
#       PlayerExtensions.c @ MarkCardGen (0x38e450), MarkTagGen (0x38e6e0)]
var gen_cards: Dictionary = {}
var gen_tags: Dictionary = {}
# Active on-screen beginner-guide directive from the last `begin_guide`
# action (type/anim_type/pos/ring_pos/bind...). `close_begin_guide` clears
# it. Presentation cues (focus/hand_pop/rite_pop/slide/close_*) accumulate
# in guide_cues for the overlay; the rules layer never reads them.
# [SRC: BeginGuideController.c @ ShowBeginGuide (0x526220) /
#       GetBeginGuideItem (0x525630); CloseBeginGuide.c]
var begin_guide: Dictionary = {}
var guide_cues: Array = []
# Original Player keeps the terminal outcome independently of the transient
# game-over presentation request. `over_reason` uses int.MinValue while no
# terminal outcome has been set.
# [SRC: dump.cs Player @0x79/@0x7C; GameController.c SetGameOver (0x556a50);
#       GameOver.c Do (0x50ff10) calls SetGameOver(false, operation.value)]
var success := false
var over_reason := -2147483648
# Persistent end/armageddon presentation state. These are source Player
# fields, not a clone-authored combat-mode abstraction: end_open switches the
# map to its terminal background, while is_armageddon + armageddon_rite_id
# restore the rite-specific loop-audio animator after loading/next round.
# [SRC: dump.cs Player @0x178/@0x179/@0x17C; MapController.c Start
#       (0x56a890); GameController.c Start (armageddon animator restore);
#       GameController.__c__DisplayClass142_0.c b__5 (0x570850)]
var end_open := false
var is_armageddon := false
var armageddon_rite_id := 0
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


## ---- Un-drawn Sultan pool (player.sudan_card_pool @0xB0, List<Card>) ----
## The pool is an ordered list of Card objects, not config ids: duplicate ids
## are real and each entry owns its uid/count/life/tag delta.
## [SRC: dump.cs Player.sudan_card_pool @0xB0; GameController.c GenSudanCard
##       0x54f6f0 (removes the chosen object and promotes that same object),
##       RedrawSudanCard 0x5558b0 (re-inserts the discarded object).]

## Build (or rebuild) the pool from init_config sudan_pool, in config order.
func build_sudan_pool(db) -> void:
	sudan_deck.clear()
	for raw_id in db.get_sudan_pool():
		add_sudan_pool_card(int(raw_id))


func sudan_pool_size() -> int:
	return sudan_deck.size()


## Test/tool fixture hook: replace the pool with one object per given id.
## Runtime code must use build_sudan_pool / draw_sudan_pool_card instead.
func reset_sudan_pool_to_ids(ids: Array) -> void:
	sudan_deck.clear()
	sudan_pool_next_uid = 1
	for raw_id in ids:
		add_sudan_pool_card(int(raw_id))


## Append a NEW pool Card object for one config id (AddSudanCard).
## [SRC: PlayerExtensions.c @ AddSudanCard 0x38c440]
func add_sudan_pool_card(card_id: int) -> void:
	if card_id <= 0:
		return
	# [SRC: PlayerExtensions.GetNextCardUId 0x38da40 is shared by all Cards.]
	var entry = SudanPoolCardData.new(next_card_uid, card_id)
	next_card_uid += 1
	sudan_pool_next_uid = next_card_uid
	sudan_deck.append(entry)


func sudan_deck_ids() -> Array:
	var ids: Array = []
	for entry in sudan_deck:
		ids.append(int(entry.card_id))
	return ids


## GenSudanCard's consumption order: shuffle the pool in place when the init
## profile asks for it, then take the last entry. It is the SAME object that
## leaves the pool, so its runtime tags travel with it.
## [SRC: GameController.c @ GenSudanCard 0x54f6f0: GetInitNode+0x48 gates
##       ListExtensions.Shuffle, then ListExtensions.RemoveLast.]
func draw_sudan_pool_card(rng, db = null):
	if sudan_deck.is_empty():
		return null
	if db != null and bool(db.init_config.get("sudan_shuffle", true)) and rng != null:
		var shuffled: Array = rng.shuffle(sudan_deck.duplicate())
		sudan_deck.clear()
		sudan_deck.append_array(shuffled)
	return sudan_deck.pop_back()


## Re-insert a discarded object at Random.Range(0, count), half-open.
## [SRC: GameController.c @ RedrawSudanCard 0x5558b0 L3840-3842]
func insert_sudan_pool_card(rng, entry) -> void:
	if entry == null:
		return
	if sudan_deck.is_empty() or rng == null:
		sudan_deck.append(entry)
		return
	sudan_deck.insert(rng.range_int_half_open(0, sudan_deck.size()), entry)


func sudan_pool_entry(pool_uid: int):
	for entry in sudan_deck:
		if int(entry.uid) == pool_uid:
			return entry
	return null


## Effective tag row of one pool entry: its config definition plus the entry's
## own delta, in the config key domain.
func sudan_pool_entry_tags(entry, db) -> Dictionary:
	if entry == null:
		return {}
	var tags: Dictionary = {}
	for raw_name in _base_tag_row(int(entry.card_id), db):
		tags[str(raw_name)] = int(_base_tag_row(int(entry.card_id), db)[raw_name])
	_add_tag_row(tags, entry.tags, db)
	return tags


## Compatibility view: card_id -> raw runtime delta. Later entries win, matching
## the old id-keyed dictionary when the pool happens to hold one object per id.
func sudan_pool_tags() -> Dictionary:
	var out: Dictionary = {}
	for entry in sudan_deck:
		var normalized: Dictionary = {}
		for raw_name in entry.tags:
			normalized[str(raw_name)] = int(entry.tags[raw_name])
		out[int(entry.card_id)] = normalized
	return out


func set_sudan_pool_tags_for_id(card_id: int, tags: Dictionary) -> void:
	for entry in sudan_deck:
		if int(entry.card_id) == card_id:
			entry.tags = tags.duplicate(true)


func create_card_instance(card_id: int, db, zone: String = "hand"):
	if card_id <= 0:
		return null
	# A fresh Card starts with an EMPTY runtime delta (Card.tag@0x30); its whole
	# row comes from the shared CardNode definition. Seeding the delta with the
	# definition row would double every value once GetTag-style evaluation runs.
	# [SRC: CardExtensions.c @ GetTag 0x3814a0 reads Card.data+0x58 plus Card+0x30;
	#       GenCard.c / GenSudanCard construct the runtime Card without copying
	#       the definition tag dictionary.]
	var instance = CardInstanceData.new(next_card_uid, card_id)
	next_card_uid += 1
	instance.zone = zone
	card_instances[instance.uid] = instance
	if zone in ["hand", "sudan"]:
		player_card_order.append(instance.uid)
	_initialize_tag_attributes(instance, db)
	_record_card_op(CARD_OP_NEW, instance.uid)
	return instance


func record_card_generation(instance, db = null) -> void:
	if instance == null or int(instance.card_id) <= 0:
		return
	var card_id := int(instance.card_id)
	gen_cards[card_id] = int(gen_cards.get(card_id, 0)) + 1
	# MarkCardGen walks GetTags(Card), which unions the definition tag keys
	# (CardNode.tag@0x58) with the runtime delta keys (Card.tag@0x30) and each
	# inheritable equip's keys. Iterating only the runtime delta would drop the
	# definition's own tags.
	# [SRC: CardExtensions.c @ GetTags (0x381940); PlayerExtensions.c
	#       @ MarkCardGen (0x38e450)]
	for tag_name in effective_card_tag_names(instance.uid, db):
		record_tag_generation(str(tag_name), db)


func record_tag_generation(raw_tag: Variant, db = null) -> void:
	var tag_code := _generation_tag_code(raw_tag, db)
	if tag_code.is_empty():
		return
	gen_tags[tag_code] = int(gen_tags.get(tag_code, 0)) + 1


func _generation_tag_code(raw_tag: Variant, db = null) -> String:
	var tag_name := str(raw_tag)
	if db != null and db.has_method("tag_code_for"):
		return str(db.tag_code_for(tag_name))
	return tag_name


func record_only_card(card_id: int, db) -> void:
	if card_id <= 0 or db == null:
		return
	var definition: Dictionary = db.get_card(card_id)
	if bool(definition.get("is_only", false)):
		only_cards[card_id] = true


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
	card["id"] = instance.card_id
	card["instance_uid"] = instance.uid
	card["tag"] = effective_card_tags(instance.uid, db)
	# Aliased key for consumers that read a materialized row (condition cost/acting
	# tag checks use "tags"; DSL selectors use "tag"). Both must be the effective
	# GetTag row, never the delta. [SRC: CardExtensions.c @ GetTag 0x3814a0]
	card["tags"] = card["tag"]
	card["count"] = instance.count
	card["life"] = instance.life
	card["is_lost"] = instance.is_lost
	card["rare"] = clampi(int(card.get("rare", 1)) + instance.rare_up, 1, 4)
	var player_name := str(player_card_names.get(instance.card_id, ""))
	var translated_name: String = db.translate_custom_card_text(instance.custom_name) if db != null else instance.custom_name
	if not player_name.is_empty():
		card["name"] = player_name
	elif not instance.custom_name.is_empty() and translated_name != instance.custom_name:
		# [SRC: CardExtensions.GetName0x37ff50 rejects unresolved keys.]
		card["name"] = translated_name
	elif db != null and not player_display_name.is_empty() and int(db.get_card(instance.card_id).get("tag", {}).get("主角", 0)) > 0:
		# GetName(CardNode) reads the definition tag, not runtime additions.
		# [SRC: CardExtensions.GetName0x3801b0; literal0x25828f8=player.]
		card["name"] = player_display_name
	if not instance.custom_text.is_empty():
		# [SRC: CardInfoNewController.Show0x537000: unlike names, an
		# unresolved custom description remains its key; no config fallback.]
		card["text"] = db.translate_custom_card_text(instance.custom_text) if db != null else instance.custom_text
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


## Effective runtime tag row for one card object, in the config (localized name)
## key domain. Mirrors CardExtensions.GetTag: the definition value plus the
## runtime delta plus each eligible equip's recursive GetTag value, with the
## can_nagative_and_zero mask on a non-positive sum and a final × Card.count.
## [SRC: CardExtensions.c @ GetTag (RVA 0x3814a0): base read at
##       Card.data+0x58, delta at Card+0x30, equip recursion gated on
##       TagNode+0x42 can_inherit, mask on 0x43, × count@0x20 at the return.]
func effective_card_tags(uid: int, db) -> Dictionary:
	var instance = get_card_instance(uid)
	if instance == null:
		return {}
	var effective: Dictionary = {}
	var per_unit := _card_tag_terms(instance, db)
	for tag_name in per_unit:
		effective[tag_name] = _mask_tag_value(str(tag_name), int(per_unit[tag_name]), false, db) * int(instance.count)
	return effective


## Key union of the same three sources, without the value walk. Mirrors
## CardExtensions.GetTags, which unions the definition keys, the runtime delta
## keys and each inheritable equip's tag list.
## [SRC: CardExtensions.c @ GetTags (RVA 0x381940) builds a HashSet from
##       CardNode.tag@0x58, then Card.tag@0x30, then UnionWith(each equip's
##       GetTags filtered to inheritable tags).]
func effective_card_tag_names(uid: int, db) -> Array:
	var instance = get_card_instance(uid)
	if instance == null:
		return []
	var names: Dictionary = {}
	for tag_name in _base_tag_row(int(instance.card_id), db):
		names[str(tag_name)] = true
	for raw_name in instance.tags:
		names[_tag_key_name(raw_name, db)] = true
	for equipped_uid in instance.equipped_uids:
		var equipped = get_card_instance(int(equipped_uid))
		if equipped == null or equipped.zone != "equipped":
			continue
		for raw_name in effective_card_tag_names(int(equipped_uid), db):
			if _tag_can_inherit(str(raw_name), db):
				names[_tag_key_name(raw_name, db)] = true
	return names.keys()


## One walk of the three GetTag sources, in the config key domain. The result
## is per unit: the caller applies Card.count once at the end.
func _card_tag_terms(instance, db) -> Dictionary:
	var per_unit: Dictionary = {}
	_add_tag_row(per_unit, _base_tag_row(int(instance.card_id), db), db)
	_add_tag_row(per_unit, instance.tags, db)
	for equipped_uid in instance.equipped_uids:
		var equipped = get_card_instance(int(equipped_uid))
		if equipped == null or equipped.zone != "equipped":
			continue
		# Gate the REQUESTED tag, not the equipment's entire row. raw=true
		# skips the non-positive mask, but still multiplies that equip's count.
		# [SRC: CardExtensions.GetTag 0x3814a0 L1603-1625; TagNode@0x42;
		# GetTags predicate 0x393980 independently filters each tag.]
		var equip_terms := _card_tag_terms(equipped, db)
		for tag_name in equip_terms:
			if _tag_can_inherit(str(tag_name), db):
				per_unit[tag_name] = int(per_unit.get(tag_name, 0)) + int(equip_terms[tag_name]) * int(equipped.count)
	return per_unit


func _base_tag_row(card_id: int, db) -> Dictionary:
	if db == null:
		return {}
	var definition: Dictionary = db.get_card(card_id)
	var row: Variant = definition.get("tag", {})
	return row if row is Dictionary else {}


func _add_tag_row(into: Dictionary, row: Dictionary, db) -> void:
	for raw_name in row:
		var key := _tag_key_name(raw_name, db)
		var value := int(row[raw_name])
		if key.is_empty() or value == 0:
			continue
		into[key] = int(into.get(key, 0)) + value


## The non-positive mask from GetTag's tail: a sum below 1 reports 0 unless the
## tag node allows negative and zero values. raw=true is the equip recursion,
## which skips the mask.
## [SRC: CardExtensions.c @ GetTag lines 1619-1622 via TagNode+0x43.]
func _mask_tag_value(tag_name: String, value: int, raw: bool, db) -> int:
	if raw or value >= 1:
		return value
	if _tag_allows_negative_and_zero(tag_name, db):
		return value
	return 0


func _tag_key_name(raw_name: Variant, db) -> String:
	var key := str(raw_name)
	if db == null or key.is_empty():
		return key
	if db.get("tag_code_to_name") != null and db.tag_code_to_name.has(key):
		return str(db.tag_code_to_name[key])
	return key


func _tag_can_inherit(tag_name: String, db) -> bool:
	var node := _tag_node_for(tag_name, db)
	if node.is_empty():
		return false
	return int(node.get("can_inherit", 0)) != 0


func _tag_allows_negative_and_zero(tag_name: String, db) -> bool:
	var node := _tag_node_for(tag_name, db)
	if node.is_empty():
		return false
	return int(node.get("can_nagative_and_zero", 0)) != 0


func _tag_node_for(tag_name: String, db) -> Dictionary:
	if db == null or tag_name.is_empty():
		return {}
	var code := tag_name
	if db.get("tag_name_to_code") != null and db.tag_name_to_code.has(tag_name):
		code = str(db.tag_name_to_code[tag_name])
	if db.get("tags_by_code") != null and db.tags_by_code.has(code):
		return db.tags_by_code[code]
	return {}


# [SRC: PlayerExtensions.AddCard 0x38b620 enumerates definition KEYS and
# applies their attributes, without a GetTag/value gate during construction.]
func _initialize_tag_attributes(instance, db) -> void:
	for tag_name in _base_tag_row(int(instance.card_id), db):
		_write_tag_attributes(instance, _tag_node_for(str(tag_name), db), true)


# [SRC: CardExtensions.ValidateTagAttributes 0x3831c0; called after tag writes.
# Read the effective source tag once, then apply the attribute dictionary.]
func validate_tag_attributes(uid: int, tag_name: String, db) -> void:
	var instance = get_card_instance(uid)
	if instance == null:
		return
	var node := _tag_node_for(tag_name, db)
	if node.get("attributes", {}).is_empty():
		return
	var effective := effective_card_tags(uid, db)
	_write_tag_attributes(instance, node, int(effective.get(_tag_key_name(tag_name, db), 0)) > 0)


func _write_tag_attributes(instance, node: Dictionary, present: bool) -> void:
	for raw_name in node.get("attributes", {}):
		# The current original attributes corpus contains ONLY this builtin.
		# Datapool.BuildInTags 0x40d9b0 / AddBuildInTag 0x40c610:
		# adsorb_spec (吸附指定), can_add=false, can_visible=false.
		# AddTag 0x37e6a0 keeps an existing non-additive runtime marker;
		# RemoveTag 0x382e40 erases it (no base definition term exists).
		if str(raw_name) not in ["吸附指定", "adsorb_spec"]:
			push_error("Unported tag attribute: %s" % raw_name)
			continue
		if present:
			if not instance.tags.has("adsorb_spec"):
				instance.tags["adsorb_spec"] = int(node.attributes[raw_name])
		else:
			instance.tags.erase("adsorb_spec")


func _copy_tag_delta_in_source_order(source, copied, db) -> void:
	_initialize_tag_attributes(copied, db)
	# [SRC: Copy 0x37f4e0 directly writes each delta entry, then invokes
	# ValidateTagAttributes for THAT entry. Do not bulk assign before validating.]
	for raw_name in source.tags:
		copied.tags[raw_name] = source.tags[raw_name]
		validate_tag_attributes(int(copied.uid), str(raw_name), db)


## Reconstruct the runtime delta from a tag row persisted in the config domain.
## Older clone saves stored the effective row while the original stores the
## delta; the definition value is subtracted back out. Tags the definition does
## not carry (runtime markers such as lost / adsorb_spec) are kept verbatim.
## [SRC: Card.tag@0x30 is persisted, CardNode.tag@0x58 is not.]
func rebase_tag_delta(stored: Dictionary, card_id: int, db) -> Dictionary:
	var base := _base_tag_row(card_id, db)
	var delta: Dictionary = {}
	for raw_name in stored:
		var value := int(stored[raw_name])
		if value == 0:
			continue
		var key := str(raw_name)
		var base_value := 0
		var is_config_tag := false
		if db != null and db.get("tag_name_to_code") != null and db.tag_name_to_code.has(key):
			is_config_tag = true
			base_value = int(base.get(key, 0))
		elif db != null and db.get("tag_code_to_name") != null and db.tag_code_to_name.has(key):
			# A save already in the code domain is a delta and needs no rebase.
			delta[key] = value
			continue
		var rebased := value - base_value if is_config_tag else value
		if rebased != 0:
			delta[key] = rebased
	return delta


func set_card_custom_name(uid: int, value: String) -> bool:
	var instance = get_card_instance(uid)
	if instance == null:
		return false
	instance.custom_name = value
	return true


func set_player_card_name(card_id: int, value: String) -> bool:
	if card_id <= 0 or value.is_empty():
		return false
	player_card_names[card_id] = value
	return true


## [SRC: PromptChangeNameController SetPlayerName0x585530 /
## SetSpecialCardName0x585600; validation belongs to the prompt.]
func set_prompt_name(card_id: int, value: String) -> bool:
	if card_id == 0:
		player_display_name = value
		return true
	return set_player_card_name(card_id, value)


func prompt_initial_name(card_id: int, db) -> String:
	# [SRC: GetSpecialCardName0x584c60; GetPlayerName0x584a20 and
	# <>c.GetPlayerName predicate0x59fc10 (HasTag(player)).]
	if card_id != 0:
		return str(player_card_names.get(card_id, db.get_card(card_id).get("name", "")))
	if not player_display_name.is_empty():
		return player_display_name
	for uid in hand:
		var instance = get_card_instance(uid)
		if instance != null and int(effective_card_tags(uid, db).get("主角", 0)) > 0:
			return str(db.get_card(instance.card_id).get("name", ""))
	return str(db.get_card(2000001).get("name", ""))


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
	instance.custom_text = value
	return true


## ---- Result operation log (CardOpContext stream) ----
## The original's rules layer feeds the result panel a stream of CardOpContext
## rows (one per card-affecting operation), which RiteResultPanelController
## queues via AddCardOp and the OpCardNewController chain plays back. The clone
## has no operation-object layer yet, so it records the same stream here: a
## passive list that only fills between begin_result_op_log() and
## drain_result_op_log().
## [SRC: RiteResultPanelController.c @ AddCardOp (RVA 0x5a0e60) appends to the
##       pending list at +0x1d8; CardOpContext type@0x10 / card@0x18 /
##       tag@0x20 / value@0x28 / count@0x2c / pop@0x30 (dump.cs 6305);
##       CardOpType NEW0 COPY1 DELETE2 EQUIP3 UNEQUIP4 UNEQUIP_RECOVERY5
##       ADD_TAG6 REMOVE_TAG7 UPRARE8 POP9 HAND_POP10 THINK_POP11
##       REBIRTH_SUDAN_CARD12 (dump.cs 6304).]
const CARD_OP_NEW := 0
const CARD_OP_COPY := 1
const CARD_OP_DELETE := 2
const CARD_OP_EQUIP := 3
const CARD_OP_UNEQUIP := 4
const CARD_OP_UNEQUIP_RECOVERY := 5
const CARD_OP_ADD_TAG := 6
const CARD_OP_REMOVE_TAG := 7
const CARD_OP_UPRARE := 8

var card_op_log: Array = []
var _card_op_log_active := false


func begin_result_op_log() -> void:
	_card_op_log_active = true
	card_op_log.clear()


func drain_result_op_log() -> Array:
	_card_op_log_active = false
	var rows: Array = card_op_log.duplicate(true)
	card_op_log.clear()
	return rows


func is_recording_result_ops() -> bool:
	return _card_op_log_active


func _record_card_op(op_type: int, uid: int, extra: Dictionary = {}) -> void:
	if not _card_op_log_active:
		return
	var instance = get_card_instance(uid)
	var row: Dictionary = {
		"op": op_type,
		"card_uid": uid,
		"card_id": int(instance.card_id) if instance != null else 0,
	}
	row.merge(extra, true)
	card_op_log.append(row)


## Record an ADD_TAG(6) / REMOVE_TAG(7) row. `value_after` is the card's stored
## (delta) value once the mutation landed; the panel combines it with the tag
## definition, which is exactly how the original's TagNode row is rendered.
## 影响力-class tags never reach here: Result._mutate_tag drops them at the
## can_visible gate, mirroring RiteResultPanelController.AddCardOp.
## [SRC: RiteResultPanelController.c @ AddCardOp 0x5a0e60 (type 6/7 gate);
##       OperationContext.c @ AddCardOp_AddTag 0x39dfa0 / _RemoveTag 0x39e870
##       (CardOp +0x10 type, +0x18 card, +0x20 tag, +0x28 amount, +0x2c count).]
func record_tag_op(uid: int, tag_name: String, op: int, amount: int, tags: Dictionary) -> void:
	var op_type := CARD_OP_REMOVE_TAG if op == TagSystem.Op.SUB else CARD_OP_ADD_TAG
	_record_card_op(op_type, uid, {
		"tag": tag_name,
		"amount": amount,
		"value_after": int(tags.get(tag_name, 0)),
	})


func modify_card_rarity(uid: int, delta: int, db) -> bool:
	var instance = get_card_instance(uid)
	if instance == null or db == null:
		return false
	var base_rare := int(db.get_card(instance.card_id).get("rare", 1))
	var before := clampi(base_rare + instance.rare_up, 1, 4)
	var after := clampi(before + delta, 1, 4)
	instance.rare_up += after - before
	if after != before:
		_record_card_op(CARD_OP_UPRARE, uid, {"rare_before": before, "rare_after": after})
		return true
	return false


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
		or equipment.zone not in ["hand", "slot", "drag"]
		or int(_card_tag_value(equipment_uid, "装备", db)) < 1
	):
		return -1
	if enforce_slot and equipment.zone == "slot" and not preload("res://ui/rite_slot_access.gd").can_edit(self, db, equipment.rite_uid, equipment.slot_key):
		return -1
	var slot := _matching_equip_slot(host_uid, equipment_uid, db)
	if enforce_slot and slot.is_empty():
		return -1
	# CanEquip has no hand-only source gate: a movable slot card can equip too.
	# Source equipment category must intersect a host slot. Operation-driven +equip
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
			if enforce_slot:
				# [SRC: CardController.CardEquip 0x528020 and
				# CardInfoNewController.DropCard 0x533550 both call
				# BackToHandOrBag(old, host.bag, 0, true), RVA 0x4eef90.]
				get_card_instance(replaced_uid).bag = host.bag
				get_card_instance(replaced_uid).bag_pos = 0
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
	if enforce_slot and replaced_uid > 0 and host.bag == current_bag_index:
		# AddCard with bagpos=0 appends, UpdateHandCardPos compacts the
		# current page after removing the newly equipped card.
		# [SRC: GameController.c 0x54ad40 / 0x559a70.]
		var page := visible_rail_card_uids()
		for index in page.size():
			get_card_instance(page[index]).bag_pos = index + 1
	_record_card_op(CARD_OP_EQUIP, equipment_uid, {"host_uid": host_uid, "slot": slot})
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
	_record_card_op(
		CARD_OP_UNEQUIP_RECOVERY if recover_to_hand else CARD_OP_UNEQUIP,
		equipment_uid, {"host_uid": host_uid})
	if recover_to_hand:
		add_card_to_hand(equipment_uid)
	return true


func _matching_equip_slot(host_uid: int, equipment_uid: int, db) -> String:
	var equipment = get_card_instance(equipment_uid)
	if equipment == null:
		return ""
	for slot in card_equip_slots(host_uid, db):
		if int(_card_tag_value(equipment_uid, slot, db)) > 0:
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
	configure_source_counters(db)
	hand.clear()
	card_instances.clear()
	only_cards.clear()
	only_rites.clear()
	cached_event.clear()
	notes.clear()
	sudan_box_show = false
	story_unshow = false
	prestige_unshow = false
	deadline_unshow = false
	helpbtn_unshow = false
	once_new_rites_is_show.clear()
	gen_cards.clear()
	gen_tags.clear()
	end_open = false
	is_armageddon = false
	armageddon_rite_id = 0
	next_card_uid = 1
	player_card_order.clear()
	player_actor_uid = 0
	player_display_name = ""
	player_card_names.clear()
	rail_order.clear()
	current_bag_index = 0
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
	# The new Player starts with its Init recovery period and a difficulty-owned
	# per-round allowance/head-start. SetDifficulty mutates only the latter two.
	# [SRC: dump.cs Player @0x64/0x6C/0x70/0x74; PlayerExtensions.c
	#       SetDifficulty (0x38f530) L2289-2296]
	sudan_redraw_times_per_round = _configured_redraws_per_round(db)
	sudan_redraw_times = 0
	sudan_redraw_times_recovery_round = int(db.init_config.get(
		"sudan_redraw_times_recovery_round", 7))
	sudan_card_init_life = int(difficulty_config.get("sudan_life_time", 7))
	_sync_redraws_left()
	# How many new sudan cards each redraw produces (init_config sudan_redraw_count).
	# [SRC: GameController.c @ RedrawSudanCard: loops sudan_redraw_count times]
	sudan_redraw_count = int(db.init_config.get("sudan_redraw_count", 1))
	# Sudan pool: one Card object per configured entry, shuffled in place on
	# each draw (init_config sudan_shuffle) exactly like the source.
	build_sudan_pool(db)
	_initialize_source_cards(db)
	ensure_player_actor(db)
	auto_gen_sudan_card = true
	# Day/round. The first round begins after initial events are armed (see
	# below); day counts start at 1.
	day = 1
	world_location_id = "school_rooftop"
	visited_world_locations = ["school_rooftop"]
	# Gold starts at a sane default (protagonist begins solvent).
	coin_count = 0
	rite_instances.clear()
	rite_pins.clear()
	next_rite_uid = 1
	active_rite_uid = 0
	available_rites.clear()
	for rid in db.get_default_rites():
		add_available_rite(int(rid), db, rng)
	# The source applies active cross-run upgrades only after the base Player,
	# Sultan pool/cards and rites exist.  In particular, AddSudanCard appends to
	# the already-shuffled pool, so those upgrade cards remain at the draw tail.
	# [SRC: Datapool.c @ InitPlayer (RVA 0x413700) -> DoUpgrade (0x410dc0)]
	if db.has_method("do_upgrade"):
		db.do_upgrade(self)
	started_rites.clear()
	auto_result_rites.clear()
	rite_auto_result = false
	rite_settlements.clear()
	rite_confirmations.clear()
	round_transition.clear()
	think_session.clear()
	ithink_card_uid = 0
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


func _configured_redraws_per_round(db) -> int:
	return int(difficulty_config.get(
		"sudan_redraw_times_per_round",
		db.init_config.get("sudan_redraw_times_per_round", 1)
	))


## [SRC: Datapool.InitPlayer 0x413700; default_cards@0x58/card_equips@0x60,
## dump.cs:390539-390543. Binary 0x413b80-0x413c24 restores the .c missing
## success branch: stackable duplicates increment count, others AddCard.]
func _initialize_source_cards(db) -> void:
	var first_by_id := {}
	for raw_id in db.get_default_cards():
		var id := int(raw_id)
		var definition: Dictionary = db.get_card(id)
		var stack_tag: String = db.tag_code_to_name.get("stackable", "stackable")
		if int(definition.get("tag", {}).get(stack_tag, 0)) > 0 and first_by_id.has(id):
			get_card_instance(first_by_id[id]).count += 1
			continue
		var uid := add_card_to_hand(id, db)
		if uid > 0 and not first_by_id.has(id):
			first_by_id[id] = uid
	# AddCard(no_add=true) creates equipment outside Player.cards and does not
	# MarkCardGen. Initial AddEquip also bypasses the interactive CanEquip gate.
	# [SRC: Datapool.c 0x413d53/0x413d69; PlayerExtensions.AddCard 0x38b620.]
	for raw_id in db.init_config.get("card_equips", {}):
		var host_uid := int(first_by_id.get(int(raw_id), 0))
		if host_uid == 0:
			push_error("Initial equipment host missing: %s" % raw_id)
			continue
		for equip_id in db.init_config.card_equips[raw_id]:
			var equipment = create_card_instance(int(equip_id), db, "equipped")
			if equipment != null:
				attach_equipment(host_uid, equipment.uid, db)
				record_only_card(int(equip_id), db)


func _sync_redraws_left() -> void:
	redraws_left = maxi(0, sudan_redraw_times_per_round - sudan_redraw_times)


func reset_sudan_redraw_usage() -> void:
	sudan_redraw_times = 0
	_sync_redraws_left()


func use_sudan_per_round_redraw() -> void:
	if redraws_left <= 0:
		return
	sudan_redraw_times += 1
	_sync_redraws_left()


func set_game_over(is_success: bool, reason: int) -> void:
	success = is_success
	over_reason = reason


func add_cached_event(event_id: int) -> bool:
	# ObservableList.Contains blocks duplicates, then Add appends at the tail.
	# [SRC: PlayerExtensions.c AddCacheEvent (0x38b580)]
	if event_id in cached_event:
		return false
	cached_event.append(event_id)
	return true


func remove_cached_event(event_id: int) -> void:
	# ObservableList.Remove deletes the matching notice after its cached
	# settlement finishes or the event config can no longer be found.
	# [SRC: PlayerExtensions.c RemoveCacheEvent (0x38ecb0); GameController.c
	#       OnCachedEventClicked; GameController.__c__DisplayClass243_0.c (0x5728d0)]
	cached_event.erase(event_id)


## Append one journal entry to the current round's page, growing the page
## list like the original AddNote (pages are indexed by round - 1).
## [SRC: PlayerExtensions.c AddNote (0x38c130) L1868-1933]
func add_note(note_type: int, entry_id: int, entry_uid: int, entry_count: int = 0) -> void:
	var page_index := maxi(round_number - 1, 0)
	while notes.size() <= page_index:
		notes.append([])
	notes[page_index].append({
		"type": note_type,
		"id": entry_id,
		"uid": entry_uid,
		"count": entry_count,
	})


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


## Mid-run difficulty switch. The original replaces the allowance and future
## Sultan head-start, but retains the current round's already-used redraw
## count and the Init-owned recovery period.
## [SRC: PlayerExtensions.c @ SetDifficulty (0x38f530) writes Player+0x6C and
##       +0x64 only; Player+0x70/+0x74 are untouched]
func apply_difficulty(index: int, db) -> void:
	if db == null or db.get_difficulty(index).is_empty():
		return
	difficulty_index = index
	difficulty_config = db.get_difficulty(index)
	sudan_redraw_times_per_round = _configured_redraws_per_round(db)
	sudan_card_init_life = int(difficulty_config.get("sudan_life_time", 7))
	_sync_redraws_left()
	_apply_difficulty_resources()


# ---- Counter access ----
func register_nonneg(id: int) -> void:
	_nonneg_ids[id] = true


func configure_source_counters(db) -> void:
	# [SRC: GameApplication.__c.c b__43_6 0x45c620 ->
	# VariableNode.special_counters@0xC0 (dump.cs:387317);
	# PlayerExtensions.SetCounter 0x38f2d0. Derived configuration, not save data.]
	for counter_id in db.variable_config.get("special_counters", []):
		register_nonneg(int(counter_id))


func is_nonneg_gated(id: int) -> bool:
	return CounterSystem.is_nonneg_gated(id, _nonneg_ids)


func get_counter(id: int) -> int:
	# COUNTER_BACK_TO_PREV lives on the global object, not the run's counter
	# dict. [SRC: PlayerExtensions.c GetCounter 0x38ce70 L1103-1108]
	if id == COUNTER_BACK_TO_PREV:
		return global_state.back_to_prev_round
	return int(local_counters.get(id, 0))


func get_global_counter(id: int) -> int:
	# Global.counter is the persistent truth; Player.global_counter_cacher is
	# retained only as the source-shaped run cache/old-save compatibility view.
	# [SRC: dump.cs Global.counter@0x68; Player.global_counter_cacher@0xE0;
	#       GlobalExtensions.GetCounter / ModifyGlobalCounter.Do 0x5176a0]
	if global_state != null and global_state.counters.has(id):
		return global_state.get_counter_value(id)
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
	var before := get_global_counter(id)
	var current := before + delta
	global_counters[id] = current
	if global_state != null:
		global_state.set_counter_value(id, current)
	if before != current:
		_notify_global_counter_changed(id, current)


func sub_global_counter(id: int, delta: int) -> void:
	var before := get_global_counter(id)
	var current := CounterSystem.clamp_nonneg(id, before - delta, _nonneg_ids)
	global_counters[id] = current
	if global_state != null:
		global_state.set_counter_value(id, current)
	if before != current:
		_notify_global_counter_changed(id, current)


func set_global_counter(id: int, val: int) -> void:
	var clamped := CounterSystem.clamp_nonneg(id, val, _nonneg_ids)
	var before := get_global_counter(id)
	global_counters[id] = clamped
	if global_state != null:
		global_state.set_counter_value(id, clamped)
	if before != clamped:
		_notify_global_counter_changed(id, clamped)


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
	var is_new_instance := false
	if instance == null:
		instance = create_card_instance(card_or_uid, db, "hand")
		if instance == null:
			return 0
		uid = instance.uid
		is_new_instance = true
	if uid not in player_card_order:
		player_card_order.append(uid)
	instance.zone = "hand"
	instance.rite_uid = 0
	instance.slot_key = ""
	if uid not in hand:
		hand.append(uid)
	if uid not in rail_order:
		rail_order.append(uid)
	_sync_hand_order_from_rail()
	# AddCard counts only newly-created player cards; returning/moving an
	# existing uid must not inflate history. The is_only registry is independent
	# and remains idempotent at the visible-table boundary.
	# [SRC: PlayerExtensions.c @ AddCard (0x38b620) -> MarkCardGen (0x38e450);
	#       GameController.c @ GenCard (0x54f650) -> PutCardOnTable (0x5556c0)]
	if is_new_instance:
		record_card_generation(instance, db)
	record_only_card(instance.card_id, db)
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
		if instance != null and instance.card_id == card_id and is_hand_card(int(uid)):
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


## CardExtensions.Copy: a new runtime Card of the same definition, carrying the
## source's runtime tag delta, its count, and a recursive copy of its equipped
## cards. Presentation fields (custom name/text, rareup, life, bag) are not part
## of the source copy; the extra lifecycle notifications belong to the caller.
## [SRC: CardExtensions.c @ Copy (RVA 0x37f4e0):
##       PlayerExtensions.AddCard(source.id) -> walk source.equips@+0x40 with
##       Copy(equip, raw=true) and append -> walk source.tag@+0x30 through
##       AddTag (0x37e6a0) -> Card.set_count(source.count@0x20) when the
##       keep-count flag is false; the equip recursion passes the flag true.]
func copy_card_instance(source_uid: int, db = null, zone := "hand") -> int:
	var source = get_card_instance(source_uid)
	if source == null:
		return 0
	var copy = CardInstanceData.new(next_card_uid, source.card_id)
	next_card_uid += 1
	copy.zone = zone
	card_instances[copy.uid] = copy
	_record_card_op(CARD_OP_COPY, copy.uid, {"source_uid": source_uid})
	if zone == "hand":
		add_card_to_hand(copy.uid, db)
	# Equipped cards are copied recursively; the recursion passes keep-count=true
	# so an equip copy keeps count 1 instead of inheriting the source's.
	for equipped_uid in source.equipped_uids:
		var equipped_copy_uid := copy_card_instance(int(equipped_uid), db, "removed")
		if equipped_copy_uid <= 0:
			continue
		var equipped_copy = get_card_instance(equipped_copy_uid)
		if equipped_copy != null:
			equipped_copy.count = 1
		attach_equipment(copy.uid, equipped_copy_uid, db, false, false)
	_copy_tag_delta_in_source_order(source, copy, db)
	copy.count = int(source.count)
	return copy.uid


func _copy_card_for_stack(source, amount: int):
	var copied = CardInstanceData.new(next_card_uid, source.card_id)
	next_card_uid += 1
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
	_copy_tag_delta_in_source_order(source, copied, _runtime_db())
	copied.count = amount
	return copied


## Splits `amount` (default half, rounded down) off a stackable hand card.
## [SRC: CardController.CardSplit 0x528390 — `count > n` is required; the source
##       card keeps count-n and a CardExtensions.Copy takes n with the same
##       bag/bagpos, returned to the hand by CardDropManager.BackToHandOrBag.
##       CardController.OnPointerUp calls it with count/2 for a stackable card
##       whose count is above 1.]
func split_card_stack(uid: int, amount: int = -1) -> int:
	var source = get_card_instance(uid)
	if source == null:
		return 0
	var count := int(source.count)
	if count <= 1:
		return 0
	var n := amount if amount > 0 else count / 2
	if n <= 0 or n >= count:
		return 0
	var copy = _copy_card_for_stack(source, n)
	source.count = count - n
	var source_index: int = rail_order.find(uid)
	var insert_at: int = (source_index + 1) if source_index >= 0 else rail_order.size()
	add_card_to_hand_at_rail(copy.uid, insert_at)
	return copy.uid


## Merges `source_uid` into `target_uid`.
## [SRC: CardController.CardStack 0x5286b0 — same card id, both cards carry the
##       可堆叠 tag; the target takes `count += other.count`, the other card is
##       removed from the player, and the target returns to its own bag/bagpos.
##       CardDropManager.DropCard 0x4ef4f0 calls it for hand targets and
##       CardSlotController.CardStack for occupied slots.]
func stack_cards(target_uid: int, source_uid: int) -> bool:
	if target_uid <= 0 or source_uid <= 0 or target_uid == source_uid:
		return false
	var target = get_card_instance(target_uid)
	var source = get_card_instance(source_uid)
	if target == null or source == null:
		return false
	if int(target.card_id) != int(source.card_id):
		return false
	if not _instance_is_stackable(target) or not _instance_is_stackable(source):
		return false
	target.count = int(target.count) + int(source.count)
	remove_card_instance_from_play(source_uid)
	return true


## [SRC: content/tag.json 可堆叠 (code stackable); CardExtensions.HasTag.]
func _instance_is_stackable(instance) -> bool:
	if instance == null:
		return false
	# HasTag reads the whole row; 可堆叠 may come from the definition even when
	# the runtime delta is empty, or from an inheritable equip.
	var tags: Dictionary = instance.tags
	var runtime_db = _runtime_db()
	if runtime_db != null and not runtime_db.get_card(int(instance.card_id)).is_empty():
		tags = effective_card_tags(instance.uid, runtime_db)
	return int(tags.get("可堆叠", tags.get("stackable", 0))) > 0


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
		player_card_order.erase(uid)
		return true
	return false


## Pay the cost condition's `need_cost_cards` amount out of a hand stack and put
## the paid portion into a rite slot. Returns the uid now occupying the slot, or
## 0 when the payment did not happen.
##
## This is the body the audit recorded as missing ("ClearNeedCosts 0x385470 has
## no decompiled callers, so the clone never actually deducts"). That note was
## looking at the wrong method: ClearNeedCosts is a ConditionContext field reset
## with no callers anywhere, and CostCondition.PostProcess is a *config-load*
## pass (Datapool.LoadRitePostProcess 0x4163c0 walks the rite nodes, translates
## each card's tag names via TranslateTag, then calls PostProcess to resolve
## Min/Max once). The real payment is CardSlotController.CardStack 0x53b0a0:
##
##   if (context.is_cost@0x60 == false) return 0;      // not a cost payment
##   iVar8 = card.count@0x20 - context.cost_count@0x64;
##   if (iVar8 < 1) {                                  // stack exactly/underpaid
##       PlayerExtensions.RemoveCard(player, card.id@0x18);   // whole card leaves
##   } else {                                          // stack larger than cost
##       card.set_count(iVar8);                        // remainder stays behind
##       lVar7 = CardExtensions.Copy(card, keep_count=true);
##       lVar7.set_count(context.cost_count@0x64);     // the paid slice
##   }
##   RecoveryCard(); SetCard(lVar7);                   // paid slice goes to the slot
##
## The whole method is gated on CardExtensions.HasTag(card, "stackable") at the
## top: a non-stackable card always takes the "whole card leaves" path.
## [SRC: CardSlotController.c @ CardStack (RVA 0x53b0a0) lines 855-892;
##       CostCondition.c @ IsSatisfied 0x3f6160 (sets +0x60/+0x64/+0x68);
##       datum literal 0x2593720 = "stackable";
##       CardExtensions.c @ Copy (0x37f4e0) keep-count flag.]
func pay_cost_into_slot(card_uid: int, slot: int, needed: int, db, rite_uid: int = 0) -> int:
	if slot <= 0 or needed < 0:
		return 0
	var source = get_card_instance(card_uid)
	if source == null:
		return 0
	var stackable := _instance_is_stackable(source)
	var remainder := int(source.count) - needed
	if not stackable or remainder < 1:
		# The whole card leaves the hand and the stack itself becomes the slot
		# card. This is the non-stackable path AND the exact/over-paid stack path.
		remove_card_from_hand(card_uid)
		add_card_to_slot(card_uid, slot, db, rite_uid)
		return card_uid
	# Stack larger than the cost: the remainder stays in hand and a copy carrying
	# exactly `needed` goes into the slot.
	source.count = remainder
	var paid_uid := copy_card_instance(card_uid, db, "slot")
	if paid_uid <= 0:
		source.count = remainder + needed
		return 0
	var paid = get_card_instance(paid_uid)
	if paid != null:
		paid.count = needed
	add_card_to_slot(paid_uid, slot, db, rite_uid)
	return paid_uid


## Evaluate the complete authored condition with a current-card context.
## No extraction of a cost leaf from its any/all parent is permitted.
## [SRC: RiteExtensions.CanPutCard 0x3918b0 invokes the slot condition list;
## CardSlotController.CardStack 0x53b0a0 creates a first-drop context.]
func slot_cost_needed(slot: int, card_uid: int, db, rite_uid: int = 0) -> int:
	if slot <= 0 or db == null or get_card_instance(card_uid) == null:
		return 0
	var slot_def := slot_definition(slot, rite_uid)
	if slot_def.is_empty():
		return 0
	var card := card_data_for(card_uid, db)
	var rite = get_rite_instance(rite_uid)
	var ctx := {
		"state": self, "db": db, "acting_card_uid": card_uid,
		"acting_card": card, "acting_card_id": int(card.get("id", 0)),
		"acting_card_only": true, "is_first_drop": true,
		"rite_uid": rite_uid, "attr_slots": [],
		"slot_entries": cards_in_slot_entries_for_rite(rite_uid),
		"rite_id": int(rite.id) if rite != null else 0,
	}
	if not ConditionEval.can_put_card(slot_def.get("condition", {}), ctx):
		return 0
	return int(ctx.get("cost_count", 0)) if bool(ctx.get("is_cost", false)) else 0


## The rite definition's cards_slot entry for a 1-based slot number.
func slot_definition(slot: int, rite_uid: int = 0) -> Dictionary:
	var rite = get_rite_instance(rite_uid)
	if rite == null:
		return {}
	var runtime_db = _runtime_db()
	if runtime_db == null:
		return {}
	var definition: Dictionary = runtime_db.get_rite(int(rite.id))
	var slot_defs: Variant = definition.get("cards_slot", {})
	if not (slot_defs is Dictionary):
		return {}
	var entry: Variant = (slot_defs as Dictionary).get("s%d" % slot, null)
	return entry if entry is Dictionary else {}


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


func set_current_bag_index(index: int) -> int:
	# [SRC: PlayerExtensions.SetCurrentBagIndex 0x38f500; Player.BagIndex@0x150.]
	if index >= 0 and index < 4:
		current_bag_index = index
	return current_bag_index


## The historical `hand` collection represents unassigned Player.cards,
## including NPCs. Eligibility is derived, so gaining/losing ownership changes
## visibility without deleting or recreating a character.
## [SRC: CardExtensions.IsHandCard 0x3827c0, dump.cs:388147;
## stringliteral 0x2580360=own, 0x258ac48=adherent, 0x25828f8=player.]
func is_hand_card(uid: int, db = null) -> bool:
	if get_card_instance(uid) == null:
		return false
	var config = db if db != null else _runtime_db()
	var tags := effective_card_tags(uid, config)
	for code in ["own", "adherent", "player"]:
		if int(tags.get(config.tag_code_to_name.get(code, code), 0)) > 0:
			return true
	return false


func visible_rail_card_uids(bag_index: int = -1) -> Array[int]:
	sync_rail_order()
	var page := current_bag_index if bag_index < 0 else bag_index
	var out: Array[int] = []
	for uid in rail_order:
		if card_is_on_table(int(uid)):
			continue
		var instance = get_card_instance(int(uid))
		if instance == null or int(instance.bag) != page:
			continue
		# The host's active-Sultan rail is a separate presentation path. The
		# three-tag gate applies to the ordinary Player.cards population.
		if (int(uid) in hand and is_hand_card(int(uid))) or is_active_sudan_card(int(uid)):
			out.append(int(uid))
	return out


## [SRC: GameController.HandCardSortByCondition 0x5515a0 writes bagpos=i+1;
## comparator 0x56f1c0 shared with FlashAndSortCard (dump.cs:319328),
## CardExtensions.CompareBagPos 0x37eff0; Card id/uid/bagpos offsets
## independently confirmed in dump.cs:389593.]
func sort_current_hand_by_condition(db, validator: Callable) -> Array[int]:
	var page := visible_rail_card_uids()
	var qualified := {}
	for uid in page:
		qualified[uid] = bool(validator.call(card_data_for(uid, db)))
	page.sort_custom(func(a: int, b: int) -> bool:
		if qualified[a] != qualified[b]:
			return qualified[a]
		var left = get_card_instance(a)
		var right = get_card_instance(b)
		var left_pos: int = left.bag_pos if left.bag_pos > 0 else 2147483647
		var right_pos: int = right.bag_pos if right.bag_pos > 0 else 2147483647
		if left_pos != right_pos:
			return left_pos < right_pos
		if left.card_id != right.card_id:
			return left.card_id < right.card_id
		return left.uid < right.uid
	)
	var page_uids := {}
	var matches: Array[int] = []
	for index in page.size():
		var uid := page[index]
		page_uids[uid] = true
		get_card_instance(uid).bag_pos = index + 1
		if qualified[uid]:
			matches.append(uid)
	var next := 0
	for index in rail_order.size():
		if page_uids.has(rail_order[index]):
			rail_order[index] = page[next]
			next += 1
	_sync_hand_order_from_rail()
	return matches


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
	# [SRC: PlayerExtensions.InitRite 0x38e140, RiteNode.once_new@0x50;
	# dump.cs:393182. Only the first generation is new when once_new == 1.]
	var once_new := int(rite.get("once_new", 0))
	instance.new_born = not only_rites.has(id) if once_new == 1 else once_new == 0
	if not _adsorb_open_slots(instance, rite, db, rng):
		remove_rite_instance(instance.uid)
		# Failed adsorption rolls back the allocation in the original.
		next_rite_uid -= 1
		return 0
	# InitRite adds the id only after open-slot adsorption succeeded and the
	# runtime rite has joined player.rites. This records every rite id; unlike
	# cards, RiteNode has no is_only config gate for this HashSet.
	# [SRC: PlayerExtensions.c @ InitRite (0x38e140) lines 769-812]
	only_rites[id] = true
	if once_new == 1 and not once_new_rites_is_show.has(id):
		once_new_rites_is_show[id] = false
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
		var chosen_uid := _choose_adsorb_candidate(candidates, rng)
		if not _remove_adsorb_candidate(chosen_uid):
			_reback_absorbed_cards(absorbed, instance.uid)
			return false
		var slot_number := slot_key.substr(1).to_int()
		add_card_to_slot(chosen_uid, slot_number, db, instance.uid)
		absorbed.append({"uid": chosen_uid, "slot": slot_number})
	return true


func _adsorbable_card_uids() -> Array[int]:
	var out: Array[int] = []
	for card in source_player_cards():
		out.append(card.uid)
	return out


## [SRC: RiteExtensions.AdsorbCards0x38fca0, .c:1425-1438;
## dump.cs:389090. Ordinary candidates use Random.Range only when Count>1.]
func _choose_adsorb_candidate(candidates: Array[int], rng) -> int:
	if candidates.size() == 1:
		return candidates[0]
	var index: int = rng.range_int_half_open(0, candidates.size()) if rng != null else randi_range(0, candidates.size() - 1)
	return candidates[index]


## Daily AdsorbCards pass: once per round, every OPEN slot of every player rite
## samples an eligible player card, if that slot is
## still empty. This is the round-end counterpart of the creation-time
## adsorption in InitRite and runs for every rite, not just new ones.
## [SRC: RiteExtensions.c @ AdsorbCards (RVA 0x38fca0): the outer loop walks
##       RiteNode+0xB0 (slot definitions) as the slot index source, reads
##       rite+0x30 slot entries, keeps only entries whose RiteNode.Slot
##       open_adsorb @+0x20 is true, then walks player+0x88 (Player.cards) in
##       order, collects accepted candidates and selects randomly, removing it from
##       the player list and writing it into rite+0x30[index].
##       Caller: GameController.__c__DisplayClass142_0.c @ <OnNextRound>b__6
##       (0x570b00) prelude — for each r in player+0x90 (List<Rite>) call
##       RiteExtensions.AdsorbCards(r, player).]
func adsorb_open_slots_daily(db, rng) -> Array:
	var absorbed: Array = []
	var uids: Array = rite_instances.keys()
	uids.sort()
	for raw_uid in uids:
		var instance = rite_instances.get(raw_uid, null)
		if instance == null:
			continue
		absorbed.append_array(adsorb_open_slots(instance, db, rng))
	return absorbed


## One rite's open-slot adsorption. Returns the rows it actually filled.
func adsorb_open_slots(instance, db, rng) -> Array:
	var absorbed: Array = []
	if instance == null or db == null:
		return absorbed
	var rite: Dictionary = db.get_rite(int(instance.id))
	if rite.is_empty():
		return absorbed
	var slots: Dictionary = rite.get("cards_slot", {})
	var slot_keys: Array[String] = []
	for key in slots.keys():
		slot_keys.append(str(key))
	slot_keys.sort_custom(func(a: String, b: String) -> bool: return a.substr(1).to_int() < b.substr(1).to_int())
	for slot_key in slot_keys:
		var slot_def: Dictionary = slots.get(slot_key, {})
		if int(slot_def.get("open_adsorb", 0)) != 1:
			continue
		# An occupied slot is skipped, not an abort: the source only looks at
		# entries whose Card value is still null.
		if int(instance.slot_cards.get(slot_key, 0)) > 0:
			continue
		var candidates: Array[int] = []
		for card_uid in _adsorbable_card_uids():
			var uid := int(card_uid)
			var card: Dictionary = card_data_for(uid, db)
			if not _can_adsorb_card(slot_def, card, instance, rite, db, rng):
				continue
			candidates.append(uid)
		if candidates.is_empty():
			continue
		var uid := _choose_adsorb_candidate(candidates, rng)
		if not _remove_adsorb_candidate(uid):
			continue
		var slot_number := slot_key.substr(1).to_int()
		add_card_to_slot(uid, slot_number, db, instance.uid)
		absorbed.append({"uid": uid, "slot": slot_number, "rite_uid": int(instance.uid)})
	return absorbed


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
	var condition: Variant = slot_def.get("condition", {})
	var rite_state := {}
	for slot_key in instance.slot_cards:
		var slotted_card = card_data_for(int(instance.slot_cards[slot_key]), db)
		if not slotted_card.is_empty():
			rite_state[str(slot_key)] = int(slotted_card.get("id", 0))
	var attr_slots: Array[String] = []
	for key in rite.get("cards_slot", {}).keys():
		attr_slots.append(str(key))
	return ConditionEval.can_put_card(condition, {
		"db": db,
		"state": self,
		"rng": rng,
		"rite_state": rite_state,
		"attr_slots": attr_slots,
		"rite_uid": int(instance.uid),
		"rite_id": int(instance.id),
		"slot_entries": cards_in_slot_entries_for_rite(int(instance.uid)),
		"acting_card": card,
		"acting_card_id": int(card.get("id", 0)),
		"acting_card_uid": int(card.get("instance_uid", 0)),
		"acting_card_only": true,
	})


## Rites whose open slots would accept this card.
## [SRC: CardHandler.GetCardSatisfiedRite 0x52e770 — walk the player's rites,
##       skip started ones (Rite.start +0x22), and keep those where
##       RiteExtensions.GetSatisfiedSlotIndex 0x392ac0 finds a slot; the caller
##       GameController.ShowSatisfiedRite 0x5576b0 then plays
##       RiteController.ShowEffect(1) on each of them.]
func satisfied_rite_uids_for_card(card_uid: int, db, rng = null) -> Array[int]:
	var out: Array[int] = []
	var card: Dictionary = card_data_for(card_uid, db)
	if card.is_empty():
		return out
	var rite_uids: Array = rite_instances.keys()
	rite_uids.sort()
	for raw_uid in rite_uids:
		var rite_uid := int(raw_uid)
		var instance = get_rite_instance(rite_uid)
		if instance == null or bool(instance.start):
			continue
		var definition: Dictionary = db.get_rite(instance.id) if db != null else {}
		var slots: Dictionary = definition.get("cards_slot", {})
		for slot_key in slots.keys():
			var slot_def: Dictionary = slots[slot_key]
			if int(slot_def.get("open_adsorb", 0)) == 1:
				continue
			if instance.slot_cards.has(slot_key):
				continue
			if _can_adsorb_card(slot_def, card, instance, definition, db, rng):
				out.append(rite_uid)
				break
	return out


func _reback_absorbed_cards(absorbed: Array[Dictionary], rite_uid: int) -> void:
	for entry in absorbed:
		var card_uid := int(entry.get("uid", 0))
		remove_card_from_slot(card_uid, int(entry.get("slot", 0)), rite_uid)
		if is_active_sudan_card(card_uid):
			var sudan_instance = get_card_instance(card_uid)
			if sudan_instance != null:
				if card_uid not in player_card_order:
					player_card_order.append(card_uid)
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


## PlayerExtensions.AddRitePin is an ordered List<int> append with a Contains
## guard.  These ids are map endpoints, not an alternate live-rite list.
## [SRC: PlayerExtensions.c AddRitePin (0x38c360)]
func add_rite_pin(rite_id: int) -> bool:
	if rite_id <= 0 or rite_id in rite_pins:
		return false
	rite_pins.append(rite_id)
	return true


## PlayerExtensions.RemoveRitePin delegates to List<int>.Remove.
## [SRC: PlayerExtensions.c RemoveRitePin (0x38efe0)]
func remove_rite_pin(rite_id: int) -> bool:
	var index := rite_pins.find(rite_id)
	if index < 0:
		return false
	rite_pins.remove_at(index)
	return true


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
				if card_uid not in player_card_order:
					player_card_order.append(card_uid)
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
## of that config id are removed. Their cards return to Player.cards.
## [SRC: CleanRite.c @ Do (RVA 0x4f3ae0): player.rites(+0x90) RemoveAll with
##       the settling-rite exclusion; single value 1 = all others]
func remove_rite_instances_by_id(rite_id: int, except_uid: int = 0) -> int:
	var removed := 0
	for uid in rite_instances.keys().duplicate():
		var instance: RiteInstance = rite_instances[uid]
		if int(instance.uid) == except_uid:
			continue
		if rite_id <= 1 or int(instance.id) == rite_id:
			# [SRC: CleanRite.DisplayClass3_1 b__2 0x506ed0 and 3_3 b__5
			# 0x507290 call ReturnCards before destroying the presentation.
			# Original event 5300030 refreshes the shop without killing its NPCs.]
			return_rite_cards(int(instance.uid), _runtime_db())
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
	player_card_order.erase(uid)
	_record_card_op(CARD_OP_DELETE, uid)
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


func schedule_delay(payload: Variant, context: Dictionary = {}) -> void:
	if payload.is_empty():
		return
	# DelayOp.round is a remaining Next Day countdown. The original decrements
	# it in UpdateSingleDelayOps on every NextDay, regardless of Player.round.
	# [SRC: PlayerExtensions.c @ AddDelayOp (RVA 0x38be90);
	#       GameController.c @ UpdateSingleDelayOps (RVA 0x55a700)]
	var delay_round := maxi(int(SourceJSON.member(payload, "round", 0)), 0)
	delayed_operations.append({
		"id": int(SourceJSON.member(payload, "id", 0)),
		"round": delay_round,
		"delay_mode": "next_day_countdown",
		"payload": payload.duplicate(true),
		# Keep nested unique-key operation order across sorted save JSON too.
		"payload_json": JSON.stringify(payload, "", false),
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
	# Matched events enter the serial operation runner. Interaction suspends
	# the remaining actions; silent actions need no additional event panel.
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
## [SRC: ChangeCardName.DoTemplate0x4f2130 reads Player.cards@0x88.
## Unified insertion order is independent of bag/rail display sorting.
## Neither ordinary nor active Sudan cards remain members while in a rite.]
func source_player_cards() -> Array:
	var out: Array = []
	var valid: Array[int] = []
	# Migration fallback preserves known insertion order, not the visual rail.
	for uid in card_instances:
		if int(uid) not in player_card_order:
			player_card_order.append(int(uid))
	for uid in player_card_order:
		var card = get_card_instance(uid)
		if card != null and card.zone in ["hand", "sudan"]:
			out.append(card)
			valid.append(uid)
	player_card_order = valid
	return out


func repair_pool_uid_collisions() -> void:
	# Legacy saves used a separate pool allocator. Preserve live-card UIDs;
	# only unreferenced pool objects need a replacement identity on collision.
	var occupied := {}
	for uid in card_instances:
		occupied[int(uid)] = true
		next_card_uid = maxi(next_card_uid, int(uid) + 1)
	for entry in sudan_deck:
		next_card_uid = maxi(next_card_uid, int(entry.uid) + 1)
	for entry in sudan_deck:
		if int(entry.uid) <= 0 or occupied.has(int(entry.uid)):
			entry.uid = next_card_uid
			next_card_uid += 1
		occupied[int(entry.uid)] = true
	sudan_pool_next_uid = next_card_uid



## [SRC: PlayerExtensions.GetTotalCards0x38de90, dump.cs:388887;
## Player.cards@0x88 then rites@0x90 -> Rite.cards@0x30, no equip recursion.]
func source_total_cards() -> Array:
	var out := source_player_cards()
	for rite_uid in rite_instances:
		var entries := cards_in_slot_entries_for_rite(int(rite_uid))
		entries.sort_custom(func(a, b): return int(a.slot) < int(b.slot))
		for entry in entries:
			var card = get_card_instance(int(entry.card_uid))
			if card != null:
				out.append(card)
	return out


## Cost payment candidates: Player.cards@0x88 in list order. The clone keeps one
## instance map instead of one list, so this is every player-owned card by uid
## order (hand, active Sultan, rite slots) — the same OLDEST-FIRST order the
## source's enumerator produces, since uid order is insertion order.
## Equipped cards and removed cards are not Player.cards entries.
## [SRC: CostCondition.c @ IsSatisfied 0x3f6160 enumerates player+0x88;
##       PlayerExtensions.GetHandCards vs GetTotalCards are separate reads.]
func cost_candidate_cards() -> Array:
	return source_player_cards()


## Single-tag lookup on the effective GetTag row. Callers must not read
## instance.tags directly: that dictionary is the runtime delta only.
## [SRC: CardExtensions.c @ GetTag (RVA 0x3814a0), HasTag (0x382250).]
func _card_tag_value(uid: int, tag_name: String, db) -> int:
	return int(effective_card_tags(uid, db).get(tag_name, 0))


## Result-text playback rate for one auto-play state. The source has exactly two
## rates, both seeded from variable.json onto Player, and the panel picks
## between them by its autoPlay flag; the value is clamped before use.
## [SRC: RiteResultPanelController.c @ UpdateResultTextSpeed (0x5a74a0):
##       autoPlay == 0 -> Player.result_text_play_rate@0x68, else
##       Player.result_text_auto_play_rate@0x6C, clamped to
##       [DAT_181c92b4c, DAT_181c9e4d0] = [0.5, 100.0] (read from
##       GameAssembly.dll .rdata) and written to ScrollViewTextController+0x38.]
func source_result_text_rate(auto_play: bool) -> float:
	var db = _runtime_db()
	var config: Dictionary = db.variable_config if db != null and db.get("variable_config") != null else {}
	var key := "result_text_auto_play_rate" if auto_play else "result_text_play_rate"
	var rate := float(config.get(key, 1.0))
	return clampf(rate, 0.5, 100.0)


## ConfigDB reachable from this state when a caller has none at hand. Snapshots
## below need it to resolve the definition tag row. Hand-built states in tests
## never call setup_new_run, so fall back to the shipped content once.
func _runtime_db():
	if event_runtime != null and event_runtime._db != null:
		return event_runtime._db
	if _fallback_db == null:
		_fallback_db = ConfigDB.new()
		_fallback_db.load_all()
	return _fallback_db


## Every table entry is a snapshot derived from CardInstance placement. The tag
## row is the effective GetTag result (definition + delta + inheritable equips),
## so consumers must mutate through the tag APIs below rather than the snapshot.
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
			"tags": effective_card_tags(instance.uid, _runtime_db()),
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
			"tags": effective_card_tags(instance.uid, _runtime_db()),
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


## [SRC: DesktopCleanCard.DoTemplate 0x4f8250 / callback 0x5208b0:
## Player.cards in order, positive value is a count budget, <=0 means all.]
func clean_table_card_instances(selector: String, count: int, db) -> Array:
	var cleaned: Array = []
	var remaining := count if count > 0 else 99999999
	for instance in preload("res://sim/operation_filter.gd").select_desktop(self, db, selector):
		if remaining <= 0:
			break
		if instance.count > remaining:
			instance.count -= remaining
			break
		remaining -= instance.count
		cleaned.append({"id": instance.card_id, "card_uid": instance.uid, "rite_uid": 0})
		remove_card_instance_from_play(instance.uid)
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
	player_card_order.erase(uid)
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
	_record_card_op(CARD_OP_DELETE, uid)


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
