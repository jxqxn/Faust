extends GutTest

## Batch E: bag placement fields (original Card bag@0x48 / bagpos@0x4c).
## bag = bag page id (BagIndex marks the page being viewed), bag_pos = 1-based
## position within the page (0 = unplaced); UpdateHandCardPos compacts the
## current page's hand cards to 1..N; GenCoin pins fresh gold at position 1.
## [SRC: CardExtensions.c IsCurrentHandCard (0x3826a0): bag == player+0x150;
##       GameController.c UpdateHandCardPos (0x559a70) L1060-1097;
##       GenCoin.c set_bagpos(1); GenSudanCard set_bag(BagIndex)]

const RNG = preload("res://core/rng.gd")
const CORPUS_AUTO_SAVE := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"


func _local_db() -> ConfigDB:
	var local_db := ConfigDB.new()
	local_db.load_all()
	return local_db


func test_gold_grant_pins_bag_pos_one() -> void:
	var state := GameState.new()
	state.setup_new_run(_local_db(), 1, RNG.new(1))
	state.add_coin(5)
	for uid in state.gold_card_uids():
		var instance = state.get_card_instance(int(uid))
		assert_eq(int(instance.bag_pos), 1, "GenCoin pins gold at the front position")
		assert_eq(int(instance.bag), 0, "gold lives on the default page")


func test_day_boundary_compacts_hand_positions() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.setup_new_run(local_db, 1, RNG.new(2))
	for uid in state.hand:
		var instance = state.get_card_instance(int(uid))
		assert_eq(int(instance.bag_pos), 0, "freshly granted cards start unplaced")
	RoundLoop.advance_day(state, local_db, RNG.new(3))
	for index in state.hand.size():
		var instance = state.get_card_instance(int(state.hand[index]))
		assert_eq(int(instance.bag_pos), index + 1,
			"UpdateHandCardPos compacts positions to 1..N in hand order")


func test_compaction_skips_other_bag_pages() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.setup_new_run(local_db, 1, RNG.new(4))
	var keeper = state.get_card_instance(int(state.hand[0]))
	keeper.bag = 2
	keeper.bag_pos = 7
	RoundLoop.advance_day(state, local_db, RNG.new(5))
	assert_eq(int(keeper.bag), 2, "cards on other pages keep their page")
	assert_eq(int(keeper.bag_pos), 7, "and their positions (IsCurrentHandCard filters by page)")


func test_bag_fields_round_trip_through_save() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.setup_new_run(local_db, 1, RNG.new(6))
	state.get_card_instance(int(state.hand[0])).bag_pos = 3
	state.get_card_instance(int(state.hand[1])).bag = 4
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, local_db)
	assert_eq(int(restored.get_card_instance(int(state.hand[0])).bag_pos), 3)
	assert_eq(int(restored.get_card_instance(int(state.hand[1])).bag), 4)


func test_sudan_draw_enters_current_bag_page() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.setup_new_run(local_db, 1, RNG.new(7))
	RoundLoop.draw_weekly_sudan(state, local_db, RNG.new(8))
	var instance = state.get_card_instance(int(state.active_sudan_cards.back().card_uid))
	assert_eq(int(instance.bag), 0, "GenSudanCard set_bag(BagIndex) lands on the viewed page")


func test_importer_carries_bag_positions_verbatim() -> void:
	if not FileAccess.file_exists(CORPUS_AUTO_SAVE):
		pending("corpus save sample not available; skipping")
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CORPUS_AUTO_SAVE))
	if not (parsed is Dictionary):
		pending("corpus save sample unreadable; skipping")
		return
	var imported: Dictionary = OriginalSaveImporter.import_save(parsed, _local_db())
	var state = imported["state"]
	# The sample positions: uid 29 (protagonist) at 1, the sudan at 2, etc.
	assert_eq(int(state.get_card_instance(29).bag_pos), 1)
	assert_eq(int(state.get_card_instance(11).bag_pos), 2, "the sudan card sits at position 2")
	assert_eq(int(state.get_card_instance(31).bag_pos), 3)
	var bag_row: Dictionary = {}
	for row in imported["report"]["diff"]:
		if str(row["check"]) == "bag_positions":
			bag_row = row
	assert_true(bag_row.has("check"), "the diff covers bag positions")
	assert_true(bool(bag_row.get("pass", false)), "every imported card keeps its [bag, bagpos] pair")
