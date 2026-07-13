extends Control

## Top-level game controller. Manages menu -> game -> rite flow, owns the
## GameState/ConfigDB/RNG, and wires signals between screens.

const MainMenu = preload("res://ui/main_menu.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const RiteView = preload("res://ui/rite_view.gd")
const RiteSelector = preload("res://ui/rite_selector.gd")

var db: ConfigDB
var state: GameState
var rng: GameRNG
var _current: Control
var _game_screen: Control
var _rite_overlay: Control
var _menu_overlay: Control
var _user_archive_overlay: Control
var _user_archive_name_input: LineEdit
var _current_rite_id := 0
var _current_rite_uid := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = FaustTheme.get_theme()
	db = ConfigDB.new()
	db.load_all()
	rng = GameRNG.new()
	_show_menu()


func _show_menu() -> void:
	_clear_current()
	_game_screen = null
	var menu := MainMenu.new()
	menu.setup(db)
	menu.difficulty_selected.connect(_on_difficulty_selected)
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


func _on_difficulty_selected(index: int) -> void:
	_start_new_run(index, false)


func _on_test_start_requested(index: int) -> void:
	_start_new_run(index, true)


func _start_new_run(index: int, use_test_cards: bool) -> void:
	db.set_test_starting_cards_enabled(use_test_cards)
	state = GameState.new()
	state.setup_new_run(db, index, rng)
	db.set_test_starting_cards_enabled(false)
	RoundLoop.start_auto_begin_rites(state, db)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	_show_game()


func _show_game() -> void:
	_clear_current()
	if state != null and db != null:
		RoundLoop.start_auto_begin_rites(state, db)
	var gs := GameScreen.new()
	gs.setup(state, db, rng)
	gs.open_rite.connect(_on_open_rite)
	gs.open_rite_instance.connect(_on_open_rite_instance)
	gs.advance_pressed.connect(_on_advance)
	gs.redraw_pressed.connect(_on_redraw)
	gs.open_rite_selector.connect(_on_open_rite_selector)
	gs.menu_pressed.connect(_on_menu_pressed)
	gs.game_over_requested.connect(_show_game_over)
	add_child(gs)
	_current = gs
	_game_screen = gs
	gs.refresh()


func _on_open_rite_selector(location_filter: String = "") -> void:
	# Count via the static filter to avoid instantiating a RiteSelector node
	# just to probe (Nodes are not GC'd, so a probe instance would leak).
	var open_uids := RiteSelector.filter_open_rite_instance_uids(db, state, rng, location_filter)
	if open_uids.size() == 1:
		_on_open_rite_instance(int(open_uids[0]))
		return
	if open_uids.is_empty():
		if _game_screen != null and _game_screen.has_method("set_log"):
			_game_screen.set_log("该地点尚未开放。")
		return
	_clear_current()
	var sel := RiteSelector.new()
	sel.setup(db, state, rng, location_filter)
	sel.rite_chosen_instance.connect(_on_open_rite_instance)
	sel.closed.connect(_show_game)
	add_child(sel)
	_current = sel


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
	panel.custom_minimum_size = Vector2(260, 330)
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style(FaustTheme.GOLD))
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


func _on_save_from_menu() -> void:
	var ok := SaveSystem.save(state)
	_close_game_menu()
	if _current and _current.has_method("set_log"):
		_current.set_log("已保存。" if ok else "保存失败。")


func _show_user_archive_overlay() -> void:
	_close_game_menu()
	_close_user_archive_overlay()
	_user_archive_overlay = Control.new()
	_user_archive_overlay.name = "UserArchiveOverlay"
	_user_archive_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_user_archive_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.56)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	panel.add_theme_stylebox_override("panel", FaustTheme.card_style(FaustTheme.GOLD))
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
	if _menu_overlay == null:
		return
	_menu_overlay.queue_free()
	_menu_overlay = null


func _close_user_archive_overlay() -> void:
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
	var result := RoundLoop.start_round_if_no_sudan(state, db, rng)
	if _game_screen != null:
		_game_screen.refresh()
	if not result.get("new_round", false):
		return
	if _rite_overlay and _rite_overlay.has_method("set_log"):
		_rite_overlay.set_log(_round_result_log(result))


func _round_result_log(result: Dictionary) -> String:
	var log_text := "—— 第 %d 回合开始 ——" % state.round_number
	if int(result.get("drawn_sudan", -1)) >= 0:
		var dec = SudanCards.decode(int(result.drawn_sudan))
		log_text += "\n新苏丹卡: %s%s" % [dec.rank, dec.action]
	if not result.get("auto_rites", []).is_empty():
		log_text += "\n自动开启仪式: %d 个" % result.auto_rites.size()
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
	var new_id := RoundLoop.use_redraw(state, rng, db)
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
	_close_user_archive_overlay()
	_close_rite_overlay()
	if _current:
		_current.queue_free()
		_current = null


func _close_rite_overlay() -> void:
	if _rite_overlay == null:
		return
	_rite_overlay.queue_free()
	_rite_overlay = null
