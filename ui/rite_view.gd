## Rite overlay: appears on top of the main scene instead of replacing it.
## It owns the rite slots and settlement controls, while the main scene HUD,
## lateral world, hand rail, and day controls remain visible underneath.
## Cards move between hand, slots, and back again like the original
## CardController/CardDropManager flow instead of being copied into placeholders.
## [SRC: CardController.c @ OnDrag/OnEndDrag/RemoveFromSlot (RVA 0x52a150/0x52a570/0x52ba20);
##       dump.cs: CardController 317051-317135, CardDropManager 311015-311018,
##       CardSlotController.SetCard 317978]
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
signal game_over_requested()

const MOCKUP_SIZE := Vector2(1280, 720)

var _state
var _db
var _rng
var _rite_id: int = 5000001
var _rite_uid: int = 0
var _rite: Dictionary = {}
var _placed: Dictionary = {}  # slot_key -> CardInstance uid
var _managed_slots: Array[int] = []
var _gold_used_this_resolve: int = 0
var _gold_dice_map: Dictionary = {}
var _resolve_baseline: Dictionary = {}
var _resolve_dice_cache: Dictionary = {}
var _last_result = null  # last RiteResult
var _pending_table_entries: Array = []
var _resolution_pending := false
var _rerolls_left := 0
var _reroll_btn: Button
var _last_state_btn: Button
var _resolution_committed := false

var _shade: ColorRect
var _slot_layer: Control
var _rite_panel: Panel
var _gold_dice_label: Label
var _gold_dice_btn: Button
var _resolve_btn: Button
var _stop_btn: Button
var _close_btn: Button
var _result_label: RichTextLabel
var _log_label: Label
var _selected_card_uid: int = 0
var _slot_buttons: Dictionary = {}
var _slot_titles: Dictionary = {}
var _slot_details: Dictionary = {}

var _slots_container: VBoxContainer


func setup(state, db, rng, rite_id: int, rite_uid: int = 0) -> void:
	_state = state
	_db = db
	_rng = rng
	_rite_id = rite_id
	_rite = db.get_rite(rite_id)
	if _state != null and _state.has_method("get_rite_instance"):
		_rite_uid = rite_uid
		var instance = _state.get_rite_instance(_rite_uid) if _rite_uid > 0 else _state.find_rite_instance_by_id(rite_id)
		if instance == null:
			_rite_uid = int(_state.add_available_rite(rite_id, _db, _rng))
		else:
			_rite_uid = int(instance.uid)
		_load_placements_from_instance()
		_update_stop_button()


