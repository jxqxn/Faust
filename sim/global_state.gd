## Cross-run global domain, the counterpart of the original's Global object
## persisted as global.json next to the run saves. Only evidence-backed fields
## are carried today: the back-to-prev quota (COUNTER_BACK_TO_PREV 7100007
## routes here through GameState.get_counter/set_counter) and the rollback-kind
## marker written at round boundaries. `overRecord` is retained as opaque
## original `Global.OverData` JSON until the original result-record lifecycle
## is fully traced; `overID` and `showedGalleryCards` retain HashSet semantics.
## [SRC: dump.cs:385599-385609 Global fields; Global.c @ .ctor (0x38a510)
##       constructs List<OverData> + three HashSet<int>; GalleryCGIconController
##       @ IsLock (0x5430a0) queries overID; save_samples/global.json]
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
## Original `List<Global.OverData>`; dictionaries remain source-shaped JSON
## records, because their player/card payload must not be translated here.
var over_records: Array[Dictionary] = []
## Original `HashSet<int>` at Global+0x90 (dump offset 0x90).
var over_ids: Dictionary = {}
## Original `HashSet<int>` at Global+0xB0 (dump offset 0xB0).
var showed_gallery_cards: Dictionary = {}

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
	var directory := _path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	save_time = Time.get_datetime_string_from_system()
	var file := FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		push_warning("GlobalState: cannot open %s" % _path)
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
	return true


## Whether this instance represents the process-wide, disk-backed Global.
## Bare GameState instances deliberately carry a detached GlobalState so
## simulation tests and import probes do not write player files.
func is_disk_bound() -> bool:
	return _path != ""


func to_dict() -> Dictionary:
	return {
		# Use original Global/global.json key spelling. _apply_dict keeps reading
		# the clone's former snake_case file so existing local saves migrate.
		"saveTime": save_time,
		"backToPrevRound": back_to_prev_round,
		"roundRollback": round_rollback,
		"overRecord": over_records.duplicate(true),
		"overID": _serialize_int_set(over_ids),
		"showedGalleryCards": _serialize_int_set(showed_gallery_cards),
	}


func _apply_dict(data: Dictionary) -> void:
	back_to_prev_round = int(data.get("backToPrevRound", data.get("back_to_prev_round", 0)))
	round_rollback = int(data.get("roundRollback", data.get("round_rollback", ROLLBACK_NONE)))
	save_time = str(data.get("saveTime", data.get("save_time", "")))
	over_records.clear()
	var raw_records: Variant = data.get("overRecord", data.get("over_records", []))
	if raw_records is Array:
		for raw_record in raw_records:
			if raw_record is Dictionary:
				over_records.append((raw_record as Dictionary).duplicate(true))
	over_ids = _restore_int_set(data.get("overID", data.get("over_ids", [])))
	showed_gallery_cards = _restore_int_set(
		data.get("showedGalleryCards", data.get("showed_gallery_cards", []))
	)


## HashSet<int> serialization has no meaningful order; a sorted array makes
## clone saves stable while preserving original membership semantics.
static func _serialize_int_set(values: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for raw_id in values.keys():
		out.append(int(raw_id))
	out.sort()
	return out


static func _restore_int_set(value: Variant) -> Dictionary:
	var restored := {}
	if value is Array:
		for raw_id in value:
			restored[int(raw_id)] = true
	return restored


func has_shown_gallery_card(id: int) -> bool:
	return showed_gallery_cards.has(id)


## [SRC: GalleryCGIconController.IsLock 0x5430a0 / ShowIcon 0x5433a0:
## GalleryCGNode.over_id is tested against Global.overID (offset 0x90).]
func has_over_id(id: int) -> bool:
	return over_ids.has(id)


func mark_gallery_card_shown(id: int) -> void:
	showed_gallery_cards[id] = true
