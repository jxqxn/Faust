extends GutTest

## Result-text playback rate: variable.json holds exactly two rates and the
## result panel picks between them by its auto-play flag. There is no x1/x2
## cycle, and the value is clamped before use.
## [SRC: RiteResultPanelController.c @ UpdateResultTextSpeed (RVA 0x5a74a0):
##       autoPlay == 0 -> Player.result_text_play_rate@0x68, else
##       Player.result_text_auto_play_rate@0x6C; clamped to [0.5, 100.0]
##       (GameAssembly.dll 0x1c92b4c = 0f, 0x1c9e4d0 = 100f).]

const RNG = preload("res://core/rng.gd")


var db: ConfigDB


func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_variable_config_is_loaded() -> void:
	assert_false(db.variable_config.is_empty(), "variable.json loads into ConfigDB")
	assert_eq(float(db.variable_config.get("result_text_play_rate", 0.0)), 1.0)
	assert_eq(float(db.variable_config.get("result_text_auto_play_rate", 0.0)), 15.0)


func test_rate_follows_the_auto_play_flag() -> void:
	var state := GameState.new()
	assert_eq(state.source_result_text_rate(false), 1.0, "manual playback uses result_text_play_rate")
	assert_eq(state.source_result_text_rate(true), 15.0, "auto playback uses result_text_auto_play_rate")


func test_rate_is_clamped_to_the_source_bounds() -> void:
	var state := GameState.new()
	var db_holder := ConfigDB.new()
	db_holder.variable_config = {"result_text_play_rate": 0.0, "result_text_auto_play_rate": 5000.0}
	state._fallback_db = db_holder
	assert_eq(state.source_result_text_rate(false), 0.5, "below the low bound clamps up to 0.5")
	assert_eq(state.source_result_text_rate(true), 100.0, "above the high bound clamps down to 100")


func test_rate_without_config_falls_back_to_one() -> void:
	var state := GameState.new()
	var db_holder := ConfigDB.new()
	db_holder.variable_config = {}
	state._fallback_db = db_holder
	assert_eq(state.source_result_text_rate(false), 1.0, "a missing config keeps the identity rate")


func test_play_rate_button_uses_the_config_rates() -> void:
	var state := GameState.new()
	var view = preload("res://ui/rite_view.gd").new()
	add_child_autofree(view)
	view.setup(state, db, RNG.new(3), 5000001)
	view._refresh_play_rate()
	assert_eq(float(view._result_play_rate), 1.0, "a fresh result surface plays at the manual rate")
	assert_eq(float(view._play_rate_button.get_meta("source_play_rate")), 1.0)
	view._toggle_result_auto_play()
	assert_eq(float(view._result_play_rate), 15.0, "auto play switches to result_text_auto_play_rate")
	assert_eq(float(view._play_rate_button.get_meta("source_play_rate")), 15.0)
	view._toggle_result_auto_play()
	assert_eq(float(view._result_play_rate), 1.0, "turning auto play off returns to the manual rate")
