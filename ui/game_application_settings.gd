## Application-level settings mirroring the original GameApplication fields.
##
## These settings deliberately live outside GameState/save files.  The source
## writes them through Unity PlayerPrefs, so a player save must not transport
## audio or consent settings between machines.
## [SRC: decompiled/GameApplication.c @ SetMusicState/SetMusicValue/
##       SetSoundState/SetSoundValue (RVA 0x43f5e0/0x43f670/0x43f8b0/0x43f940);
##       dump.cs:423185-423196]
class_name GameApplicationSettings
extends RefCounted

const SETTINGS_PATH := "user://application_settings.json"
const STATE_ON := "ON"
const STATE_OFF := "OFF"
const EXCLUSIVE_FULLSCREEN := "ExclusiveFullScreen"
# User-requested launch policy. Unity's application default is exclusive,
# but a windowed launch must never change the desktop display mode.
const DEFAULT_FULLSCREEN := "Windowed"
const DEFAULT_RESOLUTION := "1920x1080"
# GameApplicationConfig..cctor 0x300380, stringliteral 0x25C2418 = md.
const DEFAULT_FONT_SIZE := "md"
const DisplayAdapter = preload("res://platform/windows/display_adapter.gd")

class PreferenceEvents extends RefCounted:
	signal font_size_changed(code: String)

static var events := PreferenceEvents.new()
static var font_size := DEFAULT_FONT_SIZE

static var settings_path := SETTINGS_PATH
static var full_screen := DEFAULT_FULLSCREEN
static var resolution := DEFAULT_RESOLUTION
static var display_error := ""
static var _display_backend = null
static var _display_window: WeakRef
static var _resolutions: Array[String] = []

static var _loaded := false
static var music_state := STATE_ON
static var sound_state := STATE_ON
static var music_value := 100.0
static var sound_value := 100.0
static var data_collect := false
static var harmonious := false
static var mobile_ui := false


static func load_preferences() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	music_state = _state(parsed.get("music_state", music_state))
	sound_state = _state(parsed.get("sound_state", sound_state))
	music_value = clampf(float(parsed.get("music_value", music_value)), 0.0, 100.0)
	sound_value = clampf(float(parsed.get("sound_value", sound_value)), 0.0, 100.0)
	data_collect = bool(parsed.get("data_collect", data_collect))
	harmonious = bool(parsed.get("harmonious", harmonious))
	mobile_ui = bool(parsed.get("mobile_ui", mobile_ui))
	font_size = str(parsed.get("GameFontSize", DEFAULT_FONT_SIZE))
	if font_size not in font_size_options().values():
		font_size = DEFAULT_FONT_SIZE
	full_screen = str(parsed.get("GameFullScreen", DEFAULT_FULLSCREEN))
	if full_screen not in [EXCLUSIVE_FULLSCREEN, "Windowed"]:
		full_screen = DEFAULT_FULLSCREEN
	resolution = str(parsed.get("GameResolution", DEFAULT_RESOLUTION))
	if parse_resolution(resolution) == Vector2i.ZERO:
		resolution = DEFAULT_RESOLUTION


## [SRC: GameApplication.<DoInit>d__43.MoveNext 0x4520e0 L883-984;
## dump.cs:542497-542500. Application preferences are not player saves.]
static func initialize_display(window: Window, backend = null, launch_args: PackedStringArray = OS.get_cmdline_args()) -> bool:
	load_preferences()
	# Explicit launch mode takes precedence over a previous fullscreen choice.
	if "--windowed" in launch_args or "-w" in launch_args or "--embedded" in launch_args:
		full_screen = "Windowed"
	for index in range(launch_args.size() - 1):
		if launch_args[index] == "--resolution" and parse_resolution(launch_args[index + 1]) != Vector2i.ZERO:
			resolution = launch_args[index + 1]
	if backend == null and DisplayServer.get_name() == "headless":
		return true
	_display_backend = backend if backend != null else DisplayAdapter.new()
	_display_window = weakref(window)
	_resolutions.clear()
	var available: Dictionary = _display_backend.query(window)
	if not bool(available.get("ok", false)):
		display_error = str(available.get("error", "无法读取显示模式。"))
		return false
	for value in available.get("modes", []):
		_resolutions.append(str(value))
	var selected := resolution
	# A monitor replacement can invalidate the saved choice. Source dropdown
	# uses the first supported mode when its saved string has no match.
	# [SRC: SettingDropDownController.InitResolutionDropDown 0x5aa0b0.]
	if selected not in _resolutions and not _resolutions.is_empty():
		selected = _resolutions[0]
	if not _apply_display(full_screen, selected):
		return false
	resolution = selected
	return true


