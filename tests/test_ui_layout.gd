extends GutTest

const RNG = preload("res://core/rng.gd")
const MainMenu = preload("res://ui/main_menu.gd")
const Game = preload("res://ui/game.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const RiteView = preload("res://ui/rite_view.gd")

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


func test_representative_main_screen_controls_exist():
	var state := GameState.new()
	state.setup_new_run(db, 1, RNG.new(71))
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, RNG.new(72))
	stage.add_child(screen)
	await wait_process_frames(2)

	for node_name in ["MenuButton", "Location_SelfHome", "AdvanceDayButton"]:
		var control := _find_node_by_name(screen, node_name)
		assert_not_null(control, "%s should exist" % node_name)


func test_begin_guide_replays_source_default_geometry():
	var state := GameState.new()
	state.setup_new_run(db, 1, RNG.new(711))
	state.begin_guide = {"type": "RIGHT_CLICK_CARD", "is_show_ring": true}
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, RNG.new(712))
	stage.add_child(screen)
	await wait_process_frames(2)

	var guide := _find_node_by_name(screen, "BeginGuide") as Control
	assert_not_null(guide)
	if guide == null:
		return
	var default_item := guide.get_node_or_null("Default") as Control
	var image := guide.get_node_or_null("Default/Image") as TextureRect
	var text := guide.get_node_or_null("Default/Text") as Label
	var close := guide.get_node_or_null("Default/Close") as Button
	var ring := guide.get_node_or_null("Default/Ring") as TextureRect
	assert_not_null(default_item)
	assert_not_null(image)
	assert_not_null(text)
	assert_not_null(close)
	assert_not_null(ring)
	if default_item == null or image == null or text == null or close == null or ring == null:
		return
	assert_eq(guide.size, Vector2(3840, 2160), "BeginGuide parent keeps the source canvas")
	assert_eq(default_item.position, Vector2(2067.3, 65), "Default replays its resolved source position")
	assert_eq(default_item.size, Vector2(1200, 460), "Default replays its source dimensions")
	assert_eq(image.position, Vector2(-356, 30), "the 400px mouse hint intentionally extends beyond Default")
	assert_eq(image.size, Vector2(400, 400))
	assert_eq(text.position, Vector2(35, 35), "Text uses the source stretch offsets")
	assert_eq(text.size, Vector2(1130, 390))
	assert_eq(text.get_theme_font_size("font_size"), 75)
	assert_eq(close.position, Vector2(1149.1, 410), "Close uses the source bottom-right anchor")
	assert_eq(close.size, Vector2(80, 80))
	assert_true(ring.visible, "is_show_ring displays the original ring child")
	assert_eq(ring.position, Vector2(-263, -219.5))
	assert_eq(ring.size, Vector2(314, 225))


func test_game_over_replays_source_stages_and_geometry():
	var state := GameState.new()
	state.setup_new_run(db, 1, RNG.new(713))
	state.over_reason = 12
	var stage := _stage()
	var over = preload("res://ui/game_over.gd").new()
	over.setup(state, db)
	stage.add_child(over)
	await wait_process_frames(2)

	assert_eq(over.name, "Over")
	assert_eq(over.size, Vector2(3840, 2160), "Over retains the source design canvas")
	var title_bg := over.get_node_or_null("Step1/Title BG") as Control
	assert_not_null(title_bg)
	if title_bg == null:
		return
	assert_eq(title_bg.position, Vector2(1442, 420))
	assert_eq(title_bg.size, Vector2(956, 1320))
	over.do_next()
	assert_not_null(over.get_node_or_null("Step2/CG"), "DoNext advances from source Step1 to CG")
	over.do_next()
	assert_not_null(over.get_node_or_null("Step3/MainMenuButton"), "no-story over node falls through to source result step")


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
	var archive_toggle := _find_node_by_name(menu, "UserArchiveLoadGameButton")
	assert_not_null(archive_toggle, "archives are reachable from the title menu")
	archive_toggle.pressed.emit()
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

	var strip := _find_node_by_name(screen, "RoundNumberBG")
	assert_not_null(strip, "the original deadline strip (RoundNumber BG) is the desktop HUD")
	var hud_text := _collect_label_and_button_text(strip)
	assert_true(hud_text.find("处决日") >= 0, "deadline strip keeps the original title")
	assert_eq(hud_text.find("回合"), -1, "HUD should not expose internal round wording")
	assert_eq(hud_text.find("金币"), -1, "gold should be represented as cards instead of a HUD counter")


