## A painterly lateral exploration stage for the main game screen.
##
## The simulation still owns rites and events. This control only represents
## those runtime objects spatially: the protagonist can walk, pause to think,
## and reveal the rite buttons supplied by GameScreen.
class_name ThoughtWorld
extends Control

signal thinking_changed(enabled: bool)
signal protagonist_moved()

class ThinkDropButton:
	extends Button

	var owner_world: Control

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return (
			owner_world != null
			and owner_world.has_method("can_drop_card_on_think_button")
			and bool(owner_world.can_drop_card_on_think_button(data))
		)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if owner_world != null and owner_world.has_method("drop_card_on_think_button"):
			owner_world.drop_card_on_think_button(data)


const BACKGROUND_TEXTURE = preload(
	"res://assets/original/thought_world/school_rooftop_sunset.png"
)
const IDLE_TEXTURE = preload(
	"res://assets/original/thought_world/protagonist_idle.png"
)
const THINK_TEXTURE = preload(
	"res://assets/original/thought_world/protagonist_think.png"
)
const WALK_TEXTURES := [
	preload("res://assets/original/thought_world/protagonist_walk_a.png"),
	preload("res://assets/original/thought_world/protagonist_walk_b.png"),
]
const ATMOSPHERE_SHADER = preload(
	"res://ui/shaders/thought_world_atmosphere.gdshader"
)
const SELECT_SOUND = preload(
	"res://assets/third_party/kenney_new_platformer_subset/audio/sfx_select.ogg"
)
const THINK_SOUND = preload(
	"res://assets/third_party/kenney_new_platformer_subset/audio/sfx_magic.ogg"
)

const WALK_SPEED := 330.0
const PLAYER_BASE_SIZE := Vector2(154, 308)
const GROUND_RATIO := 0.94

var _thinking := false
var _player_x_ratio := 0.5
var _walk_time := 0.0
var _world_time := 0.0
var _thought_targets: Array[Control] = []
var _motes: Array[Vector3] = []

var _protagonist: TextureRect
var _atmosphere: ColorRect
var _think_button: Button
var _hint_label: Label
var _scene_title: Label
var _thought_heading: Label
var _audio: AudioStreamPlayer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	_build_overlay()
	_make_motes()
	resized.connect(_layout_overlay)
	_layout_overlay()
	set_process(true)
	queue_redraw()


func _build_overlay() -> void:
	_atmosphere = ColorRect.new()
	_atmosphere.name = "Atmosphere"
	_atmosphere.color = Color.WHITE
	_atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atmosphere.z_index = 1
	var atmosphere_material := ShaderMaterial.new()
	atmosphere_material.shader = ATMOSPHERE_SHADER
	_atmosphere.material = atmosphere_material
	add_child(_atmosphere)

	_scene_title = Label.new()
	_scene_title.name = "SceneTitle"
	_scene_title.text = "1985 · 放学后"
	_scene_title.add_theme_font_size_override("font_size", 13)
	_scene_title.add_theme_color_override("font_color", Color(0.94, 0.94, 0.91, 0.90))
	_scene_title.add_theme_color_override("font_shadow_color", Color(0.03, 0.04, 0.08, 0.72))
	_scene_title.add_theme_constant_override("shadow_offset_x", 1)
	_scene_title.add_theme_constant_override("shadow_offset_y", 2)
	_scene_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_title.z_index = 10
	add_child(_scene_title)

	_hint_label = Label.new()
	_hint_label.name = "MovementHint"
	_hint_label.text = "A / D 或 ← / → 移动"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.91, 0.76))
	_hint_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.07, 0.86))
	_hint_label.add_theme_constant_override("shadow_offset_x", 1)
	_hint_label.add_theme_constant_override("shadow_offset_y", 2)
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.z_index = 10
	add_child(_hint_label)

	_thought_heading = Label.new()
	_thought_heading.name = "ThoughtHeading"
	_thought_heading.text = "思考"
	_thought_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thought_heading.add_theme_font_size_override("font_size", 16)
	_thought_heading.add_theme_color_override("font_color", Color("#fff0bf"))
	_thought_heading.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.07, 0.92))
	_thought_heading.add_theme_constant_override("shadow_offset_x", 1)
	_thought_heading.add_theme_constant_override("shadow_offset_y", 2)
	_thought_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thought_heading.visible = false
	_thought_heading.z_index = 10
	add_child(_thought_heading)

	_protagonist = TextureRect.new()
	_protagonist.name = "Protagonist"
	_protagonist.texture = IDLE_TEXTURE
	_protagonist.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_protagonist.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_protagonist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_protagonist.z_index = 4
	add_child(_protagonist)

	_think_button = ThinkDropButton.new()
	_think_button.name = "ThinkButton"
	(_think_button as ThinkDropButton).owner_world = self
	_think_button.text = "思考"
	_think_button.tooltip_text = "停下脚步，让此刻的念头浮现"
	_think_button.custom_minimum_size = Vector2(138, 54)
	_think_button.add_theme_font_size_override("font_size", 15)
	_think_button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.89, 0.94))
	_think_button.add_theme_color_override("font_hover_color", Color("#fff1bd"))
	_think_button.add_theme_stylebox_override("normal", _think_style(Color(0.86, 0.89, 0.91, 0.42)))
	_think_button.add_theme_stylebox_override("hover", _think_style(Color("#f0c56b"), true))
	_think_button.add_theme_stylebox_override("pressed", _think_style(Color("#fff0b3"), true))
	_think_button.pressed.connect(func(): set_thinking(not _thinking))
	_think_button.z_index = 12
	add_child(_think_button)

	_audio = AudioStreamPlayer.new()
	_audio.name = "SceneAudio"
	_audio.volume_db = -9.0
	add_child(_audio)


