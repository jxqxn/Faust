## Rite selector: a scrollable list of currently generated rites grouped by
## location. Every rite uses the same event surface; the estate rite is only the
## first home rite in the player's runtime rite pool.
extends Control

signal rite_chosen(rite_id: int)
signal rite_chosen_instance(rite_uid: int)
signal closed()

const UiMotionScript = preload("res://ui/ui_motion.gd")

const OVERLAY_SHADE_ALPHA := 0.32
const OPEN_DURATION := 0.16
const CLOSE_DURATION := 0.12
const CONTEXT_MENU_MIN_WIDTH := 288.0
const CONTEXT_MENU_MAX_WIDTH := 432.0
const CONTEXT_MENU_MAX_HEIGHT := 224.0

var _db
var _state = null
var _rng = null
var _location_filter := ""
var _overlay_mode := false
var _overlay_anchor := Vector2(-1.0, -1.0)
var _overlay_safe_rect := Rect2()
var _location_order := ["自宅", "商业区", "宫廷", "上城区", "黑街", "神殿区", "野外", "大敌", "奇珍", "结局"]

var _list_container: VBoxContainer
var _overlay_panel: PanelContainer
var _overlay_backdrop: ColorRect
var _title_label: Label
var _scroll_container: ScrollContainer
var _rite_grids: Array[GridContainer] = []
var _first_rite_button: Button
var _action_count := 0
var _closing := false
var _open_motion_started := false
var _motion_direction := Vector2.DOWN


func setup(db, state = null, rng = null, location_filter: String = "") -> void:
	_db = db
	_state = state
	_rng = rng.duplicate_stream() if rng != null and rng.has_method("duplicate_stream") else rng
	_location_filter = location_filter


func set_overlay_mode(enabled: bool) -> void:
	_overlay_mode = enabled


func set_overlay_anchor(anchor: Vector2) -> void:
	_overlay_anchor = anchor
	if is_inside_tree() and _overlay_mode:
		_layout_overlay_panel()


func set_overlay_safe_rect(safe_rect: Rect2) -> void:
	_overlay_safe_rect = safe_rect
	if is_inside_tree() and _overlay_mode:
		_layout_overlay_panel()


func _ready() -> void:
	name = "RiteSelector"
	theme = FaustTheme.get_theme()
	_build_ui()
	if _overlay_mode:
		resized.connect(_layout_overlay_panel)
		call_deferred("_layout_overlay_panel")


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_backdrop = ColorRect.new()
	_overlay_backdrop.name = "RiteSelectorBackdrop"
	_overlay_backdrop.color = (
		Color(0.01, 0.012, 0.025, 0.0)
		if _overlay_mode
		else FaustTheme.BG_DEEP
	)
	_overlay_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	if _overlay_mode:
		_overlay_backdrop.gui_input.connect(_on_backdrop_input)
	add_child(_overlay_backdrop)

	var content_parent: Control = self
	if _overlay_mode:
		_overlay_panel = PanelContainer.new()
		_overlay_panel.name = "RiteSelectorPanel"
		add_child(_overlay_panel)
		_overlay_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_overlay_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_overlay_panel.add_theme_stylebox_override("panel", FaustTheme.card_style(FaustTheme.GOLD))
		content_parent = _overlay_panel

	var margin := MarginContainer.new()
	if not _overlay_mode:
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	content_parent.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	# A context menu keeps the selected place visible. It is not another screen,
	# so closing happens with Esc or a click outside instead of a second return UI.
	_title_label = Label.new()
	_title_label.name = "RiteSelectorTitle"
	_title_label.text = (
		"%s · 可执行行动" % _location_filter
		if not _location_filter.is_empty()
		else "选择仪式"
	)
	_title_label.custom_minimum_size = Vector2(0, 26)
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_title_label)
	# Scrollable list.
	var scroll := ScrollContainer.new()
	scroll.name = "RiteSelectorScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_scroll_container = scroll
	_list_container = VBoxContainer.new()
	_list_container.add_theme_constant_override("separation", 6)
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_container)
	_populate()


