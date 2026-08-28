## Source-shaped persistence boundary for the original ending-record archive.
## This class corresponds to Datapool's OverRecord methods; it deliberately
## keeps the original JSON field names and one-file-per-record layout.
## [SRC: Datapool.InitOverRecord 0x4133d0; LoadOverRecordExcerpt 0x4159f0;
##       LoadOverRecord 0x415c50; AddOverRecord 0x40cef0;
##       DeleteOverRecord 0x410b80; dump.cs Global.OverData/OverDataExcerpt.]
class_name OverRecordStore
extends RefCounted

const RECORD_ROOT := "OVERRECORDDATA"
const EXCESS_ROOT := "EXCESSDATA"
const EXCERPT_FILE := "over_record_excerpt.json"
const RECORD_FILE_FORMAT := "over_record_No.%d"
const MAX_VISIBLE_RECORDS := 200
const OriginalSaveImporterScript = preload("res://sim/original_save_importer.gd")
const GameStateScript = preload("res://sim/game_state.gd")

var root_path := "user://"
var excerpt := _empty_excerpt()


func _init(source_root: String = "user://") -> void:
	root_path = source_root if source_root.ends_with("://") else source_root.trim_suffix("/").trim_suffix("\\")


static func _empty_excerpt() -> Dictionary:
	return {
		"overRecordCount": 0,
		"overRecordNameList": [],
		"overRecordNameListExcess": [],
	}


func load_over_record_excerpt() -> bool:
	var path := _join(root_path, EXCERPT_FILE)
	if not FileAccess.file_exists(path):
		excerpt = _empty_excerpt()
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		excerpt = _empty_excerpt()
		return false
	excerpt = _normalize_excerpt(parsed as Dictionary)
	return true


func init_over_record(global_state: GlobalState = null) -> void:
	# Original migration: an absent excerpt imports legacy Global.overRecord,
	# clears that legacy list, then persists Global and the new excerpt.
	if not load_over_record_excerpt():
		if global_state != null:
			for raw_record in global_state.over_records:
				if raw_record is Dictionary:
					add_over_record(raw_record as Dictionary, false)
			global_state.over_records.clear()
			global_state.save()
		save_over_record_excerpt()
	correct_over_record_excerpt()


func correct_over_record_excerpt() -> bool:
	var before: Array = excerpt["overRecordNameList"]
	var seen := {}
	var corrected: Array = []
	for raw_name in before:
		var name := str(raw_name)
		if name.is_empty() or seen.has(name):
			continue
		seen[name] = true
		corrected.append(name)
	if corrected.size() == before.size():
		return false
	excerpt["overRecordNameList"] = corrected
	return save_over_record_excerpt()


func load_indexed_records() -> Array[Dictionary]:
	# [SRC: OverRecordController.OnEnable 0x57d9a0] walks the excerpt in
	# authored order and removes unreadable names at the current index.
	var records: Array[Dictionary] = []
	var names: Array = excerpt["overRecordNameList"]
	var index := 0
	while index < names.size():
		var file_name := str(names[index])
		var over_data := load_over_record(file_name)
		if over_data.is_empty():
			names.remove_at(index)
			continue
		records.append({"dataFileName": file_name, "overData": over_data})
		index += 1
	return records


func load_over_record(file_name: String) -> Dictionary:
	var path := get_over_record_file_name(file_name)
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func load_player_over_data(player_data: Dictionary, db) -> Dictionary:
	# [SRC: Datapool.LoadPlayerOverData 0x415e40] installs the archived Player,
	# then initializes top-level and rite-nested Card objects. The established
	# original-save importer is this clone's one Player boundary and supplies a
	# same-instant differential report; no second record-only schema is created.
	return OriginalSaveImporterScript.import_save(player_data, db)


func load_default_player_over_data(db) -> Dictionary:
	# [SRC: Datapool.LoadDefaultPlayerOverData 0x414c70] constructs a fresh
	# Player and only assigns the default protagonist name. GameState does not
	# carry Player.name, so the faithful representable state is a fresh object.
	return {"state": GameStateScript.new(), "payload": {}, "report": {
		"converted": [],
		"dropped": [{"field": "name", "reason": "GameState has no Player.name field"}],
		"approximated": [],
		"diff": [],
	}}


func add_over_record(over_data: Dictionary, save_excerpt := true) -> String:
	var count := int(excerpt.get("overRecordCount", 0))
	var file_name := RECORD_FILE_FORMAT % count
	if not _write_json(get_over_record_file_name(file_name), over_data):
		return ""
	var names: Array = excerpt["overRecordNameList"]
	if not names.has(file_name):
		names.push_front(file_name)
	excerpt["overRecordCount"] = count + 1
	check_over_record_excess()
	if save_excerpt:
		save_over_record_excerpt()
	return file_name


func delete_over_record(file_name: String) -> bool:
	var path := get_over_record_file_name(file_name)
	var removed := not FileAccess.file_exists(path) or DirAccess.remove_absolute(path) == OK
	var names: Array = excerpt["overRecordNameList"]
	while names.has(file_name):
		names.erase(file_name)
	save_over_record_excerpt()
	return removed


func check_over_record_excess() -> void:
	var names: Array = excerpt["overRecordNameList"]
	while names.size() > MAX_VISIBLE_RECORDS:
		var file_name := str(names.back())
		var record := load_over_record(file_name)
		if not record.is_empty():
			_write_json(get_over_record_excess_file_name(file_name), record)
		var source_path := get_over_record_file_name(file_name)
		if FileAccess.file_exists(source_path):
			DirAccess.remove_absolute(source_path)
		names.pop_back()


func save_over_record_excerpt() -> bool:
	return _write_json(_join(root_path, EXCERPT_FILE), excerpt)


func get_over_record_file_name(file_name: String) -> String:
	return _join(_join(root_path, RECORD_ROOT), "%s.json" % file_name)


func get_over_record_excess_file_name(file_name: String) -> String:
	return _join(_join(_join(root_path, RECORD_ROOT), EXCESS_ROOT), "%s.json" % file_name)


static func _normalize_excerpt(raw: Dictionary) -> Dictionary:
	var names = raw.get("overRecordNameList", [])
	var excess = raw.get("overRecordNameListExcess", [])
	return {
		"overRecordCount": int(raw.get("overRecordCount", 0)),
		"overRecordNameList": names.duplicate(true) if names is Array else [],
		"overRecordNameListExcess": excess.duplicate(true) if excess is Array else [],
	}


static func _write_json(path: String, payload: Dictionary) -> bool:
	var absolute_dir := ProjectSettings.globalize_path(path.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "  "))
	return true


static func _join(left: String, right: String) -> String:
	if left.ends_with("://"):
		return left + right
	return "%s/%s" % [left.trim_suffix("/").trim_suffix("\\"), right]
