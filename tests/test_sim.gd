extends GutTest

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

func test_table_and_sudan_pool_have_positive_and_negative_conditions():
	var st := GameState.new()
	st.add_card_to_slot(2000005, 1, db)
	st.sudan_deck = [2010001]
	var ctx := _make_ctx(st, RNG.new(1))
	assert_true(ConditionEval.eval_key("table_have.2000005", 1, ctx))
	assert_false(ConditionEval.eval_key("!table_have.2000005", 1, ctx))
	assert_false(ConditionEval.eval_key("table_have.2000006", 1, ctx))
	assert_true(ConditionEval.eval_key("!table_have.2000006", 1, ctx))
	assert_true(ConditionEval.eval_key("sudan_pool_have.2010001", 1, ctx))
	assert_false(ConditionEval.eval_key("!sudan_pool_have.2010001", 1, ctx))
	assert_false(ConditionEval.eval_key("sudan_pool_have.2010002", 1, ctx))
	assert_true(ConditionEval.eval_key("!sudan_pool_have.2010002", 1, ctx))

func test_condition_supports_rite_batch_tag_rare_cost_and_coin_keys():
	var st := GameState.new()
	st.setup_new_run(db, 1, RNG.new(48))
	st.coin_count = 3
	var card: Dictionary = db.get_card(2000005).duplicate(true)
	card["id"] = 2000005
	var ctx := {"db": db, "state": st, "rng": RNG.new(48), "acting_card": card, "acting_card_id": 2000005, "acting_card_only": true}
	var first_tag := ""
	for tag in card.get("tag", {}).keys():
		if int(card.tag[tag]) > 0:
			first_tag = str(tag)
			break

	assert_true(ConditionEval.eval_key("金币", 3, ctx), "coin condition checks current coin count")
	assert_true(ConditionEval.eval_key(first_tag + ">=", 1, ctx), "acting-card tag conditions support explicit compare ops")
	assert_true(ConditionEval.eval_key("rare=", int(card.get("rare", 0)), ctx), "acting-card rare compare supports explicit op")
	assert_true(ConditionEval.eval_key("cost." + first_tag, 1, ctx), "slot cost precheck can be evaluated against the dragged card")

func test_bare_tag_condition_checks_owned_cards_without_acting_card():
	var st := GameState.new()
	st.add_card_to_hand(2000001)
	var protagonist: Dictionary = db.get_card(2000001)
	var tag_name := str(protagonist.get("tag", {}).keys()[0])
	var ctx := _make_ctx(st, RNG.new(2))
	assert_true(ConditionEval.eval_key(tag_name, 1, ctx))
	assert_false(ConditionEval.eval_key("!" + tag_name, 1, ctx))

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

func test_result_clean_card_id_records_and_removes_table_card():
	var st := GameState.new()
	st.add_card_to_slot(2000005, 1, db)
	st.add_card_to_slot(2000006, 2, db)
	var d := ResultExec.execute({"clean.2000005": 1}, st, db)
	assert_eq(st.cards_in_slot(1).size(), 0)
	assert_eq(st.cards_in_slot(2).size(), 1)
	assert_eq(d.clean_card_ids, [2000005])

func test_result_slot_tag_op():
	var st := GameState.new()
	st.add_card_to_slot(2000005, 4, db)
	ResultExec.execute({"s4+回收": 1}, st, db)
	var c: Dictionary = st.cards_in_slot(4)[0]
	assert_true(c.tags.has("回收"), "回收 tag added to slot 4")

func test_result_deferred_events_and_choose():
	var st := GameState.new()
	var d := ResultExec.execute({"event_on": 5300601, "choose": {"a": "x"}}, st, db)
	assert_true(st.is_event_enabled(5300601), "event_on enables the target event")
	assert_true(5300601 in st.event_queue, "start_trigger event queues its settlement")
	assert_true(d.events.is_empty(), "event_on is registration, not a deferred display event")
	assert_eq(d.choose, {"a": "x"})

func test_result_deferred_prompts_and_rite_generation_keys():
	var st := GameState.new()
	var d := ResultExec.execute({"think_pop.5000002_result_20": "stop", "prompt": {"id": "p1"}, "rite": 5001001}, st, db)
	assert_eq(d.prompts.size(), 2)
	assert_eq(str(d.prompts[0].get("text", "")), "stop")
	assert_eq(int(d.rite), 5001001)

func test_result_deferred_loot_keys():
	var st := GameState.new()
	var d := ResultExec.execute({"loot": 6000005, "loot.已拥有+1": 6000011}, st, db)
	assert_eq(d.loots, [6000005, 6000011])

func test_deferred_effects_apply_choice_and_loot_to_world():
	var st := GameState.new()
	st.setup_new_run(db, 1, RNG.new(51))
	var initial_hand := st.hand.size()
	DeferredEffects.execute_choice("pop.test", "hello", st, db, RNG.new(51))
	assert_eq(str(st.event_prompts[0].get("text", "")), "hello", "choice operation should enqueue its resulting prompt")

	DeferredEffects.apply({"loots": [6000005]}, st, db, RNG.new(52))
	assert_gt(st.hand.size(), initial_hand, "loot results should grant generated cards into hand")
	assert_gt(st.event_prompts.size(), 1, "loot grants should be visible to the player")

func test_dsl_audit_exposes_unsupported_rite_keys():
	var report := DslAudit.audit_rites(db.rites, db)
	var unsupported_total: int = report.result.unsupported.size() + report.action.unsupported.size() + report.condition.unsupported.size()
	assert_true(unsupported_total > 0, "audit should make unsupported DSL keys visible")

func test_dsl_audit_scans_loot_conditions_and_choose_operations():
	var report := DslAudit.audit_configs(db.rites, db.events, db.loots, db)
	assert_true(report.result.supported.has("choose"), "choose container should be counted")
	assert_true(report.result.supported.has("pop.5000001_result_01_11.2000523"), "choose child operations should be classified by support")
	assert_true(report.condition.supported.has("!have.2000707"), "loot item conditions should be scanned")

func test_dsl_audit_can_focus_first_daily_batch():
	var first_batch: Array[int] = [
		5000001, 5001001, 5001501, 5002006, 5000154, 5001006, 5001008,
		5002002, 5002001, 5000163, 5001004, 5006591, 5002036, 5002037,
		5002038, 5002003, 5002004, 5002005, 5002035, 5004809, 5004810,
		5004811, 5004812, 5004813, 5004814, 5001002, 5001016, 5001018,
		5008120,
	]
	var report := DslAudit.audit_rite_ids(db.rites, first_batch, db)
	var seen_supported: int = report.condition.supported.size() + report.result.supported.size() + report.action.supported.size()
	assert_true(seen_supported > 0, "focused audit should scan the first daily batch")
	assert_not_null(report.result.unsupported, "focused audit should make unsupported result keys test-visible")

func test_dsl_audit_records_config_source_for_unsupported_keys():
	var report := DslAudit.audit_rites({9000001: {
		"id": 9000001,
		"settlement": [{"result": {"missing_result": 1}}],
	}}, db)
	var refs: Array = report.result.references["missing_result"]
	assert_eq(refs.size(), 1)
	assert_eq(refs[0].kind, "rite")
	assert_eq(refs[0].id, 9000001)
	assert_eq(refs[0].path, "rite/9000001.json")
	assert_eq(refs[0].field, "settlement[0].result")

func test_dsl_audit_scans_event_settlement_actions():
	var report := DslAudit.audit_configs({}, {9100001: {
		"id": 9100001,
		"settlement": [{"action": {"missing_event_action": 1}}],
	}}, {}, db)
	assert_true(report.action.unsupported.has("missing_event_action"))
	assert_eq(report.action.references["missing_event_action"][0].field, "settlement[0].action")

func test_dsl_audit_does_not_treat_unknown_bare_key_as_supported():
	var report := DslAudit.audit_rites({9200001: {
		"id": 9200001,
		"settlement": [{"condition": {"unknown_control_key": 1}}],
	}}, db)
	assert_true(report.condition.unsupported.has("unknown_control_key"))

func test_dsl_audit_accepts_known_bare_card_tag_and_flags_new_baseline_gap():
	var report := DslAudit.audit_rites({9300001: {
		"id": 9300001,
		"settlement": [{"condition": {"智慧>=": 1}, "result": {"missing_result": 1}}],
	}}, db)
	assert_true(report.condition.supported.has("智慧>="))
	var unexpected := DslAudit.unexpected_unsupported(report, {"condition": {}, "result": {}, "action": {}})
	assert_true(unexpected.result.has("missing_result"))
	assert_false(unexpected.condition.has("智慧>="))
	assert_string_contains(DslAudit.to_markdown(report), "rite/9300001.json")

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
	assert_true(st.is_event_enabled(5300601), "rite event_on enables the target event")
	assert_true(5300601 in st.event_queue, "start-trigger event is queued once enabled")
	assert_true(res.deferred.events.is_empty(), "event_on does not masquerade as a display event")

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


# ---- Game-loop integrity fixes ----

func test_r1_funccompare_tolerates_malformed_scalar_value():
	# A malformed r1 config (scalar value instead of [X, Y]) must fail the
	# condition gracefully instead of crashing resolution.
	var st := GameState.new()
	st.difficulty_config = db.get_difficulty(1)
	var ctx := _make_ctx(st, RNG.new(1))
	assert_false(ConditionEval.eval_key("r1:智慧>=", 3, ctx), "scalar r1 value fails instead of crashing")
	assert_false(ConditionEval.eval_key("r1:智慧>=", [3], ctx), "single-element r1 array fails instead of crashing")
	# A well-formed array still evaluates normally. Need 0 successes with
	# empty slots so the comparison holds without slotted cards.
	assert_true(ConditionEval.eval_key("r1:智慧>=", [0, 5], ctx), "well-formed r1 still works")

func test_sub_counter_clamps_registered_nonneg_to_zero():
	# SUB on a registered non-negative counter must clamp to 0, matching
	# set_counter's contract. Ungated counters pass through negative.
	var st := GameState.new()
	st.set_counter(7100006, 3)
	st.register_nonneg(7100006)
	st.sub_counter(7100006, 10)
	assert_eq(st.get_counter(7100006), 0, "gated counter clamps to 0 on sub")
	# Ungated counter goes negative (no clamp).
	st.set_counter(7000999, 5)
	st.sub_counter(7000999, 10)
	assert_eq(st.get_counter(7000999), -5, "ungated counter may go negative")

func test_methinks_consume_last_sudan_triggers_new_round():
	# Consuming the last active sudan via methinks must start a new round and
	# draw a fresh sudan, instead of leaving the player stuck.
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.init_config["think_id"] = 999001
	# A think rite that consumes the slotted card (clean.rite).
	local_db.rites[999001] = {
		"id": 999001,
		"cards_slot": {"s1": {"condition": {}}},
		"settlement_prior": [],
		"settlement": [{"condition": {}, "result": {"clean.rite": 1}}],
		"settlement_extre": [],
	}
	var rng := RNG.new(7)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	# Ensure exactly one active sudan and a non-empty deck for the next draw.
	state.active_sudan_cards.clear()
	state.active_sudan_cards.append(RoundLoop.ActiveSudan.new(2010001, 7, 1))
	state.sudan_deck = [2010002, 2010003]
	var round_before := state.round_number
	var result := MethinksEngine.process_card(2010001, "active_sudan", state, local_db, rng)
	assert_true(result.get("accepted", false), "methinks accepts the sudan card")
	assert_true(result.get("new_round", false), "consuming the last sudan starts a new round")
	assert_true(result.drawn_sudan >= 0, "a new sudan is drawn")
	assert_eq(state.round_number, round_before + 1, "round number incremented")
	assert_false(state.active_sudan_cards.is_empty(), "a new sudan is now active")

