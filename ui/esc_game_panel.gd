## Source-shaped in-game ESC panel.
##
## GameScene uses ESCPanelNew, with a centred 1665x1036 group and top
## anchored rows. Unity anchor y=1 is the TOP, not the bottom.
## [SRC: Scenes/GameScene.unity MainUI/Prompt/ESCPanelNew;
##       decompiled/ESCGameController.c @ OnEndGame/OnMainMenu/OnReturn
##       (RVA 0x5429f0/0x542ae0/0x542f40), dump.cs:318671]
extends Control

const SourceText = preload("res://ui/source_text_style.gd")

signal return_requested
signal end_game_requested
signal main_menu_requested
signal settings_requested
signal save_requested

const DESIGN_SPACE := Vector2(3840, 2160)
const BUTTON_GROUP_SIZE := Vector2(1665, 1036)
const BUTTON_SIZE := Vector2(668, 174)
const BUTTON_STEP := 199.0 # source VerticalLayoutGroup spacing=25.


func _ready() -> void:
	name = "GameMenuOverlay"
	theme = FaustTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1000
	_build_source_tree()
	apply_source_layout(get_viewport_rect().size)


func apply_source_layout(view_size: Vector2) -> void:
	position = Vector2.ZERO
	size = DESIGN_SPACE
	scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _build_source_tree() -> void:
	var esc_panel := Control.new()
	esc_panel.name = "ESCPanel"
	esc_panel.position = Vector2.ZERO
	esc_panel.size = DESIGN_SPACE
	esc_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(esc_panel)

	# Source Mask is a black Image (alpha 0.6509804) and closes via PanelBase.
	var mask := ColorRect.new()
	mask.name = "Mask"
	mask.color = Color(0, 0, 0, 0.6509804)
	mask.position = Vector2.ZERO
	mask.size = DESIGN_SPACE
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	mask.gui_input.connect(_on_mask_gui_input)
	esc_panel.add_child(mask)

	var background := NinePatchRect.new()
	background.name = "Background"
	background.texture = load("res://assets/original/ui/prompt_bg.png")
	background.patch_margin_left = 193
	background.patch_margin_right = 201
	background.patch_margin_top = 233
	background.patch_margin_bottom = 248
	background.position = Vector2(0, 0)
	background.size = BUTTON_GROUP_SIZE + Vector2(0, 40)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The source background belongs to ButtonGroup, rather than covering the viewport.

	var group := Control.new()
	group.name = "ButtonGroup"
	group.position = Vector2((DESIGN_SPACE.x - BUTTON_GROUP_SIZE.x) * 0.5, (DESIGN_SPACE.y - BUTTON_GROUP_SIZE.y) * 0.5)
	group.size = BUTTON_GROUP_SIZE
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	esc_panel.add_child(group)
	group.add_child(background)
	group.move_child(background, 0)

	# Top-anchor centres y=-227/-426/-625/-824 minus half the row height.
	# GamepadReturn is an input hint, not a fifth PC menu button.
	var captions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/ui.json"))
	_add_source_button(group, "Settings", captions.SETTINGS.zhCN, Vector2(498.5, 140), BUTTON_SIZE, settings_requested.emit)
	_add_source_button(group, "SaveGame", captions.USER_ARCHIVE_SAVE.zhCN, Vector2(498.5, 339), BUTTON_SIZE, save_requested.emit)
	_add_source_button(group, "SaveAndExit", captions.SAVE_EXIT.zhCN, Vector2(488.5, 538), Vector2(688, 174), main_menu_requested.emit)
	_add_source_button(group, "EndGame", captions.END_GAME.zhCN, Vector2(498.5, 737), BUTTON_SIZE, end_game_requested.emit)
	var close := TextureButton.new()
	close.name = "Close"
	close.position = Vector2(1564, 55)
	close.size = Vector2(75, 78)
	close.texture_normal = load("res://assets/original/ui/checkbox_bg.png")
	close.ignore_texture_size = true
	close.stretch_mode = TextureButton.STRETCH_SCALE
	close.pressed.connect(return_requested.emit)
	group.add_child(close)
	var close_icon := TextureRect.new()
	close_icon.texture = load("res://assets/original/ui/close_2.png")
	close_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	close_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close_icon.position = Vector2(16, 20.5)
	close_icon.size = Vector2(43, 37)
	close_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close.add_child(close_icon)


func _add_source_button(
	group: Control,
	node_name: String,
	caption: String,
	position: Vector2,
	size: Vector2,
	callback: Callable
) -> void:
	var button := Button.new()
	button.name = node_name
	button.size = size
	button.position = position
	button.flat = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = ""
	group.add_child(button)
	if callback.is_valid():
		button.pressed.connect(callback)

	preload("res://ui/source_menu_button.gd").decorate(button)

	var text := Label.new()
	text.name = "Text (TMP)"
	text.text = caption
	text.position = Vector2((size.x - 540.0) * 0.5, 37)
	text.size = Vector2(540, 100)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 60)
	SourceText.apply(text, "@BIG_BUTTON")
	text.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(text)


func _on_mask_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		return_requested.emit()
		accept_event()
