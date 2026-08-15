extends GutTest

const RNG = preload("res://core/rng.gd")
const MainMenu = preload("res://ui/main_menu.gd")
const Game = preload("res://ui/game.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const RiteView = preload("res://ui/rite_view.gd")
const UiMotionScript = preload("res://ui/ui_motion.gd")

const WIDE_VIEWPORT := Vector2(1152, 648)
const MIN_CONTENT_WIDTH := 900.0

var db: ConfigDB


func before_all():
	SaveSystem.use_save_path("user://test_ui_layout_save.json")
	SaveSystem.use_user_archive_root("user://test_ui_layout_archives")
	SaveSystem.delete_save()
	SaveSystem.delete_all_user_archives()
	db = ConfigDB.new()
	db.load_all()


func after_all():
	SaveSystem.delete_save()
	SaveSystem.delete_all_user_archives()
	SaveSystem.use_default_save_path()
	SaveSystem.use_default_user_archive_root()


func test_main_menu_uses_wide_viewport_width():
	var stage := _stage()
	var menu = MainMenu.new()
	stage.add_child(menu)
	await wait_process_frames(2)

	assert_true(_widest_content(menu) >= MIN_CONTENT_WIDTH, "main menu content should use the wide viewport")


func test_ui_motion_animates_visuals_without_moving_layout_or_hit_rect():
	var stage := _stage()
	var button := Button.new()
	button.position = Vector2(80, 60)
	button.size = Vector2(160, 48)
	stage.add_child(button)
	var layout_position := button.position
	var layout_size := button.size
	var motion = UiMotionScript.bind(button, UiMotionScript.Profile.PRIMARY)

	motion.set_hovered_for_test(true)
	for frame in 18:
		motion._process(1.0 / 60.0)

	assert_eq(button.position, layout_position, "motion must not change Container or anchor layout")
	assert_eq(button.size, layout_size, "motion must not change the hit rectangle")
	assert_true(button.offset_transform_visual_only, "interaction motion should be visual-only")
	assert_true(button.offset_transform_scale.x > 1.0, "hover should lightly enlarge the visual")
	assert_almost_eq(
		button.offset_transform_position.y,
		0.0,
		0.001,
		"ordinary UI hover should remain vertically anchored"
	)


func test_ui_motion_press_interrupts_hover_without_resetting_the_pose():
	var stage := _stage()
	var button := Button.new()
	stage.add_child(button)
	var motion = UiMotionScript.bind(button)
	motion.set_hovered_for_test(true)
	for frame in 12:
		motion._process(1.0 / 60.0)
	var hover_scale := button.offset_transform_scale.x

	motion.set_pressed_for_test(true)
	motion._process(1.0 / 60.0)
	var first_pressed_scale := button.offset_transform_scale.x

	assert_true(
		absf(first_pressed_scale - hover_scale) < 0.08,
		"press should retarget the active spring instead of snapping to a new Tween"
	)
	for frame in 18:
		motion._process(1.0 / 60.0)
	assert_true(
		button.offset_transform_scale.x < hover_scale,
		"held buttons should settle toward a compact pressed pose"
	)


func test_ui_motion_panel_reveal_is_bounded_and_settles():
	var stage := _stage()
	var panel := PanelContainer.new()
	panel.position = Vector2(180, 90)
	panel.size = Vector2(320, 240)
	stage.add_child(panel)
	var layout_position := panel.position
	var motion = UiMotionScript.bind(panel, UiMotionScript.Profile.PANEL, true)

	assert_true(panel.offset_transform_position.y > 0.0, "panel reveal should start slightly below rest")
	assert_true(panel.self_modulate.a < 1.0, "panel reveal should begin transparent")
	for frame in 90:
		motion._process(1.0 / 60.0)

	assert_eq(panel.position, layout_position, "panel reveal must preserve its anchored rectangle")
	assert_almost_eq(panel.offset_transform_position.y, 0.0, 0.01)
	assert_almost_eq(panel.offset_transform_scale.x, 1.0, 0.001)
	assert_almost_eq(panel.self_modulate.a, 1.0, 0.001)


func test_ui_motion_selected_site_survives_hover_exit_and_reduced_motion_snaps():
	var stage := _stage()
	var button := Button.new()
	stage.add_child(button)
	var motion = UiMotionScript.bind(button, UiMotionScript.Profile.SITE)

	motion.set_hovered_for_test(true)
	motion.set_selected(true)
	motion.set_hovered_for_test(false)
	for frame in 90:
		motion._process(1.0 / 60.0)

	assert_almost_eq(button.offset_transform_position.y, -6.0, 0.02)
	assert_almost_eq(button.offset_transform_scale.x, 1.05, 0.002)
	motion.set_selected(false)
	for frame in 90:
		motion._process(1.0 / 60.0)
	assert_almost_eq(button.offset_transform_position.y, 0.0, 0.02)

	UiMotionScript.reduced_motion = true
	motion.set_selected(true)
	assert_almost_eq(button.offset_transform_position.y, -6.0, 0.001)
	assert_almost_eq(button.offset_transform_scale.x, 1.05, 0.001)
	motion.set_selected(false)
	assert_almost_eq(button.offset_transform_position.y, 0.0, 0.001)
	UiMotionScript.reduced_motion = false


func test_representative_main_screen_controls_share_ui_motion():
	var state := GameState.new()
	state.setup_new_run(db, 1, RNG.new(71))
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, RNG.new(72))
	stage.add_child(screen)
	await wait_process_frames(2)

	for node_name in ["MenuButton", "SiteHome", "AdvanceDayButton"]:
		var control := _find_node_by_name(screen, node_name)
		assert_not_null(control, "%s should exist" % node_name)
		if control != null:
			assert_not_null(
				control.get_node_or_null(UiMotionScript.DRIVER_NAME),
				"%s should use the shared interaction motion" % node_name
			)


func test_game_screen_shared_hand_clock_stops_for_local_and_global_pauses():
	var rng := RNG.new(73)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)
	screen.set_process(false)
	var rail_cards := _rail_card_widgets(screen)
	assert_gt(rail_cards.size(), 0)
	if rail_cards.is_empty():
		return
	var card := rail_cards[0] as CardWidget
	var initial_time := screen.hand_idle_time_seconds()
	assert_almost_eq(card._idle_time_seconds(), initial_time, 0.000001)

	screen.set_world_scene_blocker("clock_test", true, false, true, true)
	screen._process(4.0)
	assert_almost_eq(screen.hand_idle_time_seconds(), initial_time, 0.000001)
	assert_almost_eq(card._idle_time_seconds(), initial_time, 0.000001)
	screen.set_world_scene_blocker("clock_test", false, false, true, true)
	var delta := 1.0 / 60.0
	screen._process(delta)
	var after_local_resume := initial_time + delta
	assert_almost_eq(screen.hand_idle_time_seconds(), after_local_resume, 0.000001)
	assert_almost_eq(card._idle_time_seconds(), after_local_resume, 0.000001)

	screen.set_presentation_frozen(true)
	screen._process(4.0)
	assert_almost_eq(screen.hand_idle_time_seconds(), after_local_resume, 0.000001)
	assert_almost_eq(card._idle_time_seconds(), after_local_resume, 0.000001)
	screen.set_presentation_frozen(false)
	screen.set_process(false)
	screen._process(delta)
	assert_almost_eq(
		screen.hand_idle_time_seconds(),
		after_local_resume + delta,
		0.000001,
		"continue game should resume the shared hand clock from its frozen phase"
	)


func test_main_menu_hides_continue_without_valid_player_save():
	SaveSystem.delete_save()
	var file := FileAccess.open(SaveSystem.save_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "hand": [2000001]}, "\t"))
	file.close()
	var stage := _stage()
	var menu = MainMenu.new()
	menu.setup(db)
	stage.add_child(menu)
	await wait_process_frames(2)

	assert_null(_find_node_by_name(menu, "ContinueGameButton"), "old or test save files should not show a continue button")


func test_main_menu_shows_continue_for_valid_player_save():
	SaveSystem.delete_save()
	var rng := RNG.new(16)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	assert_true(SaveSystem.save(state), "test setup should create a player save")
	var stage := _stage()
	var menu = MainMenu.new()
	menu.setup(db)
	stage.add_child(menu)
	await wait_process_frames(2)

	assert_not_null(_find_node_by_name(menu, "ContinueGameButton"), "valid player saves should show a continue button")


func test_main_menu_lists_named_archives_with_load_and_delete_actions():
	SaveSystem.delete_all_user_archives()
	var state := GameState.new()
	state.setup_new_run(db, 1, RNG.new(19))
	state.day = 5
	assert_true(SaveSystem.save_user_archive(state, 0, "Book shop route"), "test setup should create a manual archive")
	var stage := _stage()
	var menu = MainMenu.new()
	menu.setup(db)
	stage.add_child(menu)
	await wait_process_frames(2)

	assert_not_null(_find_node_by_name(menu, "UserArchiveList"), "manual archives should be visible on the title menu")
	assert_not_null(_find_node_by_name(menu, "LoadUserArchiveButton_0"), "an archive row should load its selected slot")
	assert_not_null(_find_node_by_name(menu, "DeleteUserArchiveButton_0"), "an archive row should expose deletion")


func test_main_menu_exposes_test_start_in_debug_builds():
	var stage := _stage()
	var menu = MainMenu.new()
	menu.setup(db)
	stage.add_child(menu)
	await wait_process_frames(2)

	if OS.is_debug_build():
		assert_not_null(_find_node_by_name(menu, "TestStartButton"), "debug builds should expose a simple test start entry")


