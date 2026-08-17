## Main in-game desk screen.
## The tabletop SituationDesk is the single play surface; the shared rail,
## queue surfaces, and day controls remain persistent.
extends Control

## Presentation contract:
## - The desk is the only surface; modals pause it via set_world_scene_blocker.

signal open_rite(rite_id: int)
signal open_rite_instance(rite_uid: int)
signal advance_pressed()
signal redraw_pressed()
signal back_to_prev_pressed()
signal open_rite_selector(location_name: String)
signal menu_pressed()
signal game_over_requested()

const SituationDeskScript = preload("res://ui/situation_desk.gd")

class HandRailDrop:
	extends Control

	var owner_screen: Control

	func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
		var accepted: bool = (
			owner_screen != null
			and owner_screen.has_method("can_drop_card_to_hand")
			and bool(owner_screen.can_drop_card_to_hand(data))
		)
		if accepted and owner_screen.has_method("_preview_hand_drop"):
			owner_screen.call("_preview_hand_drop", data, at_position)
		return accepted

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if owner_screen != null and owner_screen.has_method("drop_card_to_hand"):
			owner_screen.drop_card_to_hand(data, get_local_mouse_position())

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion and owner_screen != null and owner_screen.has_method("_set_hand_pan_ratio"):
			var ratio := clampf(event.position.x / maxf(size.x, 1.0), 0.0, 1.0)
			owner_screen.call("_set_hand_pan_ratio", ratio)


const MOCKUP_SIZE := Vector2(1280, 720)
const HAND_NATURAL_STEP := 112.0
const HAND_MIN_VISIBLE_WIDTH := 20.0
const HAND_RAIL_BOTTOM_GUTTER := 20.0
# Rendering budget. Game owns the global menu above this entire screen.
const SCENE_CONTENT_Z_MAX := 99
const OVERLAY_LAYER_Z := 100
const PERSISTENT_CONTROL_Z := 200

var _state
var _db
var _rng

var _round_label: Label
var _gold_label: Label
var _log_label: Label
var _background: ColorRect
var _begin_guide_bar: BeginGuideBar
var _hud: PanelContainer
var _menu_button: Button
var _desk_map: PanelContainer
var _desk_content: SituationDesk
var _overlay_layer: Control
var _rail_label: VBoxContainer
var _card_rail_view: Control
var _rail_padding: MarginContainer
var _card_items: Control
var _hand_pan_ratio := 0.5
var _hand_idle_clock_seconds := 0.0
var _hand_content_overflows := false
var _hand_drop_preview_index := -1
var _pending_hand_drop_origins: Dictionary = {}
var _pending_hand_drop_poses: Dictionary = {}
var _known_rail_card_uids: Dictionary = {}
var _right_actions: VBoxContainer
var _advance_button: Button
var _redraw_button: Button
var _back_to_prev_button: Button
var _card_detail_overlay: Control
var _card_detail_panel: Panel
var _card_detail_card_id := 0
var _card_detail_card_uid := 0
var _detail_card_type := ""
var _event_overlay: Control
var _event_panel: Panel
var _rename_input: LineEdit
var _sleep_waiting := false
var _presentation_frozen := false
var _presentation_blockers: Dictionary = {}
var _persistent_action_locks: Dictionary = {}
var _underlying_presentation_pauses: Dictionary = {}


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


func _process(delta: float) -> void:
	if (
		delta <= 0.0
		or _presentation_frozen
		or not _underlying_presentation_pauses.is_empty()
	):
		return
	_hand_idle_clock_seconds += delta


func hand_idle_time_seconds() -> float:
	return _hand_idle_clock_seconds


