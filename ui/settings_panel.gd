## [SRC: SettingsPanelNew.prefab; SettingsController.ShowSettings 0x5ab420 /
## OnEnable 0x5ab270 (dump.cs:325897). Coordinates include scene root scale.]
extends Control

signal closed

const DESIGN_SPACE := Vector2(3840, 2160)
const AppSettings = preload("res://ui/game_application_settings.gd")
const SourceText = preload("res://ui/source_text_style.gd")
const INK := Color("c6bd83")
# SettingsPanelNew KeyMapController.keys order; Resources/InputActions.asset
# keyboard bindings; KeyItemController.SetKey 0x5656e0 skips composites.
const KEY_BINDINGS := [
	["Submit", "Space / Enter"], ["Cancel", "Escape"], ["Sort", "O"],
	["IThink", "Z"], ["ShowCardInfo", "X"], ["Help", "/"],
	["MapMove", "W / S / A / D"], ["MapZoom", "Q / E"],
	["Bag1", "1"], ["Bag2", "2"], ["Bag3", "3"], ["Bag4", "4"],
	["BagSwitch", "Tab"], ["BagOpen", "B"], ["Notes", "I"], ["RestoreRite", "R"],
]

var _audio: GameAudio
var _music_slider: HSlider
var _sound_slider: HSlider
var _screen_mode: OptionButton
var _resolution: OptionButton
var _pages: Array[Control] = []
var _tabs: Array[Button] = []
var _ui: Dictionary
var _fonts: Dictionary = {}


func setup(audio: GameAudio) -> void:
	_audio = audio


func _ready() -> void:
	name = "SettingsController"
	theme = FaustTheme.get_theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1001
	AppSettings.load_preferences()
	_ui = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/ui.json"))
	_build_source_tree()
	_on_viewport_resized()
	get_viewport().size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	apply_source_layout(get_viewport_rect().size)


func apply_source_layout(view_size: Vector2) -> void:
	position = Vector2.ZERO
	size = DESIGN_SPACE
	scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _build_source_tree() -> void:
	var root := _group(self, "SettingsPanelNew", Rect2(Vector2.ZERO, DESIGN_SPACE))
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := NinePatchRect.new()
	bg.name = "PanelBG"
	bg.size = DESIGN_SPACE
	bg.texture = _texture("bg_2")
	# Sprite border145/155 at PPU50; referencePixelsPerUnit100.
	bg.patch_margin_left = 145
	bg.patch_margin_right = 145
	bg.patch_margin_top = 155
	bg.patch_margin_bottom = 155
	bg.size = DESIGN_SPACE / 2
	bg.scale = Vector2(2, 2)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var nav := _group(root, "Group1", Rect2(240, 380, 950, 1400))
	_image(nav, "TitleIcon", "setting_icon", Rect2(0, 0, 132, 124))
	_label(nav, "Title", "SETTING_PANEL", Rect2(165, -13, 500, 150), "@TITLE_H1")
	# 3x150 + 2x20, pivot .5 at authored y692 => top447 in Group1.
	var tabs := _group(nav, "ToggleGroup", Rect2(0, 447, 950, 490))
	for i in range(3):
		var button := Button.new()
		button.name = ["ScreenSound", "KayMap", "Other"][i]
		button.position = Vector2(0, i * 170)
		button.size = Vector2(950, 150)
		button.flat = true
		button.toggle_mode = true
		button.pressed.connect(_select_page.bind(i))
		tabs.add_child(button)
		_image(button, "HighLight", "hightlight", Rect2(150, 0, 800, 150))
		_image(button, "Line", "slash", Rect2(0, 135, 950, 30))
		_label(button, "Text", ["SCREEN_SOUND_SETTING", "KEYMAP_KEYBOARD", "OTHER_SETTING"][i], Rect2(50, 0, 850, 150), "@TITLE_H3")
		_tabs.append(button)
	var content := _group(root, "Group2", Rect2(1340, 180, 2345, 1800))
	_pages.append(_group(content, "ScreenSound", Rect2(130, 150, 2115, 1480)))
	_pages.append(_group(content, "KeyMapKeyboard", Rect2(40, 0, 2280, 1800)))
	_pages.append(_group(content, "TriggerGroup", Rect2(0, 0, 2345, 1800)))
	_build_display(_pages[0])
	_build_keymap(_pages[1])
	_build_other(_pages[2])
	var close := Button.new()
	close.name = "Close"
	close.position = Vector2(3722.3, 46.3)
	close.size = Vector2(75, 78)
	close.flat = true
	close.tooltip_text = "关闭"
	close.pressed.connect(_close)
	root.add_child(close)
	_image(close, "Background", "checkbox_bg", Rect2(0, 0, 75, 78))
	_image(close, "Image", "close_2", Rect2(16, 20.5, 43, 37))
	_select_page(0)


