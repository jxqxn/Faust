extends GutTest

const ContentRepository = preload("res://modes/calendar_coop/services/content_repository.gd")


func test_repository_loads_complete_eight_day_content_and_returns_copies() -> void:
	var repository = ContentRepository.new()
	assert_true(repository.load_all(), "the checked-in calendar content should validate")
	assert_eq(repository.get_calendar().get("days", []).size(), 8)
	assert_eq(repository.get_case("museum_case").get("deadline_day", 0), 8)
	assert_eq(repository.get_character("network").get("progression_source", ""), "resolved_requests")
	assert_eq(repository.get_action("station_request_run").get("kind", ""), "request_run")
	assert_eq(repository.get_action("museum_key_action").get("phase_transition", {}).get("to", ""), "route_confirmed")

	var action := repository.get_action("mentor_rank_1")
	action["display_name"] = "mutated"
	assert_ne(repository.get_action("mentor_rank_1").get("display_name", ""), "mutated", "callers cannot mutate repository content")


func test_repository_rejects_duplicate_ids_and_unknown_action_kinds() -> void:
	var repository = ContentRepository.new()
	var content := _valid_content()
	content["cards"]["cards"].append({"id": "crowd_clue", "display_name": "Duplicate", "kind": "support", "tags": []})
	content["actions"]["actions"][0]["kind"] = "freeform_effect"

	assert_false(repository.validate_content(content))
	assert_true(_has_error(repository.get_errors(), "duplicate card id: crowd_clue"))
	assert_true(_has_error(repository.get_errors(), "unknown kind: freeform_effect"))


func test_repository_rejects_missing_visible_fields_and_invalid_action_schedule() -> void:
	var repository = ContentRepository.new()
	var content := _valid_content()
	content["actions"]["actions"][0].erase("display_name")
	content["actions"]["actions"][0].erase("day")
	content["actions"]["actions"][0]["period"] = "morning"
	content["actions"]["actions"][0]["effect"] = "arbitrary mutation"

	assert_false(repository.validate_content(content))
	assert_true(_has_error(repository.get_errors(), "action mentor_rank_1 is missing display_name"))
	assert_true(_has_error(repository.get_errors(), "action mentor_rank_1 has an invalid or missing day"))
	assert_true(_has_error(repository.get_errors(), "action mentor_rank_1 has an invalid or missing period"))
	assert_true(_has_error(repository.get_errors(), "action mentor_rank_1 has an unknown field: effect"))


func test_repository_rejects_unknown_references_and_illegal_case_transitions() -> void:
	var repository = ContentRepository.new()
	var content := _valid_content()
	var heist: Dictionary = content["actions"]["actions"][1]
	heist["case_id"] = "missing_case"
	heist["required_cards"].append("missing_card")
	heist["phase_transition"] = {"from": "intel", "to": "route_confirmed", "bypass": true}

	assert_false(repository.validate_content(content))
	assert_true(_has_error(repository.get_errors(), "heist action museum_scout case_id references unknown case missing_case"))
	assert_true(_has_error(repository.get_errors(), "action museum_scout required_cards references unknown card or character missing_card"))
	assert_true(_has_error(repository.get_errors(), "heist action museum_scout has an illegal case phase transition"))
	assert_true(_has_error(repository.get_errors(), "heist action museum_scout phase_transition has an unknown field: bypass"))


func _valid_content() -> Dictionary:
	var repository = ContentRepository.new()
	assert_true(repository.load_all())
	return repository.content.duplicate(true)


func _has_error(errors: Array, fragment: String) -> bool:
	return errors.any(func(message): return str(message).contains(fragment))
