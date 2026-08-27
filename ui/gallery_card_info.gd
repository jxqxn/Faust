## Dedicated source-shaped GalleryCardInfo surface.
## [SRC: decompiled/GalleryCardInfo.c @ Show (RVA 0x5465f0),
## AddShowedGalleryCard (0x543c80), OnItemClicked (0x5456d0),
## OnPrevBtn (0x545920), OnNextBtn (0x545870), OnClose (0x5455a0);
## dump.cs:318797; Resources/prefab/GalleryCardInfo.prefab.]
class_name GalleryCardInfo
extends Control

signal closed()
signal navigation_requested(delta: int)

const DESIGN_SPACE := Vector2(3840, 2160)
const PLOTS_RECT := Rect2(0, 228, 1300, 1930)
const CARD_INFO_RECT := Rect2(1210, 191.005, 2630, 1946.73)
const PLOTS_GROUP_RECT := Rect2(217, 512, 900, 1170)
const SOURCE_UI := "res://assets/original/ui/"
const TAG_GRID_CELL := Vector2(365, 120)
const TAG_GRID_COLUMNS := 3
const TAG_GRID_LEFT_PADDING := -70.0
const ATTRIBUTE_ITEM_SIZE := Vector2(60, 40)
const ATTRIBUTE_SPACING := Vector2(20, 10)

static var _tags_atlas: OriginalAtlas = null

var _db: ConfigDB
var _global_state: GlobalState
var _definition: Dictionary
var _card: Dictionary
var _design: Control
var _plots_group: Control
var _plot_mask: Control
var _card_info: Control
var _basic_content: Control
var _plot_content: Control
var _plot_content_list: VBoxContainer
var _main_icon: TextureRect
var _rare_image: TextureRect
var _head_markers: Array[Control] = []


func setup(config_db: ConfigDB, global_state: GlobalState, definition: Dictionary, card: Dictionary, has_prev: bool, has_next: bool) -> void:
	_db = config_db
	_global_state = global_state
	_definition = definition
	_card = card
	_build_ui(has_prev, has_next)


func _ready() -> void:
	theme = FaustTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if _design != null:
		call_deferred("_layout_design")


func _build_ui(has_prev: bool, has_next: bool) -> void:
	_design = Control.new()
	_design.name = "GalleryCardInfo"
	_design.size = DESIGN_SPACE
	add_child(_design)
	resized.connect(_layout_design)

	var background := _texture_rect("cardinfo_bg.png")
	background.name = "Background"
	_place(_design, Rect2(Vector2.ZERO, DESIGN_SPACE), background)

	var plots := _texture_rect("cardinfo_bg_left.png")
	plots.name = "Plots"
	_place(_design, PLOTS_RECT, plots)
	_build_identity(plots)
	_build_plots(plots)
	_build_resource_toggles(plots)

	_card_info = _texture_rect("cardinfo_bg_char.png")
	_card_info.name = "CardInfo"
	_place(_design, CARD_INFO_RECT, _card_info)
	_build_card_info()
	_build_navigation(has_prev, has_next)
	_layout_design()


func _layout_design() -> void:
	if _design == null:
		return
	var view_size := size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		var viewport := get_viewport()
		view_size = viewport.get_visible_rect().size if viewport != null else DESIGN_SPACE
	_design.scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _build_identity(plots: Control) -> void:
	# GalleryCardInfo/Plots/Name authored at anchor top-right, scale 2.
	var name_label := _label(str(_card.get("name", "")), 40)
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(plots, Rect2(571.45, 247, 435.55, 72.02), name_label)
	name_label.scale = Vector2(2, 2)
	name_label.pivot_offset = name_label.size
	var title := _label(str(_card.get("title", "")), 30)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(plots, Rect2(707, 391.5, 300, 36.01), title)


