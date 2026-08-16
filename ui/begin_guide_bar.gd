## On-screen beginner-guide bar. The active `begin_guide` directive from the
## rules layer renders as a short instruction line with the bound-key hint;
## clicking it dismisses the directive (the original's OnClose path). Cue
## entries (focus/hand_pop/rite_pop/slide) stay invisible until their hosts
## exist. [SRC: BeginGuideController.c @ ShowBeginGuide (0x526220),
## OnCloseBtnClick (0x525fa0); BeginGuideItemController.c:132 -> OnCloseBeginGuide]
class_name BeginGuideBar
extends Control

signal dismiss_requested()

const TYPE_TEXT := {
	"CHANGE_SUDAN_CARD": "换一张苏丹卡：把手牌拖进仪式，解决当前的苏丹。",
	"REDRAW_SUDAN_CARD": "点击“重抽”可以调换苏丹卡。",
	"RIGHT_CLICK_SLOT": "右键点击卡槽可以放回卡牌。",
	"RIGHT_CLICK_CARD": "右键点击卡牌可以收回它。",
	"RITE_CONFIRM": "安排好卡牌后，点击确认开始仪式。",
	"NEXT_DAY": "点击“下一天”推进时间。",
	"ADD_SUDAN_CARD": "抽出的苏丹卡会出现在手牌最前端。",
	"MAIN_HELP": "遇到困难时可以打开帮助。",
	"READ_BOOK": "把读物拖到“俺寻思”上可以获得收益。",
	"TIME_OUT": "注意：卡牌放置过久会消散。",
	"BACK_ROUND": "点击“回退”可以回到上一回合。",
	"CARD_INFO": "点击卡牌可以查看详细信息。",
	"RITE_LAST_STATE": "仪式进行中：可以停止或等待结算。",
	"RITE_STOP": "点击“停止”可以撤回进行中的仪式。",
	"FILL_COIN": "金币不足：需要先补充金币。",
}

var _label: Label
var _close: Button
var _state = null


func setup(state) -> void:
	_state = state
	_refresh()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := PanelContainer.new()
	bar.name = "BeginGuideBar"
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.add_theme_stylebox_override("panel", _bar_style())
	add_child(bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	_label = Label.new()
	_label.name = "BeginGuideText"
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color("#f5e5b4"))
	_label.custom_minimum_size = Vector2(420, 0)
	row.add_child(_label)

	_close = Button.new()
	_close.name = "BeginGuideClose"
	_close.text = "知道了"
	_close.pressed.connect(_on_dismiss)
	row.add_child(_close)

	_refresh()


func _bar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.05, 0.03, 0.92)
	style.border_color = Color("#d4ad5a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	return style


func refresh(state) -> void:
	_state = state
	_refresh()


func _refresh() -> void:
	if _label == null:
		return
	var directive: Dictionary = _state.begin_guide if _state != null else {}
	visible = not directive.is_empty()
	if directive.is_empty():
		return
	var guide_type := str(directive.get("type", ""))
	_label.text = TYPE_TEXT.get(guide_type, "跟随指引继续操作。")
	if str(directive.get("bind", "")) != "":
		_label.text += "（手柄：%s）" % str(directive.get("bind"))


func _on_dismiss() -> void:
	# The original closes via OnCloseBtnClick -> CloseBeginGuide op.
	if _state != null:
		_state.begin_guide = {}
		_state.guide_cues.clear()
	_refresh()
	dismiss_requested.emit()
