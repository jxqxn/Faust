extends SceneTree

# Original fragment60 instruction fixtures. Run card_metal_asm_reference.py first.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := "res://.godot/card_metal_reference/"
	var cases = JSON.parse_string(FileAccess.get_file_as_string(path + "cases.json"))
	if not cases is Array:
		push_error("Generate original ASM reference fixtures first")
		quit(1)
		return
	var input := ImageTexture.create_from_image(Image.load_from_file(path + "albedo.png"))
	var errors := []
	var results := []
	for entry in cases:
		var extent := 32
		var viewport := SubViewport.new()
		viewport.size = Vector2i(extent, extent)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var background := ColorRect.new()
		background.color = Color.BLACK
		background.size = Vector2(extent, extent)
		viewport.add_child(background)
		var sprite := TextureRect.new()
		sprite.texture = input
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.size = Vector2(extent, extent)
		sprite.modulate = Color(0.8, 0.9, 0.7, 1.0)
		var material := ShaderMaterial.new()
		material.shader = load("res://ui/card_metal.gdshader")
		material.set_shader_parameter("has_detail", true)
		for binding in {"normal_map":"normal", "metal_map":"metal", "detail_map":"detail", "emission_map":"emission"}:
			var names := {"normal_map":"normal", "metal_map":"metal", "detail_map":"detail", "emission_map":"emission"}
			material.set_shader_parameter(binding, ImageTexture.create_from_image(Image.load_from_file(path + names[binding] + ".png")))
		for binding in {"light_color":"light", "ambient_diffuse":"ambient", "emission_color":"emission"}:
			var names := {"light_color":"light", "ambient_diffuse":"ambient", "emission_color":"emission"}
			var value: Array = entry[names[binding]]
			material.set_shader_parameter(binding, Vector3(value[0], value[1], value[2]))
		sprite.material = material
		viewport.add_child(sprite)
		await process_frame
		await RenderingServer.frame_post_draw
		var actual := viewport.get_texture().get_image()
		actual.save_png(path + str(entry.name) + "_actual.png")
		var expected := Image.load_from_file(path + "expected_" + str(entry.name) + ".png")
		var max_error := 0.0
		for y in extent:
			for x in extent:
				var a := actual.get_pixel(x, y)
				var b := expected.get_pixel(x, y)
				max_error = maxf(max_error, maxf(absf(a.r-b.r), maxf(absf(a.g-b.g), absf(a.b-b.b))))
		results.append({"case":entry.name, "max_channel_error":max_error})
		if max_error > 2.0 / 255.0:
			errors.append(results.back())
		viewport.free()
	var report := FileAccess.open("res://docs/ui_layout/shader_evidence/metal_gpu_results.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"cases":results, "failures":errors}, "\t"))
	report.close()
	print("METAL_ASM_GPU: ", "PASS" if errors.is_empty() else "FAIL", " ", JSON.stringify(results))
	quit(0 if errors.is_empty() else 1)
