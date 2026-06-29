## Counter (计数器) system.
## verified-conclusions.md #8-#10. op dispatch re-confirmed vs
## decompiled/ModifyCounter.c @ Do (0x5159c0):
##   op 1 = add, op 2 = sub, op 3 = set, else = no-op
## The op is parsed from the result key character: counter+<id>, counter-<id>, counter=<id>.
class_name CounterSystem
extends RefCounted


enum Op { NONE = 0, ADD = 1, SUB = 2, SET = 3 }


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
