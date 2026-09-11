## Desktop map presentation mapped to the original MapController.
##
## The source owns a `locations` array, a name-keyed `maps` dictionary, and a
## config-id-keyed `pins` dictionary and UID-keyed `rite_cards` dictionary.
## A completed final_pin rite creates the former; a live Rite creates the
## latter. This deliberately does not expose the clone-era "location -> action
## list" shortcut: only the RiteNew/RiteController card can open a rite.
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

	func remove_rite(rite_uid: int) -> void:
		rite_uids.erase(rite_uid)


## Godot rendering host for LineCreator/LineController.  It intentionally owns
## only the already-parsed original FromPin data; it is not a new map graph.
## [SRC: decompiled/MapController.c RefreshRitePinLines/CreateLine
##       (0x5690d0/0x568360); decompiled/LineController.c GenerateLine
##       (0x42edd0); il2cpp_dump/dump.cs RiteNode.FromPin@393030.]
class RitePinLineView:
	extends Control

	var target_rite_id := 0
	var source_rite_id := 0
	var sampled_points := PackedVector2Array()
	var arrow_points := PackedVector2Array()
	var line_color := Color.WHITE
	var line_width := 1.0
	var dashed := false

	func _draw() -> void:
		if dashed:
			for point_index in range(0, sampled_points.size() - 1, 2):
				draw_line(sampled_points[point_index], sampled_points[point_index + 1], line_color, line_width, true)
		elif sampled_points.size() >= 2:
			draw_polyline(sampled_points, line_color, line_width, true)
		if arrow_points.size() == 3:
			draw_line(arrow_points[0], arrow_points[1], line_color, line_width, true)
			draw_line(arrow_points[2], arrow_points[1], line_color, line_width, true)


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
const END_MAP_TEXTURE = preload("res://assets/original/situation_desk/table-map-end.png")

# GameScene/Map RectTransform = 4200 x 2600, local scale 1.25 and position
# (0,-178).  Each entry below is a direct Scene YAML value, not gameplay data.
# [SRC: GameScene.unity MapController@11384, Map RectTransform@7621,
#       LocationController components@12280..12291]
const MAP_SIZE := Vector2(4200.0, 2600.0)
const MAP_LOCAL_OFFSET := Vector2(0.0, -178.0)
# [SRC: GameScene Desktop Camera Transform3970/Camera4419; Map7621.]
const CAMERA_POSITION := Vector2(97, -106)
const CAMERA_HALF_HEIGHT := 1732.0
const MAP_SCALE := 1.25
# Image children, independent of their LocationController container rectangles.
# [SRC: GameScene RectTransforms 7684/7775/7695/7644/7632 and siblings.]
const LOCATION_ART := {
	"Palace": [["Palace.png", Vector2(-10, 21), Vector2(690, 446)]],
	"Parish": [["Parish_1.png", Vector2(61, -4), Vector2(296, 170)]],
	"Outside": [["Outside_1.png", Vector2(158, -625), Vector2(343, 222)]],
	"Blackstreet": [["Blackstreet_1.png", Vector2(-184, 202.5), Vector2(340, 226)], ["Blackstreet_2.png", Vector2(8.5, -203), Vector2(736, 410)]],
	"SelfHome": [["SelfHome.png", Vector2(37, 105), Vector2(321, 211)]],
	"Uptown": [["Uptown.png", Vector2(3, 0), Vector2(723, 383)], ["Uptown_2.png", Vector2(-802, -714), Vector2(223, 279)]],
	"Downtown": [["Downtown_1.png", Vector2(-98.5, 23.8), Vector2(261, 230)], ["Downtown_2.png", Vector2(-760.5, -200), Vector2(261, 210)]],
}
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
# (0.5,0).  RiteNew's RiteController bound is independently authored at
# (0,-18), also 123x133, pivot (0.5,0).  Both roots remain at their selected
# RitePosition; neither is centred on that root.
# [SRC: Resources/prefab/RitePin.prefab Icon RectTransform@224632457200066912;
#       Resources/prefab/RiteNew.prefab bound RectTransform@224738892719839630;
#       il2cpp_dump/dump.cs RitePinRender@324544 / RiteController@320629.]
const RITE_PIN_ICON_SIZE := Vector2(123.0, 133.0)
const RITE_PIN_ICON_ANCHORED_POSITION := Vector2(0.0, -17.6)
const RITE_PIN_ICON_PIVOT := Vector2(0.5, 0.0)
const RITE_CARD_BOUND_SIZE := Vector2(123.0, 133.0)
const RITE_CARD_BOUND_ANCHORED_POSITION := Vector2(0.0, -18.0)
const RITE_CARD_BOUND_PIVOT := Vector2(0.5, 0.0)
# `RiteController.bounds` is CalculateRelativeRectTransformBounds(Map,
# RiteNew.bound), so the collision rectangle is this child bound rather than
# the RitePosition root.  The root-to-bound centre offset follows directly
# from its anchor/pivot geometry.
const RITE_CARD_BOUND_CENTER_OFFSET := Vector2(0.0, 48.5)
const RITE_CARD_BOUND_EXTENTS := Vector2(61.5, 66.5)
# MapController.SetRitesPosition converts the screen centre into Map-local
# space before sorting, including camera translation and Map local scale.
const RITE_CARD_SORT_CENTER := (CAMERA_POSITION - MAP_LOCAL_OFFSET) / MAP_SCALE
# MapController.SetPos checks the moved RiteNew *bound centre* against `bg`;
# it restores the old point when that centre leaves the background.  Scene
# YAML: Map=4200x2600 scale 1.25 at (0,-178); bg=4095x2147 scale 1.5 at (0,0).
# Expressing bg relative to Map yields centre (0,142.4), extents (2457,1288.2).
const RITE_CARD_BG_BOUNDS := Rect2(Vector2(-2457.0, -1145.8), Vector2(4914.0, 2576.4))

