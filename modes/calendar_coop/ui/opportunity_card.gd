class_name CalendarOpportunityCard
extends PanelContainer

signal chosen(opportunity)

var opportunity


func setup(value, display_name: String) -> void:
	opportunity = value
	name = "Opportunity_%s" % value.opportunity_id
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var title := Label.new()
	title.text = display_name
	title.add_theme_font_size_override("font_size", 16)
	box.add_child(title)
	var details := Label.new()
	details.text = "%s · %s" % [value.period, value.kind]
	box.add_child(details)
	if not value.lock_reason.is_empty():
		var reason := Label.new()
		reason.text = value.lock_reason
		reason.name = "LockReason"
		box.add_child(reason)
	var button := Button.new()
	button.name = "ChooseButton"
	button.text = "选择"
	button.disabled = not value.lock_reason.is_empty() or value.kind == "fixed"
	button.pressed.connect(func(): chosen.emit(opportunity))
	box.add_child(button)
