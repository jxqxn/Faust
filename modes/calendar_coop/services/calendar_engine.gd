## The single authority that advances a CalendarState through the two daily
## periods. It never applies relationship, card, or case effects.
class_name CalendarEngine
extends RefCounted

const CalendarStateModel = preload("res://modes/calendar_coop/model/calendar_state.gd")

var state
var repository


func _init(calendar_state, content_repository) -> void:
	state = calendar_state
	repository = content_repository


func current_period() -> String:
	return str(state.period)


func consume_current_period() -> bool:
	return consume_period(state.day, state.period)


func consume_period(day: int, period: String) -> bool:
	return state.consume_period(day, period)


func is_current_period_available() -> bool:
	return not state.is_period_consumed(state.day, state.period)


func remaining_periods_for_today() -> Array:
	var periods: Array = []
	for period in CalendarStateModel.VALID_PERIODS:
		if not state.is_period_consumed(state.day, period):
			periods.append(period)
	return periods


func advance_period() -> bool:
	if state.period == CalendarStateModel.PERIOD_AFTER_SCHOOL:
		state.period = CalendarStateModel.PERIOD_NIGHT
		return true
	if state.period == CalendarStateModel.PERIOD_NIGHT:
		state.day += 1
		state.period = CalendarStateModel.PERIOD_AFTER_SCHOOL
		return true
	return false


func fixed_events_for_day(target_day: int = state.day) -> Array:
	var events: Array = []
	for event in repository.get_calendar().get("fixed_events", []):
		if event is Dictionary and int(event.get("day", 0)) == target_day:
			events.append(event.duplicate(true))
	return events


func forecast_for_next_days(day_count: int = 2) -> Array:
	var forecast: Array = []
	var last_day: int = int(state.day) + maxi(day_count, 0)
	var calendar: Dictionary = repository.get_calendar()
	for entry in calendar.get("forecast", []):
		if entry is Dictionary and int(entry.get("day", 0)) > state.day and int(entry.get("day", 0)) <= last_day:
			forecast.append(entry.duplicate(true))
	for event in calendar.get("fixed_events", []):
		if event is Dictionary and int(event.get("day", 0)) > state.day and int(event.get("day", 0)) <= last_day:
			forecast.append(event.duplicate(true))
	return forecast
