## Main menu: title page (new game / continue / archives / quit), re-emitted
## 1:1 in the original's 3840x2160 MainUI canvas space.
##
## [SRC: docs/ui_layout/StartScene.md — MainUI canvas ref 3840x2160 Expand;
##       StartPanel full-rect bg_new_0; MainGroup 2200x1800 center
##       VerticalLayoutGroup spacing=30 UpperCenter;
##       logo 730x458 scale 1.1; NewGame/LoadGame/UserArchiveLoadGame/QuitGame
##       668x174 with Image 668x140 button_bg_new + TMP 540x100 fs=60;
##       Line 2200x100 -> rite_log_sperator 6px. ButtonsGroup (图鉴/商店/剧情)
##       and Contacts rows need their panels/links and stay unimplemented
##       (registered in METHOD_MAP).]
extends Control

signal new_game_pressed()
signal test_start_requested(index: int)

signal continue_pressed()
signal user_archive_load_requested(index: int)
signal user_archive_delete_requested(index: int)

const DESIGN_SPACE := Vector2(3840, 2160)
const MAIN_GROUP_SIZE := Vector2(2200, 1800)
const STACK_SPACING := 30
const TITLE_BG_PATH := "res://assets/original/ui/bg_new_0.png"
const BUTTON_BG_PATH := "res://assets/original/ui/button_bg_new.png"
const BUTTON_SIZE := Vector2(668, 174)
const BUTTON_IMAGE_SIZE := Vector2(668, 140)
const BUTTON_FONT_SIZE := 60

var _db = null
var _column: VBoxContainer
var _show_archives := false


func setup(db = null) -> void:
	_db = db


func _ready() -> void:
	theme = FaustTheme.get_theme()
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# [SRC: StartPanel full-rect Image bg_new_0 — stretched to fill the canvas]
	var bg := TextureRect.new()
	bg.name = "Background"
	if ResourceLoader.exists(TITLE_BG_PATH):
		bg.texture = load(TITLE_BG_PATH) as Texture2D
		bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_title_view()


## Title page: the game's front door. Difficulty is NOT chosen here.
func _build_title_view() -> void:
	_clear_dynamic()
	# [SRC: MainGroup RectTransform 2200x1800 anchors (0.5,0.5) pos (0,0)]
	var group := Control.new()
	group.name = "MainGroup"
	group.size = MAIN_GROUP_SIZE
	group.position = (DESIGN_SPACE - MAIN_GROUP_SIZE) * 0.5
	add_child(group)
	# [SRC: MainGroup VerticalLayoutGroup spacing=30 UpperCenter]
	var vbox := VBoxContainer.new()
	vbox.name = "Stack"
	vbox.add_theme_constant_override("separation", STACK_SPACING)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	group.add_child(vbox)
	_column = vbox

	# [SRC: logo 730x458 m_LocalScale (1.1, 1.1), sprite logo_zhCN]
	var logo := TextureRect.new()
	logo.name = "MenuLogo"
	logo.texture = preload("res://assets/original/ui/logo/logo_zhCN.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_SCALE
	logo.custom_minimum_size = Vector2(730, 458)
	logo.size = Vector2(730, 458)
	logo.pivot_offset = Vector2(365, 229)
	logo.scale = Vector2(1.1, 1.1)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(logo)

	var new_game := _title_button("新的游戏", "NewGameButton")
	# The original starts the run right away: the opening show (event
	# 5310006) presents the narrator/difficulty pick in-game via the
	# SetDifficulty op. [SRC: SetDifficulty.c @ Do -> ShowDifficulty]
	new_game.pressed.connect(func(): new_game_pressed.emit())
	vbox.add_child(new_game)

	if _has_continue_save():
		var cont := _title_button("继续游戏", "ContinueGameButton")
		cont.pressed.connect(func(): continue_pressed.emit())
		vbox.add_child(cont)

	var archives := SaveSystem.list_user_archives(_db) if _db != null else []
	if not archives.is_empty():
		var archive_btn := _title_button("读取存档", "UserArchiveLoadGameButton")
		archive_btn.pressed.connect(_toggle_archive_section)
		vbox.add_child(archive_btn)

	var quit := _title_button("退出游戏", "QuitGameButton")
	quit.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit)

	if OS.is_debug_build():
		var test_btn := _title_button("测试开始", "TestStartButton")
		test_btn.add_theme_font_size_override("font_size", 40)
		test_btn.pressed.connect(func(): test_start_requested.emit(1))
		vbox.add_child(test_btn)

	# [SRC: Line 2200x100 -> Image stretched rite_log_sperator 6px]
	var line := Control.new()
	line.name = "Line"
	line.custom_minimum_size = Vector2(2200, 100)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var seperator := _atlas_frame("res://assets/original/ui/rite_settlement_icon.png", "rite_log_sperator.png")
	var sep := TextureRect.new()
	if seperator != null:
		sep.texture = seperator
		sep.stretch_mode = TextureRect.STRETCH_SCALE
		sep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sep.set_anchors_preset(Control.PRESET_CENTER)
		sep.anchor_left = 0.0
		sep.anchor_right = 1.0
		sep.offset_left = 0
		sep.offset_right = 0
		sep.offset_top = -3
		sep.offset_bottom = 3
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(sep)
	vbox.add_child(line)

	if not archives.is_empty() and _show_archives:
		vbox.add_child(_make_archive_section(archives))


