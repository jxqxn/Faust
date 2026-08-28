## Source-shaped `OverNewStep2Controller` presentation.
##
## [SRC: OverNewStep2Controller.<Init>d__5::MoveNext 0x587ee0]
## Name <- OverNode.name, FullCG <- OverNode.bg, CGMask <- OverNode.bg +
## "_mask". `UpdateMaskCanvasGroup` starts a five-second linear fade.
## [SRC: dump.cs OverNewStep2Controller fields; Resources/prefab/Over.prefab]
class_name OverNewStep2ControllerView
extends Control

const DESIGN_SPACE := Vector2(3840, 2160)

var full_cg: TextureRect
var cg_mask: TextureRect
var name_label: Label
var npc_head_container: HBoxContainer
var mask_group: Control
var _mask_group_tween: Tween


func setup(over_node: Dictionary, _over_data: Dictionary = {}) -> void:
	name = "Step2"
	position = Vector2.ZERO
	size = DESIGN_SPACE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	full_cg = TextureRect.new()
	full_cg.name = "CG"
	full_cg.position = Vector2.ZERO
	full_cg.size = DESIGN_SPACE
	full_cg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	full_cg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	full_cg.texture = _ending_texture(over_node, "bg")
	add_child(full_cg)

	mask_group = Control.new()
	mask_group.name = "Mask"
	mask_group.position = Vector2.ZERO
	mask_group.size = DESIGN_SPACE
	mask_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask_group.visible = false
	add_child(mask_group)

	cg_mask = TextureRect.new()
	cg_mask.name = "CGMask"
	cg_mask.position = Vector2.ZERO
	cg_mask.size = DESIGN_SPACE
	cg_mask.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cg_mask.stretch_mode = TextureRect.STRETCH_SCALE
	cg_mask.texture = _ending_texture(over_node, "bg", "_mask")
	cg_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask_group.add_child(cg_mask)

	_build_over_title(str(over_node.get("name", "")))


func set_animation_mask_alpha(value: float) -> void:
	if cg_mask != null and is_instance_valid(cg_mask):
		# `show_story.anim` drives Image.m_Color.a independently of the
		# controller's CanvasGroup alpha.
		cg_mask.self_modulate.a = smoothstep(0.0, 1.0, value)


func update_mask_canvas_group() -> void:
	# [SRC: OverNewStep2Controller.UpdateMaskCanvasGroup 0x57a820,
	# Update 0x57a8b0, .ctor 0x57a960] alpha=0 then elapsed/duration, where
	# fadeDuration is authored as 5 in Over.prefab.
	if mask_group == null:
		return
	mask_group.modulate.a = 0.0
	if _mask_group_tween != null:
		_mask_group_tween.kill()
	_mask_group_tween = create_tween()
	_mask_group_tween.tween_property(mask_group, "modulate:a", 1.0, 5.0)


func _build_over_title(title_text: String) -> void:
	# Unity bottom-left authored coordinates folded into the 3840x2160 design
	# canvas. See docs/ui_layout/Over.md, `Over/Step2/Over Title` rows.
	var over_title := Control.new()
	over_title.name = "Over Title"
	over_title.position = Vector2(100, 1960)
	over_title.size = Vector2(100, 100)
	add_child(over_title)

	var bg := Control.new()
	bg.name = "BG"
	bg.position = Vector2(50, 0)
	bg.size = Vector2(4000, 100)
	over_title.add_child(bg)

	var board := TextureRect.new()
	board.name = "BG"
	board.position = Vector2(0, 10)
	board.size = Vector2(800, 80)
	board.texture = load("res://assets/original/ui/after_story_title_board.png") as Texture2D
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_SCALE
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(board)

	var border := TextureRect.new()
	border.name = "Border"
	border.position = Vector2(8, 10)
	border.size = Vector2(13, 80)
	border.texture = load("res://assets/original/ui/after_story_title_bg.png") as Texture2D
	border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	border.stretch_mode = TextureRect.STRETCH_SCALE
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(border)

	var title_row := HBoxContainer.new()
	title_row.name = "Title"
	title_row.position = Vector2(20, 0)
	title_row.size = Vector2(3960, 100)
	title_row.add_theme_constant_override("separation", 30)
	bg.add_child(title_row)

	name_label = Label.new()
	name_label.name = "Title"
	name_label.text = title_text
	name_label.custom_minimum_size = Vector2(0, 80)
	name_label.add_theme_font_size_override("font_size", 50)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.8126906, 0.0))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(name_label)

	npc_head_container = HBoxContainer.new()
	npc_head_container.name = "Content"
	npc_head_container.custom_minimum_size = Vector2(30, 100)
	npc_head_container.add_theme_constant_override("separation", 10)
	title_row.add_child(npc_head_container)


func _ending_texture(over_node: Dictionary, key: String, suffix := "") -> Texture2D:
	var relative := str(over_node.get(key, ""))
	if relative.is_empty():
		return null
	var path := "res://assets/original/ui/%s%s.png" % [relative, suffix]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
