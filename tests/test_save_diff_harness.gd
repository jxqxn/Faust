extends GutTest

## Save diff harness tests: the decoded original-save schema must stay total
## (every corpus Player field classified) and the analyzer must accept the real
## corpus save sample. Corpus-dependent tests skip gracefully when the
## read-only corpus is absent.

const CORPUS_SAVE := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"

var _corpus_available: bool:
	get:
		return FileAccess.file_exists(CORPUS_SAVE)


func test_schema_is_total_over_player_class() -> void:
	# dump.cs Player (TypeDefIndex 6274) declares 60 serializable fields,
	# exactly matching the corpus auto_save.json top-level key count.
	assert_eq(OriginalSaveSchema.ORIGINAL_FIELDS.size(), 60)
	var counts: Dictionary = OriginalSaveSchema.status_counts()
	assert_eq(counts["mapped"] + counts["semantic"] + counts["missing"], 60)
	for field in OriginalSaveSchema.ORIGINAL_FIELDS:
		var meta: Dictionary = OriginalSaveSchema.ORIGINAL_FIELDS[field]
		assert_true(meta.has("type"), "%s needs a model type" % field)
		assert_true(meta["status"] in ["mapped", "semantic", "missing"], "%s has bad status" % field)


func test_clone_only_fields_are_documented() -> void:
	for field in OriginalSaveSchema.CLONE_ONLY_FIELDS:
		assert_true(String(OriginalSaveSchema.CLONE_ONLY_FIELDS[field]).length() > 3, "%s needs a note" % field)
		assert_not_null(field)
	# Envelope fields must stay classified as acceptable.
	for field in OriginalSaveSchema.ENVELOPE_FIELDS:
		assert_true(OriginalSaveSchema.CLONE_ONLY_FIELDS.has(field), "%s should stay documented" % field)


func test_gold_model_divergence_is_recorded() -> void:
	# Structural finding: original gold = stacked card 2000029 count
	# (GenCoin.c Do 0x510b40 double signal); the clone coin_count scalar is
	# drift and must stay flagged until the card-stack model lands.
	assert_true(OriginalSaveSchema.CLONE_ONLY_FIELDS.has("coin_count"))
	assert_true(String(OriginalSaveSchema.CLONE_ONLY_FIELDS["coin_count"]).contains("2000029"))


func test_analyze_save_accepts_synthetic_player() -> void:
	var save := {
		"round": 3.0,
		"difficulty": 1.0,
		"cards": [],
		"rites": [],
		"counter": {},
		"ithink_card": null,
		"success": false,
	}
	var analysis: Dictionary = OriginalSaveSchema.analyze_save(save)
	assert_eq(analysis["unknown_fields"], [])
	assert_eq(analysis["type_mismatches"], [])
	assert_eq(analysis["fields_present"], 7)


func test_analyze_save_flags_unknown_and_mismatched() -> void:
	var analysis: Dictionary = OriginalSaveSchema.analyze_save({"round": "not-a-number", "self_made_field": 1})
	assert_eq(analysis["unknown_fields"], ["self_made_field"])
	assert_eq(analysis["type_mismatches"].size(), 1)


func test_compare_clone_reports_absent_and_differs() -> void:
	var original := {"round": 5.0, "difficulty": 1.0, "card_uid_index": 9.0, "counter": {"a": 1.0}}
	var clone := {"round_number": 5.0, "difficulty_index": 0.0, "next_card_uid": 9.0}
	var rows: Array = OriginalSaveSchema.compare_clone(original, clone)
	var by_field := {}
	for row in rows:
		by_field[row["field"]] = row
	assert_eq(by_field["round"]["verdict"], "equal")
	assert_eq(by_field["difficulty"]["verdict"], "differs")
	assert_eq(by_field["card_uid_index"]["verdict"], "equal")
	assert_eq(by_field["counter"]["verdict"], "absent")


func test_corpus_sample_passes_schema_analysis() -> void:
	if not _corpus_available:
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CORPUS_SAVE))
	assert_true(parsed is Dictionary, "corpus save must parse as JSON object")
	var analysis: Dictionary = OriginalSaveSchema.analyze_save(parsed)
	assert_eq(analysis["unknown_fields"], [], "every corpus field must be known to the schema")
	assert_eq(analysis["type_mismatches"], [], "every corpus field must match its model type")
	assert_eq(analysis["fields_present"], 60)
