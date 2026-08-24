## Source-shaped title GalleryPanelController surface.
## [SRC: GalleryPanelController.OnEnable/OnClose; GalleryCardPanel.GetCards
##       (RVA 0x548540) / ShowCards (RVA 0x549720); GalleryPanelNew.prefab;
##       GalleryCardController.OnPointerClick (RVA 0x543890) ->
##       CardInfoNewController.Show (RVA 0x537000).]
class_name GalleryPanel
extends Control

signal closed()

const DESIGN_SPACE := Vector2(3840, 2160)
const GROUP_RECT := Rect2(1340, 0, 2500, 2160)
const CARD_PANEL_RECT := Rect2(0, 150, 2500, 1910)
const TYPE_GROUP_RECT := Rect2(0, 67.5, 1482, 135)
const CARD_SCROLL_RECT := Rect2(-50, 100, 2500, 1710)
const CARD_GROUP_SIZE := Vector2(2048, 690)
const CARD_ITEM_SIZE := Vector2(322, 650.5)
const CARDS_PER_GROUP := 6
const CARD_GAP := 13.2
const CARD_PADDING := Vector2(21, 25)
const GALLERY_CARDS_PATH := "res://content/gallery_cards.json"
const VARIABLE_PATH := "res://content/variable.json"
const UI_PATH := "res://content/ui.json"
## [SRC: GalleryPanelNew/Background Sprite bg_2.asset -> texture GUID
## 9a7a67e0a2b80064d887233bee114f63 (Texture2D/bg_2.png).]
const BACKGROUND_PATH := "res://assets/original/ui/bg_2.png"

var _db: ConfigDB
var _design: Control
var _over: Control
var _cards: Control
var _cg: Control
var _scroll: ScrollContainer
var _scroll_content: Control
var _gallery_cards: Dictionary = {}
var _variables: Dictionary = {}
var _ui: Dictionary = {}
var _types: Array[String] = []
var _card_groups: Array[Array] = []
var _current_type := ""
var _card_detail: CardInfoView


func setup(config_db: ConfigDB) -> void:
	_db = config_db


func _ready() -> void:
	theme = FaustTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_source_data()
	_build_ui()


func _load_source_data() -> void:
	_gallery_cards = _read_object(GALLERY_CARDS_PATH)
	_variables = _read_object(VARIABLE_PATH)
	_ui = _read_object(UI_PATH)
	for value in _variables.get("gallery_card_type", []):
		_types.append(str(value))
	if not _types.is_empty():
		_current_type = _types[0]


func _read_object(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _build_ui() -> void:
	_design = Control.new()
	_design.name = "GalleryNew"
	_design.size = DESIGN_SPACE
	_design.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_design)
	resized.connect(_layout_design)
	call_deferred("_layout_design")
	var background := TextureRect.new()
	background.name = "Background"
	background.texture = load(BACKGROUND_PATH) as Texture2D if ResourceLoader.exists(BACKGROUND_PATH) else null
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.size = DESIGN_SPACE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design.add_child(background)
	_build_title()
	_build_mode_buttons()
	_build_body()
	_build_close()
	_show_mode("Over")


func _layout_design() -> void:
	if _design == null:
		return
	var view_size := size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		view_size = get_viewport().get_visible_rect().size
	_design.scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _build_title() -> void:
	# [SRC: GalleryNew/Title pos (315,-270), title fs60; Text fs36.]
	var title := Control.new()
	title.name = "Title"
	title.position = Vector2(249, 206)
	title.size = Vector2(132, 128)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design.add_child(title)
	var headline := Label.new()
	headline.name = "title"
	headline.text = "历史画廊"
	headline.position = Vector2(160, 24)
	headline.size = Vector2(1000, 80)
	headline.add_theme_font_size_override("font_size", 60)
	title.add_child(headline)
	var copy := Label.new()
	copy.name = "Text"
	copy.text = "在这里可以看到已经触发过的游戏内容。"
	copy.position = Vector2(-71.87, 200)
	copy.size = Vector2(940, 351.36)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override("font_size", 36)
	title.add_child(copy)


