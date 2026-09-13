extends GutTest

func test_night_and_day_masks_join_without_a_hard_overlap_band() -> void:
	if DisplayServer.get_name() == "headless":
		pending("Requires the GPU renderer; run with gl_compatibility")
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(viewport)
	var bg := ColorRect.new()
	bg.size = Vector2(viewport.size)
	bg.color = Color.WHITE
	viewport.add_child(bg)
	var overlay = preload("res://ui/next_day_transition.gd").new()
	viewport.add_child(overlay)
	var clock := NextDayClock.create()
	var maximum_jump := 0.0
	for daytime in [false,true]:
		clock["continue"] = daytime
		for step in range(9):
			var t := float(step) * 0.5
			clock.night_time = 4.0 if daytime else t
			clock.day_time = t if daytime else 0.0
			clock.time = t
			overlay.present({"animation":clock},Vector2(viewport.size))
			overlay.clock_root.hide()
			await wait_process_frames(2)
			await RenderingServer.frame_post_draw
			var frame := viewport.get_texture().get_image()
			var worst_jump := 0.0
			for y in [100,300,540,780,980]:
				for x in range(1,1919):
					worst_jump = maxf(worst_jump,absf(frame.get_pixel(x,y).r-frame.get_pixel(x-1,y).r))
			maximum_jump = maxf(maximum_jump,worst_jump)
			# Raster discontinuity tolerance, not an authored opacity parameter.
			# The old pivot sign produced a >22% one-pixel jump on a white background.
			assert_lt(worst_jump,0.05,"no hard band: day=%s time=%.1f" % [daytime,t])
	print("MASK_CONTINUITY maximum_single_pixel_red_jump=",maximum_jump)
