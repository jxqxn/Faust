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
	# round (optional comparison suffix, e.g. "round<=")
	if k.begins_with("round"):
		var st = ctx.get("state")
		var suffix := k.substr("round".length())
		if not suffix.is_empty() and not (suffix in OPS):
			return false
		var round_op := "=" if suffix.is_empty() else suffix
		# Original quirk: non-regex conditions only map = < > >= <>; <= and !=
		# fall out of the chain and degrade to Equal. Kept for fidelity.
		# [SRC: ConditionManager.c @ GetCondition (0x3872f0); report 3 A9]
		if round_op == "<=" or round_op == "!=":
			round_op = "="
		return apply_compare(st.round_number, int(val), round_op)
	# rite_end.<id>: the referenced rite finished settlement at least once.
	# [SRC: decompiled/RiteEnd.c @ IsSatisfied (RVA 0x405300)]
	if k.begins_with("rite_end."):
		var st_end = ctx.get("state")
		return st_end != null and st_end.has_method("has_rite_ended") \
			and st_end.has_rite_ended(int(k.substr("rite_end.".length())))
	# rite_have.<rite_id>[.<card_id>][.<name-or-tag>]<op>
	if k.begins_with("rite_have.") or k.begins_with("!rite_have.") or k.begins_with("~rite_have."):
		return eval_rite_have(k, val, ctx)
	# difficulty
	if k == "difficulty":
		var st2 = ctx.get("state")
		return st2.difficulty_index == int(val)
	if k == "金币" or k == "coin" or k == "g.coin":
		var st_coin = ctx.get("state")
		return st_coin != null and int(st_coin.coin_count) >= int(val)
	if k.begins_with("cost."):
		return eval_cost(k, val, ctx)
	# rite = runtime instance existence (any instance whose config id equals
	# the value); is_rite = the current rite's id comparison (IsRiteId).
	# [SRC: HasRite.c @ IsSatisfiedInternal 0x3fdef0 + b__6_0 0x3fe1c0:
	#       any player.rites instance with r.id == Value; IsRiteId.c 0x403070]
	if k == "rite":
		var rite_state = ctx.get("state")
		return rite_state != null and rite_state.find_rite_instance_by_id(int(val)) != null
	if k == "is_rite":
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
	if k.begins_with("rite_end.") or k.begins_with("!rite_end."):
		return true
	if k.begins_with("rite_have.") or k.begins_with("!rite_have.") or k.begins_with("~rite_have."):
		return true
	if k.begins_with("round") and (k.substr(5) == "" or k.substr(5) in OPS):
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
		# No-op-suffix counter keys default to >= in the original.
		# [SRC: HasCounter.c @ ctor (0x3fd8b0) -> Compare.Update(inv, cmp=null)
		#       -> Compare.c @ Update (0x384eb0) default 0xA = GreaterEqual]
		op_str = ">="
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
	# The op is the trailing suffix of the key ("r1:智慧+社交>="), so match
	# the longest candidate at the end; picking by max find() position would
	# split ">=" into "=" plus a stray ">" glued to the expression.
	# [SRC: FuncCompare ctor 0x3fd360 receives type/expr/op pre-split by the
	# JSON converter; content op domain is {">=", "<", "<=", ">", "="}]
	var op := ""
	var expr := after
	for cand in OPS:
		if after.ends_with(cand) and cand.length() > op.length():
			op = cand
	if op.is_empty():
		op = "="
	else:
		expr = after.substr(0, after.length() - op.length())
	expr = expr.strip_edges()
	# Evaluate the attribute expression against the slotted cards.
	var attr_val := eval_attr_expr(expr, ctx)
	if is_r:
		# val is [X, Y]: X=needed successes, Y=success line. A single-element
		# value rolls expr-value dice and compares the EXPRESSION total
		# against the rolled face sum with the trailing op.
		# [SRC: FuncCompare.c @ IsSatisfied (0x3fc060) L249-251: Values.Count
		#       == 1 dice branch; report 3 A8]
		if val is Array and val.size() == 1:
			var st_single = ctx.get("state")
			var weights_single: Array = GameModels.difficulty_weights(st_single.difficulty_config)
			var rng_single = ctx.get("rng")
			var face_sum := 0
			for i in maxi(attr_val, 0):
				face_sum += Dice.roll_weighted_face(rng_single, weights_single)
			return Dice.apply_compare(attr_val, face_sum, op)
		# Defensive: any other malformed r1 value fails the condition rather
		# than crashing resolution.
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


