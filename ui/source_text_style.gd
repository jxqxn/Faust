extends Node

const Preferences = preload("res://ui/game_application_settings.gd")
var _control: Control
var _style: Dictionary

# TextTranslate.UpdateTextInternal 0x1566ad0 / UpdateFontSize 0x1566920;
# dump.cs:393716 TextStyleNode. Font paths follow SDF m_SourceFontFile GUIDs.
const FONT_PATHS := {
	"CardTitle SDF": "res://assets/fonts/HYJieLongTaoHuaYuanW-2.ttf",
	"Title SDF": "res://assets/fonts/XiQueGuZiDianTiJFT.ttf",
	"xiquemuye SDF": "res://assets/fonts/xiquemuye.ttf",
}


## Largest point size in [floor_size, ceiling] whose wrapped layout fits `box`.
## Independent of any Control so the search itself stays testable.
static func fit_point_size(font: Font, text: String, box: Vector2, floor_size: int, ceiling: int) -> int:
	if font == null or text.is_empty() or box.x <= 0.0 or box.y <= 0.0:
		return ceiling
	if floor_size < 1:
		floor_size = 1
	if ceiling <= floor_size:
		return floor_size
	var low := floor_size
	var high := ceiling
	var best := floor_size
	while low <= high:
		var mid := int((low + high) / 2)
		if _fits_at(font, text, box, mid):
			best = mid
			low = mid + 1
		else:
			high = mid - 1
	return best


static func _fits_at(font: Font, text: String, box: Vector2, point_size: int) -> bool:
	var line_height := font.get_height(point_size)
	if line_height <= 0.0:
		return true
	var sample := font.get_string_size("汉", HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x
	if sample <= 0.0:
		sample = font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x
	if sample <= 0.0:
		return true
	var per_line := maxi(1, int(floor(box.x / sample)))
	var lines := int(ceil(float(text.length()) / float(per_line)))
	return float(lines) * line_height <= box.y

static func apply(control: Control, key: String, size_class: String = "") -> void:
	var styles: Dictionary = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/textstyle.json"))
	if not styles.has(key):
		push_error("Unknown source text style: " + key)
		return
	var style: Dictionary = styles[key]
	var path: String = FONT_PATHS.get(str(style.get("font", "")), "")
	if path.is_empty():
		push_error("Unmapped source font: " + str(style.get("font")))
		return
	var font := load(path) as Font
	var binding = control.get_node_or_null("SourceTextStyle")
	if binding != null:
		control.remove_child(binding)
		binding.free()
	binding = load("res://ui/source_text_style.gd").new()
	binding.name = "SourceTextStyle"
	binding._control = control
	binding._style = style
	control.add_child(binding)
	if size_class.is_empty():
		Preferences.load_preferences()
		size_class = Preferences.font_size
		# [SRC: TextTranslate.UpdateTextInternal 0x1566ad0 subscribes to
		# OnFontSizeChanged only when enableAutoSize(@0x21) is false and
		# css_size(@0x40) exists; an auto-size style has neither.]
		if style.has("css_size") and not bool(style.get("enableAutoSize", false)):
			Preferences.events.font_size_changed.connect(binding._update_size)
	var point_size := _point_size(style, size_class)
	control.set_meta("source_text_style", key)
	if control is RichTextLabel:
		for font_key in ["normal_font", "bold_font", "italics_font", "bold_italics_font"]:
			control.add_theme_font_override(font_key, font)
		for size_key in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
			control.add_theme_font_size_override(size_key, point_size)
	else:
		control.add_theme_font_override("font", font)
		control.add_theme_font_size_override("font_size", point_size)
	binding._apply_auto_size(font)
	# TMP material and the spacing fields still need renderer-specific evidence;
	# this method only claims font identity, configured point size, and the
	# auto-size fit.


## Auto-sizing (TMP enableAutoSizing): the configured ceiling is the starting
## point and the renderer shrinks toward sizeRange.x until the text fits the
## control's box. The clone measures with the real Font instead of TMP's layout
## engine, and never goes above the ceiling or below the floor.
## [SRC: TextTranslate.c @ UpdateFontSize 0x1566920:
##       set_fontSize(size@0x24, 0 when absent) then
##       set_enableAutoSizing(enableAutoSize@0x21),
##       set_fontSizeMin/set_fontSizeMax(sizeRange@0x28).]
func _ready() -> void:
	# TMP refits whenever the rect or the text changes; a Godot control has no
	# single hook for that, so follow the Control's own resized signal.
	if _control != null and bool(_style.get("enableAutoSize", false)):
		if not _control.resized.is_connected(_apply_auto_size):
			_control.resized.connect(_apply_auto_size)


func _apply_auto_size(font: Font = null) -> void:
	if _control == null or not bool(_style.get("enableAutoSize", false)):
		return
	var limits: Array = _style.get("sizeRange", [])
	if limits.size() != 2:
		return
	var floor_size := maxi(int(limits[0]), 1)
	var ceiling := int(limits[1])
	_control.set_meta("source_text_size_range", [floor_size, ceiling])
	if font == null:
		font = _control.get_theme_font("normal_font") if _control is RichTextLabel else _control.get_theme_font("font")
	if font == null:
		return
	var text := str(_control.text)
	if text.is_empty():
		return
	var box := _control.size
	if box.x <= 0.0 or box.y <= 0.0:
		return
	var fitted := fit_point_size(font, text, box, floor_size, ceiling)
	_control.set_meta("source_text_fitted_size", fitted)
	if _control is RichTextLabel:
		for key in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
			_control.add_theme_font_size_override(key, fitted)
	else:
		_control.add_theme_font_size_override("font_size", fitted)


# [SRC: TextTranslate.UpdateFontSize 0x1566920 / OnDestroy 0x15665d0.]
# A child Node ties the subscription lifetime to the rendered text. Updating
# only point sizes preserves renderer-specific font/material overrides.
func _update_size(code: String) -> void:
	var point_size := _point_size(_style, code)
	if _control is RichTextLabel:
		for key in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
			_control.add_theme_font_size_override(key, point_size)
	else:
		_control.add_theme_font_size_override("font_size", point_size)
	_apply_auto_size()


static func _point_size(style: Dictionary, code: String) -> int:
	# The ceiling: an auto-size style carries only sizeRange, and the source
	# hands TMP size@0x24 (absent => 0) plus fontSizeMax from sizeRange@0x28.
	# The fit in _apply_auto_size is what actually shrinks it.
	if bool(style.get("enableAutoSize", false)):
		var limits: Array = style.get("sizeRange", [])
		if limits.size() == 2:
			return int(limits[1])
	var css: Dictionary = style.get("css_size", {})
	if css.has(code):
		return int(css[code])
	return int(style.get("size", 0))
