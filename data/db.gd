## Config database: loads and indexes the game's config JSON.
## Single source of truth for cards/rites/loot/tags/init at runtime.
class_name ConfigDB
extends RefCounted

const ResultExecScript = preload("res://sim/result.gd")

const NORMAL_DEFAULT_CARDS: Array[int] = [2000001, 2000006, 2000523, 2000005]
const NORMAL_DEFAULT_RITES: Array[int] = [
	5000001, # 治理家业
	5001001, # 权力的游戏
	5001501, # 浴场里的消息
	5002006, # 书店营业
	5001006, # 探访监狱
	5001008, # 囚牢
	5002001, # 医馆
	5002036, 5002037, 5002038, # 淘书 variants
	5002003, 5002004, 5002005, 5002035, # 欢愉之馆 variants
]

var cards := {}            # id(int) -> card dict
var cards_by_str := {}     # id(str) -> card dict (config uses string keys)
var rites := {}            # id(int) -> rite dict
var loots := {}            # id(int) -> loot dict
var events := {}           # id(int) -> event dict
var after_stories := {}    # id(int/card id) -> AfterStoryNode dict
var quests := {}           # id(int) -> QuestNode dict
var upgrades := {}         # id(int) -> UpgradeNode dict
var credits := {}          # original singleton CreditsNode
# Runtime-only Datapool.over_ids HashSet<string>. This is distinct from
# Global.overID HashSet<int>, which unlocks gallery CG across runs.
var over_ids := {}
var tags_by_code := {}     # code -> tag dict
var tags_by_id := {}       # id(int) -> tag dict
var tag_name_to_code := {} # name -> code
# Inverse of tag_name_to_code. The original keeps two tag key domains: config
# files (CardNode.tag@0x58) are keyed by the localized name, while the runtime
# Card.tag@0x30 dictionary and the save file are keyed by the stable code.
# [SRC: dump.cs CardNode.tag@0x58 / Card.tag@0x30; Datapool.c @ TranslateTag
#       (0x41bc20); save_samples/auto_save.json stores {"social":1,"charm":1}.]
var tag_code_to_name := {} # code -> name
var init_config := {}      # init/1.json contents
# variable.json: the global preferences/config table (result text rates, ui
# scale, supported resolutions, pop timing). Runtime values are read from here
# instead of being re-typed at call sites.
# [SRC: _unpack/data/config/variable.json; RiteResultPanelController.c @
#       UpdateResultTextSpeed 0x5a74a0 reads the two result rates off Player,
#       which Datapool seeds from this table.]
var variable_config := {}
# The wizard (女术士) dialogue node that hosts the draw-Sultan demonstration.
# Datapool keeps it in a wizard dictionary (Datapool+0x40) keyed by the wizard
# id, and MagicSudan.Do registers a directive that WizardController consumes.
# [SRC: _unpack/data/config/wizard/wizard.json + wizard_sudan.json;
#       MagicSudan.c @ .ctor 0x5153f0 -> Datapool.AddMagicSudan;
#       WizardController.c @ LoadWizard 0x5cbdf0 reads Datapool+0x40.]
var wizard_config := {}
# sfx_config.json: the source's music/sfx loop tables. This is where clip names
# and loop points come from -- the audit's earlier "the volume clip name is not
# in any config" note was a search-scope error, not a data gap.
# Top-level keys: main_game_loop / main_game_loop_difficulty / settle_loop /
# settle_loop_difficulty / armageddon_music_loop. Every entry is
# {clip, start, loop_start, loop_end} plus optional flags
# (play_in_rite_create / play_instant).
# [SRC: _unpack/data/config/sfx_config.json;
#       LoopArmageddonController.c @ GetLoopData 0x4033f0 reads the table at
#       Datapool+0x68 -> +0x60 -> +0xB0 -> +0x38 keyed by the controller's
#       config id (+0x48); GetClip 0x403240 maps the entry's clip name to an
#       AudioClip via Datapool.LoadModAudioClip then the built-in array.]
var sfx_config := {}
# sfx_npc_role_dub.json: character card id -> ordered list of voice clip names.
# This is the table the audit recorded as missing ("~391 dub filenames -> call
# sites live in unexported .cs"). The mapping is data, not code: 584 card ids,
# 579 of them non-empty, 670 references over 123 unique clips.
# [SRC: _unpack/data/config/sfx_npc_role_dub.json. Card 2000029 -> ["item_coin"]
#       ties the key domain to CardNode.id.]
var npc_role_dub := {}
# sfx_settle_card_new.json: card id -> settlement cue name. The "0" key is the
# default, so the table is a sparse override on top of a generic cue.
# Values: settle_card_new_nomal / _great / _bad.
# [SRC: _unpack/data/config/sfx_settle_card_new.json]
var settle_card_new := {}
# over_music_config.json: ending id -> {clip, start, loop_start, loop_end}, the
# same entry shape as sfx_config's loop tables. Keyed by the over/ending id that
# over.json also uses.
# [SRC: _unpack/data/config/over_music_config.json]
var over_music := {}
var use_test_starting_cards := false
# [SRC: Datapool.custom_card_text@0x110; MergeCustomTextToDefaultLanguage
# 0x417dc0. Runtime index of original operation values, not rewritten content.]
var custom_card_translates: Dictionary = {}
# The original's default-language text table, i.e. the dictionary
# Datapool.Translate looks a key up in.
#
# `data/config/ui.json` is that table: a flat `KEY -> {zhCN, comment}` map whose
# `zhCN` values are the game's default display language (simplified Chinese).
# `data/i18n/<locale>/` holds the *translations* of that same key space -- zhTW
# is traditional Chinese and en is English -- so consuming those instead would
# silently switch the clone's language. Only the default table is loaded here.
#
# This is what every TipsHolder.TipsId and every TextTranslate `key:` field
# resolves against; without it the tooltip layer has no text source at all.
# [SRC: _unpack/data/config/ui.json (1669 lines, flat key->{zhCN,comment}) plus
#       the _TEXT keys in the per-domain configs (e.g. sfx_config's clip
#       captions); Datapool.c @ Translate (RVA 0x422740): dictionary lookup on
#       the translator objects wired at Datapool+0x268 / +600, returning the
#       input key unchanged when neither has it.]
var translations: Dictionary = {}
# The second dictionary Datapool.Translate falls back to. The clone keeps the
# tooltip caption table (ui.json) separate from the general text table so a
# missing caption cannot be masked by a same-named general key, and so
# `has_translation` can answer for the tips surface specifically.
# [SRC: Datapool.c @ Translate 0x422740 second TryGetValue against +600.]
var ui_translations: Dictionary = {}


