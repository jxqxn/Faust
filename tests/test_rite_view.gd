extends GutTest

const RNG = preload("res://core/rng.gd")
const RiteView = preload("res://ui/rite_view.gd")

var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()


func test_rite_view_keeps_protagonist_as_actor_while_other_cards_are_participants() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(700))
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, RNG.new(701), 5000001)
	add_child(view)
	await wait_process_frames(2)
	# Actor identity is runtime context, not clone-only prose in the original
	# RitePanelShow prefab. Keep it in the resolver payload and do not restore
	# the removed RiteActorLabel/RitePerspectiveHint presentation nodes.
	var actor := state.player_actor_data(db)
	var context := state.with_player_actor_context({"rite_id": 5000001}, db)
	assert_eq(actor.get("name", ""), "阿尔图")
	assert_eq(int(context.get("player_actor_uid", 0)), state.player_actor_uid)
	assert_eq(int(context.get("player_actor_id", 0)), 2000001)
	assert_null(view.find_child("RiteActorLabel", true, false))
	assert_null(view.find_child("RitePerspectiveHint", true, false))
	view.queue_free()


func test_power_game_real_source_config_opens_and_confirms_without_nil_chain() -> void:
	var state := GameState.new()
	state.setup_new_run(db, 0, RNG.new(9101))
	var event := db.get_event(5300089)
	assert_false(event.is_empty(), "source power-game event is loaded")
	DeferredEffects.execute_event(event, state, db, RNG.new(9101))
	var instance = state.find_rite_instance_by_id(5001001)
	assert_not_null(instance, "source event creates the power-game rite")
	if instance == null:
		return
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, RNG.new(9101), 5001001, instance.uid)
	add_child(view)
	await wait_process_frames(3)
	assert_eq(view._rite_uid, instance.uid, "panel binds the generated rite instance")
	assert_eq(view._slot_buttons.size(), 7, "source power-game panel builds all seven slots")
	view._resolve()
	await wait_process_frames(3)
	RiteSettlement.pump_confirmations(state)
	assert_true(instance.start, "confirming the source rite starts the one-day instance")


func test_result_dice_prompt_reads_repeated_source_conditions() -> void:
	var view := _owned(RiteView.new()) as RiteView
	var result := {
		"normal_entry": {
			"condition": [
				{"r1:智慧>=": [1, 5]},
				{"r1:智慧>=": [1, 4]},
			]
		},
		"dice_rolls": [5, 4, 3],
	}
	assert_eq(view._successes_for_result(result), 1, "result prompt reads the first repeated r1 threshold")


func _owned(node: Node) -> Node:
	autofree(node)
	return node

