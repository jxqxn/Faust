extends GutTest


func test_source_markup_preserves_comparisons_and_nested_styles():
	var converter = preload("res://ui/source_rich_text.gd")
	assert_eq(converter.to_bbcode("3 > 2; 1 < 2"), "3 > 2; 1 < 2")
	assert_eq(converter.to_bbcode("<b><color=#FCE29A><size=86>角色</size></color></b>"), "[b][color=#FCE29A][font_size=86]角色[/font_size][/color][/b]")
	assert_eq(converter.to_bbcode("<sprite=12><size=120%>文字</size>"), "<sprite=12><size=120%>文字</size>", "unsupported tokens remain paired for the renderer audit")
	assert_eq(converter.to_bbcode("<size=+10>大</size><size=-10>小</size>", 50), "[font_size=60]大[/font_size][font_size=40]小[/font_size]")
	assert_eq(converter.to_bbcode("<size=+10>大</size>"), "<size=+10>大</size>", "without a source base size do not invent an absolute size")
	assert_eq(converter.to_bbcode('<font="unknown"><b>字</b></font>', 50), '<font="unknown">[b]字[/b]</font>', "unmapped fonts remain visible to the audit")
	assert_eq(converter.to_bbcode('· <size=125%><align=left>事件</align></size>', 40), '· [font_size=50]事件[/font_size]', "source inline left alignment must not split the bullet into a separate paragraph")
	assert_eq(converter.to_bbcode('<size=125%>事件</size>', 60), '[font_size=75]事件[/font_size]', "percentage size follows the active source font preference")

const Style = preload("res://ui/source_text_style.gd")

func test_source_body_and_title_use_distinct_fonts_and_size_tables() -> void:
	var body := RichTextLabel.new()
	var title := Label.new()
	Style.apply(body, "@RITE_TEXT", "md")
	Style.apply(title, "@RITE_PANEL_TITLE", "md")
	assert_eq(body.get_theme_font("normal_font").resource_path, "res://assets/fonts/xiquemuye.ttf")
	assert_eq(title.get_theme_font("font").resource_path, "res://assets/fonts/HYJieLongTaoHuaYuanW-2.ttf")
	assert_eq(body.get_theme_font_size("normal_font_size"), 36)
	Style.apply(body, "@RITE_SETTLEMENT_TEXT", "md")
	assert_eq(body.get_theme_font_size("normal_font_size"), 40)
	Style.apply(body, "@RITE_TEXT", "xxl")
	assert_eq(body.get_theme_font_size("normal_font_size"), 56)
	assert_eq(title.get_theme_font_size("font_size"), 60)
	body.free()
	title.free()


func test_auto_size_style_without_fixed_size_uses_its_maximum() -> void:
	var label := Label.new()
	Style.apply(label, "@CARD_INFO_TAG_TEXT", "md")
	assert_eq(label.get_theme_font_size("font_size"), 30)
	assert_eq(label.get_meta("source_text_size_range"), [26, 30],
		"the configured sizeRange is exposed for the fit")
	label.free()


func test_auto_size_fit_shrinks_toward_the_configured_floor() -> void:
	var font := load("res://assets/fonts/xiquemuye.ttf") as Font
	assert_not_null(font)
	# A box wide and tall enough for the ceiling keeps the ceiling.
	var roomy := Vector2(2000, 2000)
	assert_eq(Style.fit_point_size(font, "体魄 3", roomy, 26, 30), 30,
		"a roomy box keeps the sizeRange maximum")
	# A short box forces the search down but never below the floor.
	var tight := Vector2(40, 20)
	var fitted := Style.fit_point_size(font, "体魄 3", tight, 26, 30)
	assert_true(fitted >= 26 and fitted <= 30, "the fit stays inside sizeRange")
	assert_lt(fitted, 30, "a tight box shrinks below the maximum")
	# An impossible box never goes under the floor either.
	assert_eq(Style.fit_point_size(font, "很长的正文内容".repeat(20), Vector2(10, 10), 26, 30), 26,
		"the floor is the lower clamp")


func test_auto_size_fit_handles_degenerate_inputs() -> void:
	var font := load("res://assets/fonts/xiquemuye.ttf") as Font
	var no_font: Font = null
	assert_eq(Style.fit_point_size(no_font, "文本", Vector2(100, 100), 10, 40), 40,
		"no font falls back to the ceiling")
	assert_eq(Style.fit_point_size(font, "", Vector2(100, 100), 10, 40), 40,
		"no text falls back to the ceiling")
	assert_eq(Style.fit_point_size(font, "文本", Vector2(0, 100), 10, 40), 40,
		"a zero-width box falls back to the ceiling instead of guessing")
	assert_eq(Style.fit_point_size(font, "文本", Vector2(100, 100), 40, 40), 40,
		"a collapsed range returns its single value")
	assert_eq(Style.fit_point_size(font, "文本", Vector2(100, 100), 0, 40), 40,
		"a zero floor is lifted to 1 rather than looping forever")


func test_fixed_size_style_falls_back_to_its_size_field() -> void:
	# A css_size table that lacks the active class must not erase the text:
	# the source falls back to TextStyleNode.size@0x24.
	var label := Label.new()
	Style.apply(label, "@CARD_TITLE", "md")
	assert_eq(label.get_theme_font_size("font_size"), 38,
		"the table's md entry wins when it exists")
	# An explicitly unknown class on the SAME style must fall back to `size`
	# instead of collapsing to 0.
	Style.apply(label, "@CARD_TITLE", "not-a-real-class")
	assert_eq(label.get_theme_font_size("font_size"), 45,
		"an unknown class falls back to the configured size")
	label.free()


func test_preference_updates_open_text_and_survives_restart() -> void:
	var settings = preload("res://ui/game_application_settings.gd")
	var old_path: String = settings.settings_path
	var old_loaded: bool = settings._loaded
	var old_size: String = settings.font_size
	settings.settings_path = "user://test-font-preference.json"
	settings._loaded = true
	settings.font_size = "md"
	var body := RichTextLabel.new()
	var title := Label.new()
	Style.apply(body, "@MAIN_BODY")
	preload("res://ui/source_rich_text.gd").set_label_text(body, "<size=+10>relative</size>")
	Style.apply(title, "@RITE_PANEL_TITLE")
	var source: Dictionary = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/textstyle.json"))
	assert_true(settings.set_font_size("lg"))
	assert_eq(body.get_theme_font_size("normal_font_size"), int(source["@MAIN_BODY"].css_size.lg))
	assert_string_contains(body.text, "[font_size=%d]" % (int(source["@MAIN_BODY"].css_size.lg) + 10))
	assert_eq(title.get_theme_font_size("font_size"), 60)
	settings.font_size = "sm"
	settings._loaded = false
	settings.load_preferences()
	assert_eq(settings.font_size, "lg")
	assert_false(settings.set_font_size("invalid"))
	assert_eq(settings.font_size, "lg")
	Style.apply(body, "@RITE_SETTLEMENT_TEXT")
	assert_string_contains(body.text, "[font_size=%d]" % (int(source["@RITE_SETTLEMENT_TEXT"].css_size.lg) + 10), "rebinding a style recalculates relative source markup")
	assert_true(settings.set_font_size("xxl"))
	assert_eq(body.get_theme_font_size("normal_font_size"), int(source["@RITE_SETTLEMENT_TEXT"].css_size.xxl))
	body.free()
	title.free()
	assert_true(settings.set_font_size("md"), "freed pages leave no stale subscription")
	DirAccess.remove_absolute(settings.settings_path)
	settings.settings_path = old_path
	settings._loaded = old_loaded
	settings.font_size = old_size
