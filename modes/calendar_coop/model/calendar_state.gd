## Mutable state owned by one calendar-relationship mode run.
##
## This model intentionally knows nothing about UI, content loading, or the
## Sultan reference-mode state. CalendarEngine owns progression policy; this
## object only records the resulting calendar facts.
class_name CalendarState
extends RefCounted

const PERIOD_AFTER_SCHOOL := "after_school"
const PERIOD_NIGHT := "night"
const VALID_PERIODS := [PERIOD_AFTER_SCHOOL, PERIOD_NIGHT]

var day: int = 1
var period: String = PERIOD_AFTER_SCHOOL
# Dictionary keyed by decimal day strings so it round-trips through JSON.
var consumed_periods: Dictionary = {}
var fixed_events: Array = []
var forecast: Array = []
var history: Array = []


func _init(initial_day: int = 1, initial_period: String = PERIOD_AFTER_SCHOOL) -> void:
	day = maxi(initial_day, 1)
	period = initial_period if is_valid_period(initial_period) else PERIOD_AFTER_SCHOOL


static func is_valid_period(value: String) -> bool:
	return value in VALID_PERIODS


func is_period_consumed(target_day: int, target_period: String) -> bool:
	if target_day < 1 or not is_valid_period(target_period):
		return false
	return target_period in _periods_for_day(target_day)


func consume_period(target_day: int, target_period: String) -> bool:
	if target_day < 1 or not is_valid_period(target_period) or is_period_consumed(target_day, target_period):
		return false
	var periods := _periods_for_day(target_day)
	periods.append(target_period)
	consumed_periods[str(target_day)] = periods
	return true


func release_period(target_day: int, target_period: String) -> bool:
	if not is_period_consumed(target_day, target_period):
		return false
	var periods := _periods_for_day(target_day)
	periods.erase(target_period)
	if periods.is_empty():
		consumed_periods.erase(str(target_day))
	else:
		consumed_periods[str(target_day)] = periods
	return true


func add_history(entry: Dictionary) -> void:
	history.append(entry.duplicate(true))


func to_dict() -> Dictionary:
	return {
		"day": day,
		"period": period,
		"consumed_periods": consumed_periods.duplicate(true),
		"fixed_events": fixed_events.duplicate(true),
		"forecast": forecast.duplicate(true),
		"history": history.duplicate(true),
	}


static func from_dict(data: Dictionary):
	var state = load("res://modes/calendar_coop/model/calendar_state.gd").new(int(data.get("day", 1)), str(data.get("period", PERIOD_AFTER_SCHOOL)))
	state.consumed_periods = _read_consumed_periods(data.get("consumed_periods", {}))
	state.fixed_events = _read_array(data.get("fixed_events", []))
	state.forecast = _read_array(data.get("forecast", []))
	state.history = _read_array(data.get("history", []))
	return state


func _periods_for_day(target_day: int) -> Array:
	var stored = consumed_periods.get(str(target_day), [])
	var periods: Array = []
	if stored is Array:
		for value in stored:
			var candidate := str(value)
			if is_valid_period(candidate) and candidate not in periods:
				periods.append(candidate)
	return periods


static func _read_consumed_periods(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not (value is Dictionary):
		return result
	for raw_day in value:
		var target_day := int(str(raw_day))
		if target_day < 1 or not (value[raw_day] is Array):
			continue
		var periods: Array = []
		for raw_period in value[raw_day]:
			var candidate := str(raw_period)
			if is_valid_period(candidate) and candidate not in periods:
				periods.append(candidate)
		if not periods.is_empty():
			result[str(target_day)] = periods
	return result


static func _read_array(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []
