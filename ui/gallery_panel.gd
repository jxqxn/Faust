## Source-shaped title GalleryPanelController surface.
## [SRC: GalleryPanelController.OnEnable/OnClose; GalleryCardPanel.GetCards
##       (RVA 0x548540) / ShowCards (RVA 0x549720); GalleryPanelNew.prefab.]
class_name GalleryPanel
extends Control

const GalleryCardInfoView = preload("res://ui/gallery_card_info.gd")

signal closed()

const DESIGN_SPACE := Vector2(3840, 2160)
const GROUP_RECT := Rect2(1340, 0, 2500, 2160)
const CARD_PANEL_RECT := Rect2(0, 150, 2500, 1910)
const CG_PANEL_RECT := Rect2(0, 100, 2500, 1960)
const CG_INNER_RECT := Rect2(54, 132, 2281.8, 1574.5)
const CG_ITEM_SIZE := Vector2(315.5, 441.2)
const CG_LAYER_SIZE := Vector2(337, 439)
const CG_LAYER_SCALE := Vector2(1.2, 1.2)
const TYPE_GROUP_RECT := Rect2(0, 67.5, 1482, 135)
const CARD_SCROLL_RECT := Rect2(-50, 100, 2500, 1710)
## [SRC: GalleryCard/Scroll View/Search: resolved from anchors (1,1),
## pos (-773.4,75), size 826x100 in the 2500x1710 Scroll View.]
const SEARCH_RECT := Rect2(1313.6, -125, 826, 100)
const CARD_GROUP_SIZE := Vector2(2048, 690)
const CARD_ITEM_SIZE := Vector2(322, 650.5)
const CARDS_PER_GROUP := 6
const CARD_GAP := 13.2
const CARD_PADDING := Vector2(21, 25)
const GALLERY_CARDS_PATH := "res://content/gallery_cards.json"
const GALLERY_CG_PATH := "res://content/gallery_cg.json"
const VARIABLE_PATH := "res://content/variable.json"
const UI_PATH := "res://content/ui.json"
## [SRC: GalleryPanelNew/Background Sprite bg_2.asset -> texture GUID
## 9a7a67e0a2b80064d887233bee114f63 (Texture2D/bg_2.png).]
const BACKGROUND_PATH := "res://assets/original/ui/bg_2.png"
const SEARCH_ICON_PATH := "res://assets/original/ui/search.png"

var _db: ConfigDB
var _global_state: GlobalState
var _design: Control
var _over: Control
var _cards: Control
var _cg: Control
var _scroll: ScrollContainer
var _scroll_content: Control
var _search_input: LineEdit
var _gallery_cards: Dictionary = {}
var _gallery_cg: Dictionary = {}
var _variables: Dictionary = {}
var _ui: Dictionary = {}
var _types: Array[String] = []
var _card_groups: Array[Array] = []
var _current_type := ""
var _search_query := ""
var _card_info: Control
var _current_card_index := -1
var _cg_items: Dictionary = {}
var _big_cg_container: Control
var _big_cg: TextureRect
var _cg_title: Label
var _cg_lock_prompt: Label

## Authored GalleryPanelNew.prefab RectTransforms, converted from Unity's
## centre anchors / upward Y into top-left positions inside CG's 2281.8x1574.5
## inner surface. This is layout evidence, not content data.
const CG_ITEM_LAYOUT := {
	1: Vector2(592.55, 71.25), 2: Vector2(308.55, 854.75),
	3: Vector2(980.75, 1096.15), 4: Vector2(1374.85, 581.25),
	5: Vector2(592.55, 581.25), 6: Vector2(1374.85, 71.25),
	7: Vector2(980.75, 581.25), 8: Vector2(1659.65, 324.65),
	9: Vector2(1659.65, 854.75), 10: Vector2(980.75, 71.25),
	11: Vector2(1939.15, 581.25), 12: Vector2(308.55, 324.65),
	13: Vector2(1374.85, 1096.15), 14: Vector2(592.55, 1096.15),
	15: Vector2(27.55, 581.25),
}


func setup(config_db: ConfigDB, global_state: GlobalState = null) -> void:
	_db = config_db
	_global_state = global_state