var _state
var _db
var _rng
var _scene_blockers: Dictionary = {}
var locations: Array[LocationController] = []
var maps: Dictionary = {}
var pins: Dictionary = {} # rite definition id -> non-interactive RitePin view
var rite_cards: Dictionary = {} # runtime rite uid -> clickable RiteNew view
# Original MapController.lines is keyed by (target rite definition id,
# source completed-pin definition id), not a runtime Rite UID.
var lines: Dictionary = {}
# Runtime counterpart of RiteController.position and its Transform position.
# Init selects a RitePosition once; later SetRitesPosition moves that already
# instantiated RiteNew transform, never calls GetPosition a second time.
var _rite_position_assignments: Dictionary = {} # uid -> {controller, position}
var _rite_card_source_positions: Dictionary = {} # uid -> current Map-local root
var _rite_bounds_dirty := false
var last_rite: int = 0
var ViewRange := Rect2()
var DeskBGSpecial: TextureRect

var _think_drop_zone: ThinkDropZone
var _thinking := false
static var _pin_atlas: OriginalAtlas = null
static var _outline_atlas: OriginalAtlas = null
static var _end_map_atlas: OriginalAtlas = null
var _end_background_active := false
## MapController.EftEnd@0x78: the end-state map effect slot. The source scene
## ships it as an inactive, childless Transform; ChangeBGToEnd switches it on.
var _eft_end_map: Control


func setup(state, db = null, rng = null) -> void:
	_state = state
	_db = db
	_rng = rng


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_locations()
	if _state != null and bool(_state.end_open):
		change_bg_to_end()
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
		for entry in LOCATION_ART.get(str(spec["node"]), []):
			var art := TextureRect.new()
			art.name = "Art" if location.get_child_count() == 0 else "Art2"
			art.set_meta("source_asset", entry[0])
			art.texture = load("res://assets/original/ui/areas/%s" % entry[0]) as Texture2D
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_SCALE
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			location.add_child(art)


func _build_ithink_target() -> void:
	_think_drop_zone = ThinkDropZone.new()
	_think_drop_zone.name = "ThinkDropZone"
	_think_drop_zone.owner_map = self
	_think_drop_zone.mouse_default_cursor_shape = Control.CURSOR_CAN_DROP
	# [SRC: GameScene MainUI/IThink/BG (388x704) and Folder (400x700),
	# both bottom-left. Keep the existing live rite drop handler.]
	_think_drop_zone.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for asset in ["bg_0", "open_03"]:
		var art := TextureRect.new()
		art.name = asset
		art.texture = load("res://assets/original/ui/%s.png" % asset)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_think_drop_zone.add_child(art)
	_think_drop_zone.mouse_exited.connect(_set_think_drop_highlight.bind(false))
	_think_drop_zone.z_index = 8
	add_child(_think_drop_zone)
	_build_eft_end_map()


## The end-state map effect slot. The source's GameScene has GameObject
## "Eft_End_Map" (fileID 2574, layer 6) as an EMPTY Transform at localPosition
## (0,0,0) scale (200,200,200), referenced by MapController.EftEnd@0x78 and
## switched on as the last statement of ChangeBGToEnd. Its particle children are
## instantiated at runtime, and the exported package carries no portable
## ParticleSystem data for this slot, so the clone carries the slot (name, parked
## rect and inactive start) without inventing a particle hierarchy.
## [SRC: GameScene.unity GameObject 2574 "Eft_End_Map" (m_IsActive 0, Transform
##       4141); MapController.c @ ChangeBGToEnd (RVA 0x567b70) tail:
##       GameObject.SetActive(param_1 + 0x78, true); dump.cs MapController
##       bg@0x68 / bg_end@0x70 / EftEnd@0x78.]
func _build_eft_end_map() -> void:
	_eft_end_map = Control.new()
	_eft_end_map.name = "Eft_End_Map"
	_eft_end_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eft_end_map.visible = false
	_eft_end_map.set_meta("source_active_at_start", false)
	_eft_end_map.set_meta("source_particle_children_unported", true)
	add_child(_eft_end_map)


func refresh_context() -> void:
	if _state != null and bool(_state.end_open):
		change_bg_to_end()
	refresh_rite_cards()
	refresh_rite_pins()
	refresh_rite_pin_lines()
	queue_redraw()


