extends GutTest

## CostCondition semantics: `cost.<selector><op>` is a transaction, not a
## property of the dragged card. The condition walks Player.cards@0x88 in order,
## keeps every card the inner Compare accepts, accumulates Card.count until the
## requirement is met and records that selection.
## [SRC: decompiled/CostCondition.c @ IsSatisfied (RVA 0x3f6160);
##       CostCondition.c @ PostProcess (0x3f6520) for the [min,max] value shape;
##       ConditionContext cost fields is_cost@0x60 / cost_count@0x64 /
##       need_cost_cards@0x68 (dump.cs:383873).]

const RNG = preload("res://core/rng.gd")

# 不满 carrier: 妻子的不满 (2000083) is the ONLY card with the 不满 tag, so it
# isolates "a matching owned card pays" from gold, which every cost of the
# 消耗品 family would otherwise satisfy (2000029 金币 carries 消耗品 too).
const COMPLAINT_CARD := 2000083
const GOLD_CARD := 2000029
const PLAIN_CARD := 2000006  # 梅姬: no 不满 tag


var db: ConfigDB


func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()


func _ctx(state) -> Dictionary:
	return {"db": db, "state": state, "rng": RNG.new(7), "rite_state": {}, "attr_slots": ["s1", "s2"]}


func test_cost_is_paid_by_a_matching_owned_card_not_the_acting_card() -> void:
	var state := GameState.new()
	state.add_card_to_hand(COMPLAINT_CARD, db)
	var ctx := _ctx(state)
	# A card with no 不满 tag is what the player dragged; the cost is still
	# payable because the hand holds the carrier.
	ctx["acting_card"] = db.get_card(PLAIN_CARD)
	assert_true(ConditionEval.eval_key("cost.不满", 1, ctx),
		"an unrelated acting card does not block a cost the player can pay")
	assert_eq((ctx.get("need_cost_cards", []) as Array).size(), 1,
		"the payer selection is recorded on the context")


func test_cost_unsatisfied_without_any_matching_card() -> void:
	var state := GameState.new()
	state.add_card_to_hand(PLAIN_CARD, db)
	var ctx := _ctx(state)
	ctx["acting_card"] = db.get_card(PLAIN_CARD)
	assert_false(ConditionEval.eval_key("cost.不满", 1, ctx),
		"no owned card carries the cost tag, so the gate fails")
	assert_eq((ctx.get("need_cost_cards", []) as Array).size(), 0,
		"a failed gate records no payer cards")


func test_cost_accumulates_counts_in_player_cards_order() -> void:
	var state := GameState.new()
	state.add_card_to_hand(COMPLAINT_CARD, db)
	var uid := state.card_uid_for(COMPLAINT_CARD)
	state.get_card_instance(uid).count = 3
	var ctx := _ctx(state)
	assert_true(ConditionEval.eval_key("cost.不满", 2, ctx),
		"Card.count feeds the running total")
	assert_eq(int(ctx.get("cost_count", 0)), 2,
		"with max == int.MaxValue the payer hands over the minimum once it is reached")


func test_cost_stops_at_the_first_card_that_covers_the_requirement() -> void:
	var state := GameState.new()
	state.add_card_to_hand(COMPLAINT_CARD, db)
	var first_uid := state.card_uid_for(COMPLAINT_CARD)
	state.get_card_instance(first_uid).count = 2
	state.add_card_to_hand(COMPLAINT_CARD, db)
	var ctx := _ctx(state)
	assert_true(ConditionEval.eval_key("cost.不满", 2, ctx))
	var selected: Array = ctx.get("need_cost_cards", [])
	assert_eq(selected.size(), 1, "the walk stops as soon as the minimum is covered")
	assert_eq(int(selected[0].uid), first_uid, "and it selected the first card in order")


func test_cost_range_second_element_is_the_hand_over_ceiling() -> void:
	var state := GameState.new()
	state.add_card_to_hand(COMPLAINT_CARD, db)
	var uid := state.card_uid_for(COMPLAINT_CARD)
	state.get_card_instance(uid).count = 9
	var ctx := _ctx(state)
	# [min, max] = [1, 2]: one is required and the payer never hands over more
	# than two, so the amount saturates at the ceiling instead of the total.
	assert_true(ConditionEval.eval_key("cost.不满", [1, 2], ctx))
	assert_eq(int(ctx.get("cost_count", 0)), 2, "the PayCosts amount is clamped by max")


func test_cost_selector_accepts_compare_suffixes_and_numeric_ids() -> void:
	var state := GameState.new()
	state.add_card_to_hand(COMPLAINT_CARD, db)
	var ctx := _ctx(state)
	assert_true(ConditionEval.eval_key("cost.不满>=", 1, ctx), "a compare suffix is stripped")
	assert_true(ConditionEval.eval_key("cost.%d" % COMPLAINT_CARD, 1, ctx),
		"a numeric selector matches the card definition id")
	assert_false(ConditionEval.eval_key("cost.%d" % PLAIN_CARD, 1, ctx),
		"a numeric selector for an unowned card fails")


func test_cost_reads_the_effective_tag_row_including_count() -> void:
	var state := GameState.new()
	state.add_card_to_hand(COMPLAINT_CARD, db)
	var uid := state.card_uid_for(COMPLAINT_CARD)
	# 妻子的不满 carries 不满 1 in config; the runtime delta raises the row to 3
	# and the object holds a stack of 2, so GetTag reports 6 and the cost walk
	# contributes count 2.
	var instance = state.get_card_instance(uid)
	instance.count = 2
	instance.tags["不满"] = 2
	assert_eq(int(state.effective_card_tags(uid, db).get("不满", 0)), 6,
		"(1 definition + 2 delta) x count 2")
	var ctx := _ctx(state)
	assert_true(ConditionEval.eval_key("cost.不满", 2, ctx),
		"the cost gate accepts the card through the definition row plus delta")
	assert_eq(int(ctx.get("cost_count", 0)), 2, "and hands over the stack count")


func test_slot_embedded_cards_count_toward_the_cost() -> void:
	var state := GameState.new()
	var rite_uid := state.create_rite_instance(5000001).uid
	state.add_card_to_hand(GOLD_CARD, db)
	var uid := state.card_uid_for(GOLD_CARD)
	state.add_card_to_slot(uid, 1, db, rite_uid)
	var ctx := _ctx(state)
	assert_false(state.has_card_in_hand(uid), "the carrier sits in a slot")
	assert_eq(state.get_card_instance(uid).zone, "slot")
	assert_true(ConditionEval.eval_key("cost.消耗品", 1, ctx),
		"Player.cards is one list: a slotted card still pays")


func test_gold_pays_the_consumable_cost_family() -> void:
	# The config's dominant cost family is 消耗品 (370 keys), and gold carries
	# that tag, so holding gold must satisfy it without any extra card.
	var state := GameState.new()
	state.add_coin(1, db)
	assert_true(ConditionEval.eval_key("cost.消耗品", 1, _ctx(state)),
		"a single gold card satisfies cost.消耗品")
