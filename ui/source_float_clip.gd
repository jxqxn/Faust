extends RefCounted
## Read the original unweighted Unity float curves without a translated asset.
## Float and quaternion component curves plus events; callers own node bindings.
var curves: Array[Dictionary] = []
var rotation_curves: Array[Dictionary] = []
var events: Array[Dictionary] = []
var duration := 0.0

func read(path: String) -> void:
	curves.clear()
	rotation_curves.clear()
	events.clear()
	duration = 0.0
	var section := ""
	var curve: Dictionary = {}
	var key: Dictionary = {}
	var event: Dictionary = {}
	for raw in FileAccess.get_file_as_string(path).split("\n"):
		var line := raw.strip_edges()
		if raw.begins_with("  m_"):
			section = line.get_slice(":", 0)
		if section == "m_RotationCurves":
			if raw.begins_with("  - curve:"):
				curve = {"keys": []}
				rotation_curves.append(curve)
			elif raw.begins_with("      - serializedVersion:"):
				key = {}
				curve.keys.append(key)
			elif line.begins_with("path:"):
				curve.path = line.substr(5).strip_edges()
			elif line.begins_with("time:"):
				key.time = float(line.get_slice(":", 1))
				duration = maxf(duration, key.time)
			elif line.get_slice(":", 0) in ["value", "inSlope", "outSlope"]:
				var components: Dictionary = {}
				for item in line.substr(line.find("{") + 1).trim_suffix("}").split(","):
					components[item.get_slice(":", 0).strip_edges()] = float(item.get_slice(":", 1))
				key[line.get_slice(":", 0)] = components
			elif line.begins_with("weightedMode:"):
				assert(int(line.get_slice(":", 1)) == 0, "Weighted quaternion curves need a separate evaluator")
		elif section == "m_FloatCurves":
			if raw.begins_with("  - serializedVersion:"):
				curve = {"keys": []}
				curves.append(curve)
			elif raw.begins_with("      - serializedVersion:"):
				key = {}
				curve.keys.append(key)
			elif line.begins_with("attribute:") or line.begins_with("path:"):
				curve[line.get_slice(":", 0)] = line.substr(line.find(":") + 1).strip_edges()
			elif line.get_slice(":", 0) in ["time", "value", "inSlope", "outSlope", "weightedMode"]:
				var value := line.get_slice(":", 1).strip_edges()
				key[line.get_slice(":", 0)] = INF if value == "Infinity" else float(value)
				if line.begins_with("time:"):
					duration = maxf(duration, float(value))
				if line.begins_with("weightedMode:"):
					assert(int(value) == 0, "Weighted source curves require their own evaluator")
		elif section == "m_Events":
			if line.begins_with("- time:"):
				event = {"time": float(line.get_slice(":", 1))}
				events.append(event)
			elif line.begins_with("functionName:") or line.begins_with("data:"):
				event[line.get_slice(":", 0)] = line.substr(line.find(":") + 1).strip_edges()

static func sample(curve: Dictionary, time: float) -> float:
	var keys: Array = curve.keys
	if time <= float(keys[0].time):
		return float(keys[0].value)
	for index in range(1, keys.size()):
		var right: Dictionary = keys[index]
		if time > float(right.time):
			continue
		var left: Dictionary = keys[index - 1]
		if time == float(right.time):
			return float(right.value)
		if is_inf(float(left.outSlope)) or is_inf(float(right.inSlope)):
			return float(left.value)
		var span := float(right.time) - float(left.time)
		var t := (time - float(left.time)) / span
		var t2 := t * t
		var t3 := t2 * t
		return (2 * t3 - 3 * t2 + 1) * float(left.value) + (t3 - 2 * t2 + t) * span * float(left.outSlope) + (-2 * t3 + 3 * t2) * float(right.value) + (t3 - t2) * span * float(right.inSlope)
	return float(keys[-1].value)

static func sample_rotation(curve: Dictionary, time: float) -> Quaternion:
	var values: Array[float] = []
	for component in ["x", "y", "z", "w"]:
		var scalar: Dictionary = {"keys": []}
		for key in curve.keys:
			scalar.keys.append({"time": key.time, "value": key.value[component],
				"inSlope": key.inSlope[component], "outSlope": key.outSlope[component]})
		values.append(sample(scalar, time))
	return Quaternion(values[0], values[1], values[2], values[3]).normalized()
