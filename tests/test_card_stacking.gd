extends GutTest

## Card stack gestures, source-backed:
## [SRC: CardController.CardSplit 0x528390 / CardController.CardStack 0x5286b0;
##       CardDropManager.DropCard routes hand targets to CardStack and occupied
##       slots to CardSlotController.CardStack.]

const RNG = preload("res://core/rng.gd")

const COIN_ID := 2000029  # 金币, type item, tag 可堆叠
const CHARACTER_ID := 2000006  # 梅姬, not stackable

var db: ConfigDB


func before_all():
	db = ConfigDB.new()
	db.load_all()


func _state() -> GameState:
	var rng := RNG.new(7301)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.hand.clear()
	state.rail_order.clear()
	return state


func test_split_card_stack_halves_the_count_and_copies_bag_state() -> void:
	var state := _state()
	var uid := int(state.add_card_to_hand(COIN_ID, db))
	var coin = state.get_card_instance(uid)
	coin.count = 8
	coin.bag = 2
	coin.bag_pos = 3

	var copy_uid := state.split_card_stack(uid)
	assert_gt(copy_uid, 0, "CardSplit returns the new card")
	assert_eq(int(coin.count), 4, "the source keeps count-n")
	var copy = state.get_card_instance(copy_uid)
	assert_not_null(copy)
	assert_eq(int(copy.card_id), COIN_ID)
	assert_eq(int(copy.count), 4, "the copy takes n")
	assert_eq(int(copy.bag), 2, "CardExtensions.Copy keeps bag")
	assert_eq(int(copy.bag_pos), 3, "and bagpos")
	assert_eq(str(copy.zone), "hand", "BackToHandOrBag returns it to the hand")
	assert_true(copy_uid in state.hand)
	assert_true(copy_uid in state.rail_order)


func test_split_card_stack_requires_count_above_n() -> void:
	var state := _state()
	var uid := int(state.add_card_to_hand(COIN_ID, db))
	var coin = state.get_card_instance(uid)
	coin.count = 1
	assert_eq(state.split_card_stack(uid), 0, "a single card cannot split")
	coin.count = 2
	assert_eq(state.split_card_stack(uid, 2), 0, "n must stay below count")
	var copy_uid := state.split_card_stack(uid, 1)
	assert_gt(copy_uid, 0, "a count-2 stack can split off 1")
	assert_eq(int(coin.count), 1)
	assert_eq(int(state.get_card_instance(copy_uid).count), 1)


func test_split_card_stack_explicit_amount() -> void:
	var state := _state()
	var uid := int(state.add_card_to_hand(COIN_ID, db))
	state.get_card_instance(uid).count = 10
	var copy_uid := state.split_card_stack(uid, 3)
	assert_gt(copy_uid, 0)
	assert_eq(int(state.get_card_instance(uid).count), 7)
	assert_eq(int(state.get_card_instance(copy_uid).count), 3)


func test_stack_cards_merges_same_id_stackables_and_removes_the_source() -> void:
	var state := _state()
	var target_uid := int(state.add_card_to_hand(COIN_ID, db))
	var source_uid := int(state.add_card_to_hand(COIN_ID, db))
	state.get_card_instance(target_uid).count = 5
	state.get_card_instance(source_uid).count = 3

	assert_true(state.stack_cards(target_uid, source_uid), "CardStack accepts same-id stackables")
	assert_eq(int(state.get_card_instance(target_uid).count), 8, "target takes source count")
	assert_eq(str(state.get_card_instance(source_uid).zone), "removed", "RemoveCard removes the source")
	assert_false(source_uid in state.hand)
	assert_true(target_uid in state.hand)


func test_stack_cards_rejects_other_cards() -> void:
	var state := _state()
	var coin_uid := int(state.add_card_to_hand(COIN_ID, db))
	var character_uid := int(state.add_card_to_hand(CHARACTER_ID, db))
	var other_coin_uid := int(state.add_card_to_hand(COIN_ID, db))
	assert_false(state.stack_cards(coin_uid, character_uid), "different card id")
	assert_false(state.stack_cards(character_uid, coin_uid), "non-stackable target")
	assert_false(state.stack_cards(coin_uid, coin_uid), "a card cannot stack with itself")
	assert_eq(str(state.get_card_instance(other_coin_uid).zone), "hand", "a rejected stack leaves the source alone")


func test_card_widget_accepts_a_same_id_stackable_drop() -> void:
	var target_card: Dictionary = db.get_card(COIN_ID).duplicate(true)
	target_card["count"] = 8
	var widget := CardWidget.make(target_card, "hand")
	add_child_autofree(widget)
	await wait_process_frames(1)
	var payload := {
		"type": "card",
		"card_id": COIN_ID,
		"card_uid": 999,
		"card": {"id": COIN_ID, "tag": {"可堆叠": 1}, "count": 2},
		"source": "hand",
	}
	assert_true(widget._can_drop_data(Vector2.ZERO, payload), "CardStack target accepts the drop")
	watch_signals(widget)
	widget._drop_data(Vector2.ZERO, payload)
	assert_signal_emitted_with_parameters(widget, "stack_dropped", [widget.card_uid, 999])

	var other := payload.duplicate(true)
	other["card"] = {"id": CHARACTER_ID, "tag": {}, "count": 1}
	assert_false(widget._can_drop_data(Vector2.ZERO, other), "a different card id must not stack")


func test_shift_click_requests_a_split_instead_of_the_detail() -> void:
	var target_card: Dictionary = db.get_card(COIN_ID).duplicate(true)
	target_card["count"] = 8
	var widget := CardWidget.make(target_card, "hand")
	add_child_autofree(widget)
	await wait_process_frames(1)
	watch_signals(widget)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(10, 10)
	press.shift_pressed = true
	widget._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(10, 10)
	release.shift_pressed = true
	widget._gui_input(release)
	assert_signal_emitted_with_parameters(widget, "split_requested", [widget.card_uid])
	assert_signal_not_emitted(widget, "clicked")

	var plain_release := release.duplicate()
	plain_release.shift_pressed = false
	widget._gui_input(press)
	widget._gui_input(plain_release)
	assert_signal_emitted(widget, "clicked")
