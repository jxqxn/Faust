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
signal save_requested(index: int, archive_name: String)
signal rename_requested(index: int, archive_name: String)
signal delete_requested(index: int)

const DESIGN_SPACE := Vector2(3840, 2160)
const SLOT_COUNT := 50
const ITEM_SIZE := Vector2(2760, 240)
const LEFT_RECT := Rect2(200, 300, 875.2, 1560)
const SCROLL_RECT := Rect2(1228.8, 200, 2511.2, 1760)
const MAX_ARCHIVE_NAME_LENGTH := 20

var _save_mode := true
var _archives_by_index: Dictionary = {}
var _name_popup: Control
var _name_input: LineEdit
var _name_confirm: Button
var _pending_index := -1
var _pending_action := ""


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
	# bg_1 is not present in the extracted asset set.  Retain the original
	# full-rect carrier and source geometry; do not invent replacement art.
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.045, 0.038, 0.03, 0.96)
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
	var close_text := Label.new()
	close_text.name = "X"
	close_text.text = "×"
	close_text.position = Vector2(0, 0)
	close_text.size = close.size
	close_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	close_text.add_theme_font_size_override("font_size", 64)
	close_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close.add_child(close_text)

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
	var icon := Label.new()
	icon.name = "Icon"
	icon.text = "▣"
	icon.custom_minimum_size = Vector2(80, 80)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 58)
	header.add_child(icon)
	var title := Label.new()
	title.name = "Title"
	title.text = "保存进度" if _save_mode else "读取存档"
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	header.add_child(title)
	var desc := Label.new()
	desc.name = "Desc"
	desc.position = Vector2(0, 140)
	desc.size = Vector2(LEFT_RECT.size.x, 300)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text = "选择一个档位保存当前进度。" if _save_mode else "选择一个档位继续游戏。"
	desc.add_theme_font_size_override("font_size", 40)
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
	content.size = Vector2(ITEM_SIZE.x, ITEM_SIZE.y * SLOT_COUNT)
	scroll.add_child(content)
	for index in SLOT_COUNT:
		var item := _make_archive_item(index, _archives_by_index.get(index))
		item.position = Vector2(0, ITEM_SIZE.y * index)
		content.add_child(item)


func _make_archive_item(index: int, archive: Variant) -> Control:
	var item := Button.new()
	item.name = "UserArchiveItem_%02d" % index
	item.flat = true
	item.custom_minimum_size = ITEM_SIZE
	item.size = ITEM_SIZE
	item.tooltip_text = ""
	item.pressed.connect(_on_item_clicked.bind(index))

	var footer := ColorRect.new()
	footer.name = "footer"
	footer.color = Color(FaustTheme.GOLD, 0.42)
	footer.position = Vector2(0, ITEM_SIZE.y - 18)
	footer.size = Vector2(ITEM_SIZE.x, 3)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(footer)
	if not (archive is Dictionary):
		var empty := Label.new()
		empty.name = "EmptyContent"
		empty.text = "空"
		empty.position = Vector2(0, 80)
		empty.size = Vector2(600, 80)
		empty.add_theme_font_size_override("font_size", 60)
		empty.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(empty)
		return item

	var content := Control.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(content)
	var number := Label.new()
	number.name = "No"
	number.text = "%03d" % (index + 1)
	number.position = Vector2(0, 20)
	number.size = Vector2(180, 80)
	number.add_theme_font_size_override("font_size", 60)
	number.add_theme_color_override("font_color", FaustTheme.GOLD)
	content.add_child(number)
	var title := Label.new()
	title.name = "Title"
	title.text = str((archive as Dictionary).get("name", "未命名存档"))
	title.position = Vector2(200, 20)
	title.size = Vector2(1500, 80)
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	content.add_child(title)
	var desc := Label.new()
	desc.name = "Desc"
	desc.position = Vector2(100, 120)
	desc.size = Vector2(1940, 90)
	desc.add_theme_font_size_override("font_size", 40)
	desc.add_theme_color_override("font_color", FaustTheme.TEXT)
	desc.text = _archive_description(archive as Dictionary)
	content.add_child(desc)
	if _save_mode:
		var rename := Button.new()
		rename.name = "ModifyName"
		rename.text = "改名"
		rename.position = Vector2(1980, 20)
		rename.size = Vector2(180, 76)
		rename.add_theme_font_size_override("font_size", 40)
		rename.pressed.connect(_open_rename.bind(index))
		content.add_child(rename)
		var delete := Button.new()
		delete.name = "Delete"
		delete.text = "删除"
		delete.position = Vector2(2180, 38)
		delete.size = Vector2(168, 120)
		delete.add_theme_font_size_override("font_size", 40)
		delete.pressed.connect(_confirm_delete.bind(index))
		content.add_child(delete)
	else:
		var load := Label.new()
		load.name = "Load"
		load.text = "读取"
		load.position = Vector2(2160, 38)
		load.size = Vector2(328, 120)
		load.add_theme_font_size_override("font_size", 46)
		load.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
		content.add_child(load)
	return item


