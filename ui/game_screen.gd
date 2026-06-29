## Main in-game screen. Shows the calendar, resources (gold/gold dice/redraws),
## active sudan cards with deadlines, the player's hand, rite access, and the
## event log. Advances days and opens rites. Uses a MarginContainer + VBox so
## content fills the 1280x800 window instead of stacking at the origin.
extends Control

signal open_rite(rite_id: int)
signal advance_pressed()
signal redraw_pressed()

const FaustTheme = preload("res://ui/theme.gd")
const CardWidget = preload("res://ui/card_widget.gd")
const SudanCards = preload("res://sim/sudan_cards.gd")

var _state
var _db
var _rng

var _round_label: Label
var _gold_label: Label
var _sudan_box: HBoxContainer
var _hand_container: HBoxContainer
var _log_label: Label


func setup(state, db, rng) -> void:
	_state = state
	_db = db
	_rng = rng


func _ready() -> void:
	theme = FaustTheme.get_theme()
	_build_ui()
	refresh()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = FaustTheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Outer margin.
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	# ---- Top HUD bar ----
	var hud := _panel()
	var hud_row := HBoxContainer.new()
	hud_row.add_theme_constant_override("separation", 24)
	_round_label = _stat_label()
	hud_row.add_child(_round_label)
	_gold_label = _stat_label()
	hud_row.add_child(_gold_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_row.add_child(spacer)
	hud.add_child(hud_row)
	root.add_child(hud)
	# ---- Sultan cards ----
	var sudan_panel := _section("苏丹的旨意", "在期限内完成对应行为，否则游戏结束")
	_sudan_box = HBoxContainer.new()
	_sudan_box.add_theme_constant_override("separation", 10)
	sudan_panel.add_child(_sudan_box)
	root.add_child(sudan_panel)
	# ---- Hand ----
	var hand_panel := _section("手牌", "将角色与道具放入仪式卡槽以通过检定")
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 200)
	_hand_container = HBoxContainer.new()
	_hand_container.add_theme_constant_override("separation", 8)
	_hand_container.custom_minimum_size = Vector2(0, 190)
	scroll.add_child(_hand_container)
	hand_panel.add_child(scroll)
	root.add_child(hand_panel)
	# ---- Action bar ----
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	var rite_btn := _action_button("治理家业", "打开仪式", 200)
	rite_btn.pressed.connect(func(): open_rite.emit(5000001))
	actions.add_child(rite_btn)
	var redraw_btn := _action_button("重抽苏丹卡", "换一张", 150)
	redraw_btn.pressed.connect(func(): redraw_pressed.emit())
	actions.add_child(redraw_btn)
	var adv_btn := _action_button("推进一天", "时间流逝", 150)
	adv_btn.pressed.connect(func(): advance_pressed.emit())
	actions.add_child(adv_btn)
	root.add_child(actions)
	# ---- Event log ----
	var log_panel := _section("事件日志", "")
	_log_label = Label.new()
	_log_label.add_theme_font_size_override("font_size", 14)
	_log_label.add_theme_color_override("font_color", FaustTheme.TEXT)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.custom_minimum_size = Vector2(0, 90)
	log_panel.add_child(_log_label)
	root.add_child(log_panel)


func _stat_label() -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	return l


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", FaustTheme.card_style())
	return p


func _section(title: String, subtitle: String) -> PanelContainer:
	var p := _panel()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	var head := Label.new()
	head.text = title
	head.add_theme_font_size_override("font_size", 18)
	head.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	col.add_child(head)
	if subtitle != "":
		var st := Label.new()
		st.text = subtitle
		st.add_theme_font_size_override("font_size", 12)
		st.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
		col.add_child(st)
	p.add_child(col)
	return p


func _action_button(label: String, _hint: String, minw: int) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(minw, 44)
	return b


func refresh() -> void:
	if _state == null:
		return
	_round_label.text = "第 %d 回合 · 第 %d 天" % [_state.round_number, _state.day]
	_gold_label.text = "金币 %d    金骰 %d    重抽 %d" % [_state.coin_count, _state.gold_dice, _state.redraws_left]
	# Sultan cards.
	for c in _sudan_box.get_children():
		c.queue_free()
	if _state.active_sudan_cards.is_empty():
		var empty := Label.new()
		empty.text = "暂无悬而未决的苏丹卡"
		empty.add_theme_font_size_override("font_size", 14)
		empty.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
		_sudan_box.add_child(empty)
	else:
		var life := int(_state.difficulty_config.get("sudan_life_time", 7))
		for asc in _state.active_sudan_cards:
			_sudan_box.add_child(_make_sudan_card(asc, life))
	# Hand.
	for c in _hand_container.get_children():
		c.queue_free()
	for cid in _state.hand:
		var card: Dictionary = _db.get_card(int(cid))
		if card.is_empty():
			continue
		_hand_container.add_child(CardWidget.make(card))


func _make_sudan_card(asc, life: int) -> Control:
	var dec = SudanCards.decode(int(asc.card_id))
	var panel := PanelContainer.new()
	var accent: Color = FaustTheme.SUDAN_RANK_COLORS.get(dec.rank, FaustTheme.DANGER_LIGHT)
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style(accent))
	panel.custom_minimum_size = Vector2(200, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	var head := Label.new()
	head.text = "苏丹卡 · %s" % dec.rank
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", accent)
	col.add_child(head)
	var act := Label.new()
	act.text = dec.action
	act.add_theme_font_size_override("font_size", 20)
	act.add_theme_color_override("font_color", FaustTheme.TEXT)
	col.add_child(act)
	# Deadline progress bar.
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = life
	bar.value = int(asc.days_left)
	bar.custom_minimum_size = Vector2(0, 18)
	col.add_child(bar)
	var days := Label.new()
	days.text = "剩余 %d 天" % int(asc.days_left)
	days.add_theme_font_size_override("font_size", 12)
	days.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	col.add_child(days)
	panel.add_child(col)
	return panel


func set_log(text: String) -> void:
	if _log_label:
		_log_label.text = text
