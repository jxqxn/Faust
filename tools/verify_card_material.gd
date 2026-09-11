extends SceneTree

# GPU contract: with lighting disabled, a card surface must preserve authored
# colour and modulation just like a plain TextureRect. Compare both in the
# same viewport, so this also catches renderer-specific colour-space mistakes.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(160, 32)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var samples := [Color(0.2, 0.4, 0.7), Color(0.6, 0.3, 0.1), Color(0.8, 0.8, 0.8), Color(0.5, 0.5, 0.5, 0.5)]
	for i in samples.size():
		var pixels := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		pixels.fill(samples[i])
		var texture := ImageTexture.create_from_image(pixels)
		for row in 2:
			var rect := TextureRect.new()
			rect.texture = texture
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.size = Vector2(32, 16)
			rect.position = Vector2(i * 40, row * 16)
			rect.modulate = Color(0.8, 0.9, 0.7, 0.6)
			if row == 1:
				var material := ShaderMaterial.new()
				material.shader = load("res://ui/card_metal.gdshader")
				material.set_shader_parameter("sample_only", true)
				rect.material = material
			viewport.add_child(rect)
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image()
	var failed := false
	for i in samples.size():
		var plain := result.get_pixel(i * 40 + 8, 8)
		var shaded := result.get_pixel(i * 40 + 8, 24)
		var error := Vector4(plain.r - shaded.r, plain.g - shaded.g, plain.b - shaded.b, plain.a - shaded.a).length()
		print("CARD_MATERIAL sample=", i, " plain=", plain, " shaded=", shaded, " error=", error)
		failed = failed or error > 0.015
	print("CARD_MATERIAL: ", "FAIL" if failed else "PASS")
	viewport.free()
	quit(1 if failed else 0)
