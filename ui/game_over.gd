## Source-shaped `OverNewController` presentation.
##
## The original is a stage controller, not a one-page restart popup:
## SHOW_OVER -> SHOW_CG -> (SHOW_STORY -> SHOW_AFTER_STORY)? -> SHOW_RESULT.
## [SRC: OverNewController.c @ Init/DoNext (0x579f50/0x579bc0),
##       SetRecord/Hide (0x57a480/0x579e40),
##       OverNewStep1Controller.c @ Init (0x57a700),
##       OverNewStep3Controller.c @ OnMain (0x57cad0),
##       dump.cs OverNewController.Stage/fields; content/over.json]
class_name OverNewControllerView
extends Control

signal restart()
signal closed()

const DESIGN_SPACE := Vector2(3840, 2160)
const Step2StoryViewScript = preload("res://ui/over_new_step2_story.gd")

enum Stage { SHOW_OVER, SHOW_CG, SHOW_STORY, SHOW_AFTER_STORY, SHOW_RESULT }

var _state
var _db
var _endings: Dictionary = {}
var _stage := Stage.SHOW_OVER
var _entry: Dictionary = {}
var _surface: Control
var _is_record := false
var _over_data: Dictionary = {}
var _embedded_source_canvas := false
var _story_controller: OverNewStep2StoryControllerView


func setup(state, db) -> void:
	_state = state
	_db = db
	_load_endings()


func setup_record(state, db, over_data: Dictionary, embedded_source_canvas := false) -> void:
	# [SRC: OverNewController.SetRecord 0x57a480] stores the exact OverData and
	# sets isRecord before Init(overData.id). GalleryPanel supplies the Player
	# loaded by Datapool.LoadPlayerOverData/LoadDefaultPlayerOverData.
	_state = state
	_db = db
	_over_data = over_data.duplicate(true)
	_is_record = true
	_embedded_source_canvas = embedded_source_canvas
	_load_endings()


func _ready() -> void:
	name = "Over"
	theme = FaustTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	position = Vector2.ZERO
	size = DESIGN_SPACE
	_entry = _ending_entry()
	_show_stage(Stage.SHOW_OVER)
	if not _embedded_source_canvas:
		apply_source_layout(get_viewport_rect().size)


func apply_source_layout(view_size: Vector2) -> void:
	position = Vector2.ZERO
	size = DESIGN_SPACE
	scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _gui_input(event: InputEvent) -> void:
	# [SRC: OverNewController.OnPointerClick -> DoNext. The original excludes
	# the dedicated MainMenuButton; Godot's child Button consumes that click.]
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _stage != Stage.SHOW_RESULT:
			do_next()
			accept_event()


func do_next() -> void:
	# Exact branch order from OverNewController.DoNext. Record playback closes
	# after its last story stage; only a live ending reaches SHOW_RESULT.
	match _stage:
		Stage.SHOW_OVER:
			_show_stage(Stage.SHOW_CG)
		Stage.SHOW_CG:
			if _has_story():
				_show_stage(Stage.SHOW_STORY)
			else:
				_finish_sequence()
		Stage.SHOW_STORY:
			if _has_after_story():
				_show_stage(Stage.SHOW_AFTER_STORY)
			else:
				_finish_sequence()
		Stage.SHOW_AFTER_STORY:
			_finish_sequence()


func _finish_sequence() -> void:
	# [SRC: OverNewController.DoNext 0x579bc0 -> Hide 0x579e40] record mode
	# destroys only the replay instance and returns to GalleryPanelNew.
	if _is_record:
		closed.emit()
	else:
		_show_stage(Stage.SHOW_RESULT)


func _show_stage(next_stage: Stage) -> void:
	if next_stage == Stage.SHOW_AFTER_STORY and _story_controller != null and is_instance_valid(_story_controller):
		_stage = next_stage
		_story_controller.show_after_story()
		return
	if next_stage == Stage.SHOW_STORY:
		_stage = next_stage
		if _surface != null:
			_surface.queue_free()
		_build_story_step()
		return
	_stage = next_stage
	if _surface != null:
		_surface.queue_free()
	_surface = Control.new()
	_surface.name = _stage_name(next_stage)
	_surface.position = Vector2.ZERO
	_surface.size = DESIGN_SPACE
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	match next_stage:
		Stage.SHOW_OVER:
			_build_step1()
		Stage.SHOW_CG:
			_build_step2_cg()
		Stage.SHOW_RESULT:
			_build_step3()


func _build_step1() -> void:
	# `Over/Step1` authored geometry from Resources/prefab/Over.prefab.
	var up := ColorRect.new()
	up.name = "Up Mask"
	up.color = Color.BLACK
	up.size = Vector2(3840, 1080)
	_surface.add_child(up)
	var down := ColorRect.new()
	down.name = "Down Mask"
	down.color = Color.BLACK
	down.position = Vector2(0, 1080)
	down.size = Vector2(3840, 1080)
	_surface.add_child(down)
	var title_bg := Control.new()
	title_bg.name = "Title BG"
	title_bg.position = Vector2(1442, 420)
	title_bg.size = Vector2(956, 1320)
	_surface.add_child(title_bg)
	# The source title-sprite variants are selected by runtime player identity.
	# No title atlas is extracted, so preserve geometry and do not invent art.
	var title := Label.new()
	title.name = "Title"
	title.text = str(_entry.get("name", "游戏结束"))
	title.position = Vector2(300, 580)
	title.size = Vector2(356, 160)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", FaustTheme.DANGER_LIGHT)
	title_bg.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "Sub Title"
	subtitle.text = str(_entry.get("sub_name", ""))
	subtitle.position = Vector2(150, 550)
	subtitle.size = Vector2(656, 200)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 36)
	subtitle.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	title_bg.add_child(subtitle)


