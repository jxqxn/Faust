extends GutTest


## Audio cue surface: every clip the clone can play must be an original
## AudioClip file name that the clone actually carries. A renamed or invented
## cue would otherwise fail silently, because play() degrades to a no-op on a
## missing resource.
## [SRC: _unpack/unity_export/ExportedProject/Assets/AudioClip/*.ogg;
##       ui/audio_manager.gd AUDIO_DIR / BGM_TRACKS / SUDAN_DRAW_CUES / CUE_CLIPS]

const GameAudio = preload("res://ui/audio_manager.gd")
const AUDIO_DIR := "res://assets/original/audio/"


func test_every_referenced_clip_exists() -> void:
	var clips: Array = GameAudio.all_clip_names()
	assert_gt(clips.size(), 20, "the cue surface is registered")
	for clip in clips:
		assert_true(ResourceLoader.exists(AUDIO_DIR + str(clip)),
			"cue asset must exist: " + str(clip))


func test_bgm_tracks_and_sudan_cues_are_registered() -> void:
	var clips: Array = GameAudio.all_clip_names()
	for track in GameAudio.BGM_TRACKS.values():
		assert_true(clips.has(track), "BGM track %s is part of the cue surface" % track)
	for cue_file in GameAudio.SUDAN_DRAW_CUES.values():
		assert_true(clips.has(cue_file), "Sultan draw cue %s is part of the cue surface" % cue_file)


func test_sudan_draw_families_map_to_distinct_clips() -> void:
	var seen: Dictionary = {}
	for action in ["纵欲", "杀戮", "征服", "奢靡"]:
		var clip: String = str(GameAudio.SUDAN_DRAW_CUES.get(action, ""))
		assert_false(clip.is_empty(), "%s has a draw cue" % action)
		assert_false(seen.has(clip), "%s must not share a cue with another family" % action)
		seen[clip] = action
	assert_eq(seen.size(), 4, "all four Sultan card families are covered")


func test_missing_clip_degrades_without_playing() -> void:
	# play() must stay a silent no-op for an unknown cue rather than pushing an
	# error, so headless and partial-content environments keep deterministic.
	var audio := GameAudio.new()
	add_child_autofree(audio)
	assert_null(audio._load_stream("does_not_exist.ogg"),
		"an unknown clip resolves to null instead of exploding")
	audio.play("does_not_exist.ogg")
	assert_eq(audio._sfx_players.size(), 8, "player pool is unchanged by a failed cue")


# ---- sfx_config.json: the armageddon loop table ----------------------------
#
# The audit used to record the armageddon clip name as "comes from an editor
# field, no such string in the corpus, not derivable". That was a search-scope
# error: the table is content/sfx_config.json -> armageddon_music_loop, keyed by
# rite config id. These tests pin the table, its accessor, and the requirement
# that every clip it names is actually present in the project.
# [SRC: LoopArmageddonController.c @ GetLoopData 0x4033f0 / GetClip 0x403240 /
#       Start 0x403e80; SFxStatePlayLoopArmageddon.c @ OnStateEnter 0x407d90]


func _db() -> ConfigDB:
	var local_db := ConfigDB.new()
	local_db.load_all()
	return local_db


func test_sfx_config_is_loaded_from_content() -> void:
	var local_db := _db()
	assert_false(local_db.sfx_config.is_empty(),
		"content/sfx_config.json is required, not optional: it is the clip-name source")
	for key in ["main_game_loop", "settle_loop", "armageddon_music_loop"]:
		assert_true(local_db.sfx_config.has(key), "sfx_config carries the %s table" % key)


func test_armageddon_table_covers_the_configured_rites() -> void:
	var local_db := _db()
	var ids: Array = GameAudio.armageddon_rite_ids(local_db)
	assert_eq(ids.size(), 22, "the armageddon_music_loop table has 22 rite entries")
	# Spot-check the two shapes the table uses: a plain loop and an instant one.
	var journey := GameAudio.armageddon_loop_for(local_db, 5003027)
	assert_eq(str(journey.get("clip", "")), "secret_journey")
	assert_eq(float(journey.get("loop_start", -1)), 0.0)
	assert_eq(float(journey.get("loop_end", -1)), -1.0)
	var instant := GameAudio.armageddon_loop_for(local_db, 5006079)
	assert_eq(str(instant.get("clip", "")), "final_battle_facing_sultan")
	assert_true(bool(instant.get("play_instant", false)), "an instant entry keeps its flag")


func test_armageddon_lookup_returns_empty_for_an_unknown_rite() -> void:
	var local_db := _db()
	assert_eq(GameAudio.armageddon_loop_for(local_db, 9999999), {},
		"a rite outside the table resolves to nothing, the clone's empty-clip path")
	assert_eq(GameAudio.armageddon_loop_for(local_db, 0), {})
	assert_eq(GameAudio.armageddon_clip_for(local_db, 9999999), "")
	assert_eq(GameAudio.armageddon_loop_for(null, 5003027), {},
		"a missing config must not throw")