func test_game_screen_uses_wide_viewport_width():
	var rng := RNG.new(1)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	assert_true(_widest_content(screen) >= MIN_CONTENT_WIDTH, "game screen content should use the wide viewport")
	var desk_map := _find_node_by_name(screen, "DeskMap") as Control
	assert_not_null(desk_map, "game screen should keep the situation desk as the wide central panel")
	if desk_map != null:
		assert_true(desk_map.size.x >= MIN_CONTENT_WIDTH, "situation desk should not remain in a left-column layout")


func test_game_screen_uses_bottom_card_rail_for_sudan_and_hand():
	var rng := RNG.new(3)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var card_rail := _find_node_by_name(screen, "CardRail")
	var bottom_actions := _find_node_by_name(screen, "RightActions")
	assert_not_null(card_rail, "main screen should expose a unified bottom card rail")
	assert_not_null(bottom_actions, "advance-day actions should share the bottom band with cards")
	if card_rail == null or bottom_actions == null:
		return
	assert_eq(_count_card_widgets(card_rail), state.hand.size() + state.active_sudan_cards.size(), "sudan cards and hand cards share one bottom rail")
	assert_not_null(_find_node_by_name(bottom_actions, "AdvanceDayButton"), "advance-day button belongs beside the bottom card rail")
	assert_eq(_count_nodes_by_name(screen, "SultanPanel"), 0, "sudan cards should not live in a separate top panel")


func test_game_screen_hud_uses_day_without_coin_or_round_labels():
	var rng := RNG.new(5)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var hud_text := _collect_label_and_button_text(_find_node_by_name(screen, "Hud"))
	assert_true(hud_text.find("第 1 天") >= 0, "HUD should show the visible day")
	assert_eq(hud_text.find("回合"), -1, "HUD should not expose internal round wording")
	assert_eq(hud_text.find("金币"), -1, "gold should be represented as cards instead of a HUD counter")


func test_game_screen_home_site_and_menu_are_interactive():
	var rng := RNG.new(6)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var opened: Array = []
	var locations: Array = []
	var menu_count := [0]
	screen.open_rite.connect(func(id: int): opened.append(id))
	screen.open_rite_selector.connect(func(location: String): locations.append(location))
	screen.menu_pressed.connect(func(): menu_count[0] += 1)

	var home := _find_node_by_name(screen, "SiteHome") as Button
	var menu := _find_node_by_name(screen, "MenuButton") as Button
	assert_not_null(home, "home site should be an interactive button")
	assert_not_null(menu, "menu should be an interactive button")
	if home != null:
		home.pressed.emit()
	if menu != null:
		menu.pressed.emit()
	assert_eq(opened, [], "site buttons should not hard-code a specific rite id")
	assert_eq(locations, ["自宅"], "clicking home site should request the home location rites")
	assert_eq(menu_count[0], 1, "clicking menu should emit a menu action")


