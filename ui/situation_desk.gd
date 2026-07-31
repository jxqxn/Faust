## The primary tabletop-map play surface.
##
## SituationDesk owns only presentation state. The pawn records the most
## recently inspected action site for this node's lifetime; it never writes to
## GameState, SaveSystem, Rite, Queue, RNG, or the lateral scene location.
class_name SituationDesk
extends Control

signal open_rite_selector(location_name: String)
signal open_rite_instance(rite_uid: int)
signal context_requested()
signal site_navigation_active_changed(active: bool)


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


const WorldScenes = preload("res://sim/world_scene_catalog.gd")
const UiMotionScript = preload("res://ui/ui_motion.gd")
const RiteSelectorScript = preload("res://ui/rite_selector.gd")
const MAP_TEXTURE = preload("res://assets/original/situation_desk/tabletop_campaign_map.png")
const NODE_TEXTURE = preload("res://assets/original/situation_desk/map_node_token.png")
const PAWN_TEXTURE = preload("res://assets/original/situation_desk/protagonist_pawn.png")

const SITE_SPECS := [
	{"id": "home", "name": "SiteHome", "label": "家", "location": "自宅", "position": Vector2(0.18, 0.67)},
	{"id": "market", "name": "SiteMarket", "label": "商店街", "location": "商业区", "position": Vector2(0.40, 0.38)},
	{"id": "palace", "name": "SitePalace", "label": "校舍", "location": "宫廷", "position": Vector2(0.57, 0.62)},
	{"id": "temple", "name": "SiteTemple", "label": "旧校舍", "location": "神殿区", "position": Vector2(0.73, 0.31)},
	{"id": "wild", "name": "SiteWild", "label": "河堤", "location": "野外", "position": Vector2(0.82, 0.72)},
]
const WAYPOINT_SPECS := [
	{"id": "west", "position": Vector2(0.29, 0.55)},
	{"id": "east", "position": Vector2(0.70, 0.60)},
]
const ROUTE_EDGES := [
	["home", "west"],
	["west", "market"],
	["market", "palace"],
	["palace", "temple"],
	["palace", "east"],
	["east", "wild"],
]
const SITE_NODE_SIZE := Vector2(72.0, 58.0)
const WAYPOINT_NODE_SIZE := Vector2(34.0, 27.0)
const PAWN_SIZE := Vector2(88.0, 112.0)
const MAP_TOP_SCALE := 0.90
const MAP_VERTICAL_SCALE := 0.94
const EDGE_DURATION := 0.16
const MAX_NAVIGATION_DURATION := 0.56

const PAPER_LIGHT := Color("#ead79a")
const PAPER_SHADOW := Color("#3c281a")
const INK := Color("#251a13")
const MUTED_INK := Color("#5d452f")
const RED_WAX := Color("#8a3a31")
const ROUTE_DARK := Color(0.15, 0.10, 0.07, 0.72)
const ROUTE_LIGHT := Color(0.90, 0.76, 0.44, 0.72)

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
var _dossier: Button
var _think_drop_zone: ThinkDropZone
var _think_drop_label: Label
var _site_buttons: Array[Button] = []
var _selected_site_button: Button
var _selected_site_location := ""
var _pawn: TextureRect
var _pawn_shadow: TextureRect
var _pawn_location_id := "home"
var _navigation_active := false
var _navigation_tween: Tween


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

	_dossier = Button.new()
	_dossier.name = "CurrentSceneDossier"
	_dossier.text = "进入现场"
	_dossier.tooltip_text = "打开当前保存的现场"
	_dossier.add_theme_font_size_override("font_size", 14)
	_dossier.add_theme_color_override("font_color", INK)
	_dossier.add_theme_color_override("font_hover_color", Color("#6b231d"))
	_dossier.add_theme_stylebox_override("normal", _paper_prop_style(PAPER_SHADOW))
	_dossier.add_theme_stylebox_override("hover", _paper_prop_style(RED_WAX, true))
	_dossier.add_theme_stylebox_override("pressed", _paper_prop_style(Color("#b58e43"), true))
	_dossier.pressed.connect(func(): context_requested.emit())
	_dossier.z_index = 8
	add_child(_dossier)
	UiMotionScript.bind(_dossier, UiMotionScript.Profile.SITE)

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

	_pawn_shadow = TextureRect.new()
	_pawn_shadow.name = "TabletopPawnShadow"
	_pawn_shadow.texture = PAWN_TEXTURE
	_pawn_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pawn_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pawn_shadow.modulate = Color(0.05, 0.035, 0.02, 0.34)
	_pawn_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pawn_shadow.z_index = 10
	add_child(_pawn_shadow)

	_pawn = TextureRect.new()
	_pawn.name = "TabletopProtagonistPawn"
	_pawn.texture = PAWN_TEXTURE
	_pawn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pawn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pawn.z_index = 11
	add_child(_pawn)


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
	var location_id := str(_state.world_location_id)
	var location_data: Dictionary = WorldScenes.location(location_id)
	var title := str(location_data.get("title", location_id))
	_subtitle.text = "地图 · 行动档案"
	_dossier.text = "进入现场\n现场档案"
	_dossier.tooltip_text = "进入当前保存的%s现场；现场位置会继续写入当前存档" % title
	_refresh_site_availability()
	queue_redraw()


func _on_site_pressed(button: Button, location_name: String, site_id: String) -> void:
	if button == null or _navigation_active or is_scene_blocked():
		return
	_selected_site_button = button
	_selected_site_location = location_name
	if site_id == _pawn_location_id:
		open_rite_selector.emit(location_name)
		return
	_start_navigation(site_id, location_name)