func test_gold_dice_reresolve_does_not_apply_results_twice():
	var rng := RNG.new(1)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.gold_dice = 2
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"settlement": [
			{"condition": {}, "result": {"coin": 5}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._gold_dice_label = _owned(Label.new()) as Label
	view._gold_dice_btn = _owned(Button.new()) as Button
	view._result_label = _owned(RichTextLabel.new()) as RichTextLabel

	view._resolve()
	assert_eq(state.coin_count, 0, "selection does not execute finalResults")
	assert_eq(state.gold_dice, 2, "first resolve does not spend gold dice")

	view._use_gold_dice_reactive()
	assert_eq(state.coin_count, 0, "gold-dice retry only repeats selection")
	assert_eq(state.gold_dice, 1, "one gold die spent")

	view._use_gold_dice_reactive()
	assert_eq(state.coin_count, 0, "second retry still has no world reward")
	assert_eq(state.gold_dice, 0, "second gold die spent")
	view._commit_resolution()
	assert_eq(state.coin_count, 5, "finalResults execute once after accepting the decision")

func test_gold_dice_reresolve_reuses_cached_dice():
	var rng := RNG.new(77)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.gold_dice = 2
	state.add_card_to_hand(2000005)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"settlement": [
			{"condition": {"r1:智慧>=": [99, 5]}, "result": {"coin": 5}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._placed = {"s1": 2000005}
	view._gold_dice_label = _owned(Label.new()) as Label
	view._gold_dice_btn = _owned(Button.new()) as Button
	view._result_label = _owned(RichTextLabel.new()) as RichTextLabel

	view._resolve()
	var after_first := rng.get_state()
	view._use_gold_dice_reactive()
	assert_eq(rng.get_state(), after_first, "gold-dice retry reuses the first resolve's dice cache")


func test_result_surface_replays_dice_prompt_and_gold_count_prompt():
	var rng := RNG.new(771)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"id": 5000001,
		"cards_slot": {"s1": {"condition": {"type": "char"}}},
		"settlement": [{"condition": {"r1:体魄>=": [1, 5]}, "result": {"coin": 1}}],
		"settlement_prior": [], "settlement_extre": [],
	}
	add_child(view)
	await wait_process_frames(2)
	var card_uid := int(state.hand[0])
	view._place_card_in_slot("s1", card_uid, "hand", "")
	view._resolve()
	var dice_prompt := view.find_child("DicePromptNew", true, false) as Control
	var count_prompt := view.find_child("DiceCountPromptNew", true, false) as Control
	assert_not_null(dice_prompt, "resolved rite exposes DicePromptNew")
	assert_false(dice_prompt.visible, "the eager resolver has finished rolling before the count decision")
	assert_not_null(count_prompt, "resolved rite exposes DiceCountPromptNew")
	view._show_dice_count_prompt("gold")
	assert_true(count_prompt.visible, "gold dice action opens the source count prompt")
	view._confirm_dice_count_prompt()
	assert_true(count_prompt.visible, "re-resolve exposes the new count decision")
	assert_eq(view._gold_selected, 0, "confirmation clears the tentative selection")

func test_result_surface_replays_source_play_rate_button():
	var rng := RNG.new(772)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	add_child(view)
	await wait_process_frames(2)
	var button := view.find_child("PlayRate", true, false) as Button
	assert_not_null(button, "result surface exposes source PlayRate")
	assert_eq(button.position, Vector2(3067, 1441), "PlayRate keeps authored local position")
	assert_eq(button.size, Vector2(104, 104), "PlayRate keeps authored size")
	assert_false(button.visible, "PlayRate is hidden before settlement")
	# The source has two rates, both from variable.json, selected by the
	# auto-play flag — there is no x1/x2 cycle.
	# [SRC: RiteResultPanelController.c @ UpdateResultTextSpeed 0x5a74a0]
	var rates: Dictionary = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/variable.json"))
	var manual_rate := float(rates.get("result_text_play_rate", 1))
	var auto_rate := float(rates.get("result_text_auto_play_rate", 15))
	view._toggle_play_rate()
	assert_eq(view._result_play_rate, auto_rate, "PlayRate switches to the auto-play rate")
	assert_eq(button.get_node("Art").texture.resource_path, "res://assets/original/ui/play_speed_x2.png")
	view._toggle_play_rate()
	assert_eq(view._result_play_rate, manual_rate, "PlayRate switches back to the manual rate")
	var auto_button := view.find_child("AutoPlay", true, false) as Button
	assert_not_null(auto_button, "result surface exposes source AutoPlay")
	assert_eq(auto_button.position, Vector2(2668, 1445), "AutoPlay keeps source parent-relative geometry")
	assert_eq(auto_button.size, Vector2(240, 88), "AutoPlay keeps source size")
	assert_false(auto_button.visible, "AutoPlay is hidden before settlement")
	view._rite["auto_result"] = 0
	view._toggle_result_auto_play()
	assert_true(state.rite_auto_result, "AutoPlay writes Player+0x160, independent of per-rite automation")
	assert_false(state.auto_result_rites.has(5000001))
	assert_eq(auto_button.get_node("Art").texture.resource_path, "res://assets/original/ui/auto_play_active.png")

func test_result_text_uses_source_typewriter_and_next_skips_before_commit():
	var rng := RNG.new(773)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._rite = {"id": 5000001, "round_number": 0,
		"settlement": [{"condition": {}, "result": {}, "result_title": "标题", "result_text": "这是结算正文"}],
		"settlement_prior": [], "settlement_extre": []}
	add_child(view)
	await wait_process_frames(2)
	view._resolve()
	var text := view._result_surface_text
	assert_not_null(text, "result text exists")
	assert_false(view._result_text_done, "source result text starts in typewriter state")
	assert_eq(text.visible_characters, 0, "source result text starts with zero visible characters")
	view._on_result_next()
	assert_true(view._result_text_done, "first next press completes the source text")
	assert_eq(text.visible_characters, -1, "first next press reveals all text")
	assert_true(state.get_rite_instance(view._rite_uid) != null, "revealing text does not commit the rite")

func test_resolved_rite_does_not_consume_sudan_without_clean_result():
	var rng := RNG.new(88)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var sudan_id := RoundLoop.draw_weekly_sudan(state, db, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000003)
	view._rite = {
		"settlement": [
			{"condition": {"s1.type": "sudan"}, "result": {}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._placed = {"s1": sudan_id}
	view._gold_dice_label = _owned(Label.new()) as Label
	view._gold_dice_btn = _owned(Button.new()) as Button
	view._result_label = _owned(RichTextLabel.new()) as RichTextLabel

	view._resolve()
	assert_eq(state.active_sudan_cards.size(), 1, "placing a sudan card does not consume it without an explicit clean result")

func test_resolved_rite_consumes_sudan_when_cleaning_placed_slot():
	var rng := RNG.new(89)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var sudan_id := RoundLoop.draw_weekly_sudan(state, db, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000003)
	view._rite = {
		"settlement": [
			{"condition": {"s1.type": "sudan"}, "result": {"clean.s1": 1}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._placed = {"s1": sudan_id}
	view._gold_dice_label = _owned(Label.new()) as Label
	view._gold_dice_btn = _owned(Button.new()) as Button
	view._result_label = _owned(RichTextLabel.new()) as RichTextLabel

	view._resolve()
	assert_eq(state.active_sudan_cards.size(), 1, "preview must not consume a sudan card before result confirmation")
	view._resolve()
	assert_eq(state.active_sudan_cards.size(), 0, "confirming the result consumes the explicitly cleaned sudan card")

func test_slot_accepts_card_requires_type_and_tag_conditions():
	var rng := RNG.new(90)
	var state := GameState.new()
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	var noble_card: Dictionary = db.get_card(2000005).duplicate(true)
	noble_card["id"] = 2000005
	var protagonist_card: Dictionary = db.get_card(2000001).duplicate(true)
	protagonist_card["id"] = 2000001
	var required_tag := _tag_on_first_not_second(noble_card, protagonist_card)
	var slot_def := {"condition": {"type": "char", required_tag: 1}}

	assert_true(view._slot_accepts_card(slot_def, noble_card), "card with required type and tag is accepted")
	assert_false(view._slot_accepts_card(slot_def, protagonist_card), "card missing required tag is rejected")

func test_slot_accepts_card_rejects_wrong_type():
	var rng := RNG.new(91)
	var state := GameState.new()
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	var card: Dictionary = db.get_card(2000005).duplicate(true)
	card["id"] = 2000005
	assert_false(view._slot_accepts_card({"condition": {"type": "item"}}, card), "wrong card type is rejected")

func test_rite_view_builds_dynamic_slots_from_config():
	var rng := RNG.new(93)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5001001)
	view._rite = {
		"cards_slot": {
			"s1": {}, "s2": {}, "s3": {}, "s4": {}, "s5": {}, "s6": {}, "s7": {},
		}
	}
	view._slot_layer = _owned(Control.new()) as Control
	view._build_slot_placeholders()

	assert_eq(view._slot_buttons.size(), 7, "rite UI should render every configured slot")
	assert_true(view._slot_buttons.has("s7"), "slot generation should not stop at s4")
	for button in view._slot_buttons.values():
		var background := button.get_node("SlotBackground") as TextureRect
		assert_not_null(background.texture, "null template background retains the default slot texture")

func test_rite_resolution_deferred_rite_event_and_prompt_reach_state():
	var rng := RNG.new(94)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"settlement": [
			{"condition": {}, "result": {"event_on": 5310008}, "action": {"rite": 5000001, "prompt": {"id": "p1"}}}
		],
		"settlement_extre": [],
		"settlement_prior": [],
		"cards_slot": {},
	}
	view._gold_dice_label = _owned(Label.new()) as Label
	view._gold_dice_btn = _owned(Button.new()) as Button
	view._result_label = _owned(RichTextLabel.new()) as RichTextLabel
	var rites_before := state.available_rite_instances().filter(func(instance): return instance.id == 5000001).size()

	view._resolve()
	view._commit_resolution()

	assert_eq(str(state.event_prompts[0].get("id", "")), "think_pop.5310008_01", "nested event prompt runs before the following action")
	assert_eq(state.available_rite_instances().filter(func(instance): return instance.id == 5000001).size(), rites_before, "finalOperations wait for the nested event")
	var operation := state.consume_pending_operation()
	OperationsSequence.resume(operation, state, db, rng)
	view._advance_settlement_execution()
	for i in range(8):
		if state.pending_operations.is_empty() or str(state.event_prompts[0].get("id", "")) == "p1":
			break
		OperationsSequence.resume(state.consume_pending_operation(), state, db, rng)
		view._advance_settlement_execution()
	assert_eq(state.available_rite_instances().filter(func(instance): return instance.id == 5000001).size(), rites_before + 1, "rite result creates a fresh runtime rite entry")
	assert_eq(str(state.event_prompts[0].get("id", "")), "p1", "prompt should enter the runtime prompt queue")

func test_rite_resolution_choose_executes_one_random_suboperation():
	# ChooseOperations randomly executes N (default 1) nested operations —
	# it is not a player choice (that is `option`).
	# [SRC: ChooseOperations.c @ GetOperations (0x4f3830): Shuffle + GetRange]
	var rng := RNG.new(95)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"settlement": [
			{"condition": {}, "result": {"choose": {"pop.test": "hello"}}}
		],
		"settlement_extre": [],
		"settlement_prior": [],
		"cards_slot": {},
	}
	view._gold_dice_label = _owned(Label.new()) as Label
	view._gold_dice_btn = _owned(Button.new()) as Button
	view._result_label = _owned(RichTextLabel.new()) as RichTextLabel

	view._resolve()

	view._commit_resolution()
	assert_eq(state.event_prompts.size(), 1, "choose executes its single nested operation")
	assert_eq(str(state.event_prompts[0].get("id", "")), "pop.test", "the nested pop operation runs as-is")
	assert_eq(str(state.event_prompts[0].get("text", "")), "hello")

func test_drop_card_moves_between_hand_slot_and_back():
	var rng := RNG.new(92)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var card_id := int(state.hand[0])
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._slot_buttons = {"s1": _owned(Button.new()) as Button}
	# The slot renderer inserts its card below the authored hover surface.
	var highlight := TextureRect.new()
	highlight.name = "SourceHighlight"
	view._slot_buttons.s1.add_child(highlight)
	view._slot_titles = {"s1": _owned(Label.new()) as Label}
	view._slot_details = {"s1": _owned(Label.new()) as Label}
	var initial_hand_size := state.hand.size()

	view.drop_card_on_slot("s1", {"type": "card", "card_id": card_id, "source": "hand"})

	assert_false(state.has_card_in_hand(card_id), "card leaves hand when placed in a slot")
	assert_eq(state.cards_in_slot(1).size(), 1, "placed card enters the slot table state")
	assert_eq(int(view._placed.get("s1", 0)), card_id)

	view.return_card_to_hand(card_id, "s1")

	assert_true(state.has_card_in_hand(card_id), "card returns to hand when dragged back")
	assert_eq(state.hand.size(), initial_hand_size)
	assert_eq(state.cards_in_slot(1).size(), 0)
	await wait_process_frames(2)

func test_prepare_table_preserves_cards_outside_placed_slots():
	var rng := RNG.new(99)
	var state := GameState.new()
	state.add_card_to_slot(2000006, 3, db)
	state.add_card_to_slot(2000007, 1, db)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._placed = {"s1": 2000005}

	view._prepare_table_from_placements()

	assert_eq(state.cards_in_slot(3).size(), 1, "unrelated table cards remain")
	if state.cards_in_slot(3).is_empty():
		return
	assert_eq(int(state.cards_in_slot(3)[0].get("id", 0)), 2000006)
	assert_eq(state.cards_in_slot(1, view._rite_uid).size(), 1, "placed slot is replaced within this rite")
	assert_eq(int(state.cards_in_slot(1, view._rite_uid)[0].get("id", 0)), 2000005)

func test_prepare_table_clears_slots_cancelled_after_prior_placement():
	var rng := RNG.new(100)
	var state := GameState.new()
	state.add_card_to_slot(2000006, 3, db)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._placed = {"s1": 2000005}

	view._prepare_table_from_placements()
	assert_eq(state.cards_in_slot(1, view._rite_uid).size(), 1, "initial placement exists")

	view._placed.clear()
	view._prepare_table_from_placements()

	assert_eq(state.cards_in_slot(1, view._rite_uid).size(), 0, "cancelled placement slot is cleared")
	assert_eq(state.cards_in_slot(3).size(), 1, "unrelated table card still remains")


func test_rite_over_result_emits_game_over_requested():
	# A rite settlement carrying an `over` result must signal game-over to the
	# controller, so rite-driven endings actually fire.
	var rng := RNG.new(91)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000003)
	view._rite = {
		"settlement": [
			{"condition": {}, "result": {"over": 1}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._gold_dice_label = _owned(Label.new()) as Label
	view._gold_dice_btn = _owned(Button.new()) as Button
	view._result_label = _owned(RichTextLabel.new()) as RichTextLabel
	watch_signals(view)

	view._resolve()
	assert_signal_not_emitted(view, "game_over_requested", "preview must not end the game before confirmation")
	view._resolve()
	assert_signal_emitted(view, "game_over_requested", "rite over result should emit game_over_requested")


func test_rite_without_over_does_not_emit_game_over():
	# A normal rite (no over) must not emit game_over_requested.
	var rng := RNG.new(92)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000003)
	view._rite = {
		"settlement": [
			{"condition": {}, "result": {"coin": 1}, "result_title": "", "result_text": ""}
		],
		"settlement_extre": [],
		"settlement_prior": [],
	}
	view._gold_dice_label = _owned(Label.new()) as Label
	view._gold_dice_btn = _owned(Button.new()) as Button
	view._result_label = _owned(RichTextLabel.new()) as RichTextLabel
	watch_signals(view)

	view._resolve()
	assert_signal_not_emitted(view, "game_over_requested", "normal rite should not emit game_over_requested")


func test_manual_rite_settlement_waits_for_confirmation_before_removing_instance():
	var rng := RNG.new(96)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"id": 5000001,
		"settlement": [{"condition": {}, "result": {"coin": 2}, "action": {}}],
		"settlement_prior": [], "settlement_extre": [], "cards_slot": {},
	}
	view._gold_dice_label = _owned(Label.new()) as Label
	view._gold_dice_btn = _owned(Button.new()) as Button
	view._result_label = _owned(RichTextLabel.new()) as RichTextLabel
	watch_signals(view)

	view._resolve()
	assert_not_null(state.get_rite_instance(view._rite_uid), "first confirmation opens a retryable result preview")
	assert_signal_not_emitted(view, "resolved", "preview must not announce a completed rite")
	assert_eq(state.coin_count, 0, "selection keeps finalResults unexecuted")

	view._resolve()
	assert_null(state.get_rite_instance(view._rite_uid), "second confirmation commits and removes the rite instance")
	assert_signal_emitted(view, "resolved", "only the committed settlement emits resolved")


func test_closing_committed_5010009_result_opens_terminal_map_state():
	var rng := RNG.new(9609)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5010009)
	view._resolution_committed = true
	view._close_panel()
	assert_true(state.end_open, "OnClose b__0 writes Player.end_open for exactly rite 5010009")

	state.end_open = false
	var other := _owned(RiteView.new()) as RiteView
	other.setup(state, db, rng, 5000001)
	other._resolution_committed = true
	other._close_panel()
	assert_false(state.end_open, "other final_pin or ordinary rites cannot synthesize terminal map state")


func test_rite_view_binds_to_existing_runtime_instance_when_no_uid_is_supplied():
	var rng := RNG.new(98)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var instance = state.create_rite_instance(5000001)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	assert_not_null(instance)
	if instance != null:
		assert_eq(view._rite_uid, instance.uid, "existing rite view must bind to its runtime uid instead of using global slots")


func test_closing_pending_result_restores_uncommitted_world_effects():
	var rng := RNG.new(97)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._rite = {
		"id": 5000001,
		"settlement": [{"condition": {}, "result": {"coin": 4}, "action": {}}],
		"settlement_prior": [], "settlement_extre": [], "cards_slot": {},
	}
	view._gold_dice_label = _owned(Label.new()) as Label
	view._gold_dice_btn = _owned(Button.new()) as Button
	view._result_label = _owned(RichTextLabel.new()) as RichTextLabel

	view._resolve()
	assert_eq(state.coin_count, 0, "selection has no world transaction to roll back")
	state.add_coin(3, db)
	view._close_panel()
	assert_eq(state.coin_count, 3, "closing cannot overwrite unrelated live world changes")
	assert_not_null(state.get_rite_instance(view._rite_uid), "cancelled preview leaves the rite open")


func _tag_on_first_not_second(first: Dictionary, second: Dictionary) -> String:
	var first_tags: Dictionary = first.get("tag", {})
	var second_tags: Dictionary = second.get("tag", {})
	for tag in first_tags:
		if int(first_tags[tag]) != 0 and int(second_tags.get(tag, 0)) == 0:
			return str(tag)
	return str(first_tags.keys()[0])


func _db_with_manual_rites() -> ConfigDB:
	# Non-auto_begin stubs: setup_new_run leaves them unstarted so the panel's
	# confirm path (start, not settle) can be exercised.
	var local_db := ConfigDB.new()
	local_db.load_all()
	local_db.rites[992001] = {
		"id": 992001, "name": "Manual multi-day", "open_conditions": [],
		"cards_slot": {}, "round_number": 2, "waiting_round": 0,
		"waiting_round_end_action": [],
		"settlement_prior": [],
		"settlement": [{"condition": {}, "result": {"coin": 6}, "action": {}}],
		"settlement_extre": [], "auto_begin": 0, "auto_result": 0,
	}
	local_db.rites[992002] = {
		"id": 992002, "name": "Manual zero-day", "open_conditions": [],
		"cards_slot": {}, "round_number": 0, "waiting_round": 0,
		"waiting_round_end_action": [],
		"settlement_prior": [],
		"settlement": [{"condition": {}, "result": {"coin": 6}, "action": {}}],
		"settlement_extre": [], "auto_begin": 0, "auto_result": 0,
	}
	local_db.rites[992003] = {
		"id": 992003, "name": "Manual restore", "open_conditions": [],
		"cards_slot": {
			"s1": {"condition": {}, "open_adsorb": 0},
			"s2": {"condition": {}, "open_adsorb": 0},
			"s3": {"condition": {}, "open_adsorb": 1},
		}, "round_number": 2, "waiting_round": 0,
		"waiting_round_end_action": [], "settlement_prior": [],
		"settlement": [{"condition": {}, "result": {}, "action": {}}],
		"settlement_extre": [], "auto_begin": 0, "auto_result": 0,
	}
	return local_db


func test_started_rite_blocks_slot_click_drag_and_desktop_return_until_stopped():
	var local_db := _db_with_manual_rites()
	var rng := RNG.new(510)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, local_db, rng, 992003)
	add_child(view)
	await wait_process_frames(2)
	var uid: int = state.player_actor_uid
	view._place_card_in_slot("s1", uid, "hand", "")
	view._refresh_slot_visuals()
	var data := {"type": "card", "card_uid": uid, "source": "slot", "source_slot": "s1", "source_rite_uid": view._rite_uid}
	var screen = _owned(preload("res://ui/game_screen.gd").new())
	screen._state = state
	screen._db = local_db
	assert_false(view._can_edit_slot("s3"), "automatic adsorption never allows manual editing")
	state.get_rite_instance(view._rite_uid).start = true
	state.get_rite_instance(view._rite_uid).start_round = state.round_number
	view._on_slot_pressed("s1")
	view.return_card_to_hand(uid, "s1")
	view.drop_card_on_slot("s2", data)
	screen.drop_card_to_hand(data)
	assert_eq(state.cards_in_slot(1, view._rite_uid).size(), 1, "all return and move routes retain the running card")
	assert_true(state.cards_in_slot(2, view._rite_uid).is_empty())
	assert_false(screen.can_drop_card_to_hand(data))
	assert_false(view.can_drop_card_on_slot("s2", data))
	var widget = view._slot_buttons["s1"].get_node("Container/PlacedCard_S1")
	assert_null(widget._get_drag_data(Vector2.ZERO), "running slot cannot initiate a drag")
	view._stop_started_rite()
	assert_true(view._can_edit_slot("s1"), "stop reopens the same slot without rebuilding state")
	assert_true(screen.can_drop_card_to_hand(data))
	view.return_card_to_hand(uid, "s1")
	assert_true(state.has_card_in_hand(uid))
	await wait_process_frames(2)


func test_empty_slot_cycles_qualified_bags_and_keeps_empty_match_state():
	var local_db := _db_with_manual_rites()
	var state := GameState.new()
	var rng := RNG.new(511)
	state.setup_new_run(local_db, 1, rng)
	# The fixture's s3 is the open_adsorb slot. Creation-time adsorption walks
	# the hand in source order and takes the FIRST match, so the unconstrained
	# s3 takes the protagonist; the manual-slot cycling below is about s1/s2.
	# [SRC: RiteExtensions.c @ AdsorbCards 0x38fca0]
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, local_db, rng, 992003)
	# The fixture's s3 is the open_adsorb slot and creation-time adsorption
	# walks the hand in source order, taking the FIRST accepted card — here the
	# protagonist. Page 2 is therefore empty and the qualified set is [0].
	# [SRC: RiteExtensions.c @ AdsorbCards 0x38fca0 (CanPutCard scan order)]
	assert_eq(int(view._placed.get("s3", 0)), int(state.player_actor_uid),
		"the open_adsorb slot takes the first hand card its condition accepts")
	view._rite["cards_slot"]["s1"]["condition"] = {"type": "char"}
	view._rite["cards_slot"]["s2"]["condition"] = {"type": "unmatched"}
	for uid in state.hand:
		state.get_card_instance(uid).bag = 0
	state.current_bag_index = 0
	var slots_before := view._placed.duplicate(true)
	view._on_slot_pressed("s1")
	assert_eq(state.current_bag_index, 0, "first click keeps the only qualified page")
	view._on_slot_pressed("s1")
	assert_eq(state.current_bag_index, 0, "repeat cycles the qualified set")
	view._on_slot_pressed("s2")
	assert_eq(state.current_bag_index, 0, "no matches does not change page")
	assert_eq_deep(view._placed, slots_before)


func test_reopened_running_rite_cannot_settle_before_source_life_boundary():
	var local_db := _db_with_manual_rites()
	var rng := RNG.new(514)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, local_db, rng, 992001)
	add_child(view)
	await wait_process_frames(2)
	state.start_rite_instance(view._rite_uid)
	var instance = state.get_rite_instance(view._rite_uid)
	for age in [0, 1]:
		instance.life = age
		view._update_resolve_button()
		assert_true(view._resolve_btn.disabled)
		var before := SaveSystem.serialize(state)
		view._resolve()
		assert_eq_deep(SaveSystem.serialize(state), before)
		assert_false(view._resolution_pending)
	instance.life = 2
	view._update_resolve_button()
	assert_false(view._resolve_btn.disabled)
	view._resolve()
	assert_true(view._resolution_pending)
	assert_eq(state.coin_count, 0)


func test_result_prompt_blocks_commit_cancel_and_retry_until_response():
	var local_db := _db_with_manual_rites()
	local_db.rites[992002]["settlement"][0]["action"] = {"prompt": {"id": "result_wait", "text": "Wait"}}
	var rng := RNG.new(512)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	state.gold_dice = 2
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, local_db, rng, 992002)
	add_child(view)
	await wait_process_frames(2)
	watch_signals(view)
	view._resolve()
	view._commit_resolution()
	view._rerolls_left = 1
	view._update_result_wait_controls()
	var before := SaveSystem.serialize(state)
	view._commit_resolution()
	view._close_panel()
	view._use_gold_dice_reactive()
	view._use_reroll()
	assert_eq_deep(SaveSystem.serialize(state), before)
	assert_eq(view._rerolls_left, 1)
	assert_not_null(state.get_rite_instance(view._rite_uid))
	assert_signal_not_emitted(view, "resolved")
	assert_signal_not_emitted(view, "closed")
	assert_true(view._resolve_btn.disabled)
	assert_true(view._close_btn.disabled)
	assert_true(view._gold_dice_btn.disabled)
	assert_true(view._reroll_btn.disabled)
	var screen = _owned(preload("res://ui/game_screen.gd").new())
	screen._state = state
	screen._db = local_db
	screen._rng = rng
	# Actual queue completion path, including close_prompt and continuations.
	screen._consume_event_display()
	await wait_process_frames(2)
	assert_true(view._resolution_committed, "serial completion finishes after the response")
	assert_null(state.get_rite_instance(view._rite_uid))
	assert_eq(state.coin_count, 6, "waiting must not replay the reward")
	assert_signal_emitted(view, "resolved")


func test_zero_day_auto_result_waits_for_prompt_before_closing():
	var local_db := _db_with_manual_rites()
	local_db.rites[992002]["auto_result"] = 1
	local_db.rites[992002]["settlement"][0]["action"] = {"prompt": {"id": "auto_wait", "text": "Wait"}}
	var rng := RNG.new(513)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	state.auto_result_rites.append(992002)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, local_db, rng, 992002)
	add_child(view)
	await wait_process_frames(2)
	watch_signals(view)
	view._resolve()
	await wait_process_frames(2)
	assert_signal_not_emitted(view, "closed")
	assert_not_null(state.get_rite_instance(view._rite_uid))
	var screen = _owned(preload("res://ui/game_screen.gd").new())
	screen._state = state
	screen._db = local_db
	screen._rng = rng
	screen._consume_event_display()
	await wait_process_frames(3)
	assert_signal_emitted(view, "resolved")
	assert_signal_emitted(view, "closed")
	assert_null(state.get_rite_instance(view._rite_uid))


