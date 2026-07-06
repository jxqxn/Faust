## Developer-only helper window for deterministic local setup.
extends Control

signal closed()
signal start_requested(difficulty_index: int, use_test_cards: bool)
signal give_card_requested(card_id: int)
signal generate_rite_requested(rite_id: int)
signal draw_sudan_requested(card_id: int)
signal clear_hand_requested()

const FaustTheme = preload("res://ui/theme.gd")

var _state = null
var _db = null
var _difficulty: OptionButton
var _test_cards: CheckBox
var _card_id: LineEdit
var _rite_id: LineEdit
var _sudan_id: LineEdit
var _summary: Label


func setup(state = null, db = null) -> void:
	_state = state
	_db = db


func _ready() -> void:
	name = "DebugToolsOverlay"
	theme = FaustTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh_summary(_state, _db)


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "DebugToolsPanel"
	panel.custom_minimum_size = Vector2(440, 520)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -220
	panel.offset_top = -260
	panel.offset_right = 220
	panel.offset_bottom = 260
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style(FaustTheme.GOLD))
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "开发工具"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.name = "CloseDebugToolsButton"
	close.text = "×"
	close.custom_minimum_size = Vector2(40, 40)
	close.pressed.connect(func(): closed.emit())
	header.add_child(close)

	_difficulty = OptionButton.new()
	_difficulty.name = "DebugDifficulty"
	_difficulty.add_item("简单", 0)
	_difficulty.add_item("普通", 1)
	_difficulty.add_item("困难", 2)
	_difficulty.select(1)
	root.add_child(_labeled("难度", _difficulty))

	_test_cards = CheckBox.new()
	_test_cards.name = "DebugUseTestCards"
	_test_cards.text = "Test 全卡开局"
	root.add_child(_test_cards)

	var start_row := HBoxContainer.new()
	start_row.add_theme_constant_override("separation", 8)
	var normal_start := _button("正常开局", "DebugNormalStartButton")
	normal_start.pressed.connect(func(): start_requested.emit(_difficulty.get_selected_id(), false))
	start_row.add_child(normal_start)
	var test_start := _button("按当前设置开局", "DebugStartButton")
	test_start.pressed.connect(func(): start_requested.emit(_difficulty.get_selected_id(), _test_cards.button_pressed))
	start_row.add_child(test_start)
	root.add_child(start_row)

	_card_id = LineEdit.new()
	_card_id.name = "DebugCardId"
	_card_id.placeholder_text = "2000001"
	root.add_child(_id_action("给卡", _card_id, "DebugGiveCardButton", func(id: int): give_card_requested.emit(id)))

	_rite_id = LineEdit.new()
	_rite_id.name = "DebugRiteId"
	_rite_id.placeholder_text = "5000001"
	root.add_child(_id_action("生成仪式", _rite_id, "DebugGenerateRiteButton", func(id: int): generate_rite_requested.emit(id)))

	_sudan_id = LineEdit.new()
	_sudan_id.name = "DebugSudanId"
	_sudan_id.placeholder_text = "留空抽下一张"
	root.add_child(_id_action("抽苏丹卡", _sudan_id, "DebugDrawSudanButton", func(id: int): draw_sudan_requested.emit(id), true))

	var clear_hand := _button("清空手牌", "DebugClearHandButton")
	clear_hand.pressed.connect(func(): clear_hand_requested.emit())
	root.add_child(clear_hand)

	_summary = Label.new()
	_summary.name = "DebugSummary"
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.add_theme_font_size_override("font_size", 14)
	_summary.add_theme_color_override("font_color", FaustTheme.TEXT)
	root.add_child(_labeled("当前状态", _summary))


func refresh_summary(state = null, db = null) -> void:
	_state = state
	_db = db
	if _summary == null:
		return
	if _state == null:
		_summary.text = "尚未进入游戏。"
		return
	_summary.text = "第 %d 天  回合 %d\n手牌 %d  苏丹卡 %d\n已生成仪式 %d  已开始仪式 %d" % [
		_state.day,
		_state.round_number,
		_state.hand.size(),
		_state.active_sudan_cards.size(),
		_state.available_rites.size(),
		_state.started_rites.size(),
	]


func _id_action(label_text: String, input: LineEdit, button_name: String, callback: Callable, allow_empty := false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(86, 0)
	row.add_child(label)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(input)
	var button := _button("执行", button_name)
	button.pressed.connect(func():
		var raw := input.text.strip_edges()
		if raw == "" and allow_empty:
			callback.call(0)
			return
		if not raw.is_valid_int():
			return
		callback.call(raw.to_int())
	)
	row.add_child(button)
	return row


func _labeled(label_text: String, control: Control) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	box.add_child(label)
	box.add_child(control)
	return box


func _button(label: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(0, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button
