extends GutTest
const Screen = preload("res://ui/game_screen.gd")
const View = preload("res://ui/rite_view.gd")
var db: ConfigDB
var old_save_path: String
var old_round_root: String
var old_global_path: String
var test_root: String
func before_each():
	old_save_path = SaveSystem.save_path_override
	old_round_root = SaveSystem.round_save_root_override
	old_global_path = GlobalState.global_path_override
	test_root = "user://slot-object-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(test_root)
	SaveSystem.use_save_path(test_root.path_join("save.json"))
	SaveSystem.use_round_save_root(test_root)
	GlobalState.use_global_path(test_root.path_join("global.json"))
func after_each():
	SaveSystem.use_save_path(old_save_path)
	SaveSystem.use_round_save_root(old_round_root)
	GlobalState.use_global_path(old_global_path)
	for filename in DirAccess.get_files_at(test_root):
		DirAccess.remove_absolute(test_root.path_join(filename))
	DirAccess.remove_absolute(test_root)
func before_all():
	db = ConfigDB.new()
	db.load_all()
func _drag(viewport, widget, target):
	var motion = InputEventMouseMotion.new()
	motion.position = widget.get_global_rect().get_center()
	viewport.push_input(motion,true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(),widget,"real input hits source card")
	var click = InputEventMouseButton.new()
	click.position = motion.position
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	viewport.push_input(click,true)
	motion.position -= Vector2(0,80)
	motion.relative = Vector2(0,-80)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	viewport.push_input(motion,true)
	await wait_process_frames(2)
	assert_true(viewport.gui_is_dragging(),"real drag starts")
	motion.position = target
	viewport.push_input(motion,true)
	await wait_process_frames(2)
	print("DROP_TARGET ",viewport.gui_get_hovered_control()," ",target)
	click.position = target
	click.pressed = false
	click.button_mask = 0
	viewport.push_input(click,true)
	await wait_process_frames(4)
	assert_false(viewport.gui_is_dragging())
func test_source_slot_object_transfer():
	# Source contract audit, not an original runtime recording.
	# SetCard 0x53c7d0 reuses card.gameObject; RecoveryCard 0x53c660 retains it.
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		var state = GameState.new()
		var uid = state.add_card_to_hand(2000029,db)
		state.get_card_instance(uid).tags["own"] = 1
		state.get_card_instance(uid).count = 3
		var rite = state.create_rite_instance(5000005)
		var viewport = SubViewport.new()
		viewport.size = dimensions
		viewport.handle_input_locally = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child_autofree(viewport)
		var screen = Screen.new()
		screen.setup(state,db,GameRNG.new(9615))
		viewport.add_child(screen)
		var view = View.new()
		view.setup(state,db,GameRNG.new(9615),5000005,rite.uid)
		screen.add_source_overlay(view)
		screen.set_world_scene_blocker("rite",true,false,true,true)
		await wait_process_frames(4)
		var hand = screen._hand_object(uid)
		assert_not_null(hand)
		var hand_id = hand.get_instance_id()
		var btn = view._slot_buttons.s2
		print("ACCEPT ",view.can_drop_card_on_slot("s2",hand.drag_payload())," ",btn.get_global_rect())
		await _drag(viewport,hand,btn.get_global_rect().get_center())
		assert_eq(int(view._placed.get("s2",0)),uid,"real drop accepted by s2")
		assert_eq(state.get_card_instance(uid).zone,"slot")
		var slot = btn.get_node_or_null("Container/PlacedCard_S2")
		assert_not_null(slot)
		if slot == null:
			viewport.queue_free()
			await wait_process_frames(3)
			continue
		var slot_id = slot.get_instance_id()
		assert_eq(slot_id,hand_id,"SetCard must transfer the same physical object")
		assert_eq(screen._hand_object(uid),slot,"object query must observe slot owner")
		view._refresh_slot_visuals()
		await wait_process_frames(3)
		var refreshed = btn.get_node("Container/PlacedCard_S2")
		assert_eq(refreshed.get_instance_id(),slot_id,"refresh must preserve slot object")
		await RenderingServer.frame_post_draw
		var capture = OS.get_environment("FAUST_TEST_DATA_ROOT")
		if not capture.is_empty():
			viewport.get_texture().get_image().save_png(capture.path_join("slot-%d.png" % dimensions.x))
		var payload = SaveSystem.serialize(state)
		var restored = GameState.new()
		SaveSystem.deserialize(payload,restored,db)
		assert_eq(int(restored.get_rite_instance(rite.uid).slot_cards.s2),uid,"state survives serialization; not full UI reload")
		var before_return = refreshed.get_instance_id()
		await _drag(viewport,refreshed,Vector2(dimensions.x*0.5,dimensions.y-40))
		assert_true(state.has_card_in_hand(uid),"real drag returns card to hand")
		assert_eq(screen._hand_object(uid).get_instance_id(),before_return,"return must keep transferred slot object")
		print("SLOT_OBJECT_AUDIT ",JSON.stringify({"width":dimensions.x,"hand":hand_id,"slot":slot_id,"refreshed":before_return,"returned":screen._hand_object(uid).get_instance_id()}))
		viewport.queue_free()
		await wait_process_frames(3)