func _build_ui() -> void:
	_background = ColorRect.new()
	_background.name = "ScreenBackground"
	_background.color = Color("#17120e")
	add_child(_background)
	_begin_guide_bar = BeginGuideBar.new()
	_begin_guide_bar.name = "BeginGuideBarRoot"
	_begin_guide_bar.setup(_state)
	_begin_guide_bar.z_index = PERSISTENT_CONTROL_Z + 2
	add_child(_begin_guide_bar)
	# The screen uses an explicit scaled layout; keep the background on the
	# same top-left coordinate system so resizing it does not fight anchors.
	_background.set_anchors_preset(Control.PRESET_TOP_LEFT)

	_hud = _panel("Hud")
	# The original floats the gold/round readouts over the desk painting with
	# no chrome strip; the host panel stays only as a layout node.
	# [SRC: GameScene.unity TopLeft cluster - no background Image]
	_hud.add_theme_stylebox_override("panel", _hud_panel_style())
	add_child(_hud)
	var hud_row := HBoxContainer.new()
	hud_row.add_theme_constant_override("separation", 24)
	hud_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_row.offset_left = 18
	hud_row.offset_right = -18
	_hud.add_child(hud_row)

	# Round display beside a compact crop of the original pocket-watch
	# dial (56x56 icon; the HUD strip stays thin so the map sits below).
	# [SRC: Texture2D/clock_bg.png 596x636]
	if ResourceLoader.exists("res://assets/original/ui/clock_bg.png"):
		var clock_box := HBoxContainer.new()
		clock_box.name = "RoundClock"
		clock_box.add_theme_constant_override("separation", 6)
		var clock_icon := TextureRect.new()
		var clock_atlas := AtlasTexture.new()
		clock_atlas.atlas = preload("res://assets/original/ui/clock_bg.png")
		clock_atlas.region = Rect2(96, 96, 404, 404)
		clock_icon.texture = clock_atlas
		clock_icon.custom_minimum_size = Vector2(36, 36)
		clock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		clock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		clock_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		clock_box.add_child(clock_icon)
		_round_label = _stat_label()
		_round_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		clock_box.add_child(_round_label)
		hud_row.add_child(clock_box)
	else:
		_round_label = _stat_label()
		hud_row.add_child(_round_label)
	# Original gold-coin badge art beside the gold count.
	if ResourceLoader.exists("res://assets/original/ui/coin.png"):
		var coin_icon := TextureRect.new()
		coin_icon.texture = preload("res://assets/original/ui/coin.png")
		coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin_icon.custom_minimum_size = Vector2(54, 18)
		coin_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hud_row.add_child(coin_icon)
	_gold_label = _stat_label()
	hud_row.add_child(_gold_label)

	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	_menu_button.text = "菜单"
	_menu_button.flat = true
	_menu_button.add_theme_font_size_override("font_size", 15)
	_menu_button.add_theme_color_override("font_color", Color("#e8d59f"))
	_menu_button.add_theme_color_override("font_hover_color", Color("#fff0ba"))
	_menu_button.pressed.connect(func(): menu_pressed.emit())
	_menu_button.z_index = PERSISTENT_CONTROL_Z
	add_child(_menu_button)

	_desk_map = _panel("DeskMap")
	_desk_map.add_theme_stylebox_override("panel", _scene_frame_style())
	add_child(_desk_map)
	_desk_content = SituationDeskScript.new()
	_desk_content.name = "SituationDesk"
	_desk_content.setup(_state, _db, _rng)
	_desk_content.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_desk_content.open_rite_selector.connect(_on_desk_rite_selector_requested)
	_desk_content.open_rite_instance.connect(_emit_open_rite_instance)
	add_child(_desk_content)

	_log_label = Label.new()
	_log_label.name = "EventToast"
	_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_log_label.add_theme_font_size_override("font_size", 18)
	_log_label.add_theme_color_override("font_color", Color("#fff1c2"))
	_log_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.025, 0.06, 0.90))
	_log_label.add_theme_constant_override("shadow_offset_x", 1)
	_log_label.add_theme_constant_override("shadow_offset_y", 2)
	_desk_content.add_child(_log_label)

	_overlay_layer = Control.new()
	_overlay_layer.name = "OverlayLayer"
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.z_index = OVERLAY_LAYER_Z
	add_child(_overlay_layer)

	_rail_label = VBoxContainer.new()
	_rail_label.name = "RailLabel"
	_rail_label.z_index = PERSISTENT_CONTROL_Z
	_rail_label.add_theme_constant_override("separation", 8)
	add_child(_rail_label)
	var rail_text := Label.new()
	rail_text.name = "RailContextLabel"
	rail_text.text = "当前处境"
	rail_text.add_theme_font_size_override("font_size", 14)
	rail_text.add_theme_color_override("font_color", Color(0.92, 0.92, 0.93, 0.72))
	_rail_label.add_child(rail_text)
	var rank_caption := Label.new()
	rank_caption.text = "卡牌等级"
	rank_caption.add_theme_font_size_override("font_size", 11)
	rank_caption.add_theme_color_override("font_color", Color(0.92, 0.92, 0.93, 0.46))
	_rail_label.add_child(rank_caption)
	var rank_range := Label.new()
	rank_range.text = "I — IV"
	rank_range.add_theme_font_size_override("font_size", 13)
	rank_range.add_theme_color_override("font_color", Color(0.92, 0.92, 0.93, 0.62))
	_rail_label.add_child(rank_range)

	_card_rail_view = HandRailDrop.new()
	_card_rail_view.name = "CardRail"
	_card_rail_view.z_index = PERSISTENT_CONTROL_Z
	(_card_rail_view as HandRailDrop).owner_screen = self
	_card_rail_view.clip_contents = true
	_card_rail_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_card_rail_view.mouse_exited.connect(_clear_hand_drop_preview)
	add_child(_card_rail_view)
	_rail_padding = MarginContainer.new()
	_rail_padding.name = "CardRailPadding"
	# Leave room for CardWidget's bottom-pivot hover lift and shadow inside the
	# clipped hand viewport. Without this inset the effect exists in code but
	# its top edge is visibly cut off by the rail.
	_rail_padding.add_theme_constant_override("margin_top", 24)
	# Extend the clipping viewport to the screen edge, then reserve the same
	# amount as inner space.  This keeps the hand at its existing height while
	# allowing tilted bottom corners and the 12 px card shadow to render fully.
	_rail_padding.add_theme_constant_override("margin_bottom", int(HAND_RAIL_BOTTOM_GUTTER))
	_card_rail_view.add_child(_rail_padding)
	# Anchor only after parenting.  Doing this while the node is orphaned makes
	# Godot calculate offsets from the viewport, shifting the centred hand right.
	_rail_padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_items = Control.new()
	_card_items.name = "CardRailItems"
	_card_items.mouse_filter = Control.MOUSE_FILTER_PASS
	_card_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_items.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Hidden Controls are excluded from Container layout.  Stay layout-visible
	# and use alpha to suppress the unpositioned first frame instead.
	_card_items.modulate = Color(1, 1, 1, 0)
	_card_items.resized.connect(_layout_hand_cards)
	_rail_padding.add_child(_card_items)

	_right_actions = VBoxContainer.new()
	_right_actions.name = "RightActions"
	_right_actions.z_index = PERSISTENT_CONTROL_Z
	_right_actions.add_theme_constant_override("separation", 12)
	add_child(_right_actions)

	_advance_button = Button.new()
	_advance_button.name = "AdvanceDayButton"
	_advance_button.tooltip_text = "下一天"
	_advance_button.custom_minimum_size = Vector2(150, 160)
	# Pocket-watch composite: the clock_bg watch IS the button face with the
	# next_day_0 stamp riding in its center — no circular chrome of our own.
	# [SRC: GameScene.unity "Next Round" -> clock_bg 596x634 + Image 305x306
	#       sprite=next_day_0; Texture2D/clock_bg.png + next_day_0.png]
	if ResourceLoader.exists("res://assets/original/ui/clock_bg.png"):
		var watch := TextureRect.new()
		watch.name = "NextDayWatch"
		watch.texture = preload("res://assets/original/ui/clock_bg.png")
		watch.set_anchors_preset(Control.PRESET_FULL_RECT)
		watch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		watch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		watch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_advance_button.add_child(watch)
	if ResourceLoader.exists("res://assets/original/ui/next_day_0.png"):
		var stamp := TextureRect.new()
		stamp.name = "NextDayStamp"
		stamp.texture = load("res://assets/original/ui/next_day_0.png") as Texture2D
		stamp.set_anchors_preset(Control.PRESET_CENTER)
		stamp.custom_minimum_size = Vector2(74, 74)
		stamp.size = Vector2(74, 74)
		stamp.position = Vector2(-37, -42)
		stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_advance_button.add_child(stamp)
	else:
		_advance_button.text = "下一天"
		_advance_button.add_theme_font_size_override("font_size", 23)
		_advance_button.add_theme_color_override("font_color", Color("#2b1d12"))
		_advance_button.add_theme_color_override("font_hover_color", Color("#681f1b"))
		_advance_button.add_theme_color_override("font_disabled_color", Color(0.26, 0.20, 0.15, 0.52))
	var advance_style := _round_button_style()
	_advance_button.add_theme_stylebox_override("normal", advance_style if not ResourceLoader.exists("res://assets/original/ui/clock_bg.png") else StyleBoxEmpty.new())
	_advance_button.add_theme_stylebox_override("hover", _round_button_style(Color("#efc46e")) if not ResourceLoader.exists("res://assets/original/ui/clock_bg.png") else StyleBoxEmpty.new())
	_advance_button.add_theme_stylebox_override("pressed", _round_button_style(Color("#fff1bc")) if not ResourceLoader.exists("res://assets/original/ui/clock_bg.png") else StyleBoxEmpty.new())
	# Disabled is a distinct theme state. Without this explicit style Godot falls
	# back to a rectangular default, making the paused primary action look
	# malformed even though its layout rectangle has not changed.
	_advance_button.add_theme_stylebox_override("disabled", _round_button_style(Color(0.82, 0.84, 0.88, 0.24)))
	_advance_button.pressed.connect(func(): advance_pressed.emit())
	_right_actions.add_child(_advance_button)

	_redraw_button = _icon_button("重抽")
	_redraw_button.name = "RedrawSudanButton"
	# Original redraw coin art when present.
	if ResourceLoader.exists("res://assets/original/ui/redraw_active.png"):
		var redraw_icon := TextureRect.new()
		redraw_icon.texture = preload("res://assets/original/ui/redraw_active.png")
		redraw_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		redraw_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		redraw_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		redraw_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_redraw_button.text = ""
		_redraw_button.tooltip_text = "重抽苏丹卡"
		_redraw_button.add_child(redraw_icon)
	_redraw_button.pressed.connect(func(): redraw_pressed.emit())
	_right_actions.add_child(_redraw_button)

	_back_to_prev_button = _icon_button("回退")
	_back_to_prev_button.name = "BackToPrevButton"
	# Original return-to-previous-round stamp.
	# [SRC: GameScene.unity Next Round/PrevRound -> return_last_round;
	#       Texture2D/return_last_round.png 160x140]
	if ResourceLoader.exists("res://assets/original/ui/return_last_round.png"):
		var back_icon := TextureRect.new()
		back_icon.texture = load("res://assets/original/ui/return_last_round.png") as Texture2D
		back_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		back_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_back_to_prev_button.text = ""
		_back_to_prev_button.tooltip_text = "回到上一回合结束（消耗一次回退机会）"
		_back_to_prev_button.add_child(back_icon)
	_back_to_prev_button.pressed.connect(func(): back_to_prev_pressed.emit())
	_right_actions.add_child(_back_to_prev_button)


