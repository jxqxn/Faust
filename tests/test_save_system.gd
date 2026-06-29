extends GutTest

## Tests for the save/load system: serialize -> deserialize round-trip must
## preserve all gameplay-relevant GameState fields.

const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
const RNG = preload("res://core/rng.gd")
const RoundLoop = preload("res://sim/round_loop.gd")
const SaveSystem = preload("res://sim/save_system.gd")

var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()

func test_save_load_round_trip_preserves_state():
	var rng := RNG.new(42)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	RoundLoop.draw_weekly_sudan(state, db, rng)
	state.add_coin(15)
	state.gold_dice = 1
	state.day = 3
	state.round_number = 2
	state.add_card_to_slot(2000001, 1, db)
	state.table_cards[0].tags["临时标记"] = 7
	state.started_rites.append(5000001)
	# Serialize.
	var data := SaveSystem.serialize(state)
	# Deserialize into a fresh state.
	var state2 := GameState.new()
	SaveSystem.deserialize(data, state2, db)
	# Verify all fields preserved.
	assert_eq(state2.difficulty_index, 1, "difficulty preserved")
	assert_eq(state2.round_number, 2, "round_number preserved")
	assert_eq(state2.day, 3, "day preserved")
	assert_eq(state2.coin_count, 15, "coin_count preserved")
	assert_eq(state2.gold_dice, 1, "gold_dice preserved")
	assert_eq(state2.hand.size(), state.hand.size(), "hand size preserved")
	assert_eq(state2.sudan_deck.size(), state.sudan_deck.size(), "sudan_deck size preserved")
	assert_eq(state2.active_sudan_cards.size(), 1, "active sudan card preserved")
	assert_eq(state2.table_cards.size(), 1, "table card preserved")
	if state2.table_cards.size() > 0:
		assert_eq(int(state2.table_cards[0].get("id", 0)), 2000001, "table card id preserved")
		assert_eq(int(state2.table_cards[0].get("slot", 0)), 1, "table card slot preserved")
		assert_eq(int(state2.table_cards[0].get("tags", {}).get("临时标记", 0)), 7, "table card tags preserved")
	assert_true(5000001 in state2.started_rites, "started rites preserved")
	if state2.active_sudan_cards.size() > 0:
		var asc = state2.active_sudan_cards[0]
		assert_eq(asc.card_id, state.active_sudan_cards[0].card_id, "sudan card_id preserved")
		assert_eq(asc.days_left, state.active_sudan_cards[0].days_left, "sudan days_left preserved")

func test_load_missing_save_returns_null():
	SaveSystem.delete_save()
	var result = SaveSystem.load(db)
	assert_eq(result, null, "no save -> null")
