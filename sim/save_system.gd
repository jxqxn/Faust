## Save/load system. Serializes the GameState to a JSON file so the player can
## quit and resume. The original uses Datapool.SaveGlobal (binary); this clone
## uses JSON for simplicity and debuggability.
## [RUNTIME_OPEN] — the original's exact serialization format is not needed
## for gameplay fidelity; we preserve all gameplay-relevant fields.
class_name SaveSystem
extends RefCounted

const CardInstanceData = preload("res://sim/card_instance.gd")

const DEFAULT_SAVE_PATH := "user://save.json"
const SAVE_VERSION := 8
# v6 moved gold from the coin_count scalar to stacked gold card objects
# (GenCard 2000029). v7 moved the back-to-prev quota off the run payload onto
# the global domain (user://global.json, COUNTER_BACK_TO_PREV 7100007).
# v8 adds Player.pins, the ordered completed-rite endpoint list.  v5-v7 saves
# migrate with an empty list; anything older stays rejected.
const MIN_LOADABLE_SAVE_VERSION := 5
const SAVE_KIND_PLAYER := "player"
const USER_ARCHIVE_ROOT := "user://user_archives"
const USER_ARCHIVE_INDEX_NAME := "user_archives.json"
const MAX_USER_ARCHIVE_COUNT := 50
const DEFAULT_ROUND_SAVE_ROOT := "user://"
const ROUND_BEGIN_NAME := "round_%d.json"
const ROUND_END_NAME := "round_%d_end.json"

static var save_path_override := ""
static var user_archive_root_override := ""
static var round_save_root_override := ""


static func save_path() -> String:
	return save_path_override if save_path_override != "" else DEFAULT_SAVE_PATH


static func use_save_path(path: String) -> void:
	save_path_override = path


static func use_default_save_path() -> void:
	save_path_override = ""


## Round snapshots sit beside auto_save in the original save root. Tests may
## redirect them independently so no real continue data is touched.
## [SRC: DatapoolExtensions.c @ SaveRoundBegin (RVA 0x3f9050) /
##       SaveRoundEnd (RVA 0x3f9120); stringliteral.json 0x258BED0
##       "round_{0}" and 0x258BF40 "round_{0}_end"]
static func round_save_root() -> String:
	return round_save_root_override if round_save_root_override != "" else DEFAULT_ROUND_SAVE_ROOT


static func use_round_save_root(path: String) -> void:
	round_save_root_override = path


static func use_default_round_save_root() -> void:
	round_save_root_override = ""


static func round_begin_save_path(round: int) -> String:
	return _round_save_path(ROUND_BEGIN_NAME % round)


static func round_end_save_path(round: int) -> String:
	return _round_save_path(ROUND_END_NAME % round)


static func _round_save_path(filename: String) -> String:
	return "%s/%s" % [round_save_root().trim_suffix("/"), filename]


## Manual archives deliberately use a separate index and payload directory.
## [SRC: Datapool.c @ SaveUserArchive (RVA 0x41aa50);
##  GameApplicationConfig.USER_ARCHIVE_SAVE_ROOT (dump.cs:542386-542392)]
static func user_archive_root() -> String:
	return user_archive_root_override if user_archive_root_override != "" else USER_ARCHIVE_ROOT


static func use_user_archive_root(path: String) -> void:
	user_archive_root_override = path


static func use_default_user_archive_root() -> void:
	user_archive_root_override = ""


static func user_archive_index_path() -> String:
	return "%s/%s" % [user_archive_root(), USER_ARCHIVE_INDEX_NAME]


static func user_archive_save_path(index: int) -> String:
	return "%s/archive_%02d.json" % [user_archive_root(), index]


## Serialize the game state to a dictionary.
static func serialize(state) -> Dictionary:
	var sudan_cards_data: Array = []
	for asc in state.active_sudan_cards:
		sudan_cards_data.append({
			"card_id": asc.card_id,
			"card_uid": asc.card_uid,
			"days_left": asc.days_left,
			"drawn_round": asc.drawn_round,
		})
	var rite_instances_data: Array = []
	for instance in state.available_rite_instances():
		rite_instances_data.append(instance.to_save_dict())
	return {
		"version": SAVE_VERSION,
		"save_kind": SAVE_KIND_PLAYER,
		"player_save": true,
		"difficulty_index": state.difficulty_index,
		"round_number": state.round_number,
		"day": state.day,
		"min_round": state.min_round,
		"world_location_id": state.world_location_id,
		"world_spawn_id": state.world_spawn_id,
		"world_position_ratio": state.world_position_ratio,
		"visited_world_locations": state.visited_world_locations.duplicate(),
		"redraws_left": state.redraws_left,
		"sudan_redraw_count": state.sudan_redraw_count,
		"sudan_card_init_life": state.sudan_card_init_life,
		"sudan_redraw_times_per_round": state.sudan_redraw_times_per_round,
		"sudan_redraw_times": state.sudan_redraw_times,
		"sudan_redraw_times_recovery_round": state.sudan_redraw_times_recovery_round,
		"success": state.success,
		"over_reason": state.over_reason,
		"hand": state.hand.duplicate(),
		"rail_order": state.rail_order.duplicate(),
		"sudan_deck": state.sudan_deck.duplicate(),
		"sudan_pool_tags": state.sudan_pool_tags.duplicate(true),
		"auto_gen_sudan_card": state.auto_gen_sudan_card,
		"active_sudan_cards": sudan_cards_data,
		"card_instances": state.card_instances.values().map(func(instance): return instance.to_save_dict()),
		"next_card_uid": state.next_card_uid,
		"player_actor_uid": state.player_actor_uid,
		"rite_instances": rite_instances_data,
		"next_rite_uid": state.next_rite_uid,
		"active_rite_uid": state.active_rite_uid,
		"rite_pins": state.rite_pins.duplicate(),
		"available_rites": state.available_rites.duplicate(),
		"started_rites": state.started_rites.duplicate(),
		"auto_result_rites": state.auto_result_rites.duplicate(),
		"rite_auto_result": state.rite_auto_result,
		"last_round_rite_data": state.last_round_rite_data.duplicate(true),
		"custom_rite_names": state.custom_rite_names.duplicate(true),
		"player_card_names": state.player_card_names.duplicate(true),
		"only_cards": _sorted_set_keys(state.only_cards),
		"only_rites": _sorted_set_keys(state.only_rites),
		"cached_event": state.cached_event.duplicate(),
		"notes": state.notes.duplicate(true),
		"sudan_box_show": state.sudan_box_show,
		"story_unshow": state.story_unshow,
		"prestige_unshow": state.prestige_unshow,
		"deadline_unshow": state.deadline_unshow,
		"helpbtn_unshow": state.helpbtn_unshow,
		"once_new_rites_is_show": state.once_new_rites_is_show.duplicate(true),
		"gen_cards": state.gen_cards.duplicate(true),
		"gen_tags": state.gen_tags.duplicate(true),
		"ended_rites": state.ended_rites.duplicate(true),
		"pending_operations": state.pending_operations.duplicate(true),
		"delayed_operations": state.delayed_operations.duplicate(true),
		"event_status": state.event_status.duplicate(true),
		"event_done": state.event_done.duplicate(true),
		"timing_rounds": state.timing_rounds.duplicate(true),
		"begin_guide": state.begin_guide.duplicate(true),
		"guide_cues": state.guide_cues.duplicate(true),
		"event_init_profile_id": state.event_init_profile_id,
		"local_counters": state.local_counters.duplicate(true),
		"global_counters": state.global_counters.duplicate(true),
	}


