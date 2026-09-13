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
	var overflow := Axis.allocate(0, [100], [100], [0], 0, 0, 0, 1)
	assert_eq(overflow.positions[0], 0.0, "source main-axis overflow does not apply negative bottom alignment")

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
		assert_eq(body.size.x, [1970.0, 1875.0, 1675.0, 1475.0][count])
		var rows: Control = view.get("_options_box")
		assert_eq(rows.get_child(0).size.y, 112.0)
		assert_almost_eq(rows.get_child(1).position.y - rows.get_child(0).position.y, 132.0, 0.001)
		assert_eq(rows.get_child(0).size.x, body.size.x + 30.0)
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

func test_prompt_body_scrollbar_uses_source_art_and_width() -> void:
	var view := Prompt.new()
	view.size = Vector2(3840, 2160)
	add_child_autofree(view)
	view.show_prompt({"text": "正文\n".repeat(100), "choices": {"甲": 1}}, Callable())
	await wait_process_frames(4)
	var body := view.get("_body") as RichTextLabel
	var scrollbar = view.get("_source_scrollbar")
	assert_eq(scrollbar.track_rect.size.x, 6.0, "source track width")
	var track := scrollbar.get("_track") as StyleBoxTexture
	var thumb := scrollbar.get("_thumb") as StyleBoxTexture
	assert_not_null(track, "PromptNew track style is explicit")
	assert_not_null(thumb, "PromptNew thumb style is explicit")
	assert_true(track.texture.resource_path.ends_with("scroll_bar.png"))
	assert_true(thumb.texture.resource_path.ends_with("scroll_thumb.png"))
	assert_eq(track.texture_margin_top, 212.0, "Unity border.w is the track top slice")
	assert_eq(track.texture_margin_bottom, 171.0, "Unity border.y is the track bottom slice")
	assert_eq(thumb.texture_margin_left, 9.0, "PromptNew keeps the source thumb side slices")
	assert_eq(thumb.texture_margin_top, 58.0, "Unity border.w is the thumb top slice")
	assert_eq(thumb.texture_margin_bottom, 77.0, "Unity border.y is the thumb bottom slice")
	assert_true(scrollbar.visible, "source AutoHide scrollbar is visible when body overflows")

	view.show_prompt({"text": "短正文", "choices": {"甲": 1}}, Callable())
	await wait_process_frames(4)
	assert_false(view.get("_source_scrollbar").visible, "source AutoHide scrollbar hides without overflow")

	# PromptNew's plain confirm/continue surface also owns the ScrollRect, but
	# a single-line body never overflows it. This is the boundary that exposed
	# the stray bright vertical bar in the runtime screenshot.
	view.show_prompt({"text": "好吧，如果遇到不知道怎么使用的牌，就拖到这里来，让俺寻思寻思。"}, Callable())
	await wait_process_frames(4)
	assert_false(view.get("_source_scrollbar").visible, "plain one-line prompt hides the source scrollbar")

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

