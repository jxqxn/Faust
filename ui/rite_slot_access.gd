extends RefCounted

# RitePanelShowController.Show 0x596450 L649-658, L892-900 passes
# !Slot.open_adsorb && !Rite.start into CardSlotController.Init's can_move.
# Independent layout: dump.cs CardSlotController can_move +0x158,
# Rite.start +0x22, RiteNode.Slot.open_adsorb +0x20.
static func can_edit(state, db, rite_uid: int, slot_key: String) -> bool:
	if state == null or db == null:
		return false
	var rite = state.get_rite_instance(rite_uid)
	if rite == null:
		return rite_uid == 0
	if rite.start:
		return false
	var slots: Dictionary = db.get_rite(rite.id).get("cards_slot", {})
	return slots.has(slot_key) and int(slots[slot_key].get("open_adsorb", 0)) == 0

static func can_move_source(state, db, data: Dictionary) -> bool:
	if bool(data.get("detached_from_slot", false)):
		var card = state.get_card_instance(int(data.get("card_uid", 0)))
		return card != null and card.zone == "drag"
	if str(data.get("source", "")) != "slot":
		return true
	return can_edit(state, db, int(data.get("source_rite_uid", 0)), str(data.get("source_slot", "")))
