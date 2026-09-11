extends GutTest

const Layout = preload("res://ui/source_hand_layout.gd")

func test_insertion_uses_half_width_plus_space_and_boundary_moves_right() -> void:
	# One194 card in600: start203, half(width+10)=102, boundary305.
	assert_eq(Layout.preview([194], 600, 0, Vector2(304.9, 0), [false], false, Vector2.ZERO).index, 0)
	assert_eq(Layout.preview([194], 600, 0, Vector2(305, 0), [false], false, Vector2.ZERO).index, 1)
	# Overflow uses natural origin plus range offset, not compressed painter positions.
	assert_eq(Layout.preview([194, 194, 194, 194, 194], 600, 1, Vector2(100, 0), [], false, Vector2.ZERO).index, 3)

func test_compatible_target_suppresses_gap_and_tracks_source_sticky_anchor() -> void:
	var result := Layout.preview([194], 600, 0, Vector2(250, 60), [true], false, Vector2.ZERO)
	assert_eq(result.index, -1)
	assert_true(result.sticky)
	assert_eq(result.start, Vector2(203, 60))
	assert_eq(Layout.preview([194], 600, 0, Vector2(202, 60), [true], false, Vector2.ZERO).index, 0,
		"compatible card does not absorb pointer before its left edge")

func test_sticky_release_is_inclusive_and_gap_waits_until_following_update() -> void:
	var anchor := Vector2(203, 60)
	var held := Layout.preview([194], 600, 0, Vector2(-37, 160), [false], true, anchor)
	assert_true(held.sticky, "x240/y100 boundaries remain inside sticky region")
	assert_eq(held.index, -1)
	var released := Layout.preview([194], 600, 0, Vector2(-37.1, 160), [false], true, anchor)
	assert_false(released.sticky)
	assert_eq(released.index, -1, "release frame only clears IsSticky")
	assert_eq(Layout.preview([194], 600, 0, Vector2(-37.1, 160), [false], false, anchor).index, 0)
	assert_false(Layout.preview([194], 600, 0, Vector2(180, 160.1), [false], true, anchor).sticky)

func test_insertion_gap_does_not_become_an_extra_clamped_child() -> void:
	# Native shifts ItemInfo.pos and total width, retaining original child count.
	var result := Layout.allocate([194, 194, 194, 194, 194], 600, 1, [], 1, 194)
	assert_eq(result.positions, [0.0, 20.0, 40.0, 202.0, 406.0],
		"gap inside the compressed left stack does not invent an extra20 notch")
	assert_eq(result.draw_order, [0, 1, 2, 3, 4])
	var full := Layout.allocate([194, 194], 1000, 0, [], 1, 194)
	assert_eq(full.positions, [199.0, 607.0], "full row centers after the gap adds194+10")

func test_screen_preview_ignores_painter_order_and_old_gap_and_absorbs_equipment() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var rng := GameRNG.new(8901)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	state.hand.clear()
	state.rail_order.clear()
	state.active_sudan_cards.clear()
	state.event_prompts.clear()
	state.begin_guide = {}
	var host := state.add_card_to_hand(2001193, db)
	state.add_card_to_hand(2000001, db)
	var equipment := state.add_card_to_hand(2000246, db)
	for uid in [host, equipment]:
		state.get_card_instance(uid).tags["own"] = 1
	var screen := preload("res://ui/game_screen.gd").new()
	screen.size = Vector2(3840, 2160)
	screen.setup(state, db, rng)
	add_child_autofree(screen)
	await wait_process_frames(3)
	var cards: Array = screen._ordered_hand_cards()
	var held: CardWidget = cards.back()
	var data := held.drag_payload()
	held._hide_source_for_drag()
	var rail: Control = screen.get("_card_items")
	var natural_start := (rail.size.x - 398.0) * 0.5
	var point := Vector2(natural_start + 40, 200)
	var rail_point: Vector2 = screen.get("_card_rail_view").get_global_transform().affine_inverse() * (rail.get_global_transform() * point)
	screen._preview_hand_drop(data, rail_point)
	assert_true(screen.get("_hand_sticky"), "source equipment-compatible target sets sticky")
	assert_eq(screen.get("_hand_drop_preview_index"), -1, "equipment hover does not push character aside")
	assert_eq(state.rail_order[0], host)
	assert_eq(data.card_uid, equipment)
	screen.set("_hand_sticky", false)
	screen.set("_hand_drop_preview_index", 1)
	var host_widget: CardWidget = cards[0]
	assert_true(host_widget._can_drop_data(Vector2(40, 200), data))
	assert_true(screen.get("_hand_sticky"), "direct card acceptance still updates parent sticky state")
	assert_eq(screen.get("_hand_drop_preview_index"), -1, "prior gap closes on actual equipment target")
	var before: int = screen._hand_preview_index_at(rail_point, equipment)
	rail.move_child(cards[1], 0)
	screen.set("_hand_drop_preview_index", 1)
	assert_eq(screen._hand_preview_index_at(rail_point, equipment), before,
		"previous gap and painter reordering do not move source insertion boundary")
