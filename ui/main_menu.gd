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
signal story_pressed()
signal shop_pressed()
signal collect_pressed()
signal settings_pressed()
signal notice_pressed()
signal mod_pressed()
signal credits_pressed()

const DESIGN_SPACE := Vector2(3840, 2160)
const MAIN_GROUP_SIZE := Vector2(2200, 1800)
const STACK_SPACING := 30
const TITLE_BG_PATH := "res://assets/original/ui/bg_new_0.png"
const BUTTON_BG_PATH := "res://assets/original/ui/button_bg_new.png"
const BUTTON_SIZE := Vector2(668, 174)
const BUTTON_IMAGE_SIZE := Vector2(668, 140)
const BUTTON_FONT_SIZE := 60
const GlobalExtensionsScript = preload("res://sim/global_extensions.gd")

var _db = null
var _column: VBoxContainer
var _show_archives := false
var _design: Control = null


func setup(db = null) -> void:
	_db = db


func _ready() -> void:
	theme = FaustTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# The whole menu is authored in the 3840x2160 design space; a scaled
	# design canvas keeps the original geometry while the root adapts to the
	# actual window (same convention as the in-game screen chrome).
	_design = Control.new()
	_design.name = "DesignCanvas"
	_design.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_design)
	resized.connect(_layout_design)
	call_deferred("_layout_design")
	# [SRC: StartPanel full-rect Image bg_new_0 — stretched to fill the canvas]
	var bg := TextureRect.new()
	bg.name = "Background"
	if ResourceLoader.exists(TITLE_BG_PATH):
		bg.texture = load(TITLE_BG_PATH) as Texture2D
		bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.position = Vector2.ZERO
	bg.size = DESIGN_SPACE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design.add_child(bg)
	_build_title_view()


func _layout_design() -> void:
	if _design == null:
		return
	var view_size := size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		var parent_control := get_parent() as Control
		if parent_control != null:
			view_size = parent_control.size
		if view_size.x <= 0.0 or view_size.y <= 0.0:
			view_size = get_viewport().get_visible_rect().size
	_design.scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


## Title page: the game's front door. Difficulty is NOT chosen here.
func _build_title_view() -> void:
	_clear_dynamic()
	# [SRC: MainGroup RectTransform 2200x1800 anchors (0.5,0.5) pos (0,0)]
	var group := Control.new()
	group.name = "MainGroup"
	group.size = MAIN_GROUP_SIZE
	group.position = (DESIGN_SPACE - MAIN_GROUP_SIZE) * 0.5
	_design.add_child(group)
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

	# [SRC: MainGroup/ButtonsGroup 1900x200 HorizontalLayoutGroup spacing 240
	#       MiddleCenter; Story/Shop/Collect 405x174 with Image 668x140
	#       button_bg_new + Text fs60 + RedDot 114x114 @(56.5,-21).]
	_build_buttons_group(vbox)

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

	# [SRC: MainGroup/Contacts 1820x60 HorizontalLayoutGroup spacing 20 +
	#       Version 400x50 at the bottom.]
	_build_contacts_row(vbox)
	_build_version(vbox)

	if not archives.is_empty() and _show_archives:
		vbox.add_child(_make_archive_section(archives))


func _build_buttons_group(vbox: VBoxContainer) -> void:
	var group := HBoxContainer.new()
	group.name = "ButtonsGroup"
	group.custom_minimum_size = Vector2(1900, 200)
	group.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	group.add_theme_constant_override("separation", 240)
	vbox.add_child(group)
	var entries := [
		["千零一夜", "StoryButton", story_pressed],
		["命运商店", "ShopButton", shop_pressed],
		["游戏画廊", "CollectButton", collect_pressed],
	]
	for entry in entries:
		var btn_signal: Signal = entry[2]
		var button := _title_button(String(entry[0]), String(entry[1]))
		button.custom_minimum_size = Vector2(405, 174)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(func(): btn_signal.emit())
		# [SRC: Story/Shop/Collect/RedDot — new.asset 114x114, anchors (1,1),
		# pos (56.5,-21): centre at (405+56.5, 21) on the button box.]
		var red := TextureRect.new()
		red.name = "RedDot"
		red.texture = load("res://assets/original/ui/new.png") as Texture2D
		red.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		red.stretch_mode = TextureRect.STRETCH_SCALE
		red.size = Vector2(114, 114)
		red.set_anchors_preset(Control.PRESET_TOP_LEFT)
		red.position = Vector2(405 + 56.5 - 57.0, 21 - 57.0)
		red.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if String(entry[1]) == "ShopButton":
			red.visible = _db != null and GlobalExtensionsScript.has_available_upgrade(
				GlobalState.load_default(), _db)
		button.add_child(red)
		group.add_child(button)


