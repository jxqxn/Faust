## Desktop map presentation mapped to the original MapController.
##
## The source owns a `locations` array, a name-keyed `maps` dictionary, and a
## UID-keyed `pins` dictionary.  Location artwork is the authored GameScene
## layout; rites are individually clickable pins.  This deliberately does not
## expose the clone-era "location -> action list" shortcut: MapController only
## forwards a dropped card to `lastRite` (MapController.c OnDrop), while rites
## enter the map as individual pins (AddPin).
class_name MapController
extends Control

signal open_rite_instance(rite_uid: int)


class ThinkDropZone:
	extends PanelContainer

	var owner_map: Control

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		var accepted := (
			owner_map != null
			and owner_map.has_method("can_drop_card_on_think_button")
			and bool(owner_map.can_drop_card_on_think_button(data))
		)
		if owner_map != null and owner_map.has_method("_set_think_drop_highlight"):
			owner_map.call("_set_think_drop_highlight", accepted)
		return accepted

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if owner_map != null and owner_map.has_method("drop_card_on_think_button"):
			owner_map.drop_card_on_think_button(data)
		if owner_map != null and owner_map.has_method("_set_think_drop_highlight"):
			owner_map.call("_set_think_drop_highlight", false)


## Direct structural counterpart of the original RitePosition component.
## GameScene gives every child an integer name (1-based); AddRite keeps a
## creation-order list and lays that list out at 100 source pixels per entry.
## [SRC: decompiled/RitePosition.c AddRite/RemoveRite/UpdateExistsChild;
##       il2cpp_dump/dump.cs RitePosition@426135.]
class RitePosition:
	extends RefCounted

	var index: int
	var source_position: Vector2
	var rite_uids: Array[int] = []

	func _init(position_index: int, position: Vector2) -> void:
		index = position_index
		source_position = position

	func rite_count() -> int:
		return rite_uids.size()

	func add_rite(rite_uid: int) -> Vector2:
		if rite_uid in rite_uids:
			return source_position + Vector2(float(rite_uids.find(rite_uid)) * 100.0, 0.0)
		# The source calls UpdateExistsChild before the append, then parents the
		# new RiteController at (count_after_add * 100 - 100, 0, 0).
		rite_uids.append(rite_uid)
		return source_position + Vector2(float(rite_uids.size() - 1) * 100.0, 0.0)


## Direct structural counterpart of the original LocationController.  `view`
## is Godot's visual host; placement remains in the original source space.
## [SRC: decompiled/LocationController.c InitInternal/GetPosition;
##       il2cpp_dump/dump.cs LocationController@320988.]
class LocationController:
	extends RefCounted

	var node_name: String
	var location_name: String
	var source_position: Vector2
	var view: Control
	var positions: Array[RitePosition] = []

	func _init(source_node_name: String, source_location_name: String, root_position: Vector2, source_view: Control, source_positions: Array) -> void:
		node_name = source_node_name
		location_name = source_location_name
		source_position = root_position
		view = source_view
		for i in source_positions.size():
			positions.append(RitePosition.new(i + 1, source_positions[i]))

	func get_position(minimum: int, maximum: int) -> RitePosition:
		var last_index := positions.size() if maximum == 2147483647 else maximum
		var selected: RitePosition = null
		# Original uses 1-based inclusive bounds and only replaces on a strictly
		# smaller count, retaining the lower numbered child on ties.
		for index in range(minimum - 1, last_index):
			if index < 0 or index >= positions.size():
				continue
			var candidate := positions[index]
			if selected == null or candidate.rite_count() < selected.rite_count():
				selected = candidate
		return selected


const TABLE_TEXTURE = preload("res://assets/original/situation_desk/table.png")
const MAP_TEXTURE = preload("res://assets/original/situation_desk/table-map.png")

