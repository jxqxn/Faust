## GPU isolation diagnostic; never attached to the playable scene.
extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var output := "res://docs/audit/next_day_runtime/mask_isolation"
	DirAccess.make_dir_recursive_absolute(output)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var bg := ColorRect.new()
	bg.size = Vector2(viewport.size)
	bg.color = Color.WHITE
	viewport.add_child(bg)
	var overlay = load("res://ui/next_day_transition.gd").new()
	viewport.add_child(overlay)
	var clock := NextDayClock.create()
	clock.night_time = 4.0
	clock.time = 4.0
	overlay.present({"animation":clock}, Vector2(viewport.size))
	overlay.clock_root.hide()
	var findings := {"phase":"night_enter", "time":4, "emitters":[], "captures":{}}
	for emitter in overlay.mask_root.get_children():
		var quad: TextureRect = emitter.get_child(0).get_child(0)
		var corners := []
		for point in [Vector2.ZERO, Vector2(60,0), Vector2(60,60), Vector2(0,60)]:
			var screen_point: Vector2 = quad.get_global_transform() * point
			corners.append([screen_point.x,screen_point.y])
		findings.emitters.append({"quad_count":emitter.get_child_count(), "corners":corners})
	for mode in ["both", "parent_only", "child_only"]:
		overlay.mask_root.get_child(0).visible = mode != "child_only"
		overlay.mask_root.get_child(1).visible = mode != "parent_only"
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var rendered := viewport.get_texture().get_image()
		var error := rendered.save_png(output.path_join(mode + ".png"))
		if error != OK:
			printerr("Failed to capture mask isolation")
			quit(1)
			return
		var jumps := []
		# Scan an unoccluded horizontal row of the GPU-rendered mask.
		for x in range(1,1919):
			var left := rendered.get_pixel(x-1,540).r
			var right := rendered.get_pixel(x,540).r
			if absf(right-left) > 0.05:
				jumps.append({"x":x,"y":540,"left_red":left,"right_red":right})
		findings.captures[mode] = {"single_pixel_jumps_over_5_percent":jumps}
	var file := FileAccess.open(output.path_join("measurements.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(findings,"\t"))
	file.close()
	print("MASK_ISOLATION " + JSON.stringify(findings.captures))
	viewport.queue_free()
	await process_frame
	await process_frame
	quit(0)