func test_armageddon_clip_names_are_resolvable_clip_files() -> void:
	var local_db := _db()
	var ids: Array = GameAudio.armageddon_rite_ids(local_db)
	assert_gt(ids.size(), 0, "fixture guard: the table was read")
	for rite_id in ids:
		var file: String = GameAudio.armageddon_clip_for(local_db, int(rite_id))
		assert_false(file.is_empty(), "rite %d names a clip" % int(rite_id))
		assert_true(file.ends_with(".ogg"), "and it resolves to an .ogg name")
		# GetClip 0x403240 falls back to the built-in array; a name with no asset
		# is the source's silent-null case, which must not happen for real config.
		assert_true(ResourceLoader.exists(AUDIO_DIR + file),
			"rite %d's clip %s exists in the clone" % [int(rite_id), file])


func test_armageddon_clips_are_registered_on_the_cue_surface() -> void:
	# A clip that exists on disk but is absent from CUE_CLIPS is invisible to the
	# cue-surface test, so keep the two in sync.
	var local_db := _db()
	var clips: Array = GameAudio.all_clip_names()
	for rite_id in GameAudio.armageddon_rite_ids(local_db):
		var file: String = GameAudio.armageddon_clip_for(local_db, int(rite_id))
		assert_true(clips.has(file), "%s is registered in CUE_CLIPS" % file)


func test_main_game_loop_clip_names_also_exist() -> void:
	# The same config drives the ordinary BGM loop table; check it too so the file
	# cannot be half-integrated.
	var local_db := _db()
	var tables: Variant = local_db.sfx_config.get("main_game_loop", {})
	assert_true(tables is Dictionary and not (tables as Dictionary).is_empty(),
		"main_game_loop is present")
	for level in (tables as Dictionary):
		var entry: Variant = (tables as Dictionary)[level]
		if not (entry is Dictionary):
			continue
		var file := str((entry as Dictionary).get("clip", ""))
		if file.is_empty():
			continue
		assert_true(ResourceLoader.exists(AUDIO_DIR + file + ".ogg"),
			"main_game_loop[%s] clip %s exists" % [str(level), file])


# ---- sfx_npc_role_dub.json: the character dub table -------------------------
#
# The audit recorded "~391 character-dub / ambient clip filenames have their
# file->call-site mapping in unexported .cs, so they cannot be diffed one by
# one". That reasoning had the same flaw as the armageddon clip: the mapping is
# configuration. sfx_npc_role_dub.json maps card id -> ordered voice clip names.


func test_npc_dub_table_is_loaded_and_shaped_as_expected() -> void:
	var local_db := _db()
	assert_false(local_db.npc_role_dub.is_empty(), "the dub table is required content")
	assert_eq(local_db.npc_role_dub.size(), 584, "584 card entries")
	var non_empty := 0
	for key in local_db.npc_role_dub:
		var row: Variant = local_db.npc_role_dub[key]
		assert_true(row is Array, "entry %s is a list of clip names" % str(key))
		if row is Array and not (row as Array).is_empty():
			non_empty += 1
	assert_eq(non_empty, 579, "579 entries actually name a voice line")


func test_npc_dub_key_domain_is_card_id() -> void:
	# 2000029 is the gold coin card, whose only "voice" is the coin sound. That
	# pins the key as CardNode.id rather than a character id.
	var local_db := _db()
	assert_eq(GameAudio.npc_dub_files(local_db, 2000029), ["item_coin.ogg"],
		"card 2000029 -> item_coin")
	assert_true(local_db.get_card(2000029).has("id"), "and 2000029 really is a card id")
	assert_eq(int(local_db.get_card(2000029).get("id", 0)), 2000029)


func test_npc_dub_order_is_preserved_and_index_is_clamped() -> void:
	var local_db := _db()
	var files: Array = GameAudio.npc_dub_files(local_db, 2000006)
	assert_eq(files, ["mg001.ogg", "mg002.ogg", "mg003.ogg"],
		"the table's own order is the playback order")
	assert_eq(GameAudio.npc_dub_file(local_db, 2000006, 0), "mg001.ogg")
	assert_eq(GameAudio.npc_dub_file(local_db, 2000006, 2), "mg003.ogg")
	assert_eq(GameAudio.npc_dub_file(local_db, 2000006, 99), "mg003.ogg",
		"an out-of-range index clamps instead of failing")
	assert_eq(GameAudio.npc_dub_file(local_db, 2000006, -5), "mg001.ogg")


func test_npc_dub_empty_and_unknown_entries_resolve_to_nothing() -> void:
	var local_db := _db()
	assert_eq(GameAudio.npc_dub_files(local_db, 2000001), [],
		"card 2000001 has an empty list in the source table")
	assert_eq(GameAudio.npc_dub_file(local_db, 2000001), "")
	assert_eq(GameAudio.npc_dub_files(local_db, 9999999), [], "an unknown card is silent")
	assert_eq(GameAudio.npc_dub_files(null, 2000006), [], "a missing config must not throw")
	assert_eq(GameAudio.npc_dub_files(local_db, 0), [])


