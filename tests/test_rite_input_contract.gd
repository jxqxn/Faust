extends GutTest

const RiteView = preload("res://ui/rite_view.gd")
var db: ConfigDB

func after_each():
	await wait_process_frames(2)

func before_all():
	db = ConfigDB.new()
	db.load_all()

func make_view(id: int = 5000001):
	var state := GameState.new()
	var rng := GameRNG.new(123)
	state.setup_new_run(db, 1, rng)
	var view := RiteView.new()
	view.setup(state, db, rng, id)
	add_child_autofree(view)
	return view

func payload(uid: int) -> Dictionary:
	return {"type": "card", "source": "hand", "card_uid": uid}

func test_desktop_rebuild_preserves_preparing_and_running_rites():
	# [SRC: Start b__5 0x56f9c0 skips new-round work on load;
	# OnNextRound metadata 0x2599300 owns DoStartAutoBeginRite.]
	var main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(201))
	state.add_available_rite(5000001, db)
	main.state = state
	main.call("_show_game")
	main.call("_on_open_rite", 5000001)
	var household = state.get_rite_instance(main._rite_overlay._rite_uid)
	assert_false(household.start, "auto_begin does not mean start while showing desktop")
	main.call("_close_rite_overlay")
	main.call("_show_game")
	assert_false(household.start, "reopening/loading cannot lock preparing slots")
	state.start_rite_instance(household.uid)
	var start_round: int = household.start_round
	main.call("_show_game")
	assert_true(household.start, "rebuilding cannot unlock a genuinely running rite")
	assert_eq(household.start_round, start_round)

func test_panel_drop_prioritizes_empty_then_replaces_occupied_and_rejects_running():
	# CardDropManager.DropCard 0x4ef4f0, original household s1/s2 config.
	var view = make_view()
	var state: GameState = view._state
	var first := state.add_card_to_hand(2000001, db)
	var second := state.add_card_to_hand(2000001, db)
	var third := state.add_card_to_hand(2000001, db)
	assert_eq(view.panel_drop_slot(payload(first)), "s1")
	view.drop_card_on_slot("s1", payload(first))
	assert_eq(view.panel_drop_slot(payload(second)), "s2", "empty s2 wins over occupied matching s1")
	view.drop_card_on_slot("s2", payload(second))
	assert_eq(view.panel_drop_slot(payload(third)), "s1", "occupied pass runs only after empty candidates")
	view.drop_card_on_slot("s1", payload(third))
	assert_true(state.has_card_in_hand(first), "replacement returns previous UID")
	assert_false(state.has_card_in_hand(third))
	assert_eq(int(view._placed.s1), third)
	state.get_rite_instance(view._rite_uid).start = true
	assert_eq(view.panel_drop_slot(payload(first)), "")
	view.return_card_to_hand(third, "s1")
	assert_eq(int(view._placed.s1), third)

func test_cost_slot_highlights_partial_deposit_and_panel_uses_same_candidate():
	# ShowSatisfiedSlot accepts ctx.is_cost even when 1 coin cannot meet 3.
	var view = make_view(5000005)
	var state: GameState = view._state
	var uid := state.add_card_to_hand(2000029, db)
	state.get_card_instance(uid).count = 1
	view.show_satisfied_slots(uid)
	assert_eq(view._slot_buttons.s2.get_node("SourceSatisfiedOutline").get_meta("clip"), "show")
	assert_eq(view._slot_buttons.s1.get_node("SourceSatisfiedOutline").get_meta("clip", "hide"), "hide")
	assert_eq(view.panel_drop_slot(payload(uid)), "s2")
	view.drop_card_on_slot("s2", payload(uid))
	assert_eq(state.get_card_instance(uid).count, 1, "partial deposit cannot invent coins")
	assert_eq(int(view._placed.s2), uid)

func test_satisfied_outlines_are_separate_from_hover_and_clear_on_drag_end():
	var view = make_view()
	var state: GameState = view._state
	var uid := state.add_card_to_hand(2000001, db)
	view.show_satisfied_slots(uid)
	var s1: Button = view._slot_buttons.s1
	var outline: TextureRect = s1.get_node("SourceSatisfiedOutline")
	assert_false(s1.get_node("SourceHighlight").visible, "drag does not fake pointer enter")
	assert_eq(outline.get_meta("clip"), "show")
	assert_eq(view._slot_buttons.s2.get_node("SourceSatisfiedOutline").get_meta("clip"), "show")
	assert_eq(view._slot_buttons.s3.get_node("SourceSatisfiedOutline").get_meta("clip", "hide"), "hide", "auto-adsorb never offers manual drop")
	await wait_seconds(0.4)
	assert_almost_eq(outline.modulate.a, 1.0, 0.001)
	view.show_satisfied_slots(0)
	await wait_seconds(0.4)
	assert_almost_eq(outline.modulate.a, 0.0, 0.001)
	var material: ShaderMaterial = s1.get_node("SourceHighlight").material
	assert_not_null(material)
	assert_eq(material.get_shader_parameter("outline_color"), Color(0.94639033, 0.8695029, 0.6157619, 1))
	assert_eq(material.get_shader_parameter("outline_fade"), 1.0)