func _build_plots(plots: Control) -> void:
	_plots_group = Control.new()
	_plots_group.name = "PlotsGroup"
	_place(plots, PLOTS_GROUP_RECT, _plots_group)
	var scroll := ScrollContainer.new()
	scroll.name = "PlotList"
	scroll.size = _plots_group.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_plots_group.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "PlotItems"
	list.custom_minimum_size = Vector2(880, 0)
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	# [SRC: Show 0x5465f0 instantiates one PlotItemController per
	# GalleryCardNode.plots entry; PlotItemController.Init displays title.]
	for raw_plot in _definition.get("plots", []):
		var plot := raw_plot as Dictionary
		if plot == null:
			continue
		var button := Button.new()
		button.name = "PlotItem_%s" % str(plot.get("guid", ""))
		button.custom_minimum_size = Vector2(850, 100)
		# PlotItem.prefab owns its 850px width; the source VerticalLayoutGroup
		# does not control child width (cc=0), so keep it from stretching.
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.flat = true
		var highlight := _texture_rect("hightlight.png")
		highlight.name = "HighLight"
		_place(button, Rect2(50, 0, 800, 100), highlight)
		var dot := _texture_rect("dot_light.png")
		dot.name = "Image"
		_place(button, Rect2(0, 23.495, 50, 53.01), dot)
		var title := _label(str(plot.get("title", "")), 50)
		title.name = "Title"
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place(button, Rect2(50, 0, 800, 100), title)
		button.pressed.connect(func(): _show_plot(plot))
		list.add_child(button)

	_plot_mask = Control.new()
	_plot_mask.name = "PlotMask"
	_plot_mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	_plot_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	var mask_panel := Panel.new()
	mask_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask_panel.add_theme_stylebox_override("panel", _texture_style("cardinfo_plot_mask.png"))
	_plot_mask.add_child(mask_panel)
	var tips := _texture_rect("rite_tips.png")
	_place(_plot_mask, Rect2(374, 313, 152, 144), tips)
	var prompt := _label("解锁该角色的剧情记录", 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(_plot_mask, Rect2(255, 500, 390.3, 80), prompt)
	var confirm := Button.new()
	confirm.name = "Confirm"
	confirm.text = "确认"
	confirm.position = Vector2(287.5, 862)
	confirm.size = Vector2(325, 158)
	confirm.add_theme_font_size_override("font_size", 36)
	confirm.add_theme_stylebox_override("normal", _texture_style("rite_op_confirm.png"))
	confirm.pressed.connect(_add_showed_gallery_card)
	_plot_mask.add_child(confirm)
	_plots_group.add_child(_plot_mask)
	# [SRC: Show 0x5465f0 sets PlotMask active iff this id is absent from
	# Global.showedGalleryCards.]
	_plot_mask.visible = _global_state != null and not _global_state.has_shown_gallery_card(int(_definition.get("id", 0)))


func _build_resource_toggles(plots: Control) -> void:
	var resources := _image_resources()
	if resources.is_empty():
		return
	_head_markers.clear()
	var heads := HBoxContainer.new()
	heads.name = "HeadGroup"
	heads.position = Vector2(346, 0)
	heads.size = Vector2(632.08, 240)
	heads.alignment = BoxContainer.ALIGNMENT_CENTER
	plots.add_child(heads)
	for index in resources.size():
		var resource := resources[index] as Dictionary
		var toggle := Button.new()
		toggle.name = "GalleryCardHead_%d" % index
		toggle.custom_minimum_size = Vector2(110, 110)
		toggle.tooltip_text = str(resource.get("pic_res", ""))
		toggle.flat = true
		var head := _card_art(_resource_asset_path(str(resource.get("pic_res", ""))))
		head.name = "Head"
		head.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_place(toggle, Rect2(0, 0, 110, 110), head)
		var marker := _texture_rect("is_on.png")
		marker.name = "Image"
		marker.position = Vector2(36.3, 78.69)
		marker.size = Vector2(50, 50)
		marker.visible = index == 0
		toggle.add_child(marker)
		_head_markers.append(marker)
		toggle.pressed.connect(func(): _change_icon(index))
		heads.add_child(toggle)


func _build_card_info() -> void:
	_rare_image = _texture_rect(_rare_texture_name(_initial_rare()))
	_rare_image.name = "Rare"
	_place(_card_info, Rect2(2173.26, 441.865, 370, 1063), _rare_image)
	_main_icon = _card_art(_card_resource_path(0))
	_main_icon.name = "MainIcon"
	_main_icon.position = Vector2(1755, 334.365)
	_main_icon.size = Vector2(472, 1028)
	_main_icon.scale = Vector2(2, 2)
	_main_icon.pivot_offset = _main_icon.size * 0.5
	_card_info.add_child(_main_icon)

	_basic_content = Control.new()
	_basic_content.name = "Left"
	_place(_card_info, Rect2(350, 253.365, 930, 1440), _basic_content)
	var quote := _label("“", 200)
	_place(_basic_content, Rect2(0, 0, 100, 150), quote)
	var content := _label(str(_card.get("text", "")), 42)
	content.name = "Content"
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(_basic_content, Rect2(0, 180, 930, 360), content)
	_build_tags(_basic_content)

	_plot_content = Control.new()
	_plot_content.name = "plotContent"
	_plot_content.visible = false
	_place(_card_info, Rect2(350, 253.365, 930, 1440), _plot_content)
	var plot_scroll := ScrollContainer.new()
	plot_scroll.name = "Scroll View"
	plot_scroll.size = Vector2(930, 1400)
	plot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_plot_content.add_child(plot_scroll)
	_plot_content_list = VBoxContainer.new()
	_plot_content_list.name = "PlotContainer"
	_plot_content_list.custom_minimum_size = Vector2(913, 0)
	_plot_content_list.add_theme_constant_override("separation", 100)
	plot_scroll.add_child(_plot_content_list)
	var back := Button.new()
	back.name = "PlotBack"
	back.position = Vector2(372.5, 1260)
	back.size = Vector2(168, 160)
	back.flat = true
	var back_icon := _texture_rect("close_0.png")
	back_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.add_child(back_icon)
	back.pressed.connect(_show_basic_content)
	_plot_content.add_child(back)

	var close := Button.new()
	close.name = "Close"
	close.position = Vector2(2462, 125.365)
	close.size = Vector2(80, 82)
	close.icon = load(SOURCE_UI + "close_2.png") as Texture2D if ResourceLoader.exists(SOURCE_UI + "close_2.png") else null
	close.pressed.connect(func(): closed.emit())
	_card_info.add_child(close)


func _build_tags(parent: Control) -> void:
	# [SRC: GalleryCardInfo.RefreshAllTags 0x5459c0] builds TagNode lists
	# directly from CardExtensions.GetTags, applies TagNode visibility/value
	# gates, splits type=="attribute", sorts both by tag_rank descending, then
	# instantiates CardTagNew (non-attribute) and CardAttribute (attribute).
	var split := _source_tag_nodes()
	var tag_nodes: Array = split["tags"]
	var attribute_nodes: Array = split["attributes"]

	# GalleryCardInfo/Left/TagInfo is the controller's TagContainer: a source
	# GridLayoutGroup with padding-left -70, cell 365x120 and 3 columns.
	var tag_contents := Control.new()
	tag_contents.name = "TagContents"
	_place(parent, Rect2(0, 650, 1095, ceili(float(tag_nodes.size()) / TAG_GRID_COLUMNS) * TAG_GRID_CELL.y), tag_contents)
	for index in tag_nodes.size():
		var row: Dictionary = tag_nodes[index]
		var item := _card_tag_new(row)
		item.position = Vector2(
			TAG_GRID_LEFT_PADDING + float(index % TAG_GRID_COLUMNS) * TAG_GRID_CELL.x,
			float(index / TAG_GRID_COLUMNS) * TAG_GRID_CELL.y
		)
		tag_contents.add_child(item)

	# Source Attribute Contents wraps a Real Attribute Contents flow group at
	# scale 1.5. CardAttribute.Show 0x527c10 assigns TagNode.name only.
	var attribute_contents := Control.new()
	attribute_contents.name = "AttributeContents"
	_place(parent, Rect2(0, 910, 930, 100), attribute_contents)
	var real_contents := Control.new()
	real_contents.name = "RealAttributeContents"
	real_contents.scale = Vector2(1.5, 1.5)
	real_contents.size = Vector2(620, 60)
	attribute_contents.add_child(real_contents)
	var cursor := Vector2.ZERO
	for raw_row in attribute_nodes:
		var row: Dictionary = raw_row
		var item := _card_attribute(row)
		item.position = cursor
		real_contents.add_child(item)
		cursor.x += ATTRIBUTE_ITEM_SIZE.x + ATTRIBUTE_SPACING.x


func _source_tag_nodes() -> Dictionary:
	var out := {"tags": [], "attributes": []}
	if _db == null:
		return out
	var card_tags = _card.get("tag", {})
	if not (card_tags is Dictionary):
		return out
	var source_index := 0
	for raw_name in (card_tags as Dictionary).keys():
		var tag_name := str(raw_name)
		var code := str(_db.tag_name_to_code.get(tag_name, ""))
		if code.is_empty() or not _db.tags_by_code.has(code):
			source_index += 1
			continue
		var tag_node: Dictionary = (_db.tags_by_code[code] as Dictionary).duplicate(true)
		var value := int((card_tags as Dictionary).get(raw_name, 0))
		# Exact RefreshAllTags gates: visible && (can_add || value != 0) &&
		# (can_nagative_and_zero || value > 0).
		if int(tag_node.get("can_visible", 0)) == 0:
			source_index += 1
			continue
		if int(tag_node.get("can_add", 0)) == 0 and value == 0:
			source_index += 1
			continue
		if int(tag_node.get("can_nagative_and_zero", 0)) == 0 and value <= 0:
			source_index += 1
			continue
		tag_node["_source_name"] = tag_name
		tag_node["_source_value"] = value
		tag_node["_source_index"] = source_index
		var bucket: Array = out["attributes"] if str(tag_node.get("type", "")) == "attribute" else out["tags"]
		bucket.append(tag_node)
		source_index += 1
	for bucket_key in ["tags", "attributes"]:
		var bucket: Array = out[bucket_key]
		bucket.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var a_rank := int(a.get("tag_rank", 0))
			var b_rank := int(b.get("tag_rank", 0))
			if a_rank == b_rank:
				return int(a.get("_source_index", 0)) < int(b.get("_source_index", 0))
			return a_rank > b_rank
		)
	return out


