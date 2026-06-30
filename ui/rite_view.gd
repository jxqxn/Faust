## Rite view: shows the rite's card slots, lets the player place cards from the
## hand, resolves via RiteResolver, and shows the result + gold.
## Gold dice flow (RISK#3 fix): dice are spent REACTIVELY after a failed/low
## settlement, not proactively before resolve. The player resolves, sees the
## outcome, and if the r1 check produced a sub-optimal result they can spend
## gold dice to add successes and re-resolve. This matches the original's
## GoldDiceException -> Promise.Reject -> re-resolve flow.
## [SRC: RiteResultDiceCountPromptController.c @ OnGoldConfirm (0x59d8b0)]
extends Control

signal closed()
signal resolved()

const FaustTheme = preload("res://ui/theme.gd")
const CardWidget = preload("res://ui/card_widget.gd")
const RiteResolver = preload("res://sim/rite_resolver.gd")
const SaveSystem = preload("res://sim/save_system.gd")
const RoundLoop = preload("res://sim/round_loop.gd")

const CONTENT_WIDTH := 960

var _state
var _db
var _rng
var _rite_id: int = 5000001
var _rite: Dictionary = {}
var _placed: Dictionary = {}  # slot_key -> card_id
var _managed_slots: Array[int] = []
var _gold_used_this_resolve: int = 0
var _gold_dice_map: Dictionary = {}
var _resolve_baseline: Dictionary = {}
var _resolve_dice_cache: Dictionary = {}
var _last_result = null  # last RiteResult

var _slots_container: VBoxContainer
var _result_label: RichTextLabel
var _gold_dice_label: Label
var _gold_dice_btn: Button
var _resolve_btn: Button


func setup(state, db, rng, rite_id: int) -> void:
	_state = state
	_db = db
	_rng = rng
	_rite_id = rite_id
	_rite = db.get_rite(rite_id)


