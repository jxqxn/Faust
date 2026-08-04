## A painterly lateral exploration stage for the main game screen.
##
## The simulation still owns rites and events. This control only represents
## those runtime objects spatially: the protagonist can walk, pause to think,
## and reveal the rite buttons supplied by GameScreen.
class_name ThoughtWorld
extends Control

signal protagonist_moved()
signal interaction_requested(interaction: Dictionary)
signal location_changed(location_id: String)
signal return_requested()

class ParallaxTextureLayer:
	extends Control

	var texture: Texture2D
	var pan_ratio := 0.0
	var zoom := 1.0
	var crop_anchor := 0.5
	var tint := Color.WHITE

	func set_view(next_texture: Texture2D, next_pan: float, next_zoom: float, next_anchor: float) -> void:
		texture = next_texture
		pan_ratio = clampf(next_pan, 0.0, 1.0)
		zoom = maxf(next_zoom, 1.0)
		crop_anchor = clampf(next_anchor, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		if texture == null or size.x <= 0.0 or size.y <= 0.0:
			return
		var texture_size := texture.get_size()
		if texture_size.x <= 0.0 or texture_size.y <= 0.0:
			return
		var target_aspect := size.x / size.y
		var source := Rect2(Vector2.ZERO, texture_size)
		if texture_size.x / texture_size.y > target_aspect:
			source.size.x = texture_size.y * target_aspect
		else:
			source.size.y = texture_size.x / target_aspect
		var base_source_size := source.size
		source.size = base_source_size / zoom
		var horizontal_room := texture_size.x - source.size.x
		var vertical_room := texture_size.y - source.size.y
		source.position = Vector2(horizontal_room * pan_ratio, vertical_room * crop_anchor)
		draw_texture_rect_region(texture, Rect2(Vector2.ZERO, size), source, tint)


class StageEffectsLayer:
	extends Control

	var ambient := "highland"
	var world_time := 0.0
	var pan_ratio := 0.0
	var reduced_motion := false
	var particles: Array[Vector4] = []

	func configure(next_ambient: String, seed: int) -> void:
		ambient = next_ambient
		particles.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		for i in 18:
			particles.append(Vector4(rng.randf(), rng.randf_range(0.2, 0.9), rng.randf_range(0.5, 1.4), rng.randf_range(-1.0, 1.0)))
		queue_redraw()

	func set_view(next_time: float, next_pan: float, motion_reduced: bool) -> void:
		world_time = next_time
		pan_ratio = next_pan
		reduced_motion = motion_reduced
		queue_redraw()

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var animation_time := 0.0 if reduced_motion else world_time
		if ambient == "river":
			for ribbon in 4:
				var y := size.y * (0.61 + float(ribbon) * 0.055)
				var drift := sin(animation_time * (0.13 + ribbon * 0.025) + ribbon) * 38.0
				draw_arc(
					Vector2(size.x * (0.52 - pan_ratio * 0.08) + drift, y),
					size.x * (0.26 + ribbon * 0.035),
					3.32,
					6.04,
					42,
					Color(0.70, 0.78, 0.74, 0.035 + ribbon * 0.006),
					2.0 + ribbon * 0.5,
					true
				)
		else:
			for particle in particles:
				var drift_x := fposmod(particle.x + animation_time * 0.012 * particle.z - pan_ratio * 0.06, 1.08) - 0.04
				var y := particle.y * size.y + sin(animation_time * particle.z + particle.x * 9.0) * 7.0
				var center := Vector2(drift_x * size.x, y)
				var angle := animation_time * 0.55 * particle.w
				var tangent := Vector2(cos(angle), sin(angle)) * (2.0 + particle.z * 2.2)
				draw_line(center - tangent, center + tangent, Color(0.85, 0.66, 0.27, 0.20), 1.2, true)


const WorldScenes = preload("res://sim/world_scene_catalog.gd")
const UiMotionScript = preload("res://ui/ui_motion.gd")
const IDLE_TEXTURE = preload(
	"res://assets/original/thought_world/protagonist_traveler_idle.png"
)
const WALK_TEXTURES := [
	preload("res://assets/original/thought_world/protagonist_traveler_walk_a.png"),
	preload("res://assets/original/thought_world/protagonist_traveler_walk_b.png"),
]
const ATMOSPHERE_SHADER = preload(
	"res://ui/shaders/thought_world_atmosphere.gdshader"
)

const WALK_SPEED := 330.0
const INTERACTION_ARRIVAL_EPSILON := 0.0005
const PLAYER_BASE_SIZE := Vector2(154, 308)
const NPC_BASE_SIZE := Vector2(150, 300)
const CAMERA_RESPONSE := 5.5
const EXIT_TRANSITION_SECONDS := 0.30

var _context_mode := false
var _player_x_ratio := 0.5
var _location_id := WorldScenes.DEFAULT_LOCATION_ID
var _location_data: Dictionary = {}
var _background_texture: Texture2D
var _foreground_texture: Texture2D
var _state
var _walk_time := 0.0
var _world_time := 0.0
var _motes: Array[Vector3] = []
var _npc_nodes: Array[Dictionary] = []
var _exit_nodes: Array[Dictionary] = []
var _scene_blockers: Dictionary = {}
var _interaction_walk_active := false
var _interaction_walk_target := 0.5
var _pending_npc_interaction: Dictionary = {}
var _exit_transition_active := false
var _exit_transition_elapsed := 0.0
var _pending_exit_interaction: Dictionary = {}
var _camera_pan := 0.5
var _camera_target_pan := 0.5
var _camera_focus_ratio := -1.0
var _dialogue_focus_ratio := -1.0

var _protagonist: TextureRect
var _backdrop_layer: ParallaxTextureLayer
var _atmosphere: ColorRect
var _foreground_layer: ParallaxTextureLayer
var _stage_effects: StageEffectsLayer
var _return_button: Button
var _hint_label: Label
var _scene_title: Label
var _interaction_hint: Label
var _transition_flash: ColorRect


func setup(state) -> void:
	_state = state
	if state == null:
		return
	_location_id = str(state.world_location_id)
	_player_x_ratio = clampf(float(state.world_position_ratio), 0.04, 0.96)


## GameScreen uses the lateral world as a local dossier.
func set_context_mode(enabled: bool) -> void:
	_context_mode = enabled
	if is_node_ready():
		_apply_presentation()
		_layout_overlay()


func reload_from_state() -> void:
	if _state == null:
		return
	_location_id = str(_state.world_location_id)
	_player_x_ratio = clampf(float(_state.world_position_ratio), 0.04, 0.96)
	if is_node_ready():
		_apply_location(_location_id, str(_state.world_spawn_id), true, false)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	_build_overlay()
	_make_motes()
	_apply_location(_location_id, "", true, false)
	resized.connect(_layout_overlay)
	_layout_overlay()
	_apply_presentation()
	set_process(true)
	queue_redraw()


func _build_overlay() -> void:
	_backdrop_layer = ParallaxTextureLayer.new()
	_backdrop_layer.name = "BackdropParallax"
	_backdrop_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_layer.z_index = 0
	add_child(_backdrop_layer)

	_atmosphere = ColorRect.new()
	_atmosphere.name = "Atmosphere"
	_atmosphere.color = Color.WHITE
	_atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atmosphere.z_index = 2
	var atmosphere_material := ShaderMaterial.new()
	atmosphere_material.shader = ATMOSPHERE_SHADER
	atmosphere_material.set_shader_parameter("world_time", _world_time)
	_atmosphere.material = atmosphere_material
	add_child(_atmosphere)

	_scene_title = Label.new()
	_scene_title.name = "SceneTitle"
	_scene_title.text = "高地驿台 · 暮光"
	_scene_title.add_theme_font_size_override("font_size", 13)
	_scene_title.add_theme_color_override("font_color", Color(0.96, 0.87, 0.66, 0.94))
	_scene_title.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.82))
	_scene_title.add_theme_constant_override("shadow_offset_x", 1)
	_scene_title.add_theme_constant_override("shadow_offset_y", 2)
	_scene_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_title.z_index = 20
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
	_hint_label.z_index = 20
	add_child(_hint_label)

	_protagonist = TextureRect.new()
	_protagonist.name = "Protagonist"
	_protagonist.texture = IDLE_TEXTURE
	_protagonist.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_protagonist.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_protagonist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_protagonist.z_index = 6
	add_child(_protagonist)

	_foreground_layer = ParallaxTextureLayer.new()
	_foreground_layer.name = "ForegroundOcclusion"
	_foreground_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foreground_layer.z_index = 9
	add_child(_foreground_layer)

	_stage_effects = StageEffectsLayer.new()
	_stage_effects.name = "EnvironmentLoop"
	_stage_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_effects.z_index = 10
	add_child(_stage_effects)

	_interaction_hint = Label.new()
	_interaction_hint.name = "WorldInteractionHint"
	_interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interaction_hint.add_theme_font_size_override("font_size", 15)
	_interaction_hint.add_theme_color_override("font_color", Color("#fff3cb"))
	_interaction_hint.add_theme_color_override("font_shadow_color", Color(0.01, 0.02, 0.05, 0.92))
	_interaction_hint.add_theme_constant_override("shadow_offset_x", 1)
	_interaction_hint.add_theme_constant_override("shadow_offset_y", 2)
	_interaction_hint.add_theme_stylebox_override("normal", _interaction_style())
	_interaction_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interaction_hint.visible = false
	_interaction_hint.z_index = 25
	add_child(_interaction_hint)

	_return_button = Button.new()
	_return_button.name = "ReturnToDeskButton"
	_return_button.text = "← 当日形势"
	_return_button.tooltip_text = "回到地图与档案，保留当前位置和未处理事项"
	_return_button.add_theme_font_size_override("font_size", 14)
	_return_button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.89, 0.94))
	_return_button.add_theme_color_override("font_hover_color", Color("#fff1bd"))
	_return_button.add_theme_stylebox_override("normal", _chrome_button_style(Color(0.86, 0.89, 0.91, 0.42)))
	_return_button.add_theme_stylebox_override("hover", _chrome_button_style(Color("#f0c56b"), true))
	_return_button.add_theme_stylebox_override("pressed", _chrome_button_style(Color("#fff0b3"), true))
	_return_button.pressed.connect(func(): return_requested.emit())
	_return_button.visible = false
	_return_button.z_index = 22
	add_child(_return_button)

	_transition_flash = ColorRect.new()
	_transition_flash.name = "LocationTransition"
	_transition_flash.color = Color(0.96, 0.72, 0.40, 0.0)
	_transition_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_flash.z_index = 30
	add_child(_transition_flash)


