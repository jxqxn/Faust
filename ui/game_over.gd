## Game over screen: shows when a sudan card expires unfulfilled.
## Displays the final stats and offers a restart.
extends Control

signal restart()

const FaustTheme = preload("res://ui/theme.gd")
const SudanCards = preload("res://sim/sudan_cards.gd")

var _state
var _db


func setup(state, db) -> void:
	_state = state
	_db = db


func _ready() -> void:
	theme = FaustTheme.get_theme()
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = FaustTheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	col.custom_minimum_size = Vector2(520, 0)
	center.add_child(col)
	# Title.
	var title := Label.new()
	title.text = "游戏结束"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", FaustTheme.DANGER_LIGHT)
	col.add_child(title)
	# Reason.
	var reason := Label.new()
	reason.text = "一张苏丹卡到期未完成。苏丹的怒火降临了。"
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.add_theme_font_size_override("font_size", 16)
	reason.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(reason)
	col.add_child(_spacer(12))
	# Stats.
	var stats := Label.new()
	stats.text = "存活: 第 %d 回合 · 第 %d 天\n金币: %d\n金骰: %d" % [_state.round_number, _state.day, _state.coin_count, _state.gold_dice]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 18)
	stats.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	col.add_child(stats)
	col.add_child(_spacer(16))
	# Restart.
	var btn := Button.new()
	btn.text = "重新开始"
	btn.custom_minimum_size = Vector2(200, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): restart.emit())
	col.add_child(btn)


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