func test_game_screen_hud_chrome_honors_player_visibility_preferences():
	var rng := RNG.new(51)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	state.sudan_box_show = true
	state.prestige_unshow = false
	state.deadline_unshow = false
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)

	var box := _find_node_by_name(screen, "SudanBox") as Control
	var prestige := _find_node_by_name(screen, "Prestige") as Control
	var deadline := _find_node_by_name(screen, "RoundNumberBG") as Control
	assert_true(box.visible, "sudan_box_show uses visible polarity")
	assert_true(prestige.visible, "a false prestige_unshow leaves the strip visible")
	assert_true(deadline.visible, "a false deadline_unshow leaves the strip visible")

	state.sudan_box_show = false
	state.prestige_unshow = true
	state.deadline_unshow = true
	screen.refresh()
	assert_false(box.visible, "sudan_box_show false hides the desktop box")
	assert_false(prestige.visible, "prestige_unshow true hides the desktop strip")
	assert_false(deadline.visible, "deadline_unshow true hides the deadline strip")


func test_game_screen_map_pin_and_menu_are_interactive():
	var rng := RNG.new(6)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.create_rite_instance(5000001)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)
	screen.refresh()

	var opened: Array[int] = []
	var menu_count := [0]
	screen.open_rite_instance.connect(func(rite_uid: int): opened.append(rite_uid))
	screen.menu_pressed.connect(func(): menu_count[0] += 1)

	var pin: Button = null
	for node in _find_node_by_name(screen, "SituationDesk").get_children():
		if node is Button and str(node.name).begins_with("RiteNew_"):
			pin = node
			break
	var menu := _find_node_by_name(screen, "MenuButton") as Button
	assert_not_null(pin, "an available rite should be an interactive RiteNew map card")
	assert_not_null(menu, "menu should be an interactive button")
	if pin != null:
		pin.pressed.emit()
	if menu != null:
		menu.pressed.emit()
	assert_eq(opened, [pin.rite_uid] if pin != null else [], "the pin must expose its exact runtime rite uid")
	assert_eq(menu_count[0], 1, "clicking menu should emit a menu action")


func test_rite_card_opens_its_runtime_rite_without_location_selector_shortcut():
	var stage := _stage()
	var game = Game.new()
	stage.add_child(game)
	await wait_process_frames(2)
	game._on_new_game_pressed()
	await wait_process_frames(2)
	_drain_intro_events(game)
	game.state.create_rite_instance(5000001)
	game._game_screen.refresh()
	await wait_process_frames(1)

	var screen := game._game_screen as Control
	var desk := _find_node_by_name(game, "SituationDesk") as Control
	var card_rail := _find_node_by_name(game, "CardRail") as Control
	var think_drop := _find_node_by_name(game, "ThinkDropZone") as Control
	var right_actions := _find_node_by_name(game, "RightActions") as Control
	var advance := _find_node_by_name(game, "AdvanceDayButton") as Button
	var redraw := _find_node_by_name(game, "RedrawSudanButton") as Button
	var menu := _find_node_by_name(game, "MenuButton") as Button
	assert_not_null(screen)
	assert_not_null(desk)
	assert_not_null(card_rail)
	assert_not_null(think_drop)
	assert_not_null(right_actions)
	assert_not_null(advance)
	assert_not_null(redraw)
	assert_not_null(menu)
	if screen == null or desk == null or card_rail == null or think_drop == null or right_actions == null or advance == null or redraw == null or menu == null:
		return
	var rite_card: Button = null
	for node in desk.get_children():
		if node is Button and str(node.name).begins_with("RiteNew_"):
			rite_card = node
			break
	assert_not_null(rite_card, "an available rite must render as its own RiteNew map card")
	if rite_card == null:
		return
	var rng_state_before: int = game.rng.get_state()
	rite_card.pressed.emit()
	await wait_process_frames(2)

	assert_eq(game.rng.get_state(), rng_state_before, "opening a pin must not consume simulation RNG")
	var rite_panel := _find_node_by_name(game, "RiteOverlayPanel") as Control
	assert_not_null(rite_panel, "a pin opens its rite directly")
	if rite_panel != null:
		assert_eq(rite_panel.get_parent().get_parent().get_parent().name, "SourceOverlayLayer", "RitePanelShow must bypass the legacy overlay scale")
	assert_null(_find_node_by_name(game, "RiteSelector"), "MapController has no location selector shortcut")
	assert_true(think_drop.visible, "the thought target remains visible under the rite overlay")
	assert_true(right_actions.visible)
	assert_true(advance.disabled, "rite overlay blocks progression controls")
	assert_true(redraw.disabled, "rite overlay blocks redraw controls")
	assert_true(menu.disabled, "rite overlay blocks the global menu entry")
	assert_eq(card_rail.mouse_filter, Control.MOUSE_FILTER_IGNORE, "rite overlay blocks direct rail input")


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
	var target_style := target.get_theme_stylebox("panel") as StyleBoxTexture
	assert_not_null(target_style, "the original IThink affordance is a textured panel")
	if target_style != null:
		assert_not_null(target_style.texture, "the thought target must use its original texture")
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
	# Events settle when they fire; the display queue only shows them. The
	# effects land before the panel opens and consuming just dismisses it.
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events[990002] = {
		"id": 990002,
		"name": "奖励事件",
		"text": "你获得了一些金币。",
		"result": {"金币": 7, "counter+7000001": 3},
		"on": {"game_end": -1},
	}
	var rng := RNG.new(21)
	var state := GameState.new()
	state.setup_new_run(local_db, 0, rng)
	state.enable_event(990002, local_db)
	state.trigger_events("game_end", {"ending": 3})
	assert_eq(state.coin_count, 7, "event result coin applied when the event fires")
	assert_eq(state.get_counter(7000001), 3, "event result counter applied when the event fires")
	# Interaction-bearing events display; a text+result event stays silent
	# unless its settlement queues a prompt.
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
	assert_eq(state.coin_count, 7, "consuming does not double-apply the settlement")


