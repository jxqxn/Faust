extends SceneTree

## Card-surface verification: builds the hand visible in the original
## desktop.jpg, checks the CardNew/CardShow* authored geometry, and writes a
## screenshot at the original capture resolution for a pixel comparison.
##
## Run at the original window size so 1 unit of the 3840x2160 design canvas is
## the same number of screen pixels as in docs/ui_layout/original_runtime/
## desktop.jpg (2560x1440 -> scale 0.6667):
##   godot --path . --windowed --resolution 2560x1440 --script tools/verify_card_surface.gd

## Card ids in the order the original hand shows them (desktop.jpg).
const ORIGINAL_HAND := [2000006, 2000001, 2000029, 2000369, 2000370, 2000371]
const COIN_CARD_ID := 2000029
const COIN_COUNT := 8

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var db := ConfigDB.new()
	db.load_all()
	var rng := GameRNG.new(201)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	state.begin_guide = {}
	# Replace the seeded opening hand with the card set visible in the
	# original screenshot so both images can be compared card by card.
	for instance in state.card_instances.values():
		instance.zone = "removed"
	state.hand.clear()
	state.rail_order.clear()
	state.active_sudan_cards.clear()
	for card_id in ORIGINAL_HAND:
		var uid := int(state.add_card_to_hand(card_id, db))
		if card_id == COIN_CARD_ID:
			var instance = state.get_card_instance(uid)
			if instance != null:
				instance.count = COIN_COUNT
	main.state = state
	main.call("_show_game")
	await _settle(12)
	var screen = main.get("_game_screen")
	screen.refresh()
	await _settle(8)

	var widgets: Array = []
	var rail: Control = screen.find_child("CardRailItems", true, false) as Control
	_check(rail != null, "hand rail CardRailItems missing")
	if rail == null:
		_finish(main)
		return
	for child in rail.get_children():
		if child is CardWidget and not child.is_queued_for_deletion() and child.visible:
			widgets.append(child)
	_check(widgets.size() == ORIGINAL_HAND.size(), "hand should show %d cards, got %d" % [ORIGINAL_HAND.size(), widgets.size()])

	for widget in widgets:
		var card_id: int = widget.card_id
		var face: Control = widget.get_node_or_null("CardVisualFace")
		_check(face != null, "card %d has no CardVisualFace" % card_id)
		if face == null:
			continue
		var flash := face.get_node_or_null("Flash") as TextureRect
		_check(flash != null, "card %d is missing CardNew/Flash" % card_id)
		if flash != null:
			_check(flash.position.is_equal_approx(Vector2(-31, -45)), "card %d Flash position %s" % [card_id, flash.position])
			_check(flash.size.is_equal_approx(Vector2(256, 512)), "card %d Flash size %s" % [card_id, flash.size])
			_check(flash.material is ShaderMaterial, "card %d Flash must carry the CardFlash material" % card_id)
			_check(flash.texture != null and str(flash.texture.resource_path).ends_with("card_outline.png"), "card %d Flash texture" % card_id)
			var art := face.get_node_or_null("CardArt") as TextureRect
			if art != null:
				_check(flash.get_index() > art.get_index(), "card %d Flash must render above the art" % card_id)
		_check(face.get_node_or_null("Outline") == null, "card %d must not draw the inactive CardNew/Outline" % card_id)
		var frame := face.get_node_or_null("RarityFrame") as TextureRect
		_check(frame != null, "card %d has no rarity frame" % card_id)
		var title := face.get_node_or_null("Title") as Label
		_check(title != null, "card %d has no Title" % card_id)
		if title != null:
			_check(title.position.is_equal_approx(Vector2(9.5, 15)), "card %d Title position %s" % [card_id, title.position])
			_check(title.size.is_equal_approx(Vector2(175, 40)), "card %d Title size %s" % [card_id, title.size])
			_check(title.get_theme_font_size("font_size") == 30, "card %d Title font size" % card_id)
			_check(title.get_theme_color("font_color").is_equal_approx(Color.BLACK), "card %d Title color" % card_id)
		var stackable := face.get_node_or_null("Stackable") as TextureRect
		if card_id == COIN_CARD_ID:
			_check(stackable != null, "stackable coin must show the count badge")
			if stackable != null:
				_check(stackable.position.is_equal_approx(Vector2(57, 332)), "Stackable position %s" % stackable.position)
				_check(stackable.size.is_equal_approx(Vector2(80, 80)), "Stackable size %s" % stackable.size)
				_check(str(stackable.texture.resource_path).ends_with("number_bg.png"), "Stackable must use number_bg")
				var count_label := stackable.get_node_or_null("Count") as Label
				_check(count_label != null and count_label.text == str(COIN_COUNT), "Stackable count label")
		else:
			_check(stackable == null, "card %d must not show a count badge" % card_id)

	await RenderingServer.frame_post_draw
	var size := DisplayServer.window_get_size()
	var path := "res://docs/ui_layout/card_surface_%d.png" % size.x
	root.get_texture().get_image().save_png(path)
	_finish(main, path)


func _finish(main, path: String = "") -> void:
	print("CARD_SURFACE: ", "PASS" if failures.is_empty() else "FAIL", " -> ", path)
	for failure in failures:
		print("  - ", failure)
	if main != null and is_instance_valid(main):
		main.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame
