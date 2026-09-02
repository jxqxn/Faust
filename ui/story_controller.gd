## Original StoryController quest panel.  Content stays as raw QuestNode
## dictionaries from content/quest.json; this controller only presents and
## invokes the source-shaped GlobalExtensions boundary.
## [SRC: StoryController.c @ OnEnable/OnItemClicked/OnRewardClicked/
##       OnRewardAllClicked/Sort/UpdateQuestRewardIcon
##       (RVA 0x5b0f70/0x5b1370/0x5b20b0/0x5b1d20/0x5b2370/0x5b2680);
##       StoryPanel.prefab; dump.cs:326466 StoryController]
class_name StoryController
extends Control

signal closed()

const GlobalExtensionsScript = preload("res://sim/global_extensions.gd")
const StoryItemControllerScript = preload("res://ui/story_item_controller.gd")
const StoryTargetItemControllerScript = preload("res://ui/story_target_item_controller.gd")
const DESIGN_SPACE := Vector2(3840, 2160)
const GROUP1_RECT := Rect2(180, 180, 1250, 1800)
const GROUP2_RECT := Rect2(1600, 280, 1440, 1600)
const SOURCE_ART := "res://assets/original/ui/"

var _db: ConfigDB
var _global: GlobalState
var _state = null
var _target_quest_id := 0
var _design: Control
var _list: VBoxContainer
var _targets: VBoxContainer
var _point_count: Label
var _quest_title: Label
var _quest_desc: Label
var _reward_count: Label
var _reward_button: TextureButton
var _reward_state: TextureRect
var _all_button: Button
var _rows: Dictionary = {}
var _selected: Dictionary = {}


func setup(config_db: ConfigDB, global_state: GlobalState, game_state = null, target_quest_id := 0) -> void:
	_db = config_db
	_global = global_state
	_state = game_state
	_target_quest_id = target_quest_id


func _ready() -> void:
	theme = FaustTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	GlobalExtensionsScript.refresh_quest(_global, _state, _db, false, false)
	_build_source_surface()
	populate()


func _build_source_surface() -> void:
	_design = Control.new()
	_design.name = "StoryPanel"
	_design.size = DESIGN_SPACE
	_design.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_design)
	resized.connect(_layout_design)
	call_deferred("_layout_design")

	var background := _texture_rect("Background", Rect2(Vector2.ZERO, DESIGN_SPACE), "bg_1.png")
	_design.add_child(background)
	_build_close()
	_build_group1()
	_build_group2()


func _layout_design() -> void:
	if _design == null:
		return
	var view_size := size
	if view_size.x <= 0 or view_size.y <= 0:
		view_size = get_viewport().get_visible_rect().size
	_design.scale = Vector2(view_size.x / DESIGN_SPACE.x, view_size.y / DESIGN_SPACE.y)


func _build_close() -> void:
	var close := TextureButton.new()
	close.name = "Close"
	close.position = Vector2(3718.2, 32.7)
	close.size = Vector2(80, 82)
	close.ignore_texture_size = true
	close.stretch_mode = TextureButton.STRETCH_SCALE
	close.texture_normal = _source_texture("checkbox_bg.png")
	close.pressed.connect(func(): closed.emit())
	_design.add_child(close)
	var x := _texture_rect("X", Rect2(18.5, 22.5, 43, 37), "close_2.png")
	close.add_child(x)


func _build_group1() -> void:
	var group := Control.new()
	group.name = "Group1"
	group.position = GROUP1_RECT.position
	group.size = GROUP1_RECT.size
	_design.add_child(group)

	var icon := _texture_rect("Icon", Rect2(0, 0, 131, 146), "icon.png")
	group.add_child(icon)
	var title := _label("Title", "一千零一夜", Rect2(151, 0, 650, 146), 80)
	group.add_child(title)
	var point_icon := _texture_rect("PointIcon", Rect2(980, 18, 103, 110), "point_0.png")
	group.add_child(point_icon)
	_point_count = _label("PointCount", "0", Rect2(1103, 0, 127, 146), 50)
	group.add_child(_point_count)
	var desc := _label("Desc", "根据提示完成一千零一夜的故事，可以获得命运点。", Rect2(0, 166, 1250, 100), 36)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	group.add_child(desc)

	var scroll := ScrollContainer.new()
	scroll.name = "QuestListNew"
	scroll.position = Vector2(0, 286)
	scroll.size = Vector2(1250, 1374)
	group.add_child(scroll)
	_list = VBoxContainer.new()
	_list.name = "Content"
	_list.custom_minimum_size = Vector2(1110, 0)
	_list.add_theme_constant_override("separation", 0)
	scroll.add_child(_list)

	_all_button = Button.new()
	_all_button.name = "All"
	_all_button.text = "全部领取"
	_all_button.position = Vector2(930, 1690)
	_all_button.size = Vector2(220, 96)
	_all_button.add_theme_font_size_override("font_size", 40)
	_all_button.icon = _source_texture("all_reward.png")
	_all_button.expand_icon = true
	_all_button.pressed.connect(reward_all)
	group.add_child(_all_button)


