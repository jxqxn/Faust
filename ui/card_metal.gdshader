shader_type canvas_item;
render_mode unshaded;

// [SRC: sharedassets0.assets CardShow/Default, fragment60/75, vertex14;
// docs/ui_layout/shader_evidence. Gamma BRDF, not a fitted light lobe.]
uniform sampler2D normal_map : filter_linear, repeat_disable;
uniform sampler2D metal_map : filter_linear, repeat_disable;
uniform sampler2D detail_map : filter_linear, repeat_disable;
uniform sampler2D emission_map : filter_linear, repeat_disable;
uniform bool has_detail = false;
uniform vec3 emission_color = vec3(0.0);
uniform float bump_scale = 0.3680556;
uniform float gloss_scale = 0.75;
// Scene-authored inputs: GameScene Light4870/Transform4011 and MainUI
// Canvas7581 (plane100), camera4416 (ortho5). Tangent space has forward +Z.
// Light4870 is the ONLY light that can reach a card: its culling mask
// 2147483895 (0x800000F7) has bit 5 set, and cards sit on Unity layer 5.
// Light4869 is layer-30 only (mask 1<<30) and must not shade cards -- it is the
// Sudan dice camera's light. Both are directional, white, intensity 1.
// The z sign below is unresolved (see docs/audit/CardShaderEnvironmentCorrection.md):
// the vector equals the source quaternion's forward, but the clone's tangent
// space is not the source's, so no negation is applied without a same-frame check.
uniform vec3 light_direction = vec3(-0.08418598, 0.25881905, 0.96225019);
uniform vec3 light_color = vec3(1.0);
uniform float camera_half_height = 5.0;
uniform float canvas_plane_distance = 100.0;
// Flat RenderSettings ambient, now source-backed rather than approximated:
// GameScene.unity RenderSettings has m_AmbientMode:3 (Flat), so the only
// contribution is m_AmbientSkyColor = (0.212, 0.227, 0.259) at
// m_AmbientIntensity:1 -- no SH probe is baked (m_EnableBakedLightmaps:0 /
// m_EnableRealtimeLightmaps:0). The equator/ground colours are unused in Flat
// mode, so do not substitute them.
uniform vec3 ambient_diffuse = vec3(0.212, 0.227, 0.259);
// Exactly zero, and not merely unmeasured: m_SkyboxMaterial and
// m_CustomReflection are both {fileID: 0}, so Unity has no cubemap to bind.
uniform vec3 environment_specular = vec3(0.0);
// Verification switch; never enabled by CardWidget.
uniform bool sample_only = false;
varying vec4 canvas_modulate;
varying vec2 canvas_tangent;

float pow5(float value) {
    float square = value * value;
    return square * square * value;
}

void vertex() {
    canvas_modulate = COLOR;
    canvas_tangent = normalize(MODEL_MATRIX[0].xy);
}

void fragment() {
    vec4 base = texture(TEXTURE, UV) * canvas_modulate;
    if (sample_only) {
        COLOR = base;
    } else {
        if (has_detail) {
            base.rgb *= texture(detail_map, UV).rgb * 2.0;
        }
        vec4 metal = texture(metal_map, UV);
        // AssetRipper PNGs already unpack A/G to R/G. Verified against
        // original Texture2D114/100/116; do not decode DXT5nm a second time.
        vec2 xy = (texture(normal_map, UV).rg * 2.0 - 1.0) * bump_scale;
        float z = sqrt(1.0 - min(dot(xy, xy), 1.0));
        vec3 n = normalize(vec3(xy, z));
        // Canvas rotation: Unity y-up vs Godot y-down.
        n.xy = mat2(vec2(canvas_tangent.x, -canvas_tangent.y),
                    vec2(canvas_tangent.y, canvas_tangent.x)) * n.xy;
        float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
        vec2 camera_xy = vec2((SCREEN_UV.x - 0.5) * aspect, 0.5 - SCREEN_UV.y)
            * (2.0 * camera_half_height);
        vec3 v = normalize(vec3(-camera_xy, canvas_plane_distance));
        vec3 l = normalize(light_direction);
        vec3 sum = l + v;
        vec3 h = sum * inversesqrt(max(dot(sum, sum), 0.001));
        float nv = abs(dot(n, v));
        float nl = clamp(dot(n, l), 0.0, 1.0);
        float nh = clamp(dot(n, h), 0.0, 1.0);
        float lh = clamp(dot(l, h), 0.0, 1.0);
        float smoothness = metal.a * gloss_scale;
        float perceptual_roughness = 1.0 - smoothness;
        float roughness = max(perceptual_roughness * perceptual_roughness, 0.002);
        float one_minus_reflectivity = 0.779084 * (1.0 - metal.r);
        vec3 specular_color = mix(vec3(0.220916), base.rgb, metal.r);
        vec3 diffuse_color = base.rgb * one_minus_reflectivity;
        float fd90_minus_one = 2.0 * lh * lh * perceptual_roughness - 0.5;
        float diffuse_term = (1.0 + fd90_minus_one * pow5(1.0 - nl))
            * (1.0 + fd90_minus_one * pow5(1.0 - nv)) * nl;
        float visibility = 0.5 / (nl * (nv * (1.0 - roughness) + roughness)
            + nv * (nl * (1.0 - roughness) + roughness) + 0.00001);
        float a2 = roughness * roughness;
        float denominator = nh * nh * (a2 - 1.0) + 1.0;
        float distribution = a2 * 0.318309886 / (denominator * denominator + 0.0000001);
        float specular_term = sqrt(max(visibility * distribution * 3.141592654, 0.0001)) * nl;
        if (dot(specular_color, specular_color) == 0.0) {
            specular_term = 0.0;
        }
        vec3 direct_fresnel = mix(specular_color, vec3(1.0), pow5(1.0 - lh));
        float grazing = clamp(smoothness + 1.0 - one_minus_reflectivity, 0.0, 1.0);
        vec3 indirect_fresnel = mix(specular_color, vec3(grazing), pow5(1.0 - nv));
        float surface_reduction = 1.0 - 0.28 * roughness * perceptual_roughness;
        vec3 rgb = diffuse_color * (light_color * diffuse_term + ambient_diffuse)
            + direct_fresnel * (light_color * specular_term)
            + environment_specular * surface_reduction * indirect_fresnel
            + texture(emission_map, UV).rgb * emission_color;
        COLOR = vec4(rgb, base.a);
    }
}
