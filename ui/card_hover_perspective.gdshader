// Mild two-axis card projection adapted from Knower Coder's MIT-licensed
// 3D Hover Shader. See THIRD_PARTY_NOTICES.md.
shader_type canvas_item;

uniform vec2 tilt = vec2(0.0);
uniform vec2 visual_size = vec2(120.0, 176.0);
uniform float max_pitch_degrees = 3.5;
uniform float max_yaw_degrees = 4.5;
uniform float perspective_strength = 0.35;

varying vec2 perspective_uv;
varying float perspective_weight;

void vertex() {
	vec2 centered = UV - vec2(0.5);
	// The face leans toward the pointer: screen-down maps to positive X
	// rotation, while screen-right maps to negative Y rotation. Keeping these
	// signs explicit prevents the common "card moves away from the mouse" bug.
	float pitch = radians(tilt.y * max_pitch_degrees);
	float yaw = radians(-tilt.x * max_yaw_degrees);
	float cp = cos(pitch);
	float sp = sin(pitch);
	float cy = cos(yaw);
	float sy = sin(yaw);
	mat3 rotate_x = mat3(
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, cp, -sp),
		vec3(0.0, sp, cp)
	);
	mat3 rotate_y = mat3(
		vec3(cy, 0.0, sy),
		vec3(0.0, 1.0, 0.0),
		vec3(-sy, 0.0, cy)
	);
	vec3 projected = rotate_y * rotate_x * vec3(centered, 0.0);
	float depth = 1.0 / max(0.75, 1.0 - projected.z * perspective_strength);
	projected.xy *= depth;
	VERTEX += (projected.xy - centered) * visual_size;
	perspective_uv = UV * depth;
	perspective_weight = depth;
}

void fragment() {
	vec2 corrected_uv = perspective_uv / perspective_weight;
	if (corrected_uv.x < 0.0 || corrected_uv.x > 1.0 || corrected_uv.y < 0.0 || corrected_uv.y > 1.0) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, corrected_uv);
	}
}
