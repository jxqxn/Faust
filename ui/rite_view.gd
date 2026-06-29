extends Control

## Rite view: shows the rite's card slots, lets the player place cards from the
## hand, rolls dice, resolves via RiteResolver, and shows the result text + gold.
signal closed()

var _state
var _db
var _rng
var _rite_id: int = 5000001
var _rite: Dictionary = {}
var _placed: Dictionary = {} # slot_key -> card_id

var _slots_container: VBoxContainer
var _result_label: Label
var _gold_dice_label: Label

func setup(state, db, rng, rite_id: int) -> void:
	_state = state
	_db = db
	_rng = rng
	_rite_id = rite_id
	_rite = db.get_rite(rite_id)

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var title := Label.new()
	title.text = "%s" % _rite.get("name", str(_rite_id))
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)
	var desc := Label.new()
	desc.text = "%s" % _rite.get("text", "")
	desc.add_theme_font_size_override("font_size", 14)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(1200, 60)
	add_child(desc)
	# Slots.
	_slots_container = VBoxContainer.new()
	add_child(_slots_container)
	_build_slots()
	# Gold dice control.
	_gold_dice_label = Label.new()
	_gold_dice_label.text = "金骰: %d" % _state.gold_dice
	_gold_dice_label.add_theme_font_size_override("font_size", 18)
	add_child(_gold_dice_label)
	var gold_btn := Button.new()
	gold_btn.text = "使用金骰 +1成功"
	gold_btn.pressed.connect(_use_gold_dice)
	add_child(gold_btn)
	# Resolve button.
	var resolve_btn := Button.new()
	resolve_btn.text = "掷骰结算"
	resolve_btn.custom_minimum_size = Vector2(200, 50)
	resolve_btn.pressed.connect(_resolve)
	add_child(resolve_btn)
	# Result.
	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 16)
	_result_label.custom_minimum_size = Vector2(1200, 120)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_result_label)
	# Close.
	var close_btn := Button.new()
	close_btn.text = "返回"
	close_btn.pressed.connect(func(): closed.emit())
	add_child(close_btn)

func _build_slots() -> void:
	for c in _slots_container.get_children():
		c.queue_free()
	var slots: Dictionary = _rite.get("cards_slot", {})
	for slot_key in ["s1", "s2", "s3", "s4"]:
		if not slots.has(slot_key):
			continue
		var slot_def: Dictionary = slots[slot_key]
		var cond: Dictionary = slot_def.get("condition", {})
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = "%s: %s" % [slot_key, slot_def.get("text", "")]
		name_lbl.custom_minimum_size = Vector2(400, 0)
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(name_lbl)
		# Card selection dropdown.
		var opt := OptionButton.new()
		opt.add_item("（空）", 0)
		var idx := 1
		for cid in _state.hand:
			var card: Dictionary = _db.get_card(int(cid))
			opt.add_item("%s (%d)" % [card.get("name", str(cid)), int(cid)], idx)
			opt.set_item_metadata(idx, int(cid))
			idx += 1
		opt.item_selected.connect(func(i): _on_slot_selected(slot_key, opt, i))
		row.add_child(opt)
		_slots_container.add_child(row)

func _on_slot_selected(slot_key: String, opt: OptionButton, index: int) -> void:
	if index == 0:
		_placed.erase(slot_key)
	else:
		var cid: int = opt.get_item_metadata(index)
		_placed[slot_key] = cid

func _use_gold_dice() -> void:
	if _state.gold_dice <= 0:
		return
	_state.gold_dice -= 1
	_gold_dice_label.text = "金骰: %d (本检定 +1成功)" % _state.gold_dice

func _resolve() -> void:
	# Place selected cards onto the table.
	_state.table_cards.clear()
	for slot_key in _placed:
		var slot_num: int = slot_key.substr(1).to_int()
		_state.add_card_to_slot(int(_placed[slot_key]), slot_num, _db)
	var ctx := {
		"db": _db, "state": _state, "rng": _rng,
		"rite_state": _placed.duplicate(),
		"attr_slots": ["s1", "s2"], "rite_id": _rite_id,
	}
	var gold_used: int = _state.gold_dice  # track gold dice used this resolve (simplified)
	var res = preload("res://sim/rite_resolver.gd").resolve(_rite, ctx, 0)
	var entry: Dictionary = res.normal_entry
	var txt := ""
	if entry.is_empty():
		txt = "（没有匹配的结算分支）"
	else:
		var t1: String = entry.get("result_title", "")
		var t2: String = entry.get("result_text", "")
		if t1 != "":
			txt += t1 + "\n"
		txt += t2
	txt += "\n\n[金币: %d]" % _state.coin_count
	if not res.extre_log.is_empty():
		txt += "\n（附加结算 %d 条）" % res.extre_log.size()
	_result_label.text = txt
