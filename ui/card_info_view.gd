extends Control
class_name CardInfoView
## Source-backed card info panel (Cards 详情浮层).
## Geometry is a direct replay of the original prefab truth table
## docs/ui_layout/CardInfoNew.md (Resources/prefab/CardInfoNew.prefab):
## the panel is 2510x1077 centred on the 3840x2160 MainUI canvas and every
## child here is placed with the authored anchors/anchoredPosition/sizeDelta/
## pivot numbers from that table (converted by _unity_rect, see below).
##
## [SRC: decompiled/CardInfoNewController.c @ Show (RVA 0x537000) +
## dump.cs:317550: Name/Title/Content/RareText/TypeIcon/RareIcon fields;
## textstyle.json @CARD_INFO_NAME/DESC/TYPE/RARE_TEXT_FORMAT;
## ui.json CARD_INFO_STATE_TITLE/ATTRIBUTE_TITLE/HELP_*]
##
## Known host-view gaps (METHOD_MAP): composite tags, equipment interaction,
## live property subscriptions, tooltips and full TMP material/layout parity.

signal closed
signal equipment_dropped(target_uid: int, source_uid: int)
var equipment_drop_allowed: Callable

class EquipmentDropPanel extends Control:
	var owner_view: Control
	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return owner_view.equipment_drop_allowed.is_valid() and owner_view.equipment_drop_allowed.call(owner_view._card_uid, data)
	func _drop_data(at: Vector2, data: Variant) -> void:
		if _can_drop_data(at, data):
			owner_view.equipment_dropped.emit(owner_view._card_uid, int(data.get("card_uid", 0)))

const DESIGN_SIZE := Vector2(3840, 2160)
const PANEL_SIZE := Vector2(2510, 1077)
const SOURCE_ART := "res://assets/original/ui/"

var _state
var _db
var _source_canvas: Control
var _panel: Control
var _name_label: Label
var _title_label: Label
var _content_label: RichTextLabel
var _rare_text: Label
var _state_bar_chips: Control
var _tag_chips: Control
var _equip_rows: Control
var _help_overlay: Control
var _card_uid := 0
var _card_id := 0
var _tag_groups: Dictionary
var _state_icons: Dictionary


func setup(state, db) -> void:
	_state = state
	_db = db


func card_uid() -> int:
	return _card_uid


func card_id() -> int:
	return _card_id


## [SRC: CardInfoNewController.Show 0x537000 — Name=GetName(card),
## Title=config.title, Content=custom_text||config.text (translated +
## placeholders), RareText=CARD_RARE_{rare}, TypeIcon=card_type_<type>,
## MainIcon=GetPic(card); FillTagArea/RefreshAllTags fills the 属性/标签
## columns; RefreshAllEquips fills Equips.]
func show_card(card: Dictionary, card_uid: int) -> void:
	_card_id = int(card.get("id", 0))
	_card_uid = card_uid
	_build_panel(card)


func _build_panel(card: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	if not resized.is_connected(_apply_layout):
		resized.connect(_apply_layout)
	_help_overlay = null
	name = "CardDetailOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# The root receives the window rect; the source canvas is the fixed
	# 3840x2160 CardInfoNew design space (scaled to the window, as in
	# ui/rite_view.gd).
	_source_canvas = Control.new()
	_source_canvas.name = "CardInfoCanvas"
	_source_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_source_canvas)

	# [SRC: CardInfoNewController.OnDrop 0x534410 -> DropCard 0x533550.]
	_panel = EquipmentDropPanel.new()
	_panel.owner_view = self
	_panel.name = "CardDetailPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# [SRC: CardInfoNew/CardInfoNew — 2510x1077 centred on the MainUI canvas]
	_panel.position = (DESIGN_SIZE - PANEL_SIZE) * 0.5
	_panel.size = PANEL_SIZE
	# [SRC: CardInfoNewController.Show 0x537000 tail reads Variable.ui_size
	# @0x58 using Datapool.fontSize@0x218, then scales the whole panel.]
	var preferences = preload("res://ui/game_application_settings.gd")
	preferences.load_preferences()
	var variable: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/variable.json"))
	_state_icons = variable.get("card_state_icon", {})
	_tag_groups = preload("res://ui/card_tag_presentation.gd").group(card, _db, _state_icons)
	var panel_scale := float(variable.get("ui_size", {}).get(preferences.font_size, 1.0))
	_panel.pivot_offset = PANEL_SIZE * 0.5
	_panel.scale = Vector2.ONE * panel_scale
	# The panel is a pure painting (bg_7) with free-floating children; the
	# card art (MainIcon 471x1028) hangs below its mask without clipping.
	_panel.clip_contents = false
	_source_canvas.add_child(_panel)

	var panel_bg := _texture_rect("bg_7.png", PANEL_SIZE)
	panel_bg.name = "PanelBackground"
	_panel.add_child(panel_bg)

	_build_name(card)
	_build_content(card)
	_build_rare(card)
	_build_tag_area(card)
	# [SRC: CardInfoNew.prefab panel children: Equips (224017892387517381)
	# precedes MainIconMask (224709890794832471) and BottomDecorate.]
	_build_equips(card)
	_build_main_icon(card)
	_build_decorate()
	_build_close()
	_build_help_button()
	_apply_layout()


