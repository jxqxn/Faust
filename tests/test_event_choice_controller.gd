extends GutTest

const RNG = preload("res://core/rng.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const PromptView = preload("res://ui/event_prompt_view.gd")
var db: ConfigDB


func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()


func _state() -> GameState:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(901))
	state.pending_operations.clear()
	return state


func _screen(state: GameState):
	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	add_child_autofree(stage)
	var screen = GameScreen.new()
	screen.setup(state, db, RNG.new(901))
	stage.add_child(screen)
	return screen


func _node(root: Node, target: String) -> Node:
	return root.find_child(target, true, false)


func test_prompt_mask_clips_runtime_background_without_drawing_black_mask() -> void:
	# PromptNew Full: m_ShowMaskGraphic=0, source border and stretch offsets;
	# PromptControllerBase.Awake 0x589430 creates full/item_bg below FullImage.
	var screen = _screen(_state())
	screen._show_event_overlay({"kind": "prompt", "text": "Mask regression"})
	await wait_process_frames(2)
	var mask := _node(screen, "Full") as NinePatchRect
	assert_not_null(mask)
	assert_eq(mask.clip_children, CanvasItem.CLIP_CHILDREN_ONLY)
	assert_eq(mask.position, Vector2(38, 52))
	assert_eq(mask.size * mask.scale, Vector2(2629, mask.get_parent().size.y - 132), "Full compresses border geometry to the authored runtime rect")
	var background := mask.get_node("RuntimeBackground") as TextureRect
	assert_true(background.texture.resource_path.ends_with("prompt_full_item_bg.png"))
	assert_true(background.size.x > mask.size.x)
	assert_true(background.size.y > mask.size.y)


func test_original_option_waits_for_confirmation_and_allows_reselection() -> void:
	# Original content is the branch oracle; no retyped case payload.
	# [SRC: content/event/5300102.json settlement[0].action;
	# OptionController.Show 0x576b50 / b__0 0x588f00 / OnConfirm 0x576900;
	# dump.cs:321643-321673.]
	var state := _state()
	var event := db.get_event(5300102)
	DeferredEffects.execute_event(event, state, db, RNG.new(901))
	var screen = _screen(state)
	await wait_process_frames(2)
	var group := _node(screen, "OptionGroup")
	var confirm := _node(screen, "EventPromptConfirmButton") as Button
	assert_not_null(confirm)
	if confirm == null:
		return
	assert_true(confirm.disabled, "Show starts without an option")
	assert_eq(confirm.text, "", "source confirm image must not carry a second text overlay")
	var portrait := screen._event_overlay._portrait as TextureRect
	assert_not_null(portrait.texture, "current source option icon reaches the prompt")
	assert_eq(portrait.texture.resource_path, "res://assets/original/cards/2000001.png")
	confirm.pressed.emit()
	assert_eq(state.pending_operation().kind, "choice", "even a direct signal cannot submit an unselected choice")
	var first := group.get_child(0) as Button
	var second := group.get_child(1) as Button
	assert_eq(first.get_node("OptionText").get_parsed_text(), event.settlement[0].action.option.items[0].text)
	assert_eq(second.get_node("OptionText").get_parsed_text(), event.settlement[0].action.option.items[1].text)
	assert_null(_node(screen, "EventPromptTitle"), "internal option id is not a source-authored title")
	var initial_body := _node(screen, "EventPromptBody") as RichTextLabel
	var prefs = preload("res://ui/game_application_settings.gd")
	var styles: Dictionary = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/textstyle.json"))
	assert_eq(initial_body.get_theme_font_size("normal_font_size"), int(styles["@PROMPT_TEXT"].css_size[prefs.font_size]))
	assert_gt(initial_body.get_content_height(), 40, "real glyph layout must use the source-sized text")
	first.pressed.emit()
	second.pressed.emit()
	assert_false(first.button_pressed, "reselection clears the previous toggle")
	assert_true(second.button_pressed)
	assert_false(state.is_event_enabled(5300104))
	assert_false(state.is_event_enabled(5300174), "selection has no branch side effects")
	assert_eq(state.pending_operation().kind, "choice")
	screen.refresh()
	await wait_process_frames(2)
	assert_same(_node(screen, "EventPromptConfirmButton"), confirm, "refresh retains the active occurrence")
	assert_true(second.button_pressed)
	confirm.pressed.emit()
	confirm.pressed.emit()
	await wait_process_frames(2)
	assert_false(state.is_event_enabled(5300104), "unselected branch stays untouched")
	assert_false(state.is_event_enabled(5300174), "the branch waits for its own prompt before event_on")
	assert_eq(state.pending_operations.size(), 1, "one follow-up; old confirm cannot consume it")
	assert_eq(state.pending_operation().payload.id, "5300102_prompt_2")
	var body := _node(screen, "EventPromptBody") as RichTextLabel
	assert_eq(body.text, event.settlement[0].action["case:op2"].prompt.text)
	(_node(screen, "EventPromptContinueButton") as Button).pressed.emit()
	assert_true(state.is_event_enabled(5300174), "closing the branch prompt resumes event_on")
	await wait_process_frames(2)


