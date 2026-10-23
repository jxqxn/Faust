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
	test_root = "user://equipment-object-%d" % Time.get_ticks_usec()
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
func _drag(viewport, widget, target, after_start: Callable = Callable()):
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
	if after_start.is_valid():
		after_start.call()
		await wait_process_frames(2)
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
func _fixture(dimensions: Vector2i) -> Dictionary:
	var state := GameState.new()
	var host_uid := state.add_card_to_hand(2000001, db)
	var equip_uid := state.add_card_to_hand(2000246, db)
	state.get_card_instance(host_uid).tags["own"] = 1
	state.get_card_instance(equip_uid).tags["own"] = 1
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(viewport)
	var screen = Screen.new()
	screen.setup(state, db, GameRNG.new(9615))
	viewport.add_child(screen)
	await wait_process_frames(3)
	return {"state":state,"host":host_uid,"equip":equip_uid,"viewport":viewport,"screen":screen}

func _click(viewport, control):
	var point = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion,true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(),control,"real click target")
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event,true)
	await wait_process_frames(3)

func test_equipment_root_reuse_refresh_close_and_disk_restore():
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		var f = await _fixture(dimensions)
		var original = f.screen._hand_object(f.equip)
		assert_not_null(original)
		var object_id = original.get_instance_id()
		f.state.attach_equipment(f.host,f.equip,db,true,true)
		f.screen.refresh()
		await _click(f.viewport,f.screen._hand_object(f.host))
		var detail = f.screen._card_info_view
		assert_not_null(detail)
		var shown = detail._equip_rows.get_child(0)
		assert_eq(shown.get_instance_id(),object_id,"RefreshAllEquips reuses card.gameObject")
		assert_eq(f.screen._hand_object(f.equip),shown)
		f.screen.refresh()
		assert_eq(shown.get_parent(),detail._equip_rows,"general refresh does not steal equipped root")
		detail.show_card(f.state.card_data_for(f.host,db),f.host)
		await wait_process_frames(3)
		assert_eq(detail._equip_rows.get_child(0).get_instance_id(),object_id,"Clear(false) keeps existing object")
		assert_true(SaveSystem.save(f.state))
		await RenderingServer.frame_post_draw
		var capture = OS.get_environment("FAUST_TEST_DATA_ROOT")
		if not capture.is_empty():
			f.viewport.get_texture().get_image().save_png(capture.path_join("equipment-%d.png" % dimensions.x))
		await _click(f.viewport,detail.find_child("CloseCardDetailButton",true,false))
		assert_null(f.screen._card_info_view)
		assert_false(is_instance_valid(original),"OnClose destroys the still-parented equipment root")
		assert_eq(f.state.get_card_instance(f.equip).zone,"equipped")
		var restored := GameState.new()
		SaveSystem.deserialize(JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.save_path())),restored,db)
		f.screen.queue_free()
		await wait_process_frames(3)
		var screen = Screen.new()
		screen.setup(restored,db,GameRNG.new(9615))
		f.viewport.add_child(screen)
		await wait_process_frames(3)
		await _click(f.viewport,screen._hand_object(f.host))
		var rebuilt = screen._card_info_view._equip_rows.get_child(0)
		assert_eq(rebuilt.card_uid,f.equip)
		assert_eq(screen._hand_object(f.equip),rebuilt,"disk restore materializes registered equipment root")
		assert_ne(rebuilt.get_instance_id(),object_id)
		f.viewport.queue_free()
		await wait_process_frames(3)

func test_equipment_real_drag_returns_same_object_and_persists():
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		var f = await _fixture(dimensions)
		f.state.attach_equipment(f.host,f.equip,db,true,true)
		f.screen.refresh()
		await _click(f.viewport,f.screen._hand_object(f.host))
		var detail = f.screen._card_info_view
		var widget = detail._equip_rows.get_child(0)
		var id = widget.get_instance_id()
		assert_true(detail._can_move_equipment(f.equip))
		await _drag(f.viewport,widget,Vector2(dimensions.x*0.75,dimensions.y-25))
		assert_eq(f.state.get_card_instance(f.equip).zone,"hand")
		assert_false(f.state.get_card_instance(f.host).equipped_uids.has(f.equip))
		assert_eq(f.screen._hand_object(f.equip).get_instance_id(),id)
		assert_eq(detail._equip_rows.get_child_count(),0)
		assert_true(widget.visible)
		var restored := GameState.new()
		SaveSystem.deserialize(JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.save_path())),restored,db)
		assert_eq(restored.get_card_instance(f.equip).zone,"hand")
		assert_eq(restored.get_card_instance(f.equip).equipped_to_uid,0)
		f.viewport.queue_free()
		await wait_process_frames(3)


