extends SceneTree

## GPU check for the source-shaped RiteResultPanel shell and its real commit
## button. The settlement payload is synthetic; this verifies presentation and
## input routing, while RiteResolver/GUT cover the source-backed semantics.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _click(control: Control) -> void:
	if control == null:
		failures.append("missing click target")
		return
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event, true)
		await process_frame
	for i in 8:
		await process_frame

func _run() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var rng := GameRNG.new(702)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var screen := preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := preload("res://ui/rite_view.gd").new()
	view.setup(state, db, rng, 5000001)
	view._rite = {"id": 5000001, "name": "结算测试", "round_number": 0,
		"cards_slot": {"s1": {"condition": {"type": "char"}}},
		"settlement": [{"condition": {"r1:体魄>=": [1, 5]}, "result": {"coin": 1},
		"result_title": "结算完成", "result_text": "源结算面板测试"}],
		"settlement_prior": [], "settlement_extre": []}
	screen.add_source_overlay(view)
	screen.set_world_scene_blocker("rite", true, false, true, true)
	for i in 12:
		await process_frame
	var card_uid := state.add_card_to_hand(2000001, db)
	view._place_card_in_slot("s1", card_uid, "hand", "")
	await _click(view._resolve_btn)
	if not view._resolution_pending:
		failures.append("resolve did not enter result preview")
	# Enable the source-backed toggle after entering the manual result preview;
	# auto_result=1 at start would correctly bypass this surface for a zero-day rite.
	view._rite["auto_result"] = 1
	var result_panel := view.find_child("RiteResultPanel", true, false) as Control
	if result_panel == null or not result_panel.visible:
		failures.append("source result panel is not visible")
	else:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/rite_result_surface_%d.png" % root.size.x)
	# Exercise the actual source-side hit targets while preparation is hidden.
	var initial_gold := state.gold_dice
	view._rerolls_left = 1
	view._refresh_dice_selection()
	await _click(view._gold_dice_btn)
	if view._gold_selected != 1 or state.gold_dice != initial_gold:
		failures.append("gold click did not reserve without spending")
	await _click(view._dice_count_prompt_surface.get_node("Gold Cancel"))
	if view._gold_selected != 0 or state.gold_dice != initial_gold:
		failures.append("gold cancellation changed resources")
	await _click(view._reroll_btn)
	if view._dice_count_kind != "reroll":
		failures.append("redraw side control did not receive click")
	await _click(view._dice_count_prompt_surface.get_node("Redraw Cancel"))
	if view._rerolls_left != 1 or not view._dice_count_kind.is_empty():
		failures.append("redraw cancellation changed resources")
	await _click(view._gold_dice_btn)
	await _click(view._dice_count_prompt_surface.get_node("Gold Confirm"))
	if state.gold_dice != initial_gold - 1:
		failures.append("gold confirmation did not spend once")
	var play_rate := view.find_child("PlayRate", true, false) as Button
	if play_rate == null or not play_rate.visible:
		failures.append("source result PlayRate button is not visible")
	else:
		var initial_texture: String = str(play_rate.get_node("Art").texture.resource_path)
		await _click(play_rate)
		if play_rate.get_node("Art").texture.resource_path == initial_texture:
			failures.append("PlayRate click did not toggle source texture")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/rite_result_surface_playrate_%d.png" % root.size.x)
	var auto_button := view.find_child("AutoPlay", true, false) as Button
	if auto_button == null or not auto_button.visible:
		failures.append("source result AutoPlay button is not visible")
	else:
		await _click(auto_button)
		if not state.auto_result_rites.has(view._rite_id):
			failures.append("AutoPlay click did not update the player flag")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/rite_result_surface_autoplay_%d.png" % root.size.x)
	var next_button := view.find_child("Next", true, false) as Control

	if next_button == null or not next_button.visible:
		failures.append("source result next button is not visible")
	else:
		await _click(next_button)
	if state.get_rite_instance(view._rite_uid) != null:
		# The first source Next press completes the typewriter text. The second
		# advances the settlement promise and removes the rite.
		await _click(next_button)
	if state.get_rite_instance(view._rite_uid) != null:
		failures.append("source result next button did not commit the rite")
	print("RITE_RESULT_SURFACE_INPUT: ", "PASS" if failures.is_empty() else failures)
	screen.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
