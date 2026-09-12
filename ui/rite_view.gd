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

class RiteDropSurface:
	extends ColorRect
	var owner_view: Control
	func _can_drop_data(_point: Vector2, data: Variant) -> bool:
		return not owner_view.panel_drop_slot(data).is_empty()
	func _drop_data(_point: Vector2, data: Variant) -> void:
		var slot: String = owner_view.panel_drop_slot(data)
		if not slot.is_empty():
			owner_view.drop_card_on_slot(slot, data)

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
var _awaiting_confirmation := false
var _result_paragraphs: Array[String] = []
var _result_paragraph_index := 0
var _db
var _rng
var _rite_id: int = 5000001
var _rite_uid: int = 0
var _rite: Dictionary = {}
var _placed: Dictionary = {}  # slot_key -> CardInstance uid
var _dragged_slot_widgets: Dictionary = {}
var _managed_slots: Array[int] = []
var _gold_used_this_resolve: int = 0
var _gold_dice_map: Dictionary = {}
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
var _result_surface: Control
var _result_surface_text: RichTextLabel
var _result_next_button: Button
var _play_rate_button: Button
var _result_auto_button: Button
var _result_play_rate := 1.0
var _result_auto_play := false
var _result_text_progress := 0.0
var _result_text_done := true
var _result_ops_layer: Control
var _result_hand_ops_layer: Control
var _result_cards_layer: Control
var _dice_prompt_surface: Control
var _dice_count_prompt_surface: Control
var _dice_roll_label: Label
var _dice_count_label: Label
var _dice_success_label: Label
var _dice_count_title: Label
var _dice_count_value: Label
var _dice_count_kind := ""
var _gold_selected: int = 0
var _selected_card_uid: int = 0
var _effect_drag_uid: int = 0
var _slot_effect_tweens: Dictionary = {}
var _slot_tips: Control
var _settlement_context: Dictionary = {}
var _settlement_phase := "selection"
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
	_shade = RiteDropSurface.new()
	_shade.owner_view = self
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
	_slot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_layer.name = "RiteSlotOverlay"
	# This layer receives literal source-canvas coordinates; full-rect anchors
	# would fight its 3840x2160 source size on every resize.
	_slot_layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_source_canvas.add_child(_slot_layer)
	_slot_tips = preload("res://ui/tips_view.gd").new()
	add_child(_slot_tips)
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
		# SourceJSON preserves repeated condition members as an ordered Array.
		# Slot s4 in the source has repeated !is entries, so its condition is no
		# longer a plain Dictionary even though the slot definition itself is.
		# Read the authored `type` member through the lossless accessor instead of
		# calling Dictionary.get on the condition value.
		var slot_condition: Variant = _rite.get("cards_slot", {}).get(slot_key, {}).get("condition", {})
		var type_name := str(SourceJSON.member(slot_condition, "type", ""))
		if ResourceLoader.exists("res://assets/original/ui/card_type_%s.png" % type_name):
			var icon := _picture(btn, "SlotType", "card_type_" + type_name, Rect2())
			var icon_size := icon.texture.get_size() * 1.7
			_set_rect(icon, Rect2(SOURCE_SLOT_SIZE * 0.5 + Vector2(0, 25) - icon_size * 0.5, icon_size))

		# [SRC: CardSlot.prefab Highlight + Selectable state relay:
		# HighlightEnabled=1, other states=0; 256x512 centered at (0,-19).]
		var highlight := _picture(btn, "SourceHighlight", "card_outline", Rect2(8, 11, 256, 512))
		# Same GUI SSU inner-outline variant as CardFlash (DXBC blob118),
		# with slot_highlight.mat's own color and permanently enabled fade.
		var highlight_material := ShaderMaterial.new()
		highlight_material.shader = preload("res://ui/card_flash.gdshader")
		highlight_material.set_shader_parameter("outline_color", Color(0.94639033, 0.8695029, 0.6157619, 1))
		highlight_material.set_shader_parameter("outline_width", 0.08)
		highlight_material.set_shader_parameter("outline_fade", 1.0)
		highlight.material = highlight_material
		highlight.visible = false
		btn.mouse_entered.connect(func(): highlight.visible = not btn.disabled and not btn.has_focus())
		btn.mouse_exited.connect(func(): highlight.visible = false)
		btn.button_down.connect(func(): highlight.visible = false)
		btn.focus_entered.connect(func(): highlight.visible = false)
		btn.focus_exited.connect(func(): highlight.visible = btn.is_hovered() and not btn.disabled and not btn.is_pressed())
		btn.button_up.connect(func(): highlight.visible = btn.is_hovered() and not btn.disabled and not btn.has_focus())
		var outline := _picture(btn, "SourceSatisfiedOutline", "rite_slot_outline", Rect2(37.5, 55.5, 197, 423))
		# Authored sibling order: BG, Prompt, OutlineNew, Types, Container,
		# Highlight. The broad drag glow must remain below the hover outline.
		btn.move_child(outline, 1)
		outline.modulate.a = 0.0
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
	_result_label = _rich_text("", 32)
	_result_label.name = "RiteResult"
	preload("res://ui/source_text_style.gd").apply(_result_label, "@MAIN_BODY")
	_result_label.fit_content = false
	_rite_panel.add_child(_result_label)
	_set_rect(_result_label, Rect2(167, 70, 710, 720))
	_result_label.visible = false
	_build_result_surface()
	_update_stop_button()
	_update_last_state_button()