## Deserialize a dictionary back into a GameState (requires db for setup).
static func deserialize(data: Dictionary, state, db) -> void:
	state.difficulty_index = int(data.get("difficulty_index", 1))
	state.difficulty_config = db.get_difficulty(state.difficulty_index)
	state.round_number = int(data.get("round_number", 1))
	state.day = int(data.get("day", 1))
	state.min_round = maxi(1, int(data.get("min_round", 1)))
	state.world_location_id = str(data.get("world_location_id", "school_rooftop"))
	state.world_spawn_id = str(data.get("world_spawn_id", "default"))
	state.world_position_ratio = clampf(float(data.get("world_position_ratio", 0.5)), 0.04, 0.96)
	state.visited_world_locations.clear()
	for raw_location_id in data.get("visited_world_locations", [state.world_location_id]):
		var location_id := str(raw_location_id)
		if not location_id.is_empty() and location_id not in state.visited_world_locations:
			state.visited_world_locations.append(location_id)
	if state.world_location_id not in state.visited_world_locations:
		state.visited_world_locations.append(state.world_location_id)
	# Gold lives in gold card instances since v6 (see deserialize migration);
	# gold dice live in the counter dict (COUNTER_GOLD_DICE) since v6; the
	# back-to-prev quota lives on the global domain since v7.
	var legacy_coin: int = int(data.get("coin_count", 0)) if data.has("coin_count") else -1
	var legacy_gold_dice: int = int(data.get("gold_dice", 0)) if data.has("gold_dice") else -1
	var legacy_back_to_prev: int = int(data.get("back_to_prev_left", 0)) if data.has("back_to_prev_left") else -1
	state.gold_dice = int(data.get("gold_dice", 0))
	var fallback_redraw_per_round := int(state.difficulty_config.get("sudan_redraw_times_per_round", 1))
	state.sudan_redraw_times_per_round = int(data.get("sudan_redraw_times_per_round", fallback_redraw_per_round))
	var legacy_redraws_left := int(data.get("redraws_left", state.sudan_redraw_times_per_round))
	state.sudan_redraw_times = maxi(0, int(data.get("sudan_redraw_times",
		maxi(0, state.sudan_redraw_times_per_round - legacy_redraws_left))))
	state.sudan_redraw_times_recovery_round = int(data.get("sudan_redraw_times_recovery_round",
		db.init_config.get("sudan_redraw_times_recovery_round", 7)))
	state.sudan_card_init_life = int(data.get("sudan_card_init_life",
		state.difficulty_config.get("sudan_life_time", 7)))
	if state.has_method("_sync_redraws_left"):
		state._sync_redraws_left()
	else:
		state.redraws_left = maxi(0, state.sudan_redraw_times_per_round - state.sudan_redraw_times)
	state.success = bool(data.get("success", false))
	state.over_reason = int(data.get("over_reason", -2147483648))
	state.sudan_redraw_count = int(data.get("sudan_redraw_count", 1))
	state.hand.clear()
	state.card_instances.clear()
	for card_data in data.get("card_instances", []):
		if card_data is Dictionary:
			var card_instance = CardInstanceData.from_save_dict(card_data)
			if card_instance.uid > 0 and card_instance.card_id > 0:
				state.card_instances[card_instance.uid] = card_instance
	state.next_card_uid = int(data.get("next_card_uid", 1))
	for card_uid in state.card_instances:
		state.next_card_uid = maxi(state.next_card_uid, int(card_uid) + 1)
	state.player_actor_uid = int(data.get("player_actor_uid", 0))
	if state.has_method("ensure_player_actor"):
		state.ensure_player_actor(db)
	if state.has_method("repair_equipment_links"):
		state.repair_equipment_links()
	for cid in data.get("hand", []):
		state.hand.append(int(cid))
	state.sudan_deck.clear()
	for cid in data.get("sudan_deck", []):
		state.sudan_deck.append(int(cid))
	state.sudan_pool_tags.clear()
	var saved_pool_tags: Dictionary = data.get("sudan_pool_tags", {})
	for card_id in saved_pool_tags:
		if saved_pool_tags[card_id] is Dictionary:
			var normalized_tags: Dictionary = {}
			for tag_name in saved_pool_tags[card_id]:
				normalized_tags[str(tag_name)] = int(saved_pool_tags[card_id][tag_name])
			state.sudan_pool_tags[int(card_id)] = normalized_tags
	state.auto_gen_sudan_card = bool(data.get("auto_gen_sudan_card", true))
	state.active_sudan_cards.clear()
	var ASC = preload("res://sim/round_loop.gd").ActiveSudan
	for asc_data in data.get("active_sudan_cards", []):
		var asc = ASC.new(
			int(asc_data.get("card_id", 0)),
			int(asc_data.get("days_left", 0)),
			int(asc_data.get("drawn_round", 0)),
			int(asc_data.get("card_uid", 0))
		)
		state.active_sudan_cards.append(asc)
	state.rail_order.clear()
	for cid in data.get("rail_order", []):
		state.rail_order.append(int(cid))
	state.rite_instances.clear()
	for instance_data in data.get("rite_instances", []):
		if instance_data is Dictionary:
			var instance := RiteInstance.from_save_dict(instance_data)
			if instance.uid > 0 and instance.id > 0:
				state.rite_instances[instance.uid] = instance
	state.next_rite_uid = int(data.get("next_rite_uid", 1))
	for rite_uid in state.rite_instances:
		state.next_rite_uid = maxi(state.next_rite_uid, int(rite_uid) + 1)
	state.active_rite_uid = int(data.get("active_rite_uid", 0))
	state.rite_pins.clear()
	for raw_rite_id in data.get("rite_pins", []):
		state.add_rite_pin(int(raw_rite_id))
	state.available_rites.clear()
	for rid in data.get("available_rites", db.get_default_rites()):
		state.available_rites.append(int(rid))
	state.started_rites.clear()
	for rid in data.get("started_rites", []):
		state.started_rites.append(int(rid))
	state.auto_result_rites.clear()
	for rid in data.get("auto_result_rites", []):
		state.auto_result_rites.append(int(rid))
	state.rite_auto_result = bool(data.get("rite_auto_result", false))
	state.custom_rite_names = _restore_nonempty_string_map(data.get("custom_rite_names", {}))
	state.player_card_names = _restore_nonempty_string_map(data.get("player_card_names", {}))
	state.only_cards = _restore_positive_id_set(data.get("only_cards", []))
	state.only_rites = _restore_positive_id_set(data.get("only_rites", []))
	state.cached_event.clear()
	for raw_event_id in data.get("cached_event", []):
		state.add_cached_event(int(raw_event_id))
	# Journal pages restore with int-normalized fields (JSON parses numbers
	# as floats).
	state.notes.clear()
	for raw_page in data.get("notes", []):
		var page: Array = []
		if raw_page is Array:
			for raw_note in raw_page:
				if raw_note is Dictionary:
					page.append({
						"type": int(raw_note.get("type", 0)),
						"id": int(raw_note.get("id", 0)),
						"uid": int(raw_note.get("uid", 0)),
						"count": int(raw_note.get("count", 0)),
					})
		state.notes.append(page)
	state.sudan_box_show = bool(data.get("sudan_box_show", false))
	state.story_unshow = bool(data.get("story_unshow", false))
	state.prestige_unshow = bool(data.get("prestige_unshow", false))
	state.deadline_unshow = bool(data.get("deadline_unshow", false))
	state.helpbtn_unshow = bool(data.get("helpbtn_unshow", false))
	state.once_new_rites_is_show = _restore_int_bool_dictionary(data.get("once_new_rites_is_show", {}))
	state.gen_cards = _restore_int_count_dictionary(data.get("gen_cards", {}))
	state.gen_tags = _restore_string_count_dictionary(data.get("gen_tags", {}))
	state.last_round_rite_data.clear()
	var saved_last_rite_data = data.get("last_round_rite_data", {})
	if saved_last_rite_data is Dictionary:
		for raw_rite_id in saved_last_rite_data:
			var raw_slots = saved_last_rite_data[raw_rite_id]
			if not (raw_slots is Dictionary):
				continue
			var slots := {}
			for raw_slot_key in raw_slots:
				var raw_card = raw_slots[raw_slot_key]
				if not (raw_card is Dictionary):
					continue
				var card_id := int(raw_card.get("id", 0))
				var count := int(raw_card.get("count", 0))
				if card_id > 0 and count > 0:
					slots[str(raw_slot_key)] = {"id": card_id, "count": count}
			state.last_round_rite_data[int(raw_rite_id)] = slots
	state.ended_rites.clear()
	var saved_ended_rites = data.get("ended_rites", {})
	if saved_ended_rites is Dictionary:
		for rid in saved_ended_rites:
			state.ended_rites[int(rid)] = int(saved_ended_rites[rid])
	if state.has_method("_ensure_legacy_rite_instances"):
		state._ensure_legacy_rite_instances()
	if state.has_method("_sync_rite_instance_cards"):
		state._sync_rite_instance_cards()
	state.pending_operations.clear()
	if data.get("pending_operations", null) is Array:
		for operation in data.pending_operations:
			if operation is Dictionary and str(operation.get("kind", "")) in ["event", "prompt", "choice", "sleep", "rename_card"]:
				state.pending_operations.append(operation.duplicate(true))
	else:
		# First queue-schema saves were still v5. Their old split queues have no
		# cross-kind ordering metadata, so preserve the only deterministic order:
		# queued events first, followed by prompts, while retaining event context.
		var saved_event_contexts: Dictionary = data.get("event_contexts", {})
		for eid in data.get("event_queue", []):
			var event_id := int(eid)
			var legacy_context: Dictionary = saved_event_contexts.get(str(event_id), saved_event_contexts.get(event_id, {}))
			state.queue_event(event_id, legacy_context if legacy_context is Dictionary else {})
		for prompt in data.get("event_prompts", []):
			if prompt is Dictionary:
				state.queue_prompt(prompt)
	state.delayed_operations.clear()
	for operation in data.get("delayed_operations", []):
		if operation is Dictionary:
			var restored_delay: Dictionary = operation.duplicate(true)
			# v5 queue saves created before the countdown fix stored an absolute
			# GameState.round_number target. Convert them at the load boundary.
			if str(restored_delay.get("delay_mode", "")) != "next_day_countdown":
				restored_delay["round"] = maxi(0, int(restored_delay.get("round", 0)) - state.round_number)
				restored_delay["delay_mode"] = "next_day_countdown"
			state.delayed_operations.append(restored_delay)
	state.event_status.clear()
	var saved_event_status: Dictionary = data.get("event_status", {})
	for event_id in saved_event_status:
		state.event_status[int(event_id)] = bool(saved_event_status[event_id])
	state.event_done.clear()
	var saved_event_done: Dictionary = data.get("event_done", {})
	for event_id in saved_event_done:
		state.event_done[int(event_id)] = bool(saved_event_done[event_id])
	state.timing_rounds.clear()
	var saved_timing_rounds: Dictionary = data.get("timing_rounds", {})
	for key in saved_timing_rounds:
		# Keys are the original int form (event_id*100); migrate the clone's old
		# string "timing:id" form. No config carries two round timings on one
		# event, so the string timing name maps unambiguously to ordinal 0.
		if str(key).contains(":"):
			var parts := str(key).split(":")
			state.timing_rounds[int(parts[parts.size() - 1]) * 100] = int(saved_timing_rounds[key])
		else:
			state.timing_rounds[int(key)] = int(saved_timing_rounds[key])
	state.begin_guide = data.get("begin_guide", {}).duplicate(true) if data.get("begin_guide", {}) is Dictionary else {}
	state.guide_cues = data.get("guide_cues", []).duplicate(true) if data.get("guide_cues", []) is Array else []
	state.event_init_profile_id = int(data.get("event_init_profile_id", 1))
	state.local_counters = _restore_int_keyed_dictionary(data.get("local_counters", {}))
	state.global_counters = _restore_int_keyed_dictionary(data.get("global_counters", {}))
	# Old clone saves carried only Player.global_counter_cacher. Seed an empty
	# Global.counter once; an existing global.json remains authoritative.
	if state.global_state != null:
		if state.global_state.counters.is_empty() and not state.global_counters.is_empty():
			state.global_state.counters = state.global_counters.duplicate(true)
		elif not state.global_state.counters.is_empty():
			state.global_counters = state.global_state.counters.duplicate(true)
	if state.has_method("sync_rail_order"):
		state.sync_rail_order()
	if state.has_method("_rebuild_event_runtime"):
		state._rebuild_event_runtime(db)
	# v5 migration: the scalar coin_count becomes one stacked gold card object
	# (id 2000029) at the front of the hand, preserving the recorded total.
	if legacy_coin > 0 and state.gold_total() == 0:
		state.reconcile_gold(legacy_coin, db)
	# v5 migration: scalar gold_dice becomes the COUNTER_GOLD_DICE counter.
	if legacy_gold_dice >= 0 and not state.local_counters.has(state.COUNTER_GOLD_DICE):
		state.set_counter(state.COUNTER_GOLD_DICE, legacy_gold_dice)
	# v7 migration: the run payload's recorded quota seeds the attached global
	# object (the archive index's snapshot overrides it afterwards, like the
	# original's archive restore). [SRC: Datapool.c @ CorrectPlayerData
	# L4130-4134 restores Global.backToPrevRound from the archive slot's value]
	if legacy_back_to_prev >= 0:
		state.global_state.back_to_prev_round = legacy_back_to_prev


