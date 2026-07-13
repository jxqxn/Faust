extends GutTest

const RiteSelector = preload("res://ui/rite_selector.gd")


func _owned(node: Node) -> Node:
	autofree(node)
	return node


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
	var selector := _owned(RiteSelector.new()) as RiteSelector
	selector.setup(db)
	selector._list_container = _owned(VBoxContainer.new()) as VBoxContainer

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
	var selector := _owned(RiteSelector.new()) as RiteSelector
	selector.setup(db, state)
	selector._list_container = _owned(VBoxContainer.new()) as VBoxContainer

	selector._populate()

	assert_eq(_count_buttons(selector._list_container), 0)


func test_selector_keeps_distinct_runtime_instances_of_one_rite():
	var db := ConfigDB.new()
	db.rites = {
		9010: {
			"id": 9010,
			"name": "Repeatable",
			"text": "",
			"location": "Test",
			"auto_begin": 0,
			"cards_slot": {"s1": {}},
			"settlement": [{"condition": {}, "result": {}}],
			"open_conditions": [],
		},
	}
	var state := GameState.new()
	var first = state.create_rite_instance(9010)
	var second = state.create_rite_instance(9010)
	var uids := RiteSelector.filter_open_rite_instance_uids(db, state, null, "Test")
	assert_eq(uids, [first.uid, second.uid], "selector preserves distinct rite instances with one config id")


func test_selector_requires_all_open_conditions_current_assumption():
	var db := ConfigDB.new()
	db.rites = {
		9003: _rite_with_open_conditions([
			{"condition": {}},
			{"condition": {"counter.7000001=": 1}},
		]),
	}
	var state := GameState.new()
	var selector := _owned(RiteSelector.new()) as RiteSelector
	selector.setup(db, state)
	selector._list_container = _owned(VBoxContainer.new()) as VBoxContainer

	selector._populate()

	assert_eq(_count_buttons(selector._list_container), 0)


func test_selector_fails_closed_without_state_for_non_empty_condition():
	var db := ConfigDB.new()
	db.rites = {
		9004: _rite_with_open_conditions([
			{"condition": {"counter.7000001=": 0}},
		]),
	}
	var selector := _owned(RiteSelector.new()) as RiteSelector
	selector.setup(db)
	selector._list_container = _owned(VBoxContainer.new()) as VBoxContainer

	selector._populate()

	assert_eq(_count_buttons(selector._list_container), 0)


func test_selector_filters_open_rites_by_location():
	var db := ConfigDB.new()
	db.rites = {
		9005: _rite_with_location("Home"),
		9006: _rite_with_location("Market"),
	}
	var selector := _owned(RiteSelector.new()) as RiteSelector
	selector.setup(db, null, null, "Home")

	assert_eq(selector.open_rite_ids(), [9005])


func test_auto_begin_rite_is_available_only_after_it_is_started():
	var db := ConfigDB.new()
	db.rites = {
		9007: _rite_with_location("Home", 1),
	}
	var state := GameState.new()
	state.available_rites.append(9007)
	var selector := _owned(RiteSelector.new()) as RiteSelector
	selector.setup(db, state, null, "Home")

	assert_eq(selector.open_rite_ids(), [], "auto-begin rites should not appear just because the config exists")

	state.started_rites.append(9007)
	assert_eq(selector.open_rite_ids(), [9007], "started auto-begin rites should be enterable at their location")


func test_rite_with_only_prior_settlement_is_interactive():
	# A rite whose only settlement branch is in settlement_prior (no `settlement`
	# entries) must still count as interactive. Previously the selector counted
	# only `settlement`, hiding such rites while the map showed them.
	var db := ConfigDB.new()
	db.rites = {
		9008: {
			"id": 9008,
			"name": "Prior-only rite",
			"text": "",
			"location": "Home:1",
			"auto_begin": 0,
			"cards_slot": {"s1": {}},
			"settlement_prior": [{"condition": {}, "result": {}}],
			"settlement": [],
			"settlement_extre": [],
			"open_conditions": [],
		},
	}
	var state := GameState.new()
	state.available_rites.append(9008)
	var selector := _owned(RiteSelector.new()) as RiteSelector
	selector.setup(db, state, null, "Home")
	assert_eq(selector.open_rite_ids(), [9008], "prior-only rite should appear in the selector")
	# The shared predicate is the single source of truth now.
	assert_true(RiteOpen.is_interactive(db.rites[9008]), "is_interactive treats prior as interactive")


func test_static_filter_counts_open_rites_without_instantiating():
	# filter_open_rite_ids lets callers count open rites without creating a
	# RiteSelector node (which would leak). It must agree with open_rite_ids().
	var db := ConfigDB.new()
	db.rites = {
		9005: _rite_with_location("Home"),
		9006: _rite_with_location("Market"),
	}
	var state := GameState.new()
	var selector := _owned(RiteSelector.new()) as RiteSelector
	selector.setup(db, state, null, "Home")
	assert_eq(RiteSelector.filter_open_rite_ids(db, state, null, "Home"), selector.open_rite_ids(), "static filter matches instance filter")


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