func _build_mode_buttons() -> void:
	# [SRC: GalleryNew/ButtonGroup 950x320, Over/Gallery 950x150 fs50.]
	var buttons := VBoxContainer.new()
	buttons.name = "ButtonGroup"
	buttons.position = Vector2(174.5, 676.1)
	buttons.size = Vector2(950, 320)
	buttons.add_theme_constant_override("separation", 20)
	_design.add_child(buttons)
	for entry in [["结局", "Over"], ["卡牌", "Gallery"]]:
		var button := Button.new()
		button.name = "%sTab" % entry[1]
		button.text = entry[0]
		button.custom_minimum_size = Vector2(950, 150)
		button.add_theme_font_size_override("font_size", 50)
		button.pressed.connect(func(): _show_mode(str(entry[1])))
		buttons.add_child(button)


func _build_body() -> void:
	var body := Control.new()
	body.name = "Group"
	body.position = GROUP_RECT.position
	body.size = GROUP_RECT.size
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design.add_child(body)
	_over = Control.new()
	_over.name = "Over"
	_over.size = Vector2(2500, 1960)
	body.add_child(_over)
	_cards = Control.new()
	_cards.name = "GalleryCard"
	_cards.position = CARD_PANEL_RECT.position
	_cards.size = CARD_PANEL_RECT.size
	body.add_child(_cards)
	_cg = Control.new()
	_cg.name = "CG"
	_cg.size = Vector2(2500, 1960)
	body.add_child(_cg)
	_build_card_panel()


func _build_card_panel() -> void:
	# [SRC: GalleryCard/TypeGroup (1482x135) -> horizontally scrollable
	# 302x100 GalleryCardToggle children. Types come from VariableNode.
	# The original does not alphabetize categories.]
	var type_group := ScrollContainer.new()
	type_group.name = "TypeGroup"
	type_group.position = TYPE_GROUP_RECT.position
	type_group.size = TYPE_GROUP_RECT.size
	type_group.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cards.add_child(type_group)
	var type_content := HBoxContainer.new()
	type_content.name = "ViewportContent"
	type_content.custom_minimum_size = Vector2(302 * _types.size(), 100)
	type_content.add_theme_constant_override("separation", 0)
	type_group.add_child(type_content)
	for card_type in _types:
		var button := Button.new()
		button.name = "Type_%s" % card_type
		button.text = _ui_text("GALLERY_CARD_TYPE_%s" % card_type, card_type)
		button.custom_minimum_size = Vector2(302, 100)
		button.add_theme_font_size_override("font_size", 60)
		button.pressed.connect(func(): _change_type(card_type))
		type_content.add_child(button)
	# [SRC: GalleryCard/Scroll View -> Content vertical GalleryCardGroup rows.]
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll View"
	_scroll.position = CARD_SCROLL_RECT.position
	_scroll.size = CARD_SCROLL_RECT.size
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cards.add_child(_scroll)
	_scroll_content = Control.new()
	_scroll_content.name = "ViewportContent"
	_scroll.add_child(_scroll_content)
	_scroll.get_v_scroll_bar().value_changed.connect(func(_value): _refresh_visible_groups())
	_rebuild_card_groups()


func _build_close() -> void:
	# [SRC: GalleryPanelNew.prefab OnClose -> GalleryPanelController.OnClose.]
	var close := Button.new()
	close.name = "Close"
	close.position = Vector2(3721.5, 46)
	close.size = Vector2(75, 78)
	close.icon = load("res://assets/original/ui/close_2.png") as Texture2D
	close.pressed.connect(func(): closed.emit())
	_design.add_child(close)


func _show_mode(mode: String) -> void:
	if _over == null:
		return
	_over.visible = mode == "Over"
	_cards.visible = mode == "Gallery"
	_cg.visible = mode == "CG"
	if mode == "Gallery":
		call_deferred("_refresh_visible_groups")


func _change_type(card_type: String) -> void:
	if card_type == _current_type:
		return
	_current_type = card_type
	_rebuild_card_groups()