func test_site_action_uses_one_local_selector_flow_and_locks_day_controls():
	var stage := _stage()
	var game = Game.new()
	stage.add_child(game)
	await wait_process_frames(2)
	game._on_difficulty_selected(0)
	await wait_process_frames(2)
	_drain_intro_events(game)

	var screen := game._game_screen as Control
	var home := _find_node_by_name(game, "SiteHome") as Button
	var market := _find_node_by_name(game, "SiteMarket") as Button
	var desk := _find_node_by_name(game, "SituationDesk") as Control
	var card_rail := _find_node_by_name(game, "CardRail") as Control
	var think_drop := _find_node_by_name(game, "ThinkDropZone") as Control
	var right_actions := _find_node_by_name(game, "RightActions") as Control
	var advance := _find_node_by_name(game, "AdvanceDayButton") as Button
	var redraw := _find_node_by_name(game, "RedrawSudanButton") as Button
	var menu := _find_node_by_name(game, "MenuButton") as Button
	assert_not_null(screen)
	assert_not_null(home)
	assert_not_null(market)
	assert_not_null(desk)
	assert_not_null(card_rail)
	assert_not_null(think_drop)
	assert_not_null(right_actions)
	assert_not_null(advance)
	assert_not_null(redraw)
	assert_not_null(menu)
	if screen == null or home == null or market == null or desk == null or card_rail == null or think_drop == null or right_actions == null or advance == null or redraw == null or menu == null:
		return
	assert_false(home.disabled, "a site with available actions should be visibly enabled")
	assert_string_contains(home.text, "·", "site labels should expose their action availability")
	var rng_state_before: int = game.rng.get_state()
	var source_anchor: Vector2 = screen.site_action_anchor("自宅")
	home.pressed.emit()
	await wait_process_frames(2)

	var selector := _find_node_by_name(game, "RiteSelector") as Control
	var selector_panel := _find_node_by_name(game, "RiteSelectorPanel") as Control
	var selector_backdrop := _find_node_by_name(game, "RiteSelectorBackdrop") as Control
	var rail_cards := _rail_card_widgets(screen)
	assert_not_null(selector, "every non-empty site should open the same action selector")
	assert_not_null(selector_panel, "site actions should use a local context menu instead of replacing the game screen")
	assert_not_null(selector_backdrop, "the menu needs a full-screen input-capturing pause shade")
	assert_null(_find_node_by_name(game, "RiteSelectorConnector"), "nearby context should not need a tether line")
	assert_null(_find_node_by_name(game, "CloseRiteSelectorButton"), "the visible map makes a return button redundant")
	assert_eq(game._game_screen, screen, "opening a site action list must preserve the current GameScreen")
	assert_eq(game.rng.get_state(), rng_state_before, "availability previews must not consume simulation RNG")
	assert_null(_find_node_by_name(game, "RiteOverlayPanel"), "a single action must not skip the selector contract")
	if selector != null:
		assert_eq(selector._overlay_anchor, source_anchor, "the selector should open from the clicked site")
	assert_true(home.visible, "the selected site should remain visible beneath its local panel")
	assert_almost_eq(
		market.self_modulate.a,
		1.0,
		0.001,
		"pausing a site menu must not fade or remove the other physical nodes"
	)
	assert_true(think_drop.visible, "a compact site menu must not make the thought drop target disappear")
	if selector_panel != null:
		var panel_rect := selector_panel.get_global_rect()
		assert_lte(selector_panel.size.x, 288.0, "one local action should use a compact menu")
		assert_true(
			desk.get_global_rect().encloses(panel_rect),
			"the menu should stay inside the map work area"
		)
		assert_false(
			panel_rect.intersects(card_rail.get_global_rect()),
			"the menu must never overlap the persistent card rail"
		)
		assert_false(
			Rect2(selector_panel.position, selector_panel.size).has_point(source_anchor),
			"the menu should open beside, not over, the selected site"
		)
	assert_true(right_actions.visible, "a local context menu must not make persistent actions disappear")
	assert_true(advance.disabled, "visible day controls must reject programmatic activation while the menu is open")
	assert_true(redraw.disabled, "visible redraw controls must reject programmatic activation while the menu is open")
	assert_almost_eq(right_actions.self_modulate.a, 1.0, 0.001, "the shared pause shade, not a special alpha, should dim right-side controls")
	var disabled_advance_style := advance.get_theme_stylebox("disabled") as StyleBoxFlat
	assert_not_null(disabled_advance_style, "the disabled primary action must retain an authored shape")
	if disabled_advance_style != null:
		assert_eq(disabled_advance_style.corner_radius_top_left, 72, "the disabled primary action must retain its round silhouette")
	var disabled_redraw_style := redraw.get_theme_stylebox("disabled") as StyleBoxFlat
	assert_not_null(disabled_redraw_style, "the disabled secondary action must retain an authored shape")
	if selector != null:
		assert_gt(selector.z_index, card_rail.z_index, "the contextual pause shade must cover the card rail")
		assert_gt(selector.z_index, right_actions.z_index, "the contextual pause shade must cover right-side controls")
		assert_gt(selector.z_index, menu.z_index, "the contextual pause shade must cover the menu entry")
	if selector_backdrop != null:
		assert_eq(selector_backdrop.mouse_filter, Control.MOUSE_FILTER_STOP, "the shade must intercept all background pointer input")
	assert_true(menu.disabled, "the menu must pause with the rest of the background")
	assert_eq(card_rail.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the paused rail must reject direct drag/drop input")
	if not rail_cards.is_empty():
		var first_card := rail_cards[0] as CardWidget
		assert_true(first_card.is_presentation_paused(), "visible rail cards must stop their idle and hover processing")
		assert_false(first_card.is_processing(), "a paused background card must not keep animating beneath the menu")
	if selector != null:
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		selector.call("_unhandled_key_input", escape)
		await wait_seconds(0.18)
		await wait_process_frames(1)
	assert_null(_find_node_by_name(game, "RiteSelector"), "closing the action panel should remove the selector")
	assert_true(right_actions.visible, "closing the local panel should restore desk progression controls")
	assert_false(advance.disabled)
	assert_false(redraw.disabled)
	assert_almost_eq(right_actions.self_modulate.a, 1.0, 0.001)
	assert_false(menu.disabled, "closing the local panel should restore the persistent menu entry")
	assert_eq(card_rail.mouse_filter, Control.MOUSE_FILTER_STOP, "closing the local panel should restore rail input")
	if not rail_cards.is_empty():
		var restored_card := rail_cards[0] as CardWidget
		assert_false(restored_card.is_presentation_paused(), "closing the local panel should resume rail presentation")
	assert_almost_eq(market.self_modulate.a, 1.0, 0.001)
	await wait_process_frames(1)
	assert_true(home.has_focus(), "returning from the local panel should restore the source site focus")


func test_game_screen_exposes_a_labelled_drag_only_thought_drop_zone():
	var rng := RNG.new(17)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var target := _find_node_by_name(screen, "ThinkDropZone") as Control
	var desk := _find_node_by_name(screen, "SituationDesk")
	var card_uid := state.card_uid_for(2000001, "hand")
	var drag_data := {"type": "card", "card_id": 2000001, "card_uid": card_uid, "source": "hand"}
	assert_not_null(target, "the desk should expose one visible card-to-thought drop zone")
	assert_null(_find_node_by_name(screen, "MethinksDropTarget"), "the obsolete standalone clone-era target should be gone")
	if target == null or desk == null:
		return
	assert_false(target is Button, "drag-only affordances must not be exposed as clickable buttons")
	assert_string_contains(
		_collect_label_and_button_text(target),
		"拖入卡牌",
		"the drop zone should state the required gesture without relying on a tooltip"
	)
	assert_lt(target.position.x, desk.size.x * 0.2, "the thought drop zone stays in the desk lower-left position")
	assert_true(target._can_drop_data(Vector2.ZERO, drag_data), "the desk drop zone should accept valid card drops")


func test_thought_drop_uses_legacy_bridge_without_opening_rite_overlay():
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.init_config["think_id"] = 999000
	local_db.rites[999000] = {
		"id": 999000,
		"cards_slot": {"s1": {"condition": {}}},
		"settlement_prior": [],
		"settlement": [
			{"condition": {"s1.is": 2000001}, "result": {}, "action": {"rite": 5000001, "prompt": {"id": "think.test"}}}
		],
		"settlement_extre": [],
	}
	var rng := RNG.new(18)
	var state := GameState.new()
	state.setup_new_run(local_db, 0, rng)
	state.available_rites.erase(5000001)
	var rites_before := state.available_rite_instances().filter(func(instance): return instance.id == 5000001).size()
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, local_db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var protagonist_uid := state.card_uid_for(2000001, "hand")
	var think_button := _find_node_by_name(screen, "ThinkDropZone") as Control
	var desk := _find_node_by_name(screen, "SituationDesk")
	think_button._drop_data(
		Vector2.ZERO,
		{"type": "card", "card_id": 2000001, "card_uid": protagonist_uid, "source": "hand"}
	)

	assert_true(5000001 in state.available_rites, "the legacy card-to-thought bridge should generate rites through scene processing")
	assert_eq(state.available_rite_instances().filter(func(instance): return instance.id == 5000001).size(), rites_before + 1, "the compatibility bridge creates a fresh runtime rite instead of a config-only flag")
	assert_true(state.hand_has_card_id(2000001), "cards return to hand unless the result explicitly cleans them")
	assert_eq(str(state.event_prompts[0].get("id", "")), "think.test")
	assert_eq(
		int(state.event_prompts[0].get("context", {}).get("player_actor_uid", 0)),
		state.player_actor_uid,
		"thought results retain who the player is acting through"
	)
	assert_eq(
		int(state.event_prompts[0].get("context", {}).get("focus_card_uid", 0)),
		protagonist_uid,
		"thought results distinguish the focused object from the player actor"
	)
	var prompt_panel := _find_node_by_name(screen, "EventPromptPanel") as Control
	var scene := _find_node_by_name(screen, "DeskMap") as Control
	var rail := _find_node_by_name(screen, "CardRail") as Control
	assert_not_null(prompt_panel, "card-to-thought results should use the scene event prompt layer")
	assert_null(_find_node_by_name(screen, "RiteOverlayPanel"), "card-to-thought processing should not open the rite overlay")
	assert_false(desk.is_thinking(), "dropping a card should not create a desk thought presentation state")
	if prompt_panel != null and scene != null and rail != null:
		assert_lte(
			prompt_panel.position.y + prompt_panel.size.y,
			scene.position.y + scene.size.y,
			"event prompts should stay inside the desk area"
		)
		assert_lt(
			prompt_panel.position.y + prompt_panel.size.y,
			rail.position.y,
			"event prompts must not cover the card rail"
		)
		assert_lt(
			prompt_panel.size.y,
			scene.size.y * 0.6,
			"ordinary prompts should stay compact, not full-screen pages"
		)


func test_game_screen_event_overlay_consumes_prompt_choice_and_followup():
	var rng := RNG.new(19)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.queue_choice_prompt({"pop.test": "hello"})
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	assert_not_null(_find_node_by_name(screen, "EventPromptPanel"), "queued choices should render as a scene overlay")
	var choice := _find_node_by_name(screen, "EventPromptChoiceButton") as Button
	assert_not_null(choice, "choice prompts should render clickable option buttons")
	if choice == null:
		return
	choice.pressed.emit()
	await wait_process_frames(2)

	assert_eq(str(state.event_prompts[0].get("id", "")), "pop.test", "clicking a choice should execute the selected operation")
	var text := _collect_label_and_button_text(_find_node_by_name(screen, "EventPromptPanel"))
	assert_true(text.find("hello") >= 0, "choice follow-up prompt should be visible")

	var cont := _find_node_by_name(screen, "EventPromptContinueButton") as Button
	assert_not_null(cont, "follow-up prompt should be consumable")
	if cont != null:
		cont.pressed.emit()
		await wait_process_frames(2)
	assert_true(state.event_prompts.is_empty(), "continue should consume the prompt queue")


func test_game_screen_rename_operation_blocks_for_input_and_updates_card() -> void:
	var rng := RNG.new(190)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var card_uid := int(state.hand[0])
	state.queue_operation("rename_card", "rename.test", {
		"card_uid": card_uid,
		"title": "为卡牌命名",
		"text": "输入一个名字。",
		"initial_text": "旧名字",
	}, {"card_uid": card_uid})
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var input := _find_node_by_name(screen, "CardRenameInput") as LineEdit
	var confirm := _find_node_by_name(screen, "CardRenameConfirmButton") as Button
	assert_not_null(input, "rename operations render a real text input")
	assert_not_null(confirm, "rename operations require an explicit confirmation")
	if input == null or confirm == null:
		return
	input.text = "新名字"
	confirm.pressed.emit()
	await wait_process_frames(2)

	assert_true(state.pending_operations.is_empty())
	assert_eq(str(state.card_data_for(card_uid, db).name), "新名字")
	assert_null(_find_node_by_name(screen, "CardRenameInput"), "the blocking rename overlay closes after a valid submission")


func test_game_screen_option_choice_uses_configured_label():
	var rng := RNG.new(191)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.queue_choice_prompt({"case:op1": {"text": "给钱", "value": {"金币": 2}}})
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var choice := _find_node_by_name(screen, "EventPromptChoiceButton") as Button
	assert_not_null(choice)
	if choice == null:
		return
	assert_eq(choice.text, "给钱", "button should show option text instead of its action dictionary")
	choice.pressed.emit()
	await wait_process_frames(2)
	assert_eq(state.coin_count, 2)


func test_game_screen_event_overlay_displays_missing_event_placeholder():
	var rng := RNG.new(20)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.queue_event(5310008)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var panel := _find_node_by_name(screen, "EventPromptPanel")
	assert_not_null(panel, "queued events should render as a scene overlay even before event configs are imported")
	var text := _collect_label_and_button_text(panel)
	assert_true(text.find("5310008") >= 0, "missing event configs should fall back to a visible event id")

	var cont := _find_node_by_name(screen, "EventPromptContinueButton") as Button
	if cont != null:
		cont.pressed.emit()
		await wait_process_frames(2)
	assert_true(state.event_queue.is_empty(), "continue should consume the event queue")


func test_game_screen_event_queue_executes_event_result_when_consumed():
	# A queued event with a result payload must apply its effects when the
	# player dismisses it, instead of being a no-op.
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events[990002] = {
		"id": 990002,
		"name": "奖励事件",
		"text": "你获得了一些金币。",
		"result": {"金币": 7, "counter+7000001": 3},
	}
	var rng := RNG.new(21)
	var state := GameState.new()
	state.setup_new_run(local_db, 0, rng)
	state.queue_event(990002)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, local_db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var cont := _find_node_by_name(screen, "EventPromptContinueButton") as Button
	assert_not_null(cont, "event with no choices renders a continue button")
	if cont == null:
		return
	cont.pressed.emit()
	await wait_process_frames(2)

	assert_true(state.event_queue.is_empty(), "event consumed from the queue")
	assert_eq(state.coin_count, 7, "event result coin applied on consume")
	assert_eq(state.get_counter(7000001), 3, "event result counter applied on consume")


func test_game_screen_event_with_over_result_signals_game_over():
	# An event whose result carries `over` must signal game-over to the
	# controller when consumed.
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events[990003] = {
		"id": 990003,
		"name": "结局事件",
		"text": "一切都结束了。",
		"result": {"over": 1},
	}
	var rng := RNG.new(22)
	var state := GameState.new()
	state.setup_new_run(local_db, 0, rng)
	state.queue_event(990003)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, local_db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)
	watch_signals(screen)

	var cont := _find_node_by_name(screen, "EventPromptContinueButton") as Button
	if cont != null:
		cont.pressed.emit()
		await wait_process_frames(2)
	assert_signal_emitted(screen, "game_over_requested", "event over result should signal game-over")


