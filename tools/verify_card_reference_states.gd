extends "res://tools/verify_card_equipment_input.gd"

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui_layout/card_reference_%s_%d.png" % [label, DisplayServer.window_get_size().x])

func _run() -> void:
	await verify_edge_alpha()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	state.setup_new_run(db, 1, GameRNG.new(201))
	state.begin_guide = {}
	for instance in state.card_instances.values():
		instance.zone = "removed"
	state.hand.clear()
	state.rail_order.clear()
	state.active_sudan_cards.clear()
	var coin := state.add_card_to_hand(2000029, db)
	state.get_card_instance(coin).count = 7
	var host := state.add_card_to_hand(2000001, db)
	# User's reference has two earned wisdom points above the base card.
	# This is comparison-fixture state, not a change to original content.
	state.get_card_instance(host).tags["智慧"] = 3
	state.add_card_to_hand(2000006, db)
	state.add_card_to_hand(2000372, db)
	var armor := state.add_card_to_hand(2000368, db)
	main.state = state
	main.call("_show_game")
	await create_timer(1.0).timeout
	var screen = main.get("_game_screen")
	if "--interactive" in OS.get_cmdline_user_args():
		print("CARD_REFERENCE_INTERACTIVE: ready; close window to end")
		return
	screen.focus_qualified_hand(func(card: Dictionary): return str(card.get("type")) == "char")
	await create_timer(0.15).timeout
	var flashing := 0
	for child in screen.get("_card_items").get_children():
		if child is CardWidget and float(child._flash_material.get_shader_parameter("outline_fade")) > 0.1:
			flashing += 1
	check(flashing >= 2, "multiple candidate cards play the live flash")
	await capture("candidate_flash")
	await create_timer(0.7).timeout
	for child in screen.get("_card_items").get_children():
		if child is CardWidget:
			check(is_zero_approx(float(child._flash_material.get_shader_parameter("outline_fade"))), "candidate flash returns to zero")
	screen.focus_qualified_hand(func(_card: Dictionary): return false)
	var gold_widget := hand_widget(screen, coin)
	gold_widget.set_selected(true, false)
	await capture("gold_selected")
	gold_widget.set_selected(false, false)
	var from := hand_widget(screen, armor)
	var to := hand_widget(screen, host)
	var start := from.get_global_rect().get_center()
	var finish := to.get_global_rect().get_center()
	await pointer(start)
	await button(start, true)
	for i in range(1, 16):
		await pointer(start.lerp(finish, float(i) / 15), true)
	finish = to.get_global_rect().get_center()
	await pointer(finish, true)
	check(root.gui_is_dragging(), "reference armor drag is active")
	await verify_drag_occlusion(to)
	await capture("armor_drag")
	await button(finish, false)
	await create_timer(0.7).timeout
	check(armor in state.get_card_instance(host).equipped_uids, "reference armor equips on Artu")
	screen.show_card_detail(host)
	await create_timer(0.3).timeout
	var detail = screen.get("_card_info_view")
	var panel: Control = detail.get("_panel")
	check(panel.get_node("Equips").get_index() < panel.get_node("MainIconMask").get_index(), "portrait must occlude equipped armor")
	await capture("armor_detail")
	print("CARD_REFERENCE_STATES: ", "PASS" if failures.is_empty() else failures)
	main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func verify_drag_occlusion(target: CardWidget) -> void:
	# Input success alone cannot prove the preview is drawn in front of the
	# target. Compare actual pixels inside the character, with preview on/off.
	var preview := root.find_child("CardDragPreview", true, false) as Control
	check(preview != null, "drag preview is present")
	if preview == null:
		return
	await RenderingServer.frame_post_draw
	var shown := root.get_texture().get_image()
	preview.visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	var hidden := root.get_texture().get_image()
	preview.visible = true
	var ratio := Vector2(shown.get_size()) / root.get_visible_rect().size
	var center := target.get_global_rect().get_center() * ratio
	var changed := 0
	for y in range(int(center.y) - 10, int(center.y) + 10):
		for x in range(int(center.x) - 10, int(center.x) + 10):
			var a := shown.get_pixel(x, y)
			var b := hidden.get_pixel(x, y)
			if Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() > 0.025:
				changed += 1
	check(changed > 100, "drag armor visibly overlays character: %d/400 pixels" % changed)
	await process_frame


func verify_edge_alpha() -> void:
	# A half-covered silhouette dragged at .6 must contribute .3 opacity,
	# not .15. This tests the GPU output, rather than inspecting shader text.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(16, 16)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var pixels := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	pixels.fill(Color(0.5, 0.5, 0.5, 0.5))
	var rect := TextureRect.new()
	rect.texture = ImageTexture.create_from_image(pixels)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.size = Vector2(16, 16)
	rect.modulate.a = 0.6
	var material := ShaderMaterial.new()
	material.shader = load("res://ui/card_metal.gdshader")
	rect.material = material
	viewport.add_child(rect)
	await process_frame
	await RenderingServer.frame_post_draw
	var opacity := viewport.get_texture().get_image().get_pixel(8, 8).a
	check(absf(opacity - 0.3) < 0.015, "soft card edge keeps single alpha multiplication: %s" % opacity)
	viewport.queue_free()
	await process_frame