func test_auto_result_capability_does_not_skip_player_decision():
	var local_db := _db_with_manual_rites()
	local_db.rites[992002]["auto_result"] = 1
	var state := GameState.new()
	var rng := RNG.new(513)
	state.setup_new_run(local_db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, local_db, rng, 992002)
	add_child(view)
	view._resolve()
	assert_true(view._resolution_pending)
	assert_false(view._resolution_committed, "config permits automation; player has not enabled it")
	assert_eq(state.coin_count, 0, "selection must await the result decision")
	view._toggle_result_auto_play()
	assert_true(state.rite_auto_result, "playback belongs to the global flag at Player+0x160")
	assert_false(state.auto_result_rites.has(992002), "playback does not hide future results")
	view._toggle_auto_result()
	assert_true(state.auto_result_rites.has(992002))
	view._toggle_result_auto_play()
	assert_false(state.rite_auto_result)
	assert_true(state.auto_result_rites.has(992002), "per-rite automation survives playback changes")


func test_confirm_records_manual_rite_slots_for_last_state_restore():
	# OnConfirm stores manual slot guid -> LastCardData{id,count}; open_adsorb
	# is field +0x20 and must not be confused with is_enemy.
	# [SRC: RitePanelController.c OnConfirm 0x58f1c0 L1282-1288; dump.cs
	#       RiteNode.Slot.open_adsorb @0x20]
	var local_db := _db_with_manual_rites()
	var rng := RNG.new(100)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	state.add_coin(3, local_db)
	var gold_uid := state.gold_card_uids()[0]
	var actor_uid := state.player_actor_uid
	var view := _owned(RiteView.new()) as RiteView
	add_child(view)
	view.setup(state, local_db, rng, 992003)
	await wait_process_frames(2)
	view._place_card_in_slot("s1", gold_uid, "hand", "")
	view._place_card_in_slot("s3", actor_uid, "hand", "")
	view._resolve()
	assert_eq(state.get_last_round_rite_data(992003), {
		"s1": {"id": 2000029, "count": 3},
	}, "only manual slots are recorded under the rite config id")


