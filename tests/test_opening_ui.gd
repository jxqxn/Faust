extends GutTest

const GameScreen = preload("res://ui/game_screen.gd")

func test_real_new_game_choices_grant_source_sample_cards_before_sudan_draw():
	# [SRC: event/5310000 op3, 5310001 op1, 5310002 op2, 5310003 op2;
	# save_samples/auto_save.json notes 10001/10002 provide independent rewards.]
	var stage := Control.new()
	stage.size = get_viewport().get_visible_rect().size
	add_child_autofree(stage)
	var main = load("res://scenes/main.tscn").instantiate()
	stage.add_child(main)
	main._start_new_run(1, false)
	var state: GameState = main.state
	var wife_uid := state.card_uid_for(2000006, "hand")
	var armor_uid := state.card_uid_for(2000368, "hand")
	var follower_uid := state.card_uid_for(2000372, "hand")
	assert_false(state.is_hand_card(wife_uid))
	assert_false(state.is_hand_card(armor_uid))
	assert_false(state.is_hand_card(follower_uid))
	var picked: Array = []
	for step in range(128):
		await wait_process_frames(2)
		if state.pending_operations.is_empty():
			break
		var operation := state.pending_operation()
		assert_eq(state.active_sudan_cards.size(), 0, "no Sultan during opening: %s" % operation.id)
		var screen = main._game_screen
		var choices: Dictionary = operation.get("payload", {}).get("choices", {})
		if operation.kind == "rename_card":
			screen._rename_input.text = "阿尔图"
			screen._consume_event_display()
		elif choices.has("diff_1"):
			screen._consume_event_display("diff_1", choices.diff_1)
		elif operation.has("sequence_response"):
			var id := str(operation.id)
			if id == "5300000_confirm_1":
				screen._consume_event_display("confirm_cancel")
				continue
			var tags := {"5310000_option_1": "op3", "5310001_option_1": "op1", "5310002_option_1": "op2", "5310003_option_1": "op2", "5310004_option_1": "op1"}
			if not tags.has(id):
				fail_test("Unhandled opening choice: " + id)
				return
			var index := -1
			for key in operation.sequence_response.choices:
				var choice: Dictionary = operation.sequence_response.choices[key]
				if choice.tag == tags[id]:
					index = int(choice.index)
			assert_gte(index, 0)
			if index < 0:
				return
			var overlay = screen._event_overlay
			var group = overlay.find_child("OptionGroup", true, false)
			group.get_child(index).pressed.emit()
			var confirm = overlay.find_child("EventPromptConfirmButton", true, false)
			assert_eq(confirm.text, "")
			if id == "5310003_option_1" and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://docs/ui_layout/opening_wife_confirm.png")
			confirm.pressed.emit()
			picked.append(id)
			if id == "5310000_option_1":
				assert_true(state.is_hand_card(armor_uid), "military family unlocks the existing armor")
			if id == "5310002_option_1":
				assert_true(state.is_hand_card(follower_uid), "follower becomes owned at choice completion")
			if id == "5310003_option_1":
				assert_true(state.is_hand_card(wife_uid), "wife appears immediately after her choice")
		else:
			if not choices.is_empty():
				fail_test("Unhandled choices: %s" % operation.id)
				return
			screen._consume_event_display()
	await wait_process_frames(3)
	assert_true(state.pending_operations.is_empty())
	assert_true(state.round_transition.is_empty())
	assert_eq(picked.size(), 5)
	assert_eq(state.active_sudan_cards.size(), 1, "one draw after the complete opening")
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"))
	var expected: Array = [2000001]
	var expected_rites: Array = []
	for note in source.notes[0]:
		if int(note.type) == 1:
			expected_rites.append(int(note.id))
		if int(note.type) in [10001, 10002]:
			expected.append(int(note.id))
	var actual: Array = []
	for uid in state.visible_rail_card_uids():
		if not state.is_active_sudan_card(uid):
			actual.append(state.get_card_instance(uid).card_id)
	expected.sort()
	actual.sort()
	assert_eq(actual, expected, "ordinary opening hand matches original save reward evidence")
	var actual_rites: Array = []
	for instance in state.available_rite_instances():
		actual_rites.append(instance.id)
	assert_eq(actual_rites, expected_rites, "all opening rites and their order match original save notes")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/ui_layout/opening_reward_hand.png")


func test_first_two_days_use_real_next_day_input_and_survive_save_load() -> void:
	var stage := Control.new()
	stage.size = get_viewport().get_visible_rect().size
	add_child_autofree(stage)
	var main = load("res://scenes/main.tscn").instantiate()
	stage.add_child(main)
	main._start_new_run(1, false)
	var state: GameState = main.state
	# Resolve the source opening chain through the live prompt controller.
	for step in range(256):
		await wait_process_frames(1)
		if state.pending_operations.is_empty():
			break
		var op := state.pending_operation()
		var choices: Dictionary = op.get("payload", {}).get("choices", {})
		if choices.has("diff_1"):
			main._game_screen._consume_event_display("diff_1", choices.diff_1)
		elif op.has("sequence_response"):
			var selected := ""
			for key in op.sequence_response.choices:
				if str(op.sequence_response.choices[key].tag) == "op1":
					selected = str(key)
					break
			if selected.is_empty():
				selected = "confirm_cancel"
			main._game_screen._consume_event_display(selected)
		elif op.kind == "rename_card":
			main._game_screen._rename_input.text = "阿尔图"
			main._game_screen._consume_event_display()
		else:
			main._game_screen._consume_event_display()
	await wait_process_frames(2)
	assert_true(state.pending_operations.is_empty())
	assert_true(state.round_transition.is_empty())
	var screen = main._game_screen as GameScreen
	var next_day := screen.get_node("RightActions/AdvanceDayButton") as Button
	var actions := screen.get_node("RightActions") as Control
	assert_false(next_day.disabled, "completed opening enables Next Round")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = next_day.get_global_rect().get_center() - actions.global_position
	screen._on_right_actions_gui_input(press)
	await wait_process_frames(2)
	assert_eq(state.round_number, 2, "real mouse input starts the second day")
	assert_true(screen.get_node_or_null("NextDayTransitionMask") != null or state.round_transition.is_empty(), "next-day transition is represented while the chain runs")
	var saved := SaveSystem.serialize(state)
	var restored := GameState.new()
	SaveSystem.deserialize(saved, restored, main.db)
	assert_eq(restored.round_number, 2, "second-day state survives save/load")
