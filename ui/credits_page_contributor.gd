## Original contributor page: two ContributorGroup records per internal page.
## [SRC: CreditsPageContributor.c @ Show/set_Position/Next/Previous/HasNext
##       (RVA 0x3f7a30/0x3f7bb0/0x3f79a0/0x3f7a10/0x3f7b50)]
class_name CreditsPageContributor
extends "res://ui/credits_page.gd"

const GroupView = preload("res://ui/credits_group.gd")
const PAGE_SIZE := 2

var _contributor: Dictionary = {}
var _layout: Control


func show_data(data: Variant, pos: int) -> void:
	super.show_data(data, pos)
	_contributor = data as Dictionary
	setup_page(str(_contributor.get("title", "")), str(_contributor.get("type", "helper")))
	if _layout == null:
		_layout = Control.new()
		_layout.name = "Layouts"
		_layout.position = Vector2(170, 470)
		_layout.size = Vector2(3500, 1300)
		add_child(_layout)
	set_page_position(pos)


func set_page_position(value: int) -> void:
	page_position = maxi(0, value)
	for child in _layout.get_children():
		child.queue_free()
	var groups: Array = _contributor.get("group", [])
	for slot in range(PAGE_SIZE):
		var index := page_position + slot
		if index >= groups.size():
			break
		var view = GroupView.new()
		view.name = "Group%d" % index
		view.position = Vector2(slot * 1750 + 175, 0)
		view.setup(groups[index])
		_layout.add_child(view)


func has_previous() -> bool:
	return page_position > 0


func has_next() -> bool:
	return page_position + PAGE_SIZE < int((_contributor.get("group", []) as Array).size())


func previous() -> void:
	if has_previous():
		set_page_position(page_position - PAGE_SIZE)


func next() -> void:
	if has_next():
		set_page_position(page_position + PAGE_SIZE)
