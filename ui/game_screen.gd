## Main in-game desk screen.
## The tabletop SituationDesk is the single play surface; the shared rail,
## queue surfaces, and day controls remain persistent.
extends Control

## Presentation contract:
## - The desk is the only surface; modals pause it via set_world_scene_blocker.

signal open_rite(rite_id: int)
signal open_rite_instance(rite_uid: int)
signal advance_pressed()
signal back_to_prev_pressed()
signal menu_pressed()
signal game_over_requested()
signal story_requested(quest_id: int)

const MapControllerScript = preload("res://ui/map_controller.gd")
const CardInfoViewScript = preload("res://ui/card_info_view.gd")
const MainHelpViewScript = preload("res://ui/main_help.gd")
const ChangeNameViewScript = preload("res://ui/change_name_view.gd")
const CachedEventsViewScript = preload("res://ui/cached_events_view.gd")
const EventPromptViewScript = preload("res://ui/event_prompt_view.gd")
const StoryNotifyControllerScript = preload("res://ui/story_notify_controller.gd")
const TextureCache = preload("res://ui/source_texture_cache.gd")

class HandRailDrop:
	extends Control

	var owner_screen: Control

	func _has_point(point: Vector2) -> bool:
		# The full-width Godot rail must not intercept the source IThink target.
		# [SRC: GameScene MainUI/IThink + Hand; TipsHolder on IThink.]
		if owner_screen != null and owner_screen._desk_content != null:
			var think: Control = owner_screen._desk_content._think_drop_zone
			if is_instance_valid(think) and think.is_visible_in_tree():
				if think.get_global_rect().has_point(get_global_transform() * point):
					return false
		return Rect2(Vector2.ZERO, size).has_point(point)

	func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
		var accepted: bool = (
			owner_screen != null
			and owner_screen.has_method("can_drop_card_to_hand")
			and bool(owner_screen.can_drop_card_to_hand(data))
		)
		if accepted and owner_screen.has_method("_preview_hand_drop"):
			owner_screen.call("_preview_hand_drop", data, at_position)
		return accepted

	func _drop_data(at_position: Vector2, data: Variant) -> void:
		if owner_screen != null and owner_screen.has_method("drop_card_to_hand"):
			owner_screen.drop_card_to_hand(data, at_position)



const MOCKUP_SIZE := Vector2(1280, 720)
## HandCardsController authoring on GameScene/MainUI/Hand.
const SourceHandLayout = preload("res://ui/source_hand_layout.gd")
var _hand_normalized_range := 0.0

const HAND_SPACE := 10.0
const HAND_MIN_VISIBLE_WIDTH := 20.0
const HAND_MASK_HEIGHT := 470.0
const HAND_CONTENT_OFFSET := Vector2(516.7349, 36.0)
const HAND_CONTENT_SIZE := Vector2(2723.264, 430.0)
# Original MainUI canvas: 3840x2160 (GameScene.unity CanvasScaler Expand).
# Desktop chrome anchors below are authored values from docs/ui_layout/GameScene.
const DESIGN_SPACE := Vector2(3840, 2160)
# Full-rect overlays built by not-yet-migrated scripts (rite view/selector)
# still lay out in the 1280x800 legacy space, scaled to fill design height.
const LEGACY_OVERLAY_DESIGN := Vector2(1280, 800)
# Rendering budget. Game owns the global menu above this entire screen.
const SCENE_CONTENT_Z_MAX := 99
const OVERLAY_LAYER_Z := 100
const PERSISTENT_CONTROL_Z := 200
const BLOCKING_PROMPT_Z := 400

var _state
var _db
var _rng

var _log_label: Label
var _background: ColorRect
var _begin_guide_bar: BeginGuideBar
var _menu_button: Button
var _deadline_strip: PanelContainer
var _deadline_number: HBoxContainer
var _deadline_track: HBoxContainer
var _deadline_title: Label
var _deadline_pulse: Curve
var _deadline_pulse_time := 0.0
var _sudan_box: Control
var _prestige_strip: Control
var _prestige_slots: Array = []
var _next_day_transition: Control
var _desk_map: PanelContainer
var _desk_content: Control
var _overlay_layer: Control
var _source_overlay_layer: Control
var _hand_bg_sprite: TextureRect
var _bag_tabs: HandBagTabs
var _card_rail_view: Control
var _rail_padding: MarginContainer
var _card_items: Control
var _hand_sticky := false
var _hand_sticky_start := Vector2.ZERO
var _hand_idle_clock_seconds := 0.0
var _hand_content_overflows := false
var _hand_drop_preview_index := -1
var _pending_hand_drop_origins: Dictionary = {}
var _pending_hand_drop_poses: Dictionary = {}
var _known_rail_card_uids: Dictionary = {}
var _right_actions: Control
var _advance_button: Button
var _back_to_prev_button: Button
var _sort_button: Button
var _main_help_view = null
var _change_name_view = null
var _main_help_button: Button
var _card_info_view = null
var _cached_events_view = null
var _cached_event_mask: Button
var _story_notify = null
var _tips = null  # SourceTips panel (Tips.prefab + SlotTipsController placement)
var _card_detail_card_id := 0
var _card_detail_card_uid := 0
var _event_overlay: Control
var _shown_event_operation: Dictionary = {}
var _event_panel = null  # PromptNew OptionBG (plain Control after batch AL)
var _rename_input: LineEdit
var _sleep_waiting := false
var _presentation_frozen := false
var _presentation_blockers: Dictionary = {}
var _persistent_action_locks: Dictionary = {}
var _underlying_presentation_pauses: Dictionary = {}


func setup(state, db, rng) -> void:
	_state = state
	_db = db
	_rng = rng


func _ready() -> void:
	theme = FaustTheme.get_theme()
	# Runtime-created Controls start at size zero. Reset offsets as well as
	# anchors; otherwise child overlays inherit an empty rect even though
	# the desktop's explicit layout falls back to the viewport size.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	resized.connect(_apply_layout)
	call_deferred("_apply_layout")
	refresh()
	# TipsHolder components are authored onto source GameObjects, so they exist
	# as soon as the screen is built. Attach once; the panel itself is reused.
	_attach_source_tips()



## Attach the source's TipsHolder inventory to the clone Controls that stand in
## for the same GameObjects. Ids and NeedWidth are the scene's own values from
## docs/ui_layout/SourceTips.md; a holder the scene does not author is not
## invented here.
##
## [SRC: GameScene.unity TipsHolder components (30 holders / 16 ids, scanned);
##       TipsHolder.c @ GetTipText 0x5c4400 resolves TipsId through
##       Datapool.Translate, and OnPointerEnter 0x5c53a0 spawns Tips.prefab.]
func _attach_source_tips() -> void:
	if _tips == null or _db == null:
		return
	# MainUI/Next Round/PrevRound — return_last_round stamp (NeedWidth 1000).
	if _back_to_prev_button != null:
		_tips.attach(_db, _back_to_prev_button, "BACK_TO_LAST_ROUND_BEGIN_TIPS", "", 1000.0)
	# MainUI/Next Round/Sort — hand_sort stamp (TipsHolder NeedWidth 1000).
	if _sort_button != null:
		_tips.attach(_db, _sort_button, "SORT_HAND_CARD_TIPS", "", 1000.0)
	# MainUI/RoundNumber BG — the deadline strip itself.
	if _deadline_strip != null:
		_tips.attach(_db, _deadline_strip, "EXECUTION_DAY_TIPS")
	# MainUI/BagBtnGroup/BagGroup/{0..3}.
	if _bag_tabs != null:
		for index in range(mini(4, _bag_tabs.buttons.size())):
			_tips.attach(_db, _bag_tabs.buttons[index], "BAG_POS_%d_TIPS" % (index + 1))
	# MainUI/IThink — the thought drop zone.
	_tips.attach(_db, _find_node_by_name(self, "ThinkDropZone") as Control, "ITHINK_TIPS")


## The sort-all action behind MainUI/Next Round/Sort.
##
## `GameController.HandCardSort` first collapses each bag page's history with
## `HandCardAutoClassify`, then walks every bag index and re-runs
## `HandCardArrange` for it. The clone carries one bag page, so the equivalent is
## the existing `sort_current_hand_by_condition` with an always-true validator:
## the comparator then falls through to bagpos → card id → uid, which is exactly
## the no-match ordering, and every card gets a fresh 1..N bagpos.
##
## [SRC: GameController.c @ HandCardSort (RVA 0x5523e0): HandCardAutoClassify
##       then per-page HandCardArrange; @ HandCardSortByCondition (RVA 0x5515a0).]
func sort_hand_pressed() -> void:
	if _state == null or _db == null:
		return
	_state.sort_current_hand_by_condition(_db, func(_card): return true)
	_layout_hand_cards()
	refresh()


func _process(delta: float) -> void:
	if (
		delta <= 0.0
		or _presentation_frozen
		or not _underlying_presentation_pauses.is_empty()
	):
		return
	_hand_idle_clock_seconds += delta
	_advance_hand_edge_scroll()
	if _deadline_track != null and _deadline_strip.visible:
		if int(_deadline_track.get_meta("remaining", 7)) < 2:
			_deadline_pulse_time = fmod(_deadline_pulse_time + delta, 1.0)
			var pulse := _deadline_pulse.sample(_deadline_pulse_time)
			for control in [_deadline_title, _deadline_number]:
				control.pivot_offset = control.size * 0.5
				control.scale = Vector2.ONE * pulse


func hand_idle_time_seconds() -> float:
	return _hand_idle_clock_seconds