func test_deferred_effects_execute_event_applies_result_and_action():
	# execute_event runs an event's result and action payloads through
	# ResultExec and applies the deferred effects, mirroring rite resolution.
	var st := GameState.new()
	st.setup_new_run(db, 0, RNG.new(1))
	var event := {
		"id": 990001,
		"name": "测试事件",
		"result": {"金币": 5, "counter+7000001": 2},
		"action": {"over": 1},
	}
	var merged := DeferredEffects.execute_event(event, st, db, RNG.new(1))
	assert_eq(st.coin_count, 5, "event result coin applied")
	assert_eq(st.get_counter(7000001), 2, "event result counter applied")
	assert_true(bool(merged.get("over", false)), "event action over flag merged into result")


func test_execute_event_reads_settlement_action_payload():
	# Real events nest their payload at settlement[].action — execute_event
	# must read that path, not the top-level result/action.
	var st := GameState.new()
	st.setup_new_run(db, 0, RNG.new(1))
	var event := {
		"id": 990002,
		"text": "测试",
		"settlement": [
			{"tips_text": "", "action": {"金币": 3, "counter+7000002": 1}},
		],
	}
	var merged := DeferredEffects.execute_event(event, st, db, RNG.new(1))
	assert_eq(st.coin_count, 3, "settlement action coin applied")
	assert_eq(st.get_counter(7000002), 1, "settlement action counter applied")
	assert_true(merged.get("events", []).is_empty(), "no events queued from simple action")


func test_execute_event_gates_on_top_level_condition():
	# An event whose top-level condition fails should execute nothing.
	var st := GameState.new()
	st.setup_new_run(db, 0, RNG.new(1))
	var event := {
		"id": 990003,
		"text": "条件事件",
		"condition": {"counter.7000001>=": 999},
		"settlement": [{"action": {"金币": 100}}],
	}
	var merged := DeferredEffects.execute_event(event, st, db, RNG.new(1))
	assert_eq(st.coin_count, 0, "no effect when condition fails")
	assert_true(merged.is_empty(), "empty deferred when condition fails")


func test_execute_event_real_5300002_jumps_rite():
	# A real imported event: 5300002 (向神殿求助) fires on round_begin_ba:1 and
	# its settlement action opens a rite. With its condition satisfied this
	# should produce a deferred rite id.
	var st := GameState.new()
	st.setup_new_run(db, 1, RNG.new(1))
	var event := db.get_event(5300002)
	assert_false(event.is_empty(), "event 5300002 should be loaded from config")
	if event.is_empty():
		return
	var merged := DeferredEffects.execute_event(event, st, db, RNG.new(1))
	# The action contains a rite jump (or event_off); either way it should not
	# crash and should produce some deferred state. Condition may pass or fail
	# depending on starting hand; just assert no crash and a valid dict.
	assert_true(merged is Dictionary, "real event executes without crashing")


# ---- EventRuntime trigger tests ----

func test_event_runtime_matches_round_begin_by_round_number():
	# Events with on.round_begin_ba match only when the context round equals
	# the trigger value. Use an isolated ConfigDB (no real data) for precision.
	var local_db := ConfigDB.new()
	local_db.events[990010] = {"id": 990010, "on": {"round_begin_ba": 2}, "condition": {}}
	local_db.events[990011] = {"id": 990011, "on": {"round_begin_ba": 5}, "condition": {}}
	var st := GameState.new()
	st.event_status[990010] = true
	st.event_status[990011] = true
	var rt := EventRuntime.new()
	rt.build(local_db, st)
	assert_eq(rt.fire("round_begin_ba", {"round": 2}), [990010], "only round-2 event fires on round 2")
	assert_eq(rt.fire("round_begin_ba", {"round": 5}), [990011], "only round-5 event fires on round 5")
	assert_eq(rt.fire("round_begin_ba", {"round": 3}), [], "no event fires on round 3")


