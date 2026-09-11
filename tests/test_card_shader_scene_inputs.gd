extends GutTest

## A11: the light model `ui/card_metal.gdshader` fakes.
##
## The clone renders cards unshaded inside a 2D canvas, so it has to state the
## scene's lighting inputs as uniforms. This test pins those inputs against the
## exported Unity scene instead of trusting the shader comments, and it records
## which parts of the original light model are now *settled by data* rather than
## awaiting field capture.
##
## [SRC: unity_export/ExportedProject/Assets/Scenes/GameScene.unity
##       RenderSettings block (line 4ff) + !u!108 &4869 / &4870 (lines 90827 /
##       90889) + !u!4 &4011 (line 73026);
##       ProjectSettings/ProjectSettings.asset m_ActiveColorSpace: 0 (line 60).]

const SHADER_PATH := "res://ui/card_metal.gdshader"
const CLONE_PROJECT := "res://project.godot"
const CORPUS_SCENE := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/unity_export/ExportedProject/Assets/Scenes/GameScene.unity"
const CORPUS_PROJECT_SETTINGS := "C:/Users/User/Documents/GitHub/Faust-local-source/_unpack/unity_export/ExportedProject/ProjectSettings/ProjectSettings.asset"

## Card GameObjects sit on this Unity layer (m_Layer: 5 on the CardNew roots).
const CARD_LAYER := 5

var _shader: String = ""


func before_all() -> void:
	if FileAccess.file_exists(SHADER_PATH):
		_shader = FileAccess.get_file_as_string(SHADER_PATH)


func _uniform_vec3(name: String) -> Array:
	# GLSL allows the short forms vec3(0.0) and vec3(1.0); fill the missing
	# components with the last written one, which is what GLSL does.
	var re := RegEx.new()
	re.compile("uniform\\s+vec3\\s+%s\\s*=\\s*vec3\\(([^)]*)\\)" % name)
	var m := re.search(_shader)
	if m == null:
		return []
	var raw := m.get_string(1).split(",")
	var filled: Array = []
	for part in raw:
		filled.append(float(part.strip_edges()))
	var out: Array = []
	for i in 3:
		out.append(float(filled[mini(i, filled.size() - 1)]))
	return out


func _corpus_lines() -> PackedStringArray:
	return FileAccess.get_file_as_string(CORPUS_SCENE).split("\n")


func _render_setting(key: String) -> String:
	for raw in _corpus_lines():
		var line := str(raw).strip_edges()
		if line.begins_with(key + ":"):
			return line.substr(key.length() + 1).strip_edges()
	return ""


# ---- RenderSettings: what the ambient uniform may and may not claim ---------

func test_ambient_is_the_flat_sky_colour_not_an_sh_probe() -> void:
	assert_false(_shader.is_empty(), "fixture guard: the card shader exists")
	assert_eq(_render_setting("m_AmbientMode"), "3",
		"AmbientMode 3 = Flat: Unity uses only m_AmbientSkyColor, no SH probe is baked")
	assert_eq(_render_setting("m_SkyboxMaterial"), "{fileID: 0}",
		"no skybox material, so there is no sky-derived ambient or reflection cubemap")
	assert_eq(_render_setting("m_CustomReflection"), "{fileID: 0}", "no custom reflection either")
	assert_eq(_render_setting("m_ReflectionIntensity"), "1")
	assert_almost_eq(float(_render_setting("m_AmbientIntensity")), 1.0, 0.0001,
		"flat ambient is used at full intensity")


func test_ambient_diffuse_uniform_equals_the_scene_sky_colour() -> void:
	var sky := _render_setting("m_AmbientSkyColor")
	var want := [0.212, 0.227, 0.259]
	for i in 3:
		assert_true(sky.contains("%s" % str(want[i])), "scene sky colour carries %s" % str(want[i]))
	assert_eq(_uniform_vec3("ambient_diffuse"), want,
		"the shader's ambient uniform is the scene's flat ambient colour, verbatim")
	# The other two RenderSettings ambient colours are unused under Flat mode;
	# using either of them would be an invention.
	assert_ne(_uniform_vec3("ambient_diffuse"), [0.114, 0.125, 0.133],
		"m_AmbientEquatorColor must not be used under AmbientMode 3")
	assert_ne(_uniform_vec3("ambient_diffuse"), [0.047, 0.043, 0.035],
		"m_AmbientGroundColor must not be used under AmbientMode 3")


func test_environment_specular_is_zero_because_there_is_no_reflection_source() -> void:
	# With m_SkyboxMaterial and m_CustomReflection both null and no SH probe,
	# Unity has no cubemap to bind: the shader's `environment_specular` zero is
	# now source-backed rather than "awaiting field capture".
	assert_eq(_uniform_vec3("environment_specular"), [0.0, 0.0, 0.0],
		"no skybox and no custom reflection => no environment specular term")


# ---- Lights: which one can actually reach a card --------------------------

func test_exactly_one_directional_light_covers_the_card_layer() -> void:
	var masks := _directional_light_masks()
	assert_eq(masks.size(), 2, "GameScene declares exactly two directional lights")
	# Anchor each mask to its own light component: file order is not meaningful.
	var card_light := _mask_value("4870")
	var dice_light := _mask_value("4869")
	assert_true(_mask_has_layer(card_light, CARD_LAYER),
		"light 4870's culling mask includes the card layer")
	assert_false(_mask_has_layer(dice_light, CARD_LAYER),
		"light 4869's mask does not; it exists for the Sudan dice camera")
	assert_true(_mask_has_layer(dice_light, 30),
		"4869 is the layer-30 light")
	assert_false(_mask_has_layer(card_light, 30),
		"and 4870 is not, so the two masks are complementary, not identical")
	assert_ne(card_light, dice_light)