func _apply_layout() -> void:
	if _source_canvas == null or _panel == null:
		return
	var view_size := size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		var parent_control := get_parent() as Control
		if parent_control != null:
			view_size = parent_control.size
	_source_canvas.position = Vector2.ZERO
	_source_canvas.size = DESIGN_SIZE
	_source_canvas.scale = Vector2(view_size.x / DESIGN_SIZE.x, view_size.y / DESIGN_SIZE.y)


## --- source geometry conversion -------------------------------------------
## Unity RectTransform -> Godot Rect2 in parent-local top-left coordinates.
## Verified against the CardInfoNew truth table rows (min/max formula and the
## y-axis flip; e.g. Content resolves to Rect2(270,80,1550,185) on the panel).
static func _unity_rect(
	parent_size: Vector2,
	anchor_min: Vector2,
	anchor_max: Vector2,
	pos: Vector2,
	size_delta: Vector2,
	pivot: Vector2
) -> Rect2:
	var unity_min := Vector2(
		anchor_min.x * parent_size.x + pos.x - pivot.x * size_delta.x,
		anchor_min.y * parent_size.y + pos.y - pivot.y * size_delta.y
	)
	var unity_max := Vector2(
		anchor_max.x * parent_size.x + pos.x + (1.0 - pivot.x) * size_delta.x,
		anchor_max.y * parent_size.y + pos.y + (1.0 - pivot.y) * size_delta.y
	)
	return Rect2(unity_min.x, parent_size.y - unity_max.y, unity_max.x - unity_min.x, unity_max.y - unity_min.y)


static func _place(parent: Control, rect: Rect2, node: Control, pivot_scale: Vector2 = Vector2.ONE) -> void:
	node.position = rect.position
	node.size = rect.size
	if pivot_scale != Vector2.ONE:
		node.scale = pivot_scale
	parent.add_child(node)


static func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _texture_rect(file_name: String, sprite_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	var path := SOURCE_ART + file_name
	if ResourceLoader.exists(path):
		rect.texture = load(path) as Texture2D
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.custom_minimum_size = sprite_size
	rect.size = sprite_size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _colored_text_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(4)
	return style


## --- children ---------------------------------------------------------------

## [SRC: CardInfoNew/CardInfoNew/Name — anchors (0,1) pivot (0,1)
## pos (1911,-89) size 435.55x71.58; Name/TypeIcon 36x58 @1.5;
## TypeIcon/Title fs30 (CARD_INFO_TYPE; @CARD_INFO_NAME autosize 40..60)]
func _build_name(card: Dictionary) -> void:
	var rect := _unity_rect(PANEL_SIZE, Vector2(0, 1), Vector2(0, 1), Vector2(1911, -89), Vector2(435.55, 71.58), Vector2(0, 1))
	# The authored rect must stay exact, so the label sits inside a plain
	# wrapper Control (Godot clamps a Label to its minimum size otherwise).
	var name_box := Control.new()
	name_box.name = "CardDetailName"
	name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_panel, rect, name_box)
	_name_label = _label(str(_card_display_name(card)), 56, Color("#f2e3c0"))
	preload("res://ui/source_text_style.gd").apply(_name_label, "@CARD_INFO_NAME")
	_name_label.name = "CardDetailNameText"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_box.add_child(_name_label)

	var type_rect := _unity_rect(rect.size, Vector2.ZERO, Vector2.ZERO, Vector2(0, -10), Vector2(36, 58), Vector2(0, 1))
	var type_icon := _texture_rect("card_type_%s.png" % str(card.get("type", "item")), Vector2(36, 58))
	type_icon.name = "TypeIcon"
	type_icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_place(_panel, Rect2(rect.position + type_rect.position, type_rect.size), type_icon, Vector2(1.5, 1.5))

	var title_rect := _unity_rect(Vector2(36, 58), Vector2(1, 0.5), Vector2(1, 0.5), Vector2(10, 0), Vector2(300, 50), Vector2(0, 0.5))
	# TypeIcon carries a 1.5x scale; its children inherit it in Unity.
	var title_local := title_rect.position * 1.5
	_title_label = _label(str(card.get("title", "")), 30, Color("#d8c088"))
	preload("res://ui/source_text_style.gd").apply(_title_label, "@CARD_INFO_TYPE")
	_title_label.name = "CardDetailSubtitle"
	_place(_panel, Rect2(rect.position + type_rect.position + title_local, title_rect.size), _title_label, Vector2(1.5, 1.5))