## Direct counterpart of MapController.ChangeBGToEnd. The source replaces
## `bg` with `bg_end`, then replaces every location child Image by looking up
## its current sprite name in Datapool.end_map_sprites, and finally switches on
## the end-state effect slot `EftEnd`.
## [SRC: MapController.c ChangeBGToEnd (RVA 0x567b70);
##       dump.cs MapController.bg/bg_end/EftEnd @0x68/0x70/0x78;
##       Resources/image/end_map.json; GameScene.unity bg_end guid
##       80246786a586a354f936cf6047ef6b07 and Eft_End_Map fileID 2574.]
func change_bg_to_end() -> void:
	_end_background_active = true
	if _end_map_atlas == null:
		_end_map_atlas = OriginalAtlas.load_atlas("res://assets/original/ui/end_map.png")
	if _end_map_atlas != null:
		for spec in LOCATION_SCENE_SPECS:
			var asset_name := str(spec.get("asset", ""))
			if asset_name.is_empty() or not _end_map_atlas.has_frame(asset_name):
				continue
			var controller := maps.get(str(spec["location"])) as LocationController
			if controller == null:
				continue
			for art in controller.view.get_children():
				var frame_name := str(art.get_meta("source_asset", ""))
				if art is TextureRect and _end_map_atlas.has_frame(frame_name):
					art.texture = _end_map_atlas.frame(frame_name)
	# Last statement of the source method: switch the end effect slot on.
	if _eft_end_map != null:
		_eft_end_map.visible = true
	queue_redraw()


func is_end_background_active() -> bool:
	return _end_background_active


func set_scene_blocker(source: String, blocking: bool, _hide_chrome: bool = true) -> void:
	if source.is_empty():
		return
	if blocking:
		_scene_blockers[source] = true
	else:
		_scene_blockers.erase(source)
	if _think_drop_zone != null:
		_think_drop_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_scene_blocked() else Control.MOUSE_FILTER_STOP
	for card in rite_cards.values():
		var button := card as Button
		if button != null:
			button.disabled = is_scene_blocked()
			var banner := button.get_node_or_null("TitleBG") as TextureButton
			if banner != null:
				banner.disabled = button.disabled


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
	_play_think_animation()
	var screen := get_parent()
	if screen != null and screen.has_method("drop_card_on_methinks"):
		screen.drop_card_on_methinks(data)


func _play_think_animation() -> void:
	if _think_drop_zone == null:
		return
	var front := _think_drop_zone.get_node_or_null("open_03") as Control
	if front == null:
		return
	front.pivot_offset = front.size * 0.5
	front.rotation = -0.045
	front.scale = Vector2(0.96, 0.96)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(front, "rotation", 0.0, 0.18)
	tween.parallel().tween_property(front, "scale", Vector2.ONE, 0.22)
	tween.tween_property(front, "rotation", -0.018, 0.12)
	tween.tween_property(front, "rotation", 0.0, 0.12)


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
		location.size = source_size * _map_scale()
		location.position = (center - location.size * 0.5).round()
		var artwork: Array = LOCATION_ART.get(str(spec["node"]), [])
		for i in artwork.size():
			var art: Control = location.get_child(i)
			var offset: Vector2 = artwork[i][1]
			art.size = artwork[i][2] * _map_scale()
			art.position = location.size * 0.5 + Vector2(offset.x, -offset.y) * _map_scale() - art.size * 0.5
	if _think_drop_zone != null:
		var k := minf(size.x / 3840.0, size.y / 2160.0)
		_think_drop_zone.size = Vector2(400, 704) * k
		_think_drop_zone.position = Vector2(0, size.y - 704 * k)
		var back := _think_drop_zone.get_node("bg_0") as TextureRect
		back.size = Vector2(388, 704) * k
		var front := _think_drop_zone.get_node("open_03") as TextureRect
		front.size = Vector2(400, 700) * k
		front.position = Vector2(0, 4 * k)
	_layout_rite_cards()
	_layout_rite_pins()
	refresh_rite_pin_lines()


func _map_local_to_canvas(source_position: Vector2) -> Vector2:
	var world := (source_position - MAP_LOCAL_OFFSET) * MAP_SCALE + MAP_LOCAL_OFFSET
	return _world_to_canvas(world)


func _map_scale() -> float:
	return size.y / (CAMERA_HALF_HEIGHT * 2.0) * MAP_SCALE


func _world_to_canvas(world: Vector2) -> Vector2:
	var relative := (world - CAMERA_POSITION) * size.y / (CAMERA_HALF_HEIGHT * 2.0)
	return size * 0.5 + Vector2(relative.x, -relative.y)


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
	var rite_ids: Array[int] = _state.rite_pins
	for rite_id in rite_ids:
		var rite: Dictionary = _db.rites.get(rite_id, {})
		var texture := _rite_icon(rite)
		var pin := RitePinView.new()
		pin.name = "RitePin_%d" % rite_id
		pin.rite_id = rite_id
		pin.tooltip_text = str(rite.get("name", rite_id))
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if texture != null:
			var art := TextureRect.new()
			art.texture = texture
			art.set_anchors_preset(Control.PRESET_FULL_RECT)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pin.add_child(art)
		pin.z_index = 5
		add_child(pin)
		pins[rite_id] = pin
	_layout_rite_pins()