func test_game_screen_event_with_over_result_signals_game_over():
	# An `over` result settles silently and raises over_pending; the screen
	# signals game-over when it processes the outcome.
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.events[990003] = {
		"id": 990003,
		"name": "结局事件",
		"text": "一切都结束了。",
		"result": {"over": 1},
		"on": {"game_end": -1},
	}
	var rng := RNG.new(22)
	var state := GameState.new()
	state.setup_new_run(local_db, 0, rng)
	state.enable_event(990003, local_db)
	state.trigger_events("game_end", {"ending": 3})
	assert_true(state.over_pending, "the silent settlement raises over_pending")
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
	# Rite generation from a settled event parks the rite for the desk map;
	# the clone no longer force-opens the panel (the original's system
	# initialization events create many rites at once).
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.rites[990005] = {
		"id": 990005, "cards_slot": {"s1": {"condition": {}}}, "round_number": 1,
		"settlement": [], "settlement_prior": [], "settlement_extre": []}
	local_db.events[990004] = {
		"id": 990004,
		"text": "求助",
		"settlement": [{"action": {"rite": 990005}}],
		"on": {"game_end": -1},
	}
	var rng := RNG.new(23)
	var state := GameState.new()
	state.setup_new_run(local_db, 0, rng)
	state.enable_event(990004, local_db)
	state.trigger_events("game_end", {"ending": 3})
	assert_not_null(state.find_rite_instance_by_id(990005), "the settled event generates the rite")
	assert_false(state.available_rites.is_empty(), "the generated rite is available on the desk")


func test_game_menu_button_opens_real_overlay():
	var stage := _stage()
	var game = Game.new()
	stage.add_child(game)
	await wait_process_frames(2)

	game._on_new_game_pressed()
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
	assert_not_null(_find_node_by_name(game, "ESCPanel"), "menu must replay the source ESCPanel root")
	assert_null(_find_node_by_name(game, "NewGame"), "NewGame is inactive in ESCPanel.prefab")
	assert_not_null(_find_node_by_name(game, "Settings"), "source Settings entry must remain visible")
	assert_not_null(_find_node_by_name(game, "EndGame"), "source EndGame entry must remain visible")
	assert_not_null(_find_node_by_name(game, "SaveAndExit"), "source Main Menu entry must remain visible")
	assert_not_null(_find_node_by_name(game, "Return"), "source Return entry must remain visible")
	if overlay != null and rail != null:
		assert_gt(overlay.z_index, rail.z_index, "the menu must cover persistent hand cards")
		assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_STOP, "the global menu layer must block clicks behind it")
		var source_root := _find_node_by_name(overlay, "ESCPanel") as Control
		var shade := _find_node_by_name(source_root, "Mask") as Control
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
	var resume := _find_node_by_name(game, "Return") as Button
	if resume != null:
		resume.pressed.emit()
		await wait_process_frames(1)
		assert_false(desk.is_scene_blocked(), "resuming should release the menu blocker")
		assert_eq(
			(game._game_screen as Node).process_mode,
			Node.PROCESS_MODE_INHERIT,
			"resuming should reactivate the lower gameplay layer"
		)