## [SRC: CardInfoNew/CardInfoNew/Content — anchors (0,1)-(1,1)
## pos (-210,-80) sizeDelta (-960,185); @CARD_INFO_DESC autosize 18..40]
func _build_content(card: Dictionary) -> void:
	var rect := _unity_rect(PANEL_SIZE, Vector2(0, 1), Vector2(1, 1), Vector2(-210, -80), Vector2(-960, 185), Vector2(0.5, 1))
	_content_label = RichTextLabel.new()
	_content_label.name = "CardDetailContent"
	_content_label.bbcode_enabled = true
	_content_label.fit_content = false
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_label.scroll_active = false
	_content_label.add_theme_font_size_override("normal_font_size", 34)
	preload("res://ui/source_text_style.gd").apply(_content_label, "@CARD_INFO_DESC")
	_content_label.add_theme_color_override("default_color", Color("#efe4c2"))
	var text := str(card.get("text", card.get("tips", "")))
	if _state != null and _state.has_method("substitute_text"):
		text = str(_state.substitute_text(text))
	_content_label.text = preload("res://ui/source_rich_text.gd").to_bbcode(text)
	_place(_panel, rect, _content_label)


## [SRC: CardInfoNew/CardInfoNew/RareBG — rare_stone 147x249 at (144.2,-163.3);
## RareText 120.93x50 fs60 (CARD_RARE_1..4: 石/铜/银/金)]
func _build_rare(card: Dictionary) -> void:
	var rect := _unity_rect(PANEL_SIZE, Vector2(0, 1), Vector2(0, 1), Vector2(144.2, -163.3), Vector2(147, 249), Vector2(0.5, 0.5))
	var rare := clampi(int(card.get("rare", 1)), 1, 4)
	# [SRC: Show 0x537000 -> CardShows.card_info_rare_bg@0xe0;
	# CardShows_FaceUnlit.asset:123 source sprite array in rarity order.]
	var rare_file: String = ["rare_stone.png", "rare_copper.png", "rare_silver.png", "rare_gold.png"][rare - 1]
	var rare_bg := _texture_rect(rare_file, Vector2(147, 249))
	rare_bg.name = "RareBG"
	_place(_panel, rect, rare_bg)
	_rare_text = _label(_rare_name(rare), 60, Color.BLACK)
	preload("res://ui/source_text_style.gd").apply(_rare_text, "@CARD_INFO_RARE_TEXT_FORMAT")
	_rare_text.name = "RareText"
	_rare_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rare_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var text_rect := _unity_rect(Vector2(147, 249), Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector2(-13.03, 0), Vector2(120.93, 50), Vector2(0.5, 0.5))
	_place(rare_bg, text_rect, _rare_text)