func _build_ui() -> void:
	_background = ColorRect.new()
	_background.name = "ScreenBackground"
	_background.color = Color("#17120e")
	add_child(_background)
	# The screen uses an explicit scaled layout; keep the background on the
	# same top-left coordinate system so resizing it does not fight anchors.
	_background.set_anchors_preset(Control.PRESET_TOP_LEFT)

	# [SRC: docs/ui_layout/GameScene.md — RoundNumber BG top-right anchors (1,1)
	#       pivot (1,1) pos (-80,0) height 204, countdown_bg_new strip;
	#       children Left Space/RoundNumberTitle (translated) fs60/NumberSprite/
	#       RoundNumber "N/7" fs60/Right Space (horizontal layout)]
	_deadline_strip = PanelContainer.new()
	_deadline_strip.name = "RoundNumberBG"
	_deadline_strip.custom_minimum_size.y = 204
	_deadline_strip.z_index = PERSISTENT_CONTROL_Z
	# Sprite/countdown_bg_new.asset has explicit slice borders, not 40% margins.
	var deadline_style := StyleBoxTexture.new()
	deadline_style.texture = load("res://assets/original/ui/countdown_bg_new.png")
	deadline_style.texture_margin_left = 227
	deadline_style.texture_margin_right = 245
	deadline_style.texture_margin_top = 52
	deadline_style.texture_margin_bottom = 71
	deadline_style.content_margin_left = 150
	deadline_style.content_margin_right = 180
	deadline_style.content_margin_top = 37
	deadline_style.content_margin_bottom = 67
	_deadline_strip.add_theme_stylebox_override("panel", deadline_style)
	_deadline_strip.minimum_size_changed.connect(_layout_deadline)
	add_child(_deadline_strip)
	var deadline_row := HBoxContainer.new()
	deadline_row.add_theme_constant_override("separation", 0)
	deadline_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_deadline_strip.add_child(deadline_row)
	var deadline_title := Label.new()
	var ui_text: Dictionary = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/ui.json"))
	deadline_title.text = str(ui_text.GAME_MAIN_HEAD_TITLE.zhCN)
	deadline_title.add_theme_font_size_override("font_size", 60)
	deadline_title.add_theme_color_override("font_color", Color.WHITE)
	deadline_title.custom_minimum_size.y = 100
	deadline_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preload("res://ui/source_text_style.gd").apply(deadline_title, "@EXECUTION_DAY_TITLE")
	_deadline_title = deadline_title
	deadline_row.add_child(deadline_title)
	# GameScene GO 87/101/225: title Bottom/Right Border/Left Border are inactive.
	_deadline_track = HBoxContainer.new()
	_deadline_track.name = "NumberSprite"
	_deadline_track.custom_minimum_size = Vector2(1115, 100)
	_deadline_track.add_theme_constant_override("separation", 0)
	_deadline_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deadline_row.add_child(_deadline_track)
	_deadline_number = preload("res://ui/source_number.gd").new()
	_deadline_number.glyph_height = 60.0
	_deadline_number.add_theme_constant_override("separation", 6)
	deadline_row.add_child(_deadline_number)
	# [SRC: Resources/anims/countdown/RedText.anim, one-second Hermite curve.]
	_deadline_pulse = Curve.new()
	_deadline_pulse.min_value = 0.9
	_deadline_pulse.max_value = 1.1
	for point in [Vector2(0, 1), Vector2(0.25, 0.95), Vector2(0.5, 1), Vector2(0.75, 1.05), Vector2(1, 1)]:
		var tangent := 0.2 if point.x == 0.5 else 0.0
		_deadline_pulse.add_point(point, tangent, tangent)

	# [SRC: GameScene Quit — checkbox_bg 80x82 top-right pivot (0.5,1) pos
	#       (-70,-30), child Image menu 49x43 centered]
	var quit_anchor := Control.new()
	quit_anchor.name = "QuitAnchor"
	quit_anchor.z_index = PERSISTENT_CONTROL_Z
	quit_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quit_anchor)
	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	# No TipsHolder in the source's Quit block, so the clone does not invent one.
	# Godot's own tooltip is not the source's tip surface; see
	# docs/ui_layout/SourceTips.md for the scene-wide holder inventory.
	_menu_button.flat = false
	_menu_button.custom_minimum_size = Vector2(80, 82)
	_menu_button.size = Vector2(80, 82)
	var quit_style := _nine_slice_style("res://assets/original/ui/checkbox_bg.png")
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		_menu_button.add_theme_stylebox_override(state_name, quit_style)
	if ResourceLoader.exists("res://assets/original/ui/menu.png"):
		var menu_icon := TextureRect.new()
		menu_icon.texture = load("res://assets/original/ui/menu.png") as Texture2D
		menu_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		menu_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		menu_icon.set_anchors_preset(Control.PRESET_CENTER)
		menu_icon.custom_minimum_size = Vector2(49, 43)
		menu_icon.size = Vector2(49, 43)
		menu_icon.position = Vector2(-24.5, -21.5)
		menu_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_menu_button.add_child(menu_icon)
	_menu_button.pressed.connect(func(): menu_pressed.emit())
	quit_anchor.add_child(_menu_button)

	# [SRC: GameScene MainHelpTrigger — help_button 88x91 top-right pivot
	# (0.5,1) pos (-70,-143.5); opens MainUI/MainHelp (main_help.gd).
	# Player.helpbtn_unshow 0=show, nonzero=hide (batch N close_* polarity).]
	var help_anchor := Control.new()
	help_anchor.name = "HelpAnchor"
	help_anchor.z_index = 50
	help_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(help_anchor)
	_main_help_button = Button.new()
	_main_help_button.name = "MainHelpTrigger"
	# The source's help trigger has no TipsHolder either; the MainHelp overlay it
	# opens is its own documentation surface.
	_main_help_button.flat = true
	_main_help_button.custom_minimum_size = Vector2(88, 91)
	_main_help_button.size = Vector2(88, 91)
	var help_style := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		_main_help_button.add_theme_stylebox_override(state_name, help_style)
	if ResourceLoader.exists("res://assets/original/ui/help_button.png"):
		var help_icon := TextureRect.new()
		help_icon.texture = load("res://assets/original/ui/help_button.png") as Texture2D
		help_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		help_icon.stretch_mode = TextureRect.STRETCH_SCALE
		help_icon.custom_minimum_size = Vector2(88, 91)
		help_icon.size = Vector2(88, 91)
		help_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_main_help_button.add_child(help_icon)
	_main_help_button.pressed.connect(_toggle_main_help)
	help_anchor.add_child(_main_help_button)

	# [SRC: GameScene SudanBox — box_open 455x954 anchors (0,1) pivot (0,1)
	#       pos (-47,20); child BoxTop 244x528 at center+(-85,43)]
	_sudan_box = Control.new()
	_sudan_box.name = "SudanBox"
	_sudan_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sudan_box.z_index = PERSISTENT_CONTROL_Z
	add_child(_sudan_box)
	var box_frame := _sprite_child("res://assets/original/ui/box_open.png", Vector2(455, 954))
	_sudan_box.add_child(box_frame)
	var box_top := _sprite_child("res://assets/original/ui/box_top.png", Vector2(244, 528))
	box_top.set_anchors_preset(Control.PRESET_CENTER)
	box_top.position = Vector2(455 * 0.5 - 85 - 122, 954 * 0.5 + 43 - 264)
	_sudan_box.add_child(box_top)

	_build_prestige_strip()

	_build_cached_events()
	_build_story_notify()

	_desk_map = _panel("DeskMap")
	_desk_map.add_theme_stylebox_override("panel", _scene_frame_style())
	add_child(_desk_map)
	_desk_content = MapControllerScript.new()
	_desk_content.name = "SituationDesk"
	_desk_content.setup(_state, _db, _rng)
	_desk_content.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_desk_content.open_rite_instance.connect(_emit_open_rite_instance)
	add_child(_desk_content)

	_log_label = Label.new()
	_log_label.name = "EventToast"
	_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_log_label.add_theme_font_size_override("font_size", 18)
	_log_label.add_theme_color_override("font_color", Color("#fff1c2"))
	_log_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.025, 0.06, 0.90))
	_log_label.add_theme_constant_override("shadow_offset_x", 1)
	_log_label.add_theme_constant_override("shadow_offset_y", 2)
	_desk_content.add_child(_log_label)
	# Control mouse picking follows tree order, independently of z_index.
	move_child(quit_anchor, get_child_count() - 1)
	move_child(help_anchor, get_child_count() - 1)

	# Godot Control input follows sibling order, not z_index. Keep the guide
	# above the full-screen desk for input, but below modal overlay children.
	_begin_guide_bar = BeginGuideBar.new()
	_begin_guide_bar.name = "BeginGuideBarRoot"
	_begin_guide_bar.setup(_state)
	_begin_guide_bar.z_index = PERSISTENT_CONTROL_Z + 2
	add_child(_begin_guide_bar)

	_overlay_layer = Control.new()
	_overlay_layer.name = "OverlayLayer"
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.z_index = OVERLAY_LAYER_Z
	add_child(_overlay_layer)

	# New overlays migrate here one at a time after their original RectTransform
	# hierarchy has been re-emitted in the 3840x2160 GameScene design space.
	# Keep OverlayLayer intact for the remaining 1280x800 compatibility views.
	_source_overlay_layer = Control.new()
	_source_overlay_layer.name = "SourceOverlayLayer"
	_source_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_source_overlay_layer.z_index = OVERLAY_LAYER_Z + 1
	add_child(_source_overlay_layer)

	# [SRC: Resources/prefab/Tips.prefab + SlotTipsController.SetPositionInternal
	#       0x5ac340. The source spawns this panel per hover from TipsHolder; the
	#       clone keeps one instance above the desktop chrome but below modal
	#       prompts, exactly like the source's tip canvas layer.]
	_tips = preload("res://ui/tips_view.gd").new()
	add_child(_tips)
	# [SRC: GameScene MainUI/Hand BG, hand_bg, bottom-stretched 356.]
	_hand_bg_sprite = _sprite_child("res://assets/original/ui/hand_bg.png", Vector2(3840, 356))
	_hand_bg_sprite.name = "HandBG"
	# Background belongs below the interactive desk and modal overlays.
	_hand_bg_sprite.z_index = 7
	add_child(_hand_bg_sprite)
	_bag_tabs = HandBagTabs.new()
	_bag_tabs.name = "BagBtnGroup"
	_bag_tabs.z_index = 21
	_bag_tabs.page_selected.connect(_change_hand_bag)
	add_child(_bag_tabs)
	_card_rail_view = HandRailDrop.new()
	_card_rail_view.name = "CardRail"
	_card_rail_view.z_index = PERSISTENT_CONTROL_Z
	(_card_rail_view as HandRailDrop).owner_screen = self
	# Original Hand Mask is inactive in GameScene. The HandCardsController
	# compresses cards itself, so it must not clip CardController's raised root.
	_card_rail_view.clip_contents = false
	_card_rail_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_card_rail_view.mouse_exited.connect(_clear_hand_drop_preview)
	add_child(_card_rail_view)
	_rail_padding = MarginContainer.new()
	_rail_padding.name = "CardRailPadding"
	_card_rail_view.add_child(_rail_padding)
	# GameScene/MainUI/Hand has stretch-x anchors but resolves to this concrete
	# rect on the 3840x2160 canvas. Keep it as a source-space child, not a
	# full-width clone container.
	_rail_padding.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_card_items = Control.new()
	_card_items.name = "CardRailItems"
	_card_items.mouse_filter = Control.MOUSE_FILTER_PASS
	_card_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_items.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Hidden Controls are excluded from Container layout.  Stay layout-visible
	# and use alpha to suppress the unpositioned first frame instead.
	_card_items.modulate = Color(1, 1, 1, 0)
	_card_items.resized.connect(_layout_hand_cards)
	_rail_padding.add_child(_card_items)

	_right_actions = Control.new()
	_right_actions.name = "RightActions"
	_right_actions.z_index = PERSISTENT_CONTROL_Z
	add_child(_right_actions)

	_advance_button = Button.new()
	_advance_button.name = "AdvanceDayButton"
	# [SRC: GameScene Next Round — clock_bg 596x634 anchors (1,0) pivot (1,0);
	#       Image next_day_0 305x306 at center+(62,-41); Sort hand_sort 93x93
	#       at (1,300); PrevRound return_last_round 158x137 at
	#       center+(-206.1,-207.2); Text (TMP) "下一天" fs100 322x174 at
	#       bottom-right (-240.5,275)]
	_advance_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists("res://assets/original/ui/clock_bg.png"):
		var watch := TextureRect.new()
		watch.name = "NextDayWatch"
		watch.texture = preload("res://assets/original/ui/clock_bg.png")
		watch.set_anchors_preset(Control.PRESET_FULL_RECT)
		watch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		watch.stretch_mode = TextureRect.STRETCH_SCALE
		watch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_advance_button.add_child(watch)
	if ResourceLoader.exists("res://assets/original/ui/next_day_0.png"):
		var stamp := TextureRect.new()
		stamp.name = "NextDayStamp"
		stamp.texture = load("res://assets/original/ui/next_day_0.png") as Texture2D
		stamp.size = Vector2(305, 306)
		stamp.position = Vector2(596 * 0.5 + 62 - 305 * 0.5, 634 * 0.5 + 41 - 306 * 0.5)
		stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp.stretch_mode = TextureRect.STRETCH_SCALE
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_advance_button.add_child(stamp)
	# [SRC: GameScene.unity rect 7637/7690/7633/7659, Image 11518;
	# HoverImageSwitch.c Awake 0x42c640 / OnPointerEnter 0x42c680;
	# dump.cs HoverImageSwitch NormalImage@0x20 / HoverImage@0x28.]
	# Text center is bottom-right + (-240.5, -275) in Godot coordinates.
	# This is independent of Image/next_day_0, which is the compass dial.
	var text_hit := Button.new()
	text_hit.name = "NextDayTextButton"
	text_hit.position = Vector2(355.5, 359) - Vector2(352, 192) * 0.95 * 0.5
	text_hit.size = Vector2(352, 192) * 0.95
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		text_hit.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	_advance_button.add_child(text_hit)
	var normal_text := TextureRect.new()
	normal_text.name = "Normal"
	normal_text.texture = preload("res://assets/original/ui/main/next_day.png")
	normal_text.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	normal_text.stretch_mode = TextureRect.STRETCH_SCALE
	normal_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	normal_text.size = Vector2(512, 512) * 0.95
	normal_text.position = (text_hit.size - normal_text.size) * 0.5
	text_hit.add_child(normal_text)
	var hover_text := normal_text.duplicate() as TextureRect
	hover_text.name = "Hover"
	hover_text.texture = preload("res://assets/original/ui/main/next_day_hover.png")
	hover_text.visible = false
	text_hit.add_child(hover_text)
	text_hit.mouse_entered.connect(func():
		normal_text.visible = false
		hover_text.visible = true
	)
	text_hit.mouse_exited.connect(func():
		normal_text.visible = true
		hover_text.visible = false
	)
	text_hit.pressed.connect(func():
		if not _advance_button.disabled:
			advance_pressed.emit()
	)
	var watch_style := _round_button_style()
	_advance_button.add_theme_stylebox_override("normal", watch_style if not ResourceLoader.exists("res://assets/original/ui/clock_bg.png") else StyleBoxEmpty.new())
	_advance_button.add_theme_stylebox_override("hover", _round_button_style(Color("#efc46e")) if not ResourceLoader.exists("res://assets/original/ui/clock_bg.png") else StyleBoxEmpty.new())
	_advance_button.add_theme_stylebox_override("pressed", _round_button_style(Color("#fff1bc")) if not ResourceLoader.exists("res://assets/original/ui/clock_bg.png") else StyleBoxEmpty.new())
	# Disabled is a distinct theme state. Without this explicit style Godot falls
	# back to a rectangular default, making the paused primary action look
	# malformed even though its layout rectangle has not changed.
	_advance_button.add_theme_stylebox_override("disabled", _round_button_style(Color(0.82, 0.84, 0.88, 0.24)) if not ResourceLoader.exists("res://assets/original/ui/clock_bg.png") else StyleBoxEmpty.new())
	_advance_button.pressed.connect(func():
		# The plate remains drawn during the source transition, but is not
		# an alternate action while GO45 (the next-day text) is hidden.
		if text_hit.is_visible_in_tree() and not _advance_button.disabled:
			advance_pressed.emit()
	)
	_right_actions.add_child(_advance_button)
	_back_to_prev_button = _icon_button("回退")
	_back_to_prev_button.name = "BackToPrevButton"
	# Original return-to-previous-round stamp.
	# [SRC: GameScene.unity Next Round/PrevRound -> return_last_round;
	#       Texture2D/return_last_round.png 160x140]
	if ResourceLoader.exists("res://assets/original/ui/return_last_round.png"):
		var back_icon := TextureRect.new()
		back_icon.texture = load("res://assets/original/ui/return_last_round.png") as Texture2D
		back_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		back_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_back_to_prev_button.text = ""
		_back_to_prev_button.add_child(back_icon)
	_back_to_prev_button.pressed.connect(func(): back_to_prev_pressed.emit())
	_right_actions.add_child(_back_to_prev_button)

	# [SRC: GameScene MainUI/Next Round/Sort — 93x93 at anchors (0,0) pivot (0,0)
	#       pos (1,300); Image hand_sort 93x93; UnityEvent OnClick ->
	#       GameController.HandCardSort 0x5523e0. TipsHolder NeedWidth 1000.]
	_sort_button = Button.new()
	_sort_button.name = "SortHandButton"
	_sort_button.flat = true
	var sort_style := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		_sort_button.add_theme_stylebox_override(state_name, sort_style)
	if ResourceLoader.exists("res://assets/original/ui/hand_sort.png"):
		var sort_icon := TextureRect.new()
		sort_icon.name = "hand_sort"
		sort_icon.texture = load("res://assets/original/ui/hand_sort.png") as Texture2D
		sort_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sort_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sort_icon.stretch_mode = TextureRect.STRETCH_SCALE
		sort_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sort_button.add_child(sort_icon)
	_sort_button.pressed.connect(sort_hand_pressed)
	_right_actions.add_child(_sort_button)
	# Input is owned by the Button children, matching Unity's Button.OnClick.
	# Do not catch the parent rect and synthesize a second press.
	# Match visual chrome order for Godot mouse picking (z_index alone does
	# not change Control hit testing). Keep modal hosts above these targets.
	for chrome in [_deadline_strip, _bag_tabs]:
		move_child(chrome, get_child_count() - 1)
	for overlay in [_overlay_layer, _source_overlay_layer]:
		move_child(overlay, get_child_count() - 1)
	# Unity's cached-event mask intercepts Next Round (GO47 OnClick ->
	# NoticeCachedEvent). Godot mouse picking follows sibling order, not z.
	move_child(_cached_event_mask, get_child_count() - 1)
	# Source buttons are icon images, not the 516px text-button strip. That
	# strip's 316px content margins forced both controls wider than their rect.
	for icon_button in [_back_to_prev_button, _sort_button]:
		for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			icon_button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
		for child in icon_button.get_children():
			if child is TextureRect:
				child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## [SRC: GameScene MainUI/CachedEvents (rect 7782, custom layout group
