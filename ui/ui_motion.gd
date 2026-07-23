## Shared interaction motion for ordinary Controls.
##
## The component uses Godot 4.7's visual-only offset transform so Containers,
## anchors, focus navigation, and hit testing all keep their stable rectangles.
## Every property has one owner and one interruptible target: hover, press,
## focus, and reveal never start competing Tweens.
class_name UiMotion
extends Node

enum Profile {
	BUTTON,
	PRIMARY,
	SITE,
	SLOT,
	PANEL,
}

const DRIVER_NAME := "UiMotion"
const MOVEABLE_XY_DECAY_RATE := 50.0
const MOVEABLE_SCALE_DECAY_RATE := 60.0
const MOVEABLE_ROTATION_DECAY_RATE := 190.0
const MOVEABLE_XY_RESPONSE := 35.0
const JUICE_DURATION := 0.28
const JUICE_SCALE_FREQUENCY := 50.8
const JUICE_ROTATION_FREQUENCY := 40.8
const SETTLED_POSITION_SQUARED := 0.0004
const SETTLED_SCALE_SQUARED := 0.000001
const SETTLED_ROTATION := 0.0002
const SETTLED_ALPHA := 0.001

static var reduced_motion := false

var _target: Control
var _profile := Profile.BUTTON
var _hovered := false
var _focused := false
var _pressed := false
var _revealing := false
var _position_velocity := Vector2.ZERO
var _scale_velocity := Vector2.ZERO
var _rotation_velocity := 0.0
var _alpha_velocity := 0.0
var _visual_alpha := 1.0
var _base_self_modulate := Color.WHITE
var _juice_elapsed := JUICE_DURATION
var _juice_direction := 1.0
var _juice_scale := 0.0
var _juice_rotation := 0.0


static func bind(
	control: Control,
	profile: Profile = Profile.BUTTON,
	reveal := false
) -> UiMotion:
	if control == null:
		return null
	var existing := control.get_node_or_null(DRIVER_NAME) as UiMotion
	if existing != null:
		return existing
	var driver := UiMotion.new()
	driver.name = DRIVER_NAME
	driver._configure(control, profile, reveal or profile == Profile.PANEL)
	control.add_child(driver)
	return driver


func _configure(control: Control, profile: Profile, reveal: bool) -> void:
	_target = control
	_profile = profile
	_base_self_modulate = control.self_modulate
	control.offset_transform_enabled = true
	control.offset_transform_visual_only = true
	control.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	control.mouse_entered.connect(_on_mouse_entered)
	control.mouse_exited.connect(_on_mouse_exited)
	control.focus_entered.connect(_on_focus_entered)
	control.focus_exited.connect(_on_focus_exited)
	if control is BaseButton:
		var button := control as BaseButton
		button.button_down.connect(_on_button_down)
		button.button_up.connect(_on_button_up)
	_revealing = reveal
	if _revealing and not reduced_motion:
		control.offset_transform_position = Vector2(0.0, 12.0)
		control.offset_transform_scale = Vector2.ONE * 0.965
		_visual_alpha = 0.0
		_apply_alpha()
	set_process(_revealing)
	if reduced_motion:
		_snap_to_target()


func _on_mouse_entered() -> void:
	if _profile == Profile.PANEL or _is_disabled():
		return
	var was_active := _hovered or _focused
	_hovered = true
	if not was_active:
		_start_entry_juice()
	set_process(true)


func _on_mouse_exited() -> void:
	_hovered = false
	_pressed = false
	set_process(true)


func _on_focus_entered() -> void:
	if _profile == Profile.PANEL or _is_disabled():
		return
	var was_active := _hovered or _focused
	_focused = true
	if not was_active:
		_start_entry_juice()
	set_process(true)


func _on_focus_exited() -> void:
	_focused = false
	_pressed = false
	set_process(true)


func _on_button_down() -> void:
	if _is_disabled():
		return
	_pressed = true
	set_process(true)


func _on_button_up() -> void:
	_pressed = false
	set_process(true)


func _start_entry_juice() -> void:
	if reduced_motion:
		_snap_to_target()
		return
	_juice_elapsed = 0.0
	_juice_scale = 0.0
	_juice_rotation = 0.0
	_juice_direction = _entry_direction()
	_target.offset_transform_scale = Vector2.ONE * (1.0 - _juice_amount() * 0.55)


func _entry_direction() -> float:
	if _target.is_inside_tree() and _target.size.x > 0.0:
		return -1.0 if _target.get_local_mouse_position().x < _target.size.x * 0.5 else 1.0
	return -1.0 if _target.get_instance_id() % 2 == 0 else 1.0


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		set_process(false)
		return
	if reduced_motion:
		_snap_to_target()
		return
	_step_juice(delta)
	var targets := _motion_targets()
	_step_moveable_pose(targets.position, targets.rotation, targets.scale, delta)
	_step_alpha(1.0, delta)
	if _revealing and absf(1.0 - _visual_alpha) < SETTLED_ALPHA:
		_revealing = false
	if _juice_elapsed >= JUICE_DURATION and _pose_is_settled(targets):
		_snap_to_values(targets.position, targets.rotation, targets.scale, 1.0)
		set_process(false)


