extends GutTest

func make_card() -> CardWidget:
	var card := CardWidget.make({"id": 2000001, "name": "阿尔图", "type": "char", "rare": 3})
	add_child_autofree(card)
	card.set_hand_pose(Vector2(300, 600), 0, 0)
	return card

func test_root_growth_keeps_bottom_and_fixed_face_centered() -> void:
	# CardMoveUp root+100; SetChild scaled half-height; CardShow fixed center.
	var card := make_card()
	var bottom := card.get_global_rect().end.y
	for i in range(4):
		card.set_selected(true)
		assert_eq(card.size, Vector2(194, 522))
		assert_eq(card.get_global_rect().end.y, bottom)
		var face := card.get_node("CardVisualFace") as Control
		assert_eq(face.size, Vector2(194, 422))
		assert_eq(face.position, Vector2(0, 50))
		card.set_card({"id": 2000001, "name": "更新", "type": "char", "rare": 3})
		assert_eq(card.get_global_rect().end.y, bottom, "content refresh cannot accumulate displacement")
		card._set_hovered(false)
		assert_eq(card.size.y, 522.0, "active selection prevents pointer-exit reset")
		card.set_selected(false)
		assert_eq(card.position, Vector2(300, 600))
		assert_eq(card.size, Vector2(194, 422))
	# Rebuild detaches old faces and queue_free releases them on the next frame.
	await wait_process_frames(2)

func test_scaled_candidate_root_is_the_hit_and_render_transform() -> void:
	var card := make_card()
	card.set_candidate_highlight(true)
	# Caller layout positions the unraised root with the authored scale.
	card.set_hand_pose(Vector2(309.7, 578.9), 0, 0)
	card.set_selected(true)
	assert_almost_eq(card.get_global_rect().position.x, 300.0, 0.001)
	assert_almost_eq(card.get_global_rect().end.y, 1022.0, 0.001)
	assert_almost_eq(card.get_global_rect().size.x, 213.4, 0.001)
	assert_almost_eq(card.get_global_rect().size.y, 574.2, 0.001)
	assert_eq(card.offset_transform_position, Vector2.ZERO, "no visual-only second displacement")
	assert_eq(card.offset_transform_scale, Vector2.ONE, "no visual-only second scale")

func test_slot_root_does_not_grow_or_overwrite_host_scale() -> void:
	var card := make_card()
	card.drag_source = "slot"
	card.scale = Vector2(0.5, 0.5)
	card.set_selected(true)
	assert_eq(card.size, Vector2(194, 422))
	assert_eq(card.position, Vector2(300, 600))
	assert_eq(card.scale, Vector2(0.5, 0.5))

func test_pointer_entry_respects_flash_flag_not_residual_fade() -> void:
	# OnPointerEnter 0x52ae70 checks flash@0x38; Update 0x52e330 clears at peak.
	var card := make_card()
	card.reset_card_flash(true)
	card._set_hovered(true)
	assert_eq(card.size.y, 422.0, "rising flash suppresses entry lift")
	card._advance_card_flash(1.0 / 3.0)
	card._apply_rest_pose()
	assert_eq(card.size.y, 422.0, "flash completion does not synthesize another pointer enter")
	card._set_hovered(false)
	card._set_hovered(true)
	assert_eq(card.size.y, 522.0, "falling residual fade does not suppress a fresh entry")

func test_drag_grab_clamps_to_active_descendant_bounds_after_scale_normalization() -> void:
	var card := make_card()
	card._set_hovered(true)
	# CardNew Flash remains active even at zero shader alpha:256x512.
	# Root194x522 covers its height; active flash extends x to[-31,225].
	assert_eq(card.normalized_drag_grab_offset(Vector2(-1000, -1000)), Vector2(-31, -50))
	assert_eq(card.normalized_drag_grab_offset(Vector2(1000, 1000)), Vector2(225, 472))
	card.set_candidate_highlight(true)
	assert_almost_eq(card.normalized_drag_grab_offset(Vector2(97, 0)).y, -50.0, 0.001,
		"candidate top press is clamped after normalizing1.1 scale")
	card.set_selected(true)
	assert_eq(card.normalized_drag_grab_offset(Vector2(-1000, -1000)), Vector2(-31, -73.5),
		"active Outline expands the union; a hidden outline did not")