func _build_group2() -> void:
	var group := Control.new()
	group.name = "Group2"
	group.position = GROUP2_RECT.position
	group.size = GROUP2_RECT.size
	_design.add_child(group)

	var reward_bg := _texture_rect("RewardBG", Rect2(0, 336, 192, 264), "reward_bg.png")
	group.add_child(reward_bg)
	var reward_title := _label("Title", "奖励", Rect2(-4, -40, 200, 70), 60)
	reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_bg.add_child(reward_title)
	_reward_state = _texture_rect("State", Rect2(0, 0, 192, 264), "reward_point.png")
	reward_bg.add_child(_reward_state)
	_reward_count = _label("Text", "+0", Rect2(50, 164, 92, 50), 36)
	_reward_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_bg.add_child(_reward_count)
	_reward_button = TextureButton.new()
	_reward_button.name = "Reward"
	_reward_button.size = Vector2(192, 264)
	_reward_button.ignore_texture_size = true
	_reward_button.texture_normal = _source_texture("reward_bg1.png")
	_reward_button.pressed.connect(reward_selected)
	reward_bg.add_child(_reward_button)
	var reward_copy := _label("Text", "领取", Rect2(20, 172, 152, 60), 40)
	reward_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward_button.add_child(reward_copy)

	_quest_title = _label("QuestTitle", "", Rect2(250, 300, 1150, 90), 60)
	group.add_child(_quest_title)
	_quest_desc = _label("QuestDesc", "", Rect2(250, 400, 1150, 200), 36)
	_quest_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	group.add_child(_quest_desc)
	group.add_child(_texture_rect("Seperator", Rect2(0, 630, 1440, 30), "slash.png"))

	var target_scroll := ScrollContainer.new()
	target_scroll.name = "Targets"
	target_scroll.position = Vector2(0, 710)
	target_scroll.size = Vector2(1440, 870)
	group.add_child(target_scroll)
	_targets = VBoxContainer.new()
	_targets.name = "Content"
	_targets.add_theme_constant_override("separation", 0)
	target_scroll.add_child(_targets)


func populate() -> void:
	if _db == null or _global == null or _list == null:
		return
	_rows.clear()
	for child in _list.get_children():
		child.queue_free()
	var quests: Array[Dictionary] = []
	for raw in _db.quests.values():
		quests.append(raw as Dictionary)
	quests.sort_custom(func(a: Dictionary, b: Dictionary):
		var av := source_sort_value(a, false)
		var bv := source_sort_value(b, false)
		return av < bv or (av == bv and int(a.get("id", 0)) < int(b.get("id", 0))))
	for quest in quests:
		var row = StoryItemControllerScript.new()
		row.setup(quest)
		row.quest_selected.connect(select_quest)
		row.reward_requested.connect(func(value: Dictionary):
			select_quest(value)
			reward_selected())
		_list.add_child(row)
		_rows[int(quest.get("id", 0))] = row
	_point_count.text = str(_global.total_point)
	_all_button.disabled = not _global.has_quest_reward
	var initial := _db.get_quest(_target_quest_id)
	if initial.is_empty() and not quests.is_empty():
		initial = quests[0]
	select_quest(initial)


func select_quest(quest: Dictionary) -> void:
	if quest.is_empty():
		return
	_selected = quest
	for quest_id in _rows:
		_rows[quest_id].set_selected(int(quest_id) == int(quest.get("id", 0)))
	_quest_title.text = str(quest.get("name", ""))
	_quest_desc.text = str(quest.get("favour_text", ""))
	_reward_count.text = "+%d" % int(quest.get("upgrade_point", 0))
	_update_reward_state()
	for child in _targets.get_children():
		child.queue_free()
	for raw_target in quest.get("target", []):
		var target_row = StoryTargetItemControllerScript.new()
		target_row.setup(raw_target as Dictionary)
		_targets.add_child(target_row)


func reward_selected() -> bool:
	if _selected.is_empty():
		return false
	var quest_id := int(_selected.get("id", 0))
	var claimed := GlobalExtensionsScript.get_quest_reward(_global, quest_id, _db)
	if claimed:
		_point_count.text = str(_global.total_point)
		_rows[quest_id].update_state()
		_all_button.disabled = not _global.has_quest_reward
		_update_reward_state()
	return claimed


func reward_all() -> int:
	var received_points := 0
	for raw in _db.quests.values():
		var quest := raw as Dictionary
		if bool(quest.get("isComplete", false)) and not bool(quest.get("isReceived", false)):
			if GlobalExtensionsScript.get_quest_reward(_global, int(quest.get("id", 0)), _db):
				received_points += int(quest.get("upgrade_point", 0))
	for row in _rows.values():
		row.update_state()
	_point_count.text = str(_global.total_point)
	_all_button.disabled = not _global.has_quest_reward
	_update_reward_state()
	return received_points


func _update_reward_state() -> void:
	var complete := bool(_selected.get("isComplete", false))
	var received := bool(_selected.get("isReceived", false))
	_reward_button.visible = complete and not received
	_reward_state.texture = _source_texture("reward_point_1.png" if received else "reward_point.png")
	_reward_state.modulate = Color.WHITE if complete else Color(0.45, 0.45, 0.45, 1)


## Exact tri-state keys used by StoryController.Sort.
static func source_sort_value(quest: Dictionary, inverse: bool) -> int:
	var complete := bool(quest.get("isComplete", false))
	var received := bool(quest.get("isReceived", false))
	if inverse:
		return 1 if complete and received else (2 if complete else 3)
	return 1 if complete and not received else (3 if complete else 2)


func _label(node_name: String, copy: String, rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = copy
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _texture_rect(node_name: String, rect: Rect2, texture_name: String) -> TextureRect:
	var view := TextureRect.new()
	view.name = node_name
	view.position = rect.position
	view.size = rect.size
	view.texture = _source_texture(texture_name)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


func _source_texture(texture_name: String) -> Texture2D:
	var path := SOURCE_ART + texture_name
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
