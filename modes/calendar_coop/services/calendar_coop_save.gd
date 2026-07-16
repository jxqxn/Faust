## Independent save storage for the formal calendar-relationship mode.
## It never reads or writes Sultan v5 data or user://save.json.
class_name CalendarCoopSave
extends RefCounted

const SAVE_KIND := "calendar_coop"
const SAVE_VERSION := 1
const DEFAULT_SAVE_ROOT := "user://calendar_coop"
const DEFAULT_SAVE_NAME := "save.json"
const CalendarStateModel = preload("res://modes/calendar_coop/model/calendar_state.gd")
const CalendarEngine = preload("res://modes/calendar_coop/services/calendar_engine.gd")
const OpportunityService = preload("res://modes/calendar_coop/services/opportunity_service.gd")
const ActionResolver = preload("res://modes/calendar_coop/services/action_resolver.gd")

static var save_path_override := ""


static func save_path() -> String:
	return save_path_override if not save_path_override.is_empty() else "%s/%s" % [DEFAULT_SAVE_ROOT, DEFAULT_SAVE_NAME]


static func use_save_path(path: String) -> void:
	save_path_override = path


static func use_default_save_path() -> void:
	save_path_override = ""


static func save(resolver) -> bool:
	_ensure_parent_directory()
	var file := FileAccess.open(save_path(), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"save_kind": SAVE_KIND,
		"version": SAVE_VERSION,
		"runtime": resolver.export_runtime_data(),
	}, "\t"))
	file.close()
	return true


static func load(repository):
	var data = _read_data()
	if not is_valid_save_data(data):
		return null
	var runtime: Dictionary = data.get("runtime", {})
	var initial_state = CalendarStateModel.from_dict(runtime.get("calendar", {}))
	var engine = CalendarEngine.new(initial_state, repository)
	var resolver = ActionResolver.new(engine, OpportunityService.new(repository), repository)
	resolver.restore_runtime_data(runtime)
	return resolver


static func has_valid_save() -> bool:
	return is_valid_save_data(_read_data())


static func is_valid_save_data(data) -> bool:
	return data is Dictionary and str(data.get("save_kind", "")) == SAVE_KIND and int(data.get("version", 0)) == SAVE_VERSION and data.get("runtime", {}) is Dictionary


static func delete_save() -> void:
	if FileAccess.file_exists(save_path()):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path()))


static func _read_data():
	if not FileAccess.file_exists(save_path()):
		return {}
	return JSON.parse_string(FileAccess.get_file_as_string(save_path()))


static func _ensure_parent_directory() -> void:
	var absolute_parent := ProjectSettings.globalize_path(save_path()).get_base_dir()
	DirAccess.make_dir_recursive_absolute(absolute_parent)
