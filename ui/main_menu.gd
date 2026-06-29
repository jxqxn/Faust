extends Control

## Main menu / new-game screen. Lets the player pick a difficulty and start.
signal difficulty_selected(index: int)

const DIFF_NAMES := ["梅姬（简单）", "哈桑（普通）", "女术士（困难）"]
const DIFF_DESC := [
	"温柔的叙事者。骰子成功率 60%，可无限倒回，初始 3 枚金骰。",
	"严谨的诗人。骰子成功率 50%，可倒回 10 次，初始 2 枚金骰。",
	"以观察你的苦痛为乐。骰子成功率 40%，无倒回，初始 1 枚金骰。"
]

var _buttons: Array = []

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Title.
	var title := Label.new()
	title.text = "苏丹的游戏"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	# Difficulty buttons.
	var vbox := VBoxContainer.new()
	vbox.name = "DifficultyList"
	vbox.position = Vector2(440, 180)
	vbox.custom_minimum_size = Vector2(400, 0)
	add_child(vbox)
	for i in 3:
		var btn := Button.new()
		btn.text = DIFF_NAMES[i]
		btn.custom_minimum_size = Vector2(400, 60)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_difficulty.bind(i))
		vbox.add_child(btn)
		_buttons.append(btn)
		var desc := Label.new()
		desc.text = DIFF_DESC[i]
		desc.add_theme_font_size_override("font_size", 14)
		desc.custom_minimum_size = Vector2(400, 0)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc)

func _on_difficulty(index: int) -> void:
	difficulty_selected.emit(index)
#
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_relayout()

func _relayout() -> void:
	pass
