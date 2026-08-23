extends Control

## Event prompt — 1:1 of Resources/prefab/PromptNew.prefab (GameScene MainUI/Prompt).
##
## [SRC: docs/ui_layout/PromptNew.md truth table; PromptController.Show
##   0x58a020 (ProcessPlaceholders -> set_Text -> ForceRebuildLayoutImmediate);
##   PromptControllerBase.ShowInternal 0x589890 (Full = config `full` sprite,
##   IconGroup 3 slots via PromptIconController.SetIcon);
##   OptionNewItem.prefab (option row: Text fs40 centred, row bg
##   option_item_bg, hover option_item_highlight, root Button + Toggle).]
##
## User-supplied original-game screenshots (2026-08-23, 苏丹雅兴 3-选项 /
## 贵族品级 4-选项事件, 16:9 全窗) cross-check the structure: title/body
## paragraph, full-width option rows, right-side portrait, bottom confirm.
##
## OptionBG height is a runtime layout-group computation (ForceRebuild
## LayoutImmediate); statically unresolvable -> 🟡 constant from the
## screenshot ratio + truth table (wall-clock measured 2026-08-23), to be
## replaced in place once a full-window original capture has been measured.

signal choice_clicked(choice_key: String, choice_value: Variant)
signal confirm_clicked

const DESIGN_SIZE := Vector2(3840, 2160)
const SOURCE_ART := "res://assets/original/ui/"

# OptionBG: authored width 2705; height = runtime layout -> 🟡 960
# (screenshot measure: panel height/width ≈ 0.355 => 2705 * 0.355 ≈ 960).
const OPTION_BG_SIZE := Vector2(2705, 960)
# Full mask: stretch offsets left 38 / right -38 / bottom 80 / top -52
# (anchors (0,0)-(1,1), pos (0,14), sizeDelta (-76,-132)).
const FULL_RECT := Rect2(38, -52, 2629, 1092)
# Border: decorate 250x323, anchors (1,0), pos (-126,164), pivot (0.5,0.5).
const BORDER_RECT := Rect2(2454, 634.5, 250, 323)
# Confirm: rite_op_confirm 325x158, anchors (1,0), pos (-483,73).
const CONFIRM_RECT := Rect2(2059.5, 808, 325, 158)
# Body text: screenshot-derived insets (text starts ~280 in from the panel
# left, ~150 down, spans ~1820 wide) — 🟡 until the runtime rect is
# measurable; the authored Content row is only a one-line sample.
const TEXT_RECT := Rect2(280, 150, 1820, 300)
# Option rows: full-width rows under the ContentGroup (vertical layout
# spacing 50); row height 100 and stride 150 are screenshot-derived 🟡.
const OPTION_ROW_SIZE := Vector2(2200, 100)
const OPTION_ROW_STRIDE := 150.0
const OPTION_ROW_Y0 := 320.0
# Portrait: screenshot-derived 🟡 (right side, bottom-anchored block).
const PORTRAIT_RECT := Rect2(2147, 440, 400, 500)

var _canvas: Control
var _panel: Control
var _title: Label
var _body: RichTextLabel
var _options_box: Control
var _confirm_button: Button
var _portrait: TextureRect
var _on_choice_key_value: Callable

## [SRC: PromptController.Show — the prompt is the game's choice surface;
## the clone keeps its op-queue semantics and only swaps presentation.]
func show_prompt(display: Dictionary, on_choice: Callable) -> void:
	clear_prompt()
	_on_choice_key_value = on_choice
	var text := str(display.get("text", ""))
	if text.strip_edges().is_empty():
		text = str(display.get("title", ""))
	if _body != null:
		_body.text = text
	if _title != null:
		_title.text = str(display.get("title", ""))
	var choices: Dictionary = display.get("choices", {})
	if choices.is_empty():
		_build_confirm()
	else:
		_build_choices(choices)
	var portrait: Texture2D = display.get("icon", null)
	if portrait != null and _portrait != null:
		_portrait.texture = portrait


func clear_prompt() -> void:
	if _options_box != null and is_instance_valid(_options_box):
		for child in _options_box.get_children():
			child.queue_free()
	if _confirm_button != null and is_instance_valid(_confirm_button):
		_confirm_button.queue_free()
		_confirm_button = null
	if _body != null:
		_body.text = ""
	if _portrait != null:
		_portrait.texture = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_canvas()
	resized.connect(_layout_canvas)
	call_deferred("_layout_canvas")