func test_game_screen_event_with_rite_auto_opens_rite():
	# An event whose action opens a rite should auto-open it (so the player sees
	# the rite's narration), not silently park it in available_rites.
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events[990004] = {
		"id": 990004,
		"text": "求助",
		"settlement": [{"action": {"rite": 5001001}}],
	}
	var rng := RNG.new(23)
	var state := GameState.new()
	state.setup_new_run(local_db, 0, rng)
	state.queue_event(990004)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, local_db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)
	watch_signals(screen)

	var cont := _find_node_by_name(screen, "EventPromptContinueButton") as Button
	if cont != null:
		cont.pressed.emit()
		await wait_process_frames(2)
	assert_signal_emitted_with_parameters(screen, "open_rite", [5001001])


func test_game_menu_button_opens_real_overlay():
	var stage := _stage()
	var game = Game.new()
	stage.add_child(game)
	await wait_process_frames(2)

	game._on_difficulty_selected(0)
	await wait_process_frames(2)
	_drain_intro_events(game)

	var menu := _find_node_by_name(game, "MenuButton") as Button
	assert_not_null(menu, "menu button should exist in the in-game HUD")
	if menu == null:
		return
	menu.pressed.emit()
	await wait_process_frames(1)

	var overlay := _find_node_by_name(game, "GameMenuOverlay") as Control
	var rail := _find_node_by_name(game, "CardRail") as Control
	var desk_think := _find_node_by_name(game, "ThinkDropZone") as Control
	assert_not_null(overlay, "menu button should open an in-game menu overlay")
	assert_not_null(rail)
	assert_not_null(desk_think)
	assert_not_null(_find_node_by_name(game, "ResumeGameButton"), "menu overlay should include a resume action")
	assert_not_null(_find_node_by_name(game, "SaveGameButton"), "menu overlay should include a save action")
	assert_not_null(_find_node_by_name(game, "SaveUserArchiveButton"), "menu overlay should include a named archive action")
	assert_not_null(_find_node_by_name(game, "ReturnTitleButton"), "menu overlay should include a return-title action")
	if overlay != null and rail != null:
		assert_gt(overlay.z_index, rail.z_index, "the menu must cover persistent hand cards")
		assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_STOP, "the global menu layer must block clicks behind it")
		var shade := overlay.get_child(0) as Control
		assert_not_null(shade)
		if shade != null:
			assert_eq(shade.mouse_filter, Control.MOUSE_FILTER_STOP, "the menu shade must absorb background input")
	if desk_think != null:
		assert_true(desk_think.visible, "the global menu pauses the visible desk instead of hiding its thought target")
	assert_eq(
		(game._game_screen as Node).process_mode,
		Node.PROCESS_MODE_DISABLED,
		"the global menu freezes the complete lower gameplay layer"
	)
	var desk := _find_node_by_name(game, "SituationDesk")
	assert_true(desk.is_scene_blocked(), "the game menu should block desk input")
	var resume := _find_node_by_name(game, "ResumeGameButton") as Button
	if resume != null:
		resume.pressed.emit()
		await wait_process_frames(1)
		assert_false(desk.is_scene_blocked(), "resuming should release the menu blocker")
		assert_eq(
			(game._game_screen as Node).process_mode,
			Node.PROCESS_MODE_INHERIT,
			"resuming should reactivate the lower gameplay layer"
		)


func test_player_path_keeps_surface_ownership_and_modal_budget_intact():
	var stage := _stage()
	var game = Game.new()
	stage.add_child(game)
	await wait_process_frames(2)
	game._on_difficulty_selected(0)
	await wait_process_frames(2)
	_drain_intro_events(game)

	var screen := game._game_screen as Control
	var desk := _find_node_by_name(game, "SituationDesk") as Control
	var right_actions := _find_node_by_name(game, "RightActions") as Control
	assert_not_null(screen)
	assert_not_null(desk)
	assert_not_null(right_actions)
	if screen == null or desk == null or right_actions == null:
		return

	assert_true(desk.visible, "the player lives on the situation desk")
	assert_eq(desk.get_parent(), screen, "the desk keeps GameScreen as its permanent parent")
	assert_true(right_actions.visible, "day controls belong to the desk commit surface")
	for child in desk.get_children():
		if child is CanvasItem:
			assert_lte((child as CanvasItem).z_index, GameScreen.SCENE_CONTENT_Z_MAX, "desk content stays inside its layer budget: %s" % child.name)
	var menu_button := _find_node_by_name(game, "MenuButton") as Button
	assert_not_null(menu_button)
	if menu_button == null:
		return
	assert_true(menu_button.visible, "the visible top menu remains the real route into the global modal")
	menu_button.pressed.emit()
	await wait_process_frames(1)

	var menu_overlay := _find_node_by_name(game, "GameMenuOverlay") as Control
	var rail := _find_node_by_name(game, "CardRail") as Control
	assert_not_null(menu_overlay)
	assert_not_null(rail)
	if menu_overlay != null and rail != null:
		assert_eq(menu_overlay.get_parent(), game, "the global menu keeps Game as its permanent parent")
		assert_gt(menu_overlay.z_index, rail.z_index, "global menu outranks persistent hand cards")
		assert_eq(menu_overlay.mouse_filter, Control.MOUSE_FILTER_STOP, "global menu blocks clicks behind its shade")
	assert_true(desk.is_scene_blocked(), "the global menu blocks all lower desk input")
	var resume := _find_node_by_name(game, "ResumeGameButton") as Button
	assert_not_null(resume)
	if resume == null:
		return
	resume.pressed.emit()
	await wait_process_frames(1)
	assert_false(desk.is_scene_blocked(), "closing the global menu releases the desk input lock")


func test_game_menu_opens_manual_archive_picker():
	var stage := _stage()
	var game = Game.new()
	stage.add_child(game)
	await wait_process_frames(2)
	game._on_difficulty_selected(0)
	await wait_process_frames(2)
	_drain_intro_events(game)
	game._show_user_archive_overlay()
	await wait_process_frames(1)

	assert_not_null(_find_node_by_name(game, "UserArchiveOverlay"), "manual save opens a separate archive picker")
	assert_not_null(_find_node_by_name(game, "UserArchiveNameInput"), "archive picker accepts a player-specified name")
	assert_not_null(_find_node_by_name(game, "SaveNewUserArchiveButton"), "archive picker can create a new slot")
	var desk := _find_node_by_name(game, "SituationDesk")
	assert_true(desk.is_scene_blocked(), "the archive picker should block desk input")
	game._close_user_archive_overlay()
	assert_false(desk.is_scene_blocked(), "closing the archive picker should release its blocker")


func test_test_start_entry_uses_test_card_profile():
	var stage := _stage()
	var game = Game.new()
	stage.add_child(game)
	await wait_process_frames(2)

	game._on_test_start_requested(1)
	await wait_process_frames(2)

	assert_true(game.state.hand.size() > 50, "test start profile should use the full init/1 card list")
	assert_false(game.db.use_test_starting_cards, "test-card flag should not leak into later normal starts")


func test_card_widget_exports_drag_payload_with_card_id():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	await wait_process_frames(1)

	widget._drag_selected_position = Vector2(1.5, -11.0)
	widget._drag_selected_rotation = deg_to_rad(1.25)
	widget._drag_selected_scale = Vector2.ONE * 1.04
	widget._drag_selected_tilt = Vector2(0.35, -0.2)
	var data = widget.drag_payload()
	assert_true(data is Dictionary, "dragging a card should produce a card payload")
	assert_eq(int(data.get("card_id", 0)), 2000001, "drag payload should identify the dragged card")
	assert_eq(data.get("drag_visual_position"), widget._drag_selected_position)
	assert_almost_eq(float(data.get("drag_visual_rotation")), widget._drag_selected_rotation, 0.000001)
	assert_eq(data.get("drag_visual_scale"), widget._drag_selected_scale)
	assert_eq(data.get("drag_visual_tilt"), widget._drag_selected_tilt)

func test_card_widget_face_only_shows_name_and_art():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 3, "tag": {"智慧": 9, "主角": 1}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	await wait_process_frames(1)

	assert_not_null(_find_node_by_name(widget, "CardArt"), "compact card should include a visual art area")
	var text := _collect_label_and_button_text(widget)
	assert_true(text.find("Test") >= 0, "compact card should show the card name")
	assert_eq(text.find("智慧"), -1, "compact card should not show attributes")
	assert_eq(text.find("主角"), -1, "compact card should not show tags")

func test_card_widget_inner_art_does_not_block_dragging():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	await wait_process_frames(1)

	var art := _find_node_by_name(widget, "CardArt") as Control
	assert_not_null(art, "card art placeholder should exist")
	if art != null:
		assert_eq(art.mouse_filter, Control.MOUSE_FILTER_IGNORE, "card art should not eat drag events")

func test_card_widget_hides_source_while_dragging_and_restores_on_failed_drop():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	await wait_process_frames(1)

	widget._set_hovered(true)
	widget._drag_selected_position = Vector2(2.0, -12.0)
	widget._drag_selected_rotation = deg_to_rad(1.4)
	widget._drag_selected_scale = Vector2.ONE * CardWidget.HOVER_SCALE
	widget._hide_source_for_drag()
	assert_false(widget.visible, "source card should disappear from hand while dragging")
	assert_eq(widget.z_index, 0, "hidden drag source should release its temporary hover layer")

	widget._restore_source_after_failed_drag()
	assert_true(widget.visible, "source card should reappear if drop fails")
	assert_almost_eq(
		widget.offset_transform_rotation, widget._drag_selected_rotation, 0.000001,
		"a failed drop should return from the selected angle without snapping"
	)


