extends GutTest

const CORPUS_QUEST := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/data/config/quest.json"
const GlobalExtensionsScript = preload("res://sim/global_extensions.gd")
const ResultExecScript = preload("res://sim/result.gd")
const StoryNotifyControllerScript = preload("res://ui/story_notify_controller.gd")

var db: ConfigDB


func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_quest_config_is_loaded_without_translation() -> void:
	assert_gt(db.quests.size(), 0)
	assert_eq(db.get_quest(3300001).get("name", ""), "坠落的初端")
	if FileAccess.file_exists(CORPUS_QUEST):
		assert_true(
			FileAccess.get_file_as_bytes("res://content/quest.json")
			== FileAccess.get_file_as_bytes(CORPUS_QUEST),
			"content/quest.json remains byte-identical to the original config"
		)


func test_refresh_quest_replays_source_state_and_transition_notification() -> void:
	var state := GameState.new()
	var global := GlobalState.new()
	state.global_state = global
	state.global_counters = global.counters
	var notified: Array[int] = []
	global.quest_completed.connect(func(quest: Dictionary): notified.append(int(quest.get("id", 0))))
	ResultExecScript.execute({"global_counter+7220001": 1}, state, db)
	assert_true(global.quests.has(3300001), "a complete unreceived quest enters Global.quest")
	assert_eq(int(global.quests[3300001]), 1, "state 1 means completed and unreceived")
	assert_true(bool(db.get_quest(3300001).get("isComplete", false)))
	assert_true(global.has_quest_reward)
	assert_true(3300001 in notified, "only the false-to-true transition raises OnQuestCompleted")

	notified.clear()
	GlobalExtensionsScript.refresh_quest(global, state, db, true, false)
	assert_false(3300001 in notified, "an already-complete quest does not replay its notification")

	ResultExecScript.execute({"global_counter=7220001": 0}, state, db)
	assert_false(global.quests.has(3300001), "an incomplete quest is removed like Dictionary.Remove")
	assert_false(bool(db.get_quest(3300001).get("isComplete", true)))


func test_story_notify_replays_prefab_geometry_and_fifo() -> void:
	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	add_child_autofree(stage)
	var global := GlobalState.new()
	var notify = StoryNotifyControllerScript.new()
	notify.setup(global)
	stage.add_child(notify)
	await wait_process_frames(2)
	notify.apply_source_layout(stage.size)
	var first := {"id": 3300001, "name": "坠落的初端", "upgrade_point": 1}
	var second := {"id": 3300004, "name": "幸存者", "upgrade_point": 2}
	global.notify_quest_completed(first)
	global.notify_quest_completed(second)
	assert_eq(notify.size, Vector2(630, 444), "StoryNotify.prefab root is 630x444")
	assert_eq(notify.position.x, 1605.0, "top notification is horizontally centred on 3840")
	assert_eq((notify.get_node("Title") as Label).position, Vector2(15, 73))
	assert_eq((notify.get_node("Icon") as TextureRect).position, Vector2(193.5, 207))
	assert_eq((notify.get_node("PointCount") as Label).position, Vector2(316.5, 237))
	assert_eq((notify.get_node("PointCount") as Label).text, "+1")
	assert_eq(notify.waiting_queue.size(), 1, "Show enqueues while Animation.isPlaying")
	notify.complete_animation_for_test()
	assert_eq(int(notify.current.get("id", 0)), 3300004, "OnAnimationDone dequeues FIFO")
	assert_eq((notify.get_node("PointCount") as Label).text, "+2")


func test_global_quest_fields_round_trip_with_source_keys() -> void:
	var global := GlobalState.new()
	global._apply_dict({"upgrade": {"3400001": 2}, "version": "source-version"})
	global.total_point = 7
	global.used_point = 2
	global.quest_state = "source-state"
	global.quests = {3300001: 1, 3300004: 2}
	global.counters = {7220001: 3}
	global.has_enter_quest = true
	var restored := GlobalState.new()
	restored._apply_dict(global.to_dict())
	assert_eq(restored.total_point, 7)
	assert_eq(restored.used_point, 2)
	assert_eq(restored.quest_state, "source-state")
	assert_eq(restored.quests, global.quests)
	assert_eq(restored.counters, global.counters)
	assert_true(restored.has_enter_quest)
	assert_eq(restored.to_dict().get("upgrade", {}), {"3400001": 2}, "unmigrated source fields survive Global saves")
	assert_eq(restored.to_dict().get("version", ""), "source-version")
