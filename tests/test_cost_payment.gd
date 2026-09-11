extends GutTest

## Cost payment execution: the body that moves a paid slice out of a hand stack
## and into a rite slot.
##
## The audit recorded this as missing ("ClearNeedCosts 0x385470 has no
## decompiled callers ... the clone never actually deducts"). That note pointed
## at the wrong methods: ClearNeedCosts is an uncalled field reset, and
## CostCondition.PostProcess is a config-load pass. The body is
## CardSlotController.CardStack 0x53b0a0.
##
## [SRC: CardSlotController.c @ CardStack (RVA 0x53b0a0) lines 855-892;
##       CostCondition.c @ IsSatisfied 0x3f6160; stringliteral 0x2593720 =
##       "stackable"; CardExtensions.c @ Copy 0x37f4e0 keep-count flag.]

const STACKABLE_CARD := 2000029 # 金币: 金币/可堆叠/消耗品
const PLAIN_CARD := 2000001    # 阿尔图: no 可堆叠
const RNG = preload("res://core/rng.gd")


var db: ConfigDB


func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_fixture_guard_tag_domains() -> void:
	assert_gt(int(db.get_card(STACKABLE_CARD).get("tag", {}).get("可堆叠", 0)), 0,
		"the stackable fixture really carries 可堆叠")
	assert_eq(int(db.get_card(PLAIN_CARD).get("tag", {}).get("可堆叠", 0)), 0,
		"and the plain fixture does not")


func test_paying_less_than_the_stack_splits_off_exactly_the_cost() -> void:
	# card.set_count(count - cost) + Copy(keep_count) + copy.set_count(cost)
	var state := GameState.new()
	var uid: int = state.add_card_to_hand(STACKABLE_CARD, db)
	state.get_card_instance(uid).count = 5
	var placed: int = state.pay_cost_into_slot(uid, 1, 1, db, 0)
	assert_ne(placed, uid, "a partial payment is a new card, not the same one")
	var source = state.get_card_instance(uid)
	var paid = state.get_card_instance(placed)
	assert_eq(int(source.count), 4, "the remainder stays on the hand card")
	assert_eq(str(source.zone), "hand", "and it is still in hand")
	assert_true(state.hand.has(uid), "the hand list still holds the original")
	assert_eq(int(paid.count), 1, "the paid slice carries exactly the cost")
	assert_eq(str(paid.zone), "slot")
	assert_eq(str(paid.slot_key), "s1", "and it occupies the requested slot")
	assert_eq(int(paid.card_id), STACKABLE_CARD, "the slice is the same card id")


func test_paying_the_whole_stack_moves_that_card() -> void:
	var state := GameState.new()
	var uid: int = state.add_card_to_hand(STACKABLE_CARD, db)
	state.get_card_instance(uid).count = 3
	var placed: int = state.pay_cost_into_slot(uid, 2, 3, db, 0)
	assert_eq(placed, uid, "an exactly-paid stack is moved, not copied")
	var moved = state.get_card_instance(uid)
	assert_eq(int(moved.count), 3, "the count is untouched")
	assert_eq(str(moved.zone), "slot")
	assert_eq(str(moved.slot_key), "s2")
	assert_false(state.hand.has(uid), "and it left the hand")


func test_overpaying_a_stack_also_moves_the_whole_card() -> void:
	# iVar8 = count - cost < 1 takes the SameCardLeaves path, so a cost that
	# exceeds the stack consumes the card rather than splitting it.
	var state := GameState.new()
	var uid: int = state.add_card_to_hand(STACKABLE_CARD, db)
	state.get_card_instance(uid).count = 1
	var placed: int = state.pay_cost_into_slot(uid, 1, 4, db, 0)
	assert_eq(placed, uid, "count 1 against a cost of 4 moves the card itself")
	assert_false(state.hand.has(uid))
	assert_eq(int(state.get_card_instance(uid).count), 1, "the source count is not rewritten")


func test_non_stackable_cards_always_move_whole() -> void:
	# The HasTag(card, "stackable") guard at the top of CardStack means a
	# non-stackable card can never be split, whatever the cost.
	var state := GameState.new()
	var uid: int = state.add_card_to_hand(PLAIN_CARD, db)
	state.get_card_instance(uid).count = 5
	var placed: int = state.pay_cost_into_slot(uid, 1, 2, db, 0)
	assert_eq(placed, uid, "a non-stackable card is moved whole")
	var moved = state.get_card_instance(uid)
	assert_eq(int(moved.count), 5, "its count survives intact")
	assert_eq(str(moved.zone), "slot")
	assert_false(state.hand.has(uid))


func test_payment_rejects_nonsense_arguments() -> void:
	var state := GameState.new()
	var uid: int = state.add_card_to_hand(STACKABLE_CARD, db)
	state.get_card_instance(uid).count = 4
	assert_eq(state.pay_cost_into_slot(uid, 0, 1, db, 0), 0, "slot 0 is not a slot")
	assert_eq(state.pay_cost_into_slot(uid, 1, -3, db, 0), 0, "nor is a negative cost")
	assert_eq(state.pay_cost_into_slot(999999, 1, 1, db, 0), 0, "an unknown uid pays nothing")
	assert_eq(int(state.get_card_instance(uid).count), 4, "and the stack is untouched")
	assert_true(state.hand.has(uid), "still in hand")


