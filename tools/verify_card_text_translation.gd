extends "res://tools/verify_prompt_preferred_layout.gd"

func run() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var state := GameState.new()
	var rng := GameRNG.new(317)
	state.setup_new_run(db, 0, rng)
	var uid := state.add_card_to_hand(2001193, db)
	state.set_card_custom_name(uid, "change_card_name_5000301_01")
	state.set_card_custom_text(uid, "change_card_text_5000301_01")
	var restored := GameState.new()
	SaveSystem.deserialize(SaveSystem.serialize(state), restored, db)
	var screen := preload("res://ui/game_screen.gd").new()
	screen.setup(restored, db, rng)
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	screen.show_card_detail(uid)
	await settle()
	var view = screen._card_info_view
	if view == null:
		failures.append("card detail missing")
	else:
		if view._content_label.get_parsed_text() != "它刚刚步入现实世界，开始拙劣地模仿着人类，或者任何生物的外形……":
			failures.append("card detail did not display the original description translation")
		if restored.card_data_for(uid, db).name != "镜中的生灵":
			failures.append("card name translation lost after save")
	await capture("card_text_translation")
	screen.queue_free()
	await settle()
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("CARD_TEXT_TRANSLATION: PASS")
	quit(0 if failures.is_empty() else 1)
