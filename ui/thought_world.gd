## A painterly lateral exploration stage for the main game screen.
##
## The simulation still owns rites and events. This control only represents
## those runtime objects spatially: the protagonist can walk, pause to think,
## and reveal the rite buttons supplied by GameScreen.
class_name ThoughtWorld
extends Control

signal thinking_changed(enabled: bool)
signal protagonist_moved()
signal interaction_requested(interaction: Dictionary)
signal location_changed(location_id: String)
signal return_requested()

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


const WorldScenes = preload("res://sim/world_scene_catalog.gd")
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
const INTERACTION_ARRIVAL_EPSILON := 0.0005
const PLAYER_BASE_SIZE := Vector2(154, 308)
const NPC_BASE_SIZE := Vector2(150, 300)
const THOUGHT_WORLD_MASK_COLOR := Color(0.035, 0.045, 0.105, 0.46)

var _thinking := false
var _context_mode := false
var _player_x_ratio := 0.5
var _location_id := WorldScenes.DEFAULT_LOCATION_ID
var _location_data: Dictionary = {}
var _background_texture: Texture2D
var _state
var _walk_time := 0.0
var _world_time := 0.0
var _thought_targets: Array[Control] = []
var _motes: Array[Vector3] = []
var _npc_nodes: Array[Dictionary] = []
var _exit_nodes: Array[Dictionary] = []
var _scene_blockers: Dictionary = {}
var _interaction_walk_active := false
var _interaction_walk_target := 0.5
var _pending_npc_interaction: Dictionary = {}

var _protagonist: TextureRect
var _atmosphere: ColorRect
var _thought_world_mask: ColorRect
var _think_button: Button
var _return_button: Button
var _hint_label: Label
var _scene_title: Label
var _thought_heading: Label
var _interaction_hint: Label
var _transition_flash: ColorRect
var _audio: AudioStreamPlayer


func setup(state) -> void:
	_state = state
	if state == null:
		return
	_location_id = str(state.world_location_id)
	_player_x_ratio = clampf(float(state.world_position_ratio), 0.04, 0.96)


## GameScreen uses the lateral world as a local dossier, while direct users
## retain the established standalone Thought interaction.
func set_context_mode(enabled: bool) -> void:
	_context_mode = enabled
	if enabled:
		set_thinking(false)
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
	_atmosphere = ColorRect.new()
	_atmosphere.name = "Atmosphere"
	_atmosphere.color = Color.WHITE
	_atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atmosphere.z_index = 1
	var atmosphere_material := ShaderMaterial.new()
	atmosphere_material.shader = ATMOSPHERE_SHADER
	atmosphere_material.set_shader_parameter("world_time", _world_time)
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

	# Thought separates the protagonist's active attention from the surrounding
	# world. The mask sits above every background/NPC layer but below Al-Tu,
	# so future scene actors inherit the same visual rule without per-NPC tint.
	_thought_world_mask = ColorRect.new()
	_thought_world_mask.name = "ThoughtWorldMask"
	_thought_world_mask.color = THOUGHT_WORLD_MASK_COLOR
	_thought_world_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thought_world_mask.visible = false
	_thought_world_mask.z_index = 4
	add_child(_thought_world_mask)

	_protagonist = TextureRect.new()
	_protagonist.name = "Protagonist"
	_protagonist.texture = IDLE_TEXTURE
	_protagonist.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_protagonist.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_protagonist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_protagonist.z_index = 5
	add_child(_protagonist)

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
	_interaction_hint.z_index = 15
	add_child(_interaction_hint)

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

	_return_button = Button.new()
	_return_button.name = "ReturnToDeskButton"
	_return_button.text = "返回形势桌"
	_return_button.tooltip_text = "回到地图与档案，保留当前位置和未处理事项"
	_return_button.add_theme_font_size_override("font_size", 14)
	_return_button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.89, 0.94))
	_return_button.add_theme_color_override("font_hover_color", Color("#fff1bd"))
	_return_button.add_theme_stylebox_override("normal", _think_style(Color(0.86, 0.89, 0.91, 0.42)))
	_return_button.add_theme_stylebox_override("hover", _think_style(Color("#f0c56b"), true))
	_return_button.add_theme_stylebox_override("pressed", _think_style(Color("#fff0b3"), true))
	_return_button.pressed.connect(func(): return_requested.emit())
	_return_button.visible = false
	_return_button.z_index = 12
	add_child(_return_button)

	_audio = AudioStreamPlayer.new()
	_audio.name = "SceneAudio"
	_audio.volume_db = -9.0
	add_child(_audio)

	_transition_flash = ColorRect.new()
	_transition_flash.name = "LocationTransition"
	_transition_flash.color = Color(0.96, 0.72, 0.40, 0.0)
	_transition_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_flash.z_index = 30
	add_child(_transition_flash)


func _make_motes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13071985
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
	if _interaction_walk_active:
		direction = signf(_interaction_walk_target - _player_x_ratio)
	elif not _thinking and not blocking:
		direction = Input.get_axis("ui_left", "ui_right")
		if Input.is_key_pressed(KEY_A):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D):
			direction += 1.0
		direction = clampf(direction, -1.0, 1.0)
	if not is_zero_approx(direction):
		var usable_width := maxf(size.x - 170.0, 1.0)
		var step := WALK_SPEED * delta / usable_width
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
		_walk_time = 0.0
		_protagonist.texture = THINK_TEXTURE if _thinking else IDLE_TEXTURE
		if _interaction_walk_active:
			_finish_npc_interaction()
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_SPACE and not _has_blocking_overlay():
		set_thinking(not _thinking)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_E and not _thinking and not _has_blocking_overlay():
		interact_with_nearest()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_ESCAPE and _thinking:
		set_thinking(false)
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
	_apply_presentation()
	queue_redraw()


func is_scene_blocked() -> bool:
	return not _scene_blockers.is_empty()


func is_scene_chrome_hidden() -> bool:
	for hide_chrome in _scene_blockers.values():
		if bool(hide_chrome):
			return true
	return _has_implicit_blocking_overlay()


func set_thinking(enabled: bool) -> void:
	if enabled and _interaction_walk_active:
		return
	if _thinking == enabled:
		return
	_thinking = enabled
	_protagonist.texture = THINK_TEXTURE if enabled else IDLE_TEXTURE
	_protagonist.self_modulate = Color.WHITE
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
	_apply_presentation()
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
	_layout_protagonist()
	_store_player_position()
	_apply_presentation()
	protagonist_moved.emit()


func player_x_ratio() -> float:
	return _player_x_ratio


func location_id() -> String:
	return _location_id


func is_approaching_interaction() -> bool:
	return _interaction_walk_active


func change_location(location_id_value: String, spawn_id: String = "default") -> bool:
	if not WorldScenes.LOCATIONS.has(location_id_value):
		return false
	set_thinking(false)
	_apply_location(location_id_value, spawn_id, false, true)
	return true


func interact_with_nearest() -> bool:
	if _thinking or _has_blocking_overlay() or _interaction_walk_active:
		return false
	var interaction := _nearest_interaction()
	if interaction.is_empty():
		return false
	if str(interaction.get("type", "")) == "exit":
		return change_location(
			str(interaction.get("target", "")),
			str(interaction.get("target_spawn", "default"))
		)
	if str(interaction.get("type", "")) == "npc":
		_begin_npc_interaction(interaction)
		return true
	return false


func _layout_overlay() -> void:
	if _protagonist == null:
		return
	_atmosphere.position = Vector2.ZERO
	_atmosphere.size = size
	_thought_world_mask.position = Vector2.ZERO
	_thought_world_mask.size = size
	_scene_title.position = Vector2(20, 15)
	_scene_title.size = Vector2(220, 26)
	_hint_label.position = Vector2((size.x - 360.0) * 0.5, size.y - 28.0)
	_hint_label.size = Vector2(360, 22)
	_thought_heading.position = Vector2((size.x - 320.0) * 0.5, 15)
	_thought_heading.size = Vector2(320, 28)
	_think_button.position = Vector2(24.0, size.y - 82.0)
	_think_button.size = Vector2(138, 54)
	_return_button.position = Vector2(size.x - 152.0, 18.0)
	_return_button.size = Vector2(134.0, 38.0)
	_interaction_hint.position = Vector2((size.x - 360.0) * 0.5, size.y - 76.0)
	_interaction_hint.size = Vector2(360, 40)
	_transition_flash.position = Vector2.ZERO
	_transition_flash.size = size
	_layout_protagonist()
	_layout_location_actors()
	_apply_presentation()
	protagonist_moved.emit()
	queue_redraw()


func _layout_protagonist() -> void:
	if _protagonist == null:
		return
	var scale_factor := clampf(size.y / 420.0, 0.74, 1.22)
	var player_size := PLAYER_BASE_SIZE * scale_factor
	var half_width := player_size.x * 0.55
	var center_x := lerpf(half_width, maxf(half_width, size.x - half_width), _player_x_ratio)
	var ground_y := size.y * _ground_ratio()
	_protagonist.position = Vector2(center_x - player_size.x * 0.5, ground_y - player_size.y)
	_protagonist.size = player_size


func _layout_location_actors() -> void:
	var scale_factor := clampf(size.y / 420.0, 0.74, 1.22)
	var actor_size := NPC_BASE_SIZE * scale_factor
	var ground_y := size.y * _ground_ratio()
	for entry in _npc_nodes:
		var node: TextureRect = entry.get("node")
		var data: Dictionary = entry.get("data", {})
		if node == null:
			continue
		var center_x := size.x * float(data.get("x_ratio", 0.5))
		node.position = Vector2(center_x - actor_size.x * 0.5, ground_y - actor_size.y)
		node.size = actor_size
	for entry in _exit_nodes:
		var node: Label = entry.get("node")
		var data: Dictionary = entry.get("data", {})
		if node == null:
			continue
		node.position = Vector2(
			size.x * float(data.get("x_ratio", 0.05)) - 70.0,
			ground_y - 112.0
		)
		node.size = Vector2(140, 34)


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

	var ground_y := size.y * _ground_ratio()
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
	if _background_texture == null:
		return
	var texture_size := _background_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or target.size.y <= 0.0:
		return
	var target_aspect := target.size.x / target.size.y
	var texture_aspect := texture_size.x / texture_size.y
	var source := Rect2(Vector2.ZERO, texture_size)
	if target_aspect > texture_aspect:
		source.size.y = texture_size.x / target_aspect
		source.position.y = (
			(texture_size.y - source.size.y)
			* float(_location_data.get("crop_anchor", 0.5))
		)
	else:
		source.size.x = texture_size.y * target_aspect
		source.position.x = (texture_size.x - source.size.x) * 0.5
	draw_texture_rect_region(_background_texture, target, source)


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
	_scene_title.text = str(_location_data.get("title", _location_id))
	if not use_saved_position:
		_player_x_ratio = WorldScenes.spawn_ratio(_location_id, spawn_id)
	_clear_location_actors()
	_build_location_actors()
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
		sprite.z_index = 3
		add_child(sprite)
		_npc_nodes.append({"data": npc_data, "node": sprite})
	for raw_exit in _location_data.get("exits", []):
		if not (raw_exit is Dictionary):
			continue
		var exit_data: Dictionary = raw_exit.duplicate(true)
		var marker := Label.new()
		marker.name = "WorldExit_%s" % str(exit_data.get("id", "unknown"))
		marker.text = "%s  %s" % [
			str(exit_data.get("direction", "◇")),
			str(exit_data.get("label", "出口")),
		]
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.add_theme_font_size_override("font_size", 13)
		marker.add_theme_color_override("font_color", Color(0.94, 0.95, 0.98, 0.68))
		marker.add_theme_color_override("font_shadow_color", Color(0.01, 0.02, 0.05, 0.92))
		marker.add_theme_constant_override("shadow_offset_x", 1)
		marker.add_theme_constant_override("shadow_offset_y", 2)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.z_index = 7
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
		not _thinking
		and not _interaction_walk_active
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
	var hide_chrome := is_scene_chrome_hidden() or _interaction_walk_active
	if _think_button != null:
		_think_button.visible = not hide_chrome
	if _return_button != null:
		_return_button.visible = not hide_chrome and _context_mode and not _thinking
	if _hint_label != null:
		_hint_label.visible = not hide_chrome
	if _thought_world_mask != null:
		_thought_world_mask.visible = _thinking
	if _thought_heading != null:
		_thought_heading.visible = _thinking and not hide_chrome
	for entry in _exit_nodes:
		var node: Control = entry.get("node")
		if node != null:
			node.visible = not hide_chrome
	_update_interaction_hint()


func _begin_npc_interaction(interaction: Dictionary) -> void:
	_pending_npc_interaction = interaction.duplicate(true)
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


func _store_player_position() -> void:
	if _state != null:
		_state.world_position_ratio = _player_x_ratio


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
	style.bg_color = Color(0.02, 0.035, 0.08, 0.68)
	style.border_color = Color(1.0, 0.78, 0.40, 0.48)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(7)
	style.shadow_color = Color(0.0, 0.0, 0.02, 0.52)
	style.shadow_size = 6
	return style


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