## Source-shaped RiteResultPanel. The original switches from the preparation
## surface to a 3440x1820 settlement canvas with a dedicated result viewport
## and operation bar; keep the existing resolver controls as the semantic
## carrier while rendering this authored shell for the visible result state.
## [SRC: GameScene.md MainUI/UI/RiteResultPanel; RiteResultPanelController.c
##       @ Settlement (RVA 0x5a4800)]
func _build_result_surface() -> void:
	_result_surface = Control.new()
	_result_surface.name = "RiteResultPanel"
	# The result art is visual only; the blocking PromptNew sibling must still
	# receive input while a settlement operation is waiting. Its child Next
	# button remains an explicit interactive target.
	_result_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_surface.visible = false
	_source_canvas.add_child(_result_surface)
	_set_rect(_result_surface, Rect2(200, 170, 3440, 1820))
	var bg := _picture(_result_surface, "SettlementBackground", "settlement_bg", Rect2(0, 0, 3440, 1820))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# DicesBG is rendered by GameScene Camera 4420 (ortho half-height 8.91)
	# into DiceShow 1940x1800. Sprite native size is 1744x1608 at 100 PPU.
	# [SRC: GameScene.unity DicesBG 129 / Transform 3901 / Camera 4420;
	# Sprite/settlement_bg_dice.asset; runtime rite_result_power_20260910.jpg]
	var tray_size := Vector2(1744, 1608) * (1800.0 / 1782.0)
	_picture(_result_surface, "DicesBG", "settlement_bg_dice", Rect2(Vector2(912, 811) - tray_size * 0.5, tray_size))
	var title_bg := _picture(_result_surface, "TitleBG", "rite_title_bg_0", Rect2(1786, 55, 296.42, 78))
	var title := _source_label(_result_surface, "Title", Rect2(1786, 55, 296.42, 78), 60)
	title.text = _state.rite_display_name(_rite_id, _db) if _state != null else str(_rite.get("name", ""))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#111711"))
	var result_scroll := ScrollContainer.new()
	result_scroll.name = "Result"
	result_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_set_rect(result_scroll, Rect2(1786.36665, 191.79745, 1132.6333, 1185.2699))
	_result_surface.add_child(result_scroll)
	_result_surface_text = _rich_text("", 36)
	_result_surface_text.name = "Text (TMP)"
	_result_surface_text.fit_content = true
	_result_surface_text.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_surface_text.gui_input.connect(_on_result_text_input)
	_result_surface_text.custom_minimum_size = Vector2(1100, 1146)
	preload("res://ui/source_text_style.gd").apply(_result_surface_text, "@MAIN_BODY")
	# RiteResultPanel.prefab TextTranslate 114117307842306080, TMP paragraphSpacing=80.
	_result_surface_text.add_theme_constant_override("paragraph_separation", 80)
	_result_surface_text.add_theme_color_override("default_color", Color("#403525"))
	result_scroll.add_child(_result_surface_text)
	var op_bg := _picture(_result_surface, "Op BG", "settlement_op_bg", Rect2(1804, 1403, 1224, 188))
	op_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_next_button = _source_button_on(_result_surface, "Next", "rite_op_confirm_1", Rect2(1989, 1419, 604, 140), "继续", _on_result_next)
	# AutoPlay is a child of Op BG in the source prefab. Keep the exact
	# parent-relative offset and route clicks through the same player flag as
	# the preparation panel.
	# [SRC: GameScene.md MainUI/UI/RiteResultPanel/Op BG/AutoPlay;
	#       RiteResultPanelController.c OnAutoPlay 0x5a38d0]
	_result_auto_button = _source_button_on(_result_surface, "AutoPlay", "auto_play_deactive", Rect2(2668, 1445, 240, 88), "自动播放", _toggle_result_auto_play)
	_result_auto_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_auto_button.visible = false
	# Source PlayRate is an independent ImageButton, hidden until the result
	# surface is shown. Its authored rect is relative to RiteResultPanel.
	# [SRC: GameScene.md MainUI/UI/RiteResultPanel/PlayRate;
	#       RiteResultPanelController.c OnAutoPlay 0x5a38d0 /
	#       UpdateResultTextSpeed 0x5a74a0; content/variable.json]
	_play_rate_button = _source_button_on(_result_surface, "PlayRate", "play_speed_x1", Rect2(3067, 1441, 104, 104), "切换播放速度", _toggle_play_rate)
	_play_rate_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_play_rate_button.visible = false
	_build_result_lists()
	_build_dice_surfaces()


## Operation card destinations; these are NOT settlement/DSL text lists.
## [SRC: RiteResultPanelController.c AddCardToResults 0x5a0ff0;
## dump.cs:325461-325462 / OpCardShow.IsHandCard 321455]
func _build_result_lists() -> void:
	_result_ops_layer = Control.new()
	_result_ops_layer.name = "Op Results"
	_result_ops_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_surface.add_child(_result_ops_layer)
	_set_rect(_result_ops_layer, Rect2(1105, 169, 100, 100))

	_result_hand_ops_layer = Control.new()
	_result_hand_ops_layer.name = "Op Hand Results"
	_result_hand_ops_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_surface.add_child(_result_hand_ops_layer)
	_set_rect(_result_hand_ops_layer, Rect2(1316, 175, 100, 100))

	_result_cards_layer = Control.new()
	_result_cards_layer.name = "Op Cards"
	_result_cards_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_surface.add_child(_result_cards_layer)
	_set_rect(_result_cards_layer, Rect2(232, 510, 1440, 800))


func _clear_result_lists() -> void:
	for layer in [_result_ops_layer, _result_hand_ops_layer, _result_cards_layer]:
		if layer == null:
			continue
		for child in layer.get_children():
			layer.remove_child(child)
			# free(), not queue_free(): the rows are rebuilt on the same frame
			# and a deferred free would leave them orphaned at test teardown.
			child.free()


## Card-operation labels, keyed by the original CardOpType values.
## [SRC: dump.cs:394326 CardOpType NEW0 COPY1 DELETE2 EQUIP3 UNEQUIP4
##       UNEQUIP_RECOVERY5 ADD_TAG6 REMOVE_TAG7 UPRARE8 POP9 HAND_POP10
##       THINK_POP11 REBIRTH_SUDAN_CARD12]
const CARD_OP_LABELS := {
	0: "新增",
	1: "复制",
	2: "移除",
	3: "装备",
	4: "卸下",
	5: "卸下收回",
	6: "加标签",
	7: "减标签",
	8: "升稀有",
}

## One short line per card operation. The original plays a full OpCardNewController
## animation per queued CardOpContext (SetBG/SetEft/animation clip/pop); that
## playback layer is still unported, so this renders the real recorded operation
## stream as plain rows instead of leaving the authored destinations empty.
## [SRC: RiteResultPanelController.c @ AddCardOp (0x5a0e60) queues
##       CardOpContext into +0x1d8; OpCardNewController @ Init (0x572f40) is the
##       unported playback. Layers keep their authored rects.]
func _rebuild_result_lists(res) -> void:
	_clear_result_lists()
	# RiteResolver returns the deferred struct itself, so the recorded stream
	# sits at the top level (`res.card_ops`), not under `res.deferred`.
	var ops: Array = []
	if res is Dictionary:
		ops = (res as Dictionary).get("card_ops", [])
	if ops.is_empty():
		return
	var row_height := 34.0
	var index := 0
	for op in ops:
		if not (op is Dictionary):
			continue
		var op_type := int(op.get("op", -1))
		var label := str(CARD_OP_LABELS.get(op_type, "操作"))
		var card_name := _card_op_name(op)
		var layer := _result_cards_layer if op_type in [0, 1, 2, 8] else _result_ops_layer
		if layer == null:
			continue
		var row := Label.new()
		row.name = "CardOp%d" % index
		row.text = "%s %s" % [label, card_name]
		row.add_theme_font_size_override("font_size", 32)
		row.position = Vector2(0, index * row_height)
		row.size = Vector2(layer.size.x, row_height)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_meta("source_card_op", op_type)
		row.set_meta("source_card_uid", int(op.get("card_uid", 0)))
		layer.add_child(row)
		index += 1


## Best-effort card name for one recorded operation. The source rows carry a
## Card reference (CardOpContext.card@0x18); the clone's log carries the uid, so
## the name is resolved from the live instance, falling back to the config id.
## [SRC: CardOpContext fields dump.cs:6305; CardExtensions.GetName 0x37ff50]
func _card_op_name(op: Dictionary) -> String:
	var uid := int(op.get("card_uid", 0))
	if _state != null and uid > 0:
		var card: Dictionary = _state.card_data_for(uid, _db)
		if not card.is_empty():
			var name := str(card.get("name", ""))
			if not name.is_empty():
				return name
	return str(op.get("card_id", ""))


