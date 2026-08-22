extends Control

## Top-level game controller. Manages menu -> game -> rite flow, owns the
## GameState/ConfigDB/RNG, and wires signals between screens.

const MainMenu = preload("res://ui/main_menu.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const RiteView = preload("res://ui/rite_view.gd")
const ESCGamePanel = preload("res://ui/esc_game_panel.gd")
const SettingsPanel = preload("res://ui/settings_panel.gd")
const UserArchivePanel = preload("res://ui/user_archive_panel.gd")

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
var _menu_overlay: Control
var _settings_overlay: Control
var _user_archive_overlay: Control
var _legacy_root: Control
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
	_mcp_capture_first_map_pin()


func _mcp_capture_tabletop_market_actions() -> void:
	_mcp_capture_situation_desk()
	_mcp_capture_first_map_pin()


func _mcp_capture_first_map_pin() -> void:
	if _game_screen == null:
		return
	var desk := _game_screen.get_node_or_null("SituationDesk")
	if desk == null:
		return
	for child in desk.get_children():
		var pin := child as Button
		if pin != null and str(pin.name).begins_with("RitePin_") and not pin.disabled:
			pin.pressed.emit()
			return


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
	if _game_screen != null and _game_screen.has_method("add_source_overlay"):
		_game_screen.add_source_overlay(rv)
	elif _game_screen != null and _game_screen.has_method("add_overlay"):
		_game_screen.add_overlay(rv)
	else:
		_legacy_layer().add_child(rv)
	_rite_overlay = rv
	# A direct MapController pin replaces the clone-era selector, but opening
	# its rite remains the same modal input boundary: keep chrome visible while
	# the persistent controls and rail are frozen beneath it.
	_set_world_scene_blocker("rite", true, false, true, true)


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
	_menu_overlay = ESCGamePanel.new()
	_menu_overlay.return_requested.connect(_close_game_menu)
	_menu_overlay.end_game_requested.connect(_on_end_game_from_esc)
	_menu_overlay.main_menu_requested.connect(_on_main_menu_from_esc)
	_menu_overlay.settings_requested.connect(_show_settings)
	# ESCPanel is a direct GameScene Prompt child, never a 1280x800 legacy
	# surface. [SRC: GameScene.unity MainUI/Prompt/ESCPanel]
	add_child(_menu_overlay)


func _show_settings() -> void:
	if _settings_overlay != null:
		return
	# ESCGameController.OnSettings calls SettingsController.ShowSettings(false).
	# Keep the ESC panel beneath the source SettingsPanel; closing settings
	# therefore returns directly to the same paused ESC surface.
	_settings_overlay = SettingsPanel.new()
	_settings_overlay.setup(_audio)
	_settings_overlay.closed.connect(_close_settings)
	add_child(_settings_overlay)


func _close_settings() -> void:
	if _settings_overlay == null:
		return
	_settings_overlay.queue_free()
	_settings_overlay = null


func _on_end_game_from_esc() -> void:
	if state == null:
		return
	# [SRC: ESCGameController.c @ OnEndGame (RVA 0x5429f0):
	# Player.success=true; Player.over_reason=0x10; GameController.DoGameOver]
	state.success = true
	state.over_reason = 16
	_show_game_over()


func _on_main_menu_from_esc() -> void:
	# [SRC: ESCGameController.c @ OnMainMenu (RVA 0x542ae0): SavePlayer ->
	# scene transition. Save first even when the title transition later changes.]
	SaveSystem.save(state)
	_show_menu()


func _show_user_archive_overlay() -> void:
	_close_game_menu()
	_close_user_archive_overlay()
	_set_world_scene_blocker("user_archive", true, false)
	_set_gameplay_presentation_frozen(true)
	# UserArchive is a direct full-canvas GameScene prompt, not a LegacyLayer
	# surface. The controller keeps all 50 source slots visible.
	# [SRC: GameScene.unity UserArchive instance; UserArchiveController.Show
	#       (RVA 0x5c9030) binds Datapool.user_archives to its datasource.]
	var panel := UserArchivePanel.new()
	panel.name = "UserArchiveOverlay"
	panel.setup(SaveSystem.list_user_archives(db), true)
	panel.closed.connect(_close_user_archive_overlay)
	panel.save_requested.connect(_save_user_archive)
	panel.rename_requested.connect(_rename_user_archive)
	panel.delete_requested.connect(_delete_user_archive)
	_user_archive_overlay = panel
	add_child(_user_archive_overlay)


func _save_user_archive(index: int, archive_name: String) -> void:
	if state == null:
		return
	var ok := SaveSystem.save_user_archive(state, index, archive_name)
	_close_user_archive_overlay()
	if _current and _current.has_method("set_log"):
		_current.set_log("已保存为存档" if ok else "存档保存失败")


func _rename_user_archive(index: int, archive_name: String) -> void:
	var ok := SaveSystem.update_user_archive(index, archive_name)
	_close_user_archive_overlay()
	if _current and _current.has_method("set_log"):
		_current.set_log("存档名称已修改" if ok else "存档改名失败")


func _delete_user_archive(index: int) -> void:
	var ok := SaveSystem.delete_user_archive(index)
	_close_user_archive_overlay()
	if _current and _current.has_method("set_log"):
		_current.set_log("存档已删除" if ok else "存档删除失败")


func _close_game_menu() -> void:
	_close_settings()
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
	# [SRC: GameScene MainUI/Over is a direct 3840x2160 canvas.]
	add_child(go)
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
