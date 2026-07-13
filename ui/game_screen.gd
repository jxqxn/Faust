## Main in-game desk screen.
## Layout mirrors docs/mockups/game-screen-layout.html: a top HUD, a broad
## desk/map area, and a bottom card rail beside the day/action controls.
extends Control

signal open_rite(rite_id: int)
signal open_rite_instance(rite_uid: int)
signal advance_pressed()
signal redraw_pressed()
signal open_rite_selector(location_name: String)
signal menu_pressed()
signal game_over_requested()

class HandRailDrop:
	extends ScrollContainer

	var owner_screen: Control

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return owner_screen != null and owner_screen.has_method("can_drop_card_to_hand") and owner_screen.can_drop_card_to_hand(data)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if owner_screen != null and owner_screen.has_method("drop_card_to_hand"):
			owner_screen.drop_card_to_hand(data, get_local_mouse_position())


class MethinksDrop:
	extends PanelContainer

	var owner_screen: Control

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return owner_screen != null and owner_screen.has_method("can_drop_card_on_methinks") and owner_screen.can_drop_card_on_methinks(data)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if owner_screen != null and owner_screen.has_method("drop_card_on_methinks"):
			owner_screen.drop_card_on_methinks(data)

const MOCKUP_SIZE := Vector2(1280, 720)

var _state
var _db
var _rng

var _round_label: Label
var _gold_label: Label
var _log_label: Label
var _hud: PanelContainer
var _menu_button: Button
var _desk_map: PanelContainer
var _map_content: Control
var _overlay_layer: Control
var _methinks_target: PanelContainer
var _rail_label: VBoxContainer
var _card_rail_view: ScrollContainer
var _card_items: HBoxContainer
var _right_actions: VBoxContainer
var _advance_button: Button
var _site_buttons: Array[Button] = []
var _rite_pin_buttons: Array[Button] = []
var _rite_pin_ids: Dictionary = {}
var _card_detail_overlay: Control
var _card_detail_panel: Panel
var _card_detail_card_id := 0
var _event_overlay: Control
var _event_panel: Panel


func setup(state, db, rng) -> void:
	_state = state
	_db = db
	_rng = rng