func _toggle_play_rate() -> void:
	# The source has exactly TWO rates, both from variable.json, and picks
	# between them by the auto-play flag — there is no x1/x2 cycle.
	# [SRC: RiteResultPanelController.c @ UpdateResultTextSpeed (0x5a74a0):
	#       param_2 == 0 -> Player.result_text_play_rate@0x68, else
	#       Player.result_text_auto_play_rate@0x6C, clamped to
	#       [DAT_181c92b4c, DAT_181c9e4d0] = [0.5, 100.0] and written to
	#       ScrollViewTextController+0x38.]
	_result_auto_play = not _result_auto_play
	_refresh_play_rate()
	if _result_surface_text != null:
		_result_surface_text.set_meta("source_play_rate", _result_play_rate)


func _on_result_next() -> void:
	if _resolution_committed:
		_close_panel()
		return
	if not _dice_count_kind.is_empty():
		return
	# [SRC: ScrollViewTextController.c @ ForceTypeDone (0x5a8da0);
	#       RiteResultPanelController.c @ OnNext (0x5a43c0)]
	if not _result_text_done:
		_result_text_done = true
		if _result_surface_text != null:
			_result_surface_text.visible_characters = -1
		return
	if _result_paragraph_index < _result_paragraphs.size():
		_append_result_paragraph()
		return
	_resolve()


func _on_result_text_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_advance_result_text()
		_result_surface_text.accept_event()


## The original waits after every newline-split paragraph. Clicking the
## text finishes typing, then a separate click advances the waiting Promise.
## [SRC: ShowTextWithSeperator 0x5a6810 -> WaitingResultTextDone;
## ScrollViewTextController.ForceTypeDone 0x5a8da0; original runtime 2026-09-11.]
func _advance_result_text() -> void:
	if _waiting_for_result_operations() or not _dice_count_kind.is_empty():
		return
	if not _result_text_done:
		_result_surface_text.visible_characters = -1
		_result_text_done = true
		return
	if _result_paragraph_index < _result_paragraphs.size():
		_append_result_paragraph()
	elif _resolution_pending and _settlement_phase == "selection":
		_commit_resolution()


func _append_result_paragraph() -> void:
	if _result_paragraph_index >= _result_paragraphs.size():
		_result_text_done = true
		return
	var previous_count := _result_surface_text.get_total_character_count()
	var text := _result_paragraphs[_result_paragraph_index]
	_result_paragraph_index += 1
	var separator := "\n\n" if not _result_surface_text.text.is_empty() else ""
	_result_surface_text.text += separator + preload("res://ui/source_rich_text.gd").to_bbcode(text)
	_result_text_progress = float(previous_count)
	_result_surface_text.visible_characters = previous_count
	_result_text_done = false


func _refresh_play_rate() -> void:
	if _play_rate_button == null:
		return
	# Both rates come from variable.json through GameState; the panel only
	# chooses between them, and the auto-play toggle is what selects.
	# [SRC: RiteResultPanelController.c @ UpdateResultTextSpeed 0x5a74a0.]
	if _state != null:
		_result_play_rate = _state.source_result_text_rate(_result_auto_play)
	var art := "x1" if _result_play_rate <= 1.0 else "x2"
	_play_rate_button.get_node("Art").texture = load("res://assets/original/ui/play_speed_%s.png" % art)
	_play_rate_button.set_meta("source_play_rate", _result_play_rate)


func _toggle_result_auto_play() -> void:
	# [SRC: RiteResultPanelController.OnAutoPlay 0x5a38d0, autoPlay@0x184:
	#       PlayerExtensions.SetRiteAutoResult 0x38f790 writes Player+0x160,
	#       NOT the per-rite HashSet at +0x130; dump.cs:391586,391598.]
	_result_auto_play = not _result_auto_play
	_state.rite_auto_result = _result_auto_play
	_refresh_play_rate()
	_refresh_result_auto_button()
	_refresh_auto_result()


func _refresh_result_auto_button() -> void:
	if _result_auto_button == null:
		return
	var active: bool = _state != null and _state.rite_auto_result
	_result_auto_button.get_node("Art").texture = load("res://assets/original/ui/auto_play_%s.png" % ("active" if active else "deactive"))


## Source prefab children of RiteResultPanel.  These remain hidden until the
## resolver actually produced a dice check; the dimensions and authored
## offsets come from RiteResultPanel.prefab DicePromptNew/DiceCountPromptNew.
## [SRC: RiteResultPanel.prefab RectTransform 224401109917237556,
## 224728442554800362; RiteResultPanelController.c ShowDicePrompt 0x5a5910,
## ShowDiceCountPrompt 0x5a5760]
func _build_dice_surfaces() -> void:
	_dice_prompt_surface = Control.new()
	_dice_prompt_surface.name = "DicePromptNew"
	_dice_prompt_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dice_prompt_surface.visible = false
	_result_surface.add_child(_dice_prompt_surface)
	_set_rect(_dice_prompt_surface, Rect2(452.5, 297, 1032, 1032))
	_dice_prompt_surface.position.x = 452.5 # Preserve the source half-unit pivot.
	_picture(_dice_prompt_surface, "BG", "dice_prompt_bg", Rect2(0, 0, 1032, 1032))
	_picture(_dice_prompt_surface, "Normal", "dice_prompt_normal", Rect2(356, 84, 320, 864))
	var fight_art := _picture(_dice_prompt_surface, "Fight", "dice_prompt_fight", Rect2(84, 84, 864, 864))
	fight_art.visible = false
	var ring := _picture(_dice_prompt_surface, "Ring", "dice_prompt_ring", Rect2(460, 460, 112, 112))
	ring.visible = false
	_dice_count_label = _source_label(_dice_prompt_surface, "Count", Rect2(416, 250, 200, 100), 46)
	_dice_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dice_roll_label = _source_label(_dice_prompt_surface, "CurrentDices", Rect2(300, 355, 440, 100), 30)
	_dice_roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dice_success_label = _source_label(_dice_prompt_surface, "Success", Rect2(300, 455, 440, 100), 30)
	_dice_success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_dice_count_prompt_surface = Control.new()
	_dice_count_prompt_surface.name = "DiceCountPromptNew"
	_dice_count_prompt_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dice_count_prompt_surface.visible = false
	_result_surface.add_child(_dice_count_prompt_surface)
	_set_rect(_dice_count_prompt_surface, Rect2(530.5, 427, 876, 876))
	_dice_count_prompt_surface.position.x = 530.5
	_picture(_dice_count_prompt_surface, "BG", "bg_5", Rect2(0, 0, 876, 876))
	# Authored side controls belong to DiceCountPromptNew, not the hidden
	# preparation panel. [SRC: RiteResultPanel.prefab; dump.cs:324673]
	_gold_dice_btn = _source_button_on(_dice_count_prompt_surface, "GoldDice", "gold_bg", Rect2(-162, 7, 372, 832), "金骰子", func(): _show_dice_count_prompt("gold"))
	_picture(_gold_dice_btn, "Icon", "gold_active", Rect2(50, 281, 140, 124))
	var gold_title := _source_label(_gold_dice_btn, "Title", Rect2(-70, 34, 372, 832), 60)
	gold_title.text = "金骰子"
	gold_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_picture(_gold_dice_btn, "CountBG", "checkbox_bg", Rect2(84, 487, 60, 60))
	_gold_dice_label = _source_label(_gold_dice_btn, "Count", Rect2(14, 490, 200, 50), 36)
	_gold_dice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reroll_btn = _source_button_on(_dice_count_prompt_surface, "Redraw", "redraw_bg", Rect2(681, -5, 360, 848), "重投", func(): _show_dice_count_prompt("reroll"))
	_picture(_reroll_btn, "Icon", "redraw_active", Rect2(178, 293, 128, 132))
	var redraw_title := _source_label(_reroll_btn, "Title", Rect2(61, 45, 360, 848), 60)
	redraw_title.text = "重投"
	redraw_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	redraw_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_picture(_reroll_btn, "CountBG", "checkbox_bg", Rect2(213, 510, 60, 60))
	var redraw_count := _source_label(_reroll_btn, "Count", Rect2(143, 513, 200, 50), 36)
	redraw_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dice_count_title = _source_label(_dice_count_prompt_surface, "Tips", Rect2(138, 553, 600, 72.1095), 40)
	_dice_count_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dice_count_value = _source_label(_dice_count_prompt_surface, "Count", Rect2(338, 307, 200, 144), 120)
	_dice_count_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for spec in [
		["Gold Cancel", "cancel", Rect2(-269.5, 574, 124, 124)],
		["Gold Confirm", "confirm", Rect2(-94, 576, 240, 120)],
		["Redraw Cancel", "cancel", Rect2(747, 574, 124, 124)],
		["Redraw Confirm", "confirm", Rect2(920, 576, 240, 120)],
	]:
		var callback := _cancel_dice_selection if str(spec[0]).ends_with("Cancel") else _confirm_dice_count_prompt
		_source_button_on(_dice_count_prompt_surface, spec[0], spec[1], spec[2], "取消" if str(spec[0]).ends_with("Cancel") else "确认", callback).hide()