func _ready() -> void:
	theme = FaustTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_source_data()
	_build_ui()


func _load_source_data() -> void:
	_gallery_cards = _read_object(GALLERY_CARDS_PATH)
	_gallery_cg = _read_object(GALLERY_CG_PATH)
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
	# [SRC: GalleryPanelNew/ButtonGroup VerticalLayoutGroup: Over 150,
	# OverTypeGroup 216 (Memory/CG 100 rows), Gallery 150; spacing 20.]
	var buttons := VBoxContainer.new()
	buttons.name = "ButtonGroup"
	buttons.position = Vector2(174.5, 558.1)
	buttons.size = Vector2(950, 556)
	buttons.add_theme_constant_override("separation", 20)
	_design.add_child(buttons)
	var over_button := _mode_button("OverTab", "结局", Vector2(950, 150), 50)
	over_button.pressed.connect(func(): _show_mode("Over"))
	buttons.add_child(over_button)
	var over_types := VBoxContainer.new()
	over_types.name = "OverTypeGroup"
	over_types.custom_minimum_size = Vector2(950, 216)
	over_types.add_theme_constant_override("separation", 0)
	buttons.add_child(over_types)
	var memory_button := _mode_button("OverMemoryTab", "历史画廊", Vector2(950, 100), 40)
	memory_button.pressed.connect(func(): _show_mode("Over"))
	over_types.add_child(memory_button)
	var cg_button := _mode_button("CGTab", _ui_text("GALLERY_OVER_BTN_CG", "图鉴"), Vector2(950, 100), 40)
	cg_button.pressed.connect(func(): _show_mode("CG"))
	over_types.add_child(cg_button)
	var gallery_button := _mode_button("GalleryTab", "卡牌", Vector2(950, 150), 50)
	gallery_button.pressed.connect(func(): _show_mode("Gallery"))
	buttons.add_child(gallery_button)