func _load_placements_from_instance() -> void:
	_placed.clear()
	if _state == null or _rite_uid <= 0:
		return
	for slot_key in _slot_keys():
		var cards: Array = _state.cards_in_slot(slot_key.substr(1).to_int(), _rite_uid)
		if not cards.is_empty():
			_placed[slot_key] = int(cards[0].get("card_uid", 0))


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
	for slot_key in _slot_keys():
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
	title.text = _state.rite_display_name(_rite_id, _db) if _state != null else "%s" % _rite.get("name", str(_rite_id))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	col.add_child(title)

	var actor := Label.new()
	actor.name = "RiteActorLabel"
	var actor_data: Dictionary = (
		_state.player_actor_data(_db)
		if _state != null and _state.has_method("player_actor_data")
		else {}
	)
	actor.text = "行动者：%s" % str(actor_data.get("name", "主角"))
	actor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actor.add_theme_font_size_override("font_size", 13)
	actor.add_theme_color_override("font_color", FaustTheme.GOLD)
	col.add_child(actor)

	var desc := Label.new()
	desc.text = "%s" % _rite.get("text", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", FaustTheme.TEXT)
	col.add_child(desc)

	var tips := Label.new()
	tips.name = "RitePerspectiveHint"
	tips.text = "人物表示谁被卷入这次行动；物品表示你准备调用什么。"
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

	# Reroll: rejects the settlement with RetryException semantics — every
	# die of the check re-rolls (unlike gold dice which add successes). The
	# quota is the 重投 tag sum across the slotted cards.
	# [SRC: RiteResultDiceCountPromptController.c @ OnRedraw (0x59dc40):
	#       +0xd8 count -1, confirm gate; OnRedrawConfirm (0x59db60):
	#       Promise.Reject(RetryException); RiteExtensions.c @ GetRerollCount
	#       (0x392990) reads rite.cards]
	_reroll_btn = Button.new()
	_reroll_btn.text = "重掷"
	_reroll_btn.tooltip_text = "重新掷出本场全部检定骰"
	_reroll_btn.disabled = true
	_reroll_btn.custom_minimum_size = Vector2(64, 34)
	_reroll_btn.pressed.connect(_use_reroll)
	action_row.add_child(_reroll_btn)

	_last_state_btn = Button.new()
	_last_state_btn.name = "RestoreLastRiteStateButton"
	_last_state_btn.text = "恢复上次投放"
	_last_state_btn.tooltip_text = "恢复此仪式上一次确认时的手动投放"
	_last_state_btn.custom_minimum_size = Vector2(122, 34)
	_last_state_btn.pressed.connect(_restore_last_state)
	action_row.add_child(_last_state_btn)

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
	_close_btn.pressed.connect(_close_panel)
	bottom_row.add_child(_close_btn)

	_stop_btn = _round_button("⏸")
	_stop_btn.name = "StopRiteButton"
	_stop_btn.tooltip_text = "停止仪式"
	_stop_btn.custom_minimum_size = Vector2(44, 42)
	_stop_btn.pressed.connect(_stop_started_rite)
	bottom_row.add_child(_stop_btn)

	_resolve_btn = _round_button("✓")
	_resolve_btn.name = "ResolveRiteButton"
	_resolve_btn.tooltip_text = "结算仪式"
	_resolve_btn.custom_minimum_size = Vector2(52, 42)
	_resolve_btn.pressed.connect(_resolve)
	bottom_row.add_child(_resolve_btn)

	_update_stop_button()
	_update_last_state_button()

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
	_set_rect(_slot_layer, Rect2(Vector2.ZERO, view_size))
	var hand_top := view_size.y - 222 * s
	# The panel takes the original template's aspect (its bg art), sized to
	# the free area right of the hand rail like the original rite surface.
	# [SRC: rite_template bg art aspect ratios (~1.73..2.14)]
	var canvas := _template_canvas_size(_rite_template_data())
	var panel_area_width: float = view_size.x - 760 * s
	var panel_area_height: float = hand_top - 80 * s
	var panel_size := Vector2(panel_area_width, panel_area_height)
	if canvas.x > 0 and canvas.y > 0:
		var aspect: float = canvas.x / canvas.y
		if panel_size.x / panel_size.y > aspect:
			panel_size.x = panel_size.y * aspect
		else:
			panel_size.y = panel_size.x / aspect
	var panel_pos := Vector2(view_size.x - panel_size.x - 36 * s, view_size.y * 0.5 - panel_size.y * 0.5)
	_set_rect(_rite_panel, Rect2(panel_pos, panel_size))
	_set_rect(_log_label, Rect2(Vector2(386, 488) * s, Vector2(500, 26) * s))

	var slot_size := CardWidget.CARD_SIZE * s
	var safe_slot_bottom := hand_top - 12 * s
	var slot_rects := _slot_rects_for_keys(_slot_keys(), s, slot_size)
	for slot_key in _slot_buttons:
		if slot_rects.has(slot_key):
			var slot_rect: Rect2 = slot_rects[slot_key]
			if slot_rect.position.y + slot_rect.size.y > safe_slot_bottom:
				slot_rect.position.y = safe_slot_bottom - slot_rect.size.y
			_set_rect(_slot_buttons[slot_key], slot_rect)


func _slot_rect_from_center(center: Vector2, slot_size: Vector2) -> Rect2:
	return Rect2(center - slot_size * 0.5, slot_size)


func _set_rect(node: Control, rect: Rect2) -> void:
	node.position = rect.position.round()
	node.size = rect.size.round()


func refresh() -> void:
	_refresh_slot_visuals()
	_refresh_gold_label()


func _on_slot_pressed(slot_key: String) -> void:
	if _resolution_pending or _resolution_committed:
		set_log("请先确认结果或关闭仪式")
		return
	if _selected_card_uid <= 0:
		if _placed.has(slot_key):
			_return_slot_to_hand(slot_key)
			set_log("%s 已清空" % slot_key.to_upper())
			_after_placement_changed()
		else:
			set_log("先选择一张牌")
		return
	var slot_def: Dictionary = _rite.get("cards_slot", {}).get(slot_key, {})
	var card: Dictionary = _state.card_data_for(_selected_card_uid, _db)
	if not _slot_accepts_card(slot_def, card):
		set_log("这张牌不能放入 %s" % slot_key.to_upper())
		return
	_place_card_in_slot(slot_key, _selected_card_uid, "hand", "")
	set_log("%s 放入 %s" % [_card_display_name(card, int(card.get("id", 0))), slot_key.to_upper()])
	_selected_card_uid = 0
	_after_placement_changed()


func can_drop_card_on_slot(slot_key: String, data: Variant) -> bool:
	if _resolution_pending or _resolution_committed:
		return false
	var card_uid := _dragged_card_uid(data)
	if card_uid <= 0:
		return false
	var slot_def: Dictionary = _rite.get("cards_slot", {}).get(slot_key, {})
	var card: Dictionary = _state.card_data_for(card_uid, _db)
	return _slot_accepts_card(slot_def, card)


func drop_card_on_slot(slot_key: String, data: Variant) -> void:
	if _resolution_pending or _resolution_committed:
		return
	var card_uid := _dragged_card_uid(data)
	if card_uid <= 0:
		return
	var slot_def: Dictionary = _rite.get("cards_slot", {}).get(slot_key, {})
	var card: Dictionary = _state.card_data_for(card_uid, _db)
	if not _slot_accepts_card(slot_def, card) or _placed.has(slot_key):
		# Auto-route to the first satisfied slot instead of rejecting: the
		# original highlights GetSatisfiedSlotIndex during the drag and drops
		# land there, never requiring pixel-perfect slot aiming.
		# [SRC: RiteExtensions.c @ GetSatisfiedSlotIndex (0x392ac0) L2034-2040;
		#       GameController.c @ DragCard (0x54ef50) L4586; report 8 A5]
		var routed := _first_satisfied_slot(card)
		if routed == "":
			set_log("这张牌不能放入 %s" % slot_key.to_upper())
			return
		slot_key = routed
	_place_card_in_slot(slot_key, card_uid, str(data.get("source", "")), str(data.get("source_slot", "")), int(data.get("source_rite_uid", _rite_uid)))
	set_log("%s 放入 %s" % [_card_display_name(card, int(card.get("id", 0))), slot_key.to_upper()])
	_selected_card_uid = 0
	_after_placement_changed()


## The first empty, non-auto-adsorb slot whose condition accepts the card.
## [SRC: RiteExtensions.c @ GetSatisfiedSlotIndex (0x392ac0)]
func _first_satisfied_slot(card: Dictionary) -> String:
	var slots: Dictionary = _rite.get("cards_slot", {})
	for slot_key in _slot_keys():
		var def: Dictionary = slots.get(slot_key, {})
		if int(def.get("open_adsorb", 0)) == 1:
			continue
		if _placed.has(slot_key):
			continue
		if _slot_accepts_card(def, card):
			return slot_key
	return ""


func _dragged_card_uid(data: Variant) -> int:
	if not (data is Dictionary):
		return 0
	if str(data.get("type", "")) != "card":
		return 0
	return int(data.get("card_uid", data.get("card_id", 0)))


func _after_placement_changed() -> void:
	_resolve_baseline.clear()
	_last_result = null
	_gold_used_this_resolve = 0
	_gold_dice_map.clear()
	_resolve_dice_cache.clear()
	_update_gold_button()
	_refresh_gold_label()
	_refresh_slot_visuals()
	_update_last_state_button()
	_refresh_game_screen()


func _refresh_slot_visuals() -> void:
	var slots: Dictionary = _rite.get("cards_slot", {})
	for slot_key in _slot_keys():
		if not _slot_buttons.has(slot_key):
			continue
		var btn: Button = _slot_buttons[slot_key]
		var title: Label = _slot_titles[slot_key]
		var detail: Label = _slot_details[slot_key]
		var slot_def: Dictionary = slots.get(slot_key, {})
		var slot_text := str(slot_def.get("text", "空卡槽"))
		btn.tooltip_text = slot_text
		if _placed.has(slot_key):
			var card_uid := int(_placed[slot_key])
			var card: Dictionary = _state.card_data_for(card_uid, _db)
			title.text = ""
			detail.text = ""
			btn.add_theme_stylebox_override("normal", _slot_style(FaustTheme.GOLD_BRIGHT, true))
			_render_slot_card(btn, slot_key, card_uid, card)
		else:
			title.text = slot_key.to_upper()
			detail.text = _slot_brief(slot_def)
			btn.add_theme_stylebox_override("normal", _slot_style())
			_clear_slot_card(btn)


func _resolve() -> void:
	if _resolution_pending:
		_commit_resolution()
		return
	if _resolution_committed:
		return
	if _state != null and _rite_uid > 0 and _state.has_method("get_rite_instance"):
		var instance = _state.get_rite_instance(_rite_uid)
		if instance == null or not instance.start:
			# The confirm button is CheckConfirm + set_start in the original:
			# a multi-day rite only records start/start_round/start_life here
			# and settles on a later UpdateSingleRite pass. Zero-day rites
			# (round_number == 0) settle immediately after starting.
			# [SRC: RitePanelController.c OnConfirm chain, lines 1203-1239;
			#       GameController.c @ UpdateSingleRite (0x55ab10)]
			# This is the original panel-confirm write, not a round rollback
			# snapshot. It records only manual slots keyed by rite config id.
			# [SRC: RitePanelController.c OnConfirm 0x58f1c0 L1282-1288]
			_state.record_last_round_rite_data(_rite_uid, _db)
			if not _state.start_rite_instance(_rite_uid):
				return
			if int(_rite.get("auto_result", 0)) == 1:
				# auto_result rites settle without player interaction.
				# [SRC: GameController.c @ Settlement (0x556ae0) lines 4520-4526
				#       IsRiteAutoResult -> RiteResultPanelController stays
				#       inactive (lines 640-644); multi-day ones resolve at the
				#       day boundary, zero-day ones resolve right here.]
				if int(_rite.get("round_number", 0)) > 0:
					_log_label.text = "仪式已开始，将自动结算。"
					_update_resolve_button()
					_update_stop_button()
					closed.emit()
					return
				_gold_used_this_resolve = 0
				_gold_dice_map.clear()
				_resolve_dice_cache.clear()
				_prepare_table_from_placements()
				_resolve_baseline = SaveSystem.serialize(_state)
				_pending_table_entries = _state.cards_in_slot_entries_for_rite(_rite_uid)
				_do_resolve()
				_commit_resolution()
				closed.emit()
				return
			if int(_rite.get("round_number", 0)) > 0:
				_log_label.text = "仪式开始，将在 %d 天后结算。" % int(_rite.get("round_number", 0))
				_update_resolve_button()
				_update_stop_button()
				closed.emit()
				return
	# Fresh resolve: reset gold-dice-used, place cards, snapshot the pre-result
	# state, then resolve. Gold-dice re-resolves restore this baseline before
	# applying results, matching the original Promise.Reject unwind path.
	# [SRC: RiteResultDiceCountPromptController.c @ OnGoldConfirm (0x59d8b0)]
	_gold_used_this_resolve = 0
	_gold_dice_map.clear()
	_resolve_dice_cache.clear()
	_rerolls_left = _reroll_count()
	_prepare_table_from_placements()
	_resolve_baseline = SaveSystem.serialize(_state)
	_pending_table_entries = _state.cards_in_slot_entries_for_rite(_rite_uid)
	_do_resolve()


func _do_resolve() -> void:
	if not _resolve_baseline.is_empty():
		SaveSystem.deserialize(_resolve_baseline, _state, _db)
		# The baseline deserialize restored the dice counter; subtract this
		# resolve's usage from the restored value.
		_state.gold_dice = maxi(0, _state.gold_dice - _gold_used_this_resolve)
	else:
		_prepare_table_from_placements()
	var ctx := {
		"db": _db, "state": _state, "rng": _rng,
		"rite_state": _rite_state_from_placements(), "rite_uid": _rite_uid,
		"attr_slots": _slot_keys(), "rite_id": _rite_id,
		"dice_cache": _resolve_dice_cache,
		"slot_entries": _slot_entries_from_placements(),
	}
	if _state != null and _state.has_method("with_player_actor_context"):
		ctx = _state.with_player_actor_context(ctx, _db)
	var gold_dice_bonus = _gold_used_this_resolve
	if not _gold_dice_map.is_empty():
		gold_dice_bonus = _gold_dice_map
	_state.active_rite_uid = _rite_uid
	var res = RiteResolver.resolve(_rite, ctx, gold_dice_bonus)
	_state.active_rite_uid = 0
	_last_result = res
	_apply_deferred_to_world(res.deferred)
	_resolution_pending = true
	GameAudio.cue("dice_show.ogg")
	_display_result(res)
	_update_gold_button()
	_refresh_gold_label()
	_update_resolve_button()
	_update_reroll_button()


## Commit the already-previewed settlement after any gold-dice retries are
## finished. The original only removes the Rite after its settlement promise
## chain completes; showing dice is an intermediate step in that chain.
## [SRC: RiteResultPanelController.c @ Settlement (RVA 0x5a4800),
##       RiteResultPanelController.__c__DisplayClass56_0.c @ <Settlement>b__8
##       (RVA 0x5b4850), RiteResultDiceCountPromptController.c @ OnGoldConfirm
##       (RVA 0x59d8b0)]
func _commit_resolution() -> void:
	if not _resolution_pending or _last_result == null:
		return
	var instance = _state.get_rite_instance(_rite_uid) if _state != null and _state.has_method("get_rite_instance") else null
	if instance != null:
		RoundLoop.finalize_rite_settlement(instance, _last_result.deferred, _state, _db, _pending_table_entries, _rng)
	_resolution_pending = false
	_resolution_committed = true
	_pending_table_entries.clear()
	if _gold_dice_btn != null:
		_gold_dice_btn.disabled = true
	_update_resolve_button()
	resolved.emit()
	# A rite-driven game over fires only after the result is committed.
	if bool(_last_result.deferred.get("over", false)):
		game_over_requested.emit()


## Closing while dice/result preview is open abandons the uncommitted result.
## The baseline is taken after card placement, so the rite remains open with
## the same placed cards, while coin/events/loot and spent gold dice roll back.
func _close_panel() -> void:
	if _resolution_pending and not _resolve_baseline.is_empty() and _state != null:
		SaveSystem.deserialize(_resolve_baseline, _state, _db)
		_resolution_pending = false
		_last_result = null
		_gold_used_this_resolve = 0
		_gold_dice_map.clear()
		_resolve_dice_cache.clear()
		_pending_table_entries.clear()
		_refresh_gold_label()
		_update_gold_button()
		_update_resolve_button()
		_refresh_game_screen()
	closed.emit()


func _display_result(res) -> void:
	var entry: Dictionary = res.normal_entry
	var txt := ""
	if entry.is_empty():
		txt = "[color=#a89880]（没有匹配的结算分支）[/color]"
	else:
		# Display texts carry config placeholders ([sudan_life_time] etc.)
		# substituted with live run values like the original formatter.
		var t1: String = _state.substitute_text(str(entry.get("result_title", ""))) if _state != null and _state.has_method("substitute_text") else str(entry.get("result_title", ""))
		var t2: String = _state.substitute_text(str(entry.get("result_text", ""))) if _state != null and _state.has_method("substitute_text") else str(entry.get("result_text", ""))
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
	var can_spend: bool = _state != null and _state.gold_dice > 0 and _last_result != null and _resolution_pending
	if _gold_dice_btn == null:
		return
	_gold_dice_btn.disabled = not can_spend
	if can_spend:
		_gold_dice_btn.text = "投入金骰"
	else:
		_gold_dice_btn.text = "金骰耗尽" if _state != null and _state.gold_dice <= 0 else "投入金骰"


func _use_gold_dice_reactive() -> void:
	if not _resolution_pending or _state.gold_dice <= 0:
		return
	GameAudio.cue("drop_card_gold.ogg")
	_gold_used_this_resolve += 1
	var type_key := _gold_type_for_reactive_spend()
	_gold_dice_map[type_key] = int(_gold_dice_map.get(type_key, 0)) + 1
	_do_resolve()


## Reroll spends one 重投 charge and re-rolls every die of the settlement
## (dice cache cleared; the baseline rollback in _do_resolve unwinds the
## previous result first). [SRC: OnRedrawConfirm (0x59db60) rejects the
## settlement promise with RetryException; dice re-roll, gold dice do not]
func _use_reroll() -> void:
	if not _resolution_pending or _rerolls_left <= 0:
		return
	_rerolls_left -= 1
	_resolve_dice_cache.clear()
	_do_resolve()
	_update_reroll_button()


## The reroll quota is the 重投 tag sum across the slotted cards.
## [SRC: RiteExtensions.c @ GetRerollCount (0x392990) reads rite.cards]
func _reroll_count() -> int:
	var total := 0
	for entry in _slot_entries_from_placements():
		total += int(entry.get("tags", {}).get("重投", 0))
	return total


func _update_reroll_button() -> void:
	if _reroll_btn == null:
		return
	_reroll_btn.disabled = not (_resolution_pending and _rerolls_left > 0)


## OnStop: a started multi-day rite can be halted. Cards stay in their slots,
## life rolls back to start_life, and the panel returns to arrangement mode.
## [SRC: RitePanelController.c @ OnStop (RVA 0x5906e0), lines 1442-1462]
func _stop_started_rite() -> void:
	if _state == null or _rite_uid <= 0 or not _state.has_method("stop_rite_instance"):
		return
	if _resolution_pending or _resolution_committed:
		return
	if _state.stop_rite_instance(_rite_uid):
		_log_label.text = "仪式已停止，卡牌保留在槽位中。"
		_update_resolve_button()
		_update_stop_button()
		_update_last_state_button()


func _update_stop_button() -> void:
	if _stop_btn == null:
		return
	var started := false
	if _state != null and _rite_uid > 0 and _state.has_method("get_rite_instance"):
		var instance = _state.get_rite_instance(_rite_uid)
		started = instance != null and instance.start
	_stop_btn.visible = started and int(_rite.get("round_number", 0)) > 0


func _update_last_state_button() -> void:
	if _last_state_btn == null:
		return
	var started := false
	if _state != null and _rite_uid > 0 and _state.has_method("get_rite_instance"):
		var instance = _state.get_rite_instance(_rite_uid)
		started = instance != null and instance.start
	var has_snapshot: bool = _state != null and _state.has_method("get_last_round_rite_data") \
		and not _state.get_last_round_rite_data(_rite_id).is_empty()
	_last_state_btn.disabled = not has_snapshot or started or _resolution_pending or _resolution_committed


## Match RitePanelController.OnLastState: retain a current slot only when its
## id and count already cover the saved request; otherwise return it, then
## restore each saved manual slot if the necessary hand cards still exist and
## the present slot condition accepts them.
## [SRC: RitePanelController.c @ OnLastState (0x58fdf0); dump.cs
##       Player.LastCardData{id,count} @0x10/@0x14]
func _restore_last_state() -> void:
	if _state == null or _rite_uid <= 0 or _resolution_pending or _resolution_committed:
		return
	var instance = _state.get_rite_instance(_rite_uid)
	if instance != null and instance.start:
		return
	var saved: Dictionary = _state.get_last_round_rite_data(_rite_id)
	if saved.is_empty():
		return
	var restored := 0
	var slots: Dictionary = _rite.get("cards_slot", {})
	var slot_keys: Array = saved.keys()
	slot_keys.sort_custom(func(a, b): return str(a).substr(1).to_int() < str(b).substr(1).to_int())
	for raw_slot_key in slot_keys:
		var slot_key := str(raw_slot_key)
		var snapshot = saved[raw_slot_key]
		if not (snapshot is Dictionary) or not slots.has(slot_key):
			continue
		# OnConfirm never writes auto-adsorb slots. Treat a malformed/imported
		# entry the same way rather than turning restore into a placement route.
		if int(slots[slot_key].get("open_adsorb", 0)) != 0:
			continue
		var card_id := int(snapshot.get("id", 0))
		var count := int(snapshot.get("count", 0))
		if card_id <= 0 or count <= 0:
			continue
		if _placed.has(slot_key):
			var current = _state.get_card_instance(int(_placed[slot_key]))
			if current != null and current.card_id == card_id and int(current.count) >= count:
				continue
			_return_slot_to_hand(slot_key)
		var card_uid: int = int(_state.take_hand_card_count(card_id, count))
		if card_uid <= 0:
			continue
		var card: Dictionary = _state.card_data_for(card_uid, _db)
		if not _slot_accepts_card(slots[slot_key], card):
			continue
		_place_card_in_slot(slot_key, card_uid, "hand", "")
		restored += 1
	if restored > 0:
		_log_label.text = "已恢复 %d 个上次投放槽位。" % restored
	else:
		_log_label.text = "上次投放中的卡牌暂不可用。"
	_after_placement_changed()


func _update_resolve_button() -> void:
	if _resolve_btn == null:
		return
	_resolve_btn.disabled = _resolution_committed
	if _resolution_pending:
		_resolve_btn.tooltip_text = "确认结果"
	elif _state != null and _rite_uid > 0 and _state.has_method("get_rite_instance"):
		var instance = _state.get_rite_instance(_rite_uid)
		if instance != null and not instance.start:
			var days := int(_rite.get("round_number", 0))
			_resolve_btn.tooltip_text = "开始仪式（%d 天）" % days if days > 0 else "开始仪式"
		else:
			_resolve_btn.tooltip_text = "结算仪式"
	else:
		_resolve_btn.tooltip_text = "结算仪式"


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
		_state.clear_slot(slot_num, _rite_uid)
	_managed_slots.clear()
	for slot_key in _placed:
		var slot_num: int = str(slot_key).substr(1).to_int()
		_managed_slots.append(slot_num)
		var card_uid := int(_placed[slot_key])
		_state.remove_card_from_slot(card_uid, 0, _rite_uid)
		_state.add_card_to_slot(card_uid, slot_num, _db, _rite_uid)


func _place_card_in_slot(slot_key: String, card_uid: int, source: String, source_slot: String, source_rite_uid: int = 0) -> void:
	if _placed.has(slot_key) and int(_placed[slot_key]) != card_uid:
		_return_slot_to_hand(slot_key)
	var origin_rite_uid := source_rite_uid if source_rite_uid > 0 else _rite_uid
	if source == "slot" and source_slot != "":
		if origin_rite_uid == _rite_uid:
			_placed.erase(source_slot)
		_state.remove_card_from_slot(card_uid, source_slot.substr(1).to_int(), origin_rite_uid)
	elif source == "hand":
		_state.remove_card_from_hand(card_uid)
	var existing_slot: int = _state.slot_for_table_card(card_uid, _rite_uid)
	if existing_slot > 0:
		_state.remove_card_from_slot(card_uid, existing_slot, _rite_uid)
	_placed[slot_key] = card_uid
	_state.add_card_to_slot(card_uid, slot_key.substr(1).to_int(), _db, _rite_uid)


func _return_slot_to_hand(slot_key: String) -> void:
	if _resolution_pending or _resolution_committed:
		return
	if not _placed.has(slot_key):
		return
	var card_uid := int(_placed[slot_key])
	_placed.erase(slot_key)
	_state.remove_card_from_slot(card_uid, slot_key.substr(1).to_int(), _rite_uid)
	var card: Dictionary = _state.card_data_for(card_uid, _db)
	if str(card.get("type", "")) == "sudan":
		var instance = _state.get_card_instance(card_uid)
		if instance != null:
			instance.zone = "sudan"
	elif not _state.has_card_in_hand(card_uid):
		_state.add_card_to_hand(card_uid)


func return_card_to_hand(card_uid: int, source_slot: String) -> void:
	if _resolution_pending or _resolution_committed:
		return
	var slot_num: int = source_slot.substr(1).to_int() if source_slot.begins_with("s") else int(_state.slot_for_table_card(card_uid, _rite_uid))
	if source_slot != "" and _placed.has(source_slot) and int(_placed[source_slot]) == card_uid:
		_placed.erase(source_slot)
	else:
		for slot_key in _placed.keys():
			if int(_placed[slot_key]) == card_uid:
				_placed.erase(slot_key)
				break
	_state.remove_card_from_slot(card_uid, slot_num, _rite_uid)
	var card: Dictionary = _state.card_data_for(card_uid, _db)
	if str(card.get("type", "")) == "sudan":
		var instance = _state.get_card_instance(card_uid)
		if instance != null:
			instance.zone = "sudan"
	elif not _state.has_card_in_hand(card_uid):
		_state.add_card_to_hand(card_uid)
	_after_placement_changed()


func _render_slot_card(btn: Button, slot_key: String, card_uid: int, card: Dictionary) -> void:
	_clear_slot_card(btn)
	var card_copy := card.duplicate(true)
	card_copy["instance_uid"] = card_uid
	if str(card_copy.get("type", "")) == "sudan":
		var dec = SudanCards.decode(int(card_copy.get("id", 0)))
		card_copy["name"] = "%s%s" % [dec.rank, dec.action]
	var widget := CardWidget.make(card_copy, "slot", slot_key, _rite_uid)
	widget.name = "PlacedCard_%s" % slot_key.to_upper()
	widget.set_anchors_preset(Control.PRESET_FULL_RECT)
	widget.offset_left = 0
	widget.offset_top = 0
	widget.offset_right = 0
	widget.offset_bottom = 0
	widget.clicked.connect(func(_id: int, _card: Dictionary): _return_slot_to_hand(slot_key); _after_placement_changed())
	btn.add_child(widget)


func _rite_state_from_placements() -> Dictionary:
	var rite_state := {}
	for slot_key in _placed:
		var card = _state.card_data_for(int(_placed[slot_key]), _db)
		rite_state[str(slot_key)] = int(card.get("id", 0))
	return rite_state


func _clear_slot_card(btn: Button) -> void:
	for child in btn.get_children():
		if child is CardWidget:
			child.queue_free()


func _refresh_game_screen() -> void:
	var p := get_parent()
	while p != null:
		if p.has_method("refresh"):
			p.refresh()
			return
		p = p.get_parent()


func _slot_accepts_sudan(slot_def: Dictionary) -> bool:
	var cond: Dictionary = slot_def.get("condition", {})
	return str(cond.get("type", "")) == "sudan"


func _slot_accepts_card(slot_def: Dictionary, card: Dictionary) -> bool:
	if slot_def.is_empty():
		return false
	var cond: Dictionary = slot_def.get("condition", {})
	if cond.is_empty():
		return true
	# Slot conditions evaluate against the rite's currently placed cards too
	# (e.g. `s1.xxx` references), not just the card being tried.
	# [SRC: RiteExtensions.c @ GetSatisfiedSlotIndex (0x392ac0) lines
	#       2038-2040: ConditionContext ctor carries the rite's cards]
	var ctx := {
		"db": _db,
		"state": _state,
		"rng": _rng,
		"rite_state": _rite_state_from_placements(),
		"attr_slots": _slot_keys(),
		"rite_uid": _rite_uid,
		"rite_id": _rite_id,
		"acting_card": card,
		"acting_card_id": int(card.get("id", 0)),
		"acting_card_only": true,
		"slot_entries": _slot_entries_from_placements(),
	}
	return ConditionEval.evaluate(cond, ctx)


func _slot_entries_from_placements() -> Array:
	var out: Array = []
	if _state == null:
		return out
	var slots: Dictionary = _rite.get("cards_slot", {})
	for slot_key in _placed:
		var uid := int(_placed[slot_key])
		var card: Dictionary = _state.card_data_for(uid, _db)
		out.append({
			"slot": slot_key,
			"card_id": int(card.get("id", 0)),
			"card_uid": uid,
			"tags": card.get("tag", {}),
			"is_enemy": int(slots.get(slot_key, {}).get("is_enemy", 0)) == 1,
		})
	return out


func _apply_deferred_to_world(deferred: Dictionary) -> void:
	DeferredEffects.apply(deferred, _state, _db, _rng)


func _gold_type_for_reactive_spend() -> String:
	if _last_result != null and not _last_result.dice_types_seen.is_empty():
		return str(_last_result.dice_types_seen[0])
	return "r1"


func set_log(text: String) -> void:
	if _log_label:
		_log_label.text = text


func _panel(node_name: String) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	# Texture-first: the rite's template background IS the panel surface —
	# no paper chrome may frame it. The authored style only survives when
	# no art resolved.
	# [SRC: rite_template_mappings.json -> rite_template bg fields;
	#       assets/original/ui/rite_bg/]
	var bg_texture := _rite_bg_texture()
	if bg_texture != null:
		var style := StyleBoxTexture.new()
		style.texture = bg_texture
		style.texture_margin_left = 40
		style.texture_margin_right = 40
		style.texture_margin_top = 36
		style.texture_margin_bottom = 36
		style.content_margin_left = 46
		style.content_margin_right = 46
		style.content_margin_top = 42
		style.content_margin_bottom = 42
		panel.add_theme_stylebox_override("panel", style)
	else:
		panel.add_theme_stylebox_override("panel", FaustTheme.card_style())
	return panel


static var _rite_bg_cache: Dictionary = {}


## rite.mapping_id -> rite_template_mappings.json entry -> template bg name
## -> assets/original/ui/rite_bg/<name>.png.
static func _rite_bg_texture_for(rite: Dictionary) -> Texture2D:
	var mapping_id := int(rite.get("mapping_id", 0))
	var cache_key := "m%d" % mapping_id
	if _rite_bg_cache.has(cache_key):
		return _rite_bg_cache[cache_key]
	var bg_name := "nomal_rite_bg"
	var mapping: Variant = _load_json("res://content/rite_template_mappings.json")
	if mapping is Dictionary:
		var entry = mapping.get(str(mapping_id))
		if not (entry is Dictionary) or entry.is_empty():
			entry = mapping.get("0")
		if entry is Dictionary:
			var template_id := int(entry.get("template_id", 8000001))
			var template = _load_json("res://content/rite_template/%d.json" % template_id)
			if template is Dictionary and str(template.get("bg", "")) != "":
				bg_name = str(template["bg"])
	var path := "res://assets/original/ui/rite_bg/%s.png" % bg_name
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	_rite_bg_cache[cache_key] = texture
	return texture


func _rite_bg_texture() -> Texture2D:
	return _rite_bg_texture_for(_rite)


static func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


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


func _slot_style(border: Color = Color("#585345"), filled: bool = false) -> StyleBox:
	# Texture-first: the original slot backdrop IS the button surface; the
	# authored flat border only survives when the art is missing.
	# [SRC: rite/template slot_bg nomal_slot_bg.png]
	var slot_art := "res://assets/original/ui/rite_slot/nomal_slot_bg.png"
	if ResourceLoader.exists(slot_art) and not filled:
		var tex := load(slot_art) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 24
			style.texture_margin_right = 24
			style.texture_margin_top = 20
			style.texture_margin_bottom = 20
			style.content_margin_left = 28
			style.content_margin_right = 28
			style.content_margin_top = 24
			style.content_margin_bottom = 24
			return style
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color("#302d18") if filled else Color("#11120c")
	flat.border_color = border
	flat.set_border_width_all(4)
	flat.set_corner_radius_all(4)
	flat.set_content_margin_all(6)
	return flat


func _card_display_name(card: Dictionary, card_id: int) -> String:
	if str(card.get("type", "")) == "sudan":
		var dec = SudanCards.decode(card_id)
		if str(dec.rank) != "" or str(dec.action) != "":
			return "%s%s" % [dec.rank, dec.action]
	return str(card.get("name", card_id))


func _slot_keys() -> Array[String]:
	var keys: Array[String] = []
	var slots: Dictionary = _rite.get("cards_slot", {})
	for key in slots.keys():
		keys.append(str(key))
	keys.sort_custom(func(a: String, b: String) -> bool:
		return a.substr(1).to_int() < b.substr(1).to_int()
	)
	return keys


func _slot_rects_for_keys(keys: Array[String], s: float, slot_size: Vector2) -> Dictionary:
	var rects := {}
	if keys.is_empty():
		return rects
	# Template-driven placement: slot centers come from the original
	# rite_template coordinates (localPosition relative to the panel center,
	# y-up) mapped onto the rendered panel rect; rotation and per-slot scale
	# ride on the buttons. [SRC: RitePanelShowController.c L675-680
	# set_localPosition/set_localScale from the template slots]
	var template := _rite_template_data()
	var panel_rect := _rite_panel.get_rect()
	var canvas := _template_canvas_size(template)
	if canvas.x > 0 and canvas.y > 0:
		var fit := _template_fit(canvas, panel_rect)
		for slot_key in keys:
			var slot_def: Dictionary = template.get("slots", {}).get(slot_key, {})
			var pos: Dictionary = slot_def.get("pos", {}) if slot_def.get("pos", {}) is Dictionary else {}
			if pos.is_empty():
				continue
			# Unity center-origin y-up -> Godot panel-local y-down.
			var cx: float = panel_rect.position.x + (canvas.x * 0.5 + float(pos.get("x", 0))) * fit
			var cy: float = panel_rect.position.y + (canvas.y * 0.5 - float(pos.get("y", 0))) * fit
			var sc: Dictionary = slot_def.get("scale", {}) if slot_def.get("scale", {}) is Dictionary else {}
			var scale_xy := Vector2(float(sc.get("x", 1)), float(sc.get("y", 1)))
			var btn := _slot_buttons.get(slot_key) as Control
			if btn != null:
				btn.rotation_degrees = -float(slot_def.get("rotation_z", 0))
				btn.scale = scale_xy
			rects[slot_key] = _slot_rect_from_center(Vector2(cx, cy), slot_size * scale_xy)
		if not rects.is_empty():
			return rects
	# Fallback: authored grid for templates without resolvable art/coords.
	if keys.size() <= 4:
		var centers := [
			Vector2(332, 179),
			Vector2(472, 351),
			Vector2(594, 303),
			Vector2(714, 351),
		]
		for i in keys.size():
			rects[keys[i]] = _slot_rect_from_center(centers[i] * s, slot_size)
		return rects
	var cols := mini(4, keys.size())
	var rows := ceili(float(keys.size()) / float(cols))
	var start := Vector2(300, 146) * s
	var gap := Vector2(126, 170) * s
	for i in keys.size():
		var col := i % cols
		var row := floori(float(i) / float(cols))
		var center := start + Vector2(float(col) * gap.x, float(row) * gap.y)
		if rows > 1 and row == rows - 1 and keys.size() % cols != 0:
			var last_count := keys.size() % cols
			center.x += float(cols - last_count) * gap.x * 0.5
		rects[keys[i]] = _slot_rect_from_center(center, slot_size)
	return rects


## The resolved rite_template entry driving this panel's layout.
func _rite_template_data() -> Dictionary:
	var mapping: Variant = _load_json("res://content/rite_template_mappings.json")
	if not (mapping is Dictionary):
		return {}
	var entry = mapping.get(str(int(_rite.get("mapping_id", 0))))
	if not (entry is Dictionary) or entry.is_empty():
		entry = mapping.get("0")
	if not (entry is Dictionary):
		return {}
	var template: Variant = _load_json("res://content/rite_template/%d.json" % int(entry.get("template_id", 8000001)))
	return template if template is Dictionary else {}


## Canvas size = the resolved bg art's pixel size (the template's own frame).
func _template_canvas_size(template: Dictionary) -> Vector2:
	var bg_name := str(template.get("bg", ""))
	if bg_name == "":
		return Vector2.ZERO
	var path := "res://assets/original/ui/rite_bg/%s.png" % bg_name
	if not ResourceLoader.exists(path):
		return Vector2.ZERO
	var tex := load(path) as Texture2D
	if tex == null:
		return Vector2.ZERO
	return tex.get_size()


func _template_fit(canvas: Vector2, panel_rect: Rect2) -> float:
	if canvas.x <= 0 or canvas.y <= 0:
		return 1.0
	return min(panel_rect.size.x / canvas.x, panel_rect.size.y / canvas.y)


func _slot_brief(slot_def: Dictionary) -> String:
	var text := str(slot_def.get("text", ""))
	if text != "":
		return text
	var cond: Dictionary = slot_def.get("condition", {})
	if cond.is_empty():
		return "任意"
	return " / ".join(cond.keys())
