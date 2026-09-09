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

## Authored RectTransforms, not clone-side presentation measurements.
## [SRC: Resources/prefab/CardNew.prefab CardNew 194x422;
##       Resources/prefab/SudanCard.prefab 185x330 belongs to the pool only.]
const CARD_SIZE := Vector2(194, 422)
const SUDAN_CARD_SIZE := Vector2(185, 330)
const SELECTED_LIFT := CARD_SIZE.y * 0.2
const HOVER_Z_INDEX := 20
const DEAL_DURATION := 0.30
const DEAL_STAGGER := 0.055
const REFLOW_DURATION := 0.22

var _card: Dictionary = {}
var _card_size := CARD_SIZE
var card_id: int = 0
var card_uid: int = 0
var drag_source := "hand"
var drag_slot := ""
var drag_rite_uid := 0
var drag_allowed: Callable
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
var _visual_face: Control
var _presentation_paused := false
var _metal_materials: Array[ShaderMaterial] = []


func _process(_delta: float) -> void:
	if _presentation_paused or _metal_materials.is_empty():
		return
	# [SRC: CardRender.Update 0x53a8e0 -> GetScreenOffset 0x5508a0;
	# GameScene ScreenXOffsetRange=(0,.05), ScreenYOffsetRange=(.2,.4).]
	var center := get_global_transform_with_canvas() * (_card_size * 0.5 + offset_transform_position)
	var viewport_size := get_viewport_rect().size
	var offset := Vector2(center.x / viewport_size.x * 0.05, 0.4 - center.y / viewport_size.y * 0.2)
	for surface in _metal_materials:
		surface.set_shader_parameter("normal_offset", offset)


func _apply_metal_surface(image: TextureRect) -> void:
	# [SRC: materials/card/{char,item,sudan}/{stone,copper,silver,gold}.mat —
	# every tier carries a _MainTex/_BumpMap/_MetallicGlossMap surface, so the
	# material applies to all rarities, not only rare>=2. Bump/gloss values are
	# the authored _BumpScale/_GlossMapScale pairs (stone 0.9027777/0.3020833,
	# copper 0.3819444/0.7847222, silver 0.2847222/0.8090278,
	# gold 0.3680556/0.75).]
	var tier := clampi(int(_card.get("rare", 1)) - 1, 0, 3)
	var kind := str(_card.get("type", "item"))
	var normal_name := "card_n_1" if kind == "char" else ("card_n_0" if kind == "sudan" else "card_n_2")
	var metal_name := "card_mt_0" if kind == "char" else ("card_mt" if kind == "sudan" else "card_mt_1")
	var surface := ShaderMaterial.new()
	surface.shader = preload("res://ui/card_metal.gdshader")
	surface.set_shader_parameter("normal_map", load("res://assets/original/ui/%s.png" % normal_name))
	surface.set_shader_parameter("metal_map", load("res://assets/original/ui/%s.png" % metal_name))
	surface.set_shader_parameter("bump_scale", [0.9027777, 0.3819444, 0.2847222, 0.3680556][tier])
	surface.set_shader_parameter("gloss_scale", [0.3020833, 0.7847222, 0.8090278, 0.75][tier])
	var detail_name: String = str(CARD_DETAIL_MAPS.get(kind, ["", "", "", ""])[tier])
	if not detail_name.is_empty():
		surface.set_shader_parameter("detail_map", load("res://assets/original/ui/%s.png" % detail_name))
		surface.set_shader_parameter("has_detail", true)
	# Scene-light response per tier, fitted against the original hand in
	# docs/ui_layout/original_runtime/desktop.jpg (the exported CardShow shader
	# has no body). Whole-card averages in the clone and the original then
	# agree within a few percent: 梅姬 93/98/76 vs 96/100/66, 阿尔图 92/95/105
	# vs 89/94/100, 快脚 112/95/86 vs 118/98/77, 金币 94/90/70 vs 98/92/62.
	# The portrait itself renders identically (art centre 82/70/58 vs 81/68/55);
	# only the frame's lighting distribution still differs. The detail albedo
	# multiply is divided back out here so this light stays a scene constant
	# while the detail texture keeps its authored spatial variation.
	var light: Vector3 = [
		Vector3(2.0, 2.31, 3.5),
		Vector3(1.28, 1.44, 1.52),
		Vector3(1.44, 1.52, 1.61),
		Vector3(1.46, 1.77, 2.48),
	][tier]
	if not detail_name.is_empty():
		light = light / (Vector3(CARD_DETAIL_MEANS[detail_name]) * 2.0)
	surface.set_shader_parameter("material_light", light)
	# Lighting shape fitted to the original hand (see ui/card_metal.gdshader).
	surface.set_shader_parameter("vertical_light_falloff", 0.2065)
	surface.set_shader_parameter("metallic_diffuse_loss", 0.3)
	surface.set_shader_parameter("specular_strength", 0.3)
	image.material = surface
	_metal_materials.append(surface)


