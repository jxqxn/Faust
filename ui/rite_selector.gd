## Rite selector: a scrollable list of currently generated rites grouped by
## location. Every rite uses the same event surface; the estate rite is only the
## first home rite in the player's runtime rite pool.
extends Control

signal rite_chosen(rite_id: int)
signal closed()

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
	for rid in open_rite_ids():
		var r: Dictionary = _db.rites[int(rid)]
		var loc_name := _location_name(r)
		if not by_location.has(loc_name):
			by_location[loc_name] = []
		by_location[loc_name].append(rid)
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
	rids.sort()
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
	for rid in rids:
		var r: Dictionary = _db.rites[int(rid)]
		var btn := Button.new()
		btn.text = str(r.get("name", str(rid)))
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.tooltip_text = str(r.get("text", ""))
		btn.pressed.connect(_on_rite.bind(int(rid)))
		grid.add_child(btn)
	_list_container.add_child(grid)


func _on_rite(rid: int) -> void:
	rite_chosen.emit(rid)


func open_rite_ids() -> Array[int]:
	var out: Array[int] = []
	for rid in _db.rites:
		var r: Dictionary = _db.rites[rid]
		var id := int(rid)
		if not _is_interactive_rite(r):
			continue
		if _location_filter != "" and not _location_matches(_location_name(r), _location_filter):
			continue
		if _state != null and _state.get("available_rites") != null and not (id in _state.available_rites):
			continue
		if not _is_rite_open(r):
			continue
		out.append(id)
	out.sort()
	return out


func _is_interactive_rite(rite: Dictionary) -> bool:
	var slots: Dictionary = rite.get("cards_slot", {})
	var settle_count: int = (rite.get("settlement", []) as Array).size()
	return not slots.is_empty() and settle_count > 0


func _location_name(rite: Dictionary) -> String:
	return str(rite.get("location", "?")).split(":")[0]


func _location_matches(config_location: String, requested_location: String) -> bool:
	if config_location == requested_location:
		return true
	var aliases := {
		"自宅": ["鑷畢"],
		"商业区": ["鍟嗕笟鍖?"],
		"宫廷": ["瀹环"],
		"神殿区": ["绁炴鍖?"],
		"野外": ["閲庡"],
	}
	return config_location in aliases.get(requested_location, [])


func _is_rite_open(rite: Dictionary) -> bool:
	var id := int(rite.get("id", 0))
	if int(rite.get("auto_begin", 0)) == 1:
		return _state != null and id in _state.started_rites
	return RiteOpen.is_rite_open(rite, _state, _db, _rng)
