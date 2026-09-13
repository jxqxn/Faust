## Isolated, uncapped desktop benchmark. Never writes the player's saves.
extends SceneTree

var main: Control
var results := {}

class MeasuredRite extends "res://ui/rite_view.gd":
	var measured := {}
	func _picture(parent: Control, node_name: String, asset: String, rect: Rect2) -> TextureRect:
		var t := Time.get_ticks_usec()
		var result := super._picture(parent, node_name, asset, rect)
		measured.pictures = measured.get("pictures", 0.0) + (Time.get_ticks_usec() - t) / 1000.0
		return result
	func _build_result_surface() -> void:
		var t := Time.get_ticks_usec()
		super._build_result_surface()
		measured.result = (Time.get_ticks_usec() - t) / 1000.0
	func _build_ui() -> void:
		var t := Time.get_ticks_usec()
		super._build_ui()
		measured.build = (Time.get_ticks_usec() - t) / 1000.0
	func _build_panel_content() -> void:
		var t := Time.get_ticks_usec()
		super._build_panel_content()
		measured.panel = (Time.get_ticks_usec() - t) / 1000.0
	func _build_slot_placeholders() -> void:
		var t := Time.get_ticks_usec()
		super._build_slot_placeholders()
		measured.slots = (Time.get_ticks_usec() - t) / 1000.0
	func _refresh_slot_visuals() -> void:
		var t := Time.get_ticks_usec()
		super._refresh_slot_visuals()
		measured.refresh_slots = (Time.get_ticks_usec() - t) / 1000.0
	func _apply_layout() -> void:
		var t := Time.get_ticks_usec()
		super._apply_layout()
		measured.layout = (Time.get_ticks_usec() - t) / 1000.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Desktop profiling requires a rendered window")
		quit(2)
		return
	var fixture := "user://desktop_profile_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(fixture)
	SaveSystem.use_save_path(fixture.path_join("save.json"))
	SaveSystem.use_round_save_root(fixture)
	GlobalState.use_global_path(fixture.path_join("global.json"))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/save_samples/auto_save.json"))
	main.state = OriginalSaveImporter.import_save(source, main.db).state
	main._show_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	await create_timer(2).timeout
	results["renderer"] = RenderingServer.get_current_rendering_method()
	results["window_pixels"] = str(DisplayServer.window_get_size())
	results["canvas_size"] = str(root.size)
	results["cards"] = main._game_screen._card_items.get_child_count()
	results["idle"] = await sample_frames()
	var hand = main._game_screen._card_rail_view
	hand.hide()
	results["hand_hidden"] = await sample_frames()
	hand.show()
	var process_nodes := []
	for node in main.find_children("*", "", true, false):
		if node.is_processing():
			process_nodes.append(node)
			node.set_process(false)
	main.set_process(false)
	results["scripts_disabled"] = await sample_frames()
	for node in process_nodes:
		node.set_process(true)
	main.set_process(true)
	var timings := []
	for i in range(3):
		var started := Time.get_ticks_usec()
		main._game_screen.refresh()
		timings.append((Time.get_ticks_usec()-started)/1000.0)
		await process_frame
		await process_frame
	results["refresh_ms"] = timings
	var open_times := []
	for instance in main.state.rite_instances.values():
		var started := Time.get_ticks_usec()
		main._on_open_rite_instance(instance.uid)
		open_times.append({"id":instance.id,"open_ms":(Time.get_ticks_usec()-started)/1000.0})
		await process_frame
		await process_frame
		main._close_rite_overlay()
		await process_frame
	results["rite_open"] = open_times
	var instance = main.state.rite_instances.values()[0]
	var measured := MeasuredRite.new()
	measured.setup(main.state, main.db, main.rng, instance.id, instance.uid)
	main._game_screen.add_source_overlay(measured)
	await process_frame
	await process_frame
	results["rite_breakdown"] = measured.measured.duplicate()
	measured.queue_free()
	await process_frame
	var pages := []
	for index in [1, 0, 2, 0]:
		var control: Control = main._game_screen._bag_tabs.buttons[index]
		var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
		var motion := InputEventMouseMotion.new()
		motion.position = point
		root.push_input(motion, true)
		await process_frame
		var hit := root.gui_get_hovered_control() == control
		var started := Time.get_ticks_usec()
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = point
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			root.push_input(event, true)
		await RenderingServer.frame_post_draw
		pages.append({"page":index,"hit":hit,"changed":main.state.current_bag_index == index,"input_to_draw_ms":(Time.get_ticks_usec()-started)/1000.0})
	results["page_input"] = pages
	print("DESKTOP_PROFILE ",JSON.stringify(results))
	main.queue_free()
	main = null
	await process_frame
	await process_frame
	FaustTheme.clear_cache()
	await process_frame
	quit()

func sample_frames() -> Dictionary:
	for i in range(30):
		await process_frame
	var samples := []
	var cpu := 0.0
	var gpu := 0.0
	var previous := Time.get_ticks_usec()
	for i in range(240):
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now-previous)/1000.0)
		previous = now
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
	samples.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	# Performance.TIME_PROCESS is refreshed on a different sampling clock;
	# averaging it over this uncapped loop would repeat a stale observation.
	return {"frame_mean_ms":total/samples.size(),"frame_p95_ms":samples[228],"render_cpu_ms":cpu/240,"render_gpu_ms":gpu/240,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
