## Condition DSL evaluator.
## Dispatch table transcribed from dump.cs [Condition(...)] attributes (lines 416xxx).
## Handles the keys that appear in rite settlement conditions:
##   r1:/f: attribute/dice checks -> FuncCompare
##   counter.<id><op> / global_counter.<id><op>
##   s<n> / !s<n> (slot presence)  s<n>.is <id>  s<n>.<tag>
##   have.<tag> / !have.<tag>  table_have.<id> / !table_have.<id>
##   hand_have / sudan_pool_have
##   is / rare / type / round / difficulty
##   any{...} / all{...}  (logical groups)
## Every comparison op set: >= <= <> != = < >
class_name ConditionEval
extends RefCounted

# Op set used across counter/slot/attribute conditions.
const OPS := [">=", "<=", "<>", "!=", "=", "<", ">"]


## Evaluate a condition dictionary. Returns true if ALL top-level keys match
## (AND semantics). `ctx` carries: db, state, rng, rite_state{s1..s4->card_id},
## dice_cache, gold_dice_used.
static func evaluate(cond: Dictionary, ctx: Dictionary) -> bool:
	for key in cond:
		var val = cond[key]
		if not eval_key(key, val, ctx):
			return false
	return true


## Evaluate a single condition key.
static func eval_key(key: String, val: Variant, ctx: Dictionary) -> bool:
	var k := key.strip_edges()
	# Logical groups.
	if k == "any":
		return eval_any(val, ctx)
	if k == "all":
		return eval_all(val, ctx)
	# FuncCompare: (f|r\d*):<expr><op>  -> dice/attribute check.
	# val is [X, Y] for r1 (X=needed, Y=success line) or a number for f.
	if k.match("r*:*") or k.match("f:*") or k.begins_with("r1:") or k.begins_with("f:"):
		return eval_funccompare(k, val, ctx)
	# counter.<id><op>
	if k.begins_with("counter."):
		return eval_counter(k, val, ctx, false)
	if k.begins_with("global_counter."):
		return eval_counter(k, val, ctx, true)
	# slot presence / slot.is / slot.<tag>
	if k.begins_with("s") and (k.length() > 1 and k[1].is_valid_int()):
		return eval_slot(k, val, ctx)
	if (k.begins_with("!s") or k.begins_with("~s")) and (k.length() > 2 and k[2].is_valid_int()):
		return eval_slot(k, val, ctx)
	# have / !have
	if k.begins_with("have.") or k == "have":
		return eval_have(k, val, ctx, false)
	if k.begins_with("!have.") or k == "!have":
		return not eval_have(k.substr(1), val, ctx, false)
	# hand_have
	if k.begins_with("hand_have") or k.begins_with("!hand_have"):
		return eval_hand_have(k, val, ctx)
	# table_have / !table_have
	if k.begins_with("table_have.") or k.begins_with("!table_have."):
		return eval_table_have(k, val, ctx)
	# sudan_pool_have
	if k.begins_with("sudan_pool_have") or k.begins_with("!sudan_pool_have"):
		return eval_sudan_pool_have(k, val, ctx)
	# CanLoot checks whether this loot has at least one currently generatable
	# item. Negative form is used by the book-search variants once the only-new
	# pool is exhausted.
	# [SRC: decompiled/CanLoot.c @ CheckInternal (RVA 0x4ee990)]
	if k == "!loot":
		return not DeferredEffects.can_generate_loot(int(val), ctx)
	if k == "loot":
		return DeferredEffects.can_generate_loot(int(val), ctx)
	# `!rite` is an existence test against runtime RiteInstances, not the JSON
	# definition database. A configured rite which has never been created must
	# still satisfy the negative condition.
	if k == "!rite":
		var rite_state = ctx.get("state")
		return rite_state == null or rite_state.find_rite_instance_by_id(int(val)) == null
	# is (card id match against the acting card)
	if k == "is":
		return eval_is(val, ctx)
	if k == "!is":
		return not eval_is(val, ctx)
	# Acting-card checks used by rite slot conditions and card pop conditions.
	if k == "type":
		return eval_type(val, ctx)
	if k == "!type":
		return not eval_type(val, ctx)
	if k == "rare":
		return eval_rare(val, ctx)
	if k.begins_with("rare"):
		var card_rare: Dictionary = ctx.get("acting_card", {})
		var parsed_rare := _split_name_op(k)
		return apply_compare(int(card_rare.get("rare", 0)), int(val), parsed_rare.op)
	# round
	if k == "round":
		var st = ctx.get("state")
		return st.round_number == int(val)
	# difficulty
	if k == "difficulty":
		var st2 = ctx.get("state")
		return st2.difficulty_index == int(val)
	if k == "金币" or k == "coin" or k == "g.coin":
		var st_coin = ctx.get("state")
		return st_coin != null and int(st_coin.coin_count) >= int(val)
	if k.begins_with("cost."):
		return eval_cost(k, val, ctx)
	# rite (current rite id)
	if k == "rite" or k == "is_rite":
		return int(ctx.get("rite_id", 0)) == int(val)
	if _can_eval_acting_tag(k, ctx):
		return eval_acting_tag(k, val, ctx)
	if _can_eval_state_tag(k, ctx):
		return eval_state_tag(k, val, ctx)
	# Fallback: unknown key -> conservative false (log).
	push_warning("ConditionEval: unhandled key '%s'" % k)
	return false


