extends SceneTree

const RiteView = preload("res://ui/rite_view.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var mappings: Dictionary = RiteView._load_json("res://content/rite_template_mappings.json")
	var examples := {}
	for file in DirAccess.get_files_at("res://content/rite"):
		if file.ends_with(".json"):
			var rite: Dictionary = RiteView._load_json("res://content/rite/" + file)
			var entry: Dictionary = RiteView._resolved_mapping(rite)
			var key := str(int(entry.template_id))
			if not examples.has(key):
				examples[key] = rite
	var output := "res://docs/ui_layout/rite_templates"
	DirAccess.make_dir_recursive_absolute(output)
	var rows: Array = []
	for file in DirAccess.get_files_at("res://content/rite_template"):
		if not file.ends_with(".json"):
			continue
		var template: Dictionary = RiteView._load_json("res://content/rite_template/" + file)
		var key := str(int(template.id))
		var example: Dictionary = examples.get(key, {})
		if example.is_empty():
			for mapping_key in mappings:
				if int(mappings[mapping_key].template_id) == int(template.id):
					example = {"mapping_id": int(mapping_key), "name": "模板 " + key, "cards_slot": {}}
					for slot in mappings[mapping_key].slot_open:
						if not template.slots.has(slot):
							break
						example.cards_slot["s%d" % (example.cards_slot.size() + 1)] = {}
					break
		if example.is_empty():
			rows.append({"template": key, "status": "unreferenced"})
			continue
		var view := RiteView.new()
		view._rite = example
		root.add_child(view)
		view.set_anchors_preset(Control.PRESET_TOP_LEFT)
		view.size = Vector2(960, 540)
		view._apply_layout()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output + "/" + key + ".png")
		rows.append({"template": key, "rite": int(example.get("id", 0)), "name": example.name, "status": "rendered"})
		view.free()
		await process_frame
	var manifest := FileAccess.open(output + "/manifest.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify(rows, "\t"))
	manifest.close()
	print("TEMPLATE_CAPTURE ", rows.size())
	FaustTheme.clear_cache()
	await process_frame
	quit()