func _make_motes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13071985
	for i in 38:
		_motes.append(Vector3(rng.randf(), rng.randf_range(0.18, 0.86), rng.randf_range(0.35, 1.0)))


func _process(delta: float) -> void:
	_world_time += delta
	var direction := 0.0
	if not _thinking and not _has_blocking_overlay():
		direction = Input.get_axis("ui_left", "ui_right")
		if Input.is_key_pressed(KEY_A):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D):
			direction += 1.0
		direction = clampf(direction, -1.0, 1.0)
	if not is_zero_approx(direction):
		var usable_width := maxf(size.x - 170.0, 1.0)
		_player_x_ratio = clampf(
			_player_x_ratio + direction * WALK_SPEED * delta / usable_width,
			0.04,
			0.96
		)
		_walk_time += delta
		_protagonist.flip_h = direction < 0.0
		_protagonist.texture = WALK_TEXTURES[int(_walk_time * 5.0) % WALK_TEXTURES.size()]
		_layout_protagonist()
		protagonist_moved.emit()
	else:
		_walk_time = 0.0
		_protagonist.texture = THINK_TEXTURE if _thinking else IDLE_TEXTURE
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_SPACE:
		set_thinking(not _thinking)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_ESCAPE and _thinking:
		set_thinking(false)
		get_viewport().set_input_as_handled()


func _has_blocking_overlay() -> bool:
	var screen := get_parent()
	if screen == null:
		return false
	for overlay_name in ["EventPromptOverlay", "CardDetailOverlay"]:
		var overlay := screen.find_child(overlay_name, true, false)
		if overlay != null and overlay.visible:
			return true
	return false


func set_thinking(enabled: bool) -> void:
	if _thinking == enabled:
		return
	_thinking = enabled
	_protagonist.texture = THINK_TEXTURE if enabled else IDLE_TEXTURE
	_thought_heading.visible = enabled
	_hint_label.text = "选择一段思绪，或按 ESC 回到现实" if enabled else "A / D 或 ← / → 移动"
	_think_button.text = "思考"
	_think_button.tooltip_text = (
		"拖入手牌或苏丹卡产生联想；点击或按 ESC 结束思考"
		if enabled
		else "停下脚步，让此刻的念头浮现"
	)
	_audio.stream = THINK_SOUND if enabled else SELECT_SOUND
	if not DisplayServer.get_name() == "headless":
		_audio.play()
	_layout_overlay()
	thinking_changed.emit(enabled)
	queue_redraw()


func is_thinking() -> bool:
	return _thinking


func can_drop_card_on_think_button(data: Variant) -> bool:
	if not _thinking:
		return false
	var screen := get_parent()
	# Methinks is the verified clone-era processing bridge. Keep that internal
	# compatibility boundary while the player-facing concept remains Thought.
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
	if count <= 0:
		_thought_heading.text = "此刻没有浮现的念头"
	else:
		# The runtime currently knows how many placeholder rites are visible,
		# but presenting a total would imply that the character sees an
		# exhaustive action menu. The new direction keeps that count internal.
		_thought_heading.text = "思考"


func protagonist_center() -> Vector2:
	if _protagonist == null:
		return Vector2(size.x * _player_x_ratio, size.y * GROUND_RATIO)
	return _protagonist.position + _protagonist.size * Vector2(0.5, 0.43)


func set_player_x_ratio_for_test(value: float) -> void:
	_player_x_ratio = clampf(value, 0.04, 0.96)
	_layout_protagonist()
	protagonist_moved.emit()


func player_x_ratio() -> float:
	return _player_x_ratio