func _select_page(index: int) -> void:
	for i in range(_pages.size()):
		_pages[i].visible = i == index
		_tabs[i].set_pressed_no_signal(i == index)
		_tabs[i].get_node("HighLight").visible = i == index


func _build_display(page: Control) -> void:
	_label(page, "SenceTitle", "SCREEN_SETTING_TITLE", Rect2(0, 0, 2115, 116.2), "@TITLE_H2")
	var scene := _group(page, "Sence", Rect2(0, 150.4, 2115, 585))
	_screen_mode = _dropdown(scene, "ShowMode", "SCREEN_MODE_SETTING", 0)
	var variable: Dictionary = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/variable.json"))
	var modes: Array = variable.get("support_fullScreen", [])
	for i in range(modes.size()):
		_screen_mode.add_item(_text("SCREEN_MODE_%d" % i))
		_screen_mode.set_item_metadata(i, str(modes[i]))
		if str(modes[i]) == AppSettings.full_screen:
			_screen_mode.select(i)
	_screen_mode.item_selected.connect(_on_screen_mode_selected)
	var language := _dropdown(scene, "Language", "LANGUAGE_SETTING", 1)
	language.add_item("简体中文")
	language.disabled = true
	_resolution = _dropdown(scene, "Resolution", "RESOLUTION_SETTING", 2)
	for value in AppSettings.supported_resolutions():
		_resolution.add_item(value)
		if value == AppSettings.resolution:
			_resolution.select(_resolution.item_count - 1)
	_resolution.disabled = _resolution.item_count == 0
	if _resolution.disabled:
		_resolution.add_item(AppSettings.resolution)
	_resolution.item_selected.connect(_on_resolution_selected)
	var font_size := _dropdown(scene, "FontSize", "FONT_SIZE_SETTING", 3)
	var sizes := AppSettings.font_size_options()
	for key in sizes:
		font_size.add_item(_text(key))
		var index := font_size.item_count - 1
		font_size.set_item_metadata(index, sizes[key])
		if sizes[key] == AppSettings.font_size:
			font_size.select(index)
	font_size.item_selected.connect(func(index: int):
		AppSettings.set_font_size(str(font_size.get_item_metadata(index))))
	_image(page, "Line", "rite_log_sperator", Rect2(0, 926.6, 2115, 6))
	_label(page, "SoundTitle", "SOUND_SETTING_TITLE", Rect2(0, 1003.79, 2115, 116.2), "@TITLE_H2")
	var sound := _group(page, "Sound", Rect2(0, 1154.19, 2115, 358.7))
	_music_slider = _volume_row(sound, "MusicVolume", "MUSIC_VALUE_SLIDER", 0, AppSettings.music_value)
	_sound_slider = _volume_row(sound, "SoundVolume", "SOUND_VALUE_SLIDER", 179.35, AppSettings.sound_value)


