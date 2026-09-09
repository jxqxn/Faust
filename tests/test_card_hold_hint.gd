extends GutTest

## Card hold hint, source-backed:
## [SRC: CardController.Update 0x52c890 — a press held for 0.2s (ctor default
##       0x3e4ccccd) calls GameController.ShowSatisfiedRite 0x557a80, which
##       highlights every rite whose open slot accepts the card
##       (CardHandler.GetCardSatisfiedRite 0x532e10 ->
##       RiteExtensions.GetSatisfiedSlotIndex 0x392ac0 ->
##       RiteController.ShowEffect(1)).]

const RNG = preload("res://core/rng.gd")
const MapController = preload("res://ui/map_controller.gd")

const RITE_ID := 5000001  # 治理家业: s1 condition {type: char, 贵族: 1}
const NOBLE_ID := 2000001  # 阿尔图, char + 贵族
const ITEM_ID := 2000029  # 金币, item

var db: ConfigDB


func before_all():
	db = ConfigDB.new()
	db.load_all()


func _state() -> GameState:
	var rng := RNG.new(8801)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.rite_instances.clear()
	state.hand.clear()
	state.rail_order.clear()
	return state


func test_satisfied_rite_uids_follow_the_slot_condition() -> void:
	var state := _state()
	var rite = state.create_rite_instance(RITE_ID)
	var noble_uid := int(state.add_card_to_hand(NOBLE_ID, db))
	var item_uid := int(state.add_card_to_hand(ITEM_ID, db))
	assert_eq(state.satisfied_rite_uids_for_card(noble_uid, db), [rite.uid], "a noble character satisfies s1")
	assert_eq(state.satisfied_rite_uids_for_card(item_uid, db), [], "an item does not")


func test_satisfied_rite_uids_skip_started_and_occupied_rites() -> void:
	var state := _state()
	var rite = state.create_rite_instance(RITE_ID)
	var noble_uid := int(state.add_card_to_hand(NOBLE_ID, db))
	assert_eq(state.satisfied_rite_uids_for_card(noble_uid, db), [rite.uid])

	state.start_rite_instance(rite.uid)
	assert_eq(state.satisfied_rite_uids_for_card(noble_uid, db), [], "Rite.start is skipped")
	rite.start = false

	# 5000001 accepts a noble in s1 and any character in s2; filling both leaves
	# no open slot for the card, while s3 is an open_adsorb slot and s4 wants an
	# item.
	state.add_card_to_slot(noble_uid, 1, db, rite.uid)
	var second_noble := int(state.add_card_to_hand(NOBLE_ID, db))
	state.add_card_to_slot(second_noble, 2, db, rite.uid)
	assert_eq(state.satisfied_rite_uids_for_card(noble_uid, db), [], "no open slot is left")


func test_card_widget_hold_hint_fires_once_after_the_source_threshold() -> void:
	var card := {"id": NOBLE_ID, "name": "Test", "type": "char", "rare": 3, "tag": {}}
	var widget := CardWidget.make(card, "hand")
	add_child_autofree(widget)
	await wait_process_frames(1)
	widget.set_process(false)
	watch_signals(widget)

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(10, 10)
	widget._gui_input(press)
	widget._process(0.1)
	assert_signal_not_emitted(widget, "hold_hint_requested", "below the 0.2s threshold")
	widget._process(0.15)
	assert_signal_emitted_with_parameters(widget, "hold_hint_requested", [widget.card_uid])
	widget._process(0.5)
	assert_signal_emit_count(widget, "hold_hint_requested", 1, "the hint fires once per press")

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(10, 10)
	widget._gui_input(release)
	assert_signal_emitted(widget, "hold_hint_cleared")


func test_map_highlights_only_the_satisfied_rite_cards() -> void:
	var state := _state()
	var first = state.create_rite_instance(RITE_ID)
	var second = state.create_rite_instance(RITE_ID)
	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	add_child_autofree(stage)
	var desk := MapController.new()
	desk.setup(state, db, RNG.new(8802))
	desk.size = stage.size
	stage.add_child(desk)
	await wait_process_frames(2)
	desk.show_satisfied_rites([first.uid])
	var first_card := desk.rite_cards.get(first.uid) as Control
	var second_card := desk.rite_cards.get(second.uid) as Control
	assert_not_null(first_card)
	assert_not_null(second_card)
	if first_card != null and second_card != null:
		assert_true(bool(first_card.get("satisfied_hint")), "the satisfied rite pulses")
		assert_false(bool(second_card.get("satisfied_hint")), "the other rite stays quiet")
	desk.show_satisfied_rites([])
	if first_card != null:
		assert_false(bool(first_card.get("satisfied_hint")), "an empty list clears the hint")
