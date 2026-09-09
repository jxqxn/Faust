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

# Original MainUI CanvasScaler reference resolution.  RitePanelShow is a
# direct GameScene overlay, not a legacy 1280x800 mockup.
# [SRC: GameScene.unity MainUI CanvasScaler; RitePanelShow.prefab root]
const SOURCE_CANVAS_SIZE := Vector2(3840, 2160)
const SOURCE_FONT = preload("res://assets/fonts/HYJieLongTaoHuaYuanW-2.ttf")
const SOURCE_POSITION_CENTER := Vector2(1920, 870) # Position: (0, +210) in Unity y-up.
const SOURCE_SLOTS_CONTAINER_SIZE := Vector2(3692, 2132)
const SOURCE_SLOT_SIZE := Vector2(272, 496) # CardSlot.prefab root.
const SOURCE_TITLE_SIZE := Vector2(1148, 1124) # RitePanelTitle.
const SOURCE_TEMPLATE_BG_RECT := Rect2(Vector2(-128, -204), Vector2(4096, 2148))
const SOURCE_DEFAULT_TITLE_POS := Vector2(1564, -54)

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
var _last_result_waiting := false
var _close_after_commit := false

var _shade: ColorRect
var _source_canvas: Control
var _template_backdrop: Control
var _template_foreground: Control
var _tag_values: Dictionary = {}
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
var _qualified_slot := ""
var _qualified_bags: Array[int] = []
var _qualified_bag_index := -1
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
	# Desktop dimming matched to the supplied original runtime frame.
	_shade.color = Color(0, 0, 0, 0.55)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shade)

	_source_canvas = Control.new()
	_source_canvas.name = "RitePanelShow"
	_source_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_source_canvas)

	_template_backdrop = preload("res://ui/rite_sprite_surface.gd").new()
	_template_backdrop.name = "RiteTemplateBackground"
	_template_backdrop.setup(_rite_bg_texture().resource_path)
	_template_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_source_canvas.add_child(_template_backdrop)

	_slot_layer = Control.new()
	_slot_layer.name = "RiteSlotOverlay"
	# This layer receives literal source-canvas coordinates; full-rect anchors
	# would fight its 3840x2160 source size on every resize.
	_slot_layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_source_canvas.add_child(_slot_layer)
	_build_slot_placeholders()
	var foreground_path := "res://assets/original/ui/rite_bg/%s.png" % _rite_template_data().get("fg", "")
	if ResourceLoader.exists(foreground_path):
		_template_foreground = preload("res://ui/rite_sprite_surface.gd").new()
		_template_foreground.name = "RiteTemplateForeground"
		_template_foreground.setup(foreground_path)
		_template_foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_source_canvas.add_child(_template_foreground)
		# Nonzero fg_in_slot_index inserts within the slot siblings; zero puts
		# the foreground above the whole SlotsContainer.
		# [SRC: RitePanelShowController.Show 0x596450 L930-966; dump.cs RiteTemplateNode+0x38]
		var foreground_index := int(_rite_template_data().get("fg_in_slot_index", 0))
		if foreground_index > 0:
			_template_foreground.reparent(_slot_layer, false)
			_slot_layer.move_child(_template_foreground, mini(foreground_index, _slot_layer.get_child_count() - 1))

	_rite_panel = _panel("RiteOverlayPanel")
	_rite_panel.clip_contents = false
	_source_canvas.add_child(_rite_panel)
	_build_panel_content()
	var template := _rite_template_data()
	if bool(template.get("title_bg_hide", false)):
		_rite_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_rite_panel.get_node("RiteHelpButton").visible = not bool(template.get("title_help_btn_hide", false))

	_log_label = Label.new()
	_log_label.name = "RiteOverlayToast"
	_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log_label.add_theme_font_override("font", SOURCE_FONT)
	_log_label.add_theme_font_size_override("font_size", 14)
	_log_label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	_source_canvas.add_child(_log_label)

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
		for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
		var template := _rite_template_data()
		var mapping: Dictionary = _load_json("res://content/rite_template_mappings.json")
		var entry: Dictionary = _resolved_mapping(_rite)
		var index := _slot_keys().find(slot_key)
		var open: Array = entry.get("slot_open", [])
		var template_key: String = str(open[index]) if index < open.size() else slot_key
		var slot_layout: Dictionary = template.get("slots", {}).get(template_key, {})
		# Source IsNullOrEmpty treats JSON null like an empty override, preserving
		# the prefab background. [SRC: RitePanelShowController.c Show 0x596450 L848-866]
		var slot_art := str(slot_layout.get("slot_bg")) if slot_layout.get("slot_bg") != null else ""
		if slot_art.is_empty():
			slot_art = str(template.get("nomal_slot_bg")) if template.get("nomal_slot_bg") != null else ""
		if slot_art.is_empty():
			slot_art = "nomal_slot_bg"
		var backdrop := _picture(btn, "SlotBackground", "rite_slot/" + slot_art, Rect2(6, -12, 260, 520))
		# Source Image.SetNativeSize uses the selected slot sprite's dimensions.
		backdrop.size = backdrop.texture.get_size()
		backdrop.position = SOURCE_SLOT_SIZE * 0.5 - backdrop.size * 0.5
		backdrop.visible = not bool(slot_layout.get("is_hide_bg", false))
		backdrop.set_meta("hide_empty_and_filled", bool(slot_layout.get("is_hide_bg", false)))
		backdrop.set_meta("hide_when_filled", bool(slot_layout.get("is_set_card_hide_bg", false)))
		var type_name := str(_rite.get("cards_slot", {}).get(slot_key, {}).get("condition", {}).get("type", ""))
		if ResourceLoader.exists("res://assets/original/ui/card_type_%s.png" % type_name):
			var icon := _picture(btn, "SlotType", "card_type_" + type_name, Rect2())
			var icon_size := icon.texture.get_size() * 1.7
			_set_rect(icon, Rect2(SOURCE_SLOT_SIZE * 0.5 + Vector2(0, 25) - icon_size * 0.5, icon_size))

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
		title.add_theme_font_override("font", SOURCE_FONT)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
		box.add_child(title)
		_slot_titles[slot_key] = title

		var detail := Label.new()
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		detail.add_theme_font_override("font", SOURCE_FONT)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_size_override("font_size", 9)
		detail.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
		detail.custom_minimum_size = Vector2(0, 20)
		box.add_child(detail)
		_slot_details[slot_key] = detail


