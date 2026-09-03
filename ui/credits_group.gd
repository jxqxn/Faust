## Dynamic contributor group emitted by CreditsGroup.Show.
## [SRC: CreditsGroup.c @ Show (RVA 0x3f7590);
##       Resources/prefab/CreditsHelperGroup.prefab and CreditsNameWithJob.prefab]
class_name CreditsGroupView
extends Control

const SOURCE_ART := "res://assets/original/ui/"


func setup(group: Dictionary) -> void:
	size = Vector2(1400, 1300)
	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(200, 0)
	title.size = Vector2(1000, 100)
	title.text = str(group.get("title", ""))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	add_child(title)
	var separator := TextureRect.new()
	separator.name = "seperator"
	separator.position = Vector2(200, 100)
	separator.size = Vector2(1000, 28)
	separator.texture = load(SOURCE_ART + "seperator_1.png")
	separator.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	separator.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(separator)
	var y := 150.0
	for raw_member in group.get("members", []):
		var member := raw_member as Dictionary
		var row := Control.new()
		row.name = "CreditsNameWithJob"
		row.position = Vector2(200, y)
		row.size = Vector2(1000, 52)
		row.add_child(_label("Left", str(member.get("job", "")), Rect2(0, 0, 390, 52), HORIZONTAL_ALIGNMENT_RIGHT))
		row.add_child(_label("Right", str(member.get("name", "")), Rect2(430, 0, 570, 52), HORIZONTAL_ALIGNMENT_LEFT))
		add_child(row)
		y += 56.0


func _label(node_name: String, copy: String, rect: Rect2, alignment: HorizontalAlignment) -> Label:
	var view := Label.new()
	view.name = node_name
	view.text = copy
	view.position = rect.position
	view.size = rect.size
	view.horizontal_alignment = alignment
	view.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	view.add_theme_font_size_override("font_size", 40)
	return view