func _mode_button(node_name: String, text_value: String, minimum: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text_value
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", font_size)
	return button


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
	_cg.position = CG_PANEL_RECT.position
	_cg.size = CG_PANEL_RECT.size
	body.add_child(_cg)
	_build_card_panel()
	_build_cg_panel()
	_build_big_cg()


func _build_cg_panel() -> void:
	# [SRC: GalleryCGPanelController.OnEnable 0x543600 calls ShowIcon on
	# all 15 authored GalleryCGIconController children.]
	var inner := Control.new()
	inner.name = "CGInner"
	inner.position = CG_INNER_RECT.position
	inner.size = CG_INNER_RECT.size
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cg.add_child(inner)
	for raw_key in _gallery_cg.keys():
		var index := int(raw_key)
		var definition := _gallery_cg[raw_key] as Dictionary
		if definition == null or not CG_ITEM_LAYOUT.has(index):
			continue
		var button := Button.new()
		button.name = "CGItem_%d" % index
		button.position = CG_ITEM_LAYOUT[index]
		button.size = CG_ITEM_SIZE
		button.flat = true
		button.tooltip_text = str(definition.get("title", ""))
		button.set_meta("source_index", index)
		button.set_meta("is_lock", _is_cg_locked(definition))
		button.pressed.connect(func(): _on_cg_clicked(index))
		inner.add_child(button)
		_add_cg_layer(button, "Icon", str(definition.get("icon", "")), true)
		_add_cg_layer(button, "DeSelect", str(definition.get("icon_deselect", "")), false)
		_add_cg_layer(button, "Lock", str(definition.get("icon_lock", "")), bool(button.get_meta("is_lock")))
		_cg_items[index] = button


func _add_cg_layer(parent: Control, node_name: String, source_name: String, shown: bool) -> void:
	var layer := TextureRect.new()
	layer.name = node_name
	layer.position = (CG_ITEM_SIZE - CG_LAYER_SIZE) * 0.5
	layer.size = CG_LAYER_SIZE
	layer.pivot_offset = CG_LAYER_SIZE * 0.5
	layer.scale = CG_LAYER_SCALE
	layer.texture = _load_original_texture(source_name)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.visible = shown
	parent.add_child(layer)


func _build_big_cg() -> void:
	# [SRC: GalleryCGPanelController.ShowBigCG 0x5436b0; prefab's
	# BigCGContainer fills 3840x2160 and BigCG is a centred 2160 square.]
	_big_cg_container = Control.new()
	_big_cg_container.name = "BigCGContainer"
	_big_cg_container.size = DESIGN_SPACE
	_big_cg_container.visible = false
	_design.add_child(_big_cg_container)
	var shade := ColorRect.new()
	shade.name = "Mask"
	shade.color = Color(0, 0, 0, 0.92)
	shade.size = DESIGN_SPACE
	_big_cg_container.add_child(shade)
	_big_cg = TextureRect.new()
	_big_cg.name = "BigCG"
	_big_cg.position = Vector2(840, 0)
	_big_cg.size = Vector2(2160, 2160)
	_big_cg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_big_cg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_big_cg.mouse_filter = Control.MOUSE_FILTER_STOP
	_big_cg.gui_input.connect(_on_big_cg_input)
	_big_cg_container.add_child(_big_cg)
	_cg_title = Label.new()
	_cg_title.name = "CGTitle"
	_cg_title.position = Vector2(748.2, 0)
	_cg_title.size = Vector2(663.6, 147.5)
	_cg_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cg_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cg_title.add_theme_font_size_override("font_size", 60)
	_big_cg.add_child(_cg_title)
	_cg_lock_prompt = Label.new()
	_cg_lock_prompt.name = "CGLockPrompt"
	_cg_lock_prompt.position = Vector2(1420, 1840)
	_cg_lock_prompt.size = Vector2(1000, 120)
	_cg_lock_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cg_lock_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cg_lock_prompt.add_theme_font_size_override("font_size", 36)
	_cg_lock_prompt.text = _ui_text("GALLERY_OVER_CG_LOCK_TIPS", "尚未解锁")
	_cg_lock_prompt.visible = false
	_design.add_child(_cg_lock_prompt)


func _is_cg_locked(definition: Dictionary) -> bool:
	# [SRC: GalleryCGIconController.IsLock 0x5430a0 / ShowIcon 0x5433a0:
	# ANY GalleryCGNode.over_id present in Global.overID unlocks the CG.]
	if _global_state == null:
		return true
	for raw_id in definition.get("over_id", []):
		if _global_state.has_over_id(int(raw_id)):
			return false
	return true


func _on_cg_clicked(index: int) -> void:
	var definition := _gallery_cg.get(str(index), {}) as Dictionary
	if definition == null or definition.is_empty():
		return
	if _is_cg_locked(definition):
		_cg_lock_prompt.visible = true
		return
	_cg_lock_prompt.visible = false
	_big_cg.texture = _load_original_texture(str(definition.get("big_resource", "")))
	_cg_title.text = str(definition.get("title", ""))
	_big_cg_container.visible = _big_cg.texture != null


func _on_big_cg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_big_cg_container.visible = false


func _load_original_texture(source_name: String) -> Texture2D:
	if source_name.is_empty():
		return null
	var path := "res://assets/original/%s.png" % source_name
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


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
	_build_search()
	_scroll.get_v_scroll_bar().value_changed.connect(func(_value): _refresh_visible_groups())
	_rebuild_card_groups()


func _build_search() -> void:
	# [SRC: GalleryPanelNew/GalleryCard/Scroll View/Search/InputField (TMP)
	# 826x90 + Btn 110x116; GalleryCardPanel.SearchCard 0x549240.]
	var search := Control.new()
	search.name = "Search"
	search.position = CARD_SCROLL_RECT.position + SEARCH_RECT.position
	search.size = SEARCH_RECT.size
	_cards.add_child(search)
	_search_input = LineEdit.new()
	_search_input.name = "GalleryCardSearchInput"
	_search_input.position = Vector2(0, 5)
	_search_input.size = Vector2(826, 90)
	_search_input.placeholder_text = _ui_text("GALLERY_CARD_SEARCH_PLACEHOLDER", "搜索")
	_search_input.add_theme_font_size_override("font_size", 40)
	_search_input.add_theme_stylebox_override("normal", _source_texture_style("input_bg.png"))
	_search_input.add_theme_stylebox_override("focus", _source_texture_style("input_bg.png"))
	_search_input.text_submitted.connect(func(_submitted: String): _search_cards())
	search.add_child(_search_input)
	var button := Button.new()
	button.name = "GalleryCardSearchButton"
	button.position = Vector2(826, -8)
	button.size = Vector2(110, 116)
	button.flat = true
	button.tooltip_text = _ui_text("GALLERY_CARD_SEARCH_PLACEHOLDER", "搜索")
	button.pressed.connect(_search_cards)
	search.add_child(button)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(SEARCH_ICON_PATH) as Texture2D if ResourceLoader.exists(SEARCH_ICON_PATH) else null
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.size = button.size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)


