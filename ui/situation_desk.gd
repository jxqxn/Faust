## The primary tabletop-map play surface.
##
## SituationDesk owns only presentation state: the map sites, their available
## action counts, and the think drop zone. It never writes to GameState,
## SaveSystem, Rite, Queue, or RNG.
class_name SituationDesk
extends Control

signal open_rite_selector(location_name: String)
signal open_rite_instance(rite_uid: int)


class ThinkDropZone:
	extends PanelContainer

	var owner_desk: Control

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		var accepted := (
			owner_desk != null
			and owner_desk.has_method("can_drop_card_on_think_button")
			and bool(owner_desk.can_drop_card_on_think_button(data))
		)
		if owner_desk != null and owner_desk.has_method("_set_think_drop_highlight"):
			owner_desk.call("_set_think_drop_highlight", accepted)
		return accepted

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if owner_desk != null and owner_desk.has_method("drop_card_on_think_button"):
			owner_desk.drop_card_on_think_button(data)
		if owner_desk != null and owner_desk.has_method("_set_think_drop_highlight"):
			owner_desk.call("_set_think_drop_highlight", false)


const UiMotionScript = preload("res://ui/ui_motion.gd")
const RiteSelectorScript = preload("res://ui/rite_selector.gd")
const MAP_TEXTURE = preload("res://assets/original/situation_desk/tabletop_campaign_map.png")
const NODE_TEXTURE = preload("res://assets/original/situation_desk/map_node_token.png")

const SITE_SPECS := [
	{"id": "home", "name": "SiteHome", "label": "自宅", "location": "自宅", "position": Vector2(0.18, 0.67)},
	{"id": "market", "name": "SiteMarket", "label": "商业区", "location": "商业区", "position": Vector2(0.40, 0.38)},
	{"id": "palace", "name": "SitePalace", "label": "宫廷", "location": "宫廷", "position": Vector2(0.57, 0.62)},
	{"id": "temple", "name": "SiteTemple", "label": "神殿区", "location": "神殿区", "position": Vector2(0.73, 0.31)},
	{"id": "wild", "name": "SiteWild", "label": "野外", "location": "野外", "position": Vector2(0.82, 0.72)},
]
const SITE_NODE_SIZE := Vector2(72.0, 58.0)
const MAP_TOP_SCALE := 0.90
const MAP_VERTICAL_SCALE := 0.94

const PAPER_LIGHT := Color("#ead79a")
const PAPER_SHADOW := Color("#3c281a")
const INK := Color("#251a13")
const MUTED_INK := Color("#5d452f")
const RED_WAX := Color("#8a3a31")

var _state
var _db
var _rng
var _scene_blockers: Dictionary = {}
var _site_action_counts: Dictionary = {}
var _site_buttons_by_id: Dictionary = {}
var _site_id_by_location: Dictionary = {}
var _site_labels_by_id: Dictionary = {}
var _count_chits_by_id: Dictionary = {}

var _title: Label
var _subtitle: Label
var _think_drop_zone: ThinkDropZone
var _think_drop_label: Label
var _site_buttons: Array[Button] = []
var _selected_site_button: Button
var _selected_site_location := ""


func setup(state, db = null, rng = null) -> void:
	_state = state
	_db = db
	_rng = rng


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_ALL
	_build_chrome()
	resized.connect(_layout)
	_layout()
	refresh_context()
	queue_redraw()


