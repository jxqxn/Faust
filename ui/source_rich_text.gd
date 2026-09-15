extends RefCounted

## Retain TMP input so a font preference change can re-evaluate relative sizes.
static func set_label_text(label: RichTextLabel, source: String) -> void:
	label.set_meta("source_markup", source)
	var rendered := to_bbcode(source, label.get_theme_font_size("normal_font_size"))
	if label.has_meta("source_settlement_markup"):
		# [SRC: RiteResultPanel.prefab TMP spriteAsset guid 2a35b096...;
		# rite_settlement_icon.asset character index1 -> dot_dark glyph1;
		# original atlas rectangle (687,107,18,18), top-left image space.]
		rendered = rendered.replace("<sprite=1>", "[img width=18 height=18 region=687,107,18,18]res://assets/original/ui/rite_settlement_icon.png[/img]")
		# Preserve the original 10%-width tab stop in the heading paragraph.
		var indent := label.size.x * 0.1
		rendered = rendered.replace("<indent=10%>", "\t").replace("</indent>", "")
		var lines := rendered.split("\n")
		for i in lines.size():
			if lines[i].contains("[img width=18"):
				lines[i] = "[p tab_stops=%s]%s[/p]" % [indent, lines[i]]
		rendered = "\n".join(lines)
	label.text = rendered

# TMP text in content/ui.json and rite tips uses these style tags.
# Convert complete recognized tokens; ordinary comparisons such as 3 > 2
# and unsupported TMP tokens must not be rewritten as malformed BBCode.
static func to_bbcode(value: String, base_size: int = 0) -> String:
	var pattern := RegEx.new()
	pattern.compile("<(/?)(b|i|u|s|color|size|font|align)(?:=([^<>]+))?>")
	var result := ""
	var cursor := 0
	var stack: Array[Dictionary] = []
	var active_fonts: Array[String] = []
	for token in pattern.search_all(value):
		result += value.substr(cursor, token.get_start() - cursor)
		var closing := token.get_string(1)
		var tag := token.get_string(2)
		var argument := token.get_string(3)
		var output_tag := "font_size" if tag == "size" else tag
		var valid := not (tag in ["color", "size", "font"] and closing.is_empty() and argument.is_empty())
		if tag == "size" and closing.is_empty():
			# TMP m_fontSizeBase / m_sizeStack (dump.cs:364756); source event
			# 5300098 uses +10, visibly larger than the body in original runtime.
			# A signed size is relative, never an absolute ten-point font.
			if argument.ends_with("%"):
				var percentage := argument.trim_suffix("%")
				valid = base_size > 0 and percentage.is_valid_float() and float(percentage) > 0.0
				if valid:
					argument = str(roundi(base_size * float(percentage) / 100.0))
			elif argument.begins_with("+") or argument.begins_with("-"):
				valid = base_size > 0 and argument.is_valid_int() and base_size + int(argument) > 0
				if valid:
					argument = str(base_size + int(argument))
			else:
				valid = argument.is_valid_int() and int(argument) > 0
		if tag == "font" and closing.is_empty():
			var font_name := argument.trim_prefix('"').trim_suffix('"')
			var fonts: Dictionary = preload("res://ui/source_text_style.gd").FONT_PATHS
			valid = fonts.has(font_name)
			if valid:
				argument = fonts[font_name]
		if tag == "align" and closing.is_empty():
			valid = argument in ["left", "center", "right", "justified"]
			output_tag = "fill" if argument == "justified" else argument
			argument = ""
		if closing.is_empty():
			stack.append({"tag": tag, "converted": valid, "output": output_tag})
		elif not stack.is_empty() and str(stack.back()["tag"]) == tag:
			var opened: Dictionary = stack.pop_back()
			valid = bool(opened["converted"])
			output_tag = str(opened["output"])
		else:
			valid = false
		if valid:
			# TMP alignment is an inline state; Godot [left] starts a paragraph.
			# Left is already this renderer's default. Emitting [left] midway
			# through the source bullet line would strand its dot on another row.
			if tag == "align" and output_tag == "left":
				cursor = token.get_end()
				continue
			if tag == "b" and not active_fonts.is_empty():
				result += "[b][font=%s]" % active_fonts.back() if closing.is_empty() else "[/font][/b]"
				cursor = token.get_end()
				continue
			result += "[" + closing + output_tag
			if not argument.is_empty():
				result += "=" + argument
			result += "]"
			if tag == "font":
				if closing.is_empty():
					active_fonts.append(argument)
				elif not active_fonts.is_empty():
					active_fonts.pop_back()
		else:
			result += token.get_string()
		cursor = token.get_end()
	return result + value.substr(cursor)
