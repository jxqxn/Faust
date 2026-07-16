## Lightweight runtime card used by the calendar-relationship mode.
## Static content is copied in so mutable card state never leaks back into a
## repository definition.
class_name PrototypeCard
extends RefCounted

var card_id: String = ""
var kind: String = ""
var owner_id: String = ""
var display_name: String = ""
var tags: Array = []
var state: Dictionary = {}
var consumed: bool = false


func _init(id: String = "", card_kind: String = "") -> void:
	card_id = id
	kind = card_kind


func has_tag(tag: String) -> bool:
	return tag in tags


func to_dict() -> Dictionary:
	return {
		"card_id": card_id,
		"kind": kind,
		"owner_id": owner_id,
		"display_name": display_name,
		"tags": tags.duplicate(true),
		"state": state.duplicate(true),
		"consumed": consumed,
	}


static func from_dict(data: Dictionary):
	var card = load("res://modes/calendar_coop/model/prototype_card.gd").new(str(data.get("card_id", "")), str(data.get("kind", "")))
	card.owner_id = str(data.get("owner_id", ""))
	card.display_name = str(data.get("display_name", ""))
	card.tags = data.get("tags", []).duplicate(true) if data.get("tags", []) is Array else []
	card.state = data.get("state", {}).duplicate(true) if data.get("state", {}) is Dictionary else {}
	card.consumed = bool(data.get("consumed", false))
	return card
