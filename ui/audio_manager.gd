## Game audio: original BGM layers and semantic UI/event sound cues.
## Clips are extracted from the game assets and played by name; missing or
## headless environments degrade silently so tests stay deterministic.
## [SRC: AudioClip/ — main_game_level1..3.ogg, draw_sudan_card_*.ogg,
##       dice_*.ogg, button-*.ogg, card-*.ogg, ithink_close.ogg]
class_name GameAudio
extends Node

const AUDIO_DIR := "res://assets/original/audio/"
const AppSettings = preload("res://ui/game_application_settings.gd")

const BGM_TRACKS := {
	"main": "main_game_level1.ogg",
	"tutorial": "tutorial_main_game.ogg",
}

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_bgm := ""

# Static registry: overlays fire cues without touching the scene tree (the
# rite panel may resolve while detached in tests).
static var _active: GameAudio = null

## Sudan card families keyed by their Chinese names as decoded by
## SudanCards.decode().action: 纵欲/杀戮/征服/奢靡.
const SUDAN_DRAW_CUES := {
	"纵欲": "draw_sudan_card_desire.ogg",
	"杀戮": "draw_sudan_card_kill.ogg",
	"征服": "draw_sudan_card_war.ogg",
	"奢靡": "draw_sudan_card_wastefulness.ogg",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_active = self
	AppSettings.load_preferences()
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BgmPlayer"
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		add_child(player)
		_sfx_players.append(player)
	set_music_settings(AppSettings.music_value, AppSettings.music_state == AppSettings.STATE_ON)
	set_sound_settings(AppSettings.sound_value, AppSettings.sound_state == AppSettings.STATE_ON)


## Source settings use linear values in the inclusive 0..100 range, then
## apply enabled/disabled state separately. [SRC: MusicSliderController.c @
## SldOnClick/BtnOnClick (0x56c2c0/0x56bce0); SoundSliderController.c @
## SldOnClick/BtnOnClick (0x5ad100/0x5acb20)]
func set_music_settings(value: float, enabled: bool) -> void:
	if _bgm_player == null:
		return
	_bgm_player.volume_db = linear_to_db(maxf(value, 0.0001) / 100.0) if enabled else -80.0


func set_sound_settings(value: float, enabled: bool) -> void:
	var db := linear_to_db(maxf(value, 0.0001) / 100.0) if enabled else -80.0
	for player in _sfx_players:
		player.volume_db = db


func play_bgm(track: String) -> void:
	if _current_bgm == track:
		return
	var file := str(BGM_TRACKS.get(track, ""))
	if file.is_empty():
		return
	var stream := _load_stream(file)
	if stream == null:
		return
	_current_bgm = track
	_bgm_player.stream = stream
	_bgm_player.play()


func play(cue: String) -> void:
	var stream := _load_stream(cue)
	if stream == null:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	_sfx_players[0].stream = stream
	_sfx_players[0].play()


## Draw-cue dispatch for the four Sultan card families; non-family draws
## fall back to the generic draw sound.
func play_sudan_draw(action: String) -> void:
	var cue := str(SUDAN_DRAW_CUES.get(action, "drawcard.ogg"))
	play(cue)


func _load_stream(file: String) -> AudioStream:
	var path := AUDIO_DIR + file
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


## Group-free cue entry so overlays (rite panel, prompts) can fire sounds
## without a scene-tree lookup or a hard reference to the game root.
static func cue(clip: String) -> void:
	if _active != null:
		_active.play(clip)


func _exit_tree() -> void:
	if _active == self:
		_active = null
