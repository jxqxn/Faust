extends GutTest

const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
const RNG = preload("res://core/rng.gd")
const RiteView = preload("res://ui/rite_view.gd")
const RoundLoop = preload("res://sim/round_loop.gd")

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

func test_resolved_rite_consumes_placed_active_sudan_card():
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
	assert_eq(state.active_sudan_cards.size(), 0, "placed active sudan card is consumed after a matching rite settlement")