func test_drag_gate_blocks_started_host_missing_ownership_and_modal():
	var f = await _fixture(Vector2i(1280,720))
	f.state.attach_equipment(f.host,f.equip,db,true,true)
	f.screen.refresh()
	await _click(f.viewport,f.screen._hand_object(f.host))
	var view = f.screen._card_info_view
	var widget = view._equip_rows.get_child(0)
	var rite = f.state.create_rite_instance(5000005)
	var host = f.state.get_card_instance(f.host)
	var original_tags: Dictionary = host.tags.duplicate(true)
	for mode in ["started", "not_owned", "not_equipment", "modal"]:
		if mode == "started":
			f.state.add_card_to_slot(f.host,1,db,rite.uid)
			rite.start = true
		elif mode == "not_owned":
			for code in ["own", "adherent", "player"]:
				var tag: String = db.tag_code_to_name.get(code,code)
				host.tags[tag] = int(host.tags.get(tag,0)) - int(f.state.effective_card_tags(f.host,db).get(tag,0))
		elif mode == "not_equipment":
			f.state.get_card_instance(f.equip).tags["装备"] = -1
		else:
			f.screen.set_world_scene_blocker("test_prompt",true,false,true,true)
		assert_false(view._can_move_equipment(f.equip),mode)
		var motion := InputEventMouseMotion.new()
		motion.position = widget.get_global_rect().get_center()
		f.viewport.push_input(motion,true)
		await wait_process_frames(1)
		assert_eq(f.viewport.gui_get_hovered_control(),widget,"gate tested on equipment hit target")
		var click := InputEventMouseButton.new()
		click.position = motion.position
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.button_mask = MOUSE_BUTTON_MASK_LEFT
		f.viewport.push_input(click,true)
		motion.position -= Vector2(0,80)
		motion.relative = Vector2(0,-80)
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		f.viewport.push_input(motion,true)
		await wait_process_frames(2)
		assert_false(f.viewport.gui_is_dragging(),mode+" prevents real drag")
		click.pressed = false
		click.position = motion.position
		click.button_mask = 0
		f.viewport.push_input(click,true)
		await wait_process_frames(2)
		assert_eq(f.state.get_card_instance(f.equip).equipped_to_uid,f.host)
		if mode == "started":
			rite.start = false
			f.state.remove_card_from_slot(f.host,1,rite.uid)
			f.state.add_card_to_hand(f.host,db)
		elif mode == "not_owned":
			host.tags = original_tags.duplicate(true)
		elif mode == "not_equipment":
			f.state.get_card_instance(f.equip).tags.erase("装备")
		else:
			f.screen.set_world_scene_blocker("test_prompt",false)

func test_drag_survives_detail_teardown_and_re_equips():
	var f = await _fixture(Vector2i(1280,720))
	f.state.attach_equipment(f.host,f.equip,db,true,true)
	f.screen.refresh()
	await _click(f.viewport,f.screen._hand_object(f.host))
	var view = f.screen._card_info_view
	var widget = view._equip_rows.get_child(0)
	var id = widget.get_instance_id()
	# Drop on the host: this must re-equip rather than duplicate or destroy it.
	await _drag(f.viewport,widget,f.screen._hand_object(f.host).get_global_rect().get_center())
	assert_eq(f.state.get_card_instance(f.equip).equipped_to_uid,f.host)
	assert_eq(view._equip_rows.get_child(0).get_instance_id(),id)
	# Real drag followed by controlled lifecycle teardown (not a mouse close).
	await _drag(f.viewport,widget,Vector2(960,695),func():
		assert_eq(f.state.get_card_instance(f.equip).zone,"drag")
		assert_false(f.state.get_card_instance(f.host).equipped_uids.has(f.equip))
		f.screen.close_card_detail())
	assert_eq(f.state.get_card_instance(f.equip).zone,"hand")
	assert_eq(f.screen._hand_object(f.equip).get_instance_id(),id)
	assert_true(widget.visible)
	assert_eq(f.state.get_card_instance(f.equip).equipped_to_uid,0)
