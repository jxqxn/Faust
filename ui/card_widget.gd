## A compact visual card for hand, table slots, and drag previews.
##
## Its interaction layer deliberately has a little of Balatro's "held object"
## quality: cards rise from their bottom edge, lean toward the pointer, squash
## on press, and keep their shadow/layer while being manipulated.  This lives
## here rather than in the hand rail so rite slots and Sultan cards get the
## same language without coupling UI polish to game-state transitions.
class_name CardWidget
extends PanelContainer

signal clicked(card_id: int, card: Dictionary)
signal drag_visibility_changed(card_uid: int, hidden: bool)

enum HoverJuiceMode { NONE, ENTER }

const CARD_SIZE := Vector2(104, 160)
const CARD_HOVER_SHADER := preload("res://ui/card_hover_perspective.gdshader")
const CARD_SHADOW_SHADER := preload("res://ui/card_shadow.gdshader")
const VISUAL_MARGIN := 8.0
const VISUAL_RENDER_SCALE := 2.0
const HOVER_SCALE := 1.05
const SELECTED_LIFT := CARD_SIZE.y * 0.2
const DRAG_SCALE := 1.10
const DRAG_LIFT := 17.0
const PERSPECTIVE_DEAD_ZONE := 0.04
const PERSPECTIVE_EXPONENT := 1.15
const PERSPECTIVE_STIFFNESS := 360.0
const PERSPECTIVE_DAMPING := 25.0
const PERSPECTIVE_RETURN_STIFFNESS := 250.0
const PERSPECTIVE_RETURN_DAMPING := 24.0
const HOVER_Z_INDEX := 20
# Balatro's ordinary hand target uses 0.02 radians of roll at 2 rad/s and
# 0.03 world units of vertical motion at 0.666 rad/s. Its card is
# 2.4 * 47 / 41 world units tall, so convert the latter proportionally to our
# 160 px card instead of tuning it as an unrelated pixel bob. The original
# hand has no autonomous horizontal oscillation.
const BALATRO_CARD_HEIGHT_UNITS := 2.4 * 47.0 / 41.0
const BALATRO_CARD_WIDTH_UNITS := 2.4 * 35.0 / 41.0
const IDLE_SWAY_RADIANS := 0.02
const IDLE_SWAY_FREQUENCY := 2.0
const IDLE_BOB_HEIGHT := CARD_SIZE.y * 0.03 / BALATRO_CARD_HEIGHT_UNITS
const IDLE_BOB_FREQUENCY := 0.666
const DEAL_DURATION := 0.30
const DEAL_STAGGER := 0.055
const REFLOW_DURATION := 0.22
const MOVEABLE_XY_DECAY_RATE := 50.0
const MOVEABLE_SCALE_DECAY_RATE := 60.0
const MOVEABLE_ROTATION_DECAY_RATE := 190.0
const MOVEABLE_XY_RESPONSE := 35.0
const MOVEABLE_MAX_VELOCITY := 70.0
const DRAG_POINTER_VELOCITY_FOLLOW := 17.0
const DRAG_MAX_ROTATION_DEGREES := 13.0
const DRAG_VELOCITY_ROTATION_RADIANS := 0.00012
const DRAG_LIFT_BLEND_DURATION := 0.08
const SHADOW_IDLE_HEIGHT := 0.10
const SHADOW_DRAG_HEIGHT := 0.35
# These ratios specify the part of the shadow that must remain visible outside
# the scaled card silhouette, not a raw offset. Keeping the contract relative
# to CARD_SIZE prevents resolution changes or shadow-scale tuning from hiding
# the idle contact shadow again.
const SHADOW_IDLE_BOTTOM_EXPOSURE_RATIO := 0.046
const SHADOW_DRAG_BOTTOM_EXPOSURE_RATIO := 0.078
const SHADOW_IDLE_SIDE_EXPOSURE_RATIO := 0.035
const SHADOW_DRAG_SIDE_EXPOSURE_RATIO := 0.065
const HOVER_JUICE_DURATION := 0.40
const HOVER_JUICE_SCALE_AMOUNT := 0.020
const HOVER_JUICE_ROTATION_AMOUNT := 0.012
const HOVER_JUICE_COMPRESSION := 0.6 * HOVER_JUICE_SCALE_AMOUNT
const HOVER_JUICE_SCALE_FREQUENCY := 50.8
const HOVER_JUICE_ROTATION_FREQUENCY := 40.8

