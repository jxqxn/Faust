## Branch / sub-operation selection.
## verified-conclusions.md #13-#14, re-confirmed vs decompiled.
##
## ChooseOperations.GetOperations (0x4f3830):
##   count<1 -> []
##   count<=list.Count -> Shuffle + GetRange(0,count)  (random N, not a UI pop)
##   else -> whole list
##
## RandomOperations.GetOperations (0x519900):
##   uses shared dice cache (dice == point, EXACT equality, not threshold)
##   count hits N -> if N<1 skip; else copy ops -> Shuffle + GetRange(0,N)
##   if list.Count < N -> whole unshuffled list
class_name BranchSystem
extends RefCounted


## ChooseOperations: shuffle the list and take the first `count`.
## Returns [] if count<1, whole list if count>=list size.
static func choose_operations(rng: GameRNG, operations: Array, count: int) -> Array:
	if count < 1:
		return []
	if count >= operations.size():
		return operations.duplicate()
	var shuffled := rng.shuffle(operations)
	return shuffled.slice(0, count)


## RandomOperations: count how many dice hit `point` exactly, take that many.
## dice_values: the shared dice cache. point: the exact value to match.
## Returns the chosen operations (shuffled slice, or whole list if N>list).
static func random_operations(rng: GameRNG, operations: Array, dice_values: Array, point: int) -> Array:
	var hits := 0
	for d in dice_values:
		if int(d) == point:
			hits += 1
	if hits < 1:
		return []
	if hits >= operations.size():
		# list.Count < N -> whole unshuffled list.
		return operations.duplicate()
	var shuffled := rng.shuffle(operations)
	return shuffled.slice(0, hits)