func _build_contacts_row(vbox: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.name = "Contacts"
	row.custom_minimum_size = Vector2(1820, 60)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 20)
	# [SRC: SettingAndNotice 516x100, spacing 70, pad right 44 —
	#       Mod/Setting/Notice 120x100 icons with rite_title_short 108x48
	#       outline at (0,-72.6); Notice carries a new.asset red dot.]
	var san := HBoxContainer.new()
	san.name = "SettingAndNotice"
	san.custom_minimum_size = Vector2(516, 100)
	san.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	san.add_theme_constant_override("separation", 70)
	var san_entries := [
		["mod_pressed", "Mod", "workshop.png", mod_pressed],
		["settings_pressed", "Setting", "settings_icon.png", settings_pressed],
		["notice_pressed", "Notice", "notice_icon_0.png", notice_pressed],
	]
	for entry in san_entries:
		var icon_signal: Signal = entry[3]
		var icon := _icon_button(entry[2], Vector2(120, 100), String(entry[1]))
		icon.pressed.connect(func(): icon_signal.emit())
		if String(entry[1]) == "Notice":
			var dot := TextureRect.new()
			dot.texture = load("res://assets/original/ui/new.png") as Texture2D
			dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			dot.stretch_mode = TextureRect.STRETCH_SCALE
			dot.size = Vector2(57, 57)
			dot.set_anchors_preset(Control.PRESET_TOP_LEFT)
			dot.position = Vector2(120 - 20.4 - 28.5, 10.7 - 28.5)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.add_child(dot)
		san.add_child(icon)
	row.add_child(san)
	row.add_child(_divider())
	# [SRC: Contacts social buttons — Bilibili 64x56, Red 72x72, Tencent
	#       64x64, X 64x56, Discord 72x56, YouTube 72x56.]
	var socials := [
		["contact_bilibili.png", Vector2(64, 56)],
		["contact_red.png", Vector2(72, 72)],
		["content_tencent_channel.png", Vector2(64, 64)],
		["contact_X.png", Vector2(64, 56)],
		["contact_discord.png", Vector2(72, 56)],
		["contact_youtube.png", Vector2(72, 56)],
	]
	for social in socials:
		row.add_child(_icon_button(social[0], social[1], "Contact"))
	row.add_child(_divider())
	# [SRC: Credits — button_icon 516x108 + rite_title 450x56 at (0,-22).]
	var credits := Button.new()
	credits.name = "Credits"
	credits.custom_minimum_size = Vector2(516, 108)
	credits.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var credits_stamp := _icon_rect("button_icon.png", Vector2(516, 108))
	credits.add_child(credits_stamp)
	var title_art := _atlas_frame("res://assets/original/ui/rite_outlines.png", "rite_title.png")
	if title_art != null:
		var outline := TextureRect.new()
		outline.name = "Outline"
		outline.texture = title_art
		outline.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		outline.stretch_mode = TextureRect.STRETCH_SCALE
		outline.size = Vector2(450, 56)
		outline.set_anchors_preset(Control.PRESET_TOP_LEFT)
		outline.position = Vector2((516 - 450) * 0.5, 108 + 22 - 28)
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		credits.add_child(outline)
	credits.pressed.connect(func(): credits_pressed.emit())
	row.add_child(credits)
	vbox.add_child(row)


func _build_version(vbox: VBoxContainer) -> void:
	var version := Label.new()
	version.name = "Version"
	version.text = "VERSION 1.0.2lab3"
	version.custom_minimum_size = Vector2(400, 50)
	version.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 22)
	version.add_theme_color_override("font_color", Color("#b9a87a"))
	vbox.add_child(version)


func _divider() -> Control:
	var line := Control.new()
	line.custom_minimum_size = Vector2(100, 120)
	var bar := _icon_rect("scroll_bar.png", Vector2(6, 120))
	line.add_child(bar)
	return line


func _icon_button(texture_name: String, size: Vector2, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var empty := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, empty)
	var icon := _icon_rect(texture_name, size)
	button.add_child(icon)
	return button


func _icon_rect(texture_name: String, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	var path := "res://assets/original/ui/" + texture_name
	if ResourceLoader.exists(path):
		rect.texture = load(path) as Texture2D
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = size
	rect.custom_minimum_size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


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
	for child in _design.get_children():
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
