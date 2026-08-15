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

# timing string -> { event_id(int): trigger_value(int|Array) }. This contains
# only events currently enabled on the player, not every definition in db.
var _by_timing := {}
# Round-based timings follow the original TimingRoundBase lifecycle: armed on
# enable (OnStart), gated by Player.timing_rounds in IsValid, re-armed by
# NextRound when they fire, removed for non-replay events (OnEnd).
# [SRC: TimingRoundBase.c @ OnStart (0x4660d0) / IsValid (0x465d30) /
#       NextRound (0x465f20) / OnEnd (0x466000); dump.cs Player +0x128]
const ROUND_TIMINGS := ["round_begin_ba", "round_begin_fr", "round_end"]
# Retained as a compatibility/debug view for callers that need to inspect
# event_off. The source of truth is GameState.event_status.
var _disabled: Dictionary = {}
# Config + state refs for condition evaluation.
# `_state` is a weak reference: GameState owns this runtime (and its lifetime),
# so a strong back-reference would create a RefCounted reference cycle that
# leaks the whole state object graph at process exit.
var _db = null
var _state = null


func build(db, state) -> void:
	_db = db
	_state = weakref(state) if state != null else null
	_by_timing.clear()
	_disabled.clear()
	if db == null:
		return
	if state == null:
		return
	for eid in state.event_status:
		if bool(state.event_status[eid]):
			enable_event(int(eid))


## Register one enabled event in its configured timing buckets. Event
## definitions are intentionally not registered until EventOn or
## auto_start_init enables them.
## [SRC: decompiled/EventOn.__c__DisplayClass2_0.c @ <Do>b__0
##       (RVA 0x51f1a0): SetEventStatus(id, true) then EventTrigger.Add(id)]
func enable_event(event_id: int) -> bool:
	if _db == null:
		return false
	var event: Dictionary = _db.get_event(event_id)
	if event.is_empty():
		return false
	_disabled.erase(event_id)
	var on: Dictionary = event.get("on", {})
	var state = _state.get_ref() if _state is WeakRef else _state
	for timing in on:
		if not _by_timing.has(timing):
			_by_timing[timing] = {}
		_by_timing[timing][event_id] = on[timing]
		if state != null and timing in ROUND_TIMINGS:
			# OnStart: arm the next fire round (idempotent, keeps saved arms).
			var key := _timing_key(timing, event_id)
			if not state.timing_rounds.has(key):
				state.timing_rounds[key] = next_round(on[timing], int(state.round_number), {})
	return true


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
		if _disabled.has(eid):
			continue
		if timing in ROUND_TIMINGS:
			if not _round_timing_fires(timing, int(eid), trigger_value, ctx):
				continue
		elif not _value_matches(timing, trigger_value, ctx):
			continue
		if not _condition_holds(eid, ctx):
			continue
		out.append(int(eid))
	out.sort()
	return out


## Disable an event from future triggering (event_off). Matches the original
## EventTrigger.Remove + PlayerExtensions.SetEventStatus(id, 0). Round-timing
## arms are dropped too (TimingRoundBase.OnEnd removes the dictionary entry,
## after which IsValid reports missing-key and never fires again).
## [SRC: EventOff.c @ Do; EventTrigger.c @ Remove; TimingRoundBase.c @ OnEnd]
func disable_event(event_id: int) -> void:
	_disabled[event_id] = true
	for timing in _by_timing:
		_by_timing[timing].erase(event_id)
	var state = _state.get_ref() if _state is WeakRef else _state
	if state != null:
		for key in state.timing_rounds.keys():
			if str(key).ends_with(":%d" % event_id):
				state.timing_rounds.erase(key)


static func _timing_key(timing: String, event_id: int) -> String:
	return "%s:%d" % [timing, event_id]


