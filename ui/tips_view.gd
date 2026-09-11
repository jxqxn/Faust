extends Control

## [SRC: TipsHolder.c GetTipText/OnPointerEnter/OnPointerExit/OnDisable;
## SlotTipsController.c Update/SetPositionInternal; Tips.prefab.]
signal tips_shown(source_id: String)
signal tips_hidden(source_id: String)
const SourceTips = preload("res://ui/source_tips.gd")
const SourceTextStyle = preload("res://ui/source_text_style.gd")
var panel: Control
var right: Control
var text_label: Label
var border: NinePatchRect
var _background: TextureRect
var _view_size := SourceTips.DESIGN
var _screen_size := SourceTips.DESIGN
var _source_id := ""
var _active_need_width := 0.0
var _pointer := Vector2.ZERO
var _target: Control
var _holders: Dictionary = {}

func _init() -> void:
	name = "SourceTips"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 90
	visible = false
	panel = Control.new()
	panel.name = "Tips"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size = SourceTips.PANEL_SIZE
	add_child(panel)
	right = Control.new()
	right.name = "Right"
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(right)
	_background = TextureRect.new()
	_background.name = "Background"
	_background.texture = load("res://assets/original/ui/prompt_2_bg.png")
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(_background)
	text_label = Label.new()
	text_label.name = "RightText"
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.add_theme_color_override("font_color", SourceTips.TEXT_COLOR)
	SourceTextStyle.apply(text_label, SourceTips.TEXT_STYLE_KEY)
	right.add_child(text_label)
	border = NinePatchRect.new()
	border.name = "Border"
	border.texture = load("res://assets/original/ui/prompt_2_border.png")
	border.patch_margin_top = 23
	border.patch_margin_bottom = 26
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(border)
	_layout_band(false)

func resolve_text(db, tips_id: String, fallback: String = "") -> String:
	# Source precedence is TipsId before literal; unknown keys echo through.
	if tips_id.is_empty():
		return fallback
	return str(db.translate(tips_id)) if db != null else tips_id

func has_text(db, tips_id: String) -> bool:
	return not resolve_text(db, tips_id).is_empty()

func attach(db, target: Control, tips_id: String, fallback: String = "", need_width: float = 0.0) -> void:
	if target == null:
		return
	var id := target.get_instance_id()
	_holders[id] = [db, tips_id, fallback, need_width]
	target.set_meta("source_tips_id", tips_id)
	target.set_meta("source_tips_need_width", need_width)
	var enter := _enter.bind(target)
	if not target.mouse_entered.is_connected(enter):
		target.mouse_entered.connect(enter)
		target.mouse_exited.connect(_leave.bind(target))
		target.visibility_changed.connect(_target_visibility.bind(target))
		target.tree_exiting.connect(_remove_holder.bind(target))

func _enter(target: Control) -> void:
	var row: Array = _holders[target.get_instance_id()]
	show_for(row[0], row[1], _pointer, row[2], row[3])
	_target = target

func _leave(target: Control) -> void:
	if _target == target:
		hide_tips()

func _target_visibility(target: Control) -> void:
	if not target.is_visible_in_tree():
		_leave(target)

func _remove_holder(target: Control) -> void:
	_leave(target)
	_holders.erase(target.get_instance_id())

func show_for(db, tips_id: String, pointer: Vector2, fallback: String = "", need_width: float = 0.0) -> void:
	_target = null
	text_label.text = resolve_text(db, tips_id, fallback)
	if text_label.text.is_empty():
		hide_tips()
		return
	_source_id = tips_id
	_active_need_width = need_width
	visible = true
	move_to(pointer)
	tips_shown.emit(tips_id)

func _layout_band(left: bool) -> void:
	var width := SourceTips.band_width(_active_need_width, _screen_size.x)
	text_label.position = Vector2.ONE * SourceTips.PADDING
	var font := text_label.get_theme_font("font")
	var font_size := text_label.get_theme_font_size("font_size")
	var preferred := 0.0
	for line in text_label.text.split("\n"):
		preferred = maxf(preferred, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	text_label.size = Vector2(maxf(1, minf(preferred, width - 120)), 0)
	if left:
		text_label.position.x = width - 60.0 - text_label.size.x
	var height := text_label.get_minimum_size().y + 120.0
	text_label.size.y = height - 120.0
	right.size = Vector2(width, height)
	# Root pivot (0.5,1) is TOP centre in Unity. Right is anchored at the
	# root centre, pivot (0,0.5). Left rotates Y=180; its text rotates back.
	right.position = Vector2(450.0 - (width if left else 0.0), 82.0 - height * 0.5)
	_background.size = right.size
	_background.flip_h = left
	border.size = Vector2(13, height)
	border.scale.x = -1.0 if left else 1.0
	border.position = Vector2(width + 17 if left else -17, 0)

func band_screen_width() -> float:
	return right.size.x * panel.scale.x

func move_to(pointer: Vector2) -> void:
	if not visible:
		return
	_layout_band(pointer.x / _view_size.x > SourceTips.HORIZONTAL_FLIP_THRESHOLD)
	panel.position = SourceTips.panel_origin(pointer, _view_size, right.size)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_pointer = get_global_transform_with_canvas().affine_inverse() * event.position

func _process(_delta: float) -> void:
	if visible and is_instance_valid(_target):
		move_to(_pointer)

func hide_tips() -> void:
	_target = null
	if not visible:
		return
	visible = false
	text_label.text = ""
	var previous := _source_id
	_source_id = ""
	tips_hidden.emit(previous)

func source_id() -> String:
	return _source_id

func apply_source_layout(view_size: Vector2, screen_size: Vector2 = Vector2.ZERO) -> void:
	_view_size = view_size
	var window := get_window()
	_screen_size = screen_size if screen_size != Vector2.ZERO else (Vector2(window.size) if window != null else view_size)
	panel.scale = view_size / SourceTips.DESIGN
	if visible:
		move_to(_pointer)