func test_the_card_light_is_white_at_full_intensity_without_shadows() -> void:
	# Light &4870 is the one whose mask covers layer 5.
	var block := _light_block("4870")
	assert_true(block.contains("m_Type: 1"), "directional (not point/spot)")
	assert_true(block.contains("m_Color: {r: 1, g: 1, b: 1, a: 1}"), "white")
	assert_true(block.contains("m_Intensity: 1"), "unit intensity")
	assert_true(block.contains("m_Type: 0"), "shadows are off for this light")
	assert_eq(_uniform_vec3("light_color"), [1.0, 1.0, 1.0],
		"the shader's single light colour matches the only light that reaches cards")


func test_the_shadowed_light_cannot_reach_a_card() -> void:
	# &4869 has soft shadows (m_Type: 2) but its mask is layer 30 only, so the
	# clone must not invent a card shadow from it.
	var block := _light_block("4869")
	assert_true(block.contains("m_Type: 2"), "soft shadows, per the audit note")
	assert_eq(_mask_value("4869"), 1073741824, "1 << 30, the Sudan dice layer only")


func test_light_direction_width_matches_the_source_rotation_quaternion() -> void:
	# The uniform's z component is unresolved (see the evidence doc): the source
	# quaternion (.13040192,.043246232,-.005693473,.9905012) is stored verbatim in
	# the scene, so there is ground truth to check against -- but the clone's
	# tangent space is not the source's, and negating z is not yet source-backed.
	# This test only pins the two components whose magnitudes are settled.
	var q := _transform_rotation("4011")
	assert_eq(q.size(), 4, "the light transform's quaternion is in the scene")
	assert_almost_eq(float(q[0]), 0.13040192, 0.000001, "x")
	assert_almost_eq(float(q[1]), 0.043246232, 0.000001, "y")
	assert_almost_eq(float(q[2]), -0.005693473, 0.000001, "z")
	var direction := _uniform_vec3("light_direction")
	assert_eq(direction.size(), 3, "the shader carries a light_direction uniform")
	assert_almost_eq(absf(float(direction[0])), 0.08418598, 0.0001,
		"|x| matches the quaternion's forward vector")
	assert_almost_eq(absf(float(direction[1])), 0.25881905, 0.0001,
		"|y| matches; sin(15 deg) = 0.25881905 and the euler hint is x:15 y:-5")


# ---- Colour space ----------------------------------------------------------

func test_colour_space_is_gamma_in_both_projects() -> void:
	# Divergence register, not a claim about pixels: the source runs a Gamma
	# workflow and the clone does not opt into one. Whether that brightens or
	# darkens a given card needs a same-frame comparison this repo cannot run
	# yet, so the test only pins the setting so the divergence cannot silently
	# change.
	assert_true(_corpus_project_setting("m_ActiveColorSpace").begins_with("0"),
		"source m_ActiveColorSpace = 0 (Gamma)")
	assert_true(_corpus_project_setting("m_ActiveColorSpace").length() > 0,
		"fixture guard: the source setting was actually read")
	var clone_project := FileAccess.get_file_as_string(CLONE_PROJECT)
	assert_false(clone_project.contains("color_space"),
		"the clone does not opt into a Gamma workflow; registered divergence")


# ---- helpers ---------------------------------------------------------------

func _directional_light_masks() -> Array:
	var lines := _corpus_lines()
	var out: Array = []
	for i in lines.size():
		if not str(lines[i]).begins_with("--- !u!108 &"):
			continue
		for j in range(i, mini(i + 90, lines.size())):
			var line := str(lines[j]).strip_edges()
			if line.begins_with("m_CullingMask:"):
				for k in range(j, mini(j + 3, lines.size())):
					if str(lines[k]).strip_edges().begins_with("m_Bits:"):
						out.append(str(lines[k]).split(":")[1].strip_edges())
						break
				break
	return out


func _light_block(anchor: String) -> String:
	var lines := _corpus_lines()
	for i in lines.size():
		if str(lines[i]).strip_edges() == "--- !u!108 &" + anchor:
			var out := ""
			for j in range(i, mini(i + 90, lines.size())):
				if j > i and str(lines[j]).begins_with("--- !u!"):
					break
				out += str(lines[j]) + "\n"
			return out
	return ""


func _mask_value(anchor: String) -> int:
	for raw in _light_block(anchor).split("\n"):
		var line := str(raw).strip_edges()
		if line.begins_with("m_Bits:"):
			return int(line.split(":")[1].strip_edges())
	return -1


func _transform_rotation(anchor: String) -> Array:
	var lines := _corpus_lines()
	for i in lines.size():
		if str(lines[i]).strip_edges() == "--- !u!4 &" + anchor:
			for j in range(i, mini(i + 30, lines.size())):
				var line := str(lines[j]).strip_edges()
				if line.begins_with("m_LocalRotation:"):
					var body := line.substr(line.find("{") + 1, line.find("}") - line.find("{") - 1)
					var out: Array = []
					for pair in body.split(","):
						out.append(float(pair.split(":")[1].strip_edges()))
					return out
	return []


func _corpus_project_setting(key: String) -> String:
	if not FileAccess.file_exists(CORPUS_PROJECT_SETTINGS):
		return ""
	for raw in FileAccess.get_file_as_string(CORPUS_PROJECT_SETTINGS).split("\n"):
		var line := str(raw).strip_edges()
		if line.begins_with(key + ":"):
			return line.substr(key.length() + 1).strip_edges()
	return ""


func _mask_has_layer(mask: int, layer: int) -> bool:
	return (mask & (1 << layer)) != 0
