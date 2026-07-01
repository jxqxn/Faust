extends Control

## Top-level game controller. Manages menu -> game -> rite flow, owns the
## GameState/ConfigDB/RNG, and wires signals between screens.

const FaustTheme = preload("res://ui/theme.gd")
const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
const GameRNG = preload("res://core/rng.gd")
const RoundLoop = preload("res://sim/round_loop.gd")
const SudanCards = preload("res://sim/sudan_cards.gd")
const MainMenu = preload("res://ui/main_menu.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const RiteView = preload("res://ui/rite_view.gd")
const RiteSelector = preload("res://ui/rite_selector.gd")
const SaveSystem = preload("res://sim/save_system.gd")

var db: ConfigDB
var state: GameState
var rng: GameRNG
var _current: Control
var _game_screen: Control
var _rite_overlay: Control
var _menu_overlay: Control


func _ready() -> void:
	theme = FaustTheme.get_theme()
	db = ConfigDB.new()
	db.load_all()
	rng = GameRNG.new()
	_show_menu()


func _mcp_capture_governance_rite() -> void:
	state = GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.start_auto_begin_rites(state, db)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	_on_open_rite(5000001)


func _mcp_capture_main_desktop() -> void:
	state = GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.start_auto_begin_rites(state, db)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	_show_game()


func _mcp_capture_card_detail() -> void:
	state = GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.start_auto_begin_rites(state, db)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	_show_game()
	await get_tree().process_frame
	if _game_screen != null and _game_screen.has_method("show_card_detail") and not state.hand.is_empty():
		_game_screen.show_card_detail(int(state.hand[0]))


func _show_menu() -> void:
	_clear_current()
	_game_screen = null
	var menu := MainMenu.new()
	menu.difficulty_selected.connect(_on_difficulty_selected)
	menu.continue_pressed.connect(_on_continue)
	add_child(menu)
	_current = menu


func _on_continue() -> void:
	var loaded = SaveSystem.load(db)
	if loaded == null:
		_show_menu()
		return
	state = loaded
	_show_game()


func _on_difficulty_selected(index: int) -> void:
	state = GameState.new()
	state.setup_new_run(db, index, rng)
	RoundLoop.start_auto_begin_rites(state, db)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	_show_game()


func _show_game() -> void:
	_clear_current()
	var gs := GameScreen.new()
	gs.setup(state, db, rng)
	gs.open_rite.connect(_on_open_rite)
	gs.advance_pressed.connect(_on_advance)
	gs.redraw_pressed.connect(_on_redraw)
	gs.open_rite_selector.connect(_on_open_rite_selector)
	gs.menu_pressed.connect(_on_menu_pressed)
	# Autosave on entering the game.
	SaveSystem.save(state)
	add_child(gs)
	_current = gs
	_game_screen = gs
	gs.refresh()


func _on_open_rite_selector() -> void:
	_clear_current()
	var sel := RiteSelector.new()
	sel.setup(db, state, rng)
	sel.rite_chosen.connect(_on_open_rite)
	sel.closed.connect(_show_game)
	add_child(sel)
	_current = sel


func _on_open_rite(rite_id: int) -> void:
	if _game_screen == null:
		_show_game()
	_close_rite_overlay()
	var rv := RiteView.new()
	rv.setup(state, db, rng, rite_id)
	rv.closed.connect(_close_rite_overlay)
	rv.resolved.connect(_after_rite_resolution)
	if _game_screen != null and _game_screen.has_method("add_overlay"):
		_game_screen.add_overlay(rv)
	else:
		add_child(rv)
	_rite_overlay = rv


func _on_menu_pressed() -> void:
	if _menu_overlay != null:
		_close_game_menu()
		return
	_show_game_menu()


func _show_game_menu() -> void:
	if _current == null:
		return
	_menu_overlay = Control.new()
	_menu_overlay.name = "GameMenuOverlay"
	_menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_menu_overlay)
	move_child(_menu_overlay, get_child_count() - 1)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.48)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "GameMenuPanel"
	panel.custom_minimum_size = Vector2(260, 220)
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style(FaustTheme.GOLD))
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -130
	panel.offset_top = -110
	panel.offset_right = 130
	panel.offset_bottom = 110
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

	var title_screen := _menu_button("返回标题")
	title_screen.name = "ReturnTitleButton"
	title_screen.pressed.connect(_show_menu)
	box.add_child(title_screen)


func _menu_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(220, 42)
	return button


func _on_save_from_menu() -> void:
	var ok := SaveSystem.save(state)
	_close_game_menu()
	if _current and _current.has_method("set_log"):
		_current.set_log("已保存。" if ok else "保存失败。")


func _close_game_menu() -> void:
	if _menu_overlay == null:
		return
	_menu_overlay.queue_free()
	_menu_overlay = null


func _after_rite_resolution() -> void:
	var result := RoundLoop.start_round_if_no_sudan(state, db, rng)
	if _game_screen != null:
		_game_screen.refresh()
	if not result.get("new_round", false):
		return
	if _rite_overlay and _rite_overlay.has_method("set_log"):
		_rite_overlay.set_log(_round_result_log(result))


func _round_result_log(result: Dictionary) -> String:
	var log_text := "Round %d begins" % state.round_number
	if int(result.get("drawn_sudan", -1)) >= 0:
		var dec = SudanCards.decode(int(result.drawn_sudan))
		log_text += "\nNew sudan card: %s%s" % [dec.rank, dec.action]
	if not result.get("auto_rites", []).is_empty():
		log_text += "\nAuto-begin rites: %d" % result.auto_rites.size()
	return log_text


func _on_advance() -> void:
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
	SaveSystem.delete_save()
	_clear_current()
	var go := preload("res://ui/game_over.gd").new()
	go.setup(state, db)
	go.restart.connect(_show_menu)
	add_child(go)
	_current = go


func _on_redraw() -> void:
	var new_id := RoundLoop.use_redraw(state, rng)
	var log_text := ""
	if new_id < 0:
		log_text = "无法重抽（重抽次数耗尽或牌堆为空）。"
	else:
		var dec = SudanCards.decode(new_id)
		log_text = "重抽苏丹卡: %s%s" % [dec.rank, dec.action]
	if _current and _current.has_method("set_log"):
		_current.set_log(log_text)
		_current.refresh()


func _clear_current() -> void:
	_close_game_menu()
	_close_rite_overlay()
	if _current:
		_current.queue_free()
		_current = null


func _close_rite_overlay() -> void:
	if _rite_overlay:
		_rite_overlay.queue_free()
		_rite_overlay = null
	if _game_screen:
		_game_screen.refresh()