func test_restore_last_rite_state_is_partial_and_reforms_stack_count():
	# OnLastState restores each slot independently. It must form the saved count
	# from hand stacks, but leave an unavailable slot empty rather than failing
	# the whole restore.
	# [SRC: RitePanelController.c OnLastState (0x58fdf0)]
	var local_db := _db_with_manual_rites()
	var rng := RNG.new(104)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	state.add_coin(5, local_db)
	var gold_uid := state.gold_card_uids()[0]
	var view := _owned(RiteView.new()) as RiteView
	add_child(view)
	view.setup(state, local_db, rng, 992003)
	await wait_process_frames(2)
	# Creation-time adsorption filled the fixture's open_adsorb slot s3 with the
	# first hand card. Withdraw it (the panel refuses to edit that slot, so go
	# through the state) — this test is about OnLastState restore.
	# [SRC: RiteExtensions.c @ AdsorbCards 0x38fca0; RitePanelController.c
	#       @ OnLastState 0x58fdf0]
	var adsorbed_uid := int(view._placed.get("s3", 0))
	assert_gt(adsorbed_uid, 0, "the fixture's open_adsorb slot took a card")
	view._placed.erase("s3")
	state.remove_card_from_slot(adsorbed_uid, 3, view._rite_uid)
	state.add_card_to_hand(adsorbed_uid, local_db)
	assert_true(state.has_card_in_hand(gold_uid), "the gold stack is available for the restore")
	state.last_round_rite_data[992003] = {
		"s1": {"id": 2000029, "count": 3},
		"s2": {"id": 2000029, "count": 999},
	}
	view._restore_last_state()
	var s1_uid := int(view._placed.get("s1", 0))
	assert_gt(s1_uid, 0, "available first slot restores")
	assert_eq(state.get_card_instance(s1_uid).count, 3, "restore splits a larger hand stack to the saved count")
	assert_false(view._placed.has("s2"), "unavailable later slot does not undo the successful first restore")
	assert_eq(state.gold_total(), 5, "restore only moves/splits objects; total gold is unchanged")


