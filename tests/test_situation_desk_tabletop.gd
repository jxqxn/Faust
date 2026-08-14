extends GutTest

const RNG = preload("res://core/rng.gd")
const SituationDesk = preload("res://ui/situation_desk.gd")

const MAP_PATH := "res://assets/original/situation_desk/tabletop_campaign_map.png"
const NODE_PATH := "res://assets/original/situation_desk/map_node_token.png"

var db: ConfigDB


func before_all():
	db = ConfigDB.new()
	db.load_all()


func test_tabletop_assets_load_and_cutout_assets_have_alpha():
	for path in [MAP_PATH, NODE_PATH]:
		assert_true(ResourceLoader.exists(path), "%s should be imported from the project asset directory" % path)
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s should load as a texture" % path)
		if texture != null:
			assert_gt(texture.get_width(), 0, "%s should have a valid width" % path)
			assert_gt(texture.get_height(), 0, "%s should have a valid height" % path)

	var texture := load(NODE_PATH) as Texture2D
	if texture == null:
		return
	var image := texture.get_image()
	assert_lt(
		image.get_pixel(0, 0).a,
		0.05,
		"%s should retain a transparent cutout corner" % NODE_PATH
	)
	assert_gt(
		image.get_pixel(image.get_width() / 2, image.get_height() / 2).a,
		0.50,
		"%s should retain an opaque physical component" % NODE_PATH
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
		"ThinkDropZone",
		"SituationDeskTitle",
	]:
		var control := desk.get_node(node_name) as Control
		assert_true(
			desk_rect.encloses(Rect2(control.position, control.size)),
			"%s should remain inside the narrow tabletop" % node_name
		)


func test_site_press_opens_selector_immediately_without_mutating_simulation_state():
	var rng := RNG.new(8801)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var desk := _desk(state, rng)
	await wait_process_frames(2)
	var before := SaveSystem.serialize(state)
	var rng_state_before: int = rng.get_state()
	var requested: Array[String] = []
	desk.open_rite_selector.connect(func(location: String): requested.append(location))

	(desk.get_node("SiteHome") as Button).pressed.emit()
	(desk.get_node("SiteMarket") as Button).pressed.emit()
	(desk.get_node("SiteWild") as Button).pressed.emit()

	assert_eq(requested, ["自宅", "商业区", "野外"], "every site press opens its location immediately")
	assert_eq(SaveSystem.serialize(state), before, "site presses must not enter the save or rule state")
	assert_eq(rng.get_state(), rng_state_before, "site presses must not consume simulation RNG")


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
