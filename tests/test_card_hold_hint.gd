extends GutTest

## Card hold hint, source-backed:
## [SRC: CardController.Update 0x52c890 — a press held for 0.2s (ctor default
##       0x3e4ccccd) calls GameController.ShowSatisfiedRite 0x5576b0, which
##       highlights every rite whose open slot accepts the card
##       (CardHandler.GetCardSatisfiedRite 0x52e770 ->
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
	widget._process(0.1)
	assert_signal_not_emitted(widget, "hold_hint_requested", "source comparison is strictly greater than 0.2s")
	widget._process(0.01)
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
		assert_true(bool(first_card.get("satisfied_hint")), "an empty result does not cancel an existing one-shot")
		await wait_seconds(1.1)
		assert_false(bool(first_card.get("satisfied_hint")), "source animation finishes without a release")
		assert_eq(first_card.modulate, Color.WHITE, "the whole sign must not change color")
		assert_almost_eq((first_card.get_node("IconOutline") as CanvasItem).modulate.a, 0.0, 0.001)


func test_pausing_card_cancels_pending_hold_without_retriggering_on_resume() -> void:
	var widget := CardWidget.make({"id": NOBLE_ID, "name": "Test", "type": "char", "rare": 3, "tag": {}}, "hand")
	add_child_autofree(widget)
	await wait_process_frames(1)
	widget.set_process(false)
	watch_signals(widget)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	widget._gui_input(press)
	widget._process(0.1)
	widget.set_presentation_paused(true)
	widget.set_presentation_paused(false)
	widget._process(0.5)
	assert_signal_not_emitted(widget, "hold_hint_requested")


func test_hint_animation_replays_source_alpha_and_rewind() -> void:
	var state := _state()
	var rite = state.create_rite_instance(RITE_ID)
	var desk := MapController.new()
	desk.setup(state, db, RNG.new(8803))
	desk.size = Vector2(3840, 2160)
	add_child_autofree(desk)
	await wait_process_frames(2)
	var card = desk.rite_cards[rite.uid]
	var outline := card.get_node("IconOutline") as TextureRect
	assert_eq(outline.texture.get_size(), Vector2(195, 273), "source generic outline frame")
	assert_almost_eq(outline.size, Vector2(152, 208) * 2160.0 * 1.25 / 3464.0, Vector2.ONE * 0.001)
	desk.show_satisfied_rites([rite.uid])
	card._hint_tween.pause()
	card._hint_tween.custom_step(0.125)
	assert_almost_eq(outline.modulate.a, 0.5, 0.001, "zero tangent Hermite midpoint")
	card._hint_tween.custom_step(0.375)
	assert_almost_eq(outline.modulate.a, 1.0, 0.001)
	desk.show_satisfied_rites([rite.uid])
	card._hint_tween.pause()
	assert_almost_eq(outline.modulate.a, 0.0, 0.001, "ShowEffect rewinds an existing clip")
	card._hint_tween.custom_step(1.1)
	assert_false(card.satisfied_hint)
	assert_almost_eq(outline.modulate.a, 0.0, 0.001)
