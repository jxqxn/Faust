extends SceneTree

## Card-detail panel verification: builds 阿尔图 with equipped items, opens the
## production CardInfoView, checks that the equip thumbnails carry the same
## CardNew/CardShow* face layers as the hand cards, and saves a screenshot at
## the original capture resolution (2560x1440) for the reference comparison in
## docs/ui_layout/original_runtime/card_info_artu.jpg.

const CHARACTER_ID := 2000001
const EQUIP_IDS := [2000248, 2000029]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var rng := GameRNG.new(907)
	var state := GameState.new()
	state.setup_new_run(db, 1, rng)
	state.begin_guide = {}
	var character_uid := int(state.add_card_to_hand(CHARACTER_ID, db))
	var character = state.get_card_instance(character_uid)
	for card_id in EQUIP_IDS:
		var item_uid := int(state.add_card_to_hand(card_id, db))
		var item = state.get_card_instance(item_uid)
		if character != null and item != null:
			item.equipped_slot = "饰品"
			item.zone = "equipped"
			character.equipped_uids.append(item_uid)

	var screen = preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _settle(6)
	screen.show_card_detail(character_uid)
	await _settle(8)

	var view = screen._card_info_view
	_check(view != null, "card detail view missing")
	if view == null:
		_finish(screen)
		return
	var equips := view.find_child("EquipList", true, false) as Control
	_check(equips != null, "Equips/EquipList missing")
	var widgets: Array = []
	if equips != null:
		for child in equips.get_children():
			if child is CardWidget:
				widgets.append(child)
	_check(widgets.size() == EQUIP_IDS.size(), "equip thumbnails %d != %d" % [widgets.size(), EQUIP_IDS.size()])
	for widget in widgets:
		var face: Control = widget.get_node_or_null("CardVisualFace")
		_check(face != null, "equip %s has no CardVisualFace" % widget.name)
		if face == null:
			continue
		_check(face.get_node_or_null("RarityFrame") != null, "equip %s has no rarity frame" % widget.name)
		_check(face.get_node_or_null("CardArt") != null, "equip %s has no art" % widget.name)
		_check(face.get_node_or_null("Flash") != null, "equip %s has no CardNew/Flash outline" % widget.name)
		var frame := face.get_node("RarityFrame") as TextureRect
		_check(frame.material is ShaderMaterial, "equip %s must carry the card material" % widget.name)
		_check(widget.size.is_equal_approx(CardWidget.CARD_SIZE), "equip %s must use the CardNew rect" % widget.name)

	await RenderingServer.frame_post_draw
	var path := "res://docs/ui_layout/card_detail_%d.png" % root.size.x
	root.get_texture().get_image().save_png(path)
	_finish(screen, path)


func _finish(screen, path: String = "") -> void:
	print("CARD_DETAIL: ", "PASS" if failures.is_empty() else "FAIL", " -> ", path)
	for failure in failures:
		print("  - ", failure)
	if screen != null and is_instance_valid(screen):
		screen.free()
	FaustTheme.clear_cache()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame
