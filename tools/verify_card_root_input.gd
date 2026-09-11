extends "res://tools/verify_card_equipment_input.gd"

func _run() -> void:
	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	root.add_child(stage)
	var card := CardWidget.make({"id": 2000001, "instance_uid": 1, "name": "阿尔图", "type": "char", "rare": 3})
	stage.add_child(card)
	card.set_hand_pose(Vector2(1000, 1400), 0, 0)
	await process_frame
	var transform := stage.get_global_transform_with_canvas()
	await pointer(transform * Vector2(1097, 1500))
	check(card.size == Vector2(194, 522), "hover grows the real root")
	await pointer(transform * Vector2(1097, 1325))
	check(root.gui_get_hovered_control() == card, "new upper root band remains mouse reachable")
	check(card.size.y == 522, "moving into enlarged area does not reset hover")
	card.set_candidate_highlight(true)
	await pointer(transform * Vector2(999, 1400))
	check(root.gui_get_hovered_control() == card, "candidate scale enlarges actual horizontal hit area")
	card.reset_candidate_scale()
	for candidate in [false, true]:
		card.set_candidate_highlight(candidate)
		card.reset_card_flash(false)
		var start := transform * Vector2(1097, 1450)
		await pointer(start)
		var face := card.get_node("CardVisualFace") as Control
		var center_before := face.get_global_transform_with_canvas() * (face.size * 0.5)
		await button(start, true)
		var movement := Vector2(60, -60)
		await pointer(start + movement, true)
		await process_frame
		check(root.gui_is_dragging(), "enlarged root starts a GUI drag")
		var preview := root.find_child("CardDragPreview", true, false)
		check(preview != null, "drag preview exists")
		if preview != null:
			var preview_face := preview.find_child("CardVisualFace", true, false) as Control
			var center_after := preview_face.get_global_transform_with_canvas() * (preview_face.size * 0.5)
			# Physical window pixels round requested design-space coordinates.
			var actual_movement := root.get_mouse_position() - start
			print("ROOT_DRAG_TRACE before=", center_before, " after=", center_after, " actual_delta=", actual_movement, " grab=", card.get("_drag_grab_offset"))
			var pixel_units := root.get_visible_rect().size / Vector2(DisplayServer.window_get_size())
			var error := (center_after - center_before - movement).abs()
			check(error.x < pixel_units.x and error.y < pixel_units.y,
				"drag center differs by less than one physical cursor pixel; no second lift")
		await button(start + movement, false)
		await process_frame
		await pointer(transform * Vector2(500, 500))
		check(card.visible, "failed drop restores source")
		check(card.size == Vector2(194, 422), "pointer exit restores original root")
		check(card.position.is_equal_approx(Vector2(1000, 1400)), "failed drag does not accumulate root displacement")
	stage.queue_free()
	await process_frame
	print("CARD_ROOT_INPUT: ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