## Evaluate an attribute expression against ctx. Grammar (recursive descent):
##   expr   := term (('+'|'-') term)*
##   term   := factor (('*'|'/') factor)*
##   factor := number | '(' expr ')' | '-' factor | func '(' expr ')' | ref
##   ref    := 'counter.<id>' | '<slot>.<tag>' (e.g. s5.战斗, s1.rare) | tag
## A bare tag reads ctx.main (the acting card); when main is absent it sums
## across the friend-side cards. `e(expr)` sums expr over every enemy-side
## card (slot is_enemy), other function names sum over friend-side cards.
## Legacy ctx without slot_entries falls back to the old attr_slots sum.
## [SRC: FuncCompare.c @ SplitToken (0x3fc810) shunting-yard with ( ) + - * /;
##       GetOpValue (0x3fbcb0): s-prefix slot refs + counter.<id>;
##       Execute (0x3f9b20) line 624: 'e'-prefixed names iterate ctx.enemys,
##       otherwise ctx.friends, skipping ctx.main; bare tags read ctx.main
##       (friends sum only when main is null) — lines 1103-1136]
static func eval_attr_expr(expr: String, ctx: Dictionary) -> int:
	var parser := AttrExprParser.new(expr, ctx)
	return int(parser.parse())


class AttrExprParser:
	var _s: String
	var _i := 0
	var _ctx: Dictionary

	func _init(source: String, ctx: Dictionary) -> void:
		_s = source
		_ctx = ctx

	func parse() -> float:
		var value := _expr()
		return value

	func _expr() -> float:
		var value := _term()
		while true:
			_skip_ws()
			var c := _peek()
			if c == "+":
				_i += 1
				value += _term()
			elif c == "-":
				_i += 1
				value -= _term()
			else:
				break
		return value

	func _term() -> float:
		var value := _factor()
		while true:
			_skip_ws()
			var c := _peek()
			if c == "*":
				_i += 1
				value *= _factor()
			elif c == "/":
				_i += 1
				var divisor := _factor()
				value = value / divisor if absf(divisor) > 0.0001 else 0.0
			else:
				break
		return value

	func _factor() -> float:
		_skip_ws()
		var c := _peek()
		if c == "(":
			_i += 1
			var value := _expr()
			_skip_ws()
			if _peek() == ")":
				_i += 1
			return value
		if c == "-":
			_i += 1
			return -_factor()
		if c == "+" :
			_i += 1
			return _factor()
		if _at_digit():
			return _number()
		var ident := _ident()
		if ident.is_empty():
			if _i < _s.length():
				_i += 1
			return 0.0
		_skip_ws()
		if _peek() == "(" and _is_func_name(ident):
			_i += 1
			var inner := _balanced_body()
			return _func_sum(ident, inner)
		return _resolve_ref(ident)

	func _at_digit() -> bool:
		return _i < _s.length() and (_s[_i].is_valid_float() or (_s[_i] == "." and _i + 1 < _s.length() and _s[_i + 1].is_valid_float()))

	func _number() -> float:
		var start := _i
		while _i < _s.length() and (_s[_i].is_valid_float() or _s[_i] == "."):
			_i += 1
		return _s.substr(start, _i - start).to_float()

	func _ident() -> String:
		var start := _i
		while _i < _s.length():
			var ch := _s[_i]
			if ch == "+" or ch == "-" or ch == "*" or ch == "/" or ch == "(" or ch == ")" or ch == " " or ch == "\t":
				break
			_i += 1
		return _s.substr(start, _i - start)

	func _balanced_body() -> String:
		# Caller consumed the '('; capture through its matching ')'.
		var depth := 1
		var start := _i
		while _i < _s.length() and depth > 0:
			var ch := _s[_i]
			if ch == "(":
				depth += 1
			elif ch == ")":
				depth -= 1
				if depth == 0:
					var body := _s.substr(start, _i - start)
					_i += 1
					return body
			_i += 1
		return _s.substr(start, _i - start)

	func _peek() -> String:
		return _s[_i] if _i < _s.length() else ""

	func _skip_ws() -> void:
		while _i < _s.length() and (_s[_i] == " " or _s[_i] == "\t"):
			_i += 1

	static func _is_func_name(ident: String) -> bool:
		# The original recognizes 7 function names; content only uses e().
		return ident == "e" or ident == "friend" or ident == "f" \
			or ident == "enemy" or ident == "enemys" or ident == "friends" or ident == "main"

	func _func_sum(name: String, inner_expr: String) -> float:
		var is_enemy := name.begins_with("e")
		var total := 0.0
		for entry in _card_set(is_enemy):
			var sub := AttrExprParser.new(inner_expr, _scoped_ctx(entry))
			total += sub.parse()
		return total

	func _scoped_ctx(entry: Dictionary) -> Dictionary:
		var scoped := _ctx.duplicate()
		scoped["main_card"] = entry
		return scoped

	func _card_set(is_enemy: bool) -> Array:
		var entries: Array = _ctx.get("slot_entries", [])
		if not entries.is_empty():
			var out: Array = []
			for entry in entries:
				if bool(entry.get("is_enemy", false)) == is_enemy:
					out.append(entry)
			return out
		# Legacy ctx: the friend side is the acting card when present.
		if not is_enemy:
			var acting: Dictionary = _ctx.get("acting_card", {})
			if not acting.is_empty():
				return [{"tags": acting.get("tag", {}), "card_id": int(acting.get("id", 0))}]
		return []

	func _resolve_ref(ident: String) -> float:
		# counter.<id>
		if ident.begins_with("counter.") and ident.substr(8).is_valid_int():
			var st = _ctx.get("state")
			if st != null:
				return float(st.get_counter(ident.substr(8).to_int()))
			return 0.0
		# <slot>.<tag> — slot refs read that slot's card tag (or rare).
		var dot := ident.find(".")
		if dot > 0 and ident.substr(0, dot).begins_with("s") and ident.substr(1, dot - 1).is_valid_int():
			var slot_key := ident.substr(0, dot)
			var field := ident.substr(dot + 1)
			for entry in _ctx.get("slot_entries", []):
				if str(entry.get("slot", "")) == slot_key:
					if field == "rare":
						var rare_card: Dictionary = _card_data(int(entry.get("card_id", 0)))
						return float(rare_card.get("rare", 0))
					return float(entry.get("tags", {}).get(field, 0))
			return 0.0
		# Bare tag: ctx.main first, friend-side sum when main is absent.
		if _ctx.has("main_card") and not (_ctx.get("main_card") is Dictionary and _ctx["main_card"].is_empty()):
			var main_entry: Dictionary = _ctx.get("main_card", {})
			return float(main_entry.get("tags", {}).get(ident, 0))
		var entries := _card_set(false)
		if not entries.is_empty():
			var total := 0.0
			for entry in entries:
				total += float(entry.get("tags", {}).get(ident, 0))
			return total
		return _legacy_slot_sum(ident)

	# Pre-slot_entries contexts: sum the tag across the acting attr_slots
	# (test/legacy callers); acting_card_only narrows to the acting card.
	func _legacy_slot_sum(ident: String) -> float:
		var st = _ctx.get("state")
		if st == null:
			return 0.0
		if bool(_ctx.get("acting_card_only", false)):
			var acting: Dictionary = _ctx.get("acting_card", {})
			return float(acting.get("tag", {}).get(ident, 0))
		var total := 0.0
		var rite_uid := int(_ctx.get("rite_uid", 0))
		for slot_key in _ctx.get("attr_slots", ["s1", "s2"]):
			var key := str(slot_key)
			var num := key.substr(1).to_int() if key.begins_with("s") else 0
			for tc in st.cards_in_slot(num, rite_uid):
				var card: Dictionary = st.card_data_for(int(tc.get("card_uid", 0)), _ctx.get("db"))
				total += float(card.get("tag", {}).get(ident, 0))
		return total

	func _card_data(card_id: int) -> Dictionary:
		var db = _ctx.get("db")
		if db != null:
			return db.get_card(card_id)
		return {}


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
				var card_rare: Dictionary = st.card_data_for(int(tc.get("card_uid", 0)), db_rare)
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
			var effective_card: Dictionary = st.card_data_for(int(tc.get("card_uid", 0)), ctx.get("db"))
			if apply_compare(int(effective_card.get("tag", {}).get(tag_name, 0)), need, tag_query.op):
				ok = true
				break
		return ok if not negate else not ok
	# plain "s1" -> presence.
	var slot_num2 := kk.substr(1).to_int()
	var present: bool = st.slot_has_cards(slot_num2)
	return present if not negate else not present


