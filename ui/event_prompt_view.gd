extends Control

## Shared PromptNew / OptionNew surface. Authored layout groups allocate
## min/preferred/flexible space; image slots retain source native sizes.
## [SRC: PromptController.Show 0x58a020 / OptionController.Show 0x576b50;
## PromptControllerBase.ShowInternal 0x589890; original prefabs.]
## Godot/TMP glyph metrics and built-in UI sprite styling remain distinct.

signal choice_clicked(choice_key: String, choice_value: Variant)
signal confirm_clicked

const DESIGN_SIZE := Vector2(3840, 2160)
const SOURCE_ART := "res://assets/original/ui/"
const SourceText = preload("res://ui/source_text_style.gd")
const SourceRichText = preload("res://ui/source_rich_text.gd")
const SourceAxis = preload("res://ui/source_layout_axis.gd")
const MAX_BODY_HEIGHT := 1300.0
const MAX_OPTION_BODY_HEIGHT := 1100.0
const OPTION_GAP := 20.0

# Authored rects are seeds; _layout_content resolves preferred-size dimensions.
const OPTION_BG_SIZE := Vector2(2705, 0)
const FULL_RECT := Rect2(38, 52, 2629, 0)
const BORDER_RECT := Rect2(2454, 0, 250, 323)
const CONFIRM_RECT := Rect2(2059.5, 0, 325, 158)
const TEXT_RECT := Rect2(0, 0, 2000, 0)
# Image ILayoutElement: option_item_bg 1424x112, PPU100, Canvas reference100.
const OPTION_ROW_SIZE := Vector2(2000, 112)
const OPTION_ROW_STRIDE := 132.0
const OPTION_ROW_Y0 := 0.0
const PORTRAIT_RECT := Rect2(0, 0, 0, 0)

var _canvas: Control
var _panel: Control
var _body: RichTextLabel
var _options_box: Control
var _confirm_button: Button
var _portrait: TextureRect
var _icon_slots: Array[Control] = []
var _full_image: TextureRect
var _choice_group: ButtonGroup
var _selected_key := ""
var _selected_value: Variant
var _has_choices := false
var _direct_choices := false
var _submitted := false
var _last_content_height := -1

## [SRC: PromptController.Show / OptionController.Show / ConfirmController.Show:
## shared presentation, distinct selection and completion semantics.]
func show_prompt(display: Dictionary, _on_choice: Callable) -> void:
	clear_prompt()
	var text := str(display.get("text", ""))
	if text.strip_edges().is_empty():
		text = str(display.get("title", ""))
	if _body != null:
		_body.text = SourceRichText.to_bbcode(text)
	var choices: Dictionary = display.get("choices", {})
	_has_choices = not choices.is_empty()
	# ConfirmController already presents final OK/Cancel actions, unlike
	# OptionController's selection + separate confirmation.
	_direct_choices = _has_choices and str(display.get("presentation", "")) == "confirm"
	if _direct_choices and _body != null:
		_body.text = "[center]" + SourceRichText.to_bbcode(text) + "[/center]"
	if not _direct_choices:
		_build_confirm()
	if _has_choices:
		_build_choices(choices)
	var portrait: Texture2D = display.get("icon", null)
	if portrait != null and _portrait != null:
		_portrait.texture = portrait
		_portrait.size = portrait.get_size()
		_portrait.position = Vector2(-_portrait.size.x * 0.5, -_portrait.size.y)
		_icon_slots[1].show()
	if display.has("resolved_icons"):
		_show_icons(display.resolved_icons)
	call_deferred("_layout_content")


