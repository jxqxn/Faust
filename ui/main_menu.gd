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
signal archives_pressed()
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
const SourceText = preload("res://ui/source_text_style.gd")
const SourceButton = preload("res://ui/source_menu_button.gd")

var _db = null
var _column: VBoxContainer
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
	# Unity layout includes child scale; Godot Containers reset child scale.
	# ImageTranslate.Start/UpdateImg (0x1565d30/0x1565f70) applies config
	# sizeDelta before the layout group places its children.
	var image_styles: Dictionary = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/imagestyle.json"))
	var logo_style: Dictionary = image_styles.START_UI_LOGO
	logo.custom_minimum_size = Vector2(logo_style.width, logo_style.height) * 1.1
	logo.size = logo.custom_minimum_size
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(logo)

	var captions: Dictionary = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/ui.json"))
	var new_game := _title_button(captions.NEW_GAME.zhCN, "NewGameButton")
	# The original starts the run right away: the opening show (event
	# 5310006) presents the narrator/difficulty pick in-game via the
	# SetDifficulty op. [SRC: SetDifficulty.c @ Do -> ShowDifficulty]
	new_game.pressed.connect(func(): new_game_pressed.emit())
	vbox.add_child(new_game)

	# StartController.CheckCanContinueGame 0x5add30 toggles interactable,
	# never SetActive; dump.cs StartController.LoadGame is +0x90.
	var cont := _title_button(captions.LOAD_GAME.zhCN, "ContinueGameButton")
	cont.disabled = not _has_continue_save()
	cont.pressed.connect(func(): continue_pressed.emit())
	vbox.add_child(cont)

	var archive_btn := _title_button(captions.USER_ARCHIVE_LOAD.zhCN, "UserArchiveLoadGameButton")
	archive_btn.pressed.connect(func(): archives_pressed.emit())
	vbox.add_child(archive_btn)

	# [SRC: MainGroup/ButtonsGroup 1900x200 HorizontalLayoutGroup spacing 240
	#       MiddleCenter; Story/Shop/Collect 405x174 with Image 668x140
	#       button_bg_new + Text fs60 + RedDot 114x114 @(56.5,-21).]
	_build_buttons_group(vbox)

	var quit := _title_button("退出游戏", "QuitGameButton")
	quit.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit)

	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--dev-menu"):
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



func _build_buttons_group(vbox: VBoxContainer) -> void:
	var group := Control.new()
	group.name = "ButtonsGroup"
	group.custom_minimum_size = Vector2(1900, 200)
	group.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(group)
	var entries := [
		[SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/ui.json")).STORY.zhCN, "StoryButton", story_pressed],
		["命运商店", "ShopButton", shop_pressed],
		["游戏画廊", "CollectButton", collect_pressed],
	]
	for index in entries.size():
		var entry: Array = entries[index]
		var btn_signal: Signal = entry[2]
		var button := _title_button(String(entry[0]), String(entry[1]))
		button.custom_minimum_size = Vector2(405, 174)
		button.size = Vector2(405, 174)
		# Unity childControlWidth=false + childForceExpandWidth=true distributes
		# the surplus into cells, retaining each 405-wide hit rect.
		var cell_width := (1900.0 - 480.0) / 3.0
		button.position = Vector2(index * (cell_width + 240) + (cell_width - 405) / 2, 13)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(func(): btn_signal.emit())
		group.add_child(button)
		# StartPanel has reward/upgrade dots only; Collect has no RedDot child.
		if String(entry[1]) == "CollectButton":
			continue
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
		else:
			# StartController.Start 0x5af670 reads Global.HasQuestReward (+0x10)
			# and subscribes to HasQuestRewardChanged.
			var global := GlobalState.load_default()
			red.visible = global.has_quest_reward
			global.has_quest_reward_changed.connect(red.set_visible)
		button.add_child(red)


func _build_contacts_row(vbox: VBoxContainer) -> void:
	# Unity childControlHeight=false keeps this row 60 high even when its
	# centered icons are taller. A Godot HBox as a VBox child expands it.
	var carrier := Control.new()
	carrier.name = "ContactsRow"
	carrier.custom_minimum_size = Vector2(1820, 60)
	carrier.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	carrier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(carrier)
	var row := HBoxContainer.new()
	row.name = "Contacts"
	row.custom_minimum_size = Vector2(1820, 60)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 20)
	carrier.add_child(row)
	row.resized.connect(func(): row.position = Vector2((1820 - row.size.x) / 2, (60 - row.size.y) / 2))
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
	for key in ["normal", "hover", "pressed", "focus", "disabled"]:
		credits.add_theme_stylebox_override(key, StyleBoxEmpty.new())
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
		outline.hide()
		credits.mouse_entered.connect(outline.show)
		credits.mouse_exited.connect(outline.hide)
		credits.focus_entered.connect(outline.show)
		credits.focus_exited.connect(outline.hide)
	credits.pressed.connect(func(): credits_pressed.emit())
	row.add_child(credits)


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
	SourceText.apply(button, "@BIG_BUTTON")
	button.add_theme_color_override("font_color", Color("#f2e3b0"))
	button.add_theme_color_override("font_hover_color", Color("#fff3c4"))
	button.add_theme_color_override("font_pressed_color", Color("#e7d193"))
	button.add_theme_color_override("font_disabled_color", Color(0.62, 0.56, 0.44, 0.6))
	var empty := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, empty)
	SourceButton.decorate(button)
	return button


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


func _has_continue_save() -> bool:
	if _db != null:
		return SaveSystem.has_valid_save(_db)
	return false
