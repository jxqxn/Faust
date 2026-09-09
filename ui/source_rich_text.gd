extends RefCounted

# TMP text in content/ui.json and rite tips uses these style tags.
# Convert complete recognized tokens; ordinary comparisons such as 3 > 2
# and unsupported TMP tokens must not be rewritten as malformed BBCode.
static func to_bbcode(value: String) -> String:
	var pattern := RegEx.new()
	pattern.compile("<(/?)(b|i|u|s|color|size)(?:=([^<>]+))?>")
	var result := ""
	var cursor := 0
	var stack: Array[Dictionary] = []
	for token in pattern.search_all(value):
		result += value.substr(cursor, token.get_start() - cursor)
		var closing := token.get_string(1)
		var tag := token.get_string(2)
		var argument := token.get_string(3)
		var valid := not (tag in ["color", "size"] and closing.is_empty() and argument.is_empty())
		if tag == "size" and closing.is_empty():
			valid = argument.is_valid_int() and int(argument) > 0
		if closing.is_empty():
			stack.append({"tag": tag, "converted": valid})
		elif not stack.is_empty() and str(stack.back()["tag"]) == tag:
			valid = bool(stack.pop_back()["converted"])
		else:
			valid = false
		if valid:
			result += "[" + closing + ("font_size" if tag == "size" else tag)
			if not argument.is_empty():
				result += "=" + argument
			result += "]"
		else:
			result += token.get_string()
		cursor = token.get_end()
	return result + value.substr(cursor)