## [SRC: CardInfoNew/CardInfoNew/TagInfo — left column (0,0)-(0,1)
## pos (823.16,-142.69) sizeDelta (1336.7,-429.24); StateBar 1400x58.92
## (CARD_INFO_STATE_TITLE "属性"); TagInfo(Tag chips) 1700x(848.73) at
## (0.01,55.22) (CARD_INFO_ATTRIBUTE_TITLE "标签"); Attributes 1400x102.09 at
## (0,58.52). Autofill from CardExtensions.GetTags via RefreshAllTags;
## the clone keeps its existing attribute/tag data view (see header note).]
func _build_tag_area(card: Dictionary) -> void:
	var rect := _unity_rect(PANEL_SIZE, Vector2(0, 0), Vector2(0, 1), Vector2(823.16, -142.69), Vector2(1336.7, -429.24), Vector2(0.5, 0.5))
	var area := Control.new()
	area.name = "TagInfo"
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_panel, rect, area)

	var state_rect := _unity_rect(rect.size, Vector2(0, 1), Vector2(0, 1), Vector2.ZERO, Vector2(1400, 58.92), Vector2(0, 1))
	var state_bar := Control.new()
	state_bar.name = "StateBar"
	state_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(area, state_rect, state_bar)
	var state_title := _label("属性", 40, Color("#e8d8a8"))
	state_title.name = "StateTitle"
	preload("res://ui/source_text_style.gd").apply(state_title, "@CARD_INFO_TAG_TITLE")
	_place(state_bar, Rect2(0, 0, 200, 50), state_title)
	_fill_state_icons(state_bar, state_title)
	_state_bar_chips = Control.new()
	_state_bar_chips.name = "States"
	_state_bar_chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# TagContainer is the sibling TagInfo grid, not the StateBar row.
	# [SRC: CardInfoNew.prefab:1311/1316/2186; RefreshAllTags 0x535270
	# calls CardTagNewController.Show 0x53f040 for TagPrefab (CardTag).]
	_place(area, Rect2(0.01, 58.915, 1700, 419.49), _state_bar_chips)
	_fill_attribute_chips(card)

	var tags_rect := _unity_rect(rect.size, Vector2.ZERO, Vector2.ZERO, Vector2(0, 58.52), Vector2(1400, 102.09), Vector2.ZERO)
	var tags_area := Control.new()
	tags_area.name = "TagColumn"
	tags_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(area, tags_rect, tags_area)
	# 标签 title: left meta column of the original nested TagInfo node
	var tag_title := _label("标签", 40, Color("#e8d8a8"))
	tag_title.name = "AttributeTitle"
	preload("res://ui/source_text_style.gd").apply(tag_title, "@CARD_INFO_TAG_TITLE")
	_place(tags_area, Rect2(0, 0, 200, 50), tag_title)
	_tag_chips = Control.new()
	_tag_chips.name = "TagContents"
	_tag_chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(tags_area, Rect2(10, 59.79, 1390, 50), _tag_chips)
	_fill_tag_chips(card)


