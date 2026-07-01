## Rite overlay: appears on top of the main desk screen instead of replacing it.
## It owns the rite slots and settlement controls, while the main desktop HUD,
## map, hand rail, and day controls remain visible underneath.
##
## Gold dice flow (RISK#3 fix): dice are spent REACTIVELY after a failed/low
## settlement, not proactively before resolve. The player resolves, sees the
## outcome, and if the r1 check produced a sub-optimal result they can spend
## gold dice to add successes and re-resolve. This matches the original's
## GoldDiceException -> Promise.Reject -> re-resolve flow.
## [SRC: RiteResultDiceCountPromptController.c @ OnGoldConfirm (0x59d8b0)]
extends Control

class RiteSlotButton:
	extends Button

	var owner_view: Control
	var slot_key: String = ""

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		if owner_view == null or not owner_view.has_method("can_drop_card_on_slot"):
			return false
		return owner_view.can_drop_card_on_slot(slot_key, data)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if owner_view != null and owner_view.has_method("drop_card_on_slot"):
			owner_view.drop_card_on_slot(slot_key, data)

signal closed()
signal resolved()

const FaustTheme = preload("res://ui/theme.gd")
const CardWidget = preload("res://ui/card_widget.gd")
const RiteResolver = preload("res://sim/rite_resolver.gd")
const ConditionEval = preload("res://sim/condition.gd")
const SaveSystem = preload("res://sim/save_system.gd")
const RoundLoop = preload("res://sim/round_loop.gd")
const SudanCards = preload("res://sim/sudan_cards.gd")

const MOCKUP_SIZE := Vector2(1280, 720)

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

var _shade: ColorRect
var _slot_layer: Control
var _rite_panel: PanelContainer
var _gold_dice_label: Label
var _gold_dice_btn: Button
var _resolve_btn: Button
var _close_btn: Button
var _result_label: RichTextLabel
var _log_label: Label
var _selected_card_id: int = 0
var _slot_buttons: Dictionary = {}
var _slot_titles: Dictionary = {}
var _slot_details: Dictionary = {}

# Kept for compatibility with older tests/tools that inspect the old view.
var _slots_container: VBoxContainer


func setup(state, db, rng, rite_id: int) -> void:
	_state = state
	_db = db
	_rng = rng
	_rite_id = rite_id
	_rite = db.get_rite(rite_id)


func _ready() -> void:
	theme = FaustTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	resized.connect(_apply_layout)
	call_deferred("_apply_layout")


func _build_ui() -> void:
	_shade = ColorRect.new()
	_shade.name = "RiteModalShade"
	_shade.color = Color(0, 0, 0, 0.48)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shade)

	_slot_layer = Control.new()
	_slot_layer.name = "RiteSlotOverlay"
	_slot_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_slot_layer)
	_build_slot_placeholders()

	_rite_panel = _panel("RiteOverlayPanel")
	_rite_panel.clip_contents = true
	add_child(_rite_panel)
	_build_panel_content()

	_log_label = Label.new()
	_log_label.name = "RiteOverlayToast"
	_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log_label.add_theme_font_size_override("font_size", 14)
	_log_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	add_child(_log_label)

	_refresh_slot_visuals()
	_refresh_gold_label()


func _build_slot_placeholders() -> void:
	for slot_key in ["s1", "s2", "s3", "s4"]:
		var btn := RiteSlotButton.new()
		btn.name = "OverlaySlot_%s" % slot_key.to_upper()
		btn.owner_view = self
		btn.slot_key = slot_key
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_stylebox_override("normal", _slot_style())
		btn.add_theme_stylebox_override("hover", _slot_style(FaustTheme.GOLD))
		btn.add_theme_stylebox_override("pressed", _slot_style(FaustTheme.GOLD_BRIGHT))
		btn.add_theme_stylebox_override("focus", _slot_style(FaustTheme.GOLD_BRIGHT))
		btn.pressed.connect(_on_slot_pressed.bind(slot_key))
		_slot_layer.add_child(btn)
		_slot_buttons[slot_key] = btn

		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.offset_left = 6
		box.offset_right = -6
		box.offset_top = 6
		box.offset_bottom = -6
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		btn.add_child(box)

		var title := Label.new()
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
		box.add_child(title)
		_slot_titles[slot_key] = title

		var detail := Label.new()
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_size_override("font_size", 9)
		detail.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
		detail.custom_minimum_size = Vector2(0, 20)
		box.add_child(detail)
		_slot_details[slot_key] = detail