func test_game_menu_replays_source_esc_geometry_and_end_game_call_chain():
	var stage := _stage()
	var game = Game.new()
	stage.add_child(game)
	await wait_process_frames(2)
	game._on_new_game_pressed()
	await wait_process_frames(2)
	_drain_intro_events(game)
	game._show_game_menu()
	await wait_process_frames(1)

	var esc := _find_node_by_name(game, "ESCPanel") as Control
	var group := _find_node_by_name(game, "ButtonGroup") as Control
	var settings := _find_node_by_name(game, "Settings") as Button
	var end_game := _find_node_by_name(game, "EndGame") as Button
	assert_not_null(esc)
	assert_not_null(group)
	assert_not_null(settings)
	assert_not_null(end_game)
	if esc == null or group == null or settings == null or end_game == null:
		return
	assert_eq(esc.size, Vector2(1920, 1080), "ESCPanel keeps its source canvas before its 2x transform")
	assert_eq(esc.scale, Vector2(2, 2), "ESCPanel replays its source root scale")
	assert_eq(group.position, Vector2(449.5, 312), "ButtonGroup remains centered in the source canvas")
	assert_eq(group.size, Vector2(1021, 456), "inactive NewGame is excluded by the source content fitter")
	assert_eq(settings.size, Vector2(405, 174), "source ESC buttons retain their authored dimensions")
	assert_eq(settings.position, Vector2(308, 0), "Settings starts the active source layout sequence")
	assert_eq(end_game.position, Vector2(308, 94), "source layout keeps the -80px vertical overlap")
	assert_false(settings.disabled, "ESCGameController.OnSettings must reach its source SettingsController host")
	settings.pressed.emit()
	await wait_process_frames(1)
	var settings_panel := _find_node_by_name(game, "SettingsController") as Control
	assert_not_null(settings_panel, "source SettingsController opens above the ESC panel")
	if settings_panel != null:
		var source_settings := _find_node_by_name(settings_panel, "SettingsPanel") as Control
		var panel_bg := _find_node_by_name(settings_panel, "PanelBG") as Control
		var music := _find_node_by_name(settings_panel, "MusicVolume") as Control
		var sound := _find_node_by_name(settings_panel, "SoundVolume") as Control
		assert_not_null(source_settings)
		assert_not_null(panel_bg)
		assert_not_null(music)
		assert_not_null(sound)
		if source_settings != null:
			assert_eq(source_settings.size, Vector2(1920, 1080), "SettingsPanel retains the source canvas")
			assert_eq(source_settings.scale, Vector2(2, 2), "SettingsPanel retains the source root scale")
		if panel_bg != null:
			assert_eq(panel_bg.size, Vector2(1788, 1200), "PanelBG replays its source prefab dimensions")
		if music != null:
			assert_eq(music.position, Vector2(0, 0), "MusicVolume remains first in SliderGroup")
		if sound != null:
			assert_eq(sound.position, Vector2(0, 80.5), "SoundVolume keeps the source 30.5px row separation")
		settings_panel.closed.emit()
		await wait_process_frames(1)
		assert_null(_find_node_by_name(game, "SettingsController"), "SettingsController.OnClose returns to ESCPanel")

	end_game.pressed.emit()
	await wait_process_frames(1)
	assert_true(game.state.success, "ESCGameController.OnEndGame writes Player.success")
	assert_eq(game.state.over_reason, 16, "ESCGameController.OnEndGame writes over_reason 0x10")
	assert_not_null(_find_node_by_name(game, "Over"), "EndGame continues into the source-shaped game-over controller")