## CardTag grid: 400x120 cells, 20 horizontal spacing, MiddleLeft.
## CardAttribute is used for name-only tags, not these numeric attributes.
## Runtime sample (原作截图, CardInfoNew): 属性 shows 体魄/魅力/智慧/战斗/
## 社交/支持 in that order with icon+name+value (cfg 2000001, rare=3 银).
func _fill_attribute_chips(_card: Dictionary) -> void:
	if _state_bar_chips == null:
		return
	var visible_attrs: Array = _tag_groups["tags"]
	var columns := maxi(1, int((_state_bar_chips.size.x + 20) / 420))
	var rows := ceili(float(visible_attrs.size()) / columns)
	var top := (_state_bar_chips.size.y - rows * 120) * 0.5
	var index := 0
	var atlas := OriginalAtlas.load_atlas(SOURCE_ART + "tags.png")
	for node: Dictionary in visible_attrs:
		var attr := str(node["_source_name"])
		var value := int(node["_source_value"])
		var chip := Control.new()
		chip.name = "CardTag_%s" % attr
		chip.size = Vector2(400, 120)
		chip.position = Vector2((index % columns) * 420, top + (index / columns) * 120)
		var icon := TextureRect.new()
		icon.name = "Icon"
		# CardTagNewController.set_Tag 0x53f3e0 -> TagNodeExtensions.GetSprite.
		icon.texture = atlas.frame(str(node.get("resource", "")) + ".png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2(0, 6.8)
		icon.size = Vector2(86.4, 86.4)
		chip.add_child(icon)
		var title := _label(attr, 30, Color("#ddd5c4"))
		title.name = "Title"
		preload("res://ui/source_text_style.gd").apply(title, "@CARD_INFO_TAG_TEXT")
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place(chip, Rect2(98.4, 2, 154, 80), title, Vector2(1.2, 1.2))
		var count := _label(str(value), 30, Color("#ddd5c4"))
		var diff := int(node["_source_diff"])
		if diff != 0:
			count.add_theme_color_override("font_color", Color.YELLOW if diff > 0 else Color.RED)
			var arrow := _texture_rect("upper.png" if diff > 0 else "lower.png", Vector2(23, 32))
			arrow.name = "Modify"
			_place(chip, Rect2(31.7, 54.76, 27.6, 38.4), arrow)
		count.name = "Value"
		preload("res://ui/source_text_style.gd").apply(count, "@CARD_INFO_TAG_TEXT")
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# CARD_TAG_CAN_ADD_FORMAT uses <indent=70%> inside the 220x80 title.
		_place(chip, Rect2(283.2, 2, 66, 80), count, Vector2(1.2, 1.2))
		_state_bar_chips.add_child(chip)
		index += 1


## 标签 chips (non-attribute tags in config order, name-only per the runtime
## sample; the original shows 男性 贵族 主角 已拥有 with NO values).
func _fill_tag_chips(_card: Dictionary) -> void:
	if _tag_chips == null:
		return
	var x := 0.0
	var y := 0.0
	for node: Dictionary in _tag_groups["attributes"]:
		var chip := _label(str(node["_source_name"]), 30, Color("#ddd5c4"))
		preload("res://ui/source_text_style.gd").apply(chip, "@CARD_INFO_TAG_TEXT")
		chip.size = Vector2(60, 40)
		chip.position = Vector2(x, y)
		_tag_chips.add_child(chip)
		x += chip.size.x + 20.0
		if x > 1000.0:
			x = 0.0
			y += 52.0


func _fill_state_icons(bar: Control, title: Label) -> void:
	# [SRC: RefreshAllTags 0x535270 repeats StatePrefab once per positive
	# GetTag value; CardStateTagController.SetState 0x53dbb0; prefab 43x43.]
	var row := HBoxContainer.new()
	row.name = "StateIcons"
	row.position = Vector2(title.get_minimum_size().x + 10, 15.92)
	row.add_theme_constant_override("separation", 4)
	bar.add_child(row)
	for node: Dictionary in _tag_groups["states"]:
		var file_name := str(_state_icons.get(str(node.get("code", "")), "")).get_file() + ".png"
		for index in int(node["_source_value"]):
			var icon := _texture_rect(file_name, Vector2(43, 43))
			icon.name = "State_%s_%d" % [str(node.get("code", "")), index]
			row.add_child(icon)


func _tag_chip(text: String, font_size: int) -> Panel:
	var chip := Panel.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _colored_text_style(Color(0.08, 0.06, 0.04, 0.65), Color(0.5, 0.38, 0.2, 0.8)))
	var content := _label(text, font_size, Color("#f4e6c0"))
	content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(content)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 8
	content.offset_right = -8
	chip.custom_minimum_size = Vector2(60, 40)
	chip.size = Vector2(60, 40)
	chip.reset_size()
	chip.size = Vector2(maxf(64.0, content.get_minimum_size().x + 24.0), 40.0)
	return chip


## [SRC: CardInfoNew/CardInfoNew/MainIconMask 1000x1100 at (1020,89);
## MainIcon 471x1028 at (-30,431); art = GetPic(card) — the clone resolves
## assets/original/cards/<id>.png with the type-icon fallback.]
func _build_main_icon(card: Dictionary) -> void:
	var rect := _unity_rect(PANEL_SIZE, Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector2(1020, 89), Vector2(1000, 1100), Vector2(0.5, 0.5))
	var mask := Control.new()
	mask.name = "MainIconMask"
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.clip_contents = true
	_place(_panel, rect, mask)
	var icon_rect := _unity_rect(rect.size, Vector2(0.5, 0), Vector2(0.5, 0), Vector2(-30, 431), Vector2(471, 1028), Vector2(0.5, 0.5))
	var icon := _card_art(card)
	icon.name = "MainIcon"
	_place(mask, icon_rect, icon)


