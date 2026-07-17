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

const CARD_SIZE := Vector2(104, 160)
const HOVER_SCALE := 1.06
const HOVER_LIFT := 12.0
const PRESS_SCALE := 0.96
const HOVER_TILT_DEGREES := 4.0
const TILT_FOLLOW_SPEED := 18.0
const POINTER_PARALLAX := Vector2(2.5, 1.5)
const HOVER_Z_INDEX := 20
const IDLE_BOB_HEIGHT := 2.35
const IDLE_DRIFT_WIDTH := 0.65
const IDLE_SWAY_DEGREES := 0.78
const IDLE_FOLLOW_SPEED := 5.0
const IDLE_PHASE_STEP := 0.754877666
const DEAL_DURATION := 0.30
const DEAL_STAGGER := 0.055
const REFLOW_DURATION := 0.22

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
var _hidden_for_drag := false
var _hovered := false
var _pressed := false
var _drag_preview := false
var _dealing := false
var _base_z_index := 0
var _hand_idle_enabled := false
var _hand_idle_phase := 0.0
var _motion_tween: Tween


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
	set_process(_drag_preview or _hand_idle_enabled)
	_set_card_style()


## Applies the stable pose owned by the hand layout.  The ordinary Control
## transform owns hit testing; offset_transform remains free for visual feel.
func set_hand_pose(target_position: Vector2, target_rotation: float, order: int) -> void:
	position = target_position
	size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	rotation = target_rotation
	_base_z_index = order
	if not _hovered and not _drag_preview:
		z_index = order


## Gives every hand card a deterministic phase so an untouched hand feels
## alive without jittering or changing game state.
func set_hand_idle(enabled: bool, order: int = 0) -> void:
	_hand_idle_enabled = enabled
	# Keep a card on the same motion curve when its rail order changes.  Using
	# the slot index here made a dropped card jump to a new phase and could leave
	# it apparently locked into the drag preview's left lean for several seconds.
	var phase_key := card_uid
	if phase_key <= 0:
		phase_key = card_id * 31 + order * 17
	_hand_idle_phase = fposmod(float(phase_key) * IDLE_PHASE_STEP, TAU)
	set_process(_drag_preview or _hovered or _hand_idle_enabled)


## Deals a card from the right-side deck area into its already-computed hand
## slot.  Keeping the stable position untouched prevents insertion hit tests
## and resize layout from chasing the animation.
func play_deal_in(source_offset: Vector2, order: int) -> void:
	if _drag_preview or _hidden_for_drag:
		return
	_stop_motion_tween()
	_dealing = true
	_hovered = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	offset_transform_position = source_offset
	offset_transform_rotation = deg_to_rad(7.0)
	offset_transform_scale = Vector2.ONE * 0.88
	modulate = Color(1, 1, 1, 0)
	var delay := minf(float(order), 10.0) * DEAL_STAGGER
	var landing_time := _idle_time_seconds() + delay + DEAL_DURATION
	var landing_position := _idle_position_at(landing_time) if _hand_idle_enabled else Vector2.ZERO
	var landing_rotation := _idle_rotation_at(landing_time) if _hand_idle_enabled else 0.0
	_motion_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "offset_transform_position", landing_position, DEAL_DURATION).set_delay(delay)
	_motion_tween.tween_property(self, "offset_transform_rotation", landing_rotation, DEAL_DURATION).set_delay(delay)
	_motion_tween.tween_property(self, "offset_transform_scale", Vector2.ONE, DEAL_DURATION).set_delay(delay)
	_motion_tween.tween_property(self, "modulate", Color.WHITE, 0.16).set_delay(delay)
	_motion_tween.finished.connect(_finish_hand_motion)