func _rebuild_card_groups() -> void:
	if _scroll_content == null:
		return
	for child in _scroll_content.get_children():
		child.queue_free()
	_card_groups.clear()
	var filtered := _filtered_cards()
	for index in range(0, filtered.size(), CARDS_PER_GROUP):
		_card_groups.append(filtered.slice(index, min(index + CARDS_PER_GROUP, filtered.size())))
	_scroll_content.size = Vector2(2500, max(CARD_GROUP_SIZE.y, CARD_GROUP_SIZE.y * _card_groups.size()))
	_scroll_content.custom_minimum_size = _scroll_content.size
	for group_index in _card_groups.size():
		var group := Control.new()
		group.name = "GalleryCardGroup_%d" % group_index
		group.position = Vector2(226, CARD_GROUP_SIZE.y * group_index)
		group.size = CARD_GROUP_SIZE
		_scroll_content.add_child(group)
		for item_index in _card_groups[group_index].size():
			var item: Dictionary = _card_groups[group_index][item_index]
			var button := Button.new()
			button.name = "GalleryCardItem_%d" % int(item.get("id", 0))
			button.position = CARD_PADDING + Vector2(item_index * (CARD_ITEM_SIZE.x + CARD_GAP), 0)
			button.size = CARD_ITEM_SIZE
			button.flat = true
			button.tooltip_text = str(item.get("name", item.get("id", "")))
			# [SRC: GalleryCardController.OnPointerClick 0x543890 destroys the
			# prior info view, instantiates CardInfoNew, then calls Show(card).]
			button.pressed.connect(_show_card_detail.bind(item["card"]))
			group.add_child(button)
	call_deferred("_refresh_visible_groups")


func _filtered_cards() -> Array:
	# [SRC: GalleryCardPanel.GetCards 0x548540: is_show == 0, active
	# show_type, Datapool.cards definition lookup, then List.Sort.]
	var out: Array = []
	for raw in _gallery_cards.values():
		var definition := raw as Dictionary
		if definition == null or int(definition.get("is_show", 1)) != 0:
			continue
		if str(definition.get("show_type", "")) != _current_type:
			continue
		var card := _db.get_card(int(definition.get("id", 0))) if _db != null else {}
		if card.is_empty():
			continue
		out.append({"id": int(definition.get("id", 0)), "sort": int(definition.get("sort", 0)), "card": card, "name": str(card.get("name", ""))})
	out.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["sort"]) < int(b["sort"]))
	return out


func _refresh_visible_groups() -> void:
	if _scroll == null or _scroll_content == null:
		return
	var first: int = max(0, int(floor(_scroll.scroll_vertical / CARD_GROUP_SIZE.y)) - 1)
	var last: int = min(_card_groups.size() - 1, int(ceil((_scroll.scroll_vertical + _scroll.size.y) / CARD_GROUP_SIZE.y)) + 1)
	for group_index in _card_groups.size():
		var group := _scroll_content.get_node_or_null("GalleryCardGroup_%d" % group_index) as Control
		if group == null:
			continue
		if group_index >= first and group_index <= last:
			_materialize_group(group_index, group)
		else:
			_dematerialize_group(group)


func _materialize_group(group_index: int, group: Control) -> void:
	for item_index in _card_groups[group_index].size():
		var button := group.get_child(item_index) as Button
		if button == null or button.get_node_or_null("Card") != null:
			continue
		var card: Dictionary = _card_groups[group_index][item_index]["card"]
		var widget := CardWidget.make(card, "gallery")
		widget.name = "Card"
		widget.scale = Vector2(1.3, 1.3)
		widget.position = (CARD_ITEM_SIZE - CardWidget.CARD_SIZE * 1.3) * 0.5
		widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(widget)


func _dematerialize_group(group: Control) -> void:
	for child in group.get_children():
		if child is Control:
			var card := (child as Control).get_node_or_null("Card")
			if card != null:
				card.queue_free()


func _show_card_detail(card: Dictionary) -> void:
	if is_instance_valid(_card_detail):
		_card_detail.queue_free()
	_card_detail = CardInfoView.new()
	_card_detail.setup(null, _db)
	_card_detail.closed.connect(_close_card_detail)
	add_child(_card_detail)
	# GalleryCardController passes the config Card directly to the same
	# CardInfoNewController.Show surface.  There is deliberately no synthetic
	# runtime UID or equipment state in archive view.
	_card_detail.show_card(card, 0)


func _close_card_detail() -> void:
	if is_instance_valid(_card_detail):
		_card_detail.queue_free()
	_card_detail = null


func _ui_text(key: String, fallback: String) -> String:
	var row := _ui.get(key, {}) as Dictionary
	return str(row.get("zhCN", fallback))


func filtered_card_ids() -> Array[int]:
	var out: Array[int] = []
	for item in _filtered_cards():
		out.append(int(item["id"]))
	return out
