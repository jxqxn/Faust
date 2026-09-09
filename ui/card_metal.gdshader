shader_type canvas_item;
render_mode unshaded;

// Source maps and position offsets are preserved. The lighting lobe is a
// Godot approximation: the exported CardShow shader has no original body.
//
// Colour-space note: a custom canvas_item shader receives TEXTURE and its
// sampler uniforms already decoded from sRGB to linear, while the default 2D
// pipeline works in sRGB. Every sample is re-encoded with to_display() so the
// card keeps the authored albedo/normal/metallic values (measured: without it
// the surface renders about 2x darker than the same TextureRect without a
// custom shader).
uniform sampler2D normal_map : filter_linear;
uniform sampler2D metal_map : filter_linear;
// [SRC: Standard shader _DETAIL_MULX2 with _DetailAlbedoMap at UV0
//       (_UVSec: 0); enabled for copper/silver/gold, absent for stone.]
uniform sampler2D detail_map : filter_linear;
uniform bool has_detail = false;
uniform float bump_scale = 0.3680556;
uniform float gloss_scale = 0.75;
uniform vec2 normal_offset = vec2(0.025, 0.3);
// Unity's Standard shader lights the card in the scene, so the authored
// albedo arrives at the screen brighter than the raw texture. The exported
// CardShow shader has no body (DummyShaderTextExporter), so this ambient
// response is calibrated against docs/ui_layout/original_runtime/desktop.jpg:
// the same card frame patches measure ~1.5x brighter there than the raw
// albedo, with a stronger blue lift.
// Uniform is intentionally NOT source_color: it is a >1.0 lighting multiplier,
// not an sRGB colour, and the sRGB hint would clamp it to 1.0.
uniform vec3 material_light = vec3(2.2, 2.5, 4.0);

vec3 to_display(vec3 linear_value) {
	return pow(max(linear_value, vec3(0.0)), vec3(0.5));
}

void fragment() {
	vec4 base = vec4(to_display(texture(TEXTURE, UV).rgb), texture(TEXTURE, UV).a) * COLOR;
	if (has_detail) {
		base.rgb *= to_display(texture(detail_map, UV).rgb) * 2.0;
	}
	vec3 normal = to_display(texture(normal_map, UV).rgb) * 2.0 - 1.0;
	normal = normalize(vec3(normal.xy * bump_scale + normal_offset, max(normal.z, 0.2)));
	vec4 metal = vec4(to_display(texture(metal_map, UV).rgb), texture(metal_map, UV).a);
	vec3 half_vector = normalize(vec3(0.06, 0.32, 1.0));
	float smoothness = clamp(metal.a * gloss_scale, 0.0, 1.0);
	float specular = pow(max(dot(normal, half_vector), 0.0), mix(16.0, 160.0, smoothness));
	vec3 reflection = mix(vec3(0.04), base.rgb, metal.r);
	base.rgb = base.rgb * material_light;
	base.rgb = base.rgb * (1.0 - 0.15 * metal.r) + reflection * specular * 0.65;
	COLOR = base;
}
