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
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
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
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
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
	}, "\t"))