func _refresh_dice_surface(res) -> void:
	if _dice_prompt_surface == null:
		return
	var rolls: Array = res.dice_rolls if res != null else []
	var has_dice := not rolls.is_empty()
	_dice_prompt_surface.visible = false
	_dice_count_prompt_surface.visible = has_dice
	if has_dice:
		_refresh_dice_selection()
	if not has_dice:
		return
	# random_text_up carries the authored count-decision hint. Do not invent
	# a target from whichever branch happened to succeed.
	var hint: Dictionary = _rite.get("random_text_up", {}).get(_gold_type_for_reactive_spend(), {})
	_dice_count_title.text = str(hint.get("low_target_tips", ""))
	var fight: bool = res.dice_types_seen is Array and "f" in res.dice_types_seen
	_dice_prompt_surface.get_node("Normal").visible = not fight
	_dice_prompt_surface.get_node("Fight").visible = fight
	_dice_count_label.text = "骰子 × %d" % rolls.size()
	_dice_roll_label.text = "结果: " + "  ".join(rolls.map(func(v): return str(v)))
	_dice_success_label.text = "成功数: %d" % _successes_for_result(res)


func _successes_for_result(res) -> int:
	if res == null:
		return 0
	var threshold := 5
	var entry: Dictionary = res.normal_entry if res.normal_entry is Dictionary else {}
	# Lossless source conditions become an ordered Array when a member repeats.
	# Use entries() here as well as in the resolver so the result prompt cannot
	# crash while inspecting an authored repeated r1 condition.
	for condition_entry in SourceJSON.entries(entry.get("condition", {})):
		var key := str(condition_entry.keys()[0]) if condition_entry is Dictionary and not condition_entry.is_empty() else ""
		var value = condition_entry[key] if not key.is_empty() else null
		if str(key).begins_with("r") and value is Array and value.size() > 1:
			threshold = int(value[1])
			break
	var successes := 0
	for face in res.dice_rolls:
		if int(face) >= threshold:
			successes += 1
	return successes


# [SRC: RiteResultDiceCountPromptController.c OnGoldAdd 0x59d360,
# OnGoldCancel 0x59d6f0 / OnRedraw 0x59dc40; GoldAddCount@0xD4,
# RedrawUsed@0xDC, dump.cs:324690. Selection does not spend player resources.]
func _show_dice_count_prompt(kind: String) -> void:
	if _dice_count_prompt_surface == null or not _resolution_pending or _waiting_for_result_operations():
		return
	if kind == "gold":
		if _dice_count_kind == "reroll" or _gold_selected >= _state.gold_dice:
			return
		_gold_selected += 1
	elif kind == "reroll":
		if _gold_selected > 0 or _dice_count_kind == "reroll" or _rerolls_left <= 0:
			return
	else:
		return
	_dice_count_kind = kind
	_dice_count_prompt_surface.show()
	_refresh_dice_selection()


func _refresh_dice_selection() -> void:
	if _dice_count_prompt_surface == null:
		return
	for node_name in ["Gold Cancel", "Gold Confirm"]:
		_dice_count_prompt_surface.get_node(node_name).visible = _gold_selected > 0
	for node_name in ["Redraw Cancel", "Redraw Confirm"]:
		_dice_count_prompt_surface.get_node(node_name).visible = _dice_count_kind == "reroll"
	_gold_dice_label.text = str(maxi(0, _state.gold_dice - _gold_selected))
	_reroll_btn.get_node("Count").text = str(maxi(0, _rerolls_left - int(_dice_count_kind == "reroll")))
	_dice_count_value.text = str(_successes_for_result(_last_result))
	if _gold_selected > 0:
		_dice_count_value.text += " + " + str(_gold_selected)
	_update_gold_button()
	_update_reroll_button()
	if _result_next_button != null:
		_update_result_wait_controls()


func _cancel_dice_selection() -> void:
	_gold_selected = 0
	_dice_count_kind = ""
	_refresh_dice_selection()


func _hide_dice_count_prompt() -> void:
	if _dice_count_prompt_surface != null:
		_dice_count_prompt_surface.hide()
	_gold_selected = 0
	_dice_count_kind = ""


func _confirm_dice_count_prompt() -> void:
	if _waiting_for_result_operations():
		return
	var kind := _dice_count_kind
	var amount := _gold_selected
	_cancel_dice_selection()
	if kind == "gold" and amount > 0:
		_use_gold_dice_reactive(amount)
	elif kind == "reroll":
		_use_reroll()