## Return whether the audit can point at a concrete evaluator branch for `key`.
## Bare keys are generic tag checks at runtime, but only count as supported
## when the caller can prove the tag exists in loaded data. This keeps typos
## such as an unimplemented control key out of the supported bucket.
static func is_supported_key(key: String, known_tags: Dictionary = {}) -> bool:
	var k := key.strip_edges()
	if k in ["any", "all", "have", "!have", "is", "!is", "type", "!type", "rare", "round", "difficulty", "rite", "!rite", "is_rite", "loot", "!loot", "金币", "coin", "g.coin"]:
		return true
	if k.begins_with("rare"):
		return true
	if k.begins_with("cost."):
		return true
	if k.match("r*:*") or k.match("f:*") or k.begins_with("r1:") or k.begins_with("f:"):
		return true
	if k.begins_with("counter.") or k.begins_with("global_counter."):
		return true
	if k.begins_with("s") and (k.length() > 1 and k[1].is_valid_int()):
		return true
	if (k.begins_with("!s") or k.begins_with("~s")) and (k.length() > 2 and k[2].is_valid_int()):
		return true
	if k.begins_with("have.") or k.begins_with("!have."):
		return true
	if k.begins_with("hand_have") or k.begins_with("!hand_have"):
		return true
	if k.begins_with("table_have.") or k.begins_with("!table_have."):
		return true
	if k.begins_with("sudan_pool_have") or k.begins_with("!sudan_pool_have"):
		return true
	return _is_known_generic_tag_condition(k, known_tags)


static func _is_known_generic_tag_condition(key: String, known_tags: Dictionary) -> bool:
	if known_tags.is_empty():
		return false
	var bare := key.lstrip("!~")
	if bare.is_empty() or "." in bare or ":" in bare:
		return false
	var parsed := _split_name_op(bare)
	return known_tags.has(str(parsed.name))


static func eval_any(group: Dictionary, ctx: Dictionary) -> bool:
	for key in group:
		if eval_key(key, group[key], ctx):
			return true
	return false


static func eval_all(group: Dictionary, ctx: Dictionary) -> bool:
	for key in group:
		if not eval_key(key, group[key], ctx):
			return false
	return true


# Extract the op and split "prefix" / "id" / "rest" from a key like
# "counter.7000001>=" or "global_counter.7200131=".
# Returns {prefix, num, op} or {}.
static func _split_num_op(k: String, prefix: String) -> Dictionary:
	var rest := k.substr(prefix.length())
	# rest like "7000001>=" ; find where digits end.
	var i := 0
	while i < rest.length() and rest[i].is_valid_int():
		i += 1
	var num_str := rest.substr(0, i)
	var op_str := rest.substr(i)
	if op_str.is_empty():
		op_str = "="
	return {"num": num_str.to_int(), "op": op_str}


static func eval_counter(k: String, val: Variant, ctx: Dictionary, is_global: bool) -> bool:
	var st = ctx.get("state")
	var parsed := _split_num_op(k, "global_counter." if is_global else "counter.")
	var id: int = parsed.num
	var op: String = parsed.op
	var cur: int = st.get_global_counter(id) if is_global else st.get_counter(id)
	return apply_compare(cur, int(val), op)


