shader_type canvas_item;

// CardNew/Flash inner outline.
//
// [SRC: Resources/materials/CardFlash.mat — valid keywords
//  _ENABLEINNEROUTLINE_ON and _INNEROUTLINEOUTLINEONLYTOGGLE_ON,
//  _InnerOutlineColor (0.88235295, 0.72840685, 0.33725485), _Color white,
//  _InnerOutlineWidth 0.08. The exported .shader is a DummyShaderTextExporter
//  stub (see docs/ui_layout/CardSurface.md), so the ring is reconstructed from
//  the sprite's own silhouette alpha and its width is calibrated against
//  docs/ui_layout/original_runtime/desktop.jpg.]

uniform vec4 outline_color : source_color = vec4(0.88235295, 0.72840685, 0.33725485, 1.0);
uniform float outline_pixels = 2.5;
uniform vec2 sprite_size = vec2(256.0, 512.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 step_uv = outline_pixels / sprite_size;
	float inner = step(0.5, source.a);
	float edge = 0.0;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * 0.7853981634;
		vec2 direction = vec2(cos(angle), sin(angle));
		float neighbor = texture(TEXTURE, UV + direction * step_uv).a;
		edge = max(edge, 1.0 - step(0.5, neighbor));
	}
	float ring = inner * edge;
	COLOR = vec4(outline_color.rgb, outline_color.a * ring);
}
