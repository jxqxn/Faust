## Unified seeded RNG for the game.
## Per verified-conclusions #4b: DICE_SEED is NOT the dice RNG; it is a
## resource/config pack decryption seed. Dice use the project's own RNG.
## This wraps Godot's RandomNumberGenerator so all subsystems (dice, loot,
## shuffle, r1) share one deterministic, seedable stream.
class_name GameRNG
extends RefCounted

var _gen := RandomNumberGenerator.new()


func _init(seed_value: int = -1) -> void:
	if seed_value < 0:
		_gen.randomize()
	else:
		_gen.seed = seed_value


func set_seed(seed_value: int) -> void:
	_gen.seed = seed_value


func get_seed() -> int:
	return _gen.seed


## Inclusive int range [from, to], matching Unity's Random.Range(int,int) semantics.
func range_int(from_n: int, to_n: int) -> int:
	return _gen.randi_range(from_n, to_n)


## float in [0,1], matching Unity's Random.value.
func value() -> float:
	return _gen.randf()


## float in [from,to), matching Unity's Random.Range(float,float).
func range_float(from_n: float, to_n: float) -> float:
	return _gen.randf_range(from_n, to_n)


## Fisher-Yates shuffle of a copy; returns the shuffled array.
func shuffle(arr: Array) -> Array:
	var out := arr.duplicate()
	var n := out.size()
	var i := n - 1
	while i > 0:
		var j := _gen.randi_range(0, i)
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
		i -= 1
	return out


## Weighted single draw: returns the index into items chosen by int weights.
## Mirrors SimpleWeightLoot (verified-conclusions #6): total = sum(weights),
## r = Random.Range(0,total), decrement until <1.
func weighted_pick_int(weights: PackedInt32Array) -> int:
	var total := 0
	for w in weights:
		total += int(w)
	if total <= 0:
		return -1
	var r := _gen.randi_range(0, total - 1)
	for i in weights.size():
		r -= int(weights[i])
		if r < 1:
			return i
	return weights.size() - 1