## When a played card leaves, the remaining cards keep their former rendered
## positions and glide into the newly centred slots.  This mirrors the smooth
## follow/OutBack return used by public Balatro-feel implementations.
func play_hand_reflow(
	source_offset: Vector2,
	source_rotation: float = INF,
	source_scale: Vector2 = Vector2.ZERO
) -> void:
	var has_explicit_pose := source_rotation != INF or source_scale != Vector2.ZERO
	if _drag_preview or _hidden_for_drag:
		return
	if source_offset.length_squared() < 0.25 and not has_explicit_pose:
		return
	_stop_motion_tween()
	_dealing = true
	_hovered = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	offset_transform_position = source_offset
	offset_transform_rotation = (
		deg_to_rad(clampf(source_offset.x * 0.025, -2.5, 2.5))
		if source_rotation == INF
		else source_rotation
	)
	offset_transform_scale = Vector2.ONE * 0.97 if source_scale == Vector2.ZERO else source_scale
	modulate = Color.WHITE
	var landing_time := _idle_time_seconds() + REFLOW_DURATION
	var landing_position := _idle_position_at(landing_time) if _hand_idle_enabled else Vector2.ZERO
	var landing_rotation := _idle_rotation_at(landing_time) if _hand_idle_enabled else 0.0
	_motion_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "offset_transform_position", landing_position, REFLOW_DURATION)
	_motion_tween.tween_property(self, "offset_transform_rotation", landing_rotation, REFLOW_DURATION)
	_motion_tween.tween_property(self, "offset_transform_scale", Vector2.ONE, REFLOW_DURATION)
	_motion_tween.finished.connect(_finish_hand_motion)


func _finish_hand_motion() -> void:
	_dealing = false
	if not _hand_idle_enabled:
		offset_transform_position = Vector2.ZERO
		offset_transform_rotation = 0.0
	offset_transform_scale = Vector2.ONE
	modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(_hand_idle_enabled)


func is_hand_motion_active() -> bool:
	return _dealing


func _style_for_card() -> StyleBoxFlat:
	var accent := _rarity_color(int(_card.get("rare", 0)), str(_card.get("type", "")))
	var style := FaustTheme.card_style(accent)
	# A soft offset shadow is important: it gives the lift a visual anchor even
	# before an actual card illustration replaces the current placeholder art.
	style.shadow_color = Color(0.035, 0.025, 0.018, 0.72)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 5)
	if _hovered or _drag_preview:
		style.border_color = accent.lightened(0.18)
		style.set_border_width_all(2)
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 4)
	return style


func _get_drag_data(at_position: Vector2) -> Variant:
	if card_id <= 0:
		return null
	_drag_grab_offset = at_position
	# The cursor-held card starts from the exact rendered hover pose.  There is
	# no separate drag tilt, so picking a card up cannot introduce an angle jump.
	_drag_selected_position = offset_transform_position
	_drag_selected_rotation = offset_transform_rotation
	_drag_selected_scale = offset_transform_scale
	var preview := CardWidget.make(_card.duplicate(true), drag_source, drag_slot, drag_rite_uid)
	preview.card_id = card_id
	preview.make_drag_preview(
		_drag_selected_position,
		_drag_selected_rotation,
		_drag_selected_scale
	)
	var preview_root := Control.new()
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_root.custom_minimum_size = CARD_SIZE
	# Preserve the pointer-to-card offset from the moment dragging begins.
	preview.position = -at_position
	preview_root.add_child(preview)
	set_drag_preview(preview_root)
	_hide_source_for_drag()
	return drag_payload()


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
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _hidden_for_drag:
		var drag_succeeded := get_viewport() != null and get_viewport().gui_is_drag_successful()
		if drag_succeeded:
			_hidden_for_drag = false
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
			_apply_scale_motion()
		elif event.position.distance_to(_press_position) <= 8.0:
			_pressed = false
			_apply_scale_motion()
			clicked.emit(card_id, _card.duplicate(true))
		else:
			_pressed = false
			_apply_scale_motion()


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
	_stop_motion_tween()
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
	var source_offset := _drag_selected_position
	var parent_control := get_parent() as Control
	if parent_control != null and get_viewport() != null:
		var mouse_in_parent := (
			parent_control.get_global_transform().affine_inverse()
			* get_viewport().get_mouse_position()
		)
		source_offset += mouse_in_parent - _drag_grab_offset - position
	play_hand_reflow(source_offset, _drag_selected_rotation, _drag_selected_scale)