func _layout_overlay_panel() -> void:
	if _overlay_panel == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var safe_rect := _context_menu_safe_rect()
	var panel_width := minf(
		safe_rect.size.x,
		CONTEXT_MENU_MIN_WIDTH if _action_count <= 2 else CONTEXT_MENU_MAX_WIDTH
	)
	var columns := 1
	if _action_count >= 3 and panel_width >= 420.0:
		columns = 2
	var action_rows := maxi(1, ceili(float(_action_count) / float(columns)))
	var panel_height := minf(
		safe_rect.size.y,
		minf(
			CONTEXT_MENU_MAX_HEIGHT,
			26.0 + 8.0 + 44.0 * action_rows + 8.0 * (action_rows - 1) + 40.0
		)
	)
	var panel_size := Vector2(panel_width, panel_height)
	var panel_position := safe_rect.get_center() - panel_size * 0.5
	if _overlay_anchor.x >= 0.0 and _overlay_anchor.y >= 0.0:
		var right_x := _overlay_anchor.x + 26.0
		var left_x := _overlay_anchor.x - panel_width - 26.0
		var place_right := _overlay_anchor.x <= safe_rect.get_center().x
		if place_right and right_x + panel_width > safe_rect.end.x and left_x >= safe_rect.position.x:
			place_right = false
		elif not place_right and left_x < safe_rect.position.x and right_x + panel_width <= safe_rect.end.x:
			place_right = true
		panel_position.x = right_x if place_right else left_x

		var above_y := _overlay_anchor.y - panel_height - 18.0
		var below_y := _overlay_anchor.y + 18.0
		var fits_above := above_y >= safe_rect.position.y
		var fits_below := below_y + panel_height <= safe_rect.end.y
		if fits_above and (not fits_below or _overlay_anchor.y >= safe_rect.get_center().y):
			panel_position.y = above_y
		elif fits_below:
			panel_position.y = below_y
	panel_position.x = clampf(
		panel_position.x,
		safe_rect.position.x,
		maxf(safe_rect.position.x, safe_rect.end.x - panel_width)
	)
	panel_position.y = clampf(
		panel_position.y,
		safe_rect.position.y,
		maxf(safe_rect.position.y, safe_rect.end.y - panel_height)
	)
	_overlay_panel.position = panel_position.round()
	_overlay_panel.size = panel_size.round()
	for grid in _rite_grids:
		grid.columns = columns
	var from_panel := _overlay_anchor - Rect2(
		_overlay_panel.position,
		_overlay_panel.size
	).get_center()
	_motion_direction = (
		from_panel.normalized()
		if (
			_overlay_anchor.x >= 0.0
			and _overlay_anchor.y >= 0.0
			and from_panel.length_squared() > 0.001
		)
		else Vector2.DOWN
	)
	if not _open_motion_started:
		_play_open_motion()


func _context_menu_safe_rect() -> Rect2:
	var inset_rect := Rect2(Vector2(18.0, 18.0), size - Vector2(36.0, 36.0))
	if _overlay_safe_rect.size.x <= 0.0 or _overlay_safe_rect.size.y <= 0.0:
		return inset_rect
	var clipped := inset_rect.intersection(_overlay_safe_rect)
	return clipped if clipped.size.x > 0.0 and clipped.size.y > 0.0 else inset_rect


