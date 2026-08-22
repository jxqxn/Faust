extends Control
class_name ChangeNameView
## Source-backed rename prompt (卡牌改名提示浮层).
## Geometry is a direct replay of docs/ui_layout/PromptChangeName.md
## (Resources/prefab/PromptChangeName.prefab) in the 3840x2160 design space.
## [SRC: PromptChangeNameController.c — IsValidName 0x584de0 (1..20 chars),
## OnNameSubmit/OnConfirm/DoClose; ui.json PROMPT_CHANGE_NAME_TITLE/
## _INPUT_PLACEHOLDER; textstyle @CARD_INFO_* sizes for the old host text]
## 🟡 registered: PromptBG height is authored as ContentSizeFitter
## (VerticalFit.PreferredSize) and cannot be resolved statically from the
## corpus; the host uses 220px and keeps the authored anchor math for every
## child, so a later runtime sample can replace the constant without touching
## the child rects.

signal submitted(text_value: String)
signal cancelled

const DESIGN_SPACE := Vector2(3840, 2160)
const SOURCE_ART := "res://assets/original/ui/"
const BAR_SIZE := Vector2(2534.4, 220.0)
const INPUT_SIZE := Vector2(826, 90)
const MAX_NAME_LENGTH := 20


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(_apply_layout)
	_build()
	_apply_layout()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var source := Control.new()
	source.name = "ChangeNameCanvas"
	source.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(source)

	# [SRC: PromptBG 2534.4 x (fitter v=2) centred on the canvas, prompt_bg art]
	var bar := Control.new()
	bar.name = "PromptBG"
	bar.position = (DESIGN_SPACE - BAR_SIZE) * 0.5
	bar.size = BAR_SIZE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	source.add_child(bar)
	if ResourceLoader.exists(SOURCE_ART + "prompt_bg.png"):
		var bg := TextureRect.new()
		bg.texture = load(SOURCE_ART + "prompt_bg.png") as Texture2D
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.position = Vector2.ZERO
		bg.size = BAR_SIZE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.name = "PromptBGBG"
		bar.add_child(bg)

	# [SRC: PromptBG/Content — text fs40 at (0,0) pivot (0.5,0);
	# PromptChangeNameController.Show fills it with the rename title/page]
	var content_rect := _unity_rect(BAR_SIZE, Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0.5, 0))
	var text := RichTextLabel.new()
	text.name = "PromptText"
	text.position = content_rect.position
	text.size = Vector2(1200, 60)
	text.bbcode_enabled = true
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.fit_content = false
	text.scroll_active = false
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("normal_font_size", 40)
	text.add_theme_color_override("default_color", Color("#f2e3c0"))
	text.text = "修改名称"
	bar.add_child(text)

	# [SRC: Content/InputField (TMP) 826x90 at (0,-36) pivot (0.5,1),
	# input_bg art; placeholder "请输入名称" fs50. The authored rect is kept on
	# a plain wrapper Control because a LineEdit clamps to its font minimum.]
	var input_rect := _unity_rect(BAR_SIZE, Vector2(0.5, 0), Vector2(0.5, 0), Vector2(0, -36), INPUT_SIZE, Vector2(0.5, 1))
	var input_host := Control.new()
	input_host.name = "InputFieldHost"
	input_host.position = input_rect.position
	input_host.size = input_rect.size
	input_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(input_host)
	var input := LineEdit.new()
	input.name = "CardRenameInput"
	input.position = Vector2.ZERO
	input.size = input_rect.size
	input.max_length = MAX_NAME_LENGTH
	input.placeholder_text = "请输入名称"
	input.add_theme_font_size_override("font_size", 50)
	input.add_theme_color_override("font_color", Color("#2b1d12"))
	input.add_theme_color_override("font_placeholder_color", Color(0.5, 0.42, 0.3, 0.8))
	if ResourceLoader.exists(SOURCE_ART + "input_bg.png"):
		var input_style := StyleBoxTexture.new()
		input_style.texture = load(SOURCE_ART + "input_bg.png") as Texture2D
		input_style.texture_margin_left = 30
		input_style.texture_margin_right = 30
		input_style.texture_margin_top = 30
		input_style.texture_margin_bottom = 30
		input_style.content_margin_left = 40
		input_style.content_margin_right = 40
		input_style.content_margin_top = 20
		input_style.content_margin_bottom = 20
		for state_name in ["normal", "focus", "read_only"]:
			input.add_theme_stylebox_override(state_name, input_style)
	input.text_submitted.connect(func(value: String): _confirm(value))
	input_host.add_child(input)

	# [SRC: Content/Content Invalid Prompt 324x48 at (0,-227) — validation error row]
	var error_rect := _unity_rect(BAR_SIZE, Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector2(0, -227), Vector2(324, 48), Vector2(0.5, 0))
	var error := Label.new()
	error.name = "ContentInvalidPrompt"
	error.position = error_rect.position
	error.size = error_rect.size
	error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error.add_theme_font_size_override("font_size", 24)
	error.add_theme_color_override("font_color", Color("#e06a4e"))
	error.text = ""
	error.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(error)

	# [SRC: PromptBG/Icon — card art 471x1028 at (1,0) (-274,66) pivot (0.5,0)]
	var icon_rect := _unity_rect(BAR_SIZE, Vector2(1, 0), Vector2(1, 0), Vector2(-274, 66), Vector2(471, 1028), Vector2(0.5, 0))
	var art := TextureRect.new()
	art.name = "Icon"
	art.position = icon_rect.position
	art.size = icon_rect.size
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(art)

	# [SRC: PromptBG/Border — decorate 236x324 at (-120.5,162.25)]
	var border_rect := _unity_rect(BAR_SIZE, Vector2(1, 0), Vector2(1, 0), Vector2(-120.5, 162.25), Vector2(236, 324), Vector2(0.5, 0.5))
	var border := TextureRect.new()
	border.name = "Border"
	if ResourceLoader.exists(SOURCE_ART + "decorate.png"):
		border.texture = load(SOURCE_ART + "decorate.png") as Texture2D
	border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	border.stretch_mode = TextureRect.STRETCH_SCALE
	border.position = border_rect.position
	border.size = border_rect.size
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(border)

	# [SRC: PromptBG/Confirm — rite_op_confirm 325x158 at (-447.7,79)]
	var confirm_rect := _unity_rect(BAR_SIZE, Vector2(1, 0), Vector2(1, 0), Vector2(-447.7, 79), Vector2(325, 158), Vector2(0.5, 0.5))
	var confirm := _stamp_button("CardRenameConfirmButton", confirm_rect, "rite_op_confirm.png")
	confirm.pressed.connect(func(): _confirm(input.text))
	bar.add_child(confirm)

	# [SRC: PromptBG/Cancel — rite_op_cancel 168x158 at (-705,79) + "取消" fs24]
	var cancel_rect := _unity_rect(BAR_SIZE, Vector2(1, 0), Vector2(1, 0), Vector2(-705, 79), Vector2(168, 158), Vector2(0.5, 0.5))
	var cancel := _stamp_button("Cancel", cancel_rect, "rite_op_cancel.png", false)
	var cancel_text := Label.new()
	cancel_text.name = "CancelText"
	cancel_text.text = "取消"
	cancel_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cancel_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cancel_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	cancel_text.add_theme_font_size_override("font_size", 24)
	cancel_text.add_theme_color_override("font_color", Color("#2b1d12"))
	cancel_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cancel.add_child(cancel_text)
	cancel.pressed.connect(func(): cancelled.emit())
	bar.add_child(cancel)


