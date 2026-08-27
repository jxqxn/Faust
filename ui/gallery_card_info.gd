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
		button.text = str(plot.get("title", ""))
		button.custom_minimum_size = Vector2(880, 92)
		button.add_theme_font_size_override("font_size", 42)
		button.pressed.connect(func(): _show_plot(plot))
		list.add_child(button)

	_plot_mask = Control.new()
	_plot_mask.name = "PlotMask"
	_plot_mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	_plot_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	var mask_panel := Panel.new()
	mask_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask_panel.add_theme_stylebox_override("panel", _solid_style(Color(0.035, 0.025, 0.02, 0.94)))
	_plot_mask.add_child(mask_panel)
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
	var resources := _definition.get("resources", []) as Array
	if resources.is_empty():
		return
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
		toggle.text = str(index + 1)
		toggle.add_theme_font_size_override("font_size", 30)
		toggle.pressed.connect(func(): _change_icon(index))
		heads.add_child(toggle)


func _build_card_info() -> void:
	var rare := _texture_rect("cardinfo_gold.png")
	rare.name = "Rare"
	_place(_card_info, Rect2(2173.26, 441.865, 370, 1063), rare)
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
	back.text = "返回"
	back.position = Vector2(372.5, 1260)
	back.size = Vector2(168, 160)
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
	var tags := _card.get("tag", {}) as Dictionary
	var attrs := ["体魄", "魅力", "智慧", "战斗", "社交", "支持"]
	var attr_line := _label("", 32)
	attr_line.name = "AttributeContents"
	var attr_text: Array[String] = []
	for key in attrs:
		if int(tags.get(key, 0)) != 0:
			attr_text.append("%s %d" % [key, int(tags[key])])
	attr_line.text = "　".join(attr_text)
	_place(parent, Rect2(0, 650, 930, 70), attr_line)
	var tag_line := _label("", 30)
	tag_line.name = "TagContents"
	var tag_text: Array[String] = []
	for key in tags.keys():
		if key not in attrs and int(tags[key]) != 0:
			tag_text.append(str(key))
	tag_line.text = "　".join(tag_text)
	tag_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(parent, Rect2(0, 750, 930, 220), tag_line)


func _build_navigation(has_prev: bool, has_next: bool) -> void:
	var prev := Button.new()
	prev.name = "Prev"
	prev.position = Vector2(0, 1002)
	prev.size = Vector2(168, 156)
	prev.text = "‹"
	prev.disabled = not has_prev
	prev.add_theme_font_size_override("font_size", 72)
	prev.pressed.connect(func(): navigation_requested.emit(-1))
	_design.add_child(prev)
	var next := Button.new()
	next.name = "Next"
	next.position = Vector2(3672, 1002)
	next.size = Vector2(168, 156)
	next.text = "›"
	next.disabled = not has_next
	next.add_theme_font_size_override("font_size", 72)
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
	var resources := _definition.get("resources", []) as Array
	if index < 0 or index >= resources.size() or _main_icon == null:
		return
	var resource := resources[index] as Dictionary
	var path := _resource_asset_path(str(resource.get("pic_res", "")))
	if ResourceLoader.exists(path):
		_main_icon.texture = load(path) as Texture2D


func _card_resource_path(index: int) -> String:
	var resources := _definition.get("resources", []) as Array
	if index >= 0 and index < resources.size():
		var resource := resources[index] as Dictionary
		var path := _resource_asset_path(str(resource.get("pic_res", "")))
		if ResourceLoader.exists(path):
			return path
	return "res://assets/original/cards/%d.png" % int(_card.get("id", 0))


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
