extends Control
## OpCard.prefab Pop hierarchy, pop_bg Sprite border (73,31,193,17).
## [SRC: OpCardNewController.ShowPop 0x574960 / Update 0x574af0;
## TextTranslate @RITE_SETTLEMENT_POP_TEXT; variable.pop_show_time.]
const Styles = preload("res://ui/source_text_style.gd")
const RichText = preload("res://ui/source_rich_text.gd")
var label: RichTextLabel
var remaining := 0.0
var _completed := false
signal finished()
signal progressed(seconds: float)

func setup(text: String, seconds: float, style_key: String = "@RITE_SETTLEMENT_POP_TEXT") -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	remaining = seconds
	var tail := TextureRect.new()
	tail.texture = load("res://assets/original/ui/pop_from.png")
	tail.position = Vector2(32, -55.1)
	tail.size = Vector2(84, 64)
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tail)
	label = RichTextLabel.new()
	label.name = "Text"
	label.bbcode_enabled = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("default_color", Color.WHITE)
	add_child(label)
	Styles.apply(label, style_key)
	RichText.set_label_text(label, text)
	# ContentSizeFitter preferred width/height: measure the actual shaped content.
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size = Vector2(1, 1)
	label.size = Vector2(label.get_content_width(), label.get_content_height())
	label.position = Vector2(77.596985 - label.size.x * 0.2, -64.39502 - label.size.y)
	var bg := NinePatchRect.new()
	bg.name = "Background"
	bg.texture = load("res://assets/original/ui/pop_bg.png")
	bg.patch_margin_left = 73
	bg.patch_margin_bottom = 31
	bg.patch_margin_right = 193
	bg.patch_margin_top = 17
	bg.position = label.position + Vector2(-40, -28)
	bg.size = label.size + Vector2(100, 80)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func _process(delta: float) -> void:
	if _completed or not is_visible_in_tree():
		return
	# Source keeps the pop at exact equality; timeout is elapsed > duration.
	# [SRC: OpCardNewController.Update 0x574af0; independent
	# CardController.Update 0x52c890 uses the same strict comparison.]
	remaining -= delta
	progressed.emit(maxf(0.0, remaining))
	if remaining < 0.0:
		advance()

func advance() -> void:
	if _completed:
		return
	_completed = true
	remaining = 0.0
	progressed.emit(remaining)
	hide()
	finished.emit()


## PopJumpActionBlocker subscribes to InputAction.canceled (release), not
## performed (press). UI/PopJump binds Space, Enter and left mouse on PC.
## [SRC: PopJumpActionBlocker.OnActive 0x5829d0 / OnJump 0x582d70;
## Resources/UI_PopJump.asset + InputActions.asset action 8fce6225.]
func _input(event: InputEvent) -> void:
	if _completed or not is_visible_in_tree():
		return
	var matches_jump := false
	if event is InputEventMouseButton:
		matches_jump = event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventKey:
		matches_jump = event.keycode in [KEY_SPACE, KEY_ENTER]
	elif event is InputEventJoypadButton:
		matches_jump = event.button_index == JOY_BUTTON_A
	if matches_jump:
		get_viewport().set_input_as_handled()
		if not event.is_pressed():
			call_deferred("advance")
