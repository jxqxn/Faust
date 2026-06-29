## Save/load system. Serializes the GameState to a JSON file so the player can
## quit and resume. The original uses Datapool.SaveGlobal (binary); this clone
## uses JSON for simplicity and debuggability.
## [RUNTIME_OPEN] — the original's exact serialization format is not needed
## for gameplay fidelity; we preserve all gameplay-relevant fields.
class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://save.json"


## Serialize the game state to a dictionary.
static func serialize(state) -> Dictionary:
	var sudan_cards_data: Array = []
	for asc in state.active_sudan_cards:
		sudan_cards_data.append({
			"card_id": asc.card_id,
			"days_left": asc.days_left,
			"drawn_round": asc.drawn_round,
		})
	var table_cards_data: Array = []
	for tc in state.table_cards:
		table_cards_data.append(tc.duplicate(true))
	return {
		"version": 1,
		"difficulty_index": state.difficulty_index,
		"round_number": state.round_number,
		"day": state.day,
		"coin_count": state.coin_count,
		"gold_dice": state.gold_dice,
		"redraws_left": state.redraws_left,
		"back_to_prev_left": state.back_to_prev_left,
		"hand": state.hand.duplicate(),
		"sudan_deck": state.sudan_deck.duplicate(),
		"active_sudan_cards": sudan_cards_data,
		"table_cards": table_cards_data,
		"started_rites": state.started_rites.duplicate(),
		"auto_result_rites": state.auto_result_rites.duplicate(),
		"rite_auto_result": state.rite_auto_result,
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
	state.back_to_prev_left = int(data.get("back_to_prev_left", 0))
	state.hand.clear()
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
			int(asc_data.get("drawn_round", 0))
		)
		state.active_sudan_cards.append(asc)
	state.table_cards.clear()
	for tc in data.get("table_cards", []):
		if tc is Dictionary:
			state.table_cards.append(tc.duplicate(true))
	state.started_rites.clear()
	for rid in data.get("started_rites", []):
		state.started_rites.append(int(rid))
	state.auto_result_rites.clear()
	for rid in data.get("auto_result_rites", []):
		state.auto_result_rites.append(int(rid))
	state.rite_auto_result = bool(data.get("rite_auto_result", false))
	state.local_counters = data.get("local_counters", {}).duplicate(true)
	state.global_counters = data.get("global_counters", {}).duplicate(true)


## Save to disk. Returns true on success.
static func save(state) -> bool:
	var data := serialize(state)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveSystem: cannot open %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


## Load from disk into a new GameState. Returns null if no save or corrupt.
static func load(db) -> Variant:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return null
	var state = preload("res://sim/game_state.gd").new()
	deserialize(parsed, state, db)
	return state


## Check if a save exists.
static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Delete the save file.
static func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
