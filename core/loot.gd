## Loot (掉落) system.
## verified-conclusions.md #5-#7. type dispatch re-confirmed vs
## decompiled/GenLoot.c @ Generate (0x511990):
##   type 3  -> loop(repeat): ExcludeAlreadyHave + SimpleWeightLoot (empty => [])
##   type 4  -> WeightedNChooseM
##   type 99 -> loop(repeat): LootItem per-entry (condition-gated, not "grab all")
##   default (incl type 2) -> loop(repeat): SimpleWeightLoot
## SimpleWeightLoot: int weights, Random.Range(0,total) decrement.
## WeightedNChooseM: float precision, WITHOUT replacement (RemoveAt + subtract).
class_name LootSystem
extends RefCounted


# A LootNode item: {num, id, type, weight}
# items: Array of item dicts.


## Generate loot for a node definition {type, repeat, item[]}.
## `owned_ids`: set of already-owned card ids (for ExcludeAlreadyHave).
## `condition_ok`: optional Callable(item) -> bool; items failing the check
## are excluded BEFORE weighting in all types (SimpleWeightLoot,
## WeightedNChooseM, and type-99 per-item gating).
## [SRC: GenLoot.c @ Generate: SimpleWeightLoot (line 1000) and
##  WeightedNChooseM (line 1124) both apply a Where condition filter before
##  weighting; type-99 (line 849) gates each item on its condition]
## Returns Array of chosen ids (may contain duplicates).
static func generate(rng: GameRNG, node: Dictionary, owned_ids: Array = [], condition_ok: Callable = Callable()) -> Array:
	var loot_type := int(node.get("type", 2))
	var repeat := int(node.get("repeat", 1))
	var items: Array = node.get("item", [])
	# Pre-filter items by condition for all types (original applies Where before weighting).
	var filtered := _filter_conditions(items, condition_ok)
	var out: Array = []
	match loot_type:
		3:
			for _i in repeat:
				var picked: Variant = _simple_weight(rng, _exclude(filtered, owned_ids))
				if picked != null:
					out.append(picked)
				# Empty filtered set => returns nothing for that iteration.
		4:
			# M = the node's repeat/count field (node+0x20 in .c), NOT sum(num).
			# [SRC: GenLoot.c @ Generate (0x511990) type-4: passes node+0x20 as M]
			out = _weighted_n_choose_m(rng, filtered, repeat)
		99:
			for _i in repeat:
				for it in filtered:
					out.append(int(it.get("id", 0)))
		_:
			# default (incl type 2): SimpleWeightLoot per repeat.
			for _i in repeat:
				var picked: Variant = _simple_weight(rng, filtered)
				if picked != null:
					out.append(picked)
	return out


## Filter items by the condition_ok callable. Items with no condition pass through.
static func _filter_conditions(items: Array, condition_ok: Callable) -> Array:
	if not condition_ok.is_valid():
		return items
	var out: Array = []
	for it in items:
		if condition_ok.call(it):
			out.append(it)
	return out


## SimpleWeightLoot: int-weighted single pick.
static func _simple_weight(rng: GameRNG, items: Array) -> Variant:
	if items.is_empty():
		return null
	var weights := PackedInt32Array()
	for it in items:
		weights.append(int(it.get("weight", 1)))
	var idx := rng.weighted_pick_int(weights)
	if idx < 0:
		return null
	return int(items[idx].get("id", 0))


## WeightedNChooseM: float precision, without replacement.
## M = the count to draw (the node's repeat/count, NOT sum of item nums).
## [SRC: GenLoot.c @ Generate type-4 passes node+0x20 as M; offset-consistent
##  with the repeat/count loop bound in every other type branch]
static func _weighted_n_choose_m(rng: GameRNG, items: Array, m: int) -> Array:
	if items.is_empty():
		return []
	var pool: Array = items.duplicate(true)
	var out: Array = []
	var count := minf(m, pool.size())
	for _i in count:
		var total := 0.0
		for it in pool:
			total += float(it.get("weight", 1))
		if total <= 0.0:
			break
		var r := rng.value() * total
		var chosen_idx := -1
		for j in pool.size():
			r -= float(pool[j].get("weight", 1))
			if r < 0.0:
				chosen_idx = j
				break
		if chosen_idx < 0:
			chosen_idx = pool.size() - 1
		out.append(int(pool[chosen_idx].get("id", 0)))
		# Without replacement: remove and subtract weight from total.
		pool.remove_at(chosen_idx)
	return out


## ExcludeAlreadyHave: filter out items whose id is already owned.
static func _exclude(items: Array, owned_ids: Array) -> Array:
	var out: Array = []
	for it in items:
		if int(it.get("id", 0)) not in owned_ids:
			out.append(it)
	return out
