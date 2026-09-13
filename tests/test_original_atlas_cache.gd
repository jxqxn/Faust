extends GutTest

func after_each() -> void:
	OriginalAtlas.clear_cache()
	preload("res://ui/source_texture_cache.gd").clear_cache()


func test_texture_cache_retains_original_resources_without_owning_controls() -> void:
	var cache = preload("res://ui/source_texture_cache.gd")
	var path := "res://assets/original/ui/card_outline.png"
	var original := load(path) as Texture2D
	var cached := cache.load_texture(path)
	assert_same(cached, original, "reuse the exact imported resource, no pixel conversion")
	assert_same(cache.load_texture(path), cached)
	assert_lte(cache._bytes, cache.BUDGET_BYTES)
	cache.clear_cache()
	assert_eq(cache._bytes, 0)
	assert_same(cache.load_texture(path), original, "clearing cache must not invalidate a live view")


func test_shared_frames_keep_source_pixels_and_survive_cache_release() -> void:
	for path in ["res://assets/original/ui/rites.png", "res://assets/original/ui/countdown_pics.png"]:
		var atlas := OriginalAtlas.load_atlas(path)
		assert_not_null(atlas)
		var source := (load(path) as Texture2D).get_image()
		for frame_name in atlas.frame_names():
			var frame := atlas.frame(str(frame_name))
			assert_not_null(frame)
			var rect: Dictionary = atlas._frames[frame_name].frame
			var start := Vector2(float(rect.x), float(rect.y)) * atlas._frame_scale
			var ending := Vector2(float(rect.x + rect.w), float(rect.y + rect.h)) * atlas._frame_scale
			var region := Rect2i(Vector2i(start.round()), Vector2i(ending.round() - start.round()))
			assert_true(frame.get_image().get_data() == source.get_region(region).get_data(), str(frame_name))
		var name: String = atlas.frame_names()[0]
		var retained := atlas.frame(name)
		assert_same(OriginalAtlas.load_atlas(path).frame(name), retained)
		OriginalAtlas.clear_cache()
		var reloaded := OriginalAtlas.load_atlas(path).frame(name)
		assert_true(reloaded.get_image().get_data() == retained.get_image().get_data(), "live controls survive cache release")
