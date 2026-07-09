## Config database: loads and indexes the game's config JSON.
## Single source of truth for cards/rites/loot/tags/init at runtime.
class_name ConfigDB
extends RefCounted

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
var tags_by_code := {}     # code -> tag dict
var tags_by_id := {}       # id(int) -> tag dict
var tag_name_to_code := {} # name -> code
var init_config := {}      # init/1.json contents
var use_test_starting_cards := false


func load_all(content_dir: String = "res://content", use_test_cards: bool = false) -> void:
	use_test_starting_cards = use_test_cards
	_load_tags(content_dir + "/tag.json")
	_load_cards(content_dir + "/cards.json")
	_load_dir(content_dir + "/rite", rites)
	_load_dir(content_dir + "/event", events)
	_load_dir(content_dir + "/loot", loots)
	_load_init(content_dir + "/init/1.json")


func _load_init(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("ConfigDB: missing init at %s" % path)
		return
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		init_config = parsed


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


func get_card(id: int) -> Dictionary:
	return cards.get(id, {})


func get_rite(id: int) -> Dictionary:
	return rites.get(id, {})


func get_loot(id: int) -> Dictionary:
	return loots.get(id, {})


func get_event(id: int) -> Dictionary:
	return events.get(id, {})


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