func _card_tag_new(tag_node: Dictionary) -> Control:
	# [SRC: CardTag.prefab + CardTagNewController.Show 0x53f040]
	var item := Control.new()
	var tag_name := str(tag_node.get("_source_name", tag_node.get("name", "")))
	var value := int(tag_node.get("_source_value", 0))
	item.name = "CardTag_%s" % tag_name
	item.size = TAG_GRID_CELL
	item.set_meta("source_tag_name", tag_name)
	item.set_meta("source_tag_value", value)

	var icon := TextureRect.new()
	icon.name = "CardTag"
	icon.texture = _tag_texture(str(tag_node.get("resource", "")))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.position = Vector2(0, 14)
	icon.size = Vector2(72, 72)
	icon.pivot_offset = Vector2(0, 36)
	icon.scale = Vector2(1.2, 1.2)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(icon)

	var title := _label("%s　%d" % [tag_name, value], 30)
	title.name = "Title"
	title.position = Vector2(82, -4)
	title.size = Vector2(220, 80)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_child(title)

	var count_bg := _texture_rect("checkbox_bg.png")
	count_bg.name = "CountBg"
	count_bg.position = Vector2(1, 36)
	count_bg.size = Vector2(70, 72)
	count_bg.pivot_offset = count_bg.size * 0.5
	count_bg.scale = Vector2(0.5, 0.5)
	icon.add_child(count_bg)
	return item