func _build_chrome() -> void:
	_title = Label.new()
	_title.name = "SituationDeskTitle"
	_title.text = "当日形势"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", INK)
	_title.add_theme_color_override("font_outline_color", Color(0.96, 0.85, 0.57, 0.78))
	_title.add_theme_constant_override("outline_size", 3)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.z_index = 7
	add_child(_title)

	_subtitle = Label.new()
	_subtitle.name = "SituationDeskSubtitle"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 12)
	_subtitle.add_theme_color_override("font_color", Color(0.15, 0.10, 0.07, 0.78))
	_subtitle.add_theme_color_override("font_outline_color", Color(0.96, 0.85, 0.57, 0.74))
	_subtitle.add_theme_constant_override("outline_size", 2)
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.z_index = 7
	add_child(_subtitle)

	_think_drop_zone = ThinkDropZone.new()
	_think_drop_zone.name = "ThinkDropZone"
	_think_drop_zone.owner_desk = self
	_think_drop_zone.tooltip_text = "将手牌或苏丹卡拖到这里，触发既有思考事件"
	_think_drop_zone.mouse_default_cursor_shape = Control.CURSOR_CAN_DROP
	_think_drop_zone.add_theme_stylebox_override("panel", _paper_prop_style(PAPER_SHADOW))
	_think_drop_zone.mouse_exited.connect(_set_think_drop_highlight.bind(false))
	_think_drop_zone.z_index = 8
	add_child(_think_drop_zone)

	_think_drop_label = Label.new()
	_think_drop_label.text = "拖入卡牌\n以思考"
	_think_drop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_think_drop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_think_drop_label.add_theme_font_size_override("font_size", 14)
	_think_drop_label.add_theme_color_override("font_color", INK)
	_think_drop_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_think_drop_zone.add_child(_think_drop_label)
	_think_drop_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for spec in SITE_SPECS:
		_build_site(spec)


func _build_site(spec: Dictionary) -> void:
	var site_id := str(spec["id"])
	var location_name := str(spec["location"])
	var button := Button.new()
	button.name = str(spec["name"])
	button.text = "%s · 0" % str(spec["label"])
	button.tooltip_text = "查看%s可进行的行动" % location_name
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, Color.TRANSPARENT)
	button.pressed.connect(_on_site_pressed.bind(button, location_name, site_id))
	button.z_index = 5
	_site_buttons.append(button)
	_site_buttons_by_id[site_id] = button
	_site_id_by_location[location_name] = site_id
	add_child(button)

	var shadow := TextureRect.new()
	shadow.name = "NodeShadow"
	shadow.texture = NODE_TEXTURE
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shadow.position = Vector2(3.0, 5.0)
	shadow.size = SITE_NODE_SIZE
	shadow.modulate = Color(0.04, 0.025, 0.015, 0.44)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(shadow)

	var token := TextureRect.new()
	token.name = "NodeToken"
	token.texture = NODE_TEXTURE
	token.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	token.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	token.size = SITE_NODE_SIZE
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(token)
	UiMotionScript.bind(button, UiMotionScript.Profile.SITE)

	var ink_label := Label.new()
	ink_label.name = "MapLabel_%s" % site_id
	ink_label.text = str(spec["label"])
	ink_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ink_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ink_label.add_theme_font_size_override("font_size", 15)
	ink_label.add_theme_color_override("font_color", INK)
	ink_label.add_theme_color_override("font_outline_color", Color(0.93, 0.78, 0.43, 0.76))
	ink_label.add_theme_constant_override("outline_size", 3)
	ink_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink_label.z_index = 7
	add_child(ink_label)
	_site_labels_by_id[site_id] = ink_label

	var chit := PanelContainer.new()
	chit.name = "ActionCount_%s" % site_id
	chit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chit.add_theme_stylebox_override("panel", _count_chit_style())
	chit.z_index = 8
	var count_label := Label.new()
	count_label.name = "Count"
	count_label.text = "0"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 11)
	count_label.add_theme_color_override("font_color", Color("#f4e7bc"))
	chit.add_child(count_label)
	add_child(chit)
	_count_chits_by_id[site_id] = chit


func refresh_context() -> void:
	if _state == null:
		return
	_subtitle.text = "地图 · 行动档案"
	_refresh_site_availability()
	queue_redraw()


func _on_site_pressed(button: Button, location_name: String, _site_id: String) -> void:
	if button == null or is_scene_blocked():
		return
	_selected_site_button = button
	_selected_site_location = location_name
	open_rite_selector.emit(location_name)


func site_action_anchor(location_name: String) -> Vector2:
	var button := _site_button_for_location(location_name)
	if button == null:
		return Vector2(-1.0, -1.0)
	return button.position + button.size * 0.5


func clear_site_focus() -> void:
	var previous := _selected_site_button
	_selected_site_button = null
	_selected_site_location = ""
	if (
		previous != null
		and is_instance_valid(previous)
		and previous.visible
		and not previous.disabled
	):
		previous.call_deferred("grab_focus")