func _ready() -> void:
	theme = FaustTheme.get_theme()
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = FaustTheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)
	# Title + description.
	var title := Label.new()
	title.text = "%s" % _rite.get("name", str(_rite_id))
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	root.add_child(title)
	var desc := Label.new()
	desc.text = "%s" % _rite.get("text", "")
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(desc)
	# Slot panel.
	var slots_panel := _panel()
	var slots_col := VBoxContainer.new()
	slots_col.add_theme_constant_override("separation", 6)
	slots_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slots_head := Label.new()
	slots_head.text = "入槽 · 选择卡牌"
	slots_head.add_theme_font_size_override("font_size", 18)
	slots_head.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	slots_col.add_child(slots_head)
	slots_panel.add_child(slots_col)
	_slots_container = VBoxContainer.new()
	_slots_container.add_theme_constant_override("separation", 8)
	_slots_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_col.add_child(_slots_container)
	_build_slots()
	root.add_child(slots_panel)
	# Action bar: resolve + gold dice (reactive).
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 12)
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gold_dice_label = Label.new()
	_gold_dice_label.add_theme_font_size_override("font_size", 18)
	_gold_dice_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	action_row.add_child(_gold_dice_label)
	_gold_dice_btn = Button.new()
	_gold_dice_btn.text = "投入金骰 (+1成功 · 重新结算)"
	_gold_dice_btn.custom_minimum_size = Vector2(260, 44)
	_gold_dice_btn.disabled = true
	_gold_dice_btn.pressed.connect(_use_gold_dice_reactive)
	action_row.add_child(_gold_dice_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(spacer)
	_resolve_btn = Button.new()
	_resolve_btn.text = "掷骰结算"
	_resolve_btn.custom_minimum_size = Vector2(180, 44)
	_resolve_btn.pressed.connect(_resolve)
	action_row.add_child(_resolve_btn)
	root.add_child(action_row)
	# Result.
	var result_panel := _panel()
	var rcol := VBoxContainer.new()
	rcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rh := Label.new()
	rh.text = "结算结果"
	rh.add_theme_font_size_override("font_size", 18)
	rh.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	rcol.add_child(rh)
	result_panel.add_child(rcol)
	_result_label = RichTextLabel.new()
	_result_label.add_theme_font_size_override("normal_font_size", 15)
	_result_label.custom_minimum_size = Vector2(0, 120)
	_result_label.fit_content = true
	_result_label.bbcode_enabled = true
	rcol.add_child(_result_label)
	root.add_child(result_panel)
	# Close.
	var close_btn := Button.new()
	close_btn.text = "返回"
	close_btn.custom_minimum_size = Vector2(120, 44)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.pressed.connect(func(): closed.emit())
	root.add_child(close_btn)
	_result_label.text = "[color=#a89880]放入卡牌后点击「掷骰结算」。[/color]"
	_refresh_gold_label()


func _build_slots() -> void:
	for c in _slots_container.get_children():
		c.queue_free()
	var slots: Dictionary = _rite.get("cards_slot", {})
	for slot_key in ["s1", "s2", "s3", "s4"]:
		if not slots.has(slot_key):
			continue
		var slot_def: Dictionary = slots[slot_key]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var info_col := VBoxContainer.new()
		info_col.custom_minimum_size = Vector2(280, 0)
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var slot_name := Label.new()
		slot_name.text = slot_key.to_upper()
		slot_name.add_theme_font_size_override("font_size", 16)
		slot_name.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
		info_col.add_child(slot_name)
		var slot_desc := Label.new()
		slot_desc.text = "%s" % slot_def.get("text", "")
		slot_desc.add_theme_font_size_override("font_size", 13)
		slot_desc.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
		slot_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_col.add_child(slot_desc)
		row.add_child(info_col)
		var opt := OptionButton.new()
		opt.custom_minimum_size = Vector2(420, 36)
		opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opt.add_item("（空）", 0)
		var idx := 1
		for cid in _state.hand:
			var card: Dictionary = _db.get_card(int(cid))
			var nm: String = card.get("name", str(cid))
			opt.add_item("%s" % nm, idx)
			opt.set_item_metadata(idx, int(cid))
			idx += 1
		if _slot_accepts_sudan(slot_def):
			for asc in _state.active_sudan_cards:
				var sudan_card: Dictionary = _db.get_card(int(asc.card_id))
				var sudan_name: String = sudan_card.get("name", str(asc.card_id))
				opt.add_item("%s" % sudan_name, idx)
				opt.set_item_metadata(idx, int(asc.card_id))
				idx += 1
		opt.item_selected.connect(_on_slot_selected.bind(slot_key, opt))
		row.add_child(opt)
		_slots_container.add_child(row)


func _on_slot_selected(slot_key: String, opt: OptionButton, index: int) -> void:
	if index == 0:
		_placed.erase(slot_key)
	else:
		var cid: int = opt.get_item_metadata(index)
		_placed[slot_key] = cid
	_resolve_baseline.clear()
	_last_result = null
	_gold_used_this_resolve = 0
	_gold_dice_map.clear()
	_resolve_dice_cache.clear()
	_update_gold_button()
	_refresh_gold_label()


func _resolve() -> void:
	# Fresh resolve: reset gold-dice-used, place cards, snapshot the pre-result
	# state, then resolve. Gold-dice re-resolves restore this baseline before
	# applying results, matching the original Promise.Reject unwind path.
	# [SRC: RiteResultDiceCountPromptController.c @ OnGoldConfirm (0x59d8b0)]
	_gold_used_this_resolve = 0
	_gold_dice_map.clear()
	_resolve_dice_cache.clear()
	_prepare_table_from_placements()
	_resolve_baseline = SaveSystem.serialize(_state)
	_do_resolve()


func _do_resolve() -> void:
	if not _resolve_baseline.is_empty():
		SaveSystem.deserialize(_resolve_baseline, _state, _db)
		_state.gold_dice = max(0, int(_resolve_baseline.get("gold_dice", 0)) - _gold_used_this_resolve)
	else:
		_prepare_table_from_placements()
	var ctx := {
		"db": _db, "state": _state, "rng": _rng,
		"rite_state": _placed.duplicate(),
		"attr_slots": ["s1", "s2"], "rite_id": _rite_id,
		"dice_cache": _resolve_dice_cache,
	}
	var res = RiteResolver.resolve(_rite, ctx, _gold_dice_map if not _gold_dice_map.is_empty() else _gold_used_this_resolve)
	_last_result = res
	_consume_placed_sudan_cards(res)
	_display_result(res)
	_update_gold_button()
	_refresh_gold_label()
	resolved.emit()


func _display_result(res) -> void:
	var entry: Dictionary = res.normal_entry
	var txt := ""
	if entry.is_empty():
		txt = "[color=#a89880]（没有匹配的结算分支）[/color]"
	else:
		var t1: String = entry.get("result_title", "")
		var t2: String = entry.get("result_text", "")
		if t1 != "":
			txt += "[color=#e0c486]" + t1 + "[/color]\n"
		if t2 != "":
			txt += t2 + "\n"
		# Show dice check info if the condition had an r1.
		var cond: Dictionary = entry.get("condition", {})
		for k in cond:
			if k.begins_with("r1:"):
				txt += "\n[color=#a89880]检定: %s[/color]" % k
				break
	txt += "\n[color=#c9a96a]当前金币: %d[/color]" % _state.coin_count
	if not res.extre_log.is_empty():
		txt += "\n[color=#a89880]（附加结算 %d 条已执行）[/color]" % res.extre_log.size()
	if _gold_used_this_resolve > 0:
		txt += "\n[color=#e0c486]（已投入金骰 +%d成功）[/color]" % _gold_used_this_resolve
	_result_label.text = txt


func _update_gold_button() -> void:
	# Gold dice can be spent reactively after a resolve (RISK#3 fix).
	# Enable the button if: player has gold dice AND a resolve has been done.
	var can_spend: bool = _state.gold_dice > 0 and _last_result != null
	_gold_dice_btn.disabled = not can_spend
	if can_spend:
		_gold_dice_btn.text = "投入金骰 (+1成功 · 重新结算)"
	else:
		_gold_dice_btn.text = "金骰耗尽" if _state.gold_dice <= 0 else "投入金骰 (+1成功)"


func _use_gold_dice_reactive() -> void:
	# Spend one gold die, increment the per-resolve counter, re-resolve.
	if _state.gold_dice <= 0:
		return
	_gold_used_this_resolve += 1
	var type_key := _gold_type_for_reactive_spend()
	_gold_dice_map[type_key] = int(_gold_dice_map.get(type_key, 0)) + 1
	_do_resolve()


func _refresh_gold_label() -> void:
	if _gold_dice_label:
		_gold_dice_label.text = "金骰: %d" % _state.gold_dice


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", FaustTheme.card_style())
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


func _prepare_table_from_placements() -> void:
	var slots_to_clear := _managed_slots.duplicate()
	for slot_key in _placed:
		var slot_num: int = slot_key.substr(1).to_int()
		if slot_num not in slots_to_clear:
			slots_to_clear.append(slot_num)
	for slot_num in slots_to_clear:
		_state.clear_slot(slot_num)
	_managed_slots.clear()
	for slot_key in _placed:
		var slot_num: int = slot_key.substr(1).to_int()
		_managed_slots.append(slot_num)
		_state.add_card_to_slot(int(_placed[slot_key]), slot_num, _db)


func _slot_accepts_sudan(slot_def: Dictionary) -> bool:
	var cond: Dictionary = slot_def.get("condition", {})
	return str(cond.get("type", "")) == "sudan"


func _consume_placed_sudan_cards(res) -> void:
	if res == null:
		return
	var matched: bool = not res.normal_entry.is_empty() or not res.prior_log.is_empty() or not res.extre_log.is_empty()
	if not matched:
		return
	for slot_key in _placed:
		var cid := int(_placed[slot_key])
		var card: Dictionary = _db.get_card(cid)
		if str(card.get("type", "")) == "sudan":
			RoundLoop.consume_sudan(_state, cid)


func _gold_type_for_reactive_spend() -> String:
	if _last_result != null and not _last_result.dice_types_seen.is_empty():
		return str(_last_result.dice_types_seen[0])
	return "r1"