## Have-family counting core, shared by have / hand_have / table_have /
## rite_have. Domain modes: "all" = hand + every rite slot (player.cards plus
## each Rite.cards in the original), "hand", "table" (slots), "rite" (slots of
## the given rite id across all instances; <= 0 = every rite). Matching uses
## the runtime operation filter; counting sums tag values when the selector
## carries a tag, stacking count (max(count,1)) otherwise. Default compare >=.
## [SRC: BaseHaveCardCount.c @ GetCountFunc 0x3f55a0 (tag sum via GetTagCount,
##       stacking via GetCount max(count,1)), IsValidCard 0x3f57e0;
##       HaveCardCount.c 0x3fed80 (player.cards + every rite.cards);
##       HandHaveCardCount.c 0x3fd4f0; TableHaveCardCount.c 0x409b10;
##       RiteHaveCardCount.c 0x405500 (all instances, id<1 = all rites)]
static func _have_domain(st, mode: String, rite_id: int = 0) -> Array:
	var out: Array = []
	if st == null:
		return out
	for uid in st.card_instances.keys():
		var inst = st.get_card_instance(int(uid))
		if inst == null or inst.is_lost or inst.zone == "removed":
			continue
		var in_hand: bool = inst.zone == "hand"
		var in_slot: bool = inst.zone == "slot"
		match mode:
			"hand":
				if not in_hand: continue
			"table":
				# Desk-visible cards: hand rail, rite slots, and active Sultan
				# cards on the rail (all sit on the table surface).
				if not (in_hand or in_slot or inst.zone == "sudan"): continue
			"rite":
				if not in_slot: continue
				if rite_id > 0 and inst.rite_uid > 0:
					var owner = st.get_rite_instance(inst.rite_uid)
					if owner == null or int(owner.id) != rite_id:
						continue
			_:
				# "all": player.cards plus every rite's cards — every live card.
				pass
		out.append(inst)
	return out


