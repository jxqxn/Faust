extends GutTest

const GalleryPanel = preload("res://ui/gallery_panel.gd")
const RNG = preload("res://core/rng.gd")
const TEST_ROOT := "user://test_over_record_ui"
const CORPUS_AUTO_SAVE := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"

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


func test_memory_click_loads_original_player_artifact_and_record_flow_closes_to_gallery() -> void:
	assert_true(FileAccess.file_exists(CORPUS_AUTO_SAVE), "the original product save is the differential judge")
	if not FileAccess.file_exists(CORPUS_AUTO_SAVE):
		return
	var original = JSON.parse_string(FileAccess.get_file_as_string(CORPUS_AUTO_SAVE))
	assert_true(original is Dictionary)
	if not (original is Dictionary):
		return
	var store := OverRecordStore.new(TEST_ROOT)
	store.load_over_record_excerpt()
	store.add_over_record({
		"id": 273,
		"char_cards": [],
		"player_data": original,
		"after_storys": [],
		"time": "2026-08-28T12:00:00",
	})
	var stage := Control.new()
	stage.size = Vector2(1152, 648)
	add_child_autofree(stage)
	var gallery := GalleryPanel.new()
	gallery.setup(db, GlobalState.new(), store)
	stage.add_child(gallery)
	await wait_process_frames(3)

	var record := _find_node_by_name(gallery, "Record") as Button
	assert_not_null(record)
	if record == null:
		return
	record.pressed.emit()
	await wait_process_frames(3)
	var host := _find_node_by_name(gallery, "OverInfoContainer") as Control
	var over := host.get_node_or_null("Over") as Control if host != null else null
	assert_not_null(host)
	assert_not_null(over)
	if host == null or over == null:
		return
	assert_true(host.visible)
	assert_true(bool(over.get_meta("is_record", false)), "SetRecord marks the replay controller before Init")
	assert_eq(over.scale, Vector2.ONE, "OverNewPanel inherits GalleryPanelNew's single source-canvas scale")
	var report := over.get_meta("load_report", {}) as Dictionary
	var failed: Array = []
	for row in report.get("diff", []):
		if row is Dictionary and not bool(row.get("pass", false)):
			failed.append(row)
	assert_eq(failed, [], "LoadPlayerOverData passes the original save field differential")

	over.do_next()
	assert_not_null(over.get_node_or_null("Step2/CG"))
	over.do_next()
	assert_not_null(over.get_node_or_null("Step2-Story/Story View/Viewport/Content/Story"), "text_extra, not a clone story key, gates the story stage")
	over.do_next()
	var story_controller := over.get_node_or_null("Step2-Story") as OverNewStep2StoryControllerView
	assert_not_null(story_controller)
	if story_controller != null and story_controller.has_after_story_items():
		assert_true((story_controller.get_node("After Story") as Control).visible)
	over.do_next()
	await wait_process_frames(2)
	assert_false(host.visible, "record Hide returns to GalleryPanelNew instead of showing Step3")
	assert_eq(host.get_child_count(), 0)


func test_recorded_after_story_keys_replay_exact_source_settlements_and_sort_order() -> void:
	var state := GameState.new()
	var over = preload("res://ui/game_over.gd").new()
	over.setup_record(state, db, {
		"id": 273,
		"player_data": null,
		"char_cards": [],
		"after_storys": [{
			"card_id": 2000001,
			"pic": "cards/2000001",
			"prior": "",
			"extra": ["2000001_extra_1", "2000001_extra_12"],
		}],
	})
	var stage := Control.new()
	stage.size = Vector2(1152, 648)
	add_child_autofree(stage)
	stage.add_child(over)
	await wait_process_frames(2)
	over.do_next()
	over.do_next()
	var controller := over.get_node_or_null("Step2-Story") as OverNewStep2StoryControllerView
	assert_not_null(controller)
	if controller == null:
		return
	assert_eq(controller.item_count(), 2, "AfterStoryData.extra is a set of original settlement keys")
	var content := controller.get_node("After Story/Viewport/Content") as Control
	assert_eq(content.get_child(0).sort_index, 3, "items sort by Settlement.sort before card_id")
	assert_eq(content.get_child(1).sort_index, 99)
	assert_true(str(content.get_child(0).content).contains("歌谣"), "the item reads result_text directly from content/after_story")
	over.do_next()
	assert_true((controller.get_node("After Story") as Control).visible)


func test_live_after_story_conditions_bind_the_matching_runtime_card() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(81))
	var controller := OverNewStep2StoryControllerView.new()
	controller.setup({}, state, db, {}, "")
	var ctx: Dictionary = controller._runtime_condition_context(2000001)
	assert_gt(int(ctx.get("card_uid", 0)), 0, "the source AfterStoryNode is evaluated around its matching total-card instance")
	assert_eq(int(ctx.get("acting_card_id", 0)), 2000001)
	assert_true(ConditionEval.evaluate({"self.主角": 1}, ctx), "self tag conditions read the matching runtime card")
	assert_true(ConditionEval.evaluate({"type": "char", "rare": 3}, ctx), "type/rare conditions share the same card context")
	assert_eq(controller._runtime_pic(2000001, db.get_after_story(2000001)), "cards/2000001", "resource arrays resolve to the active source image instead of an array string")
	controller.free()


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
