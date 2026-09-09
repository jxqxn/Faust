extends HBoxContainer

# Utils.NumberToSprites 0x3ac420; GameScene Count references number_6.
var text := "":
	set(value):
		if text == value:
			return
		text = value
		_rebuild()
var glyph_height := 50.0
var atlas_path := "res://assets/original/ui/number_6.png":
	set(value):
		if atlas_path == value:
			return
		atlas_path = value
		_atlas = null
		_rebuild()
var _atlas: OriginalAtlas

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 0)

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if _atlas == null:
		_atlas = OriginalAtlas.load_atlas(atlas_path)
	for character in text:
		var texture := _atlas.frame(character + ".png")
		if texture != null:
			var image := TextureRect.new()
			image.texture = texture
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.custom_minimum_size = texture.get_size() * glyph_height / 50.0
			image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			image.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(image)
		else:
			var label := Label.new()
			label.text = character
			label.add_theme_font_size_override("font_size", int(glyph_height))
			label.add_theme_font_override("font", load("res://assets/fonts/xiquemuye.ttf"))
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(label)