## 11735) + "Next Round Mask For Cached Event" (GameObject 47 / rect 7639)
## + GameController.c OnCachedListChanged (0x553b70).]
func _build_cached_events() -> void:
	_cached_events_view = CachedEventsViewScript.new()
	_cached_events_view.name = "CachedEvents"
	_cached_events_view.z_index = PERSISTENT_CONTROL_Z
	_cached_events_view.cached_event_clicked.connect(_on_cached_event_clicked)
	add_child(_cached_events_view)
	# [SRC: rect 7639 — anchors (1,0)-(1,0), pos (64.87,-187.82), pivot (1,0),
	# 596x634; Image colour alpha 1/255 alpha-hit-test = invisible click
	# catcher over the next-day zone; scene UnityEvent OnClick ->
	# GameController.NoticeCachedEvent (shake the tray).]
	_cached_event_mask = Button.new()
	_cached_event_mask.name = "CachedEventMask"
	_cached_event_mask.flat = true
	# The mask GameObject carries no TipsHolder; its discoverability comes from
	# the tray it shakes, not from an invented clone-only tooltip.
	var mask_style := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		_cached_event_mask.add_theme_stylebox_override(state_name, mask_style)
	_cached_event_mask.z_index = PERSISTENT_CONTROL_Z + 1
	_cached_event_mask.visible = false
	_cached_event_mask.pressed.connect(func(): _cached_events_view.notice())
	add_child(_cached_event_mask)


func _build_story_notify() -> void:
	_story_notify = StoryNotifyControllerScript.new()
	_story_notify.name = "StoryNotify"
	_story_notify.z_index = PERSISTENT_CONTROL_Z + 3
	_story_notify.setup(_state.global_state)
	_story_notify.story_requested.connect(func(quest_id: int): story_requested.emit(quest_id))
	add_child(_story_notify)


## [SRC: GameController.c OnCachedEventClicked (0x5538e0) — TryGetValue on
## Datapool.can_cached_event_settlements; a failed lookup removes the notice
## (PlayerExtensions.RemoveCacheEvent 0x38ecb0).  Corpus config declares zero
## cached_settlement instances, so the settlement branch (OperationMask
## @0x1C0 + OperationsExtensions.Start + completion callback 0x5728d0)
## stays registered ⬜ until a config instance exists.]
func _on_cached_event_clicked(event_id: int) -> void:
	var settlement: Array = _db.get_event(event_id).get("cached_settlement", [])
	if settlement.is_empty():
		_state.remove_cached_event(event_id)
	refresh()


func _apply_layout() -> void:
	if _menu_button == null:
		return
	var view_size := _effective_view_size()
	# Chrome anchors are authored 3840x2160 values from docs/ui_layout/GameScene;
	# they scale with the actual canvas instead of the old mockup ratio.
	var k := Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)

	_set_rect(_background, Rect2(Vector2.ZERO, view_size))
	# [SRC: GameScene MainUI/Prompt/BeginGuide/Default: its parent is the
	# full 3840x2160 canvas; Default itself owns the 1200x460 source rect.]
	if _begin_guide_bar != null:
		_begin_guide_bar.apply_source_layout(view_size)
	# [SRC: RoundNumber BG top-right pos (-80,0) height 204 — width wraps text]
	if _deadline_strip != null:
		_layout_deadline()
	# [SRC: Quit checkbox_bg 80x82, pivot (0.5,1) pos (-70,-30) top-right]
	if _menu_button != null and _menu_button.get_parent() is Control:
		var quit_anchor: Control = _menu_button.get_parent()
		quit_anchor.scale = k
		quit_anchor.position = Vector2(view_size.x - 110 * k.x, 30 * k.y)
		quit_anchor.size = Vector2(80, 82)
	# [SRC: MainHelpTrigger pivot (0.5,1) pos (-70,-143.5) 88x91; x spans
	# 3726..3814 in the 3840 design space]
	if _main_help_button != null and _main_help_button.get_parent() is Control:
		var help_anchor: Control = _main_help_button.get_parent()
		help_anchor.scale = k
		help_anchor.position = Vector2(3726 * k.x, 143.5 * k.y)
		help_anchor.size = Vector2(88, 91)
	# [SRC: SudanBox box_open 455x954 anchors (0,1) pivot (0,1) pos (-47,20)]
	if _sudan_box != null:
		_sudan_box.scale = k
		_sudan_box.position = Vector2(-47 * k.x, 20 * k.y)
		_sudan_box.size = Vector2(455, 954)
	if _prestige_strip != null:
		_prestige_strip.scale = k
		# [SRC: Prestige anchors (0.3,1) pivot (0,1) 1000x264]
		_prestige_strip.position = Vector2(view_size.x * 0.3, 0)
		_prestige_strip.size = Vector2(1000, 264)
	# [SRC: MainUI/CachedEvents tray (0,1352,3840,128) + mask
	# (3308.87,1713.82,596,634), both design-space rects]
	if _cached_events_view != null:
		_cached_events_view.scale = k
		_cached_events_view.position = Vector2(0, 1352.0 * k.y)
		_cached_events_view.size = Vector2(3840, 128)
	if _cached_event_mask != null:
		_cached_event_mask.scale = k
		_cached_event_mask.position = Vector2(3308.87 * k.x, 1713.82 * k.y)
		_cached_event_mask.size = Vector2(596, 634)
	if _story_notify != null:
		_story_notify.apply_source_layout(view_size)
	# Tips.prefab is authored on the same 3840x2160 canvas, and its placement
	# math consumes screen-space fractions, so it only needs the canvas scale.
	if _tips != null:
		_tips.apply_source_layout(view_size)
	# The painted board is the whole desktop behind every persistent control.
	_set_rect(_desk_map, Rect2(Vector2.ZERO, view_size))
	_set_rect(_desk_content, Rect2(Vector2.ZERO, view_size))
	# [SRC: Next Round watch cluster anchors (1,0) pivot (1,0) 596x634;
	#       下一天 text 322x174 centered at bottom-right + (-240.5,275)]
	_right_actions.scale = k
	_right_actions.position = Vector2(view_size.x - 596 * k.x, view_size.y - 634 * k.y)
	_right_actions.size = Vector2(596, 634)
	if _back_to_prev_button != null:
		# [SRC: Next Round/PrevRound 158x137 at center+(-206.1,-207.2)]
		_set_rect(_back_to_prev_button, Rect2(Vector2(12.9, 455.7), Vector2(158, 137)))
	if _sort_button != null:
		# [SRC: Next Round/Sort anchors (0,0) pivot (0,0) pos (1,300) 93x93.
		#       Top-left = (1, 634-300-93) = (1,241); the source anchors it to the
		#       Bottom-Left corner, which is the same box.]
		_set_rect(_sort_button, Rect2(Vector2(1, 241), Vector2(93, 93)))
	var legacy_k := view_size.y / LEGACY_OVERLAY_DESIGN.y
	# Rite views/selector are still authored in the 1280x800 legacy space.
	_overlay_layer.scale = Vector2(legacy_k, legacy_k)
	_overlay_layer.position = Vector2((view_size.x - LEGACY_OVERLAY_DESIGN.x * legacy_k) * 0.5, 0)
	_overlay_layer.size = LEGACY_OVERLAY_DESIGN
	if _source_overlay_layer != null:
		_source_overlay_layer.position = Vector2.ZERO
		_source_overlay_layer.scale = Vector2.ONE
		_source_overlay_layer.size = view_size
	# [SRC: Hand BG hand_bg 4096x356 anchors (0,0)-(1,0) bottom stretched]
	if _bag_tabs != null:
		_bag_tabs.scale = k
		_bag_tabs.position = Vector2(420 * k.x, view_size.y - 340 * k.y)
	if _hand_bg_sprite != null:
		_hand_bg_sprite.scale = k
		_hand_bg_sprite.position = Vector2(0, view_size.y - 356 * k.y)
		_hand_bg_sprite.size = Vector2(view_size.x / k.x, 356)
	_set_rect(
		_card_rail_view,
		Rect2(
			Vector2(0, view_size.y - HAND_MASK_HEIGHT * k.y),
			Vector2(view_size.x, HAND_MASK_HEIGHT * k.y)
		)
	)
	_set_rect(
		_rail_padding,
		Rect2(HAND_CONTENT_OFFSET * k, HAND_CONTENT_SIZE * k)
	)
	# CardNew/SudanCard use their prefab RectTransforms directly. There is no
	# legacy mockup scale between the card root and GameScene/MainUI/Hand.
	if _card_items != null:
		_card_items.scale = Vector2.ONE
		_card_items.position = Vector2.ZERO
	_card_items.custom_minimum_size = Vector2.ZERO
	call_deferred("_layout_hand_cards")
	_layout_situation_desk(k.y)
	_layout_event_prompt(legacy_k, view_size)


## [SRC: GameScene Prestige — 1000x264 at top 30% width; bg line 1020x157
##       top-left; slots 7100001..7100006 prestige_bg 231x252 with the
##       authored anchor/pivot mix ((0,1)/(0,0) + pivot (0.52,0.94)); the
##       Godot rects below fold that pivot into the top-left origin.]
func _build_prestige_strip() -> void:
	_prestige_strip = Control.new()
	_prestige_strip.name = "Prestige"
	_prestige_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prestige_strip.z_index = PERSISTENT_CONTROL_Z
	add_child(_prestige_strip)
	var line_tex := _sprite_child("res://assets/original/ui/line.png", Vector2(1020, 157))
	line_tex.position = Vector2(0, 0)
	_prestige_strip.add_child(line_tex)
	var slot_rects := [
		Rect2(-80.12, -8.62, 231, 252),
		Rect2(103.88, -5.02, 231, 252),
		Rect2(290.98, 22.88, 231, 252),
		Rect2(473.28, -4.52, 231, 252),
		Rect2(606.08, -9.32, 231, 252),
		Rect2(751.88, 43.88, 231, 252),
	]
	for i in range(slot_rects.size()):
		var slot := Control.new()
		slot.name = "PrestigeSlot710000%d" % (i + 1)
		slot.position = slot_rects[i].position
		slot.size = slot_rects[i].size
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := _sprite_child("res://assets/original/ui/prestige_bg.png", Vector2(231, 252))
		icon.visible = i != 5
		slot.add_child(icon)
		# [SRC: Prestige/710000N/Icon — 710000N art 231x242 at (0,-3.77)]
		var medal := _sprite_child(
			"res://assets/original/ui/710000%d.png" % (i + 1),
			Vector2(160, 236) if i == 5 else Vector2(231, 242)
		)
		medal.set_anchors_preset(Control.PRESET_CENTER)
		medal.position = Vector2(0, -3.77) - medal.size * 0.5
		slot.add_child(medal)
		var count_bg := _sprite_child("res://assets/original/ui/checkbox_bg.png", Vector2(52.5, 54.6))
		count_bg.position = Vector2(89.25, 196.8)
		slot.add_child(count_bg)
		var value = preload("res://ui/source_number.gd").new()
		value.name = "Value"
		value.text = "0"
		value.position = Vector2(95.5, 199.1)
		value.size = Vector2(40, 50)
		value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(value)
		_prestige_slots.append(slot)
		_prestige_strip.add_child(slot)


