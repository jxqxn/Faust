## Dice / FuncCompare resolution.
## Faithful to verified-conclusions.md #1-#4 (re-confirmed against
## decompiled/FuncCompare.c @ IsSatisfied (0x3fc060), 2026-06-29).
##
## Resolution model (v3, the CORRECT one — do not flip the comparison):
##   N = attribute expression value (number of dice to roll)
##   each die = weighted 1..6 pick by difficulty weights
##   success ⟺ die >= Y   (Y = Values[1], success line, typically 5)
##   final = successes + goldDiceCount
##   satisfied ⟺ compare.apply(final, X)   where X = Values[0], compare = op
class_name Dice
extends RefCounted


## Roll one weighted face in 1..len(weights), mirroring the weighted pick in
## FuncCompare @ IsSatisfied: Random.Range(0, total) then decrement.
static func roll_weighted_face(rng: GameRNG, weights: Array) -> int:
	var total := 0
	for w in weights:
		total += int(w)
	if total <= 0:
		return 1
	var r := rng.range_int(0, total - 1)
	for i in weights.size():
		var w := int(weights[i])
		if r < w:
			return i + 1
		r -= w
	return weights.size()


## Evaluate a FuncCompare check. Returns true if satisfied.
##   n_dice: N (attribute value, number of dice)
##   success_line: Y (Values[1]); a die is a success when die >= success_line
##   target: X (Values[0]); final is compared against this
##   op: the compare operator string ("<", "<=", ">=", ">", "=", "!=")
##   weights: difficulty face weights (6 entries)
##   gold_dice: gold dice count to add to successes
static func is_satisfied(rng: GameRNG, n_dice: int, success_line: int, target: int, op: String, weights: Array, gold_dice: int) -> bool:
	var clamped := maxi(n_dice, 0)
	var successes := 0
	for i in clamped:
		var face := roll_weighted_face(rng, weights)
		if face >= success_line:
			successes += 1
	var final_val := successes + maxi(gold_dice, 0)
	return apply_compare(final_val, target, op)


## r1 uniform random. verified-conclusions #4:
##   one value  -> Random.Range(0, value)        [0, value)
##   two values -> Random.Range(a, b)            [a, b)
## (Unity's int Random.Range is half-open: [inclusive, exclusive]).
static func r1_random(rng: GameRNG, value_a: int, value_b: int) -> int:
	if value_b == 0 and value_a != 0:
		# Single-arg form: [0, value_a).
		return rng.range_int(0, value_a - 1)
	# Two-arg form: [value_a, value_b).
	if value_b <= value_a:
		return value_a
	return rng.range_int(value_a, value_b - 1)


## Apply a compare operator. Mirrors the Compare op dispatch built from the
## condition key (e.g. ">=" from "r1:智慧+社交>=").
static func apply_compare(a: int, b: int, op: String) -> bool:
	match op:
		"<":
			return a < b
		"<=":
			return a <= b
		">":
			return a > b
		">=":
			return a >= b
		"=", "==":
			return a == b
		"!=":
			return a != b
		_:
			# Unknown op: treat as >= (most common in config) but log.
			push_warning("Dice: unknown compare op '%s', defaulting to >=" % op)
			return a >= b
