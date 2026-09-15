extends RefCounted
## [SRC: Datapool.LoadBanWords 0x4145c0; Util.AES.GeneratePassword
## 0x397200/Decrypt 0x3966d0; MaskWordsHelper.ctor 0x3025a0 /
## HasMaskWord 0x301cd0; dump.cs:542744. Original encrypted resource only.]
const RESOURCE := "res://assets/original/text/ban_words.bytes"
# InitScene GameObject21 Camera.cullingMask=1744830530; System.Random.Next
# gives 1220381830 and 1844380820. Temporary Unity Range returns -966303212.
# This source-build resource key was independently validated by decrypting
# the original AES/PKCS7 payload to 28 JSON strings, SHA256 below. It is NOT
# a gameplay random seed and never changes GameRNG or imported player state.
const CARD_SEED: int = -966303212 * 1844380820
const RITE_SEED: int = -2255474601349826220 # unsigned 0xe0b2f1ccd2a0b954
const OTHER_SEED: int = 0x60dfa3185012834b
const DICE_SEED: int = 0x4fd28231cae9901c
const PLAINTEXT_SHA256 := "a4969c5a3e07c4fc690ef588c3509d3c4f69a39283f7a59e17589b63e512074a"
static var _loaded := false
static var _normal: RegEx
static var _special: RegEx
static var _skip: RegEx
static var source_word_count := 0

static func has_ban_words(value: String) -> bool:
	if not _loaded:
		_load_original()
	# Datapool.HasBanWords returns false if its filter failed to load.
	if _normal == null:
		return false
	var lower := value.to_lower()
	if _special != null and _special.search(lower) != null:
		return true
	return _normal.search(_skip.sub(lower, "", true)) != null

static func _load_original() -> void:
	_loaded = true
	var source := FileAccess.get_file_as_bytes(RESOURCE)
	var password := _password([CARD_SEED, OTHER_SEED, RITE_SEED, DICE_SEED])
	var salt := _password([OTHER_SEED, CARD_SEED, DICE_SEED, RITE_SEED])
	var key := _pbkdf2_sha1(password, salt)
	var aes := AESContext.new()
	if source.size() < 32 or source.size() % 16 != 0 or aes.start(AESContext.MODE_CBC_DECRYPT, key, source.slice(0, 16)) != OK:
		push_error("Original ban_words resource could not be loaded")
		return
	var plaintext := aes.update(source.slice(16))
	aes.finish()
	var padding := int(plaintext[-1])
	if padding < 1 or padding > 16:
		push_error("Original ban_words padding invalid")
		return
	for index in range(plaintext.size() - padding, plaintext.size()):
		if plaintext[index] != padding:
			push_error("Original ban_words padding invalid")
			return
	plaintext.resize(plaintext.size() - padding)
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(plaintext)
	if hash.finish().hex_encode() != PLAINTEXT_SHA256:
		push_error("Original ban_words plaintext does not match verified source build")
		return
	var words: Variant = JSON.parse_string(plaintext.get_string_from_utf8())
	if not words is Array:
		push_error("Original ban_words is not a word array")
		return
	source_word_count = words.size()
	_build_filters(words)

static func _build_filters(words: Array) -> void:
	_skip = RegEx.create_from_string(SKIP_PATTERN)
	var normal: Array[String] = []
	var special: Array[String] = []
	var seen := {}
	for raw in words:
		var word := str(raw).strip_edges().to_lower()
		if seen.has(word):
			continue
		seen[word] = true
		if _skip.search(word) != null:
			special.append(word)
		else:
			normal.append(word)
	_normal = _words_regex(normal)
	# Constructor removes special entries whose stripped form is completely
	# covered by normal words; empty stripped special entries remain.
	special = special.filter(func(word: String):
		var stripped := _skip.sub(word, "", true)
		return stripped.is_empty() or not _normal.sub(stripped, "", true).is_empty())
	_special = _words_regex(special) if not special.is_empty() else null

static func _words_regex(words: Array[String]) -> RegEx:
	var escaped: Array[String] = []
	for word in words:
		var pattern := ""
		for character in word:
			if character in "\\.^$|?*+()[]{}":
				pattern += "\\"
			pattern += character
		escaped.append(pattern)
	escaped.sort_custom(func(a: String, b: String): return a.length() > b.length())
	return RegEx.create_from_string("|".join(escaped))

static func _unsigned_right(value: int, bits: int) -> int:
	return (value >> bits) & (0x7fffffffffffffff >> (bits - 1))

static func _rotate_left(value: int, bits: int) -> int:
	return (value << bits) | _unsigned_right(value, 64 - bits)

static func _password(seeds: Array[int]) -> PackedByteArray:
	var output := PackedByteArray()
	for index in 32:
		var old := seeds[1]
		seeds[2] ^= seeds[0]
		seeds[3] ^= seeds[1]
		seeds[1] ^= seeds[2]
		seeds[0] ^= seeds[3]
		seeds[2] ^= old << 17
		seeds[3] = _rotate_left(seeds[3], 45)
		var value := _rotate_left(old * 5, 7) * 9
		var bits := (index * 4) & 63
		output.append((value if bits == 0 else _unsigned_right(value, bits)) & 255)
	return output

static func _pbkdf2_sha1(password: PackedByteArray, salt: PackedByteArray) -> PackedByteArray:
	var crypto := Crypto.new()
	var output := PackedByteArray()
	for block in [1, 2]:
		var input := salt.duplicate()
		input.append_array(PackedByteArray([0, 0, 0, block]))
		var previous := crypto.hmac_digest(HashingContext.HASH_SHA1, password, input)
		var accumulator := previous.duplicate()
		for iteration in range(1, 1000):
			previous = crypto.hmac_digest(HashingContext.HASH_SHA1, password, previous)
			for index in 20:
				accumulator[index] ^= previous[index]
		output.append_array(accumulator)
	output.resize(32)
	return output

# [SRC: MaskWordsHelper.cctor 0x302530; stringliteral RVA0x25ac008.]
const SKIP_PATTERN := "[\\x00- \\[\\]-ÿ\\\\~!@#$%^&*()_+\\-=【】、{}|;':\"，。、《》？αβγδεζηθικλμνξοπρστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ。，、；：？！…—·ˉ¨‘’“”々～‖∶＂＇｀｜〃〔〕〈〉《》「」『』．〖〗【】（）［］｛｝≈≡≠＝≤≥＜＞≮≯∷±＋－×÷／∫∮∝∞∧∨∑∏∪∩∈∵∴⊥∥∠⌒⊙≌∽√§№☆★○●◎◇◆□℃‰€■△▲※→←↑↓〓¤°＃＆＠＼︿＿￣―♂♀┌┍┎┐┑┒┓─┄┈├┝┞┟┠┡┢┣│┆┊┬┭┮┯┰┱┲┳┼┽┾┿╀╁╂╃└┕┖┗┘┙┚┛━┅┉┤┥┦┧┨┩┪┫┃┇┋┴┵┶┷┸┹┺┻╋╊╉╈╇╆╅╄]"
