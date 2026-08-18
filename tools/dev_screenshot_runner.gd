extends Control

## Dev-only screenshot runner scene: boots the real main scene as a child so
## the normal project startup path (window stretch settings included) applies,
## then saves a viewport capture and quits.
## Usage: godot res://tools/dev_screenshot_runner.tscn -- --out <path> [--frames N]

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	var out := "user://dev_screenshot.png"
	for i in range(args.size()):
		if args[i] == "--out" and i + 1 < args.size():
			out = args[i + 1]
	var frames := 120
	for i in range(args.size()):
		if args[i] == "--frames" and i + 1 < args.size():
			frames = int(args[i + 1])
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(float(frames) / 60.0).timeout
	var vp := get_viewport()
	print("viewport=%s root_size=%s scale=%s/%s" % [vp.get_visible_rect(), vp.size, vp.content_scale_mode, vp.content_scale_aspect])
	if main is Control:
		print("main rect=%s children=%d" % [(main as Control).get_global_rect(), main.get_child_count()])
		for child in (main as Control).get_children():
			if child is Control:
				print("  %s rect=%s" % [child.name, (child as Control).get_global_rect()])
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(out)
	print("screenshot saved: %s (%dx%d)" % [out, image.get_width(), image.get_height()])
	get_tree().quit(0)
