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

static func apply(control: Control, key: String, size_class: String = "") -> void:
	var styles: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/textstyle.json"))
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
	if size_class.is_empty():
		Preferences.load_preferences()
		size_class = Preferences.font_size
		if style.has("css_size"):
			binding = load("res://ui/source_text_style.gd").new()
			binding.name = "SourceTextStyle"
			binding._control = control
			binding._style = style
			control.add_child(binding)
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
	# TMP material, automatic sizing and spacing still need renderer-specific
	# evidence. This method only claims font identity and configured point size.


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


static func _point_size(style: Dictionary, code: String) -> int:
	# TMP auto-size starts at the configured maximum. The current host does
	# not yet shrink long content through the full TMP fitting algorithm.
	if bool(style.get("enableAutoSize", false)):
		var limits: Array = style.get("sizeRange", [])
		if limits.size() == 2:
			return int(limits[1])
	return int(style.get("css_size", {}).get(code, style.get("size", 0)))
