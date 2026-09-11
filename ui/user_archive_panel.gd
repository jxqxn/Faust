## Source-shaped manual archive panel.
##
## The original owns save/load selection through UserArchiveController, with a
## fixed 50-slot datasource.  This is deliberately not a clone-era ``new
## archive + list of existing archives`` dialog: empty slots are first-class
## items, while save, overwrite, rename and delete are separate controller
## transitions.
## [SRC: Resources/prefab/UserArchive.prefab / UserArchiveItem.prefab /
##       UserArchiveNameInput.prefab; decompiled/UserArchiveController.c @
##       Show (RVA 0x5c9030), OnItemClicked (RVA 0x5c8630);
##       UserArchiveItemController.c @ UpdateShow/OnDelete (0x5ca130/0x5c9760);
##       UserArchiveNameInputController.c @ Show (RVA 0x5cb0f0), dump.cs:327948]
extends Control

signal closed
signal load_requested(index: int)
signal save_requested(index: int, archive_name: String)
signal rename_requested(index: int, archive_name: String)
signal delete_requested(index: int)

const DESIGN_SPACE := Vector2(3840, 2160)
const SLOT_COUNT := 50
const ITEM_SIZE := Vector2(2760, 240)
const ITEM_RUNTIME_SIZE := Vector2(2471.2, 240)
const LEFT_RECT := Rect2(200, 300, 875.2, 1560)
const SCROLL_RECT := Rect2(1228.8, 200, 2511.2, 1760)
const MAX_ARCHIVE_NAME_LENGTH := 20
const SourceDialog = preload("res://ui/source_confirm_dialog.gd")
const SourceText = preload("res://ui/source_text_style.gd")

var _save_mode := true
var _archives_by_index: Dictionary = {}
var _name_popup: Control
var _name_input: LineEdit
var _name_confirm: Button
var _pending_index := -1
var _pending_action := ""
var _confirmation: Control
var _delete_confirmation: Control

func _text(key: String) -> String:
	return JSON.parse_string(FileAccess.get_file_as_string("res://content/ui.json"))[key].zhCN

func refresh_archives(archives: Array) -> void:
	setup(archives, _save_mode)
	var content := get_node("Background/Scroll View/Content")
	for item in content.get_children():
		content.remove_child(item)
		item.queue_free()
	_delete_confirmation = null
	for index in SLOT_COUNT:
		var item := _make_archive_item(index, _archives_by_index.get(index))
		item.position = Vector2(0, ITEM_SIZE.y * index)
		content.add_child(item)


func setup(archives: Array, save_mode: bool = true) -> void:
	_save_mode = save_mode
	_archives_by_index.clear()
	for archive in archives:
		if archive is Dictionary:
			var index := int(archive.get("index", -1))
			if index >= 0 and index < SLOT_COUNT:
				_archives_by_index[index] = archive.duplicate(true)


func _ready() -> void:
	name = "UserArchiveController"
	theme = FaustTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1002
	_build_source_tree()
	apply_source_layout(get_viewport_rect().size)


