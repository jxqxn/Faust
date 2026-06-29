extends Control

## Main in-game screen. Shows the calendar, resources (gold/gold dice/redraws),
## active sudan cards with deadlines, the player's hand, and a button to open
## the 治理家业 rite view. Advances days and rounds.
signal open_rite(rite_id: int)
signal advance_pressed()

var _state
var _db
var _rng

var _gold_label: Label
var _round_label: Label
var _sudan_label: Label
var _hand_container: HBoxContainer
var _log_label: Label

func setup(state, db, rng) -> void:
	_state = state
	_db = db
	_rng = rng

func _ready() -> void:
	_build_ui()
	refresh()

func _build_ui() -> void:
	# Top bar: round + gold + gold dice + redraws.
	var topbar := HBoxContainer.new()
	topbar.name = "TopBar"
	add_child(topbar)
	_round_label = Label.new()
	_round_label.add_theme_font_size_override("font_size", 20)
	topbar.add_child(_round_label)
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 20)
	topbar.add_child(_gold_label)
	_sudan_label = Label.new()
	_sudan_label.add_theme_font_size_override("font_size", 18)
	add_child(_sudan_label)
	# Sultan card list.
	# Hand.
	var hand_title := Label.new()
	hand_title.text = "手牌"
	hand_title.add_theme_font_size_override("font_size", 18)
	add_child(hand_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1200, 180)
	add_child(scroll)
	_hand_container = HBoxContainer.new()
	_hand_container.name = "Hand"
	scroll.add_child(_hand_container)
	# Action buttons.
	var actions := HBoxContainer.new()
	add_child(actions)
	var rite_btn := Button.new()
	rite_btn.text = "治理家业（仪式）"
	rite_btn.custom_minimum_size = Vector2(200, 50)
	rite_btn.pressed.connect(func(): open_rite.emit(5000001))
	actions.add_child(rite_btn)
	var adv_btn := Button.new()
	adv_btn.text = "推进一天"
	adv_btn.custom_minimum_size = Vector2(200, 50)
	adv_btn.pressed.connect(func(): advance_pressed.emit())
	actions.add_child(adv_btn)
	# Log.
	var log_title := Label.new()
	log_title.text = "事件日志"
	log_title.add_theme_font_size_override("font_size", 16)
	add_child(log_title)
	_log_label = Label.new()
	_log_label.add_theme_font_size_override("font_size", 14)
	_log_label.custom_minimum_size = Vector2(1200, 120)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_log_label)

func refresh() -> void:
	if _state == null:
		return
	_round_label.text = "第 %d 回合 · 第 %d 天" % [_state.round_number, _state.day]
	_gold_label.text = "金币: %d   金骰: %d   重抽: %d" % [_state.coin_count, _state.gold_dice, _state.redraws_left]
	# Sultan cards.
	var sudan_text := "苏丹卡: "
	if _state.active_sudan_cards.is_empty():
		sudan_text += "无"
	else:
		for asc in _state.active_sudan_cards:
			var dec = preload("res://sim/sudan_cards.gd").decode(asc.card_id)
			sudan_text += "%s%s(%d天) " % [dec.rank, dec.action, asc.days_left]
	_sudan_label.text = sudan_text
	# Hand.
	for c in _hand_container.get_children():
		c.queue_free()
	# Show first 40 cards of the hand to keep the list manageable.
	var shown := 0
	for cid in _state.hand:
		if shown >= 40:
			break
		var card: Dictionary = _db.get_card(int(cid))
		var lbl := Label.new()
		lbl.text = "%s" % card.get("name", str(cid))
		lbl.add_theme_font_size_override("font_size", 13)
		_hand_container.add_child(lbl)
		shown += 1

func set_log(text: String) -> void:
	if _log_label:
		_log_label.text = text