## Original RefreshRitePinLines makes a line only if the FromPin source is in
## Player.pins.  Its target is first a completed RitePin, then each live Rite
## controller.  `lines` rejects duplicate (target config id, source config id)
## pairs, even if multiple runtime rites share the target definition.
## [SRC: decompiled/MapController.c RefreshRitePinLines (0x5690d0),
##       CleanUnexistsPinLines (0x568080), CreateLine (0x568360);
##       il2cpp_dump/dump.cs MapController@321039, RiteNode.FromPin@393030.]
func refresh_rite_pin_lines() -> void:
	for line in lines.values():
		if is_instance_valid(line):
			line.queue_free()
	lines.clear()
	if _state == null or _db == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var pin_positions := _allocate_rite_pin_positions()
	# The original's first pass targets completed endpoint transforms.
	for raw_target_id in pins.keys():
		var target_id := int(raw_target_id)
		if not pin_positions.has(target_id):
			continue
		_add_rite_pin_lines_for_target(target_id, pin_positions[target_id], pin_positions)
	# The second pass targets active RiteController transforms.  This pass is
	# deliberately separate: a live RiteNew does not become a source endpoint.
	var live_positions := _allocate_rite_card_positions()
	var rite_uids: Array[int] = []
	for raw_uid in rite_cards.keys():
		rite_uids.append(int(raw_uid))
	rite_uids.sort()
	for rite_uid in rite_uids:
		var instance = _state.get_rite_instance(rite_uid) if _state.has_method("get_rite_instance") else null
		if instance == null or not live_positions.has(rite_uid):
			continue
		_add_rite_pin_lines_for_target(int(instance.id), live_positions[rite_uid], pin_positions)


func _add_rite_pin_lines_for_target(target_rite_id: int, target_root: Vector2, pin_positions: Dictionary) -> void:
	var rite: Dictionary = _db.rites.get(target_rite_id, {})
	var from_pins = rite.get("from_pins", [])
	if not (from_pins is Array):
		return
	for raw_from_data in from_pins:
		if not (raw_from_data is Dictionary):
			continue
		var from_data: Dictionary = raw_from_data
		var source_rite_id := int(from_data.get("rite_id", 0))
		# CreateLine looks up this exact source id in MapController.pins.  The
		# clone's `pin_positions` is the same completed-pin domain.
		if not pin_positions.has(source_rite_id):
			continue
		var line_key := Vector2i(target_rite_id, source_rite_id)
		if lines.has(line_key):
			continue
		var line := _create_rite_pin_line(target_rite_id, source_rite_id, pin_positions[source_rite_id], target_root, from_data)
		if line == null:
			continue
		lines[line_key] = line


func _create_rite_pin_line(target_rite_id: int, source_rite_id: int, source_root: Vector2, target_root: Vector2, from_data: Dictionary) -> RitePinLineView:
	# CreateLine converts both endpoint Transforms into rootCanvas local space.
	# Its captured lambda then adds each configured control Vector2 to the start
	# point.  Config Y is Unity-up, whereas the Godot canvas is down.
	var start := _map_local_to_canvas(source_root + MAP_LOCAL_OFFSET)
	var ending := _map_local_to_canvas(target_root + MAP_LOCAL_OFFSET)
	var controls: Array[Vector2] = []
	var raw_controls = from_data.get("controls", [])
	if raw_controls is Array:
		for raw_control in raw_controls:
			if raw_control is Array and raw_control.size() >= 2:
				controls.append(start + Vector2(
					float(raw_control[0]) * size.x / 3840.0,
					-float(raw_control[1]) * size.y / 2160.0
				))
	var resolution := int(from_data.get("resolution", 0))
	if resolution <= 0:
		resolution = 30
	var start_reserve := clampf(float(from_data.get("start_reserve", 0.0)), 0.0, 1.0)
	var end_reserve := 1.0 - float(from_data.get("end_reserve", 0.0))
	if is_zero_approx(end_reserve):
		end_reserve = 1.0
	end_reserve = clampf(end_reserve, 0.0, 1.0)
	var line := RitePinLineView.new()
	line.name = "RitePinLine_%d_from_%d" % [target_rite_id, source_rite_id]
	line.target_rite_id = target_rite_id
	line.source_rite_id = source_rite_id
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.position = Vector2.ZERO
	line.size = size
	line.z_index = 4
	line.sampled_points = sample_rite_pin_line(start, ending, controls, resolution, start_reserve, end_reserve)
	line.arrow_points = _rite_pin_line_arrow(line.sampled_points, float(from_data.get("arrow_length", 0.0)), float(from_data.get("arrow_angle", 0.0)))
	line.line_color = _rite_pin_line_color(from_data.get("color", []))
	line.line_width = float(from_data.get("width", 0.0))
	if line.line_width <= 0.0:
		line.line_width = 5.0
	line.line_width *= minf(size.x / 3840.0, size.y / 2160.0)
	line.dashed = bool(from_data.get("dashed", false))
	add_child(line)
	return line


