## Source-shaped cross-run quest operations.
## Maps original GlobalExtensions.RefreshQuest rather than inventing a clone
## achievement layer. Quest content remains the raw content/quest.json nodes.
class_name GlobalExtensions
extends RefCounted


## Re-evaluate every QuestNode target against the live global counters.
## A newly completed, unreceived quest is stored as state 1; state 2 means its
## reward was received. Incomplete quests are removed from Global.quest.
## [SRC: decompiled/GlobalExtensions.c @ RefreshQuest (RVA 0x4fcee0);
##       dump.cs:386531 QuestNode.Target and :386600 QuestNode]
static func refresh_quest(global: GlobalState, state, db: ConfigDB, send_notify := false, init := false) -> Array[Dictionary]:
	var completed_now: Array[Dictionary] = []
	if global == null or state == null or db == null:
		return completed_now
	var reward_count := 0
	for raw_quest in db.quests.values():
		var quest := raw_quest as Dictionary
		var was_complete := bool(quest.get("isComplete", false))
		var complete_targets := 0
		var targets: Array = quest.get("target", [])
		for raw_target in targets:
			var target := raw_target as Dictionary
			var condition: Dictionary = target.get("condition", {})
			var is_complete := ConditionEval.evaluate(condition, {"state": state, "db": db})
			target["isComplete"] = is_complete
			if is_complete:
				complete_targets += 1
			else:
				target["value"] = _first_global_counter_value(condition, global)
		var quest_id := int(quest.get("id", 0))
		var is_complete := complete_targets == targets.size()
		quest["isComplete"] = is_complete
		if is_complete:
			if not global.quests.has(quest_id):
				global.quests[quest_id] = 1
			var received := int(global.quests.get(quest_id, 0)) == 2
			quest["isReceived"] = received
			if not received:
				reward_count += 1
			if not was_complete:
				completed_now.append(quest)
				if send_notify:
					global.notify_quest_completed(quest)
				# The source suppresses only the analytics event during init; the
				# state transition itself still occurs. No analytics clone is added.
				if init:
					pass
		else:
			quest["isReceived"] = false
			global.quests.erase(quest_id)
	global.set_has_quest_reward(reward_count > 0)
	return completed_now


static func _first_global_counter_value(condition: Dictionary, global: GlobalState) -> int:
	for raw_key in condition.keys():
		var key := str(raw_key)
		if not key.begins_with("global_counter."):
			continue
		var tail := key.trim_prefix("global_counter.")
		for op in [">=", "<=", "<>", "!=", "=", "<", ">"]:
			if tail.ends_with(op):
				tail = tail.left(-op.length())
				break
		return global.get_counter_value(tail.to_int())
	return 0