func test_restored_slot_is_observed_by_result_binding():
	# Controlled saved-slot fixture. Existing test above covers real transfers.
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		var state = GameState.new()
		var uid = state.add_card_to_hand(2000029,db)
		state.get_card_instance(uid).count = 3
		var rite = state.create_rite_instance(5000005)
		state.add_card_to_slot(uid,2,db,rite.uid)
		assert_true(SaveSystem.save(state))
		var restored = GameState.new()
		var path = test_root.path_join("save.json")
		SaveSystem.deserialize(JSON.parse_string(FileAccess.get_file_as_string(path)),restored,db)
		assert_eq(int(restored.get_rite_instance(rite.uid).slot_cards.s2),uid)
		var viewport = SubViewport.new()
		viewport.size = dimensions
		viewport.handle_input_locally = true
		add_child_autofree(viewport)
		var screen = Screen.new()
		screen.setup(restored,db,GameRNG.new(9615))
		viewport.add_child(screen)
		var view = View.new()
		view.setup(restored,db,GameRNG.new(9615),5000005,rite.uid)
		screen.add_source_overlay(view)
		screen.set_world_scene_blocker("rite",true,false,true,true)
		await wait_process_frames(4)
		var slot = view._slot_buttons.s2.get_node_or_null("Container/PlacedCard_S2")
		assert_not_null(slot,"disk reload reconstructs actual slot object")
		assert_true(restored.result_card_object_exists.call(uid),"restored slot must be observable as a physical object")
		restored.result_card_rewards = [uid]
		var job = {"phase":"await_close"}
		RiteSettlement._bind_result_presentation(job,restored)
		assert_eq(job.presented_result_uids,[uid],"source b__8 observes an existing slot object; controlled list fixture")
		viewport.queue_free()
		await wait_process_frames(3)

func _click(viewport, control, button_index=MOUSE_BUTTON_LEFT):
	var motion = InputEventMouseMotion.new()
	motion.position = control.get_global_rect().get_center()
	viewport.push_input(motion,true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(),control,"real click hits current owner")
	for down in [true,false]:
		var click = InputEventMouseButton.new()
		click.position = motion.position
		click.button_index = button_index
		click.pressed = down
		viewport.push_input(click,true)
		await wait_process_frames(2)