## LineController samples t from startReserve through 1-endReserve inclusive
## at resolution+1 points.  The original supports linear, quadratic, and cubic
## curves (0/1/2 controls); every current original FromPin uses one control.
## [SRC: decompiled/LineController.c GenerateLine (0x42edd0);
##       decompiled/BezierCurveGenerator.c CalculateBezierPoint (0x428630).]
static func sample_rite_pin_line(start: Vector2, ending: Vector2, controls: Array[Vector2], resolution: int, start_reserve: float, end_reserve: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_resolution := maxi(resolution, 0)
	for point_index in safe_resolution + 1:
		var t := float(point_index) * (end_reserve - start_reserve) / float(safe_resolution) + start_reserve if safe_resolution > 0 else start_reserve
		if controls.is_empty():
			points.append(start.lerp(ending, t))
		elif controls.size() == 1:
			var inv_t := 1.0 - t
			points.append(start * inv_t * inv_t + controls[0] * 2.0 * t * inv_t + ending * t * t)
		elif controls.size() == 2:
			var inv_t := 1.0 - t
			points.append(start * inv_t * inv_t * inv_t + controls[0] * 3.0 * inv_t * inv_t * t + controls[1] * 3.0 * inv_t * t * t + ending * t * t * t)
		else:
			# BezierCurveGenerator logs an error and returns Vector3.zero for an
			# unsupported control count.  Preserve that boundary rather than
			# silently inventing a higher-order curve.
			points.append(Vector2.ZERO)
	return points


## LineController builds the arrow from the final two sampled points: base is
## arrowLength behind the endpoint and wing separation is length*sin(angle).
## [SRC: decompiled/BezierCurveGenerator.c GenerateArrow (0x428950).]
func _rite_pin_line_arrow(points: PackedVector2Array, source_length: float, angle_degrees: float) -> PackedVector2Array:
	if points.size() < 2 or source_length <= 0.0:
		return PackedVector2Array()
	var scale := minf(size.x / 3840.0, size.y / 2160.0)
	var ending := points[points.size() - 1]
	var direction := (ending - points[points.size() - 2]).normalized()
	if direction.is_zero_approx():
		return PackedVector2Array()
	var length := source_length * scale
	var base := ending - direction * length
	var wing_length := length * sin(deg_to_rad(angle_degrees))
	var perpendicular := Vector2(-direction.y, direction.x)
	return PackedVector2Array([base + perpendicular * wing_length, ending, base - perpendicular * wing_length])


static func _rite_pin_line_color(raw_color) -> Color:
	if raw_color is Array and raw_color.size() >= 4:
		return Color8(int(raw_color[0]), int(raw_color[1]), int(raw_color[2]), int(raw_color[3]))
	return Color.WHITE


## GameController.AddRite instantiates RiteNew and RiteController.Init parents
## it into a selected RitePosition.  Unlike Player.pins, this is a runtime-UID
## layer and its button is the map interaction surface.
## [SRC: GameController.c AddRite (0x54b320); RiteController.c Init (0x58ae00);
##       Resources/prefab/RiteNew.prefab bound RectTransform.]
func refresh_rite_cards() -> void:
	if _outline_atlas == null:
		_outline_atlas = OriginalAtlas.load_atlas("res://assets/original/ui/rite_outlines.png")
	for card in rite_cards.values():
		if is_instance_valid(card):
			card.queue_free()
	rite_cards.clear()
	if _state == null or _db == null:
		return
	if _pin_atlas == null:
		_pin_atlas = OriginalAtlas.load_atlas("res://assets/original/ui/rites.png")
	if _pin_atlas == null:
		return
	var instances: Array = _state.available_rite_instances() if _state.has_method("available_rite_instances") else []
	for instance in instances:
		var rite: Dictionary = _db.rites.get(instance.id, {})
		var texture := _rite_icon(rite)
		var card := RiteCardButton.new()
		card.name = "RiteNew_%d" % instance.uid
		card.rite_uid = instance.uid
		card.rite_id = instance.id
		card.tooltip_text = str(rite.get("name", instance.id))
		card.disabled = is_scene_blocked()
		for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
			card.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
		_build_rite_title(card, rite, instance)
		# RiteNew child order: TitleBG, IconOutline, Icon.
		if texture != null:
			var icon := TextureRect.new()
			icon.name = "Icon"
			icon.texture = texture
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_SCALE
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(icon)
		# Normal rites retain the prefab's generic rite outline. Native-size
		# special-rite offsets are a separate, still-unported Init branch.
		var outline_texture := _outline_atlas.frame("rite.png")
		if outline_texture != null:
			var outline := TextureRect.new()
			outline.name = "IconOutline"
			outline.texture = outline_texture
			outline.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			outline.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			outline.stretch_mode = TextureRect.STRETCH_SCALE
			outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
			outline.modulate = Color(1, 1, 1, 0)
			card.add_child(outline)
			card.move_child(outline, 1)
		card.pressed.connect(_on_rite_card_pressed.bind(instance.uid))
		card.z_index = 7
		add_child(card)
		rite_cards[instance.uid] = card
	_rite_bounds_dirty = true
	_layout_rite_cards()


func _rite_icon(rite: Dictionary) -> Texture2D:
	# [SRC: Datapool.GetRiteSprite 0x4128a0; stringliteral @0x258A420.]
	var texture := _pin_atlas.frame(str(rite.get("icon", "")) + ".png")
	return texture if texture != null else _pin_atlas.frame("rite_0.png")


func _on_rite_card_pressed(rite_uid: int) -> void:
	if is_scene_blocked():
		return
	last_rite = rite_uid
	open_rite_instance.emit(rite_uid)


func _build_rite_title(card: RiteCardButton, rite: Dictionary, instance) -> void:
	# [SRC: RiteRender.Init 0x59a9e0; RiteNew/TitleBG HorizontalLayoutGroup
	# Left=56, Title=PreferredWidth, Right=57, height=77; RiteShows.asset.]
	var title := Label.new()
	title.name = "Title"
	title.text = _state.rite_display_name(instance.id, _db)
	var gold := int(rite.get("type", 0)) == 3
	preload("res://ui/source_text_style.gd").apply(title, "@RITE_TITLE_BLACK" if gold else "@RITE_TITLE")
	var font := title.get_theme_font("font")
	var text_width := ceilf(font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x)
	var banner := TextureButton.new()
	banner.name = "TitleBG"
	banner.texture_normal = load("res://assets/original/ui/title_bg%s.png" % ("_gold" if gold else ""))
	banner.ignore_texture_size = true
	banner.stretch_mode = TextureButton.STRETCH_SCALE
	banner.size = Vector2(56 + text_width + 57, 77)
	banner.disabled = card.disabled
	banner.pressed.connect(_on_rite_card_pressed.bind(instance.uid))
	card.add_child(banner)
	var ending := TextureRect.new()
	ending.name = "RightImage"
	ending.texture = load("res://assets/original/ui/title_bg%s_end.png" % ("_gold" if gold else ""))
	ending.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending.position = Vector2(56 + text_width, 0)
	ending.size = Vector2(57, 77)
	ending.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(ending)
	title.position = Vector2(56, 0)
	title.size = Vector2(text_width, 77)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.BLACK if gold else Color.WHITE)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(title)
	title.minimum_size_changed.connect(_on_rite_title_size_changed.bind(card))


