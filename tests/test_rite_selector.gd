extends GutTest

const RiteSelector = preload("res://ui/rite_selector.gd")
const UiMotionScript = preload("res://ui/ui_motion.gd")


func _owned(node: Node) -> Node:
	autofree(node)
	return node


func after_each():
	UiMotionScript.reduced_motion = false


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


func test_overlay_panel_is_a_compact_site_menu_inside_its_safe_area():
	var db := ConfigDB.new()
	db.rites = {}
	for rite_id in range(9005, 9009):
		var rite := _rite_with_location("Home")
		rite["id"] = rite_id
		rite["name"] = "Home action %d" % rite_id
		db.rites[rite_id] = rite
	var cases := [
		{
			"size": Vector2(1280, 720),
			"safe_rect": Rect2(34, 78, 1212, 404),
			"anchor": Vector2(180, 310),
			"columns": 2,
		},
		{
			"size": Vector2(720, 720),
			"safe_rect": Rect2(20, 72, 680, 360),
			"anchor": Vector2(570, 270),
			"columns": 2,
		},
		{
			"size": Vector2(440, 640),
			"safe_rect": Rect2(18, 54, 404, 280),
			"anchor": Vector2(100, 230),
			"columns": 1,
		},
	]
	for test_case in cases:
		var stage := Control.new()
		add_child_autofree(stage)
		stage.size = test_case["size"]
		var selector := RiteSelector.new()
		selector.setup(db, null, null, "Home")
		selector.set_overlay_mode(true)
		selector.set_overlay_anchor(test_case["anchor"])
		selector.set_overlay_safe_rect(test_case["safe_rect"])
		stage.add_child(selector)
		selector.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await wait_process_frames(2)

		var panel := _find_node_by_name(selector, "RiteSelectorPanel") as Control
		var grid := _find_first_grid(selector)
		assert_not_null(panel)
		assert_null(
			_find_node_by_name(selector, "RiteSelectorConnector"),
			"a nearby menu should not need a decorative tether line"
		)
		assert_not_null(grid)
		if panel != null:
			var safe_rect: Rect2 = test_case["safe_rect"]
			var panel_rect := Rect2(panel.position, panel.size)
			assert_true(safe_rect.encloses(panel_rect), "menu must stay inside the map work area")
			if panel.size.x < safe_rect.size.x:
				assert_false(panel_rect.has_point(test_case["anchor"]), "menu must not cover its source site")
			assert_lte(panel.size.x, RiteSelector.CONTEXT_MENU_MAX_WIDTH)
			assert_lte(panel.size.y, RiteSelector.CONTEXT_MENU_MAX_HEIGHT)
		if grid != null:
			assert_eq(grid.columns, test_case["columns"])

		selector.queue_free()
		await wait_process_frames(1)


func test_compact_site_menu_closes_from_backdrop_or_escape_without_return_button():
	UiMotionScript.reduced_motion = true
	var db := ConfigDB.new()
	db.rites = {9005: _rite_with_location("Home")}
	for close_kind in ["backdrop", "escape"]:
		var stage := Control.new()
		add_child_autofree(stage)
		stage.size = Vector2(960, 640)
		var selector := RiteSelector.new()
		selector.setup(db, null, null, "Home")
		selector.set_overlay_mode(true)
		selector.set_overlay_anchor(Vector2(210, 190))
		selector.set_overlay_safe_rect(Rect2(24, 48, 912, 320))
		var close_count := [0]
		selector.closed.connect(func(): close_count[0] += 1)
		stage.add_child(selector)
		selector.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await wait_process_frames(2)

		assert_null(
			_find_node_by_name(selector, "CloseRiteSelectorButton"),
			"the map remains visible, so a return button would be redundant"
		)
		if close_kind == "backdrop":
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			selector._on_backdrop_input(click)
		else:
			var escape := InputEventKey.new()
			escape.keycode = KEY_ESCAPE
			escape.pressed = true
			selector._unhandled_key_input(escape)
		assert_eq(close_count[0], 1, "%s should emit the shared close signal once" % close_kind)

		selector.queue_free()
		await wait_process_frames(1)


func _count_buttons(node: Node) -> int:
	var count := 0
	if node is Button:
		count += 1
	for child in node.get_children():
		count += _count_buttons(child)
	return count


func _find_node_by_name(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _find_first_grid(node: Node) -> GridContainer:
	if node is GridContainer:
		return node
	for child in node.get_children():
		var found := _find_first_grid(child)
		if found != null:
			return found
	return null


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
