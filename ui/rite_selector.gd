## Rite selector: a scrollable list of currently generated rites grouped by
## location. Every rite uses the same event surface; the estate rite is only the
## first home rite in the player's runtime rite pool.
extends Control

signal rite_chosen(rite_id: int)
signal rite_chosen_instance(rite_uid: int)
signal closed()

const UiMotionScript = preload("res://ui/ui_motion.gd")

var _db
var _state = null
var _rng = null
var _location_filter := ""
var _location_order := ["自宅", "商业区", "宫廷", "上城区", "黑街", "神殿区", "野外", "大敌", "奇珍", "结局"]

var _list_container: VBoxContainer


func setup(db, state = null, rng = null, location_filter: String = "") -> void:
	_db = db
	_state = state
	_rng = rng
	_location_filter = location_filter


func _ready() -> void:
	name = "RiteSelector"
	theme = FaustTheme.get_theme()
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = FaustTheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	# Header.
	var head := HBoxContainer.new()
	var title := Label.new()
	title.text = "选择仪式"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "返回"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.pressed.connect(func(): closed.emit())
	head.add_child(close_btn)
	UiMotionScript.bind(close_btn)
	root.add_child(head)
	# Scrollable list.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_list_container = VBoxContainer.new()
	_list_container.add_theme_constant_override("separation", 6)
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_container)
	_populate()


func _populate() -> void:
	# Group playable rites by location.
	var by_location: Dictionary = {}
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


func _add_location_section(loc_name: String, rids: Array) -> void:
	# Sort rites by id for stable order.
	rids.sort_custom(func(a, b) -> bool: return a.uid < b.uid)
	var loc_label := Label.new()
	loc_label.text = "【%s】（%d）" % [loc_name, rids.size()]
	loc_label.add_theme_font_size_override("font_size", 18)
	loc_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	_list_container.add_child(loc_label)
	# Grid of rite buttons.
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
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
