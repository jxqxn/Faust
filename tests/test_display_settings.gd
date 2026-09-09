extends GutTest

const Settings = preload("res://ui/game_application_settings.gd")
const SettingsPanel = preload("res://ui/settings_panel.gd")
var _saved: Dictionary
var window: Window
var backend: FakeDisplay

class FakeDisplay extends RefCounted:
	var fail := false
	var applied := Vector2i.ZERO
	var restores := 0
	func query(_window) -> Dictionary:
		return {"ok": true, "modes": ["2560x1440", "1920x1080", "1280x720"]}
	func apply(_window, dimensions: Vector2i) -> Dictionary:
		if fail:
			return {"ok": false, "error": "test driver rejection"}
		applied = dimensions
		return {"ok": true}
	func restore(_window) -> Dictionary:
		restores += 1
		return {"ok": true}

func before_each() -> void:
	_saved = {
		"path": Settings.settings_path, "loaded": Settings._loaded,
		"mode": Settings.full_screen, "resolution": Settings.resolution,
		"backend": Settings._display_backend, "window": Settings._display_window,
		"modes": Settings._resolutions.duplicate(), "error": Settings.display_error,
	}
	Settings.settings_path = "user://test-display-settings-%d.json" % OS.get_process_id()
	if FileAccess.file_exists(Settings.settings_path):
		DirAccess.remove_absolute(Settings.settings_path)
	Settings._loaded = false
	Settings.full_screen = Settings.DEFAULT_FULLSCREEN
	Settings.resolution = Settings.DEFAULT_RESOLUTION
	Settings.display_error = ""
	window = Window.new()
	window.visible = false
	add_child_autofree(window)
	backend = FakeDisplay.new()

func after_each() -> void:
	if FileAccess.file_exists(Settings.settings_path):
		DirAccess.remove_absolute(Settings.settings_path)
	Settings.settings_path = _saved.path
	Settings._loaded = _saved.loaded
	Settings.full_screen = _saved.mode
	Settings.resolution = _saved.resolution
	Settings._display_backend = _saved.backend
	Settings._display_window = _saved.window
	Settings._resolutions.assign(_saved.modes)
	Settings.display_error = _saved.error

func test_windowed_startup_never_applies_a_monitor_mode() -> void:
	assert_true(Settings.initialize_display(window, backend))
	assert_eq(backend.applied, Vector2i.ZERO)
	assert_eq(window.mode, Window.MODE_WINDOWED)
	assert_eq(window.size, Vector2i(1920, 1080))
	assert_eq(Settings.full_screen, "Windowed")
	assert_eq(Settings.supported_resolutions(), ["2560x1440", "1920x1080", "1280x720"])

func test_explicit_windowed_launch_overrides_saved_fullscreen() -> void:
	var file := FileAccess.open(Settings.settings_path, FileAccess.WRITE)
	file.store_string('{"GameFullScreen":"ExclusiveFullScreen","GameResolution":"1280x720"}')
	file.close()
	assert_true(Settings.initialize_display(window, backend, PackedStringArray(["--windowed", "--resolution", "1920x1080"])))
	assert_eq(backend.applied, Vector2i.ZERO)
	assert_eq(window.mode, Window.MODE_WINDOWED)
	assert_eq(window.size, Vector2i(1920, 1080))

func test_resolution_and_mode_persist_together_and_restore_on_startup() -> void:
	Settings.initialize_display(window, backend)
	assert_true(Settings.set_full_screen("Windowed"))
	assert_true(Settings.set_resolution("1280x720"))
	assert_eq(window.mode, Window.MODE_WINDOWED)
	assert_eq(window.size, Vector2i(1280, 720))
	assert_gt(backend.restores, 0)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Settings.settings_path))
	assert_eq(saved.GameFullScreen, "Windowed")
	assert_eq(saved.GameResolution, "1280x720")
	assert_true(saved.has("music_value"), "display writes retain existing application preferences")
	Settings._loaded = false
	Settings.full_screen = "ExclusiveFullScreen"
	Settings.resolution = "1920x1080"
	var next_backend := FakeDisplay.new()
	assert_true(Settings.initialize_display(window, next_backend))
	assert_eq(Settings.full_screen, "Windowed")
	assert_eq(Settings.resolution, "1280x720")
	assert_eq(window.size, Vector2i(1280, 720))
	assert_eq(next_backend.applied, Vector2i.ZERO, "window restore never switches the monitor resolution")

func test_failed_native_change_does_not_save_or_claim_success() -> void:
	Settings.initialize_display(window, backend)
	Settings.set_full_screen("ExclusiveFullScreen")
	Settings.set_resolution("1920x1080")
	var before := FileAccess.get_file_as_string(Settings.settings_path)
	backend.fail = true
	assert_false(Settings.set_resolution("1280x720"))
	assert_eq(Settings.resolution, "1920x1080")
	assert_eq(FileAccess.get_file_as_string(Settings.settings_path), before)
	assert_eq(Settings.display_error, "test driver rejection")
	assert_false(Settings.set_resolution("999999x999999"), "unlisted modes never reach the driver")

func test_missing_monitor_mode_falls_back_to_first_enumerated_mode() -> void:
	var file := FileAccess.open(Settings.settings_path, FileAccess.WRITE)
	file.store_string('{"GameFullScreen":"Windowed","GameResolution":"1024x768"}')
	file.close()
	assert_true(Settings.initialize_display(window, backend))
	assert_eq(Settings.resolution, "2560x1440")
	assert_eq(window.size, Vector2i(2560, 1440))

func test_settings_controls_apply_source_mode_and_system_resolution() -> void:
	Settings.initialize_display(window, backend)
	var panel = SettingsPanel.new()
	window.add_child(panel)
	var mode := panel.find_child("ShowMode", true, false).get_node("Dropdown") as OptionButton
	var size_picker := panel.find_child("Resolution", true, false).get_node("Dropdown") as OptionButton
	assert_false(mode.disabled)
	assert_false(size_picker.disabled)
	assert_eq(mode.get_item_metadata(0), "ExclusiveFullScreen")
	assert_eq(mode.get_item_metadata(1), "Windowed")
	assert_eq(size_picker.item_count, 3)
	var keymap := panel.find_child("KayMap", true, false) as Control
	assert_eq(keymap.position, Vector2(0, 170))
	assert_false(keymap.get_global_rect().intersects(mode.get_global_rect()), "display picker must be reachable by mouse")
	mode.select(1)
	mode.item_selected.emit(1)
	size_picker.select(2)
	size_picker.item_selected.emit(2)
	assert_eq(Settings.full_screen, "Windowed")
	assert_eq(Settings.resolution, "1280x720")
	assert_eq(window.size, Vector2i(1280, 720))
	panel.queue_free()
	await wait_process_frames(2)
