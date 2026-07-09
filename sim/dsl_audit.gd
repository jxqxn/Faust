## Test-time coverage scanner for condition/result/action DSL keys.
class_name DslAudit
extends RefCounted

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


static func audit_configs(rites: Dictionary, events: Dictionary = {}, loots: Dictionary = {}) -> Dictionary:
	var out := audit_rites(rites)
	for eid in events:
		var event: Dictionary = events[eid]
		_scan_condition_dict(event.get("condition", {}), out.condition)
		_scan_result_dict(event.get("result", {}), out.result)
		_scan_result_dict(event.get("action", {}), out.action)
	_scan_loots(loots, out)
	return out


static func audit_rite_ids(rites: Dictionary, ids: Array[int]) -> Dictionary:
	var subset := {}
	for id in ids:
		if rites.has(id):
			subset[id] = rites[id]
	return audit_rites(subset)


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
				var choose_op := str(choose_key)
				_count(bucket, choose_op, ResultExec.is_supported_key(choose_op))


static func _scan_loots(loots: Dictionary, out: Dictionary) -> void:
	for loot_id in loots:
		var loot: Dictionary = loots[loot_id]
		_scan_condition_dict(loot.get("condition", {}), out.condition)
		for item in loot.get("item", []):
			if item is Dictionary:
				_scan_condition_dict(item.get("condition", {}), out.condition)


static func _count(bucket: Dictionary, key: String, supported: bool) -> void:
	var group_key := "supported" if supported else "unsupported"
	var group: Dictionary = bucket[group_key]
	group[key] = int(group.get(key, 0)) + 1
