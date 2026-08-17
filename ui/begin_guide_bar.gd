## On-screen beginner-guide bar. The active `begin_guide` directive from the
## rules layer renders as a short instruction line with the bound-key hint;
## clicking it dismisses the directive (the original's OnClose path). Cue
## entries (focus/hand_pop/rite_pop/slide) stay invisible until their hosts
## exist. [SRC: BeginGuideController.c @ ShowBeginGuide (0x526220),
## OnCloseBtnClick (0x525fa0); BeginGuideItemController.c:132 -> OnCloseBeginGuide]
##
## Visual layer mirrors the original BeginGuide prefab: a text_bg_2 strip,
## a mouse-hint icon from the begin_guide atlas, and a close_1 button.
## [SRC: GameScene.unity BeginGuide/Default -> text_bg_2, Close -> close_1,
##       Image -> mouse_right_click; Datapool.GetBeginGuideSprite atlas]
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

## Guide types whose original hint art is the right-click mouse icon.
const RIGHT_CLICK_TYPES := ["RIGHT_CLICK_SLOT", "RIGHT_CLICK_CARD"]

const TEXT_BG_PATH := "res://assets/original/ui/text_bg_2.png"
const CLOSE_TEXTURE_PATH := "res://assets/original/ui/close_1.png"

var _label: Label
var _icon: TextureRect
var _close: Button
var _state = null

static var _guide_atlas: OriginalAtlas = null


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

	_icon = TextureRect.new()
	_icon.name = "BeginGuideIcon"
	_icon.custom_minimum_size = Vector2(30, 30)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.visible = false
	row.add_child(_icon)

	_label = Label.new()
	_label.name = "BeginGuideText"
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color("#f5e5b4"))
	_label.custom_minimum_size = Vector2(420, 0)
	row.add_child(_label)

	_close = Button.new()
	_close.name = "BeginGuideClose"
	_close.custom_minimum_size = Vector2(30, 30)
	_close.tooltip_text = "关闭指引"
	# The original close_1 stamp IS the button face.
	# [SRC: Texture2D/close_1.png 80x80 -> BeginGuide/Default/Close]
	if ResourceLoader.exists(CLOSE_TEXTURE_PATH):
		var tex := load(CLOSE_TEXTURE_PATH) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 26
			style.texture_margin_right = 26
			style.texture_margin_top = 26
			style.texture_margin_bottom = 26
			for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
				_close.add_theme_stylebox_override(state_name, style)
	else:
		_close.text = "知道了"
	_close.pressed.connect(_on_dismiss)
	row.add_child(_close)

	_refresh()


func _bar_style() -> StyleBox:
	# Texture-first: the original strip IS the bar surface (9-slice).
	# [SRC: Texture2D/text_bg_2.png 1112x404 -> BeginGuide/Default]
	if ResourceLoader.exists(TEXT_BG_PATH):
		var tex := load(TEXT_BG_PATH) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 140
			style.texture_margin_right = 140
			style.texture_margin_top = 120
			style.texture_margin_bottom = 120
			style.content_margin_left = 150
			style.content_margin_right = 150
			style.content_margin_top = 128
			style.content_margin_bottom = 128
			return style
	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color(0.09, 0.05, 0.03, 0.92)
	fallback.border_color = Color("#d4ad5a")
	fallback.set_border_width_all(1)
	fallback.set_corner_radius_all(6)
	fallback.set_content_margin_all(10)
	return fallback


static func _hint_icon(guide_type: String) -> Texture2D:
	# [SRC: Datapool.c GetBeginGuideSprite; assets/original/ui/begin_guide.png
	#       + begin_guide.json frames mouse_* / arrow_*]
	if guide_type == "":
		return null
	if _guide_atlas == null:
		_guide_atlas = OriginalAtlas.load_atlas("res://assets/original/ui/begin_guide.png")
	if _guide_atlas == null:
		return null
	var frame_id := "mouse_right_click.png" if guide_type in RIGHT_CLICK_TYPES else ""
	if frame_id == "":
		return null
	return _guide_atlas.frame(frame_id)


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
	if _icon != null:
		_icon.texture = _hint_icon(guide_type)
		_icon.visible = _icon.texture != null


func _on_dismiss() -> void:
	# The original closes via OnCloseBtnClick -> CloseBeginGuide op.
	if _state != null:
		_state.begin_guide = {}
		_state.guide_cues.clear()
	_refresh()
	dismiss_requested.emit()
