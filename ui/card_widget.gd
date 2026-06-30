## A small visual card for hand/inventory display.
## Shows the card name, type, rarity dots, and key attribute tags.
class_name CardWidget
extends PanelContainer

const FaustTheme = preload("res://ui/theme.gd")

const CARD_SIZE := Vector2(116, 178)

var _card: Dictionary = {}
var card_id: int = 0


func set_card(card: Dictionary) -> void:
	_card = card
	card_id = int(card.get("id", card_id))
	_rebuild()


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
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


func _get_drag_data(_at_position: Vector2) -> Variant:
	if card_id <= 0:
		return null
	var preview := CardWidget.make(_card.duplicate(true))
	preview.card_id = card_id
	preview.modulate = Color(1, 1, 1, 0.82)
	var preview_root := Control.new()
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_root.custom_minimum_size = CARD_SIZE
	preview.position = -_at_position
	preview_root.add_child(preview)
	set_drag_preview(preview_root)
	return {
		"type": "card",
		"card_id": card_id,
		"card": _card.duplicate(true),
	}


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	var t := str(_card.get("type", ""))
	var name := str(_card.get("name", "?"))
	var rare := int(_card.get("rare", 0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = name
	_fit_card_label(title)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	col.add_child(title)
	var meta := Label.new()
	var dots := "●".repeat(clampi(rare, 0, 5))
	var type_cn := _type_label(t)
	meta.text = "%s %s" % [type_cn, dots]
	_fit_card_label(meta)
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
		_fit_card_label(al)
		al.add_theme_font_size_override("font_size", 12)
		al.add_theme_color_override("font_color", FaustTheme.TEXT)
		col.add_child(al)
	if not traits.is_empty():
		var tl := Label.new()
		tl.text = " ".join(traits.slice(0, 4))
		_fit_card_label(tl)
		tl.add_theme_font_size_override("font_size", 11)
		tl.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
		col.add_child(tl)
	add_child(col)


static func _fit_card_label(label: Label) -> void:
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2.ZERO
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


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
	w.custom_minimum_size = CARD_SIZE
	w.card_id = int(card.get("id", 0))
	w.set_card(card)
	return w