func _dropdown(parent: Control, node_name: String, title: String, index: int) -> OptionButton:
	var row := _group(parent, node_name, Rect2(0, index * 155, 1045, 60))
	row.scale = Vector2(2, 2)
	_label(row, "Title", title, Rect2(80, 5, 175, 50), "@SETTING_OPTION_TITLE")
	var dropdown := OptionButton.new()
	dropdown.name = "Dropdown"
	dropdown.position = Vector2(255, 2)
	dropdown.size = Vector2(790, 56)
	dropdown.fit_to_longest_item = false
	dropdown.alignment = HORIZONTAL_ALIGNMENT_CENTER
	SourceText.apply(dropdown, "@SETTING_OPTION_ITEM")
	_use_distance_field_font(dropdown)
	dropdown.add_theme_color_override("font_color", INK)
	dropdown.add_theme_color_override("font_disabled_color", INK.darkened(0.25))
	dropdown.add_theme_icon_override("arrow", _texture("dropdown_arrow"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = _texture("setting_button_bg")
		style.texture_margin_left = 29
		style.texture_margin_right = 50
		style.texture_margin_top = 15
		style.texture_margin_bottom = 15
		dropdown.add_theme_stylebox_override(state, style)
	row.add_child(dropdown)
	var popup := dropdown.get_popup()
	popup.add_theme_font_override("font", dropdown.get_theme_font("font"))
	popup.add_theme_font_size_override("font_size", 22)
	# SettingsPanelNew Dropdown/Template: dropdown_bg borders14/22/37/31,
	# option height56. PopupMenu still places checkmarks/text differently from TMP.
	var panel := StyleBoxTexture.new()
	panel.texture = _texture("dropdown_bg")
	panel.texture_margin_left = 14
	panel.texture_margin_bottom = 22
	panel.texture_margin_right = 37
	panel.texture_margin_top = 31
	popup.add_theme_stylebox_override("panel", panel)
	var hover := StyleBoxTexture.new()
	hover.texture = _texture("setting_button_bg")
	hover.texture_margin_left = 29
	hover.texture_margin_right = 50
	hover.texture_margin_top = 15
	hover.texture_margin_bottom = 15
	popup.add_theme_stylebox_override("hover", hover)
	popup.add_theme_color_override("font_color", INK)
	popup.add_theme_color_override("font_hover_color", INK)
	popup.add_theme_constant_override("v_separation", 30)
	popup.add_theme_icon_override("radio_checked", _texture("checkbox_selected"))
	return dropdown


func _volume_row(parent: Control, node_name: String, title: String, y: float, value: float) -> HSlider:
	var row := _group(parent, node_name, Rect2(0, y, 1049.59, 60))
	row.scale = Vector2(2, 2)
	_label(row, "Title", title, Rect2(80, 0.65, 203.14, 58.7), "@SETTING_OPTION_TITLE")
	var slider := HSlider.new()
	slider.name = "Slider"
	slider.position = Vector2(283.135, 15)
	slider.size = Vector2(766.45, 30)
	slider.max_value = 100
	slider.step = 0
	slider.value = value
	var track := StyleBoxTexture.new()
	track.texture = _texture("slider_bg")
	track.content_margin_top = 2.45
	track.content_margin_bottom = 2.45
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", StyleBoxEmpty.new())
	slider.add_theme_stylebox_override("grabber_area_highlight", StyleBoxEmpty.new())
	var thumb := _texture("slider_block").get_image()
	thumb.resize(9, 30, Image.INTERPOLATE_LANCZOS)
	var thumb_texture := ImageTexture.create_from_image(thumb)
	slider.add_theme_icon_override("grabber", thumb_texture)
	slider.add_theme_icon_override("grabber_highlight", thumb_texture)
	row.add_child(slider)
	var number := _label(slider, "Value", "", Rect2(0, -39.735, 42.08, 39.67), "@SETTING_OPTION_ITEM")
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_update_volume_label(value, slider, number)
	_label(slider, "Min", "", Rect2(30.4, 20.165, 30, 39.67), "@SETTING_OPTION_ITEM").text = "0"
	_label(slider, "Max", "", Rect2(716.1, 20.165, 45, 39.67), "@SETTING_OPTION_ITEM").text = "100"
	slider.value_changed.connect(func(v: float):
		_update_volume_label(v, slider, number)
		if node_name == "MusicVolume":
			AppSettings.set_music_value(v)
			if _audio != null:
				_audio.set_music_settings(v, AppSettings.music_state == AppSettings.STATE_ON)
		else:
			AppSettings.set_sound_value(v)
			if _audio != null:
				_audio.set_sound_settings(v, AppSettings.sound_state == AppSettings.STATE_ON)
	)
	return slider


func _update_volume_label(value: float, slider: HSlider, label: Label) -> void:
	label.text = str(roundi(value))
	label.position.x = 33 + (slider.size.x - 66) * value / 100.0 - label.size.x / 2


func _build_keymap(page: Control) -> void:
	# KeyItem.prefab120 high, Content VerticalLayoutGroup spacing8.
	var scroll := ScrollContainer.new()
	scroll.name = "Keys"
	scroll.size = page.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var content := Control.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.custom_minimum_size = Vector2(2260, KEY_BINDINGS.size() * 128 - 8)
	scroll.add_child(content)
	for i in range(KEY_BINDINGS.size()):
		var binding: Array = KEY_BINDINGS[i]
		var row := _group(content, str(binding[0]), Rect2(0, i * 128, 2260, 120))
		for x in [0, 1129]:
			var cell := NinePatchRect.new()
			cell.position = Vector2(x, 0)
			# KeyItem Images use pixelsPerUnitMultiplier4.
			cell.size = Vector2(1131, 120) * 4
			cell.scale = Vector2(0.25, 0.25)
			cell.texture = _texture("grid_0")
			cell.patch_margin_left = 20
			cell.patch_margin_right = 20
			cell.patch_margin_top = 20
			cell.patch_margin_bottom = 20
			cell.modulate = Color(0.5943396, 0.57878023, 0.49061054)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(cell)
		var title := _label(row, "DisplayNameText", "KEYMAP_%s_Keyboard&Mouse" % binding[0], Rect2(10, 0, 1111, 120), "@MAIN_BODY")
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var keys := _label(row, "KeyText", "", Rect2(1139, 0, 1111, 120), "@MAIN_BODY")
		keys.text = str(binding[1])
		keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_other(page: Control) -> void:
	_boolean_row(page, "DataCollect", "DATA_COLLECT_TOGGLE", "DATA_COLLECT_TIPS", 0, AppSettings.data_collect, AppSettings.set_data_collect)
	_boolean_row(page, "Harmonious", "HARMONIOUS_TOGGLE", "HARMONIOUS_TIPS", 630, AppSettings.harmonious, AppSettings.set_harmonious)
	_boolean_row(page, "MobileUI", "MOBILE_UI_TOGGLE", "MOBILE_UI_TIPS", 1260, AppSettings.mobile_ui, AppSettings.set_mobile_ui)


func _boolean_row(page: Control, node_name: String, title: String, tips: String, y: float, value: bool, setter: Callable) -> void:
	var row := _group(page, node_name, Rect2(0, y, 2345, 200))
	_label(row, "Title", title, Rect2(0, 0, 600, 200), "@TITLE_H2")
	var toggle := Button.new()
	toggle.name = "Toggle"
	toggle.position = Vector2(614.5, 56)
	toggle.size = Vector2(208, 88)
	toggle.flat = true
	toggle.toggle_mode = true
	toggle.button_pressed = value
	toggle.tooltip_text = _text(title).trim_suffix("：")
	row.add_child(toggle)
	var icon := _image(toggle, "Image", "toggle_on" if value else "toggle_off", Rect2(0, 0, 208, 88))
	toggle.toggled.connect(func(enabled: bool):
		setter.call(enabled)
		icon.texture = _texture("toggle_on" if enabled else "toggle_off"))
	var description := _label(page, node_name + "Tips", tips, Rect2(0, y + 250, 2345, 240), "@PROMPT_TEXT")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if y < 1260:
		_image(page, node_name + "Line", "rite_log_sperator", Rect2(0, y + 557, 2345, 6))


func _on_screen_mode_selected(index: int) -> void:
	if not AppSettings.set_full_screen(str(_screen_mode.get_item_metadata(index))):
		for i in range(_screen_mode.item_count):
			if str(_screen_mode.get_item_metadata(i)) == AppSettings.full_screen:
				_screen_mode.select(i)
		_show_display_error()


func _on_resolution_selected(index: int) -> void:
	if not AppSettings.set_resolution(_resolution.get_item_text(index)):
		for i in range(_resolution.item_count):
			if _resolution.get_item_text(i) == AppSettings.resolution:
				_resolution.select(i)
		_show_display_error()


func _show_display_error() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "无法切换显示设置"
	dialog.dialog_text = AppSettings.display_error
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()


func _group(parent: Node, node_name: String, rect: Rect2) -> Control:
	var control := Control.new()
	control.name = node_name
	control.position = rect.position
	control.size = rect.size
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
	return control


func _texture(asset: String) -> Texture2D:
	if asset == "rite_log_sperator":
		var frames: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/original/ui/rite_settlement_icon.json"))
		var frame: Dictionary = {}
		for entry in frames.get("frames", []):
			if entry.get("filename", "") == "rite_log_sperator.png":
				frame = entry.get("frame", {})
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/original/ui/rite_settlement_icon.png")
		atlas.region = Rect2(frame.get("x", 0), frame.get("y", 0), frame.get("w", 0), frame.get("h", 0))
		return atlas
	return load("res://assets/original/ui/%s.png" % asset)


func _image(parent: Control, node_name: String, asset: String, rect: Rect2) -> TextureRect:
	var control := TextureRect.new()
	control.name = node_name
	control.position = rect.position
	control.size = rect.size
	control.texture = _texture(asset)
	control.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
	return control


func _text(key: String) -> String:
	return str(_ui.get(key, {}).get("zhCN", ""))


func _label(parent: Control, node_name: String, key: String, rect: Rect2, style: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = _text(key)
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SourceText.apply(label, style)
	_use_distance_field_font(label)
	label.add_theme_color_override("font_color", INK)
	parent.add_child(label)
	return label


func _use_distance_field_font(control: Control) -> void:
	# Source TMP uses SDF. Keep this renderer choice local to the scaled panel.
	var original := control.get_theme_font("font")
	var key := original.resource_path
	if not _fonts.has(key):
		var font := original.duplicate() as FontFile
		if font == null:
			return
		font.multichannel_signed_distance_field = true
		font.msdf_size = 96
		_fonts[key] = font
	control.add_theme_font_override("font", _fonts[key])


func _close() -> void:
	closed.emit()
