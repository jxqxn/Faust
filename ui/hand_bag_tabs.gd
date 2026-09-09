class_name HandBagTabs
extends Control

signal page_selected(index: int)

const NUMBER_OFF_SIZE := [Vector2(17.5, 56), Vector2(30, 55.5), Vector2(40.5, 56), Vector2(47, 55)]
const NUMBER_ON_SIZE := [Vector2(12.5, 50), Vector2(24, 49.5), Vector2(35, 50), Vector2(41, 49.5)]
var buttons: Array[TextureButton] = []


func _ready() -> void:
	# [SRC: GameScene BagBtnGroup/BagGroup: 80x335, spacing 6;
	# four Toggle children 0..3; GameController.ChangeCurrentBag 0x54cb60.]
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(105, 340)
	var group := ButtonGroup.new()
	for index in range(4):
		var button := TextureButton.new()
		button.name = "Bag%d" % index
		button.position = Vector2(12.5, 2.5 + index * 86)
		button.size = Vector2(80, 80)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.texture_normal = load("res://assets/original/ui/bag_icon_1.png")
		button.texture_pressed = load("res://assets/original/ui/bag_icon.png")
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = str(index + 1)
		add_child(button)
		buttons.append(button)
		for selected in [false, true]:
			var number := TextureRect.new()
			number.name = "NumberOn" if selected else "NumberOff"
			number.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			number.texture = load("res://assets/original/ui/%d_%s.png" % [index + 1, "on" if selected else "off"])
			number.size = NUMBER_ON_SIZE[index] if selected else NUMBER_OFF_SIZE[index]
			number.position = (button.size - number.size) * 0.5
			number.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(number)
		button.pressed.connect(func(): page_selected.emit(index))
	update_page(0)


func update_page(index: int) -> void:
	for i in buttons.size():
		buttons[i].set_pressed_no_signal(i == index)
		buttons[i].get_node("NumberOn").visible = i == index
		buttons[i].get_node("NumberOff").visible = i != index
