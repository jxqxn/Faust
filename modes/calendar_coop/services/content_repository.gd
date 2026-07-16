## Loads and validates the static content for the calendar-relationship mode.
## It deliberately does not create state, generate opportunities, or resolve
## actions; those responsibilities belong to later work packages.
class_name CalendarCoopContentRepository
extends RefCounted

const DEFAULT_DATA_ROOT := "res://modes/calendar_coop/data"
const ACTION_KINDS := ["relationship_event", "request_run", "heist"]
const PERIODS := ["after_school", "night"]
const CARD_KINDS := ["persona", "clue", "request", "support"]
const CASE_PHASES := ["intel", "infiltration", "route_confirmed", "calling_card", "treasure_secured"]
const REQUIRED_FILES := ["calendar", "characters", "cards", "actions", "cases"]

var content: Dictionary = {}
var validation_errors: Array = []
var _by_type: Dictionary = {}


func load_all(data_root: String = DEFAULT_DATA_ROOT) -> bool:
	content = {}
	validation_errors = []
	_by_type = {}
	for file_name in REQUIRED_FILES:
		var file_path := "%s/%s.json" % [data_root, file_name]
		var parsed = _read_json_object(file_path)
		if parsed == null:
			continue
		content[file_name] = parsed
	if not validation_errors.is_empty():
		return false
	return validate_content(content)


func validate_content(candidate: Dictionary) -> bool:
	validation_errors = []
	_by_type = {}
	content = candidate.duplicate(true)
	for file_name in REQUIRED_FILES:
		if not content.has(file_name) or not (content[file_name] is Dictionary):
			_add_error("missing or invalid %s content object" % file_name)
	if not validation_errors.is_empty():
		return false

	_validate_calendar(content["calendar"])
	_index_records("character", content["characters"].get("characters", []))
	_index_records("card", content["cards"].get("cards", []))
	_index_records("case", content["cases"].get("cases", []))
	_index_records("action", content["actions"].get("actions", []))
	_validate_cross_type_id_uniqueness()
	_validate_characters()
	_validate_cards()
	_validate_cases()
	_validate_actions()
	return validation_errors.is_empty()


func get_calendar() -> Dictionary:
	return content.get("calendar", {}).duplicate(true)


func get_character(id: String) -> Dictionary:
	return _get_indexed("character", id)


func get_card(id: String) -> Dictionary:
	return _get_indexed("card", id)


func get_case(id: String) -> Dictionary:
	return _get_indexed("case", id)


func get_action(id: String) -> Dictionary:
	return _get_indexed("action", id)


func get_errors() -> Array:
	return validation_errors.duplicate()


func _read_json_object(file_path: String):
	if not FileAccess.file_exists(file_path):
		_add_error("content file is missing: %s" % file_path)
		return null
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	if not (parsed is Dictionary):
		_add_error("content file is not a JSON object: %s" % file_path)
		return null
	return parsed


func _validate_calendar(calendar: Dictionary) -> void:
	_validate_allowed_fields(calendar, ["days", "fixed_events", "forecast"], "calendar")
	var days = calendar.get("days", [])
	if not (days is Array) or days.size() != 8:
		_add_error("calendar must define exactly 8 days")
		return
	var seen_days: Dictionary = {}
	for entry in days:
		if not (entry is Dictionary):
			_add_error("calendar day entry must be an object")
			continue
		_validate_allowed_fields(entry, ["day", "fixed_events"], "calendar day")
		var day := int(entry.get("day", 0))
		if day < 1 or day > 8 or seen_days.has(day):
			_add_error("calendar days must be unique values from 1 through 8")
		seen_days[day] = true
		if not (entry.get("fixed_events", []) is Array):
			_add_error("calendar day %d has invalid fixed_events" % day)
	if seen_days.size() != 8:
		_add_error("calendar must include every day from 1 through 8")
	_validate_named_schedule_entries(calendar.get("fixed_events", []), "fixed event", true)
	_validate_named_schedule_entries(calendar.get("forecast", []), "forecast", false)
	for entry in days:
		if not (entry is Dictionary):
			continue
		for event_id in entry.get("fixed_events", []):
			if not _calendar_has_id("fixed_events", str(event_id)):
				_add_error("calendar day %d references unknown fixed event %s" % [int(entry.get("day", 0)), event_id])


