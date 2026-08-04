// Balatro-style 2D shadow pass. The source texture is the card before its
// pointer-perspective shader, so this silhouette follows only the card's
// ordinary 2D transform and cannot inherit pitch/yaw deformation.
shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.3);
uniform float blur_radius_px = 1.35;

void fragment() {
	// The raw alpha preserves the card silhouette. A compact 3x3 kernel grows
	// only its edge, giving an elevated card a readable contact shadow on the
	// card below without producing a rectangular dark plate.
	vec2 blur = TEXTURE_PIXEL_SIZE * blur_radius_px;
	float card_alpha = texture(TEXTURE, UV).a * 0.28;
	card_alpha += texture(TEXTURE, UV + vec2(-blur.x, 0.0)).a * 0.12;
	card_alpha += texture(TEXTURE, UV + vec2(blur.x, 0.0)).a * 0.12;
	card_alpha += texture(TEXTURE, UV + vec2(0.0, -blur.y)).a * 0.12;
	card_alpha += texture(TEXTURE, UV + vec2(0.0, blur.y)).a * 0.12;
	card_alpha += texture(TEXTURE, UV + vec2(-blur.x, -blur.y)).a * 0.06;
	card_alpha += texture(TEXTURE, UV + vec2(blur.x, -blur.y)).a * 0.06;
	card_alpha += texture(TEXTURE, UV + vec2(-blur.x, blur.y)).a * 0.06;
	card_alpha += texture(TEXTURE, UV + vec2(blur.x, blur.y)).a * 0.06;
	COLOR = vec4(shadow_color.rgb, min(card_alpha, 1.0) * shadow_color.a);
}