static func supported_resolutions() -> Array[String]:
	return _resolutions.duplicate()


static func parse_resolution(value: String) -> Vector2i:
	var parts := value.split("x")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i.ZERO
	var result := Vector2i(int(parts[0]), int(parts[1]))
	return result if result.x > 0 and result.y > 0 else Vector2i.ZERO


## [SRC: GameApplication.SetFullScreen 0x43eea0 / SetResolution 0x43f700:
## apply Screen.SetResolution first, then retain the selected string.]
static func set_full_screen(value: String) -> bool:
	load_preferences()
	if value not in [EXCLUSIVE_FULLSCREEN, "Windowed"] or not _apply_display(value, resolution):
		return false
	full_screen = value
	_save_preferences()
	return true


static func set_resolution(value: String) -> bool:
	load_preferences()
	if value not in _resolutions or not _apply_display(full_screen, value):
		return false
	resolution = value
	_save_preferences()
	return true


static func _apply_display(mode: String, selected: String) -> bool:
	var window = _display_window.get_ref() if _display_window != null else null
	var dimensions := parse_resolution(selected)
	if window == null or _display_backend == null or dimensions == Vector2i.ZERO:
		display_error = "显示设置尚未初始化。"
		return false
	var result: Dictionary
	if mode == EXCLUSIVE_FULLSCREEN:
		result = _display_backend.apply(window, dimensions)
		if bool(result.get("ok", false)):
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		result = _display_backend.restore(window)
		if bool(result.get("ok", false)):
			window.mode = Window.MODE_WINDOWED
			window.size = dimensions
			var area := DisplayServer.screen_get_usable_rect(window.current_screen)
			window.position = area.position + (area.size - dimensions) / 2
	if not bool(result.get("ok", false)):
		display_error = str(result.get("error", "显示模式切换失败。"))
		return false
	display_error = ""
	return true


## [SRC: SettingDropDownController.InitFontSizeDropDown 0x5a96a0;
## variable.json support_font_size; dump.cs:387283. Preserve source order.]
static func font_size_options() -> Dictionary:
	var variable: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/variable.json"))
	return variable.get("support_font_size", {})


## [SRC: GameApplication.SetFontSize 0x43ee10; Datapool.fontSize /
## OnFontSizeChanged, dump.cs:423380/423423; GameFontSize key:542496.]
static func set_font_size(value: String) -> bool:
	load_preferences()
	if value not in font_size_options().values():
		return false
	font_size = value
	events.font_size_changed.emit(value)
	_save_preferences()
	return true


static func set_music_state(value: String) -> void:
	load_preferences()
	music_state = _state(value)
	_save_preferences()


static func set_music_value(value: float) -> void:
	load_preferences()
	music_value = clampf(value, 0.0, 100.0)
	_save_preferences()


static func set_sound_state(value: String) -> void:
	load_preferences()
	sound_state = _state(value)
	_save_preferences()


static func set_sound_value(value: float) -> void:
	load_preferences()
	sound_value = clampf(value, 0.0, 100.0)
	_save_preferences()


static func set_data_collect(value: bool) -> void:
	load_preferences()
	data_collect = value
	_save_preferences()


static func set_harmonious(value: bool) -> void:
	load_preferences()
	harmonious = value
	_save_preferences()


static func set_mobile_ui(value: bool) -> void:
	load_preferences()
	mobile_ui = value
	_save_preferences()


static func _state(value: Variant) -> String:
	return STATE_OFF if str(value).to_upper() == STATE_OFF else STATE_ON


static func _save_preferences() -> void:
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file == null:
		push_warning("GameApplicationSettings: cannot persist application preferences")
		return
	file.store_string(JSON.stringify({
		"music_state": music_state,
		"sound_state": sound_state,
		"music_value": music_value,
		"sound_value": sound_value,
		"data_collect": data_collect,
		"harmonious": harmonious,
		"mobile_ui": mobile_ui,
		"GameFullScreen": full_screen,
		"GameResolution": resolution,
		"GameFontSize": font_size,
	}, "\t"))
