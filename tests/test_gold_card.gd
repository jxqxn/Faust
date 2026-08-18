extends GutTest

## Gold-card model tests: gold is stacked gold card objects (id 2000029) in
## hand per the original GenCoin chain (GenCoin.c Do 0x510b40 + corpus save
## multi-object stacks). coin_count is the summed read surface.

var db: ConfigDB

const RNG = preload("res://core/rng.gd")

func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()

func _new_state(seed_value: int = 7) -> GameState:
	var st := GameState.new()
	st.setup_new_run(db, 1, RNG.new(seed_value))
	return st

func test_add_coin_grants_front_gold_card_with_config_tags():
	var st := _new_state()
	st.add_coin(5, db)
	assert_eq(st.coin_count, 5)
	var uids := st.gold_card_uids()
	assert_eq(uids.size(), 1, "one coin op = one gold card object")
	var gold = st.get_card_instance(uids[0])
	assert_eq(gold.card_id, GameState.GOLD_CARD_ID)
	assert_eq(gold.count, 5)
	assert_eq(gold.tags.get("金币", 0), 1, "gold card carries the 金币 config tag")
	assert_eq(gold.tags.get("可堆叠", 0), 1)
	assert_eq(st.hand[0], uids[0], "GenCoin pins the gold stack to the hand front")

func test_coin_ops_accumulate_across_multiple_grants():
	var st := _new_state()
	st.add_coin(3, db)
	st.add_coin(4, db)
	assert_eq(st.coin_count, 7)
	assert_eq(st.gold_card_uids().size(), 2, "each op appends a fresh object like AddCard")

func test_spend_coin_decrements_and_removes_empty_objects():
	var st := _new_state()
	st.add_coin(3, db)
	st.add_coin(4, db)
	assert_true(st.spend_coin(5))
	assert_eq(st.coin_count, 2)
	assert_false(st.spend_coin(3), "cannot overspend")
	assert_true(st.spend_coin(2))
	assert_eq(st.coin_count, 0)
	assert_eq(st.gold_card_uids().size(), 0, "empty gold objects leave the hand")

func test_coin_result_op_grants_gold_card() -> void:
	var st := _new_state()
	ResultExec.execute({"coin": 6}, st, db)
	assert_eq(st.coin_count, 6)
	assert_eq(st.gold_card_uids().size(), 1)
	assert_eq(st.get_card_instance(st.gold_card_uids()[0]).count, 6)

func test_negative_coin_op_creates_negative_count_object() -> void:
	# GenCoin writes the signed op value via Card.set_count; negative totals
	# are representable as a negative-count gold card object.
	var st := _new_state()
	ResultExec.execute({"coin": -5}, st, db)
	assert_eq(st.coin_count, -5)
	assert_eq(st.gold_card_uids().size(), 1)
	assert_eq(st.get_card_instance(st.gold_card_uids()[0]).count, -5)


func test_coin_condition_reads_gold_total():
	var st := _new_state()
	st.add_coin(4, db)
	var ctx := {"db": db, "state": st, "rng": RNG.new(3)}
	assert_true(ConditionEval.eval_key("金币", 4, ctx))
	assert_false(ConditionEval.eval_key("金币", 5, ctx))

func test_have_tag_condition_sees_gold_card():
	var st := _new_state()
	st.add_coin(9, db)
	var ctx := {"db": db, "state": st, "rng": RNG.new(3)}
	assert_true(ConditionEval.eval_key("have.金币", 1, ctx), "gold card feeds have-tag conditions")

func test_v6_save_round_trip_keeps_gold_in_card_instances():
	var st := _new_state()
	st.add_coin(8, db)
	var data: Dictionary = SaveSystem.serialize(st)
	assert_false(data.has("coin_count"), "v6 saves must not carry the scalar")
	var restored := GameState.new()
	SaveSystem.deserialize(data, restored, db)
	assert_eq(restored.coin_count, 8)
	assert_eq(restored.gold_card_uids().size(), 1)

func test_v5_save_migrates_scalar_coin_to_gold_card():
	var st := _new_state()
	var data: Dictionary = SaveSystem.serialize(st)
	data["version"] = 5
	data["coin_count"] = 7
	var restored := GameState.new()
	SaveSystem.deserialize(data, restored, db)
	assert_eq(restored.coin_count, 7)
	var uids := restored.gold_card_uids()
	assert_eq(uids.size(), 1)
	assert_eq(restored.get_card_instance(uids[0]).count, 7)

func test_v5_save_with_zero_coin_gets_no_gold_object():
	var st := _new_state()
	var data: Dictionary = SaveSystem.serialize(st)
	data["version"] = 5
	data["coin_count"] = 0
	var restored := GameState.new()
	SaveSystem.deserialize(data, restored, db)
	assert_eq(restored.coin_count, 0)
	assert_eq(restored.gold_card_uids().size(), 0)
