extends Control
## Original Sprite mesh masks atlas padding; no repainting or image synthesis.
var texture: Texture2D
var _mesh: ArrayMesh

func setup(path: String) -> void:
	texture = load(path) as Texture2D
	var mesh_path := path.trim_suffix('.png') + '.mesh.json'
	if not FileAccess.file_exists(mesh_path):
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(mesh_path))
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	for pair in data.uv:
		var uv := Vector2(float(pair[0]), 1.0 - float(pair[1]))
		uvs.append(uv)
		vertices.append(Vector3(uv.x * data.size[0], uv.y * data.size[1], 0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(data.indices)
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	queue_redraw()

func _draw() -> void:
	if texture == null:
		return
	if _mesh != null:
		draw_mesh(_mesh, texture, Transform2D(0, size / texture.get_size(), 0, Vector2.ZERO))
	else:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