func _build_panel_content() -> void:
	# Authored CommonContent child rects; the painted frame lives in the template BG.
	# [SRC: RitePanelTitle.prefab; RitePanelTitleController.Show 0x5992a0]
	_picture(_rite_panel, "TitleBG", "rite_title_bg_0", Rect2(559, -48, 304, 78))
	var title := _source_label(_rite_panel, "RiteTitle", Rect2(559, -48, 304, 78), 60)
	title.text = _state.rite_display_name(_rite_id, _db) if _state != null else str(_rite.get("name", ""))
	preload("res://ui/source_text_style.gd").apply(title, "@RITE_PANEL_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#111711"))
	_picture(_rite_panel, "RoundIcon", "rite_round", Rect2(754, -100, 38, 42))
	var round_label := _source_label(_rite_panel, "Round", Rect2(798, -106, 65, 50), 50)
	round_label.text = str(int(_rite.get("round_number", 0)))
	var scroll := ScrollContainer.new()
	scroll.name = "RiteDescriptionScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Source Viewport width is Scroll View minus 17 (RitePanelTitle.prefab).
	scroll.get_v_scroll_bar().custom_minimum_size.x = 17.0
	_rite_panel.add_child(scroll)
	_set_rect(scroll, Rect2(167, 70, 710, 870))
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# RichTextLabel includes paragraph_separation after its final paragraph.
	# Adding the same gap to VBox would count the body-to-separator gap twice.
	content.add_theme_constant_override("separation", 0)
	scroll.add_child(content)
	var body := str(_rite.get("text", ""))
	if _state != null:
		body = _state.substitute_text(body)
	var desc := _rich_text(body, 36)
	desc.name = "RiteMainContent"
	# RitePanelTitle/Main Content/Scroll View/Viewport/Text is @MAIN_BODY;
	# @RITE_TEXT belongs to the separate OpenTips node, not this content.
	# [SRC: RitePanelTitle.prefab:4021/4345; Show 0x5992a0 text@0x48.]
	preload("res://ui/source_text_style.gd").apply(desc, "@MAIN_BODY")
	desc.add_theme_color_override("default_color", Color(0.86666673, 0.8352942, 0.7686275))
	desc.add_theme_constant_override("paragraph_separation", 80)
	content.add_child(desc)
	var tips: Array = _rite.get("tips_text", [])
	if not tips.is_empty():
		var separator := TextureRect.new()
		separator.name = "RiteTipsSeparator"
		separator.texture = load("res://assets/original/ui/rite_log_sperator.png")
		separator.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		separator.stretch_mode = TextureRect.STRETCH_SCALE
		separator.custom_minimum_size.y = 6
		separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var separator_spacing := MarginContainer.new()
		separator_spacing.add_theme_constant_override("margin_bottom", 80)
		content.add_child(separator_spacing)
		separator_spacing.add_child(separator)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		content.add_child(row)
		var indent := Control.new()
		indent.custom_minimum_size.x = 120
		indent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(indent)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/original/ui/rite_tips.png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(100, 100)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		indent.add_child(icon)
		var tip_lines: Array[String] = []
		for tip in tips:
			tip_lines.append(_state.substitute_text(str(tip)) if _state != null else str(tip))
		var tip_text := _rich_text("\n".join(tip_lines), 36)
		preload("res://ui/source_text_style.gd").apply(tip_text, "@MAIN_BODY")
		tip_text.name = "RiteTipsText"
		tip_text.add_theme_color_override("default_color", Color("#FCE29A"))
		tip_text.add_theme_constant_override("paragraph_separation", 80)
		row.add_child(tip_text)
	var tags: Array = _rite.get("tag_tips", [])
	for i in tags.size():
		var tag := str(tags[i])
		var icon := TextureRect.new()
		icon.texture = preload("res://ui/card_widget.gd")._attribute_icon(tag)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rite_panel.add_child(icon)
		_set_rect(icon, Rect2(973, 410 + i * 136, 75, 75))
		var value := _source_label(_rite_panel, "TagValue%d" % i, Rect2(1060, 410 + i * 136, 64, 75), 30)
		value.tooltip_text = tag
		_tag_values[tag] = value
	_last_state_btn = _source_button("RestoreLastRiteStateButton", "rite_op_last_state", Rect2(104.9, 948, 168, 158), "恢复上次投放", _restore_last_state)
	_close_btn = _source_button("CloseRiteButton", "rite_op_cancel", Rect2(291, 948, 168, 158), "关闭", _close_panel)
	_resolve_btn = _source_button("ResolveRiteButton", "rite_op_confirm", Rect2(473, 948, 325, 158), "开始仪式", _resolve)
	_stop_btn = _source_button("StopRiteButton", "rite_op_stop", Rect2(776, 944, 188, 160), "停止仪式", _stop_started_rite)
	_source_button("RiteHelpButton", "help_button", Rect2(998, -117.5, 88, 91), "帮助", _show_rite_help)
	var auto_btn := _source_button("AutoResult", "auto_result_deactive", Rect2(934, 947, 240, 88), "自动结算", _toggle_auto_result)
	auto_btn.set_meta("active", false)
	_refresh_auto_result()
	# Settlement-only controls stay available when a result actually exists.
	var result_tools := HBoxContainer.new()
	result_tools.name = "ResultTools"
	_rite_panel.add_child(result_tools)
	_set_rect(result_tools, Rect2(167, 815, 710, 90))
	_gold_dice_label = Label.new()
	result_tools.add_child(_gold_dice_label)
	_gold_dice_btn = Button.new()
	_gold_dice_btn.text = "投入金骰"
	_gold_dice_btn.disabled = true
	_gold_dice_btn.pressed.connect(_use_gold_dice_reactive)
	result_tools.add_child(_gold_dice_btn)
	_reroll_btn = Button.new()
	_reroll_btn.text = "重掷"
	_reroll_btn.disabled = true
	_reroll_btn.pressed.connect(_use_reroll)
	result_tools.add_child(_reroll_btn)
	_result_label = _rich_text("", 32)
	_result_label.name = "RiteResult"
	preload("res://ui/source_text_style.gd").apply(_result_label, "@RITE_SETTLEMENT_TEXT")
	_result_label.fit_content = false
	_rite_panel.add_child(_result_label)
	_set_rect(_result_label, Rect2(167, 70, 710, 720))
	result_tools.visible = false
	_result_label.visible = false
	_update_stop_button()
	_update_last_state_button()

