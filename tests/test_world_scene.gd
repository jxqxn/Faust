extends GutTest

const RNG = preload("res://core/rng.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const ThoughtWorld = preload("res://ui/thought_world.gd")
const WorldScenes = preload("res://sim/world_scene_catalog.gd")

const VIEWPORT_SIZE := Vector2(1152, 648)

var db: ConfigDB


func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_world_catalog_has_valid_resources_exits_and_dialogues() -> void:
	assert_eq(
		Array(WorldScenes.validate_graph()),
		[],
		"every lateral location should have loadable art and resolvable interactions"
	)


func test_rooftop_exit_moves_to_riverbank_and_updates_run_state() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(901))
	var stage := _stage()
	var world = ThoughtWorld.new()
	world.setup(state)
	stage.add_child(world)
	await wait_process_frames(2)

	world.set_player_x_ratio_for_test(0.055)
	assert_true(world.interact_with_nearest(), "the nearby rooftop exit should accept E interaction")
	await wait_process_frames(1)

	assert_eq(world.location_id(), "riverbank")
	assert_eq(state.world_location_id, "riverbank")
	assert_eq(state.world_spawn_id, "from_rooftop")
	assert_almost_eq(state.world_position_ratio, 0.14, 0.001)
	assert_true("riverbank" in state.visited_world_locations)
	assert_not_null(world.get_node_or_null("WorldExit_to_rooftop"))


func test_world_rebuild_restores_saved_location_position_and_spawn() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(904))
	state.world_location_id = "riverbank"
	state.world_spawn_id = "from_rooftop"
	state.world_position_ratio = 0.63
	state.visited_world_locations = ["school_rooftop", "riverbank"]
	var stage := _stage()
	var world = ThoughtWorld.new()
	world.setup(state)
	stage.add_child(world)
	await wait_process_frames(2)

	assert_eq(world.location_id(), "riverbank")
	assert_almost_eq(world.player_x_ratio(), 0.63, 0.001)
	assert_eq(state.world_spawn_id, "from_rooftop", "rebuilding the scene should not overwrite save metadata")
	assert_not_null(world.get_node_or_null("WorldExit_to_rooftop"))


func test_game_screen_dossier_restores_saved_scene_and_returns_to_persistent_desk() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(907))
	state.world_location_id = "riverbank"
	state.world_spawn_id = "from_rooftop"
	state.world_position_ratio = 0.63
	state.visited_world_locations = ["school_rooftop", "riverbank"]
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, RNG.new(908))
	stage.add_child(screen)
	await wait_process_frames(2)

	var desk := screen.get_node_or_null("SituationDesk") as Control
	var dossier := screen.find_child("CurrentSceneDossier", true, false) as Button
	var world = screen.get_node_or_null("SceneWorld")
	var rail := screen.get_node_or_null("CardRail") as Control
	assert_not_null(desk)
	assert_not_null(dossier)
	assert_not_null(world)
	assert_not_null(rail)
	if desk == null or dossier == null or world == null or rail == null:
		return
	var rail_instance_id := rail.get_instance_id()
	assert_true(desk.visible, "the desk should be the first visible play surface")
	assert_false(world.visible, "the dossier scene should remain closed until requested")
	dossier.pressed.emit()
	await wait_process_frames(1)
	assert_true(world.visible, "opening the dossier should reveal the saved scene")
	assert_eq(world.location_id(), "riverbank")
	assert_almost_eq(world.player_x_ratio(), 0.63, 0.001)
	assert_false((world.get_node("ThinkButton") as Control).visible, "the scene must not duplicate desk thought entry")
	assert_true((world.get_node("ReturnToDeskButton") as Control).visible)
	state.queue_prompt({"id": "desk.return.queue", "text": "keep"})
	world.return_requested.emit()
	await wait_process_frames(1)
	assert_true(desk.visible, "return should restore the same desk rather than rebuild navigation")
	assert_false(world.visible)
	assert_eq(screen.get_node("CardRail").get_instance_id(), rail_instance_id, "return must preserve the card rail")
	assert_eq(str(state.pending_operation().get("payload", {}).get("id", "")), "desk.return.queue", "return must not discard queued work")