func _archive_description(archive: Dictionary) -> String:
	return "存活天数：%d    剩余苏丹卡：%d    处刑日：第 %d 天\n保存时间：%s" % [
		int(archive.get("live_days", archive.get("day", 1))),
		int(archive.get("left_sudan", 0)),
		int(archive.get("execution_day", -1)),
		str(archive.get("save_time", "")),
	]


func _on_item_clicked(index: int) -> void:
	var archive = _archives_by_index.get(index)
	if _save_mode:
		if archive is Dictionary:
			_confirm_overwrite(index)
		else:
			_open_name_input(index, "", "save")
		return
	if archive is Dictionary:
		# The game owns the actual restore transition. This signal is intentionally
		# not emitted for empty slots, matching OnItemClicked's null no-op path.
		closed.emit()


func _confirm_overwrite(index: int) -> void:
	var confirmation := ConfirmationDialog.new()
	confirmation.name = "OverwriteArchiveConfirm"
	confirmation.dialog_text = "确定覆盖这个存档吗？"
	add_child(confirmation)
	confirmation.confirmed.connect(func():
		confirmation.queue_free()
		var archive: Dictionary = _archives_by_index.get(index, {})
		_open_name_input(index, str(archive.get("name", "")), "save")
	)
	confirmation.canceled.connect(confirmation.queue_free)
	confirmation.popup_centered()


func _open_rename(index: int) -> void:
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
	var prompt := PanelContainer.new()
	prompt.name = "PromptBG"
	prompt.position = Vector2((DESIGN_SPACE.x - 2534.4) * 0.5, (DESIGN_SPACE.y - 635.23) * 0.5)
	prompt.size = Vector2(2534.4, 635.23)
	prompt.add_theme_stylebox_override("panel", FaustTheme.card_style(FaustTheme.GOLD))
	_name_popup.add_child(prompt)
	var label := Label.new()
	label.name = "Title"
	label.text = "输入存档名称"
	label.position = Vector2(260, 110)
	label.size = Vector2(1200, 80)
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	prompt.add_child(label)
	_name_input = LineEdit.new()
	_name_input.name = "InputField (TMP)"
	_name_input.position = Vector2(260, 245)
	_name_input.size = Vector2(826, 90)
	_name_input.max_length = MAX_ARCHIVE_NAME_LENGTH
	_name_input.text = initial_name
	_name_input.placeholder_text = "请输入 1–20 个字符"
	_name_input.add_theme_font_size_override("font_size", 50)
	prompt.add_child(_name_input)
	_name_confirm = Button.new()
	_name_confirm.name = "Confirm"
	_name_confirm.text = "确认"
	_name_confirm.position = Vector2(1660, 430)
	_name_confirm.size = Vector2(325, 158)
	_name_confirm.add_theme_font_size_override("font_size", 54)
	_name_confirm.pressed.connect(_confirm_name_input)
	prompt.add_child(_name_confirm)
	var cancel := Button.new()
	cancel.name = "Cancel"
	cancel.text = "取消"
	cancel.position = Vector2(1358, 430)
	cancel.size = Vector2(168, 158)
	cancel.add_theme_font_size_override("font_size", 46)
	cancel.pressed.connect(_close_name_input)
	prompt.add_child(cancel)
	_name_input.text_changed.connect(func(_text: String): _refresh_name_confirm())
	_refresh_name_confirm()
	_name_input.grab_focus()


func _refresh_name_confirm() -> void:
	if _name_confirm != null and _name_input != null:
		_name_confirm.disabled = _name_input.text.length() < 1 or _name_input.text.length() > MAX_ARCHIVE_NAME_LENGTH


func _confirm_name_input() -> void:
	if _name_input == null or _name_confirm == null or _name_confirm.disabled:
		return
	var archive_name := _name_input.text
	if _pending_action == "rename":
		rename_requested.emit(_pending_index, archive_name)
	else:
		save_requested.emit(_pending_index, archive_name)
	_close_name_input()


func _confirm_delete(index: int) -> void:
	var confirmation := ConfirmationDialog.new()
	confirmation.name = "DeleteArchiveConfirm"
	confirmation.dialog_text = "确定删除这个存档吗？此操作无法撤销。"
	add_child(confirmation)
	confirmation.confirmed.connect(func():
		confirmation.queue_free()
		delete_requested.emit(index)
	)
	confirmation.canceled.connect(confirmation.queue_free)
	confirmation.popup_centered()


func _close_name_input() -> void:
	if _name_popup != null:
		_name_popup.queue_free()
	_name_popup = null
	_name_input = null
	_name_confirm = null
	_pending_index = -1
	_pending_action = ""
