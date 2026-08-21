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


func test_rite_new_card_opens_its_instance_without_a_location_selector_shortcut():
	var rng := RNG.new(8801)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.create_rite_instance(5000001)
	var desk := _desk(state, rng)
	await wait_process_frames(2)
	var card: Button = null
	for node in desk.get_children():
		if node is Button and str(node.name).begins_with("RiteNew_"):
			card = node
			break
	assert_not_null(card, "live rites enter the map as individual RiteNew cards")
	if card == null:
		return
	var before := SaveSystem.serialize(state)
	var rng_state_before: int = rng.get_state()
	var opened: Array[int] = []
	desk.open_rite_instance.connect(func(rite_uid: int): opened.append(rite_uid))
	card.pressed.emit()
	assert_eq(opened, [card.rite_uid])
	assert_eq(desk.last_rite, card.rite_uid)
	assert_eq(SaveSystem.serialize(state), before)
	assert_eq(rng.get_state(), rng_state_before)


func test_rite_new_positions_follow_authored_children_range_selection_and_stack_order():
	var rng := RNG.new(8802)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	# setup_new_run seeds the original opening rites.  Remove them so this test
	# isolates the exact GetPosition tie/range behaviour below.
	state.rite_instances.clear()
	state.available_rites.clear()
	state.started_rites.clear()
	# Original content locations: 5000001 = 自宅:1; 5000003 = 自宅:[2,12].
	# The final fixed RiteNew shares child 1 and receives +100 X before the
	# subsequent MapController.SetRitesPosition collision pass.
	var fixed_first = state.create_rite_instance(5000001)
	var ranged_first = state.create_rite_instance(5000003)
	var ranged_second = state.create_rite_instance(5000003)
	var ranged_third = state.create_rite_instance(5000003)
	var fixed_second = state.create_rite_instance(5000001)
	var desk := _desk(state, rng, Vector2(3840, 2160)) as MapController
	await wait_process_frames(2)
	assert_not_null(desk)
	if desk == null:
		return
	# GameScene SelfHome root @8644 plus integer-named RitePosition children.
	var root := Vector2(-1506, -141)
	# Normal/ranged live rites are sorted closest-first to the Map-local screen
	# centre, then each later rectangle is pushed along its smallest overlap
	# axis.  These values are the source SetPos result, not a clone spacing rule.
	_assert_card_center(desk, fixed_first.uid, root + Vector2(1, 3))
	var first_card := desk.rite_cards.get(fixed_first.uid, null) as Control
	if first_card != null:
		assert_almost_eq(first_card.size.x, 123.0 * 3840.0 / 4200.0, 1.0, "RiteNew bound keeps its original 123 source-pixel width")
		assert_almost_eq(first_card.size.y, 133.0 * 2160.0 / 2600.0, 1.0, "RiteNew bound keeps its original 133 source-pixel height")
	_assert_card_center(desk, ranged_first.uid, root + Vector2(-295, 11))
	_assert_card_center(desk, ranged_second.uid, root + Vector2(44, 136))
	_assert_card_center(desk, ranged_third.uid, root + Vector2(338, -3))
	_assert_card_center(desk, fixed_second.uid, root + Vector2(24 + 100, 3))


func test_rite_new_set_pos_uses_smallest_overlap_axis_and_reverts_outside_bg():
	# RiteNew.bound is 123x133.  A card 100 source pixels to the right overlaps
	# by 23 horizontally, so SetPos moves it right by 23 (the smaller axis).
	var pushed := MapController.resolve_rite_card_pair_position(Vector2.ZERO, Vector2(100, 0))
	assert_eq(pushed, Vector2(123, 0))
	var diagonal := MapController.resolve_rite_card_pair_position(Vector2(-1382, -138), Vector2(-1462, -21))
	assert_eq(diagonal, Vector2(-1462, -5), "16 vertical overlap is smaller than 43 horizontal overlap")
	# Source only tests the candidate bound centre against bg and restores the
	# old root if it would leave; it does not clamp to the right edge.
	var near_edge := Vector2(2430, 0)
	var reverted := MapController.resolve_rite_card_pair_position(Vector2(2380, 0), near_edge)
	assert_eq(reverted, near_edge)


func test_rite_position_compacts_surviving_card_after_runtime_removal():
	var rng := RNG.new(8805)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.rite_instances.clear()
	state.available_rites.clear()
	state.started_rites.clear()
	var first = state.create_rite_instance(5000001)
	var second = state.create_rite_instance(5000001)
	var desk := _desk(state, rng, Vector2(3840, 2160)) as MapController
	await wait_process_frames(2)
	state.remove_rite_instance(first.uid)
	desk.refresh_context()
	await wait_process_frames(2)
	# RemoveRite -> UpdateExistsChild reindexes the remaining sibling to local X=0.
	_assert_card_center(desk, second.uid, Vector2(-1506, -141) + Vector2(24, 3))


