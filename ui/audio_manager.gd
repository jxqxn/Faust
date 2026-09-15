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

## Every clip this module can play. The names are original AudioClip file names,
## so the whole cue surface can be checked against the exported corpus asset by
## asset instead of trusting call sites.
## [SRC: _unpack/unity_export/ExportedProject/Assets/AudioClip/*.ogg]
const CUE_CLIPS := [
	"add_card.ogg",
	"add_card_to_result.ogg",
	"adl001.ogg",
	"alm001.ogg",
	"alm002.ogg",
	"alm003.ogg",
	"almn001.ogg",
	"almn002.ogg",
	"amr001.ogg",
	"amr002.ogg",
	"animal_beast_growl.ogg",
	"animal_beast_low_growl.ogg",
	"animal_cat_1.ogg",
	"animal_cat_2.ogg",
	"animal_cute_dog_1.ogg",
	"animal_cute_dog_2.ogg",
	"animal_dog_growl.ogg",
	"animal_dog_low_growl.ogg",
	"animal_horse_1.ogg",
	"animal_horse_2.ogg",
	"animal_monster_2.ogg",
	"animal_skeleton_move.ogg",
	"animal_zombie_1.ogg",
	"animal_zombie_2.ogg",
	"atnr001.ogg",
	"atnr002.ogg",
	"atnr003.ogg",
	"battle_1.ogg",
	"battle_2.ogg",
	"battle_3.ogg",
	"battle_4.ogg",
	"bly001.ogg",
	"btl002.ogg",
	"button-back.ogg",
	"button-confirm.ogg",
	"button-next-day.ogg",
	"card_highlight_1.ogg",
	"card-begin-drag.ogg",
	"card-end-drag.ogg",
	"dice_failed.ogg",
	"dice_show.ogg",
	"dice_success.ogg",
	"dragon_slayer.ogg",
	"draw_sudan_card_desire.ogg",
	"draw_sudan_card_kill.ogg",
	"draw_sudan_card_war.ogg",
	"draw_sudan_card_wastefulness.ogg",
	"drawcard.ogg",
	"drop_card_copper.ogg",
	"drop_card_gold.ogg",
	"drop_card_silver.ogg",
	"final_battle_facing_sultan.ogg",
	"flj001.ogg",
	"flj002.ogg",
	"flj003.ogg",
	"fls001.ogg",
	"fls002.ogg",
	"fls003.ogg",
	"ftn001.ogg",
	"ftn002.ogg",
	"gls001.ogg",
	"gs001.ogg",
	"gs002.ogg",
	"gs003.ogg",
	"hbb001.ogg",
	"hmr001.ogg",
	"hmr002.ogg",
	"hmr003.ogg",
	"hs001.ogg",
	"hs002.ogg",
	"hs003.ogg",
	"item_army.ogg",
	"item_book.ogg",
	"item_clothing.ogg",
	"item_coin.ogg",
	"item_metal.ogg",
	"item_paper.ogg",
	"item_potion.ogg",
	"item_powerful_magical.ogg",
	"item_scroll.ogg",
	"item_small.ogg",
	"item_tornado_1.ogg",
	"item_tornado_2.ogg",
	"item_weight.ogg",
	"ithink_close.ogg",
	"jll001.ogg",
	"jmr001.ogg",
	"jmr002.ogg",
	"kj001.ogg",
	"lljk001.ogg",
	"lljk002.ogg",
	"lljk003.ogg",
	"lml001.ogg",
	"lml002.ogg",
	"lyd001.ogg",
	"lyd002.ogg",
	"lyd003.ogg",
	"main_game_level1.ogg",
	"main_game_level2.ogg",
	"main_game_level3.ogg",
	"mg001.ogg",
	"mg002.ogg",
	"mg003.ogg",
	"mm001.ogg",
	"mm002.ogg",
	"mm003.ogg",
	"mm004.ogg",
	"mm005.ogg",
	"mm006.ogg",
	"mm007.ogg",
	"mmzs001.ogg",
	"mmzs002.ogg",
	"mrjn002.ogg",
	"mxr001.ogg",
	"mxr002.ogg",
	"mxr003.ogg",
	"nbhn001.ogg",
	"nbhn002.ogg",
	"nbhn003.ogg",
	"nlnn001.ogg",
	"nn001.ogg",
	"nyl001.ogg",
	"nyl002.ogg",
	"nyl003.ogg",
	"over_game_china.ogg",
	"over_game_dead.ogg",
	"over_game_great_cause.ogg",
	"over_game_happiness.ogg",
	"over_game_nothingness.ogg",
	"over_game_sublime.ogg",
	"over_game_trapped_beast.ogg",
	"rn001.ogg",
	"rn002.ogg",
	"secret_journey.ogg",
	"seeds_of_history.ogg",
	"settle_card_new_bad.ogg",
	"settle_card_new_great.ogg",
	"settle_card_new_nomal.ogg",
	"sjg001.ogg",
	"sl001.ogg",
	"slwr001.ogg",
	"slwr003.ogg",
	"the_last_sultan_card.ogg",
	"tt001.ogg",
	"tutorial_main_game.ogg",
	"void_flight.ogg",
	"weapon_armor.ogg",
	"weapon_edge.ogg",
	"weapon_rare.ogg",
	"wqr002.ogg",
	"xl001.ogg",
	"xm001.ogg",
	"xy001.ogg",
	"xy002.ogg",
	"xy003.ogg",
	"ym001.ogg",
	"ym002.ogg",
	"ymcf002.ogg",
	"zbr001.ogg",
	"zbr002.ogg",
	"zn001.ogg",
	"zn002.ogg",
	"zqy001.ogg",
	"zqy002.ogg",
	"zwd001.ogg",
	"zwd002.ogg",
	"zwd003.ogg",
]


