## Builds and caches the project's Godot Theme at runtime.
## Uses the original game's CJK body font (HYJieLongTaoHuaYuanW-2) so all
## in-game text renders faithfully, and defines a dark gold-accent palette
## matching the Sultan's palace aesthetic.
class_name FaustTheme
extends RefCounted

# Palette: dark warm stone + gold. Avoids a one-note hue family.
const BG_DEEP := Color("#161210")      # window background
const BG_PANEL := Color("#241d18")      # card / panel fill
const BG_PANEL_LIGHT := Color("#332a22")
const BORDER := Color("#5a4a38")
const GOLD := Color("#c9a96a")          # primary accent
const GOLD_BRIGHT := Color("#e0c486")
const TEXT := Color("#e8dcc8")          # warm off-white
const TEXT_DIM := Color("#a89880")
const DANGER := Color("#9b3232")        # sudan card threat
const DANGER_LIGHT := Color("#c04545")
const SUCCESS := Color("#5a8a4a")
const SUDAN_RANK_COLORS := {
	"岩石": Color("#8a8a8a"),
	"青铜": Color("#b08d57"),
	"白银": Color("#cfd8dc"),
	"黄金": Color("#e0b33a"),
}

static var _theme: Theme = null


## Returns the singleton theme, building it on first call.
static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


## Test runners and scene reloads must release the cached FontVariation before
## the rendering server shuts down.  Keeping it alive until process exit leaves
## a real Font/RID leak in headless Godot runs.
static func clear_cache() -> void:
	_theme = null


static func _build() -> Theme:
	var t := Theme.new()
	var font: Font = _load_font()
	# Default font for every control type that uses the default font.
	if font != null:
		for type_name in ["", "Label", "Button", "OptionButton", "LineEdit", "RichTextLabel", "CheckBox"]:
			t.set_font("font", type_name, font)
	# Label sizes.
	t.set_font_size("font_size", "Label", 16)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_hover_color", "Label", TEXT)
	# Button styling: gold border on dark, brighten on hover/press.
	t.set_font_size("font_size", "Button", 18)
	t.set_color("font_color", "Button", GOLD_BRIGHT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", TEXT_DIM)
	var btn_normal := _make_style(BG_PANEL, BORDER, 2)
	var btn_hover := _make_style(BG_PANEL_LIGHT, GOLD, 2)
	var btn_pressed := _make_style(Color("#1e1813"), GOLD_BRIGHT, 2)
	var btn_disabled := _make_style(BG_DEEP, Color("#3a3028"), 2)
	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_stylebox("focus", "Button", _make_style(Color(0,0,0,0), Color(0,0,0,0), 0))
	# OptionButton inherits Button styles; fix its arrow/text spacing.
	t.set_font_size("font_size", "OptionButton", 15)
	t.set_color("font_color", "OptionButton", TEXT)
	# Panel: dark with subtle border.
	var panel_style := _make_style(BG_PANEL, BORDER, 1)
	t.set_stylebox("panel", "Panel", panel_style)
	t.set_stylebox("panel", "PanelContainer", panel_style)
	# ScrollContainer background.
	t.set_stylebox("bg", "ScrollContainer", _make_style(Color(0,0,0,0.0), Color(0,0,0,0), 0))
	# ProgressBar (sudan deadline bar).
	t.set_font_size("font_size", "ProgressBar", 13)
	t.set_stylebox("background", "ProgressBar", _make_style(Color("#100c0a"), Color("#2a2218"), 1))
	t.set_stylebox("fill", "ProgressBar", _make_style(DANGER, Color(0,0,0,0), 0))
	return t


static func _load_font() -> Font:
	# Headless GUT runs validate structure and behavior, not typography. Avoid
	# allocating the project FontFile in a process that is about to exit.
	if DisplayServer.get_name() == "headless":
		return null
	# Load the game's CJK font as the base, with no forced bold/spacing.
	var path := "res://assets/fonts/HYJieLongTaoHuaYuanW-2.ttf"
	var base := load(path) as FontFile
	if base == null:
		push_warning("FaustTheme: font not found at %s, falling back to default" % path)
		return FontVariation.new()
	var fv := FontVariation.new()
	fv.set_base_font(base)
	return fv


static func _make_style(bg: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(8)
	return s


## A compact dark stylebox for inner panels, used by hand cards etc.
static func card_style(accent: Color = BORDER) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = BG_PANEL
	s.border_color = accent
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(6)
	return s
