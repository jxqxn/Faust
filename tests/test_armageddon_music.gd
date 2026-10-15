extends GutTest

const Music = preload("res://ui/armageddon_music.gd")
const View = preload("res://ui/rite_view.gd")
const Screen = preload("res://ui/game_screen.gd")
var db: ConfigDB
var old_path: String
var save_path: String
var old_global: String
var old_round: String
var test_root: String

class CloseState extends GameState:
	var block_close := false
	func trigger_events(timing: String, _context: Dictionary = {}) -> Array[int]:
		if timing == "rite_end" and block_close:
			queue_prompt({"id": "music-close", "text": "关闭事件尚未结束"})
		return []

func before_all() -> void:
	db = ConfigDB.new()
	db.load_all()

func before_each() -> void:
	old_path = SaveSystem.save_path_override
	old_global = GlobalState.global_path_override
	old_round = SaveSystem.round_save_root_override
	test_root = "user://armageddon-test-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(test_root)
	save_path = test_root.path_join("save.json")
	SaveSystem.use_save_path(save_path)
	GlobalState.use_global_path(test_root.path_join("global.json"))
	SaveSystem.use_round_save_root(test_root)

func after_each() -> void:
	SaveSystem.use_save_path(old_path)
	GlobalState.use_global_path(old_global)
	SaveSystem.use_round_save_root(old_round)
	for filename in DirAccess.get_files_at(test_root):
		DirAccess.remove_absolute(test_root.path_join(filename))
	DirAccess.remove_absolute(test_root)

func _audio(state: GameState):
	var audio := GameAudio.new()
	add_child_autofree(audio)
	audio.set_music_settings(100.0, true)
	audio.play_bgm("main")
	audio.bind_music_state(state, db)
	return audio

func test_creation_requires_success_and_reads_original_flag() -> void:
	var state := GameState.new()
	var audio = _audio(state)
	assert_eq(DeferredEffects._add_rite_and_note(5010201, state, db, GameRNG.new(15)), 0,
		"missing required protagonist aborts InitRite before music")
	assert_false(state.is_armageddon)
	assert_false(audio.armageddon.player.playing)
	var uid := state.add_card_to_hand(2000001, db)
	state.get_card_instance(uid).tags["主角"] = 1
	assert_gt(DeferredEffects._add_rite_and_note(5010201, state, db, GameRNG.new(15)), 0)
	assert_true(state.is_armageddon)
	assert_eq(state.armageddon_rite_id, 5010201)
	assert_true(audio.armageddon.animator_active)
	assert_eq(audio.armageddon.playing_rite_id, 5010201)
	assert_true(audio.armageddon.player.playing)
	assert_true(SaveSystem.save(state))
	var restored = SaveSystem.load(db)
	assert_true(restored.is_armageddon)
	assert_eq(restored.armageddon_rite_id, 5010201)

func test_delayed_activation_next_day_and_loaded_state_are_distinct() -> void:
	var state := GameState.new()
	var audio = _audio(state)
	state.apply_rite_music(5003027, db, false)
	assert_true(state.is_armageddon)
	assert_false(audio.armageddon.animator_active, "Player true does not force Animator true")
	assert_false(audio.armageddon.player.playing)
	assert_true(SaveSystem.save(state))
	var restored = SaveSystem.load(db)
	audio.bind_music_state(restored, db)
	assert_eq(audio.armageddon.playing_rite_id, 5003027, "Start restores music without waiting for another day")
	audio.bind_music_state(state, db)
	audio.armageddon.reset_playback()
	# Simulate the already selected Animator integer before a delayed activation.
	audio.armageddon.animator_rite_id = state.armageddon_rite_id
	state.round_transition = {"phase": "delays", "remaining_delays": [], "interactive": true,
		"animation": preload("res://ui/next_day_clock.gd").create()}
	RoundLoop.resume_day(state, db, GameRNG.new(15))
	assert_eq(state.round_transition.phase, "day_enter", "music activates before the day-entry animation gate")
	assert_eq(audio.armageddon.playing_rite_id, 5003027)
	watch_signals(audio.armageddon)
	state.round_music_requested.emit()
	assert_signal_not_emitted(audio.armageddon, "clip_started", "already-active day boundary does not replay")

