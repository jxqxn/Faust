extends GutTest
const Screen = preload("res://ui/game_screen.gd")
var db: ConfigDB
func before_all():
	db = ConfigDB.new()
	db.load_all()
func _widget(screen, uid):
	for widget in screen._ordered_hand_cards():
		if widget.card_uid == uid:
			return widget
	return null
func _page(viewport, screen, index):
	var button = screen._bag_tabs.buttons[index]
	var motion = InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(), button, "real mouse hits bag tab")
	for down in [true, false]:
		var event = InputEventMouseButton.new()
		event.position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		viewport.push_input(event, true)
		await wait_process_frames(2)
func test_object_identity_survives_refresh_and_page_roundtrip():
	# Source contract probe for retained physical hand objects.
	# REA UpdateHandCards 0x559d90 + AddCard 0x54ad40; NOT original runtime capture.
	for size in [Vector2i(1920,1080),Vector2i(1280,720)]:
		var state = GameState.new()
		var uid = state.add_card_to_hand(2000001,db)
		var other_uid = state.add_card_to_hand(2000372,db)
		state.get_card_instance(other_uid).bag = 1
		state.get_card_instance(other_uid).tags["已拥有"] = 1
		var viewport = SubViewport.new()
		viewport.size = size
		viewport.handle_input_locally = true
		add_child_autofree(viewport)
		var screen = Screen.new()
		screen.setup(state,db,GameRNG.new(9615))
		viewport.add_child(screen)
		await wait_process_frames(3)
		var first = _widget(screen,uid)
		assert_not_null(first)
		if first == null: continue
		var first_id = first.get_instance_id()
		assert_null(_widget(screen,other_uid), "unvisited page has no current hand widget")
		screen.refresh()
		await wait_process_frames(3)
		var refresh_id = _widget(screen,uid).get_instance_id()
		assert_eq(refresh_id, first_id, "source AddCard reuses an existing object")
		var refreshed = _widget(screen,uid)
		await _page(viewport,screen,1)
		assert_eq(state.current_bag_index,1)
		assert_not_null(_widget(screen,other_uid))
		var retained = is_instance_valid(refreshed)
		assert_true(retained,"source UpdateHandCards moves off-page controller to hide, not destruction")
		await _page(viewport,screen,0)
		assert_eq(state.current_bag_index,0)
		var returned_id = _widget(screen,uid).get_instance_id()
		assert_eq(returned_id,refresh_id,"source returning page reuses the same object")
		print("LIFETIME_DIAGNOSTIC ",JSON.stringify({"width":size.x,"first":first_id,"refresh":refresh_id,"off_page_alive":retained,"returned":returned_id}))
		viewport.queue_free()
		await wait_process_frames(3)

func test_retained_data_update_removal_and_disk_reconstruction():
	var state = GameState.new()
	var uid = state.add_card_to_hand(2000029,db)
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	add_child_autofree(viewport)
	var screen = Screen.new()
	screen.setup(state,db,GameRNG.new(9615))
	viewport.add_child(screen)
	await wait_process_frames(3)
	var widget = _widget(screen,uid)
	var original_id = widget.get_instance_id()
	state.get_card_instance(uid).count = 7
	screen.refresh()
	await wait_process_frames(2)
	assert_eq(_widget(screen,uid).get_instance_id(),original_id)
	assert_eq(int(widget._card.count),7,"reused root refreshes changed card data")
	assert_eq(widget.clicked.get_connections().size(),1,"refresh does not duplicate click subscriptions")
	await _page(viewport,screen,1)
	assert_eq(widget.get_parent(),screen._hidden_hand_objects)
	assert_false(widget.is_visible_in_tree())
	assert_true(widget.can_process(),"source Hide GO171 stays active off-screen")
	var old_path = SaveSystem.save_path_override
	var save_path = "user://object-lifetime-%d.json" % Time.get_ticks_usec()
	SaveSystem.use_save_path(save_path)
	assert_true(SaveSystem.save(state))
	SaveSystem.use_save_path(old_path)
	screen.queue_free()
	await wait_process_frames(2)
	var restored = GameState.new()
	SaveSystem.deserialize(JSON.parse_string(FileAccess.get_file_as_string(save_path)),restored,db)
	DirAccess.remove_absolute(save_path)
	screen = Screen.new()
	screen.setup(restored,db,GameRNG.new(9615))
	viewport.add_child(screen)
	await wait_process_frames(3)
	assert_eq(restored.current_bag_index,1)
	assert_null(screen._hand_object(uid),"scene-local hidden objects are not resurrected from saved instance IDs")
	await _page(viewport,screen,0)
	var rebuilt = _widget(screen,uid)
	assert_not_null(rebuilt)
	assert_eq(int(rebuilt._card.count),7)
	assert_ne(rebuilt.get_instance_id(),original_id)
	restored.remove_card_instance_from_play(uid)
	screen.refresh()
	await wait_process_frames(2)
	assert_null(screen._hand_object(uid))
	assert_false(is_instance_valid(rebuilt),"removed card releases retained widget")
	viewport.queue_free()
	await wait_process_frames(2)

func test_stale_release_cannot_clear_replacement():
	var screen = Screen.new()
	var old = CardWidget.new()
	var replacement = CardWidget.new()
	screen.add_child(old)
	screen.add_child(replacement)
	screen._hand_objects[17] = replacement
	screen._release_hand_object(17,old)
	assert_eq(screen._hand_object(17),replacement,"OnDestroy identity guard preserves replacement")
	screen.free()
