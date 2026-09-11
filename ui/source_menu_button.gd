extends RefCounted

# StartPanel / ESCPanelNew: Image centered 668x140; Outline bottom-center
# (0,-4), pivot(.5,.5), 404x56. Shared geometry for the same source prefab.
static func decorate(button: Button, image_size := Vector2(668, 140)) -> void:
	var empty := StyleBoxEmpty.new()
	for key in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(key, empty)
	var stamp := TextureRect.new()
	stamp.name = "Image"
	stamp.texture = load("res://assets/original/ui/button_bg_new.png")
	stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.show_behind_parent = true
	button.add_child(stamp)
	stamp.set_anchors_preset(Control.PRESET_CENTER)
	stamp.offset_left = -image_size.x / 2
	stamp.offset_right = image_size.x / 2
	stamp.offset_top = -image_size.y / 2
	stamp.offset_bottom = image_size.y / 2
	var flourish := TextureRect.new()
	flourish.name = "Outline"
	flourish.texture = OriginalAtlas.load_atlas("res://assets/original/ui/rite_outlines.png").frame("rite_title.png")
	flourish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flourish.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flourish.show_behind_parent = true
	button.add_child(flourish)
	flourish.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	flourish.offset_left = -202
	flourish.offset_right = 202
	flourish.offset_top = -24
	flourish.offset_bottom = 32
	flourish.hide()
	button.mouse_entered.connect(func(): flourish.visible = not button.disabled)
	button.mouse_exited.connect(func(): flourish.visible = button.has_focus())
	button.focus_entered.connect(func(): flourish.visible = not button.disabled)
	button.focus_exited.connect(func(): flourish.hide())
