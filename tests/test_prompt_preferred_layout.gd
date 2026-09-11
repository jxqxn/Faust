extends GutTest

const Rename = preload("res://ui/change_name_view.gd")
const Confirm = preload("res://ui/source_confirm_dialog.gd")
const Preferences = preload("res://ui/game_application_settings.gd")


func test_rename_validation_and_enter_preserve_source_editing_boundary() -> void:
	var view := Rename.new()
	view.size = Vector2(3840, 2160)
	add_child_autofree(view)
	watch_signals(view)
	await wait_process_frames(3)
	var input := view.find_child("CardRenameInput", true, false) as LineEdit
	var confirm := view.find_child("CardRenameConfirmButton", true, false) as Button
	var error := view.find_child("ContentInvalidPrompt", true, false) as Label
	assert_true(confirm.disabled, "empty input disables confirmation")
	assert_eq(error.text, "", "empty name clears the illegal-name message")
	input.text = "a".repeat(21)
	await wait_process_frames(2)
	assert_eq(input.text.length(), 21, "do not truncate what the user typed")
	assert_true(confirm.disabled)
	assert_eq(error.text, "当前名字无法使用，请尝试其他名称。")
	input.text = "😀".repeat(10)
	await wait_process_frames(2)
	assert_false(confirm.disabled, "ten surrogate pairs are exactly20 UTF-16 units")
	input.text += "a"
	await wait_process_frames(2)
	assert_true(confirm.disabled, "eleven codepoints can exceed20 UTF-16 units")
	input.text = " A "
	await wait_process_frames(2)
	input.grab_focus()
	view._confirm(input.text)
	assert_signal_not_emitted(view, "submitted", "editing gate precedes confirmation")
	input.text_submitted.emit(input.text)
	await wait_process_frames(2)
	assert_true(confirm.has_focus(), "Enter selects Confirm without submitting")
	assert_signal_not_emitted(view, "submitted")
	confirm.pressed.emit()
	assert_signal_emitted_with_parameters(view, "submitted", [" A "])
	input.text = " "
	await wait_process_frames(2)
	assert_false(confirm.disabled, "whitespace is not an empty string")
	input.text = ""
	await wait_process_frames(2)
	assert_true(confirm.disabled)
	assert_eq(error.text, "")


func test_rename_input_replays_text_area_and_independent_placeholder() -> void:
	var view := Rename.new()
	view.size = Vector2(3840, 2160)
	add_child_autofree(view)
	await wait_process_frames(3)
	var input := view.find_child("CardRenameInput", true, false) as LineEdit
	var placeholder := view.find_child("InputPlaceholder", true, false) as Label
	var background := view.find_child("InputBackground", true, false) as TextureRect
	assert_eq(input.size, Vector2(826, 90), "input hit area remains the full source root")
	var style := input.get_theme_stylebox("normal")
	assert_eq(Vector4(style.content_margin_left, style.content_margin_top,
		style.content_margin_right, style.content_margin_bottom), Vector4(10, 7, 10, 6),
		"source TextArea anchors and pivot; no invented 40/20 text padding")
	assert_eq(background.size, Vector2(826, 90), "Simple Image fills the input root")
	assert_eq(background.stretch_mode, TextureRect.STRETCH_SCALE)
	assert_eq(input.alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_ne(input.get_theme_font("font"), placeholder.get_theme_font("font"),
		"source typed Title and translated xiquemuye placeholder are independent")
	var previous := Preferences.font_size
	Preferences.events.font_size_changed.emit("xxl")
	await wait_process_frames(2)
	assert_eq(placeholder.get_theme_font_size("font_size"), 75)
	assert_eq(input.get_theme_font_size("font_size"), 50)
	Preferences.events.font_size_changed.emit(previous)
	assert_true(placeholder.visible)
	input.text = "A"
	await wait_process_frames(2)
	assert_false(placeholder.visible, "programmatic initial names must also hide placeholder")
	input.text = ""
	await wait_process_frames(2)
	assert_true(placeholder.visible)


func test_rename_layout_counts_only_direct_content_and_tracks_preference() -> void:
	var view := Rename.new()
	view.size = Vector2(3840, 2160)
	add_child_autofree(view)
	await wait_process_frames(3)
	var bg := view.get_node("ChangeNameCanvas/PromptBG") as Control
	var content := bg.get_node("PromptText") as RichTextLabel
	var input := content.get_node("InputFieldHost") as Control
	assert_almost_eq(bg.size.y, content.get_content_height() + 600.0, 0.01,
		"source padding T200+B400 surrounds the sole participating child")
	assert_eq(content.position, Vector2(270, 200))
	assert_almost_eq(input.position.y, content.size.y + 36.0, 0.01,
		"input anchors below Content, not below PromptBG")
	var height_before := bg.size.y
	content.get_node("ContentInvalidPrompt").text = "错误信息"
	await wait_process_frames(2)
	assert_eq(bg.size.y, height_before, "grandchild error is not another root layout row")
	var previous := Preferences.font_size
	# Emit only: no write to real user preferences during this test.
	Preferences.events.font_size_changed.emit("xxl")
	await wait_process_frames(3)
	assert_eq(content.get_theme_font_size("normal_font_size"), 75)
	assert_almost_eq(bg.size.y, content.get_content_height() + 600.0, 0.01)
	Preferences.events.font_size_changed.emit(previous)
	content.text = "第一行\n第二行\n第三行"
	await wait_process_frames(3)
	assert_gt(bg.size.y, height_before, "content reflow drives the fitter")
	assert_almost_eq(bg.position.y, (2160.0 - bg.size.y) / 2.0, 0.01)


func test_confirm_uses_spacers_and_reflows_without_fixed_minimum() -> void:
	var view := Confirm.new()
	view.dialog_text = "是否继续？"
	add_child_autofree(view)
	await wait_process_frames(3)
	var bg := view.get_node("PromptBG") as Control
	var body := bg.get_node("Content") as Label
	assert_eq(body.position, Vector2(352.5, 200))
	assert_eq(body.size.x, 2000.0)
	assert_almost_eq(bg.size.y, body.size.y + 450.0, 0.01,
		"T150+B200 plus two50 spacings; no clone560 minimum")
	var short_height := bg.size.y
	view.dialog_text = "第一行\n第二行\n第三行\n第四行"
	await wait_process_frames(3)
	assert_gt(bg.size.y, short_height)
	assert_almost_eq(bg.get_node("Confirm").position.y, bg.size.y - 79.0, 0.01)
	assert_almost_eq(bg.get_node("Full").size.y, bg.size.y - 132.0, 0.01)
	view.dialog_text = "是否继续？"
	await wait_process_frames(3)
	assert_eq(bg.size.y, short_height, "shrinks again when the content gets shorter")


func test_confirm_resolves_once_after_layout_changes() -> void:
	var view := Confirm.new()
	view.dialog_text = "确认"
	add_child_autofree(view)
	watch_signals(view)
	await wait_process_frames(2)
	view.get_node("PromptBG/Confirm").pressed.emit()
	view.get_node("PromptBG/Cancel").pressed.emit()
	assert_signal_emit_count(view, "confirmed", 1)
	assert_signal_not_emitted(view, "canceled")