func _on_rite_title_size_changed(card: RiteCardButton) -> void:
	if card.is_queued_for_deletion():
		return
	var title := card.get_node("TitleBG/Title") as Label
	var width := ceilf(title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x)
	var banner := title.get_parent() as Control
	if is_equal_approx(banner.size.x, 113 + width):
		return
	banner.size.x = 113 + width
	title.size.x = width
	(banner.get_node("RightImage") as Control).position.x = 56 + width
	_rite_bounds_dirty = true
	_layout_rite_cards.call_deferred()


func _rite_card_bound(rite_uid: int) -> Rect2:
	# [SRC: RiteRender.OnUpdateBound 0x59be70; RiteNew.bound pivot(.5,0),
	# pos.y=-18. Binary float at RVA0x1c92b4c is 0.5. Map-local Y is up.]
	var card := rite_cards.get(rite_uid) as Control
	var banner := card.get_node_or_null("TitleBG") as Control if card != null else null
	var width := banner.size.x + 61.5 if banner != null else 123.0
	return Rect2(-61.5, -18, width, 133)


func _layout_rite_pins() -> void:
	var source_positions := _allocate_rite_pin_positions()
	var rite_uids: Array[int] = []
	for raw_rite_id in pins.keys():
		rite_uids.append(int(raw_rite_id))
	rite_uids.sort()
	for rite_id in rite_uids:
		var pin := pins[rite_id] as Control
		if pin == null:
			continue
		var source_position: Vector2 = source_positions.get(rite_id, Vector2.ZERO)
		_layout_rite_pin(pin, source_position)


func _layout_rite_cards() -> void:
	var source_positions := _allocate_rite_card_positions()
	var rite_uids: Array[int] = []
	for raw_uid in rite_cards.keys():
		rite_uids.append(int(raw_uid))
	rite_uids.sort()
	for rite_uid in rite_uids:
		var card := rite_cards[rite_uid] as Control
		if card == null:
			continue
		_layout_rite_card(card, source_positions.get(rite_uid, Vector2.ZERO))


func _layout_rite_pin(pin: Control, source_position: Vector2) -> void:
	_layout_map_rect(pin, source_position, RITE_PIN_ICON_SIZE, RITE_PIN_ICON_ANCHORED_POSITION, RITE_PIN_ICON_PIVOT)


func _layout_rite_card(card: Control, source_position: Vector2) -> void:
	_layout_map_rect(card, source_position, RITE_CARD_BOUND_SIZE, RITE_CARD_BOUND_ANCHORED_POSITION, RITE_CARD_BOUND_PIVOT)
	var banner := card.get_node_or_null("TitleBG") as Control
	if banner != null:
		var source_scale := Vector2.ONE * _map_scale()
		banner.scale = source_scale
		# Root is (61.5,115) from bound top-left; TitleBG top=(0,-91.5).
		banner.position = Vector2(61.5, 23.5) * source_scale
	var outline := card.get_node_or_null("IconOutline") as Control
	if outline != null:
		outline.size = Vector2(152, 208) * _map_scale()
		outline.position = Vector2(-14.5, -69.4) * _map_scale()


func _layout_map_rect(view: Control, source_position: Vector2, rect_size: Vector2, anchored_position: Vector2, pivot: Vector2) -> void:
	var source_scale := Vector2.ONE * _map_scale()
	view.size = rect_size * source_scale
	var root := _map_local_to_canvas(source_position + MAP_LOCAL_OFFSET)
	var source_top_left := Vector2(
		-rect_size.x * pivot.x + anchored_position.x,
		anchored_position.y + rect_size.y * (1.0 - pivot.y)
	)
	view.position = (root + Vector2(source_top_left.x * source_scale.x, -source_top_left.y * source_scale.y)).round()


