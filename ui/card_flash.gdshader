shader_type canvas_item;

// [SRC: sharedassets0.assets shader184 / GUI SSU, fragment blob118,
// docs/ui_layout/shader_evidence/184_118.asm; parameter blob86.]

uniform vec4 outline_color : source_color = vec4(0.88235295, 0.72840685, 0.33725485, 1.0);
uniform float outline_width = 0.08;
// CardFlash.mat _InnerOutlineFade=0; CardFlashController.Reset 0x52e2d0
// also writes zero. A live Image component does not imply a visible flash.
uniform float outline_fade = 0.0;
varying vec4 canvas_tint;

void vertex() {
	canvas_tint = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 d = outline_width * 100.0 * TEXTURE_PIXEL_SIZE;
	float neighbor = min(texture(TEXTURE, UV + vec2(-d.x, 0.0)).a,
		texture(TEXTURE, UV + vec2(d.x, 0.0)).a);
	neighbor = min(neighbor, texture(TEXTURE, UV + vec2(0.0, -d.y)).a);
	neighbor = min(neighbor, texture(TEXTURE, UV + vec2(0.0, d.y)).a);
	neighbor = min(neighbor, texture(TEXTURE, UV + d * vec2(0.705, 0.705)).a);
	neighbor = min(neighbor, texture(TEXTURE, UV + d * vec2(-0.705, 0.705)).a);
	neighbor = min(neighbor, texture(TEXTURE, UV + d * vec2(0.705, -0.705)).a);
	neighbor = min(neighbor, texture(TEXTURE, UV + d * vec2(-0.705, -0.705)).a);
	float fade = (1.0 - neighbor) * outline_fade;
	// The original ignores outline_color.a and preserves soft source alpha.
	COLOR = vec4(mix(source.rgb, outline_color.rgb, fade), fade * source.a) * canvas_tint;
}