func clear_prompt() -> void:
	_last_content_height = -1
	_selected_key = ""
	_selected_value = null
	_has_choices = false
	_direct_choices = false
	_submitted = false
	_choice_group = null
	if _options_box != null and is_instance_valid(_options_box):
		for child in _options_box.get_children():
			_options_box.remove_child(child)
			child.queue_free()
	if _confirm_button != null and is_instance_valid(_confirm_button):
		_confirm_button.get_parent().remove_child(_confirm_button)
		_confirm_button.queue_free()
		_confirm_button = null
	if _body != null:
		_body.text = ""
	if _portrait != null:
		_portrait.texture = null
	for slot in _icon_slots:
		slot.hide()
		for child in slot.get_children():
			if child == _portrait:
				continue
			slot.remove_child(child)
			child.queue_free()
	if _full_image != null:
		_full_image.texture = null
		_full_image.hide()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	# [SRC: PromptNew Full Mask m_ShowMaskGraphic=0; Awake 0x589430
	# creates full/item_bg as its first child. The mask is not black artwork.]
	var full := NinePatchRect.new()
	full.name = "Full"
	full.texture = load(SOURCE_ART + "prompt_bg_mask_2.png")
	full.position = FULL_RECT.position
	full.size = FULL_RECT.size
	full.patch_margin_left = 284
	full.patch_margin_right = 248
	full.patch_margin_top = 255
	full.patch_margin_bottom = 234
	full.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	full.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(full)
	# LoadSprite(..., true, true) sets native size before anchors become stretch.
	# item_bg.asset: 2048x1560, PPU=74.963394 (canvas reference PPU=100).
	var native_size := Vector2(2048, 1560) * (100.0 / 74.963394)
	var interior := _texture_rect("prompt_full_item_bg.png", FULL_RECT.size + native_size, 0.0)
	interior.name = "RuntimeBackground"
	interior.position = -native_size * 0.5
	full.add_child(interior)
	_full_image = TextureRect.new()
	_full_image.name = "FullImage"
	_full_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_full_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_full_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	full.add_child(_full_image)
	_full_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_full_image.hide()

	# [SRC: PromptControllerBase.ShowInternal 0x589890 writes Content;
	# PromptNew.prefab has no event-ID title. Do not display operation ids.]

	_body = RichTextLabel.new()
	_body.name = "EventPromptBody"
	_body.bbcode_enabled = true
	_body.fit_content = false
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.scroll_active = true
	_body.position = TEXT_RECT.position
	_body.size = TEXT_RECT.size
	# RichTextLabel uses normal_font_size (font_size is a Label-only key).
	# The previous override passed a getter test but did not affect glyphs.
	SourceText.apply(_body, "@PROMPT_TEXT")
	_body.add_theme_color_override("default_color", Color(0.86274517, 0.8117648, 0.6039216, 1))
	_body.mouse_filter = Control.MOUSE_FILTER_STOP
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
	_portrait.position = Vector2(-PORTRAIT_RECT.size.x * 0.5, -PORTRAIT_RECT.size.y)
	_portrait.size = PORTRAIT_RECT.size
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(3):
		var slot := Control.new()
		slot.name = "PromptIconSlot%d" % (i + 1)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel.add_child(slot)
		slot.hide()
		_icon_slots.append(slot)
	_icon_slots[1].add_child(_portrait)


func _show_icons(presentation: Dictionary) -> void:
	_full_image.texture = presentation.get("full")
	_full_image.visible = _full_image.texture != null
	var slots: Array = presentation.get("slots", [])
	for i in mini(slots.size(), 3):
		var data: Variant = slots[i]
		if not data is Dictionary:
			continue
		_icon_slots[i].show()
		if data.has("texture"):
			var portrait := _portrait if i == 1 else TextureRect.new()
			if i != 1:
				portrait.name = "PromptPortrait%d" % (i + 1)
				portrait.position = _portrait.position
				portrait.size = PORTRAIT_RECT.size
				portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_icon_slots[i].add_child(portrait)
			portrait.texture = data.texture
			if portrait.texture != null:
				portrait.size = portrait.texture.get_size()
				portrait.position = Vector2(-portrait.size.x * 0.5, -portrait.size.y)
		for entry in data.get("cards", []):
			var widget := CardWidget.new()
			widget.name = "PromptCard%d" % int(entry.card.id)
			widget.set_card(entry.card)
			_icon_slots[i].add_child(widget)
			widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
			widget.pivot_offset = widget.size * 0.5
			widget.position = Vector2(0, -entry.pose.x) - widget.pivot_offset
			widget.rotation_degrees = -entry.pose.y
			widget.scale = Vector2.ONE * 1.8
			_icon_slots[i].move_child(widget, 0)