func test_quick_action_ownership_and_close_boundaries():
	# [SRC: RitePanelShowController.OnClose 0x593b10: manual recovery only !start.]
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		for started in [false,true]:
			var state = GameState.new()
			var uid = state.add_card_to_hand(2000029,db)
			state.get_card_instance(uid).count = 3
			var rite = state.create_rite_instance(5000005)
			var viewport = SubViewport.new()
			viewport.size = dimensions
			viewport.handle_input_locally = true
			add_child_autofree(viewport)
			var screen = Screen.new()
			screen.setup(state,db,GameRNG.new(9615))
			viewport.add_child(screen)
			var view = View.new()
			view.setup(state,db,GameRNG.new(9615),5000005,rite.uid)
			screen.add_source_overlay(view)
			screen.set_world_scene_blocker("rite",true,false,true,true)
			view.closed.connect(view.queue_free)
			await wait_process_frames(4)
			var widget = screen._hand_object(uid)
			var root_id = widget.get_instance_id()
			for repeat in range(2):
				await _click(viewport,widget,MOUSE_BUTTON_RIGHT)
				assert_eq(int(view._placed.get("s2",0)),uid)
				assert_eq(screen._hand_object(uid).get_instance_id(),root_id)
				await _click(viewport,widget,MOUSE_BUTTON_RIGHT)
				assert_false(view._placed.has("s2"),"slot quick action only returns; does not reinsert")
				assert_true(state.has_card_in_hand(uid))
				assert_eq(screen._hand_object(uid).get_instance_id(),root_id)
			await _click(viewport,widget,MOUSE_BUTTON_RIGHT)
			rite.start = started
			await _click(viewport,view._close_btn)
			await wait_process_frames(3)
			if started:
				assert_eq(int(rite.slot_cards.s2),uid)
				assert_false(is_instance_valid(widget),"started slot object dies with its slot parent")
				assert_null(screen._hand_object(uid),"stale registry cannot report a destroyed root")
			else:
				assert_true(state.has_card_in_hand(uid))
				assert_eq(screen._hand_object(uid).get_instance_id(),root_id,"unstarted close recovers the same object")
				assert_true(widget.is_visible_in_tree())
			assert_true(SaveSystem.save(state))
			var restored = GameState.new()
			SaveSystem.deserialize(JSON.parse_string(FileAccess.get_file_as_string(test_root.path_join("save.json"))),restored,db)
			assert_eq(restored.get_rite_instance(rite.uid).slot_cards,rite.slot_cards)
			assert_eq(restored.has_card_in_hand(uid),not started)
			viewport.queue_free()
			await wait_process_frames(3)

func test_overlay_replacement_during_drag_preserves_returned_root():
	var state = GameState.new()
	var uid = state.add_card_to_hand(2000029,db)
	state.get_card_instance(uid).count = 3
	var rite = state.create_rite_instance(5000005)
	state.add_card_to_slot(uid,2,db,rite.uid)
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.handle_input_locally = true
	add_child_autofree(viewport)
	var screen = Screen.new()
	screen.setup(state,db,GameRNG.new(9615))
	viewport.add_child(screen)
	var view = View.new()
	view.setup(state,db,GameRNG.new(9615),5000005,rite.uid)
	screen.add_source_overlay(view)
	screen.set_world_scene_blocker("rite",true,false,true,true)
	await wait_process_frames(4)
	var widget = screen._hand_object(uid)
	var original_id = widget.get_instance_id()
	var motion = InputEventMouseMotion.new()
	motion.position = widget.get_global_rect().get_center()
	viewport.push_input(motion,true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(),widget)
	var click = InputEventMouseButton.new()
	click.position = motion.position
	click.button_index = MOUSE_BUTTON_LEFT
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	click.pressed = true
	viewport.push_input(click,true)
	motion.position -= Vector2(0,80)
	motion.relative = Vector2(0,-80)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	viewport.push_input(motion,true)
	await wait_process_frames(2)
	assert_true(viewport.gui_is_dragging())
	assert_eq(state.get_card_instance(uid).zone,"drag")
	# Scene lifecycle interruption, not a source-game mouse command.
	view.queue_free()
	await wait_process_frames(3)
	click.pressed = false
	click.button_mask = 0
	click.position = Vector2(4,4)
	viewport.push_input(click,true)
	await wait_process_frames(3)
	assert_true(state.has_card_in_hand(uid))
	assert_eq(screen._hand_object(uid).get_instance_id(),original_id)
	assert_true(screen._hand_object(uid).is_visible_in_tree())
	viewport.queue_free()
	await wait_process_frames(3)