func _motion_targets() -> Dictionary:
	var active := (_hovered or _focused) and not _is_disabled()
	var position := Vector2.ZERO
	var scale := Vector2.ONE
	var rotation := 0.0
	if active:
		scale = Vector2.ONE * _hover_scale()
		if _profile == Profile.SITE:
			rotation = _juice_direction * 0.004
	if _pressed and not _is_disabled():
		scale = Vector2.ONE * _pressed_scale()
		rotation *= 0.25
	scale += Vector2.ONE * _juice_scale
	rotation += _juice_rotation
	return {
		"position": position,
		"scale": scale,
		"rotation": rotation,
	}


func _hover_scale() -> float:
	match _profile:
		Profile.PRIMARY:
			return 1.040
		Profile.SITE:
			return 1.035
		Profile.SLOT:
			return 1.025
		_:
			return 1.030


func _pressed_scale() -> float:
	return 0.965 if _profile == Profile.PRIMARY else 0.972


func _juice_amount() -> float:
	match _profile:
		Profile.PRIMARY:
			return 0.014
		Profile.SITE:
			return 0.012
		Profile.SLOT:
			return 0.008
		_:
			return 0.010


func _step_juice(delta: float) -> void:
	if _juice_elapsed >= JUICE_DURATION:
		_juice_scale = 0.0
		_juice_rotation = 0.0
		return
	_juice_elapsed = minf(_juice_elapsed + maxf(delta, 0.0), JUICE_DURATION)
	var remaining := maxf(0.0, 1.0 - _juice_elapsed / JUICE_DURATION)
	var amount := _juice_amount()
	_juice_scale = (
		amount
		* sin(JUICE_SCALE_FREQUENCY * _juice_elapsed)
		* pow(remaining, 3.0)
	)
	_juice_rotation = (
		_juice_direction
		* amount
		* 0.42
		* sin(JUICE_ROTATION_FREQUENCY * _juice_elapsed)
		* pow(remaining, 2.0)
	)


## Directly mirrors the recurrence used by CardWidget. Velocities are visual
## deltas per frame, so they are added without multiplying by delta twice.
func _step_moveable_pose(
	target_position: Vector2,
	target_rotation: float,
	target_scale: Vector2,
	delta: float
) -> void:
	if delta <= 0.0:
		return
	var move_delta := minf(delta, 1.0 / 20.0)
	var xy_decay := exp(-MOVEABLE_XY_DECAY_RATE * delta)
	_position_velocity = (
		xy_decay * _position_velocity
		+ (1.0 - xy_decay)
		* (target_position - _target.offset_transform_position)
		* MOVEABLE_XY_RESPONSE
		* move_delta
	)
	_target.offset_transform_position += _position_velocity

	var scale_decay := exp(-MOVEABLE_SCALE_DECAY_RATE * delta)
	_scale_velocity = (
		scale_decay * _scale_velocity
		+ (1.0 - scale_decay) * (target_scale - _target.offset_transform_scale)
	)
	_target.offset_transform_scale += _scale_velocity

	var rotation_error := wrapf(
		target_rotation - _target.offset_transform_rotation,
		-PI,
		PI
	)
	var rotation_decay := exp(-MOVEABLE_ROTATION_DECAY_RATE * delta)
	_rotation_velocity = (
		rotation_decay * _rotation_velocity
		+ (1.0 - rotation_decay) * rotation_error
	)
	_target.offset_transform_rotation += _rotation_velocity


func _step_alpha(target_alpha: float, delta: float) -> void:
	var decay := exp(-50.0 * maxf(delta, 0.0))
	_alpha_velocity = (
		decay * _alpha_velocity
		+ (1.0 - decay) * (target_alpha - _visual_alpha)
	)
	_visual_alpha += _alpha_velocity
	_apply_alpha()


func _apply_alpha() -> void:
	var color := _base_self_modulate
	color.a *= clampf(_visual_alpha, 0.0, 1.0)
	_target.self_modulate = color


func _pose_is_settled(targets: Dictionary) -> bool:
	return (
		_target.offset_transform_position.distance_squared_to(targets.position)
		< SETTLED_POSITION_SQUARED
		and _target.offset_transform_scale.distance_squared_to(targets.scale)
		< SETTLED_SCALE_SQUARED
		and absf(
			wrapf(
				float(targets.rotation) - _target.offset_transform_rotation,
				-PI,
				PI
			)
		) < SETTLED_ROTATION
		and absf(1.0 - _visual_alpha) < SETTLED_ALPHA
	)


func _snap_to_target() -> void:
	if _target == null:
		return
	var targets := _motion_targets()
	_snap_to_values(targets.position, targets.rotation, targets.scale, 1.0)
	_revealing = false
	_juice_elapsed = JUICE_DURATION
	set_process(false)


func _snap_to_values(
	position: Vector2,
	rotation: float,
	scale: Vector2,
	alpha: float
) -> void:
	_target.offset_transform_position = position
	_target.offset_transform_rotation = rotation
	_target.offset_transform_scale = scale
	_visual_alpha = alpha
	_position_velocity = Vector2.ZERO
	_rotation_velocity = 0.0
	_scale_velocity = Vector2.ZERO
	_alpha_velocity = 0.0
	_apply_alpha()


func _is_disabled() -> bool:
	return _target is BaseButton and (_target as BaseButton).disabled


## Deterministic hooks used by headless UI tests.
func set_hovered_for_test(value: bool) -> void:
	if value:
		_on_mouse_entered()
	else:
		_on_mouse_exited()


func set_pressed_for_test(value: bool) -> void:
	if value:
		_on_button_down()
	else:
		_on_button_up()
