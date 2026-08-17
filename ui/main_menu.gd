## Main menu: title page first (new game / continue / archives), then the
## difficulty picker as its own page — matching the original's two-stage
## flow where difficulty is chosen after entering a new game, not on the
## title screen. Uses a full-anchor layout with a centered VBox.
extends Control

signal difficulty_selected(index: int)
signal test_start_requested(index: int)

signal continue_pressed()
signal user_archive_load_requested(index: int)
signal user_archive_delete_requested(index: int)

const UiMotionScript = preload("res://ui/ui_motion.gd")

const DIFF_NAMES := ["梅姬（简单）", "哈桑（普通）", "女术士（困难）"]

const CONTENT_WIDTH := 960

var _db = null
var _column: VBoxContainer


func setup(db = null) -> void:
	_db = db


func _ready() -> void:
	theme = FaustTheme.get_theme()
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Dark background.
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = FaustTheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_title_view()


## Title page: the game's front door. Difficulty is NOT chosen here.
func _build_title_view() -> void:
	_clear_dynamic()
	_center_column()
	var title := Label.new()
	title.name = "MenuTitle"
	title.text = "苏丹的游戏"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	_column.add_child(title)
	var logo := TextureRect.new()
	logo.name = "MenuLogo"
	logo.texture = preload("res://assets/original/ui/logo/logo_zhCN.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(560, 220)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_column.add_child(logo)
	_column.add_child(_spacer(6))
	var sub := Label.new()
	sub.text = "Godot 克隆版 · 请选择你的苏丹"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	_column.add_child(sub)
	_column.add_child(_spacer(12))
	var new_game := Button.new()
	new_game.name = "NewGameButton"
	new_game.text = "新的游戏"
	new_game.custom_minimum_size = Vector2(0, 54)
	new_game.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_game.add_theme_font_size_override("font_size", 24)
	# The original starts the run right away; the opening show (event
	# 5310006) presents the narrator/difficulty pick in-game.
	new_game.pressed.connect(func(): difficulty_selected.emit(0))
	_column.add_child(new_game)
	UiMotionScript.bind(new_game, UiMotionScript.Profile.PRIMARY)
	_column.add_child(_spacer(10))
	# Continue button (only if a valid save exists).
	if _has_continue_save():
		var cont := Button.new()
		cont.name = "ContinueGameButton"
		cont.text = "继续游戏"
		cont.custom_minimum_size = Vector2(0, 50)
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont.add_theme_font_size_override("font_size", 22)
		cont.pressed.connect(func(): continue_pressed.emit())
		_column.add_child(cont)
		UiMotionScript.bind(cont, UiMotionScript.Profile.PRIMARY)
		_column.add_child(_spacer(10))
	var archives := SaveSystem.list_user_archives(_db) if _db != null else []
	if not archives.is_empty():
		_column.add_child(_make_archive_section(archives))
		_column.add_child(_spacer(10))
	if OS.is_debug_build():
		var test_btn := Button.new()
		test_btn.name = "TestStartButton"
		test_btn.text = "测试开始"
		test_btn.custom_minimum_size = Vector2(0, 42)
		test_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		test_btn.pressed.connect(func(): test_start_requested.emit(1))
		_column.add_child(test_btn)
		UiMotionScript.bind(test_btn)


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
	var back := Button.new()
	back.name = "BackToTitleButton"
	back.text = "返回标题"
	back.custom_minimum_size = Vector2(0, 40)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(_build_title_view)
	_column.add_child(back)
	UiMotionScript.bind(back)


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
	UiMotionScript.bind(btn, UiMotionScript.Profile.PRIMARY)
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
	row.add_child(summary)
	var load := Button.new()
	load.name = "LoadUserArchiveButton_%d" % int(archive.get("index", -1))
	load.text = "读取"
	load.custom_minimum_size = Vector2(72, 42)
	load.pressed.connect(func(): user_archive_load_requested.emit(int(archive.get("index", -1))))
	row.add_child(load)
	UiMotionScript.bind(load)
	var delete := Button.new()
	delete.name = "DeleteUserArchiveButton_%d" % int(archive.get("index", -1))
	delete.text = "删除"
	delete.tooltip_text = "删除存档"
	delete.custom_minimum_size = Vector2(72, 42)
	delete.pressed.connect(_confirm_delete_archive.bind(int(archive.get("index", -1))))
	row.add_child(delete)
	UiMotionScript.bind(delete)
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
