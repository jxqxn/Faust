extends RefCounted

## [SRC: HandCardsController.Update 0x563520 / HandBagController.Update 0x55e510;
## dump.cs:320419 ItemInfo {pos,width,scale}, 320465 HandBagController fields;
## GameScene.unity Mono11456: reserve0, Space10, minVisibleWidth20, Range0.]
static func allocate(widths: Array, available: float, normalized: float, previous_order: Array = [],
	gap_index := -1, gap_width := 0.0) -> Dictionary:
	var count := widths.size()
	var natural: Array[float] = []
	var total := 0.0
	for i in count:
		if i == gap_index:
			total += gap_width + 10.0
		natural.append(total)
		total += float(widths[i]) + 10.0
	if gap_index == count:
		total += gap_width + 10.0
	if count > 0:
		total -= 10.0
	var positions: Array[float] = []
	var order: Array = previous_order.duplicate() if previous_order.size() == count else range(count)
	var offset := (available - total) * (0.5 if total <= available else normalized)
	for pos in natural:
		positions.append(pos + offset)
	var left_end := 0
	var right_begin := count
	if total > available:
		for i in count:
			if positions[i] < float(i) * 20.0:
				left_end = i + 1
			elif available - float(widths[count - 1]) - float(count - i - 1) * 20.0 < positions[i]:
				right_begin = i
				break
		for i in range(left_end):
			positions[i] = float(i) * 20.0
			order.erase(i)
			order.insert(i, i)
		for i in range(right_begin, count):
			positions[i] = available - float(count - i - 1) * 20.0 - float(widths[i])
			order.erase(i)
			order.push_front(i)
	return {"positions": positions, "draw_order": order, "total": total,
		"overflows": total > available, "range": normalized if total > available else 1.0}

## Original uses an authored per-Update increment, not deltaTime here.
## DLL RVA1c9e558=9a99993e=.3; RVA1c9e764=6f12833a=.001.
## Native branch chooses sign, clamps abs(edge excess) to SpeedRange100..400,
## then adds distance*sign*SpeedMultiple200*.001/total and Clamp01.
static func advance_range(normalized: float, local_pointer_x: float, available: float, total: float) -> float:
	if total <= available:
		return 1.0
	# Hand pivot(.52,0); source ScreenPointToLocalPoint returns pivot-relative x.
	var pointer := local_pointer_x - available * 0.52
	var excess := pointer + available * 0.3 if pointer < 0 else pointer - available * 0.3
	if (pointer < 0 and excess < 0) or (pointer >= 0 and excess > 0):
		return clampf(normalized + clampf(absf(excess), 100, 400) * signf(excess) * 200.0 * 0.001 / total, 0, 1)
	return normalized

## [SRC: HandCardsController.Update 0x563520, candidate search and IsSticky
## branches; GameScene Hand StickyRange=(240,100), dump.cs:320465 fields.]
## The search uses uncompressed ItemInfo.pos, plus half(width+Space), before
## inserting the dragged-card gap. Painter order and prior gap are not inputs.
static func preview(widths: Array, available: float, normalized: float,
	pointer: Vector2, compatible: Array, sticky: bool, sticky_start: Vector2) -> Dictionary:
	var total := 0.0
	for width in widths:
		total += float(width) + 10.0
	if not widths.is_empty():
		total -= 10.0
	var offset := (available - total) * (0.5 if total <= available else normalized)
	var start := offset
	var index := 0
	while index < widths.size():
		if pointer.x < start + (float(widths[index]) + 10.0) * 0.5:
			break
		start += float(widths[index]) + 10.0
		index += 1
	if index < compatible.size() and bool(compatible[index]) and pointer.x >= start:
		return {"index": -1, "sticky": true, "start": Vector2(start, pointer.y)}
	if sticky:
		var distance := (pointer - sticky_start).abs()
		# The release frame clears IsSticky but does not yet insert a gap.
		return {"index": -1, "sticky": distance.x <= 240.0 and distance.y <= 100.0, "start": sticky_start}
	return {"index": index, "sticky": false, "start": sticky_start}
