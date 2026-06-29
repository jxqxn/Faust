extends GutTest

const CounterSystem = preload("res://core/counter.gd")
const TagSystem = preload("res://core/tag.gd")
const LootSystem = preload("res://core/loot.gd")
const ScopeFilter = preload("res://core/scope_filter.gd")
const BranchSystem = preload("res://core/branch.gd")
const RNG = preload("res://core/rng.gd")

# ---- Counter (vc#8) ----
func test_counter_parse_keys():
	var r := CounterSystem.parse_key("counter+7000001")
	assert_eq(r.id, 7000001)
	assert_eq(r.op, CounterSystem.Op.ADD)
	assert_false(r.global)
	var s := CounterSystem.parse_key("counter-7100001")
	assert_eq(s.op, CounterSystem.Op.SUB)
	var st := CounterSystem.parse_key("counter=7000002")
	assert_eq(st.op, CounterSystem.Op.SET)
	var g := CounterSystem.parse_key("global_counter+7200131")
	assert_true(g.global)
	assert_eq(g.id, 7200131)

func test_counter_apply_ops():
	assert_eq(CounterSystem.apply(5, 3, CounterSystem.Op.ADD), 8)
	assert_eq(CounterSystem.apply(5, 3, CounterSystem.Op.SUB), 2)
	assert_eq(CounterSystem.apply(5, 10, CounterSystem.Op.SET), 10)
	assert_eq(CounterSystem.apply(5, 3, CounterSystem.Op.NONE), 5)

# ---- Tag (vc#15, pitfall#5: no clamp) ----
func test_tag_add_sub_set():
	var tags := {"智慧": 3}
	TagSystem.apply(tags, "智慧", TagSystem.Op.ADD, 2)
	assert_eq(TagSystem.get_value(tags, "智慧"), 5)
	TagSystem.apply(tags, "智慧", TagSystem.Op.SUB, 1)
	assert_eq(TagSystem.get_value(tags, "智慧"), 4)
	# Sub to zero removes the tag entirely (no clamp-to-zero kept).
	TagSystem.apply(tags, "智慧", TagSystem.Op.SUB, 10)
	assert_false(tags.has("智慧"), "sub to <=0 removes tag")
	# Set on a fresh tag.
	TagSystem.apply(tags, "体魄", TagSystem.Op.SET, 4)
	assert_eq(TagSystem.get_value(tags, "体魄"), 4)
	# Tags can go negative? No — SUB removes at <=0 (GetTag>0 guard). But ADD on
	# a tag whose source value is negative is allowed (no global clamp). Verify
	# get_value defaults to 0 for missing tags.
	assert_eq(TagSystem.get_value(tags, "不存在"), 0)

func test_tag_op_from_char():
	assert_eq(TagSystem.op_from_char("+"), TagSystem.Op.ADD)
	assert_eq(TagSystem.op_from_char("-"), TagSystem.Op.SUB)
	assert_eq(TagSystem.op_from_char("="), TagSystem.Op.SET)
	assert_eq(TagSystem.op_from_char("x"), -1)

# ---- Loot (vc#5-#7) ----
func test_loot_simple_weight_distribution():
	var rng := RNG.new(321)
	var node := {
		"type": 2,
		"repeat": 2000,
		"item": [
			{"id": "1001", "weight": 30},
			{"id": "1002", "weight": 70},
		]
	}
	var out := LootSystem.generate(rng, node)
	assert_eq(out.size(), 2000)
	var c1 := out.count(1001)
	var c2 := out.count(1002)
	# 30/70 split: 1002 should dominate.
	assert_gt(c2, c1)
	var ratio := float(c2) / float(c1)
	assert_between(ratio, 1.8, 2.6, "70/30 ~ 2.33")

func test_loot_type3_exclude_already_have():
	var rng := RNG.new(9)
	var node := {
		"type": 3,
		"repeat": 1,
		"item": [
			{"id": "1001", "weight": 50},
			{"id": "1002", "weight": 50},
		]
	}
	# Own 1001 -> only 1002 available.
	var out := LootSystem.generate(rng, node, [1001])
	assert_eq(out.size(), 1)
	assert_eq(out[0], 1002)
	# Own both -> empty filtered set -> nothing.
	var out2 := LootSystem.generate(rng, node, [1001, 1002])
	assert_eq(out2.size(), 0)

