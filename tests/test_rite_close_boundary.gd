extends GutTest

const RiteView = preload("res://ui/rite_view.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const RNG = preload("res://core/rng.gd")

class TraceState extends GameState:
	var timings: Array[String] = []
	var block_end := false
	var reveal_on_end_uid := 0
	func trigger_events(timing: String, _ctx: Dictionary = {}) -> Array[int]:
		timings.append(timing)
		if timing == "rite_end" and reveal_on_end_uid > 0:
			get_card_instance(reveal_on_end_uid).bag = current_bag_index
		var result: Array[int] = [] # Controlled timing probe; real event content has separate oracle tests.
		if timing == "rite_end" and block_end:
			queue_prompt({"id": "close-boundary", "text": "仪式结束后的提示"})
		return result

var db: ConfigDB
var old_save_path: String
var test_path: String
var old_global_path: String
var old_round_root: String
var test_root: String

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func before_each() -> void:
	old_save_path = SaveSystem.save_path_override
	old_global_path = GlobalState.global_path_override
	old_round_root = SaveSystem.round_save_root_override
	test_root = "user://rite-close-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(test_root)
	test_path = test_root.path_join("save.json")
	SaveSystem.use_save_path(test_path)
	SaveSystem.use_round_save_root(test_root)
	GlobalState.use_global_path(test_root.path_join("global.json"))

func after_each() -> void:
	SaveSystem.use_save_path(old_save_path)
	SaveSystem.use_round_save_root(old_round_root)
	GlobalState.use_global_path(old_global_path)
	for filename in DirAccess.get_files_at(test_root):
		DirAccess.remove_absolute(test_root.path_join(filename))
	DirAccess.remove_absolute(test_root)

func _viewport(dimensions: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(viewport)
	return viewport

func _mount(viewport: SubViewport, state: GameState, uid: int) -> Control:
	var screen := GameScreen.new()
	screen.setup(state, db, RNG.new(9615))
	viewport.add_child(screen)
	var view := RiteView.new()
	view.setup(state, db, RNG.new(9615), 5000001, uid)
	screen.add_source_overlay(view)
	view.set_meta("test_screen", screen)
	return view

# An empty selected result isolates the close continuation from story selection.
# This fixture is not an original runtime trace or a full rite input sequence.
func _prepare(view: Control) -> void:
	view._last_result = RiteResolver.RiteResult.new()
	view._resolution_pending = true
	view._settlement_phase = "selection"
	view._settlement_context = {"rite_id": 5000001, "rite_uid": view._rite_uid}
	view._result_surface.show()
	view._result_text_done = true
	view._result_paragraph_index = 0
	view._result_paragraphs.clear()

func _click(viewport: SubViewport, button: Button) -> void:
	assert_not_null(button)
	if button == null:
		return
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(), button, "real mouse hits " + button.name)
	for pressed in [true, false]:
		var input := InputEventMouseButton.new()
		input.position = motion.position
		input.button_index = MOUSE_BUTTON_LEFT
		input.pressed = pressed
		viewport.push_input(input, true)
		await wait_process_frames(1)

func _read_saved() -> TraceState:
	var restored := TraceState.new()
	SaveSystem.deserialize(JSON.parse_string(FileAccess.get_file_as_string(test_path)), restored, db)
	return restored

func _capture(viewport: SubViewport, label: String) -> void:
	var prefix := OS.get_environment("FAUST_CLOSE_CAPTURE")
	if prefix.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	assert_eq(viewport.get_texture().get_image().save_png(prefix + label + ".png"), OK)

func test_commit_then_disk_rebuild_then_close_waits_at_both_sizes() -> void:
	# [SRC: Settlement.b__8 0x5b4850 enables btnNext; OnClose 0x5a3ae0
	# owns OnRiteEnd. dump.cs:325466 finalPromise and backCards fields.]
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		var state := TraceState.new()
		var rite = state.create_rite_instance(5000001)
		var viewport := _viewport(dimensions)
		var view := _mount(viewport, state, rite.uid)
		await wait_process_frames(2)
		_prepare(view)
		await _click(viewport, view._result_next_button)
		assert_true(view._resolution_committed)
		assert_eq(state.timings.count("rite_end"), 0)
		assert_eq(state.rite_settlements[str(rite.uid)].phase, "await_close")
		assert_null(state.get_rite_instance(rite.uid), "RemoveRite already happened")
		assert_true(state.round_transition.is_empty(), "manual result must not invent a day transition")
		assert_false(state.rite_result_display.is_empty())
		await _capture(viewport, "committed-%d" % dimensions.x)
		assert_true(SaveSystem.save(state))
		view.get_meta("test_screen").queue_free()
		await wait_process_frames(2)
		state = _read_saved()
		view = _mount(viewport, state, rite.uid)
		view.restore_round_result(state.rite_result_display)
		await wait_process_frames(2)
		assert_true(view._result_surface.is_visible_in_tree())
		await _capture(viewport, "restored-%d" % dimensions.x)
		watch_signals(view)
		await _click(viewport, view._result_next_button)
		assert_eq(state.timings.count("rite_end"), 1)
		assert_signal_emitted(view, "settlement_closed")
		assert_signal_emit_count(view, "closed", 1)
		assert_true(state.rite_settlements.is_empty())
		assert_true(state.rite_result_display.is_empty())
		view._close_panel()
		assert_eq(state.timings.count("rite_end"), 1, "repeated close is idempotent")
		viewport.queue_free()
		await wait_process_frames(2)

func test_close_prompt_holds_continuation_across_disk_and_real_prompt_input() -> void:
	var state := TraceState.new()
	state.block_end = true
	var rite = state.create_rite_instance(5000001)
	var viewport := _viewport(Vector2i(1280, 720))
	var view := _mount(viewport, state, rite.uid)
	await wait_process_frames(2)
	_prepare(view)
	await _click(viewport, view._result_next_button)
	watch_signals(view)
	await _click(viewport, view._result_next_button)
	assert_false(view.visible, "OnClose hides its panel before the child event")
	assert_eq(state.timings.count("rite_end"), 1)
	assert_eq(state.pending_operations.size(), 1)
	assert_eq(state.rite_settlements[str(rite.uid)].phase, "done", "pending child still holds the job")
	assert_signal_not_emitted(view, "closed", "do not release the next day before child completion")
	assert_true(state.rite_result_display.closing)
	await _capture(viewport, "closing-prompt")
	assert_true(SaveSystem.save(state))
	view.get_meta("test_screen").queue_free()
	await wait_process_frames(2)
	state = _read_saved()
	state.block_end = true
	view = _mount(viewport, state, rite.uid)
	view.restore_round_result(state.rite_result_display)
	watch_signals(view)
	await wait_process_frames(3)
	assert_false(view.visible)
	assert_eq(state.timings.count("rite_end"), 0, "restore does not redispatch the event")
	var button := viewport.find_child("EventPromptContinueButton", true, false) as Button
	await _click(viewport, button)
	await wait_process_frames(3)
	assert_true(state.pending_operations.is_empty())
	assert_true(state.rite_settlements.is_empty())
	assert_true(state.rite_result_display.is_empty())
	assert_signal_emit_count(view, "closed", 1)
	assert_eq(state.timings.count("rite_end"), 0)

func test_v8_display_migration_does_not_replay_already_dispatched_events() -> void:
	var state := GameState.new()
	var saved := SaveSystem.serialize(state)
	saved.version = 8
	saved.erase("rite_result_display")
	saved.round_transition = {"phase": "rites", "rite_display": {"uid": 77, "committed": true}}
	SaveSystem.deserialize(saved, state, db)
	assert_eq(state.rite_result_display.uid, 77)
	assert_false(state.round_transition.has("rite_display"))
	assert_true(state.rite_settlements.is_empty(), "old completed effects cannot be undone or replayed")
	saved.rite_settlements = {"77": {"uid": 77, "phase": "actions"}}
	SaveSystem.deserialize(saved, state, db)
	assert_true(state.rite_settlements["77"].wait_for_close, "unfinished legacy actions acquire the new close boundary")
	saved.rite_settlements = {"77": {"uid": 77, "phase": "post_lives"}}
	SaveSystem.deserialize(saved, state, db)
	assert_false(state.rite_settlements["77"].get("wait_for_close", false), "already-started legacy close effects are not rewound")

func test_automatic_close_uses_same_continuation_and_cancel_clears_preview() -> void:
	var state := TraceState.new()
	var rite = state.create_rite_instance(5000001)
	var viewport := _viewport(Vector2i(1280, 720))
	var view := _mount(viewport, state, rite.uid)
	await wait_process_frames(2)
	_prepare(view)
	view._remember_round_result()
	assert_false(state.rite_result_display.is_empty())
	view._close_panel()
	assert_true(state.rite_result_display.is_empty(), "cancelled preview cannot reopen after a save")
	view.get_meta("test_screen").queue_free()
	await wait_process_frames(2)
	view = _mount(viewport, state, rite.uid)
	await wait_process_frames(2)
	_prepare(view)
	watch_signals(view)
	view._close_after_commit = true
	await wait_process_frames(3)
	assert_eq(state.timings.count("rite_end"), 1, "automatic close must not bypass OnClose effects")
	assert_true(state.rite_settlements.is_empty())
	assert_signal_emit_count(view, "closed", 1)

func test_post_rite_expiry_waits_for_close_and_resumes_without_reaging() -> void:
	# Controlled existing-protocol fixture for a returned host's expired equipment.
	# [SRC: OnClose 0x5a3ae0 -> backCards.DoPostRite 0x4f0d70.]
	db.cards[990601] = {"id": 990601, "type": "item", "tag": {}, "card_vanishing": 1,
		"vanish": {"prompt": {"id": "equipment_expired"}, "coin": 2}}
	var state := TraceState.new()
	var rng := RNG.new(13)
	var rite = state.create_rite_instance(5000001)
	var host := state.add_card_to_hand(2000001, db)
	var equip = state.create_card_instance(990601, db, "removed")
	state.attach_equipment(host, equip.uid, db, false, false)
	equip.life = 1
	state.remove_card_from_hand(host)
	state.add_card_to_slot(host, 1, db, rite.uid)
	var job := RiteSettlement.begin(rite.uid, RiteResolver.RiteResult.new(), {"rite_id": rite.id}, state, db, rng, true)
	assert_eq(job.phase, "await_close")
	assert_true(equip.uid in state.get_card_instance(host).equipped_uids)
	assert_eq(state.timings.count("rite_end"), 0)
	RiteSettlement.close_result(rite.uid, state, db, rng)
	assert_false(equip.uid in state.get_card_instance(host).equipped_uids)
	assert_eq(equip.life, 1)
	assert_eq(state.pending_operations.size(), 1)
	assert_eq(state.timings.count("rite_end"), 0, "vanish prompt precedes rite_end")
	assert_true(SaveSystem.save(state))
	state = _read_saved()
	OperationsSequence.resume(state.consume_pending_operation(), state, db, rng)
	RiteSettlement.pump(state, db, rng)
	assert_eq(state.coin_count, 2)
	assert_eq(state.timings.count("rite_end"), 1)
	assert_true(state.rite_settlements.is_empty())
	db.cards.erase(990601)

func test_main_scene_rebuilds_manual_result_and_close_prompt_then_autosaves() -> void:
	var viewport := _viewport(Vector2i(1920, 1080))
	var main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	var state := TraceState.new()
	state.block_end = true
	state.setup_new_run(main.db, 1, main.rng)
	state.pending_operations.clear()
	var rite = state.create_rite_instance(5000001)
	main.state = state
	main._show_game()
	main._on_open_rite_instance(rite.uid)
	await wait_process_frames(2)
	_prepare(main._rite_overlay)
	await _click(viewport, main._rite_overlay._result_next_button)
	assert_eq(state.timings.count("rite_end"), 0)
	assert_true(SaveSystem.save(state))
	main.queue_free()
	await wait_process_frames(2)
	main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	main._on_continue()
	await wait_process_frames(3)
	assert_not_null(main._rite_overlay, "manual result is restored without round_transition")
	assert_eq(main._rite_overlay._rite_uid, rite.uid)
	assert_null(main.state.get_rite_instance(rite.uid), "restore must not recreate a removed Rite")
	# Persist a blocking close fixture through the actual controller. Its state
	# is a serialized ordinary prompt; no test subclass is required on reload.
	main.state = state
	main._show_game()
	await wait_process_frames(2)
	await _click(viewport, main._rite_overlay._result_next_button)
	assert_true(main.state.rite_result_display.closing)
	assert_false(main._rite_overlay.visible)
	assert_eq(main.state.pending_operations.size(), 1)
	assert_true(SaveSystem.save(main.state))
	main.queue_free()
	await wait_process_frames(2)
	main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	main._on_continue()
	await wait_process_frames(3)
	assert_false(main._rite_overlay.visible)
	assert_eq(main.state.rite_settlements[str(rite.uid)].phase, "done")
	await _click(viewport, main._game_screen._event_overlay._confirm_button)
	await wait_process_frames(3)
	assert_null(main._rite_overlay)
	assert_true(main.state.rite_settlements.is_empty())
	assert_true(main.state.rite_result_display.is_empty())
	var autosave: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(test_path))
	assert_true(autosave.rite_result_display.is_empty(), "automatic save happens after close completion")
	assert_true(autosave.rite_settlements.is_empty())


