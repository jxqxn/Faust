extends "res://tools/verify_prompt_preferred_layout.gd"

const Preferences = preload("res://ui/game_application_settings.gd")
var selections: Array = []

func run() -> void:
	var view := preload("res://ui/event_prompt_view.gd").new()
	view.size = Vector2(3840, 2160)
	root.add_child(view)
	view.choice_clicked.connect(func(key, value): selections.append([key, value]))
	var portrait := preload("res://assets/original/cards/1_char_7.png")
	for count in range(4):
		var slots: Array = [null, null, null]
		for i in count:
			slots[i] = {"texture": portrait}
		view.show_prompt({"text": "宫廷中的选择\n每一个决定都将影响接下来的故事。", "choices": {
			"a": {"text": "留下来听听他们的计划", "value": 1},
			"b": {"text": "询问另一位随从", "value": 2},
			"c": {"text": "暂时离开", "value": 3}}, "resolved_icons": {"slots": slots}}, Callable())
		await settle()
		var rows: Control = view.get("_options_box")
		var confirm: Button = view.get("_confirm_button")
		await click(confirm)
		if selections.size() != count:
			failures.append("unselected choice submitted")
		await click(rows.get_child(0))
		await click(rows.get_child(1))
		await capture("event_icons_%d" % count)
		await click(confirm)
		await click(confirm)
		if selections.size() != count + 1 or selections.back() != ["b", 2]:
			failures.append("selection/change/confirm failed for %d portraits" % count)
	view.show_prompt({"text": "这是一段需要滚动查看的长正文。\n".repeat(100), "choices": {"a": "继续", "b": "返回"}}, Callable())
	await settle()
	var body: RichTextLabel = view.get("_body")
	var wheel := InputEventMouseButton.new()
	wheel.position = body.get_global_transform_with_canvas() * (body.size * 0.5)
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	root.push_input(wheel, true)
	await settle()
	if body.get_v_scroll_bar().value <= 0:
		failures.append("long body wheel input unreachable")
	await capture("event_long")
	for font_class in ["xs", "xxl"]:
		Preferences.events.font_size_changed.emit(font_class)
		await settle()
		if body.position.y + body.size.y > view.get("_options_box").get_child(0).position.y:
			failures.append("font preference overlaps choices")
	Preferences.events.font_size_changed.emit(Preferences.font_size)
	view.queue_free()
	await settle()
	if failures.is_empty():
		print("EVENT_PROMPT_INPUT: PASS")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
