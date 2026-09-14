extends Control

## CachedEvents notice tray — 1:1 of GameScene/MainUI/CachedEvents.
##
## [SRC: GameScene.unity rect 7782 (GameObject 320) + MonoBehaviour 11735
##   (custom HorizontalLayoutGroup) + GameController.c cachedEventContainer
##   @0x108 / CachedEventPrefab @0xA0 / OnCachedListChanged (0x553b70)]
##
## The original container is a runtime-empty layout band: items are only
## instantiated while `player.cached_event` (ObservableList<int> @0x148) is
## non-empty, one CachedEventController per id, then the custom layout group
## (padding right 100, spacing 50, MiddleRight, reverseArrangement) flows them
## right-to-left inside the 3840x128 band.  This view mirrors that contract:
## refresh(ids) rebuilds children in list order (index 0 = rightmost) with
## item rects derived from the same layout constants.

signal cached_event_clicked(event_id: int)

const DESIGN_SIZE := Vector2(3840, 2160)

# --- tray container (MainUI/CachedEvents) --------------------------------
# [SRC: RectTransform 7782 — anchors (1,0)-(1,0), pos (0,680), pivot (1,0),
# sizeDelta (3840,128); resolved via _unity_rect below.]
const TRAY_RECT := Rect2(0.0, 1352.0, 3840.0, 128.0)

# --- layout group contract (MonoBehaviour 11735) -------------------------
# m_Padding L0 R100 T0 B0, m_ChildAlignment 5 (MiddleRight), m_Spacing 50,
# forceExpand/control/scale all 0, m_ReverseArrangement 1.  Children keep
# their prefab size and flow from the right edge leftward, index 0 first.
const LAYOUT_PADDING_RIGHT := 100.0
const LAYOUT_SPACING := 50.0

# --- CachedEvent prefab --------------------------------------------------
# [SRC: Resources/prefab/CachedEvent.prefab]
const ITEM_SIZE := Vector2(112.5, 117.0)
const ICON_SIZE := Vector2(96.0, 96.0)  # authored 192x192 on a 0.5 child scale
const NEW_DOT_SIZE := Vector2(85.5, 85.5)
const NEW_DOT_POS := Vector2(61.85, -30.05)  # anchors (1,1) pos (-7.9,-12.7)

# --- Shaker (notice shake) ------------------------------------------------
# [SRC: CachedEvent.prefab MonoBehaviour (gu id 6c8e1683... / 2052804529,
#   disabled) + Shaker.c: OnEnable captures origin, Update integrates a
#   decayed perlin offset, .ctor defaults].  Serialized: positionIntension
#   (0.2,-0.2,0), rotationIntension 0, frequence 40, maxSpeed 2, time 10,
#   usePerlineNoise 1.  CachedEventController.Shake (0x527940) restarts the
#   component via set_enabled(false/true).
const SHAKE_TIME := 10.0
const SHAKE_MAX_SPEED := 2.0
const SHAKE_FREQ := 40.0
const SHAKE_AMPLITUDE := Vector2(0.2, -0.2)

const SOURCE_ART := "res://assets/original/ui/"

var _state = null
var _items: Dictionary = {}  # event_id -> item root Control
var _ordered_ids: Array = []  # list order = cached_event array order
var _source_time := float(Time.get_ticks_usec()) / 1000000.0

func _process(delta: float) -> void:
	# Shared scaled host clock: item creation/retrigger must not restart phase.
	_source_time += delta

## [SRC: GameController.c OnCachedListChanged 0x553b70 — snapshot the list,
## remove controllers whose id left it, instantiate new ones in list order,
## then SetActive(NextRoundMask, 0 < Count).]
func refresh(ids: Array) -> void:
	_ordered_ids = ids.duplicate()
	for existing_id in _items.keys():
		if not (int(existing_id) in ids):
			var old: Control = _items[existing_id]
			_items.erase(existing_id)
			if is_instance_valid(old):
				old.queue_free()
	for event_id in ids:
		var key := int(event_id)
		if not _items.has(key):
			var item := _make_item(key)
			_items[key] = item
			add_child(item)
	_layout_items()


## [SRC: GameController.c NoticeCachedEvent 0x5534d0 — shake every controller
## in the dictionary.  Reached from the next-round mask click (scene UnityEvent
## OnClick -> GameController.NoticeCachedEvent).]
func notice() -> void:
	for item in _items.values():
		item.shake_trigger()


func item_for_id(event_id: int) -> Control:
	return _items.get(event_id)


func shake_active_count() -> int:
	var count := 0
	for item in _items.values():
		if item.shake_active():
			count += 1
	return count