func _source_button_on(parent: Control, node_name: String, asset: String, rect: Rect2, hint: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.tooltip_text = hint
	button.add_theme_font_override("font", SOURCE_FONT)
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	parent.add_child(button)
	_set_rect(button, rect)
	var art := _picture(button, "Art", asset, Rect2(Vector2.ZERO, rect.size))
	button.mouse_entered.connect(func(): art.modulate = Color(1.2, 1.2, 1.2))
	button.mouse_exited.connect(func(): art.modulate = Color.WHITE)
	button.pressed.connect(callback)
	return button

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
	if _source_canvas.get_node_or_null("RiteHelp") != null:
		return
	# [SRC: RitePanelTitle.prefab CommonContent/Help and its four prompts.]
	var help := Control.new()
	help.name = "RiteHelp"
	help.size = Vector2(4096, 2160)
	help.position = _rite_panel.position + _rite_panel.size * 0.5 - help.size * 0.5 - Vector2(0, 210)
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_source_canvas.add_child(help)
	var mask := ColorRect.new()
	mask.name = "Mask"
	mask.color = Color(0, 0, 0, 128.0 / 255.0)
	mask.size = Vector2(10000, 10000)
	mask.position = (help.size - mask.size) * 0.5
	help.add_child(mask)
	mask.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			mask.accept_event()
			help.get_parent().remove_child(help)
			help.queue_free()
	)
	_picture(help, "Prompt", "rite_help", Rect2(-949, 233, 4096, 2160))
	var labels: Dictionary = _load_json("res://content/ui.json")
	var rows := [["MAIN", Vector2(-1472, -713), Vector2(1000, 200)], ["DESC", Vector2(-41, -713), Vector2(600, 200)], ["TIME", Vector2(267, 514), Vector2(600, 200)], ["TAG", Vector2(623, -464), Vector2(600, 200)]]
	for row in rows:
		var value: String = str(labels.get("RITE_HELP_%s_PROMPT" % row[0], {}).get("zhCN", ""))
		var label := _rich_text(preload("res://ui/main_help.gd")._to_bbcode(value), 50)
		label.name = "%sPrompt" % row[0]
		preload("res://ui/source_text_style.gd").apply(label, "@HELP_TEXT")
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		help.add_child(label)
		var pos: Vector2 = help.size * 0.5 + row[1] * Vector2(1, -1) - row[2] * Vector2(0.5, 1)
		_set_rect(label, Rect2(pos, row[2]))
		if row[0] == "TIME":
			# RitePanelTitle.prefab TimePrompt TMP vertical alignment 1024 = Bottom.
			label.fit_content = false
			label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM


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
	if _slot_tips != null:
		_slot_tips.apply_source_layout(view_size)
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


# Result and start actions await their prompt promises before another panel
# action can mutate the running rite.
func _waiting_for_result_operations() -> bool:
	return _awaiting_confirmation or (_resolution_pending and _state != null and not _state.pending_operations.is_empty())


func _process(_delta: float) -> void:
	_update_drag_slot_effects()
	if _awaiting_confirmation:
		RiteSettlement.pump_confirmations(_state)
		_complete_confirmation()
	if _settlement_phase in ["results", "actions"] and _state != null and _state.pending_operations.is_empty():
		_advance_settlement_execution()
	var waiting := _waiting_for_result_operations()
	if waiting != _last_result_waiting:
		_update_result_wait_controls()
	if _close_after_commit and _resolution_pending and not waiting:
		_commit_resolution()
	if _result_surface_text != null and _result_surface_text.visible and not _result_text_done:
		var total := _result_surface_text.get_total_character_count()
		if total <= 0:
			_result_text_done = true
		else:
			# One rate, from one place: just write it into the surface meta so
			# the value stays inspectable.
			# [SRC: RiteResultPanelController.c @ UpdateResultTextSpeed
			#       0x5a74a0; dump.cs:387291 Player.result_text_play_rate@0x68 /
			#       result_text_auto_play_rate@0x6C.]
			_result_text_progress = minf(float(total), _result_text_progress + _delta * 20.0 * _result_play_rate)
			_result_surface_text.visible_characters = int(_result_text_progress)
			if _result_text_progress >= float(total):
				_result_text_done = true
	if _result_auto_play and _result_text_done and _resolution_pending and not waiting and _dice_count_kind.is_empty():
		_advance_result_text()


func _update_result_wait_controls() -> void:
	_last_result_waiting = _waiting_for_result_operations()
	_update_resolve_button()
	_update_gold_button()
	_update_reroll_button()
	if _close_btn != null:
		_close_btn.disabled = _last_result_waiting
	if _result_next_button != null:
		_result_next_button.visible = true
		_result_next_button.disabled = _last_result_waiting or not _dice_count_kind.is_empty() or (_resolution_pending and _settlement_phase == "selection")


func _on_slot_pressed(slot_key: String) -> void:
	if not _can_edit_slot(slot_key):
		return
	if _resolution_pending or _resolution_committed:
		return
	if _selected_card_uid <= 0:
		if not _placed.has(slot_key):
			_focus_qualified_hand(slot_key)
			_play_slot_effect(slot_key, "flash")
		return
	var slot_def: Dictionary = _rite.get("cards_slot", {}).get(slot_key, {})
	var card: Dictionary = _state.card_data_for(_selected_card_uid, _db)
	if not _slot_accepts_card(slot_def, card):
		return
	_place_card_in_slot(slot_key, _selected_card_uid, "hand", "")
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
	if _cost_stack_context(slot_key, card_uid).get("is_cost", false):
		return true
	return _try_update_card(slot_key, card)


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
	if _try_cost_stack(slot_key, card_uid):
		_selected_card_uid = 0
		_after_placement_changed()
		return
	if not _try_update_card(slot_key, card):
		return
	_place_card_in_slot(slot_key, card_uid, str(data.get("source", "")), str(data.get("source_slot", "")), int(data.get("source_rite_uid", _rite_uid)))
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


# [SRC: CardDropManager.DropCard 0x4ef4f0: two ordered passes over Slots;
# current==null first, current!=null second, can_move and CanPutCard/is_cost.]
func panel_drop_slot(data: Variant) -> String:
	if not (data is Dictionary) or _resolution_pending or _resolution_committed:
		return ""
	if not preload("res://ui/rite_slot_access.gd").can_move_source(_state, _db, data):
		return ""
	var uid := _dragged_card_uid(data)
	if uid <= 0 or _state.get_card_instance(uid) == null:
		return ""
	var card: Dictionary = _state.card_data_for(uid, _db)
	for occupied in [false, true]:
		for key in _slot_keys():
			if _placed.has(key) != occupied or not _can_edit_slot(key):
				continue
			var ctx := _slot_condition_context(_rite.cards_slot[key], card, false)
			if bool(ctx.get("accepted", false)) or bool(ctx.get("is_cost", false)):
				# The source dispatches the first candidate once, even if the
				# subsequent destination-cleared TryUpdateCard rejects it.
				return key if can_drop_card_on_slot(key, data) else ""
	return ""


func _update_drag_slot_effects() -> void:
	if _state == null or not is_inside_tree():
		return
	var data: Variant = get_viewport().gui_get_drag_data() if get_viewport().gui_is_dragging() else null
	var uid := _dragged_card_uid(data)
	if uid == _effect_drag_uid:
		return
	_effect_drag_uid = uid
	show_satisfied_slots(uid)


# [SRC: RitePanelShowController.ShowSatisfiedSlot 0x596070;
# CardSlotController.ShowEffect 0x53cb50; CardSlot.prefab OutlineNew.]
func show_satisfied_slots(card_uid: int) -> void:
	var card: Dictionary = _state.card_data_for(card_uid, _db) if card_uid > 0 else {}
	for key in _slot_buttons:
		var matched := false
		if not card.is_empty() and not _placed.has(key) and _can_edit_slot(key):
			var ctx := _slot_condition_context(_rite.cards_slot[key], card, false)
			matched = bool(ctx.get("accepted", false)) or bool(ctx.get("is_cost", false))
		_play_slot_effect(key, "show" if matched else "hide")


