extends "res://tools/verify_prompt_preferred_layout.gd"

func run() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var rng := preload("res://core/rng.gd").new(315)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var first := state.add_card_to_hand(2001193, db)
	var second := state.add_card_to_hand(2001193, db)
	var operations := ResultExec.execute({"change_name": 2001193}, state, db, {})
	DeferredEffects.apply(operations, state, db, rng)
	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	root.add_child(stage)
	var screen := preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	stage.add_child(screen)
	await settle()
	var input := screen.find_child("CardRenameInput", true, false) as LineEdit
	if input == null:
		push_error("source change_name did not open prompt")
		quit(1)
		return
	await click(input)
	input.select_all()
	for codepoint in [32, 65, 32]:
		var key := InputEventKey.new()
		key.unicode = codepoint
		key.pressed = true
		root.push_input(key, true)
		await process_frame
	await settle()
	await capture("rename_state")
	await click(screen.find_child("CardRenameConfirmButton", true, false))
	if not state.pending_operations.is_empty():
		failures.append("rename did not consume the pending operation")
	if state.player_card_names.get(2001193, "") != " A ":
		failures.append("source id map did not receive the untrimmed input")
	for uid in [first, second]:
		if state.card_data_for(uid, db).name != " A " or state.get_card_instance(uid).custom_name != "":
			failures.append("same-id instances did not share the name override")
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	var future := restored.add_card_to_hand(2001193, db)
	if restored.card_data_for(future, db).name != " A ":
		failures.append("saved id override did not cover a future card")
	stage.queue_free()
	await settle()
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("RENAME_STATE_INPUT: PASS")
	quit(0 if failures.is_empty() else 1)