func _make_motes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13072024
	for i in 38:
		_motes.append(Vector3(rng.randf(), rng.randf_range(0.18, 0.86), rng.randf_range(0.35, 1.0)))


func _update_atmosphere_time() -> void:
	if _atmosphere == null:
		return
	var atmosphere_material := _atmosphere.material as ShaderMaterial
	if atmosphere_material != null:
		atmosphere_material.set_shader_parameter("world_time", _world_time)


func _process(delta: float) -> void:
	# In GameScreen this control stays constructed for save continuity, but it
	# must not react to movement or interaction input until its dossier is open.
	if not is_visible_in_tree():
		return
	var direction := 0.0
	var blocking := _has_blocking_overlay()
	if not blocking:
		_world_time += delta
		_update_atmosphere_time()
	_apply_presentation()
	if _exit_transition_active:
		_update_exit_transition(delta)
	elif _interaction_walk_active:
		direction = signf(_interaction_walk_target - _player_x_ratio)
	elif not blocking:
		direction = Input.get_axis("ui_left", "ui_right")
		if Input.is_key_pressed(KEY_A):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D):
			direction += 1.0
		direction = clampf(direction, -1.0, 1.0)
	if not is_zero_approx(direction):
		var step := WALK_SPEED * delta / maxf(_world_width(), 1.0)
		if _interaction_walk_active:
			_player_x_ratio = move_toward(_player_x_ratio, _interaction_walk_target, step)
		else:
			_player_x_ratio = clampf(_player_x_ratio + direction * step, 0.04, 0.96)
		_walk_time += delta
		_protagonist.flip_h = direction < 0.0
		_protagonist.texture = WALK_TEXTURES[int(_walk_time * 5.0) % WALK_TEXTURES.size()]
		_layout_protagonist()
		_store_player_position()
		protagonist_moved.emit()
		if (
			_interaction_walk_active
			and absf(_interaction_walk_target - _player_x_ratio)
			<= INTERACTION_ARRIVAL_EPSILON
		):
			_finish_npc_interaction()
	else:
		if not _exit_transition_active:
			_walk_time = 0.0
			_protagonist.texture = IDLE_TEXTURE
		if _interaction_walk_active:
			_finish_npc_interaction()
	_update_camera(delta)
	_layout_stage()
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_E and not _has_blocking_overlay():
		interact_with_nearest()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_ESCAPE and _context_mode and not _has_blocking_overlay():
		return_requested.emit()
		get_viewport().set_input_as_handled()