func test_payment_carries_the_source_runtime_tags() -> void:
	# CardExtensions.Copy duplicates Card.tag@0x30, so a paid slice keeps the
	# stack's runtime delta.
	var state := GameState.new()
	var uid: int = state.add_card_to_hand(STACKABLE_CARD, db)
	var source = state.get_card_instance(uid)
	source.count = 3
	source.tags["隐匿"] = 2
	var placed: int = state.pay_cost_into_slot(uid, 1, 1, db, 0)
	var paid = state.get_card_instance(placed)
	assert_eq(int(paid.tags.get("隐匿", 0)), 2, "the slice inherits the runtime delta")
	assert_eq(int(source.tags.get("隐匿", 0)), 2, "and the remainder keeps it too")


func test_payment_records_a_copy_operation() -> void:
	# The split goes through CopyCard, so the settlement stream sees a COPY row
	# for the slice; the original's CardStack does use CardExtensions.Copy.
	var state := GameState.new()
	var uid: int = state.add_card_to_hand(STACKABLE_CARD, db)
	state.get_card_instance(uid).count = 3
	state.begin_result_op_log()
	var placed: int = state.pay_cost_into_slot(uid, 1, 1, db, 0)
	var ops: Array = state.drain_result_op_log()
	assert_true(ops.any(func(o): return int(o["op"]) == GameState.CARD_OP_COPY and int(o["card_uid"]) == placed),
		"the paid slice is recorded as COPY of the source")


# ---- Slot cost lookup against real configured rites -------------------------
#
# 653 of the 1863 rite files carry a `cost.` key inside a slot condition, nested
# under any/all/none. The operator is part of the key.

func test_bare_cost_key_reads_its_value() -> void:
	# content/rite/5000005.json: s2 condition nests {"cost.金币": 3}.
	var result := _slot_cost_of(5000005, 2)
	assert_eq(result["cost_key"], "cost.金币", "the nested cost key is found")
	assert_eq(result["needed"], 3, "cost.金币 with value 3 asks for 3")


func test_equality_cost_key_reads_its_value() -> void:
	# content/rite/5000001.json s4 nests {"any": {"cost.消耗品=": 1, ...}}.
	var result := _slot_cost_of(5000001, 4)
	assert_eq(result["cost_key"], "cost.消耗品=", "the nested cost key is found through any")
	assert_eq(result["needed"], 0, "s4 explicitly excludes gold: nested cost cannot bypass !金币")


func test_a_slot_without_a_cost_key_asks_for_nothing() -> void:
	var result := _slot_cost_of(5000001, 1)
	assert_eq(result["cost_key"], "", "s1 of 5000001 has no cost key")
	assert_eq(result["needed"], 0, "and none is invented")


func test_cost_lookup_distribution_is_what_the_audit_claimed_to_lack() -> void:
	# Fixture guard on the corpus reading quoted in slot_cost_needed's docstring.
	assert_eq(_count_rites_with_slot_cost(), 653,
		"653 rite files carry cost. inside a slot condition")


func _count_rites_with_slot_cost() -> int:
	var count := 0
	for rite_id in db.rites:
		var definition: Dictionary = db.rites[rite_id]
		var slots: Variant = definition.get("cards_slot", {})
		if not (slots is Dictionary):
			continue
		for slot_key in (slots as Dictionary):
			var slot_def: Variant = (slots as Dictionary)[slot_key]
			if not (slot_def is Dictionary):
				continue
			if not _find_cost_key_independently((slot_def as Dictionary).get("condition", {})).is_empty():
				count += 1
				break
	return count


## Independent copy of the search, so the test does not merely mirror the
## implementation it is checking.
func _find_cost_key_independently(condition: Variant) -> String:
	if not (condition is Dictionary):
		return ""
	var stack: Array = [condition]
	while not stack.is_empty():
		var current: Variant = stack.pop_back()
		if not (current is Dictionary):
			continue
		for raw_key in (current as Dictionary):
			var key := str(raw_key)
			if key.begins_with("cost."):
				return key
			if key in ["any", "all", "none"]:
				stack.append((current as Dictionary)[raw_key])
	return ""


func _slot_cost_of(rite_id: int, slot: int, count: int = 3) -> Dictionary:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(7001))
	var rite = state.create_rite_instance(rite_id)
	var uid: int = state.add_card_to_hand(STACKABLE_CARD, db)
	# The cost is paid by Card.count, so the fixture stack has to cover it before
	# the condition can be satisfied.
	state.get_card_instance(uid).count = count
	var needed: int = state.slot_cost_needed(slot, uid, db, rite.uid)
	var definition: Dictionary = db.rites[rite_id]
	var slots: Dictionary = definition.get("cards_slot", {})
	var slot_def: Dictionary = slots.get("s%d" % slot, {})
	return {
		"needed": needed,
		"cost_key": _find_cost_key_independently(slot_def.get("condition", {})),
	}


func test_an_underfunded_stack_cannot_pay_the_cost() -> void:
	# The slot's condition is a real gate: one gold cannot pay a three-gold cost,
	# so the lookup reports nothing to pay and the drop must be refused.
	var result := _slot_cost_of(5000005, 2, 1)
	assert_eq(result["cost_key"], "cost.金币", "the slot is a cost slot")
	assert_eq(result["needed"], 0, "but a count-1 stack does not satisfy cost 3")