func _card_art(card: Dictionary) -> TextureRect:
	var rect := TextureRect.new()
	var art_path := "res://assets/original/cards/%d.png" % int(card.get("id", 0))
	if ResourceLoader.exists(art_path):
		rect.texture = load(art_path) as Texture2D
	elif ResourceLoader.exists("%scard_type_%s.png" % [SOURCE_ART, str(card.get("type", "item"))]):
		rect.texture = load("%scard_type_%s.png" % [SOURCE_ART, str(card.get("type", "item"))]) as Texture2D
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## [SRC: CardInfoNew/CardInfoNew/BottomDecorate — decorate 250x323 at
## (1108,-364), the lower-right corner ornament.]
func _build_decorate() -> void:
	var rect := _unity_rect(PANEL_SIZE, Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector2(1108, -364), Vector2(250, 323), Vector2(0.5, 0.5))
	var decorate := _texture_rect("decorate.png", Vector2(250, 323))
	decorate.name = "BottomDecorate"
	_place(_panel, rect, decorate)


## [SRC: CardInfoNew/CardInfoNew/Equips (1,0.5) pos (-680,-100)
## 402.65x500.57 — the equipped list (RefreshAllEquips); EquipState
## (1,1) (-442,-34.5) 354.22x100 is the 装备 caption/count.]
func _build_equips(card: Dictionary) -> void:
	var rect := _unity_rect(PANEL_SIZE, Vector2(1, 0.5), Vector2(1, 0.5), Vector2(-680, -100), Vector2(402.65, 500.57), Vector2(0.5, 0.5))
	var area := Control.new()
	area.name = "Equips"
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.clip_contents = false
	_place(_panel, rect, area)

	_equip_rows = Control.new()
	_equip_rows.name = "EquipList"
	_equip_rows.size = rect.size
	_equip_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(_equip_rows)
	var index := 0
	for equipment in card.get("equipped_cards", []):
		if not (equipment is Dictionary):
			continue
		var widget := CardWidget.new()
		widget.name = "EquippedCard_%d" % index
		widget.set_card(equipment)
		_equip_rows.add_child(widget)
		widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# [SRC: RefreshAllEquips 0x534c40 and .cctor 0x537e30:
		# two columns (260,-50,6)/(150,-150,16), steps (20,100)/(5,125), angle -4.]
		var column := index % 2
		var row := index / 2
		var origin := Vector2(260, -50) if column == 0 else Vector2(150, -150)
		var step := Vector2(20, 100) if column == 0 else Vector2(5, 125)
		var source_pos := origin + step * row
		widget.pivot_offset = widget.size * 0.5
		widget.position = rect.size * 0.5 + Vector2(source_pos.x, -source_pos.y) - widget.pivot_offset
		widget.rotation_degrees = -(6 if column == 0 else 16) + row * 4
		_equip_rows.move_child(widget, 0)
		index += 1

	var state_rect := _unity_rect(PANEL_SIZE, Vector2(1, 1), Vector2(1, 1), Vector2(-442, -34.5), Vector2(354.22, 100), Vector2(0.5, 0.5))
	var state := Control.new()
	state.name = "EquipState"
	state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_panel, state_rect, state)
	_fill_equipment_slots(state, card)


func _fill_equipment_slots(parent: Control, card: Dictionary) -> void:
	# [SRC: CardEquipSlot.prefab Types sprite GUID pairs; SetType 0x52dc70
	# and set_Equiped 0x52e090; GetEquipStats 0x37fa50 consumes each equip once.]
	var sprites := {
		"weapon": ["weapon_unequip", "weapon_equip"],
		"cloth": ["close_unequip", "cloth_equip"],
		"accessory": ["decorate_unequip", "decorate_equip"],
		"animal_handling": ["mount_unequip", "mount_equip"],
		"jewel": ["jewel_unequip", "jewel_equip"],
	}
	var used: Dictionary = {}
	var equipments: Array = card.get("equipped_cards", [])
	var index := 0
	for slot in card.get("equip_slots", card.get("equips", [])):
		var code := str(_db.tag_name_to_code.get(str(slot), str(slot)))
		var occupied := false
		for equip_index in equipments.size():
			var equipment: Dictionary = equipments[equip_index]
			var tags: Dictionary = equipment.get("tag", {})
			var slot_name := str(_db.tags_by_code.get(code, {}).get("name", slot))
			if not used.has(equip_index) and int(tags.get(slot_name, 0)) > 0:
				used[equip_index] = true
				occupied = true
				break
		var slot_view := _texture_rect("equip_slot.png", Vector2(60, 63))
		slot_view.name = "EquipSlot_%d" % index
		slot_view.set_meta("slot_code", code)
		slot_view.set_meta("occupied", occupied)
		_place(parent, Rect2(index * 80, 18.5, 60, 63), slot_view)
		if sprites.has(code):
			var type_icon := _texture_rect(str(sprites[code][1 if occupied else 0]) + ".png", Vector2(36, 58))
			type_icon.name = "Type"
			_place(slot_view, Rect2(12, 2.5, 36, 58), type_icon)
		index += 1