static func eval_funccompare(k: String, val: Variant, ctx: Dictionary) -> bool:
	# k: "r1:智慧+社交>="  or  "f:智慧+社交>=3"
	var is_r := k.begins_with("r")
	var colon := k.find(":")
	var type_key := k.substr(0, colon)
	var after := k.substr(colon + 1)
	# Find the op at the end of after.
	var op := "="
	var expr := after
	var op_idx := -1
	for cand in OPS:
		var idx := after.find(cand)
		if idx > 0:
			if op_idx < 0 or idx > op_idx:
				op_idx = idx
				op = cand
	if op_idx > 0:
		expr = after.substr(0, op_idx)
	expr = expr.strip_edges()
	# Evaluate the attribute expression against the slotted cards.
	var attr_val := eval_attr_expr(expr, ctx)
	if is_r:
		# val is [X, Y]: X=needed successes, Y=success line.
		# Defensive: a malformed r1 config may supply a scalar instead of a
		# 2-element array. Fail the condition rather than crashing resolution.
		if not (val is Array) or val.size() < 2:
			push_warning("ConditionEval: r1 condition '%s' expects a 2-element array value" % k)
			return false
		var arr: Array = val
		var x: int = int(arr[0])
		var y: int = int(arr[1])
		var st = ctx.get("state")
		var weights: Array = GameModels.difficulty_weights(st.difficulty_config)
		var rng = ctx.get("rng")
		var raw_gold = ctx.get("gold_dice_used", 0)
		var gold := 0 if raw_gold is Dictionary else int(raw_gold)
		# Per-type gold dice scoping: the original keys goldDiceCounts by the
		# FuncCompare type string. A scalar gold_dice_used applies to all types.
		# [SRC: FuncCompare.c @ IsSatisfied: goldDiceCounts[type] keyed by param_1+0x20]
		var gold_map = ctx.get("gold_dice_map", {})
		if gold_map is Dictionary and gold_map.size() > 0:
			gold = int(gold_map.get(type_key, gold))
		var dice_cache: Dictionary = ctx.get("dice_cache", {})
		if not ctx.has("dice_cache"):
			ctx["dice_cache"] = dice_cache
		if not dice_cache.has(type_key):
			var rolls: Array[int] = []
			for i in maxi(attr_val, 0):
				rolls.append(Dice.roll_weighted_face(rng, weights))
			dice_cache[type_key] = rolls
		var successes := 0
		for face in dice_cache.get(type_key, []):
			if int(face) >= y:
				successes += 1
		var types_seen: Array = ctx.get("dice_types_seen", [])
		if not (type_key in types_seen):
			types_seen.append(type_key)
			ctx["dice_types_seen"] = types_seen
		return Dice.apply_compare(successes + maxi(gold, 0), x, op)
	else:
		# f: pure attribute compare against val.
		return apply_compare(attr_val, int(val), op)


## Evaluate an attribute expression like "智慧+社交" or "体魄" against the
## slotted cards in ctx. Sum the named attributes across the acting slot cards.
## (Full infix parser is a future refinement; rite configs use name+name sums.)
static func eval_attr_expr(expr: String, ctx: Dictionary) -> int:
	var st = ctx.get("state")
	var rite_uid := int(ctx.get("rite_uid", 0))
	# Collect attribute names split on +/-/*.
	var tokens: Array = []
	var signs: Array = []
	var cur := ""
	var current_sign := 1
	for ch in expr:
		if ch == "+":
			tokens.append(cur)
			signs.append(current_sign)
			cur = ""
			current_sign = 1
		elif ch == "-":
			tokens.append(cur)
			signs.append(current_sign)
			cur = ""
			current_sign = -1
		elif ch == "*":
			# Multiplication not common in rite configs; treat separator.
			tokens.append(cur)
			signs.append(current_sign)
			cur = ""
			current_sign = 1
		else:
			cur += ch
	tokens.append(cur)
	signs.append(current_sign)
	if bool(ctx.get("acting_card_only", false)):
		var acting_card: Dictionary = ctx.get("acting_card", {})
		var acting_tags: Dictionary = acting_card.get("tag", {})
		var acting_total := 0
		for i in tokens.size():
			var attr_name2: String = tokens[i].strip_edges()
			if attr_name2.is_empty():
				continue
			acting_total += signs[i] * int(acting_tags.get(attr_name2, 0))
		return acting_total
	# Sum across acting slots (s1, s2 by default; ctx may specify slot list).
	var slots: Array = ctx.get("attr_slots", ["s1", "s2"])
	var total := 0
	for i in tokens.size():
		var attr_name: String = tokens[i].strip_edges()
		if attr_name.is_empty():
			continue
		var s := 0
		for slot_key in slots:
			for tc in st.cards_in_slot(_slot_num(slot_key), rite_uid):
				s += int(tc.get("tags", {}).get(attr_name, 0))
		total += signs[i] * s
	return total


