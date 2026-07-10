extends SceneTree

## Export the current config DSL coverage to files that can be reviewed in CI
## or attached to an implementation task. Defaults to user://dsl_audit so a
## normal audit run never changes tracked project content.

func _init() -> void:
	var output_dir := _output_dir()
	var db := ConfigDB.new()
	db.load_all()
	var report := DslAudit.audit_configs(db.rites, db.events, db.loots, db)
	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	_write("%s/dsl_audit.json" % output_dir, DslAudit.to_json(report))
	_write("%s/dsl_audit.md" % output_dir, DslAudit.to_markdown(report, 100))
	print("DSL audit exported to %s" % absolute_dir)
	quit()


func _output_dir() -> String:
	var args := OS.get_cmdline_user_args()
	for index in args.size() - 1:
		if args[index] == "--out" and index + 1 < args.size():
			return str(args[index + 1])
	return "user://dsl_audit"


func _write(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write DSL audit: %s" % path)
		return
	file.store_string(content)
	file.close()