func test_card_widget_hover_raises_its_layer_and_scale():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	await wait_process_frames(2)

	widget._set_hovered(true)
	assert_true(widget.z_index >= CardWidget.HOVER_Z_INDEX, "hovered card should render above neighbouring cards")
	await wait_process_frames(8)
	assert_true(widget.offset_transform_scale.x > 1.0, "hovered card should gain visual scale")
	assert_almost_eq(widget.offset_transform_position.y, 0.0, 0.5, "hover alone should not invent a selected-card lift")
	assert_true(widget.offset_transform_visual_only, "hover transform should not distort the card's mouse hit rectangle")
	assert_not_null(_find_node_by_name(widget, "CardVisualSurface"), "the dynamic card face should render as one shader-ready surface")
	assert_not_null(_find_node_by_name(widget, "CardShadowSurface"), "cards should render a separate table-plane shadow pass")
	assert_not_null(_find_node_by_name(widget, "CardRenderRoot"), "face and shadow should live below one container-managed render root")
	assert_eq(widget._shadow_surface.get_parent(), widget._render_root)
	assert_eq(widget._visual_surface.get_parent(), widget._render_root)
	assert_false(widget._render_root is Container, "projection offsets must not be rewritten by container layout")
	var shadow_style := widget._style_for_card()
	assert_eq(shadow_style.shadow_size, 0, "the perspective face texture must not contain a baked shadow")
	assert_eq(shadow_style.shadow_offset, Vector2.ZERO)
	assert_eq(widget._shadow_surface.texture, widget._visual_surface.texture, "shadow and face should sample the same pre-perspective card texture")
	assert_ne(widget._shadow_surface.material, widget._visual_surface.material, "shadow must not inherit the face perspective material")
	assert_almost_eq(widget._shadow_height, CardWidget.SHADOW_IDLE_HEIGHT, 0.001, "hover alone should not raise the table shadow")

	# The headless test pointer is fixed over the top-left corner of the stage;
	# take it out of hit testing before asserting the explicit leave transition.
	widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	widget._set_hovered(false)
	await wait_process_frames(12)
	assert_eq(widget.z_index, 0, "card should return to its normal rail layer after hover")


func test_card_moveable_scale_uses_original_exponential_recurrence():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	widget.offset_transform_scale = Vector2.ONE
	widget._pose_scale_velocity = Vector2.ZERO
	var delta := 1.0 / 60.0
	var target := Vector2.ONE * CardWidget.HOVER_SCALE
	widget._step_moveable_pose(Vector2.ZERO, 0.0, target, delta)
	var expected_velocity := (1.0 - exp(-CardWidget.MOVEABLE_SCALE_DECAY_RATE * delta)) * 0.05
	assert_almost_eq(widget._pose_scale_velocity.x, expected_velocity, 0.000001)
	assert_almost_eq(widget.offset_transform_scale.x, 1.0 + expected_velocity, 0.000001)
	assert_true(widget.offset_transform_scale.x > 1.03, "the first frame should be crisp rather than a slow generic spring")


func test_card_shadow_uses_unwarped_alpha_and_height_parallax():
	var shadow_shader: Shader = load("res://ui/card_shadow.gdshader")
	assert_not_null(shadow_shader)
	assert_true(shadow_shader.code.contains("texture(TEXTURE, UV).a"), "shadow should reuse the unwarped card alpha")
	assert_true(shadow_shader.code.contains("blur_radius_px"), "overlapping cards need a compact silhouette-edge blur")
	assert_true(shadow_shader.code.contains("min(card_alpha, 1.0) * shadow_color.a"), "shadow should tint only the blurred card silhouette")
	assert_false(shadow_shader.code.contains("tilt"), "the table shadow must not accept pointer perspective")

	var left_idle := CardWidget._shadow_offset_for_height(CardWidget.SHADOW_IDLE_HEIGHT, 0.0, 1000.0)
	var right_idle := CardWidget._shadow_offset_for_height(CardWidget.SHADOW_IDLE_HEIGHT, 1000.0, 1000.0)
	var left_drag := CardWidget._shadow_offset_for_height(CardWidget.SHADOW_DRAG_HEIGHT, 0.0, 1000.0)
	assert_true(left_idle.x > 0.0, "a card left of screen center should cast inward to the right")
	assert_true(right_idle.x < 0.0, "a card right of screen center should cast inward to the left")
	assert_true(left_idle.y > 0.0, "the overhead-light shadow should fall below the card")
	assert_true(left_drag.length() > left_idle.length() * 1.5, "drag height should separate the shadow without changing its silhouette")
	var idle_exposure := CardWidget._shadow_bottom_exposure_for_height(CardWidget.SHADOW_IDLE_HEIGHT)
	var drag_exposure := CardWidget._shadow_bottom_exposure_for_height(CardWidget.SHADOW_DRAG_HEIGHT)
	assert_true(
		idle_exposure >= CardWidget.CARD_SIZE.y * 0.04,
		"idle shadow must retain a visible contact strip after scale compensation"
	)
	assert_true(
		idle_exposure <= CardWidget.CARD_SIZE.y * 0.055,
		"idle shadow should stay compact rather than becoming a halo"
	)
	assert_true(
		drag_exposure >= CardWidget.CARD_SIZE.y * 0.07,
		"drag shadow should visibly separate from the raised card"
	)
	assert_true(
		drag_exposure <= CardWidget.CARD_SIZE.y * 0.09,
		"drag shadow should remain proportional to card size"
	)
	assert_true(
		drag_exposure < idle_exposure * 2.0,
		"drag emphasis must not make the idle shadow comparatively disappear"
	)


func test_card_drag_height_changes_shadow_without_reusing_perspective_material():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	widget.make_drag_preview(Vector2.ZERO, 0.0, Vector2.ONE)
	for frame in 18:
		widget._update_depth_layers(Vector2(0.8, -0.7), true, 1.0 / 60.0)

	assert_true(widget._shadow_height > 0.30, "held cards should raise their shadow toward the original drag height")
	assert_ne(widget._shadow_surface.material, widget._perspective_material)
	assert_true(widget._shadow_surface.scale.x < 0.95, "a raised shadow should shrink slightly like the original 2D pass")


func test_card_selected_shadow_stays_on_the_table_plane_and_softens_overlap():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	widget.set_selected(true)
	widget.offset_transform_position = Vector2(0.0, -CardWidget.SELECTED_LIFT)
	widget._update_shadow_projection(false, 1.0)
	var projection := widget._shadow_surface.position + Vector2.ONE * CardWidget.VISUAL_MARGIN
	assert_almost_eq(
		projection.y,
		CardWidget._shadow_offset_for_height(
			CardWidget.SHADOW_SELECTED_HEIGHT,
			widget.get_global_rect().get_center().x,
			widget.get_viewport_rect().size.x
		).y + CardWidget.SELECTED_LIFT,
		0.001,
		"selected-face lift must be cancelled so the shadow remains on lower cards"
	)
	assert_almost_eq(widget._shadow_height, CardWidget.SHADOW_SELECTED_HEIGHT, 0.001)
	assert_true(
		float(widget._shadow_material.get_shader_parameter("blur_radius_px")) > 1.35,
		"selected cards should soften the silhouette edge where cards overlap"
	)


func test_card_widget_drag_preview_starts_from_selected_pose_without_angle_jump():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	var selected_position := Vector2(1.5, -11.0)
	var selected_rotation := deg_to_rad(1.25)
	var selected_scale := Vector2.ONE * 1.04
	widget.make_drag_preview(
		selected_position,
		selected_rotation,
		selected_scale
	)
	assert_eq(widget.offset_transform_position, selected_position, "drag preview must start at the selected lift")
	assert_eq(widget.offset_transform_scale, selected_scale, "drag preview must start at the selected scale")
	assert_almost_eq(
		widget.offset_transform_rotation, selected_rotation, 0.000001,
		"starting a drag must not add a fixed left tilt"
	)
	stage.add_child(widget)
	# The first drag sample only establishes the pointer baseline.  Calling the
	# step directly keeps this visual contract independent of GUT's scene-tree
	# scheduling, which can otherwise advance a newly attached preview beyond
	# its initial pointer baseline before this coroutine resumes in a full run.
	widget._step_drag_motion(Vector2.ZERO, 1.0 / 60.0)

	assert_eq(widget.mouse_filter, Control.MOUSE_FILTER_IGNORE, "drag preview should not intercept drop targets")
	assert_true(
		widget.offset_transform_position.distance_to(selected_position) < 0.1,
		"the first spring step should remain visually continuous with the selected pose"
	)
	assert_true(
		absf(widget.offset_transform_rotation - selected_rotation) < deg_to_rad(0.1),
		"the first spring step should not create an angle pop"
	)


func test_card_widget_drag_motion_stays_with_pointer_swings_and_updates_drop_pose():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var payload: Dictionary = {}
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	widget.make_drag_preview(Vector2(0, -12), 0.0, Vector2.ONE * CardWidget.HOVER_SCALE, payload)
	widget._step_drag_motion(Vector2(100, 100), 1.0 / 60.0)
	widget._step_drag_motion(Vector2(124, 100), 1.0 / 60.0)

	assert_true(
		absf(widget._drag_rest_position.x - widget.offset_transform_position.x) < 0.25,
		"the drag preview root already follows the cursor, so its visual must not add a second positional delay"
	)
	assert_true(widget.offset_transform_rotation > 0.0, "rightward movement should swing the held card clockwise")
	assert_eq(payload.get("drag_visual_position"), widget.offset_transform_position)
	assert_almost_eq(
		float(payload.get("drag_visual_rotation")), widget.offset_transform_rotation, 0.000001,
		"drop data must track the live held-card angle, not the pickup snapshot"
	)
	assert_eq(payload.get("drag_visual_scale"), widget.offset_transform_scale)