func test_loot_type99_condition_gated():
	var rng := RNG.new(1)
	var node := {
		"type": 99,
		"repeat": 1,
		"item": [
			{"id": "1001"},
			{"id": "1002"},
			{"id": "1003"},
		]
	}
	# condition passes only id 1002.
	var cond := func(it): return int(it.get("id")) == 1002
	var out := LootSystem.generate(rng, node, [], cond)
	assert_eq(out, [1002])

func test_loot_type4_weighted_n_choose_m_no_replacement():
	var rng := RNG.new(5)
	var node := {
		"type": 4,
		"item": [
			{"id": "1001", "weight": 100, "num": "1"},
			{"id": "1002", "weight": 100, "num": "1"},
			{"id": "1003", "weight": 100, "num": "1"},
		]
	}
	# M = 3 = pool size -> all drawn, no dupes.
	var out := LootSystem.generate(rng, node)
	assert_eq(out.size(), 3)
	var uniq := {}
	for id in out:
		uniq[id] = true
	assert_eq(uniq.size(), 3, "no duplicates (without replacement)")

# ---- ScopeFilter (vc#11-#12) ----
func test_scope_parse_and_targets():
	assert_eq(ScopeFilter.parse_scope("friend"), ScopeFilter.Friend)
	assert_eq(ScopeFilter.parse_scope("enemy"), ScopeFilter.Enemy)
	assert_eq(ScopeFilter.parse_scope("all"), ScopeFilter.All)
	assert_eq(ScopeFilter.parse_scope("self"), ScopeFilter.Self)
	assert_eq(ScopeFilter.parse_scope("parent"), ScopeFilter.Parent)
	# All bitmask = Friend|Enemy.
	assert_eq(ScopeFilter.scope_targets(ScopeFilter.All), "all")
	assert_eq(ScopeFilter.scope_targets(ScopeFilter.Friend), "friend/enemy")
	assert_eq(ScopeFilter.scope_targets(ScopeFilter.Self), "self")
	assert_eq(ScopeFilter.scope_targets(0), "all")

func test_scope_ismatch_card_id():
	var card := {"id": 2000460, "tags": {}}
	assert_true(ScopeFilter.is_match(card, {"flags": ScopeFilter.FLAG_CARD_ID, "card_id": 2000460}).match)
	assert_false(ScopeFilter.is_match(card, {"flags": ScopeFilter.FLAG_CARD_ID, "card_id": 999}).match)
	# Lost card excluded.
	var lost := {"id": 2000460, "tags": {}, "is_lost": true}
	assert_false(ScopeFilter.is_match(lost, {"flags": ScopeFilter.FLAG_CARD_ID, "card_id": 2000460}).match)

func test_scope_ismatch_tag():
	var card := {"id": 1, "tags": {"智慧": 3}}
	assert_true(ScopeFilter.is_match(card, {"flags": ScopeFilter.FLAG_TAG, "tags": {"智慧": 2}}).match)
	assert_false(ScopeFilter.is_match(card, {"flags": ScopeFilter.FLAG_TAG, "tags": {"智慧": 5}}).match)

# ---- Branch (vc#13-#14) ----
func test_choose_operations_count_lt_one_empty():
	var rng := RNG.new(1)
	assert_eq(BranchSystem.choose_operations(rng, ["a","b","c"], 0), [])

func test_choose_operations_count_gte_list_returns_all():
	var rng := RNG.new(1)
	var ops := ["a","b","c"]
	var r := BranchSystem.choose_operations(rng, ops, 3)
	assert_eq(r.size(), 3)
	r = BranchSystem.choose_operations(rng, ops, 5)
	assert_eq(r.size(), 3)

func test_choose_operations_takes_n_shuffled():
	var rng := RNG.new(7)
	var ops := ["a","b","c","d","e"]
	var r := BranchSystem.choose_operations(rng, ops, 2)
	assert_eq(r.size(), 2)
	# All chosen must come from original set.
	for o in r:
		assert_true(o in ops)

func test_random_operations_counts_exact_hits():
	var rng := RNG.new(2)
	var ops := ["a","b","c","d","e"]
	# dice cache: 2 dice hit point 5 exactly.
	var out := BranchSystem.random_operations(rng, ops, [5, 5, 3, 1], 5)
	assert_eq(out.size(), 2)
	for o in out:
		assert_true(o in ops)
	# Zero hits -> empty.
	assert_eq(BranchSystem.random_operations(rng, ops, [1,2,3], 5), [])
	# Hits exceed list size -> whole list.
	var big := BranchSystem.random_operations(rng, ops, [5,5,5,5,5,5], 5)
	assert_eq(big.size(), 5)
