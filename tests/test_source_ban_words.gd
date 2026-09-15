extends GutTest
const Filter = preload("res://data/source_ban_words.gd")

func test_original_encrypted_resource_matches_independent_dotnet_oracle() -> void:
	var path := ProjectSettings.globalize_path("res://../Faust-artifacts/ban-word-oracle.json")
	var configured := OS.get_environment("FAUST_BAN_WORD_ORACLE")
	if not configured.is_empty():
		path = configured
	if not FileAccess.file_exists(path):
		pending("Run tools/export_source_ban_word_oracle.ps1 for independent original-source cases")
		return
	var oracle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var view := preload("res://ui/change_name_view.gd").new()
	add_child_autofree(view)
	for row in oracle.cases:
		assert_eq(Filter.has_ban_words(row.input), row.blocked, "original .NET HasMaskWord: " + row.input)
		assert_eq(view._validate_name(row.input), row.valid, "original UTF16 length + HasBanWords: " + row.input)
	assert_eq(Filter.source_word_count, int(oracle.word_count))
	assert_eq(Filter.PLAINTEXT_SHA256, oracle.plaintext_sha256)

func _click(viewport: SubViewport, control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(), control)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event, true)
	await wait_process_frames(2)

func test_real_rename_input_rejects_original_word_and_accepts_ordinary_name() -> void:
	var oracle_path := ProjectSettings.globalize_path("res://../Faust-artifacts/ban-word-oracle.json")
	if not OS.get_environment("FAUST_BAN_WORD_ORACLE").is_empty():
		oracle_path = OS.get_environment("FAUST_BAN_WORD_ORACLE")
	if not FileAccess.file_exists(oracle_path):
		pending("Original-source word oracle required")
		return
	var oracle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(oracle_path))
	var forbidden := ""
	for row in oracle.cases:
		if row.blocked and str(row.input).length() < 5:
			forbidden = row.input
			break
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.handle_input_locally = true
		add_child_autofree(viewport)
		var view := preload("res://ui/change_name_view.gd").new()
		view.size = Vector2(dimensions)
		viewport.add_child(view)
		await wait_process_frames(2)
		var input := view.find_child("CardRenameInput", true, false) as LineEdit
		var confirm := view.find_child("CardRenameConfirmButton", true, false) as Button
		var submitted: Array = []
		view.submitted.connect(func(value): submitted.append(value))
		await _click(viewport, input)
		for character in forbidden:
			var key := InputEventKey.new()
			key.unicode = character.unicode_at(0)
			key.pressed = true
			viewport.push_input(key, true)
			key = key.duplicate()
			key.pressed = false
			viewport.push_input(key, true)
		await wait_process_frames(2)
		assert_eq(input.text, forbidden)
		assert_true(confirm.disabled)
		assert_false(view.find_child("ContentInvalidPrompt", true, false).text.is_empty())
		await _click(viewport, confirm)
		assert_true(submitted.is_empty())
		# Real Ctrl+A replacement followed by typing a permitted source name.
		await _click(viewport, input)
		var select := InputEventKey.new()
		select.keycode = KEY_A
		select.ctrl_pressed = true
		select.pressed = true
		viewport.push_input(select, true)
		select = select.duplicate()
		select.pressed = false
		viewport.push_input(select, true)
		for character in "阿尔图":
			var key := InputEventKey.new()
			key.unicode = character.unicode_at(0)
			key.pressed = true
			viewport.push_input(key, true)
			key = key.duplicate()
			key.pressed = false
			viewport.push_input(key, true)
		await wait_process_frames(2)
		assert_eq(input.text, "阿尔图")
		assert_false(confirm.disabled)
		await _click(viewport, confirm)
		assert_eq(submitted, ["阿尔图"])

func _replace_by_input(viewport: SubViewport, input: LineEdit, value: String) -> void:
	await _click(viewport, input)
	var select := InputEventKey.new()
	select.keycode = KEY_A
	select.ctrl_pressed = true
	select.pressed = true
	viewport.push_input(select, true)
	select = select.duplicate()
	select.pressed = false
	viewport.push_input(select, true)
	if value.is_empty():
		var erase := InputEventKey.new()
		erase.keycode = KEY_BACKSPACE
		erase.pressed = true
		viewport.push_input(erase, true)
		erase = erase.duplicate()
		erase.pressed = false
		viewport.push_input(erase, true)
	for character in value:
		var key := InputEventKey.new()
		key.unicode = character.unicode_at(0)
		key.pressed = true
		viewport.push_input(key, true)
		key = key.duplicate()
		key.pressed = false
		viewport.push_input(key, true)
	await wait_process_frames(2)

func test_game_screen_rename_survives_pending_and_completed_save_rebuild() -> void:
	var db := ConfigDB.new()
	db.load_all()
	var rng := preload("res://core/rng.gd").new(190)
	var state := GameState.new()
	state.setup_new_run(db, 0, rng)
	var uid := int(state.hand[0])
	state.queue_operation("rename_card", "rename.test", {
		"card_uid": uid, "title": "为卡牌命名", "text": "输入一个名字。",
		"initial_text": "旧名字",
	}, {"card_uid": uid})
	var pending: Dictionary = JSON.parse_string(JSON.stringify(SaveSystem.serialize(state)))
	state = GameState.new()
	SaveSystem.deserialize(pending, state, db)
	assert_eq(state.pending_operations.size(), 1, "pending rename survives serialized reconstruction")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.handle_input_locally = true
	add_child_autofree(viewport)
	var screen := preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	viewport.add_child(screen)
	await wait_process_frames(3)
	var input := screen.find_child("CardRenameInput", true, false) as LineEdit
	var confirm := screen.find_child("CardRenameConfirmButton", true, false) as Button
	assert_not_null(input)
	assert_not_null(confirm)
	if input == null or confirm == null:
		return
	await _replace_by_input(viewport, input, "")
	assert_true(confirm.disabled)
	await _click(viewport, confirm)
	assert_eq(state.pending_operations.size(), 1, "invalid submission cannot consume pending action")
	await _replace_by_input(viewport, input, "阿尔图")
	assert_false(confirm.disabled)
	await _click(viewport, confirm)
	assert_true(state.pending_operations.is_empty())
	assert_eq(str(state.card_data_for(uid, db).name), "阿尔图")
	assert_null(screen.find_child("CardRenameInput", true, false))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveSystem.serialize(state)))
	screen.queue_free()
	await wait_process_frames(2)
	state = GameState.new()
	SaveSystem.deserialize(saved, state, db)
	screen = preload("res://ui/game_screen.gd").new()
	screen.setup(state, db, rng)
	viewport.add_child(screen)
	await wait_process_frames(3)
	assert_eq(str(state.card_data_for(uid, db).name), "阿尔图", "accepted name survives scene and state reconstruction")
	assert_true(state.pending_operations.is_empty())
	assert_null(screen.find_child("CardRenameInput", true, false), "completed prompt must not reopen after load")