func _has_blocking_overlay() -> bool:
	if is_scene_blocked():
		return true
	return _has_implicit_blocking_overlay()


func _has_implicit_blocking_overlay() -> bool:
	# Compatibility fallback for callers that have not adopted the explicit
	# blocker API. Wildcards also tolerate a transient Godot auto-rename.
	var screen := get_parent()
	if screen == null:
		return false
	for overlay_name in ["EventPromptOverlay*", "CardDetailOverlay*"]:
		var overlay := screen.find_child(overlay_name, true, false)
		if overlay != null and overlay.visible:
			return true
	return false


## `hide_chrome` separates a local modal that replaces the scene's controls
## from a global pause layer that leaves the exact underlying presentation in
## place while its own shade absorbs all input.
func set_scene_blocker(source: String, blocking: bool, hide_chrome: bool = true) -> void:
	if source.is_empty():
		return
	if blocking:
		_scene_blockers[source] = hide_chrome
	else:
		_scene_blockers.erase(source)
		if _scene_blockers.is_empty():
			_dialogue_focus_ratio = -1.0
	_apply_presentation()
	queue_redraw()


func is_scene_blocked() -> bool:
	return not _scene_blockers.is_empty()


func is_scene_chrome_hidden() -> bool:
	for hide_chrome in _scene_blockers.values():
		if bool(hide_chrome):
			return true
	return _has_implicit_blocking_overlay()