func test_identical_next_occurrence_resets_selection_and_stale_submit_is_inert() -> void:
	var state := _state()
	state.queue_choice_prompt({"case:op1": {"text": "选择", "value": {}}})
	state.queue_choice_prompt({"case:op1": {"text": "选择", "value": {}}})
	var screen = _screen(state)
	await wait_process_frames(2)
	var first_confirm := _node(screen, "EventPromptConfirmButton") as Button
	(_node(screen, "EventPromptChoiceButton") as Button).pressed.emit()
	first_confirm.pressed.emit()
	first_confirm.pressed.emit()
	var next_confirm := _node(screen, "EventPromptConfirmButton") as Button
	assert_not_same(first_confirm, next_confirm, "identical data is a new blocking occurrence")
	assert_true(next_confirm.disabled)
	assert_eq(state.pending_operations.size(), 1)
	assert_false((_node(screen, "EventPromptChoiceButton") as Button).button_pressed)
	await wait_process_frames(2)


func test_keyboard_row_submit_moves_focus_to_confirm_without_executing() -> void:
	# [SRC: OptionItemController.OnSelect 0x577400, OnSubmit 0x577490;
	# OptionController.__c__DisplayClass11_0.<Show>b__1 0x588ec0.]
	var state := _state()
	state.queue_choice_prompt({"case:op1": {"text": "选择", "value": {}}})
	var screen = _screen(state)
	await wait_process_frames(2)
	var row := _node(screen, "EventPromptChoiceButton") as Button
	var confirm := _node(screen, "EventPromptConfirmButton") as Button
	row.grab_focus()
	assert_false(confirm.disabled, "keyboard focus selects the row")
	var submit := InputEventAction.new()
	submit.action = "ui_accept"
	submit.pressed = true
	get_viewport().push_input(submit)
	await wait_process_frames(1)
	assert_true(confirm.has_focus(), "row submit moves focus to Confirm")
	assert_eq(state.pending_operations.size(), 1, "the same input cannot also confirm")
	submit = InputEventAction.new()
	submit.action = "ui_accept"
	submit.pressed = false
	get_viewport().push_input(submit)
	await wait_process_frames(1)
	assert_eq(state.pending_operations.size(), 1)


func test_only_plain_prompt_emits_close_prompt_timing() -> void:
	# [SRC: PromptController.Hide 0x589e20 vs OptionController.OnConfirm
	# 0x576900; original event/5300302.json listens to close_prompt.]
	var state := _state()
	state.enable_event(5300302, db)
	state.queue_choice_prompt({"case:op1": {"text": "选择", "value": {}}})
	var screen = _screen(state)
	await wait_process_frames(2)
	(_node(screen, "EventPromptChoiceButton") as Button).pressed.emit()
	(_node(screen, "EventPromptConfirmButton") as Button).pressed.emit()
	assert_true(state.is_event_enabled(5300302), "choice does not fire a plain-prompt listener")
	state.queue_prompt({"id": "close-test", "text": "提示"})
	screen.refresh()
	(_node(screen, "EventPromptContinueButton") as Button).pressed.emit()
	assert_false(state.is_event_enabled(5300302), "plain prompt fires the source non-replay event")
	await wait_process_frames(2)


func test_original_confirm_buttons_submit_directly_without_an_extra_confirmation() -> void:
	# [SRC: ConfirmController.OnConfirm/OnClose -> Done (0x53fb70),
	# dump.cs:318365; source event/5300000.json confirm text/labels.]
	var confirm_data: Dictionary = db.get_event(5300000).settlement[0].action.confirm
	for choice_index in range(2):
		var state := _state()
		state.enable_event(5300302, db)
		var deferred := ResultExec.execute({"confirm": confirm_data}, state, db, {})
		DeferredEffects.apply(deferred, state, db, RNG.new(902))
		var screen = _screen(state)
		await wait_process_frames(2)
		assert_null(_node(screen, "EventPromptConfirmButton"), "OK/Cancel are already final actions")
		var group := _node(screen, "OptionGroup")
		assert_eq(group.get_child(0).get_node("OptionText").get_parsed_text(), "确定")
		assert_eq(group.get_child(1).get_node("OptionText").get_parsed_text(), "取消", "label-only dictionaries do not render as dictionary syntax")
		assert_eq(group.get_child(0).size, Vector2(325, 158))
		assert_eq(group.get_child(1).size, Vector2(168, 158))
		assert_eq(group.get_child(0).position.x - group.get_child(1).position.x - group.get_child(1).size.x, 60.0)
		assert_true(group.get_child(0).get_node("OptionText").text.contains("[font_size=50]"), "source confirm markup survives the result pipeline")
		var button := group.get_child(choice_index) as Button
		assert_false(button.toggle_mode)
		button.pressed.emit()
		button.pressed.emit()
		assert_true(state.pending_operations.is_empty(), "one click completes ConfirmController")
		assert_eq(state.last_confirm_cancelled, choice_index == 1)
		assert_true(state.is_event_enabled(5300302), "confirmation is not plain-prompt close timing")
		await wait_process_frames(2)


