extends GutTest

## The wizard (女术士) dialogue host behind the `magic_sudan` demonstration.
## The clone carries the two wizard nodes so the operation has a real host to
## target; the presentation itself is still unported.
## [SRC: _unpack/data/config/wizard/wizard.json + wizard_sudan.json;
##       MagicSudan.c @ .ctor 0x5153f0 -> Datapool.AddMagicSudan;
##       WizardController.c @ LoadWizard 0x5cbdf0 reads Datapool+0x40 by id.]


var db: ConfigDB


func before_each() -> void:
	db = ConfigDB.new()
	db.load_all()


func test_both_wizard_nodes_load_by_their_string_ids() -> void:
	# The wizard files key on a STRING id, so the int-keyed directory loader
	# would collapse both to 0 and silently drop one.
	assert_eq(db.wizard_config.size(), 2, "both wizard nodes are present")
	assert_true(db.wizard_config.has("WIZARD"), "wizard.json keeps its string id")
	assert_true(db.wizard_config.has("WIZARD_SUDAN"), "wizard_sudan.json keeps its string id")


func test_wizard_nodes_carry_the_draw_sudan_prompts() -> void:
	# WIZARD supplies all four; WIZARD_SUDAN leaves
	# prompt_draw_sudan_end_without_times empty in the original data, so the key
	# must exist but its value is allowed to be empty — do not "fix" content.
	for id in ["WIZARD", "WIZARD_SUDAN"]:
		var node: Dictionary = db.wizard_config[id]
		for key in [
			"prompt_draw_sudan_start",
			"prompt_draw_sudan_start_first",
			"prompt_draw_sudan_end_with_times",
			"prompt_draw_sudan_end_without_times",
		]:
			assert_true(node.has(key), "%s.%s is present in the source node" % [id, key])
		assert_false(str(node.get("prompt_draw_sudan_start", "")).is_empty(),
			"%s carries the next-draw prompt" % id)
		assert_false(str(node.get("name", "")).is_empty(), "%s names the speaker" % id)
		assert_false(str(node.get("text", "")).is_empty(), "%s carries dialogue" % id)
	assert_false(str(db.wizard_config["WIZARD"]["prompt_draw_sudan_end_without_times"]).is_empty(),
		"the first-draw node fills every prompt")
	assert_eq(str(db.wizard_config["WIZARD_SUDAN"]["prompt_draw_sudan_end_without_times"]), "",
		"WIZARD_SUDAN leaves that one prompt empty in the original content")


func test_magic_sudan_operation_has_reachable_config_instances() -> void:
	# Three authored events invoke `magic_sudan`; the host node must exist for
	# the directive to mean anything.
	var invocations := 0
	for event_id in db.events:
		var event: Dictionary = db.events[event_id]
		if JSON.stringify(event).contains("magic_sudan"):
			invocations += 1
	assert_gt(invocations, 0, "authored events invoke the magic_sudan directive")
	assert_false(db.wizard_config.is_empty(), "and the wizard host is loaded")