func _build_panel_content() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_rite_panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)

	var title := Label.new()
	title.text = "%s" % _rite.get("name", str(_rite_id))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	col.add_child(title)

	var desc := Label.new()
	desc.text = "%s" % _rite.get("text", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", FaustTheme.TEXT)
	col.add_child(desc)

	var tips := Label.new()
	tips.text = "每回合自动进行，检定数值越高，金币收益越大。"
	tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips.add_theme_font_size_override("font_size", 11)
	tips.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	col.add_child(tips)

	var sep := HSeparator.new()
	col.add_child(sep)

	_slots_container = VBoxContainer.new()
	_slots_container.add_theme_constant_override("separation", 3)
	col.add_child(_slots_container)
	_build_slot_summary()

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	col.add_child(action_row)

	_gold_dice_label = Label.new()
	_gold_dice_label.add_theme_font_size_override("font_size", 14)
	_gold_dice_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	action_row.add_child(_gold_dice_label)

	_gold_dice_btn = Button.new()
	_gold_dice_btn.text = "投入金骰"
	_gold_dice_btn.disabled = true
	_gold_dice_btn.custom_minimum_size = Vector2(96, 34)
	_gold_dice_btn.pressed.connect(_use_gold_dice_reactive)
	action_row.add_child(_gold_dice_btn)

	_result_label = RichTextLabel.new()
	_result_label.name = "RiteResult"
	_result_label.bbcode_enabled = true
	_result_label.fit_content = false
	_result_label.scroll_active = true
	_result_label.add_theme_font_size_override("normal_font_size", 12)
	_result_label.custom_minimum_size = Vector2(0, 58)
	col.add_child(_result_label)

	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 10)
	col.add_child(bottom_row)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(bottom_spacer)

	_close_btn = _round_button("×")
	_close_btn.name = "CloseRiteButton"
	_close_btn.tooltip_text = "关闭"
	_close_btn.custom_minimum_size = Vector2(44, 42)
	_close_btn.pressed.connect(func(): closed.emit())
	bottom_row.add_child(_close_btn)

	_resolve_btn = _round_button("✓")
	_resolve_btn.name = "ResolveRiteButton"
	_resolve_btn.tooltip_text = "结算仪式"
	_resolve_btn.custom_minimum_size = Vector2(52, 42)
	_resolve_btn.pressed.connect(_resolve)
	bottom_row.add_child(_resolve_btn)

	_result_label.text = "[color=#a89880]从下方手牌选择卡牌后，点击左侧方块卡槽。[/color]"


func _build_slot_summary() -> void:
	for child in _slots_container.get_children():
		child.queue_free()
	var text := Label.new()
	text.text = "可以通过下方卡牌与左侧卡槽安排这项事务。"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 12)
	text.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	_slots_container.add_child(text)


func _apply_layout() -> void:
	if _rite_panel == null:
		return
	var view_size := size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		var parent_control := get_parent() as Control
		if parent_control != null:
			view_size = parent_control.size
	var s: float = min(view_size.x / MOCKUP_SIZE.x, view_size.y / MOCKUP_SIZE.y)

	_set_rect(_shade, Rect2(Vector2.ZERO, view_size))
	_set_rect(_rite_panel, Rect2(Vector2(760, 78) * s, Vector2(376, 404) * s))
	_set_rect(_log_label, Rect2(Vector2(386, 488) * s, Vector2(500, 26) * s))

	var slot_size := CardWidget.CARD_SIZE * s
	var slot_rects := {
		"s1": _slot_rect_from_center(Vector2(332, 179) * s, slot_size),
		"s2": _slot_rect_from_center(Vector2(472, 351) * s, slot_size),
		"s3": _slot_rect_from_center(Vector2(594, 303) * s, slot_size),
		"s4": _slot_rect_from_center(Vector2(714, 351) * s, slot_size),
	}
	for slot_key in _slot_buttons:
		_set_rect(_slot_buttons[slot_key], slot_rects[slot_key])


func _slot_rect_from_center(center: Vector2, slot_size: Vector2) -> Rect2:
	return Rect2(center - slot_size * 0.5, slot_size)


