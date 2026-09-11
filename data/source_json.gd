## Reads original StreamingAssets JSONC without collapsing repeated DSL members.
## Runtime lists contain one-key operation/condition dictionaries, not rewritten
## content files. Unique objects remain dictionaries for existing node consumers.
## [SRC: OperationJsonConverter.ReadInternal<object> 0x70d1d0, dump.cs:394250;
## ConditionJsonConverter.Read 0x386350 appends conditions to List<ICondition>.]
## [SRC: TimingJsonConverter.Read 0x3a7bc0; repeated Settlement.action reader
## DataNode.Json.RiteNode_Settlement_JsonHandler.__c b__0_6 0x3ee140 passes
## existing Operations@0x38 back into Read instead of discarding it.]
class_name SourceJSON
extends RefCounted

var _text: String
var _pos := 0
var error := ""
static var _cache: Dictionary = {}

static func parse_string(text: String) -> Variant:
	if _cache.has(text):
		var cached = _cache[text]
		return cached.duplicate(true) if cached is Dictionary or cached is Array else cached
	var reader := SourceJSON.new()
	reader._text = text.trim_prefix(String.chr(0xfeff))
	var value = reader._value("")
	reader._space()
	if reader._pos != reader._text.length() and reader.error.is_empty():
		reader.error = "Trailing input at %d" % reader._pos
	if not reader.error.is_empty():
		push_error("Original config JSONC: " + reader.error)
		return null
	_cache[text] = value
	return value.duplicate(true) if value is Dictionary or value is Array else value

static func entries(value: Variant) -> Array:
	if value is Array:
		return value
	var out: Array = []
	if value is Dictionary:
		for key in value:
			out.append({key: value[key]})
	return out

static func member(value: Variant, key: String, fallback: Variant = null) -> Variant:
	if value is Dictionary:
		return value.get(key, fallback)
	for entry in entries(value):
		if entry.has(key):
			return entry[key]
	return fallback

static func without(value: Variant, keys: Array) -> Array:
	return entries(value).filter(func(entry): return not entry.keys()[0] in keys)

func _space() -> void:
	while _pos < _text.length():
		if _text[_pos] in [" ", "\t", "\r", "\n"]:
			_pos += 1
		elif _text.substr(_pos, 2) == "//":
			var end := _text.find("\n", _pos + 2)
			_pos = _text.length() if end < 0 else end + 1
		elif _text.substr(_pos, 2) == "/*":
			var end := _text.find("*/", _pos + 2)
			if end < 0:
				error = "Unclosed comment"
				_pos = _text.length()
				return
			_pos = end + 2
		else:
			return

func _take(token: String) -> bool:
	_space()
	if _text.substr(_pos, token.length()) == token:
		_pos += token.length()
		return true
	return false

func _string() -> String:
	var begin := _pos
	_pos += 1
	while _pos < _text.length():
		var ch := _text[_pos]
		_pos += 1
		if ch == "\\":
			_pos += 1
		elif ch == '"':
			var json := JSON.new()
			if json.parse(_text.substr(begin, _pos - begin)) == OK:
				return str(json.data)
			error = json.get_error_message()
			return ""
	error = "Unclosed string at %d" % begin
	return ""

func _value(mode: String) -> Variant:
	_space()
	if _pos >= _text.length():
		error = "Unexpected end"
		return null
	if _text[_pos] == '"':
		return _string()
	if _take("{"):
		var pairs: Array = []
		var object: Dictionary = {}
		var repeated := false
		while not _take("}") and error.is_empty():
			_space()
			if _pos >= _text.length() or _text[_pos] != '"':
				error = "Expected property at %d" % _pos
				break
			var key := _string()
			if not _take(":"):
				error = "Expected colon at %d" % _pos
				break
			var child_mode := ""
			if mode == "condition" and key in ["any", "all"]:
				child_mode = "condition"
			elif mode == "operation" and (key in ["all", "no_show", "no_prompt", "success", "failed", "delay", "choose"] or key.begins_with("case:") or key.begins_with("choose:") or key.begins_with("random")):
				child_mode = "operation"
			elif mode.is_empty():
				if key == "condition" or key.ends_with("_condition"):
					child_mode = "condition"
				elif key == "on":
					child_mode = "timing"
				elif key in ["action", "result", "effect", "vanish"]:
					child_mode = "operation"
			var value = _value(child_mode)
			pairs.append({key: value})
			if object.has(key):
				repeated = true
				# Existing Operations is passed back to ReadInternal; repeated
				# node fields extend that same list, rather than replacing it.
				if mode.is_empty() and child_mode == "operation":
					value = entries(object[key]) + entries(value)
				elif mode.is_empty():
					error = "Unclassified repeated node field %s at %d" % [key, _pos]
			object[key] = value
			if not _take(","):
				if not _take("}"):
					error = "Expected object separator at %d" % _pos
				break
		return pairs if repeated and not mode.is_empty() else object
	if _take("["):
		var array: Array = []
		while not _take("]") and error.is_empty():
			array.append(_value(mode))
			if not _take(","):
				if not _take("]"):
					error = "Expected array separator at %d" % _pos
				break
		return array
	var begin := _pos
	while _pos < _text.length() and not _text[_pos] in [",", "}", "]", " ", "\t", "\r", "\n", "/"]:
		_pos += 1
	var json := JSON.new()
	if json.parse(_text.substr(begin, _pos - begin)) != OK:
		error = "Invalid value at %d" % begin
		return null
	return json.data
