## Game over screen: maps the fatal operation's ending id to the original
## ending table (content/over.json: name/sub_name/text/open_after_story) and
## shows the final stats with a restart entry.
## [SRC: data/config/over.json (159 endings); vanish.over ids index it]
extends Control

signal restart()

var _state
var _db
var _endings: Array = []


func setup(state, db) -> void:
	_state = state
	_db = db
	_load_endings()


func _load_endings() -> void:
	var path := "res://content/over.json"
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Array:
			_endings = parsed


func _ready() -> void:
	theme = FaustTheme.get_theme()
	_build_ui()


func _ending_entry() -> Dictionary:
	var idx := int(_state.over_reason) if _state != null else 0
	if idx >= 0 and idx < _endings.size():
		var entry = _endings[idx]
		return entry if entry is Dictionary else {}
	return {}


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = FaustTheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Original ending backdrop. [SRC: assets/original/ui/over_bg/over_bg_1.png]
	if ResourceLoader.exists("res://assets/original/ui/over_bg/over_bg_1.png"):
		var over_bg := TextureRect.new()
		over_bg.texture = preload("res://assets/original/ui/over_bg/over_bg_1.png")
		over_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		over_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		over_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(over_bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	col.custom_minimum_size = Vector2(520, 0)
	center.add_child(col)
	var ending := _ending_entry()
	# Title: the ending's name, or the generic header when unmapped.
	var title := Label.new()
	title.text = str(ending.get("name", "游戏结束"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", FaustTheme.DANGER_LIGHT)
	col.add_child(title)
	if str(ending.get("sub_name", "")) != "":
		var sub := Label.new()
		sub.text = str(ending.get("sub_name"))
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", 20)
		sub.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
		col.add_child(sub)
	# Reason: the ending text, falling back to the generic execution line.
	var reason := Label.new()
	reason.text = str(ending.get("text", "一张苏丹卡到期未完成。苏丹的怒火降临了。"))
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.add_theme_font_size_override("font_size", 16)
	reason.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(reason)
	if int(ending.get("open_after_story", 0)) == 1:
		var after := Label.new()
		after.text = "（后日谈待开放）"
		after.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		after.add_theme_font_size_override("font_size", 13)
		after.add_theme_color_override("font_color", FaustTheme.TEXT_DIM)
		col.add_child(after)
	col.add_child(_spacer(12))
	# Stats.
	var stats := Label.new()
	stats.text = "存活: 第 %d 回合 · 第 %d 天\n金币: %d\n金骰: %d" % [_state.round_number, _state.day, _state.coin_count, _state.gold_dice]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 18)
	stats.add_theme_color_override("font_color", FaustTheme.GOLD_BRIGHT)
	col.add_child(stats)
	col.add_child(_spacer(16))
	# Restart.
	var btn := Button.new()
	btn.text = "重新开始"
	btn.custom_minimum_size = Vector2(200, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): restart.emit())
	col.add_child(btn)


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
