extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(300, 500)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var card := CardWidget.make({"id": 2000001, "type": "char", "rare": 4, "name": "", "resource": "cards/2000001"})
	viewport.add_child(card)
	card.position = Vector2(50, 50)
	card.set_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	var before := viewport.get_texture().get_image()
	for surface in card._metal_materials:
		surface.set_shader_parameter("normal_offset", Vector2(0.05, 0.4))
	await process_frame
	await RenderingServer.frame_post_draw
	var after := viewport.get_texture().get_image()
	var changed := 0
	var visible_pixels := 0
	var alpha_changes := 0
	for y in range(500):
		for x in range(300):
			var a := before.get_pixel(x, y)
			var b := after.get_pixel(x, y)
			if a.a > 0.01:
				visible_pixels += 1
			if absf(a.a - b.a) > 0.001:
				alpha_changes += 1
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.005:
				changed += 1
	print("METAL_GPU visible=%d changed=%d alpha_changes=%d" % [visible_pixels, changed, alpha_changes])
	viewport.queue_free()
	await process_frame
	await process_frame
	quit(0 if visible_pixels > 10000 and changed > 100 and alpha_changes == 0 else 1)