func _set_rect(node: Control, rect: Rect2) -> void:
	node.position = rect.position.round()
	node.size = rect.size.round()


func refresh() -> void:
	_refresh_slot_visuals()
	_refresh_gold_label()


func _on_slot_pressed(slot_key: String) -> void:
	if _selected_card_id <= 0:
		if _placed.has(slot_key):
			_placed.erase(slot_key)
			set_log("%s 已清空" % slot_key.to_upper())
			_after_placement_changed()
		else:
			set_log("先选择一张牌")
		return
	var slot_def: Dictionary = _rite.get("cards_slot", {}).get(slot_key, {})
	var card: Dictionary = _db.get_card(_selected_card_id)
	if not _slot_accepts_card(slot_def, card):
		set_log("这张牌不能放入 %s" % slot_key.to_upper())
		return
	_placed[slot_key] = _selected_card_id
	set_log("%s 放入 %s" % [_card_display_name(card, _selected_card_id), slot_key.to_upper()])
	_selected_card_id = 0
	_after_placement_changed()


func can_drop_card_on_slot(slot_key: String, data: Variant) -> bool:
	var card_id := _dragged_card_id(data)
	if card_id <= 0:
		return false
	var slot_def: Dictionary = _rite.get("cards_slot", {}).get(slot_key, {})
	var card: Dictionary = _db.get_card(card_id)
	return _slot_accepts_card(slot_def, card)


func drop_card_on_slot(slot_key: String, data: Variant) -> void:
	var card_id := _dragged_card_id(data)
	if card_id <= 0:
		return
	var slot_def: Dictionary = _rite.get("cards_slot", {}).get(slot_key, {})
	var card: Dictionary = _db.get_card(card_id)
	if not _slot_accepts_card(slot_def, card):
		set_log("这张牌不能放入 %s" % slot_key.to_upper())
		return
	_placed[slot_key] = card_id
	set_log("%s 放入 %s" % [_card_display_name(card, card_id), slot_key.to_upper()])
	_selected_card_id = 0
	_after_placement_changed()


func _dragged_card_id(data: Variant) -> int:
	if not (data is Dictionary):
		return 0
	if str(data.get("type", "")) != "card":
		return 0
	return int(data.get("card_id", 0))


func _after_placement_changed() -> void:
	_resolve_baseline.clear()
	_last_result = null
	_gold_used_this_resolve = 0
	_gold_dice_map.clear()
	_resolve_dice_cache.clear()
	_update_gold_button()
	_refresh_gold_label()
	_refresh_slot_visuals()


func _refresh_slot_visuals() -> void:
	var slots: Dictionary = _rite.get("cards_slot", {})
	for slot_key in ["s1", "s2", "s3", "s4"]:
		if not _slot_buttons.has(slot_key):
			continue
		var btn: Button = _slot_buttons[slot_key]
		var title: Label = _slot_titles[slot_key]
		var detail: Label = _slot_details[slot_key]
		var slot_def: Dictionary = slots.get(slot_key, {})
		var slot_text := str(slot_def.get("text", "空卡槽"))
		btn.tooltip_text = slot_text
		if _placed.has(slot_key):
			var card_id := int(_placed[slot_key])
			var card: Dictionary = _db.get_card(card_id)
			title.text = _card_display_name(card, card_id)
			detail.text = "已放入"
			btn.add_theme_stylebox_override("normal", _slot_style(FaustTheme.GOLD_BRIGHT, true))
		else:
			title.text = slot_key.to_upper()
			detail.text = "空卡槽"
			btn.add_theme_stylebox_override("normal", _slot_style())


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
	var gold_dice_bonus = _gold_used_this_resolve
	if not _gold_dice_map.is_empty():
		gold_dice_bonus = _gold_dice_map
	var res = RiteResolver.resolve(_rite, ctx, gold_dice_bonus)
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
		var cond: Dictionary = entry.get("condition", {})
		for k in cond:
			if str(k).begins_with("r1:"):
				txt += "\n[color=#a89880]检定 %s[/color]" % k
				break
	txt += "\n[color=#c9a96a]当前金币: %d[/color]" % _state.coin_count
	if not res.extre_log.is_empty():
		txt += "\n[color=#a89880]（附加结算 %d 条已执行）[/color]" % res.extre_log.size()
	if _gold_used_this_resolve > 0:
		txt += "\n[color=#e0c486]（已投入金骰 +%d 成功）[/color]" % _gold_used_this_resolve
	if _result_label:
		_result_label.text = txt


