## Main in-game desk screen.
## Layout mirrors docs/mockups/game-screen-layout.html: a top HUD, a broad
## desk/map area, and a bottom card rail beside the day/action controls.
extends Control

signal open_rite(rite_id: int)
signal advance_pressed()
signal redraw_pressed()
signal open_rite_selector()

const FaustTheme = preload("res://ui/theme.gd")
const CardWidget = preload("res://ui/card_widget.gd")
const SudanCards = preload("res://sim/sudan_cards.gd")

const CONTENT_WIDTH := 960
const MOCKUP_SIZE := Vector2(1280, 720)

var _state
var _db
var _rng

var _round_label: Label
var _gold_label: Label
var _log_label: Label
var _hud: PanelContainer
var _desk_map: PanelContainer
var _map_content: Control
var _rail_label: VBoxContainer
var _card_rail_view: ScrollContainer
var _card_items: HBoxContainer
var _right_actions: VBoxContainer
var _advance_button: Button
var _site_buttons: Array[Button] = []


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
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_row.add_child(spacer)
	var menu_label := _stat_label()
	menu_label.text = "菜单"
	hud_row.add_child(menu_label)

	_desk_map = _panel("DeskMap")
	add_child(_desk_map)
	_map_content = Control.new()
	_map_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_content.clip_contents = true
	_desk_map.add_child(_map_content)

	for site_name in ["治理家业", "商业区", "宫廷", "神殿区", "野外"]:
		var site := _site_button(site_name)
		_site_buttons.append(site)
		_map_content.add_child(site)

	_log_label = Label.new()
	_log_label.name = "EventToast"
	_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_log_label.add_theme_font_size_override("font_size", 18)
	_log_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	_map_content.add_child(_log_label)

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

	_card_rail_view = ScrollContainer.new()
	_card_rail_view.name = "CardRail"
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

	var small_actions := HBoxContainer.new()
	small_actions.add_theme_constant_override("separation", 8)
	_right_actions.add_child(small_actions)
	var rite_sel_btn := _icon_button("仪")
	rite_sel_btn.pressed.connect(func(): open_rite_selector.emit())
	small_actions.add_child(rite_sel_btn)
	var redraw_btn := _icon_button("抽")
	redraw_btn.pressed.connect(func(): redraw_pressed.emit())
	small_actions.add_child(redraw_btn)


func _apply_layout() -> void:
	if _hud == null:
		return
	var view_size := size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		var parent_control := get_parent() as Control
		if parent_control != null:
			view_size = parent_control.size
	var s: float = min(view_size.x / MOCKUP_SIZE.x, view_size.y / MOCKUP_SIZE.y)

	_set_rect(_hud, Rect2(Vector2(22, 18) * s, Vector2(view_size.x - 44 * s, 44 * s)))
	_set_rect(_desk_map, Rect2(Vector2(34, 78) * s, Vector2(view_size.x - 68 * s, view_size.y - (78 + 238) * s)))
	_set_rect(_rail_label, Rect2(Vector2(28 * s, view_size.y - 168 * s), Vector2(116 * s, 140 * s)))
	_set_rect(_card_rail_view, Rect2(Vector2(180 * s, view_size.y - 222 * s), Vector2(view_size.x - 360 * s, 202 * s)))
	_set_rect(_right_actions, Rect2(Vector2(view_size.x - 160 * s, view_size.y - 194 * s), Vector2(132 * s, 170 * s)))

	_card_items.custom_minimum_size = Vector2(_card_items.get_minimum_size().x, 178 * s)
	_layout_map_content(s)


func _layout_map_content(s: float) -> void:
	if _map_content == null:
		return
	_map_content.position = Vector2.ZERO
	_map_content.size = _desk_map.size
	var map_size := _desk_map.size
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


func refresh() -> void:
	if _state == null or _card_items == null:
		return
	_round_label.text = "第 %d 回合 · 第 %d 天" % [_state.round_number, _state.day]
	_gold_label.text = "金币 %d    金骰 %d    重抽 %d" % [_state.coin_count, _state.gold_dice, _state.redraws_left]
	for child in _card_items.get_children():
		child.queue_free()
	var life := int(_state.difficulty_config.get("sudan_life_time", 7))
	for asc in _state.active_sudan_cards:
		_card_items.add_child(_make_sudan_card(asc, life))
	for cid in _state.hand:
		var card: Dictionary = _db.get_card(int(cid))
		if card.is_empty():
			continue
		var widget := CardWidget.make(card)
		widget.custom_minimum_size = Vector2(116, 178)
		_card_items.add_child(widget)


func _make_sudan_card(asc, life: int) -> CardWidget:
	var dec = SudanCards.decode(int(asc.card_id))
	var card: Dictionary = _db.get_card(int(asc.card_id)).duplicate(true)
	card["type"] = "sudan"
	card["name"] = "%s%s" % [dec.rank, dec.action]
	var widget := CardWidget.make(card)
	widget.custom_minimum_size = Vector2(116, 178)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = life
	bar.value = int(asc.days_left)
	bar.custom_minimum_size = Vector2(0, 18)
	widget.add_child(bar)
	var days := Label.new()
	days.text = "剩余 %d 天" % int(asc.days_left)
	days.add_theme_font_size_override("font_size", 12)
	days.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	widget.add_child(days)
	return widget


func set_log(text: String) -> void:
	if _log_label:
		_log_label.text = text