func _apply_layout() -> void:
	if _hud == null:
		return
	var view_size := _effective_view_size()
	var s: float = min(view_size.x / MOCKUP_SIZE.x, view_size.y / MOCKUP_SIZE.y)

	_set_rect(_background, Rect2(Vector2.ZERO, view_size))
	_set_rect(_hud, Rect2(Vector2(22, 16) * s, Vector2(392, 48) * s))
	_set_rect(_menu_button, Rect2(Vector2(view_size.x - 78 * s, 22 * s), Vector2(52, 40) * s))
	# The painted board extends behind the persistent card band. Cards and HUD
	# remain front-facing, while only the map surface uses tabletop perspective.
	_set_rect(
		_desk_map,
		Rect2(
			Vector2(18, 66) * s,
			Vector2(view_size.x - 36 * s, view_size.y - (66 + 118) * s)
		)
	)
	_set_rect(_desk_content, Rect2(_desk_map.position, _desk_map.size))
	_set_rect(_overlay_layer, Rect2(Vector2.ZERO, view_size))
	_set_rect(_rail_label, Rect2(Vector2(28 * s, view_size.y - 168 * s), Vector2(116 * s, 140 * s)))
	_set_rect(
		_card_rail_view,
		Rect2(
			Vector2(180 * s, view_size.y - 222 * s),
			Vector2(view_size.x - 360 * s, (202.0 + HAND_RAIL_BOTTOM_GUTTER) * s)
		)
	)
	_rail_padding.add_theme_constant_override(
		"margin_bottom", roundi(HAND_RAIL_BOTTOM_GUTTER * s)
	)
	_set_rect(_right_actions, Rect2(Vector2(view_size.x - 160 * s, view_size.y - 194 * s), Vector2(132 * s, 170 * s)))

	_card_items.custom_minimum_size = Vector2.ZERO
	call_deferred("_layout_hand_cards")
	_layout_situation_desk(s)
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


func _layout_situation_desk(s: float) -> void:
	if _desk_content == null:
		return
	var map_size := _desk_content.size
	_desk_content.refresh_context()
	if _log_label != null:
		_log_label.size = Vector2(520, 34) * s
		_log_label.position = Vector2((map_size.x - _log_label.size.x) * 0.5, map_size.y - 58 * s)


func _set_rect(node: Control, rect: Rect2) -> void:
	node.position = rect.position.round()
	node.size = rect.size.round()


func _stat_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.94, 0.93, 0.89, 0.88))
	return label


func _panel(node_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style())
	return panel


func _hud_panel_style() -> StyleBox:
	# Transparent host: the readouts sit directly on the table painting.
	var style := StyleBoxEmpty.new()
	return style


func _scene_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# SituationDesk paints the complete board. The host panel exists only as a
	# stable layout/safe-area node and must not reintroduce the old dark frame.
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	return style


func _on_desk_rite_selector_requested(location_name: String) -> void:
	open_rite_selector.emit(location_name)


func site_action_anchor(location_name: String) -> Vector2:
	if _desk_content == null or not _desk_content.has_method("site_action_anchor"):
		return Vector2(-1.0, -1.0)
	var desk_anchor: Vector2 = _desk_content.site_action_anchor(location_name)
	if desk_anchor.x < 0.0 or desk_anchor.y < 0.0:
		return desk_anchor
	return _desk_content.position + desk_anchor


func site_action_menu_bounds() -> Rect2:
	if _desk_map == null:
		return Rect2()
	# The map visually continues behind the hand, but contextual actions belong
	# to the readable upper work area and must never cover the persistent cards.
	var lower_edge: float = _desk_map.position.y + _desk_map.size.y
	if _card_rail_view != null:
		lower_edge = minf(lower_edge, _card_rail_view.position.y - 8.0)
	return Rect2(
		_desk_map.position,
		Vector2(_desk_map.size.x, maxf(0.0, lower_edge - _desk_map.position.y))
	)


func clear_site_focus() -> void:
	if _desk_content != null and _desk_content.has_method("clear_site_focus"):
		_desk_content.clear_site_focus()


func _icon_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(62, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#2b1d12"))
	button.add_theme_color_override("font_hover_color", Color("#681f1b"))
	button.add_theme_color_override("font_disabled_color", Color(0.26, 0.20, 0.15, 0.48))
	button.add_theme_stylebox_override("normal", _small_action_style())
	button.add_theme_stylebox_override("hover", _small_action_style(Color("#efc46e")))
	button.add_theme_stylebox_override("pressed", _small_action_style(Color("#fff1bc")))
	button.add_theme_stylebox_override("disabled", _small_action_style(Color(0.82, 0.84, 0.88, 0.20)))
	return button


## Texture-first: the original parchment strip IS the small-button surface.
## [SRC: Texture2D/button_bg.png 516x140]
func _small_action_style(border: Color = Color(0.43, 0.28, 0.15, 0.68)) -> StyleBox:
	var art_path := "res://assets/original/ui/button_bg.png"
	if ResourceLoader.exists(art_path):
		var tex := load(art_path) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 150
			style.texture_margin_right = 150
			style.texture_margin_top = 40
			style.texture_margin_bottom = 40
			style.content_margin_left = 158
			style.content_margin_right = 158
			style.content_margin_top = 46
			style.content_margin_bottom = 46
			return style
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#dfc886")
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	style.shadow_color = Color(0.04, 0.022, 0.012, 0.42)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2.0, 3.0)
	return style