# GameScene/Map RectTransform = 4200 x 2600, local scale 1.25 and position
# (0,-178).  Each entry below is a direct Scene YAML value, not gameplay data.
# [SRC: GameScene.unity MapController@11384, Map RectTransform@7621,
#       LocationController components@12280..12291]
const MAP_SIZE := Vector2(4200.0, 2600.0)
const MAP_LOCAL_OFFSET := Vector2(0.0, -178.0)
const LOCATION_SCENE_SPECS := [
	{"node": "Palace", "location": "宫廷", "position": Vector2(-477, 508), "size": Vector2(690, 446), "active": true, "asset": "Palace.png", "rite_positions": [Vector2(-87, -108), Vector2(104, 58), Vector2(-264, 7), Vector2(159, -220), Vector2(229, -55), Vector2(484, -174), Vector2(-164, -220), Vector2(-405, -108), Vector2(-213, 122), Vector2(438, 62), Vector2(11, 257)]},
	{"node": "Treasure", "location": "奇珍", "position": Vector2(-1238, 263), "size": Vector2(800, 500), "active": true, "rite_positions": [Vector2(1117, 714), Vector2(-152, 33), Vector2(604, -1079), Vector2(2174, -237), Vector2(449, 689), Vector2(2774, 536), Vector2(2736, -941), Vector2(-583, 570), Vector2(1287, -910), Vector2(1767, -1046), Vector2(3129, -777), Vector2(-167, -1122), Vector2(-922, 569), Vector2(3140, 566), Vector2(-802, -1171)]},
	{"node": "Enemy", "location": "大敌", "position": Vector2(-1238, 263), "size": Vector2(800, 500), "active": true, "rite_positions": [Vector2(1328, 188), Vector2(1843, -713), Vector2(1928, -66), Vector2(2737, -791), Vector2(-79, 163), Vector2(-531, -940)]},
	{"node": "Parish", "location": "神殿区", "position": Vector2(-1414, 521), "size": Vector2(800, 500), "active": true, "asset": "Parish_1.png", "rite_positions": [Vector2(-281, -2), Vector2(-467, -285), Vector2(310, 32), Vector2(-419, -141), Vector2(120, 166), Vector2(17, 25), Vector2(-200, 137), Vector2(146, 313), Vector2(-737, -120), Vector2(-681, 61), Vector2(-68, 454)]},
	{"node": "Outside", "location": "野外", "position": Vector2(1380, 197), "size": Vector2(800, 500), "active": true, "asset": "Outside_1.png", "rite_positions": [Vector2(32, 403), Vector2(-353, 99), Vector2(57, 33), Vector2(-217, 565), Vector2(-52, 228), Vector2(-59, -98), Vector2(-460, -353), Vector2(-479, -484), Vector2(-129, -384), Vector2(-399, -634), Vector2(-276, -792), Vector2(-17, -572), Vector2(145, -258), Vector2(251, -418), Vector2(-501, 310)]},
	{"node": "Blackstreet", "location": "黑街", "position": Vector2(439, -70), "size": Vector2(800, 500), "active": true, "asset": "Blackstreet_1.png", "rite_positions": [Vector2(147, 287), Vector2(-139, -179), Vector2(-797, -251), Vector2(-887, -364), Vector2(-567, -420), Vector2(-478, -302), Vector2(-243, -412), Vector2(-141, -298), Vector2(-283, -71), Vector2(-211, 206), Vector2(92, -52), Vector2(201, -175), Vector2(237, 156), Vector2(-945, -137), Vector2(-603, -79), Vector2(-479, -188), Vector2(-72, 92), Vector2(460, 322), Vector2(501, 447), Vector2(-129, -626)]},
	{"node": "Skill", "location": "技能树", "position": Vector2(-1238, 263), "size": Vector2(800, 500), "active": true, "rite_positions": [Vector2(3465, -1461)]},
	{"node": "SelfHome", "location": "自宅", "position": Vector2(-1506, -141), "size": Vector2(321, 211), "active": true, "asset": "SelfHome.png", "rite_positions": [Vector2(24, 3), Vector2(-295, 11), Vector2(44, 120), Vector2(338, -3), Vector2(106, -113), Vector2(82, 234), Vector2(-211, -114), Vector2(-155, -242), Vector2(164, -248), Vector2(-280, 173), Vector2(145, -389), Vector2(440, -532), Vector2(-637, -482), Vector2(-680, 92)]},
	{"node": "Harem", "location": "后宫", "position": Vector2(-1238, 263), "size": Vector2(800, 500), "active": false, "rite_positions": [Vector2(158, 17), Vector2(41, 59)]},
	{"node": "End", "location": "结局", "position": Vector2(-1238, 263), "size": Vector2(800, 500), "active": true, "rite_positions": [Vector2(-904, -731), Vector2(1976, 478), Vector2(0, -500), Vector2(830, -429), Vector2(1185, -32), Vector2(533, 292), Vector2(673, 138), Vector2(3038, 148), Vector2(1102, -170), Vector2(726, -870), Vector2(554, -194), Vector2(900, 539), Vector2(1488, 1447), Vector2(1096, -489), Vector2(282, 464), Vector2(2774, 705), Vector2(2532, 748), Vector2(1523, -859), Vector2(997, 1782), Vector2(1546, 1627)]},
	{"node": "Uptown", "location": "上城区", "position": Vector2(-65, 768), "size": Vector2(723, 383), "active": true, "asset": "Uptown.png", "rite_positions": [Vector2(-675, -754), Vector2(-995, -706), Vector2(-764, -863), Vector2(-445, -864), Vector2(-580, -635), Vector2(-907, -588), Vector2(19, 56), Vector2(409, -136), Vector2(398, -2), Vector2(-36, -78), Vector2(386, 143), Vector2(482, -267)]},
	{"node": "Downtown", "location": "商业区", "position": Vector2(-121, -133), "size": Vector2(800, 500), "active": true, "asset": "Downtown_1.png", "rite_positions": [Vector2(-232, -383), Vector2(95, -238), Vector2(4, 8), Vector2(74, 131), Vector2(-92, -108), Vector2(194, -113), Vector2(-269, -11), Vector2(284, 1), Vector2(261, 397), Vector2(337, -503)]},
]