func _update_gold_button() -> void:
	var can_spend: bool = _state != null and _state.gold_dice > 0 and _last_result != null
	if _gold_dice_btn == null:
		return
	_gold_dice_btn.disabled = not can_spend
	if can_spend:
		_gold_dice_btn.text = "投入金骰"
	else:
		_gold_dice_btn.text = "金骰耗尽" if _state != null and _state.gold_dice <= 0 else "投入金骰"


func _use_gold_dice_reactive() -> void:
	if _state.gold_dice <= 0:
		return
	_gold_used_this_resolve += 1
	var type_key := _gold_type_for_reactive_spend()
	_gold_dice_map[type_key] = int(_gold_dice_map.get(type_key, 0)) + 1
	_do_resolve()


func _refresh_gold_label() -> void:
	if _gold_dice_label and _state != null:
		_gold_dice_label.text = "金骰: %d" % _state.gold_dice


func _prepare_table_from_placements() -> void:
	var slots_to_clear := _managed_slots.duplicate()
	for slot_key in _placed:
		var slot_num: int = str(slot_key).substr(1).to_int()
		if slot_num not in slots_to_clear:
			slots_to_clear.append(slot_num)
	for slot_num in slots_to_clear:
		_state.clear_slot(slot_num)
	_managed_slots.clear()
	for slot_key in _placed:
		var slot_num: int = str(slot_key).substr(1).to_int()
		_managed_slots.append(slot_num)
		_state.add_card_to_slot(int(_placed[slot_key]), slot_num, _db)


func _slot_accepts_sudan(slot_def: Dictionary) -> bool:
	var cond: Dictionary = slot_def.get("condition", {})
	return str(cond.get("type", "")) == "sudan"


func _slot_accepts_card(slot_def: Dictionary, card: Dictionary) -> bool:
	if slot_def.is_empty():
		return false
	var cond: Dictionary = slot_def.get("condition", {})
	if cond.is_empty():
		return true
	var ctx := {
		"db": _db,
		"state": _state,
		"rng": _rng,
		"rite_state": {},
		"attr_slots": ["s1", "s2"],
		"acting_card": card,
		"acting_card_id": int(card.get("id", 0)),
		"acting_card_only": true,
	}
	return ConditionEval.evaluate(cond, ctx)


func _consume_placed_sudan_cards(res) -> void:
	if res == null:
		return
	var deferred: Dictionary = res.deferred
	var clean_rite := bool(deferred.get("clean_rite", false))
	var clean_slots: Array = deferred.get("clean_slots", [])
	var clean_card_ids: Array = deferred.get("clean_card_ids", [])
	for slot_key in _placed:
		var cid := int(_placed[slot_key])
		var card: Dictionary = _db.get_card(cid)
		if str(card.get("type", "")) != "sudan":
			continue
		var slot_num := str(slot_key).substr(1).to_int()
		if clean_rite or slot_num in clean_slots or cid in clean_card_ids:
			RoundLoop.consume_sudan(_state, cid)


func _gold_type_for_reactive_spend() -> String:
	if _last_result != null and not _last_result.dice_types_seen.is_empty():
		return str(_last_result.dice_types_seen[0])
	return "r1"


func set_log(text: String) -> void:
	if _log_label:
		_log_label.text = text


func _panel(node_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style())
	return panel


func _round_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_stylebox_override("normal", _round_button_style())
	button.add_theme_stylebox_override("hover", _round_button_style(FaustTheme.GOLD_BRIGHT))
	button.add_theme_stylebox_override("pressed", _round_button_style(FaustTheme.BORDER))
	return button


func _round_button_style(border: Color = FaustTheme.GOLD) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#15100c")
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(36)
	style.set_content_margin_all(6)
	return style


func _slot_style(border: Color = Color("#585345"), filled: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#302d18") if filled else Color("#11120c")
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	return style


func _card_display_name(card: Dictionary, card_id: int) -> String:
	if str(card.get("type", "")) == "sudan":
		var dec = SudanCards.decode(card_id)
		if str(dec.rank) != "" or str(dec.action) != "":
			return "%s%s" % [dec.rank, dec.action]
	return str(card.get("name", card_id))