func _round_button_style(border: Color = Color(0.55, 0.38, 0.17, 0.82)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d8bd74")
	style.border_color = border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 72
	style.corner_radius_top_right = 72
	style.corner_radius_bottom_left = 72
	style.corner_radius_bottom_right = 72
	style.shadow_color = Color(0.04, 0.022, 0.012, 0.54)
	style.shadow_size = 7
	style.shadow_offset = Vector2(4.0, 5.0)
	return style




func _emit_open_rite_instance(rite_uid: int) -> void:
	open_rite_instance.emit(rite_uid)




func refresh() -> void:
	if _state == null or _card_items == null:
		return
	if _begin_guide_bar != null:
		_begin_guide_bar.refresh(_state)
	_round_label.text = "第 %d 天" % _state.day
	_gold_label.text = "金骰 %d    重抽 %d" % [_state.gold_dice, _state.redraws_left]
	var previous_positions := _capture_hand_visual_positions()
	for child in _card_items.get_children():
		child.queue_free()
	_card_items.modulate = Color(1, 1, 1, 0)
	_hand_pan_ratio = 0.5
	var life := int(_state.difficulty_config.get("sudan_life_time", 7))
	_state.sync_rail_order()
	var next_known_uids: Dictionary = {}
	for card_uid in _state.visible_rail_card_uids():
		var uid := int(card_uid)
		if _state.is_active_sudan_card(uid):
			var asc = _active_sudan_for_card(uid)
			if asc != null:
				var sudan_widget := _make_sudan_card(asc, life)
				var has_drop_origin := _pending_hand_drop_origins.has(uid)
				sudan_widget.set_meta("deal_pending", not has_drop_origin and not _known_rail_card_uids.has(uid))
				if has_drop_origin:
					sudan_widget.set_meta("reflow_from", _pending_hand_drop_origins[uid])
					var sudan_drag_pose: Dictionary = _pending_hand_drop_poses.get(uid, {})
					sudan_widget.set_meta("reflow_rotation_from", float(sudan_drag_pose.get("rotation", INF)))
					sudan_widget.set_meta("reflow_scale_from", sudan_drag_pose.get("scale", Vector2.ZERO))
					sudan_widget.set_meta("reflow_tilt_from", sudan_drag_pose.get("tilt", Vector2(INF, INF)))
					_pending_hand_drop_origins.erase(uid)
					_pending_hand_drop_poses.erase(uid)
				elif previous_positions.has(uid):
					sudan_widget.set_meta("reflow_from", previous_positions[uid])
				sudan_widget.drag_visibility_changed.connect(_on_hand_card_drag_visibility_changed)
				_card_items.add_child(sudan_widget)
				sudan_widget.set_selected(uid == _card_detail_card_uid, false)
				next_known_uids[uid] = true
			continue
		var card: Dictionary = _state.card_data_for(uid, _db)
		if card.is_empty():
			continue
		var widget := CardWidget.make(card, "hand")
		widget.custom_minimum_size = CardWidget.CARD_SIZE
		widget.clicked.connect(_show_card_detail)
		var has_drop_origin := _pending_hand_drop_origins.has(uid)
		widget.set_meta("deal_pending", not has_drop_origin and not _known_rail_card_uids.has(uid))
		if has_drop_origin:
			widget.set_meta("reflow_from", _pending_hand_drop_origins[uid])
			var card_drag_pose: Dictionary = _pending_hand_drop_poses.get(uid, {})
			widget.set_meta("reflow_rotation_from", float(card_drag_pose.get("rotation", INF)))
			widget.set_meta("reflow_scale_from", card_drag_pose.get("scale", Vector2.ZERO))
			widget.set_meta("reflow_tilt_from", card_drag_pose.get("tilt", Vector2(INF, INF)))
			_pending_hand_drop_origins.erase(uid)
			_pending_hand_drop_poses.erase(uid)
		elif previous_positions.has(uid):
			widget.set_meta("reflow_from", previous_positions[uid])
		widget.drag_visibility_changed.connect(_on_hand_card_drag_visibility_changed)
		_card_items.add_child(widget)
		widget.set_selected(uid == _card_detail_card_uid, false)
		next_known_uids[uid] = true
	_known_rail_card_uids = next_known_uids
	_layout_hand_cards()
	call_deferred("_layout_hand_cards")
	_refresh_event_overlay()


## The original HandCardsController lays its children out itself and compresses
## their visible width (minVisibleWidth defaults to 20) instead of exposing a
## ScrollRect.  Keep that accessibility boundary while using a straight,
## centred row with complete borders at ordinary hand sizes.
## [SRC: decompiled/HandCardsController.c @ Update (RVA 0x563520),
## dump.cs:320760]
func _layout_hand_cards(previous_positions: Dictionary = {}) -> void:
	if _card_items == null or not is_instance_valid(_card_items):
		return
	var cards: Array[CardWidget] = []
	for child in _card_items.get_children():
		if child is CardWidget and not child.is_queued_for_deletion() and child.visible:
			cards.append(child as CardWidget)
	var count := cards.size()
	if count == 0:
		_hand_content_overflows = false
		return
	var slot_count := count + (1 if _hand_drop_preview_index >= 0 else 0)
	var metrics := _hand_layout_metrics(slot_count)
	if metrics.is_empty():
		return
	var available_width: float = metrics["available_width"]
	var step: float = metrics["step"]
	var start_x: float = metrics["start_x"]
	_hand_content_overflows = bool(metrics["overflows"])
	var base_y := maxf(0.0, (_card_items.size.y - CardWidget.CARD_SIZE.y) * 0.5)
	for index in count:
		var card := cards[index]
		var slot_index := index
		if _hand_drop_preview_index >= 0 and slot_index >= _hand_drop_preview_index:
			slot_index += 1
		card.set_hand_pose(
			Vector2(start_x + step * slot_index, base_y),
			0.0,
			slot_index
		)
		card.set_hand_idle(
			true,
			slot_index,
			Callable(self, "hand_idle_time_seconds")
		)
		if bool(card.get_meta("deal_pending", false)):
			card.set_meta("deal_pending", false)
			var deal_origin := Vector2(
				available_width - card.position.x + 42.0,
				28.0 + float(index % 2) * 4.0
			)
			card.play_deal_in(deal_origin, index)
		elif card.has_meta("reflow_from"):
			var old_position: Vector2 = card.get_meta("reflow_from")
			var old_rotation := float(card.get_meta("reflow_rotation_from", INF))
			var old_scale: Vector2 = card.get_meta("reflow_scale_from", Vector2.ZERO)
			var old_tilt: Vector2 = card.get_meta("reflow_tilt_from", Vector2(INF, INF))
			card.remove_meta("reflow_from")
			card.remove_meta("reflow_rotation_from")
			card.remove_meta("reflow_scale_from")
			card.remove_meta("reflow_tilt_from")
			card.play_hand_reflow(old_position - card.position, old_rotation, old_scale, old_tilt)
		elif previous_positions.has(card.card_uid):
			var old_position: Vector2 = previous_positions[card.card_uid]
			card.play_hand_reflow(old_position - card.position)
	_card_items.modulate = Color.WHITE


func _hand_layout_metrics(slot_count: int) -> Dictionary:
	var available_width := _card_items.size.x
	if available_width <= 0.0 or slot_count <= 0:
		return {}
	var step := HAND_NATURAL_STEP
	if slot_count > 1:
		var fit_step := (available_width - CardWidget.CARD_SIZE.x) / float(slot_count - 1)
		step = minf(step, maxf(HAND_MIN_VISIBLE_WIDTH, fit_step))
	var hand_width := CardWidget.CARD_SIZE.x + step * float(slot_count - 1)
	var overflow := maxf(0.0, hand_width - available_width)
	return {
		"available_width": available_width,
		"step": step,
		"start_x": (available_width - hand_width) * 0.5 if overflow <= 0.0 else -overflow * _hand_pan_ratio,
		"overflows": overflow > 0.0,
	}


func _capture_hand_visual_positions() -> Dictionary:
	var positions: Dictionary = {}
	if _card_items == null:
		return positions
	for child in _card_items.get_children():
		if child is CardWidget and not child.is_queued_for_deletion() and child.visible:
			var card := child as CardWidget
			positions[card.card_uid] = card.position + card.offset_transform_position
	return positions


func _on_hand_card_drag_visibility_changed(card_uid: int, hidden: bool) -> void:
	if not hidden:
		_hand_drop_preview_index = -1
		# A successful hand drop has already rebuilt this UID and started its
		# pose-preserving return.  The old source's DRAG_END notification must not
		# restart that animation with a direction-derived rotation.
		for child in _card_items.get_children():
			if (
				child is CardWidget
				and child.visible
				and int((child as CardWidget).card_uid) == card_uid
				and (child as CardWidget).is_hand_motion_active()
			):
				return
	var previous_positions := _capture_hand_visual_positions()
	_layout_hand_cards(previous_positions)


func _preview_hand_drop(data: Variant, rail_position: Vector2) -> void:
	if not can_drop_card_to_hand(data):
		return
	var dragged_uid := int(data.get("card_uid", data.get("card_id", 0)))
	var next_index := _hand_preview_index_at(rail_position, dragged_uid)
	if next_index == _hand_drop_preview_index:
		return
	var previous_positions := _capture_hand_visual_positions()
	_hand_drop_preview_index = next_index
	_layout_hand_cards(previous_positions)


func _clear_hand_drop_preview() -> void:
	if _hand_drop_preview_index < 0:
		return
	var previous_positions := _capture_hand_visual_positions()
	_hand_drop_preview_index = -1
	_layout_hand_cards(previous_positions)


func _hand_preview_index_at(rail_position: Vector2, dragged_card_uid: int) -> int:
	var visible_count := 0
	for child in _card_items.get_children():
		if child is CardWidget and child.visible and not child.is_queued_for_deletion():
			if int((child as CardWidget).card_uid) != dragged_card_uid:
				visible_count += 1
	var metrics := _hand_layout_metrics(visible_count + 1)
	if metrics.is_empty():
		return visible_count
	var global_pos := _card_rail_view.get_global_transform() * rail_position
	var local_x := (_card_items.get_global_transform().affine_inverse() * global_pos).x
	var first_center: float = float(metrics["start_x"]) + CardWidget.CARD_SIZE.x * 0.5
	return clampi(roundi((local_x - first_center) / float(metrics["step"])), 0, visible_count)


func _set_hand_pan_ratio(ratio: float) -> void:
	if not _hand_content_overflows:
		return
	var next_ratio := clampf(ratio, 0.0, 1.0)
	if is_equal_approx(next_ratio, _hand_pan_ratio):
		return
	_hand_pan_ratio = next_ratio
	_layout_hand_cards()


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


# Clone-era compatibility adapter. The desk owns the player-facing
# "思考" interaction; this method preserves the verified MethinksEngine chain
# until a replacement mechanism has been prototyped and accepted.
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
	var insert_index := (
		_hand_drop_preview_index
		if _hand_drop_preview_index >= 0
		else _rail_insert_index_at(rail_position, card_uid)
	)
	if rail_position.x != INF:
		var global_drop := _card_rail_view.get_global_transform() * rail_position
		var local_drop := _card_items.get_global_transform().affine_inverse() * global_drop
		var grab_offset: Vector2 = data.get("grab_offset", CardWidget.CARD_SIZE * 0.5)
		var drag_visual_position: Vector2 = data.get("drag_visual_position", Vector2.ZERO)
		_pending_hand_drop_origins[card_uid] = local_drop - grab_offset + drag_visual_position
		_pending_hand_drop_poses[card_uid] = {
			"rotation": float(data.get("drag_visual_rotation", INF)),
			"scale": data.get("drag_visual_scale", Vector2.ZERO),
			"tilt": data.get("drag_visual_tilt", Vector2(INF, INF)),
		}
	_hand_drop_preview_index = -1
	if source == "slot":
		var slot_num: int = (
			source_slot.substr(1).to_int()
			if source_slot.begins_with("s")
			else int(_state.slot_for_table_card(card_uid, source_rite_uid))
		)
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
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.move_child(node, _overlay_layer.get_child_count() - 1)


func set_world_scene_blocker(
	source: String,
	blocking: bool,
	hide_chrome: bool = true,
	lock_persistent_actions: bool = false,
	pause_underlying_presentation: bool = false
) -> void:
	if source.is_empty():
		return
	if blocking:
		_presentation_blockers[source] = hide_chrome
		if lock_persistent_actions:
			_persistent_action_locks[source] = true
		else:
			_persistent_action_locks.erase(source)
		if pause_underlying_presentation:
			_underlying_presentation_pauses[source] = true
		else:
			_underlying_presentation_pauses.erase(source)
	else:
		_presentation_blockers.erase(source)
		_persistent_action_locks.erase(source)
		_underlying_presentation_pauses.erase(source)
	if _desk_content != null and _desk_content.has_method("set_scene_blocker"):
		_desk_content.set_scene_blocker(source, blocking, hide_chrome)
	_update_persistent_action_availability()
	_set_underlying_presentation_paused(not _underlying_presentation_pauses.is_empty())


## A global modal lives above GameScreen. Freeze this complete lower layer so
## its already-visible controls remain a true paused snapshot beneath the
## modal rather than continuing their own visual processing.
func set_presentation_frozen(frozen: bool) -> void:
	if _presentation_frozen == frozen:
		return
	_presentation_frozen = frozen
	process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT


## Context menus are still part of GameScreen, so disabling this complete node
## would also freeze their entrance/exit animation. Pause only the persistent
## background controls instead: they remain visible under the selector shade,
## but cannot receive input or keep animating independently.
func _set_underlying_presentation_paused(paused: bool) -> void:
	if _menu_button != null:
		_menu_button.disabled = paused
	if _card_rail_view != null:
		_card_rail_view.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE if paused else Control.MOUSE_FILTER_STOP
		)
	if _card_items == null or not is_instance_valid(_card_items):
		return
	for child in _card_items.get_children():
		if child is CardWidget and not child.is_queued_for_deletion():
			(child as CardWidget).set_presentation_paused(paused)


