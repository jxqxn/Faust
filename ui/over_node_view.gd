## One ending-history row, mapped to the original OverNodeController.
## [SRC: OverNodeController.Init 0x57cc10 / OnDeleteClick 0x57cf90 /
##       OnMemoryClick 0x57cfc0; Resources/prefab/OverNode.prefab.]
class_name OverNodeView
extends Control

signal delete_requested(file_name: String)
signal memory_requested(over_data: Dictionary)

const SOURCE_ART := "res://assets/original/ui/"
const ROW_SIZE := Vector2(2301, 360)

var data_file_name := ""
var over_data: Dictionary = {}
var definition: Dictionary = {}
var _delete_confirm: Button
var _delete_cancel: Button


func setup(file_name: String, source_data: Dictionary, over_definitions: Dictionary) -> void:
	data_file_name = file_name
	over_data = source_data
	var source_id := str(int(source_data.get("id", 1)))
	definition = over_definitions.get(source_id, over_definitions.get("1", {})) as Dictionary


func _ready() -> void:
	name = "OverNode_%s" % data_file_name
	custom_minimum_size = ROW_SIZE
	size = ROW_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_surface()


func _build_surface() -> void:
	_place(_texture("hightlight.png"), Rect2(677, -15.68, 1624, 360), "highlight")
	_place(_texture("slash.png"), Rect2(0, 330, 2301, 30), "footer")

	var record := Button.new()
	record.name = "Record"
	record.flat = true
	record.pressed.connect(func(): memory_requested.emit(over_data))
	_place(record, Rect2(1723, 104.82, 324, 140))
	var record_art := _texture("repeat.png")
	record_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_child(record, record_art, Rect2(Vector2.ZERO, record.size), "Repeat")
	var record_text := _label("回忆", 72)
	record_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	record_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_child(record, record_text, Rect2(49.3, 0, 208.6, 140), "Text")

	var delete := Button.new()
	delete.name = "Delete"
	delete.flat = true
	delete.pressed.connect(_show_delete_confirm)
	_place(delete, Rect2(2110.61, 95.82, 168, 158))
	var delete_art := _texture("delete.png")
	delete_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_child(delete, delete_art, Rect2(Vector2.ZERO, delete.size), "DeleteIcon")

	var normal_icon := Control.new()
	_place(normal_icon, Rect2(13.6, 108.5, 312, 220), "NomalIcon")
	_place_child(normal_icon, _texture("fail.png"), Rect2(Vector2.ZERO, normal_icon.size), "Fail")
	var success := int(definition.get("success", 0))
	var victory_icon := _texture("great_victory.png")
	victory_icon.visible = success == 2
	_place_child(normal_icon, victory_icon, Rect2(-14, -104, 340, 324), "VictoryIcon")
	var success_title := _label("胜利", 80)
	success_title.visible = success != 0
	success_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	success_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_child(normal_icon, success_title, Rect2(56, 110.07, 200, 50), "Success")
	var dead_title := _label("死亡", 80)
	dead_title.visible = success == 0
	dead_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dead_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_child(normal_icon, dead_title, Rect2(56, 110.07, 200, 50), "Dead")

	var title_group := HBoxContainer.new()
	title_group.add_theme_constant_override("separation", 18)
	_place(title_group, Rect2(411, 41.32, 1208.72, 80), "TitleGroup")
	var title := _label(str(definition.get("name", "")), 50)
	title.name = "Title"
	title.custom_minimum_size = Vector2(0, 80)
	title_group.add_child(title)
	var time := _label(str(over_data.get("time", "")), 40)
	time.name = "Time"
	time.custom_minimum_size = Vector2(0, 80)
	title_group.add_child(time)

	var desc := _label(str(definition.get("sub_name", "")), 38)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(desc, Rect2(411, 148.24, 1159.18, 140.52), "Desc")
	_build_delete_confirm()


func _build_delete_confirm() -> void:
	_delete_confirm = Button.new()
	_delete_confirm.name = "DeleteConfirm"
	_delete_confirm.text = "确认"
	_delete_confirm.visible = false
	_delete_confirm.add_theme_font_size_override("font_size", 30)
	_delete_confirm.pressed.connect(func(): delete_requested.emit(data_file_name))
	_place(_delete_confirm, Rect2(2190.61, 249.82, 164, 80))
	_delete_cancel = Button.new()
	_delete_cancel.name = "DeleteCancel"
	_delete_cancel.text = "取消"
	_delete_cancel.visible = false
	_delete_cancel.add_theme_font_size_override("font_size", 24)
	_delete_cancel.pressed.connect(_hide_delete_confirm)
	_place(_delete_cancel, Rect2(2066.61, 250.82, 84, 79))


func _show_delete_confirm() -> void:
	_delete_confirm.visible = true
	_delete_cancel.visible = true


func _hide_delete_confirm() -> void:
	_delete_confirm.visible = false
	_delete_cancel.visible = false


func _texture(file_name: String) -> TextureRect:
	var view := TextureRect.new()
	var path := SOURCE_ART + file_name
	view.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#eadbb8"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _place(node: Control, rect: Rect2, node_name: String = "") -> void:
	if not node_name.is_empty():
		node.name = node_name
	node.position = rect.position
	node.size = rect.size
	add_child(node)


func _place_child(parent: Control, node: Control, rect: Rect2, node_name: String) -> void:
	node.name = node_name
	node.position = rect.position
	node.size = rect.size
	parent.add_child(node)
