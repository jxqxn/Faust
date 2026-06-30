extends GutTest

const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
const ConditionEval = preload("res://sim/condition.gd")
const ResultExec = preload("res://sim/result.gd")
const RiteResolver = preload("res://sim/rite_resolver.gd")
const RNG = preload("res://core/rng.gd")

var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()

func _make_ctx(state: GameState, rng) -> Dictionary:
	return {"db": db, "state": state, "rng": rng, "rite_state": {}, "attr_slots": ["s1","s2"]}

func test_counter_condition_equality():
	var st := GameState.new()
	st.set_counter(7000617, 7)
	var ctx := _make_ctx(st, RNG.new(1))
	assert_true(ConditionEval.eval_key("counter.7000617=", 7, ctx))
	assert_false(ConditionEval.eval_key("counter.7000617=", 6, ctx))
	assert_true(ConditionEval.eval_key("counter.7000617>=", 5, ctx))
	assert_false(ConditionEval.eval_key("counter.7000617<", 7, ctx))

func test_slot_presence_and_is():
	var st := GameState.new()
	var ctx := _make_ctx(st, RNG.new(1))
	# Place a 贵族 (2000005 异国商人) in slot 1.
	st.add_card_to_slot(2000005, 1, db)
	assert_true(ConditionEval.eval_key("s1", 1, ctx), "s1 present")
	assert_false(ConditionEval.eval_key("!s1", 1, ctx), "!s1 absent")
	assert_true(ConditionEval.eval_key("s1.is", 2000005, ctx), "s1.is 2000005")
	assert_false(ConditionEval.eval_key("s1.is", 9999, ctx), "s1.is not 9999")
	# Tag check: 异国商人 tag present.
	assert_true(ConditionEval.eval_key("s1.异国商人", 1, ctx))

func test_have_tag_and_card():
	var st := GameState.new()
	st.add_card_to_hand(2000005) # 异国商人
	var ctx := _make_ctx(st, RNG.new(1))
	assert_true(ConditionEval.eval_key("have.异国商人", 1, ctx))
	assert_true(ConditionEval.eval_key("have.2000005", 1, ctx))
	assert_false(ConditionEval.eval_key("have.妻子", 1, ctx))

func test_any_all_logic():
	var st := GameState.new()
	st.add_card_to_slot(2000005, 1, db)
	var ctx := _make_ctx(st, RNG.new(1))
	# any{ s1, s2 } -> true (s1 present).
	assert_true(ConditionEval.eval_key("any", {"s1": 1, "s2": 1}, ctx))
	# all{ s1, s2 } -> false (s2 absent).
	assert_false(ConditionEval.eval_key("all", {"s1": 1, "s2": 1}, ctx))

func test_result_counter_and_coin():
	var st := GameState.new()
	var d := ResultExec.execute({"金币": 5, "counter+7000001": 2}, st, db)
	assert_eq(st.coin_count, 5)
	assert_eq(st.get_counter(7000001), 2)
	# coin / 金币 are aliases.
	var d2 := ResultExec.execute({"coin": 3}, st, db)
	assert_eq(st.coin_count, 8)

func test_result_clean_slot():
	var st := GameState.new()
	st.add_card_to_slot(2000005, 1, db)
	st.add_card_to_slot(2000006, 2, db)
	assert_eq(st.table_cards.size(), 2)
	ResultExec.execute({"clean.s1": 1}, st, db)
	assert_eq(st.cards_in_slot(1).size(), 0)
	assert_eq(st.cards_in_slot(2).size(), 1)

func test_result_slot_tag_op():
	var st := GameState.new()
	st.add_card_to_slot(2000005, 4, db)
	ResultExec.execute({"s4+回收": 1}, st, db)
	var c: Dictionary = st.cards_in_slot(4)[0]
	assert_true(c.tags.has("回收"), "回收 tag added to slot 4")

func test_result_deferred_events_and_choose():
	var st := GameState.new()
	var d := ResultExec.execute({"event_on": 5300601, "choose": {"a": "x"}}, st, db)
	assert_eq(d.events, [5300601])
	assert_eq(d.choose, {"a": "x"})

func test_rite_5000001_resolves_with_empty_slots():
	# 治理家业 with no cards slotted: the "no one sent" branch should match
	# (condition !s1 / !s2 both true when slots empty).
	var st := GameState.new()
	st.difficulty_config = db.get_difficulty(1)
	var ctx := _make_ctx(st, RNG.new(42))
	var rite := db.get_rite(5000001)
	var res := RiteResolver.resolve(rite, ctx, 0)
	# The empty-slots settlement entry should match.
	assert_false(res.normal_entry.is_empty(), "normal entry matched for empty slots")
	# No gold awarded in the empty case.
	# (result is {} for the no-one-sent entry)

func test_rite_5000001_pays_gold_when_attributes_high():
	# Slotted a high-智慧+社交 card; many dice => likely the >=3 branch (5 gold).
	var st := GameState.new()
	st.difficulty_config = db.get_difficulty(0) # easy weights for higher success
	st.add_card_to_slot(2000005, 1, db) # 异国商人
	var ctx := _make_ctx(st, RNG.new(123))
	var rite := db.get_rite(5000001)
	var res := RiteResolver.resolve(rite, ctx, 0)
	# Some normal entry should match (any of the r1 branches).
	assert_false(res.normal_entry.is_empty(), "a settlement branch matched")
	# Gold count is between 1 and 5 (the four branches give 1,2,3,5 gold).
	assert_between(st.coin_count, 1, 5)

func test_funccompare_gold_dice_map_can_satisfy_r1_without_dice():
	var st := GameState.new()
	st.difficulty_config = db.get_difficulty(1)
	var ctx := _make_ctx(st, RNG.new(1))
	ctx["gold_dice_used"] = {"r1": 1}
	ctx["gold_dice_map"] = {"r1": 1}
	assert_true(ConditionEval.eval_key("r1:智慧>=", [1, 5], ctx), "per-type gold dice map satisfies r1")

func test_funccompare_gold_dice_map_uses_real_r_type_key():
	var st := GameState.new()
	st.difficulty_config = db.get_difficulty(1)
	var ctx := _make_ctx(st, RNG.new(1))
	ctx["gold_dice_used"] = {"r2": 1}
	ctx["gold_dice_map"] = {"r2": 1}
	assert_true(ConditionEval.eval_key("r2:智慧>=", [1, 5], ctx), "gold dice map satisfies the exact r2 type")
	assert_false(ConditionEval.eval_key("r3:智慧>=", [1, 5], ctx), "r2 gold dice does not leak into r3")

func test_funccompare_reuses_cached_dice_without_advancing_rng():
	var st := GameState.new()
	st.difficulty_config = db.get_difficulty(1)
	st.add_card_to_slot(2000005, 1, db)
	var rng := RNG.new(99)
	var ctx := _make_ctx(st, rng)
	ctx["dice_cache"] = {}
	ConditionEval.eval_key("r1:智慧>=", [99, 5], ctx)
	var after_first := rng.get_state()
	ctx["gold_dice_map"] = {"r1": 99}
	assert_true(ConditionEval.eval_key("r1:智慧>=", [99, 5], ctx), "cached dice plus gold can satisfy without reroll")
	assert_eq(rng.get_state(), after_first, "cached FuncCompare does not advance RNG on re-evaluation")

func test_settlement_extre_all_match():
	# Find a rite whose settlement_extre has multiple entries that can match.
	# 5000001 extre has many s4.is / s3.is entries; with no such cards none match,
	# so verify the "all match" semantics with a constructed rite instead.
	var st := GameState.new()
	var ctx := _make_ctx(st, RNG.new(1))
	var fake := {
		"settlement_extre": [
			{"condition": {"s1": 1}, "result": {"金币": 1}},
			{"condition": {"s1": 1}, "result": {"金币": 2}},
		]
	}
	st.add_card_to_slot(2000005, 1, db)
	var res := RiteResolver.resolve(fake, ctx, 0)
	assert_eq(res.extre_log.size(), 2, "both extre entries matched")
	assert_eq(st.coin_count, 3)

func test_settlement_normal_first_match_only():
	var st := GameState.new()
	var ctx := _make_ctx(st, RNG.new(1))
	var fake := {
		"settlement": [
			{"condition": {"s1": 1}, "result": {"金币": 1}},
			{"condition": {"s1": 1}, "result": {"金币": 100}},
		]
	}
	st.add_card_to_slot(2000005, 1, db)
	var res := RiteResolver.resolve(fake, ctx, 0)
	assert_eq(res.extre_log.size(), 0)
	# Only first match (1 gold), not 100.
	assert_eq(st.coin_count, 1)

func test_settlement_prior_executes_action_after_result():
	var st := GameState.new()
	var ctx := _make_ctx(st, RNG.new(1))
	var fake := {
		"settlement_prior": [
			{"condition": {}, "result": {"金币": 1}, "action": {"event_on": 5300601}},
		],
		"settlement": [],
		"settlement_extre": [],
	}
	var res := RiteResolver.resolve(fake, ctx, 0)
	assert_eq(res.prior_log.size(), 1)
	assert_eq(st.coin_count, 1)
	assert_eq(res.deferred.events, [5300601])

func test_settlement_normal_executes_action_after_result():
	var st := GameState.new()
	var ctx := _make_ctx(st, RNG.new(1))
	var fake := {
		"settlement": [
			{"condition": {}, "result": {"金币": 1}, "action": {"rite": 5000001}},
		],
	}
	var res := RiteResolver.resolve(fake, ctx, 0)
	assert_false(res.normal_entry.is_empty())
	assert_eq(st.coin_count, 1)
	assert_eq(res.deferred.rite, 5000001)

func test_settlement_action_can_defer_over():
	var st := GameState.new()
	var ctx := _make_ctx(st, RNG.new(1))
	var fake := {
		"settlement": [
			{"condition": {}, "result": {}, "action": {"over": 1}},
		],
	}
	var res := RiteResolver.resolve(fake, ctx, 0)
	assert_true(res.deferred.over)

func test_settlement_extre_executes_all_results_before_actions():
	var st := GameState.new()
	var ctx := _make_ctx(st, RNG.new(1))
	var fake := {
		"settlement_extre": [
			{"condition": {}, "result": {"金币": 1}, "action": {"金币": 10}},
			{"condition": {}, "result": {"金币": 2}, "action": {"金币": 20}},
		],
	}
	var res := RiteResolver.resolve(fake, ctx, 0)
	assert_eq(res.extre_log.size(), 2)
	assert_eq(res.deferred.logs, [
		"coin +1",
		"coin +2",
		"coin +10",
		"coin +20",
	])
	assert_eq(st.coin_count, 33)