func _site_button_for_location(location_name: String) -> Button:
	var site_id := str(_site_id_by_location.get(location_name, ""))
	return _site_buttons_by_id.get(site_id) as Button


func _refresh_site_availability() -> void:
	if _db == null or _state == null:
		return
	for spec in SITE_SPECS:
		var site_id := str(spec["id"])
		var button := _site_buttons_by_id[site_id] as Button
		var location_name := str(spec["location"])
		var availability_rng = (
			_rng.duplicate_stream()
			if _rng != null and _rng.has_method("duplicate_stream")
			else _rng
		)
		var open_uids := RiteSelectorScript.filter_open_rite_instance_uids(
			_db, _state, availability_rng, location_name
		)
		var count := open_uids.size()
		_site_action_counts[site_id] = count
		button.text = "%s · %s" % [str(spec["label"]), str(count) if count > 0 else "无"]
		button.tooltip_text = (
			"%s有 %d 项可处理行动" % [location_name, count]
			if count > 0
			else "%s当前没有可处理行动" % location_name
		)
		var chit := _count_chits_by_id[site_id] as PanelContainer
		var count_label := chit.get_node("Count") as Label
		count_label.text = str(count) if count > 0 else "—"
		chit.self_modulate = Color.WHITE if count > 0 else Color(0.68, 0.63, 0.54, 0.72)
		var token := button.get_node("NodeToken") as TextureRect
		token.self_modulate = Color.WHITE if count > 0 else Color(0.68, 0.65, 0.58, 0.76)
		var ink_label := _site_labels_by_id[site_id] as Label
		ink_label.self_modulate = Color.WHITE if count > 0 else Color(0.58, 0.55, 0.50, 0.78)
		if count == 0 and location_name == _selected_site_location:
			clear_site_focus()
	_update_site_input_state()


func _update_site_input_state() -> void:
	var blocked := is_scene_blocked()
	for spec in SITE_SPECS:
		var site_id := str(spec["id"])
		var button := _site_buttons_by_id[site_id] as Button
		button.disabled = (
			int(_site_action_counts.get(site_id, 0)) == 0
			or blocked
		)


func _set_think_drop_highlight(highlighted: bool) -> void:
	if _think_drop_zone == null:
		return
	_think_drop_zone.add_theme_stylebox_override(
		"panel",
		_paper_prop_style(RED_WAX, true) if highlighted else _paper_prop_style(PAPER_SHADOW)
	)


func set_thinking(_enabled: bool) -> void:
	pass


func is_thinking() -> bool:
	return false


## Global pause layers retain the desk exactly as it was; they block input via
## their own shade instead of hiding the already-visible tabletop components.
func set_scene_blocker(source: String, blocking: bool, hide_chrome: bool = true) -> void:
	if source.is_empty():
		return
	if blocking:
		_scene_blockers[source] = hide_chrome
	else:
		_scene_blockers.erase(source)
	_update_chrome_visibility()
	_update_site_input_state()
	queue_redraw()


func is_scene_blocked() -> bool:
	return not _scene_blockers.is_empty()


func is_scene_chrome_hidden() -> bool:
	for hide_chrome in _scene_blockers.values():
		if bool(hide_chrome):
			return true
	return false


func can_drop_card_on_think_button(data: Variant) -> bool:
	if is_scene_blocked():
		return false
	var screen := get_parent()
	return (
		screen != null
		and screen.has_method("can_drop_card_on_methinks")
		and bool(screen.can_drop_card_on_methinks(data))
	)


func drop_card_on_think_button(data: Variant) -> void:
	if not can_drop_card_on_think_button(data):
		return
	var screen := get_parent()
	if screen != null and screen.has_method("drop_card_on_methinks"):
		screen.drop_card_on_methinks(data)