var _card: Dictionary = {}
var card_id: int = 0
var card_uid: int = 0
var drag_source := "hand"
var drag_slot := ""
var drag_rite_uid := 0
var _press_position := Vector2.ZERO
var _drag_grab_offset := CARD_SIZE * 0.5
var _drag_selected_position := Vector2.ZERO
var _drag_selected_rotation := 0.0
var _drag_selected_scale := Vector2.ONE
var _drag_selected_tilt := Vector2.ZERO
var _hidden_for_drag := false
var _hovered := false
var _pressed := false
var _selected := false
var _drag_preview := false
var _dealing := false
var _base_z_index := 0
var _hand_idle_enabled := false
var _hand_idle_phase := 0.0
var _pose_position_velocity := Vector2.ZERO
var _pose_rotation_velocity := 0.0
var _pose_scale_velocity := Vector2.ZERO
var _hand_motion_delay := 0.0
var _hand_motion_elapsed := 0.0
var _hand_motion_duration := 0.0
var _hand_motion_fades_in := false
var _drag_rest_position := Vector2.ZERO
var _drag_pickup_position := Vector2.ZERO
var _drag_lift_elapsed := 0.0
var _drag_rest_rotation := 0.0
var _drag_pointer_velocity := Vector2.ZERO
var _drag_last_pointer := Vector2.ZERO
var _drag_pointer_initialized := false
var _drag_payload_ref: Dictionary = {}
var _content_root: Control
var _render_root: Control
var _visual_surface: TextureRect
var _visual_viewport: SubViewport
var _visual_face: PanelContainer
var _perspective_material: ShaderMaterial
var _perspective_tilt := Vector2.ZERO
var _perspective_velocity := Vector2.ZERO
var _shadow_surface: TextureRect
var _shadow_material: ShaderMaterial
var _shadow_height := SHADOW_IDLE_HEIGHT
var _hover_juice_mode := HoverJuiceMode.NONE
var _hover_juice_elapsed := 0.0
var _hover_juice_scale := 0.0
var _hover_juice_rotation := 0.0
var _hover_juice_direction := 1.0


func set_card(card: Dictionary) -> void:
	_card = card
	card_id = int(card.get("id", card_id))
	card_uid = int(card.get("instance_uid", card_uid))
	_rebuild()


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE if _drag_preview else Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_base_z_index = z_index
	# Godot 4.7's visual-only offset transform is purpose-built for animated
	# Controls inside Containers: layout and hit testing keep the stable card
	# rectangle while the rendered card can lift and tilt independently.
	offset_transform_enabled = true
	offset_transform_visual_only = true
	offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	mouse_entered.connect(func(): _set_hovered(true))
	mouse_exited.connect(func(): _set_hovered(false))
	set_process(_drag_preview or _hand_idle_enabled or _selected)
	_set_card_style()
	_update_shadow_projection(false, 1.0)


## Applies the stable pose owned by the hand layout.  The ordinary Control
## transform owns hit testing; offset_transform remains free for visual feel.
func set_hand_pose(target_position: Vector2, target_rotation: float, order: int) -> void:
	position = target_position
	size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	rotation = target_rotation
	_base_z_index = order
	if not _drag_preview:
		z_index = order + HOVER_Z_INDEX if (_hovered or _selected) else order


## Balatro offsets each idle sine with card.T.x, producing one spatial wave
## across the hand rather than unrelated random motion. Convert our pixel x to
## the same card-relative world units; the pose spring/reflow tween absorbs a
## phase target change when a card moves to another slot.
func set_hand_idle(enabled: bool, _order: int = 0) -> void:
	_hand_idle_enabled = enabled
	_hand_idle_phase = fposmod(position.x * BALATRO_CARD_WIDTH_UNITS / CARD_SIZE.x, TAU)
	set_process(_drag_preview or _hovered or _hand_idle_enabled or _selected)


## Selection changes only the hand target height, matching CardArea's
## highlighted offset. Hover zoom remains an independent state.
func set_selected(selected: bool, _with_impulse: bool = true) -> void:
	if _drag_preview or _selected == selected:
		return
	_selected = selected
	z_index = _base_z_index + HOVER_Z_INDEX if (_selected or _hovered) else _base_z_index
	set_process(true)
	_set_card_style()


func is_selected() -> bool:
	return _selected


## Deals a card from the right-side deck area into its already-computed hand
## slot.  Keeping the stable position untouched prevents insertion hit tests
## and resize layout from chasing the animation.
func play_deal_in(source_offset: Vector2, order: int) -> void:
	if _drag_preview or _hidden_for_drag:
		return
	_dealing = true
	_hovered = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	offset_transform_position = source_offset
	offset_transform_rotation = deg_to_rad(7.0)
	offset_transform_scale = Vector2.ONE * 0.88
	_pose_position_velocity = Vector2.ZERO
	_pose_rotation_velocity = 0.0
	_pose_scale_velocity = Vector2.ZERO
	modulate = Color(1, 1, 1, 0)
	_hand_motion_delay = minf(float(order), 10.0) * DEAL_STAGGER
	_hand_motion_elapsed = 0.0
	_hand_motion_duration = DEAL_DURATION
	_hand_motion_fades_in = true
	set_process(true)


