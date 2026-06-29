## Main menu / new-game screen. Lets the player pick a difficulty and start.
## Uses a full-anchor layout with a centered VBox so it fills any window.
extends Control

signal difficulty_selected(index: int)

const FaustTheme = preload("res://ui/theme.gd")
const SaveSystem = preload("res://sim/save_system.gd")

signal continue_pressed()


const DIFF_NAMES := ["梅姬（简单）", "哈桑（普通）", "女术士（困难）"]
const DIFF_DESC := [
	"温柔的苏丹者。骰子成功率 60%，可无限倒回，初始 3 枚金骰。",
	"严谨的诗翰。骰子成功率 50%，可倒回 10 次，初始 2 枚金骰。",
	"以窥察你的苦痛为乐。骰子成功率 40%，无倒回，初始 1 枚金骰。",
]

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
	vbox.custom_minimum_size = Vector2(560, 0)
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
	# Continue button (only if a save exists).
	if SaveSystem.has_save():
		var cont := Button.new()
		cont.text = "继续游戏"
		cont.custom_minimum_size = Vector2(560, 50)
		cont.add_theme_font_size_override("font_size", 22)
		cont.pressed.connect(func(): continue_pressed.emit())
		vbox.add_child(cont)
		vbox.add_child(_spacer(8))
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
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
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
	desc.custom_minimum_size = Vector2(540, 0)
	col.add_child(desc)
	panel.add_child(col)
	return panel


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _on_difficulty(index: int) -> void:
	difficulty_selected.emit(index)
