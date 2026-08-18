## Cross-run global domain, the counterpart of the original's Global object
## persisted as global.json next to the run saves. Only evidence-backed fields
## are carried today: the back-to-prev quota (COUNTER_BACK_TO_PREV 7100007
## routes here through GameState.get_counter/set_counter) and the rollback-kind
## marker written at round boundaries. The remaining global.json fields
## (gameStatistics, doneEvent/doneRite, showedPrompt/choosedOption, galleries,
## meta counters) stay unmigrated until their systems land.
## [SRC: dump.cs:385595 <backToPrevRound>k__BackingField @0x7C;
##       dump.cs:385641 roundRollback @0x80; RoundRollbackType enum
##       dump.cs:6186 None/BACK_TO_BEGIN/BACK_TO_PREV_END/BACK_TO_PREV_BEGIN;
##       save_samples/global.json backToPrevRound=9999, roundRollback=0]
class_name GlobalState
extends RefCounted

# RoundRollbackType (dump.cs:6186).
const ROLLBACK_NONE := 0
const ROLLBACK_TO_BEGIN := 1
const ROLLBACK_TO_PREV_END := 2
const ROLLBACK_TO_PREV_BEGIN := 3

const DEFAULT_GLOBAL_PATH := "user://global.json"

## Back-to-prev-round quota. Stored on the global object so a round restore
## cannot roll the spend back; 9999 = UNLIMIT_BACK_TO_PREV_TIMES.
var back_to_prev_round := 0
## Which boundary the run currently sits behind (RoundRollbackType).
var round_rollback := ROLLBACK_NONE
var save_time := ""

# Disk binding: instances loaded through load_default()/load_from() remember
# their path so save() persists; bare instances (tests) stay detached.
var _path := ""

static var global_path_override := ""
static var _default_cache = null
static var _default_cache_path := ""


static func global_path() -> String:
	return global_path_override if global_path_override != "" else DEFAULT_GLOBAL_PATH


static func use_global_path(path: String) -> void:
	global_path_override = path


static func use_default_global_path() -> void:
	global_path_override = ""


## Drop the cached default so the next load_default() re-reads the disk (or a
## newly chosen override path). Test isolation hook.
static func reset_default_cache() -> void:
	_default_cache = null
	_default_cache_path = ""


## Process-wide default instance, loaded from disk once. The UI and save layer
## attach this instance to GameState so the quota persists across runs and app
## restarts like the original's single Global object.
static func load_default() -> GlobalState:
	var path := global_path()
	if _default_cache == null or _default_cache_path != path:
		_default_cache = load_from(path)
		_default_cache_path = path
	return _default_cache


static func load_from(path: String) -> GlobalState:
	var state := new()
	state._path = path
	if not FileAccess.file_exists(path):
		return state
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		state._apply_dict(parsed)
	return state


func save() -> bool:
	if _path == "":
		return false
	save_time = Time.get_datetime_string_from_system()
	var file := FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		push_warning("GlobalState: cannot open %s" % _path)
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
	return true


func to_dict() -> Dictionary:
	return {
		"back_to_prev_round": back_to_prev_round,
		"round_rollback": round_rollback,
		"save_time": save_time,
	}


func _apply_dict(data: Dictionary) -> void:
	back_to_prev_round = int(data.get("back_to_prev_round", 0))
	round_rollback = int(data.get("round_rollback", ROLLBACK_NONE))
	save_time = str(data.get("save_time", ""))