func test_scroll_input_and_short_prompt_rebuild_at_two_sizes() -> void:
	for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		var viewport := SubViewport.new()
		viewport.size = resolution
		add_child_autofree(viewport)
		var view := Prompt.new()
		viewport.add_child(view)
		view.show_prompt({"text": "滚动输入边界\n".repeat(100)}, Callable())
		await wait_process_frames(5)
		var body: RichTextLabel = view.get("_body")
		var hits: Array = []
		body.gui_input.connect(func(event):
			if event is InputEventMouseButton:
				hits.append(event.button_index))
		var point := body.get_global_transform_with_canvas() * (body.size * 0.5)
		var motion := InputEventMouseMotion.new()
		motion.position = point
		viewport.push_input(motion, true)
		var wheel := InputEventMouseButton.new()
		wheel.position = point
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		viewport.push_input(wheel, true)
		wheel.pressed = false
		viewport.push_input(wheel, true)
		await wait_process_frames(3)
		assert_true(hits.has(MOUSE_BUTTON_WHEEL_DOWN), "wheel hits the text viewport at %s" % resolution)
		assert_gt(body.get_v_scroll_bar().value, 0.0, "wheel actually moves the content")
		var scrollbar = view.get("_source_scrollbar")
		assert_eq(scrollbar.handle_rect.size.x, 27.0, "authored handle is wider than the track")
		assert_almost_eq(scrollbar.position.x + scrollbar.track_rect.position.x,
			body.position.x + body.size.x + 34.0, 0.001, "viewport -30 plus source track right+4")
		point = scrollbar.get_global_transform_with_canvas() * scrollbar.handle_rect.get_center()
		motion.position = point
		viewport.push_input(motion, true)
		await wait_process_frames(2)
		assert_eq(viewport.gui_get_hovered_control(), scrollbar, "expanded handle is the real pointer target")
		var press := InputEventMouseButton.new()
		press.position = point
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		viewport.push_input(press, true)
		assert_true(scrollbar.get("_dragging"), "pointer press starts handle drag")
		await wait_seconds(0.12)
		assert_almost_eq(scrollbar.get("_tint").r, 200.0 / 255.0, 0.001, "pressed tint completes source0.1-second transition")
		var bottom: Vector2 = scrollbar.get_global_transform_with_canvas() * Vector2(13.5, scrollbar.size.y - scrollbar.handle_rect.size.y * 0.5)
		motion.position = bottom
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		viewport.push_input(motion, true)
		press.position = bottom
		press.pressed = false
		viewport.push_input(press, true)
		await wait_process_frames(3)
		assert_almost_eq(body.get_v_scroll_bar().value,
			body.get_v_scroll_bar().max_value - body.get_v_scroll_bar().page, 1.0,
			"real drag reaches the bottom of the text range")
		assert_false(scrollbar.get("_dragging"), "release clears drag capture")
		view.show_prompt({"text": "短正文"}, Callable())
		await wait_process_frames(5)
		assert_false(view.get("_source_scrollbar").visible, "no stale scrollbar after long-to-short switch")
		viewport.remove_child(view)
		view.free()
		view = Prompt.new()
		viewport.add_child(view)
		view.show_prompt({"text": "短正文"}, Callable())
		await wait_process_frames(5)
		assert_false(view.get("_source_scrollbar").visible, "rebuilt prompt remains free of the bar")

func test_original_market_emphasis_is_larger_and_uses_title_font() -> void:
	var config = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/event/5300098.json"))
	var prompt = SourceJSON.member(SourceJSON.member(config.settlement[0].action, "success"), "prompt")
	# GameScreen normally resolves the source string before calling this view.
	# Keep this isolated body test on the same display contract.
	prompt.erase("icon")
	var view := Prompt.new()
	add_child_autofree(view)
	view.show_prompt(prompt, Callable())
	await wait_process_frames(5)
	var body: RichTextLabel = view.get("_body")
	assert_string_contains(body.text, "[font_size=%d]" % (body.get_theme_font_size("normal_font_size") + 10))
	assert_string_contains(body.text, "[b][font=res://assets/fonts/XiQueGuZiDianTiJFT.ttf]")
	assert_false(body.text.contains("[font_size=+10]"), "signed TMP size must not become a tiny absolute size")
	assert_false(body.get_parsed_text().contains("<font="), "source font markup is not visible text")
	assert_false(view.get("_source_scrollbar").visible, "observed original market prompt has no scrollbar")
	var preferences = preload("res://ui/game_application_settings.gd")
	var previous: String = preferences.font_size
	preferences.events.font_size_changed.emit("xxl")
	await wait_process_frames(4)
	assert_string_contains(body.text, "[font_size=85]", "open relative text follows the75-point source setting")
	preferences.events.font_size_changed.emit(previous)


func test_market_sprite_region_native_size_and_source_layout_chain() -> void:
	var texture = preload("res://ui/source_prompt_icons.gd")._texture("common/position_shangye_1")
	assert_true(texture is AtlasTexture)
	assert_almost_eq(texture.region.size.x, 1036.9398, 0.001)
	assert_almost_eq(texture.region.position.y, 744.0 - 35.051315 - 701.89734, 0.001)
	var view := Prompt.new()
	add_child_autofree(view)
	view.show_prompt({"text": "一段\n二段", "resolved_icons": {"slots": [null, {"texture": texture}, null]}}, Callable())
	await wait_process_frames(5)
	var body: RichTextLabel = view.get("_body")
	assert_eq(body.get_theme_constant("paragraph_separation"), roundi(body.get_theme_font_size("normal_font_size") * .69))
	var portrait: TextureRect = view.get("_portrait")
	assert_almost_eq(portrait.size.x, 1036.9398, 0.001, "native width comes from Sprite.rect, not 1148px backing PNG")
	assert_almost_eq(portrait.size.y, 701.89734, 0.001)
	assert_almost_eq(portrait.get_parent().position.y, view.get("_panel").size.y - 50.0, .001, "parent padding200 + centered Pos50 + overflowing Holder100")
