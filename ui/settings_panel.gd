## Source-shaped SettingsPanel / SettingsController host.
##
## SettingsController.ShowSettings opens a 2x 1920x1080 root and receives
## `show_mask=false` from ESCGameController.OnSettings.  GameApplication owns
## persistent application preferences; player save data is intentionally not
## involved here.
## [SRC: Resources/prefab/SettingsPanel.prefab; GameScene.unity SettingsPanel;
##       decompiled/ESCGameController.c @ OnSettings (RVA 0x542f60);
##       decompiled/SettingsController.c @ ShowSettings (RVA 0x5ab420)]
extends Control

signal closed

const DESIGN_SPACE := Vector2(3840, 2160)
const SOURCE_CANVAS := Vector2(1920, 1080)
const SOURCE_ROOT_SCALE := Vector2(2, 2)
const PANEL_SIZE := Vector2(1788, 1200)
const AppSettings = preload("res://ui/game_application_settings.gd")

var _audio: GameAudio
var _music_slider: HSlider
var _sound_slider: HSlider
var _music_toggle: Button
var _sound_toggle: Button
var _data_collect_toggle: Button
var _harmonious_toggle: Button


func setup(audio: GameAudio) -> void:
	_audio = audio


func _ready() -> void:
	name = "SettingsController"
	theme = FaustTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1001
	AppSettings.load_preferences()
	_build_source_tree()
	apply_source_layout(get_viewport_rect().size)


func apply_source_layout(view_size: Vector2) -> void:
	position = Vector2.ZERO
	size = DESIGN_SPACE
	scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _build_source_tree() -> void:
	var root := Control.new()
	root.name = "SettingsPanel"
	root.size = SOURCE_CANVAS
	root.scale = SOURCE_ROOT_SCALE
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	# ShowSettings(false) leaves the shared mask transparent for the ESC route.
	var mask := ColorRect.new()
	mask.name = "Mask"
	mask.size = SOURCE_CANVAS
	mask.color = Color(0, 0, 0, 0)
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	mask.gui_input.connect(_on_mask_gui_input)
	root.add_child(mask)

	var panel := Panel.new()
	panel.name = "PanelBG"
	panel.position = Vector2(66, -60)
	panel.size = PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style(FaustTheme.GOLD))
	root.add_child(panel)

	_add_label(panel, "Title", "系统设置", Vector2(398.2, 176), Vector2(300, 50), 36, HORIZONTAL_ALIGNMENT_LEFT)
	var close := Button.new()
	close.name = "Button"
	close.text = "×"
	close.position = Vector2(1449.8, 217)
	close.size = Vector2(80, 82)
	close.flat = true
	close.add_theme_font_size_override("font_size", 42)
	close.pressed.connect(_close)
	panel.add_child(close)

	_build_dropdown_group(panel)
	_build_slider_group(panel)
	_build_trigger_group(panel)
	_build_keymap_button(panel)


func _build_dropdown_group(panel: Control) -> void:
	var group := Control.new()
	group.name = "DropDownGroup"
	group.position = Vector2(334.43, 290.4)
	group.size = Vector2(940, 333.2)
	panel.add_child(group)
	# The controller has four fields.  The original binds platform and language
	# APIs not yet present in the Godot host, so they stay visibly explicit,
	# instead of pretending that selecting one changes the OS.
	_add_source_dropdown(group, "ShowMode", "显示模式：", "全屏模式", 0)
	_add_source_dropdown(group, "Language", "语言：", "", 1)
	_add_source_dropdown(group, "Resolution", "分辨率：", "1920x1080", 2)
	_add_source_dropdown(group, "FontSize", "字体大小：", "", 3)