func _ready() -> void:
	theme = FaustTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	resized.connect(_apply_layout)
	call_deferred("_apply_layout")
	refresh()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = FaustTheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_hud = _panel("Hud")
	add_child(_hud)
	var hud_row := HBoxContainer.new()
	hud_row.add_theme_constant_override("separation", 24)
	hud_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_row.offset_left = 18
	hud_row.offset_right = -18
	_hud.add_child(hud_row)

	_round_label = _stat_label()
	hud_row.add_child(_round_label)
	_gold_label = _stat_label()
	hud_row.add_child(_gold_label)

	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	_menu_button.text = "菜单"
	_menu_button.flat = true
	_menu_button.add_theme_font_size_override("font_size", 18)
	_menu_button.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	_menu_button.pressed.connect(func(): menu_pressed.emit())
	add_child(_menu_button)

	_desk_map = _panel("DeskMap")
	add_child(_desk_map)
	_map_content = Control.new()
	_map_content.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_map_content.clip_contents = true
	add_child(_map_content)

	var site_specs := [
		{"name": "SiteHome", "label": "自宅", "location": "自宅"},
		{"name": "SiteMarket", "label": "商业区", "location": "商业区"},
		{"name": "SitePalace", "label": "宫廷", "location": "宫廷"},
		{"name": "SiteTemple", "label": "神殿区", "location": "神殿区"},
		{"name": "SiteWild", "label": "野外", "location": "野外"},
	]
	for spec in site_specs:
		var site := _site_button(str(spec["label"]))
		site.name = str(spec["name"])
		var location_name := str(spec["location"])
		site.pressed.connect(_on_site_pressed.bind(location_name))
		_site_buttons.append(site)
		_map_content.add_child(site)

	_methinks_target = MethinksDrop.new()
	_methinks_target.name = "MethinksDropTarget"
	(_methinks_target as MethinksDrop).owner_screen = self
	_methinks_target.add_theme_stylebox_override("panel", _methinks_style())
	_map_content.add_child(_methinks_target)
	var methinks_label := Label.new()
	methinks_label.name = "MethinksLabel"
	methinks_label.text = "俺寻思"
	methinks_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	methinks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	methinks_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	methinks_label.add_theme_font_size_override("font_size", 18)
	methinks_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	methinks_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_methinks_target.add_child(methinks_label)

	_log_label = Label.new()
	_log_label.name = "EventToast"
	_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_log_label.add_theme_font_size_override("font_size", 18)
	_log_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	_map_content.add_child(_log_label)

	_overlay_layer = Control.new()
	_overlay_layer.name = "OverlayLayer"
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_layer)

	_rail_label = VBoxContainer.new()
	_rail_label.name = "RailLabel"
	_rail_label.add_theme_constant_override("separation", 8)
	add_child(_rail_label)
	var rail_text := Label.new()
	rail_text.text = "统一卡牌栏"
	rail_text.add_theme_font_size_override("font_size", 14)
	rail_text.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	_rail_label.add_child(rail_text)
	for rank in ["I", "II", "III", "IV"]:
		var tab := Label.new()
		tab.text = rank
		tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab.custom_minimum_size = Vector2(34, 24)
		tab.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
		_rail_label.add_child(tab)

	_card_rail_view = HandRailDrop.new()
	_card_rail_view.name = "CardRail"
	(_card_rail_view as HandRailDrop).owner_screen = self
	_card_rail_view.clip_contents = true
	add_child(_card_rail_view)
	_card_items = HBoxContainer.new()
	_card_items.name = "CardRailItems"
	_card_items.add_theme_constant_override("separation", 10)
	_card_items.alignment = BoxContainer.ALIGNMENT_BEGIN
	_card_rail_view.add_child(_card_items)

	_right_actions = VBoxContainer.new()
	_right_actions.name = "RightActions"
	_right_actions.add_theme_constant_override("separation", 12)
	add_child(_right_actions)

	_advance_button = Button.new()
	_advance_button.name = "AdvanceDayButton"
	_advance_button.text = "下一天"
	_advance_button.custom_minimum_size = Vector2(132, 132)
	_advance_button.add_theme_font_size_override("font_size", 26)
	_advance_button.add_theme_stylebox_override("normal", _round_button_style())
	_advance_button.add_theme_stylebox_override("hover", _round_button_style(FaustTheme.GOLD_BRIGHT))
	_advance_button.add_theme_stylebox_override("pressed", _round_button_style(FaustTheme.BORDER))
	_advance_button.pressed.connect(func(): advance_pressed.emit())
	_right_actions.add_child(_advance_button)

	var redraw_btn := _icon_button("抽")
	redraw_btn.name = "RedrawSudanButton"
	redraw_btn.pressed.connect(func(): redraw_pressed.emit())
	_right_actions.add_child(redraw_btn)


func _apply_layout() -> void:
	if _hud == null:
		return
	var view_size := _effective_view_size()
	var s: float = min(view_size.x / MOCKUP_SIZE.x, view_size.y / MOCKUP_SIZE.y)

	_set_rect(_hud, Rect2(Vector2(22, 18) * s, Vector2(340, 44) * s))
	_set_rect(_menu_button, Rect2(Vector2(view_size.x - 78 * s, 22 * s), Vector2(52, 40) * s))
	_set_rect(_desk_map, Rect2(Vector2(34, 78) * s, Vector2(view_size.x - 68 * s, view_size.y - (78 + 238) * s)))
	_set_rect(_map_content, Rect2(_desk_map.position, _desk_map.size))
	_set_rect(_overlay_layer, Rect2(Vector2.ZERO, view_size))
	_set_rect(_rail_label, Rect2(Vector2(28 * s, view_size.y - 168 * s), Vector2(116 * s, 140 * s)))
	_set_rect(_card_rail_view, Rect2(Vector2(180 * s, view_size.y - 222 * s), Vector2(view_size.x - 360 * s, 202 * s)))
	_set_rect(_right_actions, Rect2(Vector2(view_size.x - 160 * s, view_size.y - 194 * s), Vector2(132 * s, 170 * s)))

	_card_items.custom_minimum_size = Vector2(_card_items.get_minimum_size().x, CardWidget.CARD_SIZE.y * s)
	_layout_map_content(s)
	_layout_card_detail(s, view_size)
	_layout_event_prompt(s, view_size)


func _effective_view_size() -> Vector2:
	if size.x > 0.0 and size.y > 0.0:
		return size
	var node := get_parent()
	while node != null:
		if node is Control:
			var control := node as Control
			if control.size.x > 0.0 and control.size.y > 0.0:
				return control.size
		node = node.get_parent()
	var viewport := get_viewport()
	if viewport != null:
		return viewport.get_visible_rect().size
	return MOCKUP_SIZE