func protagonist_center() -> Vector2:
	if _protagonist == null:
		return Vector2(size.x * _player_x_ratio, size.y * _ground_ratio())
	return _protagonist.position + _protagonist.size * Vector2(0.5, 0.43)


func dialogue_anchor_global(actor_id: String) -> Vector2:
	var actor: Control = null
	if actor_id == "protagonist":
		actor = _protagonist
	else:
		for entry in _npc_nodes:
			var data: Dictionary = entry.get("data", {})
			if str(data.get("id", "")) == actor_id:
				actor = entry.get("node") as Control
				break
	if actor == null:
		return get_global_transform() * protagonist_center()
	return actor.get_global_transform() * (actor.size * Vector2(0.5, 0.02))


func set_player_x_ratio_for_test(value: float) -> void:
	_player_x_ratio = clampf(value, 0.04, 0.96)
	_camera_target_pan = _camera_pan_for_ratio(_player_x_ratio)
	_camera_pan = _camera_target_pan
	_layout_stage()
	_store_player_position()
	_apply_presentation()
	protagonist_moved.emit()


func player_x_ratio() -> float:
	return _player_x_ratio


func location_id() -> String:
	return _location_id


func is_approaching_interaction() -> bool:
	return _interaction_walk_active


func is_exit_transition_active() -> bool:
	return _exit_transition_active


func change_location(location_id_value: String, spawn_id: String = "default") -> bool:
	if not WorldScenes.LOCATIONS.has(location_id_value):
		return false
	_apply_location(location_id_value, spawn_id, false, true)
	return true


func interact_with_nearest() -> bool:
	if _has_blocking_overlay() or _interaction_walk_active or _exit_transition_active:
		return false
	var interaction := _nearest_interaction()
	if interaction.is_empty():
		return false
	if str(interaction.get("type", "")) == "exit":
		_begin_exit_transition(interaction)
		return true
	if str(interaction.get("type", "")) == "npc":
		_begin_npc_interaction(interaction)
		return true
	return false


func _layout_overlay() -> void:
	if _protagonist == null:
		return
	_backdrop_layer.position = Vector2.ZERO
	_backdrop_layer.size = size
	_atmosphere.position = Vector2.ZERO
	_atmosphere.size = size
	_foreground_layer.position = Vector2.ZERO
	_foreground_layer.size = size
	_stage_effects.position = Vector2.ZERO
	_stage_effects.size = size
	_scene_title.position = Vector2((size.x - 300.0) * 0.5, 15)
	_scene_title.size = Vector2(300, 26)
	_scene_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.position = Vector2((size.x - 360.0) * 0.5, size.y - 28.0)
	_hint_label.size = Vector2(360, 22)
	_return_button.position = Vector2(24.0, 22.0)
	_return_button.size = Vector2(170.0, 62.0)
	_interaction_hint.position = Vector2((size.x - 360.0) * 0.5, size.y - 76.0)
	_interaction_hint.size = Vector2(360, 40)
	_transition_flash.position = Vector2.ZERO
	_transition_flash.size = size
	_layout_stage()
	_apply_presentation()
	protagonist_moved.emit()
	queue_redraw()


func _layout_stage() -> void:
	_layout_protagonist()
	_layout_location_actors()
	_update_parallax_layers()
	if _stage_effects != null:
		_stage_effects.set_view(_world_time, _camera_pan, UiMotionScript.reduced_motion)


func _layout_protagonist() -> void:
	if _protagonist == null:
		return
	var scale_factor := clampf(size.y / 420.0, 0.74, 1.22)
	var motion_scale := 1.0
	var vertical_offset := 0.0
	if not UiMotionScript.reduced_motion and not is_scene_blocked():
		if _walk_time > 0.0 or _exit_transition_active:
			vertical_offset = absf(sin(_world_time * 10.5)) * -3.0
			motion_scale = 1.0 + sin(_world_time * 10.5) * 0.004
		else:
			vertical_offset = sin(_world_time * 1.75) * 1.7
			motion_scale = 1.0 + sin(_world_time * 1.75 + 0.6) * 0.006
	var player_size := PLAYER_BASE_SIZE * scale_factor * motion_scale
	var center_x := _world_to_screen_x(_player_x_ratio)
	var ground_y := _ground_y_for_ratio(_player_x_ratio) + vertical_offset
	_protagonist.position = Vector2(center_x - player_size.x * 0.5, ground_y - player_size.y)
	_protagonist.size = player_size
	_protagonist.pivot_offset = player_size * Vector2(0.5, 0.96)
	_protagonist.rotation = 0.0 if UiMotionScript.reduced_motion else sin(_world_time * 2.1) * 0.004


func _layout_location_actors() -> void:
	var scale_factor := clampf(size.y / 420.0, 0.74, 1.22)
	var actor_size := NPC_BASE_SIZE * scale_factor
	for actor_index in _npc_nodes.size():
		var entry: Dictionary = _npc_nodes[actor_index]
		var node: TextureRect = entry.get("node")
		var data: Dictionary = entry.get("data", {})
		if node == null:
			continue
		var actor_ratio := float(data.get("x_ratio", 0.5))
		var center_x := _world_to_screen_x(actor_ratio)
		var ground_y := _ground_y_for_ratio(actor_ratio)
		var idle_phase := _world_time * 1.45 + actor_index * 1.37
		var npc_scale := 1.0 if UiMotionScript.reduced_motion or is_scene_blocked() else 1.0 + sin(idle_phase) * 0.005
		var staged_size := actor_size * npc_scale
		var idle_y := 0.0 if UiMotionScript.reduced_motion or is_scene_blocked() else sin(idle_phase + 0.4) * 1.4
		node.position = Vector2(center_x - staged_size.x * 0.5, ground_y - staged_size.y + idle_y)
		node.size = staged_size
		node.pivot_offset = staged_size * Vector2(0.5, 0.96)
		node.rotation = 0.0 if UiMotionScript.reduced_motion else sin(idle_phase * 0.72) * 0.003
		if absf(_player_x_ratio - actor_ratio) <= 0.24 or _dialogue_focus_ratio >= 0.0:
			node.flip_h = _player_x_ratio > actor_ratio
		node.z_index = 5 + int(round(ground_y / maxf(size.y, 1.0) * 2.0))
	for entry in _exit_nodes:
		var node: Label = entry.get("node")
		var data: Dictionary = entry.get("data", {})
		if node == null:
			continue
		var marker_width := minf(220.0, maxf(120.0, size.x - 32.0))
		var marker_center := _world_to_screen_x(float(data.get("x_ratio", 0.05)))
		var ground_y := _ground_y_for_ratio(float(data.get("x_ratio", 0.05)))
		node.position = Vector2(
			clampf(marker_center - marker_width * 0.5, 16.0, size.x - marker_width - 16.0),
			ground_y - 112.0
		)
		node.size = Vector2(marker_width, 34)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("#30291f"))

	# A restrained cinematic grade: warm horizon, cool vignette and deep
	# foreground shapes. The illustration stays readable instead of becoming a
	# game-board texture.
	for i in 10:
		var t := float(i) / 10.0
		draw_rect(
			Rect2(0, size.y * (0.72 + t * 0.028), size.x, size.y * 0.035),
			Color(0.09, 0.075, 0.05, 0.018 + t * 0.012)
		)
	for radius in [180.0, 130.0, 82.0]:
		var alpha: float = 0.012 + (180.0 - float(radius)) / 8000.0
		draw_circle(Vector2(size.x * 0.12, size.y * 0.48), radius, Color(0.95, 0.69, 0.34, alpha))

	var ground_y := _ground_y_for_ratio(_player_x_ratio)
	draw_set_transform(Vector2(_world_to_screen_x(_player_x_ratio), ground_y + 2.0), 0.0, Vector2(2.4, 0.34))
	draw_circle(Vector2.ZERO, 38.0, Color(0.07, 0.055, 0.035, 0.34))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for entry in _npc_nodes:
		var data: Dictionary = entry.get("data", {})
		var npc_ratio := float(data.get("x_ratio", 0.5))
		draw_set_transform(
			Vector2(_world_to_screen_x(npc_ratio), _ground_y_for_ratio(npc_ratio) + 2.0),
			0.0,
			Vector2(2.15, 0.31)
		)
		draw_circle(Vector2.ZERO, 34.0, Color(0.07, 0.055, 0.035, 0.28))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for mote in _motes:
		var drift_x := fposmod(mote.x + _world_time * 0.006 * mote.z - _camera_pan * 0.025, 1.0)
		var pulse := 0.16 + 0.18 * sin(_world_time * mote.z * 1.8 + mote.x * 12.0)
		draw_circle(
			Vector2(drift_x * size.x, mote.y * size.y),
			0.7 + mote.z * 1.2,
			Color(1.0, 0.78, 0.43, maxf(0.04, pulse))
		)