func _card_attribute(tag_node: Dictionary) -> Control:
	# [SRC: CardAttribute.prefab 60x40/fs30; CardAttributeController.Show
	# 0x527c10 writes TagNode.name and never writes the numeric value.]
	var tag_name := str(tag_node.get("name", tag_node.get("_source_name", "")))
	# A fixed RectTransform shell prevents Godot's Label minimum size from
	# expanding the authored 60x40 prefab (Unity TMP is allowed to overflow it).
	var item := Control.new()
	item.name = "CardAttribute_%s" % tag_name
	item.size = ATTRIBUTE_ITEM_SIZE
	item.set_meta("source_tag_name", tag_name)
	var text := _label(tag_name, 30)
	text.name = "Text"
	text.position = Vector2.ZERO
	text.size = ATTRIBUTE_ITEM_SIZE
	text.add_theme_constant_override("outline_size", 2)
	text.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.9))
	item.add_child(text)
	return item


func _tag_texture(resource_id: String) -> Texture2D:
	if resource_id.is_empty():
		return null
	if _tags_atlas == null:
		_tags_atlas = OriginalAtlas.load_atlas(SOURCE_UI + "tags.png")
	return _tags_atlas.frame(resource_id + ".png") if _tags_atlas != null else null


func _build_navigation(has_prev: bool, has_next: bool) -> void:
	var prev := Button.new()
	prev.name = "Prev"
	prev.position = Vector2(0, 1002)
	prev.size = Vector2(168, 156)
	prev.flat = true
	var prev_icon := _texture_rect("page_left.png")
	prev_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	prev.add_child(prev_icon)
	prev.disabled = not has_prev
	prev.pressed.connect(func(): navigation_requested.emit(-1))
	_design.add_child(prev)
	var next := Button.new()
	next.name = "Next"
	next.position = Vector2(3672, 1002)
	next.size = Vector2(168, 156)
	next.flat = true
	var next_icon := _texture_rect("page_right_0.png")
	next_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	next.add_child(next_icon)
	next.disabled = not has_next
	next.pressed.connect(func(): navigation_requested.emit(1))
	_design.add_child(next)


