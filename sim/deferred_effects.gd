## Applies deferred rite/result effects to the live world.
## Keeps UI surfaces thin: RiteView, Methinks, and desktop prompts all send
## their deferred effects here instead of duplicating event/choice/loot wiring.
class_name DeferredEffects
extends RefCounted

static func apply(deferred: Dictionary, state, db, rng) -> void:
	for event_id in deferred.get("events", []):
		if state.has_method("queue_event"):
			state.queue_event(int(event_id))
	for prompt in deferred.get("prompts", []):
		if prompt is Dictionary and state.has_method("queue_prompt"):
			state.queue_prompt(prompt)
	var choices: Dictionary = deferred.get("choose", {})
	if not choices.is_empty() and state.has_method("queue_choice_prompt"):
		state.queue_choice_prompt(choices)
	var next_rite := int(deferred.get("rite", 0))
	if next_rite > 0 and state.has_method("add_available_rite"):
		state.add_available_rite(next_rite)
	for loot_ref in deferred.get("loots", []):
		_apply_loot_ref(loot_ref, state, db, rng)


static func execute_choice(choice_key: String, choice_value: Variant, state, db, rng) -> void:
	if choice_key == "":
		return
	var result := {choice_key: choice_value}
	var deferred := ResultExec.execute(result, state, db)
	apply(deferred, state, db, rng)


static func _apply_loot_ref(loot_ref: Variant, state, db, rng) -> void:
	if loot_ref is Array:
		for nested in loot_ref:
			_apply_loot_ref(nested, state, db, rng)
		return
	var loot_id := int(loot_ref)
	var loot: Dictionary = db.get_loot(loot_id) if db != null and db.has_method("get_loot") else {}
	if loot.is_empty():
		if state.has_method("queue_prompt"):
			state.queue_prompt({"id": "loot.%d" % loot_id, "text": "获得掉落 %d" % loot_id})
		return
	var owned := _owned_ids(state)
	var generated: Array = LootSystem.generate(rng, loot, owned)
	for id in generated:
		_apply_loot_item(int(id), state, db, rng)


static func _apply_loot_item(id: int, state, db, rng) -> void:
	if id <= 0:
		return
	if db != null and not db.get_card(id).is_empty():
		state.add_card_to_hand(id)
		if state.has_method("queue_prompt"):
			var card: Dictionary = db.get_card(id)
			state.queue_prompt({"id": "card.%d" % id, "text": "获得卡牌：%s" % str(card.get("name", id))})
		return
	if db != null and not db.get_rite(id).is_empty():
		if state.has_method("add_available_rite"):
			state.add_available_rite(id)
		if state.has_method("queue_prompt"):
			var rite: Dictionary = db.get_rite(id)
			state.queue_prompt({"id": "rite.%d" % id, "text": "出现新的仪式：%s" % str(rite.get("name", id))})
		return
	if db != null and not db.get_event(id).is_empty():
		if state.has_method("queue_event"):
			state.queue_event(id)
		return
	if db != null and not db.get_loot(id).is_empty():
		_apply_loot_ref(id, state, db, rng)
		return
	if state.has_method("queue_prompt"):
		state.queue_prompt({"id": "loot_item.%d" % id, "text": "获得内容 %d" % id})


static func _owned_ids(state) -> Array:
	var ids: Array = []
	for cid in state.hand:
		ids.append(int(cid))
	for rid in state.available_rites:
		ids.append(int(rid))
	for eid in state.event_queue:
		ids.append(int(eid))
	for asc in state.active_sudan_cards:
		ids.append(int(asc.card_id))
	return ids