func _layout_overlay() -> void:
	if _protagonist == null:
		return
	_atmosphere.position = Vector2.ZERO
	_atmosphere.size = size
	_scene_title.position = Vector2(20, 15)
	_scene_title.size = Vector2(220, 26)
	_hint_label.position = Vector2((size.x - 360.0) * 0.5, size.y - 28.0)
	_hint_label.size = Vector2(360, 22)
	_thought_heading.position = Vector2((size.x - 320.0) * 0.5, 15)
	_thought_heading.size = Vector2(320, 28)
	_think_button.position = Vector2(24.0, size.y - 82.0)
	_think_button.size = Vector2(138, 54)
	_layout_protagonist()
	protagonist_moved.emit()
	queue_redraw()


func _layout_protagonist() -> void:
	if _protagonist == null:
		return
	var scale_factor := clampf(size.y / 420.0, 0.74, 1.22)
	var player_size := PLAYER_BASE_SIZE * scale_factor
	var half_width := player_size.x * 0.55
	var center_x := lerpf(half_width, maxf(half_width, size.x - half_width), _player_x_ratio)
	var ground_y := size.y * GROUND_RATIO
	_protagonist.position = Vector2(center_x - player_size.x * 0.5, ground_y - player_size.y)
	_protagonist.size = player_size


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("#1d2440"))
	_draw_background_cover(rect)

	# A restrained cinematic grade: warm horizon, cool vignette and deep
	# foreground shapes. The illustration stays readable instead of becoming a
	# game-board texture.
	for i in 10:
		var t := float(i) / 10.0
		draw_rect(
			Rect2(0, size.y * (0.72 + t * 0.028), size.x, size.y * 0.035),
			Color(0.025, 0.035, 0.075, 0.018 + t * 0.012)
		)
	for radius in [180.0, 130.0, 82.0]:
		var alpha: float = 0.012 + (180.0 - float(radius)) / 8000.0
		draw_circle(Vector2(size.x * 0.12, size.y * 0.48), radius, Color(1.0, 0.63, 0.28, alpha))

	var ground_y := size.y * GROUND_RATIO
	draw_set_transform(Vector2(size.x * _player_x_ratio, ground_y + 2.0), 0.0, Vector2(2.4, 0.34))
	draw_circle(Vector2.ZERO, 38.0, Color(0.02, 0.025, 0.055, 0.34))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for mote in _motes:
		var drift_x := fposmod(mote.x + _world_time * 0.006 * mote.z, 1.0)
		var pulse := 0.16 + 0.18 * sin(_world_time * mote.z * 1.8 + mote.x * 12.0)
		draw_circle(
			Vector2(drift_x * size.x, mote.y * size.y),
			0.7 + mote.z * 1.2,
			Color(1.0, 0.78, 0.43, maxf(0.04, pulse))
		)

	if _thinking:
		draw_rect(rect, Color(0.035, 0.045, 0.105, 0.46))
		var center := protagonist_center()
		var pulse_radius := 62.0 + sin(_world_time * 2.0) * 4.0
		draw_circle(center, pulse_radius * 0.72, Color(1.0, 0.79, 0.38, 0.035))
		for segment in 7:
			var start := -1.7 + float(segment) * 0.78
			var length := 0.22 + 0.09 * sin(float(segment) * 1.7)
			draw_arc(
				center,
				pulse_radius + float(segment % 2) * 11.0,
				start,
				start + length,
				12,
				Color(1.0, 0.86, 0.56, 0.56),
				1.4,
				true
			)
		for target in _thought_targets:
			if not is_instance_valid(target) or not target.visible:
				continue
			var target_center := target.position + target.size * 0.5
			draw_line(center, target_center, Color(1.0, 0.83, 0.55, 0.24), 1.0, true)
			draw_circle(target_center, 3.2, Color(1.0, 0.88, 0.64, 0.78))
			draw_circle(target_center, 7.0, Color(1.0, 0.78, 0.38, 0.08))


func _draw_background_cover(target: Rect2) -> void:
	var texture_size := BACKGROUND_TEXTURE.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or target.size.y <= 0.0:
		return
	var target_aspect := target.size.x / target.size.y
	var texture_aspect := texture_size.x / texture_size.y
	var source := Rect2(Vector2.ZERO, texture_size)
	if target_aspect > texture_aspect:
		source.size.y = texture_size.x / target_aspect
		source.position.y = (texture_size.y - source.size.y) * 0.64
	else:
		source.size.x = texture_size.y * target_aspect
		source.position.x = (texture_size.x - source.size.x) * 0.5
	draw_texture_rect_region(BACKGROUND_TEXTURE, target, source)


func _think_style(border: Color, bright := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.045, 0.09, 0.50) if not bright else Color(0.08, 0.075, 0.12, 0.72)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(8)
	style.shadow_color = Color(0.01, 0.015, 0.04, 0.38)
	style.shadow_size = 4
	return style