func test_close_prompt_child_resolves_before_parent_and_unrelated_queue_tail() -> void:
	# Boundary fixture for PromptController.Hide -> OnClosePrompt -> Promise chain.
	db.events[990111] = {"id": 990111, "is_replay": false, "on": {"close_prompt": 1}, "settlement": [{"action": {
		"prompt": {"id": "child-wait", "text": "child"}, "counter+990112": 2,
	}}]}
	var state := _state()
	state.enable_event(990111, db)
	OperationsSequence.start([{"prompt": {"id": "parent-wait", "text": "parent"}, "counter+990113": 3}], state, db, RNG.new(901))
	state.queue_prompt({"id": "unrelated-tail", "text": "tail"})
	var screen = _screen(state)
	await wait_process_frames(2)
	(_node(screen, "EventPromptContinueButton") as Button).pressed.emit()
	assert_eq(state.pending_operation().payload.id, "child-wait")
	assert_eq(state.get_counter(990112), 0)
	assert_eq(state.get_counter(990113), 0, "parent waits for close_prompt child")
	await wait_process_frames(2)
	(_node(screen, "EventPromptContinueButton") as Button).pressed.emit()
	assert_eq(state.get_counter(990112), 2)
	assert_eq(state.get_counter(990113), 3)
	assert_eq(state.pending_operation().payload.id, "unrelated-tail")
	await wait_process_frames(2)
	db.events.erase(990111)


func test_sleep_resume_surfaces_game_over_once() -> void:
	var state := _state()
	OperationsSequence.start([{"sleep": 0.02, "over": 1}], state, db, RNG.new(901))
	var screen = _screen(state)
	watch_signals(screen)
	await wait_for_signal(screen.game_over_requested, 2.0)
	assert_signal_emit_count(screen, "game_over_requested", 1)
	assert_eq(state.over_reason, 1)
	assert_true(state.pending_operations.is_empty())
	await wait_process_frames(2)


func test_reused_surface_clears_old_rows_and_selection() -> void:
	var view = PromptView.new()
	add_child_autofree(view)
	view.show_prompt({"choices": {"a": "A", "b": "B"}}, Callable())
	(_node(view, "EventPromptChoiceButton") as Button).pressed.emit()
	view.show_prompt({"choices": {"c": "C"}}, Callable())
	assert_eq(_node(view, "OptionGroup").get_child_count(), 1, "old toggles leave the live group immediately")
	assert_true((_node(view, "EventPromptConfirmButton") as Button).disabled)
	view.show_prompt({"text": "提示"}, Callable())
	assert_null(_node(view, "EventPromptConfirmButton"))
	assert_false((_node(view, "EventPromptContinueButton") as Button).disabled)
	await wait_process_frames(2)


func test_main_scene_prompt_has_visible_global_bounds_after_deferred_layout() -> void:
	# [SRC: GameScene MainUI 3840x2160 + PromptNew root full-stretch anchors.
	# This checks final transforms through the real Game._show_game route,
	# not just the fixed local 2705x960 panel dimensions.]
	var stage := Control.new()
	stage.size = Vector2(1152, 648)
	add_child_autofree(stage)
	var main = load("res://scenes/main.tscn").instantiate()
	stage.add_child(main)
	main.state = _state()
	main.state.queue_choice_prompt({"case:op1": {"text": "选择", "value": {}}})
	main.call("_show_game")
	await wait_process_frames(4)
	var screen = main.get("_game_screen")
	var overlay := _node(screen, "EventPromptOverlay") as Control
	var panel := _node(screen, "EventPromptPanel") as Control
	assert_eq(screen.size, main.size, "runtime desktop fills the actual parent")
	assert_eq(overlay.size, screen.size, "prompt root does not retain zero-size offsets")
	assert_gt(panel.get_global_rect().size.x, 800.0, "deferred layout must not collapse the rendered panel")
	assert_true(screen.get_global_rect().encloses(panel.get_global_rect()))
	stage.size = Vector2(1920, 1080)
	await wait_process_frames(4)
	assert_eq(overlay.size, main.size, "resize propagates to the prompt root")
	assert_almost_eq(panel.get_global_rect().size.x, 1352.5, 0.1)
