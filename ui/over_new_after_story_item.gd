## One source-shaped page in the ending after-story carousel.
## [SRC: OverNewAfterStoryItemController.c @ Setup/Show
##       (RVA 0x578e70/0x5790a0/0x579620); AfterStoryItem.prefab.]
class_name OverNewAfterStoryItemView
extends Control

const ITEM_SIZE := Vector2(1000, 1900)

var card_id := 0
var sort_index := 10
var sprite_source := ""
var content := ""
var _scroll: ScrollContainer


func setup(settlement: Dictionary, pic: String, source_card_id: int) -> void:
	card_id = source_card_id
	sort_index = int(settlement.get("sort", 10)) if int(settlement.get("sort", 0)) != 0 else 10
	sprite_source = str(settlement.get("pic", pic)) if not str(settlement.get("pic", "")).is_empty() else pic
	var lines: Array[String] = []
	for key in ["result_title", "result_text"]:
		var value := str(settlement.get(key, ""))
		if not value.is_empty():
			lines.append(value)
	content = "\n".join(lines)


func _ready() -> void:
	name = "AfterStoryItem_%d_%d" % [sort_index, card_id]
	size = ITEM_SIZE
	custom_minimum_size = ITEM_SIZE
	_build_surface()


func _build_surface() -> void:
	# AfterStoryItem.prefab is a 1000x1900 VerticalLayoutGroup. Icon keeps its
	# source aspect; Scroll View is the sole flexible-height child.
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2.ZERO
	icon.size = Vector2(1000, 1028)
	icon.texture = _source_texture(sprite_source)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll View"
	_scroll.position = Vector2(0, 1028)
	_scroll.size = Vector2(1000, 872)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	var text := RichTextLabel.new()
	text.name = "Content"
	text.text = content
	text.custom_minimum_size = Vector2(980, 872)
	text.fit_content = true
	text.add_theme_font_size_override("normal_font_size", 36)
	_scroll.add_child(text)


func bind() -> void:
	# [SRC: Bind 0x578dd0] each newly selected page returns its own ScrollRect
	# to verticalNormalizedPosition=1 (Unity top).
	if _scroll != null:
		_scroll.scroll_vertical = 0


func unbind() -> void:
	pass


func _source_texture(resource: String) -> Texture2D:
	if resource.is_empty():
		return null
	var path := "res://assets/original/%s.png" % resource
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
