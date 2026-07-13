## Main menu / new-game screen. Lets the player pick a difficulty and start.
## Uses a full-anchor layout with a centered VBox so it fills any window.
extends Control

signal difficulty_selected(index: int)
signal test_start_requested(index: int)

signal continue_pressed()
signal user_archive_load_requested(index: int)
signal user_archive_delete_requested(index: int)


const DIFF_NAMES := ["梅姬（简单）", "哈桑（普通）", "女术士（困难）"]
const DIFF_DESC := [
	"温柔的苏丹者。骰子成功率 60%，可无限倒回，初始 3 枚金骰。",
	"严谨的诗翰。骰子成功率 50%，可倒回 10 次，初始 2 枚金骰。",
	"以窥察你的苦痛为乐。骰子成功率 40%，无倒回，初始 1 枚金骰。",
]

const CONTENT_WIDTH := 960

var _db = null


func setup(db = null) -> void:
	_db = db


func _ready() -> void:
	theme = FaustTheme.get_theme()
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Dark background.
	var bg := ColorRect.new()
	bg.color = FaustTheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Centered content column.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	center.add_child(vbox)
	# Title.
	var title := Label.new()
	title.text = "苏丹的游戏"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	vbox.add_child(title)
	# Subtitle.
	var sub := Label.new()
	sub.text = "Godot 克隆版 · 请选择你的苏丹"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	vbox.add_child(sub)
	vbox.add_child(_spacer(12))
	# Continue button (only if a valid save exists).
	if _has_continue_save():
		var cont := Button.new()
		cont.name = "ContinueGameButton"
		cont.text = "继续游戏"
		cont.custom_minimum_size = Vector2(0, 50)
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont.add_theme_font_size_override("font_size", 22)
		cont.pressed.connect(func(): continue_pressed.emit())
		vbox.add_child(cont)
		vbox.add_child(_spacer(8))
	var archives := SaveSystem.list_user_archives(_db) if _db != null else []
	if not archives.is_empty():
		vbox.add_child(_make_archive_section(archives))
		vbox.add_child(_spacer(8))
	if OS.is_debug_build():
		var test_btn := Button.new()
		test_btn.name = "TestStartButton"
		test_btn.text = "测试开始"
		test_btn.custom_minimum_size = Vector2(0, 42)
		test_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		test_btn.pressed.connect(func(): test_start_requested.emit(1))
		vbox.add_child(test_btn)
	# Difficulty cards.
	for i in 3:
		vbox.add_child(_make_diff_card(i))
	# Footer note.
	vbox.add_child(_spacer(8))
	var foot := Label.new()
	foot.text = "选择难度后游戏开始。原作数值已由逆向语料库校准。"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 12)
	foot.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	vbox.add_child(foot)


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
	col.add_child(row)
	var desc := Label.new()
	desc.text = DIFF_DESC[index]
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", FaustTheme.TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(desc)
	panel.add_child(col)
	return panel


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