func _layout_deadline() -> void:
	var view_size := size if size.x > 0 and size.y > 0 else get_viewport_rect().size
	var k := view_size / Vector2(3840, 2160)
	_deadline_strip.scale = k
	_deadline_strip.size = Vector2(_deadline_strip.get_combined_minimum_size().x, 204)
	_deadline_strip.position = Vector2(view_size.x - (80 + _deadline_strip.size.x) * k.x, 0)


## UpdateSudanLife 0x55aeb0: show remaining life of the oldest Sudan card.
func _update_deadline_strip() -> void:
	if _deadline_strip == null or _state == null:
		return
	var hidden := bool(_state.get("deadline_unshow"))
	var oldest = null
	var max_life := -1
	# Player.cards is split into hand and active_sudan_cards in this host.
	var candidates: Array = _state.hand.duplicate()
	for candidate in _state.active_sudan_cards:
		if candidate.card_uid not in candidates:
			candidates.append(candidate.card_uid)
	for rite_uid in _state.rite_instances:
		candidates.append_array(_state.rite_slot_card_uids(rite_uid))
	for uid in candidates:
		var instance = _state.get_card_instance(uid)
		# Selector "sudan" is CardNode.type == "sudan", not a tag key.
		# [SRC: RuntimeOperationFilter.matches_card_data; OperationFilter.c IsMatch]
		var definition: Dictionary = _db.get_card(instance.card_id) if (instance != null and _db != null) else {}
		if instance != null and str(definition.get("type", "")) == "sudan" and instance.life > max_life:
			max_life = instance.life
			oldest = instance
	if hidden or oldest == null:
		_deadline_strip.visible = false
		return
	_deadline_strip.visible = true
	var card: Dictionary = _db.get_card(oldest.card_id) if _db != null else {}
	var lifetime := int(card.get("card_vanishing", 7))
	var remaining := lifetime - max_life
	if remaining >= 2:
		_deadline_pulse_time = 0.0
		_deadline_title.scale = Vector2.ONE
		_deadline_number.scale = Vector2.ONE
	_deadline_number.atlas_path = "res://assets/original/ui/number_6_red.png" if remaining < 3 else "res://assets/original/ui/number_6.png"
	_deadline_number.text = "%d/%d" % [maxi(0, remaining), _state.sudan_card_init_life]
	_deadline_title.modulate = Color.RED if remaining < 3 else Color.WHITE
	_update_deadline_track(remaining)
	_layout_deadline()


func _update_deadline_track(remaining: int) -> void:
	if _deadline_track.get_meta("remaining", -999) == remaining:
		return
	_deadline_track.set_meta("remaining", remaining)
	for child in _deadline_track.get_children():
		_deadline_track.remove_child(child)
		child.queue_free()
	var atlas := OriginalAtlas.load_atlas("res://assets/original/ui/countdown_pics.png")
	# Sprite index order comes from countdown_pics.asset, not atlas frame order.
	var names := ["人.png", "红色的人‘.png", "刀.png", "染血的刀.png", "进度条（亮.png", "进度条（红色.png", "暗色点点.png", "进度条暗点.png"]
	var warning := remaining < 3
	var indices: Array[int] = [1 if warning else 0]
	var variables: Dictionary = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/variable.json"))
	var repeated := str(variables.get("MAIN_UI_TITLE_NUMBER_RED" if warning else "MAIN_UI_TITLE_NUMBER_NOMAL", ""))
	var last := str(variables.get("MAIN_UI_TITLE_NUMBER_RED_TODAY" if warning else "MAIN_UI_TITLE_NUMBER_TODAY", ""))
	var tokens := RegEx.create_from_string("<sprite=(\\d+)>")
	for part in [repeated.repeat(maxi(0, remaining - 1)), last]:
		for token in tokens.search_all(part):
			indices.append(int(token.get_string(1)))
	for index in indices:
		# TMP normalizes each sprite to font size, then applies character scale.
		# countdown_pics: character scale 2 (figures), 1 (lit), 0.9 (dim).
		var cell := Control.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var character_scale := 2.0 if index < 4 else (1.0 if index < 6 else 0.9)
		var image := TextureRect.new()
		image.texture = atlas.frame(names[index])
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var glyph_size := image.texture.get_size()
		var sprite_scale := 57.0 / glyph_size.y * character_scale
		var advance := 80.0 if index < 2 else (61.0 if index < 4 else 25.0)
		cell.custom_minimum_size = Vector2(advance * sprite_scale - 20.0 * 57.0 / 90.0, 100)
		image.size = glyph_size * sprite_scale
		image.position = Vector2(-11.6 * sprite_scale if index == 2 or index == 3 else 0.0, (100.0 - image.size.y) * 0.5)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(image)
		_deadline_track.add_child(cell)


func _update_prestige_strip() -> void:
	if _state == null or _prestige_slots.is_empty():
		return
	for i in range(_prestige_slots.size()):
		var slot: Control = _prestige_slots[i]
		var value_label = slot.get_node_or_null("Value")
		if value_label != null:
			value_label.text = str(int(_state.get_counter(7100001 + i)))


func _nine_slice_style(texture_path: String) -> StyleBox:
	if not ResourceLoader.exists(texture_path):
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color("#3a2b1a")
		return flat
	var style := StyleBoxTexture.new()
	style.texture = load(texture_path) as Texture2D
	var tex: Texture2D = style.texture
	var mx := tex.get_width() * 0.4
	style.texture_margin_left = mx
	style.texture_margin_right = mx
	style.texture_margin_top = tex.get_height() * 0.4
	style.texture_margin_bottom = tex.get_height() * 0.4
	return style


func _sprite_child(texture_path: String, sprite_size: Vector2) -> TextureRect:
	var sprite := TextureRect.new()
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path) as Texture2D
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.custom_minimum_size = sprite_size
		sprite.size = sprite_size
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sprite


func _effective_view_size() -> Vector2:
	if size.x > 0.0 and size.y > 0.0:
		return size
	var node := get_parent()
	while node != null:
		if node is Control:
			var control := node as Control
			if control.size.x > 0.0 and control.size.y > 0.0:
				return control.size
		node = node.get_parent()
	var viewport := get_viewport()
	if viewport != null:
		return viewport.get_visible_rect().size
	return MOCKUP_SIZE


func _layout_situation_desk(s: float) -> void:
	if _desk_content == null:
		return
	var map_size := _desk_content.size
	_desk_content.refresh_context()
	if _log_label != null:
		_log_label.size = Vector2(520, 34) * s
		_log_label.position = Vector2((map_size.x - _log_label.size.x) * 0.5, map_size.y - 58 * s)


func _set_rect(node: Control, rect: Rect2) -> void:
	node.position = rect.position.round()
	node.size = rect.size.round()


func _stat_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.94, 0.93, 0.89, 0.88))
	return label


func _panel(node_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style())
	return panel


func _hud_panel_style() -> StyleBox:
	# Transparent host: the readouts sit directly on the table painting.
	var style := StyleBoxEmpty.new()
	return style


func _scene_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# SituationDesk paints the complete board. The host panel exists only as a
	# stable layout/safe-area node and must not reintroduce the old dark frame.
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	return style


func _icon_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(62, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#2b1d12"))
	button.add_theme_color_override("font_hover_color", Color("#681f1b"))
	button.add_theme_color_override("font_disabled_color", Color(0.26, 0.20, 0.15, 0.48))
	button.add_theme_stylebox_override("normal", _small_action_style())
	button.add_theme_stylebox_override("hover", _small_action_style(Color("#efc46e")))
	button.add_theme_stylebox_override("pressed", _small_action_style(Color("#fff1bc")))
	button.add_theme_stylebox_override("disabled", _small_action_style(Color(0.82, 0.84, 0.88, 0.20)))
	return button


## Texture-first: the original parchment strip IS the small-button surface.
## [SRC: Texture2D/button_bg.png 516x140]
func _small_action_style(border: Color = Color(0.43, 0.28, 0.15, 0.68)) -> StyleBox:
	var art_path := "res://assets/original/ui/button_bg.png"
	if ResourceLoader.exists(art_path):
		var tex := load(art_path) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 150
			style.texture_margin_right = 150
			style.texture_margin_top = 40
			style.texture_margin_bottom = 40
			style.content_margin_left = 158
			style.content_margin_right = 158
			style.content_margin_top = 46
			style.content_margin_bottom = 46
			return style
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#dfc886")
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	style.shadow_color = Color(0.04, 0.022, 0.012, 0.42)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2.0, 3.0)
	return style