func _play_open_motion() -> void:
	if _overlay_panel == null or _open_motion_started:
		return
	_open_motion_started = true
	_overlay_panel.offset_transform_enabled = true
	_overlay_panel.offset_transform_visual_only = true
	var pivot := (
		(_overlay_anchor - _overlay_panel.position) / _overlay_panel.size
		if _overlay_anchor.x >= 0.0 and _overlay_anchor.y >= 0.0
		else Vector2(0.5, 0.5)
	)
	_overlay_panel.offset_transform_pivot_ratio = Vector2(
		clampf(pivot.x, 0.0, 1.0),
		clampf(pivot.y, 0.0, 1.0)
	)
	if UiMotionScript.reduced_motion:
		_overlay_backdrop.color.a = OVERLAY_SHADE_ALPHA
		_overlay_panel.offset_transform_position = Vector2.ZERO
		_overlay_panel.offset_transform_scale = Vector2.ONE
		_overlay_panel.self_modulate.a = 1.0
	else:
		_overlay_panel.offset_transform_position = _motion_direction * 44.0
		_overlay_panel.offset_transform_scale = Vector2(0.94, 0.94)
		_overlay_panel.self_modulate.a = 0.0
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(
			_overlay_panel,
			"offset_transform_position",
			Vector2.ZERO,
			OPEN_DURATION
		)
		tween.parallel().tween_property(
			_overlay_panel,
			"offset_transform_scale",
			Vector2.ONE,
			OPEN_DURATION
		)
		tween.parallel().tween_property(
			_overlay_panel,
			"self_modulate:a",
			1.0,
			OPEN_DURATION
		)
		tween.parallel().tween_property(
			_overlay_backdrop,
			"color:a",
			OVERLAY_SHADE_ALPHA,
			OPEN_DURATION
		)
	if _first_rite_button != null:
		_first_rite_button.call_deferred("grab_focus")


func _request_close() -> void:
	if _closing:
		return
	_closing = true
	if _overlay_backdrop != null:
		_overlay_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _overlay_mode or _overlay_panel == null or UiMotionScript.reduced_motion:
		_finish_close()
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		_overlay_panel,
		"offset_transform_position",
		_motion_direction * 32.0,
		CLOSE_DURATION
	)
	tween.parallel().tween_property(
		_overlay_panel,
		"offset_transform_scale",
		Vector2(0.96, 0.96),
		CLOSE_DURATION
	)
	tween.parallel().tween_property(
		_overlay_panel,
		"self_modulate:a",
		0.0,
		CLOSE_DURATION
	)
	tween.parallel().tween_property(
		_overlay_backdrop,
		"color:a",
		0.0,
		CLOSE_DURATION
	)
	tween.finished.connect(_finish_close, CONNECT_ONE_SHOT)


func _finish_close() -> void:
	closed.emit()


func _on_backdrop_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		_request_close()
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if (
		_overlay_mode
		and event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_ESCAPE
	):
		_request_close()
		get_viewport().set_input_as_handled()


func _populate() -> void:
	# Group playable rites by location.
	var by_location: Dictionary = {}
	_action_count = 0
	var instances: Array = open_rite_instances()
	# Keep the selector's config-only preview mode used by tests/tools. Actual
	# gameplay always supplies GameState and therefore uses real instances.
	if _state == null:
		for rite_id in open_rite_ids():
			instances.append({"uid": int(rite_id), "id": int(rite_id)})
	for instance in instances:
		var r: Dictionary = _db.rites.get(instance.id, {})
		var loc_name := _location_name(r)
		if not by_location.has(loc_name):
			by_location[loc_name] = []
		by_location[loc_name].append(instance)
	# Render in canonical order, then any leftover.
	var rendered: Dictionary = {}
	for loc_name in _location_order:
		if by_location.has(loc_name):
			_add_location_section(loc_name, by_location[loc_name])
			rendered[loc_name] = true
	for loc_name in by_location:
		if not rendered.has(loc_name):
			_add_location_section(loc_name, by_location[loc_name])
	if _scroll_container != null:
		_scroll_container.vertical_scroll_mode = (
			ScrollContainer.SCROLL_MODE_DISABLED
			if _action_count <= 2
			else ScrollContainer.SCROLL_MODE_AUTO
		)
	if _title_label != null and not _location_filter.is_empty():
		_title_label.text = "%s · %d项行动" % [_location_filter, _action_count]


