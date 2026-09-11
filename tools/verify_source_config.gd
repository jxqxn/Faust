## Independent oracle input comes from Python object_pairs_hook outside content.
## Compare every source value/member, not just successful JSON parsing.
extends SceneTree

var failures: Array[String] = []
var checked := 0

func _init() -> void:
	var path := OS.get_environment("FAUST_SOURCE_ORACLE")
	if path.is_empty() or not FileAccess.file_exists(path):
		push_error("FAUST_SOURCE_ORACLE must name the independently parsed token oracle")
		quit(1)
		return
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(path))
	for row in rows:
		var parsed = SourceJSON.parse_string(FileAccess.get_file_as_string("res://content/" + row.file))
		_compare(row.tree, parsed, row.file)
		checked += 1
	print("Original token parity: %d files, %d differences" % [checked, failures.size()])
	for failure in failures.slice(0, 30):
		printerr(failure)
	quit(0 if failures.is_empty() else 1)

func _compare(expected: Variant, actual: Variant, path: String) -> void:
	if expected is Dictionary and expected.has("object"):
		var pairs: Array = expected.object
		if actual is Array:
			if actual.size() != pairs.size():
				failures.append(path + ": repeated member count differs")
				return
			for i in pairs.size():
				var key: String = pairs[i][0]
				if not actual[i] is Dictionary or actual[i].size() != 1 or not actual[i].has(key):
					failures.append(path + ": repeated member order differs")
					return
				_compare(pairs[i][1], actual[i][key], path + "." + key)
		elif actual is Dictionary:
			var merged: Dictionary = {}
			for pair in pairs:
				if merged.has(pair[0]):
					# A repeated Operations node field extends its existing list.
					merged[pair[0]].object.append_array(pair[1].object)
				else:
					merged[pair[0]] = pair[1].duplicate(true) if pair[1] is Dictionary else pair[1]
			if merged.keys() != actual.keys():
				failures.append(path + ": object fields/order differ")
				return
			for key in merged:
				_compare(merged[key], actual[key], path + "." + key)
		else:
			failures.append(path + ": expected object")
	elif expected is Dictionary and expected.has("array"):
		if not actual is Array or actual.size() != expected.array.size():
			failures.append(path + ": source array differs")
			return
		for i in expected.array.size():
			_compare(expected.array[i], actual[i], path + "[%d]" % i)
	elif expected != actual:
		failures.append(path + ": scalar differs")