func _play_slot_effect(key: String, clip: String) -> void:
	if not _slot_buttons.has(key) or not is_inside_tree():
		return
	var outline := _slot_buttons[key].get_node("SourceSatisfiedOutline") as TextureRect
	if str(outline.get_meta("clip", "hide")) == clip and clip != "flash":
		return
	if _slot_effect_tweens.has(key):
		_slot_effect_tweens[key].kill()
	outline.set_meta("clip", clip)
	# Original show/hide and flash OutlineNew alpha keys have zero tangents:
	# 0 -> 1 over .33333334s, flash returns to 0 at .6666667s.
	# Hermite with zero tangents is smoothstep, not a guessed easing curve.
	var tween := create_tween()
	_slot_effect_tweens[key] = tween
	var start := 1.0 if clip == "hide" else 0.0
	var finish := 0.0 if clip == "hide" else 1.0
	outline.modulate.a = start
	tween.tween_method(func(t: float): outline.modulate.a = lerpf(start, finish, smoothstep(0.0, 1.0, t)), 0.0, 1.0, 0.33333334)
	if clip == "flash":
		tween.tween_method(func(t: float): outline.modulate.a = 1.0 - smoothstep(0.0, 1.0, t), 0.0, 1.0, 0.33333336)


func _dragged_card_uid(data: Variant) -> int:
	if not (data is Dictionary):
		return 0
	if str(data.get("type", "")) != "card":
		return 0
	return int(data.get("card_uid", data.get("card_id", 0)))


func _after_placement_changed() -> void:
	_effect_drag_uid = -1
	_qualified_slot = ""
	_qualified_bags.clear()
	_qualified_bag_index = -1
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
		btn.tooltip_text = ""
		if _slot_tips != null:
			_slot_tips.attach(_db, btn, "", slot_text)
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
	if _awaiting_confirmation or (_state != null and _state.rite_confirmations.has(str(_rite_uid))):
		return
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
			_awaiting_confirmation = true
			RiteSettlement.confirm_start(_rite_uid, _state)
			_complete_confirmation()
			return
	# Fresh selection retains live player state; gold retries reuse dice only.
	# [SRC: RiteResultDiceCountPromptController.c @ OnGoldConfirm (0x59d8b0)]
	_gold_used_this_resolve = 0
	_gold_dice_map.clear()
	_resolve_dice_cache.clear()
	_rerolls_left = _reroll_count()
	_prepare_table_from_placements()
	_pending_table_entries = _state.cards_in_slot_entries_for_rite(_rite_uid)
	_result_auto_play = _state.rite_auto_result
	_do_resolve()
	# [SRC: GameController.Settlement 0x556ae0 reads Player.auto_result_rites
	# via GameApplication -> Datapool.player(+0x70) -> Player(+0x130).]
	if _state.auto_result_rites.has(_rite_id):
		_close_after_commit = true
		_commit_resolution()


func _complete_confirmation() -> void:
	if not _awaiting_confirmation or _state.rite_confirmations.has(str(_rite_uid)):
		return
	_awaiting_confirmation = false
	if int(_rite.get("round_number", 0)) > 0:
		_update_resolve_button()
		_update_stop_button()
		closed.emit()
	else:
		_resolve()


func _do_resolve() -> void:
	# Selection is read-only with respect to final results. Retry only changes
	# dice decisions; it must not deserialize the entire player over live events.
	if _settlement_phase != "selection":
		return
	var ctx := {
		"db": _db, "state": _state, "rng": _rng,
		"rite_state": _rite_state_from_placements(), "rite_uid": _rite_uid,
		"attr_slots": _slot_keys(), "rite_id": _rite_id,
		"dice_cache": _resolve_dice_cache,
		"slot_entries": _slot_entries_from_placements(),
	}
	if _state != null and _state.has_method("with_player_actor_context"):
		ctx = _state.with_player_actor_context(ctx, _db)
	# Actor enrichment deep-copies dictionaries. Keep the settlement's live
	# dice cache across GoldDiceException retries; redraw alone clears it.
	# [SRC: FuncCompare.c IsSatisfied 0x3fc060, ConditionContext.dices@0x40;
	# RiteResultPanelController.DisplayClass88_0 b__5 0x5b7fe0.]
	ctx["dice_cache"] = _resolve_dice_cache
	var gold_dice_bonus = _gold_used_this_resolve
	if not _gold_dice_map.is_empty():
		gold_dice_bonus = _gold_dice_map
	_state.active_rite_uid = _rite_uid
	var res = RiteResolver.select_settlements(_rite, ctx, gold_dice_bonus)
	_state.active_rite_uid = 0
	_last_result = res
	_settlement_context = ctx
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
	if _settlement_phase == "selection":
		_settlement_phase = "results"
		var job := RiteSettlement.begin(_rite_uid, _last_result, _settlement_context, _state, _db, _rng)
		_last_result.deferred = job.deferred
		_advance_settlement_execution()
		return
	if _settlement_phase != "done":
		return
	_resolution_pending = false
	_resolution_committed = true
	_update_result_wait_controls()
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


func _advance_settlement_execution() -> void:
	RiteSettlement.pump(_state, _db, _rng)
	if not _state.pending_operations.is_empty():
		_update_result_wait_controls()
		_refresh_game_screen()
		return
	if not _state.rite_settlements.has(str(_rite_uid)):
		_settlement_phase = "done"
		_commit_resolution()
		_refresh_game_screen()


## Closing selection abandons the uncommitted selection only. It never
## restores a player snapshot or refunds already spent gold dice.
func _close_panel() -> void:
	if _waiting_for_result_operations():
		return
	_qualified_slot = ""
	_qualified_bags.clear()
	_qualified_bag_index = -1
	if _resolution_pending and _settlement_phase == "selection" and _state != null:
		_resolution_pending = false
		_last_result = null
		_gold_used_this_resolve = 0
		_gold_dice_map.clear()
		_resolve_dice_cache.clear()
		_pending_table_entries.clear()
		_clear_result_lists()
		if _result_surface != null:
			_result_surface.visible = false
		if _play_rate_button != null:
			_play_rate_button.visible = false
		if _result_auto_button != null:
			_result_auto_button.visible = false
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
	# [SRC: DisplayClass77_0 b__3 0x5b5b70 / DisplayClass79_0;
	# AppendResultText 0x5a13e0; variable.json RESULT_TEXT_FORMAT={0}.]
	var entries: Array = res.settlements
	var sections: PackedStringArray = []
	# Settlement first shows RiteNode.text before prior/normal branch text.
	# [SRC: RiteResultPanelController.c Settlement 0x5a4800, rite.node@0x50
	# text@0x20 -> ShowTextWithSeperator; DisplayClass56_0 b__0 0x5b3300.]
	var introduction := str(_rite.get("text", ""))
	if _state != null:
		introduction = _state.substitute_text(introduction)
	if not introduction.is_empty():
		sections.append(introduction)
	for entry in entries:
		for key in ["result_title", "result_text"]:
			var value := str(entry.get(key, ""))
			if _state != null:
				value = _state.substitute_text(value)
			if not value.is_empty():
				sections.append(value)
	var txt := "\n".join(sections)
	if _result_label:
		_result_label.text = txt
	if _result_surface_text:
		_result_surface_text.text = ""
		_result_paragraphs.clear()
		for section in sections:
			for paragraph in section.split("\n", false):
				_result_paragraphs.append(paragraph)
		_result_paragraph_index = 0
		_append_result_paragraph()
		_result_surface_text.set_meta("source_character_per_second", 20.0)
	_rebuild_result_lists(res)
	if _result_surface:
		_result_surface.visible = true
		_result_surface.move_to_front()
	if _play_rate_button != null:
		_play_rate_button.visible = true
		_refresh_play_rate()
	if _result_auto_button != null:
		_result_auto_button.visible = true
		_refresh_result_auto_button()
	_refresh_dice_surface(res)
	if _result_next_button:
		_result_next_button.visible = true
		_result_next_button.disabled = true


