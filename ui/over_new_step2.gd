## Source-shaped `OverNewStep2Controller` presentation.
##
## [SRC: OverNewStep2Controller.<Init>d__5::MoveNext 0x587ee0]
## Name <- OverNode.name, FullCG <- OverNode.bg, CGMask <- OverNode.bg +
## "_mask". `UpdateMaskCanvasGroup` starts a five-second linear fade.
## [SRC: dump.cs OverNewStep2Controller fields; Resources/prefab/Over.prefab]
class_name OverNewStep2ControllerView
extends Control

const DESIGN_SPACE := Vector2(3840, 2160)
const OriginalAtlasScript = preload("res://ui/atlas.gd")

var full_cg: TextureRect
var cg_mask: TextureRect
var name_label: Label
var npc_head_container: HBoxContainer
var mask_group: Control
var _mask_group_tween: Tween
var _heads_atlas


func setup(over_node: Dictionary, over_data: Dictionary = {}, state = null, db = null) -> void:
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
	_build_npc_heads(_source_head_cards(over_data, state, db), db)


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


func _source_head_cards(over_data: Dictionary, state, db) -> Array:
	# [SRC: OverNewStep2Controller.<Init>d__5::MoveNext 0x587ee0]
	# A historical record without player_data copies char_cards verbatim. Live
	# playback (or a record with Player) filters player.cards through
	# <Init>b__5_0: type==char && HasTag(adherent) && !HasTag(lost).
	if not over_data.is_empty() and over_data.get("player_data") == null:
		var record_cards = over_data.get("char_cards", [])
		return record_cards.duplicate(true) if record_cards is Array else []
	var result: Array = []
	if state == null or db == null:
		return result
	var uids: Array = state.card_instances.keys()
	uids.sort()
	for uid in uids:
		var instance = state.card_instances[uid]
		if instance == null or instance.is_lost:
			continue
		var definition: Dictionary = db.get_card(int(instance.card_id))
		if str(definition.get("type", "")) != "char":
			continue
		if _effective_tag_value(instance, definition, db, "adherent") <= 0:
			continue
		if _effective_tag_value(instance, definition, db, "lost") > 0:
			continue
		result.append({
			"id": int(instance.card_id),
			"tag": instance.tags.duplicate(true),
		})
	return result


func _effective_tag_value(instance, definition: Dictionary, db, code: String) -> int:
	var value := int(instance.tags.get(code, 0))
	var source_tags = definition.get("tag", {})
	if source_tags is Dictionary:
		for raw_tag in source_tags:
			if str(db.tag_code_for(raw_tag)) == code:
				value += int(source_tags[raw_tag])
	return value


func _build_npc_heads(cards: Array, db) -> void:
	if npc_head_container == null or cards.is_empty():
		return
	_heads_atlas = OriginalAtlasScript.load_atlas("res://assets/original/ui/heads.png")
	if _heads_atlas == null:
		return
	for raw_card in cards:
		if not (raw_card is Dictionary):
			continue
		var card := raw_card as Dictionary
		var card_id := int(card.get("id", card.get("card_id", 0)))
		if card_id <= 0:
			continue
		var pic := _card_pic_value(card, db)
		var item := Control.new()
		item.name = "OverNpcHead"
		item.custom_minimum_size = Vector2(100, 100)
		item.size = Vector2(100, 100)
		npc_head_container.add_child(item)
		var head := TextureRect.new()
		head.name = "Image"
		head.position = Vector2(4, -16)
		head.size = Vector2(92, 92)
		head.texture = _head_texture(card_id, pic)
		head.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		head.stretch_mode = TextureRect.STRETCH_SCALE
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(head)


func _card_pic_value(card: Dictionary, db) -> int:
	var tags = card.get("tag", card.get("tags", {}))
	if not (tags is Dictionary):
		return 0
	if tags.has("pic"):
		return int(tags.get("pic", 0))
	if db != null:
		for raw_tag in tags:
			if str(db.tag_code_for(raw_tag)) == "pic":
				return int(tags[raw_tag])
	return 0


func _head_texture(card_id: int, pic: int) -> Texture2D:
	# [SRC: Datapool.GetHeadSprite 0x411ea0] variant, zero-padded variant,
	# base id, then the dictionary's default sprite.
	var candidates: Array[String] = []
	if pic > 0:
		candidates.append("%d_%d.png" % [card_id, pic])
		candidates.append("%d_0%d.png" % [card_id, pic])
	candidates.append("%d.png" % card_id)
	candidates.append("2000000.png")
	for frame_name in candidates:
		if _heads_atlas.has_frame(frame_name):
			return _heads_atlas.frame(frame_name)
	return null


func _ending_texture(over_node: Dictionary, key: String, suffix := "") -> Texture2D:
	var relative := str(over_node.get(key, ""))
	if relative.is_empty():
		return null
	var path := "res://assets/original/ui/%s%s.png" % [relative, suffix]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