func set_card(card: Dictionary) -> void:
	_card = card
	_card_size = size_for_card(card)
	card_id = int(card.get("id", card_id))
	card_uid = int(card.get("instance_uid", card_uid))
	custom_minimum_size = _card_size
	size = _card_size
	_rebuild()


static func size_for_card(card: Dictionary) -> Vector2:
	# GameController.AddCard 0x54ad40 uses cardPrefab for all live cards;
	# SudanCard belongs to SudanPoolController (dump.cs:327241), not the hand.
	return CARD_SIZE


func card_size() -> Vector2:
	return _card_size


func _ready() -> void:
	custom_minimum_size = _card_size
	size = _card_size
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
	size = _card_size
	pivot_offset = _card_size * 0.5
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
	if drag_allowed.is_valid() and not drag_allowed.call():
		return null
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
	preview_root.custom_minimum_size = _card_size
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
	var lift := _card_size.y * 0.2 if (_hovered or _selected) else 0.0
	offset_transform_position = Vector2(0.0, -lift)
	offset_transform_rotation = 0.0
	offset_transform_scale = Vector2.ONE


func _idle_time_seconds() -> float:
	if _idle_time_source.is_valid():
		return float(_idle_time_source.call())
	return _idle_elapsed_seconds


func _set_card_style() -> void:
	# Rarity is rendered behind the painting, never over its center.
	pass


static var _rarity_frames: Dictionary = {}
static var _rite_settlement_atlas_cache: OriginalAtlas = null


## [SRC: Resources/sprite assets/rite_settlement_icon.asset; index 21 is
##       dot_0.png, the LifeBg/Image/DotText '<sprite=21>' glyph.]
static func _rite_settlement_atlas() -> OriginalAtlas:
	if _rite_settlement_atlas_cache == null:
		_rite_settlement_atlas_cache = OriginalAtlas.load_atlas("res://assets/original/ui/rite_settlement_icon.png")
	return _rite_settlement_atlas_cache


func _rarity_frame_texture() -> Texture2D:
	# [SRC: materials/card/{char,item,sudan}/{stone,copper,silver,gold}.mat
	# _MainTex; CardRenderChar.Init 0x538030 / CardRenderItem.Init.]
	var kind := str(_card.get("type", "item"))
	var silver := int(_card.get("rare", 1)) == 3
	var surface := "card_0" if silver else "card_4"
	if kind == "item":
		surface = "card_2" if silver else "card_3"
	elif kind == "sudan":
		surface = "card" if silver else "card_1"
	return load("res://assets/original/ui/%s.png" % surface) as Texture2D


func _surface_color(foreground: bool = false) -> Color:
	# Authored material _Color, independent of the old UI rarity palette.
	if foreground and int(_card.get("rare", 1)) == 1:
		return Color(0.83137256, 0.7647059, 0.79607844, 1)
	match int(_card.get("rare", 1)):
		2: return Color(0.7048611, 0.8541666, 1, 1)
		3: return Color(0.944445, 0.8506945, 0.798611, 1)
		4: return Color(1, 0.8333333, 0.63888, 1)
		_: return Color(0.6901961, 0.6039216, 0.92156863, 1)


