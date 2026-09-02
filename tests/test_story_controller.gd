extends GutTest

const GlobalExtensionsScript = preload("res://sim/global_extensions.gd")
const StoryControllerScript = preload("res://ui/story_controller.gd")

var db: ConfigDB


func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_get_quest_reward_replays_source_guard_state_points_and_flag() -> void:
	var global := GlobalState.new()
	var first := db.get_quest(3300001)
	var second := db.get_quest(3300004)
	first["isComplete"] = true
	first["isReceived"] = false
	second["isComplete"] = true
	second["isReceived"] = false
	global.quests = {3300001: 1, 3300004: 1}
	global.set_has_quest_reward(true)

	assert_true(GlobalExtensionsScript.get_quest_reward(global, 3300001, db))
	assert_eq(int(global.quests[3300001]), 2, "Global.quest state 2 means received")
	assert_true(bool(first.get("isReceived", false)))
	assert_eq(global.total_point, int(first.get("upgrade_point", 0)))
	assert_true(global.has_quest_reward, "the other completed quest keeps the global reward flag")
	assert_false(GlobalExtensionsScript.get_quest_reward(global, 3300001, db), "a reward cannot be claimed twice")

	assert_true(GlobalExtensionsScript.get_quest_reward(global, 3300004, db))
	assert_false(global.has_quest_reward, "the source recount clears HasQuestReward after the final claim")
	assert_false(GlobalExtensionsScript.get_quest_reward(global, 9999999, db), "an absent QuestNode is rejected")


func test_story_sort_replays_source_three_state_keys() -> void:
	var unreceived := {"isComplete": true, "isReceived": false}
	var unfinished := {"isComplete": false, "isReceived": false}
	var received := {"isComplete": true, "isReceived": true}
	assert_eq(StoryControllerScript.source_sort_value(unreceived, false), 1)
	assert_eq(StoryControllerScript.source_sort_value(unfinished, false), 2)
	assert_eq(StoryControllerScript.source_sort_value(received, false), 3)
	assert_eq(StoryControllerScript.source_sort_value(received, true), 1)
	assert_eq(StoryControllerScript.source_sort_value(unreceived, true), 2)
	assert_eq(StoryControllerScript.source_sort_value(unfinished, true), 3)


func test_story_panel_replays_prefab_geometry_target_and_reward_all() -> void:
	var state := GameState.new()
	var global := GlobalState.new()
	state.global_state = global
	state.global_counters = global.counters
	# StoryController.OnEnable calls RefreshQuest before drawing.  Satisfy the
	# two raw QuestNode conditions instead of fabricating their derived flags.
	global.counters = {7220001: 1, 7220002: 1}
	state.global_counters = global.counters

	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	add_child_autofree(stage)
	var story = StoryControllerScript.new()
	story.setup(db, global, state, 3300004)
	stage.add_child(story)
	await wait_process_frames(2)

	assert_eq((story.get_node("StoryPanel/Close") as Control).position, Vector2(3718.2, 32.7))
	assert_eq((story.get_node("StoryPanel/Close") as Control).size, Vector2(80, 82))
	assert_eq((story.get_node("StoryPanel/Group1") as Control).position, Vector2(180, 180))
	assert_eq((story.get_node("StoryPanel/Group1") as Control).size, Vector2(1250, 1800))
	assert_eq((story.get_node("StoryPanel/Group2") as Control).position, Vector2(1600, 280))
	assert_eq((story.get_node("StoryPanel/Group2") as Control).size, Vector2(1440, 1600))
	assert_eq((story.get_node("StoryPanel/Group2/QuestTitle") as Label).text, "幸存者", "StoryController.Target selects the clicked notification quest")
	var target_row := story.get_node("StoryPanel/Group2/Targets/Content").get_child(0)
	assert_eq((target_row.get_node("State") as Control).position, Vector2(32, 11.5), "HorizontalLayoutGroup geometry is resolved from the prefab")
	assert_eq((target_row.get_node("Text") as Control).position, Vector2(120, 0))
	assert_true((target_row.get_node("State") as TextureRect).texture.resource_path.ends_with("finish.png"), "StoryTargetItemController uses the prefab Finish sprite")
	assert_eq((target_row.get_node("Text") as RichTextLabel).get_parsed_text().strip_edges(), "在苏丹的游戏中取得1次胜利", "completed target uses the original variable.json format")
	assert_eq(story.reward_all(), 2, "OnRewardAllClicked sums the original per-quest upgrade points")
	assert_eq(global.total_point, 2)
	assert_eq(int(global.quests[3300001]), 2)
	assert_eq(int(global.quests[3300004]), 2)
	assert_false(global.has_quest_reward)