func _apply_location(
	location_id_value: String,
	spawn_id: String,
	use_saved_position: bool,
	play_transition: bool
) -> void:
	_cancel_npc_interaction()
	_location_id = (
		location_id_value
		if WorldScenes.LOCATIONS.has(location_id_value)
		else WorldScenes.DEFAULT_LOCATION_ID
	)
	_location_data = WorldScenes.location(_location_id)
	var background_path := str(_location_data.get("background", ""))
	_background_texture = load(background_path) as Texture2D
	var foreground_path := str(_location_data.get("foreground", ""))
	_foreground_texture = load(foreground_path) as Texture2D
	_camera_focus_ratio = -1.0
	_dialogue_focus_ratio = -1.0
	_scene_title.text = str(_location_data.get("title", _location_id))
	if not use_saved_position:
		_player_x_ratio = WorldScenes.spawn_ratio(_location_id, spawn_id)
	_clear_location_actors()
	_build_location_actors()
	if _stage_effects != null:
		_stage_effects.configure(str(_location_data.get("ambient", "highland")), _location_id.hash())
	_camera_target_pan = _camera_pan_for_ratio(_player_x_ratio)
	_camera_pan = _camera_target_pan
	if _state != null:
		_state.world_location_id = _location_id
		if not use_saved_position or not spawn_id.is_empty():
			_state.world_spawn_id = spawn_id if not spawn_id.is_empty() else "default"
		_state.world_position_ratio = _player_x_ratio
		if _location_id not in _state.visited_world_locations:
			_state.visited_world_locations.append(_location_id)
	_layout_overlay()
	location_changed.emit(_location_id)
	if play_transition:
		_play_location_transition()


func _clear_location_actors() -> void:
	for entry in _npc_nodes:
		var node: Node = entry.get("node")
		if is_instance_valid(node):
			node.free()
	for entry in _exit_nodes:
		var node: Node = entry.get("node")
		if is_instance_valid(node):
			node.free()
	_npc_nodes.clear()
	_exit_nodes.clear()


func _build_location_actors() -> void:
	for raw_npc in _location_data.get("npcs", []):
		if not (raw_npc is Dictionary):
			continue
		var npc_data: Dictionary = raw_npc.duplicate(true)
		var sprite := TextureRect.new()
		sprite.name = "WorldNpc_%s" % str(npc_data.get("id", "unknown"))
		sprite.texture = load(str(npc_data.get("sprite", "")))
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.z_index = 5
		add_child(sprite)
		_npc_nodes.append({"data": npc_data, "node": sprite})
	for raw_exit in _location_data.get("exits", []):
		if not (raw_exit is Dictionary):
			continue
		var exit_data: Dictionary = raw_exit.duplicate(true)
		var marker := Label.new()
		marker.name = "WorldExit_%s" % str(exit_data.get("id", "unknown"))
		marker.text = "%s  %s" % [
			str(exit_data.get("direction", "←")),
			str(exit_data.get("label", "前往")),
		]
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.add_theme_font_size_override("font_size", 13)
		marker.add_theme_color_override("font_color", Color(0.96, 0.86, 0.62, 0.78))
		marker.add_theme_color_override("font_shadow_color", Color(0.01, 0.02, 0.05, 0.92))
		marker.add_theme_constant_override("shadow_offset_x", 1)
		marker.add_theme_constant_override("shadow_offset_y", 2)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.z_index = 8
		add_child(marker)
		_exit_nodes.append({"data": exit_data, "node": marker})


