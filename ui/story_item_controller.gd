## Source-shaped quest list row.  Selection and reward are separate signals,
## matching StoryItemController.OnClick / OnRewardClick.
## [SRC: StoryItemController.c @ Init/UpdateState/OnRewardClick
##       (RVA 0x5b9450/0x5b96a0/0x5b9520); StoryItem.prefab]
class_name StoryItemController
extends Button

signal quest_selected(quest: Dictionary)
signal reward_requested(quest: Dictionary)

const SOURCE_SIZE := Vector2(1110, 140)
const SOURCE_ART := "res://assets/original/ui/"

var quest: Dictionary = {}
var _highlight: TextureRect
var _title: Label
var _red_dot: TextureRect
var _finish_tag: Label
var _finish: TextureButton
var _finish_icon: TextureRect


func _ready() -> void:
	custom_minimum_size = SOURCE_SIZE
	size = SOURCE_SIZE
	flat = true
	_build_source_surface()
	pressed.connect(func(): quest_selected.emit(quest))
	update_state()


func setup(value: Dictionary) -> void:
	quest = value
	if is_node_ready():
		_title.text = str(quest.get("name", ""))
		update_state()


func set_selected(value: bool) -> void:
	if _highlight != null:
		_highlight.visible = value


func update_state() -> void:
	if _title == null:
		return
	_title.text = str(quest.get("name", ""))
	var complete := bool(quest.get("isComplete", false))
	var received := bool(quest.get("isReceived", false))
	_red_dot.visible = complete and not received
	_finish.visible = complete
	_finish.disabled = received
	_finish_tag.visible = complete
	_finish_icon.texture = _source_texture("rewarded.png" if received else "point.png")


func _build_source_surface() -> void:
	_highlight = _texture_rect("Hightlight", Rect2(310, 15, 800, 110), "hightlight.png")
	_highlight.visible = false
	add_child(_highlight)
	add_child(_texture_rect("Bottom", Rect2(0, 125, 1110, 30), "slash.png"))

	_title = Label.new()
	_title.name = "Title"
	_title.position = Vector2(70, 40)
	_title.size = Vector2(800, 80)
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 40)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	_red_dot = _texture_rect("RedDot", Rect2(5.5, 66.5, 57, 57), "new.png")
	add_child(_red_dot)

	_finish_tag = Label.new()
	_finish_tag.name = "FinishTag"
	_finish_tag.text = "-已完成-"
	_finish_tag.position = Vector2(910, 55)
	_finish_tag.size = Vector2(200, 50)
	_finish_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_finish_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_finish_tag.add_theme_font_size_override("font_size", 36)
	_finish_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_finish_tag)

	_finish = TextureButton.new()
	_finish.name = "Finish"
	_finish.position = Vector2(971, 28)
	_finish.size = Vector2(109, 114)
	_finish.ignore_texture_size = true
	_finish.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_finish.texture_normal = _source_texture("circle_0.png")
	_finish.pressed.connect(func(): reward_requested.emit(quest))
	add_child(_finish)
	_finish_icon = _texture_rect("State", Rect2(19.5, 18.5, 70, 77), "point.png")
	_finish_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_finish.add_child(_finish_icon)


func _texture_rect(node_name: String, rect: Rect2, texture_name: String) -> TextureRect:
	var view := TextureRect.new()
	view.name = node_name
	view.position = rect.position
	view.size = rect.size
	view.texture = _source_texture(texture_name)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


func _source_texture(texture_name: String) -> Texture2D:
	var path := SOURCE_ART + texture_name
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
