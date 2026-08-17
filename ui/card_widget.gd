## A compact visual card for hand, table slots, and drag previews.
##
## Presentation follows the original: a card is a flat UI surface — the card
## art with its rarity frame IS the card; hovering raises the highlighted
## hand card (CardArea's highlight offset); dealing and reflow ride short
## eased tweens; the drag preview tracks the cursor exactly, without
## rotation, scale, or perspective of its own. The clone-era Balatro motion
## layer (spring integrator, perspective + shadow shader passes, pointer
## velocity tilt) was removed per the 2026-08-15 presentation reset.
## [SRC: CardArea.c highlighted card offset; DOTween deal/reflow tweens in
##       CardController.c]
class_name CardWidget
extends Control

signal clicked(card_id: int, card: Dictionary)
signal drag_visibility_changed(card_uid: int, hidden: bool)

const CARD_SIZE := Vector2(104, 160)
const SELECTED_LIFT := CARD_SIZE.y * 0.2
const HOVER_Z_INDEX := 20
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
var _drag_selected_tilt := Vector2.ZERO
var _hidden_for_drag := false
var _hovered := false
var _pressed := false
var _selected := false
var _drag_preview := false
var _dealing := false
var _base_z_index := 0
var _idle_elapsed_seconds := 0.0
var _idle_time_source := Callable()
var _drag_payload_ref: Dictionary = {}
var _pose_tween: Tween
var _visual_face: PanelContainer
var _presentation_paused := false


func set_card(card: Dictionary) -> void:
	_card = card
	card_id = int(card.get("id", card_id))
	card_uid = int(card.get("instance_uid", card_uid))
	_rebuild()


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE if _drag_preview else Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_base_z_index = z_index
	# Godot 4.7's visual-only offset transform keeps layout and hit testing on
	# the stable card rectangle while the lift/tween renders independently.
	offset_transform_enabled = true
	offset_transform_visual_only = true
	offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	mouse_entered.connect(func(): _set_hovered(true))
	mouse_exited.connect(func(): _set_hovered(false))
	_set_card_style()


## Applies the stable pose owned by the hand layout. The ordinary Control
## transform owns hit testing; offset_transform carries the hover lift only.
func set_hand_pose(target_position: Vector2, target_rotation: float, order: int) -> void:
	position = target_position
	size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	rotation = target_rotation
	_base_z_index = order
	if not _drag_preview:
		z_index = order + HOVER_Z_INDEX if (_hovered or _selected) else order


## The original hand has no idle sine wave; kept as a sink so the hand rail
## can keep one call site.
func set_hand_idle(
	_enabled: bool,
	_order: int = 0,
	idle_time_source: Callable = Callable()
) -> void:
	_idle_time_source = idle_time_source


## A local context menu may keep the rail visible as background, but its cards
## must become a still, non-interactive snapshot until that menu closes.
func set_presentation_paused(paused: bool) -> void:
	if _presentation_paused == paused:
		return
	_presentation_paused = paused
	if paused:
		_kill_pose_tween()
		_dealing = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	if not _drag_preview and not _dealing and not _hidden_for_drag:
		mouse_filter = Control.MOUSE_FILTER_STOP


func is_presentation_paused() -> bool:
	return _presentation_paused


## Selection changes only the hand target height, matching CardArea's
## highlighted offset.
func set_selected(selected: bool, _with_impulse: bool = true) -> void:
	if _drag_preview or _selected == selected:
		return
	_selected = selected
	z_index = _base_z_index + HOVER_Z_INDEX if (_selected or _hovered) else _base_z_index
	_apply_rest_pose()
	_set_card_style()


func is_selected() -> bool:
	return _selected


## Deals a card from the right-side deck area into its already-computed hand
## slot, as a short eased tween (the original's DOTween deal).
func play_deal_in(source_offset: Vector2, order: int) -> void:
	if _drag_preview or _hidden_for_drag:
		return
	_dealing = true
	_hovered = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	offset_transform_position = source_offset
	offset_transform_rotation = 0.0
	offset_transform_scale = Vector2.ONE
	modulate = Color(1, 1, 1, 0)
	_pose_tween = create_tween()
	_pose_tween.set_trans(Tween.TRANS_SINE)
	_pose_tween.set_ease(Tween.EASE_OUT)
	_pose_tween.tween_interval(minf(float(order), 10.0) * DEAL_STAGGER)
	_pose_tween.parallel().tween_property(self, "modulate:a", 1.0, 0.16)
	_pose_tween.parallel().tween_property(self, "offset_transform_position", Vector2.ZERO, DEAL_DURATION)
	_pose_tween.finished.connect(_finish_hand_motion)


