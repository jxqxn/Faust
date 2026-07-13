## Runtime card stack owned by one game run.  ConfigDB card dictionaries are
## immutable definitions; all mutable tags and placement live here.
## [SRC: decompiled/CardExtensions.c @ Copy (RVA 0x37f4e0) copies runtime Card
##       data; RiteExtensions.c @ AdsorbCards (RVA 0x38fca0) moves Card values
##       into Rite slots rather than recreating their definition tags.]
class_name CardInstance
extends RefCounted

var uid := 0
var card_id := 0
var tags: Dictionary = {}
var count := 1
var is_lost := false
var zone := "hand" # hand, slot, sudan, removed
var rite_uid := 0
var slot_key := ""


func _init(instance_uid: int = 0, definition_id: int = 0, initial_tags: Dictionary = {}) -> void:
	uid = instance_uid
	card_id = definition_id
	tags = initial_tags.duplicate(true)


func to_save_dict() -> Dictionary:
	return {
		"uid": uid,
		"card_id": card_id,
		"tags": tags.duplicate(true),
		"count": count,
		"is_lost": is_lost,
		"zone": zone,
		"rite_uid": rite_uid,
		"slot_key": slot_key,
	}


static func from_save_dict(data: Dictionary):
	var instance := CardInstance.new(
		int(data.get("uid", 0)),
		int(data.get("card_id", 0)),
		data.get("tags", {}) if data.get("tags", {}) is Dictionary else {}
	)
	instance.count = maxi(int(data.get("count", 1)), 1)
	instance.is_lost = bool(data.get("is_lost", false))
	instance.zone = str(data.get("zone", "hand"))
	instance.rite_uid = int(data.get("rite_uid", 0))
	instance.slot_key = str(data.get("slot_key", ""))
	return instance
