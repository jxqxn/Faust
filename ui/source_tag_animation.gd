extends "res://ui/source_new_card_animation.gd"
## Shares only the source float-clip clock / Done continuation, not new-card art.
## [SRC: OpCardNewController.Init 0x572f40 cases 6/7, dump.cs:321362;
## OpCardTagController.set_TagNode 0x5768b0 -> TagNodeExtensions.GetSprite
## 0x3932f0; OpCard.prefab TagBg/Tag/TagModify, tagText is null.]
var amount_label: Label
var tag_icon: TextureRect

func setup(op: Dictionary, db: ConfigDB) -> void:
	operation = op
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var removal := int(op.get("op", -1)) == 7
	clip.read("res://assets/original/anims/opcard/%s.anim" % ("remove_tag" if removal else "add_tag"))
	# Cell 300x200: center pivot .5, TagBg 200x100 at (0,0).
	# Flip Unity y: root (50,50); Tag 72x72 at (64,14).
	position = Vector2(50, 50)
	banner = TextureRect.new()
	banner.name = "TagBg"
	banner.texture = load("res://assets/original/ui/prompt_2_bg.png")
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.size = Vector2(200, 100)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	tag_icon = TextureRect.new()
	tag_icon.name = "Tag"
	var tag_name := str(op.get("tag", ""))
	var code: String = str(db.tag_name_to_code.get(tag_name, tag_name))
	var definition: Dictionary = db.tags_by_code.get(code, {})
	var atlas := OriginalAtlas.load_atlas("res://assets/original/ui/tags.png")
	tag_icon.texture = atlas.frame(str(definition.get("resource", "")) + ".png")
	tag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tag_icon.position = Vector2(64, 14)
	tag_icon.size = Vector2(72, 72)
	tag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(tag_icon)
	amount_label = Label.new()
	amount_label.name = "TagModify"
	# Tag child anchoredPosition(68,1), size200x50, pivot.5 => (4,10).
	amount_label.position = Vector2(4, 10)
	amount_label.size = Vector2(200, 50)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Original format strings 0x25bde80 / 0x25c17d0: +{0} / -{0}.
	amount_label.text = ("-" if removal else "+") + str(int(op.get("amount", 0)))
	amount_label.add_theme_font_size_override("font_size", 36)
	# Init overrides prefab yellow: DLL RVA1c9e790 / 1c9e780 float4.
	amount_label.add_theme_color_override("font_color", Color(1, 0, 0, 1) if removal else Color(1, 235.0 / 255.0, 4.0 / 255.0, 1))
	tag_icon.add_child(amount_label)
	hide()