## Reflow tweens from the former rendered pose back to the rest rectangle.
func play_hand_reflow(
	source_offset: Vector2,
	source_rotation: float = INF,
	source_scale: Vector2 = Vector2.ZERO,
	source_tilt: Vector2 = Vector2(INF, INF)
) -> void:
	if _drag_preview or _hidden_for_drag:
		return
	if source_offset.length_squared() < 0.25 and source_rotation == INF:
		return
	_dealing = true
	_hovered = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	offset_transform_position = source_offset
	offset_transform_rotation = 0.0 if source_rotation == INF else source_rotation
	offset_transform_scale = Vector2.ONE if source_scale == Vector2.ZERO else source_scale
	modulate = Color.WHITE
	_pose_tween = create_tween()
	_pose_tween.set_trans(Tween.TRANS_SINE)
	_pose_tween.set_ease(Tween.EASE_OUT)
	_pose_tween.tween_property(self, "offset_transform_position", Vector2.ZERO, REFLOW_DURATION)
	_pose_tween.parallel().tween_property(
		self, "offset_transform_rotation", 0.0, REFLOW_DURATION
	)
	_pose_tween.parallel().tween_property(
		self, "offset_transform_scale", Vector2.ONE, REFLOW_DURATION
	)
	_pose_tween.finished.connect(_finish_hand_motion)


func _kill_pose_tween() -> void:
	if _pose_tween != null and _pose_tween.is_valid():
		_pose_tween.kill()
	_pose_tween = null


func _finish_hand_motion() -> void:
	_dealing = false
	_pose_tween = null
	offset_transform_position = Vector2.ZERO
	offset_transform_rotation = 0.0
	offset_transform_scale = Vector2.ONE
	modulate = Color.WHITE
	if not _presentation_paused and not _drag_preview and not _hidden_for_drag:
		mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_rest_pose()


func is_hand_motion_active() -> bool:
	return _dealing


func _style_for_card() -> StyleBoxFlat:
	# Texture-first: when original card art or a rarity frame is present the
	# art IS the face — no paper chrome may frame it.
	if _card_art_texture() != null or _rarity_frame_texture() != null:
		var empty := StyleBoxFlat.new()
		empty.bg_color = Color.TRANSPARENT
		empty.set_border_width_all(0)
		empty.set_content_margin_all(0)
		return empty
	var accent := _rarity_color(int(_card.get("rare", 0)), str(_card.get("type", "")))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ead69a")
	style.border_color = accent.darkened(0.24)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	if _hovered or _selected or _drag_preview:
		style.border_color = accent.lightened(0.18)
		style.bg_color = Color("#f5e5b4")
	return style


func _get_drag_data(at_position: Vector2) -> Variant:
	if _presentation_paused or card_id <= 0:
		return null
	_drag_grab_offset = at_position
	_drag_selected_position = offset_transform_position
	_drag_selected_rotation = 0.0
	_drag_selected_scale = Vector2.ONE
	_drag_selected_tilt = Vector2.ZERO
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
	if _presentation_paused:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_position = event.position
			_pressed = true
		elif event.position.distance_to(_press_position) <= 8.0:
			_pressed = false
			clicked.emit(card_id, _card.duplicate(true))
		else:
			_pressed = false


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
	_kill_pose_tween()
	_dealing = false
	offset_transform_rotation = 0.0
	offset_transform_position = Vector2.ZERO
	offset_transform_scale = Vector2.ONE
	z_index = _base_z_index
	visible = false
	drag_visibility_changed.emit(card_uid, true)


func _restore_source_after_failed_drag() -> void:
	_hidden_for_drag = false
	visible = true
	_set_card_style()
	# Reinsert the stable slot first, then tween back from the release point.
	drag_visibility_changed.emit(card_uid, false)
	var source_offset: Vector2 = _drag_payload_ref.get("drag_visual_position", _drag_selected_position)
	_drag_payload_ref = {}
	play_hand_reflow(source_offset)


## Marks this standalone instance as the cursor-held drag image. It tracks
## the engine drag cursor exactly; no motion of its own.
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
	offset_transform_position = initial_position
	offset_transform_rotation = initial_rotation
	offset_transform_scale = initial_scale
	_drag_payload_ref = payload_ref
	z_index = HOVER_Z_INDEX
	_set_card_style()


func _set_hovered(is_hovered: bool) -> void:
	if _presentation_paused or _drag_preview or _dealing or _hidden_for_drag or _hovered == is_hovered:
		return
	_hovered = is_hovered
	z_index = _base_z_index + HOVER_Z_INDEX if (_hovered or _selected) else _base_z_index
	_apply_rest_pose()
	_set_card_style()


## The rest pose is the CardArea highlight: hovered or selected cards sit
## lifted; everything else lies flat on the rail.
func _apply_rest_pose() -> void:
	if _drag_preview or _dealing or _hidden_for_drag:
		return
	_kill_pose_tween()
	var lift := SELECTED_LIFT if (_hovered or _selected) else 0.0
	offset_transform_position = Vector2(0.0, -lift)
	offset_transform_rotation = 0.0
	offset_transform_scale = Vector2.ONE


func _idle_time_seconds() -> float:
	if _idle_time_source.is_valid():
		return float(_idle_time_source.call())
	return _idle_elapsed_seconds


func _set_card_style() -> void:
	if is_instance_valid(_visual_face):
		_visual_face.add_theme_stylebox_override("panel", _style_for_card())
		# Original rarity frame overlay: copper/silver/gold card borders
		# painted over the face (stone for the lowest tier).
		# [SRC: Texture2D/card_bg_copper.png / card_bg_silver.png /
		#       card_bg_gold.png / card_bg_stone.png]
		var frame := _rarity_frame_texture()
		if frame != null:
			var frame_rect := _find_or_add_frame("RarityFrame")
			frame_rect.texture = frame