func _process(_delta: float) -> void:
	if _body != null and _last_content_height != _body.get_content_height():
		_layout_content()


# [SRC: PromptNew/OptionNew root Top(min100,flex3500), Bottom(min400,flex2000);
# OptionBG reverse horizontal group L200/R100/spacing100; ContentGroup preferred
# width2000. Options spacing20; option_item_bg Image preferred height112.
# ScrollViewContentHightWatcher.LateUpdate 0x4342c0 caps body at1300/1100.]
func _layout_content() -> void:
	if _body == null or _options_box == null:
		return
	var icon_count := 0
	for slot in _icon_slots:
		if slot.visible:
			icon_count += 1
	# Pos children use width400; IconGroup spacing=-200. Empty group stays active.
	var icon_width := float(icon_count * 400 - maxi(0, icon_count - 1) * 200)
	var horizontal := SourceAxis.allocate(2705, [icon_width, 0], [icon_width, 2000],
		[0, 0], 100, 200, 100, 0.5, true)
	var content_x: float = horizontal.positions[1]
	var content_width: float = horizontal.sizes[1]
	_body.size.x = content_width
	_last_content_height = _body.get_content_height()
	var limit := MAX_OPTION_BODY_HEIGHT if _has_choices and not _direct_choices else MAX_BODY_HEIGHT
	var body_height := float(_last_content_height) if _direct_choices else minf(float(_last_content_height), limit)
	var count := _options_box.get_child_count() if _has_choices and not _direct_choices else 0
	var option_gap_total := float(maxi(0, count - 1)) * OPTION_GAP
	var option_height := count * OPTION_ROW_SIZE.y + option_gap_total
	var top_padding := 200.0 if _has_choices and not _direct_choices else 150.0
	var content_min := option_gap_total + 50.0 if _has_choices and not _direct_choices else 100.0
	var content_pref := body_height + option_height + 50.0 if _has_choices and not _direct_choices else body_height + 100.0
	var panel_min := top_padding + 200.0 + content_min
	var panel_pref := top_padding + 200.0 + content_pref
	if _direct_choices:
		_panel.size.y = panel_pref
		_panel.position.y = (DESIGN_SIZE.y - panel_pref) * 0.5
	else:
		var root_axis := SourceAxis.allocate(DESIGN_SIZE.y, [100, panel_min, 400],
			[100, panel_pref, 400], [3500, 0, 2000])
		_panel.size.y = root_axis.sizes[1]
		_panel.position.y = root_axis.positions[1]
	var inner_height := _panel.size.y - top_padding - 200.0
	var content_axis: Dictionary
	if _has_choices and not _direct_choices:
		content_axis = SourceAxis.allocate(inner_height, [0, option_gap_total],
			[body_height, option_height], [0, 0], 50, 0, 0, 0)
		_body.position = Vector2(content_x, top_padding + content_axis.positions[0])
		_body.size.y = content_axis.sizes[0]
		var rows_min: Array = []
		var rows_pref: Array = []
		var rows_flex: Array = []
		for i in count:
			rows_min.append(0.0)
			rows_pref.append(OPTION_ROW_SIZE.y)
			rows_flex.append(0.0)
		var rows := SourceAxis.allocate(content_axis.sizes[1], rows_min, rows_pref,
			rows_flex, OPTION_GAP, 0, 0, 0)
		for i in count:
			var row := _options_box.get_child(i) as Control
			row.position = Vector2(content_x, top_padding + content_axis.positions[1] + rows.positions[i])
			row.size = Vector2(content_width, rows.sizes[i])
	else:
		# Two zero-height flexible spacers surround the body in Prompt/Confirm.
		content_axis = SourceAxis.allocate(inner_height, [0, 0, 0], [0, body_height, 0],
			[1, 0, 1], 50)
		_body.position = Vector2(content_x, top_padding + content_axis.positions[1])
		_body.size.y = content_axis.sizes[1]
	_panel.get_node("PromptBG").size = _panel.size
	var full := _panel.get_node("Full") as Control
	full.size.y = _panel.size.y - 132.0
	full.get_node("RuntimeBackground").size.y = full.size.y + 1560.0 * (100.0 / 74.963394)
	_panel.get_node("Border").position.y = _panel.size.y - 325.5
	var icon_index := 0
	for slot in _icon_slots:
		if not slot.visible:
			continue
		# IconGroup bottom padding=-100, zero-height Pos; Holder height100.
		slot.position = Vector2(horizontal.positions[0] + 200.0 + icon_index * 200.0,
			_panel.size.y - 150.0)
		icon_index += 1
	if _confirm_button != null:
		_confirm_button.position.y = _panel.size.y - 152.0
	if _direct_choices:
		for row in _options_box.get_children():
			var accepted := str(row.get_meta("choice_key")) == "confirm_ok"
			row.position = Vector2(2045.0 if accepted else 1817.0, _panel.size.y - 79.0)