func _face_texture(node_name: String, texture: Texture2D, rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.name = node_name
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.position = rect.position
	image.size = rect.size
	_visual_face.add_child(image)
	return image


func _rebuild() -> void:
	_metal_materials.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	# [SRC: CardController.Init -> GetCardShowPrefab -> CardRender.Init;
	# CardShowChar/Item/Sudan.prefab. Icon occupies the complete card, Title
	# folds top anchor y=-55 and pivot y=0 into top-left (9.5,15).]
	_visual_face = Control.new()
	_visual_face.name = "CardVisualFace"
	_visual_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual_face.size = CARD_SIZE
	_visual_face.scale = _card_size / CARD_SIZE
	add_child(_visual_face)
	var background := _face_texture("RarityFrame", _rarity_frame_texture(), Rect2(Vector2.ZERO, CARD_SIZE))
	background.self_modulate = _surface_color()
	_apply_metal_surface(background)
	var art_texture := _card_art_texture()
	if art_texture != null:
		_face_texture("CardArt", art_texture, Rect2(Vector2.ZERO, CARD_SIZE))
	var title := Label.new()
	title.name = "Title"
	title.text = str(_card.get("name", "?"))
	title.position = Vector2(9.5, 15)
	title.size = Vector2(175, 40)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", preload("res://assets/fonts/HYJieLongTaoHuaYuanW-2.ttf"))
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color.BLACK)
	_fit_card_label(title)
	_visual_face.add_child(title)
	if str(_card.get("type", "")) == "char":
		var tier: String = ["stone", "copper", "silver", "gold"][clampi(int(_card.get("rare", 1)) - 1, 0, 3)]
		var foreground := _face_texture("Foreground", load("res://assets/original/ui/%s_f.png" % tier), Rect2(Vector2.ZERO, CARD_SIZE))
		foreground.self_modulate = _surface_color(true)
		_apply_metal_surface(foreground)
	# [SRC: CardNew/Flash anchors(0.5,0.5) pos(0,0) size(256,512),
	#       sprite=Sprite/card_outline.asset + Resources/materials/CardFlash.mat
	#       (_ENABLEINNEROUTLINE_ON / _INNEROUTLINEOUTLINEONLYTOGGLE_ON,
	#       _InnerOutlineColor 0.882/0.728/0.337). CardNew/Outline is
	#       m_IsActive=0 in the prefab, so it is never drawn. Unity pos (0,0)
	#       with a centre pivot folds into the Godot top-left (-31,-45).]
	_face_texture("Flash", load("res://assets/original/ui/card_outline.png"), Rect2(Vector2(-31, -45), Vector2(256, 512)))
	var flash := _visual_face.get_node("Flash") as TextureRect
	var flash_material := ShaderMaterial.new()
	flash_material.shader = preload("res://ui/card_flash.gdshader")
	flash.material = flash_material
	# [SRC: CardRender.UpdateShowInternal 0x53a4a0: count>1 AND stackable;
	# content/tag.json stackable = 可堆叠. CardShowChar/Sudan use number_bg
	# 80x80 at bottom anchor +50 -> top-left (57,332); CardShowItem uses
	# checkbox_bg 75x78 -> top-left (59.5,332).]
	var tags: Dictionary = _card.get("tag", {})
	var count := int(_card.get("count", 1))
	if count > 1 and int(tags.get("可堆叠", tags.get("stackable", 0))) > 0:
		var item_badge := str(_card.get("type", "item")) == "item"
		var badge_texture := "checkbox_bg" if item_badge else "number_bg"
		var badge_rect := Rect2(59.5, 332, 75, 78) if item_badge else Rect2(57, 332, 80, 80)
		var badge := _face_texture("Stackable", load("res://assets/original/ui/%s.png" % badge_texture), badge_rect)
		badge.add_child(_source_number("Count", str(count), 58.0, Rect2(Vector2.ZERO, badge_rect.size)))
	# [SRC: CardRender.Init / UpdateShowInternal; lifetime = config minus
	# Card.life. CardShow*/LifeBg sits above the card, not in its footer.]
	var lifetime := int(_card.get("card_vanishing", 0))
	if lifetime > 0 or _card.has("remaining_life"):
		var life_bg := _face_texture("LifeBg", load("res://assets/original/ui/bg_green.png"), Rect2(57.5, -45, 98, 45))
		var clock := TextureRect.new()
		clock.texture = load("res://assets/original/ui/rite_round.png")
		clock.position = Vector2(-19, 1.5)
		clock.size = Vector2(38, 42)
		clock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		life_bg.add_child(clock)
		# [SRC: CardShow*/LifeBg/Image/DotText anchors(0,0) of the clock image,
		#       pos(36.8,5.4) pivot centre -> centre (17.8,6.9) in LifeBg space;
		#       text '<sprite=21>' of spriteAsset rite_settlement_icon, whose
		#       character table index 21 is dot_0.png (50x30).]
		var dot := TextureRect.new()
		dot.name = "DotText"
		dot.texture = _rite_settlement_atlas().frame("dot_0.png")
		dot.position = Vector2(-7.2, 23.1)
		dot.size = Vector2(50, 30)
		dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dot.stretch_mode = TextureRect.STRETCH_SCALE
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		life_bg.add_child(dot)
		life_bg.add_child(_source_number(
			"Life",
			str(int(_card.get("remaining_life", lifetime - int(_card.get("life", 0))))),
			63.0,
			Rect2(24, -2.5, 74, 50)
		))