func _layout_map_content(s: float) -> void:
	if _map_content == null:
		return
	var map_size := _map_content.size
	var site_size := Vector2(112, 34) * s
	var site_positions := [
		Vector2(0.11, 0.42),
		Vector2(0.33, 0.27),
		Vector2(0.48, 0.41),
		Vector2(0.63, 0.24),
		Vector2(0.73, 0.63),
	]
	for i in _site_buttons.size():
		var site := _site_buttons[i]
		site.size = site_size
		site.position = Vector2(map_size.x * site_positions[i].x, map_size.y * site_positions[i].y)
	_layout_rite_pins(s, map_size)
	if _methinks_target != null:
		_methinks_target.size = Vector2(126, 72) * s
		_methinks_target.position = Vector2(24, map_size.y - 104 * s)
	if _log_label != null:
		_log_label.size = Vector2(520, 34) * s
		_log_label.position = Vector2((map_size.x - _log_label.size.x) * 0.5, map_size.y - 58 * s)


func _set_rect(node: Control, rect: Rect2) -> void:
	node.position = rect.position.round()
	node.size = rect.size.round()


func _stat_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	return label


func _panel(node_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style())
	return panel


func _site_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(98, 34)
	return button


func _on_site_pressed(location_name: String) -> void:
	open_rite_selector.emit(location_name)