func _build_choices(choices: Dictionary) -> void:
	# [SRC: decompiled/OptionController.c @ Show (RVA 0x576b50,
	# dump.cs:321643-321673): a ToggleGroup, no initial option, Confirm disabled.]
	_choice_group = ButtonGroup.new()
	_choice_group.allow_unpress = false
	var index := 0
	for key in choices.keys():
		var entry = choices[key]
		var choice_text := str(entry.get("text", key)) if entry is Dictionary else str(entry)
		var choice_value: Variant = entry.get("value") if entry is Dictionary and entry.has("value") else entry
		var row := Button.new()
		# [SRC: OptionItemController.Init 0x5772b0, dump.cs:321676:
		# option.text is assigned to its child TMP, not rendered by Toggle.]
		row.name = "EventPromptChoiceButton"
		row.set_meta("choice_key", str(key))
		row.toggle_mode = not _direct_choices
		if not _direct_choices:
			row.button_group = _choice_group
		row.position = Vector2(
			(OPTION_BG_SIZE.x - OPTION_ROW_SIZE.x) * 0.5,
			OPTION_ROW_Y0 + float(index) * OPTION_ROW_STRIDE
		)
		row.size = OPTION_ROW_SIZE
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override("font_size", 40)
		SourceText.apply(row, "@OPTION_ITEM_TEXT")
		row.add_theme_color_override("font_color", Color("#dccf9c"))
		row.add_theme_color_override("font_hover_color", Color("#fff0b6"))
		row.add_theme_stylebox_override("normal", _row_style("option_item_bg.png"))
		row.add_theme_stylebox_override("hover", _row_style("option_item_highlight.png"))
		row.add_theme_stylebox_override("pressed", _row_style("option_item_highlight.png"))
		row.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		row.add_theme_stylebox_override("disabled", _row_style("option_item_bg.png"))
		if _direct_choices:
			row.pressed.connect(_submit_direct_choice.bind(str(key), choice_value))
		else:
			row.pressed.connect(_select_choice.bind(row, str(key), choice_value))
			row.focus_entered.connect(_select_choice.bind(row, str(key), choice_value))
			row.gui_input.connect(_on_choice_input.bind(row))
		_options_box.add_child(row)
		var caption := RichTextLabel.new()
		caption.name = "OptionText"
		caption.bbcode_enabled = true
		caption.scroll_active = false
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(caption)
		caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# OptionNewItem text stretches to the full root; no cloned24px inset.
		if not _direct_choices:
			SourceText.apply(caption, "@OPTION_ITEM_TEXT")
		caption.add_theme_color_override("default_color", Color(0.8627451, 0.8117647, 0.6039216))
		caption.text = "[center]" + SourceRichText.to_bbcode(choice_text) + "[/center]"
		if _direct_choices:
			var accepted := str(key) == "confirm_ok"
			row.size = Vector2(325 if accepted else 168, 158)
			var button_style := _row_style("rite_op_confirm.png" if accepted else "rite_op_cancel.png", 0)
			for style in ["normal", "hover", "pressed", "focus", "disabled"]:
				row.add_theme_stylebox_override(style, button_style)
			for font_key in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
				caption.add_theme_font_size_override(font_key, 24)
			caption.add_theme_color_override("default_color", Color(0.8666667, 0.8666667, 0.8, 0))
		index += 1