static func _selector_value_tag(selector: String) -> String:
	var normalized := selector.strip_edges()
	if normalized == "" or normalized == "all" or normalized == "sudan" or normalized.is_valid_int():
		return ""
	var last := normalized
	var dot := normalized.rfind(".")
	if dot > 0:
		last = normalized.substr(dot + 1)
	# An embedded comparison keeps only its tag name for value summing.
	for op in OPS:
		var idx := last.find(op)
		if idx > 0:
			last = last.substr(0, idx)
	return last


static func _have_count(st, db, domain: Array, selector: String) -> int:
	var total := 0
	for inst in domain:
		if not RuntimeOperationFilter.matches_card_data(int(inst.card_id), inst.tags, db, selector):
			continue
		var value_tag := _selector_value_tag(selector)
		if value_tag == "" or value_tag == "count":
			total += maxi(int(inst.count), 1)
		elif value_tag == "lifetime":
			# Generic card life lands with the card-life shelter fix; until
			# then lifetime reads as the instance's remaining life (0).
			total += 0
		else:
			total += int(inst.tags.get(value_tag, 0))
	return total


static func eval_have(k: String, val: Variant, ctx: Dictionary, _is_hand: bool) -> bool:
	var st = ctx.get("state")
	var db = ctx.get("db")
	var rest := k.substr("have.".length()) if k.begins_with("have.") else ""
	var parsed := _split_name_op(rest)
	return apply_compare(
		_have_count(st, db, _have_domain(st, "all"), parsed.name),
		int(val), parsed.op
	)