# RitePin.prefab Icon RectTransform: anchored (0,-17.6), 123x133, pivot
# (0.5,0).  Its root remains at the selected RitePosition; it is not centred
# on that root.  The clone keeps the existing direct-open interaction while
# the separate RiteNew/RiteController card layer is still pending.
# [SRC: Resources/prefab/RitePin.prefab Icon RectTransform@224632457200066912;
#       il2cpp_dump/dump.cs RitePinRender@324544.]
const RITE_PIN_ICON_SIZE := Vector2(123.0, 133.0)
const RITE_PIN_ICON_ANCHORED_POSITION := Vector2(0.0, -17.6)
const RITE_PIN_ICON_PIVOT := Vector2(0.5, 0.0)

var _state
var _db
var _rng
var _scene_blockers: Dictionary = {}
var locations: Array[LocationController] = []
var maps: Dictionary = {}
var pins: Dictionary = {}
var last_rite: int = 0
var ViewRange := Rect2()
var DeskBGSpecial: TextureRect

var _think_drop_zone: ThinkDropZone
var _thinking := false
static var _pin_atlas: OriginalAtlas = null


func setup(state, db = null, rng = null) -> void:
	_state = state
	_db = db
	_rng = rng


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_locations()
	_build_ithink_target()
	resized.connect(_layout)
	_layout()
	refresh_context()
	queue_redraw()


func _build_locations() -> void:
	for spec in LOCATION_SCENE_SPECS:
		var location := Control.new()
		location.name = "Location_%s" % str(spec["node"])
		location.mouse_filter = Control.MOUSE_FILTER_IGNORE
		location.visible = bool(spec.get("active", true))
		add_child(location)
		var controller := LocationController.new(
			str(spec["node"]),
			str(spec["location"]),
			spec["position"],
			location,
			spec.get("rite_positions", [])
		)
		locations.append(controller)
		# MapController.Awake indexes both GameObject name and location label.
		maps[str(spec["node"])] = controller
		maps[str(spec["location"])] = controller
		var asset_name := str(spec.get("asset", ""))
		if asset_name.is_empty():
			continue
		var art := TextureRect.new()
		art.name = "Art"
		art.texture = load("res://assets/original/ui/areas/%s" % asset_name) as Texture2D
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		location.add_child(art)


func _build_ithink_target() -> void:
	_think_drop_zone = ThinkDropZone.new()
	_think_drop_zone.name = "ThinkDropZone"
	_think_drop_zone.owner_map = self
	_think_drop_zone.tooltip_text = "将手牌或苏丹卡拖到这里"
	_think_drop_zone.mouse_default_cursor_shape = Control.CURSOR_CAN_DROP
	var style := StyleBoxTexture.new()
	style.texture = preload("res://assets/original/ui/IThink_01.png")
	style.texture_margin_left = 30
	style.texture_margin_right = 30
	style.texture_margin_top = 24
	style.texture_margin_bottom = 24
	_think_drop_zone.add_theme_stylebox_override("panel", style)
	_think_drop_zone.mouse_exited.connect(_set_think_drop_highlight.bind(false))
	_think_drop_zone.z_index = 8
	add_child(_think_drop_zone)


