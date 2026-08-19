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


const TABLE_TEXTURE = preload("res://assets/original/situation_desk/table.png")
const MAP_TEXTURE = preload("res://assets/original/situation_desk/table-map.png")

# GameScene/Map RectTransform = 4200 x 2600, local scale 1.25 and position
# (0,-178).  Each entry below is a direct Scene YAML value, not gameplay data.
# [SRC: GameScene.unity MapController@11384, Map RectTransform@7621,
#       LocationController components@12280..12291]
const MAP_SIZE := Vector2(4200.0, 2600.0)
const MAP_LOCAL_OFFSET := Vector2(0.0, -178.0)
const LOCATION_SCENE_SPECS := [
	{"node": "Palace", "location": "宫廷", "position": Vector2(-477, 508), "size": Vector2(690, 446), "active": true, "asset": "Palace.png"},
	{"node": "Treasure", "location": "奇珍", "position": Vector2(-1238, 263), "size": Vector2(800, 500), "active": true},
	{"node": "Enemy", "location": "大敌", "position": Vector2(-1238, 263), "size": Vector2(800, 500), "active": true},
	{"node": "Parish", "location": "神殿区", "position": Vector2(-1414, 521), "size": Vector2(800, 500), "active": true, "asset": "Parish_1.png"},
	{"node": "Outside", "location": "野外", "position": Vector2(1380, 197), "size": Vector2(800, 500), "active": true, "asset": "Outside_1.png"},
	{"node": "Blackstreet", "location": "黑街", "position": Vector2(439, -70), "size": Vector2(800, 500), "active": true, "asset": "Blackstreet_1.png"},
	{"node": "Skill", "location": "技能树", "position": Vector2(-1238, 263), "size": Vector2(800, 500), "active": true},
	{"node": "SelfHome", "location": "自宅", "position": Vector2(-1506, -141), "size": Vector2(321, 211), "active": true, "asset": "SelfHome.png"},
	{"node": "Harem", "location": "后宫", "position": Vector2(-1238, 263), "size": Vector2(800, 500), "active": false},
	{"node": "End", "location": "结局", "position": Vector2(-1238, 263), "size": Vector2(800, 500), "active": true},
	{"node": "Uptown", "location": "上城区", "position": Vector2(-65, 768), "size": Vector2(723, 383), "active": true, "asset": "Uptown.png"},
	{"node": "Downtown", "location": "商业区", "position": Vector2(-121, -133), "size": Vector2(800, 500), "active": true, "asset": "Downtown_1.png"},
]

const PIN_SIZE := Vector2(64.0, 70.0)
const PIN_COLLISION_STEP := Vector2(48.0, 34.0)

var _state
var _db
var _rng
var _scene_blockers: Dictionary = {}
var locations: Array[Control] = []
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
		locations.append(location)
		# MapController.Awake indexes both GameObject name and location label.
		maps[str(spec["node"])] = location
		maps[str(spec["location"])] = location
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
		var location := maps.get(str(spec["location"])) as Control
		if location == null:
			continue
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
	# GameController.GetLocation parses `area:min` / `area:[min,max]` then
	# LocationController.GetPosition chooses the least occupied RitePosition.
	# The corpus lacks the serialized child position list, so this carrier uses
	# the authored location origin plus an explicitly temporary visible
	# separation. It is not a claim of exact MapController.SetPos behaviour;
	# exact RitePosition child coordinates remain unverified.
	var occupied_by_location: Dictionary = {}
	for uid in pins:
		var pin := pins[uid] as Control
		if pin == null:
			continue
		var instance = _state.get_rite_instance(int(uid)) if _state != null and _state.has_method("get_rite_instance") else null
		if instance == null:
			continue
		var rite: Dictionary = _db.rites.get(instance.id, {})
		var location_name := _location_name(str(rite.get("location", "")))
		var index := int(occupied_by_location.get(location_name, 0))
		occupied_by_location[location_name] = index + 1
		var location := maps.get(location_name) as Control
		var center := location.get_rect().get_center() if location != null else size * 0.5
		pin.size = PIN_SIZE * minf(size.x / 3840.0, size.y / 2160.0)
		pin.position = (center + _pin_collision_offset(index) - pin.size * 0.5).round()


static func _location_name(location: String) -> String:
	var separator := location.find(":")
	return location.substr(0, separator) if separator > 0 else location


static func _pin_collision_offset(index: int) -> Vector2:
	if index == 0:
		return Vector2.ZERO
	var ring := ceili((sqrt(float(index)) - 1.0) * 0.5)
	var side := maxf(1.0, ring * 2.0)
	var phase := int(index - (2.0 * ring - 1.0) * (2.0 * ring - 1.0))
	var x := float(phase % int(side * 2.0)) - side + 0.5
	var y := float(phase / int(side * 2.0)) - ring + 0.5
	return Vector2(x * PIN_COLLISION_STEP.x, y * PIN_COLLISION_STEP.y)


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
