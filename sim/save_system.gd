## Save/load system. Serializes the GameState to a JSON file so the player can
## quit and resume. The original uses Datapool.SaveGlobal (binary); this clone
## uses JSON for simplicity and debuggability.
## [RUNTIME_OPEN] — the original's exact serialization format is not needed
## for gameplay fidelity; we preserve all gameplay-relevant fields.
class_name SaveSystem
extends RefCounted

const CardInstanceData = preload("res://sim/card_instance.gd")

const DEFAULT_SAVE_PATH := "user://save.json"
const SAVE_VERSION := 5
const SAVE_KIND_PLAYER := "player"

static var save_path_override := ""


static func save_path() -> String:
	return save_path_override if save_path_override != "" else DEFAULT_SAVE_PATH


static func use_save_path(path: String) -> void:
	save_path_override = path


static func use_default_save_path() -> void:
	save_path_override = ""


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
		"coin_count": state.coin_count,
		"gold_dice": state.gold_dice,
		"redraws_left": state.redraws_left,
		"sudan_redraw_count": state.sudan_redraw_count,
		"back_to_prev_left": state.back_to_prev_left,
		"hand": state.hand.duplicate(),
		"rail_order": state.rail_order.duplicate(),
		"sudan_deck": state.sudan_deck.duplicate(),
		"active_sudan_cards": sudan_cards_data,
		"card_instances": state.card_instances.values().map(func(instance): return instance.to_save_dict()),
		"next_card_uid": state.next_card_uid,
		"rite_instances": rite_instances_data,
		"next_rite_uid": state.next_rite_uid,
		"active_rite_uid": state.active_rite_uid,
		"available_rites": state.available_rites.duplicate(),
		"started_rites": state.started_rites.duplicate(),
		"auto_result_rites": state.auto_result_rites.duplicate(),
		"rite_auto_result": state.rite_auto_result,
		"event_queue": state.event_queue.duplicate(),
		"event_contexts": state.event_contexts.duplicate(true),
		"event_prompts": state.event_prompts.duplicate(true),
		"event_status": state.event_status.duplicate(true),
		"event_done": state.event_done.duplicate(true),
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
	state.coin_count = int(data.get("coin_count", 0))
	state.gold_dice = int(data.get("gold_dice", 0))
	state.redraws_left = int(data.get("redraws_left", 0))
	state.sudan_redraw_count = int(data.get("sudan_redraw_count", 1))
	state.back_to_prev_left = int(data.get("back_to_prev_left", 0))
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
	for cid in data.get("hand", []):
		state.hand.append(int(cid))
	state.sudan_deck.clear()
	for cid in data.get("sudan_deck", []):
		state.sudan_deck.append(int(cid))
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
	if state.has_method("_ensure_legacy_rite_instances"):
		state._ensure_legacy_rite_instances()
	if state.has_method("_sync_rite_instance_cards"):
		state._sync_rite_instance_cards()
	state.event_queue.clear()
	for eid in data.get("event_queue", []):
		state.event_queue.append(int(eid))
	state.event_contexts.clear()
	var saved_event_contexts: Dictionary = data.get("event_contexts", {})
	for event_id in saved_event_contexts:
		var saved_context = saved_event_contexts[event_id]
		if saved_context is Dictionary:
			state.event_contexts[int(event_id)] = saved_context.duplicate(true)
	state.event_prompts.clear()
	for prompt in data.get("event_prompts", []):
		if prompt is Dictionary:
			state.event_prompts.append(prompt.duplicate(true))
	state.event_status.clear()
	var saved_event_status: Dictionary = data.get("event_status", {})
	for event_id in saved_event_status:
		state.event_status[int(event_id)] = bool(saved_event_status[event_id])
	state.event_done.clear()
	var saved_event_done: Dictionary = data.get("event_done", {})
	for event_id in saved_event_done:
		state.event_done[int(event_id)] = bool(saved_event_done[event_id])
	state.event_init_profile_id = int(data.get("event_init_profile_id", 1))
	state.local_counters = _restore_int_keyed_dictionary(data.get("local_counters", {}))
	state.global_counters = _restore_int_keyed_dictionary(data.get("global_counters", {}))
	if state.has_method("sync_rail_order"):
		state.sync_rail_order()
	if state.has_method("_rebuild_event_runtime"):
		state._rebuild_event_runtime(db)


static func _restore_int_keyed_dictionary(value: Variant) -> Dictionary:
	var restored := {}
	if not (value is Dictionary):
		return restored
	for raw_key in value:
		restored[int(raw_key)] = value[raw_key]
	return restored


## Save to disk. Returns true on success.
static func save(state) -> bool:
	var data := serialize(state)
	var path := save_path()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveSystem: cannot open %s" % path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


static func read_save_data() -> Variant:
	if not FileAccess.file_exists(save_path()):
		return null
	var text := FileAccess.get_file_as_string(save_path())
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return null
	return parsed


## Load from disk into a new GameState. Returns null if no save, corrupt, or
## version-mismatched. A version mismatch (older/newer save schema) is rejected
## rather than silently loading wrong state.
static func load(db, require_player_save := false) -> Variant:
	var parsed = SaveSystem.read_save_data()
	if parsed == null:
		return null
	if require_player_save and not SaveSystem.is_valid_player_save_data(parsed):
		return null
	# Version gate: reject saves whose schema version doesn't match.
	# [SRC: original CorrectPlayerData reconciles configVersion; clone uses a
	# simpler save-schema version check]
	var v := int(parsed.get("version", 0))
	if v != SAVE_VERSION:
		push_warning("SaveSystem: save version %d != expected %d; refusing to load" % [v, SAVE_VERSION])
		return null
	var state = preload("res://sim/game_state.gd").new()
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
