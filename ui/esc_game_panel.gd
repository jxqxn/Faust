## Source-shaped in-game ESC panel.
##
## The original owns this surface through ESCGameController.  It is not the
## clone-era generic "pause menu": its prefab has a 2x full-screen root, a
## 1021px centre ButtonGroup, and the NewGame entry starts disabled.
## [SRC: Resources/prefab/ESCPanel.prefab (ESCPanel/ButtonGroup);
##       decompiled/ESCGameController.c @ OnEndGame/OnMainMenu/OnReturn
##       (RVA 0x5429f0/0x542ae0/0x542f40), dump.cs:318671]
extends Control

signal return_requested
signal end_game_requested
signal main_menu_requested

const DESIGN_SPACE := Vector2(3840, 2160)
const SOURCE_CANVAS := Vector2(1920, 1080)
const SOURCE_ROOT_SCALE := Vector2(2, 2)
const BUTTON_GROUP_SIZE := Vector2(1021, 456)
const BUTTON_SIZE := Vector2(405, 174)
const BUTTON_STEP := 94.0 # 174px item height + source VerticalLayout spacing -80.


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
	esc_panel.size = SOURCE_CANVAS
	esc_panel.scale = SOURCE_ROOT_SCALE
	esc_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(esc_panel)

	# Source Mask is a black Image (alpha 0.6509804) and closes via PanelBase.
	var mask := ColorRect.new()
	mask.name = "Mask"
	mask.color = Color(0, 0, 0, 0.6509804)
	mask.position = Vector2.ZERO
	mask.size = SOURCE_CANVAS
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	mask.gui_input.connect(_on_mask_gui_input)
	esc_panel.add_child(mask)

	var group := Control.new()
	group.name = "ButtonGroup"
	group.position = (SOURCE_CANVAS - BUTTON_GROUP_SIZE) * 0.5
	group.size = BUTTON_GROUP_SIZE
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	esc_panel.add_child(group)

	# esc_bg/esc_button_bg are not present in the extracted runtime asset set.
	# Preserve exact source geometry and leave those texture slots blank instead
	# of inventing replacement chrome.
	var background := Control.new()
	background.name = "bg"
	background.position = Vector2(0, -130)
	background.size = Vector2(BUTTON_GROUP_SIZE.x, BUTTON_GROUP_SIZE.y + 260)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(background)

	# NewGame is m_IsActive: 0 in the original prefab, therefore absent here.
	# The active children retain their original prefab order and overlap spacing.
	_add_source_button(group, "Settings", "Settings", 0, false, Callable())
	_add_source_button(group, "EndGame", "End Game", 1, true, end_game_requested.emit)
	_add_source_button(group, "SaveAndExit", "Main Menu", 2, true, main_menu_requested.emit)
	_add_source_button(group, "Return", "Return", 3, true, return_requested.emit)


func _add_source_button(
	group: Control,
	node_name: String,
	caption: String,
	index: int,
	interactable: bool,
	callback: Callable
) -> void:
	var button := Button.new()
	button.name = node_name
	button.position = Vector2((BUTTON_GROUP_SIZE.x - BUTTON_SIZE.x) * 0.5, BUTTON_STEP * index)
	button.size = BUTTON_SIZE
	button.flat = true
	button.disabled = not interactable
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactable else Control.CURSOR_ARROW
	button.tooltip_text = "SettingsController 尚未迁移；此原作入口暂不能执行。" if not interactable else ""
	group.add_child(button)
	if interactable:
		button.pressed.connect(callback)

	var outline := Control.new()
	outline.name = "Outline"
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(outline)

	var image := Control.new()
	image.name = "Image"
	image.position = Vector2(53, 52.5)
	image.size = Vector2(299, 69)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(image)

	var text := Label.new()
	text.name = "Text (TMP)"
	text.text = caption
	text.position = Vector2(102.5, 62)
	text.size = Vector2(200, 50)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 36)
	text.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT if interactable else Color(0.65, 0.65, 0.65))
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(text)


func _on_mask_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		return_requested.emit()
		accept_event()
