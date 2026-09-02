## Original PointShopItemController item surface.
##
## The raw UpgradeNode dictionary remains the data object.  Purchased and
## active are separate source states: key membership versus value != 0.
## [SRC: decompiled/PointShopItemController.c @ Init/UpdateShowState/
##       UpdateBuyState (RVA 0x581f20/0x582900/0x582860);
##       Resources/prefab/ShopItem.prefab; dump.cs:323149-323200]
class_name PointShopItemController
extends Control

signal buy_requested(item: PointShopItemController)
signal activate_requested(item: PointShopItemController)
signal deactivate_requested(item: PointShopItemController)

const SOURCE_ART := "res://assets/original/ui/"
const SOURCE_SIZE := Vector2(2301, 400)
const CardWidgetScript = preload("res://ui/card_widget.gd")

var item: Dictionary = {}
var _db: ConfigDB
var purchased := false
var active := false
var _highlight: TextureRect
var _activated: TextureRect
var _buy: TextureButton
var _activate: TextureButton
var _deactivate: TextureButton


func setup(config_db: ConfigDB, upgrade: Dictionary, has_bought: bool, is_active: bool, affordable: bool) -> void:
	_db = config_db
	item = upgrade
	purchased = has_bought
	active = is_active
	custom_minimum_size = SOURCE_SIZE
	size = SOURCE_SIZE
	_build(affordable)


func set_purchase_state(has_bought: bool, is_active: bool, affordable: bool) -> void:
	purchased = has_bought
	active = is_active
	_activated.visible = purchased and active
	_buy.visible = not purchased
	_buy.disabled = not affordable
	_activate.visible = purchased and not active
	_deactivate.visible = purchased and active


func _build(affordable: bool) -> void:
	for child in get_children():
		child.queue_free()

	_highlight = _texture_rect("highlight", Rect2(679, 25, 1622, 360), "hightlight.png")
	_highlight.visible = false
	add_child(_highlight)
	mouse_entered.connect(func(): _highlight.visible = true)
	mouse_exited.connect(func(): _highlight.visible = false)
	_activated = _texture_rect("activated", Rect2(0, 25, 2301, 360), "activate_bg.png")
	add_child(_activated)
	add_child(_texture_rect("footer", Rect2(2, 370, 2297, 30), "slash.png"))
	add_child(_texture_rect("IconBG", Rect2(108, 53.5, 444, 431), "promp_item_bg.png"))
	var type_name := str(item.get("icon", "gain"))
	add_child(_texture_rect("Type", Rect2(34, 76, 232, 236), "item_%s.png" % type_name))
	_build_link_card()

	var title := _label("Title", str(item.get("name", "")), Rect2(628, 74, 1186.41, 80), 50)
	add_child(title)
	var desc := _label("Desc", str(item.get("text", "")), Rect2(628, 164.26, 1226.77, 204.74), 34)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(desc)

	_buy = _action_button("Buy", "", "button_bg_0.png")
	var point := _texture_rect("Icon", Rect2(28, 29, 100, 100), "point_0.png")
	_buy.add_child(point)
	var cost := _label("Cost", str(int(item.get("cost", 0))), Rect2(139.84, 0, 185.16, 158), 60)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_buy.add_child(cost)
	_buy.pressed.connect(func(): buy_requested.emit(self))

	_activate = _action_button("Activate", "激活", "activate_button.png")
	_activate.pressed.connect(func(): activate_requested.emit(self))
	_deactivate = _action_button("Deactivate", "关闭", "button_bg_0.png")
	_deactivate.pressed.connect(func(): deactivate_requested.emit(self))
	set_purchase_state(purchased, active, affordable)


func _build_link_card() -> void:
	var link_card := int(item.get("link_card", 0))
	if _db == null or link_card <= 0:
		return
	var definition := _db.get_card(link_card)
	if definition.is_empty():
		return
	# DelaySetup creates CardController(link_card_inst) under the authored
	# Icon/Card transform. Preserve that transform and native CardNew size.
	# [SRC: PointShopItemController.c @ DelaySetup (RVA 0x5819e0);
	#       ShopItem.prefab Icon/Card]
	var host := Control.new()
	host.name = "Card"
	host.position = Vector2(348, 190)
	host.size = Vector2(100, 100)
	host.pivot_offset = Vector2(50, 50)
	host.rotation_degrees = 20
	add_child(host)
	var card = CardWidgetScript.make(definition, "shop")
	card.position = Vector2(-47, -161)
	card._drag_preview = true
	host.add_child(card)


func _action_button(node_name: String, copy: String, texture_name: String) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.position = Vector2(1888, 136.5)
	button.size = Vector2(325, 158)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = _source_texture(texture_name)
	add_child(button)
	if not copy.is_empty():
		var text := _label("Text", copy, Rect2(30, 0, 265, 158), 60)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_child(text)
	return button


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