func test_player_path_keeps_surface_ownership_and_modal_budget_intact():
	var stage := _stage()
	var game = Game.new()
	stage.add_child(game)
	await wait_process_frames(2)
	game._on_new_game_pressed()
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
		assert_eq(menu_overlay.get_parent(), game, "the source ESC panel attaches directly to Game, not LegacyLayer")
		assert_gt(menu_overlay.z_index, rail.z_index, "global menu outranks persistent hand cards")
		assert_eq(menu_overlay.mouse_filter, Control.MOUSE_FILTER_STOP, "global menu blocks clicks behind its shade")
	assert_true(desk.is_scene_blocked(), "the global menu blocks all lower desk input")
	var resume := _find_node_by_name(game, "Return") as Button
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
	game._on_new_game_pressed()
	await wait_process_frames(2)
	_drain_intro_events(game)
	game._show_user_archive_overlay()
	await wait_process_frames(1)

	var archive_panel := _find_node_by_name(game, "UserArchiveController") as Control
	var left := _find_node_by_name(game, "Left") as Control
	var scroll := _find_node_by_name(game, "Scroll View") as Control
	var first_slot := _find_node_by_name(game, "UserArchiveItem_00") as Button
	assert_not_null(archive_panel, "manual save opens the source UserArchiveController")
	assert_not_null(left, "archive controller replays its source left information column")
	assert_not_null(scroll, "archive controller replays its source scroll viewport")
	assert_not_null(first_slot, "archive controller renders its fixed source slot datasource, including empty slots")
	if archive_panel != null:
		assert_eq(archive_panel.size, Vector2(3840, 2160), "archive root retains the original full-canvas design space")
	if left != null:
		assert_eq(left.position, Vector2(200, 300), "Left replays its source inset after Unity-to-Godot coordinates")
		assert_almost_eq(left.size.x, 875.2, 0.01, "Left replays the source 28%-wide column with 200px inset")
		assert_almost_eq(left.size.y, 1560.0, 0.01, "Left preserves the source vertical insets")
	if scroll != null:
		assert_eq(scroll.position, Vector2(1228.8, 200), "Scroll View replays its source right-column origin")
		assert_almost_eq(scroll.size.x, 2511.2, 0.01, "Scroll View preserves its source width independent of item width")
		assert_almost_eq(scroll.size.y, 1760.0, 0.01, "Scroll View replays its source vertical insets")
	if first_slot != null:
		assert_eq(first_slot.custom_minimum_size, Vector2(2760, 240), "UserArchiveItem preserves the authored 2760x240 row")
	var empty_slot: Button
	for index in SaveSystem.MAX_USER_ARCHIVE_COUNT:
		var candidate := _find_node_by_name(game, "UserArchiveItem_%02d" % index) as Button
		if candidate != null and _find_node_by_name(candidate, "EmptyContent") != null:
			empty_slot = candidate
			break
	assert_not_null(empty_slot, "at least one source archive slot should be empty in this isolated test run")
	if empty_slot != null:
		empty_slot.pressed.emit()
		await wait_process_frames(1)
		assert_not_null(_find_node_by_name(game, "UserArchiveNameInput"), "selecting an empty source slot opens the separate name-input controller")
		var input := _find_node_by_name(game, "InputField (TMP)") as LineEdit
		var confirm := _find_node_by_name(game, "Confirm") as Button
		assert_not_null(input, "name controller owns the source-sized input field")
		assert_not_null(confirm, "name controller owns a separate confirm control")
		if input != null and confirm != null:
			assert_eq(input.max_length, 20, "source name input permits only 1–20 characters")
			assert_true(confirm.disabled, "empty archive names cannot be confirmed")
			input.text = "原作槽位"
			input.text_changed.emit(input.text)
			await wait_process_frames(1)
			assert_false(confirm.disabled, "a non-empty <=20-character name enables confirmation")
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


func test_card_widget_uses_source_prefab_rect_by_card_kind():
	var stage := _stage()
	var ordinary := CardWidget.make({"id": 2000001, "type": "char", "tag": {}})
	var sudan := CardWidget.make({"id": 7100001, "type": "sudan", "tag": {}})
	stage.add_child(ordinary)
	stage.add_child(sudan)
	await wait_process_frames(1)

	assert_eq(ordinary.card_size(), Vector2(194, 422), "CardNew prefab root is 194x422")
	assert_eq(ordinary.size, Vector2(194, 422), "normal card Control uses CardNew's direct RectTransform")
	assert_eq(sudan.card_size(), Vector2(185, 330), "SudanCard prefab root is 185x330")
	assert_eq(sudan.size, Vector2(185, 330), "Sudan card must not inherit CardNew's size")


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
	widget._hide_source_for_drag()
	assert_false(widget.visible, "source card should disappear from hand while dragging")
	assert_eq(widget.z_index, 0, "hidden drag source should release its temporary hover layer")

	widget._restore_source_after_failed_drag()
	assert_true(widget.visible, "source card should reappear if drop fails")
	assert_true(
		widget.is_hand_motion_active(),
		"a failed drop should tween back from the release point instead of snapping"
	)


