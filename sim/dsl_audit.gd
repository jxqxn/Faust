## Test-time coverage scanner for condition/result/action DSL keys.
class_name DslAudit
extends RefCounted

static func audit_rites(rites: Dictionary, db = null) -> Dictionary:
	var out := _new_report()
	var known_tags := _known_tag_names(db)
	for rid in rites:
		var rite: Dictionary = rites[rid]
		var source := _source("rite", int(rid), "rite/%d.json" % int(rid))
		_scan_open_conditions(rite.get("open_conditions", []), out.condition, source, known_tags)
		for section in ["settlement_prior", "settlement", "settlement_extre"]:
			var entries: Array = rite.get(section, [])
			for index in entries.size():
				var entry = entries[index]
				if entry is Dictionary:
					var entry_source := _with_field(source, "%s[%d]" % [section, index])
					_scan_condition_dict(entry.get("condition", {}), out.condition, _with_field(entry_source, "condition"), known_tags)
					_scan_result_dict(entry.get("result", {}), out.result, _with_field(entry_source, "result"))
					_scan_result_dict(entry.get("action", {}), out.action, _with_field(entry_source, "action"))
		var slots: Dictionary = rite.get("cards_slot", {})
		for slot_key in slots:
			var slot_def: Dictionary = slots[slot_key]
			var slot_source := _with_field(source, "cards_slot.%s" % str(slot_key))
			_scan_condition_dict(slot_def.get("condition", {}), out.condition, _with_field(slot_source, "condition"), known_tags)
			var pops: Array = slot_def.get("pops", [])
			for index in pops.size():
				var pop = pops[index]
				if pop is Dictionary:
					var pop_source := _with_field(slot_source, "pops[%d]" % index)
					_scan_condition_dict(pop.get("condition", {}), out.condition, _with_field(pop_source, "condition"), known_tags)
					_scan_result_dict(pop.get("action", {}), out.action, _with_field(pop_source, "action"))
	return out


static func audit_configs(rites: Dictionary, events: Dictionary = {}, loots: Dictionary = {}, db = null) -> Dictionary:
	var out := audit_rites(rites, db)
	var known_tags := _known_tag_names(db)
	for eid in events:
		var event: Dictionary = events[eid]
		var source := _source("event", int(eid), "event/%d.json" % int(eid))
		_scan_condition_dict(event.get("condition", {}), out.condition, _with_field(source, "condition"), known_tags)
		_scan_result_dict(event.get("result", {}), out.result, _with_field(source, "result"))
		_scan_result_dict(event.get("action", {}), out.action, _with_field(source, "action"))
		var settlements: Array = event.get("settlement", [])
		for index in settlements.size():
			var settlement = settlements[index]
			if settlement is Dictionary:
				var settlement_source := _with_field(source, "settlement[%d]" % index)
				_scan_condition_dict(settlement.get("condition", {}), out.condition, _with_field(settlement_source, "condition"), known_tags)
				_scan_result_dict(settlement.get("result", {}), out.result, _with_field(settlement_source, "result"))
				_scan_result_dict(settlement.get("action", {}), out.action, _with_field(settlement_source, "action"))
	_scan_loots(loots, out, known_tags)
	return out


static func audit_rite_ids(rites: Dictionary, ids: Array[int], db = null) -> Dictionary:
	var subset := {}
	for id in ids:
		if rites.has(id):
			subset[id] = rites[id]
	return audit_rites(subset, db)


static func _scan_open_conditions(open_conditions: Variant, bucket: Dictionary, source: Dictionary, known_tags: Dictionary) -> void:
	if not (open_conditions is Array):
		return
	for index in open_conditions.size():
		var entry = open_conditions[index]
		if entry is Dictionary:
			_scan_condition_dict(entry.get("condition", {}), bucket, _with_field(source, "open_conditions[%d].condition" % index), known_tags)


static func _scan_condition_dict(cond: Variant, bucket: Dictionary, source: Dictionary, known_tags: Dictionary) -> void:
	if not (cond is Dictionary):
		return
	for key in cond:
		var k := str(key)
		_record(bucket, k, ConditionEval.is_supported_key(k, known_tags), source)
		if k == "any" or k == "all":
			_scan_condition_dict(cond[key], bucket, _with_field(source, k), known_tags)