static func _restore_int_keyed_dictionary(value: Variant) -> Dictionary:
	var restored := {}
	if not (value is Dictionary):
		return restored
	for raw_key in value:
		restored[int(raw_key)] = value[raw_key]
	return restored


static func _restore_int_bool_dictionary(value: Variant) -> Dictionary:
	var restored := {}
	if not (value is Dictionary):
		return restored
	for raw_key in value:
		restored[int(raw_key)] = bool(value[raw_key])
	return restored


static func _restore_int_count_dictionary(value: Variant) -> Dictionary:
	var restored := {}
	if not (value is Dictionary):
		return restored
	for raw_key in value:
		var id := int(raw_key)
		if id > 0:
			restored[id] = int(value[raw_key])
	return restored


static func _restore_string_count_dictionary(value: Variant) -> Dictionary:
	var restored := {}
	if not (value is Dictionary):
		return restored
	for raw_key in value:
		var key := str(raw_key)
		if not key.is_empty():
			restored[key] = int(value[raw_key])
	return restored


static func _restore_nonempty_string_map(value: Variant) -> Dictionary:
	var restored := {}
	if not (value is Dictionary):
		return restored
	for raw_key in value:
		var text := str(value[raw_key])
		if int(raw_key) > 0 and not text.is_empty():
			restored[int(raw_key)] = text
	return restored


