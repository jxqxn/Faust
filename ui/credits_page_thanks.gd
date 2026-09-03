## Original thanks/supporter page. GetNames retains the source clamp values,
## UTF-16 length accounting, row alignment and page splitting; the resulting
## strings remain views over raw CreditsNode.ThankItem.members.
## [SRC: CreditsPageThanks.c @ Show/GetNames/set_Position/Next/Previous
##       (RVA 0x3f86d0/0x3f8070/0x3f8a00/0x3f8600/0x3f86b0);
##       dump.cs:418238-418300]
class_name CreditsPageThanks
extends "res://ui/credits_page.gd"

const DEFAULT_COLUMNS := 3
const DEFAULT_CELL_SIZE := 13
const DEFAULT_PAGE_SIZE := 40
# The prefab's four-line placeholder resolves to 312.01px.
const SOURCE_LINE_HEIGHT := 312.01 / 4.0

var _thanks: Dictionary = {}
var _name_pages: Array[String] = []
var _names: Control
var _desc: RichTextLabel


func show_data(data: Variant, pos: int) -> void:
	super.show_data(data, pos)
	_thanks = data as Dictionary
	setup_page(str(_thanks.get("title", "")), str(_thanks.get("type", "helper")))
	if _desc == null:
		_desc = RichTextLabel.new()
		_desc.name = "Talk"
		_desc.position = Vector2(170, 480)
		_desc.size = Vector2(3500, 96.02)
		_desc.bbcode_enabled = true
		_desc.scroll_active = false
		_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_desc.add_theme_font_size_override("normal_font_size", 80)
		_desc.add_theme_color_override("default_color", SOURCE_GOLD)
		add_child(_desc)
		_names = Control.new()
		_names.name = "Text"
		_names.position = Vector2(170, 616.02)
		_names.size = Vector2(3500, 1223.98)
		add_child(_names)
	_desc.text = _tmp_to_bbcode(str(_thanks.get("desc", "")))
	_name_pages = build_name_pages(_thanks)
	set_page_position(pos)


func set_page_position(value: int) -> void:
	page_position = clampi(value, 0, maxi(0, _name_pages.size() - 1))
	_render_name_page(_name_pages[page_position] if not _name_pages.is_empty() else "")


func has_previous() -> bool:
	return page_position > 0


func has_next() -> bool:
	return page_position + 1 < _name_pages.size()


func previous() -> void:
	if has_previous():
		set_page_position(page_position - 1)


func next() -> void:
	if has_next():
		set_page_position(page_position + 1)


static func build_name_pages(item: Dictionary) -> Array[String]:
	var columns := DEFAULT_COLUMNS if int(item.get("column", 0)) < 1 else clampi(int(item.get("column", 0)), 1, 5)
	var cell_size := DEFAULT_CELL_SIZE if int(item.get("cell_size", 0)) < 1 else clampi(int(item.get("cell_size", 0)), 10, 50)
	var page_size := DEFAULT_PAGE_SIZE if int(item.get("page_size", 0)) < 1 else clampi(int(item.get("page_size", 0)), 10, 80)
	var pages: Array[String] = []
	var out := ""
	var occupied := 0
	for raw_name in item.get("members", []):
		var member_name := str(raw_name)
		# System.String.Length in the original counts UTF-16 code units.
		var utf16_length := floori(float(member_name.to_utf16_buffer().size()) / 2.0)
		var needed := int(ceili(float(utf16_length) / float(cell_size)))
		if occupied + needed > page_size and not out.is_empty():
			pages.append(out)
			out = ""
			occupied = 0
		if occupied % columns == 0 and occupied != 0:
			out += "\n"
		var indent := int(float(occupied % columns) * 100.0 / float(columns) + 100.0 / float(columns * 5))
		out += "<indent=%d%%>%s</indent>" % [indent, member_name]
		var previous_row := floori(float(occupied) / float(columns))
		occupied += needed
		if floori(float(occupied) / float(columns)) != previous_row:
			occupied = floori(float(occupied) / float(columns)) * columns
	if not out.is_empty():
		pages.append(out)
	return pages


func _render_name_page(source: String) -> void:
	for child in _names.get_children():
		_names.remove_child(child)
		child.free()
	var regex := RegEx.new()
	regex.compile("<indent=([0-9]+)%>(.*?)</indent>")
	var item_index := 0
	var row_index := 0
	for line in source.split("\n"):
		for match in regex.search_all(line):
			var indent_percent := int(match.get_string(1))
			var x := 3500.0 * float(indent_percent) / 100.0
			var view := Label.new()
			view.name = "Name%d" % item_index
			view.position = Vector2(x, float(row_index) * SOURCE_LINE_HEIGHT)
			view.size = Vector2(3500.0 - x, SOURCE_LINE_HEIGHT)
			view.text = _tmp_plain_text(match.get_string(2))
			view.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			view.add_theme_font_size_override("font_size", 65)
			view.add_theme_color_override("font_color", SOURCE_GOLD)
			view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_names.add_child(view)
			item_index += 1
		row_index += 1


static func _tmp_to_bbcode(source: String) -> String:
	var regex := RegEx.new()
	regex.compile("<size=([0-9]+)%>")
	var out := ""
	var cursor := 0
	for match in regex.search_all(source):
		out += source.substr(cursor, match.get_start() - cursor)
		var font_size := roundi(80.0 * float(match.get_string(1)) / 100.0)
		out += "[font_size=%d]" % font_size
		cursor = match.get_end()
	out += source.substr(cursor)
	return out.replace("</size>", "[/font_size]")


static func _tmp_plain_text(source: String) -> String:
	# The raw list only uses TMP's font override for Japanese glyph coverage.
	# Godot cannot consume the TMP SDF asset, but the host font already covers
	# those glyphs; remove only the wrapper and retain the exact visible name.
	var regex := RegEx.new()
	regex.compile("<font=\"[^\"]+\">")
	return regex.sub(source, "", true).replace("</font>", "")
