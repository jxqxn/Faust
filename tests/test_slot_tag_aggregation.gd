extends GutTest

var db: ConfigDB

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func _fixture() -> Dictionary:
	var state := GameState.new()
	var rite = state.create_rite_instance(5000005)
	var a := state.add_card_to_hand(2000029, db)
	var b := state.add_card_to_hand(2000029, db)
	state.get_card_instance(a).count = 2
	state.get_card_instance(b).count = 3
	state.add_card_to_slot(a, 1, db, rite.uid)
	state.add_card_to_slot(b, 2, db, rite.uid)
	return {"state": state, "db": db, "rite_uid": rite.uid, "a": a, "b": b}

# Deliberate boundary fixture: gold in both slots bypasses the authored entry
# gate. It tests SlotHasTag 0x408cf0 / accumulator 0x40bfb0, not playability.
func test_sum_is_compared_once_instead_of_any_individual_card() -> void:
	var ctx := _fixture()
	assert_true(ConditionEval.evaluate({"all.金币=": 5}, ctx))
	assert_false(ConditionEval.evaluate({"all.金币<=": 3}, ctx))
	assert_true(ConditionEval.evaluate({"!all.金币=": 3}, ctx))
	assert_true(ConditionEval.evaluate({"s1.金币=": 2}, ctx))

func test_empty_selection_has_zero_sum() -> void:
	var ctx := _fixture()
	ctx["use_slot_snapshot"] = true
	ctx["slot_entries"] = []
	assert_true(ConditionEval.evaluate({"all.金币=": 0}, ctx))
	assert_true(ConditionEval.evaluate({"enemy.金币<=": 0}, ctx))
	assert_false(ConditionEval.evaluate({"all.金币>": 0}, ctx))
	assert_false(ConditionEval.evaluate({"!all.金币=": 0}, ctx))

func test_snapshot_replaces_live_selection_and_uses_source_side_polarity() -> void:
	var ctx := _fixture()
	ctx["use_slot_snapshot"] = true
	ctx["slot_entries"] = [
		{"slot": "s1", "card_uid": ctx.a, "is_enemy": true},
		{"slot": "s2", "card_uid": ctx.b, "is_enemy": false},
	]
	# Both filter bits call 0x392140; closure0x3937b0 keeps is_enemy==false.
	assert_true(ConditionEval.evaluate({"enemy.金币=": 3}, ctx))
	assert_true(ConditionEval.evaluate({"friend.金币=": 3}, ctx))
	assert_true(ConditionEval.evaluate({"all.金币=": 5}, ctx))
	ctx.slot_entries.remove_at(1)
	assert_true(ConditionEval.evaluate({"all.金币=": 2}, ctx))
	assert_true(ConditionEval.evaluate({"enemy.金币=": 0}, ctx))
	assert_eq(ctx.state.get_card_instance(ctx.b).count, 3)

func test_live_side_selection_reads_authored_slot_flags() -> void:
	var ctx := _fixture()
	# Both real 5000005 slots carry is_enemy=0. The source's named Enemy
	# iterator therefore selects both, independently of host context arrays.
	assert_true(ConditionEval.evaluate({"enemy.金币=": 5}, ctx))
	assert_true(ConditionEval.evaluate({"friend.金币=": 5}, ctx))
	ctx["slot_entries"] = []
	assert_true(ConditionEval.evaluate({"all.金币=": 5}, ctx), "Only explicit snapshot mode overrides live rite cards")