func _stamp_button(node_name: String, rect: Rect2, texture_name: String, with_icon: bool = true) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = rect.position
	button.size = rect.size
	button.flat = true
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var style := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, style)
	if with_icon and ResourceLoader.exists(SOURCE_ART + texture_name):
		var icon := TextureRect.new()
		icon.texture = load(SOURCE_ART + texture_name) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.position = Vector2.ZERO
		icon.size = rect.size
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
	return button


## [SRC: IsValidName 0x584de0 — String.IsNullOrEmpty(name) false AND
## 0 < name.Length < 0x15 (1..20 chars).]
func _confirm(text_value: String) -> void:
	var value := text_value.strip_edges()
	if value.is_empty() or value.length() > MAX_NAME_LENGTH:
		var error: Label = _find_node_by_name(self, "ContentInvalidPrompt")
		if error != null:
			error.text = "名称需为 1-%d 个字符" % MAX_NAME_LENGTH
		return
	submitted.emit(value)


func show_card_art(texture: Texture2D) -> void:
	var art := _find_node_by_name(self, "Icon") as TextureRect
	if art != null and texture != null:
		art.texture = texture


func initial_text(value: String) -> void:
	var input := _find_node_by_name(self, "CardRenameInput") as LineEdit
	if input != null:
		input.text = value
		input.call_deferred("grab_focus")
		input.call_deferred("select_all")
	input_selected()


func input_selected() -> void:
	var input := _find_node_by_name(self, "CardRenameInput") as LineEdit
	if input != null:
		input.call_deferred("grab_focus")
		input.call_deferred("select_all")


func close_view() -> void:
	for child in get_children():
		child.queue_free()


func _apply_layout() -> void:
	var view_size := size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		var parent_control := get_parent() as Control
		if parent_control != null:
			view_size = parent_control.size
	for child in get_children():
		if child.name == "ChangeNameCanvas":
			child.position = Vector2.ZERO
			child.size = DESIGN_SPACE
			child.scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


## Unity RectTransform -> Godot Rect2 (see ui/card_info_view.gd;_unity_rect).
static func _unity_rect(
	parent_size: Vector2,
	anchor_min: Vector2,
	anchor_max: Vector2,
	pos: Vector2,
	size_delta: Vector2,
	pivot: Vector2
) -> Rect2:
	var unity_min := Vector2(
		anchor_min.x * parent_size.x + pos.x - pivot.x * size_delta.x,
		anchor_min.y * parent_size.y + pos.y - pivot.y * size_delta.y
	)
	var unity_max := Vector2(
		anchor_max.x * parent_size.x + pos.x + (1.0 - pivot.x) * size_delta.x,
		anchor_max.y * parent_size.y + pos.y + (1.0 - pivot.y) * size_delta.y
	)
	return Rect2(unity_min.x, parent_size.y - unity_max.y, unity_max.x - unity_min.x, unity_max.y - unity_min.y)


func _find_node_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target)
		if found != null:
			return found
	return null