func _update_persistent_action_availability() -> void:
	var chrome_hidden := false
	for hide_chrome in _presentation_blockers.values():
		if bool(hide_chrome):
			chrome_hidden = true
			break
	var persistent_actions_locked := not _persistent_action_locks.is_empty()
	var actions_visible := not chrome_hidden
	var actions_available := (
		actions_visible
		and not persistent_actions_locked
	)
	if _right_actions != null:
		_right_actions.visible = actions_visible
		# Every background element recedes through the same pause shade. Applying
		# another alpha only to this column makes it read as a broken floating UI.
		_right_actions.self_modulate = Color.WHITE
	if _advance_button != null:
		_advance_button.disabled = not actions_available
	if _redraw_button != null:
		_redraw_button.disabled = not actions_available


func _refresh_event_overlay() -> void:
	if _state == null:
		_clear_event_overlay()
		return
	var display := _next_event_display()
	if display.is_empty():
		_clear_event_overlay()
		return
	if str(display.get("kind", "")) == "sleep":
		_clear_event_overlay()
		if not is_inside_tree():
			call_deferred("_refresh_event_overlay")
			return
		if not _sleep_waiting:
			_sleep_waiting = true
			_wait_for_queued_sleep(float(display.get("seconds", 0.0)))
		return
	_show_event_overlay(display)


