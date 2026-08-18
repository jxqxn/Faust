extends GutTest

## Batch O: the per-round notes journal (original Player.notes @0x138,
## List<List<Note>>, page index = round - 1). Types: 1 rite created, 2 rite
## expired, 3 rite settled, 4 rite adsorbed a card (count = card id), 10001
## follower, 10002 reward card. Runtime write points 1/2/3 landed; 4/10001
## (callers outside the decompiled subset) and 10002 (tag gate unresolvable)
## stay registered in METHOD_MAP.
## [SRC: dump.cs:391430 Player.Note; PlayerExtensions.c AddNote 0x38c130;
##       StartRite.c L133; GameController.c L5867; RiteResultPanelController]

const RNG = preload("res://core/rng.gd")
const CORPUS_AUTO_SAVE := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"


func _local_db() -> ConfigDB:
	var local_db := ConfigDB.new()
	local_db.load_all()
	return local_db


func test_add_note_pages_by_round() -> void:
	var state := GameState.new()
	state.round_number = 1
	state.add_note(1, 5001001, 7)
	assert_eq(state.notes.size(), 1, "round 1 writes page 0")
	assert_eq(state.notes[0].size(), 1)
	state.round_number = 4
	state.add_note(3, 5001001, 7)
	assert_eq(state.notes.size(), 4, "AddNote grows the page list up to round - 1")
	assert_eq(state.notes[1].size(), 0, "skipped rounds keep empty pages")
	assert_eq(state.notes[3].size(), 1)


func test_setup_new_run_clears_notes() -> void:
	var state := GameState.new()
	state.round_number = 1
	state.add_note(1, 5001001, 7)
	state.setup_new_run(_local_db(), 1, RNG.new(1))
	assert_eq(state.notes.size(), 0, "a fresh run starts with an empty journal")


func test_rite_creation_and_lifecycle_write_notes() -> void:
	var local_db := _local_db()
	local_db.rites[994001] = {
		"id": 994001, "name": "Journal test", "open_conditions": [],
		"cards_slot": {"s1": {}},
		"round_number": 1, "waiting_round": 1, "waiting_round_end_action": [],
		"settlement_prior": [], "settlement": [], "settlement_extre": [],
		"auto_begin": 0, "auto_result": 0,
	}
	var state := GameState.new()
	state.setup_new_run(local_db, 1, RNG.new(2))
	# Type 1: creation through the rite result effect (StartRite chain).
	DeferredEffects.apply({"rite": 994001, "events": []}, state, local_db, RNG.new(3))
	var created_uid := 0
	for instance in state.available_rite_instances():
		if int(instance.id) == 994001:
			created_uid = int(instance.uid)
	assert_true(_page_has_note(state.notes[0], 1, created_uid),
		"rite creation journals type 1 with the instance id and uid")
	# Start it so the next day settles it -> type 3.
	var instance = state.get_rite_instance(created_uid)
	instance.start = true
	var day := RoundLoop.advance_day(state, local_db, RNG.new(4))
	assert_eq(day.settled_rites.size(), 1)
	assert_true(_page_has_note(state.notes[0], 3, created_uid), "settlement journals type 3")
	# A never-started rite expires at waiting_round -> type 2.
	DeferredEffects.apply({"rite": 994001, "events": []}, state, local_db, RNG.new(5))
	var second_uid := 0
	for candidate in state.available_rite_instances():
		if int(candidate.id) == 994001:
			second_uid = int(candidate.uid)
	var day2 := RoundLoop.advance_day(state, local_db, RNG.new(6))
	assert_eq(day2.expired_rites.size(), 1, "the unstarted rite expires")
	var joined_pages: Array = []
	for page in state.notes:
		joined_pages.append_array(page)
	assert_true(_page_has_note(joined_pages, 2, second_uid),
		"expiry journals type 2 for the expired instance")


func _page_has_note(page: Array, note_type: int, entry_uid: int) -> bool:
	for note in page:
		if note is Dictionary and int(note.get("type", 0)) == note_type and int(note.get("uid", 0)) == entry_uid:
			return true
	return false


func test_notes_round_trip_through_save() -> void:
	var local_db := _local_db()
	var state := GameState.new()
	state.round_number = 1
	state.add_note(10002, 2000368, 126, 1)
	state.add_note(1, 5001001, 1)
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, local_db)
	assert_eq(restored.notes, [[{"type": 10002, "id": 2000368, "uid": 126, "count": 1},
		{"type": 1, "id": 5001001, "uid": 1, "count": 0}]],
		"journal pages and int fields round-trip verbatim")


func test_importer_carries_notes_verbatim() -> void:
	if not FileAccess.file_exists(CORPUS_AUTO_SAVE):
		pending("corpus save sample not available; skipping")
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CORPUS_AUTO_SAVE))
	if not (parsed is Dictionary):
		pending("corpus save sample unreadable; skipping")
		return
	var imported: Dictionary = OriginalSaveImporter.import_save(parsed, _local_db())
	var state = imported["state"]
	assert_eq(state.notes.size(), 1, "the round-1 sample carries one page")
	assert_eq(state.notes[0].size(), 7, "with all seven entries")
	assert_eq(int(state.notes[0][0]["type"]), 10002, "the equipped-clothing reward note comes first")
	assert_eq(int(state.notes[0][0]["count"]), 1)
	var notes_row: Dictionary = {}
	for row in imported["report"]["diff"]:
		if str(row["check"]) == "notes":
			notes_row = row
	assert_true(bool(notes_row.get("pass", false)), "the journal imports without loss")