func _update_gold_button() -> void:
	var can_spend: bool = _state != null and _state.gold_dice > 0 and _last_result != null and _resolution_pending and _settlement_phase == "selection"
	if _gold_dice_btn == null:
		return
	_gold_dice_btn.disabled = not can_spend or _waiting_for_result_operations() or _dice_count_kind == "reroll" or _gold_selected >= _state.gold_dice


func _use_gold_dice_reactive(amount: int = 1) -> void:
	if _waiting_for_result_operations():
		return
	if _settlement_phase != "selection" or not _resolution_pending or amount <= 0 or _state.gold_dice < amount:
		return
	GameAudio.cue("drop_card_gold.ogg")
	_gold_used_this_resolve += amount
	_state.gold_dice -= amount
	var type_key := _gold_type_for_reactive_spend()
	_gold_dice_map[type_key] = int(_gold_dice_map.get(type_key, 0)) + amount
	_do_resolve()


## Reroll spends one 重投 charge and re-rolls every die of the settlement
## (dice cache cleared; the baseline rollback in _do_resolve unwinds the
## previous result first). [SRC: OnRedrawConfirm (0x59db60) rejects the
## settlement promise with RetryException; dice re-roll, gold dice do not]
func _use_reroll() -> void:
	if _waiting_for_result_operations():
		return
	if _settlement_phase != "selection" or not _resolution_pending or _rerolls_left <= 0:
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
	_reroll_btn.disabled = not (_resolution_pending and _rerolls_left > 0 and _settlement_phase == "selection") or _waiting_for_result_operations() or not _dice_count_kind.is_empty()


## OnStop: a started multi-day rite can be halted. Cards stay in their slots,
## life rolls back to start_life, and the panel returns to arrangement mode.
## [SRC: RitePanelController.c @ OnStop (RVA 0x5906e0), lines 1442-1462]
func _stop_started_rite() -> void:
	if _state == null or _rite_uid <= 0 or not _state.has_method("stop_rite_instance"):
		return
	if _waiting_for_result_operations() or _resolution_pending or _resolution_committed or not _can_stop_this_round():
		return
	if _state.stop_rite_instance(_rite_uid):
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
		_gold_dice_label.text = str(maxi(0, _state.gold_dice - _gold_selected))
	if _rite_panel != null:
		var has_result := _last_result != null
		_rite_panel.visible = not has_result
		_template_backdrop.visible = not has_result
		if _template_foreground != null:
			_template_foreground.visible = not has_result
		_slot_layer.visible = not has_result
		_rite_panel.get_node("RiteDescriptionScroll").visible = not has_result
		_result_label.visible = has_result
		if _result_surface != null:
			_result_surface.visible = has_result
		if _play_rate_button != null:
			_play_rate_button.visible = has_result
		if _result_auto_button != null:
			_result_auto_button.visible = has_result
			if has_result:
				_refresh_result_auto_button()
		if not has_result:
			if _dice_prompt_surface != null:
				_dice_prompt_surface.visible = false
			if _dice_count_prompt_surface != null:
				_dice_count_prompt_surface.visible = false


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


# [SRC: CardSlotController.CardStack 0x53b0a0; current@0x148,
# ConditionContext.is_first_drop@0x22. Evaluate combined count using the
# existing slot card identity, then restore the speculative count immediately.]
func _cost_stack_context(slot_key: String, incoming_uid: int) -> Dictionary:
	var incoming = _state.get_card_instance(incoming_uid)
	if incoming == null or not _state._instance_is_stackable(incoming):
		return {}
	var target_uid := int(_placed.get(slot_key, 0))
	if target_uid == incoming_uid:
		return {}
	var target = _state.get_card_instance(target_uid)
	var same: bool = target != null and target.card_id == incoming.card_id and _state._instance_is_stackable(target)
	var original_count := int(target.count) if same else 0
	if same:
		target.count += incoming.count
	var ctx := _slot_condition_context(_rite.get("cards_slot", {}).get(slot_key, {}),
		_state.card_data_for(target_uid if same else incoming_uid, _db), not same)
	if same:
		target.count = original_count
	ctx["merge_uid"] = target_uid if same else 0
	return ctx


func _try_cost_stack(slot_key: String, incoming_uid: int) -> bool:
	var ctx := _cost_stack_context(slot_key, incoming_uid)
	# Original CardStack intentionally ignores CanPutCard's bool: a matching
	# but underfunded cost is a valid partial deposit (SetNeedCosts still ran).
	if not bool(ctx.get("is_cost", false)):
		return false
	var needed := int(ctx.get("cost_count", 0))
	var incoming = _state.get_card_instance(incoming_uid)
	var merge_uid := int(ctx.get("merge_uid", 0))
	if merge_uid > 0:
		var target = _state.get_card_instance(merge_uid)
		var remainder := int(target.count) + int(incoming.count) - needed
		target.count = needed
		if remainder < 1:
			_state.remove_card_instance_from_play(incoming_uid)
			for key in _placed.keys():
				if int(_placed[key]) == incoming_uid:
					_placed.erase(key)
		else:
			incoming.count = remainder
		return true
	if _placed.has(slot_key):
		_return_slot_to_hand(slot_key)
	var previous_slot := str(incoming.slot_key)
	var previous_rite := int(incoming.rite_uid)
	var paid_uid: int = _state.pay_cost_into_slot(incoming_uid, slot_key.substr(1).to_int(), needed, _db, _rite_uid)
	if paid_uid <= 0:
		return false
	if paid_uid == incoming_uid and previous_rite == _rite_uid:
		_placed.erase(previous_slot)
	_placed[slot_key] = paid_uid
	return true


