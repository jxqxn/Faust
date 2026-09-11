extends GutTest

const Axis = preload("res://ui/source_layout_axis.gd")
const Prompt = preload("res://ui/event_prompt_view.gd")

func test_root_flexible_reserves_and_reverse_order() -> void:
	# Prefab root: Top min100/flex3500, Bottom min400/flex2000.
	var result := Axis.allocate(2160, [100, 450, 400], [100, 560, 400], [3500, 0, 2000])
	assert_almost_eq(result.sizes[0], 800.0, 0.001)
	assert_almost_eq(result.positions[1], 800.0, 0.001)
	assert_almost_eq(result.sizes[2], 800.0, 0.001)
	var horizontal := Axis.allocate(2705, [0, 0], [0, 2000], [0, 0], 100, 200, 100, 0.5, true)
	assert_eq(horizontal.positions[1], 352.5, "reverse ContentGroup before empty IconGroup")
	assert_eq(horizontal.positions[0], 2452.5)
	var crowded := Axis.allocate(2160, [100, 450, 400], [100, 2000, 400], [3500, 0, 2000])
	assert_eq(crowded.sizes, [100.0, 1660.0, 400.0], "preferred sizes shrink before minimum reserves")

func test_choice_width_tracks_active_native_portraits() -> void:
	var view := Prompt.new()
	view.size = Vector2(3840, 2160)
	add_child_autofree(view)
	var portrait := preload("res://assets/original/cards/1_char_7.png")
	for count in range(4):
		var slots: Array = [null, null, null]
		for i in count:
			slots[i] = {"texture": portrait}
		view.show_prompt({"text": "请作出选择", "choices": {"甲": 1, "乙": 2, "丙": 3},
			"resolved_icons": {"slots": slots}}, Callable())
		await wait_process_frames(3)
		var body: Control = view.get("_body")
		assert_eq(body.size.x, [2000.0, 1905.0, 1705.0, 1505.0][count])
		var rows: Control = view.get("_options_box")
		assert_eq(rows.get_child(0).size.y, 112.0)
		assert_almost_eq(rows.get_child(1).position.y - rows.get_child(0).position.y, 132.0, 0.001)
		assert_eq(rows.get_child(0).size.x, body.size.x)
		for slot in view.get("_icon_slots"):
			if not slot.visible:
				continue
			var image := slot.get_child(0) as TextureRect
			assert_eq(image.size, portrait.get_size(), "SetNativeSize does not squeeze portraits into400x500")

func test_body_overflow_respects_root_reserves_and_choice_completion() -> void:
	var view := Prompt.new()
	view.size = Vector2(3840, 2160)
	add_child_autofree(view)
	watch_signals(view)
	view.show_prompt({"text": "很长的一行正文。\n".repeat(100), "choices": {"甲": 1, "乙": 2, "丙": 3}}, Callable())
	await wait_process_frames(4)
	var panel: Control = view.get("_panel")
	var body: RichTextLabel = view.get("_body")
	assert_almost_eq(panel.position.y, 100.0, 0.01)
	assert_almost_eq(panel.size.y, 1660.0, 0.01)
	assert_lte(body.size.y, 1100.0)
	assert_gt(float(body.get_content_height()), body.size.y)
	var confirm: Button = view.get("_confirm_button")
	assert_true(confirm.disabled)
	var row: Button = view.get("_options_box").get_child(1)
	row.pressed.emit()
	assert_false(confirm.disabled)
	assert_signal_not_emitted(view, "choice_clicked")
	confirm.pressed.emit()
	assert_signal_emit_count(view, "choice_clicked", 1)

func test_confirm_body_does_not_inherit_scroll_watcher_cap() -> void:
	# ConfirmNew has no ScrollViewContentHightWatcher; ContentSizeFitter owns height.
	var view := Prompt.new()
	view.size = Vector2(3840, 2160)
	add_child_autofree(view)
	view.show_prompt({"text": "确认正文\n".repeat(30), "presentation": "confirm",
		"choices": {"confirm_ok": "确定", "confirm_cancel": "取消"}}, Callable())
	await wait_process_frames(4)
	var body: RichTextLabel = view.get("_body")
	assert_gt(body.size.y, 1300.0)
	assert_almost_eq(body.size.y, float(body.get_content_height()), 0.001)
