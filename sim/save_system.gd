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
const USER_ARCHIVE_ROOT := "user://user_archives"
const USER_ARCHIVE_INDEX_NAME := "user_archives.json"
const MAX_USER_ARCHIVE_COUNT := 50

static var save_path_override := ""
static var user_archive_root_override := ""


static func save_path() -> String:
	return save_path_override if save_path_override != "" else DEFAULT_SAVE_PATH


static func use_save_path(path: String) -> void:
	save_path_override = path


static func use_default_save_path() -> void:
	save_path_override = ""


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
		"pending_operations": state.pending_operations.duplicate(true),
		"delayed_operations": state.delayed_operations.duplicate(true),
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
	state.pending_operations.clear()
	if data.get("pending_operations", null) is Array:
		for operation in data.pending_operations:
			if operation is Dictionary and str(operation.get("kind", "")) in ["event", "prompt", "choice", "sleep"]:
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
	return _write_save_data(save_path(), serialize(state))


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


static func list_user_archives(db) -> Array:
	var valid_archives: Array = []
	for entry in _read_user_archives():
		var index := int(entry.get("index", -1))
		if index < 0 or index >= MAX_USER_ARCHIVE_COUNT:
			continue
		var data: Variant = _read_save_data_at(user_archive_save_path(index))
		if not is_valid_player_save_data(data) or int(data.get("version", 0)) != SAVE_VERSION:
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
## original LoadUserArchive restores Player and then calls SavePlayer.
## [SRC: Datapool.c @ LoadUserArchive (RVA 0x417350)]
static func load_user_archive(db, index: int) -> Variant:
	if index < 0 or index >= MAX_USER_ARCHIVE_COUNT:
		return null
	var state = _load_from_path(db, user_archive_save_path(index), true)
	if state != null:
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
	var parsed = JSON.parse_string(text)
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
