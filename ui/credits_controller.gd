## Original title-screen credits controller. It reuses one instance of each
## ICreditsPage implementation and stores that page's internal position while
## traversing the raw developer/contributor/thanks records.
## [SRC: CreditsController.c @ OnEnable/OnDisable/DoPrev/DoNext
##       (RVA 0x3f6f60/0x3f6ee0/0x3f6ce0/0x3f6aa0);
##       dump.cs:418013-418041; Resources/prefab/Credits.prefab]
class_name CreditsControllerView
extends Control

signal closed()

const DeveloperPage = preload("res://ui/credits_page_developer.gd")
const ContributorPage = preload("res://ui/credits_page_contributor.gd")
const ThanksPage = preload("res://ui/credits_page_thanks.gd")
const DESIGN_SPACE := Vector2(3840, 2160)
const SOURCE_ART := "res://assets/original/ui/"

var _db: ConfigDB
var _design: Control
var _pages_root: Control
var _developer_page: CreditsPageDeveloper
var _contributor_page: CreditsPageContributor
var _thanks_page: CreditsPageThanks
var _page_data: Array[Dictionary] = []
var data_index := 0
var _prev: TextureButton
var _next: TextureButton


func setup(config_db: ConfigDB) -> void:
	_db = config_db


func _ready() -> void:
	name = "CreditsController"
	theme = FaustTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_source_surface()
	_on_enable()


func _build_source_surface() -> void:
	_design = Control.new()
	_design.name = "Credits"
	_design.size = DESIGN_SPACE
	add_child(_design)
	resized.connect(_layout_design)
	call_deferred("_layout_design")
	_design.add_child(_texture("Background", Rect2(Vector2.ZERO, DESIGN_SPACE), "bg_2.png"))
	_pages_root = Control.new()
	_pages_root.name = "Pages"
	_pages_root.size = DESIGN_SPACE
	_design.add_child(_pages_root)
	_developer_page = DeveloperPage.new()
	_developer_page.name = "developers"
	_pages_root.add_child(_developer_page)
	_contributor_page = ContributorPage.new()
	_contributor_page.name = "helpers"
	_pages_root.add_child(_contributor_page)
	_thanks_page = ThanksPage.new()
	_thanks_page.name = "thanks"
	_pages_root.add_child(_thanks_page)
	var close := _button("Close", Rect2(3717.4, 45.6, 80, 82), "checkbox_bg.png")
	close.add_child(_texture("x", Rect2(18.5, 22.5, 43, 37), "close_2.png"))
	close.pressed.connect(func(): closed.emit())
	_design.add_child(close)
	_prev = _button("PageLeft", Rect2(1636, 1862, 168, 156), "page_left.png")
	_prev.pressed.connect(do_prev)
	_design.add_child(_prev)
	_next = _button("PageRight", Rect2(2036, 1862, 168, 156), "page_right_0.png")
	_next.pressed.connect(do_next)
	_design.add_child(_next)


func _on_enable() -> void:
	_page_data.clear()
	if _db == null or _db.credits.is_empty():
		return
	_page_data.append({"page": _developer_page, "data": _db.credits.get("developers", {}), "pos": 0})
	for contributor in _db.credits.get("contributors", []):
		_page_data.append({"page": _contributor_page, "data": contributor, "pos": 0})
	for thanks in _db.credits.get("thanks", []):
		_page_data.append({"page": _thanks_page, "data": thanks, "pos": 0})
	data_index = 0
	_show_current()


func do_prev() -> void:
	if _page_data.is_empty():
		return
	var current = _current_page()
	if current.has_previous():
		current.previous()
	elif data_index > 0:
		_page_data[data_index]["pos"] = current.page_position
		current.hide_page()
		data_index -= 1
		_show_current()
	_update_buttons()


func do_next() -> void:
	if _page_data.is_empty():
		return
	var current = _current_page()
	if current.has_next():
		current.next()
	elif data_index + 1 < _page_data.size():
		_page_data[data_index]["pos"] = current.page_position
		current.hide_page()
		data_index += 1
		_show_current()
	_update_buttons()


func _show_current() -> void:
	var row := _page_data[data_index]
	var page = row["page"]
	page.show_data(row["data"], int(row["pos"]))
	_update_buttons()


func _current_page():
	return _page_data[data_index]["page"]


func _update_buttons() -> void:
	if _page_data.is_empty():
		_prev.disabled = true
		_next.disabled = true
		return
	var current = _current_page()
	_prev.disabled = not current.has_previous() and data_index == 0
	_next.disabled = not current.has_next() and data_index + 1 >= _page_data.size()
	_prev.modulate.a = 0.35 if _prev.disabled else 1.0
	_next.modulate.a = 0.35 if _next.disabled else 1.0


func _layout_design() -> void:
	if _design == null:
		return
	var view_size := size if size.x > 0 and size.y > 0 else get_viewport().get_visible_rect().size
	_design.scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _texture(node_name: String, rect: Rect2, texture_name: String) -> TextureRect:
	var view := TextureRect.new()
	view.name = node_name
	view.position = rect.position
	view.size = rect.size
	view.texture = load(SOURCE_ART + texture_name) as Texture2D
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


func _button(node_name: String, rect: Rect2, texture_name: String) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.position = rect.position
	button.size = rect.size
	button.texture_normal = load(SOURCE_ART + texture_name) as Texture2D
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	return button