func _source_texture_style(file_name: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	var path := "res://assets/original/ui/%s" % file_name
	if ResourceLoader.exists(path):
		style.texture = load(path) as Texture2D
	return style


func _search_cards() -> void:
	_search_query = _search_input.text if _search_input != null else ""
	_rebuild_card_groups()
	if _scroll != null:
		_scroll.scroll_vertical = 0


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
	elif mode == "CG":
		_refresh_cg_items()


func _refresh_cg_items() -> void:
	# [SRC: GalleryCGPanelController.OnEnable 0x543600 replays ShowIcon for
	# every child whenever the CG panel becomes active.]
	for raw_index in _cg_items.keys():
		var index := int(raw_index)
		var button := _cg_items[index] as Button
		var definition := _gallery_cg.get(str(index), {}) as Dictionary
		if button == null or definition == null:
			continue
		var locked := _is_cg_locked(definition)
		button.set_meta("is_lock", locked)
		var lock := button.get_node_or_null("Lock") as TextureRect
		if lock != null:
			lock.visible = locked


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
			button.pressed.connect(func(): _show_card_info(item))
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
		# [SRC: GalleryCardPanel.<>c__DisplayClass22_0.<SearchCard>b__0
		# 0x55c7f0: CardExtensions.GetName(card).Contains(input), no trim or
		# case-folding.  Archive view has no synthetic Player name overrides.]
		if not _search_query.is_empty() and not str(card.get("name", "")).contains(_search_query):
			continue
		out.append({"id": int(definition.get("id", 0)), "sort": int(definition.get("sort", 0)), "card": card, "definition": definition, "name": str(card.get("name", ""))})
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


func _ui_text(key: String, fallback: String) -> String:
	var row := _ui.get(key, {}) as Dictionary
	return str(row.get("zhCN", fallback))


func filtered_card_ids() -> Array[int]:
	var out: Array[int] = []
	for item in _filtered_cards():
		out.append(int(item["id"]))
	return out


func _show_card_info(item: Dictionary) -> void:
	# [SRC: GalleryCardItemController.OnPointerClick 0x547970 ->
	# GalleryCardPanel.ShowCardInfo 0x549520 -> GalleryCardInfo.Show 0x5465f0.]
	var cards := _filtered_cards()
	_current_card_index = -1
	for index in cards.size():
		if int(cards[index].get("id", 0)) == int(item.get("id", 0)):
			_current_card_index = index
			break
	if _current_card_index < 0:
		return
	_open_card_info(cards[_current_card_index], cards.size())


func _open_card_info(item: Dictionary, count: int) -> void:
	if _card_info != null and is_instance_valid(_card_info):
		remove_child(_card_info)
		_card_info.queue_free()
	_card_info = GalleryCardInfoView.new()
	_card_info.name = "GalleryCardInfoOverlay"
	_card_info.setup(_db, _global_state, item.get("definition", {}) as Dictionary, item.get("card", {}) as Dictionary, _current_card_index > 0, _current_card_index < count - 1)
	_card_info.closed.connect(_close_card_info)
	_card_info.navigation_requested.connect(_navigate_card_info)
	add_child(_card_info)


func _navigate_card_info(delta: int) -> void:
	var cards := _filtered_cards()
	var next_index := _current_card_index + delta
	if next_index < 0 or next_index >= cards.size():
		return
	_current_card_index = next_index
	_open_card_info(cards[_current_card_index], cards.size())


func _close_card_info() -> void:
	if _card_info == null:
		return
	remove_child(_card_info)
	_card_info.queue_free()
	_card_info = null
	_current_card_index = -1
