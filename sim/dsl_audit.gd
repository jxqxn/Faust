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


## Add a conservative, clone-runtime reachability layer to the full audit.
## A source is "potentially_reachable" when it can be reached from the normal
## start roots through known rite/event/loot/card generation operations. This
## intentionally does not evaluate every branch condition, so it is a planning
## aid rather than a claim that a source fires in every playthrough.
static func audit_potentially_reachable_configs(rites: Dictionary, events: Dictionary, loots: Dictionary, db) -> Dictionary:
	var report := audit_configs(rites, events, loots, db)
	var reachability := _potential_reachability(rites, events, loots, db)
	_annotate_reachability(report, reachability)
	return report


static func audit_rite_ids(rites: Dictionary, ids: Array[int], db = null) -> Dictionary:
	var subset := {}
	for id in ids:
		if rites.has(id):
			subset[id] = rites[id]
	return audit_rites(subset, db)


static func _potential_reachability(rites: Dictionary, events: Dictionary, loots: Dictionary, db) -> Dictionary:
	var reachable := {"rite": {}, "event": {}, "loot": {}, "card": {}}
	var distances := {"rite": {}, "event": {}, "loot": {}, "card": {}}
	var roots := {"rite": [], "event": [], "card": []}
	if db == null:
		return {"reachable": reachable, "distances": distances, "roots": roots}
	for rite_id in db.get_default_rites():
		_add_reachable(reachable.rite, int(rite_id), roots.rite, distances.rite, 0)
	var init_profile := int(db.init_config.get("event_init_profile_id", 1))
	for event_id in events:
		var event: Dictionary = events[event_id]
		if _contains_int(event.get("auto_start_init", []), init_profile):
			_add_reachable(reachable.event, int(event_id), roots.event, distances.event, 0)
	for card_id in db.get_default_cards():
		_add_reachable(reachable.card, int(card_id), roots.card, distances.card, 0)

	var processed := {"rite": {}, "event": {}, "loot": {}, "card": {}}
	var changed := true
	while changed:
		changed = false
		for rite_id in reachable.rite.keys():
			var rite_hops := int(distances.rite.get(rite_id, 999999))
			if int(processed.rite.get(rite_id, 999999)) <= rite_hops or not rites.has(rite_id):
				continue
			processed.rite[rite_id] = rite_hops
			changed = _collect_rite_edges(rites[rite_id], reachable, distances, rite_hops + 1) or changed
		for event_id in reachable.event.keys():
			var event_hops := int(distances.event.get(event_id, 999999))
			if int(processed.event.get(event_id, 999999)) <= event_hops or not events.has(event_id):
				continue
			processed.event[event_id] = event_hops
			changed = _collect_event_edges(events[event_id], reachable, distances, event_hops + 1) or changed
		for loot_id in reachable.loot.keys():
			var loot_hops := int(distances.loot.get(loot_id, 999999))
			if int(processed.loot.get(loot_id, 999999)) <= loot_hops or not loots.has(loot_id):
				continue
			processed.loot[loot_id] = loot_hops
			changed = _collect_loot_edges(loots[loot_id], reachable, distances, loot_hops + 1) or changed
		for card_id in reachable.card.keys():
			var card_hops := int(distances.card.get(card_id, 999999))
			if int(processed.card.get(card_id, 999999)) <= card_hops:
				continue
			processed.card[card_id] = card_hops
			var card: Dictionary = db.get_card(int(card_id))
			var rite_id := int(card.get("is_rite", 0))
			if rite_id > 0:
				changed = _add_reachable(reachable.rite, rite_id, null, distances.rite, card_hops + 1) or changed
	return {"reachable": reachable, "distances": distances, "roots": roots}


static func _collect_rite_edges(rite: Dictionary, reachable: Dictionary, distances: Dictionary, hops: int) -> bool:
	var changed := false
	for section in ["settlement_prior", "settlement", "settlement_extre"]:
		for entry in rite.get(section, []):
			if entry is Dictionary:
				changed = _collect_effect_edges(entry.get("result", {}), reachable, distances, hops) or changed
				changed = _collect_effect_edges(entry.get("action", {}), reachable, distances, hops) or changed
	for slot in rite.get("cards_slot", {}).values():
		if not (slot is Dictionary):
			continue
		for pop in slot.get("pops", []):
			if pop is Dictionary:
				changed = _collect_effect_edges(pop.get("action", {}), reachable, distances, hops) or changed
	return changed


static func _collect_event_edges(event: Dictionary, reachable: Dictionary, distances: Dictionary, hops: int) -> bool:
	var changed := _collect_effect_edges(event.get("result", {}), reachable, distances, hops)
	changed = _collect_effect_edges(event.get("action", {}), reachable, distances, hops) or changed
	for settlement in event.get("settlement", []):
		if settlement is Dictionary:
			changed = _collect_effect_edges(settlement.get("result", {}), reachable, distances, hops) or changed
			changed = _collect_effect_edges(settlement.get("action", {}), reachable, distances, hops) or changed
	return changed


static func _collect_loot_edges(loot: Dictionary, reachable: Dictionary, distances: Dictionary, hops: int) -> bool:
	var changed := _collect_effect_edges(loot.get("result", {}), reachable, distances, hops)
	changed = _collect_effect_edges(loot.get("action", {}), reachable, distances, hops) or changed
	for item in loot.get("item", []):
		if not (item is Dictionary):
			continue
		var item_id := int(item.get("id", 0))
		if item_id > 0:
			if str(item.get("type", "")) == "rite":
				changed = _add_reachable(reachable.rite, item_id, null, distances.rite, hops) or changed
			else:
				changed = _add_reachable(reachable.card, item_id, null, distances.card, hops) or changed
		changed = _collect_effect_edges(item.get("result", {}), reachable, distances, hops) or changed
		changed = _collect_effect_edges(item.get("action", {}), reachable, distances, hops) or changed
	return changed


static func _collect_effect_edges(payload: Variant, reachable: Dictionary, distances: Dictionary, hops: int) -> bool:
	var changed := false
	if payload is Array:
		for item in payload:
			changed = _collect_effect_edges(item, reachable, distances, hops) or changed
		return changed
	if not (payload is Dictionary):
		return false
	for raw_key in payload:
		var key := str(raw_key)
		var value = payload[raw_key]
		if key == "rite":
			for id in _ids_from_value(value):
				changed = _add_reachable(reachable.rite, id, null, distances.rite, hops) or changed
		elif key == "event_on":
			for id in _ids_from_value(value):
				changed = _add_reachable(reachable.event, id, null, distances.event, hops) or changed
		elif key == "loot" or key.begins_with("loot."):
			for id in _ids_from_value(value):
				changed = _add_reachable(reachable.loot, id, null, distances.loot, hops) or changed
		elif key == "card":
			for id in _ids_from_value(value):
				changed = _add_reachable(reachable.card, id, null, distances.card, hops) or changed
		changed = _collect_effect_edges(value, reachable, distances, hops) or changed
	return changed


static func _ids_from_value(value: Variant) -> Array[int]:
	var ids: Array[int] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				ids.append(int(item.get("id", 0)))
			else:
				ids.append(int(item))
	elif value is Dictionary:
		ids.append(int(value.get("id", 0)))
	else:
		ids.append(int(value))
	return ids.filter(func(id): return id > 0)


static func _add_reachable(bucket: Dictionary, id: int, root: Variant = null, distance: Dictionary = {}, hops: int = 0) -> bool:
	if id <= 0:
		return false
	if bucket.has(id) and int(distance.get(id, 999999)) <= hops:
		return false
	bucket[id] = true
	distance[id] = hops
	if root is Array:
		root.append(id)
	return true


static func _contains_int(values: Variant, wanted: int) -> bool:
	if values is Array:
		for value in values:
			if _value_matches_int(value, wanted):
				return true
	return _value_matches_int(values, wanted)


static func _value_matches_int(value: Variant, wanted: int) -> bool:
	if value is int or value is float or value is String:
		return int(value) == wanted
	if value is Dictionary:
		for field in ["id", "value", "values"]:
			if value.has(field) and _contains_int(value[field], wanted):
				return true
	return false


static func _annotate_reachability(report: Dictionary, data: Dictionary) -> void:
	var reachable: Dictionary = data.get("reachable", {})
	var distances: Dictionary = data.get("distances", {})
	var summary := {"roots": data.get("roots", {}), "sources": {}, "hops": {}}
	for family in ["condition", "result", "action"]:
		for references in report[family].references.values():
			for reference in references:
				var kind := str(reference.get("kind", ""))
				var id := int(reference.get("id", 0))
				var is_reachable: bool = reachable.has(kind) and reachable[kind].has(id)
				reference["reachability"] = "potentially_reachable" if is_reachable else "not_reached_by_static_graph"
				reference["reachability_hops"] = int(distances.get(kind, {}).get(id, -1)) if is_reachable else -1
	for kind in ["rite", "event", "loot", "card"]:
		var ids: Array = []
		for id in reachable.get(kind, {}).keys():
			ids.append(int(id))
		ids.sort()
		summary.sources[kind] = ids
		summary.hops[kind] = distances.get(kind, {}).duplicate()
	report["reachability"] = summary


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
	if report.has("reachability"):
		var reachability: Dictionary = report.reachability
		var sources: Dictionary = reachability.get("sources", {})
		lines.append("## Potential reachability")
		lines.append("Static roots and generation edges only; this is not a guarantee that a condition branch fires.")
		lines.append("- rites: %d" % (sources.get("rite", []) as Array).size())
		lines.append("- events: %d" % (sources.get("event", []) as Array).size())
		lines.append("- loots: %d" % (sources.get("loot", []) as Array).size())
		lines.append("- cards: %d" % (sources.get("card", []) as Array).size())
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
			var reachability := str(first.get("reachability", "unclassified"))
			var hops := int(first.get("reachability_hops", -1))
			var suffix := " [%s%s]" % [reachability, " h%d" % hops if hops >= 0 else ""]
			lines.append("- `%s` (%d): %s:%s%s" % [key, int(unsupported[key]), str(first.get("path", "")), str(first.get("field", "")), suffix])
	return "\n".join(lines)
