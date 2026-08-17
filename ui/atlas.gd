## Sprite-atlas loader for the original game's atlas PNG+JSON pairs
## (TexturePacker "JSON (Hash)" format). Frames are extracted on demand into
## standalone ImageTextures and cached.
## [SRC: assets/original/ui/*.json + *.png (rites.png 49 frames,
##       begin_guide, heads, tags, ...)]
class_name OriginalAtlas
extends RefCounted

const CACHE_CAPACITY := 256

var _atlas_texture: Texture2D
var _frames: Dictionary = {}
var _cache: Dictionary = {}


static func load_atlas(atlas_path: String) -> OriginalAtlas:
	if not ResourceLoader.exists(atlas_path):
		return null
	var atlas := OriginalAtlas.new()
	atlas._atlas_texture = load(atlas_path) as Texture2D
	if atlas._atlas_texture == null:
		return null
	var json_path := atlas_path.replace(".png", ".json")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(json_path)) if FileAccess.file_exists(json_path) else null
	if parsed is Dictionary:
		for frame in parsed.get("frames", []):
			if frame is Dictionary:
				atlas._frames[str(frame.get("filename", ""))] = frame
	return atlas


## Extract one frame by filename (e.g. "rite_0.png") as a standalone texture.
func frame(frame_name: String) -> Texture2D:
	if _cache.has(frame_name):
		return _cache[frame_name]
	var meta: Dictionary = _frames.get(frame_name, {})
	if meta.is_empty() or _atlas_texture == null:
		return null
	var rect: Dictionary = meta.get("frame", {})
	var image := _atlas_texture.get_image()
	var src := Rect2i(
		int(rect.get("x", 0)), int(rect.get("y", 0)),
		int(rect.get("w", 0)), int(rect.get("h", 0))
	)
	if src.size.x <= 0 or src.size.y <= 0 or src.position.x < 0 or src.position.y < 0:
		return null
	if src.position.x + src.size.x > image.get_width() or src.position.y + src.size.y > image.get_height():
		return null
	var texture := ImageTexture.create_from_image(image.get_region(src))
	if _cache.size() >= CACHE_CAPACITY:
		_cache.clear()
	_cache[frame_name] = texture
	return texture


func has_frame(frame_name: String) -> bool:
	return _frames.has(frame_name)


func frame_names() -> Array:
	return _frames.keys()
