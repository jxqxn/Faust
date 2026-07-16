## Top-level UI for the formal calendar-relationship mode. It renders state
## and sends explicit requests to the resolver; it never mutates state itself.
class_name CalendarCoopGame
extends Control

signal return_to_title()

const ContentRepository = preload("res://modes/calendar_coop/services/content_repository.gd")
const CalendarStateModel = preload("res://modes/calendar_coop/model/calendar_state.gd")
const CalendarEngine = preload("res://modes/calendar_coop/services/calendar_engine.gd")
const OpportunityService = preload("res://modes/calendar_coop/services/opportunity_service.gd")
const ActionResolver = preload("res://modes/calendar_coop/services/action_resolver.gd")
const OpportunityCard = preload("res://modes/calendar_coop/ui/opportunity_card.gd")
const PrototypeCard = preload("res://modes/calendar_coop/ui/prototype_card_widget.gd")
const ActionBoard = preload("res://modes/calendar_coop/ui/action_board.gd")

var resolver = null
var _day_label: Label
var _case_label: Label
var _forecast_label: Label
var _cards_box: HBoxContainer
var _opportunities_box: HBoxContainer
var _result_label: Label
var _board


func setup(value) -> void:
	resolver = value
	if is_inside_tree():
		refresh()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if resolver == null:
		resolver = _make_demo_resolver()
	_build_ui()
	refresh()


func refresh() -> void:
	if resolver == null or _day_label == null:
		return
	_day_label.text = "第 %d 天 · %s" % [resolver.state.day, resolver.state.period]
	var case_state = resolver.cases.get("museum_case", null)
	_case_label.text = "案件：The Closed Gallery · 截止第 %d 天 · 当前 %s" % [case_state.deadline_day, case_state.phase] if case_state != null else "案件：无"
	_forecast_label.text = _forecast_text()
	_clear_children(_cards_box)
	for card_id in resolver.owned_card_ids:
		var card = PrototypeCard.new()
		card.setup(str(card_id))
		_cards_box.add_child(card)
	_clear_children(_opportunities_box)
	for opportunity in resolver.opportunities_for_current_day():
		var card = OpportunityCard.new()
		card.setup(opportunity, _display_name(opportunity.action_id))
		card.chosen.connect(_show_action_board)
		_opportunities_box.add_child(card)
	if _restricted_night_available():
		var restricted := Button.new()
		restricted.name = "RestrictedNightButton"
		restricted.text = "受限夜晚外出"
		restricted.pressed.connect(_resolve_restricted_night)
		_opportunities_box.add_child(restricted)


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_top = 20
	root.offset_right = -24
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var heading := HBoxContainer.new()
	root.add_child(heading)
	_day_label = Label.new()
	_day_label.name = "CalendarDayLabel"
	_day_label.add_theme_font_size_override("font_size", 28)
	_day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(_day_label)
	var return_button := Button.new()
	return_button.name = "ReturnToTitleButton"
	return_button.text = "返回标题"
	return_button.pressed.connect(func(): return_to_title.emit())
	heading.add_child(return_button)
	_case_label = Label.new()
	_case_label.name = "CaseDeadlineLabel"
	root.add_child(_case_label)
	_forecast_label = Label.new()
	_forecast_label.name = "ForecastLabel"
	root.add_child(_forecast_label)
	var slots := HBoxContainer.new()
	root.add_child(slots)
	for period in ["after_school", "night"]:
		var slot := Label.new()
		slot.name = "PeriodSlot_%s" % period
		slot.text = "时段槽：%s" % period
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slots.add_child(slot)
	var cards_title := Label.new()
	cards_title.text = "持有卡牌"
	root.add_child(cards_title)
	_cards_box = HBoxContainer.new()
	_cards_box.name = "PrototypeCards"
	root.add_child(_cards_box)
	var opportunity_title := Label.new()
	opportunity_title.text = "今日机会"
	root.add_child(opportunity_title)
	_opportunities_box = HBoxContainer.new()
	_opportunities_box.name = "OpportunityCards"
	_opportunities_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_opportunities_box)
	_result_label = Label.new()
	_result_label.name = "ActionResultLog"
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_result_label)
	_board = ActionBoard.new()
	_board.name = "ActionBoard"
	_board.visible = false
	_board.submitted.connect(_resolve_action)
	root.add_child(_board)


func _show_action_board(opportunity) -> void:
	_board.show_opportunity(opportunity, _display_name(opportunity.action_id))


func _resolve_action(opportunity) -> void:
	var result = resolver.resolve(opportunity)
	_result_label.text = result.message if result.ok else result.failure_reason
	if result.ok:
		resolver.engine.advance_period()
	_board.visible = false
	refresh()


func _resolve_restricted_night() -> void:
	var result = resolver.resolve_restricted_night_out()
	_result_label.text = result.message if result.ok else result.failure_reason
	if result.ok:
		resolver.engine.advance_period()
	refresh()


func _restricted_night_available() -> bool:
	var mentor = resolver.relations.get("mentor", null)
	return mentor != null and resolver.state.period == "night" and int(mentor.flags.get("restricted_night_day", 0)) == resolver.state.day


func _forecast_text() -> String:
	var entries: Array = resolver.engine.forecast_for_next_days(2)
	if entries.is_empty():
		return "未来两天：暂无已知事项"
	var labels: Array[String] = []
	for entry in entries:
		labels.append("第 %d 天 %s" % [int(entry.get("day", 0)), str(entry.get("display_name", entry.get("id", "")))])
	return "未来两天：%s" % "；".join(labels)


func _display_name(action_id: String) -> String:
	var action: Dictionary = resolver.repository.get_action(action_id)
	return str(action.get("display_name", action_id)) if not action.is_empty() else action_id


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _make_demo_resolver():
	var repository = ContentRepository.new()
	repository.load_all()
	var engine = CalendarEngine.new(CalendarStateModel.new(1), repository)
	return ActionResolver.new(engine, OpportunityService.new(repository), repository)
