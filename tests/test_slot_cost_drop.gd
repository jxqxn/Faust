extends GutTest

const View = preload("res://ui/rite_view.gd")
var db: ConfigDB

func after_each() -> void:
	# Card surface refresh queues the replaced container for deletion.
	await wait_process_frames(2)

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func _fixture(count: int) -> Dictionary:
	var state := GameState.new()
	var rite = state.create_rite_instance(5000005)
	var uid := state.add_card_to_hand(2000029, db)
	state.get_card_instance(uid).count = count
	var view = View.new()
	view.setup(state, db, GameRNG.new(38), 5000005, rite.uid)
	add_child_autofree(view)
	return {"state": state, "view": view, "uid": uid, "rite_uid": rite.uid}

func _drop(f: Dictionary, uid: int) -> void:
	f.view.drop_card_on_slot("s2", {"type": "card", "card_uid": uid, "source": "hand"})

# [SRC: CardStack 0x53b0a0 and original 5000005 s2 cost.金币=3.]
func test_real_drop_splits_ten_gold_and_leaves_seven_in_hand() -> void:
	var f := _fixture(10)
	await wait_process_frames(2)
	_drop(f, f.uid)
	var paid := int(f.view._placed.get("s2", 0))
	assert_ne(paid, int(f.uid))
	assert_gt(paid, 0)
	assert_eq(f.state.get_card_instance(f.uid).count, 7)
	assert_true(f.state.has_card_in_hand(f.uid))
	assert_eq(f.state.get_card_instance(paid).count, 3)
	assert_eq(f.state.get_card_instance(paid).zone, "slot")
	assert_eq(f.state.get_rite_instance(f.rite_uid).slot_cards.s2, paid)

func test_partial_deposit_then_top_up_keeps_slot_identity_and_returns_excess() -> void:
	var f := _fixture(1)
	await wait_process_frames(2)
	assert_true(f.view.can_drop_card_on_slot("s2", {"type": "card", "card_uid": f.uid, "source": "hand"}))
	_drop(f, f.uid)
	assert_eq(int(f.view._placed.get("s2", 0)), int(f.uid))
	var extra: int = f.state.add_card_to_hand(2000029, db)
	f.state.get_card_instance(extra).count = 5
	_drop(f, extra)
	assert_eq(int(f.view._placed.s2), int(f.uid))
	assert_eq(f.state.get_card_instance(f.uid).count, 3)
	assert_eq(f.state.get_card_instance(extra).count, 3)
	assert_true(f.state.has_card_in_hand(extra))

func test_exact_top_up_removes_donor_without_replacing_slot_card() -> void:
	var f := _fixture(1)
	await wait_process_frames(2)
	_drop(f, f.uid)
	var extra: int = f.state.add_card_to_hand(2000029, db)
	f.state.get_card_instance(extra).count = 2
	_drop(f, extra)
	assert_eq(f.state.get_card_instance(f.uid).count, 3)
	assert_eq(f.state.get_card_instance(extra).zone, "removed")
	assert_false(f.state.has_card_in_hand(extra))
	assert_eq(int(f.view._placed.s2), int(f.uid))

func test_hover_probe_does_not_change_counts_or_membership() -> void:
	var f := _fixture(1)
	await wait_process_frames(2)
	_drop(f, f.uid)
	var extra: int = f.state.add_card_to_hand(2000029, db)
	f.state.get_card_instance(extra).count = 8
	for i in range(3):
		assert_true(f.view.can_drop_card_on_slot("s2", {"type": "card", "card_uid": extra, "source": "hand"}))
	assert_eq(f.state.get_card_instance(f.uid).count, 1)
	assert_eq(f.state.get_card_instance(extra).count, 8)
	assert_true(f.state.has_card_in_hand(extra))

func test_an_unrelated_hand_card_cannot_pay_using_owned_gold() -> void:
	var f := _fixture(10)
	await wait_process_frames(2)
	var unrelated: int = f.state.add_card_to_hand(2000246, db)
	assert_false(f.view.can_drop_card_on_slot("s2", {"type": "card", "card_uid": unrelated, "source": "hand"}))
	assert_eq(f.state.get_card_instance(f.uid).count, 10)


func test_cross_rite_partial_stack_keeps_remainder_in_origin_slot() -> void:
	var f := _fixture(10)
	var origin = f.state.create_rite_instance(5000005)
	f.state.add_card_to_slot(f.uid, 2, db, origin.uid)
	await wait_process_frames(2)
	f.view.drop_card_on_slot("s2", {"type": "card", "card_uid": f.uid,
		"source": "slot", "source_slot": "s2", "source_rite_uid": origin.uid})
	var paid := int(f.view._placed.get("s2", 0))
	assert_gt(paid, 0)
	assert_ne(paid, int(f.uid))
	assert_eq(f.state.get_card_instance(f.uid).count, 7)
	assert_eq(f.state.get_card_instance(f.uid).rite_uid, origin.uid)
	assert_eq(int(origin.slot_cards.s2), int(f.uid))
	assert_eq(f.state.get_card_instance(paid).count, 3)
	assert_eq(f.state.get_card_instance(paid).rite_uid, int(f.rite_uid))