func _build_step2_cg() -> void:
	var cg := TextureRect.new()
	cg.name = "CG"
	cg.position = Vector2.ZERO
	cg.size = DESIGN_SPACE
	cg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cg.texture = _ending_texture("bg")
	_surface.add_child(cg)
	var text := Label.new()
	text.name = "Content"
	text.text = str(_entry.get("text", ""))
	text.position = Vector2(920, 1720)
	text.size = Vector2(2000, 220)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 42)
	text.add_theme_color_override("font_color", Color.WHITE)
	_surface.add_child(text)


func _build_step3() -> void:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.texture = load("res://assets/original/ui/bg_new.png") as Texture2D
	bg.position = Vector2.ZERO
	bg.size = DESIGN_SPACE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_surface.add_child(bg)
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = load("res://assets/original/ui/logo/logo_zhCN.png") as Texture2D
	logo.position = Vector2(1190, -178)
	logo.size = Vector2(1460, 916)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_surface.add_child(logo)
	var content := Label.new()
	content.name = "Content"
	content.text = str(_entry.get("name", "游戏结束"))
	content.position = Vector2(920, 1008)
	content.size = Vector2(2000, 100)
	content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_theme_font_size_override("font_size", 56)
	content.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	_surface.add_child(content)
	var main := Button.new()
	main.name = "MainMenuButton"
	main.text = "返回标题"
	main.position = Vector2(1515, 1396)
	main.size = Vector2(810, 348)
	main.add_theme_font_size_override("font_size", 60)
	main.pressed.connect(func(): restart.emit())
	_surface.add_child(main)


func _build_story_step() -> void:
	# Keep the original class boundary instead of embedding a clone-only story
	# panel in OverNewController.
	_surface.queue_free()
	_story_controller = Step2StoryViewScript.new()
	_story_controller.setup(_entry, _state, _db, _over_data, _story_text())
	_surface = _story_controller
	add_child(_surface)


func _load_endings() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://content/over.json"))
	if parsed is Dictionary:
		_endings = parsed


func _ending_entry() -> Dictionary:
	# SetRecord is followed by Init(overData.id); record identity is not read
	# back from the temporarily loaded Player.
	var ending_id := int(_over_data.get("id", 1)) if _is_record else (int(_state.over_reason) if _state != null else 0)
	var key := str(ending_id)
	var entry = _endings.get(key, {})
	return entry if entry is Dictionary else {}


func _ending_texture(key: String) -> Texture2D:
	var relative := str(_entry.get(key, ""))
	if relative == "":
		return null
	return load("res://assets/original/ui/%s.png" % relative) as Texture2D


func _has_story() -> bool:
	# [SRC: OverNewController.Init 0x579f50] hasStory is precisely
	# OverNode.text_extra != null && text_extra.Length != 0.
	var rows = _entry.get("text_extra", [])
	return rows is Array and not rows.is_empty()


func _has_after_story() -> bool:
	# [SRC: OverNewController.<DoInit>b__18_1 0x57a510] Init starts with the
	# config flag, then the story controller callback replaces it with whether
	# any actual AfterStoryItem was created.
	return int(_entry.get("open_after_story", 0)) != 0 and _story_controller != null and _story_controller.has_after_story_items()


func _story_text() -> String:
	var lines: Array[String] = [str(_entry.get("text", ""))]
	var player_data = _over_data.get("player_data") if _is_record else {}
	for raw in _entry.get("text_extra", []):
		if not (raw is Dictionary):
			continue
		var row := raw as Dictionary
		# In record playback, the original bypasses live condition evaluation
		# when OverData.player_data is null; otherwise it evaluates against the
		# Player installed by LoadPlayerOverData.
		var include := _is_record and player_data == null
		if not include:
			include = ConditionEval.evaluate(row.get("condition", {}) as Dictionary, {"db": _db, "state": _state})
		if not include:
			continue
		var row_title := str(row.get("result_title", ""))
		var row_text := str(row.get("result_text", ""))
		if not row_title.is_empty():
			lines.append(row_title)
		if not row_text.is_empty():
			lines.append(row_text)
	return "\n\n".join(lines.filter(func(line: String): return not line.is_empty()))


func _stage_name(value: Stage) -> String:
	match value:
		Stage.SHOW_OVER: return "Step1"
		Stage.SHOW_CG: return "Step2"
		Stage.SHOW_STORY: return "Step2-Story"
		Stage.SHOW_AFTER_STORY: return "After Story"
		Stage.SHOW_RESULT: return "Step3"
	return "Step"
