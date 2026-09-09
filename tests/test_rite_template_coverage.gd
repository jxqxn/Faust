extends GutTest

const RiteView = preload("res://ui/rite_view.gd")

func test_every_configured_rite_mapping_has_renderable_slots():
	var mappings: Dictionary = RiteView._load_json("res://content/rite_template_mappings.json")
	var failures: Array[String] = []
	var count := 0
	for file in DirAccess.get_files_at("res://content/rite"):
		if not file.ends_with(".json"):
			continue
		var rite: Dictionary = RiteView._load_json("res://content/rite/" + file)
		var mapping: Dictionary = RiteView._resolved_mapping(rite)
		var template: Dictionary = RiteView._load_json("res://content/rite_template/%d.json" % int(mapping.template_id))
		var keys: Array = rite.get("cards_slot", {}).keys()
		if keys.size() > mapping.get("slot_open", []).size():
			failures.append("%s: %d slots exceed mapping %s" % [file, keys.size(), rite.get("mapping_id", 0)])
		for i in mini(keys.size(), mapping.get("slot_open", []).size()):
			if not template.slots.has(mapping.slot_open[i]):
				failures.append("%s: missing mapped slot %s" % [file, mapping.slot_open[i]])
		count += 1
	assert_eq(failures, [] as Array[String], "all rite slot mappings resolve: " + str(failures))
	assert_eq(count, 1495, "entire current rite corpus inspected")

func test_every_template_builds_with_source_transforms_and_layers():
	var mappings: Dictionary = RiteView._load_json("res://content/rite_template_mappings.json")
	var failures: Array[String] = []
	var count := 0
	for file in DirAccess.get_files_at("res://content/rite_template"):
		if not file.ends_with(".json"):
			continue
		var template: Dictionary = RiteView._load_json("res://content/rite_template/" + file)
		var mapping_key := ""
		for key in mappings:
			if int(mappings[key].template_id) == int(template.id):
				mapping_key = key
				break
		if mapping_key.is_empty():
			# Unreferenced templates have no page route; still verify their assets.
			if not ResourceLoader.exists("res://assets/original/ui/rite_bg/%s.png" % template.bg):
				failures.append(file + ": unreferenced background missing")
			count += 1
			continue
		var view := RiteView.new()
		view._rite = {"mapping_id": int(mapping_key), "name": "模板普查", "cards_slot": {}}
		var slots: Array = []
		for key in mappings[mapping_key].slot_open:
			if not template.slots.has(key):
				break
			slots.append(key)
		for i in slots.size():
			view._rite.cards_slot["s%d" % (i + 1)] = {}
		view.size = Vector2(3840, 2160)
		view._build_ui()
		view._apply_layout()
		for i in slots.size():
			var authored: Dictionary = template.slots[slots[i]]
			var button: Control = view._slot_buttons["s%d" % (i + 1)]
			var expected_scale := Vector2(float(authored.scale.x), float(authored.scale.y))
			if not button.scale.is_equal_approx(expected_scale) or button.size != Vector2(272, 496):
				failures.append(file + ": slot scale/size")
			if button.pivot_offset != Vector2(136, 248):
				failures.append(file + ": rotation pivot")
			var background: TextureRect = button.get_node("SlotBackground")
			if background.texture == null:
				failures.append(file + ": missing slot texture")
		if template.get("fg") != null and template.get("fg") != "":
			if view._template_foreground == null:
				failures.append(file + ": missing foreground")
			elif int(template.get("fg_in_slot_index", 0)) > 0:
				if view._template_foreground.get_parent() != view._slot_layer or view._template_foreground.get_index() != int(template.fg_in_slot_index):
					failures.append(file + ": foreground sibling index")
		if view._rite_panel.get_node("RiteHelpButton").visible == bool(template.get("title_help_btn_hide", false)):
			failures.append(file + ": help visibility")
		view.free()
		count += 1
	assert_eq(failures, [] as Array[String], "all template render branches: " + str(failures))
	assert_eq(count, 251, "entire current template corpus built")
