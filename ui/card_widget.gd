## A compact visual card for hand, table slots, and drag previews.
## The desktop card face intentionally shows only the card name, a placeholder
## image block, and rarity color, matching the original at this zoom level.
class_name CardWidget
extends PanelContainer

signal clicked(card_id: int, card: Dictionary)

const CARD_SIZE := Vector2(104, 160)

var _card: Dictionary = {}
var card_id: int = 0
var drag_source := "hand"
var drag_slot := ""
var _press_position := Vector2.ZERO
var _hidden_for_drag := false


func set_card(card: Dictionary) -> void:
	_card = card
	card_id = int(card.get("id", card_id))
	_rebuild()


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_theme_stylebox_override("panel", _style_for_card())


func _style_for_card() -> StyleBoxFlat:
	return FaustTheme.card_style(_rarity_color(int(_card.get("rare", 0)), str(_card.get("type", ""))))


func _get_drag_data(at_position: Vector2) -> Variant:
	if card_id <= 0:
		return null
	var preview := CardWidget.make(_card.duplicate(true), drag_source, drag_slot)
	preview.card_id = card_id
	preview.modulate = Color(1, 1, 1, 0.86)
	var preview_root := Control.new()
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_root.custom_minimum_size = CARD_SIZE
	# Preserve the pointer-to-card offset from the moment dragging begins.
	preview.position = -at_position
	preview_root.add_child(preview)
	set_drag_preview(preview_root)
	_hide_source_for_drag()
	return {
		"type": "card",
		"card_id": card_id,
		"card": _card.duplicate(true),
		"source": drag_source,
		"source_slot": drag_slot,
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _hidden_for_drag:
		var drag_succeeded := get_viewport() != null and get_viewport().gui_is_drag_successful()
		if drag_succeeded:
			_hidden_for_drag = false
		else:
			_restore_source_after_failed_drag()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var target := _drop_delegate()
	if target == null or not target.has_method("_can_drop_data"):
		return false
	return target._can_drop_data(target.get_local_mouse_position() if target is Control else at_position, data)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var target := _drop_delegate()
	if target != null and target.has_method("_drop_data"):
		target._drop_data(target.get_local_mouse_position() if target is Control else at_position, data)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_position = event.position
		elif event.position.distance_to(_press_position) <= 8.0:
			clicked.emit(card_id, _card.duplicate(true))


func _drop_delegate() -> Control:
	var p := get_parent()
	while p != null:
		if p != self and p.has_method("_can_drop_data") and p.has_method("_drop_data"):
			return p as Control
		if p.has_method("can_drop_card_to_hand") and p.has_method("drop_card_to_hand"):
			return p as Control
		p = p.get_parent()
	return null


func _hide_source_for_drag() -> void:
	_hidden_for_drag = true
	visible = false


func _restore_source_after_failed_drag() -> void:
	_hidden_for_drag = false
	visible = true


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	add_theme_stylebox_override("panel", _style_for_card())
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(col)

	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = str(_card.get("name", "?"))
	_fit_card_label(title)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	col.add_child(title)

	var art := ColorRect.new()
	art.name = "CardArt"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.color = Color("#141515")
	art.custom_minimum_size = Vector2(88, 112)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(art)


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


static func _rarity_color(rare: int, card_type: String = "") -> Color:
	if card_type == "sudan":
		return FaustTheme.DANGER_LIGHT
	match clampi(rare, 0, 4):
		0, 1:
			return Color("#b28755")
		2:
			return Color("#bcc7d4")
		3:
			return FaustTheme.GOLD_BRIGHT
		_:
			return Color("#d9d3ff")


## Build a standalone card widget from a card dictionary.
static func make(card: Dictionary, source: String = "hand", slot_key: String = "") -> CardWidget:
	var w := CardWidget.new()
	w.custom_minimum_size = CARD_SIZE
	w.card_id = int(card.get("id", 0))
	w.drag_source = source
	w.drag_slot = slot_key
	w.set_card(card)
	return w
