extends RefCounted

## Keep immutable imported textures across card/page/modal destruction. Godot's
## ResourceLoader cache alone does not retain resources after the final owner dies.
## This is a host memory budget, not an original-game visual parameter.
const BUDGET_BYTES := 128 * 1024 * 1024
static var _textures: Dictionary = {}
static var _bytes := 0

static func _retain(path: String, texture: Texture2D) -> void:
	var cost := texture.get_width() * texture.get_height() * 6
	if cost > BUDGET_BYTES:
		return
	while _bytes + cost > BUDGET_BYTES and not _textures.is_empty():
		var oldest: String = _textures.keys()[0]
		var released: Texture2D = _textures[oldest]
		_bytes -= released.get_width() * released.get_height() * 6
		_textures.erase(oldest)
	_textures[path] = texture
	_bytes += cost

static func load_texture(path: String) -> Texture2D:
	if _textures.has(path):
		var retained: Texture2D = _textures[path]
		_textures.erase(path)
		_textures[path] = retained
		return retained
	var texture := load(path) as Texture2D
	if texture == null:
		return null
	# Conservative RGBA + mip estimate, without a GPU readback.
	var cost := texture.get_width() * texture.get_height() * 6
	if cost > BUDGET_BYTES:
		return texture
	_retain(path, texture)
	return texture

static func clear_cache() -> void:
	_textures.clear()
	_bytes = 0