func apply_source_layout(view_size: Vector2) -> void:
	position = Vector2.ZERO
	size = DESIGN_SPACE
	scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _build_source_tree() -> void:
	# [SRC: UserArchive.prefab root Image -> Sprite/bg_1.asset]
	var background := TextureRect.new()
	background.name = "Background"
	background.texture = preload("res://assets/original/ui/bg_1.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.position = Vector2.ZERO
	background.size = DESIGN_SPACE
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	var close := Button.new()
	close.name = "Close"
	close.flat = true
	close.position = Vector2(3718.2, 45.3)
	close.size = Vector2(80, 82)
	close.tooltip_text = "关闭"
	close.pressed.connect(func(): closed.emit())
	background.add_child(close)
	var close_bg := TextureRect.new()
	close_bg.texture = preload("res://assets/original/ui/checkbox_bg.png")
	close_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	close_bg.size = close.size
	close_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close.add_child(close_bg)
	var close_text := TextureRect.new()
	close_text.name = "X"
	close_text.texture = preload("res://assets/original/ui/close_2.png")
	close_text.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	close_text.position = (close.size - Vector2(43, 37)) / 2
	close_text.size = Vector2(43, 37)
	close_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close.add_child(close_text)
	# [SRC: UserArchive.prefab Close Selectable, target=checkbox background.]
	close.focus_mode = Control.FOCUS_NONE
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		close.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	var close_tint := preload("res://ui/source_confirm_tint.gd").new()
	close_tint.button = close
	close_tint.graphic = close_bg
	close.add_child(close_tint)

	var left := Control.new()
	left.name = "Left"
	left.position = LEFT_RECT.position
	left.size = LEFT_RECT.size
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(left)
	var header := HBoxContainer.new()
	header.name = "Header"
	header.position = Vector2.ZERO
	header.size = Vector2(LEFT_RECT.size.x, 104)
	header.add_theme_constant_override("separation", 20)
	left.add_child(header)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load("res://assets/original/ui/user_archive_%s.png" % ("save" if _save_mode else "load"))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(132, 132)
	header.add_child(icon)
	var title := Label.new()
	title.name = "Title"
	var captions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/ui.json"))
	title.text = captions.USER_ARCHIVE_SAVE_TITLE.zhCN if _save_mode else captions.USER_ARCHIVE_LOAD_TITLE.zhCN
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	preload("res://ui/source_text_style.gd").apply(title, "@TITLE_H1")
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	header.add_child(title)
	var desc := Label.new()
	desc.name = "Desc"
	desc.position = Vector2(0, 140)
	desc.size = Vector2(LEFT_RECT.size.x, 300)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text = captions.USER_ARCHIVE_SAVE_DESC.zhCN if _save_mode else captions.USER_ARCHIVE_LOAD_DESC.zhCN
	desc.add_theme_font_size_override("font_size", 40)
	preload("res://ui/source_text_style.gd").apply(desc, "@MAIN_BODY")
	desc.add_theme_color_override("font_color", FaustTheme.TEXT)
	left.add_child(desc)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll View"
	scroll.position = SCROLL_RECT.position
	scroll.size = SCROLL_RECT.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	background.add_child(scroll)
	# The original uses LoopScrollRect virtualization: item width (2760) may be
	# wider than the visible viewport.  A plain VBox would expand the viewport
	# to its children in Godot, so keep the source content rect explicit.
	var content := Control.new()
	content.name = "Content"
	# The prefab is authored at 2760 wide, while LoopScrollRect lays each row
	# into UserArchive/Scroll View/Viewport (2511.2 - 40 = 2471.2).  Runtime
	# right anchors resolve against this viewport width.
	content.size = Vector2(ITEM_RUNTIME_SIZE.x, ITEM_SIZE.y * SLOT_COUNT)
	content.custom_minimum_size = Vector2(0, ITEM_SIZE.y * SLOT_COUNT)
	scroll.add_child(content)
	for index in SLOT_COUNT:
		var item := _make_archive_item(index, _archives_by_index.get(index))
		item.position = Vector2(0, ITEM_SIZE.y * index)
		content.add_child(item)


func _make_archive_item(index: int, archive: Variant) -> Control:
	var item := Button.new()
	item.name = "UserArchiveItem_%02d" % index
	item.flat = true
	item.custom_minimum_size = ITEM_RUNTIME_SIZE
	item.size = ITEM_RUNTIME_SIZE
	item.set_meta("source_authored_size", ITEM_SIZE)
	item.tooltip_text = ""
	item.pressed.connect(_on_item_clicked.bind(index))

	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		item.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	var highlight := SourceDialog.image(item, "Highlight", "hightlight", Rect2(Vector2.ZERO, ITEM_RUNTIME_SIZE))
	highlight.hide()
	item.mouse_entered.connect(highlight.show)
	item.mouse_exited.connect(highlight.hide)
	SourceDialog.image(item, "footer", "slash", Rect2(0, 210, ITEM_RUNTIME_SIZE.x, 30))
	if not (archive is Dictionary):
		var empty := Label.new()
		empty.name = "EmptyContent"
		empty.text = _text("USER_ARCHIVE_SLOT_EMPTY")
		empty.position = Vector2(0, 88)
		empty.size = Vector2(ITEM_RUNTIME_SIZE.x, 80)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		SourceText.apply(empty, "@TITLE_H2")
		empty.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(empty)
		return item

	var content := Control.new()
	content.name = "Content"
	content.size = ITEM_RUNTIME_SIZE
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(content)
	var title_row := HBoxContainer.new()
	title_row.name = "TitleRow"
	title_row.position = Vector2(0, 20)
	title_row.size = Vector2(2000, 80)
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_theme_constant_override("separation", 20)
	content.add_child(title_row)
	var number := Label.new()
	number.name = "No"
	number.text = "%03d" % (index + 1)
	SourceText.apply(number, "@TITLE_H2")
	number.add_theme_color_override("font_color", FaustTheme.GOLD)
	title_row.add_child(number)
	var title := Label.new()
	title.name = "Title"
	title.text = str((archive as Dictionary).get("name", "未命名存档"))
	SourceText.apply(title, "@TITLE_H2")
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	title_row.add_child(title)
	var rename := SourceDialog.button(title_row, "ModifyName", "user_archive_modify_name", Rect2(0, 0, 100, 56), true)
	rename.custom_minimum_size = Vector2(100, 56)
	rename.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rename.pressed.connect(_open_rename.bind(index))
	var desc := Label.new()
	desc.name = "Desc"
	desc.position = Vector2(100, 120)
	desc.size = Vector2(ITEM_RUNTIME_SIZE.x - 100, 90)
	SourceText.apply(desc, "@MAIN_BODY")
	desc.add_theme_color_override("font_color", FaustTheme.TEXT)
	desc.text = _archive_description(archive as Dictionary)
	content.add_child(desc)
	var delete := SourceDialog.button(content, "Delete", "delete", Rect2(ITEM_RUNTIME_SIZE.x - 343, 35.82, 168, 158), true)
	delete.pressed.connect(_confirm_delete.bind(index))
	if not _save_mode:
		var load := SourceDialog.button(content, "Load", "rite_op_confirm", Rect2(ITEM_RUNTIME_SIZE.x - 634, 34.82, 328, 160), true)
		load.pressed.connect(_on_item_clicked.bind(index))
	return item


func _archive_description(archive: Dictionary) -> String:
	return "    ".join([
		_text("USER_ARCHIVE_LIVE_TIME").replace("{0}", str(int(archive.get("live_days", 1)))),
		_text("USER_ARCHIVE_LEFT_SUDAN_CARD_COUNT").replace("{0}", str(int(archive.get("left_sudan", 0)))),
		_text("USER_ARCHIVE_EXECUTION_DAY_LEFT").replace("{0}", str(int(archive.get("execution_day", -1)))),
		_format_archive_time(str(archive.get("save_time", "")))])


## UserArchiveItemController.UpdateShow renders the ISO save timestamp as a
## short local timestamp (the source screenshot shows 2026/6/26 15:37:11,
## while the JSON index retains the offset-bearing ISO value).
## [SRC: UserArchiveItemController.c @ UpdateShow (RVA 0x5ca130),
##       save_samples/user_archive.json]
func _format_archive_time(value: String) -> String:
	if value.is_empty():
		return ""
	var date_and_time := value.split("T", false, 1)
	if date_and_time.size() != 2:
		return value.replace("T", " ")
	var date_parts := date_and_time[0].split("-", false)
	var time_part := date_and_time[1].split("+", false)[0].split("-", false)[0]
	if date_parts.size() != 3:
		return value.replace("T", " ")
	var time_parts := time_part.split(":", false)
	if time_parts.size() < 2:
		return value.replace("T", " ")
	var year := int(date_parts[0])
	var month := int(date_parts[1])
	var day := int(date_parts[2])
	var hour := int(time_parts[0])
	var minute := int(time_parts[1])
	var second := int(time_parts[2].split(".", false)[0]) if time_parts.size() > 2 else 0
	return "%d/%d/%d %02d:%02d:%02d" % [year, month, day, hour, minute, second]


func _on_item_clicked(index: int) -> void:
	if _name_popup != null or is_instance_valid(_confirmation):
		return
	var archive = _archives_by_index.get(index)
	if _save_mode:
		if archive is Dictionary:
			_confirm_overwrite(index)
		else:
			_open_name_input(index, _text("USER_ARCHIVE_UNNAMED"), "save")
		return
	if archive is Dictionary:
		# [SRC: UserArchiveController.OnItemClicked 0x5c8630, save mode +0xA0;
		# DisplayClass19_0.<OnItemClicked>b__0 loads only after confirmation.]
		var confirmation := SourceDialog.new()
		_confirmation = confirmation
		confirmation.name = "LoadArchiveConfirm"
		var captions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/ui.json"))
		confirmation.dialog_text = captions.USER_ARCHIVE_LOAD_PROMPT.zhCN
		add_child(confirmation)
		confirmation.confirmed.connect(func():
			confirmation.queue_free()
			load_requested.emit(index))
		confirmation.canceled.connect(confirmation.queue_free)
		confirmation.popup_centered()


func _confirm_overwrite(index: int) -> void:
	var confirmation := SourceDialog.new()
	_confirmation = confirmation
	confirmation.name = "OverwriteArchiveConfirm"
	confirmation.dialog_text = _text("USER_ARCHIVE_ORVEWRITE_PROMPT")
	add_child(confirmation)
	confirmation.confirmed.connect(func():
		confirmation.queue_free()
		var archive: Dictionary = _archives_by_index.get(index, {})
		_open_name_input(index, str(archive.get("name", "")), "save")
	)
	confirmation.canceled.connect(confirmation.queue_free)
	confirmation.popup_centered()


func _open_rename(index: int) -> void:
	if _name_popup != null or is_instance_valid(_confirmation):
		return
	var archive: Dictionary = _archives_by_index.get(index, {})
	_open_name_input(index, str(archive.get("name", "")), "rename")


func _open_name_input(index: int, initial_name: String, action: String) -> void:
	if _name_popup != null:
		return
	_pending_index = index
	_pending_action = action
	_name_popup = Control.new()
	_name_popup.name = "UserArchiveNameInput"
	_name_popup.position = Vector2.ZERO
	_name_popup.size = DESIGN_SPACE
	_name_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_name_popup)
	var mask := ColorRect.new()
	mask.name = "Mask"
	mask.color = Color(0, 0, 0, 0.55)
	mask.size = DESIGN_SPACE
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	_name_popup.add_child(mask)
	# UserArchive's embedded name prefab: no invented heading; input is below
	# Content at (1252.2,217.62), and buttons anchor to the bottom edge.
	var prompt := SourceDialog.panel(_name_popup, Rect2((DESIGN_SPACE - Vector2(2534.4, 635.23)) / 2, Vector2(2534.4, 635.23)))
	SourceDialog.full_background(prompt, Rect2(37.24, 50.775, 2458.66, 500.04))
	var portrait := TextureRect.new()
	portrait.name = "Icon"
	portrait.texture = preload("res://assets/original/cards/1_char_7.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(2024.9, -458.77)
	portrait.size = Vector2(471, 1028)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.add_child(portrait)
	_name_input = LineEdit.new()
	_name_input.name = "InputField (TMP)"
	_name_input.position = Vector2(839.2, 253.62)
	_name_input.size = Vector2(826, 90)
	_name_input.max_length = MAX_ARCHIVE_NAME_LENGTH
	_name_input.text = initial_name
	_name_input.placeholder_text = _text("USER_ARCHIVE_NAME_PLACEHOLDER")
	_name_input.add_theme_font_size_override("font_size", 50)
	_name_input.add_theme_font_override("font", preload("res://assets/fonts/xiquemuye.ttf"))
	var input_style := StyleBoxTexture.new()
	input_style.texture = preload("res://assets/original/ui/input_bg.png")
	for key in ["normal", "focus", "read_only"]:
		_name_input.add_theme_stylebox_override(key, input_style)
	prompt.add_child(_name_input)
	SourceDialog.image(prompt, "Border", "decorate", Rect2(2295.9, 310.98, 235.99, 324.51))
	_name_confirm = SourceDialog.button(prompt, "Confirm", "rite_op_confirm", Rect2(1924.2, 477.23, 325, 158), true)
	# UserArchiveNameInput Confirm ColorBlock differs from shared ConfirmNew.
	_name_confirm.get_node("SourceColorTint").disabled_color = Color(0.39215687, 0.39215687, 0.39215687, 1)
	_name_confirm.focus_mode = Control.FOCUS_ALL
	_name_confirm.pressed.connect(_confirm_name_input)
	var cancel := SourceDialog.button(prompt, "Cancel", "rite_op_cancel", Rect2(1701.4, 477.23, 168, 158), true)
	cancel.pressed.connect(_close_name_input)
	_name_input.text_changed.connect(func(_text: String): _refresh_name_confirm())
	_refresh_name_confirm()
	_name_input.grab_focus()
	_name_input.select_all()
	_name_input.text_submitted.connect(func(_text: String): _confirm_name_input())


func _refresh_name_confirm() -> void:
	if _name_confirm != null and _name_input != null:
		_name_confirm.disabled = _name_input.text.length() < 1 or _name_input.text.length() > MAX_ARCHIVE_NAME_LENGTH


func _confirm_name_input() -> void:
	if _name_input == null or _name_confirm == null or _name_confirm.disabled:
		return
	var archive_name := _name_input.text
	var index := _pending_index
	var action := _pending_action
	_close_name_input()
	if action == "rename":
		rename_requested.emit(index, archive_name)
	else:
		save_requested.emit(index, archive_name)


func _confirm_delete(index: int) -> void:
	if _name_popup != null or is_instance_valid(_confirmation):
		return
	if is_instance_valid(_delete_confirmation):
		_delete_confirmation.queue_free()
	var target := get_node("Background/Scroll View/Content/UserArchiveItem_%02d/Content/Delete" % index)
	var confirmation := Control.new()
	confirmation.name = "DeleteConfirm"
	confirmation.position = Vector2(34, 29)
	confirmation.size = Vector2(100, 100)
	confirmation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(confirmation)
	_delete_confirmation = confirmation
	# [SRC: UserArchiveItem Delete/DeleteConfirm prefab + OnDelete 0x5c9760]
	var accept := SourceDialog.button(confirmation, "Confirm", "rite_op_confirm", Rect2(46, 125, 164, 80), true)
	var cancel := SourceDialog.button(confirmation, "Close", "rite_op_cancel", Rect2(-78, 126, 84, 79), true)
	accept.pressed.connect(func():
		accept.disabled = true
		delete_requested.emit(index))
	cancel.pressed.connect(confirmation.queue_free)


func _close_name_input() -> void:
	if _name_popup != null:
		_name_popup.queue_free()
	_name_popup = null
	_name_input = null
	_name_confirm = null
	_pending_index = -1
	_pending_action = ""