func _equip_row(equipment: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := _texture_rect("equip_slot.png", Vector2(60, 63))
	icon.name = "EquipSlotIcon"
	row.add_child(icon)
	var slot := str(equipment.get("equipped_slot", ""))
	var name_label := _label("%s  %s" % [slot if not slot.is_empty() else "附着", str(equipment.get("name", equipment.get("id", "?")))], 30, Color("#efe4c2"))
	name_label.name = "EquipName"
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	return row


## [SRC: CardInfoNew/CardInfoNew/Close — checkbox_bg 80x82 at (-80.2,-82);
## Image close_2 43x37]
func _build_close() -> void:
	var rect := _unity_rect(PANEL_SIZE, Vector2(1, 1), Vector2(1, 1), Vector2(-80.2, -82), Vector2(80, 82), Vector2(0.5, 0.5))
	var button := Button.new()
	button.name = "CloseCardDetailButton"
	button.tooltip_text = "关闭"
	button.flat = true
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.pressed.connect(func(): closed.emit())
	var style := StyleBoxTexture.new()
	if ResourceLoader.exists(SOURCE_ART + "checkbox_bg.png"):
		style.texture = load(SOURCE_ART + "checkbox_bg.png") as Texture2D
		style.texture_margin_left = 20
		style.texture_margin_right = 20
		style.texture_margin_top = 20
		style.texture_margin_bottom = 20
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, style)
	if ResourceLoader.exists(SOURCE_ART + "close_2.png"):
		var icon := TextureRect.new()
		icon.texture = load(SOURCE_ART + "close_2.png") as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.size = Vector2(43, 37)
		icon.position = Vector2((80 - 43) * 0.5, (82 - 37) * 0.5)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
	_place(_panel, rect, button)


## [SRC: CardInfoNew/CardInfoNew/HelpButton — help_button 88x91 at (-23,67)
## bottom-right; opens the CardInfoNew/Help overlay (card_info art + the
## four CARD_INFO_HELP_* bubbles). Help texts come from ui.json (zhTW;
## converted to the clone's simplified rendering).]
func _build_help_button() -> void:
	var rect := _unity_rect(PANEL_SIZE, Vector2(1, 0), Vector2(1, 0), Vector2(-23, 67), Vector2(88, 91), Vector2(0.5, 0.5))
	var button := Button.new()
	button.name = "CardInfoHelpButton"
	button.tooltip_text = "帮助"
	button.flat = true
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.pressed.connect(_toggle_help)
	var style := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, style)
	if ResourceLoader.exists(SOURCE_ART + "help_button.png"):
		var icon := TextureRect.new()
		icon.texture = load(SOURCE_ART + "help_button.png") as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.size = Vector2(88, 91)
		icon.position = Vector2.ZERO
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
	_place(_panel, rect, button)


