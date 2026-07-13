## Runtime state for one generated rite. ConfigDB holds RiteNode definitions;
## a player run owns RiteInstance objects that reference those definitions.
##
## [SRC: il2cpp_dump/dump.cs:392391 Rite fields uid/id/new_born/is_show/
##       start/start_round/start_life/life/cards; decompiled/StartRite.c @ Do
##       (RVA 0x51bcf0) initializes a rite before GameController.AddRite.]
class_name RiteInstance
extends RefCounted

var uid: int = 0
var id: int = 0
var new_born := true
var is_show := false
var start := false
var start_round := 0
var start_life := 0
var life := 0
# Authoritative slot ownership: `s1` -> CardInstance uid.  The legacy cards
# array remains a derived compatibility view while condition/result callers
# finish their migration.
var slot_cards: Dictionary = {}
var cards: Array[Dictionary] = []
var is_cleaned := false
var custom_name := ""


func _init(instance_uid: int = 0, rite_id: int = 0) -> void:
	uid = instance_uid
	id = rite_id


func to_save_dict() -> Dictionary:
	var card_data: Array = []
	for card in cards:
		card_data.append(card.duplicate(true))
	return {
		"uid": uid,
		"id": id,
		"new_born": new_born,
		"is_show": is_show,
		"start": start,
		"start_round": start_round,
		"start_life": start_life,
		"life": life,
		"slot_cards": slot_cards.duplicate(true),
		"cards": card_data,
		"is_cleaned": is_cleaned,
		"custom_name": custom_name,
	}


static func from_save_dict(data: Dictionary) -> RiteInstance:
	var instance := RiteInstance.new(int(data.get("uid", 0)), int(data.get("id", 0)))
	instance.new_born = bool(data.get("new_born", true))
	instance.is_show = bool(data.get("is_show", false))
	instance.start = bool(data.get("start", false))
	instance.start_round = int(data.get("start_round", 0))
	instance.start_life = int(data.get("start_life", 0))
	instance.life = int(data.get("life", 0))
	for slot_key in data.get("slot_cards", {}):
		instance.slot_cards[str(slot_key)] = int(data["slot_cards"][slot_key])
	instance.is_cleaned = bool(data.get("is_cleaned", false))
	instance.custom_name = str(data.get("custom_name", ""))
	for card in data.get("cards", []):
		if card is Dictionary:
			instance.cards.append(card.duplicate(true))
	return instance