func test_confirm_on_multi_day_rite_only_starts_it():
	# Confirm = CheckConfirm + set_start/start_round/start_life; the settlement
	# happens on a later UpdateSingleRite pass, not in the panel.
	# [SRC: RitePanelController.c OnConfirm chain, lines 1203-1239]
	var local_db := _db_with_manual_rites()
	var rng := RNG.new(101)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	add_child(view)
	view.setup(state, local_db, rng, 992001)
	# Lambdas capture locals by value in GDScript; count through an array.
	var closed_count := [0]
	view.closed.connect(func(): closed_count[0] += 1)

	view._resolve()

	var instance = state.get_rite_instance(view._rite_uid)
	assert_not_null(instance, "the started instance stays on the table")
	assert_true(instance.start, "confirm marks the rite started")
	assert_eq(instance.start_round, state.round_number, "start_round records the current round")
	assert_eq(instance.start_life, instance.life, "start_life records the pre-start life")
	assert_eq(state.coin_count, 0, "multi-day rite does not settle on confirm")
	assert_eq(closed_count[0], 1, "the panel closes after starting")


func test_zero_day_rite_confirms_then_settles_in_one_press():
	# round_number == 0: the same press starts and settles immediately.
	var local_db := _db_with_manual_rites()
	var rng := RNG.new(102)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	add_child(view)
	view.setup(state, local_db, rng, 992002)
	view._resolve()
	view._commit_resolution()
	assert_eq(state.coin_count, 6, "zero-day rite settles immediately after starting")
	assert_null(state.get_rite_instance(view._rite_uid), "committed settlement removes the instance")


