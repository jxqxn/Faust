## Original title-screen fate-point shop.
##
## Content is read directly from content/upgrade.json.  This controller owns
## the same purchase/activation transitions as PointShopController; it does
## not introduce a clone-side shop model.
## [SRC: decompiled/PointShopController.c @ OnEnable/RefreshItemContainer/
##       OnBuy/OnActivate/OnDeactivate (RVA 0x580840/0x580cc0/0x5802d0/
##       0x580090/0x5805e0); Resources/prefab/Shop.prefab;
##       dump.cs:322991-323070]
class_name PointShopController
extends Control

signal closed()

const ConditionEvalScript = preload("res://sim/condition.gd")
const ItemControllerScript = preload("res://ui/point_shop_item_controller.gd")
const DESIGN_SPACE := Vector2(3840, 2160)
const SOURCE_ART := "res://assets/original/ui/"

var _db: ConfigDB
var _global: GlobalState
var _design: Control
var _items: VBoxContainer
var _point_count: Label
var _only_bought: Button
var _only_unbought: Button
var _rows: Dictionary = {}
var _ui: Dictionary = {}


func setup(config_db: ConfigDB, global_state: GlobalState) -> void:
	_db = config_db
	_global = global_state


func _ready() -> void:
	name = "PointShopController"
	theme = FaustTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://content/ui.json"))
	if parsed is Dictionary:
		_ui = parsed
	_build_source_surface()
	refresh_item_container()


func _build_source_surface() -> void:
	_design = Control.new()
	_design.name = "Shop"
	_design.size = DESIGN_SPACE
	add_child(_design)
	resized.connect(_layout_design)
	call_deferred("_layout_design")
	_design.add_child(_texture_rect("Background", Rect2(Vector2.ZERO, DESIGN_SPACE), "bg_6.png"))
	_build_close()
	_build_desc_group()
	_build_item_scroll()


func _layout_design() -> void:
	if _design == null:
		return
	var view_size := size
	if view_size.x <= 0 or view_size.y <= 0:
		view_size = get_viewport().get_visible_rect().size
	_design.scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _build_close() -> void:
	var close := TextureButton.new()
	close.name = "Close"
	close.position = Vector2(3717.4, 45.6)
	close.size = Vector2(80, 82)
	close.ignore_texture_size = true
	close.stretch_mode = TextureButton.STRETCH_SCALE
	close.texture_normal = _source_texture("checkbox_bg.png")
	close.pressed.connect(func(): closed.emit())
	_design.add_child(close)
	close.add_child(_texture_rect("x", Rect2(18.5, 22.5, 43, 37), "close_2.png"))


func _build_desc_group() -> void:
	var group := Control.new()
	group.name = "DescGroup"
	group.position = Vector2(246, 230)
	group.size = Vector2(996.78, 1700)
	_design.add_child(group)
	group.add_child(_texture_rect("Title Icon", Rect2(0, 0, 128, 118), "icon_0.png"))
	group.add_child(_label("Title", _ui_text("POINT_SHOP_TITLE", "命运商店"), Rect2(148, 0, 520, 120), 70))
	group.add_child(_texture_rect("Point Icon", Rect2(730, 10, 100, 100), "point_0.png"))
	_point_count = _label("Point Count", "0", Rect2(850, 0, 146, 120), 50)
	group.add_child(_point_count)
	group.add_child(_texture_rect("Seperator", Rect2(0, 220, 996.78, 6), "slash.png"))

	var description := RichTextLabel.new()
	description.name = "Content"
	description.position = Vector2(0, 246)
	description.size = Vector2(980, 1100)
	description.bbcode_enabled = true
	description.fit_content = true
	description.scroll_active = true
	description.add_theme_font_size_override("normal_font_size", 50)
	description.text = _tmp_to_bbcode(_ui_text("POINT_SHOP_DESC", ""))
	group.add_child(description)

	_only_bought = _filter_toggle("OnlyBuy", _ui_text("POINT_SHOP_TOGGLE_ONLY_BUY", "只看已购买"))
	_only_bought.position = Vector2(0, 1600)
	_only_bought.size = Vector2(330, 100)
	_only_bought.toggled.connect(func(_on: bool):
		if _only_bought.button_pressed:
			_only_unbought.set_pressed_no_signal(false)
			_set_toggle_mark(_only_unbought)
		_set_toggle_mark(_only_bought)
		refresh_item_container())
	group.add_child(_only_bought)

	_only_unbought = _filter_toggle("OnlyUnBuy", _ui_text("POINT_SHOP_TOGGLE_ONLY_UNBUY", "只看未购买"))
	_only_unbought.position = Vector2(350, 1600)
	_only_unbought.size = Vector2(360, 100)
	_only_unbought.toggled.connect(func(_on: bool):
		if _only_unbought.button_pressed:
			_only_bought.set_pressed_no_signal(false)
			_set_toggle_mark(_only_bought)
		_set_toggle_mark(_only_unbought)
		refresh_item_container())
	group.add_child(_only_unbought)