func _add_showed_gallery_card() -> void:
	# [SRC: AddShowedGalleryCard 0x543c80 writes GalleryData.id to the
	# process Global, saves it, then selects the first PlotItem.]
	if _global_state != null:
		_global_state.mark_gallery_card_shown(int(_definition.get("id", 0)))
		_global_state.save()
	_plot_mask.visible = false


func _show_plot(plot: Dictionary) -> void:
	for child in _plot_content_list.get_children():
		child.queue_free()
	# [SRC: OnItemClicked 0x5456d0 creates one PlotContentItemController
	# for every PlotNode.data entry and swaps CardInfo -> PlotInfo.]
	for raw_data in plot.get("data", []):
		var data := raw_data as Dictionary
		if data == null:
			continue
		var item := VBoxContainer.new()
		item.name = "PlotContentItem_%s" % str(data.get("guid", ""))
		item.custom_minimum_size = Vector2(913, 0)
		var title := _label(str(data.get("plot_title", "")), 70)
		title.name = "Title"
		title.custom_minimum_size = Vector2(913, 84)
		item.add_child(title)
		var content := _label(str(data.get("plot_text", "")), 50)
		content.name = "Content"
		content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.custom_minimum_size = Vector2(913, 0)
		item.add_child(content)
		_plot_content_list.add_child(item)
	_basic_content.visible = false
	_plot_content.visible = true


func _show_basic_content() -> void:
	_plot_content.visible = false
	_basic_content.visible = true


func _change_icon(index: int) -> void:
	# [SRC: Show 0x5465f0 prepends ResourceNode(GetPic(card), card.rare),
	# then AddRange(GalleryData.resources); ChangeIcon 0x544210 switches both
	# sprite and resource rare frame at the same index.]
	var resources := _image_resources()
	if index < 0 or index >= resources.size() or _main_icon == null:
		return
	var resource := resources[index] as Dictionary
	var path := _resource_asset_path(str(resource.get("pic_res", "")))
	if ResourceLoader.exists(path):
		_main_icon.texture = load(path) as Texture2D
	if _rare_image != null:
		var rare_path := SOURCE_UI + _rare_texture_name(int(resource.get("rare", _initial_rare())))
		if ResourceLoader.exists(rare_path):
			_rare_image.texture = load(rare_path) as Texture2D
	for marker_index in _head_markers.size():
		_head_markers[marker_index].visible = marker_index == index


func _card_resource_path(index: int) -> String:
	var resources := _image_resources()
	if index >= 0 and index < resources.size():
		var resource := resources[index] as Dictionary
		var path := _resource_asset_path(str(resource.get("pic_res", "")))
		if ResourceLoader.exists(path):
			return path
	return "res://assets/original/cards/%d.png" % int(_card.get("id", 0))


func _image_resources() -> Array:
	var resources: Array = []
	var card_resource = _card.get("resource", "cards/%d" % int(_card.get("id", 0)))
	var current_pic := ""
	if card_resource is Array and not (card_resource as Array).is_empty():
		current_pic = str((card_resource as Array)[0])
	else:
		current_pic = str(card_resource)
	resources.append({"pic_res": current_pic, "rare": _initial_rare()})
	for raw_resource in _definition.get("resources", []):
		if raw_resource is Dictionary:
			resources.append(raw_resource)
	return resources


func _initial_rare() -> int:
	return clampi(int(_card.get("rare", 1)), 1, 4)


func _rare_texture_name(rare: int) -> String:
	match clampi(rare, 1, 4):
		1:
			return "cardinfo_stone.png"
		2:
			return "cardinfo_copper.png"
		3:
			return "cardinfo_silver.png"
		_:
			return "cardinfo_gold.png"


func _resource_asset_path(resource: String) -> String:
	return "res://assets/original/%s.png" % resource


func _card_art(path: String) -> TextureRect:
	var rect := TextureRect.new()
	if ResourceLoader.exists(path):
		rect.texture = load(path) as Texture2D
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _texture_rect(file_name: String) -> TextureRect:
	var rect := TextureRect.new()
	var path := SOURCE_UI + file_name
	if ResourceLoader.exists(path):
		rect.texture = load(path) as Texture2D
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _texture_style(file_name: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	var path := SOURCE_UI + file_name
	if ResourceLoader.exists(path):
		style.texture = load(path) as Texture2D
	return style


func _solid_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	return style


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#f0dfba"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _place(parent: Control, rect: Rect2, child: Control) -> void:
	child.position = rect.position
	child.size = rect.size
	parent.add_child(child)