func _next_event_display() -> Dictionary:
	if _state == null:
		return {}
	var operation: Dictionary = _state.pending_operation() if _state.has_method("pending_operation") else {}
	if operation.is_empty():
		return {}
	var kind := str(operation.get("kind", ""))
	var payload: Dictionary = operation.get("payload", {}) if operation.get("payload", {}) is Dictionary else {}
	if kind in ["prompt", "choice"]:
		return {
			"kind": kind,
			"title": str(payload.get("title", payload.get("id", "提示"))),
			"speaker": str(payload.get("speaker", payload.get("title", ""))),
			"speaker_actor_id": str(payload.get("speaker_actor_id", "protagonist")),
			"text": str(payload.get("text", payload.get("desc", ""))),
			"choices": payload.get("choices", {}),
			"presentation": str(payload.get("presentation", "")),
		}
	if kind == "rename_card":
		return {
			"kind": kind,
			"title": str(payload.get("title", "为卡牌命名")),
			"text": str(payload.get("text", "")),
			"initial_text": str(payload.get("initial_text", "")),
		}
	if kind == "sleep":
		return {"kind": "sleep", "seconds": float(payload.get("seconds", 0.0))}
	if kind == "event":
		var event_id := int(operation.get("id", 0))
		var event: Dictionary = _db.get_event(event_id) if _db != null and _db.has_method("get_event") else {}
		return {
			"kind": "event",
			"id": event_id,
			"title": str(event.get("name", event.get("title", "事件 %d" % event_id))),
			"text": _event_body_text(event, event_id),
			"choices": event.get("choose", {}),
			"icon": _event_portrait(event),
		}
	return {}


func _show_event_overlay(display: Dictionary) -> void:
	_clear_event_overlay()
	set_world_scene_blocker("event_prompt", true)
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
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color("#fff1c3"))
	root.add_child(title)

	# Original portrait art beside the event text (event configs carry an
	# `icon` resource like "cards/2000012"; art lands in assets/original/cards
	# keyed by the resource basename). [SRC: event icon fields; heads.png
	# atlas is the live2D fallback in the original]
	var portrait: Texture2D = display.get("icon", null)
	if portrait != null:
		var portrait_rect := TextureRect.new()
		portrait_rect.name = "EventPortrait"
		portrait_rect.texture = portrait
		portrait_rect.custom_minimum_size = Vector2(96, 120)
		portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		root.add_child(portrait_rect)

	var body := RichTextLabel.new()
	body.name = "EventPromptBody"
	body.text = str(display.get("text", ""))
	body.bbcode_enabled = true
	body.fit_content = true
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("default_color", Color("#f0eee9"))
	body.scroll_active = true
	root.add_child(body)

	if str(display.get("kind", "")) == "rename_card":
		_rename_input = LineEdit.new()
		_rename_input.name = "CardRenameInput"
		_rename_input.text = str(display.get("initial_text", ""))
		_rename_input.placeholder_text = "输入名字"
		_rename_input.max_length = 32
		_rename_input.custom_minimum_size = Vector2(320, 42)
		_rename_input.text_submitted.connect(func(_value: String): _consume_event_display())
		root.add_child(_rename_input)
		_rename_input.call_deferred("grab_focus")
		_rename_input.call_deferred("select_all")

	var buttons := HFlowContainer.new()
	buttons.name = "EventPromptActions"
	buttons.add_theme_constant_override("separation", 10)
	root.add_child(buttons)

	var choices: Dictionary = display.get("choices", {})
	if str(display.get("kind", "")) == "rename_card":
		var confirm_rename := _event_button("确认")
		confirm_rename.name = "CardRenameConfirmButton"
		confirm_rename.pressed.connect(_consume_event_display)
		buttons.add_child(confirm_rename)
	elif choices.is_empty():
		var cont := _event_button("继续")
		cont.name = "EventPromptContinueButton"
		cont.pressed.connect(_consume_event_display)
		buttons.add_child(cont)
	else:
		var desc_label: RichTextLabel = null
		var has_desc := false
		for key in choices.keys():
			var entry = choices[key]
			if entry is Dictionary and str(entry.get("desc", "")) != "":
				has_desc = true
				break
		if has_desc:
			# DifficultyPanel-style live description: hovering a choice
			# updates the desc area like UpdateShow swaps portrait+desc.
			# [SRC: DifficultyPanelController.c UpdateShow/OnItemSelect]
			desc_label = RichTextLabel.new()
			desc_label.name = "EventPromptChoiceDesc"
			desc_label.bbcode_enabled = true
			desc_label.fit_content = true
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_label.custom_minimum_size = Vector2(0, 74)
			desc_label.add_theme_font_size_override("font_size", 13)
			desc_label.add_theme_color_override("default_color", Color("#e8dcb8"))
			desc_label.scroll_active = true
			root.add_child(desc_label)
		for key in choices.keys():
			var choice_entry = choices[key]
			var choice_text := str(choice_entry.get("text", key)) if choice_entry is Dictionary and choice_entry.has("value") else str(choice_entry)
			var choice_value = choice_entry.get("value") if choice_entry is Dictionary and choice_entry.has("value") else choice_entry
			var choice := _event_button(choice_text)
			choice.name = "EventPromptChoiceButton"
			var choice_icon: Texture2D = (
				_choice_icon_texture(choice_entry.get("icon", ""))
				if choice_entry is Dictionary
				else null
			)
			if choice_icon != null:
				var icon_rect := TextureRect.new()
				icon_rect.texture = choice_icon
				icon_rect.custom_minimum_size = Vector2(56, 56)
				icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				choice.add_child(icon_rect)
			if desc_label != null and choice_entry is Dictionary:
				var entry_desc := str(choice_entry.get("desc", ""))
				choice.mouse_entered.connect(func():
					desc_label.text = entry_desc
				)
			choice.pressed.connect(_consume_event_display.bind(str(key), choice_value))
			buttons.add_child(choice)
	_apply_layout()


## Resolve a choice icon resource reference ("cards/<id>" from event
## configs, "ui/<name>" for panel art) to its extracted texture.
func _choice_icon_texture(resource_ref: String) -> Texture2D:
	if str(resource_ref) == "":
		return null
	var path := ""
	if str(resource_ref).begins_with("cards/"):
		path = "res://assets/original/cards/%s.png" % str(resource_ref).split("/")[-1]
	elif str(resource_ref).begins_with("ui/"):
		path = "res://assets/original/ui/%s.png" % str(resource_ref).split("/")[-1]
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _clear_event_overlay() -> void:
	if _event_overlay == null:
		set_world_scene_blocker("event_prompt", false)
		return
	var old_overlay := _event_overlay
	_event_overlay = null
	_event_panel = null
	_rename_input = null
	if old_overlay.get_parent() != null:
		old_overlay.get_parent().remove_child(old_overlay)
	set_world_scene_blocker("event_prompt", false)
	old_overlay.queue_free()