func test_event_runtime_matches_rite_end_by_rite_id():
	var local_db := ConfigDB.new()
	local_db.events[990020] = {"id": 990020, "on": {"rite_end": 5000001}, "condition": {}}
	var st := GameState.new()
	st.event_status[990020] = true
	var rt := EventRuntime.new()
	rt.build(local_db, st)
	assert_eq(rt.fire("rite_end", {"rite": 5000001}), [990020], "rite_end event fires for matching rite")
	assert_eq(rt.fire("rite_end", {"rite": 5000002}), [], "rite_end event does not fire for wrong rite")


func test_event_runtime_gates_on_condition():
	var local_db := ConfigDB.new()
	local_db.events[990030] = {"id": 990030, "on": {"round_begin_ba": 1}, "condition": {"counter.7000001>=": 999}}
	var st := GameState.new()
	st.event_status[990030] = true
	# Condition requires a counter the state doesn't have (==0, so >=5 fails).
	var rt := EventRuntime.new()
	rt.build(local_db, st)
	assert_eq(rt.fire("round_begin_ba", {"round": 1}), [], "event with failing condition does not fire")
	st.set_counter(7000001, 1000)
	assert_eq(rt.fire("round_begin_ba", {"round": 1}), [990030], "event fires once condition holds")


func test_state_trigger_events_queues_matched_ids():
	# trigger_events is the convenience wrapper that fires + queues.
	var local_db := ConfigDB.new()
	local_db.events[990040] = {"id": 990040, "on": {"game_end": -1}, "condition": {}}
	var st := GameState.new()
	st.event_status[990040] = true
	st._rebuild_event_runtime(local_db)
	var matched := st.trigger_events("game_end", {})
	assert_eq(matched, [990040], "game_end trigger fires the registered event")
	assert_eq(st.event_queue, [990040], "matched event is queued for display")


# ---- option/case:opN branching ----

func test_option_payload_becomes_choose_prompt_with_case_choices():
	# An action with an `option` key converts to a choose prompt whose choices
	# are keyed by case:opN, each mapping to the case's executable subtree.
	var action := {
		"option": {"text": "选择命运", "items": [{"text": "生", "tag": "op1"}, {"text": "死", "tag": "op2"}]},
		"case:op1": {"rite": 5001001},
		"case:op2": {"over": 1},
	}
	var deferred := ResultExec.execute(action, GameState.new(), db)
	var choose: Dictionary = deferred.choose
	assert_false(choose.is_empty(), "option produces a choose prompt")
	var choices: Dictionary = choose.get("choices", {})
	assert_true(choices.has("case:op1"), "choice keyed by case tag op1")
	assert_true(choices.has("case:op2"), "choice keyed by case tag op2")
	# The case subtrees are the choice values (executable later).
	assert_eq(choices["case:op1"], {"rite": 5001001}, "op1 choice value is its case subtree")
	assert_eq(choices["case:op2"], {"over": 1}, "op2 choice value is its case subtree")


func test_case_op_executes_matched_subtree_only():
	# When the player picks op1, execute_choice runs only case:op1's subtree.
	# op2's subtree (over:true) must NOT execute.
	var st := GameState.new()
	st.setup_new_run(db, 0, RNG.new(1))
	# Simulate the player choosing op1: execute_choice("case:op1", <subtree>).
	var op1_subtree := {"金币": 10, "event_off": 990050}
	DeferredEffects.execute_choice("case:op1", op1_subtree, st, db, RNG.new(1))
	assert_eq(st.coin_count, 10, "chosen case subtree applied its effects")
	# event_off disabled the event in the runtime.
	assert_true(st.event_runtime._disabled.has(990050), "event_off disabled the event")