func _source_label(parent: Control, node_name: String, rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font", SOURCE_FONT)
	label.add_theme_color_override("font_color", Color("#c9bd7b"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	_set_rect(label, rect)
	return label

func _rich_text(value: String, font_size: int) -> RichTextLabel:
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("normal_font_size", font_size)
	text.add_theme_font_override("normal_font", SOURCE_FONT)
	text.add_theme_color_override("default_color", Color("#c1c2ac"))
	text.text = preload("res://ui/source_rich_text.gd").to_bbcode(value)
	return text

func _picture(parent: Control, node_name: String, asset: String, rect: Rect2) -> TextureRect:
	var picture := TextureRect.new()
	picture.name = node_name
	picture.texture = load("res://assets/original/ui/%s.png" % asset)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	_set_rect(picture, rect)
	return picture

func _source_button(node_name: String, asset: String, rect: Rect2, hint: String, callback: Callable) -> Button:
	var button := Button.new()
	button.add_theme_font_override("font", SOURCE_FONT)
	button.name = node_name
	button.tooltip_text = hint
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	_rite_panel.add_child(button)
	_set_rect(button, rect)
	var art := _picture(button, "Art", asset, Rect2(Vector2.ZERO, rect.size))
	button.mouse_entered.connect(func(): art.modulate = Color(1.2, 1.2, 1.2))
	button.mouse_exited.connect(func(): art.modulate = Color.WHITE)
	button.pressed.connect(callback)
	return button

func _toggle_auto_result() -> void:
	# [SRC: RitePanelShowController.SetAutoResult 0x595c30; Player +0x130]
	if _state.auto_result_rites.has(_rite_id):
		_state.auto_result_rites.erase(_rite_id)
	elif int(_rite.get("auto_result", 0)) != 0:
		_state.auto_result_rites.append(_rite_id)
	_refresh_auto_result()

func _refresh_auto_result() -> void:
	var button := _rite_panel.get_node("AutoResult") as Button
	button.disabled = int(_rite.get("auto_result", 0)) == 0
	var active: bool = _state != null and _state.auto_result_rites.has(_rite_id)
	button.get_node("Art").texture = load("res://assets/original/ui/auto_result_%s.png" % ("active" if active else "deactive"))

func _show_rite_help() -> void:
	var help := Control.new()
	help.name = "RiteHelp"
	help.size = SOURCE_CANVAS_SIZE
	_source_canvas.add_child(help)
	var mask := ColorRect.new()
	mask.color = Color(0, 0, 0, 0.82)
	mask.size = SOURCE_CANVAS_SIZE
	help.add_child(mask)
	mask.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			help.queue_free()
	)
	_picture(help, "Prompt", "rite_help", Rect2(0, 0, 3840, 2160))
	var labels: Dictionary = _load_json("res://content/ui.json")
	var rows := [["MAIN", Vector2(448, 1583), Vector2(1000, 200)], ["DESC", Vector2(1879, 1583), Vector2(600, 200)], ["TIME", Vector2(2187, 356), Vector2(600, 200)], ["TAG", Vector2(2543, 1334), Vector2(600, 200)]]
	for row in rows:
		var value: String = str(labels.get("RITE_HELP_%s_PROMPT" % row[0], {}).get("zhCN", ""))
		var label := _rich_text(preload("res://ui/main_help.gd")._to_bbcode(value), 50)
		preload("res://ui/source_text_style.gd").apply(label, "@HELP_TEXT")
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		help.add_child(label)
		_set_rect(label, Rect2(row[1] - row[2] * Vector2(0.5, 1), row[2]))


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
	_set_rect(_shade, Rect2(Vector2.ZERO, view_size))
	_source_canvas.position = Vector2.ZERO
	_source_canvas.size = SOURCE_CANVAS_SIZE
	_source_canvas.scale = Vector2(view_size.x / SOURCE_CANVAS_SIZE.x, view_size.y / SOURCE_CANVAS_SIZE.y)
	_set_rect(_slot_layer, Rect2(Vector2.ZERO, SOURCE_CANVAS_SIZE))
	var template := _rite_template_data()
	var bg_offset := _template_pos(template.get("bg_pos", {}))
	var native_size: Vector2 = _template_backdrop.texture.get_size()
	var position_center := SOURCE_CANVAS_SIZE * 0.5 + Vector2(bg_offset.x, -bg_offset.y)
	_set_rect(_template_backdrop, Rect2(
		position_center - native_size * 0.5,
		native_size
	))
	if _template_foreground != null:
		var foreground_size: Vector2 = _template_foreground.texture.get_size()
		_set_rect(_template_foreground, Rect2(position_center - foreground_size * 0.5, foreground_size))
	var title_pos := _template_pos(template.get("title_pos", {}), SOURCE_DEFAULT_TITLE_POS)
	var title_pivot := position_center + Vector2(title_pos.x, -title_pos.y)
	_set_rect(_rite_panel, Rect2(
		title_pivot - Vector2(SOURCE_TITLE_SIZE.x, SOURCE_TITLE_SIZE.y * 0.5),
		SOURCE_TITLE_SIZE
	))
	_set_rect(_log_label, Rect2(Vector2(1510, 1700), Vector2(820, 60)))

	var slot_rects := _slot_rects_for_keys(_slot_keys())
	for slot_key in _slot_buttons:
		if slot_rects.has(slot_key):
			_set_rect(_slot_buttons[slot_key], slot_rects[slot_key])


func _slot_rect_from_center(center: Vector2, slot_size: Vector2) -> Rect2:
	return Rect2(center - slot_size * 0.5, slot_size)


func _set_rect(node: Control, rect: Rect2) -> void:
	node.position = rect.position.round()
	node.size = rect.size.round()


func refresh() -> void:
	_refresh_slot_visuals()
	_refresh_gold_label()
	_update_result_wait_controls()


# Result actions await their prompt promises before Settlement b__8 can
# remove the rite (RVA 0x5b4850). The legacy resolver is still eager, but
# its UI must not permit commit/retry/rollback across an unresolved prompt.
func _waiting_for_result_operations() -> bool:
	return _resolution_pending and _state != null and not _state.pending_operations.is_empty()


func _process(_delta: float) -> void:
	var waiting := _waiting_for_result_operations()
	if waiting != _last_result_waiting:
		_update_result_wait_controls()
	if _close_after_commit and _resolution_pending and not waiting:
		_commit_resolution()


func _update_result_wait_controls() -> void:
	_last_result_waiting = _waiting_for_result_operations()
	_update_resolve_button()
	_update_gold_button()
	_update_reroll_button()
	if _close_btn != null:
		_close_btn.disabled = _last_result_waiting


func _on_slot_pressed(slot_key: String) -> void:
	if not _can_edit_slot(slot_key):
		return
	if _resolution_pending or _resolution_committed:
		set_log("请先确认结果或关闭仪式")
		return
	if _selected_card_uid <= 0:
		if _placed.has(slot_key):
			_return_slot_to_hand(slot_key)
			set_log("%s 已清空" % slot_key.to_upper())
			_after_placement_changed()
		else:
			_focus_qualified_hand(slot_key)
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
	if not (data is Dictionary) or not _can_edit_slot(slot_key):
		return false
	if not preload("res://ui/rite_slot_access.gd").can_move_source(_state, _db, data):
		return false
	if _resolution_pending or _resolution_committed:
		return false
	var card_uid := _dragged_card_uid(data)
	if card_uid <= 0:
		return false
	var slot_def: Dictionary = _rite.get("cards_slot", {}).get(slot_key, {})
	var card: Dictionary = _state.card_data_for(card_uid, _db)
	return _slot_accepts_card(slot_def, card)


func drop_card_on_slot(slot_key: String, data: Variant) -> void:
	if not (data is Dictionary) or not _can_edit_slot(slot_key):
		return
	if not preload("res://ui/rite_slot_access.gd").can_move_source(_state, _db, data):
		return
	if _resolution_pending or _resolution_committed:
		return
	var card_uid := _dragged_card_uid(data)
	if card_uid <= 0:
		return
	var slot_def: Dictionary = _rite.get("cards_slot", {}).get(slot_key, {})
	var card: Dictionary = _state.card_data_for(card_uid, _db)
	# [SRC: CardDropManager.DropCard -> CardSlotController.CardStack: dropping a
	#       stackable card onto an occupied slot holding the same card id merges
	#       the counts into the placed card instead of routing to a free slot.]
	if _placed.has(slot_key):
		var placed_uid := int(_placed[slot_key])
		if _state.has_method("stack_cards") and _state.stack_cards(placed_uid, card_uid):
			set_log("%s 与槽内同类卡合并" % _card_display_name(card, int(card.get("id", 0))))
			_selected_card_uid = 0
			_after_placement_changed()
			return
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
	_qualified_slot = ""
	_qualified_bags.clear()
	_qualified_bag_index = -1
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
			btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			_render_slot_card(btn, slot_key, card_uid, card)
		else:
			title.text = ""
			detail.text = ""
			btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			_clear_slot_card(btn)
		var type_icon := btn.get_node_or_null("SlotType") as TextureRect
		var backdrop := btn.get_node_or_null("SlotBackground") as TextureRect
		if backdrop != null:
			backdrop.visible = not bool(backdrop.get_meta("hide_empty_and_filled", false)) and not (
				_placed.has(slot_key) and bool(backdrop.get_meta("hide_when_filled", false)))
		if type_icon != null:
			type_icon.visible = not _placed.has(slot_key)
	_refresh_tag_values()


func _refresh_tag_values() -> void:
	for tag in _tag_values:
		var total := 0
		for uid in _placed.values():
			var card: Dictionary = _state.card_data_for(int(uid), _db)
			var slot_key: String = str(_placed.find_key(uid))
			if bool(_rite.get("cards_slot", {}).get(slot_key, {}).get("is_enemy", false)):
				continue
			total += int(card.get("tag", {}).get(tag, 0))
		_tag_values[tag].text = str(total)


func _resolve() -> void:
	if _running_before_settlement():
		return
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
			_update_last_state_button()
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
				_close_after_commit = true
				_commit_resolution()
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
	_update_result_wait_controls()
	_refresh_game_screen()


## Commit the already-previewed settlement after any gold-dice retries are
## finished. The original only removes the Rite after its settlement promise
## chain completes; showing dice is an intermediate step in that chain.
## [SRC: RiteResultPanelController.c @ Settlement (RVA 0x5a4800),
##       RiteResultPanelController.__c__DisplayClass56_0.c @ <Settlement>b__8
##       (RVA 0x5b4850), RiteResultDiceCountPromptController.c @ OnGoldConfirm
##       (RVA 0x59d8b0)]
func _commit_resolution() -> void:
	if _waiting_for_result_operations():
		return
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
	if _close_after_commit:
		_close_after_commit = false
		closed.emit()


## Closing while dice/result preview is open abandons the uncommitted result.
## The baseline is taken after card placement, so the rite remains open with
## the same placed cards, while coin/events/loot and spent gold dice roll back.
func _close_panel() -> void:
	if _waiting_for_result_operations():
		return
	_qualified_slot = ""
	_qualified_bags.clear()
	_qualified_bag_index = -1
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
	# The source writes this only when the committed 5010009 result panel is
	# closed. It does not make `final_pin` rites in general terminal rites.
	# GameController then consumes its transient flag at the next-day boundary;
	# MapController.Start also restores the background directly from Player.
	# [SRC: RiteResultPanelController.<>c__DisplayClass62_0.<OnClose>b__0
	#       (RVA 0x5b51c0); MapController.Start (RVA 0x56a890).]
	if _resolution_committed and _rite_id == 5010009 and _state != null:
		_state.end_open = true
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
	_gold_dice_btn.disabled = not can_spend or _waiting_for_result_operations()
	if can_spend:
		_gold_dice_btn.text = "投入金骰"
	else:
		_gold_dice_btn.text = "金骰耗尽" if _state != null and _state.gold_dice <= 0 else "投入金骰"


func _use_gold_dice_reactive() -> void:
	if _waiting_for_result_operations():
		return
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
	if _waiting_for_result_operations():
		return
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
	_reroll_btn.disabled = not (_resolution_pending and _rerolls_left > 0) or _waiting_for_result_operations()


## OnStop: a started multi-day rite can be halted. Cards stay in their slots,
## life rolls back to start_life, and the panel returns to arrangement mode.
## [SRC: RitePanelController.c @ OnStop (RVA 0x5906e0), lines 1442-1462]
func _stop_started_rite() -> void:
	if _state == null or _rite_uid <= 0 or not _state.has_method("stop_rite_instance"):
		return
	if _resolution_pending or _resolution_committed or not _can_stop_this_round():
		return
	if _state.stop_rite_instance(_rite_uid):
		_log_label.text = "仪式已停止，卡牌保留在槽位中。"
		_update_resolve_button()
		_update_stop_button()
		_update_last_state_button()


func _update_stop_button() -> void:
	if _stop_btn == null:
		return
	_stop_btn.visible = _can_stop_this_round()


func _can_stop_this_round() -> bool:
	# [SRC: RitePanelTitleController.Show 0x5992a0: Stop@0x70 is active
	# only when start && start_round == Player.round; dump.cs:324430.]
	if _state == null or _rite_uid <= 0:
		return false
	var instance = _state.get_rite_instance(_rite_uid)
	return instance != null and instance.start and instance.start_round == _state.round_number


func _update_last_state_button() -> void:
	if _last_state_btn == null:
		return
	var started := false
	if _state != null and _rite_uid > 0 and _state.has_method("get_rite_instance"):
		var instance = _state.get_rite_instance(_rite_uid)
		started = instance != null and instance.start
	var has_snapshot: bool = _state != null and _state.has_method("get_last_round_rite_data") \
		and not _state.get_last_round_rite_data(_rite_id).is_empty()
	_last_state_btn.visible = not started
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


## [SRC: GameController.UpdateSingleRite 0x55ab10: Rite.life@0x2c
## < RiteNode.round_number@0x44 skips Settlement; dump.cs:392403/393174.]
func _running_before_settlement() -> bool:
	if _state == null or _rite_uid <= 0:
		return false
	var instance = _state.get_rite_instance(_rite_uid)
	return instance != null and instance.start and instance.life < int(_rite.get("round_number", 0))


func _update_resolve_button() -> void:
	if _resolve_btn == null:
		return
	_resolve_btn.disabled = _resolution_committed or _waiting_for_result_operations() or _running_before_settlement()
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
	if _rite_panel != null:
		var has_result := _last_result != null
		_rite_panel.get_node("ResultTools").visible = has_result
		_rite_panel.get_node("RiteDescriptionScroll").visible = not has_result
		_result_label.visible = has_result


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
	if not _can_edit_slot(slot_key):
		return
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
	if not _can_edit_slot(source_slot):
		return
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
	widget.drag_allowed = func(): return _can_edit_slot(slot_key)
	widget.name = "PlacedCard_%s" % slot_key.to_upper()
	widget.set_anchors_preset(Control.PRESET_FULL_RECT)
	widget.offset_left = 0
	widget.offset_top = 0
	widget.offset_right = 0
	widget.offset_bottom = 0
	widget.clicked.connect(func(_id: int, _card: Dictionary): _return_slot_to_hand(slot_key); _after_placement_changed())
	btn.add_child(widget)


func _can_edit_slot(slot_key: String) -> bool:
	return not _resolution_pending and not _resolution_committed and preload("res://ui/rite_slot_access.gd").can_edit(_state, _db, _rite_uid, slot_key)


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


# CardSlotController.OnPointerClick 0x53c050 ->
# GameController.HandCardSortByCondition 0x5515a0 L8175-8240/8430-8470.
# dump.cs GameController qualified_bags_has_cards/index +0x310/+0x318.
func _focus_qualified_hand(slot_key: String) -> void:
	var slot: Dictionary = _rite.get("cards_slot", {}).get(slot_key, {})
	if _qualified_slot != slot_key:
		_qualified_bags.clear()
		_qualified_bag_index = -1
	_qualified_slot = slot_key
	if _qualified_bags.is_empty():
		for page in range(4):
			for uid in _state.visible_rail_card_uids(page):
				if _slot_accepts_card(slot, _state.card_data_for(uid, _db)):
					_qualified_bags.append(page)
					break
		if _qualified_bags.is_empty():
			return
		_qualified_bag_index = maxi(0, _qualified_bags.find(_state.current_bag_index))
	else:
		_qualified_bag_index = (_qualified_bag_index + 1) % _qualified_bags.size()
	_state.set_current_bag_index(_qualified_bags[_qualified_bag_index])
	_state.sort_current_hand_by_condition(_db, func(card: Dictionary): return _slot_accepts_card(slot, card))
	_refresh_game_screen()
	var screen := get_parent()
	while screen != null:
		if screen.has_method("focus_qualified_hand"):
			screen.call_deferred("focus_qualified_hand", func(card: Dictionary): return _slot_accepts_card(slot, card))
			return
		screen = screen.get_parent()


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
	# RitePanelTitle/CommonContent is a separate 1148x1124 source asset. The
	# rite_template background belongs to Position/bg and is rendered behind
	# the slots above, never re-used as an invented sidebar skin.
	# [SRC: RitePanelShow.prefab RitePanelTitle/CommonContent]
	var panel_texture: Texture2D = null
	var panel_path := "res://assets/original/ui/common_operation_bg.png"
	if ResourceLoader.exists(panel_path):
		panel_texture = load(panel_path) as Texture2D
	if panel_texture != null:
		var style := StyleBoxTexture.new()
		style.texture = panel_texture
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
	var entry := _resolved_mapping(rite)
	var template_id := int(entry.get("template_id", 8000001))
	var cache_key := "t%d" % template_id
	if _rite_bg_cache.has(cache_key):
		return _rite_bg_cache[cache_key]
	var template: Dictionary = _load_json("res://content/rite_template/%d.json" % template_id)
	var bg_name := str(template.get("bg", "nomal_rite_bg"))
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


func _slot_rects_for_keys(keys: Array[String]) -> Dictionary:
	var rects := {}
	# RitePanelShowController instantiates CardSlot under SlotsContainer and
	# writes each original template slot's localPosition/localScale/rotation.
	# No clone grid or hand-rail collision adjustment is permitted here.
	# [SRC: RitePanelShowController.c 0x596450, set_localPosition 0x598000,
	#       set_localScale 0x598020, set_localRotation 0x5980e0;
	#       CardSlot.prefab root = 272x496]
	var template := _rite_template_data()
	var template_slots: Dictionary = template.get("slots", {}) if template.get("slots", {}) is Dictionary else {}
	var mappings: Dictionary = _load_json("res://content/rite_template_mappings.json")
	var mapping: Dictionary = _resolved_mapping(_rite)
	var slot_open: Array = mapping.get("slot_open", [])
	var bg_offset := _template_pos(template.get("bg_pos", {}))
	var position_center := SOURCE_CANVAS_SIZE * 0.5 + Vector2(bg_offset.x, -bg_offset.y)
	for slot_key in keys:
		var index := keys.find(slot_key)
		var template_key: String = str(slot_open[index]) if index < slot_open.size() else slot_key
		var slot_def: Dictionary = template_slots.get(template_key, {})
		if slot_def.is_empty():
			continue
		var pos := _template_pos(slot_def.get("pos", {}))
		var scale_xy := _template_pos(slot_def.get("scale", {}), Vector2.ONE)
		var btn := _slot_buttons.get(slot_key) as Control
		if btn != null:
			btn.pivot_offset = SOURCE_SLOT_SIZE * 0.5
			btn.rotation_degrees = -float(slot_def.get("rotation_z", 0))
			btn.scale = scale_xy
		# Template `pos` is measured from SlotsContainer's lower-left. The
		# original controller converts it to a centered localPosition by
		# subtracting half the RectTransform width/height before assigning it.
		var center := position_center + Vector2(
			pos.x - SOURCE_SLOTS_CONTAINER_SIZE.x * 0.5,
			SOURCE_SLOTS_CONTAINER_SIZE.y * 0.5 - pos.y
		)
		rects[slot_key] = _slot_rect_from_center(center, SOURCE_SLOT_SIZE)
	return rects


func _template_pos(value: Variant, fallback := Vector2.ZERO) -> Vector2:
	if value is Dictionary:
		return Vector2(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)))
	return fallback


## The resolved rite_template entry driving this panel's layout.
func _rite_template_data() -> Dictionary:
	var entry := _resolved_mapping(_rite)
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


## Source resolves absent/undersized mappings to mapping 0 before loading the
## template, so BG, slots and title must all share this decision.
## [SRC: RitePanelShowController.Show 0x596450 L380-438;
##       dump.cs RiteNode.cards_slot / RiteTemplateMappingNode.slot_open]
static func _resolved_mapping(rite: Dictionary) -> Dictionary:
	var mappings: Dictionary = _load_json("res://content/rite_template_mappings.json")
	var entry: Dictionary = mappings.get(str(int(rite.get("mapping_id", 0))), mappings["0"])
	if entry.get("slot_open", []).size() < rite.get("cards_slot", {}).size():
		return mappings["0"]
	return entry