func _validate_named_schedule_entries(entries, label: String, requires_period: bool) -> void:
	if not (entries is Array):
		_add_error("%s entries must be an array" % label)
		return
	var ids: Dictionary = {}
	for entry in entries:
		if not (entry is Dictionary):
			_add_error("%s entry must be an object" % label)
			continue
		_validate_allowed_fields(entry, ["id", "display_name", "day", "period"] if requires_period else ["id", "display_name", "day"], "%s entry" % label)
		var id := str(entry.get("id", ""))
		if not _is_ascii_id(id) or ids.has(id):
			_add_error("%s must have a unique ASCII id" % label)
		ids[id] = true
		_require_display_name(entry, "%s %s" % [label, id])
		var day := int(entry.get("day", 0))
		if day < 1 or day > 8:
			_add_error("%s %s has an invalid day" % [label, id])
		if requires_period and str(entry.get("period", "")) not in PERIODS:
			_add_error("%s %s has an invalid period" % [label, id])


func _index_records(type: String, records) -> void:
	var indexed: Dictionary = {}
	_by_type[type] = indexed
	if not (records is Array):
		_add_error("%s collection must be an array" % type)
		return
	for record in records:
		if not (record is Dictionary):
			_add_error("%s record must be an object" % type)
			continue
		var id := str(record.get("id", ""))
		if not _is_ascii_id(id):
			_add_error("%s record has an invalid ASCII id" % type)
			continue
		if indexed.has(id):
			_add_error("duplicate %s id: %s" % [type, id])
			continue
		indexed[id] = record.duplicate(true)


func _validate_cross_type_id_uniqueness() -> void:
	var owners: Dictionary = {}
	for type in ["character", "card", "case", "action"]:
		for id in _by_type.get(type, {}):
			if owners.has(id):
				_add_error("id %s is shared by %s and %s" % [id, owners[id], type])
			else:
				owners[id] = type


func _validate_characters() -> void:
	for id in _by_type.get("character", {}):
		var character: Dictionary = _by_type["character"][id]
		_validate_allowed_fields(character, ["id", "display_name", "role", "progression_source"], "character %s" % id)
		_require_display_name(character, "character %s" % id)
		if str(character.get("role", "")) == "confidant" and str(character.get("progression_source", "")) not in ["affinity", "resolved_requests"]:
			_add_error("confidant %s has an invalid progression_source" % id)


func _validate_cards() -> void:
	for id in _by_type.get("card", {}):
		var card: Dictionary = _by_type["card"][id]
		_validate_allowed_fields(card, ["id", "display_name", "kind", "tags"], "card %s" % id)
		_require_display_name(card, "card %s" % id)
		if str(card.get("kind", "")) not in CARD_KINDS:
			_add_error("card %s has an unknown kind" % id)
		if not (card.get("tags", []) is Array):
			_add_error("card %s has invalid tags" % id)


func _validate_cases() -> void:
	for id in _by_type.get("case", {}):
		var case_data: Dictionary = _by_type["case"][id]
		_validate_allowed_fields(case_data, ["id", "display_name", "deadline_day", "initial_phase", "failure_outcome", "forecast_ids"], "case %s" % id)
		_require_display_name(case_data, "case %s" % id)
		if int(case_data.get("deadline_day", 0)) < 1 or int(case_data.get("deadline_day", 0)) > 8:
			_add_error("case %s has an invalid deadline_day" % id)
		if str(case_data.get("initial_phase", "")) not in CASE_PHASES:
			_add_error("case %s has an invalid initial_phase" % id)
		if str(case_data.get("failure_outcome", "")).is_empty():
			_add_error("case %s is missing failure_outcome" % id)
		for forecast_id in case_data.get("forecast_ids", []):
			if not _calendar_has_id("forecast", str(forecast_id)):
				_add_error("case %s references unknown forecast %s" % [id, forecast_id])


