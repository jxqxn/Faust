extends Control

## Top-level game controller. Manages menu -> game -> rite flow, owns the
## GameState/ConfigDB/RNG, and wires signals between screens.

const MainMenu = preload("res://ui/main_menu.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const RiteView = preload("res://ui/rite_view.gd")
const RiteSelector = preload("res://ui/rite_selector.gd")
const GLOBAL_MODAL_Z := 1000

# Transitional compat layer: screens not yet re-emitted in the original
# 3840x2160 canvas space still lay out in the old 1280x800 mockup space.
# They are uniformly scaled to fill the design height and centered; every
# migrated screen (main menu first) attaches to the root instead.
# Kill criterion: all ui/*.gd screens re-emitted from docs/ui_layout manifests.
const LEGACY_DESIGN := Vector2(1280, 800)
const DESIGN_SPACE := Vector2(3840, 2160)

var db: ConfigDB
var state: GameState
var rng: GameRNG
var _current: Control
var _game_screen: Control
var _rite_overlay: Control
var _rite_selector_overlay: Control
var _menu_overlay: Control
var _user_archive_overlay: Control
var _legacy_root: Control
var _user_archive_name_input: LineEdit
var _current_rite_id := 0
var _current_rite_uid := 0
var _audio: GameAudio


func _legacy_layer() -> Control:
	if _legacy_root == null or not is_instance_valid(_legacy_root):
		_legacy_root = Control.new()
		_legacy_root.name = "LegacyLayer"
		_legacy_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var scale_factor := DESIGN_SPACE.y / LEGACY_DESIGN.y
		_legacy_root.size = LEGACY_DESIGN
		_legacy_root.scale = Vector2(scale_factor, scale_factor)
		_legacy_root.position = (DESIGN_SPACE - LEGACY_DESIGN * scale_factor) * 0.5
		add_child(_legacy_root)
	return _legacy_root


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = FaustTheme.get_theme()
	db = ConfigDB.new()
	db.load_all()
	rng = GameRNG.new()
	_audio = GameAudio.new()
	_audio.name = "GameAudio"
	add_child(_audio)
	_show_menu()


func _show_menu() -> void:
	_clear_current()
	_game_screen = null
	var menu := MainMenu.new()
	menu.setup(db)
	menu.new_game_pressed.connect(_on_new_game_pressed)
	menu.continue_pressed.connect(_on_continue)
	menu.user_archive_load_requested.connect(_on_user_archive_load)
	menu.user_archive_delete_requested.connect(_on_user_archive_delete)
	menu.test_start_requested.connect(_on_test_start_requested)
	add_child(menu)
	_current = menu


func _on_continue() -> void:
	var loaded = SaveSystem.load_continue(db)
	if loaded == null:
		_show_menu()
		return
	state = loaded
	_show_game()


func _on_user_archive_load(index: int) -> void:
	var loaded = SaveSystem.load_user_archive(db, index)
	if loaded == null:
		_show_menu()
		return
	state = loaded
	_show_game()


func _on_user_archive_delete(index: int) -> void:
	SaveSystem.delete_user_archive(index)
	_show_menu()


func _on_new_game_pressed() -> void:
	# The pre-pick difficulty is the default slot; the opening show's
	# SetDifficulty op (event 5310006) applies the narrator the player picks.
	_start_new_run(0, false)


func _on_test_start_requested(index: int) -> void:
	_start_new_run(index, true)


func _start_new_run(index: int, use_test_cards: bool) -> void:
	db.set_test_starting_cards_enabled(use_test_cards)
	state = GameState.new()
	# Bind the disk-backed global domain so the new-game quota reset persists.
	state.global_state = GlobalState.load_default()
	# Menu new games defer difficulty resources to the intro narrator pick
	# (the original grants nothing before the pick); test starts chose the
	# difficulty directly and take its resources here.
	state.setup_new_run(db, index, rng, use_test_cards)
	db.set_test_starting_cards_enabled(false)
	# The original startup chain increments Player.round to 1, fires
	# OnRoundBeginBa, then runs auto-begin and the first Sultan draw in that
	# order. Opening round_begin_ba events (intro chain) display from here.
	# [SRC: GameController.__c__DisplayClass141_0.c @ <Start>b__5 (0x56f9c0)
	#       lines 120-150]
	state.trigger_events("round_begin_ba", {"round": state.round_number})
	RoundLoop.start_auto_begin_rites(state, db)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	_show_game()


func _show_game() -> void:
	_clear_current()
	if state != null and db != null:
		RoundLoop.start_auto_begin_rites(state, db)
	_audio.play_bgm("main")
	var gs := GameScreen.new()
	gs.setup(state, db, rng)
	gs.open_rite.connect(_on_open_rite)
	gs.open_rite_instance.connect(_on_open_rite_instance)
	gs.advance_pressed.connect(_on_advance)
	gs.redraw_pressed.connect(_on_redraw)
	gs.back_to_prev_pressed.connect(_on_back_to_prev)
	gs.open_rite_selector.connect(_on_open_rite_selector)
	gs.menu_pressed.connect(_on_menu_pressed)
	gs.game_over_requested.connect(_show_game_over)
	add_child(gs)
	_current = gs
	_game_screen = gs
	gs.refresh()


## Visual-capture hooks used by the managed UI review tool. Each enters a
## normal player-reachable presentation state.
func _mcp_capture_situation_desk() -> void:
	if state == null:
		_on_new_game_pressed()
	elif _game_screen == null:
		_show_game()
	if _game_screen != null and _game_screen.has_method("return_to_situation_desk"):
		_game_screen.return_to_situation_desk()


func _mcp_capture_site_actions() -> void:
	_mcp_capture_situation_desk()
	# Use the normal site-button path so the capture includes the same focus
	# state a player sees, rather than opening a detached selector directly.
	var home_site: Button = null
	if _game_screen != null:
		home_site = _game_screen.get_node_or_null("SituationDesk/SiteHome") as Button
	if home_site != null and not home_site.disabled:
		home_site.pressed.emit()
	else:
		_on_open_rite_selector("自宅")


func _mcp_capture_tabletop_market_actions() -> void:
	_mcp_capture_situation_desk()
	var market_site: Button = null
	if _game_screen != null:
		market_site = _game_screen.get_node_or_null("SituationDesk/SiteMarket") as Button
	if market_site == null or market_site.disabled:
		_mcp_capture_site_actions()
		return
	market_site.pressed.emit()


func _mcp_capture_compact_prompt() -> void:
	if state == null:
		_on_new_game_pressed()
	elif _game_screen == null:
		_show_game()
	if state == null or _game_screen == null:
		return
	state.queue_prompt({
		"id": "capture.compact_prompt",
		"title": "一闪而过的念头",
		"text": "也许趁机把房子装修一番，可以满足眷属的需求……",
	})
	_game_screen.refresh()


func _on_open_rite_selector(location_filter: String = "") -> void:
	var availability_rng = rng.duplicate_stream() if rng != null else null
	var open_uids := RiteSelector.filter_open_rite_instance_uids(
		db, state, availability_rng, location_filter
	)
	if open_uids.is_empty():
		if _game_screen != null and _game_screen.has_method("set_log"):
			_game_screen.set_log("该地点当前没有可处理行动。")
		return
	_close_rite_selector_overlay(false)
	var sel := RiteSelector.new()
	sel.setup(db, state, rng, location_filter)
	sel.set_overlay_mode(true)
	if _game_screen != null and _game_screen.has_method("site_action_anchor"):
		sel.set_overlay_anchor(_game_screen.site_action_anchor(location_filter))
	if _game_screen != null and _game_screen.has_method("site_action_menu_bounds"):
		sel.set_overlay_safe_rect(_game_screen.site_action_menu_bounds())
	sel.rite_chosen_instance.connect(_on_rite_selector_choice)
	sel.closed.connect(_close_rite_selector_overlay)
	if _game_screen != null and _game_screen.has_method("add_overlay"):
		_game_screen.add_overlay(sel)
		# Unlike a full rite view, this compact menu pauses the entire desk. Its
		# backdrop must therefore sit above the persistent rail, actions, and menu
		# instead of leaving those controls visually floating in front of it.
		sel.z_index = GameScreen.PERSISTENT_CONTROL_Z + 1
	else:
		_legacy_layer().add_child(sel)
	_rite_selector_overlay = sel
	# A site menu preserves the desk as a dimmed snapshot. Its own overlay stays
	# live, while every underlying persistent control is locked and paused.
	_set_world_scene_blocker("rite_selector", true, false, true, true)


func _on_rite_selector_choice(rite_uid: int) -> void:
	_close_rite_selector_overlay()
	_on_open_rite_instance(rite_uid)


func _on_open_rite(rite_id: int) -> void:
	var instance = state.find_rite_instance_by_id(rite_id) if state != null and state.has_method("find_rite_instance_by_id") else null
	if instance == null:
		return
	_on_open_rite_instance(instance.uid)


func _on_open_rite_instance(rite_uid: int) -> void:
	var instance = state.get_rite_instance(rite_uid) if state != null and state.has_method("get_rite_instance") else null
	if instance == null:
		return
	if _game_screen == null:
		_show_game()
	_close_rite_selector_overlay()
	_close_rite_overlay()
	_current_rite_uid = instance.uid
	_current_rite_id = instance.id
	# Fire rite-start event triggers for the opening rite.
	# [SRC: RitePanelController.__c__DisplayClass34_0.c:16 -> OnRiteStart]
	if state != null:
		state.trigger_events("rite_start", {"rite": instance.id})
	var rv := RiteView.new()
	rv.setup(state, db, rng, instance.id, instance.uid)
	rv.closed.connect(_close_rite_overlay)
	rv.resolved.connect(_after_rite_resolution)
	rv.game_over_requested.connect(_show_game_over)
	if _game_screen != null and _game_screen.has_method("add_overlay"):
		_game_screen.add_overlay(rv)
	else:
		_legacy_layer().add_child(rv)
	_rite_overlay = rv
	_set_world_scene_blocker("rite", true)


func _on_menu_pressed() -> void:
	if _menu_overlay != null:
		_close_game_menu()
		return
	_show_game_menu()


func _show_game_menu() -> void:
	if _current == null:
		return
	_set_world_scene_blocker("game_menu", true, false)
	_set_gameplay_presentation_frozen(true)
	_menu_overlay = Control.new()
	_menu_overlay.name = "GameMenuOverlay"
	_menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_overlay.z_index = GLOBAL_MODAL_Z
	_legacy_layer().add_child(_menu_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.48)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_overlay.add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "GameMenuPanel"
	panel.custom_minimum_size = Vector2(260, 330)
	panel.add_theme_stylebox_override("panel", _menu_panel_style())
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -130
	panel.offset_top = -165
	panel.offset_right = 130
	panel.offset_bottom = 165
	_menu_overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.text = "菜单"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	box.add_child(title)

	var resume := _menu_button("继续")
	resume.name = "ResumeGameButton"
	resume.pressed.connect(_close_game_menu)
	box.add_child(resume)

	var save := _menu_button("保存")
	save.name = "SaveGameButton"
	save.pressed.connect(_on_save_from_menu)
	box.add_child(save)

	var save_archive := _menu_button("保存为存档")
	save_archive.name = "SaveUserArchiveButton"
	save_archive.pressed.connect(_show_user_archive_overlay)
	box.add_child(save_archive)

	var title_screen := _menu_button("返回标题")
	title_screen.name = "ReturnTitleButton"
	title_screen.pressed.connect(_show_menu)
	box.add_child(title_screen)


func _menu_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(220, 42)
	return button


## Texture-first: the original common-operation menu surface.
## [SRC: GameScene.unity CommonContent -> common_operation_bg;
##       Texture2D/common_operation_bg.png 1148x1124]
func _menu_panel_style() -> StyleBox:
	var art_path := "res://assets/original/ui/common_operation_bg.png"
	if ResourceLoader.exists(art_path):
		var tex := load(art_path) as Texture2D
		if tex != null:
			var style := StyleBoxTexture.new()
			style.texture = tex
			style.texture_margin_left = 200
			style.texture_margin_right = 200
			style.texture_margin_top = 200
			style.texture_margin_bottom = 200
			style.content_margin_left = 210
			style.content_margin_right = 210
			style.content_margin_top = 210
			style.content_margin_bottom = 210
			return style
	return FaustTheme.card_style(FaustTheme.GOLD)


func _on_save_from_menu() -> void:
	var ok := SaveSystem.save(state)
	_close_game_menu()
	if _current and _current.has_method("set_log"):
		_current.set_log("已保存。" if ok else "保存失败。")


func _show_user_archive_overlay() -> void:
	_close_game_menu()
	_close_user_archive_overlay()
	_set_world_scene_blocker("user_archive", true, false)
	_set_gameplay_presentation_frozen(true)
	_user_archive_overlay = Control.new()
	_user_archive_overlay.name = "UserArchiveOverlay"
	_user_archive_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_user_archive_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_user_archive_overlay.z_index = GLOBAL_MODAL_Z
	_legacy_layer().add_child(_user_archive_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.56)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_user_archive_overlay.add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "UserArchivePanel"
	panel.custom_minimum_size = Vector2(720, 560)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -360
	panel.offset_top = -280
	panel.offset_right = 360
	panel.offset_bottom = 280
	panel.add_theme_stylebox_override("panel", _menu_panel_style())
	_user_archive_overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "保存为存档"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	box.add_child(title)

	var create_row := HBoxContainer.new()
	create_row.add_theme_constant_override("separation", 8)
	box.add_child(create_row)
	_user_archive_name_input = LineEdit.new()
	_user_archive_name_input.name = "UserArchiveNameInput"
	_user_archive_name_input.placeholder_text = "存档名称"
	_user_archive_name_input.text = "第 %d 天" % state.day
	_user_archive_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_row.add_child(_user_archive_name_input)
	var create := Button.new()
	create.name = "SaveNewUserArchiveButton"
	create.text = "新建存档"
	create.custom_minimum_size = Vector2(110, 42)
	var new_index := SaveSystem.next_user_archive_index()
	create.disabled = new_index < 0
	create.tooltip_text = "存档槽已满" if new_index < 0 else ""
	create.pressed.connect(_save_user_archive.bind(new_index, ""))
	create_row.add_child(create)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "UserArchiveSaveList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for archive in SaveSystem.list_user_archives(db):
		list.add_child(_make_user_archive_save_row(archive))

	var back := Button.new()
	back.name = "CloseUserArchiveButton"
	back.text = "返回"
	back.custom_minimum_size = Vector2(0, 42)
	back.pressed.connect(_close_user_archive_overlay)
	box.add_child(back)


func _make_user_archive_save_row(archive: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "UserArchiveSaveRow_%d" % int(archive.get("index", -1))
	row.add_theme_constant_override("separation", 8)
	var summary := Label.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.text = "%s  |  Day %d / Round %d" % [
		str(archive.get("name", "Unnamed archive")),
		int(archive.get("day", archive.get("live_days", 1))),
		int(archive.get("round_number", 1)),
	]
	row.add_child(summary)
	var overwrite := Button.new()
	overwrite.name = "OverwriteUserArchiveButton_%d" % int(archive.get("index", -1))
	overwrite.text = "覆盖"
	overwrite.custom_minimum_size = Vector2(72, 42)
	overwrite.pressed.connect(_confirm_overwrite_user_archive.bind(int(archive.get("index", -1)), str(archive.get("name", ""))))
	row.add_child(overwrite)
	var delete := Button.new()
	delete.name = "DeleteUserArchiveButton_%d" % int(archive.get("index", -1))
	delete.text = "删除"
	delete.tooltip_text = "删除存档"
	delete.custom_minimum_size = Vector2(72, 42)
	delete.pressed.connect(_confirm_delete_user_archive.bind(int(archive.get("index", -1))))
	row.add_child(delete)
	return row


func _confirm_overwrite_user_archive(index: int, existing_name: String) -> void:
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "确定覆盖这个存档吗？"
	_user_archive_overlay.add_child(confirm)
	confirm.confirmed.connect(_save_user_archive.bind(index, existing_name))
	confirm.canceled.connect(confirm.queue_free)
	confirm.confirmed.connect(confirm.queue_free)
	confirm.popup_centered()


func _save_user_archive(index: int, fallback_name: String) -> void:
	if index < 0 or state == null:
		return
	var name := _user_archive_name_input.text if _user_archive_name_input != null else ""
	if name.strip_edges().is_empty():
		name = fallback_name
	var ok := SaveSystem.save_user_archive(state, index, name)
	_close_user_archive_overlay()
	if _current and _current.has_method("set_log"):
		_current.set_log("已保存为存档" if ok else "存档保存失败")


func _confirm_delete_user_archive(index: int) -> void:
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "确定删除这个存档吗？此操作无法撤销。"
	_user_archive_overlay.add_child(confirm)
	confirm.confirmed.connect(func():
		SaveSystem.delete_user_archive(index)
		_close_user_archive_overlay()
		_show_user_archive_overlay()
	)
	confirm.canceled.connect(confirm.queue_free)
	confirm.confirmed.connect(confirm.queue_free)
	confirm.popup_centered()


func _close_game_menu() -> void:
	_set_gameplay_presentation_frozen(false)
	_set_world_scene_blocker("game_menu", false, false)
	if _menu_overlay == null:
		return
	_menu_overlay.queue_free()
	_menu_overlay = null


func _close_user_archive_overlay() -> void:
	_set_gameplay_presentation_frozen(false)
	_set_world_scene_blocker("user_archive", false, false)
	if _user_archive_overlay == null:
		return
	_user_archive_overlay.queue_free()
	_user_archive_overlay = null
	_user_archive_name_input = null


func _after_rite_resolution() -> void:
	# Fire rite-end event triggers for the just-resolved rite.
	# [SRC: RiteResultPanelController.c:1289 -> OnRiteEnd]
	if state != null and _current_rite_id != 0:
		state.trigger_events("rite_end", {"rite": _current_rite_id})
	# No same-day round start: consuming a Sultan card does not draw the next
	# one until the next day boundary (TryGenSudanCard lives in OnNextRound).
	if _game_screen != null:
		_game_screen.refresh()


func _on_advance() -> void:
	_audio.play("button-next-day.ogg")
	var result := RoundLoop.advance_day(state, db, rng)
	var log_text := "第 %d 天。" % state.day
	if result.game_over:
		log_text += "\n☠ 一张苏丹卡到期未完成！游戏结束。"
	if not result.expired.is_empty():
		for cid in result.expired:
			var dec = SudanCards.decode(int(cid))
			log_text += "\n过期: %s%s" % [dec.rank, dec.action]
	if result.get("new_round", false):
		log_text += "\n—— 第 %d 回合开始 ——" % state.round_number
		if int(result.get("drawn_sudan", -1)) >= 0:
			var dec2 = SudanCards.decode(int(result.drawn_sudan))
			log_text += "\n新苏丹卡: %s%s" % [dec2.rank, dec2.action]
	if not result.auto_rites.is_empty():
		log_text += "\n自动开启仪式: %d 个" % result.auto_rites.size()
	if _current and _current.has_method("set_log"):
		_current.set_log(log_text)
		_current.refresh()
	if result.game_over:
		call_deferred("_show_game_over")


func _show_game_over() -> void:
	# GameEnd events see the ending id before the run is torn down. The
	# deadline ending id (12) matches vanish.over of Sultan cards; other
	# paths pass 0 until over-reason plumbing lands.
	# [SRC: GameController.c:2868 -> OnGameEnd; CardNode.vanish.over]
	if state != null and state.event_runtime != null:
		state.trigger_events("game_end", {"ending": state.over_reason})
	# The original keeps the continue save at its last SaveRoundEnd point so
	# the player can retry the fatal round; DoGameOver only reads the reason.
	# [SRC: GameController.c @ DoGameOver (0x54dbd0); report 7 A6]
	_clear_current()
	var go := preload("res://ui/game_over.gd").new()
	go.setup(state, db)
	go.restart.connect(_show_menu)
	_legacy_layer().add_child(go)
	_current = go


func _on_redraw() -> void:
	_audio.play("button-confirm.ogg")
	var new_id := RoundLoop.use_redraw(state, rng, db)
	var log_text := ""
	if new_id < 0:
		log_text = "无法重抽（重抽次数耗尽或牌堆为空）。"
	else:
		var dec = SudanCards.decode(new_id)
		log_text = "重抽苏丹卡: %s%s" % [dec.rank, dec.action]
	# [SRC: WizardController.c:1285 -> OnSudanRedrawStart; report 6 A5]
	if state != null and state.event_runtime != null:
		state.trigger_events("sudan_redraw_start", {})
	if _current and _current.has_method("set_log"):
		_current.set_log(log_text)
	_current.refresh()


## Back to the previous round's end: consumes one back-to-prev charge (9999
## means free), restores the round_end snapshot, and reopens the retried
## round. [SRC: GameController.c @ OnPrevRound (0x554f80); report 7 A1]
func _on_back_to_prev() -> void:
	if state == null:
		return
	var log_text := ""
	if RoundLoop.back_to_prev_round_end(state, db):
		log_text = "已回到上一回合结束（第 %d 回合）。剩余回退次数: %s" % [
			state.round_number,
			"∞" if state.back_to_prev_left >= 9999 else str(state.back_to_prev_left),
		]
	else:
		log_text = "无法回退（次数耗尽、回合过早或没有当日快照）。"
	if _game_screen != null:
		_game_screen.refresh()
	if _current and _current.has_method("set_log"):
		_current.set_log(log_text)


func _clear_current() -> void:
	_close_game_menu()
	_close_user_archive_overlay()
	_close_rite_selector_overlay()
	_close_rite_overlay()
	if _current:
		_current.queue_free()
		_current = null


func _close_rite_overlay() -> void:
	_set_world_scene_blocker("rite", false)
	if _rite_overlay == null:
		return
	_rite_overlay.queue_free()
	_rite_overlay = null


func _close_rite_selector_overlay(clear_focus: bool = true) -> void:
	_set_world_scene_blocker("rite_selector", false)
	if _rite_selector_overlay != null:
		_rite_selector_overlay.queue_free()
		_rite_selector_overlay = null
	if (
		clear_focus
		and _game_screen != null
		and _game_screen.has_method("clear_site_focus")
	):
		_game_screen.clear_site_focus()


func _set_world_scene_blocker(
	source: String,
	blocking: bool,
	hide_chrome: bool = true,
	lock_persistent_actions: bool = false,
	pause_underlying_presentation: bool = false
) -> void:
	if _game_screen != null and _game_screen.has_method("set_world_scene_blocker"):
		_game_screen.set_world_scene_blocker(
			source,
			blocking,
			hide_chrome,
			lock_persistent_actions,
			pause_underlying_presentation
		)


func _set_gameplay_presentation_frozen(frozen: bool) -> void:
	if _game_screen != null and _game_screen.has_method("set_presentation_frozen"):
		_game_screen.set_presentation_frozen(frozen)
