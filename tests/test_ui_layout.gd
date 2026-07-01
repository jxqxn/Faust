extends GutTest

const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
const RNG = preload("res://core/rng.gd")
const MainMenu = preload("res://ui/main_menu.gd")
const Game = preload("res://ui/game.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const RiteView = preload("res://ui/rite_view.gd")
const CardWidget = preload("res://ui/card_widget.gd")
const RoundLoop = preload("res://sim/round_loop.gd")

const WIDE_VIEWPORT := Vector2(1152, 648)
const MIN_CONTENT_WIDTH := 900.0

var db: ConfigDB


func before_all():
	db = ConfigDB.new()
	db.load_all()


func test_main_menu_uses_wide_viewport_width():
	var stage := _stage()
	var menu = MainMenu.new()
	stage.add_child(menu)
	await wait_process_frames(2)

	assert_true(_widest_content(menu) >= MIN_CONTENT_WIDTH, "main menu content should use the wide viewport")


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
	assert_true(_narrowest_direct_panel(screen) >= MIN_CONTENT_WIDTH, "game screen panels should not remain in a left-column layout")


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
	var menu_count := [0]
	screen.open_rite.connect(func(id: int): opened.append(id))
	screen.menu_pressed.connect(func(): menu_count[0] += 1)

	var home := _find_node_by_name(screen, "SiteHome") as Button
	var menu := _find_node_by_name(screen, "MenuButton") as Button
	assert_not_null(home, "home site should be an interactive button")
	assert_not_null(menu, "menu should be an interactive button")
	if home != null:
		home.pressed.emit()
	if menu != null:
		menu.pressed.emit()
	assert_eq(opened, [5000001], "clicking home site should open the estate rite")
	assert_eq(menu_count[0], 1, "clicking menu should emit a menu action")


func test_game_menu_button_opens_real_overlay():
	var stage := _stage()
	var game = Game.new()
	stage.add_child(game)
	await wait_process_frames(2)

	game._on_difficulty_selected(0)
	await wait_process_frames(2)

	var menu := _find_node_by_name(game, "MenuButton") as Button
	assert_not_null(menu, "menu button should exist in the in-game HUD")
	if menu == null:
		return
	menu.pressed.emit()
	await wait_process_frames(1)

	assert_not_null(_find_node_by_name(game, "GameMenuOverlay"), "menu button should open an in-game menu overlay")
	assert_not_null(_find_node_by_name(game, "ResumeGameButton"), "menu overlay should include a resume action")
	assert_not_null(_find_node_by_name(game, "SaveGameButton"), "menu overlay should include a save action")
	assert_not_null(_find_node_by_name(game, "ReturnTitleButton"), "menu overlay should include a return-title action")


func test_card_widget_exports_drag_payload_with_card_id():
	var card := {"id": 2000001, "name": "Test", "type": "char", "rare": 1, "tag": {}}
	var stage := _stage()
	var widget := CardWidget.make(card)
	stage.add_child(widget)
	await wait_process_frames(1)

	var data = widget._get_drag_data(Vector2.ZERO)
	assert_true(data is Dictionary, "dragging a card should produce a card payload")
	assert_eq(int(data.get("card_id", 0)), 2000001, "drag payload should identify the dragged card")


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

	assert_not_null(_find_node_by_name(screen, "CardDetailOverlay"), "clicking a card should open a desktop card detail overlay")
	assert_not_null(_find_node_by_name(screen, "CardDetailPanel"), "card detail should render as a floating panel, not a standalone screen")
	assert_not_null(_find_node_by_name(screen, "CloseCardDetailButton"), "card detail overlay should be closable")

	screen.show_card_detail(int(state.hand[0]))
	await wait_process_frames(1)
	assert_null(_find_node_by_name(screen, "CardDetailOverlay"), "clicking the same card again should close the detail overlay")


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
	assert_eq(_count_buttons(right_actions), 2, "right actions should only contain next-day and redraw controls")
	assert_not_null(_find_node_by_name(right_actions, "AdvanceDayButton"), "next-day action remains in the right column")
	assert_not_null(_find_node_by_name(right_actions, "RedrawSudanButton"), "redraw action remains in the right column")
	assert_null(_find_node_by_name(right_actions, "OpenRiteSelectorButton"), "rite selector should not be duplicated beside the desk sites")


func test_game_screen_menu_is_separate_but_below_rite_overlay():
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
	assert_not_null(hud, "HUD should exist")
	assert_not_null(menu, "menu should exist")
	assert_not_null(overlay, "rite overlay layer should exist")
	if hud == null or menu == null or overlay == null:
		return
	assert_eq(menu.get_parent(), screen, "menu button should be separate from the HUD info panel")
	assert_true(menu.get_index() < overlay.get_index(), "rite overlays should disable the top-right menu")


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
	assert_true(card_rail.position.y > desk_map.position.y + desk_map.size.y - 8.0, "CardRail should live below the DeskMap")
	assert_almost_eq(card_rail.position.x, 162.0, 8.0, "CardRail should leave room for the mockup rail label")
	assert_true(card_rail.size.x < 840.0, "CardRail should leave room for the right action column")
	assert_true(rail_label.position.x < card_rail.position.x, "RailLabel should be left of CardRail")
	assert_true(right_actions.position.x > card_rail.position.x + card_rail.size.x, "RightActions should be right of CardRail")
	assert_true(advance.size.x >= 110.0 and advance.size.y >= 110.0, "AdvanceDayButton should be the large round bottom action")


func test_rite_view_uses_wide_viewport_width():
	var rng := RNG.new(2)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := _stage()
	var view = RiteView.new()
	view.setup(state, db, rng, 5000001)
	stage.add_child(view)
	await wait_process_frames(2)

	assert_true(_widest_content(view) >= MIN_CONTENT_WIDTH, "rite view content should use the wide viewport")


func _stage() -> Control:
	var stage: Control = Control.new()
	add_child_autofree(stage)
	stage.size = WIDE_VIEWPORT
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
	for child in node.get_children():
		var child_text := _collect_label_and_button_text(child)
		if child_text != "":
			parts.append(child_text)
	return " ".join(parts)