func _add_location_section(loc_name: String, rids: Array) -> void:
	# Sort rites by id for stable order.
	rids.sort_custom(func(a, b) -> bool: return a.uid < b.uid)
	_action_count += rids.size()
	if _location_filter.is_empty():
		var loc_label := Label.new()
		loc_label.text = "【%s】（%d）" % [loc_name, rids.size()]
		loc_label.add_theme_font_size_override("font_size", 18)
		loc_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
		_list_container.add_child(loc_label)
	# Grid of rite buttons.
	var grid := GridContainer.new()
	grid.name = "RiteGrid_%s" % loc_name
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_rite_grids.append(grid)
	for instance in rids:
		var r: Dictionary = _db.rites.get(instance.id, {})
		var btn := Button.new()
		btn.text = str(r.get("name", str(instance.id)))
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.tooltip_text = str(r.get("text", ""))
		btn.pressed.connect(_on_rite_instance.bind(instance.uid))
		grid.add_child(btn)
		UiMotionScript.bind(btn, UiMotionScript.Profile.SITE)
		if _first_rite_button == null:
			_first_rite_button = btn
	_list_container.add_child(grid)


func _on_rite(rid: int) -> void:
	rite_chosen.emit(rid)


func _on_rite_instance(rite_uid: int) -> void:
	if _state != null and _state.has_method("get_rite_instance"):
		var instance = _state.get_rite_instance(rite_uid)
		if instance != null:
			rite_chosen.emit(instance.id)
	rite_chosen_instance.emit(rite_uid)


func open_rite_ids() -> Array[int]:
	return filter_open_rite_ids(_db, _state, _rng, _location_filter)


func open_rite_instances() -> Array:
	var out: Array = []
	if _state == null or not _state.has_method("available_rite_instances"):
		return out
	for instance in _state.available_rite_instances():
		var rite: Dictionary = _db.rites.get(instance.id, {})
		if not RiteOpen.is_interactive(rite):
			continue
		if _location_filter != "" and _location_name(rite) != _location_filter:
			continue
		if int(rite.get("auto_begin", 0)) == 1:
			if not instance.start:
				continue
		elif not RiteOpen.is_rite_open(rite, _state, _db, _rng):
			continue
		out.append(instance)
	return out


## Static filter so callers can count/query open rites without instantiating a
## RiteSelector node (which would leak, since Nodes are not GC'd). The instance
## open_rite_ids() delegates here.
static func filter_open_rite_ids(db, state, rng, location_filter: String) -> Array[int]:
	var out: Array[int] = []
	if db == null:
		return out
	for rid in db.rites:
		var r: Dictionary = db.rites[rid]
		var id := int(rid)
		if not RiteOpen.is_interactive(r):
			continue
		if location_filter != "" and _location_name(r) != location_filter:
			continue
		if state != null and state.get("available_rites") != null and not (id in state.available_rites):
			continue
		if not _is_rite_open(r, db, state, rng):
			continue
		out.append(id)
	out.sort()
	return out


static func filter_open_rite_instance_uids(db, state, rng, location_filter: String) -> Array[int]:
	var out: Array[int] = []
	if db == null or state == null or not state.has_method("available_rite_instances"):
		return out
	for instance in state.available_rite_instances():
		var rite: Dictionary = db.rites.get(instance.id, {})
		if not RiteOpen.is_interactive(rite):
			continue
		if location_filter != "" and _location_name(rite) != location_filter:
			continue
		if int(rite.get("auto_begin", 0)) == 1:
			if not instance.start:
				continue
		elif not RiteOpen.is_rite_open(rite, state, db, rng):
			continue
		out.append(instance.uid)
	out.sort()
	return out


static func _location_name(rite: Dictionary) -> String:
	return str(rite.get("location", "?")).split(":")[0]


static func _is_rite_open(rite: Dictionary, db, state, rng) -> bool:
	var id := int(rite.get("id", 0))
	if int(rite.get("auto_begin", 0)) == 1:
		return state != null and id in state.started_rites
	return RiteOpen.is_rite_open(rite, state, db, rng)