func load_all(content_dir: String = "res://content", use_test_cards: bool = false) -> void:
	use_test_starting_cards = use_test_cards
	_load_translations(content_dir)
	_load_tags(content_dir + "/tag.json")
	_load_cards(content_dir + "/cards.json")
	_load_dir(content_dir + "/rite", rites)
	_load_dir(content_dir + "/event", events)
	_load_dir(content_dir + "/after_story", after_stories)
	_load_dir(content_dir + "/loot", loots)
	_load_map(content_dir + "/quest.json", quests)
	_load_map(content_dir + "/upgrade.json", upgrades)
	_load_single(content_dir + "/credits.json", credits)
	_load_single(content_dir + "/variable.json", variable_config)
	_load_single(content_dir + "/sfx_config.json", sfx_config)
	_load_single(content_dir + "/sfx_npc_role_dub.json", npc_role_dub)
	_load_single(content_dir + "/sfx_settle_card_new.json", settle_card_new)
	_load_single(content_dir + "/over_music_config.json", over_music)
	_load_dir_by_string_id(content_dir + "/wizard", wizard_config)
	_load_init(content_dir + "/init/1.json")
	custom_card_translates.clear()
	for source in [cards, rites, events, after_stories, loots, quests, upgrades, init_config]:
		_index_custom_card_text(source)


static func custom_card_text_key(operation: String) -> String:
	var parts := operation.split(".")
	var offset := 1 if parts[0] in ["table", "total"] else 0
	if parts.size() == offset + 3 and parts[offset] in ["change_card_name", "change_card_text"]:
		# [SRC: ChangeCardName .ctor0x4f2a30; stringliteral0x2595cb0 /
		# 0x25794c0 / 0x259a4e0 / 0x257f458 = change_card_ / name / text / _.]
		return parts[offset] + "_" + parts[offset + 1]
	return ""


func _index_custom_card_text(value: Variant) -> void:
	if value is Dictionary:
		for operation in value:
			var key := custom_card_text_key(str(operation))
			var item: Variant = value[operation]
			if not key.is_empty() and item is String:
				if custom_card_translates.has(key) and custom_card_translates[key] != item:
					push_error("Conflicting source custom card text: " + key)
				else:
					custom_card_translates[key] = item
			_index_custom_card_text(item)
	elif value is Array:
		for item in value:
			_index_custom_card_text(item)