## [SRC: CardShowChar/Stackable/Count and LifeBg/Life both use
##       m_spriteAsset 737d2853a5e0b98488e2cf3c384d60f3 (number_6) with
##       white m_fontColor at fs48 / fs52, so the digits are atlas sprites,
##       not font glyphs. Utils.NumberToSprites 0x3ac420 builds the same
##       left-to-right sprite row.]
func _source_number(node_name: String, value: String, glyph_height: float, rect: Rect2) -> Control:
	var number := preload("res://ui/source_number.gd").new()
	number.name = node_name
	number.glyph_height = glyph_height
	number.text = value
	number.position = rect.position
	number.size = rect.size
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return number

## Original card art extracted from the game assets, keyed by card id.
func _card_art_texture() -> Texture2D:
	# [SRC: CardExtensions.GetPic 0x3803b0, resource SingleOrListValues;
	# CardRender.InitImage 0x5390f0. Config id is not the artwork id.]
	var resource = _card.get("resource", "cards/%d" % int(_card.get("id", 0)))
	if resource is Array:
		var tags: Dictionary = _card.get("tag", {})
		resource = resource[clampi(int(tags.get("pic", 0)), 0, resource.size() - 1)] if not resource.is_empty() else ""
	var art_path := "res://assets/original/%s.png" % str(resource)
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

## [SRC: materials/card/{kind}/{tier}.mat _DetailAlbedoMap (UV0, _UVSec: 0).
## Stone has no detail map; the _DETAIL_MULX2 keyword is only on the other
## tiers. The second value is the map's measured mean RGB, used to keep the
## calibrated scene light independent of the detail texture's average.]
const CARD_DETAIL_MAPS := {
	"char": ["", "card_d_1", "card_e_0", "card_d_1"],
	"item": ["", "card_d_6", "card_d_2", "card_d_6"],
	"sudan": ["", "card_d", "card_d_3", "card_d"],
}
const CARD_DETAIL_MEANS := {
	"card_d": Vector3(0.52, 0.54, 0.32),
	"card_d_1": Vector3(0.52, 0.54, 0.32),
	"card_d_6": Vector3(0.52, 0.54, 0.32),
	"card_e_0": Vector3(0.53, 0.63, 0.70),
	"card_d_2": Vector3(0.72, 0.77, 0.80),
	"card_d_3": Vector3(0.64, 0.71, 0.75),
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
	w._card_size = size_for_card(card)
	w.custom_minimum_size = w._card_size
	w.card_id = int(card.get("id", 0))
	w.card_uid = int(card.get("instance_uid", 0))
	w.drag_source = source
	w.drag_slot = slot_key
	w.drag_rite_uid = rite_uid
	w.set_card(card)
	return w