func _add_source_dropdown(group: Control, node_name: String, title: String, value: String, index: int) -> void:
	var row := Control.new()
	row.name = node_name
	row.position = Vector2(0, 78.0 * index)
	row.size = Vector2(940, 50)
	group.add_child(row)
	_add_label(row, "Text (TMP)", title, Vector2(0, 0), Vector2(180, 50), 24, HORIZONTAL_ALIGNMENT_LEFT)
	var dropdown := Button.new()
	dropdown.name = "Dropdown"
	dropdown.position = Vector2(114.9, -3)
	dropdown.size = Vector2(760, 56)
	dropdown.text = value
	dropdown.alignment = HORIZONTAL_ALIGNMENT_LEFT
	dropdown.add_theme_font_size_override("font_size", 22)
	dropdown.tooltip_text = "SettingDropDownController 的平台/语言绑定尚未迁移。"
	dropdown.disabled = true
	row.add_child(dropdown)
	var outline := Control.new()
	outline.name = "Outline"
	outline.position = Vector2(10, 6.5)
	outline.size = Vector2(725, 43)
	dropdown.add_child(outline)
	var label := Label.new()
	label.name = "Label"
	label.text = value
	label.position = Vector2(10, 7)
	label.size = Vector2(680, 43)
	label.add_theme_font_size_override("font_size", 22)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dropdown.add_child(label)
	var arrow := Label.new()
	arrow.name = "Arrow"
	arrow.text = "⌄"
	arrow.position = Vector2(690, 8)
	arrow.size = Vector2(33, 30)
	arrow.add_theme_font_size_override("font_size", 24)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dropdown.add_child(arrow)


func _build_slider_group(panel: Control) -> void:
	var group := Control.new()
	group.name = "SliderGroup"
	group.position = Vector2(335.43, 606.05)
	group.size = Vector2(1043.6, 147.9)
	panel.add_child(group)
	_music_slider = _add_volume_row(group, "MusicVolume", "游戏音乐音量：", 0, AppSettings.music_value, AppSettings.music_state == AppSettings.STATE_ON)
	_sound_slider = _add_volume_row(group, "SoundVolume", "游戏音效音量：", 1, AppSettings.sound_value, AppSettings.sound_state == AppSettings.STATE_ON)


func _add_volume_row(group: Control, node_name: String, title: String, index: int, value: float, enabled: bool) -> HSlider:
	var row := Control.new()
	row.name = node_name
	row.position = Vector2(0, 80.5 * index)
	row.size = Vector2(1043.6, 50)
	group.add_child(row)
	_add_label(row, "Text (TMP)", title, Vector2(0, 0), Vector2(205, 50), 24, HORIZONTAL_ALIGNMENT_LEFT)
	var slider := HSlider.new()
	slider.name = "Slider"
	slider.position = Vector2(83, 10)
	slider.size = Vector2(766.45, 30)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 0.0
	slider.value = value
	slider.editable = enabled
	row.add_child(slider)
	var value_label := Label.new()
	value_label.name = "Value"
	value_label.position = Vector2(445, -33)
	value_label.size = Vector2(42, 40)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.text = str(roundi(value))
	slider.add_child(value_label)
	var min_label := Label.new()
	min_label.name = "Min"
	min_label.text = "0"
	min_label.position = Vector2(0, 35)
	min_label.size = Vector2(30, 35)
	slider.add_child(min_label)
	var max_label := Label.new()
	max_label.name = "Max"
	max_label.text = "100"
	max_label.position = Vector2(720, 35)
	max_label.size = Vector2(45, 35)
	slider.add_child(max_label)
	var toggle := Button.new()
	toggle.name = "Toggle"
	toggle.position = Vector2(849.44, -8)
	toggle.size = Vector2(102, 56)
	toggle.text = "ON" if enabled else "OFF"
	toggle.add_theme_font_size_override("font_size", 16)
	row.add_child(toggle)
	if node_name == "MusicVolume":
		_music_toggle = toggle
		slider.value_changed.connect(_on_music_value_changed.bind(value_label))
		toggle.pressed.connect(_on_music_toggled)
	else:
		_sound_toggle = toggle
		slider.value_changed.connect(_on_sound_value_changed.bind(value_label))
		toggle.pressed.connect(_on_sound_toggled)
	return slider