func test_close_sort_membership_precedes_end_event_and_survives_disk_prompt() -> void:
	# Controlled boundary: OnClose collects flash_cards before OnRiteEnd.
	# [SRC: RiteResultPanelController.c:1202-1298; dump.cs:325087.]
	var state := TraceState.new()
	state.block_end = true
	var control := state.add_card_to_hand(2000006, db)
	var returned := state.add_card_to_hand(2000372, db)
	var late := state.add_card_to_hand(2000006, db)
	for uid in [control, returned, late]:
		state.get_card_instance(uid).tags["own"] = 1
	state.get_card_instance(control).bag_pos = 1
	state.get_card_instance(returned).bag_pos = 2
	state.get_card_instance(late).bag_pos = 3
	state.get_card_instance(late).bag = 1
	state.reveal_on_end_uid = late
	var rite = state.create_rite_instance(5000001)
	var viewport := _viewport(Vector2i(1280, 720))
	var view := _mount(viewport, state, rite.uid)
	await wait_process_frames(2)
	_prepare(view)
	await _click(viewport, view._result_next_button)
	var job: Dictionary = state.rite_settlements[str(rite.uid)]
	job.back_card_uids = [returned]
	job.deferred.card_ops = [{"op": GameState.CARD_OP_NEW, "card_uid": late}]
	await _click(viewport, view._result_next_button)
	assert_eq(state.pending_operations.size(), 1)
	assert_eq(job.get("close_sort_uids", []), [returned], "end event cannot expand the captured group")
	assert_true(SaveSystem.save(state))
	view.get_meta("test_screen").queue_free()
	await wait_process_frames(2)
	state = _read_saved()
	view = _mount(viewport, state, rite.uid)
	view.restore_round_result(state.rite_result_display)
	await wait_process_frames(3)
	assert_eq(state.rite_settlements[str(rite.uid)].get("close_sort_uids", []).map(func(uid): return int(uid)), [returned], "JSON numeric representation preserves the captured identities")
	await _click(viewport, viewport.find_child("EventPromptContinueButton", true, false) as Button)
	await wait_process_frames(3)
	assert_true(state.rite_settlements.is_empty())
	assert_eq(state.visible_rail_card_uids(), [returned, control, late], "late-visible reward is not promoted")
	assert_true(SaveSystem.save(state))
	var reloaded := _read_saved()
	assert_eq(reloaded.visible_rail_card_uids(), [returned, control, late])


