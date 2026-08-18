extends SceneTree

## Save diff harness runner: analyze an original (corpus) save against the
## decoded Player schema and, optionally, compare it with a clone v5 save.
## Usage:
##   godot --headless --script tools/export_save_diff.gd -- \
##     --original <corpus_save.json> [--compare <clone_v5.json>] [--out <dir>]

const DEFAULT_ORIGINAL := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var original_path := _arg_value(args, "--original", DEFAULT_ORIGINAL)
	var compare_path := _arg_value(args, "--compare", "")
	var output_dir := _arg_value(args, "--out", "user://save_diff")

	var original := _load_json(original_path)
	if original.is_empty():
		push_error("Cannot read original save: %s" % original_path)
		quit(1)
		return
	var analysis: Dictionary = OriginalSaveSchema.analyze_save(original)

	var compare_rows: Array = []
	if compare_path != "":
		var clone := _load_json(compare_path)
		if clone.is_empty():
			push_error("Cannot read clone save: %s" % compare_path)
			quit(1)
			return
		compare_rows = OriginalSaveSchema.compare_clone(original, clone)

	var markdown: String = OriginalSaveSchema.to_markdown(analysis, compare_rows)
	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	var file := FileAccess.open("%s/save_diff.md" % output_dir, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save diff report")
		quit(1)
		return
	file.store_string(markdown)
	file.close()
	print(markdown)
	print("Save diff report exported to %s" % absolute_dir)
	quit(0 if analysis["unknown_fields"].is_empty() and analysis["type_mismatches"].is_empty() else 1)


func _arg_value(args: PackedStringArray, flag: String, fallback: String) -> String:
	for index in args.size() - 1:
		if args[index] == flag:
			return args[index + 1]
	return fallback


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
