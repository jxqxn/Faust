extends TextureRect
## [SRC: OpCardShowRender.AddOpCard0x575590; GameScene Canvas7582/
## Grid11629/Render11631: 256x512 cells, 4096x4096 target; OpCard Equip.]
## Only the isolated cell projection is ported. Shared atlas and RiftGenerator
## are still open; this is not a replacement for those missing source layers.
var render_cell: SubViewport

func setup(card: CardWidget) -> void:
	size = Vector2(256, 512)
	pivot_offset = size * 0.5
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	render_cell = SubViewport.new()
	render_cell.name = "SourceCell"
	render_cell.size = Vector2i(256, 512)
	render_cell.transparent_bg = true
	render_cell.disable_3d = true
	render_cell.gui_disable_input = true
	render_cell.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(render_cell)
	card.reparent(render_cell)
	# CardShowItem root is 194x421; its centred Icon is 194x422. The existing
	# CardWidget uses that icon extent. Full CardRender geometry is still open.
	card.position = (size - card.size) * 0.5
	texture = render_cell.get_texture()
	var broker := ShaderMaterial.new()
	broker.shader = preload("res://ui/source_opcard_broker.gdshader")
	broker.set_shader_parameter("broker_texture", preload("res://assets/original/ui/broker.png"))
	material = broker

func set_distance(value: float) -> void:
	(material as ShaderMaterial).set_shader_parameter("broker_distance", value)
