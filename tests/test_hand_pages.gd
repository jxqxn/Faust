extends GutTest

const GameScreen = preload("res://ui/game_screen.gd")

var db: ConfigDB


func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_condition_sort_uses_source_ties_and_persists_only_current_page() -> void:
	var state := GameState.new()
	var other := state.add_card_to_hand(2000001, db)
	state.get_card_instance(other).bag = 1
	state.get_card_instance(other).bag_pos = 19
	var last := state.add_card_to_hand(2000006, db)
	var first := state.add_card_to_hand(2000001, db)
	var second := state.add_card_to_hand(2000001, db)
	var rejected := state.add_card_to_hand(2000005, db)
	state.get_card_instance(last).bag_pos = 0
	state.get_card_instance(first).bag_pos = 4
	state.get_card_instance(second).bag_pos = 4
	state.get_card_instance(rejected).bag_pos = 1
	var matches := state.sort_current_hand_by_condition(db, func(card: Dictionary): return int(card.id) != 2000005)
	assert_eq(matches, [first, second, last])
	assert_eq(state.visible_rail_card_uids(), [first, second, last, rejected])
	assert_eq(state.get_card_instance(other).bag_pos, 19)
	assert_eq(state.visible_rail_card_uids(1), [other])
	for index in state.visible_rail_card_uids().size():
		assert_eq(state.get_card_instance(state.visible_rail_card_uids()[index]).bag_pos, index + 1)
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(restored.visible_rail_card_uids(), [first, second, last, rejected])
	assert_eq(restored.get_card_instance(other).bag_pos, 19)


func test_page_boundaries_preserve_cards_and_save_selection() -> void:
	var state := GameState.new()
	var uids: Array[int] = []
	for page in range(4):
		var uid := state.add_card_to_hand(2000001, db)
		state.get_card_instance(uid).bag = page
		uids.append(uid)
	for page in range(4):
		assert_eq(state.set_current_bag_index(page), page)
		assert_eq(state.visible_rail_card_uids(), [uids[page]])
	assert_eq(state.set_current_bag_index(-1), 3)
	assert_eq(state.set_current_bag_index(4), 3)
	assert_eq(state.hand, uids, "changing presentation does not remove other bags from player ownership")
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(restored.current_bag_index, 3)
	assert_eq(restored.visible_rail_card_uids(), [uids[3]])


func test_four_buttons_switch_real_pages_and_respect_modal() -> void:
	var rng := preload("res://core/rng.gd").new(180)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	while not state.pending_operation().is_empty():
		state.consume_pending_operation()
	state.get_card_instance(state.hand[0]).bag = 1
	var screen := GameScreen.new()
	screen.setup(state, db, rng)
	add_child_autofree(screen)
	await wait_process_frames(2)
	var tabs: HandBagTabs = screen.get_node("BagBtnGroup")
	assert_eq(tabs.buttons.size(), 4)
	tabs.buttons[1].pressed.emit()
	await wait_process_frames(2)
	assert_eq(state.current_bag_index, 1)
	assert_true(tabs.buttons[1].button_pressed)
	assert_eq(tabs.buttons[1].get_node("NumberOn").size, Vector2(24, 49.5))
	screen.set_world_scene_blocker("test", true)
	assert_true(tabs.buttons[0].disabled)
	tabs.buttons[0].pressed.emit()
	assert_eq(state.current_bag_index, 1)
	screen.set_world_scene_blocker("test", false)


func test_insertion_uses_page_order_not_global_index() -> void:
	var state := GameState.new()
	var first := state.add_card_to_hand(2000001, db)
	var other := state.add_card_to_hand(2000006, db)
	var second := state.add_card_to_hand(2000007, db)
	var last := state.add_card_to_hand(2000008, db)
	state.get_card_instance(other).bag = 1
	state.set_current_bag_index(0)
	var screen := GameScreen.new()
	screen.setup(state, db, preload("res://core/rng.gd").new(181))
	add_child_autofree(screen)
	await wait_process_frames(2)
	var global_index := screen._global_rail_insert_index(1, last)
	state.reorder_rail_card(last, global_index)
	assert_eq(state.visible_rail_card_uids(), [first, last, second])
	assert_eq(state.visible_rail_card_uids(1), [other])


func test_metal_material_has_no_invented_screen_normal_offset() -> void:
	# CardShow compiled bindings do not consume NormalOffsetX/Y. The old test
	# required a fabricated position-dependent normal. Motion must not mutate
	# the authored material inputs, including while a modal pauses animation.
	var widget := CardWidget.make({"id": 2000001, "type": "char", "rare": 4, "name": "Test"})
	add_child_autofree(widget)
	await wait_process_frames(2)
	var surface := widget.get_node("CardVisualFace/Foreground").material as ShaderMaterial
	assert_not_null(surface)
	var before: Vector3 = surface.get_shader_parameter("emission_color")
	widget.position += Vector2(300, 200)
	await wait_process_frames(2)
	assert_eq(surface.get_shader_parameter("emission_color"), before)
	widget.set_presentation_paused(true)
	widget.position += Vector2(300, 200)
	await wait_process_frames(2)
	assert_eq(surface.get_shader_parameter("emission_color"), before)



func test_rite_title_is_independent_of_icon_bound_and_clicks_instance() -> void:
	var state := GameState.new()
	var rng := preload("res://core/rng.gd").new(182)
	state.setup_new_run(db, 0, rng)
	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	add_child_autofree(stage)
	var desk := MapController.new()
	desk.setup(state, db, rng)
	desk.size = stage.size
	stage.add_child(desk)
	await wait_process_frames(2)
	assert_false(desk.rite_cards.is_empty())
	watch_signals(desk)
	for uid in desk.rite_cards:
		var card: Control = desk.rite_cards[uid]
		var banner := card.get_node("TitleBG") as TextureButton
		var title := banner.get_node("Title") as Label
		# [SRC: RiteRender.Init 0x59a9e0 -> TextTranslate @RITE_TITLE
		# (content/textstyle.json, md=40); GameScene camera half-height 1732
		# and Map7621 scale 1.25 give one isotropic world-to-screen factor.]
		assert_eq(title.get_theme_font_size("font_size"), 40)
		assert_eq(banner.size.y, 77.0)
		assert_gt(banner.size.x, 113.0)
		assert_almost_eq(banner.scale.x, 2160.0 * 1.25 / 3464.0, 0.001)
		banner.pressed.emit()
		assert_signal_emitted_with_parameters(desk, "open_rite_instance", [uid])
		break
	desk.set_scene_blocker("test", true)
	for card in desk.rite_cards.values():
		assert_true(card.get_node("TitleBG").disabled)
