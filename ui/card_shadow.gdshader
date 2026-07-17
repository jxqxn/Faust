// Balatro-style 2D shadow pass. The source texture is the card before its
// pointer-perspective shader, so this silhouette follows only the card's
// ordinary 2D transform and cannot inherit pitch/yaw deformation.
shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.3);

void fragment() {
	float card_alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(shadow_color.rgb, card_alpha * shadow_color.a);
}