func test_card_widget_hover_lifts_without_scale_or_perspective():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	await wait_process_frames(2)

	widget._set_hovered(true)
	assert_true(widget.z_index >= CardWidget.HOVER_Z_INDEX, "hovered card should render above neighbouring cards")
	assert_almost_eq(
		widget.offset_transform_position.y, -CardWidget.SELECTED_LIFT, 0.001,
		"hover should use CardArea's highlighted lift"
	)
	assert_almost_eq(widget.offset_transform_scale.x, 1.0, 0.001, "hover must not add clone-era zoom")
	assert_almost_eq(widget.offset_transform_rotation, 0.0, 0.000001, "hover must not tilt the card")
	assert_true(widget.offset_transform_visual_only, "hover transform should not distort the card's mouse hit rectangle")
	assert_not_null(_find_node_by_name(widget, "CardVisualFace"), "the card face should render as one flat surface")
	assert_null(
		_find_node_by_name(widget, "CardVisualSurface"),
		"the clone-era shader surface must stay removed"
	)
	assert_null(
		_find_node_by_name(widget, "CardShadowSurface"),
		"the clone-era shadow pass must stay removed"
	)

	widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	widget._set_hovered(false)
	await wait_process_frames(2)
	assert_eq(widget.z_index, 0, "card should return to its normal rail layer after hover")
	assert_almost_eq(widget.offset_transform_position.y, 0.0, 0.001)


func test_card_widget_drag_preview_tracks_cursor_without_own_motion():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	var selected_position := Vector2(1.5, -11.0)
	widget.make_drag_preview(selected_position, 0.0, Vector2.ONE)

	assert_eq(widget.offset_transform_position, selected_position, "drag preview must start at the pickup pose")
	assert_almost_eq(widget.offset_transform_rotation, 0.0, 0.000001, "the held card must not carry an angle")
	assert_almost_eq(widget.offset_transform_scale.x, 1.0, 0.000001, "the held card must not scale")
	assert_eq(widget.mouse_filter, Control.MOUSE_FILTER_IGNORE, "drag preview should not intercept drop targets")
	stage.add_child(widget)
	await wait_process_frames(6)
	assert_eq(
		widget.offset_transform_position, selected_position,
		"the preview root follows the drag cursor; the card must not add motion of its own"
	)