static func _restore_positive_id_set(value: Variant) -> Dictionary:
	var restored := {}
	if not (value is Array):
		return restored
	for raw_id in value:
		var id := int(raw_id)
		if id > 0:
			restored[id] = true
	return restored


static func _sorted_set_keys(value: Dictionary) -> Array:
	var ids: Array = []
	for raw_id in value:
		var id := int(raw_id)
		if id > 0:
			ids.append(id)
	ids.sort()
	return ids


## Save to disk. Returns true on success.
static func save(state) -> bool:
	return _write_save_data(save_path(), serialize(state))


## DatapoolExtensions.SaveRoundBegin/End first refresh auto_save, then write
## the same Player payload under the round-formatted name. The clone keeps its
## v7 Player schema but mirrors that two-file transaction and naming boundary.
static func save_round_begin(state) -> bool:
	return _save_round(state, round_begin_save_path(int(state.round_number)))


static func save_round_end(state) -> bool:
	return _save_round(state, round_end_save_path(int(state.round_number)))


static func _save_round(state, round_path: String) -> bool:
	var data := serialize(state)
	if not _write_save_data(save_path(), data):
		return false
	return _write_save_data(round_path, data)


## LoadRound/LoadRoundEnd read the selected round file and, on success,
## immediately refresh auto_save with the restored Player.
## [SRC: DatapoolExtensions.c @ LoadRound (RVA 0x3f8fa0) /
##       LoadRoundEnd (RVA 0x3f8e70); dump.cs:418331-418343]
static func load_round(state, db, round: int) -> bool:
	return _load_round_into(state, db, round_begin_save_path(round))