func test_stop_visibility_and_handler_share_original_start_round_gate():
	var local_db := _db_with_manual_rites()
	var rng := RNG.new(113)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	add_child(view)
	view.setup(state, local_db, rng, 992001)
	view._resolve()
	var instance = state.get_rite_instance(view._rite_uid)
	assert_true(view._stop_btn.visible)
	assert_false(view._last_state_btn.visible)
	state.round_number += 1
	view._update_stop_button()
	assert_false(view._stop_btn.visible, "prior-round rites cannot expose Stop")
	view._stop_started_rite()
	assert_true(instance.start, "direct handler calls cannot bypass the visible gate")
	assert_eq(view.find_child("RiteMainContent", true, false).get_meta("source_text_style"), "@MAIN_BODY")


func test_stop_started_rite_rolls_back_life_and_keeps_cards():
	# [SRC: RitePanelController.c @ OnStop (0x5906e0): set_start(0),
	#       set_life(start_life), new_born=false; cards stay in slots]
	var local_db := _db_with_manual_rites()
	var rng := RNG.new(103)
	var state := GameState.new()
	state.setup_new_run(local_db, 1, rng)
	var view := _owned(RiteView.new()) as RiteView
	add_child(view)
	view.setup(state, local_db, rng, 992001)
	view._resolve()
	var instance = state.get_rite_instance(view._rite_uid)
	assert_true(instance.start, "precondition: rite is started")

	instance.life += 1
	view._stop_started_rite()
	assert_false(instance.start, "stop clears the started flag")
	assert_eq(instance.life, instance.start_life, "life rolls back to start_life")
	assert_false(instance.new_born, "a stopped rite is no longer new-born")


