## Main menu: title page (new game / continue / archives / quit), then the
## difficulty picker as its own page — matching the original's two-stage
## flow where difficulty is chosen after entering a new game, not on the
## title screen.
##
## Visual layout mirrors StartScene's StartPanel: the bg_new_0 backdrop
## painting, the centered logo, and 668x140 button_bg_new stamps for the
## primary actions. The story/shop/collect meta row is a platform feature
## with no clone counterpart and is not reproduced.
## [SRC: StartScene.unity StartPanel/MainGroup -> bg_new_0, button_bg_new,
##       logo; button column NewGame/LoadGame/UserArchiveLoadGame/QuitGame]
extends Control

signal difficulty_selected(index: int)
signal test_start_requested(index: int)

signal continue_pressed()
signal user_archive_load_requested(index: int)
signal user_archive_delete_requested(index: int)

const DIFF_NAMES := ["梅姬（简单）", "哈桑（普通）", "女术士（困难）"]

const CONTENT_WIDTH := 980
const TITLE_BG_PATH := "res://assets/original/ui/bg_new_0.png"
const BUTTON_BG_PATH := "res://assets/original/ui/button_bg_new.png"

var _db = null
var _column: VBoxContainer


func setup(db = null) -> void:
	_db = db


func _ready() -> void:
	theme = FaustTheme.get_theme()
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Original title painting as the full-bleed backdrop.
	# [SRC: Texture2D/bg_new_0.png 2048x1076 -> StartPanel background]
	var bg := TextureRect.new()
	bg.name = "Background"
	if ResourceLoader.exists(TITLE_BG_PATH):
		bg.texture = load(TITLE_BG_PATH) as Texture2D
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		bg.texture = null
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_title_view()


## Title page: the game's front door. Difficulty is NOT chosen here.
func _build_title_view() -> void:
	_clear_dynamic()
	_center_column()
	var logo := TextureRect.new()
	logo.name = "MenuLogo"
	logo.texture = preload("res://assets/original/ui/logo/logo_zhCN.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# [SRC: StartPanel/MainGroup logo 730x458 within the 2200x1800 group]
	logo.custom_minimum_size = Vector2(620, 389)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_column.add_child(logo)
	_column.add_child(_spacer(34))
	var new_game := _title_button("新的游戏", "NewGameButton")
	# The original starts the run right away; the opening show (event
	# 5310006) presents the narrator/difficulty pick in-game.
	new_game.pressed.connect(func(): difficulty_selected.emit(0))
	_column.add_child(new_game)
	_column.add_child(_spacer(14))
	# Continue button (only if a valid save exists).
	if _has_continue_save():
		var cont := _title_button("继续游戏", "ContinueGameButton")
		cont.pressed.connect(func(): continue_pressed.emit())
		_column.add_child(cont)
		_column.add_child(_spacer(14))
	var archives := SaveSystem.list_user_archives(_db) if _db != null else []
	if not archives.is_empty():
		_column.add_child(_make_archive_section(archives))
		_column.add_child(_spacer(14))
	var quit := _title_button("退出游戏", "QuitGameButton")
	quit.pressed.connect(func(): get_tree().quit())
	_column.add_child(quit)
	if OS.is_debug_build():
		_column.add_child(_spacer(10))
		var test_btn := _title_button("测试开始", "TestStartButton")
		test_btn.pressed.connect(func(): test_start_requested.emit(1))
		_column.add_child(test_btn)


## A 668x140 button_bg_new stamp with centered text — the original title
## button. [SRC: StartPanel NewGame/Image 668x140 sprite=button_bg_new]
func _title_button(label: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(560, 104)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color("#f2e3b0"))
	button.add_theme_color_override("font_hover_color", Color("#fff3c4"))
	button.add_theme_color_override("font_pressed_color", Color("#e7d193"))
	button.add_theme_color_override("font_disabled_color", Color(0.62, 0.56, 0.44, 0.6))
	var style := _title_button_style()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, style)
	return button


func _title_button_style() -> StyleBox:
	# Texture-first: the original stamp IS the button surface.
	# [SRC: Texture2D/button_bg_new.png 668x140]
	if ResourceLoader.exists(BUTTON_BG_PATH):
		var tex := load(BUTTON_BG_PATH) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 180
			style.texture_margin_right = 180
			style.texture_margin_top = 46
			style.texture_margin_bottom = 46
			style.content_margin_left = 190
			style.content_margin_right = 190
			style.content_margin_top = 52
			style.content_margin_bottom = 52
			return style
	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color("#3a2b1a")
	fallback.border_color = Color("#d4ad5a")
	fallback.set_border_width_all(2)
	fallback.set_corner_radius_all(6)
	fallback.set_content_margin_all(18)
	return fallback