func test_card_widget_selected_pose_uses_original_highlight_height_without_scale_impulse():
	var card := {"id": 2000001, "instance_uid": 42, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	widget.set_selected(true)
	assert_true(widget.is_selected())
	assert_almost_eq(
		widget.offset_transform_position.y, -CardWidget.SELECTED_LIFT, 0.001,
		"highlighted cards should use CardArea's 0.2-card-height lift"
	)
	assert_almost_eq(widget.offset_transform_scale.x, 1.0, 0.001, "selection alone must not add hover zoom")
	assert_almost_eq(widget.offset_transform_rotation, 0.0, 0.000001)

	widget.set_selected(false)
	assert_false(widget.is_selected())
	assert_almost_eq(widget.offset_transform_position.y, 0.0, 0.001, "deselected cards should return flat to the rail")
	assert_almost_eq(widget.offset_transform_scale.x, 1.0, 0.001)


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


func test_game_screen_card_rail_replays_source_hand_and_mask_rects():
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
	assert_not_null(rail_padding, "source Hand child should exist inside the Hand Mask band")
	assert_not_null(card_rail, "card rail viewport should exist")
	if card_rail != null:
		assert_false(card_rail is ScrollContainer, "hand navigation must not expose a scrollbar")
		assert_false(card_rail.clip_contents, "inactive source Hand Mask must not clip raised CardArea visuals")
		assert_almost_eq(
			card_rail.position.y + card_rail.size.y, screen._effective_view_size().y, 1.0,
			"source Hand Mask reaches the viewport bottom"
		)
	if rail_padding != null and card_rail != null:
		var view := screen._effective_view_size()
		var k := Vector2(view.x / 3840.0, view.y / 2160.0)
		assert_almost_eq(rail_padding.position.x, 516.7349 * k.x, 1.0, "Hand's resolved left inset must replay GameScene")
		assert_almost_eq(rail_padding.position.y, 36.0 * k.y, 1.0, "Hand sits 36 pixels below the source mask top")
		assert_almost_eq(rail_padding.size.x, 2723.264 * k.x, 1.0, "Hand uses the source 2723.264 width, not full viewport width")
		assert_almost_eq(rail_padding.size.y, 430.0 * k.y, 1.0, "Hand keeps its source 430 height")
		assert_almost_eq(screen._card_items.size.x, rail_padding.size.x, 1.0, "card layout uses the source Hand rectangle")


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
	assert_almost_eq(cards[1].position.x - first.position.x, CardWidget.CARD_SIZE.x + 10.0, 0.1, "source HandCardsController uses 10 pixels of space between full cards")
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
	# HandCardsController's source minimum is 20 visible pixels. A crowded hand
	# is already at that limit, so an insertion does not invent a clone-only
	# full-card gap; its stable origins may shift by at most one compressed
	# minVisibleWidth notch as the last-card boundary is recomputed.
	if screen._hand_content_overflows:
		assert_true(
			new_span - old_span <= 20.1,
			"a saturated source hand opens at most one minVisibleWidth notch during preview"
		)
	else:
		assert_true(new_span > old_span, "a non-saturated hand opens the source-width insertion slot")
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

	var hud := _find_node_by_name(screen, "RoundNumberBG") as Control
	var menu := _find_node_by_name(screen, "MenuButton") as Control
	var overlay := _find_node_by_name(screen, "OverlayLayer") as Control
	var desk := _find_node_by_name(screen, "SituationDesk") as Control
	var rail := _find_node_by_name(screen, "CardRail") as Control
	var right_actions := _find_node_by_name(screen, "RightActions") as Control
	assert_not_null(hud, "the deadline strip is the desktop HUD")
	assert_not_null(menu, "menu should exist")
	assert_not_null(overlay, "rite overlay layer should exist")
	assert_not_null(desk)
	assert_not_null(rail)
	assert_not_null(right_actions)
	if hud == null or menu == null or overlay == null or desk == null or rail == null or right_actions == null:
		return
	assert_eq(menu.get_parent().get_parent(), screen, "menu button rides its chrome anchor, separate from the HUD strip")
	var quit_anchor := _find_node_by_name(screen, "QuitAnchor") as Control
	assert_gt(quit_anchor.z_index, overlay.z_index, "the global menu entry must remain reachable over local modals")
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

	var deadline := _find_node_by_name(screen, "RoundNumberBG") as Control
	var desk_map := _find_node_by_name(screen, "DeskMap") as Control
	var sudan_box := _find_node_by_name(screen, "SudanBox") as Control
	var card_rail := _find_node_by_name(screen, "CardRail") as Control
	var right_actions := _find_node_by_name(screen, "RightActions") as Control
	var advance := _find_node_by_name(screen, "AdvanceDayButton") as Control
	var menu := _find_node_by_name(screen, "MenuButton") as Control

	assert_not_null(deadline, "desktop layout needs the deadline strip")
	assert_not_null(menu, "desktop layout needs a separate menu button")
	assert_not_null(desk_map, "desktop layout needs a named middle DeskMap")
	assert_not_null(sudan_box, "desktop layout needs the sudan box chrome")
	assert_not_null(card_rail, "desktop layout needs a named bottom CardRail")
	assert_not_null(right_actions, "desktop layout needs named bottom-right RightActions")
	assert_not_null(advance, "desktop layout needs a named AdvanceDayButton")
	if deadline == null or menu == null or desk_map == null or sudan_box == null or card_rail == null or right_actions == null or advance == null:
		return

	# Authored 3840x2160 chrome scales with the stage (k = view/design).
	var view := Rect2(Vector2.ZERO, screen._effective_view_size())
	var k := view.size.y / 2160.0
	assert_almost_eq(deadline.position.y, 0.0, 2.0, "deadline strip pins to the top edge")
	assert_almost_eq(deadline.get_global_rect().end.x, view.end.x - 80.0 * k, 2.0, "deadline strip keeps the original right inset")
	assert_almost_eq(menu.get_global_rect().end.x, view.end.x - 30.0 * k, 2.0, "quit button keeps the original right inset")
	assert_almost_eq(menu.get_global_rect().position.y, 30.0 * k, 2.0, "quit button keeps the original top inset")
	assert_almost_eq(sudan_box.position.x, -47.0 * k, 2.0, "sudan box hangs off the left edge like the original")
	assert_almost_eq(sudan_box.position.y, 20.0 * k, 2.0, "sudan box keeps the original top inset")
	assert_almost_eq(desk_map.position.x, 0.0, 2.0, "the painted desk fills the whole canvas")
	assert_almost_eq(desk_map.size.x, view.size.x, 2.0, "the painted desk fills the whole canvas width")
	assert_almost_eq(card_rail.position.y, view.end.y - 470.0 * k, 2.0, "card rail band pins above the bottom edge")
	assert_almost_eq(card_rail.size.x, view.size.x, 2.0, "hand band spans the full width (Hand BG)")
	assert_almost_eq(right_actions.get_global_rect().end.x, view.end.x, 2.0, "watch cluster pins to the right edge")
	assert_almost_eq(right_actions.get_global_rect().end.y, view.end.y, 2.0, "watch cluster pins to the bottom edge")
	assert_almost_eq(advance.get_global_rect().size.x, 596.0 * k, 2.0, "watch keeps the original 596 width")
	assert_almost_eq(advance.get_global_rect().size.y, 634.0 * k, 2.0, "watch keeps the original 634 height")


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
	var self_home := _find_node_by_name(screen, "Location_SelfHome") as Control
	var rail := _find_node_by_name(screen, "CardRail") as Control
	var advance := _find_node_by_name(screen, "AdvanceDayButton") as Control
	var overlay := _find_node_by_name(screen, "OverlayLayer") as Control
	assert_not_null(desk)
	assert_not_null(self_home)
	assert_not_null(rail)
	assert_not_null(advance)
	assert_not_null(overlay)
	if desk == null or self_home == null or rail == null or advance == null or overlay == null:
		return
	assert_true(desk.visible, "narrow layouts should still open on the desk")
	assert_null(_find_node_by_name(screen, "SituationDeskTitle"), "the clone-era desk title must stay removed")
	var view_size := Rect2(Vector2.ZERO, screen._effective_view_size())
	assert_almost_eq(advance.get_global_rect().end.x, view_size.end.x, 2.0, "watch pins to the bottom-right corner")
	assert_almost_eq(advance.get_global_rect().end.y, view_size.end.y, 2.0, "watch pins to the bottom edge")
	assert_gt(overlay.z_index, desk.z_index, "queue overlays should remain above the paper desk")


func test_rite_view_replays_source_canvas_geometry():
	var rng := RNG.new(2)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage(Vector2(3840, 2160))
	var view = RiteView.new()
	view.setup(state, db, rng, 5000001)
	stage.add_child(view)
	await wait_process_frames(2)

	var shade := _find_node_by_name(view, "RiteModalShade") as Control
	var source_canvas := _find_node_by_name(view, "RitePanelShow") as Control
	var template_bg := _find_node_by_name(view, "RiteTemplateBackground") as Control
	var slot_layer := _find_node_by_name(view, "RiteSlotOverlay") as Control
	var slot_1 := _find_node_by_name(view, "OverlaySlot_S1") as Control
	var title_panel := _find_node_by_name(view, "RiteOverlayPanel") as Control
	assert_not_null(shade, "rite overlay should include a full-screen modal shade")
	assert_not_null(source_canvas, "rite overlay should retain the source RitePanelShow canvas")
	assert_not_null(template_bg, "rite template background should be a source-backed layer")
	assert_not_null(slot_layer, "rite overlay should include a full-screen slot layer")
	assert_not_null(slot_1, "source template slot s1 should be instantiated")
	assert_not_null(title_panel, "source RitePanelTitle surface should be instantiated")
	if shade != null:
		assert_almost_eq(shade.size.x, 3840.0, 0.1, "rite interaction blocker covers the source viewport")
		assert_almost_eq(shade.size.y, 2160.0, 0.1, "rite interaction blocker covers the source viewport")
	if source_canvas != null:
		assert_eq(source_canvas.size, Vector2(3840, 2160), "RitePanelShow retains its original design canvas")
	if slot_layer != null:
		assert_eq(slot_layer.size, Vector2(3840, 2160), "SlotsContainer coordinates are not remapped to a legacy mockup")
	if template_bg != null:
		assert_eq(template_bg.position, Vector2(-128, -414), "template bg_pos is replayed from the original JSON")
		assert_eq(template_bg.size, Vector2(4096, 2148), "Position/bg retains the original source size")
	if slot_1 != null:
		assert_eq(slot_1.position, Vector2(1472, 733), "template s1 uses the original SlotsContainer lower-left coordinate system")
		assert_eq(slot_1.size, Vector2(272, 496), "CardSlot root keeps the original 272x496 geometry")
	if title_panel != null:
		assert_eq(title_panel.position, Vector2(2199, 535), "template title_pos is replayed under Position")
		assert_eq(title_panel.size, Vector2(1148, 1124), "RitePanelTitle keeps its original source size")


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
		if child is PanelContainer and child.name in ["RoundNumberBG", "DeskMap"]:
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
