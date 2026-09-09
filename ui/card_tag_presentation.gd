extends RefCounted

# [SRC: CardInfoNewController.RefreshAllTags 0x535270;
# CardInfoNewController.<>c 0x393940; dump.cs:386926 TagNode.]
static func group(card: Dictionary, db, state_icons: Dictionary = {}) -> Dictionary:
	var groups := {"tags": [], "attributes": [], "states": []}
	if db == null:
		return groups
	var tags: Dictionary = card.get("tag", {})
	var base: Dictionary = db.get_card(int(card.get("id", 0))).get("tag", {})
	var order := 0
	for raw_name in tags:
		var tag_name := str(raw_name)
		var code := str(db.tag_name_to_code.get(tag_name, tag_name))
		var node: Dictionary = db.tags_by_code.get(code, {})
		var value := int(tags[raw_name])
		# GetTag's public read masks disallowed negatives, without changing state.
		if not bool(node.get("can_nagative_and_zero", false)):
			value = maxi(0, value)
		value *= int(card.get("count", 1))
		if not bool(node.get("can_visible", false)):
			continue
		if not bool(node.get("can_add", false)) and value == 0:
			continue
		if not bool(node.get("can_nagative_and_zero", false)) and value <= 0:
			continue
		var entry := node.duplicate(true)
		entry["_source_name"] = str(node.get("name", tag_name))
		entry["_source_value"] = value
		entry["_source_index"] = order
		# [SRC: CardExtensions.GetTagWithDiff 0x3811e0, Card.data@0x68.]
		entry["_source_diff"] = value - int(base.get(raw_name, 0))
		var bucket := "states" if state_icons.has(code) else ("attributes" if str(node.get("type", "")) == "attribute" else "tags")
		groups[bucket].append(entry)
		order += 1
	for key in groups:
		groups[key].sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if int(a.get("tag_rank", 0)) == int(b.get("tag_rank", 0)):
				return int(a["_source_index"]) < int(b["_source_index"])
			return int(a.get("tag_rank", 0)) > int(b.get("tag_rank", 0))
		)
	return groups
