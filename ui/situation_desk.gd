## The paper-and-map primary play surface.
##
## SituationDesk keeps the player in contact with the current day, available
## places, and visible rites without treating the lateral scene as a menu.
## It deliberately owns no simulation state: GameScreen remains the bridge to
## CardInstance, Queue, Rite, and legacy Methinks behaviour.
class_name SituationDesk
extends Control

signal thinking_changed(enabled: bool)
signal open_rite_selector(location_name: String)
signal open_rite_instance(rite_uid: int)
signal context_requested()


class ThinkDropButton:
	extends Button

	var owner_desk: Control

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return (
			owner_desk != null
			and owner_desk.has_method("can_drop_card_on_think_button")
			and bool(owner_desk.can_drop_card_on_think_button(data))
		)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if owner_desk != null and owner_desk.has_method("drop_card_on_think_button"):
			owner_desk.drop_card_on_think_button(data)


const WorldScenes = preload("res://sim/world_scene_catalog.gd")
const UiMotionScript = preload("res://ui/ui_motion.gd")

const SITE_SPECS := [
	{"name": "SiteHome", "label": "家", "location": "自宅", "position": Vector2(0.18, 0.67)},
	{"name": "SiteMarket", "label": "商店街", "location": "商业区", "position": Vector2(0.40, 0.38)},
	{"name": "SitePalace", "label": "校舍", "location": "宫廷", "position": Vector2(0.57, 0.62)},
	{"name": "SiteTemple", "label": "旧校舍", "location": "神殿区", "position": Vector2(0.73, 0.31)},
	{"name": "SiteWild", "label": "河堤", "location": "野外", "position": Vector2(0.82, 0.72)},
]

const PAPER_BASE := Color("#c9ad70")
const PAPER_LIGHT := Color("#ead89c")
const PAPER_SHADOW := Color("#49321f")
const INK := Color("#271c15")
const RED_WAX := Color("#8a3a31")

var _state
var _thinking := false
var _scene_blockers: Dictionary = {}
var _thought_targets: Array[Control] = []
var _world_time := 0.0

var _title: Label
var _subtitle: Label
var _dossier: Button
var _think_button: ThinkDropButton
var _thought_heading: Label
var _site_buttons: Array[Button] = []


func setup(state) -> void:
	_state = state


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_ALL
	_build_chrome()
	resized.connect(_layout)
	_layout()
	refresh_context()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_world_time += delta
	if _thinking:
		queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or is_scene_blocked():
		return
	if key_event.keycode == KEY_SPACE:
		set_thinking(not _thinking)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_ESCAPE and _thinking:
		set_thinking(false)
		get_viewport().set_input_as_handled()


