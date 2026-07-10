## EventRuntime: push-based event trigger dispatcher.
## Mirrors the original EventTrigger (a Dictionary<timing, HashSet<EventNode>>)
## keyed by timing string. Game-state transitions call fire(timing, ctx); the
## runtime looks up registered events, matches each against the TimingContext
## (round/rite/card/counter id) and the event's top-level condition, and returns
## the ids whose effects should apply.
##
## [SRC: engine_spec/decompiled/EventTrigger.c @ On (0x4fbc20);
##       EventTriggerExtensions.c — 28 On* entry points;
##       il2cpp_dump/dump.cs: EventTrigger @311522, TimingContext @395163]
class_name EventRuntime
extends RefCounted

# timing string -> { event_id(int): trigger_value(int|Array) }
var _by_timing := {}
# Config + state refs for condition evaluation.
var _db = null
var _state = null


func build(db, state) -> void:
	_db = db
	_state = state
	_by_timing.clear()
	if db == null:
		return
	for eid in db.events:
		var event: Dictionary = db.events[eid]
		var on: Dictionary = event.get("on", {})
		for timing in on:
			if not _by_timing.has(timing):
				_by_timing[timing] = {}
			_by_timing[timing][int(eid)] = on[timing]


## Fire all events registered under `timing` whose trigger value matches the
## context and whose top-level condition holds. Returns the matched event ids
## (caller queues them via state.queue_event). ctx carries the binding payload:
##   round_begin_ba / round_begin_fr / round_end -> {"round": int}
##   rite_end / rite_start / open_rite           -> {"rite": int}
##   card_clean / card_born / card_dead          -> {"card": int}
##   counter / global_counter                    -> {"counter_id": int}
##   game_end                                    -> {}
func fire(timing: String, ctx: Dictionary) -> Array[int]:
	var out: Array[int] = []
	var bucket: Dictionary = _by_timing.get(timing, {})
	if bucket.is_empty():
		return out
	for eid in bucket:
		var trigger_value = bucket[eid]
		if not _value_matches(timing, trigger_value, ctx):
			continue
		if not _condition_holds(eid):
			continue
		out.append(int(eid))
	out.sort()
	return out


## Whether the event's `on` value matches the firing context for this timing.
static func _value_matches(timing: String, trigger_value, ctx: Dictionary) -> bool:
	# Round-based timings: value is a round number (or list of rounds).
	if timing in ["round_begin_ba", "round_begin_fr", "round_end", "back_to_round_begin", "back_to_prev_round_end"]:
		return _int_or_list_includes(trigger_value, int(ctx.get("round", -1)))
	# Rite-based timings: value is a rite id.
	if timing in ["rite_end", "rite_start", "rite_begin", "rite_cancel", "rite_clean", "open_rite", "open_rite_end", "rite_can_start", "rite_can_stop", "rite_can_fill", "rite_settlement"]:
		return _int_or_list_includes(trigger_value, int(ctx.get("rite", 0)))
	# Card-based timings: value is a card id, or 1 = match-any.
	if timing in ["card_clean", "card_born", "card_dead", "open_card_info", "open_card_info_end"]:
		if _is_any(trigger_value):
			return true
		return _int_or_list_includes(trigger_value, int(ctx.get("card", 0)))
	# Counter-based: value is a counter id.
	if timing in ["counter", "global_counter"]:
		return _int_or_list_includes(trigger_value, int(ctx.get("counter_id", 0)))
	# Event-less timings (game_end, close_prompt, etc.): fire for all registered.
	return true


static func _int_or_list_includes(trigger_value, need: int) -> bool:
	if trigger_value is Array:
		return need in trigger_value
	return int(trigger_value) == need


static func _is_any(trigger_value) -> bool:
	# Sentinel value 1 means "match any card" in the original TimingCardBase.
	if trigger_value is Array:
		return trigger_value.is_empty()
	return int(trigger_value) == 1


func _condition_holds(event_id: int) -> bool:
	if _db == null or _state == null:
		return true
	var event: Dictionary = _db.get_event(event_id)
	var cond: Dictionary = event.get("condition", {})
	if cond.is_empty():
		return true
	var ctx := {"db": _db, "state": _state, "rng": null, "rite_state": {}, "attr_slots": ["s1", "s2"]}
	return ConditionEval.evaluate(cond, ctx)
