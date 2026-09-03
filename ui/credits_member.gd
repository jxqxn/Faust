## One authored developer portrait. Hover/select fades the portrait to reveal
## the config-backed name and job, matching CreditsMember's alpha toggle.
## [SRC: CreditsMember.c @ OnEnable/OnPointerEnter/OnDeselect/ShowImage
##       (RVA 0x3f7810/0x3f7850/0x3f77d0/0x3f7890);
##       Resources/prefab/CreditsMember.prefab]
class_name CreditsMemberView
extends Control

const SOURCE_ART := "res://assets/original/ui/"

var _face: TextureRect


func setup(member_key: String, member: Dictionary, face_name: String, authored_pos: Vector2,
		authored_scale: Vector2, authored_rotation: float) -> void:
	name = member_key
	size = Vector2(272, 356)
	position = Vector2(1920 + authored_pos.x - 136, 1080 - authored_pos.y - 178)
	pivot_offset = size * 0.5
	scale = authored_scale
	rotation_degrees = -authored_rotation
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(_texture("bg", Rect2(0, 0, 272, 356), "member_bg.png"))
	var desc := Label.new()
	desc.name = "desc"
	desc.position = Vector2(30, 60)
	desc.size = Vector2(212, 236)
	desc.text = "%s\n\n%s" % [str(member.get("name", member_key)), str(member.get("job", ""))]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 40)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desc)
	_face = _texture("face", Rect2(2, 0, 268, 356), "%s.png" % face_name)
	add_child(_face)
	add_child(_texture("border", Rect2(-3, -3, 278, 362), "member_border.png"))
	mouse_entered.connect(func(): _face.modulate.a = 0.0)
	mouse_exited.connect(func(): _face.modulate.a = 1.0)


func _texture(node_name: String, rect: Rect2, texture_name: String) -> TextureRect:
	var view := TextureRect.new()
	view.name = node_name
	view.position = rect.position
	view.size = rect.size
	var path := SOURCE_ART + texture_name
	view.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view