func _build_trigger_group(panel: Control) -> void:
	var group := Control.new()
	group.name = "TriggerGroup"
	group.position = Vector2(294, 768)
	group.size = Vector2(1200, 100)
	panel.add_child(group)
	_data_collect_toggle = _add_boolean_row(group, "DataCollect", "数据收集：", 176, AppSettings.data_collect)
	_harmonious_toggle = _add_boolean_row(group, "Harmonious", "主播配置：", 711.4, AppSettings.harmonious)
	_data_collect_toggle.pressed.connect(_on_data_collect_toggled)
	_harmonious_toggle.pressed.connect(_on_harmonious_toggled)


func _add_boolean_row(group: Control, node_name: String, title: String, x: float, value: bool) -> Button:
	var row := Control.new()
	row.name = node_name
	row.position = Vector2(x - 130, 29)
	row.size = Vector2(330, 56)
	group.add_child(row)
	_add_label(row, "Text (TMP)", title, Vector2(0, 0), Vector2(200, 50), 24, HORIZONTAL_ALIGNMENT_LEFT)
	var toggle := Button.new()
	toggle.name = "Toggle"
	toggle.position = Vector2(170, -7.6)
	toggle.size = Vector2(102, 56)
	toggle.text = "ON" if value else "OFF"
	toggle.add_theme_font_size_override("font_size", 16)
	row.add_child(toggle)
	return toggle


func _build_keymap_button(panel: Control) -> void:
	var keymap := Button.new()
	keymap.name = "KeyMap"
	keymap.position = Vector2(284.5, 229)
	keymap.size = Vector2(405, 174)
	keymap.text = "键位说明"
	keymap.disabled = true
	keymap.tooltip_text = "KeyMapController 的输入动作清单尚未迁移。"
	keymap.add_theme_font_size_override("font_size", 36)
	panel.add_child(keymap)


func _add_label(parent: Control, node_name: String, text: String, pos: Vector2, node_size: Vector2, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = pos
	label.size = node_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _on_music_value_changed(value: float, value_label: Label) -> void:
	value_label.text = str(roundi(value))
	AppSettings.set_music_value(value)
	if _audio != null:
		_audio.set_music_settings(value, AppSettings.music_state == AppSettings.STATE_ON)


func _on_sound_value_changed(value: float, value_label: Label) -> void:
	value_label.text = str(roundi(value))
	AppSettings.set_sound_value(value)
	if _audio != null:
		_audio.set_sound_settings(value, AppSettings.sound_state == AppSettings.STATE_ON)


func _on_music_toggled() -> void:
	var enabled := AppSettings.music_state == AppSettings.STATE_OFF
	AppSettings.set_music_state(AppSettings.STATE_ON if enabled else AppSettings.STATE_OFF)
	_music_toggle.text = "ON" if enabled else "OFF"
	_music_slider.editable = enabled
	if _audio != null:
		_audio.set_music_settings(AppSettings.music_value, enabled)


func _on_sound_toggled() -> void:
	var enabled := AppSettings.sound_state == AppSettings.STATE_OFF
	AppSettings.set_sound_state(AppSettings.STATE_ON if enabled else AppSettings.STATE_OFF)
	_sound_toggle.text = "ON" if enabled else "OFF"
	_sound_slider.editable = enabled
	if _audio != null:
		_audio.set_sound_settings(AppSettings.sound_value, enabled)


func _on_data_collect_toggled() -> void:
	AppSettings.set_data_collect(not AppSettings.data_collect)
	_data_collect_toggle.text = "ON" if AppSettings.data_collect else "OFF"


func _on_harmonious_toggled() -> void:
	AppSettings.set_harmonious(not AppSettings.harmonious)
	_harmonious_toggle.text = "ON" if AppSettings.harmonious else "OFF"


func _on_mask_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close()
		accept_event()


func _close() -> void:
	closed.emit()
