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
# Elapsed days toward the template's card_vanishing lifetime; counts up daily,
# cards in any rite slot skip the death check (shelter). [SRC: Card.life @+0x24,
# CardNode.card_vanishing @+0x60; GameController.c DoCardUpdate 0x54d4c0]
var life := 0
var is_lost := false
var zone := "hand" # hand, slot, sudan, removed
var rite_uid := 0
var slot_key := ""
# Persistent presentation/gameplay deltas. The definition id never changes:
# the original Card stores rareup/custom_name/custom_text on the runtime card.
# [SRC: decompiled/OperationContext.c @ UprareCard (RVA 0x3a03d0);
#  decompiled/ChangeCardName.__c__DisplayClass7_0.c @ <Do>b__0;
#  decompiled/Card.c @ get_Rare (RVA 0x383c30)]
var rare_up := 0
var custom_name := ""
var custom_text := ""
var equip_slots: Array[String] = []
var removed_equip_slots: Array[String] = []
var equipped_uids: Array[int] = []
var equipped_to_uid := 0
var equipped_slot := ""


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
		"life": life,
		"is_lost": is_lost,
		"zone": zone,
		"rite_uid": rite_uid,
		"slot_key": slot_key,
		"rare_up": rare_up,
		"custom_name": custom_name,
		"custom_text": custom_text,
		"equip_slots": equip_slots.duplicate(),
		"removed_equip_slots": removed_equip_slots.duplicate(),
		"equipped_uids": equipped_uids.duplicate(),
		"equipped_to_uid": equipped_to_uid,
		"equipped_slot": equipped_slot,
	}


static func from_save_dict(data: Dictionary):
	var instance := CardInstance.new(
		int(data.get("uid", 0)),
		int(data.get("card_id", 0)),
		data.get("tags", {}) if data.get("tags", {}) is Dictionary else {}
	)
	instance.count = maxi(int(data.get("count", 1)), 1)
	instance.life = int(data.get("life", 0))
	instance.is_lost = bool(data.get("is_lost", false))
	instance.zone = str(data.get("zone", "hand"))
	instance.rite_uid = int(data.get("rite_uid", 0))
	instance.slot_key = str(data.get("slot_key", ""))
	instance.rare_up = int(data.get("rare_up", 0))
	instance.custom_name = str(data.get("custom_name", ""))
	instance.custom_text = str(data.get("custom_text", ""))
	for slot in data.get("equip_slots", []):
		instance.equip_slots.append(str(slot))
	for slot in data.get("removed_equip_slots", []):
		instance.removed_equip_slots.append(str(slot))
	for equipped_uid in data.get("equipped_uids", []):
		instance.equipped_uids.append(int(equipped_uid))
	instance.equipped_to_uid = int(data.get("equipped_to_uid", 0))
	instance.equipped_slot = str(data.get("equipped_slot", ""))
	return instance
