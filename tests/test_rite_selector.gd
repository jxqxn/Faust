extends GutTest

const ConfigDB = preload("res://data/db.gd")
const GameState = preload("res://sim/game_state.gd")
const RiteSelector = preload("res://ui/rite_selector.gd")


func test_selector_shows_rite_when_open_conditions_are_satisfied():
	var db := ConfigDB.new()
	db.rites = {
		9001: {
			"id": 9001,
			"name": "Open gated rite",
			"text": "",
			"location": "Test",
			"auto_begin": 0,
			"cards_slot": {"s1": {}},
			"settlement": [{"condition": {}, "result": {}}],
			"open_conditions": [{"condition": {}}],
		},
	}
	var selector := RiteSelector.new()
	selector.setup(db)
	selector._list_container = VBoxContainer.new()

	selector._populate()

	assert_eq(_count_buttons(selector._list_container), 1)


func test_selector_hides_rite_when_open_condition_is_unsatisfied():
	var db := ConfigDB.new()
	db.rites = {
		9002: _rite_with_open_conditions([
			{"condition": {"counter.7000001=": 1}},
		]),
	}
	var state := GameState.new()
	var selector := RiteSelector.new()
	selector.setup(db, state)
	selector._list_container = VBoxContainer.new()

	selector._populate()

	assert_eq(_count_buttons(selector._list_container), 0)


func test_selector_requires_all_open_conditions_current_assumption():
	var db := ConfigDB.new()
	db.rites = {
		9003: _rite_with_open_conditions([
			{"condition": {}},
			{"condition": {"counter.7000001=": 1}},
		]),
	}
	var state := GameState.new()
	var selector := RiteSelector.new()
	selector.setup(db, state)
	selector._list_container = VBoxContainer.new()

	selector._populate()

	assert_eq(_count_buttons(selector._list_container), 0)


func test_selector_fails_closed_without_state_for_non_empty_condition():
	var db := ConfigDB.new()
	db.rites = {
		9004: _rite_with_open_conditions([
			{"condition": {"counter.7000001=": 0}},
		]),
	}
	var selector := RiteSelector.new()
	selector.setup(db)
	selector._list_container = VBoxContainer.new()

	selector._populate()

	assert_eq(_count_buttons(selector._list_container), 0)


func _count_buttons(node: Node) -> int:
	var count := 0
	if node is Button:
		count += 1
	for child in node.get_children():
		count += _count_buttons(child)
	return count


func _rite_with_open_conditions(open_conditions: Array) -> Dictionary:
	return {
		"id": 9000,
		"name": "Gated rite",
		"text": "",
		"location": "Test",
		"auto_begin": 0,
		"cards_slot": {"s1": {}},
		"settlement": [{"condition": {}, "result": {}}],
		"open_conditions": open_conditions,
	}