## Every clip name the clone can reach, BGM included. Used by the cue-surface
## test so a renamed or invented clip fails loudly instead of playing silently.
static func all_clip_names() -> Array:
	var out: Array = CUE_CLIPS.duplicate()
	for track in BGM_TRACKS.values():
		if not out.has(track):
			out.append(track)
	for cue_file in SUDAN_DRAW_CUES.values():
		if not out.has(cue_file):
			out.append(cue_file)
	return out


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


## The armageddon loop table from content/sfx_config.json, keyed by rite config
## id. Every entry is {clip, start, loop_start, loop_end} with optional
## play_in_rite_create / play_instant flags.
##
## The audit previously recorded the armageddon clip name as "not derivable from
## the corpus". It is: sfx_config.json carries `armageddon_music_loop` with 22
## rite-id -> clip entries, and LoopArmageddonController.GetLoopData 0x4033f0
## reads exactly that table (Datapool+0x68 -> +0x60 -> +0xB0 -> +0x38) keyed by
## the controller's config id (+0x48); GetClip 0x403240 then resolves the entry's
## clip name to an AudioClip. Start 0x403e80 logs an error when the name is empty.
## [SRC: _unpack/data/config/sfx_config.json; LoopArmageddonController.c @
##       GetLoopData / GetClip / PlayArmageddon 0x403520 / Update 0x404110;
##       SFxStatePlayLoopArmageddon.c @ OnStateEnter 0x407d90.]
const ARMAGEDDON_TABLE_KEY := "armageddon_music_loop"


## Every rite id the source's armageddon loop table covers, as ints.
static func armageddon_rite_ids(config) -> Array:
	var table := _armageddon_table(config)
	var out: Array = []
	for key in table:
		var id := str(key).to_int()
		if id > 0:
			out.append(id)
	out.sort()
	return out


## Resolve the loop data for one armageddon rite id. Returns {} when the rite is
## not in the armageddon table, which is the clone's equivalent of the source's
## "clip name is empty -> LogError" path.
static func armageddon_loop_for(config, rite_id: int) -> Dictionary:
	if rite_id <= 0:
		return {}
	var entry: Variant = _armageddon_table(config).get(str(rite_id), null)
	if entry is Dictionary:
		return entry
	return {}


