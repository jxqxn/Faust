extends GutTest

const RNG = preload("res://core/rng.gd")
const MapController = preload("res://ui/map_controller.gd")

const TABLE_PATH := "res://assets/original/situation_desk/table.png"
const MAP_PATH := "res://assets/original/situation_desk/table-map.png"

var db: ConfigDB


func before_all():
	db = ConfigDB.new()
	db.load_all()


func test_source_table_and_map_assets_load():
	for path in [TABLE_PATH, MAP_PATH]:
		assert_true(ResourceLoader.exists(path), "%s should be an original map asset" % path)
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s should load" % path)
		if texture != null:
			assert_gt(texture.get_width(), 0)
			assert_gt(texture.get_height(), 0)


func test_authored_location_nodes_use_gamescene_coordinates_not_clone_ratios():
	var desk := _desk(null, null, Vector2(3840, 2160))
	await wait_process_frames(2)
	var home := desk.get_node("Location_SelfHome") as Control
	var palace := desk.get_node("Location_Palace") as Control
	var uptown := desk.get_node("Location_Uptown") as Control
	assert_not_null(home)
	assert_not_null(palace)
	assert_not_null(uptown)
	if home == null or palace == null or uptown == null:
		return
	# GameScene Map@7621: 4200x2600 at (0,-178); child authored positions.
	assert_almost_eq(home.get_rect().get_center().x, 542.4, 1.0)
	assert_almost_eq(home.get_rect().get_center().y, 1345.0, 1.0)
	assert_almost_eq(palace.get_rect().get_center().x, 1484.1, 1.0)
	assert_almost_eq(palace.get_rect().get_center().y, 805.0, 1.5)
	assert_almost_eq(uptown.get_rect().get_center().x, 1860.6, 1.0)
	assert_almost_eq(uptown.get_rect().get_center().y, 588.9, 1.5)
	assert_null(desk.get_node_or_null("SiteHome"), "the invented location action buttons must be gone")
	assert_null(desk.get_node_or_null("SituationDeskTitle"), "the invented desk title must be gone")
	assert_false((desk.get_node("Location_Harem") as Control).visible, "Harem starts inactive in GameScene")


func test_rite_pin_opens_its_instance_without_a_location_selector_shortcut():
	var rng := RNG.new(8801)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.create_rite_instance(5000001)
	var desk := _desk(state, rng)
	await wait_process_frames(2)
	var pin: Button = null
	for node in desk.get_children():
		if node is Button and str(node.name).begins_with("RitePin_"):
			pin = node
			break
	assert_not_null(pin, "available rites enter the map as individual pins")
	if pin == null:
		return
	var before := SaveSystem.serialize(state)
	var rng_state_before: int = rng.get_state()
	var opened: Array[int] = []
	desk.open_rite_instance.connect(func(rite_uid: int): opened.append(rite_uid))
	pin.pressed.emit()
	assert_eq(opened, [pin.rite_uid])
	assert_eq(desk.last_rite, pin.rite_uid)
	assert_eq(SaveSystem.serialize(state), before)
	assert_eq(rng.get_state(), rng_state_before)


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
	var desk := MapController.new()
	desk.setup(state, db, rng)
	desk.size = stage.size
	stage.add_child(desk)
	return desk