func _round_button_style(border: Color = Color(0.55, 0.38, 0.17, 0.82)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d8bd74")
	style.border_color = border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 72
	style.corner_radius_top_right = 72
	style.corner_radius_bottom_left = 72
	style.corner_radius_bottom_right = 72
	style.shadow_color = Color(0.04, 0.022, 0.012, 0.54)
	style.shadow_size = 7
	style.shadow_offset = Vector2(4.0, 5.0)
	return style




func _emit_open_rite_instance(rite_uid: int) -> void:
	open_rite_instance.emit(rite_uid)




func refresh() -> void:
	if _state == null or _card_items == null:
		return
	# Rebuild visibility from the persisted host transition, not a one-way hide.
	# [SRC: GameController.<OnNextRound>b__9 0x571000 releases the operation
	# mask / controller lock after SaveRoundBegin. Exact animation timing is
	# still unported; this only restores the stable actionable state.]
	_set_next_day_text_visible(_state.round_transition.is_empty())
	# The clone rebuilds presentation from runtime state on refresh. This is the
	# host equivalent of MapController.AddPin/RemovePin reacting to rite nodes;
	# never derive pins from config-only availability.
	if _desk_content != null:
		_desk_content.refresh_context()
	if _begin_guide_bar != null:
		_begin_guide_bar.refresh(_state)
	# [SRC: GameController.c @ ShowSudanBox (0x557af0) / ShowPrestige
	#       (0x557390), dump.cs Player.sudan_box_show@0x48 /
	#       prestige_unshow@0x4A]  The stored flags are the source of truth for
	# desktop chrome visibility; prestige uses the original inverse polarity.
	if _sudan_box != null:
		_sudan_box.visible = bool(_state.sudan_box_show)
	if _prestige_strip != null:
		_prestige_strip.visible = not bool(_state.prestige_unshow)
	if _main_help_button != null:
		_main_help_button.visible = not bool(_state.helpbtn_unshow)
	# [SRC: GameController.c OnCachedListChanged (0x553b70) — the tray items
	# mirror player.cached_event; the next-round mask SetActive(0 < Count).]
	if _cached_events_view != null:
		_cached_events_view.refresh(_state.cached_event)
	if _cached_event_mask != null:
		_cached_event_mask.visible = not _state.cached_event.is_empty()
	_update_deadline_strip()
	_update_prestige_strip()
	_bag_tabs.update_page(_state.current_bag_index)
	var previous_positions := _capture_hand_visual_positions()
	for child in _card_items.get_children():
		child.queue_free()
	_card_items.modulate = Color(1, 1, 1, 0)
	_hand_sticky = false
	var life := int(_state.difficulty_config.get("sudan_life_time", 7))
	_state.sync_rail_order()
	# [SRC: CardController.CardSplit 0x528390 / CardStack 0x5286b0;
	# original runtime count badge: 8 -> two visible objects, 7 + 1.]
	# Preserve each UID as a separate hit target until an explicit stack action.
	var next_known_uids: Dictionary = {}
	for card_uid in _state.visible_rail_card_uids():
		var uid := int(card_uid)
		if _state.is_active_sudan_card(uid):
			var asc = _active_sudan_for_card(uid)
			if asc != null:
				var sudan_widget := _make_sudan_card(asc, life)
				var has_drop_origin := _pending_hand_drop_origins.has(uid)
				sudan_widget.set_meta("deal_pending", not has_drop_origin and not _known_rail_card_uids.has(uid))
				if has_drop_origin:
					sudan_widget.set_meta("reflow_from", _pending_hand_drop_origins[uid])
					var sudan_drag_pose: Dictionary = _pending_hand_drop_poses.get(uid, {})
					sudan_widget.set_meta("reflow_rotation_from", float(sudan_drag_pose.get("rotation", INF)))
					sudan_widget.set_meta("reflow_scale_from", sudan_drag_pose.get("scale", Vector2.ZERO))
					sudan_widget.set_meta("reflow_tilt_from", sudan_drag_pose.get("tilt", Vector2(INF, INF)))
					_pending_hand_drop_origins.erase(uid)
					_pending_hand_drop_poses.erase(uid)
				elif previous_positions.has(uid):
					sudan_widget.set_meta("reflow_from", previous_positions[uid])
				sudan_widget.drag_visibility_changed.connect(_on_hand_card_drag_visibility_changed)
				_card_items.add_child(sudan_widget)
				sudan_widget.set_selected(uid == _card_detail_card_uid, false)
				next_known_uids[uid] = true
			continue
		var card: Dictionary = _state.card_data_for(uid, _db)
		if card.is_empty():
			continue
		var widget := CardWidget.make(card, "hand")
		widget.custom_minimum_size = widget.card_size()
		widget.clicked.connect(_show_card_detail)
		widget.quick_action_requested.connect(_on_hand_card_quick_action)
		widget.stack_dropped.connect(_on_hand_card_stack_dropped)
		widget.stack_drop_allowed = _can_drop_stack
		widget.equipment_drop_allowed = _can_drop_equipment
		widget.equipment_dropped.connect(_on_equipment_dropped)
		widget.split_requested.connect(_on_hand_card_split_requested)
		widget.split_one_requested.connect(func(uid: int): _on_hand_card_split_requested(uid, 1))
		widget.hold_hint_requested.connect(_on_hand_card_hold_hint)
		var has_drop_origin := _pending_hand_drop_origins.has(uid)
		widget.set_meta("deal_pending", not has_drop_origin and not _known_rail_card_uids.has(uid))
		if has_drop_origin:
			widget.set_meta("reflow_from", _pending_hand_drop_origins[uid])
			var card_drag_pose: Dictionary = _pending_hand_drop_poses.get(uid, {})
			widget.set_meta("reflow_rotation_from", float(card_drag_pose.get("rotation", INF)))
			widget.set_meta("reflow_scale_from", card_drag_pose.get("scale", Vector2.ZERO))
			widget.set_meta("reflow_tilt_from", card_drag_pose.get("tilt", Vector2(INF, INF)))
			_pending_hand_drop_origins.erase(uid)
			_pending_hand_drop_poses.erase(uid)
		elif previous_positions.has(uid):
			widget.set_meta("reflow_from", previous_positions[uid])
		widget.drag_visibility_changed.connect(_on_hand_card_drag_visibility_changed)
		_card_items.add_child(widget)
		widget.set_selected(uid == _card_detail_card_uid, false)
		next_known_uids[uid] = true
	_known_rail_card_uids = next_known_uids
	_layout_hand_cards()
	call_deferred("_layout_hand_cards")
	_refresh_event_overlay()


## The original HandCardsController lays its children out itself and compresses
## their visible width (minVisibleWidth defaults to 20) instead of exposing a
## ScrollRect.  Keep that accessibility boundary while using a straight,
## centred row with complete borders at ordinary hand sizes.
## [SRC: decompiled/HandCardsController.c @ Update (RVA 0x563520),
## dump.cs:320760]
func _change_hand_bag(index: int) -> void:
	if not _presentation_blockers.is_empty():
		return
	if _state.current_bag_index == index:
		return
	_state.set_current_bag_index(index)
	_hand_drop_preview_index = -1
	refresh()


func _layout_hand_cards(previous_positions: Dictionary = {}) -> void:
	if _card_items == null or not is_instance_valid(_card_items):
		return
	var cards := _ordered_hand_cards()
	var count := cards.size()
	if count == 0:
		_hand_content_overflows = false
		return
	var metrics := _hand_layout_metrics(cards, 1 if _hand_drop_preview_index >= 0 else 0)
	if metrics.is_empty():
		return
	var available_width: float = metrics["available_width"]
	var slot_positions: Array = metrics["slot_positions"]
	_hand_content_overflows = bool(metrics["overflows"])
	for index in count:
		var card := cards[index]
		var slot_index := index
		# [SRC: GameScene MainUI/Hand anchors(0,0)-(1,0) pos(-63.97,4)
		#       sizeDelta(-1116.74,430) pivot(0.52,0): the cards sit on the
		#       content rect's bottom edge. Measured against
		#       docs/ui_layout/original_runtime/desktop.jpg, the original card
		#       top is 2px lower at 1920 than a vertically centred card, which
		#       matches bottom alignment (2156-422=1734 canvas units).]
		card.set_hand_pose(
			Vector2(
				float(slot_positions[slot_index]) + card.card_size().x * (card.hand_layout_scale() - 1.0) * 0.5,
				maxf(0.0, _card_items.size.y - card.card_size().y) - card.card_size().y * (card.hand_layout_scale() - 1.0) * 0.5
			),
			0.0,
			slot_index
		)
		card.set_hand_idle(
			true,
			slot_index,
			Callable(self, "hand_idle_time_seconds")
		)
		if bool(card.get_meta("deal_pending", false)):
			card.set_meta("deal_pending", false)
			card.play_deal_in(Vector2.ZERO, index)
		elif card.has_meta("reflow_from"):
			var old_position: Vector2 = card.get_meta("reflow_from")
			var old_rotation := float(card.get_meta("reflow_rotation_from", INF))
			var old_scale: Vector2 = card.get_meta("reflow_scale_from", Vector2.ZERO)
			var old_tilt: Vector2 = card.get_meta("reflow_tilt_from", Vector2(INF, INF))
			card.remove_meta("reflow_from")
			card.remove_meta("reflow_rotation_from")
			card.remove_meta("reflow_scale_from")
			card.remove_meta("reflow_tilt_from")
			card.play_hand_reflow(old_position - card.position, old_rotation, old_scale, old_tilt)
		elif previous_positions.has(card.card_uid):
			var old_position: Vector2 = previous_positions[card.card_uid]
			card.play_hand_reflow(old_position - card.position)
	_card_items.modulate = Color.WHITE

	for card_index in metrics.draw_order:
		_card_items.move_child(cards[card_index], -1)
	for child in cards:
		child.set_hand_draw_order(child.get_index())


func _hand_layout_metrics(cards: Array[CardWidget], preview_slots: int = 0) -> Dictionary:
	var available_width := _card_items.size.x
	if available_width <= 0.0 or cards.is_empty() and preview_slots <= 0:
		return {}
	var widths: Array[float] = []
	for card in cards:
		# [SRC: HandCardsController.Update 0x563520 gathers sizeDelta.x *
		# localScale.x; HandBagController.SetChild 0x55e360 places the scaled
		# half-height above the bottom. Preserve that geometry for 1.1x candidates.]
		widths.append(card.card_size().x * card.hand_layout_scale())
	var previous_order: Array = []
	for child in _card_items.get_children():
		if child in cards:
			previous_order.append(cards.find(child))
	var result := SourceHandLayout.allocate(widths, available_width, _hand_normalized_range, previous_order,
		_hand_drop_preview_index if preview_slots > 0 else -1, CardWidget.CARD_SIZE.x)
	_hand_normalized_range = result.range
	return {
		"available_width": available_width,
		"slot_positions": result.positions,
		"overflows": result.overflows,
		"draw_order": result.draw_order,
		"total": result.total,
	}


func _ordered_hand_cards() -> Array[CardWidget]:
	var cards: Array[CardWidget] = []
	if _card_items == null:
		return cards
	for child in _card_items.get_children():
		if child is CardWidget and not child.is_queued_for_deletion() and child.visible:
			cards.append(child)
	# Source sorts Card.bagpos before layout; draw sibling order is independent.
	if _state != null:
		cards.sort_custom(func(a, b): return _state.rail_order.find(a.card_uid) < _state.rail_order.find(b.card_uid))
	return cards


func _advance_hand_edge_scroll() -> void:
	if not _hand_content_overflows or _card_items == null or not _presentation_blockers.is_empty():
		return
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered == null or not (hovered == _card_items or _card_items.is_ancestor_of(hovered)):
		return
	var cards := _ordered_hand_cards()
	var metrics := _hand_layout_metrics(cards, 1 if _hand_drop_preview_index >= 0 else 0)
	if metrics.is_empty():
		return
	var next := SourceHandLayout.advance_range(_hand_normalized_range,
		_card_items.get_local_mouse_position().x, _card_items.size.x, metrics.total)
	if not is_equal_approx(next, _hand_normalized_range):
		_hand_normalized_range = next
		_layout_hand_cards()
		# Unity EventSystem raycasts each frame; Godot otherwise retains the
		# old hover target when cards scroll beneath a stationary pointer.
		get_viewport().update_mouse_cursor_state()


func _capture_hand_visual_positions() -> Dictionary:
	var positions: Dictionary = {}
	if _card_items == null:
		return positions
	for child in _card_items.get_children():
		if child is CardWidget and not child.is_queued_for_deletion() and child.visible:
			var card := child as CardWidget
			positions[card.card_uid] = card.position + card.offset_transform_position
	return positions


func _on_hand_card_drag_visibility_changed(card_uid: int, hidden: bool) -> void:
	if not hidden:
		_hand_sticky = false
		_hand_drop_preview_index = -1
		# A successful hand drop has already rebuilt this UID and started its
		# pose-preserving return.  The old source's DRAG_END notification must not
		# restart that animation with a direction-derived rotation.
		for child in _card_items.get_children():
			if (
				child is CardWidget
				and child.visible
				and int((child as CardWidget).card_uid) == card_uid
				and (child as CardWidget).is_hand_motion_active()
			):
				return
	var previous_positions := _capture_hand_visual_positions()
	_layout_hand_cards(previous_positions)


func _preview_hand_drop(data: Variant, rail_position: Vector2) -> void:
	if not can_drop_card_to_hand(data):
		return
	var dragged_uid := int(data.get("card_uid", data.get("card_id", 0)))
	var preview := _resolve_hand_preview(rail_position, dragged_uid, data, _hand_sticky, _hand_sticky_start)
	_hand_sticky = preview.sticky
	_hand_sticky_start = preview.start
	var next_index: int = preview.index
	if next_index == _hand_drop_preview_index:
		return
	var previous_positions := _capture_hand_visual_positions()
	_hand_drop_preview_index = next_index
	_layout_hand_cards(previous_positions)


func _clear_hand_drop_preview() -> void:
	_hand_sticky = false
	if _hand_drop_preview_index < 0:
		return
	var previous_positions := _capture_hand_visual_positions()
	_hand_drop_preview_index = -1
	_layout_hand_cards(previous_positions)


func _hand_preview_index_at(rail_position: Vector2, dragged_card_uid: int) -> int:
	return int(_resolve_hand_preview(rail_position, dragged_card_uid, {}, false, Vector2.ZERO).index)


func _resolve_hand_preview(rail_position: Vector2, dragged_uid: int, data: Dictionary,
	sticky: bool, sticky_start: Vector2) -> Dictionary:
	var widths: Array = []
	var compatible: Array = []
	for card in _ordered_hand_cards():
		if card.card_uid == dragged_uid:
			continue
		widths.append(card.card_size().x * card.hand_layout_scale())
		compatible.append(card._can_stack_dropped_card(data) or card._can_equip_dropped_card(data))
	var global_pos := _card_rail_view.get_global_transform() * rail_position
	var local_point := _card_items.get_global_transform().affine_inverse() * global_pos
	return SourceHandLayout.preview(widths, _card_items.size.x, _hand_normalized_range,
		local_point, compatible, sticky, sticky_start)


func _active_sudan_for_card(card_or_uid: int) -> Variant:
	for asc in _state.active_sudan_cards:
		if int(asc.card_id) == card_or_uid or int(asc.card_uid) == card_or_uid:
			return asc
	return null


func _make_sudan_card(asc, life: int) -> CardWidget:

	var card: Dictionary = _state.card_data_for(int(asc.card_uid), _db)
	if card.is_empty():
		# Legacy fixtures may construct an ActiveSudan directly. Runtime play
		# always has card_uid, but keep this display-only fallback harmless.
		card = _db.get_card(int(asc.card_id)).duplicate(true)
		card["instance_uid"] = int(asc.card_uid)
	card["id"] = int(asc.card_id)
	card["type"] = "sudan"
	card["remaining_life"] = int(asc.days_left)
	var widget := CardWidget.make(card, "active_sudan")
	widget.custom_minimum_size = widget.card_size()
	widget.clip_contents = false
	widget.clicked.connect(_show_card_detail)
	widget.quick_action_requested.connect(_on_hand_card_quick_action)
	return widget


func can_drop_card_to_hand(data: Variant) -> bool:
	if data is Dictionary and not preload("res://ui/rite_slot_access.gd").can_move_source(_state, _db, data):
		return false
	if not (data is Dictionary):
		return false
	if str(data.get("type", "")) != "card":
		return false
	var source := str(data.get("source", ""))
	return source == "slot" or source == "hand" or source == "active_sudan"


# Clone-era compatibility adapter. The desk owns the player-facing
# "思考" interaction; this method preserves the verified MethinksEngine chain
# until a replacement mechanism has been prototyped and accepted.
func can_drop_card_on_methinks(data: Variant) -> bool:
	if not _state.think_session.is_empty() or not _state.pending_operations.is_empty():
		return false
	if not (data is Dictionary):
		return false
	if str(data.get("type", "")) != "card":
		return false
	var source := str(data.get("source", ""))
	var uid := int(data.get("card_uid", 0))
	return (source == "hand" and _state.has_card_in_hand(uid)) or (source == "active_sudan" and _state.is_active_sudan_card(uid))


func drop_card_on_methinks(data: Variant) -> void:
	if not can_drop_card_on_methinks(data):
		return
	var card_uid := int(data.get("card_uid", data.get("card_id", 0)))
	var source := str(data.get("source", ""))
	var result: Dictionary = MethinksEngine.process_card(card_uid, source, _state, _db, _rng, true)
	set_log(str(result.get("message", "")))
	refresh()
	var deferred: Dictionary = result.get("deferred", {})
	if bool(deferred.get("over", false)):
		game_over_requested.emit()


func drop_card_to_hand(data: Variant, rail_position: Vector2 = Vector2.INF) -> void:
	if not can_drop_card_to_hand(data):
		return
	var card_uid := int(data.get("card_uid", data.get("card_id", 0)))
	var source := str(data.get("source", ""))
	var source_slot := str(data.get("source_slot", ""))
	var source_rite_uid := int(data.get("source_rite_uid", 0))
	var card: Dictionary = _state.card_data_for(card_uid, _db)
	var is_sudan: bool = str(card.get("type", "")) == "sudan" or _state.is_active_sudan_card(card_uid)
	var insert_index := (
		_hand_drop_preview_index
		if _hand_drop_preview_index >= 0
		else _rail_insert_index_at(rail_position, card_uid)
	)
	if rail_position.x != INF:
		var global_drop := _card_rail_view.get_global_transform() * rail_position
		var local_drop := _card_items.get_global_transform().affine_inverse() * global_drop
		var grab_offset: Vector2 = data.get("grab_offset", CardWidget.CARD_SIZE * 0.5)
		var drag_visual_position: Vector2 = data.get("drag_visual_position", Vector2.ZERO)
		_pending_hand_drop_origins[card_uid] = local_drop - grab_offset + drag_visual_position
		_pending_hand_drop_poses[card_uid] = {
			"rotation": float(data.get("drag_visual_rotation", INF)),
			"scale": data.get("drag_visual_scale", Vector2.ZERO),
			"tilt": data.get("drag_visual_tilt", Vector2(INF, INF)),
		}
	_hand_drop_preview_index = -1
	if source == "slot":
		var slot_num: int = (
			source_slot.substr(1).to_int()
			if source_slot.begins_with("s")
			else int(_state.slot_for_table_card(card_uid, source_rite_uid))
		)
		_state.remove_card_from_slot(card_uid, slot_num, source_rite_uid)
		var returned_instance = _state.get_card_instance(card_uid)
		if returned_instance != null:
			returned_instance.bag = _state.current_bag_index
		insert_index = _global_rail_insert_index(insert_index, card_uid)
		if is_sudan:
			var instance = _state.get_card_instance(card_uid)
			if instance != null:
				instance.zone = "sudan"
			_state.insert_card_to_rail(card_uid, insert_index)
		else:
			_state.add_card_to_hand_at_rail(card_uid, insert_index, _db)
		_notify_card_returned_to_hand(card_uid, source_slot)
	elif source == "hand" or source == "active_sudan":
		insert_index = _global_rail_insert_index(insert_index, card_uid)
		_state.reorder_rail_card(card_uid, insert_index)
	refresh()


## [SRC: CardDropManager.DropCard -> CardController.CardStack 0x5286b0 — a
##       stackable card dropped on a same-id stackable hand card merges into it
##       instead of reordering the rail.]
func _on_hand_card_stack_dropped(target_uid: int, source_uid: int) -> void:
	if _state == null or not _state.has_method("stack_cards"):
		return
	if not _can_drop_stack(target_uid, {"type": "card", "card_uid": source_uid}):
		return
	var source_rite_uid: int = _state.get_card_instance(source_uid).rite_uid
	if _state.stack_cards(target_uid, source_uid):
		_refresh_departed_slot_card(source_rite_uid)
		refresh()


func _can_drop_stack(target_uid: int, data: Variant) -> bool:
	# [SRC: CardController.CardStack 0x5286b0, dump.cs:317120;
	# CardDropManager.DropCard 0x4ef4f0. No hand-only source gate.]
	if _state == null or not (data is Dictionary) or _presentation_frozen:
		return false
	for blocker in _presentation_blockers:
		if blocker != "rite":
			return false
	var target = _state.get_card_instance(target_uid)
	var source = _state.get_card_instance(int(data.get("card_uid", 0)))
	if target == null or source == null or target == source or target.zone != "hand":
		return false
	return _can_release_drag_source(source)


func _can_release_drag_source(source) -> bool:
	# OnBeginDrag has already checked CanMove and detached the source slot.
	if source.zone in ["hand", "drag"]:
		return true
	if source.zone != "slot" or not preload("res://ui/rite_slot_access.gd").can_edit(_state, _db, source.rite_uid, source.slot_key):
		return false
	for layer in [_overlay_layer, _source_overlay_layer]:
		if layer == null:
			continue
		for child in layer.get_children():
			if child.has_method("can_release_slot_card") and not child.can_release_slot_card(source.uid, source.rite_uid, source.slot_key):
				return false
	return true


func _refresh_departed_slot_card(rite_uid: int) -> void:
	if rite_uid <= 0:
		return
	for layer in [_overlay_layer, _source_overlay_layer]:
		if layer == null:
			continue
		for child in layer.get_children():
			if child.has_method("refresh_departed_slot_card"):
				child.refresh_departed_slot_card(rite_uid)


func _can_drop_equipment(host_uid: int, data: Variant) -> bool:
	# [SRC: CardExtensions.CanEquip 0x37ec10; CardController.CardEquip
	# 0x528020; CardInfoNewController.DropCard 0x533550.]
	if _state == null or not (data is Dictionary) or data.get("type", "") != "card":
		return false
	if _presentation_frozen:
		return false
	for blocker in _presentation_blockers:
		if blocker != "card_detail" and blocker != "rite":
			return false
	var source_uid := int(data.get("card_uid", 0))
	var host = _state.get_card_instance(host_uid)
	var equipment = _state.get_card_instance(source_uid)
	return host != null and equipment != null and host_uid != source_uid and host.zone == "hand" and _can_release_drag_source(equipment) and _effective_tag_value(source_uid, "装备") > 0 and not _state._matching_equip_slot(host_uid, source_uid, _db).is_empty()


## Tag lookup on the effective GetTag row (definition + delta + inheritable
## equips). Reading CardInstance.tags directly would only see the runtime delta.
## [SRC: CardExtensions.c @ GetTag (RVA 0x3814a0)]
func _effective_tag_value(uid: int, tag_name: String) -> int:
	if _state == null:
		return 0
	return int(_state.effective_card_tags(uid, _db).get(tag_name, 0))


func _on_equipment_dropped(host_uid: int, source_uid: int) -> void:
	var data := {"type": "card", "card_uid": source_uid}
	if not _can_drop_equipment(host_uid, data):
		return
	var source_rite_uid: int = _state.get_card_instance(source_uid).rite_uid
	if _state.attach_equipment(host_uid, source_uid, _db, true, true) < 0:
		return
	_refresh_departed_slot_card(source_rite_uid)
	refresh()
	var host_card: Dictionary = _state.card_data_for(host_uid, _db)
	# [SRC: CardController.CardEquip 0x528020 -> GameController.ShowCardInfo
	# 0x556c60; CardInfoNewController.DropCard 0x533550 refreshes an open panel.]
	if _card_info_view != null and is_instance_valid(_card_info_view) and _card_detail_card_uid == host_uid:
		_card_info_view.show_card(host_card, host_uid)
	else:
		_show_card_detail(int(host_card.get("id", 0)), host_card)


## [SRC: CardController.OnPointerUp 0x52afe0 -> CardSplit(count/2). The host
##       binds the source's SplitCard prompt to Shift+click until the prompt
##       layer exists.]
func _on_hand_card_split_requested(card_uid: int, amount: int = -1) -> void:
	if _state == null or not _state.has_method("split_card_stack"):
		return
	if _state.split_card_stack(card_uid, amount) > 0:
		refresh()


## [SRC: CardController.Update 0x52c890 — a 0.2s hold calls
##       GameController.ShowSatisfiedRite 0x5576b0, which highlights every rite
##       whose open slot accepts the card.]
func _on_hand_card_hold_hint(card_uid: int) -> void:
	if _state == null or _desk_content == null or not _desk_content.has_method("show_satisfied_rites"):
		return
	if not _state.has_method("satisfied_rite_uids_for_card"):
		return
	if not _presentation_blockers.is_empty() or _presentation_frozen:
		return
	_desk_content.show_satisfied_rites(_state.satisfied_rite_uids_for_card(card_uid, _db, _rng))


# [SRC: CardController.OnPointerUp 0x52afe0: right click dispatches to the
# open, unstarted rite panel; without a panel it calls ShowSatisfiedRite.]
func _on_hand_card_quick_action(card_uid: int) -> void:
	if _source_overlay_layer != null:
		for child in _source_overlay_layer.get_children():
			if child.is_queued_for_deletion() or not child.has_method("panel_drop_slot"):
				continue
			var data := {"type": "card", "card_uid": card_uid, "source": "active_sudan" if _state.is_active_sudan_card(card_uid) else "hand"}
			var key: String = child.panel_drop_slot(data)
			if not key.is_empty():
				child.drop_card_on_slot(key, data)
			return
	_on_hand_card_hold_hint(card_uid)


func _global_rail_insert_index(page_index: int, dragged_uid: int) -> int:	# A screen insertion index belongs to the visible bag, while rail_order
	# retains all bags. Translate without permuting cards on other pages.
	var remaining: Array[int] = []
	for uid in _state.rail_order:
		if int(uid) != dragged_uid:
			remaining.append(int(uid))
	var page: Array[int] = _state.visible_rail_card_uids()
	page.erase(dragged_uid)
	if page.is_empty():
		return remaining.size()
	if page_index >= page.size():
		return remaining.find(page.back()) + 1
	return remaining.find(page[maxi(0, page_index)])


func _rail_insert_index_at(rail_position: Vector2, dragged_card_uid: int = 0) -> int:
	if _card_items == null:
		return _state.rail_order.size()
	if rail_position.x == INF:
		return _state.rail_order.size()
	var global_pos := _card_rail_view.get_global_transform() * rail_position
	var local_x := (_card_items.get_global_transform().affine_inverse() * global_pos).x
	var index := 0
	for child in _ordered_hand_cards():
		if not (child is CardWidget):
			continue
		var widget := child as CardWidget
		if int(widget.card_uid) == dragged_card_uid:
			continue
		if not widget.visible:
			continue
		var center_x := widget.position.x + widget.size.x * 0.5
		if local_x < center_x:
			return index
		index += 1
	return index


func _notify_card_returned_to_hand(card_uid: int, source_slot: String) -> void:
	for layer in [_overlay_layer, _source_overlay_layer]:
		if layer == null:
			continue
		for child in layer.get_children():
			if child.has_method("return_card_to_hand"):
				child.return_card_to_hand(card_uid, source_slot)


func set_log(text: String) -> void:
	if _log_label:
		_log_label.text = text


func play_next_day_transition() -> void:
	# [SRC: GameScene Night/Day UnityEvents toggle GO45 (text), not Next Round.]
	_set_next_day_text_visible(false)
	# The authored night/day sequence is driven by the source animation
	# controller; do not substitute an invented fade here.


func present_day_transition(progress: Dictionary) -> void:
	if _next_day_transition == null:
		_next_day_transition = preload("res://ui/next_day_transition.gd").new()
		_next_day_transition.name = "SourceNextDayTransition"
		_next_day_transition.z_index = PERSISTENT_CONTROL_Z + 1
		add_child(_next_day_transition)
	_next_day_transition.present(progress, size)
	var animated := progress.has("animation")
	var entering := str(progress.get("phase", "")) in ["night_enter", "day_enter"]
	if _presentation_blockers.has("day_animation") != entering:
		set_world_scene_blocker("day_animation", entering, false, true)
	_set_next_day_text_visible(not animated and progress.is_empty())


func _set_next_day_text_visible(shown: bool) -> void:
	# Preserve the authored watch plate behind the animated rings.
	_advance_button.visible = true
	_advance_button.get_node("NextDayTextButton").visible = shown


func add_overlay(node: Control) -> void:
	if _overlay_layer == null:
		add_child(node)
		return
	_overlay_layer.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.move_child(node, _overlay_layer.get_child_count() - 1)


func add_source_overlay(node: Control) -> void:
	if _source_overlay_layer == null:
		add_child(node)
		return
	_source_overlay_layer.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_source_overlay_layer.move_child(node, _source_overlay_layer.get_child_count() - 1)


func set_world_scene_blocker(
	source: String,
	blocking: bool,
	hide_chrome: bool = true,
	lock_persistent_actions: bool = false,
	pause_underlying_presentation: bool = false
) -> void:
	if source.is_empty():
		return
	if blocking:
		_presentation_blockers[source] = hide_chrome
		if lock_persistent_actions:
			_persistent_action_locks[source] = true
		else:
			_persistent_action_locks.erase(source)
		if pause_underlying_presentation:
			_underlying_presentation_pauses[source] = true
		else:
			_underlying_presentation_pauses.erase(source)
	else:
		_presentation_blockers.erase(source)
		_persistent_action_locks.erase(source)
		_underlying_presentation_pauses.erase(source)
	if _desk_content != null and _desk_content.has_method("set_scene_blocker"):
		_desk_content.set_scene_blocker(source, blocking, hide_chrome)
	_update_persistent_action_availability()
	_set_underlying_presentation_paused(not _underlying_presentation_pauses.is_empty())


## A global modal lives above GameScreen. Freeze this complete lower layer so
## its already-visible controls remain a true paused snapshot beneath the
## modal rather than continuing their own visual processing.
func set_presentation_frozen(frozen: bool) -> void:
	if _presentation_frozen == frozen:
		return
	_presentation_frozen = frozen
	process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT


## Context menus are still part of GameScreen, so disabling this complete node
## would also freeze their entrance/exit animation. Pause only the persistent
## background controls instead: they remain visible under the selector shade,
## but cannot receive input or keep animating independently.
func _set_underlying_presentation_paused(paused: bool) -> void:
	if _cached_event_mask != null:
		_cached_event_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE if paused else Control.MOUSE_FILTER_STOP
	var rite_open := _presentation_blockers.has("rite")
	var rite_only := rite_open and _presentation_blockers.size() == 1
	# Godot mouse picking follows tree order, not z_index. The full-screen
	# rite shade otherwise swallows the hand despite drawing beneath it.
	# [SRC: CardDropManager.DropCard 0x4ef4f0 and CardController.OnPointerUp
	# 0x52afe0 require live hand input while RitePanelShow is active.]
	if rite_only:
		move_child(_card_rail_view, -1)
		move_child(_bag_tabs, -1)
	else:
		move_child(_overlay_layer, -1)
		move_child(_source_overlay_layer, -1)
	# Restoring a rite can reorder these layers AFTER its nested prompt was
	# rebuilt. Keep the blocking prompt last for input as well as drawing.
	# [SRC: GameScene Prompt above UI/RiteResultPanel; PromptController.Show
	# 0x58a020 awaits confirmation before the rite settlement continues.]
	if is_instance_valid(_event_overlay):
		move_child(_event_overlay, -1)
	if is_instance_valid(_change_name_view):
		_change_name_view.move_to_front()
	# The rite is above desktop chrome, while its hand remains a live input
	# surface. [SRC: RitePanelShowController.BindCardHandler/ChooseSlotCard]
	_source_overlay_layer.z_index = PERSISTENT_CONTROL_Z + 1 if rite_open else OVERLAY_LAYER_Z + 1
	_card_rail_view.z_index = PERSISTENT_CONTROL_Z + 2 if rite_open else PERSISTENT_CONTROL_Z
	_bag_tabs.z_index = PERSISTENT_CONTROL_Z + 2 if rite_open else 21
	_right_actions.z_index = PERSISTENT_CONTROL_Z + 2 if rite_open else PERSISTENT_CONTROL_Z
	_begin_guide_bar.z_index = PERSISTENT_CONTROL_Z if rite_open else PERSISTENT_CONTROL_Z + 2
	var hand_paused := paused and not rite_only
	if _bag_tabs != null:
		for button in _bag_tabs.buttons:
			button.disabled = not rite_only and (paused or not _presentation_blockers.is_empty())
	if _menu_button != null:
		_menu_button.disabled = paused
	if _card_rail_view != null:
		_card_rail_view.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE if hand_paused else Control.MOUSE_FILTER_STOP
		)
	if _card_items == null or not is_instance_valid(_card_items):
		return
	for child in _card_items.get_children():
		if child is CardWidget and not child.is_queued_for_deletion():
			(child as CardWidget).set_presentation_paused(hand_paused)