func _build_chrome() -> void:
	_title = Label.new()
	_title.name = "SituationDeskTitle"
	_title.text = "当日形势"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", INK)
	_title.add_theme_color_override("font_outline_color", Color(1.0, 0.93, 0.72, 0.72))
	_title.add_theme_constant_override("outline_size", 2)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.z_index = 4
	add_child(_title)

	_subtitle = Label.new()
	_subtitle.name = "SituationDeskSubtitle"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 13)
	_subtitle.add_theme_color_override("font_color", Color(0.16, 0.10, 0.07, 0.78))
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.z_index = 4
	add_child(_subtitle)

	_dossier = Button.new()
	_dossier.name = "CurrentSceneDossier"
	_dossier.text = "当前现场"
	_dossier.tooltip_text = "打开当前保存的现场"
	_dossier.add_theme_font_size_override("font_size", 14)
	_dossier.add_theme_color_override("font_color", INK)
	_dossier.add_theme_color_override("font_hover_color", Color("#6b231d"))
	_dossier.add_theme_stylebox_override("normal", _paper_button_style(Color(0.34, 0.22, 0.13, 0.52)))
	_dossier.add_theme_stylebox_override("hover", _paper_button_style(RED_WAX, true))
	_dossier.add_theme_stylebox_override("pressed", _paper_button_style(Color("#d7b86e"), true))
	_dossier.pressed.connect(func(): context_requested.emit())
	_dossier.z_index = 4
	add_child(_dossier)
	UiMotionScript.bind(_dossier, UiMotionScript.Profile.SITE)

	_think_button = ThinkDropButton.new()
	_think_button.name = "ThinkButton"
	_think_button.owner_desk = self
	_think_button.text = "思考"
	_think_button.tooltip_text = "翻开此刻能够意识到的行动"
	_think_button.add_theme_font_size_override("font_size", 16)
	_think_button.add_theme_color_override("font_color", INK)
	_think_button.add_theme_color_override("font_hover_color", Color("#6b231d"))
	_think_button.add_theme_stylebox_override("normal", _paper_button_style(PAPER_SHADOW))
	_think_button.add_theme_stylebox_override("hover", _paper_button_style(RED_WAX, true))
	_think_button.add_theme_stylebox_override("pressed", _paper_button_style(Color("#d7b86e"), true))
	_think_button.pressed.connect(func(): set_thinking(not _thinking))
	_think_button.z_index = 5
	add_child(_think_button)
	UiMotionScript.bind(_think_button, UiMotionScript.Profile.SITE)

	_thought_heading = Label.new()
	_thought_heading.name = "ThoughtHeading"
	_thought_heading.text = "思考"
	_thought_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thought_heading.add_theme_font_size_override("font_size", 18)
	_thought_heading.add_theme_color_override("font_color", INK)
	_thought_heading.add_theme_color_override("font_outline_color", Color(1.0, 0.93, 0.72, 0.72))
	_thought_heading.add_theme_constant_override("outline_size", 2)
	_thought_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thought_heading.visible = false
	_thought_heading.z_index = 5
	add_child(_thought_heading)

	for spec in SITE_SPECS:
		var button := Button.new()
		button.name = str(spec["name"])
		button.text = str(spec["label"])
		button.tooltip_text = "查看%s可进行的行动" % str(spec["location"])
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override("font_color", INK)
		button.add_theme_color_override("font_hover_color", Color("#6b231d"))
		button.add_theme_stylebox_override("normal", _site_style(Color(0.31, 0.20, 0.12, 0.48)))
		button.add_theme_stylebox_override("hover", _site_style(RED_WAX, true))
		button.add_theme_stylebox_override("pressed", _site_style(Color("#d7b86e"), true))
		button.pressed.connect(open_rite_selector.emit.bind(str(spec["location"])))
		button.z_index = 4
		_site_buttons.append(button)
		add_child(button)
		UiMotionScript.bind(button, UiMotionScript.Profile.SITE)


func refresh_context() -> void:
	if _state == null:
		return
	var location_id := str(_state.world_location_id)
	var location_data: Dictionary = WorldScenes.location(location_id)
	var title := str(location_data.get("title", location_id))
	_subtitle.text = "地图 · 档案 · %s" % title
	_dossier.text = "现场档案\n%s" % title
	_dossier.tooltip_text = "进入%s；现场位置会继续写入当前存档" % title
	queue_redraw()


func set_thinking(enabled: bool) -> void:
	if enabled and is_scene_blocked():
		return
	if _thinking == enabled:
		return
	_thinking = enabled
	_thought_heading.visible = enabled
	_think_button.tooltip_text = (
		"拖入手牌或苏丹卡，聚焦此刻的对象；按 ESC 收起"
		if enabled
		else "翻开此刻能够意识到的行动"
	)
	_update_chrome_visibility()
	thinking_changed.emit(enabled)
	queue_redraw()


func is_thinking() -> bool:
	return _thinking


func set_scene_blocker(source: String, blocking: bool) -> void:
	if source.is_empty():
		return
	if blocking:
		_scene_blockers[source] = true
	else:
		_scene_blockers.erase(source)
	_update_chrome_visibility()
	queue_redraw()


func is_scene_blocked() -> bool:
	return not _scene_blockers.is_empty()


func can_drop_card_on_think_button(data: Variant) -> bool:
	if not _thinking or is_scene_blocked():
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


func set_thought_targets(targets: Array) -> void:
	_thought_targets.clear()
	for target in targets:
		if target is Control:
			_thought_targets.append(target)
	queue_redraw()


func set_thought_count(count: int) -> void:
	_thought_heading.text = "思考" if count > 0 else "此刻没有浮现的念头"


func protagonist_center() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.56)