func _build_item_scroll() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll View"
	scroll.position = Vector2(1332.12, 127.6)
	scroll.size = Vector2(2400, 1901.4)
	_design.add_child(scroll)
	_items = VBoxContainer.new()
	_items.name = "Content"
	_items.custom_minimum_size = Vector2(2301, 0)
	_items.add_theme_constant_override("separation", 0)
	scroll.add_child(_items)


func refresh_item_container() -> void:
	if _db == null or _global == null or _items == null:
		return
	_rows.clear()
	for child in _items.get_children():
		child.queue_free()
	for raw_upgrade in _db.upgrades.values():
		var upgrade := raw_upgrade as Dictionary
		var upgrade_id := int(upgrade.get("id", 0))
		var purchased := _global.upgrades.has(upgrade_id)
		if _only_bought != null and _only_bought.button_pressed and not purchased:
			continue
		if _only_unbought != null and _only_unbought.button_pressed and purchased:
			continue
		if not _is_visible(upgrade):
			continue
		var row = ItemControllerScript.new()
		row.setup(_db, upgrade, purchased, purchased and int(_global.upgrades[upgrade_id]) != 0,
			int(upgrade.get("cost", 0)) <= _global.total_point)
		row.buy_requested.connect(on_buy)
		row.activate_requested.connect(on_activate)
		row.deactivate_requested.connect(func(value): on_deactivate(value, true))
		_items.add_child(row)
		_rows[upgrade_id] = row
	_point_count.text = str(_global.total_point)


func _is_visible(upgrade: Dictionary) -> bool:
	var condition: Dictionary = upgrade.get("condition", {})
	return condition.is_empty() or ConditionEvalScript.evaluate(condition, {
		"db": _db,
		"global_state": _global,
	})


func on_buy(row: PointShopItemController) -> bool:
	var upgrade_id := int(row.item.get("id", 0))
	var cost := int(row.item.get("cost", 0))
	if _global.upgrades.has(upgrade_id) or _global.total_point < cost:
		return false
	_global.upgrades[upgrade_id] = 1
	_global.total_point -= cost
	_global.used_point += cost
	_global.save()
	refresh_item_container()
	return true


func on_activate(row: PointShopItemController) -> bool:
	var upgrade_id := int(row.item.get("id", 0))
	if not _global.upgrades.has(upgrade_id) or int(_global.upgrades[upgrade_id]) != 0:
		return false
	_global.upgrades[upgrade_id] = 1
	_global.save()
	refresh_item_container()
	return true


func on_deactivate(row: PointShopItemController, _prompt := true) -> bool:
	var upgrade_id := int(row.item.get("id", 0))
	if not _global.upgrades.has(upgrade_id) or int(_global.upgrades[upgrade_id]) == 0:
		return false
	_global.upgrades[upgrade_id] = 0
	_global.save()
	refresh_item_container()
	return true


func _label(node_name: String, copy: String, rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = copy
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _filter_toggle(node_name: String, copy: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.toggle_mode = true
	button.text = ""
	var empty := StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(style_name, empty)
	button.add_child(_texture_rect("Background", Rect2(0, 9, 80, 82), "checkbox_bg.png"))
	var mark := _texture_rect("Checkmark", Rect2(19.5, 33, 41, 34), "checkbox_selected.png")
	mark.visible = false
	button.add_child(mark)
	button.add_child(_label("Text", copy, Rect2(90, 0, 240, 100), 36))
	return button


func _set_toggle_mark(button: Button) -> void:
	var mark := button.get_node_or_null("Checkmark") as CanvasItem
	if mark != null:
		mark.visible = button.button_pressed


func _texture_rect(node_name: String, rect: Rect2, texture_name: String) -> TextureRect:
	var view := TextureRect.new()
	view.name = node_name
	view.position = rect.position
	view.size = rect.size
	view.texture = _source_texture(texture_name)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


func _source_texture(texture_name: String) -> Texture2D:
	var path := SOURCE_ART + texture_name
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _ui_text(key: String, fallback: String) -> String:
	var row := _ui.get(key, {}) as Dictionary
	return str(row.get("zhCN", fallback))


func _tmp_to_bbcode(source: String) -> String:
	var out := source.replace("<align=center>", "[center]").replace("</align>", "[/center]")
	out = out.replace("<size=160>", "[font_size=160]").replace("</size>", "[/font_size]")
	# TMP sprite glyphs have no textual substitute; the corresponding source
	# icons are already present elsewhere on the panel.
	var sprite_regex := RegEx.new()
	sprite_regex.compile("<sprite=[^>]+>")
	out = sprite_regex.sub(out, "", true)
	var indent_regex := RegEx.new()
	indent_regex.compile("</?indent[^>]*>")
	return indent_regex.sub(out, "", true)