func _icon_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(62, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _round_button_style(border: Color = FaustTheme.GOLD) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#15100c")
	style.border_color = border
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 72
	style.corner_radius_top_right = 72
	style.corner_radius_bottom_left = 72
	style.corner_radius_bottom_right = 72
	return style


func _methinks_style(border: Color = FaustTheme.GOLD) -> StyleBoxFlat:
	var style := FaustTheme.card_style(border)
	style.bg_color = Color("#15100c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func _rite_pin_style(border: Color = FaustTheme.GOLD) -> StyleBoxFlat:
	var style := FaustTheme.card_style(border)
	style.bg_color = Color(0.08, 0.055, 0.04, 0.96)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	return style


func _rite_pin_hover_style() -> StyleBoxFlat:
	var style := _rite_pin_style(FaustTheme.GOLD_BRIGHT)
	style.bg_color = Color(0.13, 0.085, 0.045, 0.98)
	return style


func _refresh_rite_pins() -> void:
	if _map_content == null:
		return
	_clear_rite_pins()
	var pinned_rite_ids := {}
	for instance in _open_map_rite_instances():
		# Runtime rites have unique uids, but the original player's pin list is
		# `List<int>` and rejects a config id it already contains. Keep one map
		# entry per RiteNode id. The state resolves the panel target
		# deterministically when more than one runtime instance shares that id.
		# [SRC: PlayerExtensions.c @ AddRitePin (RVA 0x38c360)]
		if pinned_rite_ids.has(instance.id):
			continue
		pinned_rite_ids[instance.id] = true
		var rite: Dictionary = _db.rites.get(instance.id, {})
		var pin := Button.new()
		pin.name = "RitePin_%d" % instance.id
		pin.text = str(rite.get("name", str(instance.id)))
		pin.tooltip_text = str(rite.get("text", ""))
		pin.custom_minimum_size = Vector2(118, 34)
		pin.add_theme_font_size_override("font_size", 15)
		pin.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
		pin.add_theme_stylebox_override("normal", _rite_pin_style())
		pin.add_theme_stylebox_override("hover", _rite_pin_hover_style())
		pin.add_theme_stylebox_override("pressed", _rite_pin_style(FaustTheme.BORDER))
		pin.pressed.connect(_emit_open_rite_instance.bind(instance.uid))
		_rite_pin_buttons.append(pin)
		_rite_pin_ids[pin] = instance.uid
		_map_content.add_child(pin)
	_apply_layout()


func _emit_open_rite(rite_id: int) -> void:
	open_rite.emit(rite_id)


func _emit_open_rite_instance(rite_uid: int) -> void:
	open_rite_instance.emit(rite_uid)


func _clear_rite_pins() -> void:
	for pin in _rite_pin_buttons:
		if is_instance_valid(pin):
			if pin.get_parent() != null:
				pin.get_parent().remove_child(pin)
			pin.free()
	_rite_pin_buttons.clear()
	_rite_pin_ids.clear()


func _open_map_rite_instances() -> Array:
	var out: Array = []
	if _db == null or _state == null:
		return out
	if not _state.has_method("available_rite_instances"):
		return out
	for instance in _state.available_rite_instances():
		var rite: Dictionary = _db.rites.get(instance.id, {})
		if not _is_map_rite_interactive(rite):
			continue
		if not _is_map_rite_open(instance, rite):
			continue
		out.append(instance)
	out.sort_custom(func(a, b) -> bool: return a.uid < b.uid)
	return out


func _is_map_rite_interactive(rite: Dictionary) -> bool:
	return RiteOpen.is_interactive(rite)


func _is_map_rite_open(instance, rite: Dictionary) -> bool:
	if int(rite.get("auto_begin", 0)) == 1:
		return bool(instance.start)
	return RiteOpen.is_rite_open(rite, _state, _db, _rng)


func _layout_rite_pins(s: float, map_size: Vector2) -> void:
	var by_location: Dictionary = {}
	for pin in _rite_pin_buttons:
		if not is_instance_valid(pin):
			continue
		var rite_uid := int(_rite_pin_ids.get(pin, 0))
		var instance = _state.get_rite_instance(rite_uid) if _state != null and _state.has_method("get_rite_instance") else null
		var rite: Dictionary = _db.rites.get(instance.id, {}) if instance != null else {}
		var loc := _rite_location_name(rite)
		if not by_location.has(loc):
			by_location[loc] = []
		by_location[loc].append(pin)
	for loc in by_location.keys():
		var pins: Array = by_location[loc]
		for i in pins.size():
			var pin := pins[i] as Button
			var anchor := _map_location_anchor(loc)
			var col := i % 2
			var row := floori(float(i) / 2.0)
			var pin_size := Vector2(120, 34) * s
			pin.size = pin_size
			var raw := Vector2(
				map_size.x * anchor.x + (col * 128 + 6) * s,
				map_size.y * anchor.y + (46 + row * 40) * s
			)
			pin.position = Vector2(
				clamp(raw.x, 8.0 * s, max(8.0 * s, map_size.x - pin_size.x - 8.0 * s)),
				clamp(raw.y, 8.0 * s, max(8.0 * s, map_size.y - pin_size.y - 8.0 * s))
			)


func _rite_location_name(rite: Dictionary) -> String:
	return str(rite.get("location", "?")).split(":")[0]


func _map_location_anchor(location_name: String) -> Vector2:
	var anchors := {
		"自宅": Vector2(0.11, 0.42),
		"商业区": Vector2(0.33, 0.27),
		"宫廷": Vector2(0.48, 0.41),
		"神殿区": Vector2(0.63, 0.24),
		"野外": Vector2(0.73, 0.63),
	}
	return anchors.get(location_name, Vector2(0.48, 0.48))


func refresh() -> void:
	if _state == null or _card_items == null:
		return
	_round_label.text = "第 %d 天" % _state.day
	_gold_label.text = "金骰 %d    重抽 %d" % [_state.gold_dice, _state.redraws_left]
	for child in _card_items.get_children():
		child.queue_free()
	var life := int(_state.difficulty_config.get("sudan_life_time", 7))
	_state.sync_rail_order()
	for card_uid in _state.visible_rail_card_uids():
		var uid := int(card_uid)
		if _state.is_active_sudan_card(uid):
			var asc = _active_sudan_for_card(uid)
			if asc != null:
				_card_items.add_child(_make_sudan_card(asc, life))
			continue
		var card: Dictionary = _state.card_data_for(uid, _db)
		if card.is_empty():
			continue
		var widget := CardWidget.make(card, "hand")
		widget.custom_minimum_size = CardWidget.CARD_SIZE
		widget.clicked.connect(_show_card_detail)
		_card_items.add_child(widget)
	_refresh_rite_pins()
	_refresh_event_overlay()


func _active_sudan_for_card(card_or_uid: int) -> Variant:
	for asc in _state.active_sudan_cards:
		if int(asc.card_id) == card_or_uid or int(asc.card_uid) == card_or_uid:
			return asc
	return null


func _make_sudan_card(asc, life: int) -> CardWidget:
	var dec = SudanCards.decode(int(asc.card_id))
	var card: Dictionary = _state.card_data_for(int(asc.card_uid), _db)
	if card.is_empty():
		# Legacy fixtures may construct an ActiveSudan directly. Runtime play
		# always has card_uid, but keep this display-only fallback harmless.
		card = _db.get_card(int(asc.card_id)).duplicate(true)
		card["instance_uid"] = int(asc.card_uid)
	card["id"] = int(asc.card_id)
	card["type"] = "sudan"
	card["name"] = "%s%s" % [dec.rank, dec.action]
	var widget := CardWidget.make(card, "active_sudan")
	widget.custom_minimum_size = CardWidget.CARD_SIZE
	widget.clip_contents = false
	widget.clicked.connect(_show_card_detail)
	var days := Label.new()
	days.name = "SudanCountdown"
	days.text = str(int(asc.days_left))
	days.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	days.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	days.position = Vector2(CardWidget.CARD_SIZE.x - 38, -20)
	days.size = Vector2(28, 24)
	days.add_theme_font_size_override("font_size", 18)
	days.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	days.add_theme_color_override("font_shadow_color", Color("#100c0a"))
	days.add_theme_constant_override("shadow_offset_x", 1)
	days.add_theme_constant_override("shadow_offset_y", 1)
	widget.add_child(days)
	return widget


func can_drop_card_to_hand(data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	if str(data.get("type", "")) != "card":
		return false
	var source := str(data.get("source", ""))
	return source == "slot" or source == "hand" or source == "active_sudan"


func can_drop_card_on_methinks(data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	if str(data.get("type", "")) != "card":
		return false
	var source := str(data.get("source", ""))
	return source == "hand" or source == "active_sudan"


func drop_card_on_methinks(data: Variant) -> void:
	if not can_drop_card_on_methinks(data):
		return
	var card_uid := int(data.get("card_uid", data.get("card_id", 0)))
	var source := str(data.get("source", ""))
	var result: Dictionary = MethinksEngine.process_card(card_uid, source, _state, _db, _rng)
	set_log(str(result.get("message", "")))
	refresh()
	var deferred: Dictionary = result.get("deferred", {})
	if bool(deferred.get("over", false)):
		game_over_requested.emit()


func drop_card_to_hand(data: Variant, rail_position: Vector2 = Vector2.INF) -> void:
	if not can_drop_card_to_hand(data):
		return
	var card_uid := int(data.get("card_uid", data.get("card_id", 0)))
	var source := str(data.get("source", ""))
	var source_slot := str(data.get("source_slot", ""))
	var source_rite_uid := int(data.get("source_rite_uid", 0))
	var card: Dictionary = _state.card_data_for(card_uid, _db)
	var is_sudan: bool = str(card.get("type", "")) == "sudan" or _state.is_active_sudan_card(card_uid)
	var insert_index := _rail_insert_index_at(rail_position, card_uid)
	if source == "slot":
		var slot_num: int = source_slot.substr(1).to_int() if source_slot.begins_with("s") else int(_state.slot_for_table_card(card_uid, source_rite_uid))
		_state.remove_card_from_slot(card_uid, slot_num, source_rite_uid)
		if is_sudan:
			var instance = _state.get_card_instance(card_uid)
			if instance != null:
				instance.zone = "sudan"
			_state.insert_card_to_rail(card_uid, insert_index)
		else:
			_state.add_card_to_hand_at_rail(card_uid, insert_index, _db)
		_notify_card_returned_to_hand(card_uid, source_slot)
	elif source == "hand" or source == "active_sudan":
		_state.reorder_rail_card(card_uid, insert_index)
	refresh()


func _rail_insert_index_at(rail_position: Vector2, dragged_card_uid: int = 0) -> int:
	if _card_items == null:
		return _state.rail_order.size()
	if rail_position.x == INF:
		return _state.rail_order.size()
	var global_pos := _card_rail_view.get_global_transform() * rail_position
	var local_x := (_card_items.get_global_transform().affine_inverse() * global_pos).x
	var index := 0
	for child in _card_items.get_children():
		if not (child is CardWidget):
			continue
		var widget := child as CardWidget
		if int(widget.card_uid) == dragged_card_uid:
			continue
		if not widget.visible:
			continue
		var center_x := widget.position.x + widget.size.x * 0.5
		if local_x < center_x:
			return index
		index += 1
	return index


func _notify_card_returned_to_hand(card_uid: int, source_slot: String) -> void:
	if _overlay_layer == null:
		return
	for child in _overlay_layer.get_children():
		if child.has_method("return_card_to_hand"):
			child.return_card_to_hand(card_uid, source_slot)


func set_log(text: String) -> void:
	if _log_label:
		_log_label.text = text


func add_overlay(node: Control) -> void:
	if _overlay_layer == null:
		add_child(node)
		return
	_overlay_layer.add_child(node)
	_overlay_layer.move_child(node, _overlay_layer.get_child_count() - 1)


func _refresh_event_overlay() -> void:
	if _state == null:
		_clear_event_overlay()
		return
	var display := _next_event_display()
	if display.is_empty():
		_clear_event_overlay()
		return
	_show_event_overlay(display)


func _next_event_display() -> Dictionary:
	if _state == null:
		return {}
	if not _state.event_prompts.is_empty():
		var prompt: Dictionary = _state.event_prompts[0]
		return {
			"kind": "prompt",
			"title": str(prompt.get("title", prompt.get("id", "提示"))),
			"text": str(prompt.get("text", prompt.get("desc", ""))),
			"choices": prompt.get("choices", {}),
		}
	if not _state.event_queue.is_empty():
		var event_id := int(_state.event_queue[0])
		var event: Dictionary = _db.get_event(event_id) if _db != null and _db.has_method("get_event") else {}
		return {
			"kind": "event",
			"id": event_id,
			"title": str(event.get("name", event.get("title", "事件 %d" % event_id))),
			"text": _event_body_text(event, event_id),
			"choices": event.get("choose", {}),
		}
	return {}


func _show_event_overlay(display: Dictionary) -> void:
	_clear_event_overlay()
	_event_overlay = Control.new()
	_event_overlay.name = "EventPromptOverlay"
	_event_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_overlay(_event_overlay)

	_event_panel = Panel.new()
	_event_panel.name = "EventPromptPanel"
	_event_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_event_panel.clip_contents = true
	_event_panel.add_theme_stylebox_override("panel", _event_panel_style())
	_event_overlay.add_child(_event_panel)

	var root := VBoxContainer.new()
	root.name = "EventPromptContent"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18
	root.offset_top = 16
	root.offset_right = -18
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 10)
	_event_panel.add_child(root)

	var title := Label.new()
	title.name = "EventPromptTitle"
	title.text = str(display.get("title", "事件"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	root.add_child(title)

	var body := RichTextLabel.new()
	body.name = "EventPromptBody"
	body.text = str(display.get("text", ""))
	body.bbcode_enabled = true
	body.fit_content = true
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("default_color", FaustTheme.TEXT)
	body.scroll_active = true
	root.add_child(body)

	var buttons := HBoxContainer.new()
	buttons.name = "EventPromptActions"
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	root.add_child(buttons)

	var choices: Dictionary = display.get("choices", {})
	if choices.is_empty():
		var cont := _event_button("继续")
		cont.name = "EventPromptContinueButton"
		cont.pressed.connect(_consume_event_display)
		buttons.add_child(cont)
	else:
		for key in choices.keys():
			var choice_entry = choices[key]
			var choice_text := str(choice_entry.get("text", key)) if choice_entry is Dictionary and choice_entry.has("value") else str(choice_entry)
			var choice_value = choice_entry.get("value") if choice_entry is Dictionary and choice_entry.has("value") else choice_entry
			var choice := _event_button(choice_text)
			choice.name = "EventPromptChoiceButton"
			choice.pressed.connect(_consume_event_display.bind(str(key), choice_value))
			buttons.add_child(choice)
	_apply_layout()


func _clear_event_overlay() -> void:
	if _event_overlay == null:
		return
	_event_overlay.queue_free()
	_event_overlay = null
	_event_panel = null


func _consume_event_display(choice_key: String = "", choice_value: Variant = "") -> void:
	if _state == null:
		return
	var merged: Dictionary = {}
	if not _state.event_prompts.is_empty():
		var prompt: Dictionary = _state.event_prompts[0]
		var prompt_context: Dictionary = prompt.get("context", {}).duplicate(true) if prompt.get("context", {}) is Dictionary else {}
		_state.event_prompts.remove_at(0)
		if choice_key != "":
			set_log("选择：%s" % str(choice_value))
			DeferredEffects.execute_choice(choice_key, choice_value, _state, _db, _rng, prompt_context)
	elif not _state.event_queue.is_empty():
		var event_id := int(_state.event_queue[0])
		_state.event_queue.remove_at(0)
		var trigger_ctx: Dictionary = _state.event_contexts.get(event_id, {}).duplicate(true)
		_state.event_contexts.erase(event_id)
		var event: Dictionary = _db.get_event(event_id) if _db != null and _db.has_method("get_event") else {}
		if choice_key != "":
			# A chosen branch overrides the event's default result/action.
			set_log("选择：%s" % str(choice_value))
			DeferredEffects.execute_choice(choice_key, choice_value, _state, _db, _rng, trigger_ctx)
		else:
			merged = DeferredEffects.execute_event(event, _state, _db, _rng, trigger_ctx)
			if bool(merged.get("over", false)):
				game_over_requested.emit()
	# An event whose action opens a rite should surface that rite to the player
	# immediately (showing the rite's narration text), not silently park it.
	# The original opens the rite as a UI surface when an event fires it.
	refresh()
	var opened_rite := int(merged.get("rite", 0))
	if opened_rite > 0:
		open_rite.emit(opened_rite)


func _event_body_text(event: Dictionary, event_id: int) -> String:
	for key in ["text", "desc", "description", "content"]:
		if str(event.get(key, "")) != "":
			return str(event[key])
	if event.is_empty():
		return "事件 %d 已触发，后续会接入原版事件文本与结果。" % event_id
	return "事件 %d" % event_id


func _layout_event_prompt(s: float, view_size: Vector2) -> void:
	if _event_panel == null:
		return
	var panel_w: float = min(view_size.x - 200 * s, 720 * s)
	# Panel occupies most of the vertical space so long narration text is visible.
	var panel_h: float = min(view_size.y * 0.62, 520 * s)
	var panel_x: float = (view_size.x - panel_w) * 0.5
	var panel_y: float = (view_size.y - panel_h) * 0.5
	_set_rect(_event_panel, Rect2(Vector2(panel_x, panel_y), Vector2(panel_w, panel_h)))


func _event_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(96, 36)
	return button


func _event_panel_style() -> StyleBoxFlat:
	var style := FaustTheme.card_style(FaustTheme.GOLD)
	style.bg_color = Color(0.05, 0.045, 0.035, 0.94)
	style.set_content_margin_all(16)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style


func show_card_detail(card_or_uid: int) -> void:
	var card_uid = _state._resolve_card_uid(card_or_uid) if _state != null and _state.has_method("_resolve_card_uid") else 0
	var card: Dictionary = _state.card_data_for(card_uid, _db) if card_uid > 0 else _db.get_card(card_or_uid).duplicate(true)
	if card.is_empty():
		return
	_show_card_detail(card_uid if card_uid > 0 else int(card.get("id", 0)), card)


func _show_card_detail(card_id: int, card: Dictionary) -> void:
	if card_id <= 0 or card.is_empty():
		return
	if _card_detail_overlay != null and _card_detail_card_id == card_id:
		close_card_detail()
		return
	close_card_detail()
	_card_detail_card_id = card_id
	_card_detail_overlay = Control.new()
	_card_detail_overlay.name = "CardDetailOverlay"
	_card_detail_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_detail_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_overlay(_card_detail_overlay)

	_card_detail_panel = Panel.new()
	_card_detail_panel.name = "CardDetailPanel"
	_card_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_card_detail_panel.clip_contents = true
	_card_detail_panel.add_theme_stylebox_override("panel", _detail_panel_style())
	_card_detail_overlay.add_child(_card_detail_panel)

	var root := VBoxContainer.new()
	root.name = "CardDetailContent"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18
	root.offset_top = 18
	root.offset_right = -18
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 8)
	_card_detail_panel.add_child(root)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	root.add_child(top_row)

	var badge := Label.new()
	badge.name = "CardDetailBadge"
	badge.text = _rarity_badge(card)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(64, 64)
	badge.add_theme_font_size_override("font_size", 28)
	badge.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	badge.add_theme_stylebox_override("normal", _badge_style())
	top_row.add_child(badge)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 6)
	top_row.add_child(title_box)

	var name_label := Label.new()
	name_label.name = "CardDetailName"
	name_label.text = str(card.get("name", "?"))
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	title_box.add_child(name_label)

	var subtitle := Label.new()
	subtitle.name = "CardDetailSubtitle"
	subtitle.text = "%s  %s" % [CardWidget._type_label(str(card.get("type", ""))), str(card.get("title", ""))]
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	title_box.add_child(subtitle)

	var text := Label.new()
	text.name = "CardDetailDescription"
	text.text = str(card.get("text", card.get("tips", "")))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.clip_text = true
	text.custom_minimum_size = Vector2(460, 46)
	text.add_theme_font_size_override("font_size", 17)
	text.add_theme_color_override("font_color", FaustTheme.TEXT)
	title_box.add_child(text)

	var close := Button.new()
	close.name = "CloseCardDetailButton"
	close.text = "×"
	close.custom_minimum_size = Vector2(42, 42)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.add_theme_font_size_override("font_size", 24)
	close.add_theme_stylebox_override("normal", _round_close_style())
	close.add_theme_stylebox_override("hover", _round_close_style(FaustTheme.GOLD_BRIGHT))
	close.add_theme_stylebox_override("pressed", _round_close_style(FaustTheme.BORDER))
	close.pressed.connect(close_card_detail)
	top_row.add_child(close)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 8)
	body.add_child(info)
	_add_detail_section(info, "属性", _attribute_lines(card))
	_add_detail_section(info, "标签", _tag_lines(card))

	var portrait := ColorRect.new()
	portrait.name = "CardDetailPortraitPlaceholder"
	portrait.color = Color("#101820")
	portrait.custom_minimum_size = Vector2(140, 150)
	body.add_child(portrait)

	_apply_layout()


func close_card_detail() -> void:
	if _card_detail_overlay == null:
		return
	_card_detail_overlay.queue_free()
	_card_detail_overlay = null
	_card_detail_panel = null
	_card_detail_card_id = 0


func _layout_card_detail(s: float, view_size: Vector2) -> void:
	if _card_detail_panel == null:
		return
	var panel_w: float = min(view_size.x - 360 * s, 690 * s)
	var panel_h: float = 340 * s
	var panel_x: float = (view_size.x - panel_w) * 0.5
	var panel_y: float = 108 * s
	_set_rect(_card_detail_panel, Rect2(Vector2(panel_x, panel_y), Vector2(panel_w, panel_h)))


func _add_detail_section(parent: VBoxContainer, title_text: String, lines: Array[String]) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", FaustTheme.GOLD)
	parent.add_child(title)

	var text := Label.new()
	text.text = "\n".join(lines) if not lines.is_empty() else "无"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", FaustTheme.TEXT)
	parent.add_child(text)


func _attribute_lines(card: Dictionary) -> Array[String]:
	var tag: Dictionary = card.get("tag", {})
	var attrs := ["体魄", "魅力", "智慧", "社交", "战斗", "支持"]
	var lines: Array[String] = []
	var row: Array[String] = []
	for attr in attrs:
		var value := int(tag.get(attr, 0))
		if value == 0:
			continue
		row.append("%s  %d" % [attr, value])
		if row.size() == 3:
			lines.append("    ".join(row))
			row.clear()
	if not row.is_empty():
		lines.append("    ".join(row))
	return lines


func _tag_lines(card: Dictionary) -> Array[String]:
	var tag: Dictionary = card.get("tag", {})
	var attrs := ["体魄", "魅力", "智慧", "社交", "战斗", "支持"]
	var visible_tags: Array[String] = []
	for key in tag.keys():
		if key in attrs:
			continue
		if int(tag[key]) != 0:
			visible_tags.append(str(key))
	if visible_tags.is_empty():
		return []
	return [" ".join(visible_tags.slice(0, 10))]


func _rarity_badge(card: Dictionary) -> String:
	var rare := clampi(int(card.get("rare", 0)), 0, 5)
	if rare <= 0:
		return "铜"
	if rare == 1:
		return "铜"
	if rare == 2:
		return "银"
	if rare == 3:
		return "金"
	return "星"


func _detail_panel_style() -> StyleBoxFlat:
	var style := FaustTheme.card_style(FaustTheme.GOLD)
	style.bg_color = Color(0.05, 0.045, 0.035, 0.94)
	style.set_content_margin_all(18)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	return style


func _badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#e9edf1")
	style.border_color = FaustTheme.GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(34)
	style.set_content_margin_all(8)
	return style


func _round_close_style(border: Color = FaustTheme.GOLD) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#17110d")
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(4)
	return style