func test_empty_close_snapshot_does_not_fall_back_to_later_candidates() -> void:
	var state := GameState.new()
	var first := state.add_card_to_hand(2000006, db)
	var late := state.add_card_to_hand(2000006, db)
	for uid in [first, late]:
		state.get_card_instance(uid).tags["own"] = 1
		state.get_card_instance(uid).bag_pos = uid
	var job := {"close_sort_uids": [], "back_card_uids": [late], "deferred": {"card_ops": []}}
	RiteSettlement._sort_closed_result(job, state, db)
	assert_eq(state.visible_rail_card_uids(), [first, late], "empty means no selected cards, not missing snapshot")


func _freeze_and_find_flash(screen: Control, uid: int) -> CardWidget:
	var found: CardWidget = null
	for widget in screen._ordered_hand_cards():
		widget.set_process(false)
		if widget.card_uid == uid:
			found = widget
	assert_not_null(found)
	return found


func test_close_flash_waits_for_end_and_survives_refresh_and_disk_at_both_sizes() -> void:
	# [SRC: FlashAndSortCard 0x54eff0; CardFlashController 0x52e330;
	# CardNew.prefab:1898-1922. Persistence is a host reconstruction adapter.]
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		var state := TraceState.new()
		state.block_end = true
		var other := state.add_card_to_hand(2000006, db)
		var returned := state.add_card_to_hand(2000372, db)
		for uid in [other, returned]:
			state.get_card_instance(uid).tags["own"] = 1
			state.get_card_instance(uid).bag_pos = uid
		var rite = state.create_rite_instance(5000001)
		var viewport := _viewport(dimensions)
		var view := _mount(viewport, state, rite.uid)
		await wait_process_frames(2)
		_prepare(view)
		await _click(viewport, view._result_next_button)
		state.rite_settlements[str(rite.uid)].back_card_uids = [returned]
		await _click(viewport, view._result_next_button)
		assert_true(state.hand_card_flashes.is_empty(), "blocked OnRiteEnd cannot start the flash")
		assert_true(SaveSystem.save(state))
		view.get_meta("test_screen").queue_free()
		await wait_process_frames(2)
		state = _read_saved()
		view = _mount(viewport, state, rite.uid)
		view.restore_round_result(state.rite_result_display)
		await wait_process_frames(3)
		await _click(viewport, viewport.find_child("EventPromptContinueButton", true, false) as Button)
		var screen: Control = view.get_meta("test_screen")
		var widget := _freeze_and_find_flash(screen, returned)
		assert_true(widget._flash_rising or widget._flash_time > 0.0, "actual close starts the returned card flash")
		assert_eq(float(state.hand_card_flashes[str(other)].time), 0.0)
		assert_false(bool(state.hand_card_flashes[str(other)].rising), "nonmatch is reset")
		var progress := widget._flash_time
		screen.refresh()
		widget = _freeze_and_find_flash(screen, returned)
		assert_eq(widget._flash_time, progress, "refresh restores rather than restarts")
		await wait_process_frames(1)
		assert_eq(widget._flash_time, progress, "queued old widgets cannot advance shared state")
		# Cross the clamp boundary; a computed exact delta can round below 1.0.
		widget._advance_card_flash((1.0 - progress) / 3.0 + 0.000001)
		assert_almost_eq(widget._flash_time, 1.0, 0.0001)
		assert_false(widget._flash_rising)
		await _capture(viewport, "flash-peak-%d" % dimensions.x)
		assert_true(SaveSystem.save(state))
		screen.queue_free()
		await wait_process_frames(2)
		state = _read_saved()
		screen = GameScreen.new()
		screen.setup(state, db, RNG.new(9615))
		viewport.add_child(screen)
		widget = _freeze_and_find_flash(screen, returned)
		assert_almost_eq(widget._flash_time, 1.0, 0.0001, "disk reload keeps peak progress")
		assert_false(widget._flash_rising, "disk reload keeps the falling direction")
		widget._advance_card_flash(1.0 / 6.0)
		assert_almost_eq(float(widget._flash_material.get_shader_parameter("outline_fade")), 0.75, 0.0001)
		await _capture(viewport, "flash-falling-%d" % dimensions.x)
		widget.set_process(true)
		await wait_seconds(0.25)
		assert_eq(widget._flash_time, 0.0, "real frame processing completes the falling half")
		assert_true(SaveSystem.save(state))
		var ended := _read_saved()
		assert_eq(float(ended.hand_card_flashes[str(returned)].time), 0.0)
		assert_false(bool(ended.hand_card_flashes[str(returned)].rising), "completed flashes do not replay on load")
		viewport.queue_free()
		await wait_process_frames(2)


