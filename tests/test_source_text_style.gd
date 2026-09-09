extends GutTest


func test_source_markup_preserves_comparisons_and_nested_styles():
	var converter = preload("res://ui/source_rich_text.gd")
	assert_eq(converter.to_bbcode("3 > 2; 1 < 2"), "3 > 2; 1 < 2")
	assert_eq(converter.to_bbcode("<b><color=#FCE29A><size=86>角色</size></color></b>"), "[b][color=#FCE29A][font_size=86]角色[/font_size][/color][/b]")
	assert_eq(converter.to_bbcode("<sprite=12><size=120%>文字</size>"), "<sprite=12><size=120%>文字</size>", "unsupported tokens remain paired for the renderer audit")

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
	Style.apply(title, "@RITE_PANEL_TITLE")
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/textstyle.json"))
	assert_true(settings.set_font_size("lg"))
	assert_eq(body.get_theme_font_size("normal_font_size"), int(source["@MAIN_BODY"].css_size.lg))
	assert_eq(title.get_theme_font_size("font_size"), 60)
	settings.font_size = "sm"
	settings._loaded = false
	settings.load_preferences()
	assert_eq(settings.font_size, "lg")
	assert_false(settings.set_font_size("invalid"))
	assert_eq(settings.font_size, "lg")
	Style.apply(body, "@RITE_SETTLEMENT_TEXT")
	assert_true(settings.set_font_size("xxl"))
	assert_eq(body.get_theme_font_size("normal_font_size"), int(source["@RITE_SETTLEMENT_TEXT"].css_size.xxl))
	body.free()
	title.free()
	assert_true(settings.set_font_size("md"), "freed pages leave no stale subscription")
	DirAccess.remove_absolute(settings.settings_path)
	settings.settings_path = old_path
	settings._loaded = old_loaded
	settings.font_size = old_size
