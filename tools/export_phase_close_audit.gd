extends SceneTree

## Read-only original-save audit. Same-instant equality is deliberately NOT
## reported as transition/settlement equivalence. Missing judges fail closed.
const CORPUS := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples"

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Usage: --script tools/export_phase_close_audit.gd -- <output.json>")
		quit(1)
		return
	var db := ConfigDB.new()
	db.load_all()
	var report := {"schema_version": 1, "scope": "same_instant_import_and_clone_roundtrip",
		"settlement_equivalence": "NOT_VERIFIED", "samples": [], "errors": []}
	for filename in ["auto_save.json", "save_slot_000.json"]:
		var path := CORPUS.path_join(filename)
		var original = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not original is Dictionary or not original.get("cards") is Array or not original.get("rites") is Array:
			report.errors.append("Missing or invalid original Player sample: " + path)
			continue
		var imported := OriginalSaveImporter.import_save(original, db)
		var restored := GameState.new()
		# Include actual JSON encoding/decoding, not just an in-memory dictionary.
		SaveSystem.deserialize(JSON.parse_string(JSON.stringify(SaveSystem.serialize(imported.state))), restored, db)
		var rows := OriginalSaveImporter.diff_against_original(original, restored)
		var failures: Array = []
		for row in imported.report.diff + rows:
			if not row.pass:
				failures.append(row)
		if not failures.is_empty():
			report.errors.append("Value differences: " + filename)
		report.samples.append({"file": filename, "sha256": FileAccess.get_sha256(path),
			"original_round": original.get("round"), "import": imported.report,
			"json_roundtrip_diff": rows, "failures": failures,
			"random_cache": original.get("random_cache"), "delay_ops": original.get("delay_ops")})
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	if file == null:
		printerr("Cannot write audit: ", args[0])
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("PHASE_CLOSE_SNAPSHOT: samples=", report.samples.size(), " errors=", report.errors.size(),
		" settlement_equivalence=NOT_VERIFIED")
	quit(0 if report.errors.is_empty() and report.samples.size() == 2 else 1)