func refresh_context() -> void:
	refresh_rite_pins()
	queue_redraw()


func set_scene_blocker(source: String, blocking: bool, _hide_chrome: bool = true) -> void:
	if source.is_empty():
		return
	if blocking:
		_scene_blockers[source] = true
	else:
		_scene_blockers.erase(source)
	if _think_drop_zone != null:
		_think_drop_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_scene_blocked() else Control.MOUSE_FILTER_STOP
	for pin in pins.values():
		var button := pin as Button
		if button != null:
			button.disabled = is_scene_blocked()


func is_scene_blocked() -> bool:
	return not _scene_blockers.is_empty()


func can_drop_card_on_think_button(data: Variant) -> bool:
	if is_scene_blocked():
		return false
	var screen := get_parent()
	return screen != null and screen.has_method("can_drop_card_on_methinks") and bool(screen.can_drop_card_on_methinks(data))


func drop_card_on_think_button(data: Variant) -> void:
	if not can_drop_card_on_think_button(data):
		return
	var screen := get_parent()
	if screen != null and screen.has_method("drop_card_on_methinks"):
		screen.drop_card_on_methinks(data)


func _set_think_drop_highlight(highlighted: bool) -> void:
	if _think_drop_zone == null:
		return
	_think_drop_zone.self_modulate = Color("#ffe7a6") if highlighted else Color.WHITE


func set_thinking(enabled: bool) -> void:
	_thinking = enabled


func is_thinking() -> bool:
	return _thinking


func _layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	for spec in LOCATION_SCENE_SPECS:
		var controller := maps.get(str(spec["location"])) as LocationController
		if controller == null:
			continue
		var location := controller.view
		var source_position: Vector2 = spec["position"]
		var source_size: Vector2 = spec["size"]
		var center := _map_local_to_canvas(source_position + MAP_LOCAL_OFFSET)
		location.size = Vector2(source_size.x * size.x / MAP_SIZE.x, source_size.y * size.y / MAP_SIZE.y)
		location.position = (center - location.size * 0.5).round()
	if _think_drop_zone != null:
		_think_drop_zone.size = Vector2(146, 58) * minf(size.x / 3840.0, size.y / 2160.0)
		_think_drop_zone.position = Vector2(size.x * 0.075, size.y * 0.735) - _think_drop_zone.size * 0.5
	_layout_rite_pins()


func _map_local_to_canvas(source_position: Vector2) -> Vector2:
	return Vector2(
		size.x * 0.5 + source_position.x * size.x / MAP_SIZE.x,
		size.y * 0.5 - source_position.y * size.y / MAP_SIZE.y
	)


func refresh_rite_pins() -> void:
	for pin in pins.values():
		if is_instance_valid(pin):
			pin.queue_free()
	pins.clear()
	if _state == null or _db == null:
		return
	if _pin_atlas == null:
		_pin_atlas = OriginalAtlas.load_atlas("res://assets/original/ui/rites.png")
	if _pin_atlas == null:
		return
	var instances: Array = _state.available_rite_instances() if _state.has_method("available_rite_instances") else []
	for instance in instances:
		var rite: Dictionary = _db.rites.get(instance.id, {})
		# MapController.AddPin receives an already-created RiteController.  It
		# does not rebuild an availability list from config/open conditions;
		# those conditions belong to the rite-generation path.
		var texture := _pin_atlas.frame(str(rite.get("icon", "")) + ".png")
		if texture == null:
			continue
		var pin := RitePinButton.new()
		pin.name = "RitePin_%d" % instance.uid
		pin.rite_uid = instance.uid
		pin.rite_id = instance.id
		pin.tooltip_text = str(rite.get("name", instance.id))
		pin.disabled = is_scene_blocked()
		for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
			pin.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
		var art := TextureRect.new()
		art.texture = texture
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pin.add_child(art)
		pin.pressed.connect(_on_rite_pin_pressed.bind(instance.uid))
		pin.z_index = 6
		add_child(pin)
		pins[instance.uid] = pin
	_layout_rite_pins()


