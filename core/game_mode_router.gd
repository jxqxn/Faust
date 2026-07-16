## Explicit boundary between the Sultan reference mode and the formal calendar
## relationship mode. It owns mode construction, never either mode's rules.
class_name GameModeRouter
extends RefCounted

const ContentRepository = preload("res://modes/calendar_coop/services/content_repository.gd")
const CalendarStateModel = preload("res://modes/calendar_coop/model/calendar_state.gd")
const CalendarEngine = preload("res://modes/calendar_coop/services/calendar_engine.gd")
const OpportunityService = preload("res://modes/calendar_coop/services/opportunity_service.gd")
const ActionResolver = preload("res://modes/calendar_coop/services/action_resolver.gd")
const CalendarSave = preload("res://modes/calendar_coop/services/calendar_coop_save.gd")

var reference_mode_visible := true


func new_calendar_resolver():
	var repository = ContentRepository.new()
	if not repository.load_all():
		return null
	var engine = CalendarEngine.new(CalendarStateModel.new(1), repository)
	return ActionResolver.new(engine, OpportunityService.new(repository), repository)


func load_calendar_resolver():
	var repository = ContentRepository.new()
	if not repository.load_all():
		return null
	return CalendarSave.load(repository)


func has_calendar_continue() -> bool:
	return CalendarSave.has_valid_save()