func _consume_event_display(choice_key: String = "", choice_value: Variant = "") -> void:
	if _state == null:
		return
	var merged: Dictionary = {}
	var operation: Dictionary = _state.consume_pending_operation() if _state.has_method("consume_pending_operation") else {}
	if operation.is_empty():
		return
	var kind := str(operation.get("kind", ""))
	var payload: Dictionary = operation.get("payload", {}) if operation.get("payload", {}) is Dictionary else {}
	var trigger_ctx: Dictionary = operation.get("context", {}).duplicate(true) if operation.get("context", {}) is Dictionary else {}
	if kind in ["prompt", "choice"]:
		# [SRC: PromptController.c:133 -> OnClosePrompt; report 6 A5]
		_state.trigger_events("close_prompt", {})
		if choice_key != "":
			set_log("选择：%s" % str(choice_value))
			DeferredEffects.execute_choice(choice_key, choice_value, _state, _db, _rng, trigger_ctx)
	elif kind == "rename_card":
		var card_uid := int(trigger_ctx.get("card_uid", payload.get("card_uid", 0)))
		if _rename_input == null or not _state.set_card_custom_name(card_uid, _rename_input.text):
			# Keep the operation in front until the player submits a non-empty
			# name; the original naming overlay is likewise a blocking promise.
			_state.pending_operations.push_front(operation)
			return
		set_log("卡牌已命名")
	elif kind == "event":
		# The settlement already ran when the event fired (trigger_events
		# settles immediately and only queues interaction-bearing events);
		# consuming must not execute it a second time. Choice branches still
		# run their subtree here.
		var event_id := int(operation.get("id", 0))
		if choice_key != "":
			set_log("选择：%s" % str(choice_value))
			DeferredEffects.execute_choice(choice_key, choice_value, _state, _db, _rng, trigger_ctx)
	# A silently-settled event chain may have requested game over.
	if _state != null and bool(_state.get("over_pending")):
		_state.over_pending = false
		game_over_requested.emit()
		return
	# An event whose action opens a rite should surface that rite to the player
	# immediately (showing the rite's narration text), not silently park it.
	# The original opens the rite as a UI surface when an event fires it.
	refresh()
	var opened_rite := int(merged.get("rite", 0))
	if opened_rite > 0:
		open_rite.emit(opened_rite)


func _wait_for_queued_sleep(seconds: float) -> void:
	await get_tree().create_timer(maxf(0.0, seconds)).timeout
	if _state != null and _state.has_method("pending_operation") and _state.has_method("consume_pending_operation"):
		if str(_state.pending_operation().get("kind", "")) == "sleep":
			_state.consume_pending_operation()
	_sleep_waiting = false
	_refresh_event_overlay()


## Original portrait for an event: its first `icon` resource (like
## "cards/2000012") resolved against assets/original/cards by basename.
## [SRC: event settlement icon fields (1211 uses, 130 distinct resources)]
func _event_portrait(event: Dictionary) -> Texture2D:
	var icon_res := _first_icon_resource(event)
	if icon_res == "":
		return null
	var name := icon_res.split("/")[-1]
	var path := "res://assets/original/cards/%s.png" % name
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func _first_icon_resource(node: Variant) -> String:
	if node is Dictionary:
		if typeof(node.get("icon")) == TYPE_STRING and str(node.get("icon")) != "":
			return str(node["icon"])
		for key in node:
			var found: String = _first_icon_resource(node[key])
			if found != "":
				return found
	elif node is Array:
		for item in node:
			var found_a: String = _first_icon_resource(item)
			if found_a != "":
				return found_a
	return ""


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
	var scene_rect := (
		Rect2(_desk_map.position, _desk_map.size)
		if _desk_map != null
		else Rect2(Vector2(16, 70) * s, view_size - Vector2(32, 320) * s)
	)
	var panel_w: float = min(maxf(1.0, scene_rect.size.x - 220 * s), 760 * s)
	var panel_h: float = 226 * s if _rename_input != null else 176 * s
	panel_h = minf(panel_h, maxf(1.0, scene_rect.size.y - 36 * s))
	var panel_x: float = scene_rect.position.x + (scene_rect.size.x - panel_w) * 0.5
	var panel_y: float = scene_rect.position.y + 18 * s
	_set_rect(_event_panel, Rect2(Vector2(panel_x, panel_y), Vector2(panel_w, panel_h)))


func _event_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(96, 36)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_color_override("font_color", Color("#f2f0eb"))
	button.add_theme_color_override("font_hover_color", Color("#fff0b6"))
	button.add_theme_stylebox_override("normal", _small_action_style())
	button.add_theme_stylebox_override("hover", _small_action_style(Color("#efc46e")))
	button.add_theme_stylebox_override("pressed", _small_action_style(Color("#fff1bc")))
	return button


func _event_panel_style() -> StyleBox:
	# Texture-first: the original prompt parchment IS the panel surface
	# (9-slice via StyleBoxTexture); the authored dark box only survives
	# when the art is missing. [SRC: Texture2D/prompt.png 632x444]
	var art_path := "res://assets/original/ui/prompt.png"
	if ResourceLoader.exists(art_path):
		var tex := load(art_path) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 70
			style.texture_margin_right = 70
			style.texture_margin_top = 60
			style.texture_margin_bottom = 60
			style.content_margin_left = 76
			style.content_margin_right = 76
			style.content_margin_top = 66
			style.content_margin_bottom = 66
			return style
	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color(0.025, 0.032, 0.075, 0.90)
	fallback.border_color = Color(0.86, 0.88, 0.91, 0.34)
	fallback.set_content_margin_all(16)
	fallback.set_border_width_all(1)
	fallback.set_corner_radius_all(3)
	fallback.shadow_color = Color(0.01, 0.012, 0.03, 0.62)
	fallback.shadow_size = 10
	return fallback


func show_card_detail(card_or_uid: int) -> void:
	var card_uid = _state._resolve_card_uid(card_or_uid) if _state != null and _state.has_method("_resolve_card_uid") else 0
	var card: Dictionary = _state.card_data_for(card_uid, _db) if card_uid > 0 else _db.get_card(card_or_uid).duplicate(true)
	if card.is_empty():
		return
	_show_card_detail(card_uid if card_uid > 0 else int(card.get("id", 0)), card)