func _layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var compact := size.x < 760.0
	var title_width := 300.0 if not compact else maxf(170.0, size.x - 220.0)
	var subtitle_width := 420.0 if not compact else maxf(170.0, size.x - 220.0)
	var title_x := (size.x - title_width) * 0.5 if not compact else 204.0
	_title.position = Vector2(title_x, 18.0)
	_title.size = Vector2(title_width, 32.0)
	_subtitle.position = Vector2((size.x - subtitle_width) * 0.5 if not compact else 204.0, 49.0)
	_subtitle.size = Vector2(subtitle_width, 24.0)
	_title.add_theme_font_size_override("font_size", 24 if not compact else 20)
	_subtitle.add_theme_font_size_override("font_size", 13 if not compact else 11)
	_dossier.position = Vector2(24.0, 22.0)
	_dossier.size = Vector2(170.0 if not compact else 160.0, 62.0)
	_think_button.position = Vector2(28.0, size.y - 76.0)
	_think_button.size = Vector2(132.0, 48.0)
	_thought_heading.position = Vector2((size.x - 320.0) * 0.5, 84.0)
	_thought_heading.size = Vector2(320.0, 28.0)
	var site_size := Vector2(116.0, 38.0) if not compact else Vector2(104.0, 36.0)
	for index in _site_buttons.size():
		var site := _site_buttons[index]
		var spec: Dictionary = SITE_SPECS[index]
		var ratio: Vector2 = spec["position"]
		site.size = site_size
		site.position = Vector2(
			clampf(size.x * ratio.x - site_size.x * 0.5, 12.0, size.x - site_size.x - 12.0),
			clampf(size.y * ratio.y - site_size.y * 0.5, 88.0, size.y - site_size.y - 92.0)
		)
	queue_redraw()


func _update_chrome_visibility() -> void:
	var blocked := is_scene_blocked()
	_dossier.visible = not blocked and not _thinking
	_think_button.visible = not blocked
	_thought_heading.visible = _thinking and not blocked
	for site in _site_buttons:
		if is_instance_valid(site):
			site.visible = not blocked and not _thinking


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, PAPER_BASE)
	draw_rect(Rect2(12.0, 12.0, maxf(0.0, size.x - 24.0), maxf(0.0, size.y - 24.0)), PAPER_LIGHT, false, 2.0)
	# Original procedural paper grain and worn map edges.  The constants make the
	# visual stable across frames instead of consuming simulation RNG.
	for i in 36:
		var x := fposmod(float(i * 137), maxf(size.x, 1.0))
		var y := fposmod(float(i * 71 + 31), maxf(size.y, 1.0))
		var radius := 8.0 + float(i % 5) * 5.0
		draw_circle(Vector2(x, y), radius, Color(0.22, 0.13, 0.08, 0.018))
	for inset in [30.0, 58.0]:
		draw_arc(
			Vector2(size.x * 0.5, size.y * 0.55),
			minf(size.x, size.y) * 0.42 - inset,
			-2.64,
			-0.40,
			22,
			Color(0.20, 0.12, 0.075, 0.18),
			1.2,
			true
		)
	var map_nodes := []
	for spec in SITE_SPECS:
		var ratio: Vector2 = spec["position"]
		map_nodes.append(Vector2(size.x * ratio.x, size.y * ratio.y))
	for i in max(0, map_nodes.size() - 1):
		var from: Vector2 = map_nodes[i]
		var to: Vector2 = map_nodes[i + 1]
		draw_line(from, to, Color(0.25, 0.15, 0.09, 0.40), 3.0, true)
		draw_line(from, to, Color(0.89, 0.76, 0.45, 0.42), 1.0, true)
	for point in map_nodes:
		draw_circle(point, 18.0, Color(0.27, 0.16, 0.09, 0.28))
		draw_circle(point, 12.0, Color(0.94, 0.80, 0.50, 0.58))
		draw_circle(point, 5.0, RED_WAX)
	if not _thinking:
		return
	var center := protagonist_center()
	var pulse := 36.0 + sin(_world_time * 2.0) * 2.0
	draw_circle(center, pulse * 1.8, Color(0.37, 0.19, 0.10, 0.12))
	draw_circle(center, pulse, Color(0.78, 0.25, 0.18, 0.20))
	for target in _thought_targets:
		if not is_instance_valid(target) or not target.visible:
			continue
		var target_center := target.position + target.size * 0.5
		draw_line(center, target_center, Color(0.38, 0.14, 0.08, 0.48), 1.4, true)
		draw_circle(target_center, 5.0, RED_WAX)


func _paper_button_style(border: Color, highlighted := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#efd99a") if not highlighted else Color("#f7e7b4")
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	style.shadow_color = Color(0.08, 0.04, 0.02, 0.35)
	style.shadow_size = 4
	return style


func _site_style(border: Color, highlighted := false) -> StyleBoxFlat:
	var style := _paper_button_style(border, highlighted)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	return style