func test_generated_sudan_is_collected_and_survives_disk_before_close() -> void:
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		var state := TraceState.new()
		state.reset_sudan_pool_to_ids([2010002])
		var rite = state.create_rite_instance(5000001)
		var viewport := _viewport(dimensions)
		var view := _mount(viewport, state, rite.uid)
		await wait_process_frames(2)
		_prepare(view)
		await _click(viewport, view._result_next_button)
		# Controlled generation while the result panel owns CardRewards.
		# REA GenSudanCard 0x54f6f0 -> PutCardOnTable 0x5556c0.
		assert_eq(RoundLoop.draw_weekly_sudan(state, db, RNG.new(9615)), 2010002)
		var generated := int(state.active_sudan_cards[0].card_uid)
		assert_true(SaveSystem.save(state))
		view.get_meta("test_screen").queue_free()
		await wait_process_frames(2)
		state = _read_saved()
		view = _mount(viewport, state, rite.uid)
		view.restore_round_result(state.rite_result_display)
		await wait_process_frames(3)
		await _click(viewport, view._result_next_button)
		var widget := _freeze_and_find_flash(view.get_meta("test_screen"), generated)
		assert_true(widget._flash_rising or widget._flash_time > 0.0, "generated Sultan belongs to close flash set after disk reload")
		viewport.queue_free()
		await wait_process_frames(2)