func _nearest_interaction() -> Dictionary:
	var nearest := {}
	var nearest_distance := INF
	for entry in _npc_nodes:
		var data: Dictionary = entry.get("data", {})
		var distance := absf(_player_x_ratio - float(data.get("x_ratio", 0.5)))
		if distance <= float(data.get("radius", 0.08)) and distance < nearest_distance:
			nearest_distance = distance
			nearest = data.duplicate(true)
			nearest["type"] = "npc"
			nearest["location_id"] = _location_id
	for entry in _exit_nodes:
		var data: Dictionary = entry.get("data", {})
		var distance := absf(_player_x_ratio - float(data.get("x_ratio", 0.5)))
		if distance <= float(data.get("radius", 0.08)) and distance < nearest_distance:
			nearest_distance = distance
			nearest = data.duplicate(true)
			nearest["type"] = "exit"
			nearest["location_id"] = _location_id
	return nearest


func _update_interaction_hint() -> void:
	if _interaction_hint == null:
		return
	var interaction := _nearest_interaction()
	_interaction_hint.visible = (
		not _interaction_walk_active
		and not interaction.is_empty()
		and not is_scene_chrome_hidden()
	)
	if not _interaction_hint.visible:
		return
	if str(interaction.get("type", "")) == "npc":
		_interaction_hint.text = "E  ·  %s" % str(interaction.get("prompt", "交谈"))
	else:
		_interaction_hint.text = "E  ·  %s" % str(interaction.get("label", "前往"))


## One rendering pass derives every thought-world control from the scene state.
## Buttons never toggle sibling visibility directly.
func _apply_presentation() -> void:
	var hide_chrome := is_scene_chrome_hidden() or _interaction_walk_active or _exit_transition_active
	if _return_button != null:
		_return_button.visible = not hide_chrome and _context_mode
	if _hint_label != null:
		_hint_label.visible = not hide_chrome
	for entry in _exit_nodes:
		var node: Control = entry.get("node")
		if node != null:
			node.visible = not hide_chrome
	_update_interaction_hint()


func _begin_exit_transition(interaction: Dictionary) -> void:
	_pending_exit_interaction = interaction.duplicate(true)
	_exit_transition_active = true
	_exit_transition_elapsed = 0.0
	_camera_focus_ratio = clampf(float(interaction.get("x_ratio", _player_x_ratio)), 0.0, 1.0)
	_protagonist.flip_h = str(interaction.get("direction", "←")) == "←"
	_apply_presentation()
	if UiMotionScript.reduced_motion:
		_complete_exit_transition()


func _update_exit_transition(delta: float) -> void:
	if not _exit_transition_active:
		return
	_exit_transition_elapsed += maxf(delta, 0.0)
	_walk_time += maxf(delta, 0.0)
	_protagonist.texture = WALK_TEXTURES[int(_walk_time * 7.0) % WALK_TEXTURES.size()]
	var progress := clampf(_exit_transition_elapsed / EXIT_TRANSITION_SECONDS, 0.0, 1.0)
	_transition_flash.color.a = sin(progress * PI) * 0.52
	if progress >= 1.0:
		_complete_exit_transition()


func _complete_exit_transition() -> void:
	if not _exit_transition_active:
		return
	var interaction := _pending_exit_interaction.duplicate(true)
	_exit_transition_active = false
	_exit_transition_elapsed = 0.0
	_pending_exit_interaction.clear()
	_camera_focus_ratio = -1.0
	_transition_flash.color.a = 0.0
	change_location(
		str(interaction.get("target", "")),
		str(interaction.get("target_spawn", "default"))
	)


func _begin_npc_interaction(interaction: Dictionary) -> void:
	_pending_npc_interaction = interaction.duplicate(true)
	_dialogue_focus_ratio = clampf(float(interaction.get("x_ratio", _player_x_ratio)), 0.0, 1.0)
	_camera_focus_ratio = (
		float(interaction.get("talk_x_ratio", _player_x_ratio))
		+ _dialogue_focus_ratio
	) * 0.5
	_interaction_walk_target = clampf(
		float(interaction.get("talk_x_ratio", _player_x_ratio)),
		0.04,
		0.96
	)
	_interaction_walk_active = true
	_apply_presentation()