func translate_custom_card_text(key: String) -> String:
	# The original default-language fallback; locale/mod overlays remain open.
	# [SRC: Datapool.Translate0x422740 returns the key if not found.]
	return str(custom_card_translates.get(key, key))


## Datapool.Translate: main table first, ui overlay second, then the input key.
## The clone never rewrites the tables -- both files are byte-identical copies
## of the source's own i18n output for the display language.
## [SRC: Datapool.c @ Translate (RVA 0x422740): TryGetValue on the translator at
##       Datapool+0x268, then on the one at +600; falling through both returns
##       the original string.]
func translate(key: Variant) -> String:
	var text := str(key)
	if text.is_empty():
		return text
	if translations.has(text):
		return str(translations[text])
	if ui_translations.has(text):
		return str(ui_translations[text])
	return text


## Keys that exist in the source's own text tables. The clone uses this to tell
## "the source names a string the player sees" apart from "the type is still on
## the numeric fallback", so a missing table entry cannot masquerade as text.
func has_translation(key: Variant) -> bool:
	var text := str(key)
	return translations.has(text) or ui_translations.has(text)


func _load_translations(content_dir: String) -> void:
	translations.clear()
	ui_translations.clear()
	# `_load_single` would also pull the per-entry `comment` field into the map;
	# only the caption value is a translation.
	_load_captions(content_dir + "/ui.json", ui_translations)


func _load_captions(path: String, dest: Dictionary) -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return
	for key in parsed:
		var entry: Variant = parsed[key]
		if entry is String:
			dest[str(key)] = entry
		elif entry is Dictionary:
			# ui.json entries are {zhCN, comment}; zhCN is the default language.
			var caption := str(entry.get("zhCN", ""))
			if not caption.is_empty():
				dest[str(key)] = caption


