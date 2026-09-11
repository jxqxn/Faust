extends RefCounted

## Godot adapter for Unity's LayoutElement min/preferred/flexible contract.
## Callers pass authored prefab values, not a second content/config format.
## [SRC: PromptController.Show 0x58a020 / OptionController.Show 0x576b50
## ForceRebuildLayoutImmediate; dump.cs:430763/430766
## HorizontalOrVerticalLayoutGroup.CalcAlongAxis/SetChildrenAlongAxis.]
## This reproduces the layout API allocation; glyph measurement is external.
static func allocate(
	extent: float, minimum: Array, preferred: Array, flexible: Array,
	spacing := 0.0, before := 0.0, after := 0.0, alignment := 0.5,
	reverse := false
) -> Dictionary:
	var count := minimum.size()
	var min_total := before + after + spacing * maxi(0, count - 1)
	var pref_total := min_total
	var flex_total := 0.0
	for i in count:
		min_total += float(minimum[i])
		pref_total += maxf(float(minimum[i]), float(preferred[i]))
		flex_total += maxf(0, float(flexible[i]))
	var ratio := 0.0
	if pref_total != min_total:
		ratio = clampf((extent - min_total) / (pref_total - min_total), 0, 1)
	var excess := maxf(0, extent - pref_total)
	var cursor := before
	if extent < min_total:
		cursor += (extent - min_total) * alignment
	elif flex_total == 0:
		cursor += excess * alignment
	var positions: Array[float] = []
	var sizes: Array[float] = []
	positions.resize(count)
	sizes.resize(count)
	for step in count:
		var i := count - 1 - step if reverse else step
		var length := lerpf(float(minimum[i]), maxf(float(minimum[i]), float(preferred[i])), ratio)
		if flex_total > 0:
			length += excess * maxf(0, float(flexible[i])) / flex_total
		positions[i] = cursor
		sizes[i] = length
		cursor += length + spacing
	return {"positions": positions, "sizes": sizes, "minimum": min_total, "preferred": pref_total}