func _place_card_in_slot(slot_key: String, card_uid: int, source: String, source_slot: String, source_rite_uid: int = 0) -> void:
	if _try_cost_stack(slot_key, card_uid):
		return
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
	widget.drag_started.connect(_begin_slot_drag.bind(widget))
	widget.drag_finished.connect(_finish_slot_drag.bind(widget))
	widget.quick_action_requested.connect(func(_uid: int): return_card_to_hand(card_uid, slot_key))
	widget.name = "PlacedCard_%s" % slot_key.to_upper()
	# [SRC: CardSlotController.SetCard 0x53c7d0; CardSlot.prefab Container]
	# Preserve the card's own size and centre it in
	# the 100x100 Container, whose authored offset is (1.6,-19.6).
	var container := Control.new()
	container.name = "Container"
	container.position = Vector2(87.6, 217.6)
	container.size = Vector2(100, 100)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(container)
	btn.move_child(container, btn.get_node("SourceHighlight").get_index())
	widget.position = (container.size - widget.card_size()) * 0.5
	# [SRC: CardController.OnPointerUp 0x52afe0: ordinary short click toggles
	# ShowCardInfo; RemoveFromSlot belongs to the separate quick-action branch.]
	widget.clicked.connect(func(_id: int, _card: Dictionary):
		var screen := get_parent()
		while screen != null:
			if screen.has_method("show_card_detail"):
				screen.show_card_detail(card_uid)
				return
			screen = screen.get_parent())
	container.add_child(widget)


func _begin_slot_drag(data: Dictionary, widget: CardWidget) -> void:
	var slot := str(data.source_slot)
	var uid := int(data.card_uid)
	if not _can_edit_slot(slot) or int(_placed.get(slot, 0)) != uid:
		return
	# [SRC: CardController.OnBeginDrag 0x5294e0 -> ICardSlot.RemoveCard;
	# CardSlotController.RemoveCard 0x53c7b0 -> SetCard(null).]
	# Keep Godot's source alive for DRAG_END while rebuilding the empty slot.
	widget.reparent(self)
	_dragged_slot_widgets[uid] = widget
	_placed.erase(slot)
	var instance = _state.get_card_instance(uid)
	_state._unlink_slot_instance(instance)
	instance.zone = "drag"
	instance.rite_uid = 0
	instance.slot_key = ""
	data.detached_from_slot = true
	_after_placement_changed()


func _finish_slot_drag(data: Dictionary, _accepted: bool, widget: CardWidget) -> void:
	var uid := int(data.card_uid)
	var instance = _state.get_card_instance(uid)
	# Check actual ownership too: a GUI target may accept without transferring.
	# [SRC: OnEndDrag 0x52a570 AddCard -> BackToHandOrBag, never old slot.]
	if instance != null and instance.zone == "drag":
		var screen := get_parent()
		while screen != null and not screen.has_method("drop_card_to_hand"):
			screen = screen.get_parent()
		if screen != null:
			screen.drop_card_to_hand(data, screen._card_rail_view.get_local_mouse_position())
		else:
			_return_detached_card(uid)
	_dragged_slot_widgets.erase(uid)
	widget.queue_free()


func _return_detached_card(uid: int) -> void:
	var instance = _state.get_card_instance(uid)
	if instance == null or instance.zone != "drag":
		return
	if str(_state.card_data_for(uid, _db).get("type", "")) == "sudan":
		instance.zone = "sudan"
	else:
		_state.add_card_to_hand(uid)


func _exit_tree() -> void:
	# Closing/replacing the overlay during a drag must not orphan the UID.
	for uid in _dragged_slot_widgets:
		_return_detached_card(int(uid))


func _can_edit_slot(slot_key: String) -> bool:
	return not _resolution_pending and not _resolution_committed and preload("res://ui/rite_slot_access.gd").can_edit(_state, _db, _rite_uid, slot_key)


func can_release_slot_card(card_uid: int, rite_uid: int, slot_key: String) -> bool:
	return rite_uid != _rite_uid or (_can_edit_slot(slot_key) and int(_placed.get(slot_key, 0)) == card_uid)


func refresh_departed_slot_card(rite_uid: int) -> void:
	if rite_uid != _rite_uid:
		return
	# Stacking/equipping already unlinked the source. Do not return it to hand.
	_load_placements_from_instance()
	_after_placement_changed()


func _rite_state_from_placements() -> Dictionary:
	var rite_state := {}
	for slot_key in _placed:
		var card = _state.card_data_for(int(_placed[slot_key]), _db)
		rite_state[str(slot_key)] = int(card.get("id", 0))
	return rite_state


func _clear_slot_card(btn: Button) -> void:
	for child in btn.get_children():
		if child is CardWidget or child.name == "Container":
			btn.remove_child(child)
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
	var cond: Variant = slot_def.get("condition", {})
	return str(SourceJSON.member(cond, "type", "")) == "sudan"


# [SRC: RitePanelShowController.TryUpdateCard 0x598140 temporarily nulls
# only the destination entry, evaluates CanPutCard, then restores it.]
func _try_update_card(slot_key: String, card: Dictionary) -> bool:
	var previous = _placed.get(slot_key)
	_placed.erase(slot_key)
	var ctx := _slot_condition_context(_rite.get("cards_slot", {}).get(slot_key, {}), card, false)
	if previous != null:
		_placed[slot_key] = previous
	return bool(ctx.get("accepted", false))


func _slot_accepts_card(slot_def: Dictionary, card: Dictionary) -> bool:
	return bool(_slot_condition_context(slot_def, card, true).get("accepted", false))


func _slot_condition_context(slot_def: Dictionary, card: Dictionary, first_drop: bool) -> Dictionary:
	if slot_def.is_empty():
		return {"accepted": false}
	var cond: Variant = slot_def.get("condition", {})
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
		"acting_card_uid": int(card.get("instance_uid", 0)),
		"is_first_drop": first_drop,
		"acting_card_id": int(card.get("id", 0)),
		"acting_card_only": true,
		"slot_entries": _slot_entries_from_placements(),
		"use_slot_snapshot": true,
	}
	ctx["accepted"] = ConditionEval.can_put_card(cond, ctx)
	return ctx


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
	# Deferred effects mutate cards after ResultExec returned, so they are a
	# second source of CardOpContext rows for the same settlement.
	# [SRC: RiteResultPanelController.c @ DoCachedOp (0x5a1a60) plays the cached
	#       operations after the immediate ones.]
	var recording: bool = _state != null and _state.has_method("begin_result_op_log")
	if recording:
		_state.begin_result_op_log()
	DeferredEffects.apply(deferred, _state, _db, _rng)
	if recording:
		var ops: Array = _state.drain_result_op_log()
		if not ops.is_empty():
			var existing: Array = deferred.get("card_ops", [])
			existing.append_array(ops)
			deferred["card_ops"] = existing


func _gold_type_for_reactive_spend() -> String:
	if _last_result != null and not _last_result.dice_types_seen.is_empty():
		return str(_last_result.dice_types_seen[0])
	return "r1"


# Compatibility sink for the host; the source rite has no debug toast surface.
func set_log(_text: String) -> void:
	pass


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
	return SourceJSON.parse_string(FileAccess.get_file_as_string(path))


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
	var cond: Variant = slot_def.get("condition", {})
	if cond.is_empty():
		return "任意"
	return " / ".join(SourceJSON.entries(cond).map(func(entry): return entry.keys()[0]))


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