## Reflow changes the stable layout immediately and lets the same Moveable
## integrator chase it from the former rendered pose. No unrelated Back tween
## is introduced at this boundary.
func play_hand_reflow(
	source_offset: Vector2,
	source_rotation: float = INF,
	source_scale: Vector2 = Vector2.ZERO,
	source_tilt: Vector2 = Vector2(INF, INF)
) -> void:
	var has_source_tilt := source_tilt.x != INF and source_tilt.y != INF
	var has_explicit_pose := source_rotation != INF or source_scale != Vector2.ZERO or has_source_tilt
	if _drag_preview or _hidden_for_drag:
		return
	if source_offset.length_squared() < 0.25 and not has_explicit_pose:
		return
	_dealing = true
	_hovered = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	offset_transform_position = source_offset
	offset_transform_rotation = (
		deg_to_rad(clampf(source_offset.x * 0.025, -2.5, 2.5))
		if source_rotation == INF
		else source_rotation
	)
	offset_transform_scale = Vector2.ONE * 0.97 if source_scale == Vector2.ZERO else source_scale
	_pose_position_velocity = Vector2.ZERO
	_pose_rotation_velocity = 0.0
	_pose_scale_velocity = Vector2.ZERO
	if has_source_tilt:
		_set_perspective_tilt(source_tilt)
		_perspective_velocity = Vector2.ZERO
	modulate = Color.WHITE
	_hand_motion_delay = 0.0
	_hand_motion_elapsed = 0.0
	_hand_motion_duration = REFLOW_DURATION
	_hand_motion_fades_in = false
	set_process(true)


func _finish_hand_motion() -> void:
	_dealing = false
	_hand_motion_delay = 0.0
	_hand_motion_elapsed = 0.0
	_hand_motion_duration = 0.0
	_hand_motion_fades_in = false
	modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(_hand_idle_enabled or _selected or not _pose_is_settled(
		_idle_position_at(_idle_time_seconds()) if _hand_idle_enabled else Vector2.ZERO,
		_idle_rotation_at(_idle_time_seconds()) if _hand_idle_enabled else 0.0,
		Vector2.ONE
	))


func is_hand_motion_active() -> bool:
	return _dealing


func _style_for_card() -> StyleBoxFlat:
	var accent := _rarity_color(int(_card.get("rare", 0)), str(_card.get("type", "")))
	var style := FaustTheme.card_style(accent)
	# The face texture must contain no baked shadow. The same pre-perspective
	# texture is sampled by a separate shadow pass below the card surface.
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	if _hovered or _selected or _drag_preview:
		style.border_color = accent.lightened(0.18)
		style.set_border_width_all(2)
	return style


func _get_drag_data(at_position: Vector2) -> Variant:
	if card_id <= 0:
		return null
	_drag_grab_offset = at_position
	# The cursor-held card starts from the exact rendered hover pose.  There is
	# no separate drag tilt, so picking a card up cannot introduce an angle jump.
	_drag_selected_position = offset_transform_position
	_drag_selected_rotation = _composed_visual_rotation()
	_drag_selected_scale = _composed_visual_scale()
	_drag_selected_tilt = _perspective_tilt
	var payload := drag_payload()
	_drag_payload_ref = payload
	var preview := CardWidget.make(_card.duplicate(true), drag_source, drag_slot, drag_rite_uid)
	preview.card_id = card_id
	preview.make_drag_preview(
		_drag_selected_position,
		_drag_selected_rotation,
		_drag_selected_scale,
		payload
	)
	var preview_root := Control.new()
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_root.custom_minimum_size = CARD_SIZE
	# Preserve the pointer-to-card offset from the moment dragging begins.
	preview.position = -at_position
	preview_root.add_child(preview)
	set_drag_preview(preview_root)
	_hide_source_for_drag()
	return payload