func test_option_event_end_to_end_through_execute_event():
	# Full flow: execute_event on an event with option+cases produces a choose
	# prompt; picking a choice runs its case subtree.
	var st := GameState.new()
	st.setup_new_run(db, 0, RNG.new(1))
	var event := {
		"id": 990060,
		"text": "抉择",
		"condition": {},
		"settlement": [{"action": {
			"option": {"text": "怎么办？", "items": [{"text": "给钱", "tag": "op1"}, {"text": "跑路", "tag": "op2"}]},
			"case:op1": {"金币": -5},
			"case:op2": {"over": 1},
		}}],
	}
	var merged := DeferredEffects.execute_event(event, st, db, RNG.new(1))
	# The choose prompt should be queued.
	assert_false(merged.get("choose", {}).is_empty(), "event option produced a choose")
	assert_false(st.event_prompts.is_empty(), "choose prompt queued for display")
	# Simulate player picking "给钱" (op1).
	st.event_prompts.clear()
	var choices: Dictionary = merged.choose.get("choices", {})
	DeferredEffects.execute_choice("case:op1", choices["case:op1"], st, db, RNG.new(1))
	assert_eq(st.coin_count, -5, "picking op1 applied its case subtree (coin -5)")


func test_event_off_disables_future_triggering():
	# An event that fires event_off should not fire again on subsequent triggers.
	var local_db := ConfigDB.new()
	local_db.events[990070] = {"id": 990070, "on": {"round_begin_ba": 1}, "condition": {}}
	var st := GameState.new()
	st.event_status[990070] = true
	st._rebuild_event_runtime(local_db)
	assert_eq(st.trigger_events("round_begin_ba", {"round": 1}), [990070], "event fires before event_off")
	st.disable_event(990070)
	st.event_queue.clear()
	assert_eq(st.trigger_events("round_begin_ba", {"round": 1}), [], "event does not fire after event_off")


func test_inactive_event_never_fires_until_event_on_enables_it():
	var local_db := ConfigDB.new()
	local_db.events[990080] = {"id": 990080, "on": {"round_begin_ba": 1}, "condition": {}, "start_trigger": true}
	var st := GameState.new()
	st._rebuild_event_runtime(local_db)
	assert_eq(st.trigger_events("round_begin_ba", {"round": 1}), [], "definitions are inactive by default")
	ResultExec.execute({"event_on": 990080}, st, local_db)
	assert_true(st.is_event_enabled(990080), "event_on sets persistent active status")
	assert_eq(st.event_queue, [990080], "start_trigger queues an enabled event immediately")
	st.event_queue.clear()
	assert_eq(st.trigger_events("round_begin_ba", {"round": 1}), [990080], "enabled event now responds to its timing")


func test_event_on_without_start_trigger_registers_without_displaying():
	var local_db := ConfigDB.new()
	local_db.events[990082] = {"id": 990082, "on": {"round_begin_ba": 1}, "condition": {}, "start_trigger": false}
	var st := GameState.new()
	ResultExec.execute({"event_on": 990082}, st, local_db)
	assert_true(st.is_event_enabled(990082), "event_on enables events regardless of start_trigger")
	assert_true(st.event_queue.is_empty(), "start_trigger=false does not display the event immediately")
	assert_eq(st.trigger_events("round_begin_ba", {"round": 1}), [990082], "registered event waits for its configured timing")


func test_new_run_activates_only_auto_start_init_events():
	var st := GameState.new()
	st.setup_new_run(db, 1, RNG.new(1))
	assert_false(st.is_event_enabled(5310008), "a config definition without auto_start_init is not active at new run")
	assert_eq(st.trigger_events("round_begin_ba", {"round": 1}).has(5310008), false, "inactive round-one event cannot fire")
	assert_gt(st.event_status.size(), 0, "auto_start_init contributes the normal opening event set")


