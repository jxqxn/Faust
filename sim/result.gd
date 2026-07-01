## Result DSL executor.
## Dispatch table transcribed from dump.cs [Operation(...)] attributes (lines 312xxx-316xxx).
## Handles the result keys that matter for the core loop:
##   coin / 金币 (GenCoin: gold-card stack)     [spec sec 10.2]
##   counter+/-/=<id>, global_counter+/-/=<id>
##   card <id>, choose{...}, clean.s<n>, clean.rite
##   s<n>+/-<tag>, s<n>+回收 (ModifyTag)
##   event_on <id>, event_off, rite <id>
##   back_to_prev_round_end, over, confirm
## Returns a list of "effects" the UI/sim can apply (some are immediate state
## mutations; choose/event_on/rite produce deferred actions).
class_name ResultExec
extends RefCounted

const CounterSystem = preload("res://core/counter.gd")
const TagSystem = preload("res://core/tag.gd")


## Execute a result dictionary against the game state.
## Returns a Dictionary of deferred actions: {choose:..., events:[...], rite:id, over:bool, ...}.
static func execute(result: Dictionary, state, db) -> Dictionary:
	var deferred := {
		"events": [], "choose": {}, "rite": 0, "over": false, "back_to_prev": false,
		"logs": [], "clean_slots": [], "clean_card_ids": [], "clean_rite": false,
	}
	for key in result:
		var val = result[key]
		_apply_key(key, val, state, db, deferred)
	return deferred


static func is_supported_key(key: String) -> bool:
	var k := key.strip_edges()
	if k in ["coin", "金币", "g.coin", "card", "choose", "clean.rite", "event_on", "event_off", "rite", "over", "back_to_prev_round_end", "confirm"]:
		return true
	if k.begins_with("counter") or k.begins_with("global_counter"):
		return true
	if k.begins_with("clean."):
		return true
	if _is_slot_tag_op(k):
		return true
	if (k.begins_with("table.") or k.begins_with("g.")) and _has_tag_op_after_dot(k):
		return true
	return false


static func _apply_key(key: String, val: Variant, state, db, deferred: Dictionary) -> void:
	var k := key.strip_edges()
	# Gold (GenCoin): coin / 金币 / g.coin.
	if k == "coin" or k == "金币" or k == "g.coin":
		state.add_coin(int(val))
		deferred.logs.append("coin +%d" % int(val))
		return
	# Counters.
	if k.begins_with("counter") or k.begins_with("global_counter"):
		_apply_counter(k, val, state)
		return
	# Card grant.
	if k == "card":
		state.add_card_to_hand(int(val))
		return
	# Choose (pop options).
	if k == "choose" and val is Dictionary:
		deferred.choose = val
		return
	# Clean slot / clean rite.
	if k == "clean.rite":
		state.table_cards.clear()
		deferred.clean_rite = true
		return
	if k.begins_with("clean."):
		var slot := _clean_slot_from_key(k)
		if slot > 0:
			state.clear_slot(slot)
			deferred.clean_slots.append(slot)
			return
		var card_id := _clean_card_id_from_key(k, db)
		if card_id > 0:
			if state.has_method("remove_table_card_id"):
				state.remove_table_card_id(card_id)
			deferred.clean_card_ids.append(card_id)
		elif _clean_all_from_key(k):
			state.table_cards.clear() # index<1 => all slots
			deferred.clean_rite = true
		return
	# Slot tag op: s<n>+/-<tag>  (ModifyTag).
	if _is_slot_tag_op(k):
		_apply_slot_tag(k, val, state)
		return
	# Table/g tag ops: table.<x>+/-<tag>, g.<x>+/-<tag>.
	if k.begins_with("table.") or k.begins_with("g."):
		_apply_table_tag(k, val, state)
		return
	# Events.
	if k == "event_on":
		deferred.events.append(int(val))
		return
	if k == "event_off":
		return
	# Rite jump.
	if k == "rite":
		deferred.rite = int(val)
		return
	# End / back.
	if k == "over":
		deferred.over = bool(val) if val is bool else true
		return
	if k == "back_to_prev_round_end":
		deferred.back_to_prev = true
		return
	if k == "confirm":
		return
	# Unhandled: log, don't crash.
	deferred.logs.append("UNHANDLED result key: %s=%v" % [k, val])


static func _apply_counter(k: String, val: Variant, state) -> void:
	var parsed := CounterSystem.parse_key(k)
	if parsed.is_empty():
		return
	var delta := int(val)
	if parsed.op == CounterSystem.Op.SET:
		if parsed.global:
			state.set_global_counter(parsed.id, delta)
		else:
			state.set_counter(parsed.id, delta)
	elif parsed.op == CounterSystem.Op.ADD:
		if parsed.global:
			state.add_global_counter(parsed.id, delta)
		else:
			state.add_counter(parsed.id, delta)
	elif parsed.op == CounterSystem.Op.SUB:
		if parsed.global:
			state.sub_global_counter(parsed.id, delta)
		else:
			state.sub_counter(parsed.id, delta)


static func _clean_slot_from_key(k: String) -> int:
	var rest := k.substr("clean.".length())
	# "s4" -> 4 ; bare (no s) -> -1 (all slots).
	if rest.begins_with("s"):
		return rest.substr(1).to_int()
	return -1


static func _clean_card_id_from_key(k: String, db) -> int:
	var rest := k.substr("clean.".length())
	if rest.begins_with("s") or rest == "rite":
		return 0
	if db != null and db.has_method("resolve_card_id"):
		return int(db.resolve_card_id(rest))
	if rest.is_valid_int():
		return rest.to_int()
	return 0


static func _clean_all_from_key(k: String) -> bool:
	var rest := k.substr("clean.".length())
	return rest.is_empty() or rest == "0"


static func _is_slot_tag_op(k: String) -> bool:
	# s<n>[+\-=]<tag> OR s<n>+回收. Must start with s and contain an op char.
	if not k.begins_with("s"):
		return false
	return ("+" in k or "-" in k or "=" in k) and not k.begins_with("sudan")


static func _has_tag_op_after_dot(k: String) -> bool:
	var dot := k.find(".")
	if dot < 0:
		return false
	var rest := k.substr(dot + 1)
	return "+" in rest or "-" in rest or "=" in rest


static func _apply_slot_tag(k: String, val: Variant, state) -> void:
	# Parse "s4+回收" -> slot=4, op=+, tag=回收.
	var op_idx := -1
	var op_char := ""
	for i in range(1, k.length()):
		if k[i] == "+" or k[i] == "-" or k[i] == "=":
			op_idx = i
			op_char = k[i]
			break
	if op_idx < 0:
		return
	var slot_num := k.substr(1, op_idx - 1).to_int()
	var tag_name := k.substr(op_idx + 1)
	var op := TagSystem.op_from_char(op_char)
	var amount := int(val)
	if amount == 0:
		amount = 1
	for tc in state.cards_in_slot(slot_num):
		var tags: Dictionary = tc.get("tags", {})
		TagSystem.apply(tags, tag_name, op, amount)
		tc.tags = tags


static func _apply_table_tag(k: String, val: Variant, state) -> void:
	# table.<x>+/-<tag> or g.<x>+/-<tag> -> apply to all table cards.
	var rest := k.substr(k.find(".") + 1)
	var op_idx := -1
	var op_char := ""
	for i in rest.length():
		if rest[i] == "+" or rest[i] == "-" or rest[i] == "=":
			op_idx = i
			op_char = rest[i]
			break
	if op_idx < 0:
		return
	var tag_name := rest.substr(op_idx + 1)
	var op := TagSystem.op_from_char(op_char)
	var amount := int(val)
	if amount == 0:
		amount = 1
	for tc in state.table_cards:
		var tags: Dictionary = tc.get("tags", {})
		TagSystem.apply(tags, tag_name, op, amount)
		tc.tags = tags
