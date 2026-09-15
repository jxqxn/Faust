extends GutTest

## CopyCard / CardExtensions.Copy: the copy is a new runtime Card of the same
## definition that CARRIES the source's runtime tag delta, its count, and a
## recursive copy of its equipped cards.
## [SRC: decompiled/CardExtensions.c @ Copy (RVA 0x37f4e0):
##       PlayerExtensions.AddCard(source.id) -> for each source.equips@+0x40
##       Copy(equip, keep_count=true) -> for each source.tag@+0x30 entry AddTag
##       (0x37e6a0) -> Card.set_count(source.count@0x20) when keep_count is
##       false. CopyCard.__c__DisplayClass4_1.c @ <Do>b__1 (0x508090) is the
##       caller that runs CardExtensions.Copy(card, false).]

const RNG = preload("res://core/rng.gd")

const HOST_CARD := 2000001    # 阿尔图
const EQUIP_CARD := 2000006   # 梅姬, carries inheritable tags


var db: ConfigDB


func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_copy_carries_the_runtime_tag_delta() -> void:
	var state := GameState.new()
	state.add_card_to_hand(HOST_CARD, db)
	var source_uid := state.card_uid_for(HOST_CARD)
	state.get_card_instance(source_uid).tags["社交"] = 2
	var copy_uid := state.copy_card_instance(source_uid, db)
	assert_gt(copy_uid, 0, "the copy is created")
	assert_ne(copy_uid, source_uid, "and it is a distinct object")
	var copy = state.get_card_instance(copy_uid)
	assert_eq(int(copy.tags.get("社交", 0)), 2, "the runtime delta is re-applied onto the copy")
	assert_eq(int(state.effective_card_tags(copy_uid, db).get("社交", 0)), 3,
		"so the copy's effective row is definition 1 + delta 2")
	# The two objects must not share the delta dictionary.
	copy.tags["社交"] = 9
	assert_eq(int(state.get_card_instance(source_uid).tags.get("社交", 0)), 2,
		"mutating the copy leaves the source alone")


func test_copy_carries_the_source_count() -> void:
	var state := GameState.new()
	state.add_card_to_hand(HOST_CARD, db)
	var source_uid := state.card_uid_for(HOST_CARD)
	state.get_card_instance(source_uid).count = 4
	var copy_uid := state.copy_card_instance(source_uid, db)
	assert_eq(int(state.get_card_instance(copy_uid).count), 4, "Card.set_count(source.count)")


func test_copy_does_not_carry_presentation_or_life() -> void:
	var state := GameState.new()
	state.add_card_to_hand(HOST_CARD, db)
	var source_uid := state.card_uid_for(HOST_CARD)
	var source = state.get_card_instance(source_uid)
	source.life = 5
	source.custom_name = "旧名"
	source.custom_text = "旧描述"
	source.rare_up = 2
	var copy = state.get_card_instance(state.copy_card_instance(source_uid, db))
	assert_eq(int(copy.life), 0, "Copy never writes Card.life")
	assert_eq(str(copy.custom_name), "", "Copy never writes custom_name")
	assert_eq(str(copy.custom_text), "", "Copy never writes custom_text")
	assert_eq(int(copy.rare_up), 0, "Copy never writes rareup")


func test_copy_recurses_into_equipped_cards() -> void:
	var state := GameState.new()
	state.add_card_to_hand(HOST_CARD, db)
	var source_uid := state.card_uid_for(HOST_CARD)
	var equip_uid := state.add_card_to_hand(EQUIP_CARD, db)
	state.attach_equipment(source_uid, equip_uid, db, false, false)
	assert_eq(state.get_card_instance(source_uid).equipped_uids.size(), 1)
	var copy_uid := state.copy_card_instance(source_uid, db)
	var copy = state.get_card_instance(copy_uid)
	assert_eq(copy.equipped_uids.size(), 1, "the copy carries a copy of the equipment")
	assert_ne(int(copy.equipped_uids[0]), int(equip_uid), "it is a new equipment object")
	var equip_copy = state.get_card_instance(int(copy.equipped_uids[0]))
	assert_eq(equip_copy.card_id, EQUIP_CARD)
	assert_eq(equip_copy.zone, "equipped", "and it is attached to the copy")
	assert_eq(int(equip_copy.equipped_to_uid), int(copy_uid))
	assert_eq(int(state.effective_card_tags(copy_uid, db).get("体魄", 0)), 5,
		"the copied equipment feeds the copy's effective row")


func test_copy_of_an_unknown_source_returns_zero() -> void:
	var state := GameState.new()
	assert_eq(int(state.copy_card_instance(9999, db)), 0)


func test_copy_operator_ignores_value_and_copies_each_target_once() -> void:
	var state := GameState.new()
	state.add_card_to_hand(HOST_CARD, db)
	var source_uid := state.card_uid_for(HOST_CARD)
	# Slot 1 of this rite is not an open_adsorb slot, so the source stays put.
	state.add_card_to_slot(source_uid, 1, db, 0)
	var source = state.get_card_instance(source_uid)
	source.tags["社交"] = 2
	assert_eq(source.zone, "slot")
	var context := {}
	var target_uids: Array = ResultExec._slot_target_uids("s1", state, context)
	assert_eq(target_uids, [source_uid], "the slot selector resolves the slotted source")
	var hand_before := state.hand.size()
	ResultExec.execute({"copy.s1": 2}, state, db, context)
	assert_eq(state.hand.size(), hand_before + 1, "CopyCard.Do ignores Value; one callback per selected card")
	var copied_rows := 0
	for uid in state.hand:
		var instance = state.get_card_instance(uid)
		if instance.card_id != HOST_CARD or int(uid) == source_uid:
			continue
		copied_rows += 1
		assert_eq(int(instance.tags.get("社交", 0)), 2,
			"each copy carries the source's runtime delta")
	assert_eq(copied_rows, 1)