func _validate_actions() -> void:
	for id in _by_type.get("action", {}):
		var action: Dictionary = _by_type["action"][id]
		_require_display_name(action, "action %s" % id)
		var kind := str(action.get("kind", ""))
		if kind not in ACTION_KINDS:
			_add_error("action %s has an unknown kind: %s" % [id, kind])
			continue
		var allowed_fields := ["id", "display_name", "kind", "day", "period", "actor_id", "required_cards", "optional_cards"]
		match kind:
			"relationship_event":
				allowed_fields.append_array(["relation_id", "rank_to", "stage_to"])
			"request_run":
				allowed_fields.append_array(["relation_id", "case_id", "request_card_id", "generated_card_id"])
			"heist":
				allowed_fields.append_array(["case_id", "phase_transition"])
		_validate_allowed_fields(action, allowed_fields, "action %s" % id)
		var day := int(action.get("day", 0))
		if day < 1 or day > 8:
			_add_error("action %s has an invalid or missing day" % id)
		if str(action.get("period", "")) not in PERIODS:
			_add_error("action %s has an invalid or missing period" % id)
		_require_reference("character", str(action.get("actor_id", "")), "action %s actor_id" % id)
		_validate_card_references(action.get("required_cards", []), "action %s required_cards" % id)
		_validate_card_references(action.get("optional_cards", []), "action %s optional_cards" % id)
		match kind:
			"relationship_event":
				_require_reference("character", str(action.get("relation_id", "")), "action %s relation_id" % id)
				if int(action.get("rank_to", 0)) < 1 or str(action.get("stage_to", "")).is_empty():
					_add_error("relationship action %s is missing rank_to or stage_to" % id)
			"request_run":
				_require_reference("character", str(action.get("relation_id", "")), "request action %s relation_id" % id)
				_require_reference("case", str(action.get("case_id", "")), "request action %s case_id" % id)
				_require_reference("card", str(action.get("request_card_id", "")), "request action %s request_card_id" % id)
				_require_reference("card", str(action.get("generated_card_id", "")), "request action %s generated_card_id" % id)
				var request_card: Dictionary = _get_indexed("card", str(action.get("request_card_id", "")))
				if not request_card.is_empty() and str(request_card.get("kind", "")) != "request":
					_add_error("request action %s request_card_id must reference a request card" % id)
			"heist":
				_require_reference("case", str(action.get("case_id", "")), "heist action %s case_id" % id)
				_validate_phase_transition(action.get("phase_transition", {}), id)


func _validate_card_references(ids, label: String) -> void:
	if not (ids is Array):
		_add_error("%s must be an array" % label)
		return
	for id in ids:
		var candidate := str(id)
		if not _by_type.get("card", {}).has(candidate) and not _by_type.get("character", {}).has(candidate):
			_add_error("%s references unknown card or character %s" % [label, candidate])


func _validate_phase_transition(transition, action_id: String) -> void:
	if not (transition is Dictionary):
		_add_error("heist action %s has no phase_transition" % action_id)
		return
	_validate_allowed_fields(transition, ["from", "to"], "heist action %s phase_transition" % action_id)
	var from_phase := str(transition.get("from", ""))
	var to_phase := str(transition.get("to", ""))
	var from_index := CASE_PHASES.find(from_phase)
	if from_index < 0 or from_index + 1 >= CASE_PHASES.size() or CASE_PHASES[from_index + 1] != to_phase:
		_add_error("heist action %s has an illegal case phase transition" % action_id)


func _require_reference(type: String, id: String, label: String) -> void:
	if not _by_type.get(type, {}).has(id):
		_add_error("%s references unknown %s %s" % [label, type, id])


func _calendar_has_id(section: String, id: String) -> bool:
	for entry in content.get("calendar", {}).get(section, []):
		if entry is Dictionary and str(entry.get("id", "")) == id:
			return true
	return false


func _require_display_name(record: Dictionary, label: String) -> void:
	if str(record.get("display_name", "")).strip_edges().is_empty():
		_add_error("%s is missing display_name" % label)


func _validate_allowed_fields(record: Dictionary, allowed_fields: Array, label: String) -> void:
	for field in record:
		if str(field) not in allowed_fields:
			_add_error("%s has an unknown field: %s" % [label, field])


func _get_indexed(type: String, id: String) -> Dictionary:
	var record = _by_type.get(type, {}).get(id, {})
	return record.duplicate(true) if record is Dictionary else {}


func _add_error(message: String) -> void:
	validation_errors.append(message)


static func _is_ascii_id(id: String) -> bool:
	if id.is_empty():
		return false
	for code in id.to_ascii_buffer():
		if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 95):
			return false
	return id.length() == id.to_ascii_buffer().size()
