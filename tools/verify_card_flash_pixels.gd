extends SceneTree

# Reference images come from executing original blob118 ASM, independently
# of card_flash.gdshader. Run card_flash_asm_reference.py first.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := "res://.godot/card_flash_reference/"
	var cases = JSON.parse_string(FileAccess.get_file_as_string(path + "cases.json"))
	if not cases is Array:
		push_error("Generate original ASM reference fixtures first")
		quit(1)
		return
	var input := ImageTexture.create_from_image(Image.load_from_file(path + "input.png"))
	var errors := []
	var results := []
	for entry in cases:
		var extent := int(entry.size)
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
		sprite.modulate = Color(0.8, 0.9, 0.7, 0.6)
		var material := ShaderMaterial.new()
		material.shader = load("res://ui/card_flash.gdshader")
		material.set_shader_parameter("outline_fade", float(entry.fade))
		sprite.material = material
		viewport.add_child(sprite)
		await process_frame
		await RenderingServer.frame_post_draw
		var actual := viewport.get_texture().get_image()
		var expected := Image.load_from_file(path + str(entry.expected))
		var max_error := 0.0
		for y in extent:
			for x in extent:
				var a := actual.get_pixel(x, y)
				var b := expected.get_pixel(x, y)
				max_error = maxf(max_error, maxf(absf(a.r-b.r), maxf(absf(a.g-b.g), absf(a.b-b.b))))
		results.append({"size":extent, "fade":entry.fade, "max_channel_error":max_error})
		if max_error > 2.0 / 255.0:
			errors.append(results.back())
		viewport.free()
	var report := FileAccess.open("res://docs/ui_layout/shader_evidence/flash_gpu_results.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"cases":results, "failures":errors}, "\t"))
	report.close()
	print("FLASH_ASM_GPU: ", "PASS" if errors.is_empty() else "FAIL", " ", JSON.stringify(results))
	quit(0 if errors.is_empty() else 1)
