## Historical ending list, mapped to the original OverRecordController.
## [SRC: OverRecordController.OnEnable 0x57d9a0 / DeleteOverNode 0x57d640 /
##       UpdateCountNumber 0x57e650; GalleryPanelNew/Over Record prefab.]
class_name OverRecordView
extends Control

const OverNodeViewScript = preload("res://ui/over_node_view.gd")
const PANEL_SIZE := Vector2(2500, 1960)
const ROW_SIZE := Vector2(2301, 360)
const TOP_PADDING := 115.0
const ROW_SPACING := 15.0
const OVER_CONFIG_PATH := "res://content/over.json"

signal count_changed(current: int, maximum: int)
signal memory_requested(over_data: Dictionary)

var _store: OverRecordStore
var _global_state: GlobalState
var _over_definitions: Dictionary = {}
var _scroll: ScrollContainer
var _content: VBoxContainer
var _records: Array[Dictionary] = []


func setup(store: OverRecordStore, global_state: GlobalState = null) -> void:
	_store = store
	_global_state = global_state


func _ready() -> void:
	name = "OverRecordController"
	size = PANEL_SIZE
	_load_definitions()
	_build_surface()
	refresh()


func _build_surface() -> void:
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll View"
	_scroll.size = PANEL_SIZE
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.custom_minimum_size = Vector2(2301, TOP_PADDING)
	_content.add_theme_constant_override("separation", int(ROW_SPACING))
	_scroll.add_child(_content)
	var spacer := Control.new()
	spacer.name = "TopPadding"
	spacer.custom_minimum_size = Vector2(2301, TOP_PADDING)
	_content.add_child(spacer)


func refresh() -> void:
	if _store == null or _content == null:
		return
	_store.init_over_record(_global_state)
	_records = _store.load_indexed_records()
	for child in _content.get_children():
		if child.name != "TopPadding":
			child.queue_free()
	for record in _records:
		var node := OverNodeViewScript.new()
		node.setup(str(record.get("dataFileName", "")), record.get("overData", {}) as Dictionary, _over_definitions)
		node.custom_minimum_size = ROW_SIZE
		node.delete_requested.connect(_delete_over_node)
		node.memory_requested.connect(func(over_data: Dictionary): memory_requested.emit(over_data))
		_content.add_child(node)
	count_changed.emit(_records.size(), OverRecordStore.MAX_VISIBLE_RECORDS)


func record_count() -> int:
	return _records.size()


func _delete_over_node(file_name: String) -> void:
	# The store updates the excerpt and deletes the exact per-record file;
	# the controller then rebuilds its datasource and count label.
	_store.delete_over_record(file_name)
	refresh()


func _load_definitions() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(OVER_CONFIG_PATH))
	_over_definitions = parsed as Dictionary if parsed is Dictionary else {}
