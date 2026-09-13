extends RefCounted

# PromptControllerBase.ShowInternal 0x589890; dump.cs:323540.
# A scalar uses the middle slot; an outer array addresses slots in order.
static func resolve(value: Variant, state, db) -> Dictionary:
	var result := {"slots": [null, null, null], "full": null}
	if value is String:
		if value.begins_with("full"):
			result.full = _texture(value)
		else:
			result.slots[1] = _slot(value, state, db)
	elif value is Array:
		var target := 0
		for i in mini(value.size(), 3):
			var item: Variant = value[i]
			if item is String and item.begins_with("full"):
				result.full = _texture(item)
				continue
			result.slots[target] = _slot(item, state, db)
			target += 1
	return result


# SetIcon 0x58a210 / .cctor 0x58ab00: inner arrays are config-card fans.
static func _slot(value: Variant, state, db) -> Variant:
	if value is String:
		var resource: String = value
		if resource.begins_with("pic/") and resource.substr(4).is_valid_int():
			var id := int(resource.substr(4))
			var uid := _find_card(id, state)
			var card: Dictionary = state.card_data_for(uid, db) if uid != 0 else db.get_card(id)
			resource = _card_resource(card)
		return {"texture": _texture(resource), "resource": resource}
	if value is Array:
		var poses := [Vector2(280, 18), Vector2(430, 10), Vector2(580, 2)]
		var start := 1 if value.size() in [1, 2] else 0
		var cards: Array = []
		for i in mini(value.size(), 3):
			if not str(value[i]).is_valid_int() or int(value[i]) == 0:
				continue
			var card: Dictionary = db.get_card(int(value[i]))
			if card.is_empty():
				continue
			cards.append({"card": card, "pose": poses[start + i]})
		return {"cards": cards}
	return null


# PlayerExtensions.FindCard 0x38c740: player.cards first, then each rite's
# cards. Detached/consumed instances in the host registry are not candidates.
static func _find_card(id: int, state) -> int:
	if state == null:
		return 0
	for uid in state.hand:
		var card = state.get_card_instance(int(uid))
		if card != null and card.card_id == id:
			return int(uid)
	for rite_uid in state.rite_instances:
		for entry in state.cards_in_slot_entries_for_rite(int(rite_uid)):
			var uid := int(entry.get("card_uid", 0))
			var card = state.get_card_instance(uid)
			if card != null and card.card_id == id:
				return uid
	return 0


# CardExtensions.GetPic 0x3803b0 / 0x3802f0: pic index clamped to resources.
static func _card_resource(card: Dictionary) -> String:
	var resource: Variant = card.get("resource", "")
	if resource is Array:
		if resource.is_empty():
			return ""
		resource = resource[clampi(int(card.get("tag", {}).get("pic", 0)), 0, resource.size() - 1)]
	return str(resource)


static func _texture(resource: String) -> Texture2D:
	if resource.is_empty():
		return null
	# Native Sprite rect/PPU imported from the source .asset. The PNG is its
	# backing texture, not necessarily the displayed Sprite's dimensions.
	var sprite_path := "res://assets/original/prompt_sprites/%s.tres" % resource
	if ResourceLoader.exists(sprite_path):
		return load(sprite_path) as Texture2D
	var paths := ["res://assets/original/%s.png" % resource]
	# Existing extracted common artwork lives beside card portraits.
	if resource.begins_with("common/"):
		paths.append("res://assets/original/cards/%s.png" % resource.get_file())
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null