## IsValid for round-based timings: fire when the current round reaches the
## armed next-fire round, then re-arm immediately (the original re-arms inside
## IsValid, even if the event's own condition later fails).
## [SRC: TimingRoundBase.c @ IsValid (0x465d30) lines 47-72]
func _round_timing_fires(timing: String, event_id: int, trigger_value, ctx: Dictionary) -> bool:
	var state = _state.get_ref() if _state is WeakRef else _state
	if state == null:
		return false
	var key := _timing_key(timing, event_id)
	if not state.timing_rounds.has(key):
		return false
	var next_fire: int = int(state.timing_rounds[key])
	var round_now := int(ctx.get("round", -1))
	if round_now < next_fire:
		return false
	state.timing_rounds[key] = next_round(trigger_value, round_now, ctx)
	return true


## NextRound: single value -> value + base; two-value list -> Unity
## Random.Range(v0, v1) [inclusive, exclusive) + base. This makes
## `round_begin_ba: N` a period (re-fire every N rounds after arming), and
## `[a, b]` a random period in that half-open range.
## [SRC: TimingRoundBase.c @ NextRound (0x465f20): Count==1 -> get_Value +
##       param; Count==2 -> UnityEngine.Random.Range(v0, v1) + param]
static func next_round(trigger_value, base_round: int, ctx: Dictionary) -> int:
	if trigger_value is Array:
		if trigger_value.size() >= 2:
			var lo := int(trigger_value[0])
			var hi := int(trigger_value[1])
			var period := lo
			if hi > lo:
				var rng = ctx.get("rng", null)
				if rng != null and rng.has_method("randi_range"):
					period = rng.randi_range(lo, hi - 1)
				else:
					period = lo + (randi() % (hi - lo))
			return period + base_round
		if trigger_value.size() == 1:
			trigger_value = trigger_value[0]
	return int(trigger_value) + base_round


## Whether the event's `on` value matches the firing context for this timing.
## Round-based timings are handled by _round_timing_fires before this runs.
static func _value_matches(timing: String, trigger_value, ctx: Dictionary) -> bool:
	# GameEnd timings filter by ending id: the value set must contain the
	# ending reached; single -1 = any ending.
	# [SRC: GameEnd.c @ IsValid (0x45efe0): player+0x7c ending id vs the
	#       timing's value set, -1 wildcard (report 6 A3)]
	if timing == "game_end":
		var ending := int(ctx.get("ending", -2147483648))
		if ending == -2147483648:
			return false
		if trigger_value is Array:
			return ending in trigger_value
		return int(trigger_value) == -1 or int(trigger_value) == ending
	# BackTo timings are value-less (TimingBase): fire on every dispatch.
	# [SRC: dump.cs:426298/426318 BackTo* : TimingBase (report 6 A4)]
	if timing in ["back_to_round_begin", "back_to_prev_round_end"]:
		return true
	# Rite-based timings: value is a rite id, or 1 = match any rite (rite
	# config ids are all >= 5000000, so 1 is an unambiguous sentinel).
	# [SRC: report 6 A2 — TimingRiteBase match-any sentinel, 10 config events]
	if timing in ["rite_end", "rite_start", "rite_begin", "rite_cancel", "rite_clean", "open_rite", "open_rite_end", "rite_can_start", "rite_can_stop", "rite_can_fill", "rite_settlement"]:
		if _is_any(trigger_value):
			return true
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


func _condition_holds(event_id: int, trigger_ctx: Dictionary = {}) -> bool:
	if _db == null:
		return true
	var state = _state.get_ref() if _state is WeakRef else _state
	if state == null:
		return true
	var event: Dictionary = _db.get_event(event_id)
	var cond: Dictionary = event.get("condition", {})
	if cond.is_empty():
		return true
	var ctx := trigger_ctx.duplicate(true)
	ctx["db"] = _db
	ctx["state"] = state
	ctx["rng"] = null
	if not ctx.has("rite_state"):
		ctx["rite_state"] = {}
	if not ctx.has("attr_slots"):
		ctx["attr_slots"] = ["s1", "s2"]
	return ConditionEval.evaluate(cond, ctx)
