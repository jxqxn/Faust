## A small visual card for hand/inventory display.
## Shows the card name, type, rarity dots, and key attribute tags.
class_name CardWidget
extends PanelContainer

const FaustTheme = preload("res://ui/theme.gd")

var _card: Dictionary = {}


func set_card(card: Dictionary) -> void:
	_card = card
	_rebuild()


func _ready() -> void:
	add_theme_stylebox_override("panel", _style_for_type())


func _style_for_type() -> StyleBoxFlat:
	var t := str(_card.get("type", ""))
	var accent := FaustTheme.BORDER
	match t:
		"char":
			accent = FaustTheme.GOLD
		"item":
			accent = Color("#7a8aa0")
		"sudan":
			accent = FaustTheme.DANGER_LIGHT
	return FaustTheme.card_style(accent)


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	var t := str(_card.get("type", ""))
	var name := str(_card.get("name", "?"))
	var rare := int(_card.get("rare", 0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	var title := Label.new()
	title.text = name
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	col.add_child(title)
	var meta := Label.new()
	var dots := "●".repeat(clampi(rare, 0, 5))
	var type_cn := _type_label(t)
	meta.text = "%s %s" % [type_cn, dots]
	meta.add_theme_font_size_override("font_size", 11)
	meta.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	col.add_child(meta)
	var attrs: Array = ["体魄", "魅力", "智慧", "社交", "理智"]
	var tag: Dictionary = _card.get("tag", {})
	var attr_texts: Array = []
	for a in attrs:
		var v := int(tag.get(a, 0))
		if v != 0:
			attr_texts.append("%s%d" % [a, v])
	var traits: Array = []
	for k in tag:
		if k in attrs:
			continue
		var v2 := int(tag[k])
		if v2 != 0:
			traits.append(k)
	if not attr_texts.is_empty():
		var al := Label.new()
		al.text = " ".join(attr_texts)
		al.add_theme_font_size_override("font_size", 12)
		al.add_theme_color_override("font_color", FaustTheme.TEXT)
		col.add_child(al)
	if not traits.is_empty():
		var tl := Label.new()
		tl.text = " ".join(traits.slice(0, 4))
		tl.add_theme_font_size_override("font_size", 11)
		tl.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
		col.add_child(tl)
	add_child(col)


static func _type_label(t: String) -> String:
	match t:
		"char":
			return "角色"
		"item":
			return "道具"
		"sudan":
			return "苏丹"
		_:
			return t


## Build a standalone card widget from a card dictionary.
static func make(card: Dictionary) -> CardWidget:
	var w := CardWidget.new()
	w.custom_minimum_size = Vector2(150, 110)
	w.set_card(card)
	return w
