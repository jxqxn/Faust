extends GutTest

const RNG = preload("res://core/rng.gd")
const RiteView = preload("res://ui/rite_view.gd")

var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()

func test_gold_dice_reresolve_does_not_apply_results_twice():
	var rng := RNG.new(1)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.gold_dice = 2
	var view := RiteView.new()
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"settlement": [
			{"condition": {}, "result": {"coin": 5}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._gold_dice_label = Label.new()
	view._gold_dice_btn = Button.new()
	view._result_label = RichTextLabel.new()

	view._resolve()
	assert_eq(state.coin_count, 5, "first resolve applies reward once")
	assert_eq(state.gold_dice, 2, "first resolve does not spend gold dice")

	view._use_gold_dice_reactive()
	assert_eq(state.coin_count, 5, "gold-dice re-resolve restores baseline before applying reward")
	assert_eq(state.gold_dice, 1, "one gold die spent")

	view._use_gold_dice_reactive()
	assert_eq(state.coin_count, 5, "second gold-dice re-resolve still applies reward once")
	assert_eq(state.gold_dice, 0, "second gold die spent")

func test_gold_dice_reresolve_reuses_cached_dice():
	var rng := RNG.new(77)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.gold_dice = 2
	state.add_card_to_hand(2000005)
	var view := RiteView.new()
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"settlement": [
			{"condition": {"r1:智慧>=": [99, 5]}, "result": {"coin": 5}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._placed = {"s1": 2000005}
	view._gold_dice_label = Label.new()
	view._gold_dice_btn = Button.new()
	view._result_label = RichTextLabel.new()

	view._resolve()
	var after_first := rng.get_state()
	view._use_gold_dice_reactive()
	assert_eq(rng.get_state(), after_first, "gold-dice retry reuses the first resolve's dice cache")

func test_resolved_rite_does_not_consume_sudan_without_clean_result():
	var rng := RNG.new(88)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var sudan_id := RoundLoop.draw_weekly_sudan(state, db, rng)
	var view := RiteView.new()
	view.setup(state, db, rng, 5000003)
	view._rite = {
		"settlement": [
			{"condition": {"s1.type": "sudan"}, "result": {}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._placed = {"s1": sudan_id}
	view._gold_dice_label = Label.new()
	view._gold_dice_btn = Button.new()
	view._result_label = RichTextLabel.new()

	view._resolve()
	assert_eq(state.active_sudan_cards.size(), 1, "placing a sudan card does not consume it without an explicit clean result")

func test_resolved_rite_consumes_sudan_when_cleaning_placed_slot():
	var rng := RNG.new(89)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var sudan_id := RoundLoop.draw_weekly_sudan(state, db, rng)
	var view := RiteView.new()
	view.setup(state, db, rng, 5000003)
	view._rite = {
		"settlement": [
			{"condition": {"s1.type": "sudan"}, "result": {"clean.s1": 1}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._placed = {"s1": sudan_id}
	view._gold_dice_label = Label.new()
	view._gold_dice_btn = Button.new()
	view._result_label = RichTextLabel.new()

	view._resolve()
	assert_eq(state.active_sudan_cards.size(), 0, "cleaning the placed sudan slot consumes the active sudan card")

func test_slot_accepts_card_requires_type_and_tag_conditions():
	var rng := RNG.new(90)
	var state := GameState.new()
	var view := RiteView.new()
	view.setup(state, db, rng, 5000001)
	var noble_card: Dictionary = db.get_card(2000005).duplicate(true)
	noble_card["id"] = 2000005
	var protagonist_card: Dictionary = db.get_card(2000001).duplicate(true)
	protagonist_card["id"] = 2000001
	var required_tag := _tag_on_first_not_second(noble_card, protagonist_card)
	var slot_def := {"condition": {"type": "char", required_tag: 1}}

	assert_true(view._slot_accepts_card(slot_def, noble_card), "card with required type and tag is accepted")
	assert_false(view._slot_accepts_card(slot_def, protagonist_card), "card missing required tag is rejected")

func test_slot_accepts_card_rejects_wrong_type():
	var rng := RNG.new(91)
	var state := GameState.new()
	var view := RiteView.new()
	view.setup(state, db, rng, 5000001)
	var card: Dictionary = db.get_card(2000005).duplicate(true)
	card["id"] = 2000005
	assert_false(view._slot_accepts_card({"condition": {"type": "item"}}, card), "wrong card type is rejected")

func test_rite_view_builds_dynamic_slots_from_config():
	var rng := RNG.new(93)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := RiteView.new()
	view.setup(state, db, rng, 5001001)
	view._rite = {
		"cards_slot": {
			"s1": {}, "s2": {}, "s3": {}, "s4": {}, "s5": {}, "s6": {}, "s7": {},
		}
	}
	view._slot_layer = Control.new()
	view._build_slot_placeholders()

	assert_eq(view._slot_buttons.size(), 7, "rite UI should render every configured slot")
	assert_true(view._slot_buttons.has("s7"), "slot generation should not stop at s4")

func test_rite_resolution_deferred_rite_event_and_prompt_reach_state():
	var rng := RNG.new(94)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := RiteView.new()
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"settlement": [
			{"condition": {}, "result": {"event_on": 5310008}, "action": {"rite": 5001001, "prompt": {"id": "p1"}}}
		],
		"settlement_extre": [],
		"settlement_prior": [],
		"cards_slot": {},
	}
	view._gold_dice_label = Label.new()
	view._gold_dice_btn = Button.new()
	view._result_label = RichTextLabel.new()

	view._resolve()

	assert_true(5310008 in state.event_queue, "event_on should enter the runtime event queue")
	assert_true(5001001 in state.available_rites, "rite result should generate a runtime rite entry")
	assert_eq(str(state.event_prompts[0].get("id", "")), "p1", "prompt should enter the runtime prompt queue")

func test_rite_resolution_deferred_choose_reaches_prompt_queue():
	var rng := RNG.new(95)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := RiteView.new()
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"settlement": [
			{"condition": {}, "result": {"choose": {"pop.test": "hello"}}}
		],
		"settlement_extre": [],
		"settlement_prior": [],
		"cards_slot": {},
	}
	view._gold_dice_label = Label.new()
	view._gold_dice_btn = Button.new()
	view._result_label = RichTextLabel.new()

	view._resolve()

	assert_eq(str(state.event_prompts[0].get("id", "")), "choose", "choose results should become a visible prompt")
	assert_eq(str(state.event_prompts[0].get("choices", {}).get("pop.test", "")), "hello")

func test_drop_card_moves_between_hand_slot_and_back():
	var rng := RNG.new(92)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var card_id := int(state.hand[0])
	var view := RiteView.new()
	view.setup(state, db, rng, 5000001)
	view._slot_buttons = {"s1": Button.new()}
	view._slot_titles = {"s1": Label.new()}
	view._slot_details = {"s1": Label.new()}
	var initial_hand_size := state.hand.size()

	view.drop_card_on_slot("s1", {"type": "card", "card_id": card_id, "source": "hand"})

	assert_false(state.has_card_in_hand(card_id), "card leaves hand when placed in a slot")
	assert_eq(state.cards_in_slot(1).size(), 1, "placed card enters the slot table state")
	assert_eq(int(view._placed.get("s1", 0)), card_id)

	view.return_card_to_hand(card_id, "s1")

	assert_true(state.has_card_in_hand(card_id), "card returns to hand when dragged back")
	assert_eq(state.hand.size(), initial_hand_size)
	assert_eq(state.cards_in_slot(1).size(), 0)

func test_prepare_table_preserves_cards_outside_placed_slots():
	var rng := RNG.new(99)
	var state := GameState.new()
	state.add_card_to_slot(2000006, 3, db)
	state.add_card_to_slot(2000007, 1, db)
	var view := RiteView.new()
	view.setup(state, db, rng, 5000001)
	view._placed = {"s1": 2000005}

	view._prepare_table_from_placements()

	assert_eq(state.cards_in_slot(3).size(), 1, "unrelated table cards remain")
	if state.cards_in_slot(3).is_empty():
		return
	assert_eq(int(state.cards_in_slot(3)[0].get("id", 0)), 2000006)
	assert_eq(state.cards_in_slot(1).size(), 1, "placed slot is replaced")
	assert_eq(int(state.cards_in_slot(1)[0].get("id", 0)), 2000005)

func test_prepare_table_clears_slots_cancelled_after_prior_placement():
	var rng := RNG.new(100)
	var state := GameState.new()
	state.add_card_to_slot(2000006, 3, db)
	var view := RiteView.new()
	view.setup(state, db, rng, 5000001)
	view._placed = {"s1": 2000005}

	view._prepare_table_from_placements()
	assert_eq(state.cards_in_slot(1).size(), 1, "initial placement exists")

	view._placed.clear()
	view._prepare_table_from_placements()

	assert_eq(state.cards_in_slot(1).size(), 0, "cancelled placement slot is cleared")
	assert_eq(state.cards_in_slot(3).size(), 1, "unrelated table card still remains")


func test_rite_over_result_emits_game_over_requested():
	# A rite settlement carrying an `over` result must signal game-over to the
	# controller, so rite-driven endings actually fire.
	var rng := RNG.new(91)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := RiteView.new()
	view.setup(state, db, rng, 5000003)
	view._rite = {
		"settlement": [
			{"condition": {}, "result": {"over": 1}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._gold_dice_label = Label.new()
	view._gold_dice_btn = Button.new()
	view._result_label = RichTextLabel.new()
	watch_signals(view)

	view._resolve()
	assert_signal_emitted(view, "game_over_requested", "rite over result should emit game_over_requested")


func test_rite_without_over_does_not_emit_game_over():
	# A normal rite (no over) must not emit game_over_requested.
	var rng := RNG.new(92)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := RiteView.new()
	view.setup(state, db, rng, 5000003)
	view._rite = {
		"settlement": [
			{"condition": {}, "result": {"coin": 1}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._gold_dice_label = Label.new()
	view._gold_dice_btn = Button.new()
	view._result_label = RichTextLabel.new()
	watch_signals(view)

	view._resolve()
	assert_signal_not_emitted(view, "game_over_requested", "normal rite should not emit game_over_requested")


func _tag_on_first_not_second(first: Dictionary, second: Dictionary) -> String:
	var first_tags: Dictionary = first.get("tag", {})
	var second_tags: Dictionary = second.get("tag", {})
	for tag in first_tags:
		if int(first_tags[tag]) != 0 and int(second_tags.get(tag, 0)) == 0:
			return str(tag)
	return str(first_tags.keys()[0])