static func _scan_result_dict(result: Variant, bucket: Dictionary, source: Dictionary) -> void:
	if not (result is Dictionary):
		return
	for key in result:
		var k := str(key)
		_record(bucket, k, ResultExec.is_supported_key(k), source)
		if k == "choose" and result[key] is Dictionary:
			for choose_key in result[key]:
				var choose_op := str(choose_key)
				# `all` is a ChooseOperations candidate-list wrapper, not a
				# standalone label. It is an AllOperations subtree and runs each
				# concrete nested operation.
				if choose_op == "all" and result[key][choose_key] is Dictionary:
					_record(bucket, choose_op, ResultExec.is_supported_key(choose_op), _with_field(source, "choose.all"))
					for nested_key in result[key][choose_key]:
						var nested_op := str(nested_key)
						_record(bucket, nested_op, ResultExec.is_supported_key(nested_op), _with_field(source, "choose.all.%s" % nested_op))
					continue
				_record(bucket, choose_op, ResultExec.is_supported_key(choose_op), _with_field(source, "choose.%s" % choose_op))


static func _scan_loots(loots: Dictionary, out: Dictionary, known_tags: Dictionary) -> void:
	for loot_id in loots:
		var loot: Dictionary = loots[loot_id]
		var source := _source("loot", int(loot_id), "loot/%d.json" % int(loot_id))
		_scan_condition_dict(loot.get("condition", {}), out.condition, _with_field(source, "condition"), known_tags)
		_scan_result_dict(loot.get("result", {}), out.result, _with_field(source, "result"))
		_scan_result_dict(loot.get("action", {}), out.action, _with_field(source, "action"))
		var items: Array = loot.get("item", [])
		for index in items.size():
			var item = items[index]
			if item is Dictionary:
				var item_source := _with_field(source, "item[%d]" % index)
				_scan_condition_dict(item.get("condition", {}), out.condition, _with_field(item_source, "condition"), known_tags)
				_scan_result_dict(item.get("result", {}), out.result, _with_field(item_source, "result"))
				_scan_result_dict(item.get("action", {}), out.action, _with_field(item_source, "action"))


static func _new_report() -> Dictionary:
	return {
		"condition": _new_bucket(),
		"result": _new_bucket(),
		"action": _new_bucket(),
	}


static func _new_bucket() -> Dictionary:
	return {"supported": {}, "unsupported": {}, "references": {}}


static func _source(kind: String, id: int, path: String) -> Dictionary:
	return {"kind": kind, "id": id, "path": path, "field": ""}


static func _with_field(source: Dictionary, field: String) -> Dictionary:
	var copy := source.duplicate()
	var prefix := str(copy.get("field", ""))
	copy["field"] = field if prefix.is_empty() else "%s.%s" % [prefix, field]
	return copy


static func _known_tag_names(db) -> Dictionary:
	var out := {}
	if db == null:
		return out
	for tag_name in db.tag_name_to_code.keys():
		out[str(tag_name)] = true
	for card in db.cards.values():
		for tag_name in (card as Dictionary).get("tag", {}).keys():
			out[str(tag_name)] = true
	return out


static func _record(bucket: Dictionary, key: String, supported: bool, source: Dictionary) -> void:
	var group_key := "supported" if supported else "unsupported"
	var group: Dictionary = bucket[group_key]
	group[key] = int(group.get(key, 0)) + 1
	var refs: Dictionary = bucket.references
	if not refs.has(key):
		refs[key] = []
	var locations: Array = refs[key]
	for location in locations:
		if location.kind == source.kind and int(location.id) == int(source.id) and location.path == source.path and location.field == source.field:
			location.count = int(location.count) + 1
			return
	var next := source.duplicate()
	next["count"] = 1
	locations.append(next)


static func unexpected_unsupported(report: Dictionary, baseline: Dictionary) -> Dictionary:
	var out := {"condition": {}, "result": {}, "action": {}}
	for family in out.keys():
		var allowed: Dictionary = baseline.get(family, {})
		for key in report[family].unsupported:
			if not allowed.has(key):
				out[family][key] = report[family].unsupported[key]
	return out


static func to_json(report: Dictionary) -> String:
	return JSON.stringify(report, "\t")


static func to_markdown(report: Dictionary, limit: int = 20) -> String:
	var lines: Array[String] = ["# DSL audit"]
	for family in ["condition", "result", "action"]:
		var unsupported: Dictionary = report.get(family, {}).get("unsupported", {})
		lines.append("## %s" % family)
		lines.append("Unsupported unique keys: %d" % unsupported.size())
		var keys: Array = unsupported.keys()
		keys.sort_custom(func(a, b): return int(unsupported[a]) > int(unsupported[b]))
		for index in mini(limit, keys.size()):
			var key := str(keys[index])
			var refs: Array = report[family].references.get(key, [])
			var first: Dictionary = refs[0] as Dictionary if not refs.is_empty() else {}
			lines.append("- `%s` (%d): %s:%s" % [key, int(unsupported[key]), str(first.get("path", "")), str(first.get("field", ""))])
	return "\n".join(lines)
