## Runtime subset of the original OperationFilter for total-card operations.
## [SRC: OperationFilter.c @ IsMatch (RVA 0x3a1880) excludes lost cards and
##  applies card-id/tag predicates before ModifyTag/TotalModifyTag execute.]
class_name RuntimeOperationFilter
extends RefCounted

static func select_total(state, db, selector: String) -> Array:
	var out: Array = []
	if state == null:
		return out
	for uid in state.card_instances.keys():
		var instance = state.get_card_instance(int(uid))
		if instance == null or instance.is_lost or instance.zone == "removed":
			continue
		if _matches(instance, db, selector):
			out.append(instance)
	return out


static func _matches(instance, db, selector: String) -> bool:
	if instance == null:
		return false
	return matches_card_data(instance.card_id, instance.tags, db, selector)


## This clone deliberately implements only the selector subset used by the
## current total/Sultan-pool operations. Scope selectors and equip operations
## remain audit-visible until their original traversal semantics are present.
static func supports_selector(selector: String) -> bool:
	var normalized := selector.strip_edges()
	if normalized == "sudan" or normalized.is_valid_int():
		return true
	if normalized in ["", "all", "self", "parent", "friend", "enemy"] or "~" in normalized:
		return false
	var dot := normalized.find(".")
	if dot < 0:
		return true # A plain runtime tag predicate.
	var selected_card_id := normalized.substr(0, dot)
	return selected_card_id.is_valid_int() and _is_tag_comparison(normalized.substr(dot + 1))


static func _is_tag_comparison(expr: String) -> bool:
	for op in [">=", "<=", "!=", "=", ">", "<"]:
		var index := expr.find(op)
		if index > 0:
			return expr.substr(index + op.length()).is_valid_int()
	return false


## Apply the ID/tag predicates to data which has not been materialized as a
## CardInstance. Sultan pool entries deliberately remain config IDs until draw.
## [SRC: OperationFilter.c @ IsMatch (RVA 0x3a1880); SudanPoolModifyTag.c @
## DoTemplate (RVA 0x51c2e0) filters the current player Sultan pool.]
static func matches_card_data(card_id: int, tags: Dictionary, db, selector: String) -> bool:
	if selector == "" or selector == "all":
		return true
	if selector == "sudan":
		return str(db.get_card(card_id).get("type", "")) == "sudan"
	if selector.is_valid_int():
		return card_id == selector.to_int()
	var dot := selector.find(".")
	if dot > 0:
		var selected_card_id := selector.substr(0, dot)
		if selected_card_id.is_valid_int() and card_id != selected_card_id.to_int():
			return false
		var expr := selector.substr(dot + 1)
		for op in [">=", "<=", "!=", "=", ">", "<"]:
			var index := expr.find(op)
			if index > 0:
				var current := int(tags.get(expr.substr(0, index), 0))
				var wanted := expr.substr(index + op.length()).to_int()
				return _compare(current, wanted, op)
	return int(tags.get(selector, 0)) > 0


static func _compare(left: int, right: int, op: String) -> bool:
	match op:
		">=": return left >= right
		"<=": return left <= right
		"!=": return left != right
		"=": return left == right
		">": return left > right
		"<": return left < right
	return false
