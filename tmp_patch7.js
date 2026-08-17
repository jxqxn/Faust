const fs = require('fs');
// --- rite_selector: pin art IS the button, no paper frame ---
let r = fs.readFileSync('ui/rite_selector.gd', 'utf8');
const oldBtn = `		var pin := _rite_pin_texture(r)
		if pin != null:
			var icon_rect := TextureRect.new()
			icon_rect.texture = pin
			icon_rect.custom_minimum_size = Vector2(40, 44)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			btn.add_child(icon_rect)
			btn.tooltip_text = "%s\n%s" % [str(r.get("name", instance.id)), str(r.get("text", ""))]
		else:
			btn.text = str(r.get("name", str(instance.id)))
			btn.tooltip_text = str(r.get("text", ""))
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", Color("#2d2017"))
		btn.add_theme_color_override("font_hover_color", Color("#681f1b"))
		btn.add_theme_color_override("font_pressed_color", Color("#421713"))
		btn.add_theme_color_override("font_focus_color", Color("#2d2017"))
		btn.add_theme_stylebox_override("normal", _rite_button_style())
		btn.add_theme_stylebox_override("hover", _rite_button_style(Color("#9a4335"), true))
		btn.add_theme_stylebox_override("pressed", _rite_button_style(Color("#6f281f"), true))
		btn.add_theme_stylebox_override("focus", _rite_button_style(Color("#b98736"), true))`;
const newBtn = `		# Texture-first: the original pin IS the button surface — no paper
		# chrome around it. Name rides as the tooltip.
		# [SRC: rites.png atlas via the rite icon field]
		var pin := _rite_pin_texture(r)
		if pin != null:
			btn.custom_minimum_size = Vector2(0, 84)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var icon_rect := TextureRect.new()
			icon_rect.texture = pin
			icon_rect.set_anchors_preset(Control.PRESET_CENTER)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(72, 80)
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(icon_rect)
			btn.tooltip_text = "%s\n%s" % [str(r.get("name", instance.id)), str(r.get("text", ""))]
			for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
				btn.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
		else:
			btn.text = str(r.get("name", str(instance.id)))
			btn.tooltip_text = str(r.get("text", ""))
			btn.custom_minimum_size = Vector2(0, 44)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.add_theme_font_size_override("font_size", 15)
			btn.add_theme_color_override("font_color", Color("#2d2017"))
			btn.add_theme_color_override("font_hover_color", Color("#681f1b"))
			btn.add_theme_color_override("font_pressed_color", Color("#421713"))
			btn.add_theme_color_override("font_focus_color", Color("#2d2017"))
			btn.add_theme_stylebox_override("normal", _rite_button_style())
			btn.add_theme_stylebox_override("hover", _rite_button_style(Color("#9a4335"), true))
			btn.add_theme_stylebox_override("pressed", _rite_button_style(Color("#6f281f"), true))
			btn.add_theme_stylebox_override("focus", _rite_button_style(Color("#b98736"), true))`;
if (!r.includes(oldBtn)) { console.log('SELECTOR BTN NOT FOUND'); process.exit(1); }
r = r.replace(oldBtn, newBtn);
fs.writeFileSync('ui/rite_selector.gd', r);
console.log('selector buttons texture-first');

// --- situation_desk: think zone drops the paper prop style when art exists ---
let s = fs.readFileSync('ui/situation_desk.gd', 'utf8');
const oldThink = `	_think_drop_zone.add_theme_stylebox_override("panel", _paper_prop_style(PAPER_SHADOW))`;
const newThink = `	# Texture-first: the IThink art IS the drop-zone surface; the paper
	# prop style only survives without art.
	if ResourceLoader.exists("res://assets/original/ui/IThink_01.png"):
		var think_tex := preload("res://assets/original/ui/IThink_01.png")
		var think_style := StyleBoxTexture.new()
		think_style.texture = think_tex
		think_style.texture_margin_left = 30
		think_style.texture_margin_right = 30
		think_style.texture_margin_top = 24
		think_style.texture_margin_bottom = 24
		_think_drop_zone.add_theme_stylebox_override("panel", think_style)
	else:
		_think_drop_zone.add_theme_stylebox_override("panel", _paper_prop_style(PAPER_SHADOW))`;
if (!s.includes(oldThink)) { console.log('THINK NOT FOUND'); process.exit(1); }
s = s.replace(oldThink, newThink);
// Remove the now-redundant art child inside the zone
const oldArt = `	# Original "I think" desk art behind the drop zone.
	# [SRC: Texture2D/IThink_01.png]
	if ResourceLoader.exists("res://assets/original/ui/IThink_01.png"):
		var think_art := TextureRect.new()
		think_art.name = "ThinkZoneArt"
		think_art.texture = preload("res://assets/original/ui/IThink_01.png")
		think_art.set_anchors_preset(Control.PRESET_FULL_RECT)
		think_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		think_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		think_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_think_drop_zone.add_child(think_art)
		_think_drop_label.z_index = 1

`;
if (s.includes(oldArt)) {
	s = s.replace(oldArt, '');
	console.log('think art child removed');
}
fs.writeFileSync('ui/situation_desk.gd', s);
console.log('think zone texture-first');
