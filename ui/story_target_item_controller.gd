## Source-shaped row used by StoryController for one QuestNode.Target.
## [SRC: StoryTargetItemController.c @ Init (RVA 0x5b9e80);
##       StoryTargetItem.prefab; dump.cs:386531 QuestNode.Target]
class_name StoryTargetItemController
extends Control

const SOURCE_SIZE := Vector2(1600, 80)
const SOURCE_ART := "res://assets/original/ui/"
const VARIABLE_PATH := "res://content/variable.json"

var target: Dictionary = {}
var _state_icon: TextureRect
var _text: RichTextLabel
var _source_formats: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = SOURCE_SIZE
	size = SOURCE_SIZE
	_build_source_surface()
	_update_view()


func setup(value: Dictionary) -> void:
	target = value
	if is_node_ready():
		_update_view()


func _build_source_surface() -> void:
	_state_icon = TextureRect.new()
	_state_icon.name = "State"
	# HorizontalLayoutGroup: left padding 40 + Holder min width 40,
	# then spacing 40 before the flexible text child.
	_state_icon.position = Vector2(32, 11.5)
	_state_icon.size = Vector2(56, 57)
	_state_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_state_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_state_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_state_icon)

	_text = RichTextLabel.new()
	_text.name = "Text"
	_text.position = Vector2(120, 0)
	_text.size = Vector2(1480, 80)
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.scroll_active = false
	_text.add_theme_font_size_override("normal_font_size", 40)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)


func _update_view() -> void:
	if _state_icon == null or _text == null:
		return
	var complete := bool(target.get("isComplete", false))
	var icon_path := SOURCE_ART + ("finish.png" if complete else "unfinish.png")
	_state_icon.texture = load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null
	var copy := str(target.get("text", ""))
	var format_key := "STORY_TARGET_ITEM_FINISH_FORMAT" if complete else (
		"STORY_TARGET_ITEM_UNFINISH_NO_NUMBER_FORMAT"
		if str(target.get("show_counter", "")).is_empty()
		else "STORY_TARGET_ITEM_UNFINISH_FORMAT")
	var source_format := str(_formats().get(format_key, "{0}"))
	var formatted := source_format.replace("{0}", copy).replace("{1}", str(int(target.get("value", 0))))
	_text.text = _tmp_to_bbcode(formatted)


func _formats() -> Dictionary:
	if not _source_formats.is_empty():
		return _source_formats
	if FileAccess.file_exists(VARIABLE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(VARIABLE_PATH))
		if parsed is Dictionary:
			_source_formats = parsed
	return _source_formats


func _tmp_to_bbcode(value: String) -> String:
	return value.replace("<color=red>", "[color=red]").replace("</color>", "[/color]").replace("<s>", "[s]").replace("</s>", "[/s]")