func test_card_widget_drag_direction_reversal_is_smooth_then_changes_swing():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	widget.make_drag_preview(Vector2(0, -12), 0.0, Vector2.ONE * CardWidget.HOVER_SCALE)
	widget._step_drag_motion(Vector2(100, 100), 1.0 / 60.0)
	for x in [112.0, 124.0, 136.0, 148.0]:
		widget._step_drag_motion(Vector2(x, 100), 1.0 / 60.0)
	var right_angle := widget.offset_transform_rotation
	assert_true(right_angle > 0.0)

	widget._step_drag_motion(Vector2(124, 100), 1.0 / 60.0)
	var first_reverse_angle := widget.offset_transform_rotation
	assert_true(
		absf(first_reverse_angle - right_angle) < deg_to_rad(5.0),
		"reversing the mouse must not snap the card to the opposite angle in one frame"
	)
	for x in [104.0, 84.0, 64.0, 44.0, 24.0, 4.0]:
		widget._step_drag_motion(Vector2(x, 100), 1.0 / 60.0)
	assert_true(widget.offset_transform_rotation < 0.0, "continued leftward movement should smoothly reverse the swing")


func test_card_widget_selected_pose_uses_original_highlight_height_without_scale_impulse():
	var card := {"id": 2000001, "instance_uid": 42, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	widget.set_selected(true)
	for frame in 30:
		widget._step_interaction_motion(1.0 / 60.0)
	assert_true(widget.is_selected())
	assert_almost_eq(
		widget.offset_transform_position.y, -CardWidget.SELECTED_LIFT, 0.5,
		"highlighted cards should use CardArea's 0.2-card-height lift"
	)
	assert_almost_eq(widget.offset_transform_scale.x, 1.0, 0.001, "selection alone must not add hover zoom")

	var selected_rotation := widget.offset_transform_rotation
	widget.set_selected(false)
	widget._step_interaction_motion(1.0 / 60.0)
	assert_true(
		absf(widget.offset_transform_rotation - selected_rotation) < deg_to_rad(5.0),
		"deselecting should begin from the current angle without a transform reset"
	)
	for frame in 45:
		widget._step_interaction_motion(1.0 / 60.0)
	assert_false(widget.is_selected())
	assert_true(widget.offset_transform_position.length() < 0.5, "deselected cards should spring back to their base pose")
	assert_almost_eq(widget.offset_transform_scale.x, 1.0, 0.01)


func test_card_widget_deal_in_uses_visual_offset_and_settles():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	await wait_process_frames(1)
	var stable_position := Vector2(120, 18)
	widget.set_hand_pose(stable_position, 0.0, 0)
	widget.set_hand_idle(true, 0)
	widget.play_deal_in(Vector2(320, 32), 0)

	assert_eq(widget.position, stable_position, "deal animation must not move the stable hand slot")
	assert_true(widget.offset_transform_position.x > 0.0, "card should start from the right-side deal origin")
	assert_eq(widget.mouse_filter, Control.MOUSE_FILTER_IGNORE, "an incoming card must not intercept hand input")
	await wait_seconds(0.42)
	assert_almost_eq(widget.offset_transform_position.x, 0.0, 1.0, "dealt card should settle into its hand slot")
	assert_almost_eq(widget.offset_transform_scale.x, 1.0, 0.02, "dealt card should finish at normal scale")
	assert_eq(widget.mouse_filter, Control.MOUSE_FILTER_STOP, "settled card should restore interaction")


func test_card_widget_reflow_keeps_slot_stable_and_animates_visual_position():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	await wait_process_frames(1)
	var stable_position := Vector2(220, 18)
	widget.set_hand_pose(stable_position, 0.0, 0)
	widget.set_hand_idle(true, 0)
	widget.play_hand_reflow(Vector2(58, 0))

	assert_eq(widget.position, stable_position, "reflow should leave the new hit-test slot stable")
	assert_true(widget.offset_transform_position.x > 40.0, "remaining card should begin at its former visual position")
	await wait_seconds(0.34)
	assert_almost_eq(widget.offset_transform_position.x, 0.0, 1.0, "remaining card should settle into the recentered hand")
	assert_eq(widget.mouse_filter, Control.MOUSE_FILTER_STOP, "settled remaining card should restore interaction")


func test_game_screen_card_rail_reserves_hover_lift_space():
	var rng := RNG.new(10)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var rail_padding := _find_node_by_name(screen, "CardRailPadding") as MarginContainer
	var card_rail := _find_node_by_name(screen, "CardRail") as Control
	assert_not_null(rail_padding, "clipped card rail should reserve inset space for hover lift and shadow")
	if rail_padding != null:
		assert_true(rail_padding.get_theme_constant("margin_top") >= 20, "rail top inset should keep the raised card inside the viewport")
		assert_true(
			rail_padding.get_theme_constant("margin_bottom") >= 16,
			"rail bottom inset should preserve the hand position while exposing card shadows"
		)
	assert_not_null(card_rail, "card rail viewport should exist")
	if card_rail != null:
		assert_false(card_rail is ScrollContainer, "hand navigation must not expose a scrollbar")
		assert_almost_eq(
			card_rail.position.y + card_rail.size.y, screen._effective_view_size().y, 1.0,
			"the central hand clip should extend to the viewport bottom like its side siblings"
		)
	if rail_padding != null and card_rail != null:
		assert_almost_eq(rail_padding.size.x, card_rail.size.x, 1.0, "hand content must use the rail width, not the whole viewport")
		assert_almost_eq(screen._card_items.size.x, card_rail.size.x, 1.0, "centering should be calculated inside the hand rail")


func test_game_screen_idle_hand_is_centered_spaced_and_straight():
	var rng := RNG.new(10)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(3)

	var cards := _rail_card_widgets(screen)
	assert_true(cards.size() >= 3, "starting rail should have enough cards to show centred spacing")
	if cards.size() < 3:
		return
	var first := cards[0] as CardWidget
	var last := cards[cards.size() - 1] as CardWidget
	var hand_left := first.position.x
	var hand_right := last.position.x + last.size.x
	assert_almost_eq((hand_left + hand_right) * 0.5, screen._card_items.size.x * 0.5, 2.0, "untouched hand should be centred")
	assert_true(cards[1].position.x - first.position.x > CardWidget.CARD_SIZE.x, "ordinary hands should leave every card border visible")
	assert_almost_eq(first.position.y, last.position.y, 0.1, "this game's hand should stay on a straight baseline")
	assert_almost_eq(first.rotation, 0.0, 0.001, "idle drift must not turn the stable hand layout into a fan")
	assert_almost_eq(last.rotation, 0.0, 0.001, "idle drift must remain a visual-only offset")
	assert_almost_eq(screen._card_items.modulate.a, 1.0, 0.001, "hand should only become opaque after its first valid layout")


func test_game_screen_dragging_card_out_closes_gap_immediately():
	var rng := RNG.new(10)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_seconds(0.65)

	var cards := _rail_card_widgets(screen)
	assert_true(cards.size() >= 3)
	if cards.size() < 3:
		return
	var dragged := cards[0] as CardWidget
	var neighbour := cards[1] as CardWidget
	var old_neighbour_x := neighbour.position.x
	dragged._hide_source_for_drag()

	assert_false(dragged.visible, "drag source should leave the stable hand layout")
	assert_true(neighbour.position.x < old_neighbour_x, "remaining hand should close the empty slot while dragging")
	assert_true(neighbour.offset_transform_position.x > 10.0, "gap closing should animate from the former visual slot")


func test_game_screen_hand_drop_preview_opens_insertion_gap():
	var rng := RNG.new(10)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_seconds(0.65)

	var cards := _rail_card_widgets(screen)
	assert_true(cards.size() >= 3)
	if cards.size() < 3:
		return
	var old_span := (cards[-1] as CardWidget).position.x - (cards[0] as CardWidget).position.x
	screen._preview_hand_drop(
		{"type": "card", "card_uid": 990001, "source": "slot"},
		_hand_drop_between(screen, 1, 2)
	)
	var new_span := (cards[-1] as CardWidget).position.x - (cards[0] as CardWidget).position.x

	assert_true(screen._hand_drop_preview_index >= 0, "hovering a dragged card over the hand should reserve an insertion slot")
	assert_true(new_span > old_span + CardWidget.CARD_SIZE.x * 0.5, "existing cards should visibly make room instead of being covered")
	screen._clear_hand_drop_preview()
	assert_eq(screen._hand_drop_preview_index, -1)


func test_game_screen_remaining_cards_animate_from_old_slots_after_one_is_played():
	var rng := RNG.new(10)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_seconds(0.65)

	var removed_uid := int(state.hand[0])
	var remaining_uid := int(state.hand[1])
	state.remove_card_from_hand(removed_uid)
	screen.refresh()
	await wait_process_frames(1)
	var remaining := _find_card_widget_by_uid(screen, remaining_uid)
	assert_not_null(remaining, "a neighbouring hand card should remain after one card is played")
	if remaining == null:
		return
	assert_true(absf(remaining.offset_transform_position.x) > 10.0, "remaining card should still render near its former slot while reflow begins")
	await wait_seconds(0.34)
	assert_almost_eq(remaining.offset_transform_position.x, 0.0, 1.0, "remaining card should settle into its new centred slot")


func test_game_screen_inserts_returned_slot_card_by_hand_drop_position():
	var rng := RNG.new(10)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var returned_id := int(state.hand[2])
	var first_id := int(state.hand[0])
	var second_id := int(state.hand[1])
	state.remove_card_from_hand(returned_id)
	state.add_card_to_slot(returned_id, 1, db)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var card_rail := _find_node_by_name(screen, "CardRail") as Control
	assert_not_null(card_rail, "card rail should exist")
	if card_rail == null:
		return
	var hand_widgets := _hand_card_widgets(screen)
	assert_true(hand_widgets.size() >= 3, "hand rail should have enough cards to test insertion")
	if hand_widgets.size() < 3:
		return
	screen.drop_card_to_hand(
		{
			"type": "card",
			"card_id": returned_id,
			"source": "slot",
			"source_slot": "s1",
			"grab_offset": Vector2(12, 20),
			"drag_visual_position": Vector2(1.5, -11.0),
			"drag_visual_rotation": deg_to_rad(1.25),
			"drag_visual_scale": Vector2.ONE * 1.04,
			"drag_visual_tilt": Vector2(0.4, -0.3),
		},
		_hand_drop_between(screen, 1, 2)
	)

	assert_eq(state.hand[0], first_id)
	assert_eq(state.hand[1], second_id)
	assert_eq(state.hand[2], returned_id, "returned card should insert at the drop position instead of appending blindly")
	var returned_widget := _find_card_widget_by_uid(screen, returned_id)
	assert_not_null(returned_widget, "returned card should be rendered in its reserved hand slot")
	if returned_widget != null:
		assert_true(absf(returned_widget.offset_transform_position.x) > 10.0, "returned card should settle from the cursor instead of appearing under another card")
		assert_almost_eq(
			returned_widget.offset_transform_rotation, deg_to_rad(1.25), 0.000001,
			"returned card should begin from the drag preview angle without snapping"
		)


func test_game_screen_reorders_hand_card_by_hand_drop_position():
	var rng := RNG.new(11)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var moved_id := int(state.hand[2])
	var first_id := int(state.hand[0])
	var second_id := int(state.hand[1])
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	screen.drop_card_to_hand(
		{"type": "card", "card_id": moved_id, "source": "hand"},
		_hand_drop_between(screen, 0, 1)
	)

	assert_eq(state.hand[0], first_id)
	assert_eq(state.hand[1], moved_id, "hand card should reorder to the drop position")
	assert_eq(state.hand[2], second_id)


func test_game_screen_reorders_hand_card_to_left_and_right_edges():
	var rng := RNG.new(12)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var moved_left_id := int(state.hand[3])
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	screen.drop_card_to_hand(
		{"type": "card", "card_id": moved_left_id, "source": "hand"},
		_hand_drop_left_of(screen, 0)
	)
	assert_eq(state.hand[0], moved_left_id, "dropping left of the first card should insert at the front")

	var moved_right_id := int(state.hand[0])
	screen.refresh()
	await wait_process_frames(1)
	screen.drop_card_to_hand(
		{"type": "card", "card_id": moved_right_id, "source": "hand"},
		_hand_drop_right_of(screen, _hand_card_widgets(screen).size() - 1)
	)
	assert_eq(state.hand[state.hand.size() - 1], moved_right_id, "dropping right of the last card should append to the end")


func test_game_screen_can_insert_hand_card_left_of_sudan_card():
	var rng := RNG.new(13)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var sudan_uid := int(state.active_sudan_cards[0].card_uid)
	var moved_uid := int(state.hand[1])
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	screen.drop_card_to_hand(
		{"type": "card", "card_uid": moved_uid, "source": "hand"},
		_rail_drop_left_of_card(screen, sudan_uid)
	)

	assert_eq(state.rail_order.find(moved_uid), state.rail_order.find(sudan_uid) - 1, "hand cards should be able to insert directly left of a sudan card")


func test_game_screen_can_reorder_sudan_card_in_bottom_rail():
	var rng := RNG.new(14)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var sudan_uid := int(state.active_sudan_cards[0].card_uid)
	var first_hand_uid := int(state.hand[0])
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	screen.drop_card_to_hand(
		{"type": "card", "card_uid": sudan_uid, "source": "active_sudan"},
		_rail_drop_left_of_card(screen, first_hand_uid)
	)

	assert_eq(state.rail_order[0], sudan_uid, "active sudan cards should be reorderable in the same bottom rail")


func test_game_screen_defaults_drawn_sudan_card_to_front_of_rail():
	var rng := RNG.new(15)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var sudan_id := RoundLoop.draw_weekly_sudan(state, db, rng)
	var sudan_uid := int(state.active_sudan_cards[0].card_uid)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	assert_eq(state.rail_order[0], sudan_uid, "newly drawn sudan cards should default to the first rail position")
	var rail_widgets := _rail_card_widgets(screen)
	assert_true(rail_widgets.size() > 0, "rail should render at least one card")
	if rail_widgets.size() > 0:
		assert_eq(int((rail_widgets[0] as CardWidget).card_id), sudan_id, "rendered rail should show the sudan card first")


func test_game_screen_can_open_card_detail_overlay():
	var rng := RNG.new(9)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	screen.show_card_detail(int(state.hand[0]))
	await wait_process_frames(1)

	assert_not_null(_find_node_by_name(screen, "CardDetailOverlay"), "clicking a card should open a main-screen card detail overlay")
	assert_not_null(_find_node_by_name(screen, "CardDetailPanel"), "card detail should render as a floating panel, not a standalone screen")
	assert_not_null(_find_node_by_name(screen, "CloseCardDetailButton"), "card detail overlay should be closable")
	var subtitle := _find_node_by_name(screen, "CardDetailSubtitle") as Label
	assert_not_null(subtitle)
	if subtitle != null:
		assert_string_contains(subtitle.text, "自身", "the protagonist card should expose its single-character role")
	var selected_widget := _find_card_widget_by_uid(screen, int(state.hand[0]))
	assert_not_null(selected_widget)
	if selected_widget != null:
		assert_true(selected_widget.is_selected(), "the detailed card should retain Balatro-style selected lift")
	screen.refresh()
	await wait_process_frames(2)
	selected_widget = _find_card_widget_by_uid(screen, int(state.hand[0]))
	assert_not_null(selected_widget)
	if selected_widget != null:
		assert_true(selected_widget.is_selected(), "refreshing the rail must preserve the detailed card's selected pose")

	screen.show_card_detail(int(state.hand[0]))
	await wait_process_frames(1)
	assert_null(_find_node_by_name(screen, "CardDetailOverlay"), "clicking the same card again should close the detail overlay")
	if selected_widget != null:
		assert_false(selected_widget.is_selected(), "closing the detail should smoothly deselect the card")


func test_card_detail_lists_attached_equipment() -> void:
	var rng := RNG.new(901)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var host_uid := int(state.hand[0])
	var equipment_uid := state.add_card_to_hand(2000246, db)
	state.attach_equipment(host_uid, equipment_uid, db, true, true)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	screen.show_card_detail(host_uid)
	await wait_process_frames(1)
	var detail := _find_node_by_name(screen, "CardDetailPanel")
	var text := _collect_label_and_button_text(detail)
	assert_true(text.find("装备") >= 0, "card detail exposes an equipment section")
	assert_true(text.find("匕首") >= 0, "the attached equipment name is visible to the player")


func test_game_screen_right_actions_do_not_duplicate_rite_entry():
	var rng := RNG.new(7)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var right_actions := _find_node_by_name(screen, "RightActions")
	assert_not_null(right_actions, "right action column should exist")
	if right_actions == null:
		return
	assert_eq(_count_buttons(right_actions), 3, "right actions contain next-day, redraw, and back-to-prev controls")
	assert_not_null(_find_node_by_name(right_actions, "AdvanceDayButton"), "next-day action remains in the right column")
	assert_not_null(_find_node_by_name(right_actions, "RedrawSudanButton"), "redraw action remains in the right column")
	assert_not_null(_find_node_by_name(right_actions, "BackToPrevButton"), "back-to-prev action stays in the right column")
	assert_null(_find_node_by_name(right_actions, "OpenRiteSelectorButton"), "rite selector should not be duplicated beside the desk sites")


func test_game_screen_menu_entry_stays_above_local_rite_overlay():
	var rng := RNG.new(8)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var hud := _find_node_by_name(screen, "Hud") as Control
	var menu := _find_node_by_name(screen, "MenuButton") as Control
	var overlay := _find_node_by_name(screen, "OverlayLayer") as Control
	var desk := _find_node_by_name(screen, "SituationDesk") as Control
	var rail := _find_node_by_name(screen, "CardRail") as Control
	var right_actions := _find_node_by_name(screen, "RightActions") as Control
	assert_not_null(hud, "HUD should exist")
	assert_not_null(menu, "menu should exist")
	assert_not_null(overlay, "rite overlay layer should exist")
	assert_not_null(desk)
	assert_not_null(rail)
	assert_not_null(right_actions)
	if hud == null or menu == null or overlay == null or desk == null or rail == null or right_actions == null:
		return
	assert_eq(menu.get_parent(), screen, "menu button should be separate from the HUD info panel")
	assert_true(menu.get_index() < overlay.get_index(), "menu ordering must not be the source of its global priority")
	assert_gt(menu.z_index, overlay.z_index, "the global menu entry must remain reachable over local modals")
	for child in desk.get_children():
		if child is CanvasItem:
			assert_lt(
				(child as CanvasItem).z_index,
				overlay.z_index,
				"every desk control must remain below modal overlays: %s" % child.name
			)
	assert_gt(rail.z_index, overlay.z_index, "the card rail must remain usable above the rite shade")
	assert_gt(right_actions.z_index, overlay.z_index, "persistent actions retain their established layer")


func test_game_screen_matches_mockup_spatial_layout():
	var rng := RNG.new(4)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var hud := _find_node_by_name(screen, "Hud") as Control
	var desk_map := _find_node_by_name(screen, "DeskMap") as Control
	var rail_label := _find_node_by_name(screen, "RailLabel") as Control
	var card_rail := _find_node_by_name(screen, "CardRail") as Control
	var right_actions := _find_node_by_name(screen, "RightActions") as Control
	var advance := _find_node_by_name(screen, "AdvanceDayButton") as Control
	var menu := _find_node_by_name(screen, "MenuButton") as Control

	assert_not_null(hud, "mockup layout needs a named top Hud")
	assert_not_null(menu, "mockup layout needs a separate menu button")
	assert_not_null(desk_map, "mockup layout needs a named middle DeskMap")
	assert_not_null(rail_label, "mockup layout needs a named bottom-left RailLabel")
	assert_not_null(card_rail, "mockup layout needs a named bottom CardRail")
	assert_not_null(right_actions, "mockup layout needs named bottom-right RightActions")
	assert_not_null(advance, "mockup layout needs a named AdvanceDayButton")
	if hud == null or menu == null or desk_map == null or rail_label == null or card_rail == null or right_actions == null or advance == null:
		return

	assert_almost_eq(hud.position.x, 20.0, 4.0, "Hud should follow the mockup left inset")
	assert_almost_eq(hud.position.y, 16.0, 4.0, "Hud should follow the mockup top inset")
	assert_true(hud.size.x < 360.0, "Hud should only frame the left status information")
	assert_true(menu.position.x > 1060.0, "Menu button should be a separate top-right control")
	assert_true(menu.get_parent() == screen, "Menu button should not live inside the Hud panel")
	assert_true(desk_map.position.y > hud.position.y + hud.size.y, "DeskMap should sit below the Hud")
	assert_true(desk_map.size.x > 1080.0, "DeskMap should use the broad middle area")
	assert_true(desk_map.size.y > 330.0, "DeskMap should be the dominant middle area")
	assert_true(
		card_rail.position.y < desk_map.position.y + desk_map.size.y,
		"the painted tabletop should continue behind the front-facing card rail"
	)
	assert_almost_eq(card_rail.position.x, 162.0, 8.0, "CardRail should leave room for the mockup rail label")
	assert_true(card_rail.size.x < 840.0, "CardRail should leave room for the right action column")
	assert_true(rail_label.position.x < card_rail.position.x, "RailLabel should be left of CardRail")
	assert_true(right_actions.position.x > card_rail.position.x + card_rail.size.x, "RightActions should be right of CardRail")
	assert_true(advance.size.x >= 110.0 and advance.size.y >= 110.0, "AdvanceDayButton should be the large round bottom action")


func test_situation_desk_keeps_actions_separate_at_narrow_width():
	var rng := RNG.new(41)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var stage := _stage(Vector2(720, 720))
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var desk := _find_node_by_name(screen, "SituationDesk") as Control
	var title := _find_node_by_name(screen, "SituationDeskTitle") as Control
	var rail := _find_node_by_name(screen, "CardRail") as Control
	var advance := _find_node_by_name(screen, "AdvanceDayButton") as Control
	var overlay := _find_node_by_name(screen, "OverlayLayer") as Control
	assert_not_null(desk)
	assert_not_null(title)
	assert_not_null(rail)
	assert_not_null(advance)
	assert_not_null(overlay)
	if desk == null or title == null or rail == null or advance == null or overlay == null:
		return
	assert_true(desk.visible, "narrow layouts should still open on the desk")
	assert_lt(rail.get_global_rect().end.x, advance.get_global_rect().position.x, "hand rail and next-day action should remain separate")
	assert_gt(overlay.z_index, desk.z_index, "queue overlays should remain above the paper desk")


func test_rite_view_uses_wide_viewport_width():
	var rng := RNG.new(2)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage()
	var view = RiteView.new()
	view.setup(state, db, rng, 5000001)
	stage.add_child(view)
	await wait_process_frames(2)

	var shade := _find_node_by_name(view, "RiteModalShade") as Control
	var slot_layer := _find_node_by_name(view, "RiteSlotOverlay") as Control
	assert_not_null(shade, "rite overlay should include a full-screen modal shade")
	assert_not_null(slot_layer, "rite overlay should include a full-screen slot layer")
	if shade != null:
		assert_true(shade.size.x >= MIN_CONTENT_WIDTH, "rite modal shade should cover the wide viewport")
	if slot_layer != null:
		assert_true(slot_layer.size.x >= MIN_CONTENT_WIDTH, "rite slot layer should cover the wide viewport")


## The real new-run entry fires the opening round_begin_ba chain (intro
## events) like the original startup; UI tests drain it to reach the desk.
func _drain_intro_events(game) -> void:
	while not game.state.pending_operation().is_empty():
		game.state.consume_pending_operation()
	if game._game_screen != null:
		game._game_screen.refresh()


func _stage(view_size: Vector2 = WIDE_VIEWPORT) -> Control:
	var stage: Control = Control.new()
	add_child_autofree(stage)
	stage.size = view_size
	return stage


func _widest_content(node: Node) -> float:
	var widest := 0.0
	if node is PanelContainer or node is VBoxContainer or node is HBoxContainer or node is ScrollContainer:
		widest = max(widest, (node as Control).size.x)
	for child in node.get_children():
		widest = max(widest, _widest_content(child))
	return widest


func _narrowest_direct_panel(screen: Control) -> float:
	var direct_narrowest := INF
	for child in screen.get_children():
		if child is PanelContainer and child.name in ["Hud", "DeskMap"]:
			direct_narrowest = min(direct_narrowest, (child as PanelContainer).size.x)
	if direct_narrowest < INF:
		return direct_narrowest
	for child in screen.get_children():
		if child is MarginContainer:
			var root := (child as MarginContainer).get_child(0)
			var narrowest := INF
			for section in root.get_children():
				if section is PanelContainer:
					narrowest = min(narrowest, (section as PanelContainer).size.x)
			return narrowest
	return 0.0


func _find_node_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target)
		if found != null:
			return found
	return null


