## Shared visual surface behind the three original ICreditsPage implementations.
## [SRC: CreditsPage.c @ Setup/Hide (RVA 0x3f8c30/0x3f8c00);
##       dump.cs:418095-418130; Resources/prefab/Credits.prefab]
class_name CreditsPageView
extends Control

const SOURCE_ART := "res://assets/original/ui/"
const DESIGN_SPACE := Vector2(3840, 2160)

# ICreditsPage.Position maps to page_position because Control.position is a
# native Vector2 property in Godot.
var page_position := 0
var _title: Label
var _title_border: TextureRect


func _init() -> void:
	size = DESIGN_SPACE
	visible = false


func setup_page(title: String, type: String) -> void:
	if _title == null:
		# Title is a full-stretch child of TitleText. Its authored
		# sizeDelta=(408,-8), so the resolved width is parent+408 rather
		# than 408. [SRC: Resources/prefab/Credits.prefab]
		_title_border = texture_rect("Title", Rect2(), "group_helper.png")
		add_child(_title_border)
		_title = label("TitleText", title, Rect2(), 140)
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_title)
	var title_width := 420.01 if type == "developer" else 560.01
	_title.position = Vector2((DESIGN_SPACE.x - title_width) * 0.5, 160)
	_title.size = Vector2(title_width, 200)
	_title_border.position = Vector2((DESIGN_SPACE.x - title_width - 408.0) * 0.5, 164)
	_title_border.size = Vector2(title_width + 408.0, 192)
	_title.text = title
	var texture_name := "group_%s.png" % type
	_title_border.texture = source_texture(texture_name) if ResourceLoader.exists(SOURCE_ART + texture_name) else source_texture("group_helper.png")


func show_data(_data: Variant, pos: int) -> void:
	page_position = pos
	visible = true


func hide_page() -> void:
	visible = false


func has_previous() -> bool:
	return false


func has_next() -> bool:
	return false


func previous() -> void:
	pass


func next() -> void:
	pass


func source_texture(texture_name: String) -> Texture2D:
	var path := SOURCE_ART + texture_name
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func texture_rect(node_name: String, rect: Rect2, texture_name: String) -> TextureRect:
	var view := TextureRect.new()
	view.name = node_name
	view.position = rect.position
	view.size = rect.size
	view.texture = source_texture(texture_name)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


func label(node_name: String, copy: String, rect: Rect2, font_size: int) -> Label:
	var view := Label.new()
	view.name = node_name
	view.text = copy
	view.position = rect.position
	view.size = rect.size
	view.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	view.add_theme_font_size_override("font_size", font_size)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view
