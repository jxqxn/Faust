extends GutTest

var db: ConfigDB

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func _widget() -> CardWidget:
	var widget := CardWidget.make(db.get_card(2000029))
	add_child_autofree(widget)
	widget.set_process(false)
	return widget

func _fade(widget: CardWidget) -> float:
	return float(widget._flash_material.get_shader_parameter("outline_fade"))

func test_flash_replays_source_curve_and_returns_to_zero() -> void:
	# Independent authored curve checkpoints: speed3 reaches t=.5 at 1/6s,
	# key tangents2/0 give fade.75, peak1 at1/3s, then mirror down to zero.
	var widget := _widget()
	widget.reset_card_flash(true)
	assert_eq(_fade(widget), 0.0)
	widget._advance_card_flash(1.0 / 6.0)
	assert_almost_eq(_fade(widget), 0.75, 0.0001)
	widget._advance_card_flash(1.0 / 6.0)
	assert_eq(_fade(widget), 1.0)
	assert_false(widget._flash_rising)
	widget._advance_card_flash(1.0 / 6.0)
	assert_almost_eq(_fade(widget), 0.75, 0.0001)
	widget._advance_card_flash(1.0 / 6.0)
	assert_eq(_fade(widget), 0.0)
	widget._advance_card_flash(1.0)
	assert_eq(_fade(widget), 0.0, "flash does not loop")

func test_retrigger_resets_and_nonmatch_cancels_previous_flash() -> void:
	var widget := _widget()
	widget.reset_card_flash(true)
	widget._advance_card_flash(0.2)
	widget.reset_card_flash(true)
	assert_eq(_fade(widget), 0.0)
	assert_true(widget._flash_rising)
	widget._advance_card_flash(0.2)
	widget.reset_card_flash(false)
	widget._advance_card_flash(0.2)
	assert_eq(_fade(widget), 0.0)
	assert_false(widget._flash_rising)

func test_candidates_flash_but_only_first_candidate_is_selected() -> void:
	var state := GameState.new()
	var rng := GameRNG.new(920)
	state.setup_new_run(db, 1, rng)
	state.add_card_to_hand(2000001, db)
	state.add_card_to_hand(2000006, db)
	state.add_card_to_hand(2000029, db)
	var screen = preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	add_child_autofree(screen)
	await wait_process_frames(2)
	for child in screen._card_items.get_children():
		if child is CardWidget:
			child.set_process(false)
	screen.focus_qualified_hand(func(card: Dictionary): return str(card.get("type")) == "char")
	var selected := 0
	var flashing := 0
	for child in screen._card_items.get_children():
		if child is CardWidget:
			selected += int(child._selected)
			flashing += int(child._flash_rising)
			assert_eq(child._flash_rising, str(child._card.get("type")) == "char")
			assert_eq(child._candidate_scale, 1.1 if str(child._card.get("type")) == "char" else 1.0)
			var bottom: float = child.position.y + child.card_size().y * (1.0 + child.hand_layout_scale()) * 0.5
			assert_almost_eq(bottom, maxf(screen._card_items.size.y, child.card_size().y), 0.01, "candidate layout keeps the scaled bottom on the rail")
	assert_eq(selected, 1, "select_first must not select every matching card")
	assert_gte(flashing, 2, "all matching candidates flash")
	screen.clear_hand_candidate_highlights()
	for child in screen._card_items.get_children():
		if child is CardWidget:
			assert_eq(child._candidate_scale, 1.0, "closing rite restores candidate size")
			assert_false(child._selected, "closing rite clears candidate selection")
	screen.focus_qualified_hand(func(card: Dictionary): return str(card.get("type")) == "char")
	screen.focus_qualified_hand(func(_card: Dictionary): return false)
	for child in screen._card_items.get_children():
		if child is CardWidget:
			assert_eq(child._candidate_scale, 1.0, "next nonmatching filter restores size")
