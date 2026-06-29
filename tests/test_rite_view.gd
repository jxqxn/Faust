extends GutTest

const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
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
