extends GutTest

## Card stack gestures, source-backed:
## [SRC: CardController.CardSplit 0x528580 / CardController.CardStack 0x5286b0;
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


func test_count_badge_splits_one_and_long_press_does_not_open_details() -> void:
	var card: Dictionary = db.get_card(COIN_ID).duplicate(true)
	card["count"] = 8
	card["instance_uid"] = 901
	var widget := CardWidget.make(card, "hand")
	add_child_autofree(widget)
	await wait_process_frames(1)
	watch_signals(widget)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = Vector2(95, 365)
	event.pressed = true
	widget._gui_input(event)
	event.pressed = false
	widget._gui_input(event)
	assert_signal_emitted_with_parameters(widget, "split_one_requested", [901])
	assert_signal_not_emitted(widget, "clicked")
	event.position = Vector2(30, 30)
	event.pressed = true
	widget._gui_input(event)
	widget._process(0.21)
	event.pressed = false
	widget._gui_input(event)
	assert_signal_not_emitted(widget, "clicked", "release after hold must not open details")
	widget._gui_input(event)
	assert_signal_not_emitted(widget, "clicked", "unpaired release is not a new click")


func test_slot_to_hand_stack_checks_live_locks_and_does_not_resurrect_source() -> void:
	var state := _state()
	state.active_sudan_cards.clear()
	state.event_prompts.clear()
	state.begin_guide = {}
	var rng := RNG.new(9322)
	var target := state.add_card_to_hand(COIN_ID, db)
	var source := state.add_card_to_hand(COIN_ID, db)
	state.get_card_instance(target).count = 5
	state.get_card_instance(source).count = 3
	var screen := preload("res://ui/game_screen.gd").new()
	screen.size = Vector2(3840, 2160)
	screen.setup(state, db, rng)
	add_child_autofree(screen)
	await wait_process_frames(2)
	var view := preload("res://ui/rite_view.gd").new()
	view.setup(state, db, rng, 5000001)
	screen.add_source_overlay(view)
	await wait_process_frames(2)
	view._place_card_in_slot("s4", source, "hand", "")
	view._after_placement_changed()
	screen.refresh()
	await wait_process_frames(2)
	screen._presentation_blockers["rite"] = false
	var widget: CardWidget
	for candidate in screen._ordered_hand_cards():
		if candidate.card_uid == target:
			widget = candidate
	assert_not_null(widget)
	var payload := {"type": "card", "card_uid": source, "source": "slot",
		"source_slot": "s4", "source_rite_uid": view._rite_uid, "card": state.card_data_for(source, db)}
	assert_true(widget._can_stack_dropped_card(payload), "editable slot source can merge into hand")
	view._resolution_pending = true
	assert_false(widget._can_stack_dropped_card(payload))
	screen._on_hand_card_stack_dropped(target, source)
	assert_eq(state.get_card_instance(target).count, 5, "direct callback also respects pending resolution")
	view._resolution_pending = false
	var rite = state.get_rite_instance(view._rite_uid)
	rite.start = true
	assert_false(widget._can_stack_dropped_card(payload))
	rite.start = false
	widget._drop_data(Vector2.ZERO, payload)
	assert_eq(state.get_card_instance(target).count, 8)
	assert_eq(state.get_card_instance(source).zone, "removed")
	assert_false(source in state.hand)
	assert_false(view._placed.has("s4"), "panel cache cannot retain consumed source")
	assert_true(state.cards_in_slot(4, view._rite_uid).is_empty())
	screen._on_hand_card_stack_dropped(target, source)
	assert_eq(state.get_card_instance(target).count, 8, "stale drop cannot consume source twice")
	await wait_process_frames(3)


func test_slot_card_delegates_stacking_to_its_owner_and_respects_lock() -> void:
	var state := _state()
	var rng := RNG.new(9321)
	var view := preload("res://ui/rite_view.gd").new()
	view.setup(state, db, rng, 5000001)
	add_child_autofree(view)
	await wait_process_frames(2)
	var target := int(state.add_card_to_hand(COIN_ID, db))
	var source := int(state.add_card_to_hand(COIN_ID, db))
	state.get_card_instance(target).count = 5
	state.get_card_instance(source).count = 3
	# Isolate a manual slot; the source-card hit must traverse the real slot node.
	view._rite = view._rite.duplicate(true)
	var slot_key: String = "s4"
	view._rite["cards_slot"][slot_key]["condition"] = {}
	view._place_card_in_slot(slot_key, target, "hand", "")
	view._after_placement_changed()
	var widget: CardWidget = view._slot_buttons[slot_key].find_child("PlacedCard_*", true, false)
	var payload := {"type": "card", "card_uid": source, "card_id": COIN_ID,
		"source": "hand", "card": state.card_data_for(source, db)}
	assert_false(widget._can_stack_dropped_card(payload), "slot cards never emit unconnected hand-stack signals")
	assert_true(widget._can_drop_data(Vector2.ZERO, payload))
	widget._drop_data(Vector2.ZERO, payload)
	assert_eq(state.get_card_instance(target).count, 8, "dropping on the card face reaches the slot's stack handler")
	assert_false(source in state.hand)
	widget = view._slot_buttons[slot_key].find_child("PlacedCard_*", true, false)
	var next_source := int(state.add_card_to_hand(COIN_ID, db))
	payload["card_uid"] = next_source
	payload["card"] = state.card_data_for(next_source, db)
	assert_true(widget._can_drop_data(Vector2.ZERO, payload), "valid stack is accepted before locking")
	view._resolution_pending = true
	assert_false(widget._can_drop_data(Vector2.ZERO, payload), "locked slot face rejects stacking")
	widget._drop_data(Vector2.ZERO, payload)
	assert_eq(state.get_card_instance(target).count, 8, "direct drop callback cannot bypass the lock")
	assert_true(next_source in state.hand)
	await wait_process_frames(2)
