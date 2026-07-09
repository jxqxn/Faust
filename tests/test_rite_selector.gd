extends GutTest

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


func test_selector_filters_open_rites_by_location():
	var db := ConfigDB.new()
	db.rites = {
		9005: _rite_with_location("Home"),
		9006: _rite_with_location("Market"),
	}
	var selector := RiteSelector.new()
	selector.setup(db, null, null, "Home")

	assert_eq(selector.open_rite_ids(), [9005])


func test_auto_begin_rite_is_available_only_after_it_is_started():
	var db := ConfigDB.new()
	db.rites = {
		9007: _rite_with_location("Home", 1),
	}
	var state := GameState.new()
	state.available_rites.append(9007)
	var selector := RiteSelector.new()
	selector.setup(db, state, null, "Home")

	assert_eq(selector.open_rite_ids(), [], "auto-begin rites should not appear just because the config exists")

	state.started_rites.append(9007)
	assert_eq(selector.open_rite_ids(), [9007], "started auto-begin rites should be enterable at their location")


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


func _rite_with_location(location: String, auto_begin: int = 0) -> Dictionary:
	var id := 9005 if location == "Home" else 9006
	if auto_begin == 1:
		id = 9007
	return {
		"id": id,
		"name": "Located rite",
		"text": "",
		"location": "%s:1" % location,
		"auto_begin": auto_begin,
		"cards_slot": {"s1": {}},
		"settlement": [{"condition": {}, "result": {}}],
		"open_conditions": [],
	}