static func load_round_end(state, db, round: int) -> bool:
	return _load_round_into(state, db, round_end_save_path(round))


static func _load_round_into(state, db, path: String) -> bool:
	var data = _read_save_data_at(path)
	if not _is_loadable_player_data(data):
		return false
	deserialize(data, state, db)
	# Original LoadRound is void: once LoadPlayer succeeds it refreshes auto_save
	# but does not turn a refresh-write failure into a failed restore.
	save(state)
	return true


static func is_valid_round(round: int) -> bool:
	return _is_loadable_player_data(_read_save_data_at(round_begin_save_path(round)))


static func is_valid_round_end(round: int) -> bool:
	return _is_loadable_player_data(_read_save_data_at(round_end_save_path(round)))


static func _is_loadable_player_data(data: Variant) -> bool:
	if not is_valid_player_save_data(data):
		return false
	var version := int(data.get("version", 0))
	return version >= MIN_LOADABLE_SAVE_VERSION and version <= SAVE_VERSION


## Loading a manual archive discards every round_*.json before installing the
## archive Player, preventing rollback into another timeline.
## [SRC: Datapool.c @ LoadUserArchive (RVA 0x417350) L4069-4083;
##       stringliteral.json:11295 "round_*.json"]
static func delete_round_saves() -> void:
	var root := round_save_root()
	var directory := DirAccess.open(root)
	if directory == null:
		return
	for filename in directory.get_files():
		if filename.begins_with("round_") and filename.ends_with(".json"):
			DirAccess.remove_absolute(_round_save_path(filename))