func _make_item(event_id: int) -> Control:
	var item := _CachedEventItem.new(
		event_id, SHAKE_TIME, SHAKE_MAX_SPEED, SHAKE_FREQ, SHAKE_AMPLITUDE
	)
	item.name = "CachedEvent_%d" % event_id
	item.size = ITEM_SIZE
	item.item_clicked.connect(_on_item_clicked.bind(event_id))
	# [SRC: CachedEvent.prefab root — Image checkbox_bg 112.5x117]
	var base := _texture_rect("checkbox_bg.png", ITEM_SIZE)
	base.name = "Base"
	item.add_child(base)
	# [SRC: CachedEvent/Image — dialog.asset 192x192 pivot (0.5,0.5) scale 0.5,
	#   visually 96x96 centred on the item root]
	var icon := _texture_rect("dialog.png", ICON_SIZE)
	icon.name = "Icon"
	icon.position = Vector2(
		(ITEM_SIZE.x - ICON_SIZE.x) * 0.5,
		(ITEM_SIZE.y - ICON_SIZE.y) * 0.5
	)
	item.add_child(icon)
	# [SRC: CachedEvent/Image — Resources/image/main_new/event-tag/new.asset
	#   anchors (1,1) pos (-7.9,-12.7) 85.5x85.5; the NEW badge pokes out of
	#   the top-right corner of the frame]
	var new_dot := _texture_rect("new.png", NEW_DOT_SIZE)
	new_dot.name = "NewDot"
	new_dot.position = NEW_DOT_POS
	item.add_child(new_dot)
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return item


## Right-to-left flow: index 0 rightmost, right edge at container right minus
## padding.right, spacing 50 between item edges, vertically centred in the
## 128px band.  [SRC: layout group contract; item rects = the directly
## derivable placement of Unity's HorizontalLayoutGroup (MiddleRight +
## ReverseArrangement, childControl off, same-size children).]
func _layout_items() -> void:
	for index in _ordered_ids.size():
		var item: Control = _items.get(_ordered_ids[index])
		if item == null:
			continue
		var right_edge := DESIGN_SIZE.x - LAYOUT_PADDING_RIGHT - float(index) * (ITEM_SIZE.x + LAYOUT_SPACING)
		var x := right_edge - ITEM_SIZE.x
		# Local to the tray root (the tray itself sits at TRAY_RECT.position).
		var y := (TRAY_RECT.size.y - ITEM_SIZE.y) * 0.5
		item.position = Vector2(x, y)


func _on_item_clicked(event_id: int) -> void:
	cached_event_clicked.emit(event_id)


func _texture_rect(file_name: String, sprite_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	var path := SOURCE_ART + file_name
	if ResourceLoader.exists(path):
		rect.texture = load(path) as Texture2D
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = sprite_size
	rect.custom_minimum_size = sprite_size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## --- Unity RectTransform -> Godot Rect2 (same convention as the other
## migrated views; y-axis flip folded into the top-left rect) -------------
static func _unity_rect(
	parent_size: Vector2,
	anchor_min: Vector2,
	anchor_max: Vector2,
	pos: Vector2,
	size_delta: Vector2,
	pivot: Vector2
) -> Rect2:
	var unity_min := Vector2(
		anchor_min.x * parent_size.x + pos.x - pivot.x * size_delta.x,
		anchor_min.y * parent_size.y + pos.y - pivot.y * size_delta.y
	)
	var unity_max := Vector2(
		anchor_max.x * parent_size.x + pos.x + (1.0 - pivot.x) * size_delta.x,
		anchor_max.y * parent_size.y + pos.y + (1.0 - pivot.y) * size_delta.y
	)
	return Rect2(unity_min.x, parent_size.y - unity_max.y, unity_max.x - unity_min.x, unity_max.y - unity_min.y)


## Source Shaker position path; CachedEvent rotationIntension is zero.
## Native noise/decay evidence: docs/replica/presentation.md#e042.
class _CachedEventItem:
	extends Control
	const Math = preload("res://ui/source_shaker_math.gd")

	signal item_clicked

	var event_id := 0
	var _shake_time := 0.0
	var _shake_velocity := 0.0
	var _shake_seed := 0.0
	var _time := 10.0
	var _max_speed := 2.0
	var _freq := 40.0
	var _amplitude := Vector2(0.2, -0.2)
	var _origin := Vector2.ZERO

	func _init(
		id: int = 0,
		shake_time: float = 10.0,
		shake_max_speed: float = 2.0,
		shake_freq: float = 40.0,
		shake_amplitude: Vector2 = Vector2(0.2, -0.2)
	) -> void:
		event_id = id
		_time = shake_time
		_max_speed = shake_max_speed
		_freq = shake_freq
		_amplitude = shake_amplitude

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			item_clicked.emit()

	func shake_trigger() -> void:
		# [SRC: Shaker.OnEnable 0x435690, dump.cs:420570 fields.]
		_origin = global_position
		_shake_time = _max_speed
		_shake_seed = Math.f(Math.f(randf() * 10.0) - 5.0)
		_shake_velocity = 0.0
		set_process(true)

	func shake_active() -> bool:
		return _shake_time > 0.0

	func _process(delta: float) -> void:
		if _shake_time <= 0.0:
			set_process(false)
			return
		advance_shake(delta, float(get_parent().get("_source_time")))

	func advance_shake(delta: float, elapsed: float) -> void:
		var step := Math.smooth_damp(_shake_time, _shake_velocity, delta, _time)
		_shake_time = step.x
		_shake_velocity = step.y
		var world_offset := Math.position_offset(_shake_seed, elapsed, _freq, _shake_time, _amplitude)
		# [SRC: GameScene Canvas7581 ScreenSpaceCamera -> Camera4416,
		# orthographic size=5 (10 world units high). Unity Y is up.]
		var units_to_viewport := get_viewport_rect().size.y / 10.0
		global_position = _origin + Vector2(world_offset.x, -world_offset.y) * units_to_viewport