func test_result_list_distinguishes_table_generation_and_freezes_once() -> void:
	var state := TraceState.new()
	var stale := state.add_card_to_hand(2000006, db)
	var rite = state.create_rite_instance(5000001)
	var selection := RiteResolver.RiteResult.new()
	var job := RiteSettlement.begin(rite.uid, selection, {"rite_id": 5000001}, state, db, RNG.new(1), true)
	assert_true(state.result_card_rewards.is_empty(), "Settlement b__4 clears prior shared list")
	var generated := ResultExec.execute({"card": 2000372}, state, db)
	var reward := int(generated.card_ops[0].card_uid)
	state.get_card_instance(reward).tags["own"] = 1
	assert_true(reward in state.visible_rail_card_uids(), "fixture reward is on current hand page")
	state.begin_result_op_log()
	var raw = state.create_card_instance(2000006, db, "hand")
	state.add_card_to_hand(raw.uid, db)
	var raw_ops: Array = state.drain_result_op_log()
	job.deferred.card_ops.append_array(generated.card_ops)
	job.deferred.card_ops.append_array(raw_ops)
	assert_eq(state.result_card_rewards, [reward], "raw allocation/return is not PutCardOnTable")
	RiteSettlement._capture_result_card_rewards(job, state)
	assert_eq(job.result_card_uids, [reward])
	assert_true(state.result_card_rewards.is_empty(), "OnClose clears list before post-rite effects")
	var later := state.add_card_to_hand(2000006, db)
	RiteSettlement._capture_result_card_rewards(job, state)
	assert_eq(job.result_card_uids, [reward], "resuming a blocked close cannot collect again")
	assert_eq(state.result_card_rewards, [later], "later generation belongs to the shared list, not frozen close")
	assert_true(SaveSystem.save(state))
	var restored := _read_saved()
	var saved_job: Dictionary = restored.rite_settlements[str(rite.uid)]
	assert_eq(RiteSettlement._close_sort_candidates(saved_job, restored), [reward])
	assert_eq(restored.result_card_rewards, [later])
	assert_false(saved_job.result_card_uids.has(stale))
	assert_false(saved_job.result_card_uids.has(raw.uid))


