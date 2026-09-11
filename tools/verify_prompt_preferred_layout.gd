extends SceneTree

var failures: Array[String] = []
var submitted := ""
var cancelled := false
var accepted := false

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 8:
		await process_frame

func click(control: Control) -> void:
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await settle()

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/%s_preferred_%d.png" % [label, DisplayServer.window_get_size().x])

func run() -> void:
	var stage := Control.new()
	stage.size = Vector2(3840, 2160)
	root.add_child(stage)
	var rename := preload("res://ui/change_name_view.gd").new()
	rename.size = stage.size
	stage.add_child(rename)
	rename.submitted.connect(func(value): submitted = value)
	rename.cancelled.connect(func(): cancelled = true)
	await settle()
	var input := rename.find_child("CardRenameInput", true, false) as LineEdit
	await capture("changename_placeholder")
	await click(input)
	var key := InputEventKey.new()
	key.unicode = 65
	key.keycode = KEY_A
	key.pressed = true
	root.push_input(key, true)
	await settle()
	if input.text != "A":
		failures.append("rename input unreachable: " + input.text)
	# The original first Enter selects Confirm; it must not resolve the prompt.
	for down in [true, false]:
		var enter := InputEventKey.new()
		enter.keycode = KEY_ENTER
		enter.pressed = down
		root.push_input(enter, true)
		await process_frame
	await settle()
	var rename_confirm := rename.find_child("CardRenameConfirmButton", true, false) as Button
	if not submitted.is_empty() or not rename_confirm.has_focus():
		failures.append("first Enter must select Confirm without submitting")
	await capture("changename")
	await click(rename.find_child("CardRenameConfirmButton", true, false))
	if submitted != "A":
		failures.append("rename confirm unreachable")
	await click(rename.find_child("Cancel", true, false))
	if not cancelled:
		failures.append("rename cancel unreachable")
	rename.queue_free()
	await settle()
	var confirm := preload("res://ui/source_confirm_dialog.gd").new()
	confirm.dialog_text = "是否继续？\n这里的高度随正文和字号重新计算。"
	stage.add_child(confirm)
	confirm.confirmed.connect(func(): accepted = true)
	await settle()
	var confirm_button := confirm.get_node("PromptBG/Confirm") as Button
	var art := confirm_button.get_node("Image") as TextureRect
	confirm_button.disabled = true
	await create_timer(0.15).timeout
	if not art.modulate.is_equal_approx(Color(0.78431374, 0.78431374, 0.78431374, 0.5019608)):
		failures.append("confirm disabled tint differs from source ColorBlock")
	confirm_button.disabled = false
	var point := confirm_button.get_global_transform_with_canvas() * (confirm_button.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await create_timer(0.15).timeout
	if not art.modulate.is_equal_approx(Color(0.9607843, 0.9607843, 0.9607843, 1)):
		failures.append("confirm hover tint differs from source ColorBlock")
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	await create_timer(0.15).timeout
	if not art.modulate.is_equal_approx(Color(0.78431374, 0.78431374, 0.78431374, 1)):
		failures.append("confirm pressed tint differs from source ColorBlock")
	await capture("confirm")
	press = press.duplicate()
	press.pressed = false
	root.push_input(press, true)
	await settle()
	if not accepted:
		failures.append("confirm action unreachable")
	stage.queue_free()
	await settle()
	if failures.is_empty():
		print("PROMPT_PREFERRED_INPUT: PASS")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
