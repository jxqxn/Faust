shader_type canvas_item;
render_mode unshaded;

// Procedural fog/film overlay inspired by the CC0 "2D Fog Overlay" pattern:
// https://godotshaders.com/shader/2d-fog-overlay-2/
// This implementation is original and uses no bundled reference imagery.
uniform vec4 fog_color : source_color = vec4(0.36, 0.42, 0.65, 0.11);
uniform float drift_speed : hint_range(0.0, 0.1) = 0.012;
uniform float grain_strength : hint_range(0.0, 0.1) = 0.018;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.55;
	for (int i = 0; i < 4; i++) {
		value += noise(p) * amplitude;
		p = p * 2.03 + vec2(13.7, 8.2);
		amplitude *= 0.48;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	vec2 fog_uv = vec2(uv.x * 3.2 + TIME * drift_speed, uv.y * 2.4 - TIME * drift_speed * 0.55);
	float fog = smoothstep(0.42, 0.78, fbm(fog_uv));
	float horizon = 1.0 - smoothstep(0.18, 0.76, abs(uv.y - 0.58));
	float edge = smoothstep(0.42, 0.92, distance(uv, vec2(0.5, 0.54)));
	float grain = (hash(FRAGCOORD.xy + vec2(TIME * 17.0, -TIME * 11.0)) - 0.5) * grain_strength;
	float alpha = fog_color.a * fog * horizon + edge * 0.055;
	COLOR = vec4(clamp(fog_color.rgb + grain, vec3(0.0), vec3(1.0)), clamp(alpha, 0.0, 0.18));
}