func test_pre_list_save_keeps_legacy_candidates() -> void:
	var state := TraceState.new()
	var reward := state.add_card_to_hand(2000372, db)
	state.get_card_instance(reward).tags["own"] = 1
	assert_true(reward in state.visible_rail_card_uids(), "legacy fixture reward is on current hand page")
	var job := {"back_card_uids": [], "deferred": {"card_ops": [{"op": GameState.CARD_OP_NEW, "card_uid": reward}]}}
	RiteSettlement._capture_result_card_rewards(job, state)
	assert_false(job.has("result_card_uids"), "no new list marker in old in-flight saves")
	assert_eq(RiteSettlement._close_sort_candidates(job, state), [reward])


func test_result_presentation_binding_is_frozen_and_does_not_change_rule_membership() -> void:
	var state := TraceState.new()
	var reward := state.add_card_to_hand(2000372, db)
	state.get_card_instance(reward).tags["own"] = 1
	var other := state.add_card_to_hand(2000006, db)
	state.get_card_instance(other).tags["own"] = 1
	state.result_card_rewards = [reward]
	var job := {"phase": "await_close"}
	state.rite_settlements["99"] = job
	RiteSettlement._bind_result_presentation(job, state)
	assert_true(reward in state.visible_rail_card_uids(), "ownership and rule scope unchanged")
	assert_false(reward in state.presented_rail_card_uids(), "bound physical card leaves hand presentation")
	assert_true(other in state.presented_rail_card_uids(), "unrelated hand remains usable")
	var late := state.add_card_to_hand(2000006, db)
	state.get_card_instance(late).tags["own"] = 1
	state.result_card_rewards.append(late)
	RiteSettlement._bind_result_presentation(job, state)
	assert_true(late in state.presented_rail_card_uids(), "later generation is not retroactively bound")
	assert_true(SaveSystem.save(state))
	var restored := _read_saved()
	assert_false(reward in restored.presented_rail_card_uids(), "JSON numeric UIDs restore ownership")
	restored.rite_settlements["99"].phase = "post_lives"
	assert_true(reward in restored.presented_rail_card_uids(), "OnClose releases before blocking end event")
	job.erase("presented_result_uids")
	assert_true(reward in state.presented_rail_card_uids(), "legacy job retains legacy presentation")
