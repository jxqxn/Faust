extends GutTest

const CORPUS_GLOBAL := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/global.json"
const TEST_ROOT := "user://test_over_record_store"


func before_each() -> void:
	_cleanup()


func after_each() -> void:
	_cleanup()


func test_original_global_sample_migrates_to_empty_excerpt() -> void:
	if not FileAccess.file_exists(CORPUS_GLOBAL):
		pending("corpus global sample not available; skipping")
		return
	var original := JSON.parse_string(FileAccess.get_file_as_string(CORPUS_GLOBAL)) as Dictionary
	assert_eq(original.get("overRecord", []), [], "the original sample is the empty archive judge")
	var global := GlobalState.load_from(CORPUS_GLOBAL)
	var store := OverRecordStore.new(TEST_ROOT)
	store.init_over_record(global)
	assert_eq(store.excerpt["overRecordCount"], 0)
	assert_eq(store.excerpt["overRecordNameList"], [])
	assert_eq(store.load_indexed_records(), [])
	assert_true(FileAccess.file_exists(TEST_ROOT + "/over_record_excerpt.json"), "InitOverRecord writes the source excerpt artifact")


func test_on_enable_order_and_missing_file_pruning_follow_excerpt() -> void:
	var store := OverRecordStore.new(TEST_ROOT)
	store.excerpt = {
		"overRecordCount": 2,
		"overRecordNameList": ["over_record_No.0", "missing", "over_record_No.1"],
		"overRecordNameListExcess": [],
	}
	OverRecordStore._write_json(store.get_over_record_file_name("over_record_No.0"), {"id": 10, "time": "first"})
	OverRecordStore._write_json(store.get_over_record_file_name("over_record_No.1"), {"id": 20, "time": "second"})
	var records := store.load_indexed_records()
	assert_eq(records.size(), 2)
	assert_eq(records[0]["dataFileName"], "over_record_No.0", "OnEnable preserves excerpt order")
	assert_eq(int(records[1]["overData"]["id"]), 20)
	assert_eq(store.excerpt["overRecordNameList"], ["over_record_No.0", "over_record_No.1"], "unreadable file is removed at the current list index")


func test_legacy_global_records_use_source_file_names_and_newest_first() -> void:
	var global := GlobalState.new()
	global.over_records = [{"id": 1, "time": "old"}, {"id": 2, "time": "new"}]
	var store := OverRecordStore.new(TEST_ROOT)
	store.init_over_record(global)
	assert_eq(global.over_records, [], "InitOverRecord clears legacy Global.overRecord after migration")
	assert_eq(store.excerpt["overRecordCount"], 2)
	assert_eq(store.excerpt["overRecordNameList"], ["over_record_No.1", "over_record_No.0"])
	assert_eq(int(store.load_indexed_records()[0]["overData"]["id"]), 2)


func test_delete_removes_record_file_and_excerpt_name() -> void:
	var store := OverRecordStore.new(TEST_ROOT)
	store.load_over_record_excerpt()
	var file_name := store.add_over_record({"id": 7, "time": "now"})
	var path := store.get_over_record_file_name(file_name)
	assert_true(FileAccess.file_exists(path))
	assert_true(store.delete_over_record(file_name))
	assert_false(FileAccess.file_exists(path))
	assert_eq(store.excerpt["overRecordNameList"], [])


func test_default_user_root_keeps_godot_scheme_separator() -> void:
	var store := OverRecordStore.new()
	assert_eq(store.get_over_record_file_name("over_record_No.3"), "user://OVERRECORDDATA/over_record_No.3.json")


func _cleanup() -> void:
	var absolute := ProjectSettings.globalize_path(TEST_ROOT)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var dir := DirAccess.open(absolute)
	if dir != null:
		dir.list_dir_begin()
		var name := dir.get_next()
		while name != "":
			var path := absolute.path_join(name)
			if dir.current_is_dir():
				var nested := DirAccess.open(path)
				if nested != null:
					nested.list_dir_begin()
					var nested_name := nested.get_next()
					while nested_name != "":
						var nested_path := path.path_join(nested_name)
						if nested.current_is_dir():
							var deep := DirAccess.open(nested_path)
							if deep != null:
								for file_name in deep.get_files():
									DirAccess.remove_absolute(nested_path.path_join(file_name))
							DirAccess.remove_absolute(nested_path)
						else:
							DirAccess.remove_absolute(nested_path)
						nested_name = nested.get_next()
				DirAccess.remove_absolute(path)
			else:
				DirAccess.remove_absolute(path)
			name = dir.get_next()
	DirAccess.remove_absolute(absolute)
