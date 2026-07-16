## The sole settlement receipt exposed to the calendar mode UI.
class_name ActionResult
extends RefCounted

var ok: bool = false
var message: String = ""
var failure_reason: String = ""
var consumed_periods: Array = []
var state_changes: Array = []
var generated_opportunity_ids: Array = []
var history_id: String = ""


func _init(success: bool = false, result_message: String = "") -> void:
	ok = success
	message = result_message


static func success(result_message: String, periods: Array = [], changes: Array = [], generated_ids: Array = [], new_history_id: String = ""):
	var result = load("res://modes/calendar_coop/model/action_result.gd").new(true, result_message)
	result.consumed_periods = periods.duplicate(true)
	result.state_changes = changes.duplicate(true)
	result.generated_opportunity_ids = generated_ids.duplicate(true)
	result.history_id = new_history_id
	return result


static func failure(reason: String, result_message: String = ""):
	var result = load("res://modes/calendar_coop/model/action_result.gd").new(false, result_message)
	result.failure_reason = reason
	return result


func to_dict() -> Dictionary:
	return {
		"ok": ok,
		"message": message,
		"failure_reason": failure_reason,
		"consumed_periods": consumed_periods.duplicate(true),
		"state_changes": state_changes.duplicate(true),
		"generated_opportunity_ids": generated_opportunity_ids.duplicate(true),
		"history_id": history_id,
	}


static func from_dict(data: Dictionary):
	var result = load("res://modes/calendar_coop/model/action_result.gd").new(bool(data.get("ok", false)), str(data.get("message", "")))
	result.failure_reason = str(data.get("failure_reason", ""))
	result.consumed_periods = data.get("consumed_periods", []).duplicate(true) if data.get("consumed_periods", []) is Array else []
	result.state_changes = data.get("state_changes", []).duplicate(true) if data.get("state_changes", []) is Array else []
	result.generated_opportunity_ids = data.get("generated_opportunity_ids", []).duplicate(true) if data.get("generated_opportunity_ids", []) is Array else []
	result.history_id = str(data.get("history_id", ""))
	return result