func _allocate_rite_card_positions() -> Dictionary:
	# GameController.GetLocationRange parses `area:N` / `area:[N,M]` before
	# GetLocation delegates to LocationController.GetPosition. RiteController.Init
	# performs that selection once; its later SetPos transforms must not re-run
	# GetPosition just because the clone redraws its view.
	# [SRC: decompiled/GameController.c GetLocation/GetLocationRange/AddRitePin;
	#       decompiled/RiteController.c Init/OnDestroy;
	#       decompiled/LocationController.c GetPosition;
	#       decompiled/RitePosition.c AddRite/RemoveRite.]
	if _state == null or _db == null:
		return {}
	var rite_uids: Array[int] = []
	for raw_uid in rite_cards.keys():
		rite_uids.append(int(raw_uid))
	rite_uids.sort()
	var live_uids := {}
	for rite_uid in rite_uids:
		live_uids[rite_uid] = true
	for raw_uid in _rite_position_assignments.keys().duplicate():
		var stale_uid := int(raw_uid)
		if live_uids.has(stale_uid):
			continue
		var assignment: Dictionary = _rite_position_assignments[stale_uid]
		var stale_position := assignment.get("position", null) as RitePosition
		if stale_position != null:
			stale_position.remove_rite(stale_uid)
		_rite_position_assignments.erase(stale_uid)
		_rite_card_source_positions.erase(stale_uid)
		# RiteController.OnDestroy -> RitePosition.RemoveRite calls
		# UpdateExistsChild, which immediately compacts every remaining sibling's
		# local X back to index * 100. Keep that lifecycle correction separate
		# from the later, global SetPos collision pass.
		# [SRC: decompiled/RiteController.c OnDestroy (0x58b200);
		#       decompiled/RitePosition.c RemoveRite/UpdateExistsChild.]
		for raw_other_uid in _rite_position_assignments.keys():
			var other_uid := int(raw_other_uid)
			var other_assignment: Dictionary = _rite_position_assignments[other_uid]
			var other_position := other_assignment.get("position", null) as RitePosition
			if other_position != stale_position:
				continue
			var other_controller := other_assignment.get("controller", null) as LocationController
			if other_controller != null:
				_rite_card_source_positions[other_uid] = other_controller.source_position + other_position.add_rite(other_uid)
	var added_any := false
	for rite_uid in rite_uids:
		var instance = _state.get_rite_instance(rite_uid) if _state.has_method("get_rite_instance") else null
		if instance == null:
			continue
		if _rite_position_assignments.has(rite_uid):
			continue
		var rite: Dictionary = _db.rites.get(instance.id, {})
		var location_range := _location_range(str(rite.get("location", "")))
		var controller := maps.get(str(location_range["name"])) as LocationController
		if controller == null:
			continue
		var position := controller.get_position(int(location_range["min"]), int(location_range["max"]))
		if position != null:
			_rite_position_assignments[rite_uid] = {"controller": controller, "position": position}
			_rite_card_source_positions[rite_uid] = controller.source_position + position.add_rite(rite_uid)
			added_any = true
	if added_any or _rite_bounds_dirty:
		_rite_card_source_positions = _resolve_rite_card_positions(_rite_card_source_positions)
		_rite_bounds_dirty = false
	return _rite_card_source_positions.duplicate()


## MapController.SetRitesPosition separates normal/ranged rites from fixed
## special rites, sorts the former by distance to the current screen centre,
## then invokes SetPos on each ordered pair.  The `[` discriminator is not a
## clone convention: it is the original literal from stringliteral.json.
## [SRC: decompiled/MapController.c SetRitesPosition (0x56a200), SetPos
##       (0x569cd0); il2cpp_dump/stringliteral.json @0x2579348 = "[";
##       il2cpp_dump/dump.cs MapController@321039, RiteController@323632.]
func _resolve_rite_card_positions(source_positions: Dictionary) -> Dictionary:
	var result := source_positions.duplicate()
	if _state == null or _db == null:
		return result
	var primary: Array[int] = []
	var fixed_special: Array[int] = []
	for raw_uid in result.keys():
		var rite_uid := int(raw_uid)
		var instance = _state.get_rite_instance(rite_uid) if _state.has_method("get_rite_instance") else null
		if instance == null:
			continue
		var rite: Dictionary = _db.rites.get(instance.id, {})
		if _is_primary_rite_position(rite):
			primary.append(rite_uid)
		else:
			fixed_special.append(rite_uid)
	primary.sort_custom(func(a: int, b: int) -> bool:
		var a_center: Vector2 = result[a] + _rite_card_bound(a).get_center()
		var b_center: Vector2 = result[b] + _rite_card_bound(b).get_center()
		return a_center.distance_squared_to(RITE_CARD_SORT_CENTER) < b_center.distance_squared_to(RITE_CARD_SORT_CENTER)
	)
	fixed_special.sort()
	for first_index in primary.size():
		for second_index in range(first_index + 1, primary.size()):
			_apply_rite_card_pair_position(result, primary[first_index], primary[second_index])
	for special_uid in fixed_special:
		for primary_uid in primary:
			_apply_rite_card_pair_position(result, primary_uid, special_uid)
	return result


func _is_primary_rite_position(rite: Dictionary) -> bool:
	var type_value = rite.get("type", "NORMAL")
	var is_normal := type_value is int and int(type_value) == 0
	if type_value is String:
		is_normal = str(type_value).is_empty() or str(type_value).to_upper() == "NORMAL"
	return is_normal or str(rite.get("location", "")).contains("[")


func _apply_rite_card_pair_position(source_positions: Dictionary, fixed_uid: int, moved_uid: int) -> void:
	if not source_positions.has(fixed_uid) or not source_positions.has(moved_uid):
		return
	source_positions[moved_uid] = resolve_rite_card_pair_position(
		source_positions[fixed_uid], source_positions[moved_uid],
		_rite_card_bound(fixed_uid), _rite_card_bound(moved_uid)
	)


