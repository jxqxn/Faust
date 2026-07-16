class_name CalendarPrototypeCardWidget
extends PanelContainer


func setup(card_id: String, label_text: String = "") -> void:
	name = "Card_%s" % card_id
	var label := Label.new()
	label.text = label_text if not label_text.is_empty() else card_id
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