func _count_nodes_by_name(node: Node, target: String) -> int:
	var count := 1 if node.name == target else 0
	for child in node.get_children():
		count += _count_nodes_by_name(child, target)
	return count


func _count_card_widgets(node: Node) -> int:
	var count := 1 if node is CardWidget else 0
	for child in node.get_children():
		count += _count_card_widgets(child)
	return count


func _hand_card_widgets(node: Node) -> Array:
	var out: Array = []
	if node is CardWidget and (node as CardWidget).drag_source == "hand":
		out.append(node)
	for child in node.get_children():
		out.append_array(_hand_card_widgets(child))
	return out


func _rail_card_widgets(node: Node) -> Array:
	var out: Array = []
	if node is CardWidget:
		out.append(node)
	for child in node.get_children():
		out.append_array(_rail_card_widgets(child))
	return out


func _find_card_widget_by_uid(node: Node, card_uid: int) -> CardWidget:
	for widget in _rail_card_widgets(node):
		if int((widget as CardWidget).card_uid) == card_uid and not widget.is_queued_for_deletion():
			return widget as CardWidget
	return null


func _hand_drop_between(screen, left_index: int, right_index: int) -> Vector2:
	var widgets := _hand_card_widgets(screen)
	var left := widgets[left_index] as Control
	var right := widgets[right_index] as Control
	var x := (left.position.x + left.size.x * 0.5 + right.position.x + right.size.x * 0.5) * 0.5
	return _rail_pos_for_card_items_local(screen, Vector2(x, 12))