## Pure MapController.SetPos counterpart.  A touching edge has zero overlap
## and remains a SetPos hit, matching the source's strict `<` early returns.
## It tests only the candidate bound centre against bg and restores the full
## previous root position on failure; it never clamps an edge.
static func resolve_rite_card_pair_position(fixed_root: Vector2, moved_root: Vector2, fixed_bound: Rect2 = Rect2(-61.5, -18, 123, 133), moved_bound: Rect2 = Rect2(-61.5, -18, 123, 133)) -> Vector2:
	var fixed_center := fixed_root + fixed_bound.get_center()
	var moved_center := moved_root + moved_bound.get_center()
	var extent_sum := (fixed_bound.size + moved_bound.size) * 0.5
	var delta := moved_center - fixed_center
	if absf(delta.x) > extent_sum.x:
		return moved_root
	if absf(delta.y) > extent_sum.y:
		return moved_root
	var overlap_x := extent_sum.x - absf(delta.x)
	var overlap_y := extent_sum.y - absf(delta.y)
	var candidate := moved_root
	if overlap_x <= overlap_y:
		candidate.x += -overlap_x if moved_center.x < fixed_center.x else overlap_x
	else:
		candidate.y += -overlap_y if moved_center.y < fixed_center.y else overlap_y
	var candidate_center := candidate + moved_bound.get_center()
	var right_bottom := RITE_CARD_BG_BOUNDS.position + RITE_CARD_BG_BOUNDS.size
	if candidate_center.x < RITE_CARD_BG_BOUNDS.position.x or candidate_center.x > right_bottom.x:
		return moved_root
	if candidate_center.y < RITE_CARD_BG_BOUNDS.position.y or candidate_center.y > right_bottom.y:
		return moved_root
	return candidate


## GameController.AddRitePin calls GetLocation and parents the pin directly;
## it does not call RitePosition.AddRite, so pins never consume stack slots.
## Their selection nevertheless observes the live RiteController occupancy.
## [SRC: GameController.c AddRitePin (0x54b080); RitePosition.c AddRite.]
func _allocate_rite_pin_positions() -> Dictionary:
	var result: Dictionary = {}
	if _state == null or _db == null:
		return result
	_allocate_rite_card_positions()
	var rite_ids: Array[int] = []
	for raw_rite_id in pins.keys():
		rite_ids.append(int(raw_rite_id))
	for rite_id in rite_ids:
		var rite: Dictionary = _db.rites.get(rite_id, {})
		var location_range := _location_range(str(rite.get("location", "")))
		var controller := maps.get(str(location_range["name"])) as LocationController
		if controller == null:
			continue
		var position := controller.get_position(int(location_range["min"]), int(location_range["max"]))
		if position != null:
			result[rite_id] = controller.source_position + position.source_position
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


## [SRC: GameController.ShowSatisfiedRite 0x5576b0; an empty result does
##       nothing. Each matched rite restarts its one-shot animation.]
func show_satisfied_rites(rite_uids: Array) -> void:
	var wanted: Dictionary = {}
	for uid in rite_uids:
		wanted[int(uid)] = true
	for uid in rite_cards:
		var card := rite_cards[uid] as Control
		if card == null or not card.has_method("set_satisfied_hint"):
			continue
		if wanted.has(int(uid)):
			card.call("set_satisfied_hint", true)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var world_scale := size.y / (CAMERA_HALF_HEIGHT * 2.0)
	var table_size := Vector2(4896, 2947) * 2.0 * world_scale
	draw_texture_rect(TABLE_TEXTURE, Rect2(_world_to_canvas(Vector2.ZERO) - table_size * 0.5, table_size), false)
	var map_texture: Texture2D = END_MAP_TEXTURE if _end_background_active else MAP_TEXTURE
	var map_size := Vector2(4095, 2147) * 1.5 * world_scale
	draw_texture_rect(map_texture, Rect2(_world_to_canvas(Vector2.ZERO) - map_size * 0.5, map_size), false)


class RitePinView:
	extends Control
	var rite_id := 0


class RiteCardButton:
	extends Button
	var rite_uid := 0
	var rite_id := 0
	var satisfied_hint := false
	var _hint_tween: Tween

	## [SRC: RiteRender.ShowEffect 0x59cc70 -> card_satisfied.anim.]
	func set_satisfied_hint(on: bool) -> void:
		satisfied_hint = on
		if _hint_tween != null and _hint_tween.is_valid():
			_hint_tween.kill()
		_hint_tween = null
		modulate = Color.WHITE
		var outline := get_node_or_null("IconOutline") as CanvasItem
		if outline != null:
			outline.modulate.a = 0.0
		if not on or not is_inside_tree() or outline == null:
			return
		# [SRC: Resources/anims/rite/card_satisfied.anim: IconOutline alpha
		#       0 -> 1 at .25s, hold to .75s, then 0 at 1s; AnimationEvent
		#       calls PostEffect at 1s.]
		_hint_tween = create_tween()
		_hint_tween.tween_method(_set_hint_fade_in, 0.0, 1.0, 0.25)
		_hint_tween.tween_interval(0.5)
		_hint_tween.tween_method(_set_hint_fade_out, 0.0, 1.0, 0.25)
		_hint_tween.tween_callback(func(): satisfied_hint = false)

	func _set_hint_fade_in(t: float) -> void:
		(get_node("IconOutline") as CanvasItem).modulate.a = smoothstep(0.0, 1.0, t)

	func _set_hint_fade_out(t: float) -> void:
		(get_node("IconOutline") as CanvasItem).modulate.a = 1.0 - smoothstep(0.0, 1.0, t)