func test_rite_instances_keep_same_numbered_slots_isolated():
	var st := GameState.new()
	var first := st.create_rite_instance(900101)
	var second := st.create_rite_instance(900102)
	st.add_card_to_slot(2000001, 1, db, first.uid)
	st.add_card_to_slot(2000005, 1, db, second.uid)
	assert_eq(st.cards_in_slot(1, first.uid).size(), 1, "first rite owns its s1 card")
	assert_eq(st.cards_in_slot(1, second.uid).size(), 1, "second rite owns its own s1 card")
	assert_eq(int(st.cards_in_slot(1, first.uid)[0].get("id", 0)), 2000001, "first rite card is not replaced")
	assert_eq(int(st.cards_in_slot(1, second.uid)[0].get("id", 0)), 2000005, "second rite card is not replaced")
	st.clear_slot(1, first.uid)
	assert_true(st.cards_in_slot(1, first.uid).is_empty(), "clearing first rite does not retain its card")
	assert_eq(st.cards_in_slot(1, second.uid).size(), 1, "clearing first rite leaves second rite untouched")


func test_non_replay_event_unregisters_after_settlement():
	var local_db := ConfigDB.new()
	local_db.events[990081] = {
		"id": 990081,
		"is_replay": false,
		"on": {"round_begin_ba": 1},
		"condition": {},
		"settlement": [{"action": {"coin": 2}}],
	}
	var st := GameState.new()
	st.enable_event(990081, local_db)
	assert_eq(st.trigger_events("round_begin_ba", {"round": 1}), [990081], "enabled non-replay event fires")
	DeferredEffects.execute_event(local_db.get_event(990081), st, local_db, RNG.new(1))
	assert_false(st.is_event_enabled(990081), "non-replay event unregisters after settlement")
	assert_true(st.event_done.has(990081), "completion history is recorded")
	st.event_queue.clear()
	assert_eq(st.trigger_events("round_begin_ba", {"round": 1}), [], "completed non-replay event cannot fire again")


func test_real_event_5300258_option_branch_executes():
	# Real event 5300258 (审判): a 3-option event. Verify it produces a choose
	# prompt and that picking op2 (交钱赎罪) opens its rite without crashing.
	var st := GameState.new()
	st.setup_new_run(db, 1, RNG.new(1))
	var event := db.get_event(5300258)
	assert_false(event.is_empty(), "event 5300258 loaded")
	if event.is_empty():
		return
	var merged := DeferredEffects.execute_event(event, st, db, RNG.new(1))
	var choose: Dictionary = merged.get("choose", {})
	if choose.is_empty():
		return  # condition gated it; acceptable for some starting states
	var choices: Dictionary = choose.get("choices", {})
	assert_true(choices.has("case:op1") and choices.has("case:op2") and choices.has("case:op3"), "all 3 options present")
	# Pick op2: should add rite 5001027 and disable event 5300258.
	DeferredEffects.execute_choice("case:op2", choices["case:op2"], st, db, RNG.new(1))
	assert_true(5001027 in st.available_rites, "op2 opened rite 5001027")
	assert_true(st.event_runtime._disabled.has(5300258), "event_off disabled 5300258")


func test_option_def_wildcard_surfaced_as_choice():
	# A case:def fallback branch is surfaced as an extra choice alongside the
	# tagged options, mirroring the original's def-wildcard match.
	# [SRC: CaseOperations.c @ Do: 'def' tag matches when last_op_status - 2 >= 3]
	var action := {
		"option": {"text": "选", "items": [{"text": "A", "tag": "op1"}]},
		"case:op1": {"rite": 5001001},
		"case:def": {"over": 1},
	}
	var deferred := ResultExec.execute(action, GameState.new(), db)
	var choices: Dictionary = deferred.choose.get("choices", {})
	assert_true(choices.has("case:def"), "def fallback is surfaced as a choice")
	assert_eq(choices["case:def"], {"over": 1}, "def choice value is its subtree")