func _start_navigation(destination_id: String, location_name: String) -> void:
	var path := _shortest_path(_pawn_location_id, destination_id)
	if path.size() < 2:
		_pawn_location_id = destination_id
		_place_pawn_at_id(destination_id)
		open_rite_selector.emit(location_name)
		return
	_set_navigation_active(true)
	if UiMotionScript.reduced_motion:
		_pawn_location_id = destination_id
		_place_pawn_at_id(destination_id)
		_finish_navigation(location_name)
		return
	var edge_count := path.size() - 1
	var edge_duration := minf(EDGE_DURATION, MAX_NAVIGATION_DURATION / float(edge_count))
	_navigation_tween = create_tween()
	_navigation_tween.set_trans(Tween.TRANS_SINE)
	_navigation_tween.set_ease(Tween.EASE_IN_OUT)
	for path_index in range(1, path.size()):
		var destination := _pawn_position_for_center(_point_for_id(str(path[path_index])))
		_navigation_tween.tween_property(_pawn, "position", destination, edge_duration)
		_navigation_tween.parallel().tween_property(
			_pawn_shadow,
			"position",
			destination + Vector2(5.0, 7.0),
			edge_duration
		)
	_pawn_location_id = destination_id
	_navigation_tween.finished.connect(_finish_navigation.bind(location_name), CONNECT_ONE_SHOT)


func _finish_navigation(location_name: String) -> void:
	_navigation_tween = null
	_place_pawn_at_id(_pawn_location_id)
	# Open synchronously before releasing this blocker. The selector installs
	# its own blocker during the emitted call, so no input-active frame exists
	# between travel and the action list.
	open_rite_selector.emit(location_name)
	_set_navigation_active(false)


func _set_navigation_active(active: bool) -> void:
	if _navigation_active == active:
		return
	_navigation_active = active
	_update_site_input_state()
	site_navigation_active_changed.emit(active)


func is_site_navigation_active() -> bool:
	return _navigation_active


func pawn_location_name() -> String:
	for spec in SITE_SPECS:
		if str(spec["id"]) == _pawn_location_id:
			return str(spec["location"])
	return ""


func _shortest_path(start_id: String, destination_id: String) -> Array[String]:
	if start_id == destination_id:
		return [start_id]
	var neighbours: Dictionary = {}
	for edge in ROUTE_EDGES:
		var from_id := str(edge[0])
		var to_id := str(edge[1])
		if not neighbours.has(from_id):
			neighbours[from_id] = []
		if not neighbours.has(to_id):
			neighbours[to_id] = []
		neighbours[from_id].append(to_id)
		neighbours[to_id].append(from_id)
	var queue: Array[String] = [start_id]
	var previous := {start_id: ""}
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for neighbour_value in neighbours.get(current, []):
			var neighbour := str(neighbour_value)
			if previous.has(neighbour):
				continue
			previous[neighbour] = current
			if neighbour == destination_id:
				var path: Array[String] = [destination_id]
				var cursor: String = current
				while not cursor.is_empty():
					path.push_front(cursor)
					cursor = str(previous.get(cursor, ""))
				return path
			queue.append(neighbour)
	return [start_id, destination_id]


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
			or _navigation_active
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


func protagonist_center() -> Vector2:
	return _point_for_id(_pawn_location_id)


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

	_dossier.size = Vector2(142.0, 56.0) if compact else Vector2(158.0, 60.0)
	# Match the scene's return control anchor so entering and leaving remains a
	# spatially reversible action even though the map itself is projected.
	_dossier.position = Vector2(36.0, 26.0)
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
	_place_pawn_at_id(_pawn_location_id)
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
	for spec in WAYPOINT_SPECS:
		if str(spec["id"]) == point_id:
			return _project_ratio(spec["position"] as Vector2)
	return _project_ratio(Vector2(0.5, 0.5))


func _pawn_position_for_center(center: Vector2) -> Vector2:
	# The contact point is near the bottom of the transparent square sprite.
	return center - Vector2(PAWN_SIZE.x * 0.5, PAWN_SIZE.y * 0.84)


func _place_pawn_at_id(point_id: String) -> void:
	if _pawn == null or _pawn_shadow == null:
		return
	var pawn_position := _pawn_position_for_center(_point_for_id(point_id))
	_pawn.size = PAWN_SIZE
	_pawn.position = pawn_position
	_pawn_shadow.size = PAWN_SIZE
	_pawn_shadow.position = pawn_position + Vector2(5.0, 7.0)


func _update_chrome_visibility() -> void:
	var hide_chrome := is_scene_chrome_hidden()
	_dossier.visible = not hide_chrome
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
	_pawn.visible = not hide_chrome
	_pawn_shadow.visible = not hide_chrome


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

	for edge in ROUTE_EDGES:
		var from := _point_for_id(str(edge[0]))
		var to := _point_for_id(str(edge[1]))
		draw_line(from + Vector2(0.0, 3.0), to + Vector2(0.0, 3.0), Color(0.02, 0.012, 0.008, 0.48), 9.0, true)
		draw_line(from, to, ROUTE_DARK, 7.0, true)
		draw_line(from, to, ROUTE_LIGHT, 3.0, true)
	for spec in WAYPOINT_SPECS:
		var point := _project_ratio(spec["position"] as Vector2)
		var shadow_rect := Rect2(point - WAYPOINT_NODE_SIZE * 0.5 + Vector2(2.0, 4.0), WAYPOINT_NODE_SIZE)
		draw_texture_rect(NODE_TEXTURE, shadow_rect, false, Color(0.04, 0.025, 0.015, 0.48))
		draw_texture_rect(NODE_TEXTURE, Rect2(point - WAYPOINT_NODE_SIZE * 0.5, WAYPOINT_NODE_SIZE), false)


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