## Marks this standalone instance as the cursor-held drag image while retaining
## the exact visual pose from the source card.
func make_drag_preview(
	initial_position: Vector2 = Vector2.ZERO,
	initial_rotation: float = 0.0,
	initial_scale: Vector2 = Vector2.ONE
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
	z_index = HOVER_Z_INDEX
	_set_card_style()


func _set_hovered(is_hovered: bool) -> void:
	if _drag_preview or _dealing or _hidden_for_drag or _hovered == is_hovered:
		return
	_hovered = is_hovered
	if _hovered:
		z_index = _base_z_index + HOVER_Z_INDEX
	set_process(_hovered or _hand_idle_enabled)
	_set_card_style()
	_apply_scale_motion()
	if not _hovered:
		# Do not leave a tiny cursor-derived twist on a card after the pointer
		# moves on to its neighbour.
		# Lower the layer immediately so a settling card cannot steal hover input
		# from the next overlapped card in a dense rail.
		z_index = _base_z_index
		_stop_motion_tween()
		_motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_motion_tween.tween_property(self, "offset_transform_scale", Vector2.ONE, 0.16)
		if not _hand_idle_enabled:
			_motion_tween.parallel().tween_property(self, "offset_transform_rotation", 0.0, 0.16)
			_motion_tween.parallel().tween_property(self, "offset_transform_position", Vector2.ZERO, 0.16)


func _process(delta: float) -> void:
	if _drag_preview:
		# The drag proxy is a frozen snapshot of the selected card.  Since the
		# grab point does not change relative to the card, recomputing tilt here
		# would only introduce a discontinuity.
		return
	if not _hovered:
		if not _hand_idle_enabled:
			return
		var idle_time := _idle_time_seconds()
		var idle_rotation := _idle_rotation_at(idle_time)
		var idle_position := _idle_position_at(idle_time)
		var idle_weight := 1.0 - exp(-IDLE_FOLLOW_SPEED * delta)
		offset_transform_rotation = lerp_angle(offset_transform_rotation, idle_rotation, idle_weight)
		offset_transform_position = offset_transform_position.lerp(idle_position, idle_weight)
		return
	var half_size := size * 0.5
	if half_size.x <= 0.0:
		return
	var pointer_offset := (get_local_mouse_position() - half_size) / half_size
	var clamped_pointer := Vector2(
		clampf(pointer_offset.x, -1.0, 1.0),
		clampf(pointer_offset.y, -1.0, 1.0)
	)
	var target_tilt := deg_to_rad(clamped_pointer.x * HOVER_TILT_DEGREES)
	var target_lift := -HOVER_LIFT
	var follow_weight := 1.0 - exp(-TILT_FOLLOW_SPEED * delta)
	if _pressed:
		target_lift *= 0.72
	var target_position := Vector2(
		clamped_pointer.x * POINTER_PARALLAX.x,
		target_lift + clamped_pointer.y * POINTER_PARALLAX.y
	)
	offset_transform_rotation = lerp_angle(offset_transform_rotation, target_tilt, follow_weight)
	offset_transform_position = offset_transform_position.lerp(target_position, follow_weight)


func _idle_time_seconds() -> float:
	return Time.get_ticks_msec() * 0.001


func _idle_rotation_at(time_seconds: float) -> float:
	return deg_to_rad(sin(time_seconds * 0.82 + _hand_idle_phase) * IDLE_SWAY_DEGREES)


func _idle_position_at(time_seconds: float) -> Vector2:
	return Vector2(
		cos(time_seconds * 0.67 + _hand_idle_phase) * IDLE_DRIFT_WIDTH,
		sin(time_seconds * 0.74 + _hand_idle_phase) * IDLE_BOB_HEIGHT
	)


func _apply_scale_motion() -> void:
	if _drag_preview or _hidden_for_drag:
		return
	_stop_motion_tween()
	var target_scale := Vector2.ONE
	if _hovered:
		target_scale *= HOVER_SCALE
	if _pressed:
		target_scale *= PRESS_SCALE
	_motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "offset_transform_scale", target_scale, 0.10)


func _set_card_style() -> void:
	add_theme_stylebox_override("panel", _style_for_card())


func _stop_motion_tween() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_set_card_style()
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(col)

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
