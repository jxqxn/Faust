extends GutTest

const Icons = preload("res://ui/source_prompt_icons.gd")
var db: ConfigDB

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func test_scalar_middle_and_outer_slot_order() -> void:
	var single := Icons.resolve("cards/2000001", null, db)
	assert_null(single.slots[0])
	assert_not_null(single.slots[1].texture)
	assert_null(single.slots[2])
	var source: Array = db.get_event(5300000).settlement[0].action.confirm.icon
	var intro := Icons.resolve(source, null, db)
	assert_eq(intro.slots[1].resource, "common/introduction")
	assert_not_null(intro.slots[1].texture)
	assert_null(intro.slots[0].texture)

func test_card_fan_indices_are_not_compacted_by_zero() -> void:
	var one := Icons.resolve([[2000001]], null, db)
	assert_eq(one.slots[0].cards[0].pose, Vector2(430, 10))
	var two := Icons.resolve([[0, 2000001]], null, db)
	assert_eq(two.slots[0].cards.size(), 1)
	assert_eq(two.slots[0].cards[0].pose, Vector2(580, 2))
	var three := Icons.resolve([[2000001, 0, 2000001, 2000001]], null, db)
	assert_eq(three.slots[0].cards.size(), 2)
	assert_eq(three.slots[0].cards[0].pose, Vector2(280, 18))
	assert_eq(three.slots[0].cards[1].pose, Vector2(580, 2))

func test_pic_uses_card_resource_and_clear_removes_generated_views() -> void:
	var data := Icons.resolve("pic/2000001", null, db)
	assert_eq(data.slots[1].resource, str(db.get_card(2000001).resource[0]))
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(614))
	var uid := state.card_uid_for(2000001)
	state.get_card_instance(uid).tags["pic"] = 2
	var current := Icons.resolve("pic/2000001", state, db)
	assert_eq(current.slots[1].resource, str(db.get_card(2000001).resource[2]))
	state.hand.erase(uid)
	state.get_card_instance(uid).zone = "consumed"
	var detached := Icons.resolve("pic/2000001", state, db)
	assert_eq(detached.slots[1].resource, str(db.get_card(2000001).resource[0]), "detached registry entries do not override config art")
	var view = preload("res://ui/event_prompt_view.gd").new()
	add_child_autofree(view)
	view.show_prompt({"text": "Cards", "resolved_icons": Icons.resolve([[2000001, 2000001]], null, db)}, Callable())
	await wait_process_frames(3)
	var slot: Control = view.find_child("PromptIconSlot1", true, false)
	assert_eq(slot.get_child_count(), 2)
	assert_almost_eq(slot.get_child(0).rotation_degrees, -2.0, 0.001)
	assert_almost_eq(slot.get_child(1).rotation_degrees, -10.0, 0.001)
	assert_eq(slot.get_child(0).scale, Vector2.ONE * 1.8)
	view.show_prompt({"text": "Empty", "resolved_icons": Icons.resolve(null, null, db)}, Callable())
	await wait_process_frames(3)
	assert_eq(slot.get_child_count(), 0)
	assert_null(view._portrait.texture)
