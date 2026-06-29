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

const Dice = preload("res://core/dice.gd")
const GameModels = preload("res://data/models.gd")


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
	# is (card id match against the acting card)
	if k == "is":
		return eval_is(val, ctx)
	if k == "!is":
		return not eval_is(val, ctx)
	# round
	if k == "round":
		var st = ctx.get("state")
		return st.round_number == int(val)
	# difficulty
	if k == "difficulty":
		var st2 = ctx.get("state")
		return st2.difficulty_index == int(val)
	# rite (current rite id)
	if k == "rite" or k == "is_rite":
		return int(ctx.get("rite_id", 0)) == int(val)
	# Fallback: unknown key -> conservative false (log).
	push_warning("ConditionEval: unhandled key '%s'" % k)
	return false


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
			var type_key: String = "r1" if is_r else "f"
			gold = int(gold_map.get(type_key, gold))
		return Dice.is_satisfied(rng, attr_val, y, x, op, weights, gold)
	else:
		# f: pure attribute compare against val.
		return apply_compare(attr_val, int(val), op)


## Evaluate an attribute expression like "智慧+社交" or "体魄" against the
## slotted cards in ctx. Sum the named attributes across the acting slot cards.
## (Full infix parser is a future refinement; rite configs use name+name sums.)
static func eval_attr_expr(expr: String, ctx: Dictionary) -> int:
	var st = ctx.get("state")
	var db = ctx.get("db")
	# Collect attribute names split on +/-/*.
	var tokens: Array = []
	var signs: Array = []
	var cur := ""
	var sign := 1
	for ch in expr:
		if ch == "+":
			tokens.append(cur)
			signs.append(sign)
			cur = ""
			sign = 1
		elif ch == "-":
			tokens.append(cur)
			signs.append(sign)
			cur = ""
			sign = -1
		elif ch == "*":
			# Multiplication not common in rite configs; treat separator.
			tokens.append(cur)
			signs.append(sign)
			cur = ""
			sign = 1
		else:
			cur += ch
	tokens.append(cur)
	signs.append(sign)
	# Sum across acting slots (s1, s2 by default; ctx may specify slot list).
	var slots: Array = ctx.get("attr_slots", ["s1", "s2"])
	var total := 0
	for i in tokens.size():
		var attr_name: String = tokens[i].strip_edges()
		if attr_name.is_empty():
			continue
		var s := 0
		for slot_key in slots:
			for tc in st.cards_in_slot(_slot_num(slot_key)):
				s += int(tc.get("tags", {}).get(attr_name, 0))
		total += signs[i] * s
	return total


static func _slot_num(slot_key: String) -> int:
	if slot_key.begins_with("s"):
		return slot_key.substr(1).to_int()
	return 0


static func eval_slot(k: String, val: Variant, ctx: Dictionary) -> bool:
	var st = ctx.get("state")
	var negate := k.begins_with("!") or k.begins_with("~")
	var kk := k.lstrip("!~")
	# "s1" presence, "s1.is <id>", "s1.<tag>"
	if "." in kk:
		var dot := kk.find(".")
		var slot_num := kk.substr(1, dot - 1).to_int()
		var rest := kk.substr(dot + 1)
		var cards: Array = st.cards_in_slot(slot_num)
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
		# rest is a tag name: check the slot card has that tag >= val.
		var tag_name := rest
		var need := int(val)
		var ok := false
		for tc in cards:
			if int(tc.get("tags", {}).get(tag_name, 0)) >= need:
				ok = true
				break
		return ok if not negate else not ok
	# plain "s1" -> presence.
	var slot_num2 := kk.substr(1).to_int()
	var present: bool = st.slot_has_cards(slot_num2)
	return present if not negate else not present


static func eval_have(k: String, val: Variant, ctx: Dictionary, is_hand: bool) -> bool:
	var st = ctx.get("state")
	var db = ctx.get("db")
	# "have.妻子" -> hand has a card with tag 妻子.
	# "have.2000005" -> hand has card id 2000005.
	var rest := k.substr("have.".length() if k.begins_with("have.") else "have".length())
	if rest.is_empty():
		return st.hand.size() > 0
	if rest.is_valid_int():
		return st.hand_has_card_id(db, rest.to_int())
	return st.hand_has_tag(db, rest)


static func eval_hand_have(k: String, val: Variant, ctx: Dictionary) -> bool:
	var neg := k.begins_with("!")
	var kk := k.lstrip("!")
	# hand_have behaves like have but explicit.
	var r := eval_have(kk.replace("hand_have", "have"), val, ctx, true)
	return r if not neg else not r


static func eval_table_have(k: String, val: Variant, ctx: Dictionary) -> bool:
	var st = ctx.get("state")
	var neg := k.begins_with("!")
	var rest := k.substr("table_have.".length())
	var want_id := rest.to_int()
	# Card on the table (any slot)?
	var found := false
	for tc in st.table_cards:
		if int(tc.get("id",0)) == want_id:
			found = true
			break
	return found if not neg else not found


static func eval_sudan_pool_have(k: String, val: Variant, ctx: Dictionary) -> bool:
	var st = ctx.get("state")
	var neg := k.begins_with("!")
	var rest := k.substr("sudan_pool_have.".length() if "sudan_pool_have." in k else "sudan_pool_have".length())
	# Check sudan deck contains the card.
	var want_id := rest.to_int() if rest.is_valid_int() else 0
	if want_id == 0:
		return false if not neg else true
	var found: bool = want_id in st.sudan_deck
	return found if not neg else not found


static func eval_is(val: Variant, ctx: Dictionary) -> bool:
	# 'is' matches the acting card id (the card being placed/checked).
	var acting := int(ctx.get("acting_card_id", 0))
	return acting == int(val)


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
