extends GutTest

const GalleryPanel = preload("res://ui/gallery_panel.gd")
const TEST_ROOT := "user://test_over_record_ui"

var db: ConfigDB


func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()


func before_each() -> void:
	_cleanup()


func after_each() -> void:
	_cleanup()


func test_gallery_over_record_replays_source_index_row_and_delete_chain() -> void:
	var store := OverRecordStore.new(TEST_ROOT)
	store.load_over_record_excerpt()
	var file_name := store.add_over_record({
		"id": 273,
		"char_cards": [],
		"player_data": null,
		"after_storys": [],
		"time": "2026-08-27T20:00:00",
	})
	assert_eq(file_name, "over_record_No.0", "AddOverRecord uses the source string literal")

	var stage := Control.new()
	stage.size = Vector2(1152, 648)
	add_child_autofree(stage)
	var gallery := GalleryPanel.new()
	gallery.setup(db, GlobalState.new(), store)
	stage.add_child(gallery)
	await wait_process_frames(3)

	var memory_tab := _find_node_by_name(gallery, "OverMemoryTab") as Button
	var over_view := _find_node_by_name(gallery, "OverRecordController") as Control
	var content := over_view.get_node_or_null("Scroll View/Content") as VBoxContainer if over_view != null else null
	var row := content.get_child(1) as Control if content != null and content.get_child_count() > 1 else null
	assert_not_null(memory_tab)
	assert_not_null(over_view)
	assert_not_null(row)
	if memory_tab != null:
		assert_eq(memory_tab.text, "历史画廊 (1/200)", "UpdateCountNumber uses GALLERY_OVER_BTN_MEMORY")
	if over_view != null:
		assert_eq(Rect2(over_view.position, over_view.size), Rect2(0, 100, 2500, 1960), "Over Record resolves its authored right-stretch panel")
	if row == null:
		return
	assert_eq(row.size, Vector2(2301, 360), "OverNode keeps the source prefab rectangle")
	var record := row.get_node_or_null("Record") as Button
	var delete := row.get_node_or_null("Delete") as Button
	var title := row.get_node_or_null("TitleGroup/Title") as Label
	var victory := row.get_node_or_null("NomalIcon/VictoryIcon") as TextureRect
	var success := row.get_node_or_null("NomalIcon/Success") as Label
	var dead := row.get_node_or_null("NomalIcon/Dead") as Label
	assert_not_null(record)
	assert_not_null(delete)
	assert_not_null(title)
	assert_not_null(victory)
	if record != null:
		assert_eq(Rect2(record.position, record.size), Rect2(1723, 104.82, 324, 140), "Record button resolves Unity anchors/pivot")
	if delete != null:
		assert_eq(Rect2(delete.position, delete.size), Rect2(2110.61, 95.82, 168, 158), "Delete button resolves Unity anchors/pivot")
	if title != null:
		assert_eq(title.text, "君权神授", "OverNodeController reads OverNode.name directly")
	if victory != null and success != null and dead != null:
		assert_true(victory.visible, "OverNode.success == 2 enables VictoryIcon")
		assert_true(success.visible)
		assert_false(dead.visible)

	delete.pressed.emit()
	var confirm := row.get_node_or_null("DeleteConfirm") as Button
	assert_not_null(confirm)
	if confirm != null:
		assert_true(confirm.visible)
		confirm.pressed.emit()
		await wait_process_frames(3)
		assert_false(FileAccess.file_exists(store.get_over_record_file_name(file_name)), "DeleteOverRecord removes the original record artifact")
		assert_eq(memory_tab.text, "历史画廊 (0/200)")


func test_over_node_assets_are_bounded_corpus_copies() -> void:
	for file_name in ["repeat.png", "delete.png", "fail.png", "great_victory.png", "slash.png", "hightlight.png"]:
		assert_true(ResourceLoader.exists("res://assets/original/ui/%s" % file_name), "%s resolves directly" % file_name)


func _find_node_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target)
		if found != null:
			return found
	return null


func _cleanup() -> void:
	var excerpt := TEST_ROOT + "/over_record_excerpt.json"
	var record := TEST_ROOT + "/OVERRECORDDATA/over_record_No.0.json"
	if FileAccess.file_exists(record):
		DirAccess.remove_absolute(record)
	if FileAccess.file_exists(excerpt):
		DirAccess.remove_absolute(excerpt)
	DirAccess.remove_absolute(TEST_ROOT + "/OVERRECORDDATA/EXCESSDATA")
	DirAccess.remove_absolute(TEST_ROOT + "/OVERRECORDDATA")
	DirAccess.remove_absolute(TEST_ROOT)
