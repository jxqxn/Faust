## Original BeginGuide presentation. The active `begin_guide` directive is
## state, while this node is the desktop `MainUI/Prompt/BeginGuide` surface.
##
## [SRC: GameScene.unity MainUI/Prompt/BeginGuide/Default; BeginGuideController
## ShowBeginGuide (0x526220) -> BeginGuideItemController.Show/SetPos
## (0x527450/0x526dd0), dump.cs BeginGuideController@316733]
class_name BeginGuideBar
extends Control

signal dismiss_requested()

const DESIGN_SPACE := Vector2(3840, 2160)
# BeginGuide/Default: center anchors, anchoredPosition (747.3,-785), 1200x460.
const DEFAULT_POSITION := Vector2(2067.3, 65.0)
const DEFAULT_SIZE := Vector2(1200, 460)
const CLOSE_RECT := Rect2(1149.1, 410.0, 80, 80)
const IMAGE_RECT := Rect2(-356, 30, 400, 400)
const TEXT_RECT := Rect2(35, 35, 1130, 390)
const RING_RECT := Rect2(-263, -219.5, 314, 225)

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

const RIGHT_CLICK_TYPES := ["RIGHT_CLICK_SLOT", "RIGHT_CLICK_CARD"]
const TEXT_BG_PATH := "res://assets/original/ui/text_bg_2.png"
const CLOSE_TEXTURE_PATH := "res://assets/original/ui/close_1.png"
const RING_TEXTURE_PATH := "res://assets/original/ui/single_ring.png"

var _default: Control
var _label: Label
var _icon: TextureRect
var _close: Button
var _ring: TextureRect
var _state = null

static var _guide_atlas: OriginalAtlas = null


func setup(state) -> void:
	_state = state
	_refresh()


func _ready() -> void:
	name = "BeginGuide"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = DESIGN_SPACE
	_build_source_default()
	_refresh()


func apply_source_layout(view_size: Vector2) -> void:
	position = Vector2.ZERO
	size = DESIGN_SPACE
	scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _build_source_default() -> void:
	_default = Control.new()
	_default.name = "Default"
	_default.position = DEFAULT_POSITION
	_default.size = DEFAULT_SIZE
	_default.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_default)

	var background := TextureRect.new()
	background.name = "Background"
	background.texture = load(TEXT_BG_PATH) as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.position = Vector2.ZERO
	background.size = DEFAULT_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_default.add_child(background)

	_icon = TextureRect.new()
	_icon.name = "Image"
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.position = IMAGE_RECT.position
	_icon.size = IMAGE_RECT.size
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_default.add_child(_icon)

	_label = Label.new()
	_label.name = "Text"
	_label.position = TEXT_RECT.position
	_label.size = TEXT_RECT.size
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 75)
	_label.add_theme_color_override("font_color", Color("#f5e5b4"))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_default.add_child(_label)

	_ring = TextureRect.new()
	_ring.name = "Ring"
	_ring.texture = load(RING_TEXTURE_PATH) as Texture2D
	_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ring.position = RING_RECT.position
	_ring.size = RING_RECT.size
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_default.add_child(_ring)

	_close = Button.new()
	_close.name = "Close"
	_close.position = CLOSE_RECT.position
	_close.size = CLOSE_RECT.size
	_close.tooltip_text = "关闭指引"
	for state_name in ["normal", "hover", "pressed", "focus"]:
		_close.add_theme_stylebox_override(state_name, _close_style())
	_close.pressed.connect(_on_dismiss)
	_default.add_child(_close)


func _close_style() -> StyleBox:
	var style := StyleBoxTexture.new()
	style.texture = load(CLOSE_TEXTURE_PATH) as Texture2D
	style.texture_margin_left = 26
	style.texture_margin_right = 26
	style.texture_margin_top = 26
	style.texture_margin_bottom = 26
	return style


static func _hint_icon(guide_type: String) -> Texture2D:
	# [SRC: Datapool.c GetBeginGuideSprite; assets/original/ui/begin_guide.png
	# + begin_guide.json frames mouse_* / arrow_*]
	if guide_type == "":
		return null
	if _guide_atlas == null:
		_guide_atlas = OriginalAtlas.load_atlas("res://assets/original/ui/begin_guide.png")
	if _guide_atlas == null:
		return null
	var frame_id := "mouse_right_click.png" if guide_type in RIGHT_CLICK_TYPES else ""
	return _guide_atlas.frame(frame_id) if frame_id != "" else null


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
	_label.text = str(directive.get("text", TYPE_TEXT.get(guide_type, "跟随指引继续操作。")))
	if str(directive.get("bind", "")) != "":
		_label.text += "（手柄：%s）" % str(directive.get("bind"))
	_icon.texture = _hint_icon(guide_type)
	_icon.visible = _icon.texture != null
	_ring.visible = bool(directive.get("is_show_ring", false))


func _on_dismiss() -> void:
	# [SRC: BeginGuideController.OnCloseBtnClick (0x525fa0) ->
	# BeginGuideItemController.CloseInternal -> OnCloseBeginGuide]
	if _state != null:
		_state.begin_guide = {}
		_state.guide_cues.clear()
	_refresh()
	dismiss_requested.emit()