func test_result_text_uses_matched_prior_and_extra_content_without_dsl_debug_rows():
	var state := GameState.new()
	var rng := RNG.new(779)
	state.setup_new_run(db, 0, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	add_child(view)
	var res := RiteResolver.RiteResult.new()
	res.settlements = [{"result_title": "前置标题", "result_text": "前置正文", "result": {"coin": 5}}]
	view._display_result(res)
	assert_eq(view._result_surface_text.get_parsed_text(), str(view._rite.text), "only introduction starts before the player advances")
	view._advance_result_text()
	assert_eq(view._result_paragraph_index, 1, "first click finishes typing without advancing")
	view._advance_result_text()
	assert_eq(view._result_surface_text.get_parsed_text(), str(view._rite.text) + "\n\n前置标题", "second click appends next paragraph")
	view._advance_result_text()
	view._advance_result_text()
	assert_true(view._result_surface_text.get_parsed_text().ends_with("\n\n前置正文"))
	assert_eq(view._result_ops_layer.get_child_count(), 0, "raw DSL keys are not operation card results")
	assert_eq(view._result_cards_layer.get_child_count(), 0, "slot snapshots are not operation card playback")
	res.settlements = [{"result_text": "普通正文"}, {"result_text": "额外正文"}]
	view._display_result(res)
	assert_eq(view._result_paragraphs, [str(view._rite.text), "普通正文", "额外正文"], "extra text is queued in source selection order")
	view._display_result(RiteResolver.RiteResult.new())
	assert_eq(view._result_surface_text.get_parsed_text(), str(view._rite.text), "empty settlement retains the original rite introduction")


func test_rite_help_follows_template_title_and_does_not_duplicate():
	var state := GameState.new()
	var rng := RNG.new(780)
	state.setup_new_run(db, 0, rng)
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	add_child(view)
	await wait_process_frames(2)
	view._show_rite_help()
	var help: Control = view._source_canvas.get_node("RiteHelp")
	assert_eq(help.position + help.size * 0.5, view._rite_panel.position + view._rite_panel.size * 0.5 - Vector2(0, 210), "Help retains the source CommonContent parent center")
	assert_eq(help.get_node("Prompt").position, Vector2(-949, 233), "help artwork retains its own authored offset")
	assert_almost_eq(help.get_node("Mask").color.a, 128.0 / 255.0, 0.0001, "source help dimming does not black out the underlying page")
	view._show_rite_help()
	assert_null(view._source_canvas.get_node_or_null("RiteHelp2"), "repeated help requests do not stack overlays")


func test_dice_selection_can_cancel_without_spending_and_confirms_multiple_gold_once():
	var rng := RNG.new(1771)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	state.gold_dice = 3
	var view := _owned(RiteView.new()) as RiteView
	view.setup(state, db, rng, 5000001)
	view._rite = {"id": 5000001, "cards_slot": {"s1": {"condition": {"type": "char"}}},
		"settlement": [{"condition": {"r1:体魄>=": [1, 5]}, "result": {"coin": 1}}],
		"settlement_prior": [], "settlement_extre": []}
	add_child(view)
	await wait_process_frames(2)
	view._place_card_in_slot("s1", int(state.hand[0]), "hand", "")
	view._resolve()
	view._rerolls_left = 2
	assert_true(view._gold_dice_btn.is_visible_in_tree(), "source side control survives preparation hide")
	assert_true(view._reroll_btn.is_visible_in_tree())
	view._show_dice_count_prompt("gold")
	view._show_dice_count_prompt("gold")
	assert_eq(state.gold_dice, 3, "tentative gold leaves persistent resources intact")
	assert_eq(view._gold_selected, 2)
	view._show_dice_count_prompt("reroll")
	assert_eq(view._dice_count_kind, "gold", "cannot start redraw during gold selection")
	view._cancel_dice_selection()
	assert_eq(state.gold_dice, 3)
	assert_eq(view._gold_selected, 0)
	view._show_dice_count_prompt("reroll")
	assert_eq(view._rerolls_left, 2, "redraw reservation is reversible")
	view._show_dice_count_prompt("gold")
	assert_eq(view._gold_selected, 0, "cannot add gold during redraw confirmation")
	view._cancel_dice_selection()
	assert_eq(view._rerolls_left, 2)
	var dice_state: Array = view._last_result.dice_rolls.duplicate()
	view._show_dice_count_prompt("gold")
	view._show_dice_count_prompt("gold")
	view._confirm_dice_count_prompt()
	assert_eq(state.gold_dice, 1, "confirmation spends exactly the reserved quantity")
	assert_eq(view._last_result.dice_rolls, dice_state, "gold confirmation retains cached rolls; newly matched rewards may consume RNG")
	assert_eq(view._gold_used_this_resolve, 2)
	view._confirm_dice_count_prompt()
	assert_eq(state.gold_dice, 1, "duplicate confirmation cannot spend twice")