static func _slot_num(slot_key: String) -> int:
	if slot_key.begins_with("s"):
		return slot_key.substr(1).to_int()
	return 0


static func eval_slot(k: String, val: Variant, ctx: Dictionary) -> bool:
	var st = ctx.get("state")
	var rite_uid := int(ctx.get("rite_uid", 0))
	var negate := k.begins_with("!") or k.begins_with("~")
	var kk := k.lstrip("!~")
	# "s1" presence, "s1.is <id>", "s1.<tag>"
	if "." in kk:
		var dot := kk.find(".")
		var slot_num := kk.substr(1, dot - 1).to_int()
		var rest := kk.substr(dot + 1)
		var cards: Array = st.cards_in_slot(slot_num, rite_uid)
		if rest == "is":
			var want_id := int(val)
			var found := false
			for tc in cards:
				if int(tc.get("id", 0)) == want_id:
					found = true
					break
			return found if not negate else not found
		if rest == "type":
			var want_type := str(val)
			var f2 := false
			var db = ctx.get("db")
			for tc in cards:
				if db.get_card(int(tc.get("id",0))).get("type","") == want_type:
					f2 = true
					break
			return f2 if not negate else not f2
		if rest.begins_with("rare"):
			var parsed_rare := _split_name_op(rest)
			var want_rare := int(val)
			var f_rare := false
			var db_rare = ctx.get("db")
			for tc in cards:
				var card_rare: Dictionary = db_rare.get_card(int(tc.get("id", 0)))
				if apply_compare(int(card_rare.get("rare", 0)), want_rare, parsed_rare.op):
					f_rare = true
					break
			return f_rare if not negate else not f_rare
		# rest is a tag name: check the slot card has that tag >= val.
		var tag_query := _split_name_op(rest)
		var tag_name := str(tag_query.name)
		var need := int(val)
		var ok := false
		for tc in cards:
			if apply_compare(int(tc.get("tags", {}).get(tag_name, 0)), need, tag_query.op):
				ok = true
				break
		return ok if not negate else not ok
	# plain "s1" -> presence.
	var slot_num2 := kk.substr(1).to_int()
	var present: bool = st.slot_has_cards(slot_num2)
	return present if not negate else not present


static func eval_have(k: String, val: Variant, ctx: Dictionary, _is_hand: bool) -> bool:
	var st = ctx.get("state")
	var db = ctx.get("db")
	# "have.妻子" -> hand has a card with tag 妻子.
	# "have.2000005" -> hand has card id 2000005.
	var rest := k.substr("have.".length() if k.begins_with("have.") else "have".length())
	if rest.is_empty():
		return st.hand.size() > 0
	if "." in rest:
		var parts := rest.split(".", false, 1)
		if parts.size() == 2 and str(parts[0]).is_valid_int():
			var want_id := str(parts[0]).to_int()
			var tag_name := str(parts[1])
			for card_uid in st.hand:
				var card: Dictionary = st.card_data_for(int(card_uid), db)
				if int(card.get("id", 0)) != want_id:
					continue
				return int(card.get("tag", {}).get(tag_name, 0)) >= int(val)
			return false
	if rest.is_valid_int():
		return st.hand_has_card_id(rest.to_int())
	return st.hand_has_tag(db, rest)


static func eval_hand_have(k: String, val: Variant, ctx: Dictionary) -> bool:
	var neg := k.begins_with("!")
	var kk := k.lstrip("!")
	# hand_have behaves like have but explicit.
	var r := eval_have(kk.replace("hand_have", "have"), val, ctx, true)
	return r if not neg else not r


static func eval_table_have(k: String, _val: Variant, ctx: Dictionary) -> bool:
	var st = ctx.get("state")
	var neg := k.begins_with("!")
	var kk := k.substr(1) if neg else k
	var rest := kk.substr("table_have.".length())
	var want_id := rest.to_int()
	# Card on the table (any slot)?
	var found := false
	for tc in st.surface_card_entries():
		if int(tc.get("id",0)) == want_id:
			found = true
			break
	return found if not neg else not found