func test_source_fades_loop_and_settings_do_not_change_player_state() -> void:
	var state := GameState.new()
	var audio = _audio(state)
	var music = audio.armageddon
	music.set_process(false)
	state.apply_rite_music(5010013, db, false)
	assert_true(music.player.playing)
	assert_eq(music.phase, "in")
	assert_eq(music._duration, float(db.variable_config.fade_in_transition_time.Armageddon))
	assert_almost_eq(music.loop_end, music.player.stream.get_length(), 0.001)
	music._process(music._duration + 0.01)
	assert_eq(music.phase, "playing")
	assert_false(audio._bgm_player.playing, "main_game exit fade stops its own source")
	state.apply_rite_music(5003027, db, false)
	assert_eq(music.phase, "out", "non-instant entry still changes an active Animator")
	assert_eq(music.playing_rite_id, 5010013, "old clip remains until fade ends")
	music._process(music._duration / 2.0)
	assert_lt(music.player.volume_db, 0.0)
	assert_eq(music.playing_rite_id, 5010013)
	state.apply_rite_music(5010022, db, false)
	music._process(music._duration + 0.01)
	assert_eq(music.playing_rite_id, 5010022, "fade completion consumes current Animator index")
	music._process(music._duration + 0.01)
	assert_eq(music.phase, "playing")
	# Exercise actual AudioStreamPlayer end/loop callback, not a synthetic clip table.
	music.player.stop()
	music._on_finished()
	assert_true(music.player.playing)
	audio.set_music_settings(100.0, false)
	assert_lte(music.player.volume_db, -80.0)
	audio.set_music_settings(100.0, true)
	assert_almost_eq(music.player.volume_db, 0.0, 0.001)
	assert_eq(state.armageddon_rite_id, 5010022)
	assert_almost_eq(Music.source_volume_db(-80.0), -80.0, 0.0001)
	assert_almost_eq(Music.source_volume_db(20.0), 0.0, 0.0001)
	# The source volume transfer is not a linear dB tween.
	assert_almost_eq(Music.source_volume_db(-30.0), -12.7282868, 0.0001)

func test_rebind_cancels_old_fade_and_detaches_old_state() -> void:
	var first := GameState.new()
	var audio = _audio(first)
	first.apply_rite_music(5010013, db, false)
	first.apply_rite_music(5003027, db, false)
	assert_eq(audio.armageddon.phase, "out")
	var loaded := GameState.new()
	loaded.is_armageddon = true
	loaded.armageddon_rite_id = 5010022
	audio.bind_music_state(loaded, db)
	assert_eq(audio.armageddon.playing_rite_id, 5010022)
	first.apply_rite_music(5010013, db, false)
	assert_eq(audio.armageddon.animator_rite_id, 5010022, "old run cannot drive newly loaded music")
	audio.armageddon._process(10.0)
	assert_eq(audio.armageddon.playing_rite_id, 5010022)
	audio.detach_music_state()
	loaded.apply_rite_music(5010013, db, false)
	assert_false(audio.armageddon.player.playing)

func test_headless_auto_close_preserves_original_music_state() -> void:
	var state := CloseState.new()
	var rite = state.create_rite_instance(5010013)
	var context := {"rite_id": rite.id, "rite_uid": rite.uid, "state": state, "db": db}
	RiteSettlement.begin(rite.uid, RiteResolver.RiteResult.new(), context, state, db, GameRNG.new(15))
	assert_true(state.rite_settlements.is_empty())
	assert_eq(state.armageddon_rite_id, 5010013)
	assert_true(state.is_armageddon)