func _update_persistent_action_availability() -> void:
	var chrome_hidden := false
	for hide_chrome in _presentation_blockers.values():
		if bool(hide_chrome):
			chrome_hidden = true
			break
	var persistent_actions_locked := not _persistent_action_locks.is_empty()
	var actions_visible := not chrome_hidden
	var actions_available := (
		actions_visible
		and not persistent_actions_locked
	)
	if _right_actions != null:
		_right_actions.visible = actions_visible
		# The host must pass pointer events to its enabled child buttons. When
		# actions are locked, ignore the whole host so its large clock rect cannot
		# cover the source result surface beneath it.
		_right_actions.mouse_filter = Control.MOUSE_FILTER_PASS if actions_available else Control.MOUSE_FILTER_IGNORE
		# Every background element recedes through the same pause shade. Applying
		# another alpha only to this column makes it read as a broken floating UI.
		_right_actions.self_modulate = Color.WHITE
	if _advance_button != null:
		_advance_button.disabled = not actions_available
		_advance_button.mouse_filter = Control.MOUSE_FILTER_STOP if actions_available else Control.MOUSE_FILTER_IGNORE
		var text_hit := _advance_button.get_node("NextDayTextButton") as Button
		text_hit.disabled = not actions_available
		text_hit.mouse_filter = _advance_button.mouse_filter
		if not actions_available:
			text_hit.get_node("Normal").visible = true
			text_hit.get_node("Hover").visible = false


func _refresh_event_overlay() -> void:
	if _state == null:
		_clear_event_overlay()
		return
	var display := _next_event_display()
	if display.is_empty():
		_clear_event_overlay()
		return
	if str(display.get("kind", "")) == "sleep":
		_clear_event_overlay()
		if not is_inside_tree():
			call_deferred("_refresh_event_overlay")
			return
		if not _sleep_waiting:
			_sleep_waiting = true
			_wait_for_queued_sleep(float(display.get("seconds", 0.0)))
		return
	_show_event_overlay(display)


func _next_event_display() -> Dictionary:
	if _state == null:
		return {}
	var operation: Dictionary = _state.pending_operation() if _state.has_method("pending_operation") else {}
	if operation.is_empty():
		return {}
	var kind := str(operation.get("kind", ""))
	var payload: Dictionary = operation.get("payload", {}) if operation.get("payload", {}) is Dictionary else {}
	if kind in ["prompt", "choice"]:
		return {
			"kind": kind,
			"title": str(payload.get("title", payload.get("id", "提示"))),
			"speaker": str(payload.get("speaker", payload.get("title", ""))),
			"speaker_actor_id": str(payload.get("speaker_actor_id", "protagonist")),
			"text": str(payload.get("text", payload.get("desc", ""))),
			"choices": payload.get("choices", {}),
			# Preserve this operation's icon; searching the whole event can pick
			# an unrelated branch. [SRC: Prompt.Do 0x519340 -> ShowPrompt(icon@0x20);
			# PromptControllerBase.ShowInternal 0x589890 / SetIcon.]
			"icon": _choice_icon_texture(str(payload.get("icon", ""))) if payload.get("icon", "") is String else null,
			"source_icon": payload.get("icon", null),
			"presentation": str(payload.get("presentation", payload.get("kind", ""))),
		}
	if kind == "rename_card":
		return {
			"kind": kind,
			"title": str(payload.get("title", "为卡牌命名")),
			"text": str(payload.get("text", "")),
			"initial_text": str(payload.get("initial_text", "")),
			"card_uid": int(payload.get("card_uid", 0)),
			"card_id": int(payload.get("card_id", 0)),
		}
	if kind == "sleep":
		return {"kind": "sleep", "seconds": float(payload.get("seconds", 0.0))}
	if kind == "event":
		var event_id := int(operation.get("id", 0))
		var event: Dictionary = _db.get_event(event_id) if _db != null and _db.has_method("get_event") else {}
		return {
			"kind": "event",
			"id": event_id,
			"title": str(event.get("name", event.get("title", "事件 %d" % event_id))),
			"text": _event_body_text(event, event_id),
			"choices": event.get("choose", {}),
			"icon": _event_portrait(event),
		}
	return {}


func _show_event_overlay(display: Dictionary) -> void:
	if str(display.get("kind", "")) == "rename_card":
		_show_change_name(display)
		return
	# Keep selection/focus while the same blocking operation is visible.
	# Compare queue-object identity: two identical consecutive prompts are
	# different occurrences and must each start with no selection.
	var operation: Dictionary = _state.pending_operations[0] if not _state.pending_operations.is_empty() else {}
	if _event_overlay != null and is_same(_shown_event_operation, operation):
		return
	_clear_event_overlay()
	_shown_event_operation = operation
	set_world_scene_blocker("event_prompt", true)
	# [SRC: PromptNew.prefab / PromptController.Show 0x58a020 —
	# the event prompt is the 2705-wide OptionBG parchment with body text,
	# full-width option rows, right-side portrait and confirm row. The clone
	# keeps its op-queue semantics and swaps only the presentation surface.]
	_event_overlay = EventPromptViewScript.new()
	_event_overlay.name = "EventPromptOverlay"
	_event_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Result operations can open prompts over an already-raised rite panel.
	_event_overlay.z_index = BLOCKING_PROMPT_Z
	add_child(_event_overlay)
	_event_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_event_panel = _event_overlay.get_node_or_null("PromptNewCanvas/EventPromptPanel")
	_event_overlay.choice_clicked.connect(
		func(key: String, value: Variant): _consume_event_display(key, value)
	)
	_event_overlay.confirm_clicked.connect(func(): _consume_event_display())
	if display.has("source_icon"):
		display["resolved_icons"] = preload("res://ui/source_prompt_icons.gd").resolve(display.source_icon, _state, _db)
	_event_overlay.show_prompt(display, Callable())
	_apply_layout()


## Resolve a choice icon resource reference ("cards/<id>" from event
## configs, "ui/<name>" for panel art) to its extracted texture.
func _choice_icon_texture(resource_ref: String) -> Texture2D:
	if str(resource_ref) == "":
		return null
	var path := ""
	if str(resource_ref).begins_with("cards/"):
		path = "res://assets/original/cards/%s.png" % str(resource_ref).split("/")[-1]
	elif str(resource_ref).begins_with("ui/"):
		path = "res://assets/original/ui/%s.png" % str(resource_ref).split("/")[-1]
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _clear_event_overlay() -> void:
	_shown_event_operation = {}
	# Rename prompts live on their own source surface.
	if _change_name_view != null and is_instance_valid(_change_name_view):
		var old_view = _change_name_view
		_change_name_view = null
		_rename_input = null
		if old_view.get_parent() != null:
			old_view.get_parent().remove_child(old_view)
		old_view.queue_free()
	if _event_overlay == null:
		set_world_scene_blocker("event_prompt", false)
		return
	var old_overlay := _event_overlay
	_event_overlay = null
	_event_panel = null
	_rename_input = null
	if old_overlay.get_parent() != null:
		old_overlay.get_parent().remove_child(old_overlay)
	set_world_scene_blocker("event_prompt", false)
	old_overlay.queue_free()


func _consume_event_display(choice_key: String = "", choice_value: Variant = "") -> void:
	if _state == null:
		return
	var merged: Dictionary = {}
	var operation: Dictionary = _state.consume_pending_operation() if _state.has_method("consume_pending_operation") else {}
	if operation.is_empty():
		return
	var queued_tail: Array = _state.pending_operations.duplicate()
	_state.pending_operations.clear()
	var kind := str(operation.get("kind", ""))
	var payload: Dictionary = operation.get("payload", {}) if operation.get("payload", {}) is Dictionary else {}
	var trigger_ctx: Dictionary = operation.get("context", {}).duplicate(true) if operation.get("context", {}) is Dictionary else {}
	if kind in ["prompt", "choice"]:
		# [SRC: PromptController.Hide 0x589e20 emits OnClosePrompt;
		# OptionController.OnConfirm 0x576900 resolves the choice directly.]
		if kind == "prompt":
			_state.trigger_events("close_prompt", {})
		if choice_key != "":
			set_log("选择：%s" % str(choice_value))
			if not operation.has("sequence_response"):
				DeferredEffects.execute_choice(choice_key, choice_value, _state, _db, _rng, trigger_ctx)
	elif kind == "rename_card":
		var card_uid := int(trigger_ctx.get("card_uid", payload.get("card_uid", 0)))
		# Old clone saves omitted card_id and retained a UID. Decode that once;
		# new operations use the source id domain, including explicit0=player.
		var legacy_card = _state.get_card_instance(card_uid)
		var card_id := int(payload.get("card_id", legacy_card.card_id if legacy_card != null else 0))
		if _rename_input == null or not _state.set_prompt_name(card_id, _rename_input.text):
			# Keep the operation in front until the player submits a non-empty
			# name; the original naming overlay is likewise a blocking promise.
			_state.pending_operations.push_front(operation)
			_state.pending_operations.append_array(queued_tail)
			return
		set_log("卡牌已命名")
	elif kind == "event":
		# The settlement already ran when the event fired (trigger_events
		# settles immediately and only queues interaction-bearing events);
		# consuming must not execute it a second time. Choice branches still
		# run their subtree here.
		var event_id := int(operation.get("id", 0))
		if choice_key != "":
			set_log("选择：%s" % str(choice_value))
			DeferredEffects.execute_choice(choice_key, choice_value, _state, _db, _rng, trigger_ctx)
	OperationsSequence.resume(operation, _state, _db, _rng, choice_key)
	_state.pending_operations.append_array(queued_tail)
	RiteSettlement.pump(_state, _db, _rng)
	# A silently-settled event chain may have requested game over.
	if _request_pending_game_over():
		return
	# An event whose action opens a rite should surface that rite to the player
	# immediately (showing the rite's narration text), not silently park it.
	# The original opens the rite as a UI surface when an event fires it.
	refresh()
	var opened_rite := int(merged.get("rite", 0))
	if opened_rite > 0:
		open_rite.emit(opened_rite)


func _wait_for_queued_sleep(seconds: float) -> void:
	await get_tree().create_timer(maxf(0.0, seconds)).timeout
	if _state != null and _state.has_method("pending_operation") and _state.has_method("consume_pending_operation"):
		if str(_state.pending_operation().get("kind", "")) == "sleep":
			var completed: Dictionary = _state.consume_pending_operation()
			var queued_tail: Array = _state.pending_operations.duplicate()
			_state.pending_operations.clear()
			OperationsSequence.resume(completed, _state, _db, _rng)
			_state.pending_operations.append_array(queued_tail)
	_sleep_waiting = false
	if not _request_pending_game_over():
		refresh()


func _request_pending_game_over() -> bool:
	if _state != null and _state.over_pending:
		_state.over_pending = false
		game_over_requested.emit()
		return true
	return false


## Original portrait for an event: its first `icon` resource (like
## "cards/2000012") resolved against assets/original/cards by basename.
## [SRC: event settlement icon fields (1211 uses, 130 distinct resources)]
func _event_portrait(event: Dictionary) -> Texture2D:
	var icon_res := _first_icon_resource(event)
	if icon_res == "":
		return null
	var name := icon_res.split("/")[-1]
	var path := "res://assets/original/cards/%s.png" % name
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func _first_icon_resource(node: Variant) -> String:
	if node is Dictionary:
		if typeof(node.get("icon")) == TYPE_STRING and str(node.get("icon")) != "":
			return str(node["icon"])
		for key in node:
			var found: String = _first_icon_resource(node[key])
			if found != "":
				return found
	elif node is Array:
		for item in node:
			var found_a: String = _first_icon_resource(item)
			if found_a != "":
				return found_a
	return ""


func _event_body_text(event: Dictionary, event_id: int) -> String:
	for key in ["text", "desc", "description", "content"]:
		if str(event.get(key, "")) != "":
			return str(event[key])
	if event.is_empty():
		return "事件 %d 已触发，后续会接入原版事件文本与结果。" % event_id
	return "事件 %d" % event_id


func _layout_event_prompt(s: float, view_size: Vector2) -> void:
	if _event_panel == null:
		return
	if _event_overlay != null and _event_overlay.has_method("apply_source_layout"):
		# PromptNew 1:1 overlay owns its 3840x2160 source canvas.
		_event_overlay.apply_source_layout(view_size)
		return
	var scene_rect := (
		Rect2(_desk_map.position, _desk_map.size)
		if _desk_map != null
		else Rect2(Vector2(16, 70) * s, view_size - Vector2(32, 320) * s)
	)
	var panel_w: float = min(maxf(1.0, scene_rect.size.x - 220 * s), 760 * s)
	var panel_h: float = 226 * s if _rename_input != null else 176 * s
	panel_h = minf(panel_h, maxf(1.0, scene_rect.size.y - 36 * s))
	var panel_x: float = scene_rect.position.x + (scene_rect.size.x - panel_w) * 0.5
	var panel_y: float = scene_rect.position.y + 18 * s
	_set_rect(_event_panel, Rect2(Vector2(panel_x, panel_y), Vector2(panel_w, panel_h)))


func _event_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(96, 36)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_color_override("font_color", Color("#f2f0eb"))
	button.add_theme_color_override("font_hover_color", Color("#fff0b6"))
	button.add_theme_stylebox_override("normal", _small_action_style())
	button.add_theme_stylebox_override("hover", _small_action_style(Color("#efc46e")))
	button.add_theme_stylebox_override("pressed", _small_action_style(Color("#fff1bc")))
	return button


func _event_panel_style() -> StyleBox:
	# Texture-first: the original prompt parchment IS the panel surface
	# (9-slice via StyleBoxTexture); the authored dark box only survives
	# when the art is missing. [SRC: Texture2D/prompt.png 632x444]
	var art_path := "res://assets/original/ui/prompt.png"
	if ResourceLoader.exists(art_path):
		var tex := load(art_path) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 70
			style.texture_margin_right = 70
			style.texture_margin_top = 60
			style.texture_margin_bottom = 60
			style.content_margin_left = 76
			style.content_margin_right = 76
			style.content_margin_top = 66
			style.content_margin_bottom = 66
			return style
	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color(0.025, 0.032, 0.075, 0.90)
	fallback.border_color = Color(0.86, 0.88, 0.91, 0.34)
	fallback.set_content_margin_all(16)
	fallback.set_border_width_all(1)
	fallback.set_corner_radius_all(3)
	fallback.shadow_color = Color(0.01, 0.012, 0.03, 0.62)
	fallback.shadow_size = 10
	return fallback


## Desktop help: MainHelpTrigger -> MainUI/MainHelp (source overlay).
## Rename prompts use the original PromptChangeName surface.
func _show_change_name(display: Dictionary) -> void:
	_clear_event_overlay()
	if _change_name_view == null or not is_instance_valid(_change_name_view):
		_change_name_view = ChangeNameViewScript.new()
		_change_name_view.name = "ChangeNameOverlay"
		_change_name_view.z_index = OVERLAY_LAYER_Z + 1
		if _source_overlay_layer != null:
			_source_overlay_layer.add_child(_change_name_view)
		else:
			add_child(_change_name_view)
		if not _change_name_view.submitted.is_connected(_consume_rename_input):
			_change_name_view.submitted.connect(_consume_rename_input)
		if not _change_name_view.cancelled.is_connected(_cancel_rename):
			_change_name_view.cancelled.connect(_cancel_rename)
	set_world_scene_blocker("event_prompt", true)
	# The original PromptChangeNameController.Show fills Icon with the card art.
	var card_uid := int(display.get("card_uid", 0))
	var card_id := int(display.get("card_id", 0))
	var art_id := card_id
	if card_uid > 0 and _state != null:
		var runtime_card: Dictionary = _state.card_data_for(card_uid, _db) if _state.has_method("card_data_for") else {}
		if not runtime_card.is_empty():
			art_id = int(runtime_card.get("id", card_id))
	var art_path := "res://assets/original/cards/%d.png" % art_id
	if ResourceLoader.exists(art_path):
		_change_name_view.show_card_art(load(art_path) as Texture2D)
	elif ResourceLoader.exists("res://assets/original/ui/card_type_item.png"):
		_change_name_view.show_card_art(load("res://assets/original/ui/card_type_item.png") as Texture2D)
	_change_name_view.initial_text(str(display.get("initial_text", "")))
	# Keep the legacy rename field name for the existing consume path.
	var rename_input := _find_node_by_name(_change_name_view, "CardRenameInput")
	_rename_input = rename_input as LineEdit if rename_input is LineEdit else null


func _consume_rename_input(text_value: String) -> void:
	if _rename_input == null:
		return
	if _rename_input.text != text_value:
		_rename_input.text = text_value
	_consume_event_display()


func _cancel_rename() -> void:
	if _state != null and _state.has_method("consume_pending_operation"):
		# [SRC: PromptChangeNameController.DoClose 0x5849b0 resolves its promise.]
		var completed: Dictionary = _state.consume_pending_operation()
		var queued_tail: Array = _state.pending_operations.duplicate()
		_state.pending_operations.clear()
		OperationsSequence.resume(completed, _state, _db, _rng)
		_state.pending_operations.append_array(queued_tail)
	_clear_event_overlay()
	if not _request_pending_game_over():
		refresh()


func _find_node_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target)
		if found != null:
			return found
	return null


## Desktop help: MainHelpTrigger -> MainUI/MainHelp (source overlay).
func _toggle_main_help() -> void:
	if _main_help_view != null and is_instance_valid(_main_help_view):
		close_main_help()
		return
	_main_help_view = MainHelpViewScript.new()
	_main_help_view.name = "MainHelpOverlay"
	_main_help_view.z_index = OVERLAY_LAYER_Z + 2
	if _source_overlay_layer != null:
		_source_overlay_layer.add_child(_main_help_view)
	else:
		add_child(_main_help_view)
	if not _main_help_view.closed.is_connected(close_main_help):
		_main_help_view.closed.connect(close_main_help)


func close_main_help() -> void:
	if _main_help_view == null or not is_instance_valid(_main_help_view):
		return
	var old_view = _main_help_view
	_main_help_view = null
	if old_view.get_parent() != null:
		old_view.get_parent().remove_child(old_view)
	old_view.queue_free()


func show_card_detail(card_or_uid: int) -> void:
	var card_uid = _state._resolve_card_uid(card_or_uid) if _state != null and _state.has_method("_resolve_card_uid") else 0
	var card: Dictionary = _state.card_data_for(card_uid, _db) if card_uid > 0 else _db.get_card(card_or_uid).duplicate(true)
	if card.is_empty():
		return
	_show_card_detail(card_uid if card_uid > 0 else int(card.get("id", 0)), card)


func _show_card_detail(card_id: int, card: Dictionary) -> void:
	if card_id <= 0 or card.is_empty():
		return
	var card_uid := int(card.get("instance_uid", 0))
	var same_card := (
		card_uid > 0 and _card_detail_card_uid == card_uid
	) or (
		card_uid <= 0 and _card_detail_card_uid <= 0 and _card_detail_card_id == card_id
	)
	if _card_info_view != null and is_instance_valid(_card_info_view) and same_card:
		close_card_detail()
		return
	close_card_detail()
	_card_detail_card_id = card_id
	_card_detail_card_uid = card_uid
	_sync_card_selection_visuals(card_uid, card_id)
	# Card-info timings fire when the detail panel opens.
	# [SRC: GameController.c:4714 -> OnCardInfoOpen; CardInfoNewController.c:601
	#       -> OnCardInfoOpenEnd on close; report 6 A5]
	if _state != null and _state.has_method("trigger_events"):
		_state.trigger_events("open_card_info", {"card": card_id, "card_uid": card_uid})
	# CardInfoNew source panel (2510x1077 on the 3840x2160 canvas) as built by
	# ui/card_info_view.gd; geometry from docs/ui_layout/CardInfoNew.md.
	# [SRC: CardInfoNew.prefab + CardInfoNewController.c Show 0x537000]
	if _card_info_view == null or not is_instance_valid(_card_info_view):
		_card_info_view = CardInfoViewScript.new()
		_card_info_view.name = "CardDetailOverlay"
		_card_info_view.z_index = OVERLAY_LAYER_Z + 1
		_card_info_view.setup(_state, _db)
		_card_info_view.equipment_drop_allowed = _can_drop_equipment
		_card_info_view.equipment_dropped.connect(_on_equipment_dropped)
		if _source_overlay_layer != null:
			_source_overlay_layer.add_child(_card_info_view)
		else:
			add_child(_card_info_view)
		if not _card_info_view.closed.is_connected(close_card_detail):
			_card_info_view.closed.connect(close_card_detail)
	# CardInfoNew overlays the desk content while the persistent Next Round
	# chrome remains visible in the source scene. Lock its action, but do not
	# hide the clock art or its label behind the detail panel.
	set_world_scene_blocker("card_detail", true, false, true)
	_card_info_view.show_card(card, card_uid)
	_apply_layout()
	_apply_layout()


func close_card_detail() -> void:
	if _card_info_view == null or not is_instance_valid(_card_info_view):
		set_world_scene_blocker("card_detail", false)
		_card_detail_card_id = 0
		_card_detail_card_uid = 0
		_sync_card_selection_visuals()
		return
	# [SRC: CardInfoNewController.c:601 -> OnCardInfoOpenEnd; report 6 A5]
	if _state != null and _state.has_method("trigger_events"):
		_state.trigger_events("open_card_info_end", {
			"card": _card_detail_card_id, "card_uid": _card_detail_card_uid,
		})
	var old_view = _card_info_view
	_card_info_view = null
	_card_detail_card_id = 0
	_card_detail_card_uid = 0
	_sync_card_selection_visuals()
	if old_view.get_parent() != null:
		old_view.get_parent().remove_child(old_view)
	set_world_scene_blocker("card_detail", false)
	old_view.queue_free()


func _sync_card_selection_visuals(selected_uid: int = 0, selected_id: int = 0) -> void:
	if _card_items == null or not is_instance_valid(_card_items):
		return
	for child in _card_items.get_children():
		if not (child is CardWidget) or child.is_queued_for_deletion():
			continue
		var widget := child as CardWidget
		var matches := selected_uid > 0 and widget.card_uid == selected_uid
		if selected_uid <= 0 and selected_id > 0:
			matches = widget.card_id == selected_id
		widget.set_selected(matches)


func focus_qualified_hand(validator: Callable) -> void:
	if _card_items == null or not validator.is_valid():
		return
	var focused := false
	for child in _card_items.get_children():
		if not (child is CardWidget) or child.is_queued_for_deletion():
			continue
		var matches: bool = validator.call(_state.card_data_for(child.card_uid, _db))
		# [SRC: HandCardSortByCondition 0x5515a0 resets/flags every card's
		# Flash controller; select_first=1 from CardSlotController selects
		# only the first match, not every matching card.]
		child.set_candidate_highlight(matches)
		child.set_selected(matches and not focused)
		if matches and not focused:
			child.focus_mode = Control.FOCUS_ALL
			child.grab_focus()
			focused = true
	_layout_hand_cards()


func clear_hand_candidate_highlights() -> void:
	if _card_items == null:
		return
	for child in _card_items.get_children():
		if child is CardWidget and not child.is_queued_for_deletion():
			child.reset_candidate_scale()
			child.set_selected(child.card_uid == _card_detail_card_uid, false)
	_layout_hand_cards()
