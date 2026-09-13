shader_type canvas_item;
// [SRC: ND_mask01.mat; MG/Almighty_Blend DXBC resources.assets shader2056
// mask variant30: t1 alpha * Main_Color.a * Alpha * t4 alpha, standard alpha blend.]
uniform sampler2D mask_texture : filter_linear, repeat_disable;
void fragment() {
	vec2 unity_uv = vec2(UV.x, 1.0-UV.y);
	vec2 uv = unity_uv * vec2(0.3,0.6) + vec2(0.0,-0.1);
	vec4 tex = texture(mask_texture, vec2(uv.x,1.0-uv.y));
	COLOR = vec4(tex.rgb * vec3(0.0,0.0,0.078431375), tex.a * tex.a * 0.7294118 * 0.8);
}