## Create or replace a named manual archive. Indexes are stable 0-based slots,
## matching the original archive controller's fixed archive array.
static func save_user_archive(state, index: int, archive_name: String) -> bool:
	if index < 0 or index >= MAX_USER_ARCHIVE_COUNT:
		return false
	var data := serialize(state)
	if not _write_save_data(user_archive_save_path(index), data):
		return false
	var archives := _read_user_archives()
	var name := archive_name.strip_edges()
	if name.is_empty():
		name = "Day %d" % state.day
	name = name.left(48)
	var entry := {
		"index": index,
		"name": name,
		"live_days": state.day,
		"left_sudan": state.active_sudan_cards.size(),
		"execution_day": _next_execution_day(state),
		"back_to_prev_round": state.back_to_prev_left,
		"save_time": Time.get_datetime_string_from_system(),
	}
	var replaced := false
	for archive_index in archives.size():
		if int(archives[archive_index].get("index", -1)) == index:
			archives[archive_index] = entry
			replaced = true
			break
	if not replaced:
		archives.append(entry)
	archives.sort_custom(func(a, b): return int(a.get("index", 0)) < int(b.get("index", 0)))
	return _write_user_archives(archives)


## UserArchiveController.OnModifyName delegates to Datapool.UpdateUserArchive:
## it changes archive metadata only and never serializes/replaces the live
## Player payload.  Keep that boundary explicit rather than routing a rename
## through save_user_archive.
## [SRC: UserArchiveController.__c__DisplayClass20_0.c @
##       <OnModifyName>b__0 (RVA 0x5c7e30) -> Datapool.UpdateUserArchive;
##       dump.cs:423740-423746]
static func update_user_archive(index: int, archive_name: String) -> bool:
	if index < 0 or index >= MAX_USER_ARCHIVE_COUNT:
		return false
	var name := archive_name.strip_edges()
	if name.is_empty() or name.length() > 20:
		return false
	var archives := _read_user_archives()
	for archive_index in archives.size():
		var entry = archives[archive_index]
		if entry is Dictionary and int(entry.get("index", -1)) == index:
			var renamed: Dictionary = entry.duplicate(true)
			renamed["name"] = name
			archives[archive_index] = renamed
			return _write_user_archives(archives)
	return false


static func list_user_archives(db) -> Array:
	var valid_archives: Array = []
	for entry in _read_user_archives():
		var index := int(entry.get("index", -1))
		if index < 0 or index >= MAX_USER_ARCHIVE_COUNT:
			continue
		var data: Variant = _read_save_data_at(user_archive_save_path(index))
		if not is_valid_player_save_data(data) or int(data.get("version", 0)) < MIN_LOADABLE_SAVE_VERSION or int(data.get("version", 0)) > SAVE_VERSION:
			continue
		var summary: Dictionary = entry.duplicate(true)
		summary["round_number"] = int(data.get("round_number", 1))
		summary["day"] = int(data.get("day", 1))
		valid_archives.append(summary)
	return valid_archives


static func next_user_archive_index() -> int:
	var used := {}
	for entry in _read_user_archives():
		used[int(entry.get("index", -1))] = true
	for index in MAX_USER_ARCHIVE_COUNT:
		if not used.has(index):
			return index
	return -1


## Restoring an archive also refreshes the current-player continue file, as the
## original LoadUserArchive restores Player and then calls SavePlayer. The
## archive index's recorded quota wins over the payload/global, mirroring the
## original's archive restore into Global + SaveGlobal.
## [SRC: Datapool.c @ LoadUserArchive (RVA 0x417350) -> CorrectPlayerData
##       L4130-4134: Global.backToPrevRound = archive slot value; SaveGlobal]
static func load_user_archive(db, index: int) -> Variant:
	if index < 0 or index >= MAX_USER_ARCHIVE_COUNT:
		return null
	var state = _load_from_path(db, user_archive_save_path(index), true)
	if state != null:
		delete_round_saves()
		for entry in _read_user_archives():
			if int(entry.get("index", -1)) == index and entry.has("back_to_prev_round"):
				state.global_state.back_to_prev_round = int(entry["back_to_prev_round"])
				state.global_state.save()
				break
		save(state)
	return state


