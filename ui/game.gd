extends Control

## Top-level game controller. Manages menu -> game -> rite flow, owns the
## GameState/ConfigDB/RNG, and wires signals between screens.
const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
const GameRNG = preload("res://core/rng.gd")
const RoundLoop = preload("res://sim/round_loop.gd")
const MainMenu = preload("res://ui/main_menu.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const RiteView = preload("res://ui/rite_view.gd")

var db: ConfigDB
var state: GameState
var rng: GameRNG
var _current: Control

func _ready() -> void:
	db = ConfigDB.new()
	db.load_all()
	rng = GameRNG.new()
	_show_menu()

func _show_menu() -> void:
	_clear_current()
	var menu := MainMenu.new()
	menu.difficulty_selected.connect(_on_difficulty_selected)
	add_child(menu)
	_current = menu

func _on_difficulty_selected(index: int) -> void:
	state = GameState.new()
	state.setup_new_run(db, index, rng)
	# Draw the first weekly sudan card to start.
	RoundLoop.draw_weekly_sudan(state, db, rng)
	_show_game()

func _show_game() -> void:
	_clear_current()
	var gs := GameScreen.new()
	gs.setup(state, db, rng)
	gs.open_rite.connect(_on_open_rite)
	gs.advance_pressed.connect(_on_advance)
	add_child(gs)
	_current = gs
	gs.refresh()

func _on_open_rite(rite_id: int) -> void:
	_clear_current()
	var rv := RiteView.new()
	rv.setup(state, db, rng, rite_id)
	rv.closed.connect(_show_game)
	add_child(rv)
	_current = rv

func _on_advance() -> void:
	var result := RoundLoop.advance_day(state, db, rng)
	var log_text := "第 %d 天。" % state.day
	if result.game_over:
		log_text += "\n⚠ 一张苏丹卡到期未完成！游戏结束。"
	if not result.expired.is_empty():
		for cid in result.expired:
			var dec = preload("res://sim/sudan_cards.gd").decode(int(cid))
			log_text += "\n过期: %s%s" % [dec.rank, dec.action]
	for ar in result.auto_rites:
		var rr = ar.result
		if not rr.normal_entry.is_empty():
			log_text += "\n治理家业: %s" % str(rr.normal_entry.get("result_text", ""))
	if _current and _current.has_method("set_log"):
		_current.set_log(log_text)
		_current.refresh()

func _clear_current() -> void:
	if _current:
		_current.queue_free()
		_current = null
