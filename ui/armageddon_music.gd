## Source Armageddon Animator entry and LoopArmageddonController host.
## [SRC: SFxManager.controller main_game/Armageddon state behaviours;
## SFxStatePlayLoopArmageddon.OnStateEnter 0x407d90; PlayArmageddon 0x403520.]
extends Node

signal clip_started(rite_id: int, clip: String)

var player: AudioStreamPlayer
var animator_active := false
var animator_rite_id := 0
var playing_rite_id := 0
var phase := "idle"
var loop_start := 0.0
var loop_end := 0.0
var _state: GameState
var _db: ConfigDB
var _main: AudioStreamPlayer
var _volume_db := 0.0
var _gain_db := -80.0
var _fade_from := -80.0
var _elapsed := 0.0
var _duration := 0.0
var _main_elapsed := 0.0
var _main_duration := 0.0
var _main_from := 0.0
var _fading_main := false

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "ArmageddonSource"
	add_child(player)
	player.finished.connect(_on_finished)

func bind_state(state: GameState, db: ConfigDB, main: AudioStreamPlayer) -> void:
	_unbind()
	_state = state
	_db = db
	_main = main
	reset_playback()
	if _state == null:
		return
	_state.armageddon_music_requested.connect(request)
	_state.round_music_requested.connect(next_round)
	# GameController.Start 0x557e10 restores Player, not an old fade cursor.
	animator_active = state.is_armageddon
	animator_rite_id = state.armageddon_rite_id
	if animator_active:
		_enter()

func _unbind() -> void:
	if _state != null:
		if _state.armageddon_music_requested.is_connected(request):
			_state.armageddon_music_requested.disconnect(request)
		if _state.round_music_requested.is_connected(next_round):
			_state.round_music_requested.disconnect(next_round)
	_state = null

func detach() -> void:
	_unbind()
	reset_playback()

func reset_playback() -> void:
	player.stop()
	phase = "idle"
	animator_active = false
	animator_rite_id = 0
	playing_rite_id = 0
	_fading_main = false
	_gain_db = -80.0
	_apply_volume()

func set_volume_db(value: float) -> void:
	_volume_db = value
	_apply_volume()

func request(rite_id: int, activate: bool) -> void:
	animator_rite_id = rite_id
	if activate:
		animator_active = true
	if animator_active:
		_enter()

func next_round() -> void:
	# b__5 0x570850: do not replay an already active Armageddon track.
	if _state != null and _state.is_armageddon and not animator_active:
		animator_active = true
		_enter()

func _entry() -> Dictionary:
	return _db.sfx_config.get("armageddon_music_loop", {}).get(str(animator_rite_id), {}) if _db != null else {}

func _fade_time(direction: String, channel: String) -> float:
	var table: Dictionary = _db.variable_config.get("fade_%s_transition_time" % direction, {})
	return float(table.get(channel, table.get("Default", 0.0)))

func _enter() -> void:
	if _entry().is_empty():
		return
	# main_game's enabled SFxStateExitMusicStop fades MainGame on exit.
	if _main != null and _main.playing and not _fading_main:
		_fading_main = true
		_main_elapsed = 0.0
		_main_duration = _fade_time("out", "MainGame")
		_main_from = _main.volume_db - _volume_db
	if player.playing:
		# FadeOutReplay reads the current Animator ID at the end of its fade.
		if phase != "out":
			_begin_fade("out", _fade_time("out", "Armageddon"))
	else:
		_play_selected()

func _begin_fade(next_phase: String, seconds: float) -> void:
	phase = next_phase
	_fade_from = _gain_db
	_elapsed = 0.0
	_duration = seconds

func _play_selected() -> void:
	var entry := _entry()
	var clip := str(entry.get("clip", ""))
	if clip == "ArmageddonStop":
		# Source stop marker is an operation, never an AudioClip filename.
		if _gain_db <= -80.0:
			player.stop()
			phase = "idle"
			return
		_begin_fade("stop", _fade_time("out", "Armageddon"))
		return
	var path := "res://assets/original/audio/" + clip + ("" if clip.ends_with(".ogg") else ".ogg")
	if clip.is_empty() or not ResourceLoader.exists(path):
		push_warning("Armageddon clip unavailable for rite %d: %s" % [animator_rite_id, clip])
		phase = "idle"
		return
	var stream := (load(path) as AudioStream).duplicate() as AudioStream
	if stream is AudioStreamOggVorbis:
		stream.loop = false # LoopArmageddonController owns the configured interval.
	loop_start = float(entry.get("loop_start", 0.0))
	loop_end = float(entry.get("loop_end", -1.0))
	if loop_end == -1.0:
		loop_end = stream.get_length()
	# [SRC: PlayArmageddon.c boundary checks + dump ClipLoopNode fields.]
	if loop_start < 0.0 or loop_end > stream.get_length() or loop_start >= loop_end:
		push_warning("Invalid original Armageddon loop for rite %d" % animator_rite_id)
		phase = "idle"
		return
	player.stream = stream
	playing_rite_id = animator_rite_id
	player.play(float(entry.get("start", 0.0)))
	_begin_fade("in", _fade_time("in", "Armageddon"))
	clip_started.emit(playing_rite_id, clip)

## Source Utils.AudioVolumeLinearToDecibel 0x3ab640; constant RVAs
## 0x1c9e4d4=-80, 0x1c9e4cc=20, 0x1c9e4b4=0.25.
static func source_volume_db(value: float) -> float:
	return -80.0 + 80.0 * pow(clampf((value + 80.0) / 100.0, 0.0, 1.0), 0.25)

func _process(delta: float) -> void:
	if _fading_main:
		_main_elapsed += delta
		var t := 1.0 if _main_duration <= 0.0 else minf(_main_elapsed / _main_duration, 1.0)
		_main.volume_db = _volume_db + source_volume_db(lerpf(_main_from, -80.0, t))
		if t >= 1.0:
			_main.stop()
			_fading_main = false
	if phase in ["in", "out", "stop"]:
		_elapsed += delta
		var t := 1.0 if _duration <= 0.0 else minf(_elapsed / _duration, 1.0)
		_gain_db = source_volume_db(lerpf(_fade_from, 20.0 if phase == "in" else -80.0, t))
		_apply_volume()
		if t >= 1.0:
			if phase == "out":
				_play_selected()
			elif phase == "stop":
				player.stop()
				phase = "idle"
			else:
				phase = "playing"
	if player.playing and player.get_playback_position() >= loop_end:
		player.seek(loop_start)

func _on_finished() -> void:
	if phase in ["in", "playing", "out"] and player.stream != null:
		player.play(loop_start)

func _apply_volume() -> void:
	if player != null:
		player.volume_db = _volume_db + _gain_db

func _exit_tree() -> void:
	_unbind()