func _build_confirm() -> void:
	_confirm_button = Button.new()
	_confirm_button.name = "EventPromptConfirmButton" if _has_choices else "EventPromptContinueButton"
	_confirm_button.text = "确认" if _has_choices else "继续"
	_confirm_button.disabled = _has_choices
	_confirm_button.position = CONFIRM_RECT.position
	_confirm_button.size = CONFIRM_RECT.size
	_confirm_button.add_theme_font_size_override("font_size", 30)
	_confirm_button.add_theme_color_override("font_color", Color("#2b1d12"))
	_confirm_button.add_theme_color_override("font_hover_color", Color("#681f1b"))
	var confirm_style := _row_style("rite_op_confirm.png")
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		_confirm_button.add_theme_stylebox_override(state, confirm_style)
	_confirm_button.pressed.connect(_submit_prompt)
	_panel.add_child(_confirm_button)


func _submit_direct_choice(choice_key: String, choice_value: Variant) -> void:
	# [SRC: ConfirmController.c @ OnConfirm/OnClose (0x53fc20/0x53fc10)
	# -> Done (0x53fb70); dump.cs:318365: Promise<bool>, no selected option.]
	if _submitted or not is_inside_tree():
		return
	_submitted = true
	choice_clicked.emit(choice_key, choice_value)


func _select_choice(row: Button, choice_key: String, choice_value: Variant) -> void:
	# [SRC: decompiled/OptionController.__c__DisplayClass11_1.c @ <Show>b__0
	# (RVA 0x588f00): selection only; no Promise resolution or result execution.]
	if _submitted or not row.is_inside_tree():
		return
	for other in _choice_group.get_buttons():
		other.set_pressed_no_signal(other == row)
	_selected_key = choice_key
	_selected_value = choice_value
	_confirm_button.disabled = false


func _on_choice_input(event: InputEvent, row: Button) -> void:
	# [SRC: OptionItemController.c @ OnSubmit (0x577490) ->
	# OptionController.__c__DisplayClass11_0.c @ <Show>b__1 (0x588ec0):
	# submit on a selected row moves focus to Confirm; it does not confirm.]
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		row.accept_event()
		if not _submitted and not _confirm_button.disabled:
			_confirm_button.grab_focus()


func _submit_prompt() -> void:
	# [SRC: decompiled/OptionController.c @ OnConfirm (RVA 0x576900):
	# interactable + CurrentToggle gates; clear Promise before resolving once.]
	if _submitted or not is_inside_tree() or _confirm_button.disabled:
		return
	_submitted = true
	_confirm_button.disabled = true
	if _has_choices:
		choice_clicked.emit(_selected_key, _selected_value)
	else:
		confirm_clicked.emit()


func _row_style(file_name: String, texture_margin := 0.0) -> StyleBox:
	var path := SOURCE_ART + file_name
	if ResourceLoader.exists(path):
		var style := StyleBoxTexture.new()
		style.texture = load(path) as Texture2D
		style.texture_margin_left = texture_margin
		style.texture_margin_right = texture_margin
		style.texture_margin_top = 0
		style.texture_margin_bottom = 0
		style.content_margin_left = 0
		style.content_margin_right = 0
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