func test_real_audio_clock_wraps_at_clip_end_and_stop_marker_is_not_a_file() -> void:
	var state := GameState.new()
	var audio = _audio(state)
	state.apply_rite_music(5010013, db, false)
	var music = audio.armageddon
	await wait_process_frames(2)
	assert_gt(music.loop_end, 1.0)
	music.player.seek(music.loop_end - 0.03)
	await wait_seconds(0.35)
	assert_true(music.player.playing)
	assert_lt(music.player.get_playback_position(), 1.0, "actual audio end callback restarts original loop")
	# Control marker branch is present in source, but commented out in shipped JSONC.
	# A bounded fixture tests it without inventing a production content entry.
	var original: Dictionary = db.sfx_config.armageddon_music_loop["5010022"]
	var marker := original.duplicate(true)
	marker.clip = "ArmageddonStop"
	db.sfx_config.armageddon_music_loop["5010022"] = marker
	state.apply_rite_music(5010022, db, false)
	music._process(music._duration + 0.01)
	assert_false(music.player.playing)
	assert_eq(music.phase, "idle")
	db.sfx_config.armageddon_music_loop["5010022"] = original

func _click(viewport: SubViewport, control: Control) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = control.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(), control, "real input hits target")
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event, true)
		await wait_process_frames(1)

func test_real_close_waits_for_prompt_then_persists_music_at_both_sizes() -> void:
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		var state := CloseState.new()
		state.block_close = true
		var audio = _audio(state)
		var viewport := SubViewport.new()
		viewport.size = size
		viewport.handle_input_locally = true
		add_child_autofree(viewport)
		var screen := Screen.new()
		screen.setup(state, db, GameRNG.new(15))
		viewport.add_child(screen)
		var rite = state.create_rite_instance(5010013)
		var view := View.new()
		view.setup(state, db, GameRNG.new(15), rite.id, rite.uid)
		screen.add_source_overlay(view)
		await wait_process_frames(2)
		# Empty selected result isolates OnClose from story selection; real JSONC music remains intact.
		view._last_result = RiteResolver.RiteResult.new()
		view._resolution_pending = true
		view._settlement_phase = "selection"
		view._settlement_context = {"rite_id": rite.id, "rite_uid": rite.uid}
		view._result_surface.show()
		view._result_text_done = true
		view._result_paragraphs.clear()
		await _click(viewport, view._result_next_button)
		assert_false(state.is_armageddon, "final operations do not activate close music")
		await _click(viewport, view._result_next_button)
		assert_false(view.visible)
		assert_false(state.is_armageddon, "OnRiteEnd prompt still owns the continuation")
		assert_true(SaveSystem.save(state))
		var restored = SaveSystem.load(db)
		assert_false(restored.is_armageddon)
		assert_true(restored.rite_result_display.closing)
		# Reconstruct the real controller from the mid-close disk payload.
		screen.free()
		audio.free()
		var main = load("res://scenes/main.tscn").instantiate()
		viewport.add_child(main)
		main._on_continue()
		await wait_process_frames(3)
		assert_false(main._rite_overlay.visible)
		await _click(viewport, main._game_screen._event_overlay._confirm_button)
		await wait_process_frames(3)
		assert_null(main._rite_overlay)
		assert_eq(main.state.armageddon_rite_id, 5010013)
		assert_true(main._audio.armageddon.player.playing)
		assert_eq(main._audio.armageddon.playing_rite_id, 5010013)
		var saved = SaveSystem.load(db)
		assert_true(saved.is_armageddon, "controller autosaves after music state update")
		main.free()
		main = load("res://scenes/main.tscn").instantiate()
		viewport.add_child(main)
		main._on_continue()
		await wait_process_frames(2)
		assert_eq(main._audio.armageddon.playing_rite_id, 5010013)
		assert_true(main._audio.armageddon.player.playing)

func test_excluded_close_and_gameover_do_not_change_music() -> void:
	var state := GameState.new()
	state.is_armageddon = true
	state.armageddon_rite_id = 5003027
	state.apply_rite_music(5006068, db, false)
	state.apply_rite_music(5000001, db, false)
	assert_eq(state.armageddon_rite_id, 5003027)
	var view := View.new()
	view._state = state
	view._db = db
	view._rng = GameRNG.new(15)
	view._rite_id = 5010013
	state.over_pending = true
	view._continue_result_close()
	assert_eq(state.armageddon_rite_id, 5003027)
	view.free()
