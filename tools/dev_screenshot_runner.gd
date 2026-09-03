extends Control

## Dev-only screenshot runner scene: boots the real main scene as a child so
## the normal project startup path (window stretch settings included) applies,
## then saves a viewport capture and quits.
## Usage: godot res://tools/dev_screenshot_runner.tscn -- --out <path> [--frames N]
##   [--gallery-card-info] [--gallery-cg] [--gallery-over] [--story-typewriter]
##   [--after-story] [--after-story-zoom] [--story-notify] [--point-shop] [--credits]

const GALLERY_OVER_SHOT_ROOT := "user://dev_gallery_over_shot"

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
	if args.has("--point-shop"):
		await get_tree().create_timer(0.5).timeout
		if main.has_method("_show_point_shop"):
			main.call("_show_point_shop")
	if args.has("--credits"):
		await get_tree().create_timer(0.5).timeout
		if main.has_method("_show_credits"):
			main.call("_show_credits")
	if args.has("--gallery-card-info"):
		await get_tree().create_timer(0.5).timeout
		# Follow the real title route: Game._show_gallery -> GalleryPanel, then
		# select the source Gallery tab and open the first source-sorted card.
		if main.has_method("_show_gallery"):
			main.call("_show_gallery")
			await get_tree().process_frame
			await get_tree().process_frame
			var gallery: Node = main.get("_gallery_overlay")
			if gallery != null:
				gallery.call("_show_mode", "Gallery")
				await get_tree().process_frame
				var cards: Array = gallery.call("_filtered_cards")
				if not cards.is_empty():
					gallery.call("_show_card_info", cards[0])
	if args.has("--gallery-cg"):
		await get_tree().create_timer(0.5).timeout
		if main.has_method("_show_gallery"):
			main.call("_show_gallery")
			await get_tree().process_frame
			await get_tree().process_frame
			var gallery: Node = main.get("_gallery_overlay")
			if gallery != null:
				# Screenshot-only detached unlock. Runtime still reads the real
				# Global.overID through GalleryCGIconController semantics.
				var shot_global := GlobalState.new()
				shot_global.over_ids[100] = true
				gallery.set("_global_state", shot_global)
				gallery.call("_show_mode", "CG")
	if args.has("--gallery-over"):
		await get_tree().create_timer(0.5).timeout
		_cleanup_gallery_over_shot()
		var shot_store := OverRecordStore.new(GALLERY_OVER_SHOT_ROOT)
		shot_store.load_over_record_excerpt()
		shot_store.add_over_record({"id": 1, "char_cards": [], "player_data": null, "after_storys": [], "time": "08/27/2026"})
		shot_store.add_over_record({"id": 273, "char_cards": [], "player_data": null, "after_storys": [], "time": "08/27/2026"})
		if main.has_method("_show_gallery"):
			main.call("_show_gallery")
			await get_tree().process_frame
			await get_tree().process_frame
			var gallery: Node = main.get("_gallery_overlay")
			if gallery != null:
				var over_view: Node = gallery.get("_over")
				if over_view != null:
					over_view.call("setup", shot_store, GlobalState.new())
					over_view.call("refresh")
				gallery.call("_show_mode", "Over")
	if args.has("--story-typewriter") or args.has("--after-story") or args.has("--after-story-zoom"):
		await get_tree().create_timer(0.5).timeout
		if main is CanvasItem:
			(main as CanvasItem).visible = false
		var shot_over = preload("res://ui/game_over.gd").new()
		shot_over.setup_record(GameState.new(), main.get("db"), {
			"id": 102 if args.has("--story-typewriter") else 273,
			"player_data": null,
			# Historical replay consumes the record's exact char_cards order.
			"char_cards": [
				{"id": 2000001, "tag": {"pic": 1}},
				{"id": 2000006, "tag": {}},
			],
			"after_storys": [{
				"card_id": 2000001,
				"pic": "cards/2000001",
				"prior": "",
				"extra": ["2000001_extra_12", "2000001_extra_1"],
			}],
		})
		add_child(shot_over)
		await get_tree().process_frame
		await get_tree().process_frame
		shot_over.do_next()
		shot_over.do_next()
		if args.has("--story-typewriter"):
			await get_tree().create_timer(1.1).timeout
		else:
			shot_over.do_next()
		if args.has("--after-story-zoom"):
			var story_controller := shot_over.get_node_or_null("Step2-Story")
			if story_controller != null:
				story_controller.call("toggle_zoom")
				await get_tree().create_timer(0.2).timeout
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
		if args.has("--event-prompt"):
			# Dev-only: queue a three-choice prompt so the PromptNew 1:1
			# surface (OptionBG + OptionNewItem rows) is captured.
			var state_p = main.get("state")
			if screen != null and state_p != null and state_p.has_method("queue_choice_prompt"):
				state_p.queue_choice_prompt(
					{"你是岩石品级": "rock", "你是青铜品级": "bronze", "你是白银品级": "silver", "你是黄金品级": "gold"},
					"贵族拦住了你",
					"一个贵族拦住你，希望你能告诉他，他自己的品位和他死对头的品位。\n他只是一个青铜品级的公子哥，而他……"
				)
				screen.call("refresh")
		if args.has("--story-notify"):
			# Screenshot-only replay of StoryNotifyController.Show with an exact
			# QuestNode from the zero-translation source configuration.
			var state_q = main.get("state")
			var db_q = main.get("db")
			if screen != null and state_q != null and db_q != null:
				state_q.global_state.notify_quest_completed(db_q.get_quest(3300001))
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
	# Remove the screenshot-only archive before image readback so even a
	# renderer/readback failure cannot leave synthetic user data behind.
	if args.has("--gallery-over"):
		_cleanup_gallery_over_shot()
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


func _cleanup_gallery_over_shot() -> void:
	for index in 2:
		var record := "%s/OVERRECORDDATA/over_record_No.%d.json" % [GALLERY_OVER_SHOT_ROOT, index]
		if FileAccess.file_exists(record):
			DirAccess.remove_absolute(record)
	var excerpt := GALLERY_OVER_SHOT_ROOT + "/over_record_excerpt.json"
	if FileAccess.file_exists(excerpt):
		DirAccess.remove_absolute(excerpt)
	DirAccess.remove_absolute(GALLERY_OVER_SHOT_ROOT + "/OVERRECORDDATA/EXCESSDATA")
	DirAccess.remove_absolute(GALLERY_OVER_SHOT_ROOT + "/OVERRECORDDATA")
	DirAccess.remove_absolute(GALLERY_OVER_SHOT_ROOT)
