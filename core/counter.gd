## Counter (计数器) system.
## verified-conclusions.md #8-#10. op dispatch re-confirmed vs
## decompiled/ModifyCounter.c @ Do (0x5159c0):
##   op 1 = add, op 2 = sub, op 3 = set, else = no-op
## The op is parsed from the result key character: counter+<id>, counter-<id>, counter=<id>.
class_name CounterSystem
extends RefCounted


enum Op { NONE = 0, ADD = 1, SUB = 2, SET = 3 }

## Special counter id hard-gated to non-negative (max(value,0)).
## [SRC: PlayerExtensions.c @ SetCounter (0x38f2d0): id 0x6c5667 always clamped]
const SPECIAL_NONNEG_ID := 0x6c5667

## Config-gated counter ids that clamp to non-negative. Populated from config
## at runtime (PlayerExtensions.SetCounter predicate over a counter-id set).
static var nonneg_counter_ids: Dictionary = {SPECIAL_NONNEG_ID: true}


## Register a counter id as non-negative-clamped (config-gated set).
static func register_nonneg(id: int) -> void:
	nonneg_counter_ids[id] = true


## Whether a counter id is gated to non-negative (special id OR registered set).
static func is_nonneg_gated(id: int) -> bool:
	return id == SPECIAL_NONNEG_ID or nonneg_counter_ids.has(id)


## Clamp a value to non-negative for gated counters.
## [SRC: PlayerExtensions.c @ SetCounter: max(value,0) for gated ids]
static func clamp_nonneg(id: int, value: int) -> int:
	if is_nonneg_gated(id) and value < 0:
		return 0
	return value


## GetRealChangeValue: resolve the actual delta for a modify-counter op.
## [SRC: ModifyCounter.c @ GetRealChangeValue (0x515d60)]:
##   if op != SET AND static_value == 0:
##       delta = the acting card tag value (OperationContext card column[0] +0x20)
##   else:
##       delta = static_value
static func real_change_value(op: int, static_value: int, card_tag_value: int) -> int:
	if op != Op.SET and static_value == 0:
		return card_tag_value
	return static_value


## Parse "counter+7000001" -> {id=7000001, op=ADD}.
## "global_counter+7200131" is the same op but targets the global table.
static func parse_key(key: String) -> Dictionary:
	var is_global := key.begins_with("global_counter")
	var rest := key.substr(len("global_counter") if is_global else len("counter"))
	if rest.is_empty():
		return {}
	var op_char := rest[0]
	var id_str := rest.substr(1)
	var op := Op.NONE
	match op_char:
		"+":
			op = Op.ADD
		"-":
			op = Op.SUB
		"=":
			op = Op.SET
		_:
			return {}
	var id := id_str.to_int()
	if id == 0 and id_str != "0":
		return {}
	return {"id": id, "op": op, "global": is_global}


## Apply an op to a value. Mirrors AddCounter/SubCounter/SetCounter.
## NOTE pitfall #7/#8: no clamp here — callers needing is_cost-gated clamp
## must handle that at the result-execution layer.
static func apply(current: int, delta: int, op: int) -> int:
	match op:
		Op.ADD:
			return current + delta
		Op.SUB:
			return current - delta
		Op.SET:
			return delta
		_:
			return current
