extends GutTest

const Layout = preload("res://ui/source_hand_layout.gd")

func test_source_left_middle_right_clamps_and_sibling_order() -> void:
	# Five194-wide cards+four10 gaps: total1010, viewport600.
	var left := Layout.allocate([194, 194, 194, 194, 194], 600, 0)
	assert_eq(left.positions, [0.0, 204.0, 366.0, 386.0, 406.0])
	assert_eq(left.draw_order, [4, 3, 2, 0, 1], "right stack is repeatedly SetAsFirstSibling")
	var middle := Layout.allocate([194, 194, 194, 194, 194], 600, 0.5)
	assert_eq(middle.positions, [0.0, 20.0, 203.0, 386.0, 406.0])
	assert_eq(middle.draw_order, [4, 3, 0, 1, 2])
	var right := Layout.allocate([194, 194, 194, 194, 194], 600, 1)
	assert_eq(right.positions, [0.0, 20.0, 40.0, 202.0, 406.0])
	assert_eq(right.draw_order, [0, 1, 2, 3, 4])

func test_full_hand_centers_and_restores_range_one_without_sorting_siblings() -> void:
	var result := Layout.allocate([194, 213.4], 600, 0.2, [1, 0])
	assert_almost_eq(result.positions[0], 91.3, 0.001)
	assert_almost_eq(result.positions[1], 295.3, 0.001)
	assert_eq(result.draw_order, [1, 0])
	assert_eq(result.range, 1.0)
	assert_false(result.overflows)

func test_edge_scroll_uses_source_pivot_dead_zone_speed_and_clamp() -> void:
	# width1000, pivot520; deadzone +/-300, so top-left x220..820 is still.
	assert_eq(Layout.advance_range(0.5, 220, 1000, 2000), 0.5)
	assert_eq(Layout.advance_range(0.5, 820, 1000, 2000), 0.5)
	assert_almost_eq(Layout.advance_range(0.5, 219, 1000, 2000), 0.49, 0.00001)
	assert_almost_eq(Layout.advance_range(0.5, 821, 1000, 2000), 0.51, 0.00001)
	assert_almost_eq(Layout.advance_range(0.5, 2000, 1000, 2000), 0.54, 0.00001)
	assert_eq(Layout.advance_range(1, 1000, 1000, 2000), 1.0)
	assert_eq(Layout.advance_range(0, 0, 1000, 2000), 0.0)