func _on_rite_pin_pressed(rite_uid: int) -> void:
	if is_scene_blocked():
		return
	last_rite = rite_uid
	open_rite_instance.emit(rite_uid)


func _layout_rite_pins() -> void:
	var source_positions := _allocate_rite_positions()
	var rite_uids: Array[int] = []
	for raw_uid in pins.keys():
		rite_uids.append(int(raw_uid))
	rite_uids.sort()
	for uid in rite_uids:
		var pin := pins[uid] as Control
		if pin == null:
			continue
		var source_position: Vector2 = source_positions.get(uid, Vector2.ZERO)
		_layout_rite_pin(pin, source_position)


func _layout_rite_pin(pin: Control, source_position: Vector2) -> void:
	var source_scale := Vector2(size.x / MAP_SIZE.x, size.y / MAP_SIZE.y)
	pin.size = RITE_PIN_ICON_SIZE * source_scale
	var root := _map_local_to_canvas(source_position + MAP_LOCAL_OFFSET)
	# Convert the prefab's bottom-pivot Icon rectangle from Unity's y-up map
	# coordinates into Godot's y-down canvas top-left coordinates.
	var source_top_left := Vector2(
		-RITE_PIN_ICON_SIZE.x * RITE_PIN_ICON_PIVOT.x,
		RITE_PIN_ICON_ANCHORED_POSITION.y + RITE_PIN_ICON_SIZE.y * (1.0 - RITE_PIN_ICON_PIVOT.y)
	)
	pin.position = (root + Vector2(source_top_left.x * source_scale.x, -source_top_left.y * source_scale.y)).round()


func _allocate_rite_positions() -> Dictionary:
	# GameController.GetLocationRange parses `area:N` / `area:[N,M]` before
	# GetLocation delegates to LocationController.GetPosition.  This runs in
	# runtime Rite UID creation order, matching the clone's ordered rite carrier.
	# [SRC: decompiled/GameController.c GetLocation/GetLocationRange/AddRitePin;
	#       decompiled/LocationController.c GetPosition;
	#       decompiled/RitePosition.c AddRite.]
	var result: Dictionary = {}
	if _state == null or _db == null:
		return result
	var rite_uids: Array[int] = []
	for raw_uid in pins.keys():
		rite_uids.append(int(raw_uid))
	rite_uids.sort()
	for rite_uid in rite_uids:
		var instance = _state.get_rite_instance(rite_uid) if _state.has_method("get_rite_instance") else null
		if instance == null:
			continue
		var rite: Dictionary = _db.rites.get(instance.id, {})
		var location_range := _location_range(str(rite.get("location", "")))
		var controller := maps.get(str(location_range["name"])) as LocationController
		if controller == null:
			continue
		var position := controller.get_position(int(location_range["min"]), int(location_range["max"]))
		if position != null:
			result[rite_uid] = controller.source_position + position.add_rite(rite_uid)
	return result


static func _location_range(raw_location: String) -> Dictionary:
	var default_range := {"name": raw_location, "min": 1, "max": 2147483647}
	var separator := raw_location.find(":")
	if separator <= 0:
		return default_range
	var name := raw_location.substr(0, separator)
	var suffix := raw_location.substr(separator + 1)
	if suffix.begins_with("[") and suffix.ends_with("]"):
		var parts := suffix.trim_prefix("[").trim_suffix("]").split(",", false)
		if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
			return default_range
		return {"name": name, "min": int(parts[0]), "max": int(parts[1])}
	if not suffix.is_valid_int():
		return default_range
	var fixed_position := int(suffix)
	return {"name": name, "min": fixed_position, "max": fixed_position}


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var table_scale := minf(size.x / TABLE_TEXTURE.get_width(), size.y / TABLE_TEXTURE.get_height())
	var table_size := TABLE_TEXTURE.get_size() * table_scale
	draw_texture_rect(TABLE_TEXTURE, Rect2((size - table_size) * 0.5, table_size), false)
	var map_scale := minf(size.x / MAP_TEXTURE.get_width(), size.y / MAP_TEXTURE.get_height())
	var map_size := MAP_TEXTURE.get_size() * map_scale
	draw_texture_rect(MAP_TEXTURE, Rect2((size - map_size) * 0.5, map_size), false)


class RitePinButton:
	extends Button
	var rite_uid := 0
	var rite_id := 0
