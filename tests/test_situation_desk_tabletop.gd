extends GutTest

const RNG = preload("res://core/rng.gd")
const SituationDesk = preload("res://ui/situation_desk.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const UiMotionScript = preload("res://ui/ui_motion.gd")

const MAP_PATH := "res://assets/original/situation_desk/tabletop_campaign_map.png"
const NODE_PATH := "res://assets/original/situation_desk/map_node_token.png"
const PAWN_PATH := "res://assets/original/situation_desk/protagonist_pawn.png"

var db: ConfigDB


func before_all():
	db = ConfigDB.new()
	db.load_all()


func after_each():
	UiMotionScript.reduced_motion = false


func test_tabletop_assets_load_and_cutout_assets_have_alpha():
	for path in [MAP_PATH, NODE_PATH, PAWN_PATH]:
		assert_true(ResourceLoader.exists(path), "%s should be imported from the project asset directory" % path)
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s should load as a texture" % path)
		if texture != null:
			assert_gt(texture.get_width(), 0, "%s should have a valid width" % path)
			assert_gt(texture.get_height(), 0, "%s should have a valid height" % path)

	for path in [NODE_PATH, PAWN_PATH]:
		var texture := load(path) as Texture2D
		if texture == null:
			continue
		var image := texture.get_image()
		assert_lt(
			image.get_pixel(0, 0).a,
			0.05,
			"%s should retain a transparent cutout corner" % path
		)
		assert_gt(
			image.get_pixel(image.get_width() / 2, image.get_height() / 2).a,
			0.50,
			"%s should retain an opaque physical component" % path
		)


func test_map_projection_uses_narrower_top_and_shared_vertical_compression():
	var desk := _desk()
	await wait_process_frames(2)
	var top_width: float = desk._project_ratio(Vector2(1, 0)).x - desk._project_ratio(Vector2(0, 0)).x
	var bottom_width: float = desk._project_ratio(Vector2(1, 1)).x - desk._project_ratio(Vector2(0, 1)).x
	var projected_height: float = desk._project_ratio(Vector2(0.5, 1)).y - desk._project_ratio(Vector2(0.5, 0)).y
	assert_almost_eq(top_width / bottom_width, 0.90, 0.001)
	assert_almost_eq(projected_height / desk.size.y, 0.94, 0.001)


func test_all_tabletop_controls_remain_inside_a_720_square_layout():
	var desk := _desk(null, null, Vector2(720, 720))
	await wait_process_frames(2)
	var desk_rect := Rect2(Vector2.ZERO, desk.size)
	for node_name in [
		"SiteHome",
		"SiteMarket",
		"SitePalace",
		"SiteTemple",
		"SiteWild",
		"CurrentSceneDossier",
		"ThinkDropZone",
		"SituationDeskTitle",
	]:
		var control := desk.get_node(node_name) as Control
		assert_true(
			desk_rect.encloses(Rect2(control.position, control.size)),
			"%s should remain inside the narrow tabletop" % node_name
		)


func test_pawn_moves_by_route_once_and_does_not_mutate_simulation_state():
	var rng := RNG.new(8801)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var desk := _desk(state, rng)
	await wait_process_frames(2)
	var before := SaveSystem.serialize(state)
	var rng_state_before: int = rng.get_state()
	var requested: Array[String] = []
	var navigation_states: Array[bool] = []
	desk.open_rite_selector.connect(func(location: String): requested.append(location))
	desk.site_navigation_active_changed.connect(
		func(active: bool): navigation_states.append(active)
	)
	var market := desk.get_node("SiteMarket") as Button
	var wild := desk.get_node("SiteWild") as Button
	var original_sizes := {}
	for site_name in ["SiteHome", "SiteMarket", "SitePalace", "SiteTemple", "SiteWild"]:
		original_sizes[site_name] = (desk.get_node(site_name) as Control).size

	market.pressed.emit()
	assert_true(desk.is_site_navigation_active(), "travel should lock repeated map input immediately")
	wild.pressed.emit()
	await wait_seconds(0.62)

	assert_false(desk.is_site_navigation_active())
	assert_eq(requested, ["商业区"], "a repeated click during travel must not replace the destination")
	assert_eq(navigation_states, [true, false])
	assert_eq(desk.pawn_location_name(), "商业区")
	assert_eq(SaveSystem.serialize(state), before, "visual pawn travel must not enter the save or rule state")
	assert_eq(rng.get_state(), rng_state_before, "visual pawn travel must not consume simulation RNG")
	for site_name in original_sizes:
		assert_eq(
			(desk.get_node(site_name) as Control).size,
			original_sizes[site_name],
			"site node size must not encode pawn position or selection"
		)


func test_same_node_is_immediate_and_reduced_motion_snaps_to_destination():
	var rng := RNG.new(8802)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var desk := _desk(state, rng)
	await wait_process_frames(2)
	var requested: Array[String] = []
	var navigation_states: Array[bool] = []
	desk.open_rite_selector.connect(func(location: String): requested.append(location))
	desk.site_navigation_active_changed.connect(
		func(active: bool): navigation_states.append(active)
	)

	(desk.get_node("SiteHome") as Button).pressed.emit()
	assert_eq(requested, ["自宅"], "the pawn's current node should open without travel")
	assert_eq(navigation_states, [])

	UiMotionScript.reduced_motion = true
	(desk.get_node("SiteTemple") as Button).pressed.emit()
	assert_eq(requested, ["自宅", "神殿区"])
	assert_eq(navigation_states, [true, false])
	assert_eq(desk.pawn_location_name(), "神殿区")


func test_route_graph_uses_the_declared_waypoints_and_caps_long_travel():
	var desk := _desk()
	await wait_process_frames(2)
	assert_eq(
		desk._shortest_path("home", "wild"),
		["home", "west", "market", "palace", "east", "wild"]
	)
	var requested: Array[String] = []
	desk.open_rite_selector.connect(func(location: String): requested.append(location))
	(desk.get_node("SiteWild") as Button).pressed.emit()
	await wait_seconds(0.59)
	assert_eq(requested, ["野外"], "five road edges should finish within the capped travel window")


func test_game_screen_pauses_all_persistent_controls_only_while_pawn_moves():
	var rng := RNG.new(8803)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var stage := Control.new()
	stage.size = Vector2(1152, 648)
	add_child_autofree(stage)
	var screen := GameScreen.new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await wait_process_frames(2)
	var desk := screen.get_node("SituationDesk")
	var market := desk.get_node("SiteMarket") as Button
	var other_site := desk.get_node("SiteWild") as Button
	var menu := screen.get_node("MenuButton") as Button
	var advance := screen.get_node("RightActions/AdvanceDayButton") as Button
	var redraw := screen.get_node("RightActions/RedrawSudanButton") as Button
	var card_rail := screen.get_node("CardRail") as Control

	market.pressed.emit()
	assert_true(desk.is_site_navigation_active())
	assert_true(menu.disabled, "menu should pause during pawn travel")
	assert_true(advance.disabled, "next day should pause during pawn travel")
	assert_true(redraw.disabled, "redraw should pause during pawn travel")
	assert_true(other_site.disabled, "other map nodes should reject input during pawn travel")
	assert_eq(card_rail.mouse_filter, Control.MOUSE_FILTER_IGNORE, "card input should pause during pawn travel")
	await wait_seconds(0.40)

	assert_false(desk.is_site_navigation_active())
	assert_false(menu.disabled)
	assert_false(advance.disabled)
	assert_false(redraw.disabled)
	assert_eq(card_rail.mouse_filter, Control.MOUSE_FILTER_STOP)


func _desk(
	state = null,
	rng = null,
	desk_size: Vector2 = Vector2(1152, 648)
) -> Control:
	if state == null:
		state = GameState.new()
		rng = RNG.new(8800)
		state.setup_new_run(db, 0, rng)
	var stage := Control.new()
	stage.size = desk_size
	add_child_autofree(stage)
	var desk := SituationDesk.new()
	desk.setup(state, db, rng)
	desk.size = stage.size
	stage.add_child(desk)
	return desk