func _layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var compact := size.x < 760.0
	var title_center := _project_ratio(Vector2(0.50, 0.07))
	var title_width := minf(320.0, size.x * 0.40)
	_title.position = Vector2(title_center.x - title_width * 0.5, title_center.y - 18.0)
	_title.size = Vector2(title_width, 32.0)
	_subtitle.position = Vector2(title_center.x - title_width * 0.65, title_center.y + 12.0)
	_subtitle.size = Vector2(title_width * 1.3, 22.0)
	_title.add_theme_font_size_override("font_size", 20 if compact else 24)
	_subtitle.add_theme_font_size_override("font_size", 10 if compact else 12)

	var think_center := _project_ratio(Vector2(0.12, 0.79))
	_think_drop_zone.size = Vector2(134.0, 54.0) if compact else Vector2(146.0, 58.0)
	_think_drop_zone.position = think_center - _think_drop_zone.size * 0.5

	var label_size := Vector2(110.0, 26.0) if not compact else Vector2(82.0, 24.0)
	for spec in SITE_SPECS:
		var site_id := str(spec["id"])
		var center := _project_ratio(spec["position"] as Vector2)
		var site := _site_buttons_by_id[site_id] as Button
		site.size = SITE_NODE_SIZE
		site.position = center - SITE_NODE_SIZE * 0.5
		var ink_label := _site_labels_by_id[site_id] as Label
		ink_label.size = label_size
		ink_label.position = center + Vector2(-label_size.x * 0.5, SITE_NODE_SIZE.y * 0.46)
		ink_label.add_theme_font_size_override("font_size", 13 if compact else 15)
		var chit := _count_chits_by_id[site_id] as PanelContainer
		chit.size = Vector2(26.0, 22.0)
		chit.position = center + Vector2(SITE_NODE_SIZE.x * 0.30, -SITE_NODE_SIZE.y * 0.36)
	queue_redraw()


func _project_ratio(ratio: Vector2) -> Vector2:
	var y := size.y * 0.5 + (ratio.y - 0.5) * size.y * MAP_VERTICAL_SCALE
	var depth_scale := lerpf(MAP_TOP_SCALE, 1.0, ratio.y)
	var x := size.x * 0.5 + (ratio.x - 0.5) * size.x * depth_scale
	return Vector2(x, y)


func _point_for_id(point_id: String) -> Vector2:
	for spec in SITE_SPECS:
		if str(spec["id"]) == point_id:
			return _project_ratio(spec["position"] as Vector2)
	return _project_ratio(Vector2(0.5, 0.5))


func _update_chrome_visibility() -> void:
	var hide_chrome := is_scene_chrome_hidden()
	_think_drop_zone.visible = not hide_chrome
	_title.visible = not hide_chrome
	_subtitle.visible = not hide_chrome
	for site in _site_buttons:
		if is_instance_valid(site):
			site.visible = not hide_chrome
	for label in _site_labels_by_id.values():
		(label as Control).visible = not hide_chrome
	for chit in _count_chits_by_id.values():
		(chit as Control).visible = not hide_chrome


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var map_points := PackedVector2Array([
		_project_ratio(Vector2(0.0, 0.0)),
		_project_ratio(Vector2(1.0, 0.0)),
		_project_ratio(Vector2(1.0, 1.0)),
		_project_ratio(Vector2(0.0, 1.0)),
	])
	var shadow_points := PackedVector2Array()
	for point in map_points:
		shadow_points.append(point + Vector2(0.0, 9.0))
	draw_colored_polygon(shadow_points, Color(0.02, 0.014, 0.009, 0.72))
	draw_polygon(
		map_points,
		PackedColorArray([Color.WHITE]),
		PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]),
		MAP_TEXTURE
	)
	var border := PackedVector2Array([map_points[0], map_points[1], map_points[2], map_points[3], map_points[0]])
	draw_polyline(border, Color(0.83, 0.68, 0.35, 0.74), 2.0, true)


func _paper_prop_style(border: Color, highlighted := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#e5ce8d") if not highlighted else Color("#f0dda6")
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(6)
	style.shadow_color = Color(0.08, 0.04, 0.02, 0.42)
	style.shadow_size = 5
	style.shadow_offset = Vector2(3.0, 4.0)
	return style


func _count_chit_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#6d3c28")
	style.border_color = Color("#d4ad5a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.shadow_color = Color(0.04, 0.02, 0.01, 0.48)
	style.shadow_size = 3
	style.shadow_offset = Vector2(2.0, 2.0)
	style.set_content_margin_all(2)
	return style