func test_final_pin_is_a_persistent_noninteractive_endpoint_separate_from_rite_new():
	var rng := RNG.new(8803)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.rite_instances.clear()
	state.available_rites.clear()
	state.started_rites.clear()
	var live := state.create_rite_instance(5000001)
	assert_true(state.add_rite_pin(5010009), "Player.pins appends a final rite id")
	assert_false(state.add_rite_pin(5010009), "Player.pins rejects duplicate ids")
	var desk := _desk(state, rng, Vector2(3840, 2160)) as MapController
	await wait_process_frames(2)
	var card := desk.rite_cards.get(live.uid, null) as Button
	var pin := desk.pins.get(5010009, null) as Control
	assert_not_null(card, "live rite owns a RiteNew/RiteController card")
	assert_not_null(pin, "completed final_pin owns a separate RitePin endpoint")
	assert_false(pin is Button, "RitePin.prefab is not the map opening button")
	assert_eq(state.rite_pins, [5010009], "pins retain source list order")


func test_settled_final_pin_enters_player_pins_only_after_live_rite_removal():
	var rng := RNG.new(8804)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.rite_instances.clear()
	state.available_rites.clear()
	state.started_rites.clear()
	var final_rite := state.create_rite_instance(5010009)
	RoundLoop.finalize_rite_settlement(final_rite, {"clean_rite": false}, state, db, [], rng)
	assert_null(state.get_rite_instance(final_rite.uid), "settlement removes the live RiteController carrier first")
	assert_eq(state.rite_pins, [5010009], "only final_pin=true creates the persistent config-id endpoint")


func test_from_pins_draws_only_from_completed_pin_to_live_rite_new():
	var rng := RNG.new(8806)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.rite_instances.clear()
	state.available_rites.clear()
	state.started_rites.clear()
	# 5010014 has FromPin(5010013).  The target is live here, so the source
	# needs to be a completed RitePin but the target must remain RiteNew.
	var target = state.create_rite_instance(5010014)
	var desk := _desk(state, rng, Vector2(3840, 2160)) as MapController
	await wait_process_frames(2)
	assert_eq(desk.lines.size(), 0, "a live target never makes an uncompleted source into a line")
	assert_true(state.add_rite_pin(5010013))
	desk.refresh_context()
	await wait_process_frames(2)
	var line := desk.lines.get(Vector2i(5010014, 5010013), null) as MapController.RitePinLineView
	assert_not_null(line, "RefreshRitePinLines connects completed source pin to live RiteController")
	if line == null:
		return
	assert_eq(line.target_rite_id, target.id)
	assert_eq(line.source_rite_id, 5010013)
	assert_eq(line.sampled_points.size(), 51, "source resolution=50 produces 51 inclusive samples")
	assert_true(line.dashed, "the original FromPin dashed flag maps to LineRenderer LineList")
	assert_eq(line.line_color, Color8(207, 187, 161, 255))
	assert_eq(line.line_width, 20.0)
	assert_eq(line.arrow_points.size(), 3, "source arrow_length creates a two-wing arrow")


func test_from_pins_connects_completed_endpoint_pairs_and_uses_source_curve_data():
	var rng := RNG.new(8807)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.rite_instances.clear()
	state.available_rites.clear()
	state.started_rites.clear()
	# 5010009 -> FromPin(5010025), with both sides now persistent endpoints.
	assert_true(state.add_rite_pin(5010025))
	assert_true(state.add_rite_pin(5010009))
	var desk := _desk(state, rng, Vector2(3840, 2160)) as MapController
	await wait_process_frames(2)
	var line := desk.lines.get(Vector2i(5010009, 5010025), null) as MapController.RitePinLineView
	assert_not_null(line, "first source pass connects completed RitePin targets")
	if line == null:
		return
	var positions := desk._allocate_rite_pin_positions()
	var start := desk._map_local_to_canvas(positions[5010025] + desk.MAP_LOCAL_OFFSET)
	var ending := desk._map_local_to_canvas(positions[5010009] + desk.MAP_LOCAL_OFFSET)
	var controls: Array[Vector2] = [start + Vector2(100, -100)]
	var expected := MapController.sample_rite_pin_line(start, ending, controls, 50, 0.08, 1.0)
	assert_eq(line.sampled_points, expected, "controls are original root-canvas offsets from the source pin")
	assert_false(desk.lines.has(Vector2i(5010009, 5010013)), "unrelated completed pins do not synthesize graph edges")


func _assert_card_center(desk: MapController, rite_uid: int, source_position: Vector2) -> void:
	var card := desk.rite_cards.get(rite_uid, null) as Control
	assert_not_null(card, "rite %d should have an original RiteNew card" % rite_uid)
	if card == null:
		return
	var bound_center := source_position + Vector2(
		desk.RITE_CARD_BOUND_ANCHORED_POSITION.x + desk.RITE_CARD_BOUND_SIZE.x * (0.5 - desk.RITE_CARD_BOUND_PIVOT.x),
		desk.RITE_CARD_BOUND_ANCHORED_POSITION.y + desk.RITE_CARD_BOUND_SIZE.y * (0.5 - desk.RITE_CARD_BOUND_PIVOT.y)
	)
	var expected := Vector2(
		desk.size.x * 0.5 + (bound_center.x + desk.MAP_LOCAL_OFFSET.x) * desk.size.x / desk.MAP_SIZE.x,
		desk.size.y * 0.5 - (bound_center.y + desk.MAP_LOCAL_OFFSET.y) * desk.size.y / desk.MAP_SIZE.y
	)
	var actual := card.position + card.size * 0.5
	assert_almost_eq(actual.x, expected.x, 1.0, "rite %d X uses the authored RitePosition child" % rite_uid)
	assert_almost_eq(actual.y, expected.y, 1.0, "rite %d Y uses the authored RitePosition child" % rite_uid)


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
