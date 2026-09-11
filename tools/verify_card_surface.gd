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
	var coin_uid := 0
	for card_id in ORIGINAL_HAND:
		var uid := int(state.add_card_to_hand(card_id, db))
		var instance = state.get_card_instance(uid)
		if instance == null:
			continue
		if card_id == COIN_CARD_ID:
			instance.count = COIN_COUNT
			coin_uid = uid
		if card_id == 2000371:
			instance.life = 1
	main.state = state
	main.call("_show_game")
	await _settle(12)
	var screen = main.get("_game_screen")
	# Give 小圆 a lifetime in the game screen's own config so the LifeBg
	# clock/digit/DotText chain is exercised; the original hand shows the same
	# badge on its sixth card.
	var screen_db = screen.get("_db")
	if screen_db != null and screen_db.has_method("get_card"):
		var life_card: Dictionary = screen_db.get_card(2000371)
		if not life_card.is_empty():
			life_card["card_vanishing"] = 7
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
		_check(not face.get_node("Outline").visible, "card %d starts with selection outline hidden" % card_id)
		var frame := face.get_node_or_null("RarityFrame") as TextureRect
		_check(frame != null, "card %d has no rarity frame" % card_id)
		var title := face.get_node_or_null("Title") as Label
		_check(title != null, "card %d has no Title" % card_id)
		if title != null:
			_check(title.position.is_equal_approx(Vector2(9.5, 15)), "card %d Title position %s" % [card_id, title.position])
			_check(title.size.is_equal_approx(Vector2(175, 40)), "card %d Title size %s" % [card_id, title.size])
			_check(title.get_meta("source_text_style", "") == "@CARD_TITLE", "card %d Title uses runtime source style" % card_id)
			_check(title.get_theme_color("font_color").is_equal_approx(Color.BLACK), "card %d Title color" % card_id)
		var stackable := face.get_node_or_null("Stackable") as TextureRect
		if card_id == COIN_CARD_ID:
			_check(stackable != null, "stackable coin must show the count badge")
			if stackable != null:
				_check(stackable.position.is_equal_approx(Vector2(59.5, 332)), "Stackable position %s" % stackable.position)
				_check(stackable.size.is_equal_approx(Vector2(75, 78)), "Stackable size %s" % stackable.size)
				_check(str(stackable.texture.resource_path).ends_with("checkbox_bg.png"), "item Stackable must use checkbox_bg")
				var count_number: Control = stackable.get_node_or_null("Count")
				_check(count_number != null and str(count_number.get("text")) == str(COIN_COUNT), "Stackable count sprites")
				if count_number != null:
					_check(count_number.get_child_count() == len(str(COIN_COUNT)), "Stackable digit sprite count")
		else:
			_check(stackable == null, "card %d must not show a count badge" % card_id)
		if card_id == 2000371:
			var life_bg := face.get_node_or_null("LifeBg") as TextureRect
			_check(life_bg != null, "lifetime card must show LifeBg")
			if life_bg != null:
				_check(life_bg.position.is_equal_approx(Vector2(57.5, -45)), "LifeBg position %s" % life_bg.position)
				_check(life_bg.size.is_equal_approx(Vector2(98, 45)), "LifeBg size %s" % life_bg.size)
				var life_number: Control = life_bg.get_node_or_null("Life")
				_check(life_number != null and str(life_number.get("text")) == "6", "life digits must show 6")
				var dot := life_bg.get_node_or_null("DotText") as TextureRect
				_check(dot != null, "LifeBg must draw the <sprite=21> DotText")
				if dot != null:
					_check(dot.position.is_equal_approx(Vector2(-7.2, 23.1)), "DotText position %s" % dot.position)
					_check(dot.size.is_equal_approx(Vector2(50, 30)), "DotText size %s" % dot.size)

	# Exercise hit testing and drag routing, not direct signal handlers.
	if coin_uid > 0:
		var coin_widget := _hand_widget(rail, coin_uid)
		var badge_point := coin_widget.get_global_transform_with_canvas() * Vector2(95, 365)
		await _pointer(badge_point)
		await _button(badge_point, true)
		await _button(badge_point, false)
		await create_timer(0.7).timeout
		var coin_uids: Array = []
		var total := 0
		for instance in state.card_instances.values():
			if int(instance.card_id) == COIN_CARD_ID and str(instance.zone) == "hand":
				coin_uids.append(int(instance.uid))
				total += int(instance.count)
		_check(coin_uids.size() == 2, "count badge click must create a second coin object")
		_check(state.get_card_instance(coin_uid).count == 7, "count badge splits exactly one")
		_check(total == COIN_COUNT, "split must preserve the total count")
		if coin_uids.size() == 2:
			rail = screen.find_child("CardRailItems", true, false) as Control
			var from := _hand_widget(rail, coin_uids[1])
			var to := _hand_widget(rail, coin_uids[0])
			if from == null or to == null:
				_check(false, "split widgets absent: %s; visible=%s" % [coin_uids, state.visible_rail_card_uids()])
				_finish(main)
				return
			var start := from.get_global_transform_with_canvas() * (from.size * 0.5)
			var finish := to.get_global_transform_with_canvas() * (to.size * 0.5)
			await _pointer(start)
			await _button(start, true)
			for step in range(1, 16):
				await _pointer(start.lerp(finish, float(step) / 15), true)
			_check(root.gui_is_dragging(), "hand movement must start a real GUI drag")
			# The source leaves the rail during drag; the remaining cards reflow.
			finish = to.get_global_transform_with_canvas() * (to.size * 0.5)
			await _pointer(finish, true)
			_check(root.gui_get_hovered_control() == to, "drop must hit the surviving stack card: hit=%s target=%s point=%s" % [root.gui_get_hovered_control(), to, finish])
			await _button(finish, false)
			await create_timer(0.7).timeout
			var merged_total := 0
			var merged_objects := 0
			for instance in state.card_instances.values():
				if int(instance.card_id) == COIN_CARD_ID and str(instance.zone) == "hand":
					merged_objects += 1
					merged_total += int(instance.count)
			_check(merged_objects == 1, "stacking must merge the two coin objects")
			_check(merged_total == COIN_COUNT, "stacking must preserve the total count")

	# Hold hint through the production game screen: a 0.2s press on a noble card
	# must highlight the rites whose slots accept it (CardController.Update ->
	# ShowSatisfiedRite). Its animation ends independently after one second.
	var noble_widget: CardWidget = null
	var current_rail: Control = screen.find_child("CardRailItems", true, false) as Control
	if current_rail != null:
		for child in current_rail.get_children():
			if child is CardWidget and int(child.card_id) == 2000001:
				noble_widget = child
				break
	var desk: Control = screen.find_child("SituationDesk", true, false) as Control
	_check(desk != null, "SituationDesk missing")
	_check(noble_widget != null, "Noble hand widget missing")
	if noble_widget != null and desk != null:
		var point := noble_widget.get_global_transform_with_canvas() * (noble_widget.size * 0.5)
		var motion := InputEventMouseMotion.new()
		motion.position = point
		root.push_input(motion, true)
		await _settle(2)
		_check(root.gui_get_hovered_control() == noble_widget, "Actual mouse must hit the hand card")
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = point
		root.push_input(press, true)
		await create_timer(0.35).timeout
		var highlighted := 0
		for uid in desk.rite_cards:
			if bool(desk.rite_cards[uid].get("satisfied_hint")):
				highlighted += 1
		_check(highlighted > 0, "holding a noble card must highlight the rites it satisfies")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui_layout/card_hold_%d.png" % DisplayServer.window_get_size().x)
		await create_timer(1.1).timeout
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = point
		root.push_input(release, true)
		await _settle(2)
		_check(screen.get("_card_detail_card_uid") == 0, "hold release must not open card details")
		await _settle(2)
		var still_highlighted := 0
		for uid in desk.rite_cards:
			if bool(desk.rite_cards[uid].get("satisfied_hint")):
				still_highlighted += 1
		_check(still_highlighted == 0, "satisfied-rite one-shot must finish automatically")

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


func _hand_widget(rail: Control, uid: int) -> CardWidget:
	for child in rail.get_children():
		if child is CardWidget and child.card_uid == uid and not child.is_queued_for_deletion():
			return child
	return null


func _pointer(point: Vector2, held: bool = false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.relative = Vector2(20, -20)
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(event, true)
	await process_frame


func _button(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed = down
	root.push_input(event, true)
	await process_frame