func test_nearby_heroine_queues_scene_dialogue_in_order() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(902))
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, RNG.new(903))
	stage.add_child(screen)
	await wait_process_frames(2)
	var dossier := screen.find_child("CurrentSceneDossier", true, false) as Button
	assert_not_null(dossier)
	if dossier == null:
		return
	dossier.pressed.emit()
	await wait_process_frames(1)
	var world = screen.get_node_or_null("SceneWorld")
	assert_not_null(world)
	if world == null:
		return

	world.set_player_x_ratio_for_test(0.79)
	assert_true(world.interact_with_nearest(), "the nearby heroine should accept E interaction")
	assert_almost_eq(
		world.player_x_ratio(),
		0.79,
		0.001,
		"triggering a conversation must not teleport the protagonist"
	)
	assert_true(
		world.is_approaching_interaction(),
		"the protagonist should walk to the authored talk mark before dialogue"
	)
	assert_false(
		world.interact_with_nearest(),
		"the approach should reject repeated interaction requests"
	)
	assert_eq(
		state.pending_operations.size(),
		0,
		"dialogue should wait until the protagonist reaches the talk mark"
	)
	for frame in 90:
		if not world.is_approaching_interaction():
			break
		await wait_process_frames(1)

	assert_almost_eq(
		world.player_x_ratio(),
		0.68,
		0.001,
		"the approach should finish at the authored talk mark"
	)
	assert_false(world.is_approaching_interaction())
	assert_true(world.is_scene_blocked(), "scene input should lock while dialogue is visible")
	_assert_world_chrome_hidden(world)
	assert_eq(state.pending_operations.size(), 3, "the whole conversation should enter the shared ordered queue")
	assert_eq(
		str(state.pending_operations[0].get("payload", {}).get("presentation", "")),
		"dialogue"
	)
	assert_eq(
		str(state.pending_operations[0].get("context", {}).get("npc_id", "")),
		"heroine",
		"dialogue occurrences should retain their world interaction context"
	)
	var line := screen.find_child("SceneDialogueLine", true, false) as Control
	var dialogue_text := screen.find_child("SceneDialogueText", true, false) as Label
	assert_not_null(line, "dialogue should float in the scene beside its speaker")
	assert_not_null(dialogue_text)
	assert_null(
		screen.find_child("EventPromptPanel", true, false),
		"world dialogue should not use a dedicated dialogue box"
	)
	if dialogue_text != null:
		assert_eq(dialogue_text.text, "你也还没有回去？")
	var line_instance_id := line.get_instance_id() if line != null else 0
	var first_line_x := line.position.x if line != null else 0.0
	var first_card_instance_id: int = (
		screen._card_items.get_child(0).get_instance_id()
		if screen._card_items.get_child_count() > 0
		else 0
	)

	var continue_button := screen.find_child("EventPromptContinueButton", true, false) as Button
	assert_not_null(continue_button)
	if continue_button != null:
		var held_e := InputEventKey.new()
		held_e.keycode = KEY_E
		held_e.pressed = true
		held_e.echo = true
		Input.parse_input_event(held_e)
		await wait_process_frames(1)
		assert_eq(
			state.pending_operations.size(),
			3,
			"holding E should not skip dialogue lines"
		)
		var pressed_e := InputEventKey.new()
		pressed_e.keycode = KEY_E
		pressed_e.pressed = true
		Input.parse_input_event(pressed_e)
		await wait_process_frames(2)
		assert_eq(state.pending_operations.size(), 2)
		assert_true(world.is_scene_blocked(), "replacing the first line must retain the scene lock")
		_assert_world_chrome_hidden(world)
		assert_not_null(
			screen.find_child("EventPromptOverlay", true, false),
			"replacement overlays should retain their stable node name"
		)
		if first_card_instance_id > 0:
			assert_eq(
				screen._card_items.get_child(0).get_instance_id(),
				first_card_instance_id,
				"advancing spoken dialogue should not rebuild the unrelated card rail"
			)
		var next_line := screen.find_child("SceneDialogueLine", true, false) as Control
		var next_text := screen.find_child("SceneDialogueText", true, false) as Label
		assert_not_null(next_line)
		assert_not_null(next_text)
		if next_line != null:
			assert_eq(
				next_line.get_instance_id(),
				line_instance_id,
				"advancing dialogue should update one stable scene label instead of rebuilding it"
			)
			assert_lt(
				next_line.position.x,
				first_line_x,
				"the line should move from the heroine to the protagonist"
			)
		if next_text != null:
			assert_eq(next_text.text, "只是想再待一会儿。", "conversation lines should preserve queue order")
		continue_button = screen.find_child("EventPromptContinueButton", true, false) as Button
		if continue_button != null:
			continue_button.pressed.emit()
			await wait_process_frames(2)
			assert_true(world.is_scene_blocked(), "the third line must retain the scene lock")
			_assert_world_chrome_hidden(world)
			var third_line := screen.find_child("SceneDialogueLine", true, false) as Control
			var third_text := screen.find_child("SceneDialogueText", true, false) as Label
			if third_line != null:
				assert_eq(third_line.get_instance_id(), line_instance_id)
			if third_text != null:
				assert_eq(third_text.text, "那就一起看看天黑吧。")
			continue_button = screen.find_child("EventPromptContinueButton", true, false) as Button
			if continue_button != null:
				continue_button.pressed.emit()
				await wait_process_frames(2)
				assert_false(world.is_scene_blocked(), "finishing dialogue should release the scene")
				assert_true(
					(world.get_node("ReturnToDeskButton") as Control).visible,
					"context scene should offer a clear return after the last line"
				)
				assert_false(
					(world.get_node("ThinkButton") as Control).visible,
					"the context scene must not duplicate the desk thought action"
				)


func test_scene_blockers_stack_and_card_detail_uses_the_same_boundary() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(905))
	var stage := _stage()
	var screen = GameScreen.new()
	screen.setup(state, db, RNG.new(906))
	stage.add_child(screen)
	await wait_process_frames(2)
	var world = screen.get_node("SceneWorld")

	screen.set_world_scene_blocker("first", true)
	screen.set_world_scene_blocker("second", true)
	screen.set_world_scene_blocker("first", false)
	assert_true(world.is_scene_blocked(), "closing one of two overlays must not unlock the scene")
	screen.set_world_scene_blocker("second", false)
	assert_false(world.is_scene_blocked())

	screen.show_card_detail(int(state.hand[0]))
	await wait_process_frames(1)
	assert_true(world.is_scene_blocked(), "card details should block lateral input")
	_assert_world_chrome_hidden(world)
	screen.close_card_detail()
	await wait_process_frames(1)
	assert_false(world.is_scene_blocked(), "closing card details should release their blocker")


func _stage() -> Control:
	var stage := Control.new()
	add_child_autofree(stage)
	stage.size = VIEWPORT_SIZE
	return stage


func _assert_world_chrome_hidden(world: Control) -> void:
	for node_name in ["WorldInteractionHint", "MovementHint", "ThinkButton", "ThoughtHeading"]:
		var control := world.get_node_or_null(node_name) as Control
		assert_not_null(control, "%s should exist" % node_name)
		if control != null:
			assert_false(control.visible, "%s should stay hidden behind a blocking overlay" % node_name)