## Difficulty page: the three narrators, shown after "新的游戏".
## [SRC: DifficultyPanelController.c / DifficultyItemController.c;
##       difficulty desc text from content/init/1.json]
func _build_difficulty_view() -> void:
	_clear_dynamic()
	_center_column()
	var head := Label.new()
	head.text = "选择你的叙事者"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 30)
	head.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	_column.add_child(head)
	_column.add_child(_spacer(12))
	for i in 3:
		_column.add_child(_make_diff_card(i))
		_column.add_child(_spacer(8))
	var back := _title_button("返回标题", "BackToTitleButton")
	back.pressed.connect(_build_title_view)
	_column.add_child(back)


func _clear_dynamic() -> void:
	for child in get_children():
		if child.name != "Background":
			child.queue_free()
	_column = null


func _center_column() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	center.add_child(vbox)
	_column = vbox


func _make_diff_card(index: int) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style(FaustTheme.GOLD))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	# Original narrator portrait (common/710000N.png keyed by index).
	# [SRC: Resources/image/common difficulty portraits]
	var portrait_path := "res://assets/original/ui/710000%d.png" % (index + 1)
	if ResourceLoader.exists(portrait_path):
		var portrait := TextureRect.new()
		portrait.texture = load(portrait_path) as Texture2D
		portrait.custom_minimum_size = Vector2(72, 72)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(portrait)
	var name_lbl := Label.new()
	name_lbl.text = DIFF_NAMES[index]
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)
	var btn := Button.new()
	btn.text = "开始"
	btn.custom_minimum_size = Vector2(90, 40)
	btn.pressed.connect(_on_difficulty.bind(index))
	row.add_child(btn)
	col.add_child(row)
	var desc := Label.new()
	desc.text = _difficulty_desc(index)
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", FaustTheme.TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(desc)
	panel.add_child(col)
	return panel


## The original narrator intro from init/1.json with its rich-text tags
## stripped, plus the die-success rate line.
func _difficulty_desc(index: int) -> String:
	var raw := ""
	if _db != null:
		var conf: Dictionary = _db.get_difficulty(index)
		raw = str(conf.get("desc", ""))
	if raw == "":
		return "叙事者尚未就位。"
	var cleaned := raw.replace("<sprite=0>", "·").replace("<indent=10%>", " ").replace("</indent>", "")
	cleaned = cleaned.replace("<size=85%>", "").replace("</size>", "")
	return cleaned.strip_edges()


func _make_archive_section(archives: Array) -> Control:
	var section := VBoxContainer.new()
	section.name = "UserArchiveList"
	section.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "存档"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	section.add_child(title)
	for archive in archives:
		section.add_child(_make_archive_row(archive))
	return section


func _make_archive_row(archive: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "UserArchive_%d" % int(archive.get("index", -1))
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style(FaustTheme.GOLD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var summary := Label.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.text = "%s  |  第 %d 天 / 第 %d 回合\n%s" % [
		str(archive.get("name", "未命名存档")),
		int(archive.get("day", archive.get("live_days", 1))),
		int(archive.get("round_number", 1)),
		str(archive.get("save_time", "")),
	]
	summary.add_theme_color_override("font_color", FaustTheme.TEXT)
	row.add_child(summary)
	var load := Button.new()
	load.name = "LoadUserArchiveButton_%d" % int(archive.get("index", -1))
	load.text = "读取"
	load.custom_minimum_size = Vector2(72, 42)
	load.pressed.connect(func(): user_archive_load_requested.emit(int(archive.get("index", -1))))
	row.add_child(load)
	var delete := Button.new()
	delete.name = "DeleteUserArchiveButton_%d" % int(archive.get("index", -1))
	delete.text = "删除"
	delete.tooltip_text = "删除存档"
	delete.custom_minimum_size = Vector2(72, 42)
	delete.pressed.connect(_confirm_delete_archive.bind(int(archive.get("index", -1))))
	row.add_child(delete)
	return panel


func _confirm_delete_archive(index: int) -> void:
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "确定删除这个存档吗？此操作无法撤销。"
	add_child(confirm)
	confirm.confirmed.connect(func(): user_archive_delete_requested.emit(index))
	confirm.canceled.connect(confirm.queue_free)
	confirm.confirmed.connect(confirm.queue_free)
	confirm.popup_centered()


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _on_difficulty(index: int) -> void:
	difficulty_selected.emit(index)


func _has_continue_save() -> bool:
	if _db != null:
		return SaveSystem.has_valid_save(_db)
	return false