func _show_card_detail(card_id: int, card: Dictionary) -> void:
	if card_id <= 0 or card.is_empty():
		return
	var card_uid := int(card.get("instance_uid", 0))
	var same_card := (
		card_uid > 0 and _card_detail_card_uid == card_uid
	) or (
		card_uid <= 0 and _card_detail_card_uid <= 0 and _card_detail_card_id == card_id
	)
	if _card_detail_overlay != null and same_card:
		close_card_detail()
		return
	close_card_detail()
	_card_detail_card_id = card_id
	_card_detail_card_uid = card_uid
	_sync_card_selection_visuals(card_uid, card_id)
	# Card-info timings fire when the detail panel opens.
	# [SRC: GameController.c:4714 -> OnCardInfoOpen; CardInfoNewController.c:601
	#       -> OnCardInfoOpenEnd on close; report 6 A5]
	if _state != null and _state.has_method("trigger_events"):
		_state.trigger_events("open_card_info", {"card": card_id, "card_uid": card_uid})
	_card_detail_overlay = Control.new()
	_card_detail_overlay.name = "CardDetailOverlay"
	_card_detail_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_detail_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_overlay(_card_detail_overlay)
	set_world_scene_blocker("card_detail", true)

	_card_detail_panel = Panel.new()
	_card_detail_panel.name = "CardDetailPanel"
	_card_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_card_detail_panel.clip_contents = true
	_card_detail_panel.add_theme_stylebox_override("panel", _detail_panel_style())
	_card_detail_overlay.add_child(_card_detail_panel)
	# Texture-first: the per-type cardinfo art drives the 9-slice surface
	# (see _detail_panel_style / _detail_backdrop_texture).
	# [SRC: Texture2D/cardinfo_bg_char.png / cardinfo_bg_item.png / cardinfo_bg.png]
	_detail_card_type = str(card.get("type", ""))
	_card_detail_panel.add_theme_stylebox_override("panel", _detail_panel_style())

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
	var perspective_role: String = (
		_state.card_perspective_role(card_uid if card_uid > 0 else int(card.get("id", 0)), _db)
		if _state != null and _state.has_method("card_perspective_role")
		else ""
	)
	subtitle.text = "%s  ·  %s  %s" % [
		perspective_role,
		CardWidget._type_label(str(card.get("type", ""))),
		str(card.get("title", "")),
	]
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
	close.text = ""
	close.tooltip_text = "关闭"
	close.custom_minimum_size = Vector2(42, 42)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# The original close_1 stamp IS the button face.
	# [SRC: Texture2D/close_1.png 80x80; GameScene Close -> close_1]
	var close_style := _close_button_style()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		close.add_theme_stylebox_override(state_name, close_style)
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
	_add_detail_section(info, "装备", _equipment_lines(card))

	# Card art fills the portrait side; the original cardinfo popup shows the
	# full card painting, with the type icon standing in when the card ships
	# without art. [SRC: Texture2D/cards/<id>.png; card_type_char/item/sudan]
	var portrait := TextureRect.new()
	portrait.name = "CardDetailPortrait"
	portrait.custom_minimum_size = Vector2(140, 150)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var art_path := "res://assets/original/cards/%d.png" % int(card.get("id", 0))
	if ResourceLoader.exists(art_path):
		portrait.texture = load(art_path) as Texture2D
	elif ResourceLoader.exists("res://assets/original/ui/card_type_%s.png" % str(card.get("type", "item"))):
		portrait.texture = load(
			"res://assets/original/ui/card_type_%s.png" % str(card.get("type", "item"))
		) as Texture2D
	if portrait.texture == null:
		portrait.texture = load("res://assets/original/ui/card_type_item.png") as Texture2D
	body.add_child(portrait)

	_apply_layout()


func close_card_detail() -> void:
	if _card_detail_overlay == null:
		set_world_scene_blocker("card_detail", false)
		_card_detail_card_id = 0
		_card_detail_card_uid = 0
		_sync_card_selection_visuals()
		return
	# [SRC: CardInfoNewController.c:601 -> OnCardInfoOpenEnd; report 6 A5]
	if _state != null and _state.has_method("trigger_events"):
		_state.trigger_events("open_card_info_end", {
			"card": _card_detail_card_id, "card_uid": _card_detail_card_uid,
		})
	var old_overlay := _card_detail_overlay
	_card_detail_overlay = null
	_card_detail_panel = null
	_card_detail_card_id = 0
	_card_detail_card_uid = 0
	_sync_card_selection_visuals()
	if old_overlay.get_parent() != null:
		old_overlay.get_parent().remove_child(old_overlay)
	set_world_scene_blocker("card_detail", false)
	old_overlay.queue_free()


func _sync_card_selection_visuals(selected_uid: int = 0, selected_id: int = 0) -> void:
	if _card_items == null or not is_instance_valid(_card_items):
		return
	for child in _card_items.get_children():
		if not (child is CardWidget) or child.is_queued_for_deletion():
			continue
		var widget := child as CardWidget
		var matches := selected_uid > 0 and widget.card_uid == selected_uid
		if selected_uid <= 0 and selected_id > 0:
			matches = widget.card_id == selected_id
		widget.set_selected(matches)


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


func _equipment_lines(card: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for equipment in card.get("equipped_cards", []):
		if not (equipment is Dictionary):
			continue
		var slot := str(equipment.get("equipped_slot", ""))
		var name := str(equipment.get("name", equipment.get("id", "?")))
		lines.append("%s：%s" % [slot if not slot.is_empty() else "附着", name])
	return lines


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


func _detail_panel_style() -> StyleBox:
	# Texture-first: original cardinfo art is the surface (set per card type
	# by the caller); authored dark box only without art.
	var art := _detail_backdrop_texture()
	if art != null:
		var style := StyleBoxTexture.new()
		style.texture = art
		style.texture_margin_left = 90
		style.texture_margin_right = 90
		style.texture_margin_top = 70
		style.texture_margin_bottom = 70
		style.content_margin_left = 96
		style.content_margin_right = 96
		style.content_margin_top = 76
		style.content_margin_bottom = 76
		return style
	var flat := FaustTheme.card_style(FaustTheme.GOLD)
	flat.bg_color = Color(0.05, 0.045, 0.035, 0.94)
	flat.set_content_margin_all(18)
	flat.border_width_left = 2
	flat.border_width_right = 2
	flat.border_width_top = 2
	flat.border_width_bottom = 2
	return flat


func _detail_backdrop_texture() -> Texture2D:
	# Current card's type backdrop for the 9-slice detail surface.
	# [SRC: Texture2D/cardinfo_bg_char.png / cardinfo_bg_item.png / cardinfo_bg.png]
	var name := "cardinfo_bg"
	match str(_detail_card_type):
		"char": name = "cardinfo_bg_char"
		"item": name = "cardinfo_bg_item"
	var path := "res://assets/original/ui/%s.png" % name
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _badge_style() -> StyleBox:
	# The original card-info tag plate IS the badge surface.
	# [SRC: Texture2D/card_info_tag.png 52x56]
	var art_path := "res://assets/original/ui/card_info_tag.png"
	if ResourceLoader.exists(art_path):
		var tex := load(art_path) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 14
			style.texture_margin_right = 14
			style.texture_margin_top = 14
			style.texture_margin_bottom = 14
			style.content_margin_left = 16
			style.content_margin_right = 16
			style.content_margin_top = 16
			style.content_margin_bottom = 16
			return style
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#e9edf1")
	style.border_color = FaustTheme.GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(34)
	style.set_content_margin_all(8)
	return style


## The shared original close stamp (close_1) as a button surface.
## [SRC: Texture2D/close_1.png 80x80; GameScene Close -> close_1]
func _close_button_style() -> StyleBox:
	var art_path := "res://assets/original/ui/close_1.png"
	if ResourceLoader.exists(art_path):
		var tex := load(art_path) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 26
			style.texture_margin_right = 26
			style.texture_margin_top = 26
			style.texture_margin_bottom = 26
			return style
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color("#17110d")
	flat.border_color = FaustTheme.GOLD
	flat.set_border_width_all(2)
	flat.set_corner_radius_all(24)
	flat.set_content_margin_all(4)
	return flat
