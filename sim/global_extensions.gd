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


## Claim one completed quest exactly at the original Global boundary.  The
## misspelt source method is GetQuestRewqrd; keep the public clone spelling
## readable while preserving its state transition and persistence order.
## [SRC: decompiled/GlobalExtensions.c @ GetQuestRewqrd (RVA 0x4fc860);
##       dump.cs:311845-311847, 385568-385576, 386600 QuestNode]
static func get_quest_reward(global: GlobalState, quest_id: int, db: ConfigDB) -> bool:
	if global == null or db == null:
		return false
	var quest := db.get_quest(quest_id)
	if quest.is_empty() or not bool(quest.get("isComplete", false)):
		return false
	if bool(quest.get("isReceived", false)) or int(global.quests.get(quest_id, 0)) == 2:
		return false
	quest["isReceived"] = true
	global.quests[quest_id] = 2
	global.total_point += int(quest.get("upgrade_point", 0))
	global.save()
	global.set_has_quest_reward(_count_available_rewards(global, db) > 0)
	return true


## The title-screen red dot ignores an upgrade's visibility condition: it is
## on when any unpurchased raw UpgradeNode costs no more than current
## totalPoint. This deliberately does not use usedPoint or totalPoint-usedPoint.
## [SRC: decompiled/GlobalExtensions.c @ HasAvailableUpgrade (RVA 0x4fcd00);
##       dump.cs:311849-311851, 385575-385583]
static func has_available_upgrade(global: GlobalState, db: ConfigDB) -> bool:
	if global == null or db == null:
		return false
	for raw_upgrade in db.upgrades.values():
		var upgrade := raw_upgrade as Dictionary
		var upgrade_id := int(upgrade.get("id", 0))
		if not global.upgrades.has(upgrade_id) and int(upgrade.get("cost", 0)) <= global.total_point:
			return true
	return false


static func _count_available_rewards(global: GlobalState, db: ConfigDB) -> int:
	var count := 0
	for raw_quest in db.quests.values():
		var quest := raw_quest as Dictionary
		var quest_id := int(quest.get("id", 0))
		var received := bool(quest.get("isReceived", false)) or int(global.quests.get(quest_id, 0)) == 2
		if bool(quest.get("isComplete", false)) and not received:
			count += 1
	return count


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
