## Original desktop quest-completion notification surface.
## [SRC: StoryNotifyController.c @ Show/OnAnimationDone/OnPointerClick
##       (RVA 0x5b9c00/0x5b99c0/0x5b9b20); StoryNotify.prefab;
##       StoryNotify.anim 0 -> -444 -> hold -> 0 in Unity y-up space.]
class_name StoryNotifyControllerView
extends Control

signal story_requested(quest_id: int)

const SOURCE_SIZE := Vector2(630, 444)
const ENTER_SECONDS := 0.33333334
const HOLD_SECONDS := 5.0
const EXIT_SECONDS := 0.33333316

var waiting_queue: Array[Dictionary] = []
var current: Dictionary = {}
var _title: Label
var _point_count: Label
var _phase := -1
var _phase_time := 0.0
var _scale_factor := Vector2.ONE


func _ready() -> void:
	name = "StoryNotify"
	size = SOURCE_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_source_surface()
	gui_input.connect(_on_gui_input)
	set_process(false)


func setup(global: GlobalState) -> void:
	if global != null and not global.quest_completed.is_connected(show_quest):
		global.quest_completed.connect(show_quest)


func _build_source_surface() -> void:
	var bg := TextureRect.new()
	bg.name = "Prompt"
	bg.texture = load("res://assets/original/ui/prompt.png") as Texture2D
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = SOURCE_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_title = Label.new()
	_title.name = "Title"
	_title.position = Vector2(15, 73)
	_title.size = Vector2(600, 50)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 60)
	_title.add_theme_color_override("font_color", Color(1.0, 0.9764706, 0.6862745))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load("res://assets/original/ui/point_0.png") as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.position = Vector2(193.5, 207)
	icon.size = Vector2(103, 110)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)

	_point_count = Label.new()
	_point_count.name = "PointCount"
	_point_count.position = Vector2(316.5, 237)
	_point_count.size = Vector2(100, 50)
	_point_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_point_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_point_count.add_theme_font_size_override("font_size", 50)
	_point_count.add_theme_color_override("font_color", Color(0.63529414, 0.5568628, 0.34509805))
	_point_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_point_count)


func apply_source_layout(view_size: Vector2) -> void:
	_scale_factor = Vector2(view_size.x / 3840.0, view_size.y / 2160.0)
	scale = _scale_factor
	position.x = (view_size.x - SOURCE_SIZE.x * _scale_factor.x) * 0.5
	position.y = _design_y() * _scale_factor.y


## Show immediately when idle, otherwise preserve the source FIFO queue.
func show_quest(quest: Dictionary) -> void:
	if _phase >= 0:
		waiting_queue.append(quest)
		return
	current = quest
	_title.text = str(quest.get("name", ""))
	_point_count.text = "+%d" % int(quest.get("upgrade_point", 0))
	_phase = 0
	_phase_time = 0.0
	visible = true
	set_process(true)
	position.y = -SOURCE_SIZE.y * _scale_factor.y


func _process(delta: float) -> void:
	if _phase < 0:
		return
	_phase_time += maxf(delta, 0.0)
	var duration := ENTER_SECONDS if _phase == 0 else (HOLD_SECONDS if _phase == 1 else EXIT_SECONDS)
	if _phase_time >= duration:
		_phase_time -= duration
		_phase += 1
		if _phase > 2:
			_on_animation_done()
			return
	position.y = _design_y() * _scale_factor.y


func _design_y() -> float:
	if _phase == 0:
		return lerpf(-SOURCE_SIZE.y, 0.0, _smoothstep(_phase_time / ENTER_SECONDS))
	if _phase == 1:
		return 0.0
	if _phase == 2:
		return lerpf(0.0, -SOURCE_SIZE.y, _smoothstep(_phase_time / EXIT_SECONDS))
	return -SOURCE_SIZE.y


static func _smoothstep(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _on_animation_done() -> void:
	current = {}
	_phase = -1
	_phase_time = 0.0
	visible = false
	set_process(false)
	if not waiting_queue.is_empty():
		show_quest(waiting_queue.pop_front())


func _on_gui_input(event: InputEvent) -> void:
	if current.is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# The source rewinds/samples/stops the notification, then calls
		# GameController.ShowStory with StoryController.Target = Current.
		story_requested.emit(int(current.get("id", 0)))
		accept_event()


func complete_animation_for_test() -> void:
	_on_animation_done()
