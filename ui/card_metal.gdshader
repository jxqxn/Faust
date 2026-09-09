shader_type canvas_item;
render_mode unshaded;

// Source maps and position offsets are preserved. The lighting lobe is a
// Godot approximation: the exported CardShow shader has no original body.
uniform sampler2D normal_map : filter_linear;
uniform sampler2D metal_map : filter_linear;
uniform float bump_scale = 0.3680556;
uniform float gloss_scale = 0.75;
uniform vec2 normal_offset = vec2(0.025, 0.3);

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec3 normal = texture(normal_map, UV).rgb * 2.0 - 1.0;
	normal = normalize(vec3(normal.xy * bump_scale + normal_offset, max(normal.z, 0.2)));
	vec4 metal = texture(metal_map, UV);
	vec3 half_vector = normalize(vec3(0.06, 0.32, 1.0));
	float smoothness = clamp(metal.a * gloss_scale, 0.0, 1.0);
	float specular = pow(max(dot(normal, half_vector), 0.0), mix(16.0, 160.0, smoothness));
	vec3 reflection = mix(vec3(0.04), base.rgb, metal.r);
	base.rgb = base.rgb * (1.0 - 0.15 * metal.r) + reflection * specular * 0.65;
	COLOR = base;
}