## Kept separate from the engine drag callback so tests can verify the game
## contract without illegally creating a drag preview outside a GUI drag.
func drag_payload() -> Dictionary:
	return {
		"type": "card",
		"card_id": card_id,
		"card_uid": card_uid,
		"card": _card.duplicate(true),
		"source": drag_source,
		"source_slot": drag_slot,
		"source_rite_uid": drag_rite_uid,
		"grab_offset": _drag_grab_offset,
		"drag_visual_position": _drag_selected_position,
		"drag_visual_rotation": _drag_selected_rotation,
		"drag_visual_scale": _drag_selected_scale,
		"drag_visual_tilt": _drag_selected_tilt,
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _hidden_for_drag:
		var drag_succeeded := get_viewport() != null and get_viewport().gui_is_drag_successful()
		if drag_succeeded:
			_hidden_for_drag = false
			_drag_payload_ref = {}
			drag_visibility_changed.emit(card_uid, false)
		else:
			_restore_source_after_failed_drag()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var target := _drop_delegate()
	if target == null or not target.has_method("_can_drop_data"):
		return false
	return target._can_drop_data(target.get_local_mouse_position() if target is Control else at_position, data)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var target := _drop_delegate()
	if target != null and target.has_method("_drop_data"):
		target._drop_data(target.get_local_mouse_position() if target is Control else at_position, data)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_position = event.position
			_pressed = true
			_wake_pose_motion()
		elif event.position.distance_to(_press_position) <= 8.0:
			_pressed = false
			_wake_pose_motion()
			clicked.emit(card_id, _card.duplicate(true))
		else:
			_pressed = false
			_wake_pose_motion()


func _drop_delegate() -> Control:
	var p := get_parent()
	while p != null:
		if p != self and p.has_method("_can_drop_data") and p.has_method("_drop_data"):
			return p as Control
		if p.has_method("can_drop_card_to_hand") and p.has_method("drop_card_to_hand"):
			return p as Control
		p = p.get_parent()
	return null


func _hide_source_for_drag() -> void:
	_hidden_for_drag = true
	_pressed = false
	_hovered = false
	_pose_position_velocity = Vector2.ZERO
	_pose_rotation_velocity = 0.0
	_pose_scale_velocity = Vector2.ZERO
	_reset_hover_juice()
	offset_transform_rotation = 0.0
	offset_transform_position = Vector2.ZERO
	z_index = _base_z_index
	set_process(false)
	visible = false
	drag_visibility_changed.emit(card_uid, true)


func _restore_source_after_failed_drag() -> void:
	_hidden_for_drag = false
	visible = true
	_set_card_style()
	# Reinsert the stable slot first, then animate the same selected pose from
	# the release point back into the live idle curve.
	drag_visibility_changed.emit(card_uid, false)
	var source_offset: Vector2 = _drag_payload_ref.get("drag_visual_position", _drag_selected_position)
	var source_rotation := float(_drag_payload_ref.get("drag_visual_rotation", _drag_selected_rotation))
	var source_scale: Vector2 = _drag_payload_ref.get("drag_visual_scale", _drag_selected_scale)
	var source_tilt: Vector2 = _drag_payload_ref.get("drag_visual_tilt", _drag_selected_tilt)
	var parent_control := get_parent() as Control
	if parent_control != null and get_viewport() != null:
		var mouse_in_parent := (
			parent_control.get_global_transform().affine_inverse()
			* get_viewport().get_mouse_position()
		)
		source_offset += mouse_in_parent - _drag_grab_offset - position
	play_hand_reflow(source_offset, source_rotation, source_scale, source_tilt)
	_drag_payload_ref = {}


## Marks this standalone instance as the cursor-held drag image while retaining
## the exact visual pose from the source card.
func make_drag_preview(
	initial_position: Vector2 = Vector2.ZERO,
	initial_rotation: float = 0.0,
	initial_scale: Vector2 = Vector2.ONE,
	payload_ref: Dictionary = {}
) -> void:
	_drag_preview = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color.WHITE
	offset_transform_enabled = true
	offset_transform_visual_only = true
	offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	offset_transform_scale = initial_scale
	offset_transform_position = initial_position
	offset_transform_rotation = initial_rotation
	_drag_pickup_position = initial_position
	_drag_lift_elapsed = 0.0
	_drag_rest_position = Vector2(initial_position.x, minf(initial_position.y, -DRAG_LIFT))
	_drag_rest_rotation = initial_rotation
	_pose_position_velocity = Vector2.ZERO
	_pose_rotation_velocity = 0.0
	_pose_scale_velocity = Vector2.ZERO
	_drag_pointer_velocity = Vector2.ZERO
	_drag_pointer_initialized = false
	_drag_payload_ref = payload_ref
	_set_perspective_tilt(payload_ref.get("drag_visual_tilt", Vector2.ZERO))
	_perspective_velocity = Vector2.ZERO
	z_index = HOVER_Z_INDEX
	_set_card_style()
	set_process(true)


func _set_hovered(is_hovered: bool) -> void:
	if _drag_preview or _dealing or _hidden_for_drag or _hovered == is_hovered:
		return
	_hovered = is_hovered
	if is_hovered:
		_start_hover_juice()
	z_index = _base_z_index + HOVER_Z_INDEX if (_hovered or _selected) else _base_z_index
	set_process(true)
	_set_card_style()


func _process(delta: float) -> void:
	_step_hover_juice(delta)
	if _drag_preview:
		var pointer := get_viewport().get_mouse_position() if get_viewport() != null else _drag_last_pointer
		_step_drag_motion(pointer, delta)
		return
	if _dealing:
		_step_hand_motion(delta)
		return
	_step_interaction_motion(delta)


## CardArea continues to update hand roll while a card is hovered. Pointer
## pitch/yaw remains a shader-only layer and therefore never replaces it.
func _step_interaction_motion(delta: float) -> void:
	if delta <= 0.0 or _hidden_for_drag:
		return
	var idle_time := _idle_time_seconds()
	var target_position := _idle_position_at(idle_time) if _hand_idle_enabled else Vector2.ZERO
	var target_rotation := _idle_rotation_at(idle_time) if _hand_idle_enabled else 0.0
	var target_scale := Vector2.ONE
	var pointer := Vector2.ZERO
	if _selected:
		target_position.y -= SELECTED_LIFT
	if _hovered:
		var half_size := size * 0.5
		if half_size.x > 0.0 and half_size.y > 0.0:
			var pointer_offset := (get_local_mouse_position() - half_size) / half_size
			pointer = Vector2(
				clampf(pointer_offset.x, -1.0, 1.0),
				clampf(pointer_offset.y, -1.0, 1.0)
			)
		target_scale = Vector2.ONE * HOVER_SCALE
	target_scale += Vector2.ONE * _hover_juice_scale
	target_rotation += _hover_juice_rotation * 2.0
	_step_moveable_pose(target_position, target_rotation, target_scale, delta)
	_update_depth_layers(pointer, false, delta)

	if (
		not (_hand_idle_enabled or _hovered or _selected or _pressed)
		and _hover_juice_mode == HoverJuiceMode.NONE
		and _pose_is_settled(target_position, target_rotation, target_scale)
	):
		offset_transform_position = target_position
		offset_transform_rotation = target_rotation
		offset_transform_scale = target_scale
		set_process(false)

## Card:hover() starts one 0.4 second juice and Moveable immediately compresses
## VT.scale by 0.6 * amount. Card:stop_hover() starts no second animation; the
## existing entry juice simply finishes while hover zoom returns through the
## same scale integrator.
func _start_hover_juice() -> void:
	_hover_juice_elapsed = 0.0
	_hover_juice_mode = HoverJuiceMode.ENTER
	_hover_juice_scale = 0.0
	_hover_juice_rotation = 0.0
	_hover_juice_direction = -1.0 if randf() < 0.5 else 1.0
	offset_transform_scale = Vector2.ONE * (1.0 - HOVER_JUICE_COMPRESSION)
	set_process(true)


func _step_hover_juice(delta: float) -> void:
	if _hover_juice_mode == HoverJuiceMode.NONE:
		return
	_hover_juice_elapsed = minf(_hover_juice_elapsed + maxf(delta, 0.0), HOVER_JUICE_DURATION)
	var sample := _sample_hover_juice(_hover_juice_elapsed, _hover_juice_direction)
	_hover_juice_scale = sample.x
	_hover_juice_rotation = sample.y
	if _hover_juice_elapsed >= HOVER_JUICE_DURATION:
		_reset_hover_juice()


static func _sample_hover_juice(
	elapsed: float,
	direction: float
) -> Vector2:
	var time := clampf(elapsed, 0.0, HOVER_JUICE_DURATION)
	var remaining := maxf(0.0, 1.0 - time / HOVER_JUICE_DURATION)
	return Vector2(
		HOVER_JUICE_SCALE_AMOUNT
		* sin(HOVER_JUICE_SCALE_FREQUENCY * time)
		* pow(remaining, 3.0),
		direction
		* HOVER_JUICE_ROTATION_AMOUNT
		* sin(HOVER_JUICE_ROTATION_FREQUENCY * time)
		* pow(remaining, 2.0)
	)


func _reset_hover_juice() -> void:
	_hover_juice_mode = HoverJuiceMode.NONE
	_hover_juice_elapsed = 0.0
	_hover_juice_scale = 0.0
	_hover_juice_rotation = 0.0


func _composed_visual_scale() -> Vector2:
	return offset_transform_scale


func _composed_visual_rotation() -> float:
	return offset_transform_rotation


## Direct port of Balatro Moveable's move_xy, move_scale, and move_r recurrence.
## Velocities are per-frame visual deltas, so they are added directly rather
## than multiplied by delta a second time.
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
	_pose_position_velocity = (
		xy_decay * _pose_position_velocity
		+ (1.0 - xy_decay)
		* (target_position - offset_transform_position)
		* MOVEABLE_XY_RESPONSE
		* move_delta
	)
	var pixels_per_world_unit := CARD_SIZE.x / BALATRO_CARD_WIDTH_UNITS
	var max_position_velocity := MOVEABLE_MAX_VELOCITY * move_delta * pixels_per_world_unit
	if _pose_position_velocity.length() > max_position_velocity:
		_pose_position_velocity = _pose_position_velocity.normalized() * max_position_velocity
	offset_transform_position += _pose_position_velocity

	var scale_decay := exp(-MOVEABLE_SCALE_DECAY_RATE * delta)
	_pose_scale_velocity = (
		scale_decay * _pose_scale_velocity
		+ (1.0 - scale_decay) * (target_scale - offset_transform_scale)
	)
	offset_transform_scale += _pose_scale_velocity

	var rotation_error := wrapf(target_rotation - offset_transform_rotation, -PI, PI)
	var rotation_decay := exp(-MOVEABLE_ROTATION_DECAY_RATE * delta)
	_pose_rotation_velocity = (
		rotation_decay * _pose_rotation_velocity
		+ (1.0 - rotation_decay) * rotation_error
	)
	offset_transform_rotation += _pose_rotation_velocity


func _step_hand_motion(delta: float) -> void:
	if delta <= 0.0:
		return
	if _hand_motion_delay > 0.0:
		_hand_motion_delay = maxf(0.0, _hand_motion_delay - delta)
		return
	_hand_motion_elapsed += delta
	if _hand_motion_fades_in:
		modulate.a = clampf(_hand_motion_elapsed / 0.16, 0.0, 1.0)
	var idle_time := _idle_time_seconds()
	var target_position := _idle_position_at(idle_time) if _hand_idle_enabled else Vector2.ZERO
	var target_rotation := _idle_rotation_at(idle_time) if _hand_idle_enabled else 0.0
	if _selected:
		target_position.y -= SELECTED_LIFT
	_step_moveable_pose(target_position, target_rotation, Vector2.ONE, delta)
	_update_depth_layers(Vector2.ZERO, false, delta)
	if _hand_motion_elapsed >= _hand_motion_duration:
		_finish_hand_motion()


## Applies one explicit pointer sample to the held-card spring.  Tests call this
## method directly, while runtime feeds it the viewport mouse position.  The
## preview root already follows Godot's drag cursor, so visual position must not
## interpolate the same movement a second time.  Pointer velocity drives the
## Balatro-like rotation, stretch, shadow, and parallax without detaching the
## card from the player's hand.  The position spring only settles the small
## pickup lift inherited from the selected pose.
func _step_drag_motion(pointer_position: Vector2, delta: float) -> void:
	if delta <= 0.0:
		return
	if not _drag_pointer_initialized:
		_drag_last_pointer = pointer_position
		_drag_pointer_initialized = true
		_update_drag_payload()
		_update_depth_layers(Vector2.ZERO, true, delta)
		return
	var pointer_delta := pointer_position - _drag_last_pointer
	_drag_last_pointer = pointer_position
	if pointer_delta.length() > 96.0:
		pointer_delta = pointer_delta.normalized() * 96.0
	var sampled_velocity := pointer_delta / maxf(delta, 0.0001)
	var velocity_weight := 1.0 - exp(-DRAG_POINTER_VELOCITY_FOLLOW * delta)
	_drag_pointer_velocity = _drag_pointer_velocity.lerp(sampled_velocity, velocity_weight)

	_drag_lift_elapsed = minf(_drag_lift_elapsed + delta, DRAG_LIFT_BLEND_DURATION)
	var lift_weight := smoothstep(0.0, 1.0, _drag_lift_elapsed / DRAG_LIFT_BLEND_DURATION)
	var lift_target := _drag_pickup_position.lerp(_drag_rest_position, lift_weight)
	var motion_rotation := _drag_pointer_velocity.x * DRAG_VELOCITY_ROTATION_RADIANS
	var max_rotation := deg_to_rad(DRAG_MAX_ROTATION_DEGREES)
	var target_rotation := _drag_rest_rotation + clampf(motion_rotation, -max_rotation, max_rotation)
	_step_moveable_pose(lift_target, target_rotation, Vector2.ONE * DRAG_SCALE, delta)

	var direction := Vector2(
		clampf(_drag_pointer_velocity.x / 1200.0, -1.0, 1.0),
		clampf(_drag_pointer_velocity.y / 1200.0, -1.0, 1.0)
	)
	_update_depth_layers(direction, true, delta)
	_update_drag_payload()


func _update_drag_payload() -> void:
	_drag_payload_ref["drag_visual_position"] = offset_transform_position
	_drag_payload_ref["drag_visual_rotation"] = offset_transform_rotation
	_drag_payload_ref["drag_visual_scale"] = offset_transform_scale
	_drag_payload_ref["drag_visual_tilt"] = _perspective_tilt


func _pose_is_settled(target_position: Vector2, target_rotation: float, target_scale: Vector2) -> bool:
	return (
		offset_transform_position.distance_squared_to(target_position) < 0.0025
		and absf(wrapf(target_rotation - offset_transform_rotation, -PI, PI)) < 0.001
		and offset_transform_scale.distance_squared_to(target_scale) < 0.00001
		and _pose_position_velocity.length_squared() < 0.01
		and absf(_pose_rotation_velocity) < 0.01
		and _pose_scale_velocity.length_squared() < 0.0001
		and _perspective_tilt.length_squared() < 0.0001
		and _perspective_velocity.length_squared() < 0.0001
	)


## The card face receives pointer perspective, while the independent shadow
## stays on the table plane. This mirrors Balatro's two-pass 2D rendering: its
## shadow draw explicitly disables hover tilt and uses height only for offset
## and a slight scale reduction.
func _update_depth_layers(pointer: Vector2, dragging: bool, delta: float) -> void:
	var weight := 1.0 - exp(-18.0 * maxf(delta, 0.0))
	var perspective_target := Vector2.ZERO
	if _hovered or dragging:
		perspective_target = Vector2(
			_shape_perspective_axis(pointer.x),
			_shape_perspective_axis(pointer.y)
		)
		if dragging:
			perspective_target *= Vector2(0.72, 0.55)
	var returning := not (_hovered or dragging)
	var stiffness := PERSPECTIVE_RETURN_STIFFNESS if returning else PERSPECTIVE_STIFFNESS
	var damping := PERSPECTIVE_RETURN_DAMPING if returning else PERSPECTIVE_DAMPING
	_perspective_velocity += (perspective_target - _perspective_tilt) * stiffness * delta
	_perspective_velocity *= exp(-damping * delta)
	_set_perspective_tilt(_perspective_tilt + _perspective_velocity * delta)
	if is_instance_valid(_content_root):
		var content_target := Vector2(pointer.x * 1.65, pointer.y * 0.9)
		if dragging:
			content_target *= 1.2
		var next_content_position := _content_root.offset_transform_position.lerp(
			content_target, weight
		)
		if next_content_position.distance_squared_to(_content_root.offset_transform_position) > 0.000001:
			_content_root.offset_transform_position = next_content_position
			_request_visual_redraw()
	_update_shadow_projection(dragging, weight)


func _update_shadow_projection(dragging: bool, weight: float) -> void:
	if not is_instance_valid(_shadow_surface):
		return
	var target_height := SHADOW_DRAG_HEIGHT if dragging else SHADOW_IDLE_HEIGHT
	_shadow_height = lerpf(_shadow_height, target_height, clampf(weight, 0.0, 1.0))
	var viewport_width := get_viewport_rect().size.x if is_inside_tree() else 1.0
	var card_center_x := get_global_rect().get_center().x if is_inside_tree() else viewport_width * 0.5
	var projection := _shadow_offset_for_height(_shadow_height, card_center_x, viewport_width)
	_shadow_surface.position = Vector2.ONE * -VISUAL_MARGIN + projection
	_shadow_surface.scale = Vector2.ONE * _shadow_scale_for_height(_shadow_height)


static func _shadow_offset_for_height(height: float, card_center_x: float, viewport_width: float) -> Vector2:
	var half_width := maxf(viewport_width * 0.5, 1.0)
	var normalized_x := clampf((card_center_x - half_width) / half_width, -1.0, 1.0)
	var state_mix := clampf(
		inverse_lerp(SHADOW_IDLE_HEIGHT, SHADOW_DRAG_HEIGHT, height),
		0.0,
		1.0
	)
	var shadow_scale := _shadow_scale_for_height(height)
	var scale_inset := CARD_SIZE * (1.0 - shadow_scale) * 0.5
	var visible_side := CARD_SIZE.x * lerpf(
		SHADOW_IDLE_SIDE_EXPOSURE_RATIO,
		SHADOW_DRAG_SIDE_EXPOSURE_RATIO,
		state_mix
	)
	var visible_bottom := CARD_SIZE.y * lerpf(
		SHADOW_IDLE_BOTTOM_EXPOSURE_RATIO,
		SHADOW_DRAG_BOTTOM_EXPOSURE_RATIO,
		state_mix
	)
	return Vector2(
		-normalized_x * (visible_side + scale_inset.x),
		visible_bottom + scale_inset.y
	)


static func _shadow_scale_for_height(height: float) -> float:
	return 1.0 - 0.2 * height


static func _shadow_bottom_exposure_for_height(height: float) -> float:
	var offset := _shadow_offset_for_height(height, 500.0, 1000.0)
	var scale_inset := CARD_SIZE.y * (1.0 - _shadow_scale_for_height(height)) * 0.5
	return offset.y - scale_inset


func _shape_perspective_axis(value: float) -> float:
	var magnitude := absf(clampf(value, -1.0, 1.0))
	if magnitude <= PERSPECTIVE_DEAD_ZONE:
		return 0.0
	var normalized := (magnitude - PERSPECTIVE_DEAD_ZONE) / (1.0 - PERSPECTIVE_DEAD_ZONE)
	return signf(value) * pow(normalized, PERSPECTIVE_EXPONENT)


func _set_perspective_tilt(value: Vector2) -> void:
	_perspective_tilt = value
	if is_instance_valid(_perspective_material):
		_perspective_material.set_shader_parameter("tilt", value)


func _request_visual_redraw() -> void:
	if is_instance_valid(_visual_viewport):
		_visual_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _idle_time_seconds() -> float:
	return Time.get_ticks_msec() * 0.001


func _idle_rotation_at(time_seconds: float) -> float:
	return sin(time_seconds * IDLE_SWAY_FREQUENCY + _hand_idle_phase) * IDLE_SWAY_RADIANS


func _idle_position_at(time_seconds: float) -> Vector2:
	return Vector2(
		0.0,
		sin(time_seconds * IDLE_BOB_FREQUENCY + _hand_idle_phase) * IDLE_BOB_HEIGHT
	)


func _wake_pose_motion() -> void:
	if _drag_preview or _hidden_for_drag:
		return
	set_process(true)


func _set_card_style() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if is_instance_valid(_visual_face):
		_visual_face.add_theme_stylebox_override("panel", _style_for_card())
		_request_visual_redraw()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_content_root = null
	_render_root = null
	_visual_surface = null
	_visual_viewport = null
	_visual_face = null
	_perspective_material = null
	_shadow_surface = null
	_shadow_material = null
	_shadow_height = SHADOW_IDLE_HEIGHT
	_hover_juice_mode = HoverJuiceMode.NONE
	_hover_juice_elapsed = 0.0
	_hover_juice_scale = 0.0
	_hover_juice_rotation = 0.0
	_build_visual_surface()
	var col := VBoxContainer.new()
	col.name = "CardFaceContent"
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.offset_transform_enabled = true
	col.offset_transform_visual_only = true
	col.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	_visual_face.add_child(col)
	_content_root = col

	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = str(_card.get("name", "?"))
	_fit_card_label(title)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	col.add_child(title)

	var art := ColorRect.new()
	art.name = "CardArt"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.color = Color("#141515")
	art.custom_minimum_size = Vector2(88, 112)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(art)
	_set_card_style()


func _build_visual_surface() -> void:
	var logical_size := CARD_SIZE + Vector2.ONE * VISUAL_MARGIN * 2.0
	_visual_viewport = SubViewport.new()
	_visual_viewport.name = "CardVisualViewport"
	_visual_viewport.size = Vector2i(logical_size * VISUAL_RENDER_SCALE)
	_visual_viewport.transparent_bg = true
	_visual_viewport.disable_3d = true
	_visual_viewport.gui_disable_input = true
	_visual_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_visual_viewport)

	_visual_face = PanelContainer.new()
	_visual_face.name = "CardVisualFace"
	_visual_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual_face.position = Vector2.ONE * VISUAL_MARGIN * VISUAL_RENDER_SCALE
	_visual_face.size = CARD_SIZE
	_visual_face.custom_minimum_size = CARD_SIZE
	_visual_face.scale = Vector2.ONE * VISUAL_RENDER_SCALE
	_visual_viewport.add_child(_visual_face)

	# PanelContainer owns the layout of its direct Control children. Keep one
	# stable CARD_SIZE child under that contract, then place the face and shadow
	# inside this plain Control so their negative texture margin and projection
	# offsets cannot be reset by container sorting.
	_render_root = Control.new()
	_render_root.name = "CardRenderRoot"
	_render_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_render_root.custom_minimum_size = CARD_SIZE
	_render_root.size = CARD_SIZE
	_render_root.offset_transform_enabled = true
	_render_root.offset_transform_visual_only = true
	_render_root.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	add_child(_render_root)

	# Draw the unwarped face alpha once more as the table shadow. It shares the
	# root card's ordinary 2D motion but is a sibling of the perspective surface,
	# so pointer pitch/yaw can never deform it.
	_shadow_surface = TextureRect.new()
	_shadow_surface.name = "CardShadowSurface"
	_shadow_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow_surface.position = Vector2.ONE * -VISUAL_MARGIN
	_shadow_surface.size = logical_size
	_shadow_surface.pivot_offset = logical_size * 0.5
	_shadow_surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shadow_surface.stretch_mode = TextureRect.STRETCH_SCALE
	_shadow_surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_shadow_surface.texture = _visual_viewport.get_texture()
	_shadow_material = ShaderMaterial.new()
	_shadow_material.shader = CARD_SHADOW_SHADER
	_shadow_surface.material = _shadow_material
	_render_root.add_child(_shadow_surface)
	_update_shadow_projection(false, 1.0)

	# Render the viewport through a plain TextureRect. SubViewportContainer's
	# internal stretch transform changes canvas UVs before a custom material is
	# evaluated, which makes the card texture tile when the container is shrunk.
	_visual_surface = TextureRect.new()
	_visual_surface.name = "CardVisualSurface"
	_visual_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual_surface.position = Vector2.ONE * -VISUAL_MARGIN
	_visual_surface.size = logical_size
	_visual_surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_visual_surface.stretch_mode = TextureRect.STRETCH_SCALE
	_visual_surface.texture = _visual_viewport.get_texture()
	_perspective_material = ShaderMaterial.new()
	_perspective_material.shader = CARD_HOVER_SHADER
	_perspective_material.set_shader_parameter("visual_size", logical_size)
	_perspective_material.set_shader_parameter("tilt", _perspective_tilt)
	_visual_surface.material = _perspective_material
	_render_root.add_child(_visual_surface)


static func _fit_card_label(label: Label) -> void:
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2.ZERO
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


static func _type_label(t: String) -> String:
	match t:
		"char":
			return "角色"
		"item":
			return "道具"
		"sudan":
			return "苏丹"
		_:
			return t


static func _rarity_color(rare: int, card_type: String = "") -> Color:
	if card_type == "sudan":
		return FaustTheme.DANGER_LIGHT
	match clampi(rare, 0, 4):
		0, 1:
			return Color("#b28755")
		2:
			return Color("#bcc7d4")
		3:
			return FaustTheme.GOLD_BRIGHT
		_:
			return Color("#d9d3ff")


## Build a standalone card widget from a card dictionary.
static func make(card: Dictionary, source: String = "hand", slot_key: String = "", rite_uid: int = 0) -> CardWidget:
	var w := CardWidget.new()
	w.custom_minimum_size = CARD_SIZE
	w.card_id = int(card.get("id", 0))
	w.card_uid = int(card.get("instance_uid", 0))
	w.drag_source = source
	w.drag_slot = slot_key
	w.drag_rite_uid = rite_uid
	w.set_card(card)
	return w