## Unlike the original index-only deletion, remove both registry entry and
## payload so a player-selected deletion actually frees the archive.
static func delete_user_archive(index: int) -> bool:
	var archives := _read_user_archives()
	var found := false
	var retained: Array = []
	for entry in archives:
		if int(entry.get("index", -1)) == index:
			found = true
		else:
			retained.append(entry)
	if not found:
		return false
	var archive_path := user_archive_save_path(index)
	if FileAccess.file_exists(archive_path) and DirAccess.remove_absolute(archive_path) != OK:
		return false
	return _write_user_archives(retained)


static func delete_all_user_archives() -> void:
	for entry in _read_user_archives():
		var archive_path := user_archive_save_path(int(entry.get("index", -1)))
		if FileAccess.file_exists(archive_path):
			DirAccess.remove_absolute(archive_path)
	var index_path := user_archive_index_path()
	if FileAccess.file_exists(index_path):
		DirAccess.remove_absolute(index_path)


static func _write_save_data(path: String, data: Dictionary) -> bool:
	_ensure_parent_directory(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveSystem: cannot open %s" % path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


static func read_save_data() -> Variant:
	return _read_save_data_at(save_path())


static func _read_save_data_at(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	var parsed = json.data
	if not (parsed is Dictionary):
		return null
	return parsed


## Load from disk into a new GameState. Returns null if no save, corrupt, or
## version-mismatched. A version mismatch (older/newer save schema) is rejected
## rather than silently loading wrong state.
static func load(db, require_player_save := false) -> Variant:
	return _load_from_path(db, save_path(), require_player_save)


static func _load_from_path(db, path: String, require_player_save := false) -> Variant:
	var parsed = _read_save_data_at(path)
	if parsed == null:
		return null
	if require_player_save and not SaveSystem.is_valid_player_save_data(parsed):
		return null
	# Version gate: reject saves whose schema version doesn't match.
	# [SRC: original CorrectPlayerData reconciles configVersion; clone uses a
	# simpler save-schema version check]
	var v := int(parsed.get("version", 0))
	if v < MIN_LOADABLE_SAVE_VERSION or v > SAVE_VERSION:
		push_warning("SaveSystem: save version %d outside loadable range [%d, %d]; refusing to load" % [v, MIN_LOADABLE_SAVE_VERSION, SAVE_VERSION])
		return null
	var state = preload("res://sim/game_state.gd").new()
	# The quota lives on the global domain: attach the process-wide disk-backed
	# global before deserializing so v5/v6 migration seeds land there and v7
	# payloads keep the persisted quota. [SRC: original Global/global.json is a
	# separate file loaded once per process, GameApplication.get_global]
	state.global_state = GlobalState.load_default()
	deserialize(parsed, state, db)
	return state


static func load_continue(db) -> Variant:
	return SaveSystem.load(db, true)


## Check if a save exists.
static func has_save() -> bool:
	return FileAccess.file_exists(save_path())


static func has_valid_save(db) -> bool:
	return SaveSystem.load_continue(db) != null


static func is_valid_player_save_data(data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	return bool(data.get("player_save", false)) and str(data.get("save_kind", "")) == SAVE_KIND_PLAYER


## Delete the save file.
static func delete_save() -> void:
	if FileAccess.file_exists(save_path()):
		DirAccess.remove_absolute(save_path())


static func _read_user_archives() -> Array:
	var path := user_archive_index_path()
	if not FileAccess.file_exists(path):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary) or int(parsed.get("version", 0)) != 1:
		return []
	var archives = parsed.get("archives", [])
	if not (archives is Array):
		return []
	return archives.filter(func(entry): return entry is Dictionary)


static func _write_user_archives(archives: Array) -> bool:
	return _write_save_data(user_archive_index_path(), {"version": 1, "archives": archives})


static func _ensure_parent_directory(path: String) -> void:
	var directory := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))


static func _next_execution_day(state) -> int:
	var next_day := -1
	for sudan in state.active_sudan_cards:
		var candidate: int = state.day + int(sudan.days_left)
		if next_day < 0 or candidate < next_day:
			next_day = candidate
	return next_day