static func armageddon_clip_for(config, rite_id: int) -> String:
	return _cue_file(str(armageddon_loop_for(config, rite_id).get("clip", "")))


static func _armageddon_table(config) -> Dictionary:
	if config == null or config.get("sfx_config") == null:
		return {}
	var table: Variant = config.sfx_config.get(ARMAGEDDON_TABLE_KEY, {})
	if table is Dictionary:
		return table
	return {}


## Character voice lines for one card id, as .ogg file names in the table's own
## order. The order is meaningful: the source plays variant N for repeat lines.
##
## This closes the audit's "~391 character-dub filenames -> call sites live in
## unexported .cs" note the same way the armageddon clip did: the mapping is
## configuration, not code.
## [SRC: _unpack/data/config/sfx_npc_role_dub.json (584 card ids, 579 non-empty,
##       670 references over 123 unique clips; every one exists in
##       Assets/AudioClip). Card 2000029 -> ["item_coin"], which pins the key as
##       CardNode.id rather than a character id.]
static func npc_dub_files(config, card_id: int) -> Array:
	var out: Array = []
	if config == null or config.get("npc_role_dub") == null or card_id <= 0:
		return out
	var table: Variant = config.npc_role_dub
	if not (table is Dictionary):
		return out
	var row: Variant = (table as Dictionary).get(str(card_id), null)
	if not (row is Array):
		return out
	for name in (row as Array):
		var clip := str(name)
		if clip.is_empty():
			continue
		out.append(clip if clip.ends_with(".ogg") else clip + ".ogg")
	return out


## One voice line by index, clamped into range; "" when the card has none.
static func npc_dub_file(config, card_id: int, index: int = 0) -> String:
	var files := npc_dub_files(config, card_id)
	if files.is_empty():
		return ""
	return str(files[clampi(index, 0, files.size() - 1)])


## Specific card overrides first, then character/non-character defaults.
## [SRC: OpCardNewController.PlaySFx 0x5744b0; original
## content/sfx_settle_card_new.json explicitly assigns defaults 1/0.]
static func settle_card_cue(config, card_id: int) -> String:
	return _cue_file(_settle_lookup(config, card_id))


static func _settle_lookup(config, card_id: int) -> String:
	if config == null or config.get("settle_card_new") == null:
		return ""
	var table: Variant = config.settle_card_new
	if not (table is Dictionary):
		return ""
	var dict := table as Dictionary
	var specific: Variant = dict.get(str(card_id), null)
	if specific is String and not (specific as String).is_empty():
		return str(specific)
	var card: Dictionary = config.get_card(card_id)
	var fallback: Variant = dict.get("1" if str(card.get("type", "")) == "char" else "0", null)
	return str(fallback) if fallback is String else ""


## Ending music entry for an over/ending id: {clip, start, loop_start, loop_end}.
## Same shape as the sfx_config loop tables, keyed by the id over.json uses as
## its property key. The table's own fallback key is "-1" (it plays the same clip
## as endings 1..7), so negative ids are valid lookups and must not be filtered.
## 10 of the 159 endings declare no music of their own.
## [SRC: _unpack/data/config/over_music_config.json]
static func over_music_entry(config, over_id: int) -> Dictionary:
	if config == null or config.get("over_music") == null:
		return {}
	var table: Variant = config.over_music
	if not (table is Dictionary):
		return {}
	var entry: Variant = (table as Dictionary).get(str(over_id), null)
	if entry is Dictionary:
		return entry
	return {}


static func over_music_clip(config, over_id: int) -> String:
	return _cue_file(str(over_music_entry(config, over_id).get("clip", "")))


static func _cue_file(clip: String) -> String:
	if clip.is_empty():
		return ""
	return clip if clip.ends_with(".ogg") else clip + ".ogg"


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
