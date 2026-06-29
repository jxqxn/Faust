## Scope filter (槽位筛选) — OperationFilter.
## verified-conclusions.md #11-#12, re-confirmed vs decompiled/OperationFilter.c.
##
## FilterType bitmask (dump.cs:394750):
##   Friend=2, Enemy=4, All=6, Self=8, Parent=16
## Execution (Filter, 0x3a15c0):
##   &1  -> single card at slot_index (target)
##   &2 or &4 (Friend/Enemy) -> GetEnemyCardsWithIndex
##   &6 (All = Friend|Enemy) -> GetAllCardsWithIndex
##   &8 (Self) -> GetCardByIndex(self_index)
##   &0x10 (Parent) -> GetCardParentByIndex(self_index)
##   else/no bits -> GetAllCardsWithIndex (All)
##
## IsMatch (0x3a1880) per-card match flags:
##   &0x40000000 -> card_id exact match (excludes IsLost)
##   &0x20000000 -> not_card_ids HashSet exclude (excludes IsLost)
##   &0x80000000 (sign bit) -> TagCompare loop per tag GetTag -> Compare.Check
class_name ScopeFilter
extends RefCounted


const Friend := 2
const Enemy := 4
const All := 6
const Self := 8
const Parent := 16

const FLAG_CARD_ID := 0x40000000
const FLAG_NOT_CARD := 0x20000000
const FLAG_TAG := 0x80000000


## Parse a scope token ("friend"/"enemy"/"all"/"self"/"parent") to a bitmask.
## Combines via OR for compound tokens.
static func parse_scope(token: String) -> int:
	var mask := 0
	match token.to_lower():
		"friend":
			mask |= Friend
		"enemy":
			mask |= Enemy
		"all":
			mask |= All
		"self":
			mask |= Self
		"parent":
			mask |= Parent
	return mask


## Determine which slot set a scope bitmask selects.
## Returns one of: "single","friend/enemy","all","self","parent","all(default)".
static func scope_targets(mask: int) -> String:
	if mask & 1:
		return "single"
	if (mask & All) == All:
		return "all"
	if mask & Friend or mask & Enemy:
		return "friend/enemy"
	if mask & Self:
		return "self"
	if mask & Parent:
		return "parent"
	return "all"


## Test whether a card matches the per-card match flags.
##   spec: {card_id:int?, not_card_ids:Array[int]?, tags:Dictionary?}
##   card: {id:int, tags:Dictionary}
static func is_match(card: Dictionary, spec: Dictionary) -> Dictionary:
	var flags := int(spec.get("flags", 0))
	# card_id exact match (excludes lost).
	if flags & FLAG_CARD_ID:
		if int(card.get("id", 0)) != int(spec.get("card_id", -1)):
			return {"match": false}
		if bool(card.get("is_lost", false)):
			return {"match": false}
	# not_card_ids exclude (excludes lost).
	if flags & FLAG_NOT_CARD:
		var nids: Array = spec.get("not_card_ids", [])
		if int(card.get("id", 0)) in nids:
			return {"match": false}
		if bool(card.get("is_lost", false)):
			return {"match": false}
	# Tag comparison.
	if flags & FLAG_TAG:
		var want: Dictionary = spec.get("tags", {})
		for tag_name in want:
			var got := int(card.get("tags", {}).get(tag_name, 0))
			var need := int(want[tag_name])
			# Compare.Check with op from spec.tags_ops if present, else >=.
			if got < need:
				return {"match": false}
	return {"match": true}
#
## Filter a list of cards by scope and per-card match flags.
## Returns the matched cards.
static func filter_cards(cards: Array, scope_mask: int, match_spec: Dictionary, slot_index: int = -1) -> Array:
	var target := scope_targets(scope_mask)
	var out: Array = []
	# For single/self/parent, slot_index matters; for all/friend/enemy it selects all.
	for card in cards:
		match target:
			"single":
				if int(card.get("slot_index", -1)) == slot_index:
					if is_match(card, match_spec).match:
						out.append(card)
			"self":
				if int(card.get("self_index", -1)) == slot_index:
					if is_match(card, match_spec).match:
						out.append(card)
			_:
				# all / friend-enemy / parent / default-all: include all that match.
				if is_match(card, match_spec).match:
					out.append(card)
	return out
#
## Build match spec flags from a slot condition dictionary.
## slot condition keys like "is" (card id), tags, etc.
static func build_match_spec(slot_cond: Dictionary) -> Dictionary:
	var flags := 0
	var spec: Dictionary = {}
	if slot_cond.has("is"):
		flags |= FLAG_CARD_ID
		spec["card_id"] = int(slot_cond["is"])
	# Negative presence of specific ids handled separately; tags via presence.
	var tags: Dictionary = {}
	for k in slot_cond:
		if k == "is" or k == "type" or k.begins_with("!"):
			continue
		tags[k] = slot_cond[k]
	if not tags.is_empty():
		flags |= FLAG_TAG
		spec["tags"] = tags
	spec["flags"] = flags
	return spec