func _finish_npc_interaction() -> void:
	if not _interaction_walk_active:
		return
	var interaction := _pending_npc_interaction.duplicate(true)
	var npc_x := float(interaction.get("x_ratio", _player_x_ratio))
	_interaction_walk_active = false
	_pending_npc_interaction.clear()
	_camera_focus_ratio = -1.0
	_dialogue_focus_ratio = npc_x
	_walk_time = 0.0
	if _protagonist != null:
		_protagonist.flip_h = _player_x_ratio > npc_x
		_protagonist.texture = IDLE_TEXTURE
	_store_player_position()
	_apply_presentation()
	protagonist_moved.emit()
	interaction_requested.emit(interaction)


func _cancel_npc_interaction() -> void:
	_interaction_walk_active = false
	_pending_npc_interaction.clear()
	_dialogue_focus_ratio = -1.0


func _store_player_position() -> void:
	if _state != null:
		_state.world_position_ratio = _player_x_ratio


func _world_width() -> float:
	return maxf(size.x * float(_location_data.get("world_width_ratio", 1.32)), size.x)


func _world_to_screen_x(world_ratio: float) -> float:
	var width := _world_width()
	var camera_travel := maxf(width - size.x, 0.0)
	return width * clampf(world_ratio, 0.0, 1.0) - camera_travel * _camera_pan


func _ground_y_for_ratio(world_ratio: float) -> float:
	var centered := clampf(world_ratio, 0.0, 1.0) - 0.5
	var curve := float(_location_data.get("ground_curve", 0.0))
	var slope := float(_location_data.get("ground_slope", 0.0))
	return size.y * (
		_ground_ratio()
		+ sin(centered * PI) * curve
		+ centered * slope
	)


func _camera_pan_for_ratio(world_ratio: float) -> float:
	return clampf(inverse_lerp(0.24, 0.76, world_ratio), 0.0, 1.0)


func _update_camera(delta: float) -> void:
	var focus_ratio := _player_x_ratio
	if _camera_focus_ratio >= 0.0:
		focus_ratio = _camera_focus_ratio
	elif _dialogue_focus_ratio >= 0.0:
		focus_ratio = (_player_x_ratio + _dialogue_focus_ratio) * 0.5
	_camera_target_pan = _camera_pan_for_ratio(focus_ratio)
	if UiMotionScript.reduced_motion:
		_camera_pan = _camera_target_pan
	else:
		var response := 1.0 - exp(-CAMERA_RESPONSE * maxf(delta, 0.0))
		_camera_pan = lerpf(_camera_pan, _camera_target_pan, response)


func _update_parallax_layers() -> void:
	if _backdrop_layer != null:
		_backdrop_layer.set_view(
			_background_texture,
			lerpf(0.5, _camera_pan, 0.42),
			1.10,
			float(_location_data.get("crop_anchor", 0.5))
		)
	if _foreground_layer != null:
		_foreground_layer.set_view(
			_foreground_texture,
			lerpf(0.5, _camera_pan, 0.92),
			1.15,
			0.78
		)


func camera_pan_ratio() -> float:
	return _camera_pan


func stage_layer_names() -> PackedStringArray:
	return PackedStringArray([
		"BackdropParallax",
		"Atmosphere",
		"Protagonist",
		"ForegroundOcclusion",
		"EnvironmentLoop",
	])


func stage_time_seconds() -> float:
	return _world_time


func _ground_ratio() -> float:
	return float(_location_data.get("ground_ratio", 0.94))


func _play_location_transition() -> void:
	if _transition_flash == null:
		return
	_transition_flash.color.a = 0.78
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_transition_flash, "color:a", 0.0, 0.42)


func _interaction_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.17, 0.12, 0.075, 0.82)
	style.border_color = Color(0.91, 0.73, 0.39, 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(7)
	style.shadow_color = Color(0.07, 0.045, 0.025, 0.58)
	style.shadow_size = 6
	return style


func _chrome_button_style(border: Color, bright := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.17, 0.12, 0.075, 0.72) if not bright else Color(0.25, 0.17, 0.09, 0.86)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(8)
	style.shadow_color = Color(0.07, 0.045, 0.025, 0.46)
	style.shadow_size = 4
	return style