func test_cross_rite_exact_transfer_clears_old_slot_membership() -> void:
	var f := _fixture(3)
	var origin = f.state.create_rite_instance(5000005)
	f.state.add_card_to_slot(f.uid, 2, db, origin.uid)
	await wait_process_frames(2)
	f.view.drop_card_on_slot("s2", {"type": "card", "card_uid": f.uid,
		"source": "slot", "source_slot": "s2", "source_rite_uid": origin.uid})
	assert_eq(int(f.view._placed.get("s2", 0)), int(f.uid))
	assert_false(origin.slot_cards.has("s2"))
	assert_eq(f.state.get_card_instance(f.uid).rite_uid, int(f.rite_uid))


func test_non_cost_replacement_returns_old_card_without_routing_elsewhere() -> void:
	var f := _fixture(3)
	f.view.setup(f.state, db, GameRNG.new(39), 5000001, f.rite_uid)
	await wait_process_frames(2)
	var old_uid: int = f.state.add_card_to_hand(2000006, db)
	var new_uid: int = f.state.add_card_to_hand(2000001, db)
	f.view._place_card_in_slot("s1", old_uid, "hand", "")
	f.view._after_placement_changed()
	f.view.drop_card_on_slot("s1", {"type": "card", "card_uid": new_uid, "source": "hand"})
	assert_eq(int(f.view._placed.s1), new_uid)
	assert_true(f.state.has_card_in_hand(old_uid))
	assert_eq(f.state.get_card_instance(old_uid).zone, "hand")
	assert_false(f.state.has_card_in_hand(new_uid))
	assert_false(f.view._placed.has("s2"))

func test_rejected_specific_slot_does_not_auto_route_to_another_empty_slot() -> void:
	var f := _fixture(3)
	await wait_process_frames(2)
	var person: int = f.state.add_card_to_hand(2000006, db)
	f.view.drop_card_on_slot("s2", {"type": "card", "card_uid": person, "source": "hand"})
	assert_true(f.state.has_card_in_hand(person))
	assert_true(f.view._placed.is_empty(), "s1 could accept the person but was not targeted")

func test_replacement_probe_temporarily_excludes_only_destination() -> void:
	var f := _fixture(3)
	await wait_process_frames(2)
	var old_uid: int = f.state.add_card_to_hand(2000006, db)
	var next_uid: int = f.state.add_card_to_hand(2000001, db)
	f.view._place_card_in_slot("s1", old_uid, "hand", "")
	# Boundary fixture tests the source temporary-null operation independently
	# of currently authored slot conditions. Never modifies ConfigDB content.
	f.view._rite = f.view._rite.duplicate(true)
	f.view._rite.cards_slot.s1.condition = {"!s1": 1, "type": "char"}
	assert_true(f.view._try_update_card("s1", f.state.card_data_for(next_uid, db)))
	assert_eq(int(f.view._placed.s1), old_uid)
	assert_eq(f.state.get_card_instance(old_uid).zone, "slot")
	f.view._rite.cards_slot.s1.condition = {"s1": 1, "type": "char"}
	assert_false(f.view._try_update_card("s1", f.state.card_data_for(next_uid, db)))
	assert_eq(int(f.view._placed.s1), old_uid)


func test_zero_cost_slice_survives_save_load_without_creating_one_gold() -> void:
	var f := _fixture(4)
	await wait_process_frames(2)
	# No current authored slot has zero cost. This is an explicit source-method
	# boundary fixture, not claimed as an observed original gameplay sample.
	f.view._rite = f.view._rite.duplicate(true)
	f.view._rite.cards_slot.s2.condition = {"type": "item", "cost.金币": 0}
	_drop(f, f.uid)
	var paid := int(f.view._placed.get("s2", 0))
	assert_gt(paid, 0)
	assert_ne(paid, int(f.uid))
	assert_eq(f.state.get_card_instance(paid).count, 0)
	assert_false(f.state._instance_is_stackable(f.state.get_card_instance(paid)), "HasTag(stackable) is zero when count is zero")
	assert_eq(f.state.get_card_instance(f.uid).count, 4)
	assert_eq(f.state.gold_total(), 4)
	var saved := SaveSystem.serialize(f.state)
	var restored := GameState.new()
	SaveSystem.deserialize(saved, restored, db)
	assert_eq(restored.get_card_instance(paid).count, 0)
	assert_eq(restored.gold_total(), 4)
	assert_eq(int(restored.get_rite_instance(f.rite_uid).slot_cards.s2), paid)