func test_every_npc_dub_clip_is_present_and_registered() -> void:
	var local_db := _db()
	var seen: Dictionary = {}
	for key in local_db.npc_role_dub:
		for file in GameAudio.npc_dub_files(local_db, int(str(key).to_int())):
			var name := str(file)
			if seen.has(name):
				continue
			seen[name] = true
			assert_true(ResourceLoader.exists(AUDIO_DIR + name),
				"dub clip %s exists in the project" % name)
	assert_eq(seen.size(), 123, "123 unique voice clips are referenced")
	var clips: Array = GameAudio.all_clip_names()
	for name in seen:
		assert_true(clips.has(name), "%s is registered on the cue surface" % str(name))


# ---- sfx_settle_card_new.json ----------------------------------------------


func test_settle_card_cue_uses_specific_then_default() -> void:
	var local_db := _db()
	assert_false(local_db.settle_card_new.is_empty(), "the settle table is required content")
	assert_eq(GameAudio.settle_card_cue(local_db, 2000083), "settle_card_new_bad.ogg",
		"a listed card gets its own cue")
	assert_eq(GameAudio.settle_card_cue(local_db, 2000029), "settle_card_new_nomal.ogg",
		"an unlisted item falls back to the table's 0 key")
	assert_eq(GameAudio.settle_card_cue(local_db, 2000006), "settle_card_new_great.ogg",
		"the wife's character card uses the source character default")
	assert_eq(GameAudio.settle_card_cue(local_db, 2000001), "settle_card_new_great.ogg",
		"unlisted characters use the source table's 1 key")
	assert_eq(GameAudio.settle_card_cue(local_db, 9999999), "settle_card_new_nomal.ogg",
		"and so does an unknown one -- the fallback is not silence")
	assert_eq(GameAudio.settle_card_cue(null, 2000006), "", "a missing config is silent")
	for key in local_db.settle_card_new:
		var file := str(local_db.settle_card_new[key])
		assert_true(ResourceLoader.exists(AUDIO_DIR + file + ".ogg"),
			"settle cue %s exists" % file)


# ---- over_music_config.json ------------------------------------------------


func test_over_music_entries_and_clips() -> void:
	var local_db := _db()
	assert_false(local_db.over_music.is_empty(), "the ending-music table is required content")
	var first: Dictionary = GameAudio.over_music_entry(local_db, 1)
	assert_false(first.is_empty(), "ending 1 has a music entry")
	for field in ["clip", "start", "loop_start", "loop_end"]:
		assert_true(first.has(field), "an ending entry carries %s like the loop tables" % field)
	assert_eq(GameAudio.over_music_entry(local_db, 9999999), {}, "unknown ending -> nothing")
	assert_eq(GameAudio.over_music_entry(null, 1), {})
	assert_eq(GameAudio.over_music_clip(local_db, 1), "over_game_dead.ogg")
	var seen: Dictionary = {}
	for key in local_db.over_music:
		var clip := GameAudio.over_music_clip(local_db, int(str(key).to_int()))
		if clip.is_empty():
			continue
		seen[clip] = true
		assert_true(ResourceLoader.exists(AUDIO_DIR + clip), "ending clip %s exists" % clip)
	assert_gt(seen.size(), 0, "at least one distinct ending clip")


func test_over_music_ids_are_real_endings() -> void:
	# The table is keyed by the ending id, which in over.json is the *property
	# key* -- the nodes themselves carry no id field. (ui/game_over.gd reads
	# ending_id from state/record and looks it up against those keys.)
	# [SRC: _unpack/data/config/over_music_config.json has 150 entries: ids
	#       1..604 plus a -1 fallback; content/over.json is a 159-key object.]
	var local_db := _db()
	var parsed = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/over.json"))
	assert_true(parsed is Dictionary, "content/over.json parses as the ending table")
	var endings: Dictionary = parsed
	assert_gt(endings.size(), 100, "the ending table is the full one")
	var missing: Array = []
	var covered := 0
	for key in local_db.over_music:
		var id := str(key)
		if id == "-1":
			continue
		if endings.has(id):
			covered += 1
		else:
			missing.append(int(id))
	assert_eq(missing, [], "every over_music key resolves to an ending in over.json")
	assert_eq(covered, 149, "149 of the 150 entries are real ending ids")
	# -1 is the table's own fallback, not an ending: it resolves to the same clip
	# as endings 1..7, i.e. the "no specific ending" entry.
	assert_eq(GameAudio.over_music_clip(local_db, -1), GameAudio.over_music_clip(local_db, 1),
		"the -1 fallback plays the same clip as the default endings")
	# The reverse is not total: some endings have no music entry of their own.
	var without_music: Array = []
	for key in endings:
		if not local_db.over_music.has(str(key)):
			without_music.append(str(key))
	assert_eq(without_music, ["0", "15", "40", "999", "204", "273", "274", "289", "290", "291"],
		"exactly these endings declare no ending music of their own")
