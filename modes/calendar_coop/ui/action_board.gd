class_name CalendarActionBoard
extends PanelContainer

signal submitted(opportunity)
signal closed()

var _opportunity = null
var _title: Label
var _detail: Label
var _submit: Button


func _ready() -> void:
	_build()


func show_opportunity(opportunity, display_name: String) -> void:
	if _title == null:
		_build()
	_opportunity = opportunity
	visible = true
	_title.text = display_name
	_detail.text = "占用：%s\n必需卡牌：%s\n可选卡牌：%s" % [opportunity.period, ", ".join(opportunity.required_cards), ", ".join(opportunity.optional_cards)]


func _build() -> void:
	if _title != null:
		return
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_title = Label.new()
	_title.name = "ActionBoardTitle"
	_title.add_theme_font_size_override("font_size", 20)
	box.add_child(_title)
	_detail = Label.new()
	_detail.name = "ActionBoardDetail"
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail)
	_submit = Button.new()
	_submit.name = "ResolveActionButton"
	_submit.text = "结算行动"
	_submit.pressed.connect(func(): submitted.emit(_opportunity))
	box.add_child(_submit)
	var close := Button.new()
	close.name = "CloseActionBoardButton"
	close.text = "关闭"
	close.pressed.connect(func(): visible = false; closed.emit())
	box.add_child(close)