func _hand_drop_left_of(screen, index: int) -> Vector2:
	var widgets := _hand_card_widgets(screen)
	var card := widgets[index] as Control
	return _rail_pos_for_card_items_local(screen, Vector2(card.position.x - 12, 12))


func _hand_drop_right_of(screen, index: int) -> Vector2:
	var widgets := _hand_card_widgets(screen)
	var card := widgets[index] as Control
	return _rail_pos_for_card_items_local(screen, Vector2(card.position.x + card.size.x + 12, 12))


func _rail_drop_left_of_card(screen, card_id: int) -> Vector2:
	for widget in _rail_card_widgets(screen):
		if int((widget as CardWidget).card_id) == card_id or int((widget as CardWidget).card_uid) == card_id:
			var card := widget as Control
			return _rail_pos_for_card_items_local(screen, Vector2(card.position.x - 12, 12))
	return _rail_pos_for_card_items_local(screen, Vector2.ZERO)


func _rail_pos_for_card_items_local(screen, local_pos: Vector2) -> Vector2:
	var card_rail := _find_node_by_name(screen, "CardRail") as Control
	var global_drop: Vector2 = screen._card_items.get_global_transform() * local_pos
	return card_rail.get_global_transform().affine_inverse() * global_drop


func _count_buttons(node: Node) -> int:
	var count := 1 if node is Button else 0
	for child in node.get_children():
		count += _count_buttons(child)
	return count


func _collect_label_and_button_text(node: Node) -> String:
	if node == null:
		return ""
	var parts: Array[String] = []
	if node is Label:
		parts.append((node as Label).text)
	elif node is Button:
		parts.append((node as Button).text)
	elif node is RichTextLabel:
		parts.append((node as RichTextLabel).text)
	for child in node.get_children():
		var child_text := _collect_label_and_button_text(child)
		if child_text != "":
			parts.append(child_text)
	return " ".join(parts)
