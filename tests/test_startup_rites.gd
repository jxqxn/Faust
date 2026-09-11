extends GutTest

var db: ConfigDB

func before_all():
	db = ConfigDB.new()
	db.load_all()

func count_rite(state: GameState, id: int) -> int:
	var count := 0
	for instance in state.available_rite_instances():
		if instance.id == id:
			count += 1
	return count

func acknowledge(state: GameState, rng: GameRNG) -> void:
	for step in range(256):
		if state.pending_operations.is_empty():
			return
		var pending := state.pending_operation()
		var choice := ""
		var choices: Dictionary = pending.get("payload", {}).get("choices", {})
		if choices.has("diff_1"):
			choice = "diff_1" # Explicit fixture: Hassan / normal difficulty.
		elif str(pending.id) in ["5310000_option_1", "5310001_option_1", "5310002_option_1", "5310003_option_1", "5310004_option_1"]:
			for key in pending.get("sequence_response", {}).get("choices", {}):
				if pending.sequence_response.choices[key].tag == "op1":
					choice = key # Merchant / speech / conservative / valiant wife / accept.
			if choice.is_empty():
				fail_test("Source op1 missing from %s" % pending.id)
				return
		elif str(pending.id) == "5300000_confirm_1":
			choice = "confirm_cancel" # Both source branches enable 5300066.
		elif str(pending.kind) == "rename_card":
			state.set_prompt_name(0, "阿尔图")
		elif not choices.is_empty() or pending.has("sequence_response"):
			fail_test("Fixture needs explicit choice: %s %s" % [pending.id, choices.keys()])
			return
		var operation := state.consume_pending_operation()
		if choice == "diff_1":
			DeferredEffects.execute_choice(choice, choices[choice], state, db, rng, operation.context)
		OperationsSequence.resume(operation, state, db, rng, choice)
	fail_test("Informational sequence did not finish")

func finish_day(state: GameState, rng: GameRNG) -> void:
	RoundLoop.advance_day(state, db, rng)
	for step in range(256):
		acknowledge(state, rng)
		if not state.pending_operations.is_empty():
			return
		if state.round_transition.is_empty():
			return
		RoundLoop.resume_day(state, db, rng)
	fail_test("Day transition did not finish")

func test_story_generates_one_household_and_day_transition_keeps_one_successor():
	# [SRC: Datapool.InitPlayer 0x413700 / InitNode.default_rite@0x68;
	# init/1.json []; event/5300066 settlement.action.rite;
	# rite/5000001 settlement.action.rite creates the successor.]
	var rng := GameRNG.new(201)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng, false)
	assert_eq(state.available_rite_instances().size(), 0, "no invented map entries before story")
	RoundLoop.begin_opening(state, db, rng)
	assert_eq(state.active_sudan_cards.size(), 0, "opening choices precede the draw")
	acknowledge(state, rng)
	RoundLoop.resume_day(state, db, rng)
	assert_eq(count_rite(state, 5000001), 1, "story creates the first household, not a duplicate")
	assert_eq(count_rite(state, 5002006), 1, "source population supplies the required bookshop owner")
	assert_eq(count_rite(state, 5002001), 0, "unowned injured NPCs must not spuriously unlock hospital")
	var shop = state.find_rite_instance_by_id(5002006)
	assert_eq(state.get_card_instance(state.cards_in_slot(5, shop.uid)[0].card_uid).card_id, 2000199)
	var first_day_ids: Array = []
	for instance in state.available_rite_instances():
		first_day_ids.append(instance.id)
	assert_eq(first_day_ids, [5001001, 5001501, 5002006, 5000001], "raw operation order matches original first-day notes")
	print("STARTUP_RITES first_day=", first_day_ids)
	var first_uid: int = state.find_rite_instance_by_id(5000001).uid
	for day in range(2, 4):
		finish_day(state, rng)
		assert_eq(state.round_number, day)
		assert_true(state.round_transition.is_empty())
		assert_eq(count_rite(state, 5000001), 1, "one household successor after day %s" % day)
	assert_null(state.get_rite_instance(first_uid), "completed household replaced, not retained")
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(count_rite(restored, 5000001), 1, "loading does not seed additional defaults")

func test_explicit_duplicate_instances_survive_save_without_global_deduplication():
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(202))
	state.add_available_rite(5000001, db)
	state.add_available_rite(5000001, db)
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(count_rite(restored, 5000001), 2, "no name/id based cleanup of existing progress")

func test_opening_wait_and_draw_survive_save_load():
	var rng := GameRNG.new(203)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng, false)
	RoundLoop.begin_opening(state, db, rng)
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	assert_eq(restored.round_transition.phase, "opening_draw")
	RoundLoop.resume_day(restored, db, rng)
	assert_eq(restored.active_sudan_cards.size(), 0, "loading cannot bypass the pending opening")
	acknowledge(restored, rng)
	RoundLoop.resume_day(restored, db, rng)
	assert_eq(restored.active_sudan_cards.size(), 1)
	assert_eq(restored.round_number, 1, "opening is not a next-day transition")
	assert_true(restored.round_transition.is_empty())
	RoundLoop.resume_day(restored, db, rng)
	assert_eq(restored.active_sudan_cards.size(), 1, "resume is idempotent after completion")

func test_desktop_reward_targets_hidden_cards_and_excludes_rite_and_equipment():
	# [SRC: DesktopModifyTag.DoTemplate 0x50e400 -> Player.cards@0x88;
	# event/5310003 grants the existing wife adherent without creating a card.]
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(204), false)
	var wife := state.card_uid_for(2000006, "hand")
	var slotted = state.create_card_instance(2000006, db, "slot")
	var equipped = state.create_card_instance(2000006, db, "equipped")
	ResultExec.execute({"table.妻子+追随者": 1}, state, db, {"card_uid": slotted.uid, "rite_uid": 999})
	assert_true(state.is_hand_card(wife), "hidden desktop wife receives the reward despite unrelated context")
	assert_eq(int(slotted.tags.get("追随者", 0)), 0)
	assert_eq(int(equipped.tags.get("追随者", 0)), 0)