func _build_canvas() -> void:
	_canvas = Control.new()
	_canvas.name = "PromptNewCanvas"
	_canvas.size = DESIGN_SIZE
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)

	_panel = Control.new()
	_panel.name = "EventPromptPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.position = Vector2((DESIGN_SIZE.x - OPTION_BG_SIZE.x) * 0.5, (DESIGN_SIZE.y - OPTION_BG_SIZE.y) * 0.5)
	_panel.size = OPTION_BG_SIZE
	_canvas.add_child(_panel)

	# [SRC: OptionBG sprite prompt_bg (nine-slice parchment) + Full
	# prompt_bg_mask_2 inner mask area]
	var bg := _texture_rect("prompt_bg.png", OPTION_BG_SIZE, float(0))
	bg.name = "PromptBG"
	_panel.add_child(bg)
	var full := _texture_rect("prompt_bg_mask_2.png", FULL_RECT.size, float(0))
	full.name = "Full"
	full.position = FULL_RECT.position
	_panel.add_child(full)

	# [SRC: user screenshots — the prompt carries an event title strip above
	# the body; the authored top-notch strip lives outside OptionBG, so the
	# title node stays a screenshot-derived placeholder for now (🟡).]
	_title = Label.new()
	_title.name = "EventPromptTitle"
	_title.position = Vector2(280, 80)
	_title.size = Vector2(1820, 64)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 38)
	_title.add_theme_color_override("font_color", Color("#e6d7a8"))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_title)

	_body = RichTextLabel.new()
	_body.name = "EventPromptBody"
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.scroll_active = true
	_body.position = TEXT_RECT.position
	_body.size = TEXT_RECT.size
	_body.custom_minimum_size = TEXT_RECT.size
	_body.add_theme_font_size_override("font_size", 40)
	_body.add_theme_color_override("default_color", Color("#eee2c4"))
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_body)

	_options_box = Control.new()
	_options_box.name = "OptionGroup"
	_options_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_options_box)

	var border := _texture_rect("decorate.png", BORDER_RECT.size, float(0))
	border.name = "Border"
	border.position = BORDER_RECT.position
	_panel.add_child(border)

	_portrait = TextureRect.new()
	_portrait.name = "PromptPortrait"
	_portrait.position = PORTRAIT_RECT.position
	_portrait.size = PORTRAIT_RECT.size
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_portrait)


func _build_choices(choices: Dictionary) -> void:
	var index := 0
	for key in choices.keys():
		var entry = choices[key]
		var choice_text := str(entry.get("text", key)) if entry is Dictionary and entry.has("value") else str(entry)
		var choice_value: Variant = entry.get("value") if entry is Dictionary and entry.has("value") else entry
		var row := Button.new()
		row.text = choice_text
		row.name = "EventPromptChoiceButton"
		row.position = Vector2(
			(OPTION_BG_SIZE.x - OPTION_ROW_SIZE.x) * 0.5,
			OPTION_ROW_Y0 + float(index) * OPTION_ROW_STRIDE
		)
		row.size = OPTION_ROW_SIZE
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override("font_size", 40)
		row.add_theme_color_override("font_color", Color("#dccf9c"))
		row.add_theme_color_override("font_hover_color", Color("#fff0b6"))
		row.add_theme_stylebox_override("normal", _row_style("option_item_bg.png"))
		row.add_theme_stylebox_override("hover", _row_style("option_item_highlight.png"))
		row.add_theme_stylebox_override("pressed", _row_style("option_item_highlight.png"))
		row.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		row.add_theme_stylebox_override("disabled", _row_style("option_item_bg.png"))
		row.pressed.connect(_emit_choice.bind(str(key), choice_value))
		_options_box.add_child(row)
		index += 1


func _build_confirm() -> void:
	_confirm_button = Button.new()
	_confirm_button.name = "EventPromptContinueButton"
	_confirm_button.text = "继续"
	_confirm_button.position = CONFIRM_RECT.position
	_confirm_button.size = CONFIRM_RECT.size
	_confirm_button.add_theme_font_size_override("font_size", 30)
	_confirm_button.add_theme_color_override("font_color", Color("#2b1d12"))
	_confirm_button.add_theme_color_override("font_hover_color", Color("#681f1b"))
	var confirm_style := _row_style("rite_op_confirm.png")
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		_confirm_button.add_theme_stylebox_override(state, confirm_style)
	_confirm_button.pressed.connect(func(): confirm_clicked.emit())
	_panel.add_child(_confirm_button)


func _emit_choice(choice_key: String, choice_value: Variant) -> void:
	choice_clicked.emit(choice_key, choice_value)


func _row_style(file_name: String, texture_margin := 20.0) -> StyleBox:
	var path := SOURCE_ART + file_name
	if ResourceLoader.exists(path):
		var style := StyleBoxTexture.new()
		style.texture = load(path) as Texture2D
		style.texture_margin_left = texture_margin
		style.texture_margin_right = texture_margin
		style.texture_margin_top = 10
		style.texture_margin_bottom = 10
		style.content_margin_left = 24
		style.content_margin_right = 24
		return style
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0.12, 0.10, 0.07, 0.86)
	flat.border_color = Color(0.86, 0.83, 0.62, 0.55)
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(6)
	return flat


func _texture_rect(file_name: String, sprite_size: Vector2, _scale: float) -> TextureRect:
	var rect := TextureRect.new()
	var path := SOURCE_ART + file_name
	if ResourceLoader.exists(path):
		rect.texture = load(path) as Texture2D
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = sprite_size
	rect.custom_minimum_size = sprite_size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Scale the fixed 3840x2160 source canvas onto the screen (same convention
## as the other migrated overlays).
func apply_source_layout(view_size: Vector2) -> void:
	if _canvas == null:
		return
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		var parent_control := get_parent() as Control
		if parent_control != null:
			view_size = parent_control.size
	_canvas.scale = Vector2(view_size.x / DESIGN_SIZE.x, view_size.y / DESIGN_SIZE.y)


func _layout_canvas() -> void:
	apply_source_layout(size)
