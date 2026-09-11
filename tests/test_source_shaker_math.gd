extends GutTest

const Math = preload("res://ui/source_shaker_math.gd")

func test_perlin_matches_original_native_samples() -> void:
	var oracle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/audit/shaker_native_oracle.json"))
	var mismatches := []
	for row in oracle.noise:
		var actual := Math.perlin(row[0], row[1])
		if actual != Math.f(row[2]):
			mismatches.append([row, actual])
	assert_eq(mismatches.size(), 0, "all 1029 outputs match native float32 values; first=" + str(mismatches.slice(0, 3)))

func test_decay_matches_original_native_steps() -> void:
	var oracle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/audit/shaker_native_oracle.json"))
	var mismatches := []
	for row in oracle.decay:
		var actual := Math.smooth_damp(row[0], row[1], row[2])
		if actual.x != Math.f(row[3]) or actual.y != Math.f(row[4]):
			mismatches.append([row, actual])
	assert_eq(mismatches.size(), 0, "all 468 steps match native float32 values; first=" + str(mismatches.slice(0, 3)))

func test_item_restart_and_world_projection_do_not_use_local_pixel_amplitude() -> void:
	var tray := preload("res://ui/cached_events_view.gd").new()
	add_child_autofree(tray)
	tray.scale = Vector2(0.5, 0.5)
	tray.refresh([5300001])
	tray.set_process(false)
	var item = tray.item_for_id(5300001)
	item.shake_trigger()
	item.set_process(false)
	assert_eq(item._shake_time, 2.0, "OnEnable copies maxSpeed into currentFreq")
	assert_eq(item._shake_velocity, 0.0)
	assert_between(item._shake_seed, -5.0, 5.0)
	item._shake_seed = 0.0
	var origin: Vector2 = item.global_position
	var step := Math.smooth_damp(2, 0, 1.0 / 60.0)
	var offset := Math.position_offset(0, 0, 40, step.x, Vector2(0.2, -0.2))
	var expected := Vector2(offset.x, -offset.y) * get_viewport().get_visible_rect().size.y / 10.0
	item.advance_shake(1.0 / 60.0, 0)
	assert_almost_eq(item.global_position.x - origin.x, expected.x, 0.0002, "world projection independent of parent scale")
	assert_almost_eq(item.global_position.y - origin.y, expected.y, 0.0002, "Unity Y flips into canvas Y")
	var current: Vector2 = item.global_position
	item.shake_trigger()
	item.set_process(false)
	assert_eq(item._origin, current, "retrigger captures current world position")
	assert_eq(item._shake_velocity, 0.0, "retrigger resets velocity")
