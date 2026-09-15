shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

// [SRC: original sharedassets0.assets OpCardShow/Broker path_id181,
// DXBC181_7..10; OpCardBroker.mat UVWidth=1/16, UVHeight=1/8.]
// Isolated source-sized cell adapter; shared atlas neighbours are not rendered.
// Gamma project (PlayerSettings m_ActiveColorSpace=0): displacement data must
// not pass through source_color conversion. PNG and viewport use top-left UV.
uniform sampler2D broker_texture : filter_linear, repeat_disable;
uniform float broker_distance = 0.0;
varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec4 broker = texture(broker_texture, UV);
	vec2 displacement = (vec2(broker.r * broker.a, broker.g) * 2.0 - 1.0) * broker_distance;
	vec2 sample_uv = UV + displacement * vec2(16.0, -8.0);
	vec4 sample_color = texture(TEXTURE, sample_uv);
	// The full source atlas repeats; this adapter has only one padded cell.
	// Do not smear the cell edge into the missing neighbours.
	if (any(lessThan(sample_uv, vec2(0.0))) || any(greaterThan(sample_uv, vec2(1.0)))) {
		sample_color = vec4(0.0);
	}
	vec4 tinted = sample_color * vertex_color;
	COLOR = vec4(tinted.rgb * tinted.a, tinted.a);
}