func _toggle_archive_section() -> void:
	_show_archives = not _show_archives
	_build_title_view()


## A 668x174 hit rect with the 668x140 button_bg_new stamp behind centered
## 60px text — the original title button.
## [SRC: StartPanel NewGame 668x174 { Image 668x140 button_bg_new,
##       Text (TMP) 540x100 m_fontSize 60, Outline 404x56 rite_title y=-4 }]
func _title_button(label: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	button.add_theme_color_override("font_color", Color("#f2e3b0"))
	button.add_theme_color_override("font_hover_color", Color("#fff3c4"))
	button.add_theme_color_override("font_pressed_color", Color("#e7d193"))
	button.add_theme_color_override("font_disabled_color", Color(0.62, 0.56, 0.44, 0.6))
	var empty := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, empty)
	_framed_button_decoration(button, BUTTON_IMAGE_SIZE, BUTTON_BG_PATH,
		_atlas_frame("res://assets/original/ui/rite_outlines.png", "rite_title.png"))
	return button


## Original buttons are hit rects with sprite children drawn under the text:
## Image (the stamp) + Outline (rite_title flourish at y=-4). We mirror that
## with behind-parent TextureRects instead of styleboxes, which would stretch.
func _framed_button_decoration(button: Button, image_size: Vector2, image_path: String, outline: Texture2D) -> void:
	if ResourceLoader.exists(image_path):
		var stamp := TextureRect.new()
		stamp.name = "Image"
		stamp.texture = load(image_path) as Texture2D
		stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp.stretch_mode = TextureRect.STRETCH_SCALE
		stamp.custom_minimum_size = image_size
		stamp.size = image_size
		# Top-left anchor so the authored inset applies from the button origin
		# (a CENTER preset would make `position` an offset from the centre).
		stamp.set_anchors_preset(Control.PRESET_TOP_LEFT)
		stamp.position = (BUTTON_SIZE - image_size) * 0.5
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamp.show_behind_parent = true
		button.add_child(stamp)
	if outline != null:
		var flourish := TextureRect.new()
		flourish.name = "Outline"
		flourish.texture = outline
		flourish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flourish.stretch_mode = TextureRect.STRETCH_SCALE
		flourish.custom_minimum_size = Vector2(404, 56)
		flourish.size = Vector2(404, 56)
		flourish.set_anchors_preset(Control.PRESET_TOP_LEFT)
		flourish.position = (BUTTON_SIZE - Vector2(404, 56)) * 0.5 + Vector2(0, -4)
		flourish.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flourish.show_behind_parent = true
		button.add_child(flourish)


func _atlas_frame(atlas_path: String, frame_name: String) -> Texture2D:
	var atlas := OriginalAtlas.load_atlas(atlas_path)
	if atlas != null and atlas.has_frame(frame_name):
		return atlas.frame(frame_name)
	return null


func _clear_dynamic() -> void:
	for child in get_children():
		if child.name != "Background":
			child.queue_free()
	_column = null


func _make_archive_section(archives: Array) -> Control:
	var section := VBoxContainer.new()
	section.name = "UserArchiveList"
	section.add_theme_constant_override("separation", 12)
	section.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var title := Label.new()
	title.text = "存档"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	section.add_child(title)
	for archive in archives:
		section.add_child(_make_archive_row(archive))
	return section


func _make_archive_row(archive: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "UserArchive_%d" % int(archive.get("index", -1))
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style(FaustTheme.GOLD))
	panel.custom_minimum_size = Vector2(2200, 150)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
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
	summary.add_theme_font_size_override("font_size", 36)
	summary.add_theme_color_override("font_color", FaustTheme.TEXT)
	row.add_child(summary)
	var load := Button.new()
	load.name = "LoadUserArchiveButton_%d" % int(archive.get("index", -1))
	load.text = "读取"
	load.add_theme_font_size_override("font_size", 36)
	load.custom_minimum_size = Vector2(300, 120)
	load.pressed.connect(func(): user_archive_load_requested.emit(int(archive.get("index", -1))))
	row.add_child(load)
	var delete := Button.new()
	delete.name = "DeleteUserArchiveButton_%d" % int(archive.get("index", -1))
	delete.text = "删除"
	delete.add_theme_font_size_override("font_size", 36)
	delete.tooltip_text = "删除存档"
	delete.custom_minimum_size = Vector2(300, 120)
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


func _has_continue_save() -> bool:
	if _db != null:
		return SaveSystem.has_valid_save(_db)
	return false