static func eval_hand_have(k: String, val: Variant, ctx: Dictionary) -> bool:
	var neg := k.begins_with("!")
	var kk := k.lstrip("!")
	var st = ctx.get("state")
	var db = ctx.get("db")
	var rest := kk.substr("hand_have.".length()) if kk.begins_with("hand_have.") else ""
	var parsed := _split_name_op(rest)
	var ok := apply_compare(
		_have_count(st, db, _have_domain(st, "hand"), parsed.name),
		int(val), parsed.op
	)
	return ok if not neg else not ok


## rite_have.<rite_id>[.<card_id>][.<name-or-tag>]<op> — count matching cards
## across ALL instances of the rite id; id 0 counts across every rite (not
## just the current one). Counting follows the shared have-family rules.
## [SRC: RiteHaveCardCount.c @ IsSatisfied (0x405500): iterates every
##       player.rites instance, IsValidRite 0x4058c0 (id<1 -> SkipIsValidRite)]
static func eval_rite_have(k: String, val: Variant, ctx: Dictionary) -> bool:
	var neg := k.begins_with("!") or k.begins_with("~")
	var kk := k.lstrip("!~")
	var rest := kk.substr("rite_have.".length())
	var parsed := _split_name_op(rest)
	var selector_parts: PackedStringArray = str(parsed.name).split(".", false)
	if selector_parts.is_empty() or not str(selector_parts[0]).is_valid_int():
		push_warning("ConditionEval: malformed rite_have key '%s'" % k)
		return false if not neg else true
	var rite_id := int(selector_parts[0])
	# Optional leading card-id segment narrows the selector before the tag.
	var selector := ""
	for i in range(1, selector_parts.size()):
		selector = str(selector_parts[i]) if selector == "" else selector + "." + str(selector_parts[i])
	var st = ctx.get("state")
	var db = ctx.get("db")
	var count := 0
	if st != null:
		count = _have_count(st, db, _have_domain(st, "rite", rite_id), selector)
	var ok := apply_compare(count, int(val), parsed.op)
	return ok if not neg else not ok


static func eval_table_have(k: String, val: Variant, ctx: Dictionary) -> bool:
	var st = ctx.get("state")
	var db = ctx.get("db")
	var neg := k.begins_with("!")
	var kk := k.substr(1) if neg else k
	var rest := kk.substr("table_have.".length()) if kk.begins_with("table_have.") else ""
	var parsed := _split_name_op(rest)
	var ok := apply_compare(
		_have_count(st, db, _have_domain(st, "table"), parsed.name),
		int(val), parsed.op
	)
	return ok if not neg else not ok


static func eval_sudan_pool_have(k: String, _val: Variant, ctx: Dictionary) -> bool:
	var st = ctx.get("state")
	var db = ctx.get("db")
	var neg := k.begins_with("!")
	var kk := k.substr(1) if neg else k
	var rest := kk.substr("sudan_pool_have.".length() if "sudan_pool_have." in kk else "sudan_pool_have".length())
	var parsed := _split_name_op(rest)
	# The pool stays config ids until drawn; runtime tag overrides live in
	# sudan_pool_tags, so count matched pool entries by id with tag overrides.
	# [SRC: SudanPoolHaveCardCount.c @ 0x409760 iterates player.sudan_card_pool]
	var total := 0
	if st != null:
		for pool_id in st.sudan_deck:
			var cid := int(pool_id)
			var pool_tags: Dictionary = st.sudan_pool_tags.get(cid, {}) if st.get("sudan_pool_tags") is Dictionary else {}
			if RuntimeOperationFilter.matches_card_data(cid, pool_tags, db, parsed.name):
				total += 1
	var ok := apply_compare(total, int(_val), parsed.op)
	return ok if not neg else not ok


static func eval_is(val: Variant, ctx: Dictionary) -> bool:
	# 'is' matches the acting card id first; without an acting card it checks
	# any slotted card of the current rite (settlement conditions run with no
	# acting card).
	# [SRC: IsCardId.c @ 0x402180: ctx.main first, otherwise any slot card id
	#       in the value set; report 3 A7]
	var want := int(val)
	var acting := int(ctx.get("acting_card_id", 0))
	if acting == 0 and ctx.has("acting_card"):
		acting = int((ctx.get("acting_card", {}) as Dictionary).get("id", 0))
	if acting > 0:
		return acting == want
	for entry in ctx.get("slot_entries", []):
		if int(entry.get("card_id", 0)) == want:
			return true
	return false


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
