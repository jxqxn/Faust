extends Control

# [SRC: ConfirmController.Show 0x53fc30 / Done 0x53fb70; dump.cs:318365;
# ConfirmNew.prefab: layout groups + ContentSizeFitter, not screenshot height.
# Godot glyph metrics remain distinct from TMP preferred-size metrics.]
signal confirmed
signal canceled
var dialog_text := ""
var _done := false
const UI = preload("res://ui/source_text_style.gd")

static func image(parent: Control, node_name: String, asset: String, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.name = node_name
	node.texture = load("res://assets/original/ui/" + asset + ".png")
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Control, node_name: String, asset: String, rect: Rect2, source_confirm_tint := true) -> Button:
	var node := Button.new()
	node.name = node_name
	node.position = rect.position
	node.size = rect.size
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		node.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	parent.add_child(node)
	var art := image(node, "Image", asset, Rect2(Vector2.ZERO, rect.size))
	if source_confirm_tint:
		# Shared source ColorBlock; callers with Explicit navigation override focus.
		node.focus_mode = Control.FOCUS_NONE
		var tint := preload("res://ui/source_confirm_tint.gd").new()
		tint.name = "SourceColorTint"
		tint.button = node
		tint.graphic = art
		node.add_child(tint)
	return node

static func panel(parent: Control, rect: Rect2) -> NinePatchRect:
	var node := NinePatchRect.new()
	node.name = "PromptBG"
	node.texture = preload("res://assets/original/ui/prompt_bg.png")
	node.position = rect.position
	node.size = rect.size
	# Sprite borders in texture pixels; draw at the source PPU ratio.
	node.patch_margin_left = 193
	node.patch_margin_right = 201
	node.patch_margin_top = 233
	node.patch_margin_bottom = 248
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func full_background(parent: Control, rect: Rect2) -> NinePatchRect:
	# [SRC: PromptControllerBase.Awake 0x589430 loads full/item_bg below the
	# invisible prompt_bg_mask_2 Mask.]
	var full := NinePatchRect.new()
	full.name = "Full"
	full.texture = preload("res://assets/original/ui/prompt_bg_mask_2.png")
	full.position = rect.position
	full.size = rect.size
	full.patch_margin_left = 284
	full.patch_margin_right = 248
	full.patch_margin_top = 255
	full.patch_margin_bottom = 234
	full.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	full.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(full)
	var native_size := Vector2(2048, 1560) * (100.0 / 74.963394)
	var interior := image(full, "RuntimeBackground", "prompt_full_item_bg", Rect2(-native_size * 0.5, rect.size + native_size))
	interior.stretch_mode = TextureRect.STRETCH_SCALE
	return full

func _ready() -> void:
	size = Vector2(3840, 2160)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var mask := ColorRect.new()
	mask.size = size
	mask.color = Color(0, 0, 0, 0.55)
	add_child(mask)
	var body := Label.new()
	body.name = "Content"
	body.text = dialog_text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.apply(body, "@MAIN_BODY")
	body.add_theme_color_override("font_color", Color("d7ca96"))
	body.size = Vector2(2000, 0)
	var height := body.get_minimum_size().y + 450.0
	var bg := panel(self, Rect2((size - Vector2(2705, height)) / 2, Vector2(2705, height)))
	full_background(bg, Rect2(38, 52, 2629, height - 132))
	body.position = Vector2(352.5, 200)
	bg.add_child(body)
	image(bg, "Border", "decorate", Rect2(2454, height - 325.5, 250, 323))
	# Operations: right padding120, gap60; Cancel then Confirm.
	var cancel := button(bg, "Cancel", "rite_op_cancel", Rect2(1817, height - 79, 168, 158), true)
	var confirm := button(bg, "Confirm", "rite_op_confirm", Rect2(2045, height - 79, 325, 158), true)
	cancel.pressed.connect(_finish.bind(false))
	confirm.pressed.connect(_finish.bind(true))
	_layout_content()

# [SRC: ConfirmNew OptionBG pad L200/R100/T150/B200, spacing100;
# reverse arrangement puts ContentGroup before active empty IconGroup (width0);
# ContentGroup preferred width2000,
# two active zero-height spacers around Content, spacing50. ConfirmController
# Show 0x53fc30 forces layout after assigning translated text. No minimum560.]
func _process(_delta: float) -> void:
	_layout_content()

func _layout_content() -> void:
	var bg := get_node_or_null("PromptBG") as Control
	if bg == null:
		return
	var body := bg.get_node("Content") as Label
	body.text = dialog_text
	var content_height := body.get_minimum_size().y
	var height := 150.0 + 50.0 + content_height + 50.0 + 200.0
	bg.size.y = height
	bg.position = (size - bg.size) * 0.5
	body.size.y = content_height
	var full := bg.get_node("Full") as Control
	full.size.y = height - 132.0
	full.get_node("RuntimeBackground").size.y = full.size.y + 1560.0 * (100.0 / 74.963394)
	bg.get_node("Border").position.y = height - 325.5
	for node_name in ["Cancel", "Confirm"]:
		bg.get_node(NodePath(node_name)).position.y = height - 79.0

func popup_centered() -> void:
	show()

func _finish(accepted: bool) -> void:
	if _done:
		return
	_done = true
	hide()
	if accepted:
		confirmed.emit()
	else:
		canceled.emit()