func test_occupied_slot_button_no_longer_removes_card_on_ordinary_click():
	var view = make_view()
	var state: GameState = view._state
	var uid := state.add_card_to_hand(2000001, db)
	view.drop_card_on_slot("s1", payload(uid))
	view._on_slot_pressed("s1")
	assert_eq(int(view._placed.s1), uid)
	assert_false(state.has_card_in_hand(uid))
	var widget: CardWidget = view._slot_buttons.s1.get_node("Container/PlacedCard_S1")
	widget.quick_action_requested.emit(uid)
	assert_true(state.has_card_in_hand(uid), "separate right-click action returns card")
	assert_false(view._placed.has("s1"))


func begin_slot_drag(view, uid: int) -> Dictionary:
	var widget = view._slot_buttons.s1.get_node("Container/PlacedCard_S1")
	var data := {"type": "card", "source": "slot", "card_uid": uid,
		"source_slot": "s1", "source_rite_uid": view._rite_uid}
	view._begin_slot_drag(data, widget)
	return {"data": data, "widget": widget}


func test_slot_drag_detaches_before_release_and_invalid_drop_returns_to_hand():
	# [SRC: CardController.OnBeginDrag 0x5294e0 / OnEndDrag 0x52a570;
	# dump.cs ICardSlot slot 3 = RemoveCard.]
	var view = make_view()
	var state: GameState = view._state
	var uid := state.add_card_to_hand(2000001, db)
	view.drop_card_on_slot("s1", payload(uid))
	var drag := begin_slot_drag(view, uid)
	assert_false(view._placed.has("s1"))
	assert_false(state.get_rite_instance(view._rite_uid).slot_cards.has("s1"))
	assert_false(state.has_card_in_hand(uid))
	assert_eq(state.get_card_instance(uid).zone, "drag")
	view._finish_slot_drag(drag.data, false, drag.widget)
	assert_true(state.has_card_in_hand(uid))
	assert_false(view._placed.has("s1"))


func test_slot_drag_to_another_slot_preserves_destination_after_end():
	var view = make_view()
	var state: GameState = view._state
	var uid := state.add_card_to_hand(2000001, db)
	view.drop_card_on_slot("s1", payload(uid))
	var drag := begin_slot_drag(view, uid)
	view.drop_card_on_slot("s2", drag.data)
	view._finish_slot_drag(drag.data, true, drag.widget)
	assert_false(view._placed.has("s1"))
	assert_eq(int(view._placed.get("s2", 0)), uid)
	assert_eq(state.get_card_instance(uid).zone, "slot")
	assert_false(state.has_card_in_hand(uid))


func test_closing_panel_during_drag_returns_card_without_orphaning_uid():
	var view = make_view()
	var state: GameState = view._state
	var uid := state.add_card_to_hand(2000001, db)
	view.drop_card_on_slot("s1", payload(uid))
	begin_slot_drag(view, uid)
	view.get_parent().remove_child(view)
	assert_true(state.has_card_in_hand(uid))
	assert_eq(state.get_card_instance(uid).zone, "hand")
	assert_false(state.get_rite_instance(view._rite_uid).slot_cards.has("s1"))


func test_running_rite_cannot_detach_slot_card():
	var view = make_view()
	var state: GameState = view._state
	var uid := state.add_card_to_hand(2000001, db)
	view.drop_card_on_slot("s1", payload(uid))
	state.get_rite_instance(view._rite_uid).start = true
	var drag := begin_slot_drag(view, uid)
	assert_false(drag.data.has("detached_from_slot"))
	assert_eq(state.get_card_instance(uid).zone, "slot")
	assert_eq(int(view._placed.s1), uid)


func test_detached_equipment_remains_eligible_for_hand_host():
	# CardEquip / CanEquip have no hand-only source gate; OnBeginDrag
	# removes CardSlot before the drop manager dispatches to the host.
	var view = make_view()
	var state: GameState = view._state
	var host := state.add_card_to_hand(2001193, db)
	var equipment := state.add_card_to_hand(2000246, db)
	# Seed a slot directly: this tests drag ownership, not household filtering.
	state.remove_card_from_hand(equipment)
	state.add_card_to_slot(equipment, 1, db, view._rite_uid)
	view._load_placements_from_instance()
	view._after_placement_changed()
	var drag := begin_slot_drag(view, equipment)
	var screen = preload("res://ui/game_screen.gd").new()
	screen._state = state
	screen._db = db
	assert_true(screen._can_drop_equipment(host, drag.data))
	assert_eq(state.attach_equipment(host, equipment, db, true, true), 0)
	view._finish_slot_drag(drag.data, true, drag.widget)
	assert_eq(state.get_card_instance(equipment).zone, "equipped")
	assert_false(state.has_card_in_hand(equipment))
	assert_false(view._placed.has("s1"))
	screen.free()


func test_detached_stack_merges_once_without_returning_consumed_uid():
	var view = make_view()
	var state: GameState = view._state
	var target := state.add_card_to_hand(2000029, db)
	var source := state.add_card_to_hand(2000029, db)
	state.get_card_instance(target).count = 3
	state.get_card_instance(source).count = 2
	state.remove_card_from_hand(source)
	state.add_card_to_slot(source, 1, db, view._rite_uid)
	view._load_placements_from_instance()
	view._after_placement_changed()
	var drag := begin_slot_drag(view, source)
	var screen = preload("res://ui/game_screen.gd").new()
	screen._state = state
	screen._db = db
	assert_true(screen._can_drop_stack(target, drag.data))
	assert_true(state.stack_cards(target, source))
	view._finish_slot_drag(drag.data, true, drag.widget)
	assert_eq(state.get_card_instance(target).count, 5)
	assert_false(state.has_card_in_hand(source))
	assert_false(view._placed.has("s1"))
	screen.free()