static var _rarity_frames: Dictionary = {}


func _rarity_frame_texture() -> Texture2D:
	var rare := int(_card.get("rare", 0))
	var tier := "card_bg_stone"
	if rare >= 4:
		tier = "card_bg_gold"
	elif rare >= 3:
		tier = "card_bg_silver"
	elif rare >= 2:
		tier = "card_bg_copper"
	if _rarity_frames.has(tier):
		return _rarity_frames[tier]
	var path := "res://assets/original/ui/%s.png" % tier
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	_rarity_frames[tier] = texture
	return texture


func _find_or_add_frame(node_name: String) -> TextureRect:
	if is_instance_valid(_visual_face):
		var existing := _visual_face.get_node_or_null(NodePath(node_name))
		if existing is TextureRect:
			return existing
		var rect := TextureRect.new()
		rect.name = node_name
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_face.add_child(rect)
		return rect
	var stub := TextureRect.new()
	return stub


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	# The face is a container anchored to the stable card rectangle: the
	# widget root stays a plain Control so the face's content minimums can
	# never inflate the card's layout size.
	_visual_face = PanelContainer.new()
	_visual_face.name = "CardVisualFace"
	_visual_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual_face.clip_contents = true
	_visual_face.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_visual_face)

	var col := VBoxContainer.new()
	col.name = "CardFaceContent"
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_visual_face.add_child(col)

	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = str(_card.get("name", "?"))
	_fit_card_label(title)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("#2d2118"))
	col.add_child(title)

	# Prefer the original card art (extracted per card id). Cards that ship
	# without art in the original data show the type icon instead — the
	# original renders no painting for them either.
	# [SRC: Texture2D/cards/<id>.png; Texture2D/card_type_char/item/sudan]
	var art_texture := _card_art_texture()
	if art_texture != null:
		var art_tex := TextureRect.new()
		art_tex.name = "CardArt"
		art_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_tex.texture = art_texture
		art_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art_tex.custom_minimum_size = Vector2(88, 112)
		art_tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art_tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(art_tex)
	else:
		var type_icon := _card_type_icon()
		if type_icon != null:
			var icon_box := CenterContainer.new()
			icon_box.name = "CardArt"
			icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_box.custom_minimum_size = Vector2(88, 112)
			icon_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			icon_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
			var icon := TextureRect.new()
			icon.texture = type_icon
			icon.custom_minimum_size = Vector2(48, 48)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_box.add_child(icon)
			col.add_child(icon_box)
	# Attribute row: the original tag icons for the six attribute tags
	# (tags atlas, keyed by tag.json `resource` like "tag_1" for 体魄).
	var attr_row := HBoxContainer.new()
	attr_row.name = "CardAttrRow"
	attr_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attr_row.add_theme_constant_override("separation", 2)
	attr_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(attr_row)
	for tag_name in ["体魄", "魅力", "智慧", "隐匿", "战斗", "社交", "生存", "魔力"]:
		var icon := _attribute_icon(tag_name)
		if icon == null:
			continue
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(16, 16)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.tooltip_text = tag_name
		attr_row.add_child(icon_rect)
	_set_card_style()


## Original card art extracted from the game assets, keyed by card id.
func _card_art_texture() -> Texture2D:
	var art_path := "res://assets/original/cards/%d.png" % int(_card.get("id", 0))
	if ResourceLoader.exists(art_path):
		return load(art_path) as Texture2D
	return null


## Type icon for cards without extracted art.
## [SRC: Texture2D/card_type_char.png / card_type_item.png / card_type_sudan.png]
func _card_type_icon() -> Texture2D:
	var type := str(_card.get("type", "item"))
	if type == "":
		type = "item"
	var path := "res://assets/original/ui/card_type_%s.png" % type
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static var _tags_atlas: OriginalAtlas = null


## Attribute icons come from the original tags atlas via tag.json resource
## ids ("tag_1" 体魄, ...). [SRC: assets/original/ui/tags.png + tags.json;
##       content/tag.json resource fields]
static func _attribute_icon(tag_name: String) -> Texture2D:
	if _tags_atlas == null:
		_tags_atlas = OriginalAtlas.load_atlas("res://assets/original/ui/tags.png")
	if _tags_atlas == null:
		return null
	var resource_id := _attribute_tag_resource(tag_name)
	if resource_id == "":
		return null
	return _tags_atlas.frame(resource_id + ".png")


const ATTRIBUTE_TAG_RESOURCES := {
	"体魄": "tag_1", "魅力": "tag_2", "智慧": "tag_3",
	"隐匿": "tag_4", "战斗": "tag_5", "社交": "tag_6",
	"生存": "tag_8", "魔力": "tag_9",
}


static func _attribute_tag_resource(tag_name: String) -> String:
	return str(ATTRIBUTE_TAG_RESOURCES.get(tag_name, ""))


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