static func eval_sudan_pool_have(k: String, _val: Variant, ctx: Dictionary) -> bool:
	var st = ctx.get("state")
	var neg := k.begins_with("!")
	var kk := k.substr(1) if neg else k
	var rest := kk.substr("sudan_pool_have.".length() if "sudan_pool_have." in kk else "sudan_pool_have".length())
	# Check sudan deck contains the card.
	var want_id := rest.to_int() if rest.is_valid_int() else 0
	if want_id == 0:
		return false if not neg else true
	var found: bool = want_id in st.sudan_deck
	return found if not neg else not found


static func eval_is(val: Variant, ctx: Dictionary) -> bool:
	# 'is' matches the acting card id (the card being placed/checked).
	var acting := int(ctx.get("acting_card_id", 0))
	if acting == 0 and ctx.has("acting_card"):
		acting = int((ctx.get("acting_card", {}) as Dictionary).get("id", 0))
	return acting == int(val)


static func eval_type(val: Variant, ctx: Dictionary) -> bool:
	var card: Dictionary = ctx.get("acting_card", {})
	return str(card.get("type", "")) == str(val)


static func eval_rare(val: Variant, ctx: Dictionary) -> bool:
	var card: Dictionary = ctx.get("acting_card", {})
	return int(card.get("rare", 0)) == int(val)


static func eval_cost(k: String, val: Variant, ctx: Dictionary) -> bool:
	# In slot prechecks, cost.* means the dragged card/resource must be able to
	# satisfy that resource tag; exact consumption is handled by result/action.
	var card: Dictionary = ctx.get("acting_card", {})
	var tag_name := k.substr("cost.".length())
	var tags: Dictionary = card.get("tag", {})
	if val is Array:
		return int(tags.get(tag_name, 0)) >= int(val[0])
	return int(tags.get(tag_name, 0)) >= int(val)


static func _can_eval_acting_tag(k: String, ctx: Dictionary) -> bool:
	if not ctx.has("acting_card"):
		return false
	var kk := k.lstrip("!~")
	return not kk.is_empty() and not ("." in kk) and not (":" in kk)


static func eval_acting_tag(k: String, val: Variant, ctx: Dictionary) -> bool:
	var neg := k.begins_with("!") or k.begins_with("~")
	var parsed := _split_name_op(k.lstrip("!~"))
	var tag_name := str(parsed.name)
	var card: Dictionary = ctx.get("acting_card", {})
	var tags: Dictionary = card.get("tag", {})
	var ok := apply_compare(int(tags.get(tag_name, 0)), int(val), parsed.op)
	return ok if not neg else not ok


static func _can_eval_state_tag(k: String, ctx: Dictionary) -> bool:
	var kk := k.lstrip("!~")
	return ctx.has("state") and ctx.has("db") and not kk.is_empty() and not ("." in kk) and not (":" in kk)


static func eval_state_tag(k: String, val: Variant, ctx: Dictionary) -> bool:
	var neg := k.begins_with("!") or k.begins_with("~")
	var parsed := _split_name_op(k.lstrip("!~"))
	var tag_name := str(parsed.name)
	var st = ctx.get("state")
	var db = ctx.get("db")
	var need := int(val)
	var ok := false
	if st != null:
		for card_uid in st.hand:
			var card: Dictionary = st.card_data_for(int(card_uid), db)
			if apply_compare(int(card.get("tag", {}).get(tag_name, 0)), need, parsed.op):
				ok = true
				break
	if not ok and st != null:
		for tc in st.surface_card_entries():
			if apply_compare(int(tc.get("tags", {}).get(tag_name, 0)), need, parsed.op):
				ok = true
				break
	return ok if not neg else not ok


static func _split_name_op(k: String) -> Dictionary:
	for op in OPS:
		var idx := k.find(op)
		if idx > 0:
			return {"name": k.substr(0, idx), "op": op}
	return {"name": k, "op": ">="}


static func apply_compare(a: int, b: int, op: String) -> bool:
	match op:
		">=":
			return a >= b
		"<=":
			return a <= b
		">":
			return a > b
		"<":
			return a < b
		"=", "==":
			return a == b
		"!=":
			return a != b
		"<>":
			return a != b
	push_warning("ConditionEval: unknown op '%s'" % op)
	return false