## [SRC: CardInfoNew/Help — full-rect help overlay on its own constant-pixel
## canvas (authored for 1920x1080; the clone renders it at 2x inside the
## 3840x2160 design space): Mask 10000x10000, Prompt card_info art, four
## fs50 bubbles with the CARD_INFO_HELP_* texts.]
func _toggle_help() -> void:
	if _help_overlay != null:
		hide_help()
		return
	_help_overlay = Control.new()
	_help_overlay.name = "CardInfoHelp"
	_help_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_help_overlay.position = Vector2.ZERO
	_help_overlay.size = DESIGN_SIZE
	_help_overlay.pivot_offset = DESIGN_SIZE * 0.5
	_help_overlay.scale = _panel.scale
	_help_overlay.z_index = 300
	var mask := ColorRect.new()
	mask.name = "Mask"
	mask.color = Color(0, 0, 0, 0.5019608)
	mask.position = (DESIGN_SIZE - Vector2(10000, 10000)) * 0.5
	mask.size = Vector2(10000, 10000)
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	mask.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide_help()
	)
	_help_overlay.add_child(mask)
	var prompt := _texture_rect("card_info.png", DESIGN_SIZE)
	prompt.name = "Prompt"
	_help_overlay.add_child(prompt)
	# The nested world-space Canvas has no scaler; its units inherit the
	# 3840x2160 root, not a second 1920x1080 design space.
	_help_overlay.add_child(_help_bubble("RARE", Vector2(670, 340), Vector2(600, 200), VERTICAL_ALIGNMENT_BOTTOM))
	_help_overlay.add_child(_help_bubble("MAIN", Vector2(1348, 1336), Vector2(600, 200)))
	_help_overlay.add_child(_help_bubble("EQUIP", Vector2(2133.4, 1380), Vector2(1114.6, 200)))
	_help_overlay.add_child(_help_bubble("EQUIP_SLOT", Vector2(2056, 310), Vector2(1200, 200), VERTICAL_ALIGNMENT_BOTTOM))
	if _source_canvas != null:
		_source_canvas.add_child(_help_overlay)
	else:
		add_child(_help_overlay)


func _help_bubble(kind: String, pos: Vector2, bubble_size: Vector2, alignment: VerticalAlignment = VERTICAL_ALIGNMENT_TOP) -> RichTextLabel:
	var bubble := RichTextLabel.new()
	bubble.name = "HelpBubble_" + kind
	bubble.position = pos
	bubble.size = bubble_size
	bubble.bbcode_enabled = true
	bubble.scroll_active = false
	bubble.add_theme_color_override("default_color", Color(0.94509804, 0.87163, 0.7504079))
	preload("res://ui/source_text_style.gd").apply(bubble, "@HELP_TEXT")
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.vertical_alignment = alignment
	bubble.text = _to_bbcode(_help_text(kind))
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# TMP Overflow leaves long help text visible beyond the authored rect.
	# Godot clips RichTextLabel, so grow its paint bounds while retaining the
	# source top/bottom alignment anchor.
	bubble.set_meta("source_rect", Rect2(pos, bubble_size))
	call_deferred("_fit_help_text", bubble, pos, bubble_size, alignment)
	return bubble


func _fit_help_text(bubble: RichTextLabel, pos: Vector2, authored_size: Vector2, alignment: VerticalAlignment) -> void:
	if not is_instance_valid(bubble):
		return
	var height := maxf(authored_size.y, bubble.get_content_height())
	bubble.size.y = height
	if alignment == VERTICAL_ALIGNMENT_BOTTOM:
		bubble.position.y = pos.y + authored_size.y - height


## Unity TMP emphasis tags (<b><color=white><size=86>…) -> Godot 4 BBCode.
static func _to_bbcode(text_value: String) -> String:
	return preload("res://ui/source_rich_text.gd").to_bbcode(text_value)


func _help_text(kind: String) -> String:
	var text: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/ui.json"))
	return str(text.get("CARD_INFO_HELP_%s_PROMPT" % kind, {}).get("zhCN", ""))


func hide_help() -> void:
	if _help_overlay == null:
		return
	var old := _help_overlay
	_help_overlay = null
	if old.get_parent() != null:
		old.get_parent().remove_child(old)
	old.queue_free()


func _card_display_name(card: Dictionary) -> String:
	if not card.is_empty():
		return str(card.get("name", card.get("base_name", "?")))
	return "?"


static func _rare_name(rare: int) -> String:
	# ui.json CARD_RARE_1..4: 石/铜/银/金 (config rare values are 1..4 only)
	match rare:
		1:
			return "石"
		2:
			return "铜"
		3:
			return "银"
		4:
			return "金"
	return ""


func close_view() -> void:
	hide_help()
	for child in get_children():
		child.queue_free()
