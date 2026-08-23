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
	var auto_start := args.has("--new-game")
	if auto_start:
		await get_tree().create_timer(1.5).timeout
		if main.has_method("_on_new_game_pressed"):
			main.call("_on_new_game_pressed")
		# The opening events have already applied their world effects; their
		# remaining queue entries are only blocking presentation.  Consume them
		# exactly like the layout-test desk fixture so this captures the stable,
		# player-reachable tabletop rather than an off-screen intro modal.
		var state = main.get("state")
		# Some intro queues can schedule their follow-up while being consumed.
		# A capture must reach a stable player-reachable frame rather than loop
		# forever if a malformed/config-only chain keeps re-arming itself.
		var drained := 0
		while (
			state != null
			and state.has_method("pending_operation")
			and not state.pending_operation().is_empty()
			and drained < 128
		):
			state.consume_pending_operation()
			drained += 1
		if drained == 128:
			push_warning("Screenshot capture reached the intro-queue safety cap")
		var screen: Node = main.get("_game_screen")
		if screen != null and screen.has_method("refresh"):
			screen.call("refresh")
		if args.has("--card-detail"):
			var state_c = main.get("state")
			var db_c = main.get("db")
			if screen != null and state_c != null and not state_c.hand.is_empty() and screen.has_method("show_card_detail"):
				screen.call("show_card_detail", int(state_c.hand[0]))
		if args.has("--main-help"):
			if screen != null and screen.has_method("_toggle_main_help"):
				screen.call("_toggle_main_help")
		if args.has("--change-name"):
			var state_c = main.get("state")
			if screen != null and state_c != null and not state_c.hand.is_empty() and state_c.has_method("queue_operation"):
				state_c.queue_operation("rename_card", "rename.shot", {
					"card_uid": int(state_c.hand[0]),
					"title": "为卡牌命名",
					"text": "输入一个名字。",
					"initial_text": "",
				})
				screen.call("refresh")
		if args.has("--event-tray"):
			# Dev-only: seed two cached notices so the 1:1 tray is captured.
			# Runtime play never writes these ids (corpus has zero
			# cached_settlement configs), so this stays a screenshot-only path.
			var state_t = main.get("state")
			if screen != null and state_t != null:
				state_t.add_cached_event(5300001)
				state_t.add_cached_event(5300002)
				screen.call("refresh")
		await get_tree().process_frame
		await get_tree().process_frame
	await get_tree().create_timer(float(frames) / 60.0).timeout
	if auto_start:
		var screen_node: Node = main.get("_game_screen")
		if screen_node == null:
			for child in main.get_children():
				if child.get_script() != null and str(child.get_script().resource_path).find("game_screen") != -1:
					screen_node = child
		if screen_node != null:
			for child in screen_node.get_children():
				if child is Control and child.name in ["RoundNumberBG", "SudanBox", "Prestige", "QuitAnchor", "HandBG", "NextDayLabel", "CachedEvents", "CachedEventMask"]:
					var c: Control = child
					print("chrome %s visible=%s rect=%s modulate=%s" % [child.name, c.visible, c.get_global_rect(), c.modulate])
					if child.name == "CachedEvents":
						for sub in child.get_children():
							var c2: Control = sub
							print("  tray %s visible=%s rect=%s" % [sub.name, c2.visible, c2.get_global_rect()])
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