func _load_init(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("ConfigDB: missing init at %s" % path)
		return
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		init_config = parsed


func _load_single(path: String, dest: Dictionary) -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		dest.assign(parsed)


func _load_tags(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return
	for code in parsed:
		var td: Dictionary = parsed[code]
		tags_by_code[code] = td
		var id := int(td.get("id", 0))
		if id:
			tags_by_id[id] = td
		var nm: String = td.get("name", "")
		if nm != "":
			tag_name_to_code[nm] = code
			tag_code_to_name[code] = nm


func _load_cards(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return
	for key in parsed:
		var cd: Dictionary = parsed[key]
		var id := int(cd.get("id", key.to_int()))
		cards[id] = cd
		cards_by_str[str(id)] = cd


func _load_map(path: String, dest: Dictionary) -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return
	for key in parsed:
		var node: Dictionary = parsed[key]
		var id := int(node.get("id", str(key).to_int()))
		dest[id] = node


func _load_dir(dir_path: String, dest: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			var full := dir_path + "/" + fname
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(full))
			if parsed is Dictionary:
				var id := int(parsed.get("id", fname.get_basename().to_int()))
				dest[id] = parsed
		fname = dir.get_next()
	dir.list_dir_end()


## Directory loader for node files whose `id` is a STRING (the wizard nodes use
## "WIZARD" / "WIZARD_SUDAN"). `_load_dir` would collapse both to key 0 and keep
## only the last one.
## [SRC: Datapool wizard dictionary keyed by WizardNode.id (Datapool+0x40);
##       _unpack/data/config/wizard/*.json]
func _load_dir_by_string_id(dir_path: String, dest: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(dir_path + "/" + fname))
			if parsed is Dictionary:
				var id := str(parsed.get("id", fname.get_basename()))
				dest[id] = parsed
		fname = dir.get_next()
	dir.list_dir_end()


func get_card(id: int) -> Dictionary:
	return cards.get(id, {})


## Runtime config loading in the original replaces localized tag names with
## their stable codes. Most clone gameplay still consumes the raw original
## config names, but persisted engine-facing registries (such as gen_tags)
## must use that same code identity.
## [SRC: Datapool._LoadConfig_d__154.c @ tag dictionary/list translation;
##       Datapool.c @ TranslateTag (0x41bc20)]
func tag_code_for(raw_tag: Variant) -> String:
	var tag_name := str(raw_tag)
	if tag_name.is_empty() or tags_by_code.has(tag_name):
		return tag_name
	if tag_name_to_code.has(tag_name):
		return str(tag_name_to_code[tag_name])
	# The original recursively translates either side of a compound tag key.
	if tag_name.contains(":"):
		var parts := tag_name.split(":", false)
		if parts.size() == 2:
			return "%s:%s" % [tag_code_for(parts[0]), tag_code_for(parts[1])]
	return tag_name


func get_rite(id: int) -> Dictionary:
	return rites.get(id, {})


func get_loot(id: int) -> Dictionary:
	return loots.get(id, {})


func get_event(id: int) -> Dictionary:
	return events.get(id, {})


func get_after_story(id: int) -> Dictionary:
	# [SRC: dump.cs Datapool.after_story @0x70 / AfterStoryNode fields
	# @ dump.cs:389342] The source dictionary is keyed by the character card id.
	return after_stories.get(id, {})


func get_quest(id: int) -> Dictionary:
	return quests.get(id, {})


func get_upgrade(id: int) -> Dictionary:
	return upgrades.get(id, {})


## Apply every active purchased UpgradeNode in ascending id order.  The raw
## `effect` dictionary is passed straight to the operation dispatcher; there
## is no clone-side upgrade DTO or rewritten effect table.
## [SRC: Datapool.c @ DoUpgrade (RVA 0x410dc0): copy Global.upgrade.Keys,
##       Sort, skip value==0, lookup raw UpgradeNode, execute effect ops]
func do_upgrade(state) -> void:
	if state == null or state.global_state == null:
		return
	var ids: Array[int] = []
	for raw_id in state.global_state.upgrades.keys():
		ids.append(int(raw_id))
	ids.sort()
	for upgrade_id in ids:
		if int(state.global_state.upgrades.get(upgrade_id, 0)) == 0:
			continue
		var upgrade := get_upgrade(upgrade_id)
		if upgrade.is_empty():
			continue
		var effect: Dictionary = upgrade.get("effect", {})
		ResultExecScript.execute(effect, state, self, {"upgrade_id": upgrade_id})


## [SRC: Datapool.c @ ClearOverIds/SetOverId/HasOverId
##       (RVA 0x40f8b0/0x41b2f0/0x413300), dump.cs Datapool.over_ids@0x2A0]
## Ending settlements use their string keys as a transient condition chain;
## they never write Global.overID, whose element type and lifecycle differ.
func clear_over_ids() -> void:
	over_ids.clear()


func set_over_id(id: String) -> void:
	if not id.is_empty():
		over_ids[id] = true


func has_over_id(id: String) -> bool:
	return over_ids.has(id)


func get_difficulty(index: int) -> Dictionary:
	# index 0=easy(梅姬), 1=normal(哈桑), 2=hard(女术士)
	var arr: Array = init_config.get("difficulty", [])
	if index >= 0 and index < arr.size():
		return arr[index]
	return {}


func get_sudan_pool() -> Array:
	return init_config.get("sudan_pool", [])


func get_default_cards() -> Array:
	if use_test_starting_cards:
		return get_test_default_cards()
	return NORMAL_DEFAULT_CARDS.duplicate()


func get_test_default_cards() -> Array:
	return init_config.get("default_cards", [])


func get_default_rites() -> Array:
	var configured: Array = init_config.get("default_rite", [])
	if not configured.is_empty():
		return _filter_generated_rites(configured)
	return _filter_generated_rites(NORMAL_DEFAULT_RITES)


func get_generated_rite_ids() -> Array[int]:
	var generated: Dictionary = {}
	for loot in loots.values():
		var items: Array = (loot as Dictionary).get("item", [])
		for item in items:
			if str((item as Dictionary).get("type", "")) == "rite":
				generated[int((item as Dictionary).get("id", 0))] = true
	for card in cards.values():
		var rite_id := int((card as Dictionary).get("is_rite", 0))
		if rite_id > 0:
			generated[rite_id] = true
	var out: Array[int] = []
	for rid in generated.keys():
		out.append(int(rid))
	out.sort()
	return out


func _filter_generated_rites(rite_ids: Array) -> Array[int]:
	var generated: Dictionary = {}
	for rid in get_generated_rite_ids():
		generated[int(rid)] = true
	var out: Array[int] = []
	for rid in rite_ids:
		var id := int(rid)
		if generated.has(id):
			continue
		out.append(id)
	return out


func set_test_starting_cards_enabled(enabled: bool) -> void:
	use_test_starting_cards = enabled


## Resolve a card id that may be given as int or numeric string.
func resolve_card_id(val: Variant) -> int:
	if val is int:
		return val
	if val is float:
		return int(val)
	return str(val).to_int()
