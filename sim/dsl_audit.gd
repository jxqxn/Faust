## Test-time coverage scanner for condition/result/action DSL keys.
class_name DslAudit
extends RefCounted

const ConditionEval = preload("res://sim/condition.gd")
const ResultExec = preload("res://sim/result.gd")


static func audit_rites(rites: Dictionary) -> Dictionary:
	var out := {
		"condition": {"supported": {}, "unsupported": {}},
		"result": {"supported": {}, "unsupported": {}},
		"action": {"supported": {}, "unsupported": {}},
	}
	for rid in rites:
		var rite: Dictionary = rites[rid]
		_scan_open_conditions(rite.get("open_conditions", []), out.condition)
		for section in ["settlement_prior", "settlement", "settlement_extre"]:
			for entry in rite.get(section, []):
				if entry is Dictionary:
					_scan_condition_dict(entry.get("condition", {}), out.condition)
					_scan_result_dict(entry.get("result", {}), out.result)
					_scan_result_dict(entry.get("action", {}), out.action)
		var slots: Dictionary = rite.get("cards_slot", {})
		for slot_key in slots:
			var slot_def: Dictionary = slots[slot_key]
			_scan_condition_dict(slot_def.get("condition", {}), out.condition)
			for pop in slot_def.get("pops", []):
				if pop is Dictionary:
					_scan_condition_dict(pop.get("condition", {}), out.condition)
					_scan_result_dict(pop.get("action", {}), out.action)
	return out


static func _scan_open_conditions(open_conditions: Variant, bucket: Dictionary) -> void:
	if not (open_conditions is Array):
		return
	for entry in open_conditions:
		if entry is Dictionary:
			_scan_condition_dict(entry.get("condition", {}), bucket)


static func _scan_condition_dict(cond: Variant, bucket: Dictionary) -> void:
	if not (cond is Dictionary):
		return
	for key in cond:
		var k := str(key)
		_count(bucket, k, ConditionEval.is_supported_key(k))
		if k == "any" or k == "all":
			_scan_condition_dict(cond[key], bucket)


static func _scan_result_dict(result: Variant, bucket: Dictionary) -> void:
	if not (result is Dictionary):
		return
	for key in result:
		var k := str(key)
		_count(bucket, k, ResultExec.is_supported_key(k))
		if k == "choose" and result[key] is Dictionary:
			for choose_key in result[key]:
				_count(bucket, str(choose_key), false)


static func _count(bucket: Dictionary, key: String, supported: bool) -> void:
	var group_key := "supported" if supported else "unsupported"
	var group: Dictionary = bucket[group_key]
	group[key] = int(group.get(key, 0)) + 1
